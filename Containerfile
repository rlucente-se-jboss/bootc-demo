FROM registry.redhat.io/rhel9/rhel-bootc:latest

# install the LAMP components
RUN dnf module enable -y php:8.2 nginx:1.22 \
    && dnf install -y httpd mariadb mariadb-server php-fpm php-mysqlnd \
           firewalld scap-security-guide \
    && dnf clean all

# enable fips crypto policy on first boot
RUN touch /etc/configure-fips-mode
COPY configure-fips-mode.service /etc/systemd/system/

# configure firewall on first boot
RUN touch /etc/configure-firewall
COPY configure-firewall.service /etc/systemd/system/

# start the services automatically on boot
RUN systemctl enable httpd mariadb php-fpm sshd firewalld configure-fips-mode configure-firewall

# create an awe-inspiring home page!
RUN echo '<h1 style="text-align:center;">Welcome to RHEL Image Mode</h1><?php phpinfo();?>' >> /var/www/html/index.php

