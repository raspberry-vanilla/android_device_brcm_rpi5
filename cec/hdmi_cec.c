/*
 * Copyright (C) 2019 BayLibre, SAS.
 * Copyright (C) 2021-2022 KonstaKANG
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

#define LOG_TAG "hdmi_cec"

#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>

#include <sys/ioctl.h>
#include <sys/types.h>

#include <poll.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/cec.h>
#include <sys/eventfd.h>

#include <log/log.h>
#include <cutils/properties.h>
#include <hardware/hdmi_cec.h>

typedef struct hdmicec_context
{
    hdmi_cec_device_t device; /* must be first */
    int cec_fd;
    unsigned int vendor_id;
    unsigned int type;
    unsigned int version;
    struct hdmi_port_info port_info;
    event_callback_t p_event_cb;
    void *cb_arg;
    pthread_t thread;
    int exit_fd;
    pthread_mutex_t options_lock;
    bool cec_enabled;
    bool cec_control_enabled;
} hdmicec_context_t;

static int hdmicec_add_logical_address(const struct hdmi_cec_device *dev, cec_logical_address_t addr)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    unsigned int la_type = CEC_LOG_ADDR_TYPE_UNREGISTERED;
    unsigned int all_dev_types = 0;
    unsigned int prim_type = 0xff;
    struct cec_log_addrs laddrs;
    int ret;

    ALOGD("%s: addr:%x\n", __func__, addr);

    if (addr >= CEC_ADDR_BROADCAST)
        return -1;

    ret = ioctl(ctx->cec_fd, CEC_ADAP_G_LOG_ADDRS, &laddrs);
    if (ret)
        return ret;
    memset(&laddrs, 0, sizeof(laddrs));

    laddrs.cec_version = ctx->version;
    laddrs.vendor_id = ctx->vendor_id;

    switch (addr) {
        case CEC_LOG_ADDR_TV:
            prim_type = CEC_OP_PRIM_DEVTYPE_TV;
            la_type = CEC_LOG_ADDR_TYPE_TV;
            all_dev_types = CEC_OP_ALL_DEVTYPE_TV;
            break;
        case CEC_LOG_ADDR_RECORD_1:
        case CEC_LOG_ADDR_RECORD_2:
        case CEC_LOG_ADDR_RECORD_3:
            prim_type = CEC_OP_PRIM_DEVTYPE_RECORD;
            la_type = CEC_LOG_ADDR_TYPE_RECORD;
            all_dev_types = CEC_OP_ALL_DEVTYPE_RECORD;
            break;
        case CEC_LOG_ADDR_TUNER_1:
        case CEC_LOG_ADDR_TUNER_2:
        case CEC_LOG_ADDR_TUNER_3:
        case CEC_LOG_ADDR_TUNER_4:
            prim_type = CEC_OP_PRIM_DEVTYPE_TUNER;
            la_type = CEC_LOG_ADDR_TYPE_TUNER;
            all_dev_types = CEC_OP_ALL_DEVTYPE_TUNER;
            break;
        case CEC_LOG_ADDR_PLAYBACK_1:
        case CEC_LOG_ADDR_PLAYBACK_2:
        case CEC_LOG_ADDR_PLAYBACK_3:
            prim_type = CEC_OP_PRIM_DEVTYPE_PLAYBACK;
            la_type = CEC_LOG_ADDR_TYPE_PLAYBACK;
            all_dev_types = CEC_OP_ALL_DEVTYPE_PLAYBACK;
            laddrs.flags = CEC_LOG_ADDRS_FL_ALLOW_RC_PASSTHRU;
            break;
        case CEC_LOG_ADDR_AUDIOSYSTEM:
            prim_type = CEC_OP_PRIM_DEVTYPE_AUDIOSYSTEM;
            la_type = CEC_LOG_ADDR_TYPE_AUDIOSYSTEM;
            all_dev_types = CEC_OP_ALL_DEVTYPE_AUDIOSYSTEM;
            break;
        case CEC_LOG_ADDR_SPECIFIC:
            prim_type = CEC_OP_PRIM_DEVTYPE_PROCESSOR;
            la_type = CEC_LOG_ADDR_TYPE_SPECIFIC;
            all_dev_types = CEC_OP_ALL_DEVTYPE_SWITCH;
            break;
        case CEC_ADDR_RESERVED_1:
        case CEC_ADDR_RESERVED_2:
        case CEC_ADDR_UNREGISTERED:
            laddrs.flags = CEC_LOG_ADDRS_FL_ALLOW_UNREG_FALLBACK;
            break;
    }

    laddrs.num_log_addrs = 1;
    laddrs.log_addr[0] = addr;
    laddrs.log_addr_type[0] = la_type;
    laddrs.primary_device_type[0] = prim_type;
    laddrs.all_device_types[0] = all_dev_types;
    laddrs.features[0][0] = 0;
    laddrs.features[0][1] = 0;

    ret = ioctl(ctx->cec_fd, CEC_ADAP_S_LOG_ADDRS, &laddrs);
    if (ret) {
        ALOGD("%s: %m\n", __func__);
        return ret;
    }

    ALOGD("%s: log_addr_mask=%x\n", __func__,  laddrs.log_addr_mask);

    return 0;
}

