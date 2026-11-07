/*
 * usb_bridge_linux.h - the usb_bridge.h calls on Linux, on hidraw.
 *
 * Devices come from /sys/class/hidraw, so nothing beyond the kernel is needed.
 * Report sizes are not published, so they are worked out from each device's
 * report descriptor. As on Windows and macOS, the first byte of a report is its
 * report id, and 0 means the device has none. hidraw leaves that byte out on
 * reads from such a device, so it is put back here.
 *
 * Opening /dev/hidrawN needs permission, usually a udev rule; without it
 * usb_hid_open answers NULL.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef USB_BRIDGE_LINUX_H
#define USB_BRIDGE_LINUX_H

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/hidraw.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#ifndef USB_HIDRAW_SYSFS
#define USB_HIDRAW_SYSFS "/sys/class/hidraw"
#endif
#ifndef USB_HIDRAW_DEV
#define USB_HIDRAW_DEV "/dev"
#endif

#define USB_TEXT_SIZE 256
#define USB_DESCRIPTOR_MAX 4096

typedef struct {
    int vendor;
    int product;
    int usage_page;
    int usage;
    int input_length;
    int output_length;
    int feature_length;
    int has_report_ids;
    char name[USB_TEXT_SIZE];
    char manufacturer[USB_TEXT_SIZE];
    char path[USB_TEXT_SIZE];
} UsbDeviceInfo;

typedef struct {
    int fd;
    int has_report_ids;
} UsbOpenDevice;

/* Shared, not static: this header can be compiled into several generated C files. */
__attribute__((weak)) UsbDeviceInfo* g_usb_devices = NULL;
__attribute__((weak)) int g_usb_device_count = 0;

/* Sizes from a report descriptor, in bytes with the report id byte counted, as
   Windows reports them. Each report id is summed apart, and the largest wins. */
static inline void usb_parse_descriptor(const unsigned char* d, int length, UsbDeviceInfo* info)
{
    static const int kinds = 3;
    unsigned int bits[3][256];
    unsigned int report_size = 0, report_count = 0, report_id = 0;
    unsigned int saved_size[8], saved_count[8], saved_id[8], saved_page[8];
    unsigned int usage_page = 0, first_usage = 0;
    int have_usage = 0, top_level_done = 0, depth = 0;
    int i = 0, k, id;

    memset(bits, 0, sizeof(bits));
    while (i < length) {
        unsigned char prefix = d[i];
        int size, type, tag;
        unsigned int value = 0;
        int b;

        if (prefix == 0xFE) {   /* a long item: its size is in the next byte */
            if (i + 1 >= length) break;
            i += 3 + d[i + 1];
            continue;
        }
        size = prefix & 3;
        if (size == 3) size = 4;
        type = (prefix >> 2) & 3;
        tag = prefix >> 4;
        if (i + 1 + size > length) break;
        for (b = 0; b < size; b++) value |= (unsigned int) d[i + 1 + b] << (8 * b);
        i += 1 + size;

        if (type == 1) {        /* global */
            switch (tag) {
                case 0: usage_page = value; break;
                case 7: report_size = value; break;
                case 8: report_id = value & 0xFF; info->has_report_ids = 1; break;
                case 9: report_count = value; break;
                case 10:
                    if (depth < 8) {
                        saved_size[depth] = report_size;
                        saved_count[depth] = report_count;
                        saved_id[depth] = report_id;
                        saved_page[depth] = usage_page;
                        depth++;
                    }
                    break;
                case 11:
                    if (depth > 0) {
                        depth--;
                        report_size = saved_size[depth];
                        report_count = saved_count[depth];
                        report_id = saved_id[depth];
                        usage_page = saved_page[depth];
                    }
                    break;
                default: break;
            }
        } else if (type == 2) { /* local */
            if (tag == 0 && !have_usage) {
                first_usage = value;
                have_usage = 1;
            }
        } else if (type == 0) { /* main */
            switch (tag) {
                case 8:  bits[0][report_id] += report_size * report_count; break;
                case 9:  bits[1][report_id] += report_size * report_count; break;
                case 11: bits[2][report_id] += report_size * report_count; break;
                case 10:
                    if (!top_level_done) {
                        info->usage_page = (int) usage_page;
                        info->usage = (int) (first_usage & 0xFFFF);
                        top_level_done = 1;
                    }
                    break;
                default: break;
            }
        }
    }
    for (k = 0; k < kinds; k++) {
        unsigned int largest = 0;
        for (id = 0; id < 256; id++) {
            if (bits[k][id] > largest) largest = bits[k][id];
        }
        largest = largest == 0 ? 0 : (largest + 7) / 8 + 1;
        if (k == 0) info->input_length = (int) largest;
        else if (k == 1) info->output_length = (int) largest;
        else info->feature_length = (int) largest;
    }
}

