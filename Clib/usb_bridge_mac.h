/*
 * usb_bridge_mac.h - the usb_bridge.h calls on macOS, on IOKit's HID Manager.
 *
 * A device path is "IOService:<registry entry id>", which stays valid across
 * a re-enumeration. Input reports arrive on a dispatch queue and wait in a
 * small ring for usb_hid_read. As on Windows, the first byte of a written
 * report is its report id; 0 means the device has none.
 *
 * macOS may refuse to open a keyboard or mouse without the Input Monitoring
 * permission: usb_hid_open then answers NULL.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef USB_BRIDGE_MAC_H
#define USB_BRIDGE_MAC_H

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/hid/IOHIDDevice.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/hid/IOHIDManager.h>
#include <dispatch/dispatch.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define USB_MAX_DEVICES 128
#define USB_RING_SLOTS 64
#define USB_REPORT_MAX 1024

typedef struct {
    unsigned short vendor_id;
    unsigned short product_id;
    char product_name[256];
    char manufacturer[256];
    char device_path[512];
    unsigned short usage_page;
    unsigned short usage;
    unsigned short input_report_length;
    unsigned short output_report_length;
    unsigned short feature_report_length;
} UsbDeviceInfo;

static UsbDeviceInfo g_devices[USB_MAX_DEVICES];
static int g_device_count = 0;

static int usb_number(IOHIDDeviceRef a_device, CFStringRef a_key)
{
    CFTypeRef l_value = IOHIDDeviceGetProperty(a_device, a_key);
    int l_result = 0;
    if (l_value && CFGetTypeID(l_value) == CFNumberGetTypeID()) {
        CFNumberGetValue((CFNumberRef) l_value, kCFNumberIntType, &l_result);
    }
    return l_result;
}

static void usb_text(IOHIDDeviceRef a_device, CFStringRef a_key, char* a_out, int a_size)
{
    CFTypeRef l_value = IOHIDDeviceGetProperty(a_device, a_key);
    a_out[0] = 0;
    if (l_value && CFGetTypeID(l_value) == CFStringGetTypeID()) {
        CFStringGetCString((CFStringRef) l_value, a_out, a_size, kCFStringEncodingUTF8);
    }
}

static inline int usb_hid_enumerate(void)
{
    IOHIDManagerRef l_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    CFSetRef l_set;
    CFIndex l_count, i;
    const void** l_all;
    uint64_t l_entry;

    g_device_count = 0;
    if (!l_manager) return 0;
    IOHIDManagerSetDeviceMatching(l_manager, NULL);
    l_set = IOHIDManagerCopyDevices(l_manager);
    if (l_set) {
        l_count = CFSetGetCount(l_set);
        l_all = (const void**) calloc((size_t) (l_count > 0 ? l_count : 1), sizeof(void*));
        if (l_all) {
            CFSetGetValues(l_set, l_all);
            for (i = 0; i < l_count && g_device_count < USB_MAX_DEVICES; i++) {
                IOHIDDeviceRef l_device = (IOHIDDeviceRef) l_all[i];
                UsbDeviceInfo* d = &g_devices[g_device_count];
                memset(d, 0, sizeof(*d));
                d->vendor_id = (unsigned short) usb_number(l_device, CFSTR(kIOHIDVendorIDKey));
                d->product_id = (unsigned short) usb_number(l_device, CFSTR(kIOHIDProductIDKey));
                d->usage_page = (unsigned short) usb_number(l_device, CFSTR(kIOHIDPrimaryUsagePageKey));
                d->usage = (unsigned short) usb_number(l_device, CFSTR(kIOHIDPrimaryUsageKey));
                d->input_report_length = (unsigned short) usb_number(l_device, CFSTR(kIOHIDMaxInputReportSizeKey));
                d->output_report_length = (unsigned short) usb_number(l_device, CFSTR(kIOHIDMaxOutputReportSizeKey));
                d->feature_report_length = (unsigned short) usb_number(l_device, CFSTR(kIOHIDMaxFeatureReportSizeKey));
                usb_text(l_device, CFSTR(kIOHIDProductKey), d->product_name, sizeof(d->product_name));
                usb_text(l_device, CFSTR(kIOHIDManufacturerKey), d->manufacturer, sizeof(d->manufacturer));
                l_entry = 0;
                IORegistryEntryGetRegistryEntryID(IOHIDDeviceGetService(l_device), &l_entry);
                snprintf(d->device_path, sizeof(d->device_path), "IOService:%llu", (unsigned long long) l_entry);
                g_device_count++;
            }
            free(l_all);
        }
        CFRelease(l_set);
    }
    CFRelease(l_manager);
    return g_device_count;
}

static inline void* usb_hid_get_device(int index)
{
    return (index >= 0 && index < g_device_count) ? &g_devices[index] : NULL;
}

static inline void usb_hid_free_enumeration(void) { g_device_count = 0; }

static inline int usb_device_vendor_id(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->vendor_id : 0; }
static inline int usb_device_product_id(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->product_id : 0; }
static inline const char* usb_device_product_name(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->product_name : ""; }
static inline const char* usb_device_manufacturer(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->manufacturer : ""; }
static inline const char* usb_device_path(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->device_path : ""; }
static inline int usb_hid_usage_page(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->usage_page : 0; }
static inline int usb_hid_usage(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->usage : 0; }
static inline int usb_hid_input_report_length(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->input_report_length : 0; }
static inline int usb_hid_output_report_length(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->output_report_length : 0; }
static inline int usb_hid_feature_report_length(void* handle) { return handle ? ((UsbDeviceInfo*) handle)->feature_report_length : 0; }

typedef struct {
    IOHIDDeviceRef device;
    dispatch_queue_t queue;
    pthread_mutex_t lock;
    pthread_cond_t ready;
    unsigned char ring[USB_RING_SLOTS][USB_REPORT_MAX];
    int sizes[USB_RING_SLOTS];
    int head;
    int count;
    unsigned char incoming[USB_REPORT_MAX];
} UsbOpenDevice;

static void usb_on_report(void* a_context, IOReturn a_result, void* a_sender, IOHIDReportType a_type,
                          uint32_t a_id, uint8_t* a_report, CFIndex a_length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) a_context;
    int l_slot, l_size = a_length > USB_REPORT_MAX ? USB_REPORT_MAX : (int) a_length;
    (void) a_result; (void) a_sender; (void) a_type; (void) a_id;
    pthread_mutex_lock(&o->lock);
    if (o->count == USB_RING_SLOTS) {
        /* Full: the oldest report goes, as a slow reader loses reports on Windows too. */
        o->head = (o->head + 1) % USB_RING_SLOTS;
        o->count--;
    }
    l_slot = (o->head + o->count) % USB_RING_SLOTS;
    memcpy(o->ring[l_slot], a_report, (size_t) l_size);
    o->sizes[l_slot] = l_size;
    o->count++;
    pthread_cond_broadcast(&o->ready);
    pthread_mutex_unlock(&o->lock);
}

