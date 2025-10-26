#!/bin/bash
set -e

LDAP_HOST="ldap-server"
LDAP_PORT="3389"
BASE_DN="dc=yildizskylab,dc=com"
BIND_DN="cn=Directory Manager"
BIND_PW="admin"

echo "[SETUP] LDAP sunucusunun hazır olması bekleniyor..."
sleep 5

echo "[SETUP] Backend kontrolü..."

BACKENDS=$(dsconf -D "${BIND_DN}" -w "${BIND_PW}" ldap://${LDAP_HOST}:${LDAP_PORT} backend suffix list 2>&1 || true)

if echo "$BACKENDS" | grep -q "${BASE_DN}"; then
    echo "[INFO] Backend zaten mevcut."
else
    echo "[SETUP] Backend oluşturuluyor..."
    dsconf -D "${BIND_DN}" -w "${BIND_PW}" ldap://${LDAP_HOST}:${LDAP_PORT} backend create \
      --suffix "${BASE_DN}" \
      --be-name userRoot

    echo "[INFO] Backend başarıyla oluşturuldu."
    sleep 3
fi

echo "[SETUP] Base DN kontrolü..."

if ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT} -x -D "${BIND_DN}" -w "${BIND_PW}" \
    -b "${BASE_DN}" -s base "(objectClass=*)" >/dev/null 2>&1; then
    echo "[INFO] Base DN zaten mevcut."
else
    echo "[SETUP] Base DN oluşturuluyor..."
    cat <<EOF | ldapadd -H ldap://${LDAP_HOST}:${LDAP_PORT} -x -D "${BIND_DN}" -w "${BIND_PW}"
dn: ${BASE_DN}
objectClass: top
objectClass: domain
dc: yildizskylab
EOF
    echo "[INFO] Base DN oluşturuldu."
fi

echo "[SETUP] OU yapıları kontrolü..."

if ldapsearch -H ldap://${LDAP_HOST}:${LDAP_PORT} -x -D "${BIND_DN}" -w "${BIND_PW}" \
    -b "ou=people,${BASE_DN}" -s base "(objectClass=*)" >/dev/null 2>&1; then
    echo "[INFO] OU yapıları zaten mevcut."
else
    echo "[SETUP] OU yapıları oluşturuluyor..."
    ldapadd -H ldap://${LDAP_HOST}:${LDAP_PORT} -x -D "${BIND_DN}" -w "${BIND_PW}" -f /init-scripts/bootstrap.ldif
    echo "[INFO] OU yapıları oluşturuldu."
fi

echo ""
echo "=========================================="
echo "[SUCCESS] 389 DS kurulumu tamamlandı!"
echo "=========================================="
echo "LDAP URI: ldap://ldap-server:3389"
echo "Base DN: ${BASE_DN}"
echo "Bind DN: ${BIND_DN}"
echo "Password: ${BIND_PW}"
echo "=========================================="