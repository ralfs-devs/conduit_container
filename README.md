# Conduit Container

- Containerized legacy full-stack application (Django 1.10 backend + Angular 17
frontend) deployed with Docker Compose.  
- Lift-and-shift exercise for DevSecOps training

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
- [Architecture](#architecture)
- [Usage](#usage)
- [Security Notes](#security-notes)

## Prerequisites

- Docker Engine (incl. the `docker compose` plugin)
- A working shell (Linux/macOS/WSL)

## Quickstart

1. Clone this Repository

   ```bash
   git clone git@github.com:ralfs-devs/conduit-container.git
   cd conduit-container
   ```

2. Copy .env.example to .env and customize it to your personal settings

   ```bash
   cp .env.example .env
   nano .env
   ```

   For further information about configuration see [Configuration](#configuration)

3. Start the Docker Containers

   ```bash
   docker compose up --build -d
   ```

4. The application is then available at  

   <http://localhost:8282>

For information regarding runtime refer to [Usage](#usage)

## Architecture

The stack runs as three Docker services:

| Service  | Image                 | Role                                              |
| -------- | --------------------- | ------------------------------------------------- |
| frontend | nginx:1.25-alpine     | Angular 17 build served by nginx, reverse proxy   |
| backend  | python:3.6-slim       | Django 1.10 REST API behind gunicorn (WSGI)       |
| database | postgres:13-alpine    | PostgreSQL datastore                              |

The legacy code itself is largely unchanged, with the exception of a few minor changes  
(such as fixing external broken links and adapting the code to containerisation needs).  

Only the frontend exposes a port (`8282:80`). Backend and database have no  
host port mappings and communicate exclusively over the internal Compose  
network. nginx proxies `/api/` and `/admin/` requests to the backend and  
serves Django's collected static files from a shared volume, while the  
Angular SPA uses client-side routing with an `index.html` fallback.  

## Usage

### Configuration

All configuration happens through environment variables defined in `.env`
(see `.env.example`). Missing required variables abort startup via `:?` checks.

| Variable             | Required | Purpose                                  |
| -------------------- |  ---     | ---------------------------------------- |
| SECRET_KEY           | yes      | Django secret key                        |
| DB_PASSWORD          | yes      | PostgreSQL / Django database password    |
| DJANGO_DEBUG         | no       | Enable debug mode (default: false)       |
| DJANGO_ALLOWED_HOSTS | no       | Allowed hosts (comma-separated)          |
| CORS_WHITELIST       | no       | Allowed origins (comma-separated)        |
| DJANGO_ADMIN_*       | no       | Admin credentials created on first start |

### Changing Ports / Hosts

The frontend port is mapped in `docker-compose.yaml` (`8282:80`). To serve
on another port, change the mapping (e.g. `9090:80`). When exposing the
app to a network host, add its IP to `DJANGO_ALLOWED_HOSTS` and its origin
to `CORS_WHITELIST`, then recreate the containers.

### Managing the Stack

```bash
docker compose ps        # status  
docker compose logs -f   # follow logs  
docker compose down      # stop (add -v to wipe database data)  
```

## Security Notes

This project intentionally ships an end-of-life stack (Django 1.10,
Python 3.6) as a lift-and-shift exercise — known vulnerabilities remain
unpatched by design. Do not use this application for production purposes

Mitigations in place:

- Backend and database have no host port mappings; only nginx is reachable
- All secrets are injected via `.env` (never committed; enforced by  
  `:?` checks in `docker-compose.yaml`)
- Debug mode is disabled by default
- Database data persists in a named volume isolated from the host FS
- The `create_superuser` script requires `DJANGO_ADMIN_*` variables to be  
  set in .env by replacing the default values — empty values abort startup

Known legacy risks:

- Django 1.10 / Python 3.6 receive no security updates anymore
