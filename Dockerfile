# Hessian.AI Plugin for pi Coding Agent - Docker Image
# Multi-stage build for smaller final image

# Stage 1: Builder
FROM node:24-alpine as builder

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
RUN npm run tsc -- --noEmit --skipLibCheck 2>/dev/null || true

# Stage 2: Production
FROM node:24-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    bc

# Create non-root user
RUN adduser -D -s /bin/bash -u 1000 -G node pluginuser
WORKDIR /home/pluginuser

# Copy node_modules from builder
COPY --from=builder --chown=pluginuser:pluginuser /home/pluginuser/app/node_modules /home/pluginuser/node_modules

# Copy package files
COPY --chown=pluginuser:pluginuser package*.json tsconfig.json ./

# Copy all files
COPY --chown=pluginuser:pluginuser . .

# Ensure correct permissions
RUN chmod +x /home/pluginuser/src/*.sh /home/pluginuser/sandbox/*.sh 2>/dev/null || true

# Create pi plugin directory structure
RUN mkdir -p /home/pluginuser/.config/pi/plugins/hessian

# Copy plugin files explicitly (not relying on wildcard)
RUN cp -f /home/pluginuser/src/hessian.ts /home/pluginuser/.config/pi/plugins/hessian/hessian.ts && \
    cp -f /home/pluginuser/src/hessian-memory.ts /home/pluginuser/.config/pi/plugins/hessian/hessian-memory.ts && \
    cp -f /home/pluginuser/src/types.ts /home/pluginuser/.config/pi/plugins/hessian/types.ts && \
    mkdir -p /home/pluginuser/.config/pi/plugins/hessian/.opencode && \
    mkdir -p /home/pluginuser/.config/pi/plugins/hessian/schema && \
    chown -R pluginuser:pluginuser /home/pluginuser/.config

# Switch to non-root user
USER pluginuser
WORKDIR /home/pluginuser

# Environment variables
ENV NODE_ENV=production
ENV HESSIAN_API_KEY=""
ENV HESSIAN_PROFILE="production"
ENV HESSIAN_API_URL=""

# Default command
CMD ["tail", "-f", "/dev/null"]
