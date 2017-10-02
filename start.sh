# Env var START_MODE controls initial command 
# INITIAL - push a base backup 
# RESTORE - fetch a base backup
# CONTINOUS_BACKUP - no initial command, default

set -e

: "${PGDATA:?PGDATA must be set}"

START_MODE=${START_MODE:-CONTINOUS_BACKUP}
WALE_BIN=${WALE_BIN:-/usr/local/bin/wal-e}
WALE_INIT_LOCKFILE=$PGDATA/wale_init_lockfile
WALE_RESTORE_LABEL=${WALE_RESTORE_LABEL:-LATEST}
WALE_SIDECAR_HOSTNAME=${WALE_SIDECAR_HOSTNAME:-localhost}
WALE_LISTEN_PORT=${WALE_LISTEN_PORT:-5000}

CRON_TIMING=${CRON_TIMING:-'0 0 * * *'}

while [ ! -f $WALE_INIT_LOCKFILE ] ;
do
    sleep 1
    echo 'waiting for timescaledb startup script'
done

# Setup cron
export > /env_vars
echo "$CRON_TIMING bash -l -c '. /env_vars; /usr/src/app/backup_push.sh >> /var/log/cron.log 2>&1'" > /wal-e-backup-cron.tmp
echo "" >> /wal-e-backup-cron.tmp
crontab /wal-e-backup-cron.tmp
cron 

case $START_MODE in
    BACKUP_PUSH)
	chmod 700 "$PGDATA"

        echo "pushing base backup"
        rm $WALE_INIT_LOCKFILE

        eval backup_push.sh
        ;;
    RESTORE)
	chmod 700 "$PGDATA"
        echo "fetching base backup"        

        $WALE_BIN $WALE_RESTORE_FLAGS backup-fetch $PGDATA $WALE_RESTORE_LABEL

        echo "restore_command = '/usr/bin/wget ${WALE_SIDECAR_HOSTNAME}:${WALE_LISTEN_PORT}/fetch/%f -O -'" > $PGDATA/recovery.conf
        
        if [ ! -z $RECOVERY_ADDITION ]; then
            echo "$RECOVERY_ADDITION" >> $PGDATA/recovery.conf
        fi

        if [ ! -z $PGCONF_BACKUP_DIR ]; then
            echo "Restoring confs: $PGCONF_BACKUP_DIR/*.conf $PGDATA/ "
            cp $PGCONF_BACKUP_DIR/*.conf $PGDATA/
        else
            echo "No config files restored"
        fi
        
        ;;
    *)
        echo "starting continous backup"
        ;;
esac

rm $WALE_INIT_LOCKFILE

python ./wale-rest.py