static inline int usb_read_file(const char* path, unsigned char* out, int size)
{
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    int n;
    if (fd < 0) return -1;
    n = (int) read(fd, out, (size_t) size);
    close(fd);
    return n;
}

/* Fill `info' from the kernel's description of `node', such as "hidraw0". */
static inline int usb_describe(const char* node, UsbDeviceInfo* info)
{
    char path[USB_TEXT_SIZE * 2];
    char text[2048];
    unsigned char descriptor[USB_DESCRIPTOR_MAX];
    unsigned int bus = 0, vendor = 0, product = 0;
    char* line;
    char* rest = NULL;
    int n;

    memset(info, 0, sizeof(*info));
    snprintf(info->path, sizeof(info->path), "%s/%s", USB_HIDRAW_DEV, node);
    snprintf(path, sizeof(path), "%s/%s/device/uevent", USB_HIDRAW_SYSFS, node);
    n = usb_read_file(path, (unsigned char*) text, (int) sizeof(text) - 1);
    if (n <= 0) return 0;
    text[n] = 0;
    for (line = strtok_r(text, "\n", &rest); line; line = strtok_r(NULL, "\n", &rest)) {
        if (sscanf(line, "HID_ID=%x:%x:%x", &bus, &vendor, &product) == 3) {
            info->vendor = (int) (vendor & 0xFFFF);
            info->product = (int) (product & 0xFFFF);
        } else if (strncmp(line, "HID_NAME=", 9) == 0) {
            strncpy(info->name, line + 9, USB_TEXT_SIZE - 1);
        }
    }
    snprintf(path, sizeof(path), "%s/%s/device/report_descriptor", USB_HIDRAW_SYSFS, node);
    n = usb_read_file(path, descriptor, USB_DESCRIPTOR_MAX);
    if (n > 0) usb_parse_descriptor(descriptor, n, info);
    return 1;
}

static inline void usb_hid_free_enumeration(void)
{
    free(g_usb_devices);
    g_usb_devices = NULL;
    g_usb_device_count = 0;
}

static inline int usb_hid_enumerate(void)
{
    DIR* dir = opendir(USB_HIDRAW_SYSFS);
    struct dirent* entry;
    int capacity = 0;

    usb_hid_free_enumeration();
    if (!dir) return 0;
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, "hidraw", 6) != 0) continue;
        if (g_usb_device_count == capacity) {
            int larger = capacity ? capacity * 2 : 8;
            UsbDeviceInfo* grown = (UsbDeviceInfo*) realloc(g_usb_devices, (size_t) larger * sizeof(UsbDeviceInfo));
            if (!grown) break;
            g_usb_devices = grown;
            capacity = larger;
        }
        if (usb_describe(entry->d_name, &g_usb_devices[g_usb_device_count])) g_usb_device_count++;
    }
    closedir(dir);
    return g_usb_device_count;
}

static inline void* usb_hid_get_device(int index)
{
    return index >= 0 && index < g_usb_device_count ? &g_usb_devices[index] : NULL;
}

