# coastguard
This provides a docker-compose setup for sentry behind nginx with peripheals installed.
I made this to provide a ready to use installation of [sentry](see https://getsentry.com) behind a nginx reverse proxy and with a mailserver and postgress and reddis in place.

## Installation
### install ssl certificates:
place your certificate and key in:
* Dockers/nginx/mycert.pem
* Dockers/nginx/mykey.key

### Change config
All variables you need to change are in docker-compose.yml. You need to change at least:
  * SECRET_KEY
  * SERVER_EMAIL (where emails send by sentry will appear to originate from)
  * SENTRY_ADMIN_EMAIL:
  * SENTRY_URL_PREFIX: 
  
### start the docker
```bash
docker compose build
```
you will need to initialize the database:
  ```bash
docker-compose run web sentry upgrade
docker compose up
```
And you're in bussiness.
