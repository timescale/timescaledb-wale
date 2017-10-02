# WAL-e sidecar for timescaledb docker container.

This docker image is used as a backup sidecar container to a postgresql container. It makes periodic
backups to wal-e (https://github.com/wal-e/wal-e) supported backups as well as WAL backups. Wal-e
will not backup configuration files so they need to be stores separately. If they are stored where the
wal-e sidecar container can reach them, they can be restored during the wal-e restore process using the
environment variable PGCONF_BACKUP_DIR. 

## Configuration

### Modifications to postgresql container

The postgresql and the wal-e containers need to share PGDATA and PGWAL volumes.
Before starting the postgres instance, the postgresql needs to create a
`$PGDATA/wale_init_lockfile`. When the wal-e sidecar container
removes that file, it is safe for postgres to start.

Typical modifications to `postgresql.conf` are 

```
archive_command='/usr/bin/wget wale_container_hostname:5000/wal-push/%f -O -'
wal_level=archive 
archive_mode=on 
archive_timeout=600 
checkpoint_timeout=700 
```

### Side car configurations
The wal-e container is configured using environment variables. First, the startup operation is controlled by
the `START_MODE` variable where the options are `CONTINOUS_BACKUP`, `BACKUP_PUSH`, or `RESTORE`.

MODE | Operation
---- | ----
BACKUP_PUSH | Pushes a base backup before starting to accept archive commands
CONTINOUS_BACKUP | starts up and accepts archive commands
RESTORE | Fetches a backup, creates a restore.conf, and optionally restores configuration files 

The backup and restore operation can be further configured through the following variables.

Variable | Use | Default
--- | --- | ---
WALE_RESTORE_LABEL | label of backup to pull when restoring | LATEST 
WALE_SIDECAR_HOSTNAME | hostname where the side car can be reached | localhost
WALE_LISTEN_PORT | port  | 5000 
CRON_TIMING | Cron string for periodic backups | "0 0 \* \* \*" (24h)
RECOVERY_ADDITION | line to add to recovery.conf, typically timestamp for PIT recovery | -
PGCONF_BACKUP_DIR | directory path holding configuration files to restore after data dir restore | -
PGDATA | path to mounted postgres data dir | -


### Running Wal-e commands
The wal-e container can be used to run arbitrary wal-e commands. For example, to list the stored backups
you can run
```
docker exec wale_container_name wal-e backup-list
```