static void hdmicec_clear_logical_address(const struct hdmi_cec_device *dev)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    struct cec_log_addrs laddrs;
    int ret;

    memset(&laddrs, 0, sizeof(laddrs));
    ret = ioctl(ctx->cec_fd, CEC_ADAP_S_LOG_ADDRS, &laddrs);
    if (ret)
        ALOGD("%s: %m\n", __func__);
}

static int hdmicec_get_physical_address(const struct hdmi_cec_device *dev, uint16_t *addr)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    int ret = ioctl(ctx->cec_fd, CEC_ADAP_G_PHYS_ADDR, addr);
    if (ret)
        ALOGD("%s: %m\n", __func__);

    return ret;
}

static int hdmicec_send_message(const struct hdmi_cec_device *dev, const cec_message_t *msg)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    struct cec_msg cec_msg;
    int ret;

    pthread_mutex_lock(&ctx->options_lock);
    bool cec_enabled = ctx->cec_enabled;
    pthread_mutex_unlock(&ctx->options_lock);
    if (!cec_enabled) {
        return HDMI_RESULT_FAIL;
    }

    ALOGD("%s: len=%u\n", __func__, (unsigned int)msg->length);

    memset(&cec_msg, 0, sizeof(cec_msg));
    cec_msg.msg[0] = (msg->initiator << 4) | msg->destination;

    memcpy(&cec_msg.msg[1], msg->body, msg->length);
    cec_msg.len = msg->length + 1;

    ret = ioctl(ctx->cec_fd, CEC_TRANSMIT, &cec_msg);
    if (ret) {
        ALOGD("%s: %m\n", __func__);
        return HDMI_RESULT_FAIL;
    }

    if (cec_msg.tx_status != CEC_TX_STATUS_OK)
        ALOGD("%s: tx_status=%d\n", __func__, cec_msg.tx_status);

    switch (cec_msg.tx_status) {
        case CEC_TX_STATUS_OK:
            return HDMI_RESULT_SUCCESS;
        case CEC_TX_STATUS_ARB_LOST:
            return HDMI_RESULT_BUSY;
        case CEC_TX_STATUS_NACK:
            return HDMI_RESULT_NACK;
        default:
            if (cec_msg.tx_status & CEC_TX_STATUS_NACK)
                return HDMI_RESULT_NACK;
            return HDMI_RESULT_FAIL;
    }
}

static void hdmicec_register_event_callback(const struct hdmi_cec_device *dev,
        event_callback_t callback, void *arg)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;

    ctx->p_event_cb = callback;
    ctx->cb_arg = arg;
}

static void hdmicec_get_version(const struct hdmi_cec_device *dev, int *version)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;

    *version = ctx->version;
}

static void hdmicec_get_vendor_id(const struct hdmi_cec_device *dev, uint32_t *vendor_id)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;

    *vendor_id = ctx->vendor_id;
}

static void hdmicec_get_port_info(const struct hdmi_cec_device *dev,
        struct hdmi_port_info *list[], int *total)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    int ret;

    ret = ioctl(ctx->cec_fd, CEC_ADAP_G_PHYS_ADDR, &ctx->port_info.physical_address);
    if (ret)
        ALOGD("%s: %m\n", __func__);

    ALOGD("type:%s, id:%d, cec support:%d, arc support:%d, physical address:%x",
            ctx->port_info.type ? "output" : "input",
            ctx->port_info.port_id,
            ctx->port_info.cec_supported,
            ctx->port_info.arc_supported,
            ctx->port_info.physical_address);

    if (ctx->port_info.physical_address != CEC_PHYS_ADDR_INVALID) {
        *list = &ctx->port_info;
        *total = 1;
    }
}

