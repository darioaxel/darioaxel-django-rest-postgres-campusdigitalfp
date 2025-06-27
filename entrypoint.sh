#!/bin/sh

# Espera a que la base de datos esté disponible (opcional, pero recomendable)
if [ "$DATABASE" = "postgres" ]
then
    echo "Esperando a que Postgres esté disponible..."
    while ! nc -z $DATABASE_HOST $DATABASE_PORT; do
      sleep 0.1
    done
    echo "Postgres está disponible"
fi

# Ejecuta migraciones
python manage.py migrate --noinput

# Ejecuta cualquier otro comando que necesites (ejemplo: collectstatic)
# python manage.py collectstatic --noinput

# Crear superadmin
echo "Creando superadmin..."
python manage.py shell <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()

if not User.objects.filter(email='$DJANGO_SUPERUSER_EMAIL').exists():
    User.objects.create_superuser(
        email='$DJANGO_SUPERUSER_EMAIL',
        password='$DJANGO_SUPERUSER_PASSWORD',
        role='superadmin'
    )
    print('Superadmin creado')
else:
    print('Superadmin ya existe')
EOF

# Finalmente ejecuta el comando por defecto (por ejemplo, el servidor)
exec "$@"
