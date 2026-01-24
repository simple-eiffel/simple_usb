# S04 - Feature Specifications: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## Core Features

### SIMPLE_USB (Facade)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `()` | Initialize USB subsystem |
| `is_initialized` | `: BOOLEAN` | Subsystem ready? |
| `device_count` | `: INTEGER` | Total USB devices |
| `hid_count` | `: INTEGER` | HID devices count |
| `gamepad_count` | `: INTEGER` | Gamepads count |
| `last_error` | `: detachable STRING_32` | Last error |
| `devices` | `: LIST [USB_DEVICE]` | All devices |
| `hid_devices` | `: LIST [USB_HID_DEVICE]` | HID devices |
| `gamepads` | `: LIST [USB_GAMEPAD]` | Gamepads |
| `find_device` | `(vid, pid: INTEGER): USB_DEVICE` | Find by ID |
| `find_hid_device` | `(vid, pid: INTEGER): USB_HID_DEVICE` | Find HID |
| `find_arduino` | `: USB_HID_DEVICE` | Find Arduino |
| `refresh` | `()` | Re-enumerate |

### USB_DEVICE

| Feature | Signature | Description |
|---------|-----------|-------------|
| `vendor_id` | `: INTEGER` | VID (0x0000-0xFFFF) |
| `product_id` | `: INTEGER` | PID (0x0000-0xFFFF) |
| `vendor_id_hex` | `: STRING` | VID as "1234" |
| `product_id_hex` | `: STRING` | PID as "5678" |
| `product_name` | `: STRING` | Device name |
| `manufacturer` | `: STRING` | Manufacturer |
| `serial_number` | `: STRING` | Serial number |
| `device_path` | `: STRING` | System path |
| `is_connected` | `: BOOLEAN` | Still connected? |
| `device_class` | `: INTEGER` | USB class code |

### USB_HID_DEVICE

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make_from_handle` | `(handle: POINTER)` | Create from C handle |
| `is_open` | `: BOOLEAN` | Device opened? |
| `open` | `: BOOLEAN` | Open device |
| `close` | `()` | Close device |
| `read_report` | `: USB_HID_REPORT` | Read input |
| `write_report` | `(report: USB_HID_REPORT): BOOLEAN` | Write output |
| `get_feature_report` | `(id: INTEGER): USB_HID_REPORT` | Get feature |
| `send_feature_report` | `(report: USB_HID_REPORT): BOOLEAN` | Send feature |
| `input_report_length` | `: INTEGER` | Input size (bytes) |
| `output_report_length` | `: INTEGER` | Output size (bytes) |
| `feature_report_length` | `: INTEGER` | Feature size |
| `is_gamepad` | `: BOOLEAN` | Is game controller? |

### USB_GAMEPAD

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make_from_hid` | `(hid: USB_HID_DEVICE)` | Create from HID |
| `update` | `()` | Read current state |
| `buttons` | `: ARRAY [BOOLEAN]` | Button states |
| `button_count` | `: INTEGER` | Number of buttons |
| `is_button_pressed` | `(index: INTEGER): BOOLEAN` | Check button |
| `axes` | `: ARRAY [INTEGER]` | Axis values |
| `axis_count` | `: INTEGER` | Number of axes |
| `axis_value` | `(index: INTEGER): INTEGER` | Get axis |
| `left_stick_x` | `: INTEGER` | Left X (-32768 to 32767) |
| `left_stick_y` | `: INTEGER` | Left Y |
| `right_stick_x` | `: INTEGER` | Right X |
| `right_stick_y` | `: INTEGER` | Right Y |
| `left_trigger` | `: INTEGER` | Left trigger (0-255) |
| `right_trigger` | `: INTEGER` | Right trigger |
| `dpad` | `: INTEGER` | D-pad direction |

### USB_HID_REPORT

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(size: INTEGER)` | Create with size |
| `report_id` | `: INTEGER` | Report ID |
| `data` | `: ARRAY [NATURAL_8]` | Raw bytes |
| `count` | `: INTEGER` | Data length |
| `byte_at` | `(index: INTEGER): NATURAL_8` | Get byte |
| `set_byte_at` | `(index: INTEGER; value: NATURAL_8)` | Set byte |

## Common VID/PID Values

| Device | VID | PID | Description |
|--------|-----|-----|-------------|
| Arduino Uno | 0x2341 | 0x0043 | Arduino.cc Uno |
| Arduino Mega | 0x2341 | 0x0042 | Arduino.cc Mega |
| Arduino Leonardo | 0x2341 | 0x8036 | HID-capable |
| Xbox Controller | 0x045E | 0x028E | Microsoft Xbox 360 |
| PlayStation | 0x054C | Various | Sony |
