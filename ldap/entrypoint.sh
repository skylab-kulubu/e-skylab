#!/bin/bash
set -e

INSTANCE_DIR="/etc/dirsrv/slapd-${DS_INSTANCE_NAME}"
INF_TEMPLATE="/etc/dirsrv/setup.inf.template"
INF_FILE="/tmp/setup.inf"
BOOTSTRAP_LDIF="/etc/dirsrv/bootstrap.ldif"
PID_FILE="/run/dirsrv/slapd-${DS_INSTANCE_NAME}.pid" # Arch'ta /var/run yerine /run olabilir
SOCKET_PATH="/run/dirsrv/slapd-${DS_INSTANCE_NAME}.socket" # LDAPI için socket yolu

# Gerekli dizinleri oluştur ve izinleri ayarla
# Arch'ta 'dirsrv' kullanıcısı ve grubu olabilir, 'nobody' yerine onu kullanmak daha iyi
# Veya şimdilik root olarak çalıştırıp sonra izinleri ayarlarız
mkdir -p /run/dirsrv /var/log/dirsrv/slapd-${DS_INSTANCE_NAME} /var/lib/dirsrv/slapd-${DS_INSTANCE_NAME}/db /var/lib/dirsrv/slapd-${DS_INSTANCE_NAME}/logs
# chown -R dirsrv:dirsrv /run/dirsrv /var/log/dirsrv /var/lib/dirsrv/slapd-${DS_INSTANCE_NAME}
# chmod -R 700 /var/lib/dirsrv/slapd-${DS_INSTANCE_NAME}

# LDAP URL'leri (yerel bağlantı için)
LDAP_URL="ldap://localhost:389"
LDAPI_URL="ldapi://${SOCKET_PATH//\//%2f}" # Socket path'ini URL encode et

echo ">>> Entrypoint baslatildi. Instance: ${DS_INSTANCE_NAME}, Suffix: ${DS_SUFFIX_NAME}"

# --- İlk Kurulum Kontrolü ---
if [ ! -f "${INSTANCE_DIR}/dse.ldif" ]; then
  echo ">>> Ilk kurulum yapiliyor..."

  # 1. Template dosyasını doldur
  envsubst < "${INF_TEMPLATE}" > "${INF_FILE}"
  echo ">>> Kurulum dosyasi (${INF_FILE}):"
  cat "${INF_FILE}"

  # 2. 389ds instance'ını oluştur
  echo ">>> 'dscreate from-file' calistiriliyor..."
  dscreate -v from-file "${INF_FILE}"
  echo ">>> Instance olusturuldu."

  # 3. Sunucuyu GEÇİCİ olarak ARKA PLANDA başlat (bootstrap için)
  echo ">>> Sunucu gecici olarak arka planda baslatiliyor..."
  # dsctl ${DS_INSTANCE_NAME} start # Bu komut foreground'a geçebilir, ns-slapd daha iyi
  /usr/sbin/ns-slapd -D "${INSTANCE_DIR}" -i "${PID_FILE}" &
  SLAPD_PID=$!
  echo ">>> ns-slapd PID: ${SLAPD_PID}"

  # 4. Sunucunun hazır olmasını bekle (ldapsearch ile ping)
  echo ">>> LDAP sunucusunun hazir olmasi bekleniyor (max 30sn)..."
  ATTEMPTS=0
  MAX_ATTEMPTS=15
  until ldapsearch -H "${LDAP_URL}" -x -b "" -s base "(objectClass=*)" > /dev/null 2>&1 || \
        ldapsearch -H "${LDAPI_URL}" -x -b "" -s base "(objectClass=*)" > /dev/null 2>&1; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ ${ATTEMPTS} -ge ${MAX_ATTEMPTS} ]; then
      echo "!!! HATA: LDAP sunucusu zamaninda baslatilamadi!"
      # Sunucunun loglarına bakmak faydalı olabilir
      # cat /var/log/dirsrv/slapd-${DS_INSTANCE_NAME}/errors || true
      kill ${SLAPD_PID} || true
      exit 1
    fi
    echo "    ...bekleniyor (${ATTEMPTS}/${MAX_ATTEMPTS})"
    sleep 2
  done
  echo ">>> LDAP sunucusu hazir."

  # 5. Bootstrap LDIF'i (OU ve Gruplar) ekle (Önceki setup.sh mantığı)
  echo "[SETUP] Base DN kontrolü..."
  if ldapsearch -H "${LDAP_URL}" -x -D "cn=Directory Manager" -w "${DS_DM_PASSWORD}" \
      -b "${DS_SUFFIX_NAME}" -s base "(objectClass=*)" >/dev/null 2>&1; then
      echo "[INFO] Base DN zaten mevcut."
  else
      echo "[SETUP] Base DN oluşturuluyor (dscreate zaten yapmis olabilir)..."
      # dscreate zaten suffix eklemiş olmalı, bu adımı atlayabiliriz veya kontrol edebiliriz
      # ldapadd ... (Gerekirse base DN ekleme komutu)
  fi

  echo "[SETUP] OU yapıları kontrolü (${BOOTSTRAP_LDIF})..."
  if ldapsearch -H "${LDAP_URL}" -x -D "cn=Directory Manager" -w "${DS_DM_PASSWORD}" \
      -b "ou=people,${DS_SUFFIX_NAME}" -s base "(objectClass=*)" >/dev/null 2>&1; then
      echo "[INFO] OU yapıları zaten mevcut."
  else
      echo "[SETUP] OU yapıları (${BOOTSTRAP_LDIF}) oluşturuluyor..."
      ldapadd -H "${LDAP_URL}" -x -D "cn=Directory Manager" -w "${DS_DM_PASSWORD}" -f "${BOOTSTRAP_LDIF}" || \
      ldapadd -H "${LDAPI_URL}" -x -D "cn=Directory Manager" -w "${DS_DM_PASSWORD}" -f "${BOOTSTRAP_LDIF}"
      echo "[INFO] OU yapıları oluşturuldu."
  fi

  # 6. Geçici sunucuyu durdur
  echo ">>> Gecici sunucu (PID: ${SLAPD_PID}) durduruluyor..."
  kill ${SLAPD_PID}
  # İşlemin tamamen bitmesini bekle, hata verirse görmezden gel
  wait ${SLAPD_PID} || true
  # PID dosyasını sil (önemli!)
  rm -f "${PID_FILE}" || true
  echo ">>> Gecici sunucu durduruldu."
  echo ">>> Ilk kurulum tamamlandi."

else
  echo ">>> Mevcut kurulum bulundu (${INSTANCE_DIR}). Kurulum adimi atlandi."
fi

# --- Sunucuyu Normal Modda Başlat ---
echo ">>> 389 Directory Server (${DS_INSTANCE_NAME}) on planda baslatiliyor..."
# Bu komut konteynerin ana işlemi olacak ve logları STDOUT'a basacak
# exec /usr/sbin/ns-slapd -D "${INSTANCE_DIR}" -i "${PID_FILE}" -Z localhost -d 0 # Eski yöntem
exec dsctl "${DS_INSTANCE_NAME}" start --foreground # Arch'taki önerilen yöntem