static void hdmicec_set_option(const struct hdmi_cec_device *dev, int flag, int value)
{
    struct hdmicec_context* ctx = (struct hdmicec_context*)dev;
    ALOGD("%s: flag=%d, value=%d", __func__, flag, value);
    switch (flag) {
        case HDMI_OPTION_ENABLE_CEC:
            pthread_mutex_lock(&ctx->options_lock);
            ctx->cec_enabled = (value == 1 ? true : false);
            pthread_mutex_unlock(&ctx->options_lock);
            break;
        case HDMI_OPTION_WAKEUP:
            // Not valid for playback devices
            break;
        case HDMI_OPTION_SYSTEM_CEC_CONTROL:
            pthread_mutex_lock(&ctx->options_lock);
            ctx->cec_control_enabled = (value == 1 ? true : false);
            pthread_mutex_unlock(&ctx->options_lock);
            break;
    }
}

static int hdmicec_is_connected(const struct hdmi_cec_device *dev, int port_id)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    int ret;

    (void)port_id;

    ret = ioctl(ctx->cec_fd, CEC_ADAP_G_PHYS_ADDR,
            &ctx->port_info.physical_address);
    if (ret) {
        ALOGD("%s: %m\n", __func__);
        return ret;
    }

    if (ctx->port_info.physical_address == CEC_PHYS_ADDR_INVALID)
        return false;

    return true;
}

static int get_opcode(struct cec_msg* message) {
    return (((uint8_t)message->msg[1]) & 0xff);
}

static int get_first_param(struct cec_msg* message) {
    return (((uint8_t)message->msg[2]) & 0xff);
}

static bool is_power_ui_command(struct cec_msg* message) {
    int ui_command = get_first_param(message);
    switch (ui_command) {
        case CEC_OP_UI_CMD_POWER:
        case CEC_OP_UI_CMD_DEVICE_ROOT_MENU:
        case CEC_OP_UI_CMD_POWER_ON_FUNCTION:
            return true;
        default:
            return false;
    }
}

static bool is_transferable_in_sleep(struct cec_msg* message) {
    int opcode = get_opcode(message);
    switch (opcode) {
        case CEC_MESSAGE_ABORT:
        case CEC_MESSAGE_DEVICE_VENDOR_ID:
        case CEC_MESSAGE_GET_CEC_VERSION:
        case CEC_MESSAGE_GET_MENU_LANGUAGE:
        case CEC_MESSAGE_GIVE_DEVICE_POWER_STATUS:
        case CEC_MESSAGE_GIVE_DEVICE_VENDOR_ID:
        case CEC_MESSAGE_GIVE_OSD_NAME:
        case CEC_MESSAGE_GIVE_PHYSICAL_ADDRESS:
        case CEC_MESSAGE_REPORT_PHYSICAL_ADDRESS:
        case CEC_MESSAGE_REPORT_POWER_STATUS:
        case CEC_MESSAGE_SET_OSD_NAME:
        case CEC_MESSAGE_DECK_CONTROL:
        case CEC_MESSAGE_PLAY:
            return true;
        case CEC_MESSAGE_USER_CONTROL_PRESSED:
            return is_power_ui_command(message);
        default:
            return false;
    }
}

