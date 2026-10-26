# Changelog

All notable changes to simple_usb.

## 1.0.1 - 2026-10-26

### Fixed
- `USB_GAMEPAD.button_count` was always 0: its attribute body (`Result := 12`)
  never ran, because an INTEGER attribute initializes itself (compiler warning
  VWAB). It is now set to the new constant `Default_button_count` (12) at
  creation. `test_gamepad_default_button_count` (old code: 0), with a
  hardware-free test device, `testing/usb_test_hid_device.e`.

### Changed
- Dropped the ISE `wel` library from `simple_usb.ecf`. Nothing used it; the
  clean build links without it. simple_usb depends only on EiffelBase and
  EiffelTesting.
- Zero compiler warnings: three STRING_8 + STRING_32 concatenations now use
  `{STRING_32}` literals (obsolete `as_string_8`).
- 30 pass.

## 1.0.0 - 2025-12-26

- Initial release: device and HID enumeration, HID device input and output
  reports, gamepads, Arduino lookup.
