# Upgrade Sentry from v8.22 to v9.0

This is an overview of how an upgrade from Sentry version 8.22 to version 9.0 **might** work.

Sentry v8.22 was installed from the repo `wearespindle/coastguard.git`, installed in `/srv/sentry`:

`git clone git@github.com:wearespindle/coastguard.git sentry`

We used Vagrant and a Vagrantbox `debian/contrib-stretch64` to setup a VM to test this upgrade.

## Upgrade steps

If already running, stop Sentry and check if there are no more containers running:

```txt
cd /srv/sentry/
service sentry stop
docker ps -a
```

The mentioned service command for Sentry is the file `sentry-service` copied to `/etc/init.d/sentry` and enabled with `update-rc.d sentry defaults`.

Import a recent dump from the production Sentry VM:

```txt
docker-compose up -d postgres
docker exec -i sentry_postgres_1 psql -U postgres -d postgres < /home/vagrant/postgres-dump_20190313
service sentry start
docker-compose ps
```

Log in to the 8.22 version of Sentry and if so, click a bit around.

Now the upgrade to v9.0 can start.

Here we upgraded from a feature branch in GitHub, called `feature/upgrade-sentry-INFRA-1382`. This will have the code in place for the upgrade, under `Dockers/sentry/`. The Dockerfile for the `9.0-onbuild` image, `sentry-plugins` and a new `sentry.conf.py`.

```txt
git pull --rebase
git checkout feature/upgrade-sentry-INFRA-1382
service sentry stop
```

> :warning: **NOTE**\
> Dont' forget to delete the old Sentry Docker images **and** containers!!

Delete the old `sentry_*` containers:

```console
root@vagrant-stretch64:/srv/sentry# docker ps -a

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                     PORTS               NAMES
6b7f26e24446        postgres:9.5        "docker-entrypoint..."   28 minutes ago      Exited (0) 4 seconds ago                       sentry_postgres_1
b0bc29569773        a869f98ea1c7        "/entrypoint.sh ru..."   32 minutes ago      Exited (0) 6 seconds ago                       sentry_cron_1
366b26320fe8        a869f98ea1c7        "/entrypoint.sh ru..."   32 minutes ago      Exited (0) 4 seconds ago                       sentry_worker_1
04ced0fce675        a869f98ea1c7        "/entrypoint.sh ru..."   32 minutes ago      Exited (0) 5 seconds ago                       sentry_web_1
539c8963ee72        a869f98ea1c7        "/entrypoint.sh ru..."   32 minutes ago      Exited (0) 5 seconds ago                       sentry_base_1
0b35a8318a67        redis:3.2-alpine    "docker-entrypoint..."   32 minutes ago      Exited (0) 4 seconds ago                       sentry_redis_1
36f63d11583a        panubo/postfix      "/entry.sh /usr/bi..."   32 minutes ago      Exited (0) 4 seconds ago                       sentry_postfix_1

root@vagrant-stretch64:/srv/sentry# docker rm b0bc29569773 366b26320fe8 04ced0fce675 539c8963ee72
```

Delete the old `sentry_*` image with ID `a869f98ea1c7` from which the old containers ran from:

```console
root@vagrant-stretch64:/srv/sentry# docker images

REPOSITORY          TAG                 IMAGE ID            CREATED              SIZE
sentry_base         latest              a869f98ea1c7        About a minute ago   546MB
sentry_cron         latest              a869f98ea1c7        About a minute ago   546MB
sentry_web          latest              a869f98ea1c7        About a minute ago   546MB
sentry_worker       latest              a869f98ea1c7        About a minute ago   546MB
postgres            9.5                 885382ee3e93        8 days ago           227MB
sentry              9.0-onbuild         0445f07abe89        2 weeks ago          609MB
panubo/postfix      latest              2d2a36c8ef20        3 weeks ago          207MB
sentry              8.22-onbuild        b311b97d279e        6 weeks ago          546MB
redis               3.2-alpine          6e94a98d3442        5 months ago         22.9MB

root@vagrant-stretch64:/srv/sentry# docker rmi --force a869f98ea1c7
```

Once the old containers and images are deleted, we will pull the **new** Sentry Docker image, build the sentry_base, -cron, -web and -worker images and do the upgrade:

```txt
docker pull sentry:9.0-onbuild
docker-compose -f /srv/sentry/docker-compose.yml -f /srv/sentry/docker-compose.override.yml build
docker-compose -f /srv/sentry/docker-compose.yml -f /srv/sentry/docker-compose.override.yml run --rm web upgrade
```

The `upgrade` command (answer "yes" to *The following content types are stale and need to be deleted*) gave the following output:

```console
root@vagrant-stretch64:/srv/sentry# docker-compose -f /srv/sentry/docker-compose.yml -f /srv/sentry/docker-compose.override.yml run --rm web upgrade

Starting sentry_postfix_1  ... done
Starting sentry_postgres_1 ... done
Starting sentry_redis_1    ... done
10:41:27 [INFO] sentry.plugins.github: apps-not-configured
Syncing...
Creating tables ...
Installing custom SQL ...
Installing indexes ...
Installed 0 object(s) from 0 fixture(s)

Synced:
 > django.contrib.admin
 > django.contrib.auth
 > django.contrib.contenttypes
 > django.contrib.messages
 > django.contrib.sessions
 > django.contrib.sites
 > django.contrib.staticfiles
 > crispy_forms
 > debug_toolbar
 > raven.contrib.django.raven_compat
 > rest_framework
 > sentry.plugins.sentry_interface_types
 > sentry.plugins.sentry_mail
 > sentry.plugins.sentry_urls
 > sentry.plugins.sentry_useragents
 > sentry.plugins.sentry_webhooks
 > sudo
 > south
 > sentry_plugins.slack

Not synced (use migrations):
 - sentry
 - sentry.nodestore
 - sentry.search
 - social_auth
 - sentry.tagstore
 - sentry_plugins.jira_ac
 - sentry_plugins.hipchat_ac
(use ./manage.py migrate to migrate these)
Running migrations for sentry:
 - Migrating forwards to 0423_auto__add_index_grouphashtombstone_deleted_at.
 > sentry:0365_auto__del_index_eventtag_project_id_key_id_value_id
 > sentry:0366_backfill_first_project_heroku
Organizations: 100% |#################### // ####################| Time: 0:00:00
 > sentry:0367_auto__chg_field_release_ref__chg_field_release_version

--- cut --- 8< ---

 > sentry:0423_auto__add_index_grouphashtombstone_deleted_at
The following content types are stale and need to be deleted:

    sentry | useridentity
    sentry | minidumpfile

Any objects related to these content types by a foreign key will also
be deleted. Are you sure you want to delete these content types?
If you're unsure, answer 'no'.

    Type 'yes' to continue, or 'no' to cancel: yes
 - Loading initial data for sentry.
Installed 0 object(s) from 0 fixture(s)
Running migrations for nodestore:
- Nothing to migrate.

--- cut --- 8< ---
```

Now you can (re)start the Sentry Docker stack:

```txt
service sentry start
```

Clear the Sentry related cookies from the browser and login again.

You should now see the new `Sentry 9.0.0` web interface.

---

Updated: 20190313
