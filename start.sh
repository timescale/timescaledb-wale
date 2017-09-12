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
WALE_HOSTNAME=${WALE_HOSTNAME:-localhost}
WALE_PORT=${WALE_PORT:-5000}
REVOCERY_ADDITION=${RECOVERY_ADDITION:-""}

while [ ! -f $WALE_INIT_LOCKFILE ] ;
do
    sleep 1
    echo 'waiting for timescaledb startup script startup'
done

case $START_MODE in
    INITIAL)
        mkdir -p "$PGDATA"
	chmod 700 "$PGDATA"

        echo "pushing base backup"
        rm $WALE_INIT_LOCKFILE

        eval backup_push.sh
        ;;
    RESTORE)
        mkdir -p "$PGDATA"
	chmod 700 "$PGDATA"
        echo "fetching base backup"        

        $WALE_BIN $WALE_RESTORE_FLAGS backup-fetch $PGDATA $WALE_RESTORE_LABEL

        echo "restore_command = '/usr/bin/wget ${WALE_HOSTNAME}:${WALE_PORT}/fetch/%f -O -'" > $PGDATA/recovery.conf
        
        if [ -z $RECOVERY_ADDITION ]; then
            echo "$RECOVERY_ADDITION" >> $PGDATA/recovery.conf
        fi
        
        ;;
    *)
        echo "starting continous backup"
        ;;
esac

rm $WALE_INIT_LOCKFILE

python ./wale-rest.py
