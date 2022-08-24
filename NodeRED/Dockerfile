### Define the base image version
ARG version=3.0.2

#### Use nodered/node-red:2.2.2 as the base
FROM nodered/node-red:${version} AS base

USER root

# Install libgpiod
RUN apk add libgpiod-dev

# Copy package.json contains curated version of Node-RED NPM module and node dependencies
COPY package.json .

# Install node-red nodes
RUN npm install --unsafe-perm --no-update-notifier --no-fund --only=production

RUN addgroup -g 998 i2c
RUN addgroup node-red i2c
RUN addgroup node-red dialout

USER node-red