static void *event_thread(void *arg)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)arg;
    int ret;
    struct pollfd ufds[3] = {
        { ctx->cec_fd, POLLIN, 0 },
        { ctx->cec_fd, POLLERR, 0 },
        { ctx->exit_fd, POLLIN, 0 },
    };

    ALOGI("%s start!", __func__);

    while (1) {
        ufds[0].revents = 0;
        ufds[1].revents = 0;
        ufds[2].revents = 0;

        ret = poll(ufds, 3, -1);

        if (ret <= 0)
            continue;

        if (ufds[2].revents == POLLIN)   /* Exit */
            break;

        if (ufds[1].revents == POLLERR) { /* CEC Event */
            hdmi_event_t event = { };
            struct cec_event ev;

            ret = ioctl(ctx->cec_fd, CEC_DQEVENT, &ev);
            if (ret)
                continue;

            pthread_mutex_lock(&ctx->options_lock);
            bool cec_enabled = ctx->cec_enabled;
            pthread_mutex_unlock(&ctx->options_lock);
            if (!cec_enabled) {
                continue;
            }

            if (ev.event == CEC_EVENT_STATE_CHANGE) {
                event.type = HDMI_EVENT_HOT_PLUG;
                event.dev = &ctx->device;
                event.hotplug.port_id = 1;
                if (ev.state_change.phys_addr == CEC_PHYS_ADDR_INVALID)
                    event.hotplug.connected = false;
                else
                    event.hotplug.connected = true;

                if (ctx->p_event_cb != NULL) {
                    ctx->p_event_cb(&event, ctx->cb_arg);
                } else {
                    ALOGE("no event callback for hotplug\n");
                }
            }
        }

        if (ufds[0].revents == POLLIN) { /* CEC Driver */
            struct cec_msg msg = { };
            hdmi_event_t event = { };

            ret = ioctl(ctx->cec_fd, CEC_RECEIVE, &msg);
            if (ret) {
                ALOGE("%s: CEC_RECEIVE error (%m)\n", __func__);
                continue;
            }

            if (msg.rx_status != CEC_RX_STATUS_OK) {
                ALOGD("%s: rx_status=%d\n", __func__, msg.rx_status);
                continue;
            }

            pthread_mutex_lock(&ctx->options_lock);
            bool cec_enabled = ctx->cec_enabled;
            pthread_mutex_unlock(&ctx->options_lock);
            if (!cec_enabled) {
                continue;
            }

            pthread_mutex_lock(&ctx->options_lock);
            bool cec_control_enabled = ctx->cec_control_enabled;
            pthread_mutex_unlock(&ctx->options_lock);
            if (!cec_control_enabled && !is_transferable_in_sleep(&msg)) {
                ALOGD("%s: filter message in standby mode\n", __func__);
                continue;
            }

            if (ctx->p_event_cb != NULL) {
                event.type = HDMI_EVENT_CEC_MESSAGE;
                event.dev = &ctx->device;
                event.cec.initiator = msg.msg[0] >> 4;
                event.cec.destination = msg.msg[0] & 0xf;
                event.cec.length = msg.len - 1;
                memcpy(event.cec.body, &msg.msg[1], msg.len - 1);

                ctx->p_event_cb(&event, ctx->cb_arg);
            } else {
                ALOGE("no event callback for msg\n");
            }
        }
    }

    ALOGI("%s exit!", __func__);
    return NULL;
}

static void hdmicec_set_arc(const struct hdmi_cec_device *dev, int port_id, int flag)
{
    (void)dev;
    (void)port_id;
    (void)flag;
    /* Not supported */
}

static int hdmicec_close(struct hdmi_cec_device *dev)
{
    struct hdmicec_context *ctx = (struct hdmicec_context *)dev;
    uint64_t tmp = 1;

    ALOGD("%s\n", __func__);

    if (ctx->exit_fd > 0) {
        write(ctx->exit_fd, &tmp, sizeof(tmp));
        pthread_join(ctx->thread, NULL);
    }

    if (ctx->cec_fd > 0)
        close(ctx->cec_fd);
    if (ctx->exit_fd > 0)
        close(ctx->exit_fd);
    free(ctx);

    ctx->cec_enabled = false;
    ctx->cec_control_enabled = false;
    return 0;
}

