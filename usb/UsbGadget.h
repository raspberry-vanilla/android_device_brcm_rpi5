/*
 * Copyright (C) 2020 The Android Open Source Project
 * Copyright (C) 2023 KonstaKANG
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef ANDROID_HARDWARE_USB_GADGET_V1_2_USBGADGET_H
#define ANDROID_HARDWARE_USB_GADGET_V1_2_USBGADGET_H

#include <UsbGadgetCommon.h>
#include <android-base/file.h>
#include <android-base/properties.h>
#include <android-base/strings.h>
#include <android-base/unique_fd.h>
#include <android/hardware/usb/gadget/1.2/IUsbGadget.h>
#include <android/hardware/usb/gadget/1.2/types.h>
#include <hidl/MQDescriptor.h>
#include <hidl/Status.h>
#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <utils/Log.h>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <string>
#include <thread>

namespace android {
namespace hardware {
namespace usb {
namespace gadget {
namespace V1_2 {
namespace implementation {

using ::android::sp;
using ::android::base::GetProperty;
using ::android::base::ReadFileToString;
using ::android::base::SetProperty;
using ::android::base::Trim;
using ::android::base::unique_fd;
using ::android::base::WriteStringToFile;
using ::android::hardware::hidl_array;
using ::android::hardware::hidl_memory;
using ::android::hardware::hidl_string;
using ::android::hardware::hidl_vec;
using ::android::hardware::Return;
using ::android::hardware::Void;
using ::android::hardware::usb::gadget::addAdb;
using ::android::hardware::usb::gadget::addEpollFd;
using ::android::hardware::usb::gadget::getVendorFunctions;
using ::android::hardware::usb::gadget::kDebug;
using ::android::hardware::usb::gadget::kDisconnectWaitUs;
using ::android::hardware::usb::gadget::linkFunction;
using ::android::hardware::usb::gadget::MonitorFfs;
using ::android::hardware::usb::gadget::resetGadget;
using ::android::hardware::usb::gadget::setVidPid;
using ::android::hardware::usb::gadget::unlinkFunctions;
using ::std::string;

constexpr char kGadgetName[] = "1000480000.usb";
static MonitorFfs monitorFfs(kGadgetName);

#define UDC_PATH "/sys/class/udc/1000480000.usb/"
#define SPEED_PATH UDC_PATH "current_speed"

struct UsbGadget : public IUsbGadget {
    UsbGadget();

    // Makes sure that only one request is processed at a time.
    std::mutex mLockSetCurrentFunction;
    uint64_t mCurrentUsbFunctions;
    bool mCurrentUsbFunctionsApplied;
    UsbSpeed mUsbSpeed;

    Return<void> setCurrentUsbFunctions(uint64_t functions,
                                        const sp<V1_0::IUsbGadgetCallback>& callback,
                                        uint64_t timeout) override;

    Return<void> getCurrentUsbFunctions(const sp<V1_0::IUsbGadgetCallback>& callback) override;

    Return<Status> reset() override;

    Return<void> getUsbSpeed(const sp<V1_2::IUsbGadgetCallback>& callback) override;

  private:
    V1_0::Status tearDownGadget();
    V1_0::Status setupFunctions(uint64_t functions, const sp<V1_0::IUsbGadgetCallback>& callback,
                                uint64_t timeout);
};

}  // namespace implementation
}  // namespace V1_2
}  // namespace gadget
}  // namespace usb
}  // namespace hardware
}  // namespace android

#endif  // ANDROID_HARDWARE_USB_V1_2_USBGADGET_H
