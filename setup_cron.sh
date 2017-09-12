#!/bin/bash

export > /env_vars
echo "$CRON_TIMING bash -l -c '. /env_vars; /usr/src/app/backup_push.sh >> /var/log/cron.log 2>&1'" > /wal-e-backup-cron.tmp
echo "" >> /wal-e-backup-cron.tmp

crontab /wal-e-backup-cron.tmp
cron 
