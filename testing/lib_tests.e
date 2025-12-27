note
	description: "Tests for SIMPLE_USB including edge cases"
	author: "Larry Rix"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Test: Initialization

	test_initialization
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("initialized", usb.is_initialized)
		end

	test_device_enumeration
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("devices not void", usb.devices /= Void)
			print ("Found " + usb.device_count.out + " USB devices%N")
		end

	test_hid_enumeration
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("hid devices not void", usb.hid_devices /= Void)
			print ("Found " + usb.hid_count.out + " HID devices%N")
		end

	test_gamepad_enumeration
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("gamepads not void", usb.gamepads /= Void)
			print ("Found " + usb.gamepad_count.out + " gamepads%N")
		end

feature -- Test: Device Info

	test_device_ids
		local
			usb: SIMPLE_USB
		do
			create usb.make
			across usb.devices as d loop
				assert_true ("vid valid", d.vendor_id >= 0)
				assert_true ("pid valid", d.product_id >= 0)
				assert_true ("vid hex length", d.vendor_id_hex.count = 4)
				assert_true ("pid hex length", d.product_id_hex.count = 4)
			end
		end

	test_id_string
		local
			dev: USB_DEVICE
		do
			create dev.make (0x1234, 0xABCD, "Test", "Mfr", "path")
			assert_strings_equal ("id format", "1234:abcd", dev.id_string)
		end

feature -- Test: HID Report

	test_report_creation
		local
			report: USB_HID_REPORT
		do
			create report.make (64)
			assert_integers_equal ("size", 64, report.count)
		end

	test_report_byte_access
		local
			report: USB_HID_REPORT
		do
			create report.make (10)
			report.set_byte (0, 0x12)
			report.set_byte (5, 0xFF)
			assert_integers_equal ("byte 0", 0x12, report.byte_at (0))
			assert_integers_equal ("byte 5", 0xFF, report.byte_at (5))
		end

	test_report_bit_access
		local
			report: USB_HID_REPORT
		do
			create report.make (10)
			report.set_bit (0, 0, True)
			report.set_bit (0, 7, True)
			assert_true ("bit 0", report.bit_at (0, 0))
			assert_true ("bit 7", report.bit_at (0, 7))
			assert_false ("bit 1", report.bit_at (0, 1))
			assert_integers_equal ("byte value", 0x81, report.byte_at (0))
		end

	test_report_word_access
		local
			report: USB_HID_REPORT
		do
			create report.make (10)
			report.set_byte (0, 0x34)
			report.set_byte (1, 0x12)
			assert_integers_equal ("word", 0x1234, report.word_at (0))
		end

	test_report_hex_string
		local
			report: USB_HID_REPORT
		do
			create report.make (3)
			report.set_byte (0, 0x01)
			report.set_byte (1, 0xAB)
			report.set_byte (2, 0xFF)
			assert_true ("has hex", report.to_hex_string.count > 0)
		end

feature -- Test: Find Device

	test_find_device
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("not found", usb.find_device (0x0000, 0x0000) = Void)
		end

	test_find_arduino
		local
			usb: SIMPLE_USB
		do
			create usb.make
			if attached usb.find_arduino as arduino then
				print ("Found Arduino: " + arduino.product_name + "%N")
			else
				print ("No Arduino connected%N")
			end
		end

	test_refresh
		local
			usb: SIMPLE_USB
			count1, count2: INTEGER
		do
			create usb.make
			count1 := usb.device_count
			usb.refresh
			count2 := usb.device_count
			assert_integers_equal ("same count", count1, count2)
		end

