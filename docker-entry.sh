#!/bin/bash

set -e

DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-biblioteca}
KOHA_INSTANCE=${KOHA_INSTANCE:-biblioteca}
KOHA_DB_USER="koha_${KOHA_INSTANCE}"
KOHA_DB_PASSWORD=${KOHA_DB_PASSWORD:-koha_password}
KOHA_DB_NAME="koha_${KOHA_INSTANCE}"
KOHA_DOMAIN=${KOHA_DOMAIN:-koha.farusac.edu.gt}

echo "=========================================="
echo "Iniciando Koha..."
echo "=========================================="

echo "Esperando a que MariaDB esté disponible en ${DB_HOST}:${DB_PORT}..."
until nc -z ${DB_HOST} ${DB_PORT}; do
    echo "MariaDB no está listo aún. Reintentando en 3 segundos..."
    sleep 3
done
echo "¡MariaDB está listo!"

sleep 5

if [ ! -f "/etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml" ]; then
    mysql -h ${DB_HOST} -P ${DB_PORT} -u root -p ${DB_ROOT_PASSWORD} <<-EOSQL
    CREATE DATABASE IF NOT EXISTS ${KOHA_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS '${KOHA_DB_USER}'@'%' IDENTIFIED BY '${KOHA_DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON ${KOHA_DB_NAME}.* TO '${KOHA_DB_USER}'@'%';
        FLUSH PRIVILEGES;
EOSQL

    if [ $! -eq 0]; then
        echo "Base de datos y usuario creados exitosamente."
    else
        echo "Error al crear la base de datos o el usuario."
        exit 1
    fi

    cat > /etc/koha/koha-sites.conf <<EOF
DOMAIN="${KOHA_DOMAIN}"
INTRAPORT="8080"
INTRAPREFIX=""
INTRASUFFIX="-intra"
DEFAULTSQL=""
OPACPORT="80"
OPACPREFIX=""
OPACSUFFIX=""
ZEBRA_MARC_FORMAT="marc21"
ZEBRA_LANGUAGE="es"
ADMINUSER="koha"
PASSWDFILE="/etc/koha/passwd"
MEMCACHED_SERVERS=""
MEMCACHED_PREFIX=""
RUN_DATABASE_TESTS="no"
DB_TYPE="mysql"
DB_HOST="${DB_HOST}"
DB_PORT="${DB_PORT}"
DB_NAME="${KOHA_DB_NAME}"
DB_USER="${KOHA_DB_USER}"
DB_PASS="${KOHA_DB_PASSWORD}"
DB_USE_TLS="no"
EOF

    echo "Creando instancia de Koha..."
    koha-create --request-db ${DB_HOST}:${DB_PORT}:${KOHA_DB_NAME}:${KOHA_DB_USER}:${KOHA_DB_PASSWORD} \
                --no-database \
                ${KOHA_INSTANCE}

    if [ -f "/etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml" ]; then
        sed -i "s/<hostname>.*<\/hostname>/<hostname>${DB_HOST}<\/hostname>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
        sed -i "s/<port>.*<\/port>/<port>${DB_PORT}<\/port>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
        sed -i "s/<database>.*<\/database>/<database>${KOHA_DB_NAME}<\/database>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
        sed -i "s/<user>.*<\/user>/<user>${KOHA_DB_USER}<\/user>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
        sed -i "s/<pass>.*<\/pass>/<pass>${KOHA_DB_PASSWORD}<\/pass>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
    fi

    a2ensite ${KOHA_INSTANCE}

    WEB_INSTALLER_PASS=$(xmlstarlet sel -t -v 'yazgfs/config/pass' /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml 2>/dev/null || koha-passwd ${KOHA_INSTANCE} | tail -1)
    echo "Credenciales para el instalador web de koha Usuario: koha_${KOHA_INSTANCE} Contraseña: ${WEB_INSTALLER_PASS}"

else
    echo "La instancia de Koha ya está configurada."
    if [ -f "/etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml" ]; then
        sed -i "s/<hostname>.*<\/hostname>/<hostname>${DB_HOST}<\/hostname>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
        sed -i "s/<port>.*<\/port>/<port>${DB_PORT}<\/port>/" /etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml
    fi
fi

if [ -d '/usr/share/koha/misc/translator' ]; then
    cd /usr/share/koha/misc/translator

    ./translate  install es-MX || echo "Advertencia: No se pudo instalar la traducción"

fi

koha-plack --enable ${KOHA_INSTANCE} || true
koha-plack --start ${KOHA_INSTANCE} || true


koha-zebra --start ${KOHA_INSTANCE} || true

service apache2 restart

exec "$@"