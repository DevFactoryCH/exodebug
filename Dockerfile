ARG PHP_VERSION=8.1

# Base image for the container
FROM php:${PHP_VERSION}-fpm-alpine

ARG BUILD_DATE
ARG COMMIT_REF

#Add PHP and Laravel necessary php extensions
RUN apk --no-cache add \
        curl \
        nginx \
        supervisor \
        bash

# PHP Extension Installer: <https://github.com/mlocati/docker-php-extension-installer>
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
        install-php-extensions exif \
        gettext \
        gd \
        imagick \
        memcache \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        redis \
        zip \
        intl \
        soap

ARG BUILD_DATE
ARG COMMIT_REF
ARG VERSION

ENV PHP_MEMORY_LIMIT 512M

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
# Remove default server definition
RUN rm /etc/nginx/http.d/default.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /usr/local/etc/php-fpm.d/www.conf

# Use production php.ini defaults
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" $PHP_INI_DIR/php.ini

# Labels
LABEL ch.devfactory.maintainer="Mark CAMERON <mark.cameron@devfactory.ch>" \
        ch.devfactory.os="Alpine" \
        ch.devfactory.sourceurl="https://git.devfactory.ch/devfactory/docker/nginx-drupal" \
        ch.devfactory.manufacturer="DevFactory Sàrl" \
        ch.devfactory.build-date=$BUILD_DATE \
        ch.devfactory.commit-ref=$COMMIT_REF

# Configure PHP OPcache
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

COPY config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY config/php.ini /usr/local/etc/php/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
        chown -R nobody.nobody /run && \
        chown -R nobody.nobody /var/lib/nginx && \
        chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm and run other tasks
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
