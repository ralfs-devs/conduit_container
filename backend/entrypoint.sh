#!/bin/bash
set -e

python manage.py migrate --noinput
python manage.py collectstatic --noinput --clear

exec gunicorn conduit.wsgi:application --bind 0.0.0.0:${DJANGO_PORT:-8000} --workers 3
