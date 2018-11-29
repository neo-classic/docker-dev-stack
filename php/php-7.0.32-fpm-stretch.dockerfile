FROM php:7.0.32-fpm-stretch

COPY php.ini /usr/local/etc/php/

COPY GeoIP/GeoLite2-City.mmdb /usr/share/GeoIP/
RUN chmod +r /usr/share/GeoIP/GeoLite2-City.mmdb

RUN docker-php-ext-install pdo pdo_mysql mbstring iconv opcache mysqli

# Common utils
RUN apt-get update && apt-get install -y git

# Zip
RUN apt-get update && apt-get install -y zlib1g-dev \
    && docker-php-ext-install zip

# XML
RUN apt-get update && \
    apt-get install -y libxml2-dev && \
    docker-php-ext-install xml xmlwriter

# GD
RUN apt-get update && apt-get install -y \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
		libpng-dev \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) gd

# Imagemagick
RUN apt-get update && apt-get -y install libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && rm -r /var/lib/apt/lists/*

# MongoDB
RUN apt-get update && apt-get install -y pkg-config libssl-dev
RUN mkdir /src && cd /src && git clone https://github.com/mongodb/mongo-php-driver.git \
    && cd mongo-php-driver && git submodule update --init \
    && phpize && ./configure --with-php-config=/usr/local/bin/php-config --with-mongodb-ssl=openssl \
    && make all && make install \
    && docker-php-ext-enable mongodb \
    && cd  / && rm -fr /src

# Memcached
RUN apt-get update && apt-get install -y libmemcached-dev libpq-dev \
    && curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz

# GOLANG
RUN apt-get update && apt-get install --no-install-recommends --assume-yes --quiet ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.10.1.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH

# Mail
RUN go get github.com/mailhog/mhsendmail && cp /root/go/bin/mhsendmail /usr/local/bin/mhsendmail

RUN apt-get update && apt-get install -y pdftk

WORKDIR /var/www

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require "fxp/composer-asset-plugin:@dev" \
    && composer global require "hirak/prestissimo"

#RUN usermod -u 1000 www-data
#RUN chown www-data:www-data /var/www -R
#USER www-data

CMD ["php-fpm"]