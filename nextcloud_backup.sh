#!/bin/sh
# vim:set syntax=sh:
# kate: syntax bash;
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright 2021 Jakob Meng, <jakobmeng@web.de>
exit # do not run any commands when file is executed
#
# Nextcloud/ownCloud Backups
#

apt-get install rsync

MYSQL_USER=sql_backup_user # no longer than 16 chars
MYSQL_PASS=... # Generate e.g. with: openssl rand -base64 15

cat << EOF >> /root/.my.cnf
[mysqldump]
user=$MYSQL_USER
password=$MYSQL_PASS
EOF

chmod 600 /root/.my.cnf

# Create mysql backup user
# Ref.:
#  http://bencane.com/2011/12/12/creating-a-read-only-backup-user-for-mysqldump/
#  https://www.fromdual.com/de/node/483

mysql -uroot -p -e "GRANT LOCK TABLES, SELECT ON *.* TO '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS'; flush privileges;"

cat << 'EOF' > /etc/cron.daily/owncloud_backup
#!/bin/sh
# 2016-2019 Jakob Meng, <jakobmeng@web.de>
# 2018 Martin Schenk, <martin.schenk@h-brs.de>
# Do a complete ownCloud/Nextcloud backup incl. its database, configuration and files

set -e

DB_NAME=ocdb
MYSQL_USER=sql_backup_user
OWNCLOUD_ROOT_PATH=/var/www/owncloud/
OWNCLOUD_DATA_PATH=/var/oc_data/
BACKUP_PATH=/var/backups/owncloud/
BACKUP_PREFIX=owncloud
KEEP_FOR_DAYS=30 # delete backups after x days
INCREMENTAL=yes
VERBOSE=no

if [ -f /etc/default/owncloud_backup ]; then
    . /etc/default/owncloud_backup
fi

[ ! -e "${OWNCLOUD_ROOT_PATH}/version.php" ] && {
    echo "ownCloud / Nextcloud has been removed, no upgrade required." >&2
    exit 0
}

if [ -z "$DB_NAME" ]           || [ -z "$MYSQL_USER" ] || \
  [ -z "$OWNCLOUD_ROOT_PATH" ] || [ -z "$OWNCLOUD_DATA_PATH" ] || \
  [ -z "$BACKUP_PATH" ]        || [ -z "$BACKUP_PREFIX" ] || \
  [ -z "$KEEP_FOR_DAYS" ]      || [ -z "$INCREMENTAL" ] || \
  [ -z "$VERBOSE" ]; then
    echo "Missing arguments." >&2
    exit 255
fi

[ ! -e "${BACKUP_PATH}" ] && mkdir "${BACKUP_PATH}"

REAL_OC_ROOT_PATH="$(readlink -f "${OWNCLOUD_ROOT_PATH}")"
REAL_OC_DATA_PATH="$(readlink -f "${OWNCLOUD_DATA_PATH}")"

OC_ROOT_IS_PARENT=$(case "${REAL_OC_DATA_PATH}" in "${REAL_OC_ROOT_PATH}"*) echo 'yes';; *) echo 'no';; esac)
OC_DATA_IS_PARENT=$(case "${REAL_OC_ROOT_PATH}" in "${REAL_OC_DATA_PATH}"*) echo 'yes';; *) echo 'no';; esac)

make_dir() {
    local _name="$1"
    
    mkdir "$_name" >/dev/null 2>&1 && {
        echo "$_name"
        return 0
    }
    
    local _i=0
    
    while true; do
        _i=$(expr $_i + 1)
        local _test="${_name}_${_i}"
        mkdir "$_test" >/dev/null 2>&1 || continue
        echo "$_test"
        break
    done
}

if [ "${OC_DATA_IS_PARENT}" != 'yes' ]; then
    set +e # workaround for https://stackoverflow.com/a/19789651/6490710
    (
        set -e
        
        ROOT_BACKUP_PATH="$(make_dir "${BACKUP_PATH}/${BACKUP_PREFIX}-root-dirbkp_$(date +%Y%m%d%H%M%S)")"
        ROOT_LAST_BACKUP_PATH="${BACKUP_PATH}/${BACKUP_PREFIX}-root-dirbkp_latest"
        
        [ "$VERBOSE" = 'no' ] || echo "Doing ownCloud / Nextcloud root backup to $ROOT_BACKUP_PATH"
        
        if [ "$INCREMENTAL" != 'yes' ] || [ ! -e "${ROOT_LAST_BACKUP_PATH}" ]; then
            rsync -Aax "${OWNCLOUD_ROOT_PATH}/" "${ROOT_BACKUP_PATH}/"
        else
            rsync -Aax "${OWNCLOUD_ROOT_PATH}/" "${ROOT_BACKUP_PATH}/" --link-dest="${ROOT_LAST_BACKUP_PATH}"
        fi
        ln -nsf "${ROOT_BACKUP_PATH}" "${ROOT_LAST_BACKUP_PATH}"
        touch "${ROOT_BACKUP_PATH}"
    )
    errc=$?
    set -e
    [ $errc -ne 0 ] && {
        echo "ownCloud / Nextcloud root backup to '$ROOT_BACKUP_PATH' failed with return code $?" >&2
        exit 255
    }
fi

