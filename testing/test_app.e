note
	description: "Test application for SIMPLE_USB"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			print ("Running SIMPLE_USB tests...%N%N")
			passed := 0
			failed := 0

			run_lib_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_lib_tests
		do
			create lib_tests
			-- Basic tests
			run_test (agent lib_tests.test_initialization, "test_initialization")
			run_test (agent lib_tests.test_device_enumeration, "test_device_enumeration")
			run_test (agent lib_tests.test_hid_enumeration, "test_hid_enumeration")
			run_test (agent lib_tests.test_gamepad_enumeration, "test_gamepad_enumeration")
			run_test (agent lib_tests.test_device_ids, "test_device_ids")
			run_test (agent lib_tests.test_id_string, "test_id_string")
			run_test (agent lib_tests.test_report_creation, "test_report_creation")
			run_test (agent lib_tests.test_report_byte_access, "test_report_byte_access")
			run_test (agent lib_tests.test_report_bit_access, "test_report_bit_access")
			run_test (agent lib_tests.test_report_word_access, "test_report_word_access")
			run_test (agent lib_tests.test_report_hex_string, "test_report_hex_string")
			run_test (agent lib_tests.test_find_device, "test_find_device")
			run_test (agent lib_tests.test_find_arduino, "test_find_arduino")
			run_test (agent lib_tests.test_refresh, "test_refresh")
			-- Edge Case Tests: Report Boundaries
			run_test (agent lib_tests.test_report_single_byte, "test_report_single_byte")
			run_test (agent lib_tests.test_report_large, "test_report_large")
			run_test (agent lib_tests.test_report_all_bits_set, "test_report_all_bits_set")
			run_test (agent lib_tests.test_report_all_bits_clear, "test_report_all_bits_clear")
			run_test (agent lib_tests.test_report_word_boundary, "test_report_word_boundary")
			run_test (agent lib_tests.test_report_zero_word, "test_report_zero_word")
			-- Edge Case Tests: Device Creation
			run_test (agent lib_tests.test_device_empty_strings, "test_device_empty_strings")
			run_test (agent lib_tests.test_device_max_ids, "test_device_max_ids")
			run_test (agent lib_tests.test_device_zero_ids, "test_device_zero_ids")
			run_test (agent lib_tests.test_device_unicode_name, "test_device_unicode_name")
			-- Edge Case Tests: Multiple Operations
			run_test (agent lib_tests.test_multiple_usb_instances, "test_multiple_usb_instances")
			run_test (agent lib_tests.test_rapid_refresh, "test_rapid_refresh")
			run_test (agent lib_tests.test_report_rapid_modifications, "test_report_rapid_modifications")
			-- Edge Case Tests: Find Operations
			run_test (agent lib_tests.test_find_with_max_vid_pid, "test_find_with_max_vid_pid")
			run_test (agent lib_tests.test_find_hid_nonexistent, "test_find_hid_nonexistent")
		end

feature {NONE} -- Test Infrastructure

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				a_test.call (Void)
				passed := passed + 1
				print ("[PASS] " + a_name + "%N")
			end
		rescue
			l_failed := True
			failed := failed + 1
			print ("[FAIL] " + a_name + "%N")
			retry
		end

	passed: INTEGER
	failed: INTEGER

feature {NONE} -- Test Objects

	lib_tests: LIB_TESTS

end