
# Docker Quickstart

## Install

Follow the installation instructions for
[docker](https://docs.docker.com/install/) and
[docker-compose](https://docs.docker.com/compose/install/)

## Run

``` bash
docker-compose up -V
```

the app will become available at `http://localhost:3001`

the `-V` option is

```
-V, --renew-anon-volumes   Recreate anonymous volumes instead of retrieving
                           data from the previous containers.
```
which forces docker-compose to recreate the tmp and log directories

## Notes

The first time you start the environment you'll want to
get keys for the exercises service from Dante and put them in
a .env file. then run:

```bash
docker-compose run tutor rake db:setup demo[soc]
```

If the Gemfile changes you'll have to:

```bash
docker-compose build --no-cache tutor
```
