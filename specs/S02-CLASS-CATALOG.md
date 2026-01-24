# S02 - Class Catalog: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## Class Hierarchy

```
SIMPLE_USB (facade)
|
+-- USB_DEVICE (base)
|   +-- USB_HID_DEVICE
|       +-- USB_GAMEPAD
|
+-- USB_HID_REPORT
|
+-- USB_BULK_DEVICE (planned)
```

## Class Descriptions

### SIMPLE_USB (Facade)
Main entry point for USB device access. Provides device enumeration and discovery.

**Creation:** `make`

**Key Features:**
- `devices` - All USB devices
- `hid_devices` - HID devices only
- `gamepads` - Game controllers
- `find_device(vid, pid)` - Find by VID/PID
- `find_arduino` - Find Arduino devices
- `refresh` - Re-enumerate devices

### USB_DEVICE (Base)
Base class for all USB devices with identification properties.

**Properties:**
- `vendor_id` - Vendor ID (VID)
- `product_id` - Product ID (PID)
- `product_name` - Device name
- `manufacturer` - Manufacturer name
- `device_path` - System path
- `is_connected` - Connection status
- `device_class` - USB class code

### USB_HID_DEVICE
HID (Human Interface Device) with report read/write capability.

**Inherits:** USB_DEVICE

**Additional Features:**
- `open` / `close` - Device handle
- `read_report` - Read input report
- `write_report` - Write output report
- `get_feature_report` - Get feature report
- `send_feature_report` - Send feature report
- `input_report_length` - Input size
- `output_report_length` - Output size
- `is_gamepad` - Controller detection

### USB_HID_REPORT
Container for HID report data.

**Properties:**
- `report_id` - Report identifier
- `data` - Raw bytes (ARRAY [NATURAL_8])
- `count` - Data length

### USB_GAMEPAD
Specialized HID device for game controllers.

**Inherits:** USB_HID_DEVICE

**Additional Features:**
- `buttons` - Button states (ARRAY [BOOLEAN])
- `axes` - Axis values (ARRAY [INTEGER])
- `left_stick_x/y` - Left stick position
- `right_stick_x/y` - Right stick position
- `triggers` - Trigger values
- `dpad` - D-pad state

## Class Count Summary
- Facade: 1
- Device classes: 4
- Data classes: 1
- **Total: 6 classes**
