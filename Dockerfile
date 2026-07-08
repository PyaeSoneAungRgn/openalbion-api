FROM serversideup/php:8.3-fpm-nginx

# Install Node.js 22.x
USER root

RUN apt-get update && apt-get install -y curl \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install required PHP extensions
RUN install-php-extensions pcntl sockets exif sqlite3

# FIX: Redirect Nginx logs to process 1 to bypass Vercel's /dev/stderr permission denied error
RUN ln -sf /proc/1/fd/2 /var/log/nginx/error.log \
    && ln -sf /proc/1/fd/1 /var/log/nginx/access.log

# Make Nginx actually listen on port 80 instead of the image's default 8080.
# The listen port is baked into this template (not env-var driven), so we patch it directly.
RUN sed -i 's/listen 8080/listen 80/; s/listen \[::\]:8080/listen [::]:80/' \
    /etc/nginx/site-opts.d/http.conf.template

# Since the container still runs as the unprivileged www-data user, grant the
# Nginx binary permission to bind to ports <1024 without needing root.
RUN apt-get update && apt-get install -y libcap2-bin \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx \
    && apt-get purge -y libcap2-bin && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 80

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