static inline void* usb_hid_open(const char* path)
{
    unsigned long long l_entry = 0;
    io_service_t l_service;
    IOHIDDeviceRef l_device;
    UsbOpenDevice* o;

    if (!path || sscanf(path, "IOService:%llu", &l_entry) != 1) return NULL;
    l_service = IOServiceGetMatchingService(kIOMainPortDefault, IORegistryEntryIDMatching(l_entry));
    if (!l_service) return NULL;
    l_device = IOHIDDeviceCreate(kCFAllocatorDefault, l_service);
    IOObjectRelease(l_service);
    if (!l_device) return NULL;
    if (IOHIDDeviceOpen(l_device, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
        CFRelease(l_device);
        return NULL;
    }
    o = (UsbOpenDevice*) calloc(1, sizeof(UsbOpenDevice));
    if (!o) {
        IOHIDDeviceClose(l_device, kIOHIDOptionsTypeNone);
        CFRelease(l_device);
        return NULL;
    }
    pthread_mutex_init(&o->lock, NULL);
    pthread_cond_init(&o->ready, NULL);
    o->device = l_device;
    o->queue = dispatch_queue_create("simple_usb", NULL);
    IOHIDDeviceRegisterInputReportCallback(l_device, o->incoming, USB_REPORT_MAX, usb_on_report, o);
    IOHIDDeviceSetDispatchQueue(l_device, o->queue);
    IOHIDDeviceActivate(l_device);
    return o;
}

static inline void usb_hid_close(void* handle)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    if (o) {
        IOHIDDeviceCancel(o->device);
        dispatch_sync(o->queue, ^{ });
        IOHIDDeviceClose(o->device, kIOHIDOptionsTypeNone);
        CFRelease(o->device);
        dispatch_release(o->queue);
        pthread_cond_destroy(&o->ready);
        pthread_mutex_destroy(&o->lock);
        free(o);
    }
}

