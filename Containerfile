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

# add the tailored STIG rules
COPY ssg-rhel9-ds-tailoring-high-only.xml /usr/share/xml/scap/ssg/content/

# add configuration to meet CAT I STIG rules
#     xccdf_org.ssgproject.content_rule_ensure_gpgcheck_local_packages
#     xccdf_org.ssgproject.content_rule_disable_ctrlaltdel_burstaction
#     xccdf_org.ssgproject.content_rule_disable_ctrlaltdel_reboot
#     xccdf_org.ssgproject.content_rule_no_empty_passwords
#     xccdf_org.ssgproject.content_rule_grub2_admin_username
#     xccdf_org.ssgproject.content_rule_sshd_disable_empty_passwords
RUN    echo "localpkg_gpgcheck = 1" >> /etc/dnf/dnf.conf \
    && sed -i 's/^#\(CtrlAltDelBurstAction=\)..*/\1none/g' /etc/systemd/system.conf \
    && rm -f /etc/systemd/system/ctrl-alt-del.target \
    && systemctl mask ctrl-alt-del.target \
    && sed -i 's/nullok//g' /etc/pam.d/system-auth \
    && sed -i 's/nullok//g' /etc/pam.d/password-auth \
    && sed -i 's/\(set superusers=\).*/\1"someuser"/g' /etc/grub.d/01_users \
    && echo "PermitEmptyPasswords no" > /etc/ssh/sshd_config.d/00-complianceascode-hardening.conf

# create an awe-inspiring home page!
RUN echo '<h1 style="text-align:center;">Welcome to RHEL Image Mode</h1><?php phpinfo();?>' >> /var/www/html/index.php

