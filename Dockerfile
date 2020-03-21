FROM balenalib/rpi-raspbian:latest

MAINTAINER Habilis

# /usr/local/etc/php/conf.d
ENV PHP_DIR /usr/local/etc/php

# Add libraries directory
ADD ./lib /home/lib

RUN apt-get update && apt-transport-https && \
	apt-get install -y \
		zip \
		wget \
		curl \
		gnupg2 \
		imagemagick \
		ca-certificates \
		librecode0 \
		default-libmysqlclient-dev \
		libsqlite3-0 \
		libxml2 \
		autoconf \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkg-config \
		re2c \
		autoconf2.13 \
		libssl-dev \
		libcurl4-openssl-dev \
		libreadline6-dev \
		librecode-dev \
		libsqlite3-dev \
		libxml2-dev \
		libevent-dev \
		libjpeg-dev \
		libpng-dev \
		xz-utils \
		build-essential \
		libgd3 \
		libgd-dev \
		mcrypt \
		libmcrypt-dev \
		libbz2-dev \
		libffi-dev \
		libglib2.0-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmysqlclient-dev \
		libncurses-dev \
		libpq-dev \
		libreadline-dev \
		libxslt-dev \
		libyaml-dev \
		zlib1g-dev \
		tar \
	--no-install-recommends \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /var/www \
	&& chown -R www-data:www-data /var/www

RUN mkdir ~/.gnupg \
	&& echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
	&& cd /usr/local/include \
	&& ln -s /usr/include/arm-linux-gnueabihf/curl curl \
	&& mkdir -p $PHP_DIR/conf.d
	
WORKDIR /home/lib/

RUN tar -xzf openssl-1.0.2k.tar.gz -C openssl --strip-components=1 \
	&& cd openssl \
	&& ./config --prefix=/usr/local --openssldir=/usr/local/openssl \
	&& make && make install \
	&& cd .. \
	&& rm -rf openssl

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
		--with-libdir=/lib/arm-linux-gnueabihf \
		--enable-fpm \
		--with-fpm-user=www-data \
		--with-fpm-group=www-data \
		--disable-cgi \
		--enable-mysqlnd \
		--with-mysql=/usr/bin/mysql_config \
		--with-mysqli=/usr/bin/mysql_config \
		--with-curl \
		--with-openssl \
		--with-openssl-dir=/usr/local/openssl \
		--with-readline \
		--with-recode \
		--with-zlib \
		--with-gd \
		--with-freetype \
		--enable-gd-native-ttf \
	&& make -j"$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps

COPY ./conf/php-fpm.conf /usr/local/etc/php/conf.d/php-fpm.conf
COPY ./conf/php.ini /usr/local/etc/php/conf.d/php.ini

RUN if [ ! -d /etc/init.d ]; then mkdir /etc/init.d; fi

RUN cp /usr/src/php/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm \
	&& chmod 755 /etc/init.d/php-fpm \
	&& chmod +x /etc/init.d/php-fpm \
	&& update-rc.d php-fpm defaults \
	&& cd /usr/src/php \
	&& rm /usr/local/etc/php/conf.d/php-fpm.conf.default

VOLUME /var/www
EXPOSE 9000

CMD service php-fpm restart && tail -F /var/log/php-fpm.log
