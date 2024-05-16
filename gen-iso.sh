#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"
[[ -z $SUDO_USER ]] && exit_on_error "Must run using sudo"

# generate a blueprint to extract the kernel arguments (and append fips=1
# to them)

oscap xccdf generate fix \
    --fetch-remote-resources \
    --profile xccdf_org.ssgproject.content_profile_stig \
    --fix-type blueprint /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml \
> pre-stig-blueprint.toml
export BOOT_ARGS="fips=1 $(grep -A2 customizations.kernel pre-stig-blueprint.toml | grep append | cut -d\" -f2)"
rm -f pre-stig-blueprint.toml

# generate the grub password

export BOOT_HASH="$(printf "$BOOT_PASS\n$BOOT_PASS" | grub2-mkpasswd-pbkdf2 | grep grub | rev | cut -d' ' -f1 | rev)"

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

# bootloader with crypted password and kernel args
bootloader --append="$BOOT_ARGS" --iscrypted --password=$BOOT_HASH

# Here's where we reference the container image to install--notice the kickstart
# has no '%packages' section! What's being installed here is a container image.
ostreecontainer --url ${CONTAINER_REPO}:prod

firewall --enabled --ssh --http
services --enabled=sshd

# optionally add a user
user --name ${EDGE_USER} --groups wheel --iscrypted --password ${EDGE_HASH}
sshkey --username ${EDGE_USER} "${SSH_PUB_KEY}"

reboot
EOF

rm -f bootc-lamp.iso
mkksiso --ks bootc-lamp.ks --cmdline "$BOOT_ARGS" $BOOT_ISO bootc-lamp.iso

