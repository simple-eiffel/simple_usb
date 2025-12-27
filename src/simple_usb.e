note
	description: "[
		SIMPLE_USB - USB Device Access Library for Eiffel

		Provides USB device enumeration, HID device access, and gamepad support
		using Windows SetupAPI and HID API.

		Example:
			usb: SIMPLE_USB
			create usb.make

			-- List all USB devices
			across usb.devices as d loop
				print (d.product_name + " [" + d.vendor_id_hex + ":" + d.product_id_hex + "]%N")
			end

			-- Find specific device
			if attached usb.find_device (0x2341, 0x0043) as arduino then
				print ("Found Arduino: " + arduino.product_name + "%N")
			end

			-- Work with HID devices
			across usb.hid_devices as hid loop
				if hid.open then
					if attached hid.read_report as report then
						print ("Report: " + report.count.out + " bytes%N")
					end
					hid.close
				end
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_USB

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize USB subsystem.
		do
			create internal_devices.make (10)
			create internal_hid_devices.make (10)
			create internal_gamepads.make (4)
			refresh
		ensure
			initialized: is_initialized
		end

feature -- Status

	is_initialized: BOOLEAN
			-- Is USB subsystem initialized?
		do
			Result := True  -- Always true on Windows
		end

	device_count: INTEGER
			-- Number of USB devices found.
		do
			Result := internal_devices.count
		end

	hid_count: INTEGER
			-- Number of HID devices found.
		do
			Result := internal_hid_devices.count
		end

	gamepad_count: INTEGER
			-- Number of gamepads found.
		do
			Result := internal_gamepads.count
		end

	last_error: detachable STRING_32
			-- Last error message.

feature -- Device Access

	devices: ARRAYED_LIST [USB_DEVICE]
			-- All USB devices.
		do
			Result := internal_devices
		end

	hid_devices: ARRAYED_LIST [USB_HID_DEVICE]
			-- All HID devices.
		do
			Result := internal_hid_devices
		end

	gamepads: ARRAYED_LIST [USB_GAMEPAD]
			-- All gamepads/game controllers.
		do
			Result := internal_gamepads
		end

feature -- Device Discovery

	find_device (a_vendor_id, a_product_id: INTEGER): detachable USB_DEVICE
			-- Find device by vendor and product ID.
		require
			valid_ids: a_vendor_id >= 0 and a_product_id >= 0
		do
			across internal_devices as d loop
				if d.vendor_id = a_vendor_id and d.product_id = a_product_id then
					Result := d
				end
			end
		end

	find_hid_device (a_vendor_id, a_product_id: INTEGER): detachable USB_HID_DEVICE
			-- Find HID device by vendor and product ID.
		require
			valid_ids: a_vendor_id >= 0 and a_product_id >= 0
		do
			across internal_hid_devices as d loop
				if d.vendor_id = a_vendor_id and d.product_id = a_product_id then
					Result := d
				end
			end
		end

	find_arduino: detachable USB_HID_DEVICE
			-- Find Arduino device (common VID/PIDs).
		do
			-- Arduino Uno/Nano/Mega use VID 0x2341
			Result := find_hid_device (0x2341, 0x0043)  -- Uno
			if Result = Void then
				Result := find_hid_device (0x2341, 0x0042)  -- Mega
			end
			if Result = Void then
				Result := find_hid_device (0x2341, 0x8036)  -- Leonardo
			end
		end

	refresh
			-- Refresh device lists.
		do
			internal_devices.wipe_out
			internal_hid_devices.wipe_out
			internal_gamepads.wipe_out
			enumerate_hid_devices
		end

feature {NONE} -- Enumeration

	enumerate_hid_devices
			-- Enumerate all HID devices.
		local
			l_device_count: INTEGER
			l_info: POINTER
			i: INTEGER
			l_device: USB_HID_DEVICE
			l_gamepad: USB_GAMEPAD
		do
			l_device_count := c_hid_enumerate
			from i := 0 until i >= l_device_count loop
				l_info := c_hid_get_device (i)
				if l_info /= default_pointer then
					create l_device.make_from_handle (l_info)
					internal_devices.extend (l_device)
					internal_hid_devices.extend (l_device)
					
					-- Check if it's a gamepad
					if l_device.is_gamepad then
						create l_gamepad.make_from_hid (l_device)
						internal_gamepads.extend (l_gamepad)
					end
				end
				i := i + 1
			end
			c_hid_free_enumeration
		end

feature {NONE} -- Implementation

	internal_devices: ARRAYED_LIST [USB_DEVICE]
	internal_hid_devices: ARRAYED_LIST [USB_HID_DEVICE]
	internal_gamepads: ARRAYED_LIST [USB_GAMEPAD]

feature {NONE} -- C Externals

	c_hid_enumerate: INTEGER
			-- Enumerate HID devices, return count.
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_enumerate();"
		end

	c_hid_get_device (a_index: INTEGER): POINTER
			-- Get device info at index.
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_hid_get_device($a_index);"
		end

	c_hid_free_enumeration
			-- Free enumeration resources.
		external
			"C inline use %"usb_bridge.h%""
		alias
			"usb_hid_free_enumeration();"
		end

invariant
	devices_not_void: internal_devices /= Void
	hid_devices_not_void: internal_hid_devices /= Void
	gamepads_not_void: internal_gamepads /= Void

end