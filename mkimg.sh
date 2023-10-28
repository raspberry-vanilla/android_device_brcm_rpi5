#!/bin/bash

#
# Copyright (C) 2021-2022 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

VERSION=RaspberryVanillaAOSP14
DATE=$(date +%Y%m%d)
IMGNAME=${VERSION}-${DATE}-rpi5.img
IMGSIZE=7
OUTDIR=$(pwd | sed 's/\/device\/brcm\/rpi5$//')/out/target/product/rpi5

echo "Creating image file ${OUTDIR}/${IMGNAME}..."
sudo dd if=/dev/zero of="${OUTDIR}/${IMGNAME}" bs=1M count=$(echo "${IMGSIZE}*1024" | bc)
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
) | sudo fdisk "${OUTDIR}/${IMGNAME}"
sync

LOOPDEV=$(sudo kpartx -av "${OUTDIR}/${IMGNAME}" | awk 'NR==1{ sub(/p[0-9]$/, "", $3); print $3 }')
if [ -z ${LOOPDEV} ]; then
  echo "Unable to find loop device!"
  exit 1
fi
echo "Image mounted as /dev/${LOOPDEV}"
sleep 1

echo "Copying boot..."
sudo dd if=${OUTDIR}/boot.img of=/dev/mapper/${LOOPDEV}p1 bs=1M
echo "Copying system..."
sudo dd if=${OUTDIR}/system.img of=/dev/mapper/${LOOPDEV}p2 bs=1M
echo "Copying vendor..."
sudo dd if=${OUTDIR}/vendor.img of=/dev/mapper/${LOOPDEV}p3 bs=1M
echo "Creating userdata..."
sudo mkfs.ext4 /dev/mapper/${LOOPDEV}p4 -I 512 -L userdata
sync

sudo kpartx -d "/dev/${LOOPDEV}"
echo "Done, created ${OUTDIR}/${IMGNAME}!"

exit 0
