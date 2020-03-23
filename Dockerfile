FROM balenalib/raspberrypi3-alpine:latest

MAINTAINER Habilis

# /usr/local/etc/php/conf.d
ENV PHP_DIR /usr/local/etc/php

# Add libraries directory
ADD ./lib /home/lib

RUN set -x \
        && addgroup -g 82 -S www-data \
        && adduser -u 82 -D -S -G www-data www-data \
        && mkdir -p /var/www \
        && chown -R www-data:www-data /var/www \
        && mkdir -p $PHP_DIR/conf.d \
        && export CFLAGS="-fstack-protector-strong -fpic -fpie -O2" \
                CPPFLAGS="-fstack-protector-strong -fpic -fpie -O2" \
                LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie" \
        && apk update \
        && apk add --update --no-cache --virtual .image-packages \
                ca-certificates \
                openrc \
                curl \
                tar \
                xz \
                zip \
                wget

RUN apk add --update --no-cache --virtual .php-packages \
                curl-dev \
                libedit-dev \
                libxml2-dev \
                openssl-dev \
                libpng-dev \
                sqlite-dev \
                gnupg \
                openssl \
                autoconf \
                file \
                g++ \
                gcc \
                libc-dev \
                make \
                pkgconf \
                re2c

WORKDIR /home/lib/

RUN mkdir -p /tmp/openssl \
        && tar -xzf openssl-1.0.2k.tar.gz -C /tmp/openssl --strip-components=1 \
        && cd /tmp/openssl \
        && ./config --prefix=/usr/local --openssldir=/usr/local/openssl \
        && make && make install \
        && cd /home/lib/ \
        && rm -rf /tmp/openssl


# php 5.3 needs older autoconf
# --enable-mysqlnd is included below because it's harder to compile after the fact the extensions are (since it's a plugin for several extensions, not an extension in itself)
RUN mkdir -p /usr/src/php \
        && tar -xof php-5.3.29.tar.xz -C /usr/src/php --strip-components=1 \
        && cd /usr/src/php \
        && ./configure \
                --prefix="$PHP_DIR" \
                --sysconfdir="$PHP_DIR/conf.d" \
                --with-config-file-path="$PHP_DIR/conf.d/php.ini" \
                --with-config-file-scan-dir="$PHP_DIR/conf.d" \
                --enable-fpm \
                --with-fpm-user=www-data \
                --with-fpm-group=www-data \
                --disable-cgi \
                --enable-ftp \
                --enable-mbstring \
                --enable-mysqlnd \
                --with-curl \
                --with-libedit \
                --with-openssl \
                --with-openssl-dir=/usr/local/openssl \
                --with-zlib \
                --with-gd \
                --with-freetype \
                --enable-gd-native-ttf \
        && make -j "$(getconf _NPROCESSORS_ONLN)" \
        && make install \
        && { find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; } \
        && make clean \
        && runDeps="$( \
                scanelf --needed --nobanner --recursive /usr/local \
                        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
                        | sort -u \
                        | xargs -r apk info --installed \
                        | sort -u \
        )" \
        && apk add --no-cache --virtual .php-rundeps $runDeps \
        && apk del .php-packages

COPY ./config/php-fpm.conf /usr/local/etc/php/conf.d/php-fpm.conf
COPY ./config/php.ini /usr/local/etc/php/conf.d/php.ini
		
RUN cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm \
        && chmod 755 /etc/init.d/php-fpm \
        && chmod +x /etc/init.d/php-fpm \
        && rc-update add php-fpm default \
        && rm /usr/local/etc/php/conf.d/php-fpm.conf.default \
        && service php-fpm restart

VOLUME /usr/local/etc/php/conf.d/
VOLUME /var/www/
EXPOSE 9000
CMD tail -F /usr/local/etc/php/var/log/php-fpm.log

