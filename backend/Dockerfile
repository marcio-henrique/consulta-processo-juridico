# syntax=docker/dockerfile:1
# check=error=true
#
# Development image for the Rails API, run via docker-compose.yml.
# Not intended for production deployment.

ARG RUBY_VERSION=3.3.12
FROM docker.io/library/ruby:$RUBY_VERSION-slim-bookworm

ARG HOST_UID=1000
ARG HOST_GID=1000

WORKDIR /rails

# Runtime + build packages (kept in one layer; this image is dev-only, size is not a priority)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libyaml-dev pkg-config curl postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH="/usr/local/bundle" \
    RAILS_ENV="development" \
    HOME="/rails"

COPY Gemfile Gemfile.lock ./
RUN bundle install

# Non-root user; defaults to 1000 but matches the host user when
# HOST_UID/HOST_GID build args are passed, so bind-mounted and named-volume
# files created inside the container stay writable at runtime (the api
# service's docker-compose.yml sets `user:` to the same HOST_UID/HOST_GID).
RUN groupadd --system --gid ${HOST_GID} rails 2>/dev/null || true && \
    useradd rails --uid ${HOST_UID} --gid ${HOST_GID} --create-home --shell /bin/bash 2>/dev/null || true && \
    chown -R ${HOST_UID}:${HOST_GID} /rails "${BUNDLE_PATH}"
USER ${HOST_UID}:${HOST_GID}

COPY --chown=${HOST_UID}:${HOST_GID} . .

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
