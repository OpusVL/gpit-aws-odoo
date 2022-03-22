#!/bin/bash

AUTHOR="Paul Baregewell <paul.bargewell@opusvl.com>"
COPYRIGHT="Copyright 2021, Opus Vision Limited T/A OpusVL"
LICENSE="SPDX-License-Identifier: AGPL-3.0-or-later"

SCRIPT_PATH=$(dirname "$0")
cd "${SCRIPT_PATH}" || exit

source .env

DESTINATION=/srv/databasedumps
TIMESLOT=$(date '+%Y%m%d%H%M')

PGPASSWORD="${ODOO_POSTGRES_PASSWORD}" pg_dump -h "${DB_HOST}" -U odoo -d "${ODOO_DATABASE}" | gzip > "${DESTINATION}/${ODOO_DATABASE}_${TIMESLOT}.sql.gz"

find "${DESTINATION}" -maxdepth 1 -type f -mtime +31 -exec rm {} \;

rsync -av "${CONTAINER_VOLUME}/invoicing/odoo/filestore/${ODOO_DATABASE}" "${DESTINATION}/filestore"