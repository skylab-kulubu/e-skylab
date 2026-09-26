# Single Redis instance, multiple logical databases

All services that need Redis (CMS drafts, forms, optional rate limiting) share one Redis container. Separate Redis databases or key prefixes isolate apps. Backup is one RDB/AOF, same idea as one Postgres `pg_dumpall`.
