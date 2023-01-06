FROM alpine:3.16

MAINTAINER Ivo Schimani <ivo@schimani.de>

ARG LOCAL_USER_ID=1000
ARG LOCAL_GROUP_ID=1000

RUN apk update \
  && apk upgrade

# Create user
RUN mkdir -p /var/www && \
    adduser -D --home /var/www -u $LOCAL_USER_ID -g $LOCAL_GROUP_ID -s /bin/sh www-data -G www-data && \
    chown -R www-data:www-data /var/www

RUN mkdir -p /run/nginx

# Install nginx
# Create cachedir and fix permissions
RUN apk add --no-cache --update \
    nginx && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/tmp/nginx && \
    mkdir -p /var/tmp/php && \
    mkdir - p /var/www/.ssh && \
    chown -R www-data:www-data /var/cache/nginx && \
    chown -R www-data:www-data /var/lib/nginx && \
    chown -R www-data:www-data /var/tmp/nginx && \
    chown -R www-data:www-data /var/tmp/php

RUN apk --no-cache --update add tzdata php8-fpm php8-pdo_mysql php8-json php8-iconv php8-openssl php8-curl php8-ctype php8-zlib php8-xml php8-phar php8-intl php8-session php8-simplexml php8-soap php8-fileinfo php8-dom php8-tokenizer php8-pdo php8-xmlreader php8-xmlwriter php8-mbstring php8-gd php8-zip php8-bcmath php8-gmp php8-ftp php8-pecl-ssh2 libwebp-dev libzip-dev libjpeg-turbo-dev supervisor curl git openssh-client mysql-client imagemagick-dev libtool imagemagick ghostscript

RUN rm -rf /etc/localtime \
    && ln -s /usr/share/zoneinfo/"Europe/Berlin" /etc/localtime \
    && echo "Europe/Berlin" > /etc/timezone

RUN set -ex \
  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
  && php -r "unlink('composer-setup.php');" \
  && chmod +x /usr/local/bin/composer

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php8/php-fpm.d/www.conf
COPY config/php.ini /etc/php8/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy Entrypoint
COPY start.sh /

RUN chown -R www-data:www-data /var/www

RUN rm -rf /var/cache/apk/*

WORKDIR /var/www/contao
USER root

# Expose the port nginx is reachable on
EXPOSE 8080

ENTRYPOINT ["/start.sh"]
