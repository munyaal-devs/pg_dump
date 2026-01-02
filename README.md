This image used to backup a postgres database to an S3 bucket.

## Build

```shell
docker build -t pg-backup:latest .
```

## Backup

```shell
docker run \
-e PGHOST=PGHOST \
-e PGPORT=PGPORT \
-e PGUSER=PGUSER \
-e PGPASSWORD=PGPASSWORD \
-e PGDATABASE=PGDATABASE \
-e AWS_ACCESS_KEY_ID=AWS_ACCESS_KEY_ID \
-e AWS_SECRET_ACCESS_KEY=AWS_SECRET_ACCESS_KEY \
-e AWS_DEFAULT_REGION=AWS_DEFAULT_REGION \
-e AWS_S3_BUCKET=AWS_S3_BUCKET \
pg-backup:latest
```
