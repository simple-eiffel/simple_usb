note
	description: "[
		USB_HID_REPORT - HID Input/Output/Feature Report

		Represents a HID report containing device data.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	USB_HID_REPORT

create
	make,
	make_from_buffer,
	make_output

feature {NONE} -- Initialization

	make (a_size: INTEGER)
			-- Create empty report of given size.
		require
			positive_size: a_size > 0
		do
			create data.make (a_size)
			count := a_size
		ensure
			size_set: count = a_size
		end

	make_from_buffer (a_buffer: MANAGED_POINTER; a_length: INTEGER)
			-- Create from existing buffer.
		require
			buffer_valid: a_buffer /= Void
			length_valid: a_length > 0 and a_length <= a_buffer.count
		do
			create data.make (a_length)
			data.item.memory_copy (a_buffer.item, a_length)
			count := a_length
		ensure
			count_set: count = a_length
		end

	make_output (a_size: INTEGER; a_report_id: INTEGER)
			-- Create output report with report ID.
		require
			positive_size: a_size > 0
			valid_id: a_report_id >= 0 and a_report_id <= 255
		do
			create data.make (a_size)
			data.put_natural_8 (a_report_id.to_natural_8, 0)
			count := a_size
		ensure
			size_set: count = a_size
			id_set: report_id = a_report_id
		end

feature -- Access

	data: MANAGED_POINTER
			-- Raw report data.

	count: INTEGER
			-- Number of bytes in report.

	report_id: INTEGER
			-- Report ID (first byte).
		require
			not_empty: count > 0
		do
			Result := data.read_natural_8 (0).to_integer_32
		end

feature -- Byte Access

	byte_at (a_index: INTEGER): INTEGER
			-- Get byte at index (0-based).
		require
			valid_index: a_index >= 0 and a_index < count
		do
			Result := data.read_natural_8 (a_index).to_integer_32
		ensure
			valid_byte: Result >= 0 and Result <= 255
		end

	set_byte (a_index: INTEGER; a_value: INTEGER)
			-- Set byte at index (0-based).
		require
			valid_index: a_index >= 0 and a_index < count
			valid_value: a_value >= 0 and a_value <= 255
		do
			data.put_natural_8 (a_value.to_natural_8, a_index)
		ensure
			byte_set: byte_at (a_index) = a_value
		end

feature -- Word Access

	word_at (a_index: INTEGER): INTEGER
			-- Get 16-bit word at index (little-endian, 0-based).
		require
			valid_index: a_index >= 0 and a_index + 1 < count
		do
			Result := data.read_natural_16_le (a_index).to_integer_32
		end

	signed_word_at (a_index: INTEGER): INTEGER
			-- Get signed 16-bit word at index (little-endian).
		require
			valid_index: a_index >= 0 and a_index + 1 < count
		do
			Result := data.read_integer_16_le (a_index).to_integer_32
		end

feature -- Bit Access

	bit_at (a_byte_index, a_bit_index: INTEGER): BOOLEAN
			-- Get bit at position.
		require
			valid_byte: a_byte_index >= 0 and a_byte_index < count
			valid_bit: a_bit_index >= 0 and a_bit_index < 8
		local
			l_byte: INTEGER
		do
			l_byte := byte_at (a_byte_index)
			Result := (l_byte & (1 |<< a_bit_index)) /= 0
		end

	set_bit (a_byte_index, a_bit_index: INTEGER; a_value: BOOLEAN)
			-- Set bit at position.
		require
			valid_byte: a_byte_index >= 0 and a_byte_index < count
			valid_bit: a_bit_index >= 0 and a_bit_index < 8
		local
			l_byte: INTEGER
		do
			l_byte := byte_at (a_byte_index)
			if a_value then
				l_byte := l_byte | (1 |<< a_bit_index)
			else
				l_byte := l_byte & (0xFF - (1 |<< a_bit_index))
			end
			set_byte (a_byte_index, l_byte)
		ensure
			bit_set: bit_at (a_byte_index, a_bit_index) = a_value
		end

feature -- Conversion

	to_array: ARRAY [NATURAL_8]
			-- Convert to array.
		local
			i: INTEGER
		do
			create Result.make_filled (0, 0, count - 1)
			from i := 0 until i >= count loop
				Result [i] := data.read_natural_8 (i)
				i := i + 1
			end
		ensure
			same_count: Result.count = count
		end

	to_hex_string: STRING_32
			-- Convert to hex string.
		local
			i: INTEGER
		do
			create Result.make (count * 3)
			from i := 0 until i >= count loop
				if i > 0 then
					Result.append_character (' ')
				end
				Result.append_string_general (byte_at (i).to_hex_string.as_lower)
				i := i + 1
			end
		end

invariant
	data_not_void: data /= Void
	count_positive: count > 0
	count_matches_data: count <= data.count

end