if [ "${OC_ROOT_IS_PARENT}" != 'yes' ]; then
    set +e # workaround for https://stackoverflow.com/a/19789651/6490710
    (
        set -e
        
        DATA_BACKUP_PATH="$(make_dir "${BACKUP_PATH}/${BACKUP_PREFIX}-data-dirbkp_$(date +%Y%m%d%H%M%S)")"
        DATA_LAST_BACKUP_PATH="${BACKUP_PATH}/${BACKUP_PREFIX}-data-dirbkp_latest"
        
        [ "$VERBOSE" = 'no' ] || echo "Doing ownCloud / Nextcloud data backup to $DATA_BACKUP_PATH"
        
        if [ "$INCREMENTAL" != 'yes' ] || [ ! -e "${DATA_LAST_BACKUP_PATH}" ]; then
            rsync -Aax "${OWNCLOUD_DATA_PATH}/" "${DATA_BACKUP_PATH}/"
        else
            rsync -Aax "${OWNCLOUD_DATA_PATH}/" "${DATA_BACKUP_PATH}/" --link-dest="${DATA_LAST_BACKUP_PATH}"
        fi
        ln -nsf "${DATA_BACKUP_PATH}" "${DATA_LAST_BACKUP_PATH}"
        touch "${DATA_BACKUP_PATH}"
    )
    errc=$?
    set -e
    [ $errc -ne 0 ] && {
        echo "ownCloud / Nextcloud data backup to '$DATA_BACKUP_PATH' failed with return code $?" >&2
        exit 255
    }
fi

DB_BACKUP_PATH="$(make_dir "${BACKUP_PATH}/${BACKUP_PREFIX}-sqlbkp_$(date +%Y%m%d%H%M%S)")"
[ "$VERBOSE" = 'no' ] || echo "Doing ownCloud / Nextcloud database backup to $DB_BACKUP_PATH"
mysqldump --lock-tables -h localhost -u "${MYSQL_USER}" "${DB_NAME}" \
  > "${DB_BACKUP_PATH}/${DB_NAME}.sql" || {
  echo "ownCloud / Nextcloud database backup to '$DB_BACKUP_PATH'failed with return code $?" >&2
  exit 255
}

[ "$VERBOSE" = 'no' ] || echo "Removing old ownCloud / Nextcloud backups"
cd "${BACKUP_PATH}" && [ "${KEEP_FOR_DAYS}" != '' ] && \
  find -maxdepth 1 -mtime +"${KEEP_FOR_DAYS}" -iname "${BACKUP_PREFIX}*" -exec rm -r $([ "$VERBOSE" = 'no' ] || echo "-v") '{}' \; || {
    echo "Removal of old ownCloud / Nextcloud backups failed with return code $?" >&2
}

EOF

chmod a+x /etc/cron.daily/owncloud_backup

# Nextcloud backup configuration
cat << 'EOF' > /etc/default/owncloud_backup
OWNCLOUD_ROOT_PATH=/var/www/nextcloud/
BACKUP_PATH=/var/backups/nextcloud/
BACKUP_PREFIX=nextcloud
EOF


# NOTE: owncloud_upgrade is only required when doing unattended upgrades, it will help
#       to keep ownCloud's downtime due to maintenance mode after upgrades minimal.

cat << 'EOF' > /usr/local/bin/owncloud_upgrade
#!/bin/sh
# 2016 Jakob Meng, <jakobmeng@web.de>
# Upgrade ownCloud after package upgrade

HTTP_USER=www-data
OWNCLOUD_PATH=/var/www/owncloud/
OWNCLOUD_CACHE_PATH=/var/cache/owncloud/

if [ -f /etc/default/owncloud_upgrade ]; then
    . /etc/default/owncloud_upgrade
fi

[ ! -e "${OWNCLOUD_PATH}/version.php" ] && { 
    echo "ownCloud has been removed, no upgrade required." >&2
    exit 0
}

which sudo >/dev/null && CH_USER_CMD=sudo || \
  { which su >/dev/null && CH_USER_CMD=su; } || {
    echo "You need either 'sudo' or 'su' for this script" >&2
    exit 255
}

[ ! -e "${OWNCLOUD_CACHE_PATH}" ] && {
    mkdir -p "${OWNCLOUD_CACHE_PATH}" || {
        echo "ownCloud cache ${OWNCLOUD_CACHE_PATH} could not be created." >&2
        exit 255
    }
}

[ ! -e "${OWNCLOUD_CACHE_PATH}/version.php.last" ] && \
  cp -a "${OWNCLOUD_PATH}/version.php" "${OWNCLOUD_CACHE_PATH}/version.php.last"

cmp --silent "${OWNCLOUD_CACHE_PATH}/version.php.last" "${OWNCLOUD_PATH}/version.php" || {
    /etc/cron.daily/owncloud_backup || {
        echo "Aborting ownCloud upgrade because backup failed" >&2
        exit 255
    }
    
    cd "${OWNCLOUD_PATH}"
    
    if [ "${CH_USER_CMD}" = 'sudo' ]; then
        sudo -u "${HTTP_USER}" php occ upgrade && \
          sudo -u "${HTTP_USER}" php occ maintenance:mode --off
    else
        su -s /bin/sh -c 'php occ upgrade' "${HTTP_USER}" && \
          su -s /bin/sh -c 'php occ maintenance:mode --off' "${HTTP_USER}"
    fi
    
    cp -a "${OWNCLOUD_PATH}/version.php" "${OWNCLOUD_CACHE_PATH}/version.php.last"
}

EOF

chmod a+x /usr/local/bin/owncloud_upgrade

cat << 'EOF' > /etc/apt/apt.conf.d/55owncloud_upgrade
// 2016 Jakob Meng, <jakobmeng@web.de>
// Upgrade ownCloud after package upgrade

DPkg {
    Post-Invoke { /usr/local/bin/owncloud_upgrade; };
};
EOF

exit # the end
