#!/bin/bash

WALE_BIN=${WALE_BIN:-/usr/local/bin/wal-e}


set +e
while true; do
    sleep 1

    pg_isready

    if [[ $? == 0 ]] ; then
        break
    fi

done
set -e

$WALE_BIN $WALE_BASE_BACKUP_FLAGS backup-push $PGDATA
