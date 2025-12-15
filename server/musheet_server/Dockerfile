# MuSheet Server Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec files first for caching
COPY pubspec.* ./

# Get dependencies
RUN dart pub get

# Copy source code
COPY . .

# Generate Serverpod protocol
RUN dart pub run serverpod generate

# Build the server
RUN dart compile exe bin/main.dart -o bin/server

# Stage 2: Production image
FROM debian:bookworm-slim

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd -r -u 1000 -g root musheet

WORKDIR /app

# Copy compiled binary from build stage
COPY --from=build /app/bin/server ./bin/server

# Copy config files
COPY --from=build /app/config ./config

# Create directories for file storage
RUN mkdir -p /app/uploads /app/logs && \
    chown -R musheet:root /app

# Switch to non-root user
USER musheet

# Expose ports
# 8080: API server
# 8081: Insights (admin panel)
# 8082: Web server (if needed)
EXPOSE 8080 8081 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/status/health || exit 1

# Environment variables
ENV SERVERPOD_ENV=production
ENV SERVERPOD_LOG_LEVEL=info

# Run the server
ENTRYPOINT ["./bin/server"]