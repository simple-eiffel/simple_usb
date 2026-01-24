# S01 - Project Inventory: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Version:** 1.0
**Date:** 2026-01-23

## Overview

USB device access library for Eiffel providing device enumeration, HID device communication, and gamepad support using Windows SetupAPI and HID API.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/simple_usb.e` | Main facade class |
| `src/usb_device.e` | Base device representation |
| `src/usb_hid_device.e` | HID device with read/write |
| `src/usb_hid_report.e` | HID report data |
| `src/usb_gamepad.e` | Gamepad/controller support |

### C Bridge Files
| File | Purpose |
|------|---------|
| `Clib/usb_bridge.h` | C header for USB operations |
| `Clib/Makefile.win` | Windows build configuration |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_usb.ecf` | EiffelStudio project configuration |
| `simple_usb.rc` | Windows resource file |

### Documentation
| File | Purpose |
|------|---------|
| `README.md` | Project documentation |
| `docs/` | API documentation |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)
- wel (Windows externals)

### simple_* Libraries
- simple_win32_api (optional, for advanced features)

### Windows Libraries (Native)
```
setupapi.lib  - Device enumeration
hid.lib       - HID device access
winusb.lib    - WinUSB device access
```

## Build Targets
- `simple_usb` - Main library
- `simple_usb_tests` - Test suite