static inline int usb_device_vendor_id(void* h) { return h ? ((UsbDeviceInfo*) h)->vendor : 0; }
static inline int usb_device_product_id(void* h) { return h ? ((UsbDeviceInfo*) h)->product : 0; }
static inline const char* usb_device_product_name(void* h) { return h ? ((UsbDeviceInfo*) h)->name : ""; }
static inline const char* usb_device_manufacturer(void* h) { return h ? ((UsbDeviceInfo*) h)->manufacturer : ""; }
static inline const char* usb_device_path(void* h) { return h ? ((UsbDeviceInfo*) h)->path : ""; }
static inline int usb_hid_usage_page(void* h) { return h ? ((UsbDeviceInfo*) h)->usage_page : 0; }
static inline int usb_hid_usage(void* h) { return h ? ((UsbDeviceInfo*) h)->usage : 0; }
static inline int usb_hid_input_report_length(void* h) { return h ? ((UsbDeviceInfo*) h)->input_length : 0; }
static inline int usb_hid_output_report_length(void* h) { return h ? ((UsbDeviceInfo*) h)->output_length : 0; }
static inline int usb_hid_feature_report_length(void* h) { return h ? ((UsbDeviceInfo*) h)->feature_length : 0; }

static inline void* usb_hid_open(const char* path)
{
    UsbOpenDevice* o;
    UsbDeviceInfo info;
    const char* node;
    int fd;

    if (!path) return NULL;
    node = strrchr(path, '/');
    node = node ? node + 1 : path;
    memset(&info, 0, sizeof(info));
    usb_describe(node, &info);
    fd = open(path, O_RDWR | O_CLOEXEC);
    if (fd < 0) return NULL;
    o = (UsbOpenDevice*) malloc(sizeof(UsbOpenDevice));
    if (!o) {
        close(fd);
        return NULL;
    }
    o->fd = fd;
    o->has_report_ids = info.has_report_ids;
    return o;
}

static inline void usb_hid_close(void* handle)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    if (o) {
        close(o->fd);
        free(o);
    }
}

/* Bytes read, 0 on a timeout, -1 on an error. A negative timeout waits forever. */
static inline int usb_hid_read_timeout(void* handle, void* buffer, int length, int timeout_ms)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    unsigned char* out = (unsigned char*) buffer;
    struct pollfd p;
    int ready, skip, n;

    if (!o || !out || length <= 0) return -1;
    p.fd = o->fd;
    p.events = POLLIN;
    do {
        ready = poll(&p, 1, timeout_ms);
    } while (ready < 0 && errno == EINTR);
    if (ready < 0) return -1;
    if (ready == 0) return 0;

    skip = o->has_report_ids ? 0 : 1;
    if (length <= skip) return -1;
    do {
        n = (int) read(o->fd, out + skip, (size_t) (length - skip));
    } while (n < 0 && errno == EINTR);
    if (n < 0) return -1;
    if (n == 0) return 0;
    if (skip) out[0] = 0;
    return n + skip;
}

static inline int usb_hid_read(void* handle, void* buffer, int length)
{
    return usb_hid_read_timeout(handle, buffer, length, -1);
}

/* The first byte is the report id, or 0, which is what hidraw expects too. */
static inline int usb_hid_write(void* handle, void* buffer, int length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    int n;
    if (!o || !buffer || length <= 0) return -1;
    do {
        n = (int) write(o->fd, buffer, (size_t) length);
    } while (n < 0 && errno == EINTR);
    return n;
}

static inline int usb_hid_send_feature_report(void* handle, void* buffer, int length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    if (!o || !buffer || length <= 0) return -1;
    return ioctl(o->fd, HIDIOCSFEATURE(length), buffer);
}

static inline int usb_hid_get_feature_report(void* handle, void* buffer, int length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    if (!o || !buffer || length <= 0) return -1;
    return ioctl(o->fd, HIDIOCGFEATURE(length), buffer);
}

#endif /* USB_BRIDGE_LINUX_H */
