FROM registry.redhat.io/rhel9/rhel-bootc:latest

# configure an insecure local registry
RUN  mkdir -p /etc/containers/registries.conf.d
COPY 999-local-registry.conf /etc/containers/registries.conf.d/

# install the LAMP components
RUN dnf module enable -y php:8.2 nginx:1.22 \
    && dnf install -y httpd mariadb mariadb-server php-fpm php-mysqlnd \
           firewalld \
    && dnf clean all

# configure firewall on first boot
RUN touch /etc/configure-firewall
COPY configure-firewall.service /etc/systemd/system/

# start the services automatically on boot
RUN systemctl enable httpd mariadb php-fpm sshd firewalld configure-firewall

# create an awe-inspiring home page!
RUN echo '<h1 style="text-align:center;">Welcome to RHEL Image Mode</h1><?php phpinfo();?>' >> /var/www/html/index.php

#
# The rest of this file is related to the DISA STIG for RHEL 9
#

# install the SCAP Security Guide tooling
RUN dnf -y install scap-security-guide

# mask the kdump service
RUN systemctl mask kdump.service

# add the tailored STIG rules
COPY ssg-rhel9-ds-tailoring-high-only.xml /usr/share/xml/scap/ssg/content/

# RHEL-09-671010 RHEL 9 must enable FIPS mode
# fips=1 is added to bootloader so enable fips crypto policy on first
# boot here and add fips dracut module
COPY   configure-fips-mode.service /etc/systemd/system/
RUN    touch /etc/configure-fips-mode \
    && systemctl enable configure-fips-mode \
    && mkdir -p /etc/dracut.conf.d \
    && echo "add_dracutmodules+=\" fips \"" >> /etc/dracut.conf.d/40-fips.conf

# add configuration to meet selected CAT I STIG rules

# RHEL-09-211045 the systemcd Ctrl-Alt-Delete burst key sequence in RHEL 9 must be disabled
RUN    sed -i 's/^#\(CtrlAltDelBurstAction=\)..*/\1none/g' /etc/systemd/system.conf

# RHEL-09-211050 The x86 Ctrl-Alt-Delete key sequence must be disabled on RHEL 9
RUN    systemctl disable ctrl-alt-del.target \
    && systemctl mask ctrl-alt-del.target

# RHEL-09-212020 RHEL 9 must require a unique superusers name upon booting into single-user and maintenance modes
RUN    sed -i 's/\(set superusers=\).*/\1"someuser"/g' /etc/grub.d/01_users

# RHEL-09-214020 RHEL 9 must check the GPG signature of locally installed software packages before installation
RUN    echo "localpkg_gpgcheck = 1" >> /etc/dnf/dnf.conf

# RHEL-09-255040 RHEL 9 SSHD must not allow blank passwords 
RUN    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config.d/00-complianceascode-hardening.conf \
    && echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config \
    && echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config.d/50-redhat.conf \
    && echo "PermitEmptyPasswords no" >> /etc/crypto-policies/back-ends/opensshserver.config

# RHEL-09-255050 RHEL 9 must enable the Pluggable Authentication Module (PAM) interface for SSHD
RUN    echo "UsePAM yes" >> /etc/ssh/sshd_config \
    && echo "UsePAM yes" >> /etc/ssh/sshd_config.d/50-redhat.conf \
    && echo "UsePAM yes" >> /etc/crypto-policies/back-ends/opensshserver.config

# RHEL-09-611025 RHEL 9 must not allow blank or null passwords
RUN    sed -i 's/nullok//g' /etc/pam.d/system-auth \
    && sed -i 's/nullok//g' /etc/pam.d/password-auth

