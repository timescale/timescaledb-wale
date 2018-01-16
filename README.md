# WAL-E sidecar for TimescaleDB

This docker image can be used as a backup "sidecar" container to a
TimescaleDB container. It makes periodic
backups using WAL-E (https://github.com/wal-e/wal-e) as well as WAL
backups.  WAL-E will not backup configuration files so they need to be
stored separately. If they are stored where the
WAL-E sidecar container can reach them, they can be restored during the
WAL-E restore process using the environment variable `PGCONF_BACKUP_DIR`.

## Configuration

### Modifications to TimescaleDB container

The TimescaleDB and the WAL-E containers need to share `PGDATA` and
`PGWAL` disk volumes. Before starting the TimescaleDB instance,
the TimescaleDB container needs to create a
`$PGDATA/wale_init_lockfile` (our [official Docker release][ts-docker]
supports this). When the WAL-E sidecar container
removes that file, it is safe for TimescaleDB to start.

Typical modifications to `postgresql.conf` are

```
archive_command='/usr/bin/wget wale_container_hostname:5000/wal-push/%f -O -'
wal_level=archive
archive_mode=on
archive_timeout=600
checkpoint_timeout=700
```

### Sidecar configurations
The WAL-E container is configured using environment variables.
First, the startup operation is controlled by
the `START_MODE` variable where the options are `CONTINOUS_BACKUP`, `BACKUP_PUSH`, or `RESTORE`.

MODE | Operation
---- | ----
BACKUP_PUSH | Pushes a base backup before starting to accept archive commands
CONTINOUS_BACKUP | Starts up and accepts archive commands
RESTORE | Fetches a backup, creates a restore.conf, and optionally restores configuration files

The backup and restore operation can be further configured through the following variables.

Variable | Use | Default
--- | --- | ---
WALE_RESTORE_LABEL | label of backup to pull when restoring | LATEST
WALE_SIDECAR_HOSTNAME | hostname where the sidecar can be reached | localhost
WALE_LISTEN_PORT | port  | 5000
WALE_INIT_LOCKFILE | path to lock file | `${PGDATA}/wale_init_lockfile`
CRON_TIMING | Cron string for periodic backups | "0 0 \* \* \*" (24h)
RECOVERY_ADDITION | line to add to recovery.conf, typically timestamp for PIT recovery | -
PGCONF_BACKUP_DIR | directory path holding configuration files to restore after data dir restore | -
PGDATA | the TimescaleDB/PostgreSQL data dir | `/var/lib/postgresql/data`
PGWAL | the TimescaleDB/PostgreSQL WAL log dir | `${PGDATA}/pg_wal`

### Running WAL-E commands
The WAL-E container can be used to run arbitrary WAL-E commands using
the `wal-e` binary. For example, to list the stored backups
you can run
```
docker exec <wale_container_name> wal-e backup-list
```

[ts-docker]: https://github.com/timescale/timescaledb-docker
