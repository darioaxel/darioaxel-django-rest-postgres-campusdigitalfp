FROM python:3.13.2-slim

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y curl

# Instala Poetry
ENV POETRY_VERSION=1.7.1
RUN curl -sSL https://install.python-poetry.org | python3 - --version $POETRY_VERSION
ENV PATH="/root/.local/bin:$PATH"

# Desactiva la creación de entornos virtuales dentro del contenedor
RUN poetry config virtualenvs.create false

# Copia solo los archivos de dependencias primero
COPY pyproject.toml poetry.lock ./

# Instala dependencias
RUN poetry install --no-interaction --no-ansi

# Copia el resto del código
COPY . .

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
