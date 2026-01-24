# Drift Analysis: simple_usb

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 784 |
| research/*.md | 1 | 427 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_USB | 52 | 33 | -19 |

## Feature-Level Drift

### Specified, Implemented ✓
- `device_count` ✓
- `find_arduino` ✓
- `find_device` ✓
- `find_hid_device` ✓
- `gamepad_count` ✓
- `hid_count` ✓
- `hid_devices` ✓
- `is_initialized` ✓
- `last_error` ✓

### Specified, NOT Implemented ✗
- `axis_count` ✗
- `axis_value` ✗
- `button_count` ✗
- `byte_at` ✗
- `device_class` ✗
- `device_path` ✗
- `feature_report_length` ✗
- `get_feature_report` ✗
- `hid_close` ✗
- `hid_enumerate` ✗
- ... and 33 more

### Implemented, NOT Specified
- `Io`
- `Operating_environment`
- `author`
- `conforms_to`
- `copy`
- `date`
- `default_rescue`
- `description`
- `devices`
- `devices_not_void`
- ... and 14 more

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 9 |
| Spec'd, missing | 43 |
| Implemented, not spec'd | 24 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_usb** has high drift. Significant gaps between spec and implementation.
