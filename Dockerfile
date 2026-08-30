# Multi-stage build for Catherine Wallage WordPress Stack
FROM php:8.3-fpm-alpine AS builder

RUN apk update && apk add --no-cache \
    $PHPIZE_DEPS \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libavif-dev \
    libzip-dev \
    imagemagick \
    imagemagick-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev

# Configure and compile core PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif && \
    docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        opcache \
        exif \
        zip \
        intl \
        bcmath \
        soap

# Compile PECL extensions
RUN pecl install redis imagick && \
    docker-php-ext-enable redis imagick

# ==============================================================================
# Final Production Runtime Stage
# ==============================================================================
FROM php:8.3-fpm-alpine

RUN apk update && apk add --no-cache \
    freetype \
    libjpeg-turbo \
    libpng \
    libwebp \
    libavif \
    libzip \
    imagemagick \
    icu-libs \
    shadow \
    bash \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    mariadb-client \
    curl

# Install WP-CLI into runtime
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

# Copy compiled extensions from builder stage
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Create host-matching user and group (2000:2000)
RUN addgroup -g 2000 media && \
    adduser -u 2000 -D -S -G media sickchill

# Production PHP & OPcache tuning
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PHP-FPM Process Pool Tuning
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
} > /usr/local/etc/php-fpm.d/zz-docker.conf

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
