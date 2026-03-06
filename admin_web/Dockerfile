# MuSheet Admin Web UI Dockerfile
# Multi-stage build: Flutter build -> Nginx serve

# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first for caching
COPY pubspec.* ./

# Copy the musheet_client dependency
COPY ../musheet_client /musheet_client

# Update pubspec to use absolute path in docker context
RUN sed -i 's|path: ../musheet_client|path: /musheet_client|g' pubspec.yaml

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build Flutter web app
RUN flutter build web --release --dart-define=API_URL=/api

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built Flutter web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
