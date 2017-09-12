# WAL-e sidecar for timescaledb docker container.

This docker image is used as a backup sidecar container to a postgresql container. It makes periodic
backups to wal-e (https://github.com/wal-e/wal-e) supported backups as well as WAL backups.

## Configuration

### Modifications to postgresql container

The postgresql and the wal-e containers need to share PGDATA and PGWAL volumes.
Before starting the postgres instance, the postgresql needs to create a
`$PGDATA/wale_init_lockfile`. When the wal-e sidecar container
removes that file, it is safe for postgres to start.

Typical modifications to `postgresql.conf` are 

```
archive_command='/usr/bin/wget wale_container:5000/push/%f -O -'
wal_level=archive 
archive_mode=on 
archive_timeout=600 
checkpoint_timeout=700 
```

### Side car configurations
The wal-e container is configured using environment variables. First, the startup operation is controlled by
the `START_MODE` variable where the options are `CONTINOUS_BACKUP`, `INITIAL`, or `RESTORE`.

START_MODE settings |
MODE | Operation
---- | ----
INITIAL | Pushes a base backup before starting to accept archive commands 
CONTINOUS_BACKUP | starts up and accepts archive commands 
RESTORE | Fetches a backup, creates a restore.conf, and optionally restores configuration files 

The backup and restore operation can be further configured through the following variables.

Variable | use | default
--- | --- | ---
WALE_RESTORE_LABEL | label of backup to pull when restoring | LATEST 
WALE_SIDECAR_HOSTNAME | hostname where the side car can be reached | localhost
WALE_LISTEN_PORT | port  | 5000 
CRON_TIMING | Cron string for periodic backups | '0 0 * * *' (24h)
RECOVERY_ADDITION | line to add to recovery.conf, typically restore timestamp | -
PGCONF_BACKUP_DIR | directory holding configuration files to restore after data dir restore | -
