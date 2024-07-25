#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

dnf -y install container-tools lorax scap-security-guide xmlstarlet openscap-utils

firewall-cmd --permanent --add-port=${HOSTPORT}/tcp
firewall-cmd --reload

