#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"
[[ -z $SUDO_USER ]] && exit_on_error "Must run using sudo"

dnf -y install container-tools lorax scap-security-guide

sudo -u $SUDO_USER mkdir -p /home/$SUDO_USER/.config/containers
sudo -u $SUDO_USER cat > /home/$SUDO_USER/.config/containers/registries.conf <<EOF
# we'll be using only these

[registries.search]
registries = ['registry.redhat.io','quay.io']

EOF

firewall-cmd --permanent --add-port=${HOSTPORT}/tcp
firewall-cmd --reload

