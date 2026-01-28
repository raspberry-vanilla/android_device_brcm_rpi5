#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/brcm/rpi5

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, frameworks/native/build/tablet-7in-xhdpi-2048-dalvik-heap.mk)
$(call inherit-product, vendor/brcm/rpi5/rpi5-vendor.mk)

# APEX
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)
OVERRIDE_PRODUCT_COMPRESSED_APEX := false

# API level
PRODUCT_SHIPPING_API_LEVEL := 35

# Audio
PRODUCT_PACKAGES += \
    com.android.hardware.audio.rpi5

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/audio/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    $(DEVICE_PATH)/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    $(DEVICE_PATH)/audio/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml

# Bluetooth
PRODUCT_PACKAGES += \
    com.android.hardware.bluetooth.rpi5

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

# Camera
PRODUCT_PACKAGES += \
    com.android.hardware.camera.external.rpi5

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/camera/external/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.external.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.external.xml

PRODUCT_PACKAGES += \
    com.android.hardware.camera.libcamera

$(call soong_config_set,libcamera,ipa,pisp)

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/camera/libcamera/camera_hal.yaml:$(TARGET_COPY_OUT_VENDOR)/etc/libcamera/camera_hal.yaml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.concurrent.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.concurrent.xml \
    frameworks/native/data/etc/android.hardware.camera.flash-autofocus.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.camera.full.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.full.xml \
    frameworks/native/data/etc/android.hardware.camera.raw.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.raw.xml

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/camera/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml

# CEC
PRODUCT_PACKAGES += \
    com.android.hardware.tv.hdmi.cec.rpi5 \
    com.android.hardware.tv.hdmi.connection.rpi5

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.hdmi.cec.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.hdmi.cec.xml

# DRM
PRODUCT_PACKAGES += \
    com.android.hardware.drm.clearkey

# Emergency info
PRODUCT_PACKAGES += \
    EmergencyInfo

# Ethernet
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml

# FFmpeg
PRODUCT_PACKAGES += \
    com.android.hardware.media.c2.ffmpeg

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/media/media_codecs_ffmpeg_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_ffmpeg_c2.xml

# Gatekeeper
PRODUCT_PACKAGES += \
    com.android.hardware.gatekeeper.nonsecure

# Graphics
PRODUCT_PACKAGES += \
    com.android.hardware.graphics.allocator.minigbm_gbm_mesa

PRODUCT_PACKAGES += \
    com.android.hardware.graphics.composer.drm_hwcomposer

PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.opengles.deqp.level-latest.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml

PRODUCT_PACKAGES += \
    com.android.hardware.vulkan.broadcom

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-latest.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# Health
PRODUCT_PACKAGES += \
    com.android.hardware.health.rpi5

# Kernel
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)-kernel/Image:$(PRODUCT_OUT)/kernel

# Keymint
PRODUCT_PACKAGES += \
    com.android.hardware.keymint.rust_nonsecure

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml

# Lights
PRODUCT_PACKAGES += \
    com.android.hardware.light.rpi5

# Media
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/media/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_tv.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_tv.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml

# Power
PRODUCT_PACKAGES += \
    com.android.hardware.power

# Ramdisk
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/ramdisk/fstab.rpi5:$(TARGET_COPY_OUT_RAMDISK)/fstab.rpi5 \
    $(DEVICE_PATH)/ramdisk/fstab.rpi5:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.rpi5 \
    $(DEVICE_PATH)/ramdisk/init.rpi5.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rpi5.rc \
    $(DEVICE_PATH)/ramdisk/init.rpi5.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rpi5.usb.rc \
    $(DEVICE_PATH)/ramdisk/ueventd.rpi5.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc

# Seccomp
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/seccomp_policy/mediacodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy \
    $(DEVICE_PATH)/seccomp_policy/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy

# Soong
PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)

# Storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Suspend
PRODUCT_PACKAGES += \
    com.android.hardware.suspend_blocker.rpi5

# Thermal
PRODUCT_PACKAGES += \
    com.android.hardware.thermal

# Touchscreen
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml

# USB
PRODUCT_PACKAGES += \
    com.android.hardware.usb \
    com.android.hardware.usb.gadget.rpi5

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

# Virtualization
$(call inherit-product, packages/modules/Virtualization/apex/product_packages.mk)

# Wifi
PRODUCT_PACKAGES += \
    com.android.hardware.wifi \
    com.android.hardware.wifi.hostapd.rpi5 \
    com.android.hardware.wifi.supplicant.rpi5 \
    libwpa_client \
    wificond

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml
