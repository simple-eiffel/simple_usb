/*
 * usb_bridge_none.h - the usb_bridge.h calls where no backend exists yet.
 * Linux lands here until its backend is written: no devices, nothing opens.
 *
 * Copyright (c) 2026 Larry Rix - MIT License
 */

#ifndef USB_BRIDGE_NONE_H
#define USB_BRIDGE_NONE_H

static inline int usb_hid_enumerate(void) { return 0; }
static inline void* usb_hid_get_device(int index) { (void) index; return 0; }
static inline void usb_hid_free_enumeration(void) { }
static inline int usb_device_vendor_id(void* h) { (void) h; return 0; }
static inline int usb_device_product_id(void* h) { (void) h; return 0; }
static inline const char* usb_device_product_name(void* h) { (void) h; return ""; }
static inline const char* usb_device_manufacturer(void* h) { (void) h; return ""; }
static inline const char* usb_device_path(void* h) { (void) h; return ""; }
static inline int usb_hid_usage_page(void* h) { (void) h; return 0; }
static inline int usb_hid_usage(void* h) { (void) h; return 0; }
static inline int usb_hid_input_report_length(void* h) { (void) h; return 0; }
static inline int usb_hid_output_report_length(void* h) { (void) h; return 0; }
static inline int usb_hid_feature_report_length(void* h) { (void) h; return 0; }
static inline void* usb_hid_open(const char* p) { (void) p; return 0; }
static inline void usb_hid_close(void* h) { (void) h; }
static inline int usb_hid_read(void* h, void* b, int l) { (void) h; (void) b; (void) l; return -1; }
static inline int usb_hid_read_timeout(void* h, void* b, int l, int t) { (void) h; (void) b; (void) l; (void) t; return -1; }
static inline int usb_hid_write(void* h, void* b, int l) { (void) h; (void) b; (void) l; return -1; }
static inline int usb_hid_send_feature_report(void* h, void* b, int l) { (void) h; (void) b; (void) l; return -1; }
static inline int usb_hid_get_feature_report(void* h, void* b, int l) { (void) h; (void) b; (void) l; return -1; }

#endif /* USB_BRIDGE_NONE_H */
