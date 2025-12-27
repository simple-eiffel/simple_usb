note
	description: "[
		USB_GAMEPAD - Gamepad/Joystick Device

		High-level interface for gamepad input with
		normalized axes and button states.

		Example:
			if gamepad.open then
				gamepad.poll
				print ("Left stick X: " + gamepad.left_stick_x.out + "%N")
				print ("Button A: " + gamepad.button (0).out + "%N")
				gamepad.close
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	USB_GAMEPAD

inherit
	USB_HID_DEVICE
		rename
			make_from_handle as make_hid_from_handle
		redefine
			read_report
		end

create
	make_from_hid

feature {NONE} -- Initialization

	make_from_hid (a_hid: USB_HID_DEVICE)
			-- Create gamepad from HID device.
		require
			hid_valid: a_hid /= Void
			is_gamepad: a_hid.is_gamepad
		do
			vendor_id := a_hid.vendor_id
			product_id := a_hid.product_id
			product_name := a_hid.product_name
			manufacturer := a_hid.manufacturer
			device_path := a_hid.device_path
			handle := a_hid.handle
			usage_page := a_hid.usage_page
			usage := a_hid.usage
			input_report_length := a_hid.input_report_length
			output_report_length := a_hid.output_report_length
			feature_report_length := a_hid.feature_report_length
			
			create buttons.make_filled (False, 0, Max_buttons - 1)
			create axes.make_filled (0, 0, Max_axes - 1)
		end

feature -- Configuration

	Max_buttons: INTEGER = 32
			-- Maximum number of buttons.

	Max_axes: INTEGER = 8
			-- Maximum number of axes.

feature -- Button State

	buttons: ARRAY [BOOLEAN]
			-- Button states (True = pressed).

	button (a_index: INTEGER): BOOLEAN
			-- Get button state.
		require
			valid_index: a_index >= 0 and a_index < Max_buttons
		do
			Result := buttons [a_index]
		end

	button_count: INTEGER
			-- Number of buttons detected.
		attribute
			Result := 12  -- Common default
		end

feature -- Axis State

	axes: ARRAY [INTEGER]
			-- Axis values (-32768 to 32767).

	axis (a_index: INTEGER): INTEGER
			-- Get axis value.
		require
			valid_index: a_index >= 0 and a_index < Max_axes
		do
			Result := axes [a_index]
		ensure
			valid_range: Result >= -32768 and Result <= 32767
		end

	axis_normalized (a_index: INTEGER): REAL_64
			-- Get axis value normalized to -1.0 to 1.0.
		require
			valid_index: a_index >= 0 and a_index < Max_axes
		do
			Result := axes [a_index] / 32767.0
			if Result < -1.0 then Result := -1.0 end
			if Result > 1.0 then Result := 1.0 end
		ensure
			valid_range: Result >= -1.0 and Result <= 1.0
		end

feature -- Common Axes

	left_stick_x: INTEGER
			-- Left stick X axis.
		do
			Result := axis (0)
		end

	left_stick_y: INTEGER
			-- Left stick Y axis.
		do
			Result := axis (1)
		end

	right_stick_x: INTEGER
			-- Right stick X axis.
		do
			Result := axis (2)
		end

	right_stick_y: INTEGER
			-- Right stick Y axis.
		do
			Result := axis (3)
		end

	left_trigger: INTEGER
			-- Left trigger (0 to 255 mapped to 0 to 32767).
		do
			Result := axis (4).max (0)
		end

	right_trigger: INTEGER
			-- Right trigger (0 to 255 mapped to 0 to 32767).
		do
			Result := axis (5).max (0)
		end

feature -- D-Pad

	dpad_up: BOOLEAN
			-- D-pad up pressed?
		do
			Result := button (12) or axis (7) < -16384
		end

	dpad_down: BOOLEAN
			-- D-pad down pressed?
		do
			Result := button (13) or axis (7) > 16384
		end

	dpad_left: BOOLEAN
			-- D-pad left pressed?
		do
			Result := button (14) or axis (6) < -16384
		end

	dpad_right: BOOLEAN
			-- D-pad right pressed?
		do
			Result := button (15) or axis (6) > 16384
		end

feature -- Polling

	poll: BOOLEAN
			-- Read and parse gamepad state. Returns True if successful.
		require
			is_open: is_open
		do
			if attached read_report as report then
				parse_report (report)
				Result := True
			end
		end

	read_report: detachable USB_HID_REPORT
			-- Read input report and update state.
		do
			Result := Precursor
			if Result /= Void then
				parse_report (Result)
			end
		end

feature {NONE} -- Parsing

	parse_report (a_report: USB_HID_REPORT)
			-- Parse HID report into gamepad state.
		require
			report_valid: a_report /= Void
		local
			i: INTEGER
			l_byte: INTEGER
		do
			-- Parse buttons (common layout: bytes 5-6 contain button bits)
			if a_report.count > 5 then
				from i := 0 until i >= 8 loop
					buttons [i] := a_report.bit_at (5, i)
					i := i + 1
				end
			end
			if a_report.count > 6 then
				from i := 0 until i >= 8 loop
					buttons [i + 8] := a_report.bit_at (6, i)
					i := i + 1
				end
			end

			-- Parse axes (common layout: bytes 1-4 contain stick data)
			if a_report.count > 1 then
				-- Left stick X
				l_byte := a_report.byte_at (1)
				axes [0] := ((l_byte - 128) * 256)
			end
			if a_report.count > 2 then
				-- Left stick Y
				l_byte := a_report.byte_at (2)
				axes [1] := ((l_byte - 128) * 256)
			end
			if a_report.count > 3 then
				-- Right stick X
				l_byte := a_report.byte_at (3)
				axes [2] := ((l_byte - 128) * 256)
			end
			if a_report.count > 4 then
				-- Right stick Y
				l_byte := a_report.byte_at (4)
				axes [3] := ((l_byte - 128) * 256)
			end
		end

invariant
	buttons_exist: buttons /= Void
	axes_exist: axes /= Void
	buttons_size: buttons.count = Max_buttons
	axes_size: axes.count = Max_axes

end