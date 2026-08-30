# Multi-stage build for Catherine Wallage WordPress Stack
FROM wordpress:fpm-alpine AS builder

RUN apk add --no-cache \
    autoconf \
    build-base \
    linux-headers \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libavif-dev \
    imagemagick-dev \
    libzip-dev \
    git \
    unzip

# Configure and compile GD with modern format support
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-avif \
    && docker-php-ext-install -j$(nproc) gd

# Compile PECL extensions
RUN pecl install redis imagick && \
    docker-php-ext-enable redis imagick

# ==============================================================================
# Final Production Runtime Stage
# ==============================================================================
FROM wordpress:fpm-alpine

RUN apk add --no-cache \
    freetype \
    libjpeg-turbo \
    libpng \
    libwebp \
    libavif \
    imagemagick \
    libzip \
    libgomp \
    jpegoptim \
    libjpeg-turbo-utils \
    optipng \
    pngquant \
    gifsicle \
    mariadb-client \
    curl

# Install WP-CLI into runtime
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Copy extensions from builder stage
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Create the explicit host-matching Group and User accounts
RUN addgroup -g 2000 media && \
    adduser -u 2000 -D -S -G media sickchill

# Inject optimized PHP OPcache settings
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-custom.ini

# Inject performance pool configuration aligned to UID/GID 2000
RUN { \
    echo '[www]'; \
    echo 'user = sickchill'; \
    echo 'group = media'; \
    echo 'pm = dynamic'; \
    echo 'pm.max_children = 24'; \
    echo 'pm.start_servers = 6'; \
    echo 'pm.min_spare_servers = 4'; \
    echo 'pm.max_spare_servers = 12'; \
    echo 'pm.max_requests = 1000'; \
} > /usr/local/etc/php-fpm.d/zz-docker-performance.conf

WORKDIR /var/www/html
RUN chown -R sickchill:media /var/www/html

USER sickchill
