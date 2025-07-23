#!/bin/bash

# Docker installation script for Ubuntu/Debian servers
# This script will install Docker and Docker Compose

set -e

echo "🐳 Installing Docker and Docker Compose..."

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo "❌ Cannot detect OS. This script supports Ubuntu/Debian only."
        exit 1
    fi
    echo "✅ Detected OS: $OS $VER"
}

# Function to update system
update_system() {
    echo "📦 Updating system packages..."
    sudo apt-get update
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    echo "✅ System updated"
}

# Function to install Docker
install_docker() {
    echo "🐳 Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        echo "ℹ️  Docker is already installed: $(docker --version)"
        return 0
    fi
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "✅ Docker installed successfully"
}

# Function to install Docker Compose
install_docker_compose() {
    echo "🔧 Installing Docker Compose..."
    
    # Check if Docker Compose is already installed
    if command -v docker-compose &> /dev/null; then
        echo "ℹ️  Docker Compose is already installed: $(docker-compose --version)"
        return 0
    fi
    
    # Install Docker Compose plugin (newer method)
    sudo apt-get install -y docker-compose-plugin
    
    # Create symlink for backward compatibility
    sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    echo "✅ Docker Compose installed successfully"
}

# Function to start and enable Docker service
setup_docker_service() {
    echo "⚙️  Setting up Docker service..."
    
    # Start Docker service
    sudo systemctl start docker
    
    # Enable Docker to start on boot
    sudo systemctl enable docker
    
    echo "✅ Docker service configured"
}

# Function to create application directory
setup_app_directory() {
    echo "📁 Setting up application directory..."
    
    APP_DIR="$HOME/montedakou"
    
    # Create directory if it doesn't exist
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_DIR/logs/nginx"
    mkdir -p "$APP_DIR/icecast"
    
    echo "✅ Application directory created: $APP_DIR"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    
    # Check Docker
    if docker --version &> /dev/null; then
        echo "✅ Docker: $(docker --version)"
    else
        echo "❌ Docker installation failed"
        exit 1
    fi
    
    # Check Docker Compose
    if docker-compose --version &> /dev/null; then
        echo "✅ Docker Compose: $(docker-compose --version)"
    else
        echo "❌ Docker Compose installation failed"
        exit 1
    fi
    
    # Check Docker service
    if sudo systemctl is-active --quiet docker; then
        echo "✅ Docker service is running"
    else
        echo "❌ Docker service is not running"
        exit 1
    fi
    
    # Test Docker without sudo (requires re-login)
    if groups $USER | grep -q docker; then
        echo "✅ User $USER is in docker group"
        echo "ℹ️  Note: You may need to log out and back in for group changes to take effect"
    else
        echo "❌ User $USER is not in docker group"
        exit 1
    fi
}

# Function to display next steps
show_next_steps() {
    echo ""
    echo "🎉 Docker installation completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Log out and log back in (or run 'newgrp docker') to refresh group membership"
    echo "2. Test Docker: docker run hello-world"
    echo "3. Your application directory is ready at: $HOME/montedakou"
    echo ""
    echo "🚀 Ready for deployment!"
}

# Main installation process
main() {
    echo "🚀 Starting Docker installation for Monte Dakou deployment..."
    echo ""
    
    detect_os
    update_system
    install_docker
    install_docker_compose
    setup_docker_service
    setup_app_directory
    verify_installation
    show_next_steps
}

# Run main function only if Docker is not already installed and working
if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
    echo "✅ Docker is already installed and working!"
    setup_app_directory
    show_next_steps
else
    main "$@"
fi