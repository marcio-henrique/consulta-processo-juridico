# syntax=docker/dockerfile:1
#
# Development image for the Vite dev server, run via docker-compose.yml.
# Not intended for production deployment.

ARG NODE_VERSION=22
FROM docker.io/library/node:${NODE_VERSION}-slim

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