static int cec_init(struct hdmicec_context *ctx)
{
    struct cec_log_addrs laddrs = {};
    struct cec_caps caps = {};
    uint32_t mode;
    int ret;

    // Ensure the CEC device supports required capabilities
    ret = ioctl(ctx->cec_fd, CEC_ADAP_G_CAPS, &caps);
    if (ret)
        return ret;

    if (!(caps.capabilities & (CEC_CAP_LOG_ADDRS |
                    CEC_CAP_TRANSMIT |
                    CEC_CAP_PASSTHROUGH))) {
        ALOGE("%s: wrong cec adapter capabilities %x\n",
                __func__, caps.capabilities);
        return -1;
    }

    // This is an exclusive follower, in addition put the CEC device into passthrough mode
    mode = CEC_MODE_INITIATOR | CEC_MODE_EXCL_FOLLOWER_PASSTHRU;
    ret = ioctl(ctx->cec_fd, CEC_S_MODE, &mode);
    if (ret)
        return ret;

    ctx->type = property_get_int32("ro.hdmi.device_type", CEC_DEVICE_PLAYBACK);

    ctx->vendor_id = property_get_int32("ro.hdmi.vendor_id",
            0x000c03 /* HDMI LLC vendor ID */);

    ctx->version = property_get_bool("ro.hdmi.cec_version",
            CEC_OP_CEC_VERSION_1_4);

    ctx->port_info.type = ctx->type == CEC_DEVICE_TV ? HDMI_INPUT : HDMI_OUTPUT;
    ctx->port_info.port_id = 1;
    ctx->port_info.cec_supported = 1;
    ctx->port_info.arc_supported = 0;

    ALOGD("%s: type=%d\n", __func__, ctx->type);
    ALOGD("%s: vendor_id=%04x\n", __func__, ctx->vendor_id);
    ALOGD("%s: version=%d\n", __func__, ctx->version);

    memset(&laddrs, 0, sizeof(laddrs));
    ret = ioctl(ctx->cec_fd, CEC_ADAP_S_LOG_ADDRS, &laddrs);
    if (ret)
        return ret;

    pthread_mutex_init(&ctx->options_lock, NULL);

    ALOGD("%s: initialized CEC controller\n", __func__);

    return ret;
}

static int open_hdmi_cec(const struct hw_module_t *module, const char *id,
        struct hw_device_t **device)
{
    char path[32];
    char prop[PROPERTY_VALUE_MAX];
    hdmicec_context_t *ctx;
    int ret;

    ALOGD("%s: id=%s\n", __func__, id);

    ctx = malloc(sizeof(struct hdmicec_context));
    if (!ctx)
        return -ENOMEM;

    memset(ctx, 0, sizeof(*ctx));

    property_get("ro.hdmi.cec_device", prop, "cec0");
    snprintf(path, sizeof(path), "/dev/%s", prop);

    ctx->cec_fd = open(path, O_RDWR);
    if (ctx->cec_fd < 0) {
        ALOGE("faild to open %s, ret=%s\n", path, strerror(errno));
        goto fail;
    }

    ctx->exit_fd = eventfd(0, EFD_NONBLOCK);
    if (ctx->exit_fd < 0) {
        ALOGE("faild to open eventfd, ret = %d\n", errno);
        goto fail;
    }

    ctx->device.common.tag = HARDWARE_DEVICE_TAG;
    ctx->device.common.version = HDMI_CEC_DEVICE_API_VERSION_1_0;
    ctx->device.common.module = (struct hw_module_t *)module;
    ctx->device.common.close = (int (*)(struct hw_device_t* device))hdmicec_close;

    ctx->device.add_logical_address = hdmicec_add_logical_address;
    ctx->device.clear_logical_address = hdmicec_clear_logical_address;
    ctx->device.get_physical_address = hdmicec_get_physical_address;
    ctx->device.send_message = hdmicec_send_message;
    ctx->device.register_event_callback = hdmicec_register_event_callback;
    ctx->device.get_version = hdmicec_get_version;
    ctx->device.get_vendor_id = hdmicec_get_vendor_id;
    ctx->device.get_port_info = hdmicec_get_port_info;
    ctx->device.set_option = hdmicec_set_option;
    ctx->device.set_audio_return_channel = hdmicec_set_arc;
    ctx->device.is_connected = hdmicec_is_connected;

    /* init status */
    ret = cec_init(ctx);
    if (ret)
        goto fail;

    *device = &ctx->device.common;

    /* thread loop for receiving cec msg */
    if (pthread_create(&ctx->thread, NULL, event_thread, ctx)) {
        ALOGE("Can't create event thread: %s\n", strerror(errno));
        goto fail;
    }

    ctx->cec_enabled = true;
    ctx->cec_control_enabled = true;
    return 0;

fail:
    hdmicec_close((struct hdmi_cec_device *)ctx);
    return -errno;
}

/* module method */
static struct hw_module_methods_t hdmi_cec_module_methods = {
    .open =  open_hdmi_cec,
};

/* hdmi_cec module */
struct hw_module_t HAL_MODULE_INFO_SYM = {
    .tag = HARDWARE_MODULE_TAG,
    .version_major = 1,
    .version_minor = 0,
    .id = HDMI_CEC_HARDWARE_MODULE_ID,
    .name = "Raspberry Pi HDMI CEC HAL",
    .author = "The Android Open Source Project",
    .methods = &hdmi_cec_module_methods,
};
