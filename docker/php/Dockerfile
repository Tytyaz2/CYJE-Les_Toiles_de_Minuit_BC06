FROM php:8.2-fpm

# Install extensions
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    unzip \
    git \
 && docker-php-ext-install pdo pdo_pgsql

WORKDIR /var/www/symfony