/* With the lock held: move the oldest report into `buffer'. */
static int usb_take(UsbOpenDevice* o, void* buffer, int length)
{
    int l_size = o->sizes[o->head] < length ? o->sizes[o->head] : length;
    memcpy(buffer, o->ring[o->head], (size_t) l_size);
    o->head = (o->head + 1) % USB_RING_SLOTS;
    o->count--;
    return l_size;
}

/* Bytes read, 0 on timeout, -1 on error. A negative timeout waits for ever. */
static inline int usb_hid_read_timeout(void* handle, void* buffer, int length, int timeout_ms)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    struct timespec l_until;
    int l_wait = 0, l_result = 0;

    if (!o) return -1;
    if (timeout_ms >= 0) {
        clock_gettime(CLOCK_REALTIME, &l_until);
        l_until.tv_sec += timeout_ms / 1000;
        l_until.tv_nsec += (long) (timeout_ms % 1000) * 1000000L;
        if (l_until.tv_nsec >= 1000000000L) { l_until.tv_sec++; l_until.tv_nsec -= 1000000000L; }
    }
    pthread_mutex_lock(&o->lock);
    while (o->count == 0 && l_wait == 0) {
        if (timeout_ms < 0) {
            pthread_cond_wait(&o->ready, &o->lock);
        } else {
            l_wait = pthread_cond_timedwait(&o->ready, &o->lock, &l_until);
        }
    }
    if (o->count > 0) l_result = usb_take(o, buffer, length);
    pthread_mutex_unlock(&o->lock);
    return l_result;
}

static inline int usb_hid_read(void* handle, void* buffer, int length)
{
    return usb_hid_read_timeout(handle, buffer, length, -1);
}

/* The first byte is the report id; a 0 there is not sent. */
static int usb_set_report(void* handle, IOHIDReportType a_type, void* buffer, int length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    const uint8_t* l_data = (const uint8_t*) buffer;
    CFIndex l_id, l_size = length;
    if (!o || !l_data || length <= 0) return -1;
    l_id = l_data[0];
    if (l_id == 0) { l_data++; l_size--; }
    return IOHIDDeviceSetReport(o->device, a_type, l_id, l_data, l_size) == kIOReturnSuccess ? length : -1;
}

static inline int usb_hid_write(void* handle, void* buffer, int length)
{
    return usb_set_report(handle, kIOHIDReportTypeOutput, buffer, length);
}

static inline int usb_hid_send_feature_report(void* handle, void* buffer, int length)
{
    return usb_set_report(handle, kIOHIDReportTypeFeature, buffer, length);
}

static inline int usb_hid_get_feature_report(void* handle, void* buffer, int length)
{
    UsbOpenDevice* o = (UsbOpenDevice*) handle;
    uint8_t* l_data = (uint8_t*) buffer;
    CFIndex l_size = length;
    if (!o || !l_data || length <= 0) return -1;
    return IOHIDDeviceGetReport(o->device, kIOHIDReportTypeFeature, l_data[0], l_data, &l_size) == kIOReturnSuccess ? (int) l_size : -1;
}

#endif /* USB_BRIDGE_MAC_H */
