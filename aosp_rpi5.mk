#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit device configuration
$(call inherit-product, device/brcm/rpi5/device.mk)

PRODUCT_AAPT_CONFIG := normal mdpi hdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_CHARACTERISTICS := tablet,nosdcard
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

# Overlays
PRODUCT_PACKAGES += \
    AndroidRpiOverlay \
    SettingsRpiOverlay \
    SettingsProviderRpiOverlay \
    SystemUIRpiOverlay \
    WifiRpiOverlay

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := rpi5
PRODUCT_NAME := aosp_rpi5
PRODUCT_BRAND := Raspberry
PRODUCT_MODEL := Raspberry Pi 5
PRODUCT_MANUFACTURER := Raspberry
PRODUCT_RELEASE_NAME := Raspberry Pi 5
