# Multi-stage Dockerfile for Monte Dakou Internet Radio Web App
FROM nginx:alpine as base

# Install PHP-FPM
RUN apk add --no-cache \
    php82 \
    php82-fpm \
    php82-opcache \
    php82-json \
    php82-openssl \
    php82-curl \
    php82-zlib \
    php82-xml \
    php82-phar \
    php82-intl \
    php82-dom \
    php82-xmlreader \
    php82-ctype \
    php82-session \
    php82-mbstring \
    php82-gd \
    supervisor

# Create php-fpm symlink
RUN ln -s /usr/bin/php82 /usr/bin/php

# Copy application files
COPY src/ /var/www/montedakou.net/
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/montedakou.conf /etc/nginx/conf.d/default.conf

# Create directories for SSL certificates (will be mounted as volumes in production)
RUN mkdir -p /etc/letsencrypt/live/montedakou.net \
    && mkdir -p /var/www/certbot

# Configure PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /etc/php82/php-fpm.d/www.conf \
    && sed -i 's/;listen.owner = nginx/listen.owner = nginx/' /etc/php82/php-fpm.d/www.conf \
    && sed -i 's/;listen.group = nginx/listen.group = nginx/' /etc/php82/php-fpm.d/www.conf \
    && sed -i 's/user = nobody/user = nginx/' /etc/php82/php-fpm.d/www.conf \
    && sed -i 's/group = nobody/group = nginx/' /etc/php82/php-fpm.d/www.conf

# Create supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root

[program:ssl-fix]
command=/bin/sh -c 'if [ -d "/etc/letsencrypt/live" ]; then find /etc/letsencrypt -type f -name "*.pem" -exec chmod 644 {} \; 2>/dev/null || true; fi; sleep 1'
autostart=true
autorestart=false
startsecs=0
stdout_logfile=/var/log/ssl-fix.log
stderr_logfile=/var/log/ssl-fix-error.log
priority=100

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/var/log/nginx/access.log
stderr_logfile=/var/log/nginx/error.log
priority=200

[program:php-fpm]
command=php-fpm82 -F
autostart=true
autorestart=true
stdout_logfile=/var/log/php-fpm.log
stderr_logfile=/var/log/php-fpm-error.log
priority=150
EOF

# Set proper permissions
RUN chown -R nginx:nginx /var/www/montedakou.net \
    && chmod -R 755 /var/www/montedakou.net

# Expose ports
EXPOSE 80 443

# Start supervisor directly without custom script
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]