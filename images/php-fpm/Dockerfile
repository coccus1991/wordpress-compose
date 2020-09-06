FROM php:7.4-fpm

# Download script to install PHP extensions and dependencies
ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
      curl \
      git \
      zip unzip \
    && install-php-extensions \
      bcmath \
      bz2 \
      calendar \
      exif \
      gd \
      intl \
      ldap \
      memcached \
      mysqli \
      opcache \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      redis \
      soap \
      xsl \
      zip \
      sockets

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1

# Install prestissimo (composer plugin). Plugin that downloads packages in parallel to speed up the installation process
# After release of Composer 2.x, remove prestissimo, because parallelism already merged into Composer 2.x branch:
# https://github.com/composer/composer/pull/7904
RUN composer global require hirak/prestissimo

RUN apt update
RUN apt-get install wget git default-mysql-client -y
RUN cd /home
RUN wget https://phar.phpunit.de/phpunit-5.1.3.phar 
RUN mv phpunit-5.1.3.phar /usr/local/bin/phpunit
RUN chmod +x /usr/local/bin/phpunit
RUN id -u www-data &>/dev/null || useradd -m www-data
RUN mkdir /home/shared -p && chown -R www-data:www-data /home/shared
RUN mkdir /websites && chown -R www-data:www-data /websites
WORKDIR /websites
RUN chsh -s /bin/bash www-data
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp
