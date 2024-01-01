FROM php:8.3-apache

RUN set -xe; \
    apt update; \
    apt install unzip

COPY ./runtimes/001_apache_mod_php_prefork/sites-enabled/symfony7site.local.conf /etc/apache2/sites-available/symfony7site.local.conf
RUN a2ensite symfony7site.local

COPY ./runtimes/001_apache_mod_php_prefork/mods-available/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf
COPY ./runtimes/001_apache_mod_php_prefork/mods-available/status.conf /etc/apache2/mods-available/status.conf

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions \
        exif \
        intl \
        opcache \
        pdo_pgsql \
        tidy \
        gd \
        bcmath \
        sockets \
        zip && \
    install-php-extensions @composer;

#COPY --chown=www-data:www-data ../../projects/symfony-7 /var/www/symfony
COPY "./projects/symfony-7" "/var/www/symfony"

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini;
COPY ./runtimes/001_apache_mod_php_prefork/php.ini /usr/local/etc/php/conf.d/custom-php.ini

WORKDIR /var/www/symfony

RUN cp .env.example .env.local

RUN rm -rf vendor && \
    composer install --no-dev --no-scripts --prefer-dist --no-interaction && \
    composer dump-autoload --no-dev --classmap-authoritative && \
    composer check-platform-reqs && \
    php bin/console cache:clear && \
    php bin/console cache:warmup


