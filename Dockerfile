FROM serversideup/php:8.5-frankenphp

USER root

# Install Node.js 22.x
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions
RUN install-php-extensions pcntl sockets exif sqlite3

USER www-data

# Copy root composer files
COPY --chown=www-data:www-data composer.json composer.lock ./
RUN composer install --no-dev --no-autoloader --no-scripts

COPY --chown=www-data:www-data package.json package-lock.json* ./
RUN npm ci

COPY --chown=www-data:www-data . .
RUN npm run build

RUN composer dump-autoload --no-dev --classmap-authoritative
