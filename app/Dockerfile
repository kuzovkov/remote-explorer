FROM ubuntu:22.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata curl wget mc
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    dpkg -l | grep php | tee packages.txt && \
    add-apt-repository -y ppa:ondrej/php
RUN apt-get update && \
    apt-get install -y php8.2 && \
    apt-get install -y php8.2-cli && \
    apt-get install -y php8.2-curl && \
    apt-get install -y php8.2-pdo && \
    apt-get install -y php8.2-pgsql
RUN apt-get install -y php8.2-dom && \
    apt-get install -y php8.2-imagick && \
    apt-get install -y php8.2-mbstring && \
    apt-get install -y php8.2-zip && \
    apt-get install -y php8.2-gd && \
    apt-get install -y php8.2-intl

RUN apt-get install -y apt-transport-https ca-certificates build-essential libpq-dev libssl-dev openssl libffi-dev zlib1g-dev curl unzip libgconf-2-4
RUN apt-get install -y software-properties-common

# install node.js
#RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
#RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
#    apt-get install -y nodejs
################

RUN apt-get update && apt-get install -y ca-certificates curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
ENV NODE_MAJOR=18
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install nodejs -y

WORKDIR /var/www/html

RUN npm install --save-dev chokidar

# Create the user
ARG user_id
ARG group_id
ARG user

RUN groupadd --gid $group_id $user \
    && useradd --uid $user_id --gid $group_id -m $user \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $user ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$user \
    && chmod 0440 /etc/sudoers.d/$user

#Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
php -r "unlink('composer-setup.php');" && \
chmod a+x /usr/local/bin/composer
RUN apt-get update && apt-get install -y php8.2-soap  php8.2-fpm
USER ${user}
COPY ./web .
COPY ./conf/php.ini /etc/php/8.2/fpm/php.ini
RUN sudo chmod -R a+w /var/log
ENTRYPOINT sudo /usr/sbin/php-fpm8.2 --nodaemonize --fpm-config /etc/php/8.2/fpm/php-fpm.conf
