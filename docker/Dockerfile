FROM python:3.10-alpine as poetry

# Keeps Python from generating .pyc files in the container
ENV PYTHONDONTWRITEBYTECODE 1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED 1

# Install poetry and it's dev dependencies
RUN apk add --no-cache curl gcc python3-dev musl-dev openssl-dev libffi-dev \
    && curl -sSL https://install.python-poetry.org | python -
ENV PATH="/root/.local/bin:$PATH"

# Install poetry dependencies
RUN python -m venv /venv

COPY pyproject.toml ./
RUN . /venv/bin/activate && poetry install --no-dev --no-root

FROM python:3.10-alpine as final

WORKDIR /usr/src/app

COPY . ./
COPY --from=poetry /venv /venv

EXPOSE 5000

# run entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]
