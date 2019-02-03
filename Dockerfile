FROM php:7.1-apache-stretch

ADD root/ /
# Fix the original permissions of /tmp, the PHP default upload tmp dir.
RUN chmod 777 /tmp && chmod +t /tmp

# Setup the required extensions.
ARG DEBIAN_FRONTEND=noninteractive
RUN /tmp/setup/php-extensions.sh
RUN /tmp/setup/oci8-extension.sh
ENV LD_LIBRARY_PATH /usr/local/instantclient

RUN mkdir /var/www/moodledata && chown www-data /var/www/moodledata
#   && \
#    mkdir /var/www/phpunitdata && chown www-data /var/www/phpunitdata && \
#    mkdir /var/www/behatdata && chown www-data /var/www/behatdata && \
#    mkdir /var/www/behatfaildumps && chown www-data /var/www/behatfaildumps

#    && add-apt-repository "deb [arch=amd64] http://deb.debian.org/debian \
#       $(lsb_release -cs) universe" \

RUN apt-get update && apt-get -y dist-upgrade \
    && apt-get install -y lsb-release apt-utils software-properties-common \
    && apt-get install -y supervisor cron
    
COPY launch /launch
RUN chmod +x /launch/entrypoint.sh

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
  && sed \
  -e "s/upload_max_filesize = 2M/upload_max_filesize = 50M/" \
  -e "s/post_max_size = 8M/post_max_size = 50M/" \
  -i /usr/local/etc/php/php.ini

ENTRYPOINT ["/tini", "-s", "--"]
CMD ["/bin/bash", "-c", "/launch/entrypoint.sh"] 
