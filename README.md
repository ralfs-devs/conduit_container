# Conduit Container

- Containerized legacy full-stack application (Django 1.10 backend + Angular 17
frontend) deployed with Docker Compose.  
- Lift-and-shift exercise for DevSecOps training

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quickstart](#quickstart)
- [Architecture](#architecture)
- [Usage](#usage)
  - [Configuration](#configuration)
  - [Changing Ports / Hosts](#changing-ports--hosts)
  - [Managing the Stack](#managing-the-stack)
- [Deployment](#deployment)
  - [Workflow](#workflow)
  - [Setup](#setup)
- [Security Notes](#security-notes)

## Prerequisites

- Docker Engine (incl. the `docker compose` plugin)
- A working shell (Linux/macOS/WSL)

## Quickstart

1. Clone this Repository

   ```bash
   git clone git@github.com:ralfs-devs/conduit_container.git
   ```

2. Change to the project directory

   ```bash
   cd conduit_container
   ```

3. Copy .env.example to .env

   ```bash
   cp .env.example .env
   ```

4. Customize it to your personal settings

   ```bash
   nano .env
   ```

   For further information about configuration see  
   [Configuration](#configuration)

5. Start the Docker Containers

   ```bash
   docker compose up --build -d
   ```

6. The application is then available at

   `http://<YOUR URL>:<YOUR PORT>`

   Replace the placeholder with the host or IP you configured in
   `DJANGO_ALLOWED_HOSTS`  
   (see also [Changing Ports / Hosts](#changing-ports--hosts)).

## Architecture

The stack runs as three Docker services:

| Service  | Image                 | Role                                              |
| -------- | --------------------- | ------------------------------------------------- |
| frontend | nginx:1.25-alpine     | Angular 17 build served by nginx, reverse proxy   |
| backend  | python:3.6-slim       | Django 1.10 REST API behind gunicorn (WSGI)       |
| database | postgres:13.23-alpine | PostgreSQL datastore                              |

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
(see `.env.example`). Required variables abort `docker compose` before the
build starts via `:?` checks.

| Variable              | Required | Purpose                                |
| --------------------- | -------- | -------------------------------------- |
| SECRET_KEY            | yes      | Django secret key                      |
| DB_PASSWORD           | yes      | PostgreSQL / Django database password  |
| DJANGO_ADMIN_USER     | yes      | Admin username created on first start  |
| DJANGO_ADMIN_EMAIL    | yes      | Admin email created on first start     |
| DJANGO_ADMIN_PASSWORD | yes      | Admin password (min. 8 characters)     |
| DJANGO_DEBUG          | no       | Enable debug mode (default: false)     |
| DJANGO_ALLOWED_HOSTS  | no       | Allowed hosts (comma-separated)        |
| CORS_WHITELIST        | no       | Allowed origins (comma-separated)      |

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

## Deployment

The application is deployed to a cloud VM via a GitHub Actions CI/CD pipeline.
Images are built and pushed on the runner; the VM only consumes pre-built
images (no local builds).

### Workflow

The pipeline lives in
[.github/workflows/deployment.yaml](.github/workflows/deployment.yaml)
and consists of two jobs:

1. **build** — checks out the repository, logs in to GHCR with the built-in
   `GITHUB_TOKEN`, then builds and pushes the backend and frontend images
   using `docker/build-push-action`. Each image is tagged with `latest` and
   the triggering commit SHA.
2. **deploy** — runs after a successful `build` (`needs: build`), opens an
   SSH connection to the VM and:
   - copies `docker-compose.yaml` to the VM via `scp`
   - pulls the freshly built images and retags them to
     `conduit-backend:local` / `conduit-frontend:local`
   - writes deployment metadata (commit SHA, timestamp) to `.deployment_info`
   - restarts the stack with `docker compose stop`, `docker compose up -d`
     and verifies it via `docker compose ps`

> [!NOTE]
> Both jobs use `set -e` in every SSH block, so any failure aborts the workflow
> immediately. The workflow is triggered on every push
> to `feat/cicd-deployment`and `main`, guarded by a `concurrency` group
> so overlapping deployments queue instead of racing each other.

### Setup

Configure the following in *Settings → Secrets and variables → Actions*
(none of these are stored in the repository):

| Type     | Name             | Purpose                        |
| -------- | ---------------- | ------------------------------ |
| Variable | `HOST_IP`        | Public IP of the target VM     |
| Variable | `USER_NAME`      | SSH user on the VM             |
| Secret   | `SSH_PRIVATE_KEY`| Private SSH key for the deploy |

> [!TIP]
> Since the GHCR packages are public, no `docker login` is required on the VM.

## Security Notes

This project intentionally ships an end-of-life stack (Django 1.10,
Python 3.6) as a lift-and-shift exercise — known vulnerabilities remain
unpatched by design.

> [!WARNING]
> Do not use this application in production.

Mitigations in place:

- Backend and database have no host port mappings; only nginx is reachable
- All secrets are injected via `.env` (never committed); required variables
  are enforced by `:?` checks in `docker-compose.yaml`, so a missing value
  aborts the command before any image is built
- The superuser bootstrap rejects passwords shorter than 8 characters and
  raises instead of falling back to a hardcoded default
- Debug mode is disabled by default
- Database data persists in a named volume isolated from the host FS
- The `create_superuser` script requires `DJANGO_ADMIN_*` variables to be  
  set in .env by replacing the default values — empty values abort startup

> [!WARNING]
> Known legacy risks:
> Django 1.10 / Python 3.6 do not receive security updates anymore
