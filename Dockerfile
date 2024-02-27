# Use the official PHP 5.6 FPM image as the base image
FROM php:8.1-fpm

# Set the working directory in the container
WORKDIR /var/www

COPY . /var/www/

# custom.ini file
COPY docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Stage 2: Build Nginx image
# Install Supervisor
RUN apt-get update && \
    apt-get install -y supervisor nginx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy Nginx configuration file
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/sites-available/default.conf /etc/nginx/sites-available/default.conf

# Copy the supervisor configuration file
COPY docker/supervisor/supervisord.conf /etc/supervisor/supervisord.conf

# Start supervisor
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]