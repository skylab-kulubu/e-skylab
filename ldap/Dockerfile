# ARM64 uyumlu Arch Linux imajı (resmi olmayan ama yaygın)
FROM menci/archlinuxarm:latest

# Kurulum için ARG ve ENV değişkenleri (compose'dan veya default)
ARG DS_INSTANCE_NAME=ldap_instance
ARG DS_SUFFIX_NAME="dc=yildizskylab,dc=com"
ARG DS_DM_PASSWORD_ARG="admin"

ENV DS_INSTANCE_NAME=${DS_INSTANCE_NAME} \
    DS_SUFFIX_NAME=${DS_SUFFIX_NAME} \
    DS_DM_PASSWORD=${DS_DM_PASSWORD_ARG} \
    LANG=C.UTF-8

# Gerekli paketleri kur ve cache'i temizle
# openldap: ldapadd, ldapsearch içerir
# 389-ds: dscreate, dsconf, ns-slapd içerir
# gettext: envsubst için (template doldurma)
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm 389-ds openldap gettext && \
    # Eski cache dosyalarını temizle
    rm -rf /var/cache/pacman/pkg/* && \
    # Kullanılmayan bağımlılıkları temizle (isteğe bağlı)
    pacman -Qtdq | pacman -Rns --noconfirm - || true

# Kurulum template'ini, bootstrap LDIF'ini ve entrypoint'i kopyala
COPY setup.inf.template /etc/dirsrv/setup.inf.template
COPY bootstrap.ldif /etc/dirsrv/bootstrap.ldif
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Entrypoint'i çalıştırılabilir yap
RUN chmod +x /usr/local/bin/entrypoint.sh

# LDAP (389) ve LDAPS (636) portları
EXPOSE 389 636

# Verilerin kalıcı olacağı dizinler (Arch'ta varsayılanlar farklı olabilir, kontrol et)
# Genellikle /etc/dirsrv/slapd-<instance> ve /var/lib/dirsrv/slapd-<instance>/db
VOLUME ["/etc/dirsrv/slapd-${DS_INSTANCE_NAME}", "/var/lib/dirsrv/slapd-${DS_INSTANCE_NAME}/db"]

# Konteyner başladığında entrypoint'i çalıştır
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Varsayılan komut (entrypoint ns-slapd'i başlatacak)
CMD []