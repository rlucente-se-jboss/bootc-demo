# The bootc demo
yeah.

## Demo setup
Install a minimal CentOS Stream 9 instance.
Copy this repo to the CentOS Stream 9 instance.
Log into the CentOS Stream 9 instance.
Create an SSH keypair to access the edge device. Don't set a passphrase,
even though you really should, to make the demo a little easier.

    cd ~/rhel-image-mode
    ssh-keygen -t rsa -f ~/.ssh/id_core
    cp ~/.ssh/id_core.pub .

Edit `demo.conf` and make sure its what you want for the various variables.
Configure the demo.

    sudo ./register-and-update.sh
    sudo reboot
    sudo ./config-bootc.sh

## Demo
### Build the operating system image
Build the new operating system image.

    . demo.conf
    podman build -f Containerfile -t ${CONTAINER_REPO}

Test the operating system by running it as a normal container.

    podman run -d --rm --name lamp -p 8080:80 ${CONTAINER_REPO} /sbin/init
    curl http://localhost:8080 | grep -i image

Shell into the running container as well and explore the image.

    podman exec -it lamp /bin/bash
    exit

Stop the running container, which will also remove the container since
the `podman run` command included the `--rm` option.

    podman stop lamp

Push the new operating system image to your registry.

    . demo.conf
    podman login $(echo ${CONTAINER_REPO} | cut -d/ -f1)
    podman push ${CONTAINER_REPO}

Make sure this container repository is publicly accessible. You may need
to log in to your registry using a browser to do this.

### Deploy the image using an ISO file
Create the kickstart file.

    . demo.conf
    envsubst '$CONTAINER_IMAGE $EDGE_USER $EDGE_HASH $SSH_PUB_KEY' \
        < bootc-lamp.ks.orig > bootc-lamp.ks

Download the [CentOS Stream bootable ISO file](https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso).

Create a bootable ISO to install the operating system by embedding the
kickstart in the standard CentOS Stream bootable ISO.

    sudo mkksiso --ks bootc-lamp.ks $(ls CentOS-Stream-9*.iso) bootc-lamp.iso

Use the `bootc-lamp.iso` to boot a physical edge device or virtual
guest. This system should be able to access your registry to pull down
the image.

