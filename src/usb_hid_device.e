note
	description: "[
		USB_HID_DEVICE - USB Human Interface Device

		Provides read/write access to HID devices including
		gamepads, keyboards, custom hardware.

		Example:
			if hid.open then
				if attached hid.read_report as report then
					print ("Report: " + report.count.out + " bytes%N")
				end
				hid.close
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	USB_HID_DEVICE

inherit
	USB_DEVICE
		redefine
			make_from_handle
		end

create
	make,
	make_from_handle

feature {NONE} -- Initialization

	make_from_handle (a_handle: POINTER)
			-- Create from C device info handle.
		do
			Precursor (a_handle)
			usage_page := c_get_usage_page (a_handle)
			usage := c_get_usage (a_handle)
			input_report_length := c_get_input_report_length (a_handle)
			output_report_length := c_get_output_report_length (a_handle)
			feature_report_length := c_get_feature_report_length (a_handle)
		end

feature -- HID Attributes

	usage_page: INTEGER
			-- HID usage page (e.g., 0x01 = Generic Desktop).

	usage: INTEGER
			-- HID usage (e.g., 0x04 = Joystick, 0x05 = Gamepad).

	input_report_length: INTEGER
			-- Length of input reports.

	output_report_length: INTEGER
			-- Length of output reports.

	feature_report_length: INTEGER
			-- Length of feature reports.

feature -- Device Classification

	is_gamepad: BOOLEAN
			-- Is this a gamepad/joystick?
		do
			-- Usage page 0x01 = Generic Desktop, Usage 0x04 = Joystick, 0x05 = Gamepad
			Result := usage_page = 0x01 and (usage = 0x04 or usage = 0x05)
		end

	is_keyboard: BOOLEAN
			-- Is this a keyboard?
		do
			-- Usage page 0x01 = Generic Desktop, Usage 0x06 = Keyboard
			Result := usage_page = 0x01 and usage = 0x06
		end

	is_mouse: BOOLEAN
			-- Is this a mouse?
		do
			-- Usage page 0x01 = Generic Desktop, Usage 0x02 = Mouse
			Result := usage_page = 0x01 and usage = 0x02
		end

feature -- Status

	is_open: BOOLEAN
			-- Is device currently open?

	last_error: detachable STRING_32
			-- Last error message.

feature -- Open/Close

	open: BOOLEAN
			-- Open device for I/O.
		require
			not_open: not is_open
		local
			l_path: C_STRING
		do
			create l_path.make (device_path.to_string_8)
			device_handle := c_open_device (l_path.item)
			if device_handle /= default_pointer then
				is_open := True
				Result := True
			else
				last_error := "Failed to open device: " + device_path
				Result := False
			end
		ensure
			open_on_success: Result implies is_open
		end

	close
			-- Close device.
		require
			is_open: is_open
		do
			c_close_device (device_handle)
			device_handle := default_pointer
			is_open := False
		ensure
			closed: not is_open
		end

feature -- Input

	read_report: detachable USB_HID_REPORT
			-- Read input report from device.
		require
			is_open: is_open
		local
			l_buffer: MANAGED_POINTER
			l_read: INTEGER
		do
			create l_buffer.make (input_report_length.max (64))
			l_read := c_read_report (device_handle, l_buffer.item, l_buffer.count)
			if l_read > 0 then
				create Result.make_from_buffer (l_buffer, l_read)
			end
		end

	read_report_timeout (a_timeout_ms: INTEGER): detachable USB_HID_REPORT
			-- Read input report with timeout.
		require
			is_open: is_open
			positive_timeout: a_timeout_ms > 0
		local
			l_buffer: MANAGED_POINTER
			l_read: INTEGER
		do
			create l_buffer.make (input_report_length.max (64))
			l_read := c_read_report_timeout (device_handle, l_buffer.item, l_buffer.count, a_timeout_ms)
			if l_read > 0 then
				create Result.make_from_buffer (l_buffer, l_read)
			end
		end

feature -- Output

	write_report (a_report: USB_HID_REPORT): BOOLEAN
			-- Write output report to device.
		require
			is_open: is_open
			report_not_void: a_report /= Void
		local
			l_written: INTEGER
		do
			l_written := c_write_report (device_handle, a_report.data.item, a_report.count)
			Result := l_written > 0
		end

	send_feature_report (a_report: USB_HID_REPORT): BOOLEAN
			-- Send feature report to device.
		require
			is_open: is_open
			report_not_void: a_report /= Void
		do
			Result := c_send_feature_report (device_handle, a_report.data.item, a_report.count) > 0
		end

	get_feature_report (a_report_id: INTEGER): detachable USB_HID_REPORT
			-- Get feature report from device.
		require
			is_open: is_open
			valid_id: a_report_id >= 0
		local
			l_buffer: MANAGED_POINTER
			l_read: INTEGER
		do
			create l_buffer.make (feature_report_length.max (64))
			l_buffer.put_natural_8 (a_report_id.to_natural_8, 0)
			l_read := c_get_feature_report (device_handle, l_buffer.item, l_buffer.count)
			if l_read > 0 then
				create Result.make_from_buffer (l_buffer, l_read)
			end
		end

feature {NONE} -- Implementation

	device_handle: POINTER
			-- Windows file handle for device.

feature {NONE} -- C Externals

	c_get_usage_page (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_usage_page($a_handle);"
		end

	c_get_usage (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_usage($a_handle);"
		end

	c_get_input_report_length (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_input_report_length($a_handle);"
		end

	c_get_output_report_length (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_output_report_length($a_handle);"
		end

	c_get_feature_report_length (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_feature_report_length($a_handle);"
		end

	c_open_device (a_path: POINTER): POINTER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_open($a_path);"
		end

	c_close_device (a_handle: POINTER)
		external
			"C inline use %"usb_bridge.h%""
		alias
			"usb_hid_close($a_handle);"
		end

	c_read_report (a_handle, a_buffer: POINTER; a_length: INTEGER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_read($a_handle, $a_buffer, $a_length);"
		end

	c_read_report_timeout (a_handle, a_buffer: POINTER; a_length, a_timeout: INTEGER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_read_timeout($a_handle, $a_buffer, $a_length, $a_timeout);"
		end

	c_write_report (a_handle, a_buffer: POINTER; a_length: INTEGER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_write($a_handle, $a_buffer, $a_length);"
		end

	c_send_feature_report (a_handle, a_buffer: POINTER; a_length: INTEGER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_send_feature_report($a_handle, $a_buffer, $a_length);"
		end

	c_get_feature_report (a_handle, a_buffer: POINTER; a_length: INTEGER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_get_feature_report($a_handle, $a_buffer, $a_length);"
		end

end