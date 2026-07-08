FROM serversideup/php:8.3-fpm-nginx

# Install Node.js 22.x
USER root

RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions
RUN install-php-extensions pcntl sockets exif sqlite3

# FIX: Create symlinks for Nginx logs pointing to PID 1's stdout/stderr
RUN ln -sf /proc/1/fd/2 /var/log/nginx/error.log \
    && ln -sf /proc/1/fd/1 /var/log/nginx/access.log

# FIX: The base image templates reference /dev/stderr and /dev/stdout directly.
# Vercel's sandbox blocks those paths, so we rewrite the templates to use the
# symlinks above before the init script processes them.
RUN for f in /etc/nginx/nginx.conf.template \
             /etc/nginx/site-opts.d/http.conf.template \
             /etc/nginx/site-opts.d/https.conf.template \
             /etc/nginx/sites-available/ssl-full.template; do \
    [ -f "$f" ] && sed -i \
        -e 's|/dev/stderr|/var/log/nginx/error.log|g' \
        -e 's|/dev/stdout|/var/log/nginx/access.log|g' \
        "$f"; \
done

# IMPORTANT: Do NOT change the listen port to 80. Vercel forwards to the port
# defined by the PORT environment variable (default 8080). The base image
# already listens on 8080, which is correct. Leave it alone.
EXPOSE 8080

USER www-data

# Copy root composer files
COPY --chown=www-data:www-data composer.json composer.lock ./

# Install dependencies
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
