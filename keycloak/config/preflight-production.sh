#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DB_MOUNT_PATH=${KEYCLOAK_DB_MOUNT_PATH:-/mnt/keycloak-db}

"$CONFIG_DIR/validate-production-inputs.sh" >/dev/null

fail() {
  printf 'The selected external database volume is not a complete PostgreSQL 17 cluster: %s\n' \
    "$1" >&2
  exit 1
}

require_nonempty_file() {
  local relative_path=$1
  [[ -f $DB_MOUNT_PATH/$relative_path && -s $DB_MOUNT_PATH/$relative_path ]] \
    || fail "missing non-empty $relative_path"
}

require_nonempty_directory_file() {
  local relative_path=$1
  local candidate
  [[ -d $DB_MOUNT_PATH/$relative_path ]] \
    || fail "missing directory $relative_path"
  for candidate in "$DB_MOUNT_PATH/$relative_path"/*; do
    if [[ -f $candidate && -s $candidate ]]; then
      return 0
    fi
  done
  fail "directory $relative_path has no non-empty segment"
}

require_nonempty_file PG_VERSION
cluster_version=$(<"$DB_MOUNT_PATH/PG_VERSION")
[[ $cluster_version == 17 ]] \
  || fail "PG_VERSION must contain exactly 17"

require_nonempty_file global/pg_control
[[ $(stat -c '%s' "$DB_MOUNT_PATH/global/pg_control") == 8192 ]] \
  || fail "global/pg_control does not have the PostgreSQL 17 control-file size"
require_nonempty_file global/pg_filenode.map

# PostgreSQL 17's initdb creates these fixed global catalog relation OIDs.
require_nonempty_file global/1260
require_nonempty_file global/1262

# template1 and template0 are fixed databases in a real initialized cluster.
for system_database_oid in 1 4; do
  require_nonempty_file "base/$system_database_oid/PG_VERSION"
  [[ $(<"$DB_MOUNT_PATH/base/$system_database_oid/PG_VERSION") == 17 ]] \
    || fail "base/$system_database_oid/PG_VERSION differs from the cluster version"
  require_nonempty_file "base/$system_database_oid/1247"
  require_nonempty_file "base/$system_database_oid/1259"
done

database_directory_count=0
for database_directory in "$DB_MOUNT_PATH/base"/*; do
  if [[ -d $database_directory && \
    $(basename -- "$database_directory") =~ ^[0-9]+$ ]]; then
    database_directory_count=$((database_directory_count + 1))
  fi
done
[[ $database_directory_count -ge 4 ]] \
  || fail "base does not contain the system databases and application database"

require_nonempty_directory_file pg_xact
require_nonempty_directory_file pg_subtrans
require_nonempty_directory_file pg_multixact/offsets
require_nonempty_directory_file pg_multixact/members
[[ -d $DB_MOUNT_PATH/pg_wal/archive_status ]] \
  || fail "missing pg_wal/archive_status"

wal_segment_found=false
for wal_segment in "$DB_MOUNT_PATH/pg_wal"/*; do
  wal_name=$(basename -- "$wal_segment")
  if [[ -f $wal_segment && $wal_name =~ ^[0-9A-F]{24}$ && \
    $(stat -c '%s' "$wal_segment") == 16777216 ]]; then
    wal_segment_found=true
    break
  fi
done
[[ $wal_segment_found == true ]] \
  || fail "pg_wal has no complete 16 MiB WAL segment"

require_nonempty_file postgresql.conf
require_nonempty_file pg_hba.conf

printf 'Production image, origin and complete PostgreSQL 17 cluster preflight passed.\n'
