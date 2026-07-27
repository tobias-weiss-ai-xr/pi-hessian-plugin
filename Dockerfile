# Hessian.AI Plugin for pi Coding Agent - Docker Image
# Multi-stage build for smaller final image

# Stage 1: Builder
FROM node:24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    bc

WORKDIR /home/pluginuser/app

# Copy package files
COPY package*.json tsconfig.json ./

# Install ALL dependencies (including devDependencies for tsc)
RUN npm install

# Copy all source files
COPY . .

# Build TypeScript (if needed)
RUN npm run lint 2>/dev/null || true

# Stage 2: Production
FROM node:24-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    bc

# Create non-root user (use a UID that doesn't conflict with the node user)
RUN adduser -D -s /bin/bash -u 1001 -G node pluginuser || adduser -D -s /bin/bash -G node pluginuser
WORKDIR /home/pluginuser

# Copy node_modules from builder
COPY --from=builder --chown=node:node /home/pluginuser/app/node_modules /home/pluginuser/node_modules

# Copy package files
COPY --chown=node:node package*.json tsconfig.json ./

# Copy all files
COPY --chown=node:node . .

# Ensure correct permissions
RUN chmod +x /home/pluginuser/src/*.sh /home/pluginuser/sandbox/*.sh 2>/dev/null || true

# Create pi plugin directory structure
RUN mkdir -p /home/pluginuser/.config/pi/plugins/hessian

# Copy plugin files explicitly (not relying on wildcard)
RUN mkdir -p /home/pluginuser/.config/pi/plugins/hessian/schema && \
    mkdir -p /home/pluginuser/.config/pi/plugins/hessian/.opencode && \
    cp -rf /home/pluginuser/src/. /home/pluginuser/.config/pi/plugins/hessian/ && \
    cp -f /home/pluginuser/schema/placeholder.json /home/pluginuser/.config/pi/plugins/hessian/schema/placeholder.json && \
    cp -rf /home/pluginuser/skills /home/pluginuser/.config/pi/plugins/hessian/ && \
    chown -R node:node /home/pluginuser/.config

# Switch to non-root user
USER pluginuser
WORKDIR /home/pluginuser

# Environment variables
ENV NODE_ENV=production
ENV HESSIAN_PROFILE="production"
ENV HESSIAN_API_URL=""

# Default command
CMD ["tail", "-f", "/dev/null"]
