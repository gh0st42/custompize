# customPIze

A minimal customizer for your Raspberry Pi images.

Main features:
- simple to use
- inspired by *pi-gen* run scripts
- input raw image OR zip file containing image
- *shrink image again after modification* (currently broken)

It should work with any linux distribution that ships a two partition (FAT + linux) disk image for Raspberry Pis. So far, it has only been tested with the official Raspbian images. The focus was on quickly building pre-configured minimal raspbian lite flavors.

## Installation

Just build the docker image:
```
./build.sh
```

## Usage

First a base image is needed for modification. A good starting point is the latest raspbian-lite:
```
wget https://downloads.raspberrypi.org/raspbian_lite_latest
```

Then a *Pifile* is needed as a blueprint for all the modifications that need to be performed.

### Creating a *Pifile*

A `Pifile` is a simple bash script for the modifications to be done to the provided input image.
There are two special helper functions:
- `increase <number_of_megabytes>` resizes the main linux partition
- `on_chroot` executes commands on the mounted system
- `${ROOTFS_DIR}` contains the mount path of the image

An example *Pifile* is provided under `example/`:
```bash
#!/bin/bash

increase 200
 
install -v -m 755 /data/test.sh		"${ROOTFS_DIR}/usr/bin/"

echo "!! Activating ssh"
touch "${ROOTFS_DIR}/boot/ssh"

on_chroot <<EOF
ifconfig
echo "on chroot"
/usr/bin/test.sh
apt-get update
apt-get -y dist-upgrade

echo "!! Changing password"
(echo "strawberry"; echo "strawberry") | passwd pi

echo "!! Changing hostname"
raspi-config nonint do_hostname bushbox

echo "!! Activating serial console"
raspi-config nonint do_serial 0
EOF
```

### Building a new image

The creation of an image itself can be easily done using the `custompize` helper script. It needs at least a *Pifile*, an input image and the desired output filename as parameters. Furthermore, an optional data directory can be supplied. This can contain additional scripts and data that should be made available to the build system.

Building a custom distribution using the above example *Pifile* and the script from `example/data/`:
```
./custompize example/Pifile ~/Downloads/pi/raspbian_lite_latest.zip /tmp/my_raspbian.img example/data
```

## Links

- https://github.com/Drewsif/PiShrink - Used to shrink the image
- https://gist.github.com/htruong/0271d84ae81ee1d301293d126a5ad716 - How to modify a raspbian image
- https://github.com/RPi-Distro/pi-gen - The official toolchain to build a raspbian image the slow way :)
- https://github.com/Nature40/pimod - More docker-like system to build pi images (I'm also more or less involved in this project)
