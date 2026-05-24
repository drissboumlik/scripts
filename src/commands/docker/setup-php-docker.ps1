

$APP_NAME = if (($value = Read-Host -Prompt "Enter the application name (myApp)").Trim()) { $value } else { "myApp" }
$TESTING_DATABASE = if (($value = Read-Host -Prompt "Enter the testing database name (laravel_test)").Trim()) { $value } else { "laravel_test" }
$DB_USERNAME = if (($value = Read-Host -Prompt "Enter the database username (db_user)").Trim()) { $value } else { "db_user" }
$APP_PORT = if (($value = Read-Host -Prompt "Enter the application port (8000)").Trim()) { $value } else { "8000" }


function Get-DockerComposeYml {
    return @"
name: ${APP_NAME}

services:
  app:
    build:
      context: ./.docker/app
      dockerfile: Dockerfile
    container_name: ${APP_NAME}
    restart: unless-stopped
    volumes:
      - .:/var/www/html:cached
      - vendor_data:/var/www/html/vendor:delegated
    networks:
      - ${APP_NAME}_NETWORK
    depends_on:
      - mysql

  webserver:
    image: nginx:latest
    container_name: ${APP_NAME}_WEB_SERVER
    restart: unless-stopped
    ports:
      - '`${APP_PORT}:`${APP_PORT}'
    volumes:
      - .:/var/www/html
      - ./.docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - ${APP_NAME}_NETWORK
    depends_on:
      - app

  mysql:
    image: mariadb:10
    container_name: ${APP_NAME}_MYSQL
    restart: unless-stopped
    ports:
      - '3308:3306'
    environment:
      MYSQL_DATABASE: '`${DB_DATABASE}'
      MYSQL_USER: '`${DB_USERNAME}'
      MYSQL_PASSWORD: '`${DB_PASSWORD}'
      MYSQL_ROOT_PASSWORD: '`${DB_PASSWORD}'
    volumes:
      - mysql_data:/var/lib/mysql
      - /dev/shm:/dev/shm # Use shared memory to speed up queries
      - ./.docker/mysql/init:/docker-entrypoint-initdb.d
    networks:
      - ${APP_NAME}_NETWORK

networks:
  ${APP_NAME}_NETWORK:
    name: ${APP_NAME}_NETWORK
    driver: bridge

volumes:
  mysql_data:
  vendor_data:
"@
}

function Get-NginxDefaultConf {
    return @"
server {
    listen ${APP_PORT};
    index index.php index.html;
    server_name localhost;
    root /var/www/html/public;

    client_max_body_size 50M;

    location / {
        try_files `$uri `$uri/ /index.php?`$query_string;
        add_header 'Access-Control-Allow-Origin' '*';
    }

    location ~* \.(ico|css|js|gif|jpe?g|png|woff2?|eot|ttf|svg)$ {
        expires 6M;
        access_log off;
        add_header Cache-Control "public, max-age=15552000";
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME `$document_root`$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_vary on;
}
"@
}

function Get-MySqlInitScript {
    return @"
CREATE DATABASE IF NOT EXISTS ${TESTING_DATABASE};
GRANT ALL PRIVILEGES ON ${TESTING_DATABASE}.* TO '${DB_USERNAME}'@'%';
FLUSH PRIVILEGES;
"@
}

function Get-AppDockerfile {
    return @"
# Use an official PHP image with required extensions
FROM php:8.1-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    unzip git curl libpng-dev libjpeg-dev libfreetype6-dev libonig-dev libzip-dev libwebp-dev libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd mbstring zip pdo pdo_mysql opcache exif

RUN pecl install xdebug && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug,coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
	&& echo "xdebug.log_level=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Install APCu (Alternative PHP Cache User)
RUN pecl install apcu && docker-php-ext-enable apcu

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js 18 and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Enable PHP Opcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=256" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=0" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.save_comments=1" >> /usr/local/etc/php/conf.d/opcache.ini

# Enable APCu
RUN echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/apcu.ini

COPY php.ini /usr/local/etc/php/conf.d/php.ini
"@
}

function Get-AppPhpIni {
    return @"
[PHP]
post_max_size = 100M
upload_max_filesize = 100M
variables_order = EGPCS
pcov.directory = .

memory_limit = 100M
zend.assertions = 1
display_errors = 1
display_startup_errors = 1
error_reporting = E_ALL
log_errors = 1
"@
}

# Create the directory structure
$root = ".docker"

# Create directories
$directories = @(
	"$root/app",
	"$root/mysql/init",
	"$root/nginx"
)

Write-Host "`n"

foreach ($dir in $directories) {
	if (-not (Test-Path -Path $dir)) {
		New-Item -ItemType Directory -Path $dir -Force | Out-Null
		# Write-Host "Created directory: $dir"
	}
}

# Create files with content
$files = [ordered]@{
	"$root/app/Dockerfile" = Get-AppDockerfile
	"$root/app/php.ini" = Get-AppPhpIni
	"$root/mysql/init/create-test-db.sql" = Get-MySqlInitScript
	"$root/nginx/default.conf" = Get-NginxDefaultConf
	"docker-compose.yml" = Get-DockerComposeYml
}

foreach ($file in $files.Keys) {
	Set-Content -Path $file -Value $files[$file]
	# Write-Host "Created file: $file"
}

Write-Host "`nDocker environment setup complete!" -ForegroundColor DarkGreen

Write-Host "`nDont't forget to edit the .env and .env.testing files." -ForegroundColor DarkYellow
Write-Host "`nYou can now run the following commands to start your Docker containers:"
Write-Host "`n> docker-compose build"
Write-Host "> docker-compose up -d"