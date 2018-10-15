FROM php:7.1-fpm-alpine

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV PHP_XDEBUG_DEFAULT_ENABLE ${PHP_XDEBUG_DEFAULT_ENABLE:-1}
ENV PHP_XDEBUG_REMOTE_ENABLE ${PHP_XDEBUG_REMOTE_ENABLE:-1}
ENV PHP_XDEBUG_REMOTE_HOST ${PHP_XDEBUG_REMOTE_HOST:-"127.0.0.1"}
ENV PHP_XDEBUG_REMOTE_PORT ${PHP_XDEBUG_REMOTE_PORT:-9000}
ENV PHP_XDEBUG_REMOTE_AUTO_START ${PHP_XDEBUG_REMOTE_AUTO_START:-1}
ENV PHP_XDEBUG_REMOTE_CONNECT_BACK ${PHP_XDEBUG_REMOTE_CONNECT_BACK:-1}
ENV PHP_XDEBUG_IDEKEY ${PHP_XDEBUG_IDEKEY:-docker}
ENV PHP_XDEBUG_PROFILER_ENABLE ${PHP_XDEBUG_PROFILER_ENABLE:-0}
ENV PHP_XDEBUG_PROFILER_OUTPUT_DIR ${PHP_XDEBUG_PROFILER_OUTPUT_DIR:-"/tmp"}

# Copy PHP config

# Composer
RUN set -xe \ 
    && apk update \
    && apk add --no-cache git mysql-client libintl curl openssh-client icu libpng libjpeg-turbo libmcrypt libmcrypt-dev pwgen\
    && apk add --no-cache --virtual build-dependencies icu-dev libxml2-dev freetype-dev libpng-dev libjpeg-turbo-dev g++ make autoconf \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Xdebug and Redis
RUN set -xe \ 
    && pecl install xdebug redis \
    && docker-php-ext-enable xdebug redis

# Memcached
RUN set -xe \
    && apk add --no-cache libmemcached-dev zlib-dev cyrus-sasl-dev \
    && docker-php-source extract \
    && git clone --branch php7 https://github.com/php-memcached-dev/php-memcached.git /usr/src/php/ext/memcached/ \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached

RUN set -xe \
    && docker-php-ext-install mcrypt pdo_mysql soap intl zip opcache \
    && docker-php-ext-install mysqli

RUN set -xe \ 
    && apk del libmcrypt-dev build-dependencies \
    && apk del --no-cache zlib-dev cyrus-sasl-dev \
    && docker-php-source delete \
    && rm -rf /tmp/* /var/cache/apk/*

RUN chmod -R 774 /root /root/.composer

RUN set -xe \
    && chown -R operator:root ./

COPY php.ini /usr/local/etc/php/php.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini