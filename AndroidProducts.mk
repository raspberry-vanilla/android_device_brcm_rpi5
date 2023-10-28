#
# Copyright (C) 2021-2023 KonstaKANG
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_rpi5.mk \
    $(LOCAL_DIR)/aosp_rpi5_car.mk \
    $(LOCAL_DIR)/aosp_rpi5_tv.mk

COMMON_LUNCH_CHOICES := \
    aosp_rpi5-userdebug \
    aosp_rpi5_car-userdebug \
    aosp_rpi5_tv-userdebug
