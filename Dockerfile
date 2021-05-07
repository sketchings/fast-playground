FROM python:3.9-alpine AS base

ARG USER=sketchings
RUN apk update

RUN mkdir /sketchings
WORKDIR /sketchings

# Generate key and cert files
RUN apk add --no-cache libpq openssl
RUN openssl req -nodes -newkey rsa:2048 \
      -keyout /etc/ssl/certs/sketchings.key \
      -out /etc/ssl/certs/sketchings.csr \
      -x509 \
      -days 3650 \
      -subj "/C=US/ST=Oregon/L=Portland/O=Sketchings/OU=Engineering/CN=sketchings.com"

RUN chmod 644 /etc/ssl/certs/sketchings.key

# Start server
EXPOSE 6443
CMD ["gunicorn", "-c", "gunicorn.conf.py", "src.main:app"]

# --- Set-up for Pipfile installation
FROM base AS build
RUN pip install pipenv
RUN apk add --no-cache build-base postgresql-dev
COPY Pipfile* /sketchings/

# --- install production dependencies

FROM build AS deps
RUN pipenv install --deploy --system

# --- install dev dependencies

FROM deps AS dev_deps
RUN pipenv install --dev --deploy --system

# --- create development image

FROM base AS development
# does not require pipenv
COPY --from=dev_deps /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=dev_deps /usr/local/bin /usr/local/bin
RUN adduser -D ${USER}
USER ${USER}