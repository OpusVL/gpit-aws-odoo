#!/bin/bash

AUTHOR="Paul Baregewell <paul.bargewell@opusvl.com>"
COPYRIGHT="Copyright 2021, Opus Vision Limited T/A OpusVL"
LICENSE="SPDX-License-Identifier: AGPL-3.0-or-later"

SCRIPT_PATH=$(dirname "$0")
cd "${SCRIPT_PATH}" || exit

set -x

source .env

TIMESLOT=$(date '+%Y%m%d%H%M')

PGPASSWORD=${ODOO_POSTGRES_PASSWORD} pg_dump -h ${DB_HOST} -U odoo -d ${ODOO_DATABASE} | gzip > /srv/databasedumps/${ODOO_DATABASE}_${TIMESLOT}.sql.gz
sudo git pull
docker-compose pull
docker-compose down

python3 ./maintenance.py &
PID=$!

docker-compose run --rm odoo -d ${ODOO_DATABASE} -u ${ODOO_MODULES:-billing,op_import_data} --stop-after-init

PGPASSWORD=${ODOO_POSTGRES_PASSWORD} psql -h ${DB_HOST} -U postgres -d ${ODOO_DATABASE} -c "DELETE FROM ir_attachment WHERE url LIKE '/web/content/%';"

if [ -n "${PID}" ]; then
    kill -s HUP ${PID}
fi

docker-compose up -d
