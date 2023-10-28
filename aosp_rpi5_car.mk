#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit device configuration
$(call inherit-product, device/brcm/rpi5/device.mk)

PRODUCT_AAPT_CONFIG := normal mdpi hdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi
PRODUCT_CHARACTERISTICS := automotive,nosdcard
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, packages/services/Car/car_product/build/car.mk)

# Bluetooth
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.device.class_of_device=38,4,8 \
    bluetooth.profile.a2dp.source.enabled=false \
    bluetooth.profile.asha.central.enabled=false \
    bluetooth.profile.avrcp.target.enabled=false \
    bluetooth.profile.bap.broadcast.assist.enabled=false \
    bluetooth.profile.bap.unicast.client.enabled=false \
    bluetooth.profile.bas.client.enabled=false \
    bluetooth.profile.ccp.server.enabled=false \
    bluetooth.profile.csip.set_coordinator.enabled=false \
    bluetooth.profile.hap.client.enabled=false \
    bluetooth.profile.hfp.ag.enabled=false \
    bluetooth.profile.hid.device.enabled=false \
    bluetooth.profile.hid.host.enabled=false \
    bluetooth.profile.map.server.enabled=false \
    bluetooth.profile.mcp.server.enabled=false \
    bluetooth.profile.opp.enabled=false \
    bluetooth.profile.pbap.server.enabled=false \
    bluetooth.profile.sap.server.enabled=false \
    bluetooth.profile.vcp.controller.enabled=false

# Broadcast radio
PRODUCT_PACKAGES += \
    android.hardware.broadcastradio-service.default

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.broadcastradio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.broadcastradio.xml

# Camera
ENABLE_CAMERA_SERVICE := true

# EVS
ENABLE_CAREVSSERVICE_SAMPLE := true
ENABLE_EVS_SAMPLE := true
ENABLE_EVS_SERVICE := true
ENABLE_REAR_VIEW_CAMERA_SAMPLE := true

PRODUCT_COPY_FILES += \
    device/brcm/rpi5/camera/evs_config_override.json:${TARGET_COPY_OUT_VENDOR}/etc/automotive/evs/config_override.json

# Overlays
PRODUCT_PACKAGES += \
    AndroidRpiOverlay \
    CarServiceRpiOverlay \
    SettingsProviderRpiOverlay \
    WifiRpiOverlay

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.activities_on_secondary_displays.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.activities_on_secondary_displays.xml \
    frameworks/native/data/etc/car_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/car_core_hardware.xml

# Vehicle
PRODUCT_PACKAGES += \
    android.hardware.automotive.vehicle@2.0-default-service

# Device identifier. This must come after all inclusions.
PRODUCT_DEVICE := rpi5
PRODUCT_NAME := aosp_rpi5_car
PRODUCT_BRAND := Raspberry
PRODUCT_MODEL := Raspberry Pi 5
PRODUCT_MANUFACTURER := Raspberry
PRODUCT_RELEASE_NAME := Raspberry Pi 5
