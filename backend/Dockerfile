# syntax=docker/dockerfile:1
# check=error=true
#
# Development image for the Rails API, run via docker-compose.yml.
# Not intended for production deployment.

ARG RUBY_VERSION=3.3.12
FROM docker.io/library/ruby:$RUBY_VERSION-slim-bookworm

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

# Non-root user; uid/gid 1000 matches the typical host dev user so bind-mounted
# files created inside the container stay editable on the host.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails /rails "${BUNDLE_PATH}"
USER 1000:1000

COPY --chown=rails:rails . .

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
