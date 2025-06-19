# darioaxel-django-rest-postgres-campusdigitalfp

## Descripción del Proyecto
Este proyecto es una API RESTful desarrollada con Django y PostgreSQL para el testeo de futuros 
usos en los módulos.

## Software a utilizar
* Python: 3.11 (última estable)
* Django: 5.2.3 (última estable, requiere Python ≥3.10)
* PostgreSQL: 17 (última estable, disponible como imagen oficial en Docker)
* Poetry: para gestión de dependencias y entorno virtual
* Docker y Docker Compose: para contenerización

## Inicialización del Proyecto
```shell
poetry new tu-proyecto
cd tu-proyecto
poetry env use 3.12
poetry add django@5.2.3 psycopg2-binary django-environ
```

> Para la instalación y administración de diversas versiones
> de Python, se utilizará `pyenv`. 
> Como guía para usar `pyenv` he usado [pyenv](https://realpython.com/intro-to-pyenv/)

# Configuración del Entorno Virtual

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