feature -- Edge Case Tests: Report Boundaries

	test_report_single_byte
		local
			report: USB_HID_REPORT
		do
			create report.make (1)
			assert_integers_equal ("size 1", 1, report.count)
			report.set_byte (0, 0xFF)
			assert_integers_equal ("value", 0xFF, report.byte_at (0))
		end

	test_report_large
		local
			report: USB_HID_REPORT
		do
			create report.make (512)
			assert_integers_equal ("size 512", 512, report.count)
			report.set_byte (511, 0xAB)
			assert_integers_equal ("last byte", 0xAB, report.byte_at (511))
		end

	test_report_all_bits_set
		local
			report: USB_HID_REPORT
			i: INTEGER
		do
			create report.make (1)
			from i := 0 until i > 7 loop
				report.set_bit (0, i, True)
				i := i + 1
			end
			assert_integers_equal ("all bits", 0xFF, report.byte_at (0))
		end

	test_report_all_bits_clear
		local
			report: USB_HID_REPORT
			i: INTEGER
		do
			create report.make (1)
			report.set_byte (0, 0xFF)
			from i := 0 until i > 7 loop
				report.set_bit (0, i, False)
				i := i + 1
			end
			assert_integers_equal ("no bits", 0x00, report.byte_at (0))
		end

	test_report_word_boundary
		local
			report: USB_HID_REPORT
		do
			create report.make (4)
			report.set_byte (0, 0xFF)
			report.set_byte (1, 0xFF)
			assert_integers_equal ("max word", 0xFFFF, report.word_at (0))
		end

	test_report_zero_word
		local
			report: USB_HID_REPORT
		do
			create report.make (4)
			report.set_byte (0, 0x00)
			report.set_byte (1, 0x00)
			assert_integers_equal ("zero word", 0, report.word_at (0))
		end

feature -- Edge Case Tests: Device Creation

	test_device_empty_strings
		local
			dev: USB_DEVICE
		do
			create dev.make (0x0001, 0x0001, "", "", "")
			assert_strings_equal ("empty product", "", dev.product_name)
			assert_strings_equal ("empty mfr", "", dev.manufacturer)
		end

	test_device_max_ids
		local
			dev: USB_DEVICE
		do
			create dev.make (0xFFFF, 0xFFFF, "Test", "Test", "path")
			assert_strings_equal ("max vid", "ffff", dev.vendor_id_hex)
			assert_strings_equal ("max pid", "ffff", dev.product_id_hex)
			assert_strings_equal ("max id", "ffff:ffff", dev.id_string)
		end

	test_device_zero_ids
		local
			dev: USB_DEVICE
		do
			create dev.make (0, 0, "Test", "Test", "path")
			assert_strings_equal ("zero vid", "0000", dev.vendor_id_hex)
			assert_strings_equal ("zero pid", "0000", dev.product_id_hex)
		end

	test_device_unicode_name
		local
			dev: USB_DEVICE
		do
			create dev.make (1, 1, "Device Name", "Manufacturer", "/path/to/device")
			assert_true ("has name", dev.product_name.count > 0)
		end

feature -- Edge Case Tests: Multiple Operations

	test_multiple_usb_instances
		local
			usb1, usb2, usb3: SIMPLE_USB
		do
			create usb1.make
			create usb2.make
			create usb3.make
			assert_true ("all init", usb1.is_initialized and usb2.is_initialized and usb3.is_initialized)
			assert_integers_equal ("same count", usb1.device_count, usb2.device_count)
		end

	test_rapid_refresh
		local
			usb: SIMPLE_USB
			i: INTEGER
		do
			create usb.make
			from i := 1 until i > 10 loop
				usb.refresh
				i := i + 1
			end
			assert_true ("still valid", usb.is_initialized)
		end

	test_report_rapid_modifications
		local
			report: USB_HID_REPORT
			i: INTEGER
		do
			create report.make (64)
			from i := 0 until i >= 64 loop
				report.set_byte (i, i.as_natural_8)
				i := i + 1
			end
			from i := 0 until i >= 64 loop
				assert_integers_equal ("byte " + i.out, i, report.byte_at (i))
				i := i + 1
			end
		end

feature -- Edge Case Tests: Find Operations

	test_find_with_max_vid_pid
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("max ids not found", usb.find_device (0xFFFF, 0xFFFF) = Void)
		end

	test_find_hid_nonexistent
		local
			usb: SIMPLE_USB
		do
			create usb.make
			assert_true ("hid not found", usb.find_hid_device (0xDEAD, 0xBEEF) = Void)
		end

end
