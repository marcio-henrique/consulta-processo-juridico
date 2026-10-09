# syntax=docker/dockerfile:1
#
# Development image for the Vite dev server, run via docker-compose.yml.
# Not intended for production deployment.

ARG NODE_VERSION=22
FROM docker.io/library/node:${NODE_VERSION}-slim

# Build and run as the host user so node_modules (installed at build time)
# stays writable at runtime when docker-compose.yml sets the same uid/gid
# via `user:`. Defaults match most single-user Linux/macOS setups.
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd --system --gid ${HOST_GID} app 2>/dev/null || true && \
    useradd app --uid ${HOST_UID} --gid ${HOST_GID} --create-home --shell /bin/bash 2>/dev/null || true

WORKDIR /app
RUN chown ${HOST_UID}:${HOST_GID} /app

USER ${HOST_UID}:${HOST_GID}

COPY --chown=${HOST_UID}:${HOST_GID} package.json package-lock.json ./
RUN npm install

COPY --chown=${HOST_UID}:${HOST_GID} . .

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
