#!/bin/bash

# mount_image mounts the given image file as a loop device and "returns"/prints
# the name of the loop device (e.g. loop0).
# Usage: mount_image PATH_TO_IMAGE
mount_image() {
  kpartx -avs "$1" \
    | sed -E 's/.*(loop[0-9])p.*/\1/g' \
    | head -n 1
}

# umount_image unmounts the given image file, mounted with mount_image.
# Usage: umount_image PATH_TO_IMAGE
umount_image() {
  kpartx -d "$1"
  dmsetup remove_all
}

function increase {
 :
}

function on_chroot {
    chroot $ROOTFS_DIR "$@"
}

export ROOTFS_DIR=/mnt/dist
mkdir -p $ROOTFS_DIR

if [ ! -f /Pifile ]; then
 echo "Pifile not found!"
 exit 1
fi

if [ ! -f /input.img ]; then
 echo "input.img not found!"
 exit 1
fi

if [ ! -f /output.img ]; then
 echo "output.img not found!"
 exit 1
fi

echo "+ Inspecting input.img"
ISZIP=$(file input.img | grep -o "Zip archive" | wc -l | awk '{print $NF}')
if [ $ISZIP -eq 0 ]; then
#    echo "Not a zip file";
    NUMPARTS=$(file /input.img | grep -o "partition [0-9]" | wc -l | awk '{print $NF}')
    if [ $NUMPARTS -eq 2 ]; then
        echo "+ Found 2 partitions"
        echo "+ Copying image"
        pv /input.img > /output.img
    else
        echo "Wrong number of partitions, aborting."
        exit 1;
    fi
else
#    echo "Is a zip file"
    NUMIMGS=$(zipinfo /input.img | sed 1,1d | awk '{print $NF}' | grep -o '.*img$' | wc -l | awk '{print $NF}')
    if [ $NUMIMGS -ne 1 ]; then
        echo "+ No suitable img found in ZIP archive, aborting."
        exit 1
    fi
    IMGNAME=$(zipinfo /input.img | sed 1,1d | awk '{print $NF}' | grep -o '.*img$')
    echo "+ Extracting $IMGNAME"
    7z e /input.img -o/tmp $IMGNAME && pv /tmp/$IMGNAME > /output.img
    #7z e /input.img -so $IMGNAME | pv > /output.img
fi

INC_SIZE=$(cat /Pifile | grep -o '^\s*increase\s*[0-9]*$' | awk '{print $NF}' | tail -n1)
echo "+ Increasing image by $INC_SIZE MB"
dd if=/dev/zero bs=1M count=$INC_SIZE >> /output.img

echo "+ Attaching image"

loop=$(mount_image /output.img)
e2fsck -fy "/dev/mapper/${loop}p2"
resize2fs "/dev/mapper/${loop}p2"
fdisk -l "/dev/${loop}"
echo "+ Detaching image"
umount_image /output.img

echo "+ Performing installation"
loop=$(mount_image /output.img)
# mount partition
mount -o rw /dev/mapper/${loop}p2  $ROOTFS_DIR
mount -o rw /dev/mapper/${loop}p1 ${ROOTFS_DIR}/boot

# mount binds
mount --bind /dev ${ROOTFS_DIR}/dev/
mount --bind /sys ${ROOTFS_DIR}/sys/
mount --bind /proc ${ROOTFS_DIR}/proc/
mount --bind /dev/pts ${ROOTFS_DIR}/dev/pts

# ld.so.preload fix
sed -i 's/^/#/g' ${ROOTFS_DIR}/etc/ld.so.preload

# copy qemu binary
cp /usr/bin/qemu-arm-static ${ROOTFS_DIR}/usr/bin/

source /Pifile

# revert ld.so.preload fix
sed -i 's/^#//g' ${ROOTFS_DIR}/etc/ld.so.preload

umount ${ROOTFS_DIR}/{dev/pts,dev,sys,proc,boot,}

umount_image /output.img

#/pishrink.sh /output.img
echo "+ Modifying image complete"