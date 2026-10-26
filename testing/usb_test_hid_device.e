note
	description: "A HID device for tests, with no hardware: it says it is a gamepad."

class
	USB_TEST_HID_DEVICE

inherit
	USB_HID_DEVICE

create
	make_gamepad

feature {NONE} -- Initialization

	make_gamepad
		do
			make (0x045E, 0x028E, "Test gamepad", "Test", "test://gamepad")
			usage_page := 0x01
			usage := 0x05
		ensure
			gamepad: is_gamepad
		end

end
