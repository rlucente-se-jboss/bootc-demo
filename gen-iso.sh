#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

cat > bootc-lamp.ks <<EOF
#
# kickstart to pull down and install OCI container as the operating system
#

text
network --bootproto=dhcp --device=link --activate

# Basic partitioning
clearpart --all --initlabel --disklabel=gpt
reqpart --add-boot
part / --grow --fstype xfs

# Here's where we reference the container image to install--notice the kickstart
# has no '%packages' section! What's being installed here is a container image.
ostreecontainer --url ${CONTAINER_REPO}:prod

# optionally add a user
user --name ${EDGE_USER} --groups wheel --iscrypted --password ${EDGE_HASH}
sshkey --username ${EDGE_USER} "${SSH_PUB_KEY}"

reboot
EOF

if [ "$REGISTRYINSECURE" = true ]
then
    cat >> bootc-lamp.ks << EOF1

%pre
mkdir -p /etc/containers/registries.conf.d
cat > /etc/containers/registries.conf.d/999-local-registry.conf << EOF
[[registry]]
location = "$HOSTIP:$REGISTRYPORT"
insecure = true
EOF
%end
EOF1
fi

rm -f bootc-lamp.iso
mkksiso --ks bootc-lamp.ks --cmdline "$BOOT_ARGS" $BOOT_ISO bootc-lamp.iso

