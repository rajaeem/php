# syntax=docker/dockerfile:1

ARG PHP_VERSION=7.4

FROM php:${PHP_VERSION}-fpm-alpine

# Set to "true" to install ionCube, or "false" to skip
ARG WITH_IONCUBE=true

LABEL maintainer="info@persiannit.net" \
      org.opencontainers.image.title="PersianNIT PHP Apache Alpine" \
      org.opencontainers.image.description="All-in-one PHP-FPM + Apache Alpine image with ionCube & Cron support" \
      org.opencontainers.image.vendor="PersianNIT"

###############################################################################
# 1. Update Base System & Install Tools + Apache + Cron
###############################################################################
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache \
        bash \
        dcron \
        unzip \
        zip \
        curl \
        wget \
        git \
        tzdata \
        ca-certificates \
        gettext \
        apache2 \
        apache2-proxy

###############################################################################
# 2. Install PHP Extensions
###############################################################################
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions \
        mysqli \
        pdo_mysql \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        soap \
        xsl \
        zip \
        opcache \
        redis \
        imagick \
        xmlrpc \
        curl

###############################################################################
# 3. Conditional ionCube Installation
###############################################################################
COPY ioncube_loaders_lin-musl_x86-64.tar.gz /tmp/ioncube.tar.gz

RUN if [ "$WITH_IONCUBE" = "true" ]; then \
        PHP_EXT_DIR=$(php -r "echo ini_get('extension_dir');"); \
        PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;"); \
        if [ -f /tmp/ioncube.tar.gz ]; then \
            tar -xzf /tmp/ioncube.tar.gz -C /tmp && \
            LOADER_FILE=$(find /tmp/ioncube -type f -name "ioncube_loader_lin*${PHP_VER}*.so" | head -n 1); \
            if [ -n "$LOADER_FILE" ] && [ -f "$LOADER_FILE" ]; then \
                cp "$LOADER_FILE" "${PHP_EXT_DIR}/" && \
                LOADER_NAME=$(basename "$LOADER_FILE"); \
                echo "zend_extension=${PHP_EXT_DIR}/${LOADER_NAME}" > /usr/local/etc/php/conf.d/00-ioncube.ini && \
                echo "ionCube installed successfully (${LOADER_NAME})."; \
            else \
                echo "Error: ionCube loader for PHP ${PHP_VER} not found in archive."; \
                exit 1; \
            fi && \
            rm -rf /tmp/ioncube*; \
        else \
            echo "Error: /tmp/ioncube.tar.gz not found."; \
            exit 1; \
        fi; \
    else \
        echo "--> Skipping ionCube installation (WITH_IONCUBE=false)"; \
        rm -f /tmp/ioncube.tar.gz; \
    fi

###############################################################################
# 4. Configure Apache for Proxy FCGI & SSL Termination Fixes
###############################################################################
RUN mkdir -p /run/apache2 /var/www/html && \
    sed -i 's#^DocumentRoot ".*"#DocumentRoot "/var/www/html"#' /etc/apache2/httpd.conf && \
    sed -i 's#<Directory "/var/www/localhost/htdocs">#<Directory "/var/www/html">#' /etc/apache2/httpd.conf && \
    sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule proxy_module/LoadModule proxy_module/' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule proxy_fcgi_module/LoadModule proxy_fcgi_module/' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule remoteip_module/LoadModule remoteip_module/' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule headers_module/LoadModule headers_module/' /etc/apache2/httpd.conf && \
    echo 'DirectoryIndex index.php index.html' >> /etc/apache2/httpd.conf && \
    echo '<FilesMatch \.php$>' >> /etc/apache2/httpd.conf && \
    echo '    SetHandler "proxy:fcgi://127.0.0.1:9000"' >> /etc/apache2/httpd.conf && \
    echo '</FilesMatch>' >> /etc/apache2/httpd.conf && \
    echo 'SetEnvIf X-Forwarded-Proto "https" HTTPS=on' >> /etc/apache2/httpd.conf && \
    echo 'RemoteIPHeader X-Forwarded-For' >> /etc/apache2/httpd.conf

###############################################################################
# 5. Directory Structure Setup
###############################################################################
RUN mkdir -p \
        /usr/local/etc/php/custom.d \
        /var/www/html/uploads \
        /var/www/html/cache \
        /var/www/html/storage \
        /var/www/html/logs \
        /var/www/html/tmp \
        /var/www/html/sessions \
        /etc/cron.d

###############################################################################
# 6. Scripts & Healthcheck
###############################################################################
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

WORKDIR /var/www/html

HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=20s \
            --retries=3 \
CMD ["/usr/local/bin/healthcheck.sh"]

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]