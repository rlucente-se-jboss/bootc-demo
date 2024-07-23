#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

subscription-manager register \
    --username $SCA_USER --password $SCA_PASS || exit 1
subscription-manager role --set="RHEL Server"
subscription-manager service-level --set="Self-Support"
subscription-manager usage --set="Development/Test"

dnf -y update
dnf -y clean all

