FROM ubuntu:22.04

ARG PHP_VERSION=8.2.35

# Configure APT retries and timeouts
RUN echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries && \
  echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries && \
  echo 'Acquire::https::Timeout "30";' >> /etc/apt/apt.conf.d/80-retries

# Install core utilities, build tools and library headers from standard Ubuntu repositories
RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends \
  build-essential \
  pkg-config \
  autoconf \
  bison \
  re2c \
  ca-certificates \
  curl \
  wget \
  git \
  unzip \
  tzdata \
  mc \
  sudo \
  gnupg \
  libxml2-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  libpq-dev \
  libonig-dev \
  libzip-dev \
  libpng-dev \
  libjpeg-dev \
  libfreetype6-dev \
  libwebp-dev \
  libicu-dev \
  libmagickwand-dev \
  libc-client-dev \
  libkrb5-dev \
  libbrotli-dev \
  libreadline-dev \
  libsodium-dev \
  libsqlite3-dev \
  zlib1g-dev \
  libffi-dev \
  && rm -rf /var/lib/apt/lists/*

# Fix libc-client library link for imap extension if needed
RUN if [ ! -f /usr/lib/libc-client.a ] && [ -f /usr/lib/x86_64-linux-gnu/libc-client.a ]; then \
  ln -s /usr/lib/x86_64-linux-gnu/libc-client.a /usr/lib/libc-client.a; \
  fi

# Download and compile PHP from official source with FPM support
RUN mkdir -p /tmp/php-src && \
  ( curl -fsSL "https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz" -o /tmp/php.tar.gz || \
  curl -fsSL "https://museum.php.net/php8/php-${PHP_VERSION}.tar.gz" -o /tmp/php.tar.gz || \
  curl -fsSL "https://github.com/php/php-src/archive/refs/tags/php-${PHP_VERSION}.tar.gz" -o /tmp/php.tar.gz ) && \
  tar -xzf /tmp/php.tar.gz -C /tmp/php-src --strip-components=1 && \
  cd /tmp/php-src && \
  if [ ! -f ./configure ]; then ./buildconf --force; fi && \
  ./configure \
  --prefix=/usr \
  --with-pear \
  --with-config-file-path=/etc/php/8.2/fpm \
  --with-config-file-scan-dir=/etc/php/8.2/fpm/conf.d \
  --enable-fpm \
  --with-fpm-user=www-data \
  --with-fpm-group=www-data \
  --enable-cli \
  --disable-cgi \
  --enable-mbstring \
  --enable-intl \
  --enable-soap \
  --enable-opcache \
  --enable-bcmath \
  --enable-calendar \
  --enable-exif \
  --enable-ftp \
  --enable-pcntl \
  --enable-sockets \
  --with-curl \
  --with-openssl \
  --with-zlib \
  --with-pgsql \
  --with-pdo-pgsql \
  --with-mysqli=mysqlnd \
  --with-pdo-mysql=mysqlnd \
  --with-zip \
  --with-readline \
  --with-sodium \
  --enable-gd \
  --with-freetype \
  --with-jpeg \
  --with-webp \
  --with-imap \
  --with-imap-ssl \
  --with-kerberos && \
  make -j$(nproc) && \
  make install && \
  mkdir -p /etc/php/8.2/fpm/conf.d /etc/php/8.2/fpm/pool.d /run/php /var/log && \
  ln -s /etc/php/8.2/fpm /etc/php/8.2/cli && \
  ln -s /usr/sbin/php-fpm /usr/sbin/php-fpm8.2 && \
  cd / && rm -rf /tmp/php-src /tmp/php.tar.gz

# Compile imagick from source
RUN git clone --depth 1 https://github.com/Imagick/imagick.git /tmp/imagick && \
  cd /tmp/imagick && \
  phpize && \
  ./configure && \
  make -j$(nproc) && \
  make install && \
  echo "extension=imagick.so" > /etc/php/8.2/fpm/conf.d/20-imagick.ini && \
  cd / && rm -rf /tmp/imagick

# Install Node.js
RUN mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && apt-get install -y --no-install-recommends nodejs && \
  rm -rf /var/lib/apt/lists/*


WORKDIR /var/www/html

RUN npm install --save-dev chokidar

# Create non-root user matching host IDs
ARG user_id
ARG group_id
ARG user

RUN groupadd --gid $group_id $user \
  && useradd --uid $user_id --gid $group_id -m $user \
  && echo $user ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$user \
  && chmod 0440 /etc/sudoers.d/$user

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
  php -r "unlink('composer-setup.php');" && \
  chmod a+x /usr/local/bin/composer

# Copy PHP and FPM configurations
RUN chown -R www-data:www-data /run/php

COPY ./conf/php.ini /etc/php/8.2/fpm/php.ini
COPY ./conf/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
RUN echo "clear_env = no" >> /etc/php/8.2/fpm/pool.d/www.conf

COPY ./web .
USER ${user}

RUN sudo chmod -R a+w /var/log
ENTRYPOINT sudo /usr/sbin/php-fpm8.2 --nodaemonize --fpm-config /etc/php/8.2/fpm/php-fpm.conf
