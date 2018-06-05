#!/bin/bash

echo "Grant sentry access from all IPs."
echo "host all sentry  0.0.0.0/0 trust" >> /var/lib/postgresql/data/pg_hba.conf

echo "Done initializing."
