#!/bin/bash

#
# Copyright (C) 2021-2022 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#


die() {
   echo "$@"
   exit 1
}

if [ -z "${TARGET_PRODUCT}" ]; then
   die "TARGET_PRODUCT environment variable is not set. Run lunch first."
fi

if [ -z "${ANDROID_PRODUCT_OUT}" ]; then
   die "ANDROID_PRODUCT_OUT environment variable is not set. Run lunch first."
fi

VERSION=RaspberryVanillaAOSP14
DATE=$(date +%Y%m%d)
IMGNAME=${VERSION}-${DATE}-${TARGET_PRODUCT}.img
IMGSIZE=7

echo "Creating image file ${ANDROID_PRODUCT_OUT}/${IMGNAME}..."
sudo dd if=/dev/zero of="${ANDROID_PRODUCT_OUT}/${IMGNAME}" bs=1M count=$(echo "${IMGSIZE}*1024" | bc)
sync

echo "Creating partitions..."
(
echo o
echo n
echo p
echo 1
echo
echo +128M
echo n
echo p
echo 2
echo
echo +2048M
echo n
echo p
echo 3
echo
echo +256M
echo n
echo p
echo
echo
echo t
echo 1
echo c
echo a
echo 1
echo w
) | sudo fdisk "${ANDROID_PRODUCT_OUT}/${IMGNAME}"
sync

LOOPDEV=$(sudo kpartx -av "${ANDROID_PRODUCT_OUT}/${IMGNAME}" | awk 'NR==1{ sub(/p[0-9]$/, "", $3); print $3 }')
if [ -z ${LOOPDEV} ]; then
  die "Unable to find loop device!"
fi
echo "Image mounted as /dev/${LOOPDEV}"
sleep 1

echo "Copying boot..."
sudo dd if=${ANDROID_PRODUCT_OUT}/boot.img of=/dev/mapper/${LOOPDEV}p1 bs=1M
echo "Copying system..."
sudo dd if=${ANDROID_PRODUCT_OUT}/system.img of=/dev/mapper/${LOOPDEV}p2 bs=1M
echo "Copying vendor..."
sudo dd if=${ANDROID_PRODUCT_OUT}/vendor.img of=/dev/mapper/${LOOPDEV}p3 bs=1M
echo "Creating userdata..."
sudo mkfs.ext4 /dev/mapper/${LOOPDEV}p4 -I 512 -L userdata
sync

sudo kpartx -d "/dev/${LOOPDEV}"

echo "Done, created ${ANDROID_PRODUCT_OUT}/${IMGNAME}!"
exit 0

