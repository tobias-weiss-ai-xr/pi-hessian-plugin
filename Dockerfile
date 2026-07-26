# Hessian.AI Plugin for pi Coding Agent - Docker Image
FROM node:24-alpine

# Install system dependencies
RUN apk add --no-cache \
    curl \
    jq \
    bash \
    git \
    bc

# Create non-root user
RUN adduser -D -s /bin/bash -u 1000 -G node pluginuser
WORKDIR /home/pluginuser

# Copy package files
COPY package*.json tsconfig.json ./

# Install dependencies
RUN npm ci 2>/dev/null || npm install 2>&1

# Copy all files
COPY . .

# Ensure correct permissions
RUN chmod +x /home/pluginuser/src/*.sh /home/pluginuser/install*.sh 2>/dev/null || true

# Set up pi config directory
RUN mkdir -p /home/pluginuser/.config/pi/plugins/hessian
RUN cp -r /home/pluginuser/src/* /home/pluginuser/.config/pi/plugins/hessian/ 2>/dev/null || true
RUN cp -r /home/pluginuser/schema /home/pluginuser/.config/pi/plugins/hessian/ 2>/dev/null || true
RUN chown -R pluginuser:pluginuser /home/pluginuser/.config

# Switch to non-root user
USER pluginuser
WORKDIR /home/pluginuser

# Environment variables
ENV NODE_ENV=production
ENV HESSIAN_API_KEY=""
ENV HESSIAN_PROFILE="production"

# Default command
CMD ["tail", "-f", "/dev/null"]
