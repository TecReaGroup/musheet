#!/bin/bash

# MuSheet Server Deployment Script
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== MuSheet Server Deployment ==="
echo "Environment: $ENVIRONMENT"
echo "Project Directory: $PROJECT_DIR"
echo ""

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    echo "Loading environment variables..."
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
fi

# Validate required environment variables
validate_env() {
    local missing=0
    for var in POSTGRES_PASSWORD REDIS_PASSWORD JWT_SECRET; do
        if [ -z "${!var}" ]; then
            echo "ERROR: $var is not set"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo ""
        echo "Please set required environment variables in .env file"
        exit 1
    fi
}

# Build the server
build_server() {
    echo "Building server..."
    cd "$PROJECT_DIR/musheet_server"
    
    # Generate Serverpod protocol
    echo "Generating protocol..."
    dart pub get
    dart pub run serverpod generate
    
    echo "Build complete!"
}

# Deploy with Docker
deploy_docker() {
    echo "Deploying with Docker..."
    cd "$PROJECT_DIR"
    
    # Build and start containers
    docker-compose build --no-cache
    docker-compose up -d
    
    # Wait for services to be ready
    echo "Waiting for services to start..."
    sleep 10
    
    # Check health
    echo "Checking service health..."
    docker-compose ps
    
    echo "Deployment complete!"
}

# Run database migrations
run_migrations() {
    echo "Running database migrations..."
    cd "$PROJECT_DIR/musheet_server"
    
    # Serverpod handles migrations automatically on startup
    # This function is for manual migration runs if needed
    
    echo "Migrations complete!"
}

# Show logs
show_logs() {
    echo "Showing server logs..."
    cd "$PROJECT_DIR"
    docker-compose logs -f musheet_server
}

# Stop services
stop_services() {
    echo "Stopping services..."
    cd "$PROJECT_DIR"
    docker-compose down
    echo "Services stopped."
}

# Main execution
case "$2" in
    build)
        build_server
        ;;
    deploy)
        validate_env
        deploy_docker
        ;;
    migrate)
        run_migrations
        ;;
    logs)
        show_logs
        ;;
    stop)
        stop_services
        ;;
    full)
        validate_env
        build_server
        deploy_docker
        ;;
    *)
        echo "Usage: $0 <environment> <command>"
        echo ""
        echo "Commands:"
        echo "  build   - Build the server"
        echo "  deploy  - Deploy with Docker"
        echo "  migrate - Run database migrations"
        echo "  logs    - Show server logs"
        echo "  stop    - Stop all services"
        echo "  full    - Full deployment (build + deploy)"
        echo ""
        echo "Example:"
        echo "  $0 production full"
        ;;
esac