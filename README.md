# darioaxel-django-rest-postgres-campusdigitalfp

## Descripción del Proyecto
Este proyecto es una API RESTful desarrollada con Django y PostgreSQL para el testeo de futuros 
usos en los módulos.

## 1. Software a utilizar
* Python: 3.11 (última estable)
* Django: 5.2.3 (última estable, requiere Python ≥3.10)
* PostgreSQL: 17 (última estable, disponible como imagen oficial en Docker)
* Poetry: para gestión de dependencias y entorno virtual
* Docker y Docker Compose: para contenerización

## 2. Inicialización del Proyecto
```shell
poetry new tu-proyecto
cd tu-proyecto
poetry env use 3.12
poetry add django@5.2.3 psycopg2-binary django-environ
```

> Para la instalación y administración de diversas versiones
> de Python, se utilizará `pyenv`. 
> Como guía para usar `pyenv` he usado [pyenv](https://realpython.com/intro-to-pyenv/)

### 2.1 Configuración del Entorno Virtual

Para configurar Postgres y django utilizaremos el fichero `.env` en la raíz del proyecto.

```shell
DJANGO_SECRET_KEY=YeAQ_wYVWV5c0FSCFEC0KVdgxblNo2lpI6kZdKjBJkRntyoWF2KfDnm1ZI_xvl-LRLU
DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_ENGINE=postgresql_psycopg2
DATABASE_NAME=campusdigitalfp
DATABASE_USERNAME=admin
DATABASE_PASSWORD=campusdigitalfp
DATABASE_HOST=db
DATABASE_PORT=5432
DJANGO_DEFAULT_AUTO_FIELD=django.db.models.BigAutoField
```

La clave `DJANGO_SECRET_KEY` la he generado con el comando:
```shell
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

## 3. Creación de la App de Usuarios
Crear una app dedicada para la gestión de usuarios:

```bash
python manage.py startapp users
```

Agregar la app users a la lista de INSTALLED_APPS en settings.py:

```python
INSTALLED_APPS = [
    # otras apps
    'users',
]
```
### 3.1 Creación del Modelo de Usuario Personalizado
Definir el modelo de usuario personalizado en users/models.py usando AbstractBaseUser y PermissionsMixin, con el email como identificador y un campo role:

```python
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models

class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, role=None, **extra_fields):
        if not email:
            raise ValueError("El email es obligatorio")
        email = self.normalize_email(email)
        user = self.model(email=email, role=role, **extra_fields)
        user.set_password(password)
        user.save()
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, role='superadmin', **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = (
        ('superadmin', 'Superadministrador'),
        ('admin', 'Administrador'),
        ('profesor', 'Profesor'),
    )
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['role']

    objects = CustomUserManager()

    def __str__(self):
        return self.email
```
## 3.2. Configuración del Modelo Personalizado
Indicar en settings.py que se usará el modelo personalizado:

```python
AUTH_USER_MODEL = 'users.User'
```
## 3.3. Migraciones
Crear y aplicar migraciones para el nuevo modelo:

```bash
python manage.py makemigrations users
python manage.py migrate
```
### 3.3.1 Configuración de Docker para Migraciones Automáticas
Para que en nuestro contenedor se realicen las migraciones de forma automática, debemos crear el archivo entrypoint.sh
```bash
#!/bin/sh

# Espera a que PostgreSQL esté disponible
if [ "$DATABASE" = "postgres" ]
then
    echo "Esperando a PostgreSQL..."
    while ! nc -z $DATABASE_HOST $DATABASE_PORT; do
      sleep 0.1
    done
    echo "PostgreSQL disponible"
fi

# Ejecuta migraciones
python manage.py migrate --noinput

# Ejecuta el comando principal
exec "$@"
```

Después, hemos de realizar las modificaciones en Dockerfile
```text
# ... (instrucciones anteriores)

# Copia y configura entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```
Configuración en docker-compose.yml

```text
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      - db
    # Configuración para ejecutar migraciones en cada inicio
    entrypoint: /entrypoint.sh

  db:
    image: postgres:15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${DATABASE_NAME}
      POSTGRES_USER: ${DATABASE_USERNAME}
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}

volumes:
  postgres_data:
```

## 3.4. Creación de Serializadores
Definir un serializador para el modelo de usuario en users/serializers.py:

```python
from rest_framework import serializers
from .models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'email', 'password', 'role')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user
```

## 3.5. Implementación de Vistas y Permisos
Crear vistas y permisos personalizados en DRF para gestionar el acceso según el rol del usuario.

Implementar clases de permisos como IsSuperAdmin, IsAdmin, IsProfesor en users/permissions.py (según necesidad).

## 3.6. Registro en el Panel de Administración
Registrar el modelo de usuario en users/admin.py para gestionarlo desde el admin de Django.

```python
from django.contrib import admin
from .models import User

admin.site.register(User)
```