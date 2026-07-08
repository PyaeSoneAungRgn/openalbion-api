FROM php:8.3-cli

USER root

# Install Node.js 22.x
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pcntl sockets exif pdo_sqlite

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy composer files and install
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-autoloader --no-scripts

# Copy npm files and install
COPY --chown=www-data:www-data package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

# Copy application
COPY --chown=www-data:www-data . .

# Build assets
RUN npm run build

# Finalize autoloader
RUN composer dump-autoload --no-dev --classmap-authoritative

# Laravel optimizations
RUN php artisan optimize

EXPOSE 8080

USER www-data

# Start Laravel's built-in server on 0.0.0.0 using Vercel's PORT
CMD ["sh", "-c", "php artisan serve --host=0.0.0.0 --port=${PORT:-8080}"]
