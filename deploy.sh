#!/bin/bash

# Deployment script for Monte Dakou Internet Radio
# Usage: ./deploy.sh [IMAGE_TAG]

set -e  # Exit on any error

IMAGE_TAG=${1:-"ghcr.io/username/montedakou:latest"}
COMPOSE_FILE="docker-compose.prod.yml"
APP_DIR="$HOME/montedakou"
BACKUP_DIR="$HOME/montedakou-backups"

echo "🚀 Starting deployment of Monte Dakou..."
echo "📦 Image: $IMAGE_TAG"
echo "📂 Directory: $APP_DIR"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to backup current state
backup_current_state() {
    if [ -f "$COMPOSE_FILE" ]; then
        echo "💾 Creating backup..."
        BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
        
        # Backup compose file and any custom configs
        cp "$COMPOSE_FILE" "$BACKUP_DIR/$BACKUP_NAME/"
        if [ -d "icecast" ]; then
            cp -r icecast "$BACKUP_DIR/$BACKUP_NAME/"
        fi
        
        echo "✅ Backup created: $BACKUP_DIR/$BACKUP_NAME"
    fi
}

# Function to check if Docker is running
check_docker() {
    if ! docker info &> /dev/null; then
        echo "❌ Docker is not running. Please start Docker first."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to pull latest image
pull_image() {
    echo "⬇️  Pulling latest image: $IMAGE_TAG"
    if ! docker pull "$IMAGE_TAG"; then
        echo "❌ Failed to pull image: $IMAGE_TAG"
        exit 1
    fi
    echo "✅ Image pulled successfully"
}

# Function to stop current containers
stop_containers() {
    if [ -f "$COMPOSE_FILE" ]; then
        echo "⏹️  Stopping current containers..."
        docker-compose -f "$COMPOSE_FILE" down --remove-orphans || true
        echo "✅ Containers stopped"
    fi
}

# Function to start new containers
start_containers() {
    echo "▶️  Starting new containers..."
    
    # Update the image tag in docker-compose file
    sed -i.bak "s|image: .*|image: $IMAGE_TAG|g" "$COMPOSE_FILE"
    
    # Start containers
    docker-compose -f "$COMPOSE_FILE" up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ Containers started successfully"
    else
        echo "❌ Failed to start containers"
        exit 1
    fi
}

# Function to verify deployment
verify_deployment() {
    echo "🔍 Verifying deployment..."
    
    # Wait a moment for containers to start
    sleep 10
    
    # Check if containers are running
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
        echo "✅ Containers are running"
    else
        echo "❌ Some containers are not running"
        docker-compose -f "$COMPOSE_FILE" ps
        exit 1
    fi
    
    # Check if web service responds
    if curl -f http://localhost &> /dev/null; then
        echo "✅ Web service is responding"
    else
        echo "⚠️  Web service is not responding yet (may still be starting)"
    fi
    
    # Check if icecast is responding
    if curl -f http://localhost:8000 &> /dev/null; then
        echo "✅ Icecast service is responding"
    else
        echo "⚠️  Icecast service is not responding yet (may still be starting)"
    fi
}

# Function to cleanup old images
cleanup_old_images() {
    echo "🧹 Cleaning up old images..."
    
    # Remove dangling images
    docker image prune -f &> /dev/null || true
    
    # Keep only the last 3 versions of our app image
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}" | \
    grep "montedakou" | \
    tail -n +4 | \
    awk '{print $1}' | \
    xargs -r docker rmi &> /dev/null || true
    
    echo "✅ Cleanup completed"
}

# Main deployment process
main() {
    cd "$APP_DIR" || { echo "❌ Cannot access $APP_DIR"; exit 1; }
    
    backup_current_state
    check_docker
    pull_image
    stop_containers
    start_containers
    verify_deployment
    cleanup_old_images
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "🌐 Your site should be available at: https://montedakou.net"
    echo "📻 Icecast should be available at: http://montedakou.net:8000"
    echo ""
    echo "📊 Container status:"
    docker-compose -f "$COMPOSE_FILE" ps
}

# Run main function
main "$@"