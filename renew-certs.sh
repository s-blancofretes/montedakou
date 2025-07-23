#!/bin/bash

# SSL Certificate Renewal Script for Docker Compose
# Add this to crontab to run weekly: 0 0 * * 0 /path/to/renew-certs.sh

cd "$(dirname "$0")"

echo "$(date): Starting certificate renewal check..."

# Run certbot renewal
docker-compose run --rm certbot renew --webroot-path=/var/www/certbot

# Restart nginx to reload certificates if renewed
if [ $? -eq 0 ]; then
    echo "$(date): Certificate check completed, restarting nginx..."
    docker-compose restart nginx
    echo "$(date): Nginx restarted successfully"
else
    echo "$(date): Certificate renewal failed"
fi

echo "$(date): Certificate renewal process completed"