# WAL-E Docker image

This docker image can be used as a backup "sidecar" container to a
TimescaleDB (or PostgreSQL) container. It can make base backups using
[WAL-E](https://github.com/wal-e/wal-e) as well as continuous WAL
archiving.  WAL-E will not backup configuration files so they need to be
handled separately.

## Functionality

The docker image contains WAL-E and a small web service that exposes
WAL-E's `wal-push`, `wal-fetch`, or `backup-push` commands via HTTP
requests. This allows a TimescaleDB container to trigger backups in
the sidecar via HTTP. Triggering happens via `GET` requests, allowing
use of, e.g., `wget`. An example request is:

```bash
wget http://localhost/wal-push/<WAL_SEGMENT_NAME> -O -
```

to trigger a WAL push.

WAL-E can be invoked directly by running the image as so:

```bash
docker run -it --rm timescale/timescale-wale wal-e <command>

```

This can be used to do base backups and restore, for instance, using a
Kubernetes init container.

## Configuration

To do backups, the TimescaleDB and the WAL-E containers need to share
`PGDATA` and `PGWAL` disk volumes so that the WAL-E sidecar container
can access the database files it needs to backup.

### TimescaleDB / PostgreSQL configuration
To enable continuous archiving for the PostgreSQL WAL, the following
modifications are necessary in `postgresql.conf`:

```
archive_command='wget <wale_container_hostname>/wal-push/%f -O -'
wal_level=replica
archive_mode=on
```

Alternatively, these options can be set on the command line. For
instance, the TimescaleDB docker image can be run as follows:

```bash
docker run -d 5432:5432 timescale/timescaledb postgres \
-carchive_command='wget <wale_container_hostname>/wal-push/%f -O -' \
-cwal_level=replica \
-carchive_mode=on
```

### Sidecar configuration
The WAL-E container is configured using the standard WAL-E environment
variables. In addition, the HTTP frontend expects the following
environment variables:

Variable | Use | Default
--- | --- | ---
WALE_LISTEN_PORT | port  | 80
PGDATA | the TimescaleDB/PostgreSQL data dir | `/var/lib/postgresql/data`
PGWAL | the TimescaleDB/PostgreSQL WAL log dir (defaults to PostgreSQL 10+ naming) | `${PGDATA}/pg_wal`


[ts-docker]: https://github.com/timescale/timescaledb-docker
