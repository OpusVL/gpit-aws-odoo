#!/bin/bash

AUTHOR="Paul Bargewell <paul.bargewell@opusvl.com>"
COPYRIGHT="Copyright 2021, Opus Vision Limited T/A OpusVL"
LICENSE="SPDX-License-Identifier: AGPL-3.0-or-later"

SCRIPT_PATH=$(dirname "$0")
cd "${SCRIPT_PATH}" || exit

if [ -f ".env" ]; then

    source .env

    function render_template() {
        eval "echo \"$(cat $1)\""
    }

    # Create the odoo user in postgres
    PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${DB_HOST} -U postgres -c "CREATE USER odoo WITH ENCRYPTED PASSWORD '${ODOO_POSTGRES_PASSWORD}' CREATEDB;"

    # PAss env variables into odoo.conf
    render_template odoo/etc/odoo.conf.tpl > odoo/etc/odoo.conf

    # Set the required odoo permissions
    docker-compose run --rm -u root odoo chown odoo: /var/lib/odoo /mnt/extra-addons

    # Fix the cipher issue with NHSD email
    RESULT=$(grep -i '\[default_conf\]' /etc/ssl/openssl.cnf)

    if [ -z "${RESULT}" ]; then
        cp /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf.bak
        echo "
[default_conf]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1.2
CipherString = DEFAULT@SECLEVEL=1
" >> /etc/ssl/openssl.cnf
    fi

    # Add cron jobs for icinga2 and backup
    CRONJOBS=$(crontab -l)
    RESULT=$(echo "${CRONJOBS}" | grep -i 'icinga-passive.sh')

    if [ -z "${RESULT}" ]; then
        echo "${CRONJOBS}
*/5 * * * * /srv/container-deployment/invoicing/icinga2/icinga-passive.sh 2>&1
0 2 * * * /srv/container-deployment/invoicing/backup.sh 2>&1
" | crontab
    fi

    cd icinga2 || exit 1
    ln -s ../.env .env
    cd ..
    
fi

