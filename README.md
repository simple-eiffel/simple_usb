<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_usb

**[Documentation](https://simple-eiffel.github.io/simple_usb/)** | **[GitHub](https://github.com/simple-eiffel/simple_usb)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)]()

USB device access library for Eiffel. Enumerate devices, read HID reports, and work with gamepads.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Development** - Windows-only, HID device support

## Overview

SIMPLE_USB provides USB device enumeration and HID device access using Windows SetupAPI and HID API. Features include:

- **Device enumeration** - List all USB/HID devices with VID, PID, names
- **HID device access** - Read/write HID reports
- **Gamepad support** - Specialized gamepad class with axes and buttons
- **Arduino detection** - Find Arduino devices by known VID/PIDs

Uses inline C externals - no external DLLs required.

## Quick Start

```eiffel
local
    usb: SIMPLE_USB
do
    create usb.make

    -- List all USB devices
    across usb.devices as d loop
        print (d.product_name + " [" + d.id_string + "]%N")
    end

    -- Find specific device
    if attached usb.find_device (0x2341, 0x0043) as arduino then
        print ("Found Arduino: " + arduino.product_name + "%N")
    end
end
```

## HID Device Access

```eiffel
local
    usb: SIMPLE_USB
do
    create usb.make

    across usb.hid_devices as hid loop
        print (hid.display_name + "%N")
        print ("  Usage: " + hid.usage_page.to_hex_string + ":" + hid.usage.to_hex_string + "%N")

        if hid.open then
            if attached hid.read_report as report then
                print ("  Report: " + report.to_hex_string + "%N")
            end
            hid.close
        end
    end
end
```

## Gamepad Support

```eiffel
local
    usb: SIMPLE_USB
do
    create usb.make

    across usb.gamepads as gp loop
        print ("Gamepad: " + gp.product_name + "%N")

        if gp.open then
            if gp.poll then
                print ("  Left Stick: " + gp.left_stick_x.out + ", " + gp.left_stick_y.out + "%N")
                print ("  Button 0: " + gp.button (0).out + "%N")
            end
            gp.close
        end
    end
end
```

## HID Reports

```eiffel
local
    report: USB_HID_REPORT
do
    -- Create output report
    create report.make_output (64, 0)  -- 64 bytes, report ID 0

    -- Set bytes
    report.set_byte (1, 0xFF)

    -- Set individual bits
    report.set_bit (2, 0, True)  -- byte 2, bit 0

    -- Send to device
    hid.write_report (report)

    -- Read report
    if attached hid.read_report as input then
        print ("Byte 0: " + input.byte_at (0).to_hex_string + "%N")
        print ("Button pressed: " + input.bit_at (1, 0).out + "%N")
    end
end
```

## Installation

1. Set the environment variable:
```batch
set SIMPLE_EIFFEL=D:\prod
```

2. Add to your ECF file:
```xml
<library name="simple_usb" location="$SIMPLE_EIFFEL/simple_usb/simple_usb.ecf"/>
```

## Dependencies

- simple_win32_api (Windows API types)

## API Reference

### SIMPLE_USB (Facade)

| Method | Description |
|--------|-------------|
| `devices` | All USB devices |
| `hid_devices` | All HID devices |
| `gamepads` | All gamepads/joysticks |
| `find_device (vid, pid)` | Find device by ID |
| `find_hid_device (vid, pid)` | Find HID device by ID |
| `find_arduino` | Find Arduino device |
| `refresh` | Re-enumerate devices |

### USB_DEVICE

| Property | Type | Description |
|----------|------|-------------|
| `vendor_id` | INTEGER | USB Vendor ID |
| `product_id` | INTEGER | USB Product ID |
| `vendor_id_hex` | STRING_32 | VID as 4-digit hex |
| `product_id_hex` | STRING_32 | PID as 4-digit hex |
| `id_string` | STRING_32 | Combined VID:PID |
| `product_name` | STRING_32 | Product name |
| `manufacturer` | STRING_32 | Manufacturer name |

### USB_HID_DEVICE

| Method | Description |
|--------|-------------|
| `open` | Open device for I/O |
| `close` | Close device |
| `read_report` | Read input report |
| `write_report` | Write output report |
| `is_gamepad` | True if gamepad/joystick |
| `is_keyboard` | True if keyboard |
| `is_mouse` | True if mouse |

### USB_GAMEPAD

| Property | Description |
|----------|-------------|
| `left_stick_x/y` | Left analog stick |
| `right_stick_x/y` | Right analog stick |
| `buttons` | Button states array |
| `poll` | Read and update state |

## Platform Support

Currently Windows-only. Uses:
- SetupAPI for device enumeration
- HID API for HID device access

## License

MIT License - see LICENSE file

---

Part of the **Simple Eiffel** ecosystem - modern, contract-driven Eiffel libraries.
