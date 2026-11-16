#
# Copyright (C) 2021-2022 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/brcm/rpi5
KERNEL_PATH := device/brcm/rpi5-kernel

BOOT_FILES := $(wildcard $(DEVICE_PATH)/boot/*)
KERNEL_FILES := $(KERNEL_PATH)/Image $(wildcard $(KERNEL_PATH)/bcm2712*.dtb)
KERNEL_OVERLAY_FILES := $(wildcard $(KERNEL_PATH)/overlays/*)

$(INSTALLED_BOOTIMAGE_TARGET): $(BOOT_FILES) $(INSTALLED_RAMDISK_TARGET) $(KERNEL_FILES) $(KERNEL_OVERLAY_FILES)
	$(call pretty,"Target boot image: $@")
	dd if=/dev/zero of=$@ bs=1M count=128
	mkfs.fat -F 32 -n "boot" $@
	mmd -i $@ overlays
	echo $(BOARD_KERNEL_CMDLINE) > $(PRODUCT_OUT)/cmdline.txt
	mcopy -i $@ $(PRODUCT_OUT)/cmdline.txt ::
	mcopy -i $@ $(PRODUCT_OUT)/ramdisk.img ::
	$(foreach FILE,$(BOOT_FILES),$(shell mcopy -i $@ $(FILE) ::))
	$(foreach FILE,$(KERNEL_FILES),$(shell mcopy -i $@ $(FILE) ::))
	$(foreach FILE,$(KERNEL_OVERLAY_FILES),$(shell mcopy -i $@ $(FILE) ::overlays))
