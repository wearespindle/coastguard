# coastguard

This repository provides a docker-compose setup for Sentry behind nginx with peripherals installed.\
It was made to provide a ready to use installation of [Sentry](https://getsentry.com) behind a nginx reverse proxy and with a mailserver and PostgreSQL and Redis in place.

## Installation

### Clone the repo

Clone the repo from git into a directory named "sentry":

`git clone git@github.com:wearespindle/coastguard.git sentry`

### Install SSL certificates

Put your certificate and key in:

* `Dockers/nginx/mycert.pem`
* `Dockers/nginx/mykey.key`

If you do not need an SSL-terminating reverse proxy inside Docker-containers, replace `Dockers/nginx/nginx.conf` with `Dockers/nginx/nginx-noSSL.conf`.

### Change config

All variables you need to change are in `docker-compose.yml`. You need to change at least:

* `SENTRY_SECRET_KEY`
* `SENTRY_SERVER_EMAIL` (where emails send by Sentry will appear to originaly come from.)
* `SENTRY_ADMIN_EMAIL`
* `SENTRY_URL_PREFIX`

### Start the containers

Steps to take on a new setup.

Build the custom container images for nginx, PostgreSQL and Sentry:

```bash
docker-compose build
```

First you will need to initialize the database, so start the PostgreSQL-container:

```bash
docker-compose up -d postgres
```

Wait app. 8 seconds and then run:

```bash
docker-compose run --rm web upgrade
```

**NOTE:** Ignore these errors when running the upgrade for the first time:

```txt
Creating sentry_redis_1    ... done
Creating sentry_postfix_1  ... done
Starting sentry_postgres_1 ... done
Traceback (most recent call last):
  File "/usr/local/lib/python2.7/site-packages/sentry/options/store.py", line 165, in get_store
    value = self.model.objects.get(key=key.name).value
  File "/usr/local/lib/python2.7/site-packages/django/db/models/manager.py", line 151, in get
    return self.get_queryset().get(*args, **kwargs)
  File "/usr/local/lib/python2.7/site-packages/django/db/models/query.py", line 304, in get
    num = len(clone)
...
```

Finish by starting the rest of the stack:

```bash
docker-compose up -d
```

You can now connect with a browser to the FQDN of the instance (or `localhost` when testing on Docker) and you're in business!

## Update / upgrade

These backup / restore steps where taken to update Sentry from v8.12 to v8.22.

### Backup

To create a dump of the database, run this command on the instance that is running the Sentry version to upgrade:

`docker exec sentry_postgres_1 pg_dump -U postgres postgres > postgres-dump`

### Restore

* Copy the dumpfile to the new instance (if needed).
* On the new instance, start a new PostgreSQL container: `docker-compose up -d postgres`.
* Then import the dump create in the step above: `docker exec -i sentry_postgres_1 psql -U postgres -d postgres < postgres-dump`. Answer **NO** to this question:

```txt
Any objects related to these content types by a foreign key will also
be deleted. Are you sure you want to delete these content types?
If you're unsure, answer 'no'.

    Type 'yes' to continue, or 'no' to cancel: no
```

* Run the upgrade: `docker-compose run --rm web upgrade`.
* Start the rest of the stack: `docker-compose up -d`.

---
