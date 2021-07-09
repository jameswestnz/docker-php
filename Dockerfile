ARG PHP_VERSION
FROM php:${PHP_VERSION}-apache

ARG WORKDIR=/srv

ARG SYSTEM_PACKAGES
ARG PECL_EXTENSIONS
ARG PHP_EXTENSIONS_INSTALL
ARG PHP_EXTENSIONS_ENABLE
ARG APACHE_MODULES_ENABLE

ENV SYSTEM_PACKAGES_DEFAULT \
  # for: intl
  libicu-dev \
  # for: uuid
  uuid-dev \
  # for: PHP ZipArchive
  zip \
  libzip-dev

ENV PECL_EXTENSIONS_DEFAULT \
  # for: frameworks/Wordpress etc
  uuid \
  # for: PhpRedis
  redis \
  # for: debugging
  xdebug

ENV PHP_EXTENSIONS_INSTALL_DEFAULT \
  # for: frameworks/Wordpress etc
  bcmath\
  intl \
  mysqli \
  pcntl \
  pdo_mysql \
  # for: PHP ZipArchive
  zip

ENV PHP_EXTENSIONS_ENABLE_DEFAULT \
  opcache \
  redis \
  uuid \
  xdebug

ENV APACHE_MODULES_ENABLE_DEFAULT \
  deflate \
  expires \
  filter \
  headers \
  mime \
  rewrite

ENV APACHE_DOCUMENT_ROOT ${WORKDIR}/public

# copy helper scripts
COPY docker-php-* /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-*

# install dependencies
RUN set -eux; \
	apt-get update; \
  apt-get install -y --no-install-recommends $(docker-php-arg-modifier "${SYSTEM_PACKAGES_DEFAULT}" "$(echo ${SYSTEM_PACKAGES} | xargs)"); \
  rm -rf /var/lib/apt/lists/*;

# install PECL extensions
RUN set -eux; \
  pecl channel-update pecl.php.net; \
  pecl install -o -f $(docker-php-arg-modifier "${PECL_EXTENSIONS_DEFAULT}" "$(echo ${PECL_EXTENSIONS} | xargs)"); \
  rm -rf /tmp/pear;

# install PHP extensions
RUN docker-php-ext-install $(docker-php-arg-modifier "${PHP_EXTENSIONS_INSTALL_DEFAULT}" "$(echo ${PHP_EXTENSIONS_INSTALL} | xargs)")

# enable PHP extensions
RUN docker-php-ext-enable $(docker-php-arg-modifier "${PHP_EXTENSIONS_ENABLE_DEFAULT}" "$(echo ${PHP_EXTENSIONS_ENABLE} | xargs)")

# set default timezone
RUN printf '[PHP]\ndate.timezone = "UTC"\n' > /usr/local/etc/php/conf.d/docker-php-date.ini

# enable Apache modules
RUN a2enmod $(docker-php-arg-modifier "${APACHE_MODULES_ENABLE_DEFAULT}" "$(echo ${APACHE_MODULES_ENABLE} | xargs)")

# configure document root
RUN set -eux; \
  mkdir -p ${APACHE_DOCUMENT_ROOT}; \
  sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/sites-available/*.conf; \
  sed -ri -e "s!/var/www/!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf;

WORKDIR ${WORKDIR}
