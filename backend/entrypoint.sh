#!/bin/bash
set -e

python manage.py migrate --noinput
python manage.py shell -c "
import os
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username=os.environ['DJANGO_ADMIN_USER']).exists():
    User.objects.create_superuser(
        os.environ['DJANGO_ADMIN_USER'],
        os.environ['DJANGO_ADMIN_EMAIL'],
        os.environ['DJANGO_ADMIN_PASSWORD'])
"
python manage.py collectstatic --noinput --clear

exec gunicorn conduit.wsgi:application --bind 0.0.0.0:${DJANGO_PORT:-8000} --workers 3
