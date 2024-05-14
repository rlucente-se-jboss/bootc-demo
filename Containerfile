FROM registry.redhat.io/rhel9/rhel-bootc:latest

# install the LAMP components
RUN dnf module enable -y php:8.2 nginx:1.22 \
    && dnf install -y httpd mariadb mariadb-server php-fpm php-mysqlnd \
    && dnf clean all

# start the services automatically on boot
RUN systemctl enable httpd mariadb php-fpm

# create an awe-inspiring home page!
RUN echo '<h1 style="text-align:center;">Welcome to RHEL Image Mode</h1><?php phpinfo();?>' >> /var/www/html/index.php

