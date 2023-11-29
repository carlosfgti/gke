# Use the official PHP 5.6 FPM image as the base image
FROM php:5.6-fpm as php-builder

RUN set -eux; \
    sed -i 's/^deb /# deb /g' /etc/apt/sources.list; \
    echo 'deb http://archive.debian.org/debian/ stretch main contrib non-free' >> /etc/apt/sources.list; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
            curl \
            libmemcached-dev \
            libbz2-dev \
            libpq-dev \
            libjpeg-dev \
            libpng-dev \
            libfreetype6-dev \
            libssl-dev \
            libxml2-dev \
            libssh2-1-dev \
            libgettextpo-dev \
            libmcrypt-dev; \
    # cleanup
    rm -rf /var/lib/apt/lists/*

# install and config extensions
RUN docker-php-ext-install mysql 
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install zip
RUN docker-php-ext-install calendar
RUN docker-php-ext-install mysqli 
RUN docker-php-ext-install dba
RUN docker-php-ext-install exif
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
&& docker-php-ext-install gd
RUN docker-php-ext-install gettext
RUN docker-php-ext-install shmop
RUN docker-php-ext-install soap
RUN docker-php-ext-install sysvmsg
RUN docker-php-ext-install wddx
RUN docker-php-ext-install opcache

# install and active bz2 extension
RUN docker-php-ext-install bz2
RUN echo "extension=bz2.so" > /usr/local/etc/php/conf.d/bz2.ini


# install and configure  ssh2 extension
WORKDIR /tmp
RUN curl -fsSL -k -o ssh2-0.13.tgz https://pecl.php.net/get/ssh2-0.13.tgz \
    && tar -xf ssh2-0.13.tgz \
    && cd ssh2-0.13 \
    && phpize \
    && ./configure \
    && make \
    && make install

# Enable the SSH2 extension
RUN echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ssh2.ini

# Cleanup
RUN rm -rf /tmp/ssh2-0.13

# Baixe e compile uma versão específica do módulo Redis compatível com o PHP 5.6
RUN mkdir -p /usr/src/php/ext/redis
RUN curl -fsSL -k -o redis.tgz https://pecl.php.net/get/redis-2.2.8.tgz
RUN tar -xf redis.tgz -C /usr/src/php/ext/redis --strip-components=1

# Compile o módulo Redis e habilite-o
RUN docker-php-ext-configure redis --enable-redis
RUN docker-php-ext-install redis

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