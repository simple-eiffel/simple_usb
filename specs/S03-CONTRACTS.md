# S03 - Contracts: simple_usb

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_usb
**Date:** 2026-01-23

## SIMPLE_USB Contracts

### Initialization

```eiffel
make
    ensure
        initialized: is_initialized
```

### Device Discovery

```eiffel
find_device (a_vendor_id, a_product_id: INTEGER): detachable USB_DEVICE
    require
        valid_ids: a_vendor_id >= 0 and a_product_id >= 0

find_hid_device (a_vendor_id, a_product_id: INTEGER): detachable USB_HID_DEVICE
    require
        valid_ids: a_vendor_id >= 0 and a_product_id >= 0
```

## USB_HID_DEVICE Contracts

### Device Operations

```eiffel
open: BOOLEAN
    require
        not_already_open: not is_open
    ensure
        success_implies_open: Result implies is_open

close
    require
        is_open: is_open
    ensure
        closed: not is_open

read_report: detachable USB_HID_REPORT
    require
        is_open: is_open

write_report (a_report: USB_HID_REPORT): BOOLEAN
    require
        is_open: is_open
        report_attached: a_report /= Void
```

### Feature Reports

```eiffel
get_feature_report (a_report_id: INTEGER): detachable USB_HID_REPORT
    require
        is_open: is_open
        valid_id: a_report_id >= 0

send_feature_report (a_report: USB_HID_REPORT): BOOLEAN
    require
        is_open: is_open
        report_attached: a_report /= Void
```

## USB_DEVICE Contracts

```eiffel
vendor_id: INTEGER
    ensure
        valid_range: Result >= 0 and Result <= 0xFFFF

product_id: INTEGER
    ensure
        valid_range: Result >= 0 and Result <= 0xFFFF

vendor_id_hex: STRING
    ensure
        length_4: Result.count = 4  -- "1234"

product_id_hex: STRING
    ensure
        length_4: Result.count = 4  -- "5678"
```

## Invariants

```eiffel
class SIMPLE_USB
invariant
    devices_not_void: internal_devices /= Void
    hid_devices_not_void: internal_hid_devices /= Void
    gamepads_not_void: internal_gamepads /= Void
end

class USB_DEVICE
invariant
    valid_vendor_id: vendor_id >= 0 and vendor_id <= 0xFFFF
    valid_product_id: product_id >= 0 and product_id <= 0xFFFF
end

class USB_HID_DEVICE
invariant
    report_lengths_positive: input_report_length >= 0 and output_report_length >= 0
end
```
