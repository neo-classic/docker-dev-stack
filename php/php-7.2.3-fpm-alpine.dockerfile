FROM php:7.2.3-fpm-alpine

COPY php.ini /usr/local/etc/php/

RUN apk add --update imagemagick-dev libmcrypt-dev autoconf g++ libtool make icu-dev libxml2-dev openssl openssl-dev

RUN docker-php-ext-install pdo pdo_mysql mbstring iconv opcache mysqli xml

RUN apk add --no-cache git freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev && \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN pecl install imagick && docker-php-ext-enable imagick

RUN mkdir /src && cd /src && git clone https://github.com/mongodb/mongo-php-driver.git \
    && cd mongo-php-driver && git submodule update --init \
    && phpize && ./configure --with-php-config=/usr/local/bin/php-config --with-mongodb-ssl=openssl \
    && make all && make install \
    && docker-php-ext-enable mongodb \
    && cd  / && rm -fr /src

# To configure PhpStorm https://blog.philipphauer.de/debug-php-docker-container-idea-phpstorm/
RUN mkdir /src && cd /src && git clone https://github.com/xdebug/xdebug.git \
    && cd xdebug \
    && sh ./rebuild.sh \
    && echo "[xdebug]" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "zend_extension=xdebug.so" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_handler=dbgp" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.remote_connect_back=on" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=IDEA_DEBUG" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && cd  / && rm -fr /src

RUN apk del --no-cache autoconf g++ libtool make && rm -rf /tmp/* /var/cache/apk/* /var/lib/apt/lists/*

WORKDIR /var/www

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require "fxp/composer-asset-plugin:@dev" \
    && composer global require "hirak/prestissimo"

CMD ["php-fpm"]