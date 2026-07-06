FROM serversideup/php:8.3-fpm

# Install Node.js 22.x
USER root
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions
RUN install-php-extensions pcntl sockets exif sqlite3

USER www-data

# Copy root composer files
COPY --chown=www-data:www-data composer.json composer.lock ./

# Install dependencies (Composer will successfully link your modules now)
RUN composer install --no-dev --no-autoloader --no-scripts

# COPY NPM DEPENDENCY FILES & INSTALL
COPY --chown=www-data:www-data package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

# Copy the rest of the application source code
COPY --chown=www-data:www-data . .

# RUN NPM BUILD
RUN npm run build

# Finalize autoloader and run framework post-install tasks
RUN composer dump-autoload --no-dev --classmap-authoritative
