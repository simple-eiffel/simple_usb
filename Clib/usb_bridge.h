/*
 * usb_bridge.h - USB HID Bridge for Eiffel
 *
 * Windows implementation using SetupAPI and HID API.
 * All functions are inline for Eric Bezault pattern.
 */

#ifndef USB_BRIDGE_H
#define USB_BRIDGE_H

#include <windows.h>
#include <setupapi.h>
#include <hidsdi.h>
#include <hidpi.h>
#include <stdio.h>

#pragma comment(lib, "setupapi.lib")
#pragma comment(lib, "hid.lib")

/* Maximum devices to enumerate */
#define USB_MAX_DEVICES 128

/* Device info structure */
typedef struct {
    USHORT vendor_id;
    USHORT product_id;
    char product_name[256];
    char manufacturer[256];
    char device_path[512];
    USHORT usage_page;
    USHORT usage;
    USHORT input_report_length;
    USHORT output_report_length;
    USHORT feature_report_length;
} UsbDeviceInfo;

/* Global state */
static UsbDeviceInfo g_devices[USB_MAX_DEVICES];
static int g_device_count = 0;

/*
 * Enumerate HID devices
 */
static inline int usb_hid_enumerate(void) {
    GUID hid_guid;
    HDEVINFO dev_info;
    SP_DEVICE_INTERFACE_DATA dev_interface_data;
    PSP_DEVICE_INTERFACE_DETAIL_DATA_A detail_data = NULL;
    DWORD required_size;
    DWORD i;
    HANDLE device_handle;
    HIDD_ATTRIBUTES attrs;
    PHIDP_PREPARSED_DATA preparsed_data;
    HIDP_CAPS caps;

    g_device_count = 0;

    /* Get HID GUID */
    HidD_GetHidGuid(&hid_guid);

    /* Get device info set */
    dev_info = SetupDiGetClassDevsA(&hid_guid, NULL, NULL,
                                    DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
    if (dev_info == INVALID_HANDLE_VALUE) {
        return 0;
    }

    dev_interface_data.cbSize = sizeof(SP_DEVICE_INTERFACE_DATA);

    /* Enumerate devices */
    for (i = 0; SetupDiEnumDeviceInterfaces(dev_info, NULL, &hid_guid, i, &dev_interface_data); i++) {
        if (g_device_count >= USB_MAX_DEVICES) break;

        /* Get required size */
        SetupDiGetDeviceInterfaceDetailA(dev_info, &dev_interface_data, NULL, 0, &required_size, NULL);

        detail_data = (PSP_DEVICE_INTERFACE_DETAIL_DATA_A)malloc(required_size);
        if (!detail_data) continue;

        detail_data->cbSize = sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA_A);

        if (SetupDiGetDeviceInterfaceDetailA(dev_info, &dev_interface_data,
                                             detail_data, required_size, NULL, NULL)) {
            /* Open device to get attributes */
            device_handle = CreateFileA(detail_data->DevicePath,
                                        GENERIC_READ | GENERIC_WRITE,
                                        FILE_SHARE_READ | FILE_SHARE_WRITE,
                                        NULL, OPEN_EXISTING, 0, NULL);

            if (device_handle != INVALID_HANDLE_VALUE) {
                attrs.Size = sizeof(HIDD_ATTRIBUTES);
                if (HidD_GetAttributes(device_handle, &attrs)) {
                    UsbDeviceInfo* info = &g_devices[g_device_count];

                    info->vendor_id = attrs.VendorID;
                    info->product_id = attrs.ProductID;

                    /* Copy device path */
                    strncpy(info->device_path, detail_data->DevicePath, sizeof(info->device_path) - 1);

                    /* Get product name */
                    wchar_t wbuf[256];
                    if (HidD_GetProductString(device_handle, wbuf, sizeof(wbuf))) {
                        WideCharToMultiByte(CP_UTF8, 0, wbuf, -1, info->product_name,
                                            sizeof(info->product_name), NULL, NULL);
                    } else {
                        info->product_name[0] = '\0';
                    }

                    /* Get manufacturer */
                    if (HidD_GetManufacturerString(device_handle, wbuf, sizeof(wbuf))) {
                        WideCharToMultiByte(CP_UTF8, 0, wbuf, -1, info->manufacturer,
                                            sizeof(info->manufacturer), NULL, NULL);
                    } else {
                        info->manufacturer[0] = '\0';
                    }

                    /* Get capabilities */
                    if (HidD_GetPreparsedData(device_handle, &preparsed_data)) {
                        if (HidP_GetCaps(preparsed_data, &caps) == HIDP_STATUS_SUCCESS) {
                            info->usage_page = caps.UsagePage;
                            info->usage = caps.Usage;
                            info->input_report_length = caps.InputReportByteLength;
                            info->output_report_length = caps.OutputReportByteLength;
                            info->feature_report_length = caps.FeatureReportByteLength;
                        }
                        HidD_FreePreparsedData(preparsed_data);
                    }

                    g_device_count++;
                }
                CloseHandle(device_handle);
            }
        }

        free(detail_data);
        detail_data = NULL;
    }

    SetupDiDestroyDeviceInfoList(dev_info);
    return g_device_count;
}

