#!/bin/bash

echo "Grant sentry access from all IPs."
echo "host all sentry  0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf

echo "Create a user and database."
gosu postgres postgres --single <<- EOSQL
    CREATE USER sentry;
    CREATE DATABASE sentry;
    GRANT ALL PRIVILEGES ON DATABASE sentry TO sentry;
    ALTER USER sentry CREATEDB;
EOSQL

echo "Done initializing."
