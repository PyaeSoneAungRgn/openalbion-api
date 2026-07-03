FROM serversideup/php:8.5-frankenphp

# Install Node.js 22.x
USER root
RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
USER www-data

# Copy root composer files
COPY --chown=www-data:www-data composer.json composer.lock ./

# Install dependencies (Composer will successfully link your modules now)
RUN composer install --no-dev --no-autoloader --no-scripts

# COPY NPM DEPENDENCY FILES & INSTALL
COPY --chown=www-data:www-data package.json package-lock.json* ./
RUN npm ci

# Copy the rest of the application source code
COPY --chown=www-data:www-data . .

# RUN NPM BUILD
RUN npm run build

# Finalize autoloader and run framework post-install tasks
RUN composer dump-autoload --no-dev --classmap-authoritative
