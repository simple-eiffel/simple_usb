note
	description: "[
		USB_DEVICE - Base USB device information

		Contains basic device identification and metadata.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	USB_DEVICE

create
	make,
	make_from_handle

feature {NONE} -- Initialization

	make (a_vendor_id, a_product_id: INTEGER; a_name, a_manufacturer, a_path: READABLE_STRING_GENERAL)
			-- Create device with explicit values.
		require
			valid_vendor: a_vendor_id >= 0 and a_vendor_id <= 0xFFFF
			valid_product: a_product_id >= 0 and a_product_id <= 0xFFFF
		do
			vendor_id := a_vendor_id
			product_id := a_product_id
			product_name := a_name.to_string_32
			manufacturer := a_manufacturer.to_string_32
			device_path := a_path.to_string_32
		end

	make_from_handle (a_handle: POINTER)
			-- Create from C device info handle.
		require
			valid_handle: a_handle /= default_pointer
		local
			l_ptr: POINTER
		do
			handle := a_handle
			vendor_id := c_get_vendor_id (a_handle)
			product_id := c_get_product_id (a_handle)
			
			l_ptr := c_get_product_name (a_handle)
			if l_ptr /= default_pointer then
				create product_name.make_from_c (l_ptr)
			else
				create product_name.make_empty
			end
			
			l_ptr := c_get_manufacturer (a_handle)
			if l_ptr /= default_pointer then
				create manufacturer.make_from_c (l_ptr)
			else
				create manufacturer.make_empty
			end
			
			l_ptr := c_get_device_path (a_handle)
			if l_ptr /= default_pointer then
				create device_path.make_from_c (l_ptr)
			else
				create device_path.make_empty
			end
		end

feature -- Identification

	vendor_id: INTEGER
			-- USB Vendor ID (VID).

	product_id: INTEGER
			-- USB Product ID (PID).

	vendor_id_hex: STRING_32
			-- Vendor ID as 4-digit hex string.
		do
			Result := to_hex_4 (vendor_id)
		ensure
			length: Result.count = 4
		end

	product_id_hex: STRING_32
			-- Product ID as 4-digit hex string.
		do
			Result := to_hex_4 (product_id)
		ensure
			length: Result.count = 4
		end

	id_string: STRING_32
			-- Combined VID:PID string.
		do
			create Result.make (9)
			Result.append (vendor_id_hex)
			Result.append_character (':')
			Result.append (product_id_hex)
		ensure
			format: Result.count = 9
		end

feature -- Metadata

	product_name: STRING_32
			-- Product name from device.

	manufacturer: STRING_32
			-- Manufacturer name from device.

	device_path: STRING_32
			-- System device path.

	display_name: STRING_32
			-- Human-readable display name.
		do
			if product_name.is_empty then
				Result := "USB Device [" + id_string + "]"
			else
				Result := product_name
			end
		end

feature -- Status

	is_connected: BOOLEAN
			-- Is device currently connected?
		do
			Result := not device_path.is_empty
		end

feature {USB_DEVICE} -- Implementation

	handle: POINTER
			-- C device info handle.

feature {NONE} -- Helpers

	to_hex_4 (a_value: INTEGER): STRING_32
			-- Convert to 4-digit hex string.
		local
			l_hex: STRING
		do
			l_hex := a_value.to_hex_string
			create Result.make (4)
			from until Result.count + l_hex.count >= 4 loop
				Result.append_character ('0')
			end
			Result.append_string_general (l_hex.as_lower)
			if Result.count > 4 then
				Result := Result.substring (Result.count - 3, Result.count)
			end
		end

feature {NONE} -- C Externals

	c_get_vendor_id (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_device_vendor_id($a_handle);"
		end

	c_get_product_id (a_handle: POINTER): INTEGER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_device_product_id($a_handle);"
		end

	c_get_product_name (a_handle: POINTER): POINTER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_device_product_name($a_handle);"
		end

	c_get_manufacturer (a_handle: POINTER): POINTER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_device_manufacturer($a_handle);"
		end

	c_get_device_path (a_handle: POINTER): POINTER
		external
			"C inline use %"usb_bridge.h%""
		alias
			"return usb_device_path($a_handle);"
		end

invariant
	valid_vendor: vendor_id >= 0 and vendor_id <= 0xFFFF
	valid_product: product_id >= 0 and product_id <= 0xFFFF

end