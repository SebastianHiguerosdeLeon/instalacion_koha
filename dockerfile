FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV KOHA_INSTANCE=biblioteca

RUN apt-get update && apt-get install -y \
    wget\
    gnupg2\
    ca-certificates\
    apt-transport-https\
    lsb-release\
    mariadb-client\
    netcat\
    && rm -rf /var/lib/apt/lists/*

RUN echo "deb http://debian.koha-community.org/koha stable main" > /etc/apt/sources.list.d/koha.list \
    && wget -qO- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

RUN apt-get update && apt-get install -y\
    koha-common\
    apache2\
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod rewrite\
    && a2enmod cgi\
    && a2enmod headers\
    && a2enmod proxy_http\
    && a2enmod ssl

RUN a2dissite 002-default

COPY docker-entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80 8080

VOLUME ["var/lib/koha", "/etc/koha"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2ctl", "-D", "FOREGROUND"]


