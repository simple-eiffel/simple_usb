# S07 - Specification Summary: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## Executive Summary

simple_usb is a USB device access library for Eiffel providing HID device enumeration, communication, and specialized gamepad support using Windows native APIs.

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Classes | 6 |
| Public Features | ~40 |
| LOC (estimated) | ~800 |
| Dependencies | base, WEL |

## Architecture Overview

```
+-------------------+
|   SIMPLE_USB      |  <-- Facade
+-------------------+
         |
    +----+----+
    |         |
+--------+ +--------+
| HID    | | Enum   |
| Device | | logic  |
+--------+ +--------+
    |
+--------+
|Gamepad |
+--------+
    |
+--------+
| C API  |
| Bridge |
+--------+
```

## Core Value Proposition

1. **Simple Enumeration** - List devices in one call
2. **HID Communication** - Read/write reports easily
3. **Gamepad Support** - Specialized controller API
4. **Arduino Detection** - Find Arduino by known VIDs
5. **Contract-Driven** - DBC for all operations

## Contract Summary

| Category | Preconditions | Postconditions |
|----------|---------------|----------------|
| Initialization | (none) | initialized |
| Find device | Valid VID/PID | Device or Void |
| Open | Not already open | is_open on success |
| Read/Write | Must be open | Result or Void |
| Close | Must be open | Not open |

## Feature Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Enumeration | 6 | Device discovery |
| HID access | 8 | Report read/write |
| Gamepad | 12 | Controller input |
| Status | 4 | Error/state queries |

## Constraints Summary

1. VID/PID: 16-bit unsigned (0-65535)
2. Report ID: 8-bit unsigned (0-255)
3. Single-threaded access
4. Windows-only platform

## Known Limitations

1. No bulk transfer support
2. No hotplug detection
3. Windows-only
4. No hub management

## Common Use Cases

| Use Case | API |
|----------|-----|
| List USB devices | `devices` |
| Find specific device | `find_device(vid, pid)` |
| Read from HID | `hid.open; hid.read_report` |
| Write to HID | `hid.write_report(data)` |
| Read gamepad | `gamepad.update; gamepad.buttons` |
| Find Arduino | `find_arduino` |

## Future Directions

1. Bulk transfer support
2. Hotplug event callbacks
3. Cross-platform (Linux, macOS)
4. XInput integration for Xbox controllers
