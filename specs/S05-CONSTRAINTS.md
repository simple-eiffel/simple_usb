# S05 - Constraints: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## Identifier Constraints

### Vendor/Product ID
```
Range: 0x0000 to 0xFFFF (16-bit)
Eiffel type: INTEGER (positive values only)
Display: 4-digit hex string ("1234")
```

### Report ID
```
Range: 0 to 255 (8-bit)
ID 0 = default (single report device)
```

## HID Report Constraints

### Report Sizes
```
Input report:  1 to 64 bytes (typical)
Output report: 1 to 64 bytes (typical)
Feature report: 1 to 64 bytes (typical)
Maximum: 65535 bytes (USB HID spec)
```

### Report Data
```
Type: ARRAY [NATURAL_8]
Index: 1-based (Eiffel convention)
First byte may be report ID
```

## Device Access Constraints

### Handle Management
```eiffel
-- Device must be opened before read/write
read_report requires is_open
write_report requires is_open

-- Device must not be double-opened
open requires not is_open

-- Device should be closed when done
close requires is_open
```

### Exclusive Access
- Only one handle per device path
- Multiple applications cannot share device
- Some devices allow shared access (keyboards, mice)

## Gamepad Constraints

### Axis Values
```
Standard range: -32768 to 32767 (16-bit signed)
Trigger range: 0 to 255 (8-bit unsigned)
D-pad: Bitmask or POV angle
```

### Button Indices
```
Index: 0 to button_count - 1
State: BOOLEAN (pressed/not pressed)
```

## Platform Constraints

### Windows-Specific
- Requires Windows Vista or later
- Uses SetupAPI for enumeration
- Uses HID API for device access
- Requires setupapi.lib, hid.lib

### Driver Requirements
- HID devices: Windows HID driver (built-in)
- Custom devices: May need WinUSB driver
- Some devices need vendor drivers

## Error Constraints

### Error Conditions
| Condition | Result |
|-----------|--------|
| Device not found | find_* returns Void |
| Open failed | open returns False |
| Read failed | read_report returns Void |
| Write failed | write_report returns False |
| Device disconnected | Operations fail |

### Error Messages
- Available via `last_error` feature
- Includes Windows error codes
- Human-readable descriptions

## Threading Constraints

### Not Thread-Safe
- Device handles are not shareable
- Enumeration should be single-threaded
- For SCOOP: one processor per device
