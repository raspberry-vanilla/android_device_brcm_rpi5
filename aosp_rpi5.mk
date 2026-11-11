#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/brcm/rpi5

# Inherit device configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_AAPT_CONFIG := normal mdpi hdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_CHARACTERISTICS := tablet,nosdcard

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call enforce-product-packages-exist,com.android.ranging vendor_tracing_descriptors)

# Freeform windows
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.freeform_window_management.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.freeform_window_management.xml

# Keylayout
PRODUCT_PACKAGES += \
    generic_keylayout_rpi

$(call soong_config_set_bool,rpi_keylayout,use_generic_keylayout_rpi,true)

# Large screen
$(call inherit-product, $(SRC_TARGET_DIR)/product/large_screen_common.mk)

# Lockscreen
PRODUCT_VENDOR_PROPERTIES += \
    ro.lockscreen.disable.default=true

# Overlays
PRODUCT_PACKAGES += \
    AndroidRpiOverlay \
    BluetoothRpiOverlay \
    SettingsProviderRpiOverlay \
    SettingsRpiOverlay \
    SystemUIRpiOverlay \
    WifiRpiOverlay

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := rpi5
PRODUCT_NAME := aosp_rpi5
PRODUCT_BRAND := Raspberry
PRODUCT_MODEL := Pi 5
PRODUCT_MANUFACTURER := Raspberry
