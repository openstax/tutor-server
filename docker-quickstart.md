# Docker Quickstart

## Installation

Follow the installation instructions for [docker](https://docs.docker.com/install/) and
[docker-compose](https://docs.docker.com/compose/install/). Tutor requires docker-compose v1.26+.

## Running the development server

To start the app at `http://localhost:3001`, run:

```bash
docker-compose up --build
```

The --build flag ensures the image is kept up to date with your code checked out locally.

## Resetting the Postgres container database

To reset the database to a state containing only the course created by `bin/rake demo[mini]`, run:

```bash
docker-compose up --build --renew-anon-volumes
```

The --renew-anon-volumes flag (or -V) resets the database to an empty state,
which is then repopulated by the entrypoint script.

## GitHub actions

To use tutor-server in a GitHub action, add the following to your action:

```yaml
- uses: openstax/tutor-server
```
