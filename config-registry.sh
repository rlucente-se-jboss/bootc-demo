#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

#
# Setup for a local insecure registry
#
firewall-cmd --permanent --add-port=$REGISTRYPORT/tcp
firewall-cmd --reload

cat > /etc/containers/registries.conf.d/999-local-registry.conf <<EOF
[[registry]]
location = "$HOSTIP:$REGISTRYPORT"
insecure = true
EOF

# make local copy for later container build
cp /etc/containers/registries.conf.d/999-local-registry.conf .

#
# Create quadlet for registry service
#
mkdir -p /var/lib/registry

cat > /etc/containers/systemd/local-registry.container <<EOF
[Unit]
Description=A simple local registry

[Container]
Image=docker.io/library/registry:2
ContainerName=registry
PublishPort=$REGISTRYPORT:$REGISTRYPORT
Volume=/var/lib/registry:/var/lib/registry:Z

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF

#
# Launch the local registry
#
systemctl daemon-reload
systemctl start local-registry