/*
 * Get device at index
 */
static inline void* usb_hid_get_device(int index) {
    if (index >= 0 && index < g_device_count) {
        return &g_devices[index];
    }
    return NULL;
}

/*
 * Free enumeration resources
 */
static inline void usb_hid_free_enumeration(void) {
    /* Nothing to free - static array */
}

/*
 * Device info accessors
 */
static inline int usb_device_vendor_id(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->vendor_id : 0;
}

static inline int usb_device_product_id(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->product_id : 0;
}

static inline const char* usb_device_product_name(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->product_name : "";
}

static inline const char* usb_device_manufacturer(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->manufacturer : "";
}

static inline const char* usb_device_path(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->device_path : "";
}

/*
 * HID info accessors
 */
static inline int usb_hid_usage_page(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->usage_page : 0;
}

static inline int usb_hid_usage(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->usage : 0;
}

static inline int usb_hid_input_report_length(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->input_report_length : 0;
}

static inline int usb_hid_output_report_length(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->output_report_length : 0;
}

static inline int usb_hid_feature_report_length(void* handle) {
    return handle ? ((UsbDeviceInfo*)handle)->feature_report_length : 0;
}

/*
 * Open HID device
 */
static inline void* usb_hid_open(const char* path) {
    HANDLE handle = CreateFileA(path,
                                GENERIC_READ | GENERIC_WRITE,
                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                NULL, OPEN_EXISTING, 0, NULL);
    return (handle != INVALID_HANDLE_VALUE) ? handle : NULL;
}

/*
 * Close HID device
 */
static inline void usb_hid_close(void* handle) {
    if (handle) {
        CloseHandle((HANDLE)handle);
    }
}

/*
 * Read HID report
 */
static inline int usb_hid_read(void* handle, void* buffer, int length) {
    DWORD bytes_read = 0;
    if (handle && ReadFile((HANDLE)handle, buffer, length, &bytes_read, NULL)) {
        return bytes_read;
    }
    return -1;
}

/*
 * Read HID report with timeout
 */
static inline int usb_hid_read_timeout(void* handle, void* buffer, int length, int timeout_ms) {
    DWORD bytes_read = 0;
    OVERLAPPED ol = {0};
    DWORD result;

    if (!handle) return -1;

    ol.hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (!ol.hEvent) return -1;

    if (ReadFile((HANDLE)handle, buffer, length, &bytes_read, &ol)) {
        CloseHandle(ol.hEvent);
        return bytes_read;
    }

    if (GetLastError() != ERROR_IO_PENDING) {
        CloseHandle(ol.hEvent);
        return -1;
    }

    result = WaitForSingleObject(ol.hEvent, timeout_ms);
    if (result == WAIT_OBJECT_0) {
        GetOverlappedResult((HANDLE)handle, &ol, &bytes_read, FALSE);
        CloseHandle(ol.hEvent);
        return bytes_read;
    }

    CancelIo((HANDLE)handle);
    CloseHandle(ol.hEvent);
    return 0;  /* Timeout */
}

/*
 * Write HID report
 */
static inline int usb_hid_write(void* handle, void* buffer, int length) {
    DWORD bytes_written = 0;
    if (handle && WriteFile((HANDLE)handle, buffer, length, &bytes_written, NULL)) {
        return bytes_written;
    }
    return -1;
}

/*
 * Send feature report
 */
static inline int usb_hid_send_feature_report(void* handle, void* buffer, int length) {
    if (handle && HidD_SetFeature((HANDLE)handle, buffer, length)) {
        return length;
    }
    return -1;
}

/*
 * Get feature report
 */
static inline int usb_hid_get_feature_report(void* handle, void* buffer, int length) {
    if (handle && HidD_GetFeature((HANDLE)handle, buffer, length)) {
        return length;
    }
    return -1;
}

#endif /* USB_BRIDGE_H */
