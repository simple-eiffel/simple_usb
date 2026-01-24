# S06 - Boundaries: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- USB device enumeration
- Device identification (VID, PID, name, manufacturer)
- HID device read/write
- Feature report access
- Gamepad/controller support
- Arduino device detection
- Device refresh/re-enumeration

### Out of Scope
- **Bulk transfer** - Not yet implemented
- **Isochronous transfer** - Audio/video streaming
- **Control transfer** - Low-level USB control
- **USB hub management** - Power, port control
- **Device drivers** - Driver installation
- **Hotplug events** - Automatic detection
- **Cross-platform** - Windows only

## API Boundaries

### Public API (SIMPLE_USB facade)
- Device enumeration
- Device discovery by VID/PID
- Arduino detection
- Refresh functionality

### Internal API (not exported)
- C bridge functions
- Windows API wrappers
- Handle management

## Integration Boundaries

### Input Boundaries

| Input Type | Format | Validation |
|------------|--------|------------|
| VID/PID | INTEGER | 0 to 0xFFFF |
| Report ID | INTEGER | 0 to 255 |
| Report data | ARRAY [NATURAL_8] | Non-void |
| Device handle | POINTER | From enumeration |

### Output Boundaries

| Output Type | Format | Notes |
|-------------|--------|-------|
| Device list | LIST [USB_DEVICE] | May be empty |
| Device | USB_DEVICE | May be Void |
| Report | USB_HID_REPORT | May be Void |
| Success | BOOLEAN | True/False |

## Performance Boundaries

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Enumerate | 100-500 ms | Depends on device count |
| Open device | < 10 ms | Handle acquisition |
| Read report | < 10 ms | Blocking read |
| Write report | < 10 ms | Blocking write |

### Resource Usage

| Resource | Usage |
|----------|-------|
| Handles | One per open device |
| Memory | ~1KB per device |
| Threads | Single-threaded |

## Extension Points

### Custom Device Classes
1. Inherit from USB_DEVICE or USB_HID_DEVICE
2. Add device-specific features
3. Create factory method in SIMPLE_USB

### Future Extensions
- USB_BULK_DEVICE for bulk transfers
- Hotplug notification system
- Cross-platform support

## Dependency Boundaries

### Required Dependencies
- EiffelBase
- WEL (Windows Eiffel Library)

### Native Libraries
```
setupapi.lib - Device enumeration
hid.lib      - HID device access
```

### Optional Dependencies
- simple_win32_api (advanced Windows features)

## Device Class Support

### Supported
- HID (class 0x03): Full support
- Vendor-specific (class 0xFF): Partial support

### Not Supported
- Audio (class 0x01)
- Mass Storage (class 0x08)
- CDC (class 0x0A)
- Smart Card (class 0x0B)
