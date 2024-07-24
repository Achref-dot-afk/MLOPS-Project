FROM python:3.9-buster as builder

RUN pip install poetry

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache 

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN poetry lock --no-update

RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --without dev --no-root

FROM python:3.9-slim-buster as runtime 

WORKDIR /app

ENV PORT=5000

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"

RUN : \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      --no-install-recommends \
      curl \
      build-essential \
      libsndfile1 \
      libsndfile1-dev

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY . ./

EXPOSE $PORT

CMD gunicorn --workers=2 --bind 0.0.0.0:$PORT app:app