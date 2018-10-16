FROM php:7.1-fpm-alpine
MAINTAINER Giampiero Lai <giampiero.lai@gmail.com>

ENV COMPOSER_ALLOW_SUPERUSER 1


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

# Copy PHP config
COPY php.ini /usr/local/etc/php/php.ini

# Enable XDEBUG with a custom config
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug-dev.ini

EXPOSE 9000
EXPOSE 9009