#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit device configuration
$(call inherit-product, device/brcm/rpi5/device.mk)

PRODUCT_AAPT_PREF_CONFIG := tvdpi
PRODUCT_CHARACTERISTICS := tv
$(call inherit-product, device/google/atv/products/atv_base.mk)

# Android TV
PRODUCT_PACKAGES += \
    DocumentsUI \
    LeanbackIME \
    TvProvision \
    TvSampleLeanbackLauncher \
    TvSettingsTwoPanel

# Bluetooth
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.device.class_of_device=34,4,36

# Boot animation
PRODUCT_COPY_FILES += \
    device/google/atv/products/bootanimations/bootanimation.zip:$(TARGET_COPY_OUT_SYSTEM)/media/bootanimation.zip

# Overlays
PRODUCT_PACKAGES += \
    AndroidTvRpiOverlay \
    SettingsProviderTvRpiOverlay \
    WifiRpiOverlay

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := rpi5
PRODUCT_NAME := aosp_rpi5_tv
PRODUCT_BRAND := Raspberry
PRODUCT_MODEL := Raspberry Pi 5
PRODUCT_MANUFACTURER := Raspberry
PRODUCT_RELEASE_NAME := Raspberry Pi 5
