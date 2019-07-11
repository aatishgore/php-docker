#FROM php:5.4-apache
FROM php:7.2-fpm

# Set working directory
WORKDIR /var/www


RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libicu-dev \
        libc6 \
        libaio1 \
        zlib1g \
        make \
        libcurl4-gnutls-dev \
        unzip \
        libcurl4-gnutls-dev \
        libxml2-dev \
        build-essential \
        mysql-client \
        locales \
        zip \
        jpegoptim optipng pngquant gifsicle \
        vim \
        git \
        curl \
        unixodbc \
        unixodbc-dev 
# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Uncomment if this u get pdo_oci.so error.
RUN rm -rf /usr/local/lib/php/extensions/no-debug-non-zts-20170718/pdo_oci.so 

RUN docker-php-ext-install intl mbstring sockets soap calendar

# installing oci8 for php7
ADD instantclient-basic-linux.x64-19.3.0.0.0dbru.zip /usr/local/
ADD instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip /usr/local/

RUN unzip /usr/local/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip -d /usr/local/
RUN unzip /usr/local/instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip  -d /usr/local/
RUN ln -s /usr/local/instantclient_19_3 /usr/local/instantclient

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient_19_3,19.3 \
       && echo 'instantclient,/usr/local/instantclient_19_3/' | pecl install oci8 \
       && docker-php-ext-install \
               pdo_oci \
       && docker-php-ext-enable \
               oci8
RUN ln -s /usr/local/instantclient_19_3/lib* /usr/lib
RUN ln -s /usr/local/lib/php/extensions/no-debug-non-zts-20170718/oci8.so \
        /usr/local/lib/php/extensions/no-debug-non-zts-20170718/oci8.so.so

# installing mssql(sql_srv)
RUN curl -o /tmp/msodbcsql17_17.0.1.1-1_amd64.deb https://packages.microsoft.com/debian/9/prod/pool/main/m/msodbcsql17/msodbcsql17_17.0.1.1-1_amd64.deb
RUN ACCEPT_EULA=Y dpkg -i /tmp/msodbcsql17_17.0.1.1-1_amd64.deb


# Install extensions
RUN docker-php-ext-install pdo pdo_mysql zip exif pcntl
RUN docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/
RUN docker-php-ext-install gd
#sql_srv extension
RUN pecl install sqlsrv pdo_sqlsrv\
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www


# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Change current user to www
USER www

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]