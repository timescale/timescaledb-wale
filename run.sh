#!/bin/sh

WALE_S3_PREFIX=${WALE_S3_PREFIX:-s3://${WALE_S3_BUCKET:-wale_bucket}/${WALE_S3_PATH:-}}

export WALE_S3_PREFIX

exec python3 wale-rest.py $@
