#!/usr/bin/env python3

import argparse
import json
import os
import re
import subprocess
import sys

BANNER = r"""reconstruct_source.py
v0.1
Ben Lincoln, Bishop Fox, 2022-09-12
https://github.com/BishopFox/asminject
"""

METADATA_FILENAME = "___exported_object_metadata___.json"
BASE_PATH_PLACEHOLDER = "___base_path___"
NO_ORIGINAL_PATH_PLACEHOLDER = "___no_original_path___"

class process_params:
    def __init__(self):
        self.input_dir = None
        self.output_dir = None
        self.assume_base_path = None
        self.ignored_modules = []
        self.processed_modules = []
        self.pycdc_path = ""
        self.only_embedded_source = False
        self.only_reconstructed_source = False
        self.include_builtins = False
        self.include_delimiter_comments = False

def get_data_from_text_file(file_path):
    result = None
    # Try to read the file in all possible encodings that Python 2 and 3 might have generated
    for enc in [ "utf-8", "ascii", "latin-1" ]:
        if not result:
            try:
                file_text = ""
                with open(file_path, "r", encoding=enc) as text_file:
                    file_text_array = text_file.readlines()
                    for ft in file_text_array:
                        file_text += ft
                result = file_text
            except Exception as e:
                result = None
    if not result:
        print(f"Could not read the text file at path {file_path} in any known encoding")
        sys.exit(1)
    return result

def get_data_from_json_file(file_path):
    result = None
    try:
        file_text = get_data_from_text_file(file_path)
        result = json.loads(file_text)
    except Exception as e:
        print(f"Error processing JSON file at path {file_path}: {e}")
    return result

def get_output_relative_path(params, input_path):
    result = input_path
    handled = False
    #print(f"Debug: generating output path for '{input_path}'")
    if params.assume_base_path:
        len_abp = len(params.assume_base_path)
        if len(input_path) >= len_abp:
            if input_path[0:len_abp] == params.assume_base_path:
                revised_path = input_path[len_abp:]
                if len(revised_path) > 0:
                    if revised_path[0:1] == "/":
                        revised_path = revised_path[1:]
                result = os.path.join(params.output_dir, BASE_PATH_PLACEHOLDER, revised_path)
                handled = True
    if not handled:
        if len(result) > 0:
            if result[0:1] == "/":
                result = result[1:]
            if "/" not in result:
                result = os.path.join(NO_ORIGINAL_PATH_PLACEHOLDER, result)
        result = os.path.join(params.output_dir, result)
    
    return result

def append_content_to_reconstructed_source(params, reconstructed_content_type, input_path, output_path, content):
    output_dir = os.path.dirname(output_path)
    try:
        #print(f"Debug: creating '{output_dir}'")
        os.makedirs(output_dir, exist_ok=True)
    except Exception as e:
        print(f"Error creating output directory {output_dir}: {e}")
        return
    try:
        #print(f"Debug: writing {reconstructed_content_type} to '{output_path}'")
        with open(output_path, "a") as output_file:
            if params.include_delimiter_comments:
                output_file.write("# BEGIN: ")
                output_file.write(reconstructed_content_type)
                output_file.write(" from '")
                output_file.write(input_path)
                output_file.write("'\n")
            output_file.write(content)
            if params.include_delimiter_comments:
                output_file.write("# END: ")
                output_file.write(reconstructed_content_type)
                output_file.write(" from '")
                output_file.write(input_path)
                output_file.write("'")
            output_file.write("\n\n")
    except IOException as e:
        print(f"Error writing content to {output_path}: {e}")

def get_import_reconstruction(params, object_metadata_json):
    result = ""
    if "imported_modules" in object_metadata_json.keys():
        ma = object_metadata_json["imported_modules"]
        for att in ma:
            if att not in [ "__builtins__" ]:
                result += "import " 
                result += att
                result += "\n"
    return result

def escape_string_value_inner(input_string, chr_num):
    return input_string.replace(chr(chr_num), '\\x' + '{0:0{1}x}'.format(chr_num, 2))

def escape_string_value(string_value):
    result = string_value
    result = escape_json_value_inner(result, 92)
    for i in range(0, 31):
        result = escape_json_value_inner(result, i)
    # double quote
    result = escape_json_value_inner(result, 34)
    # high ASCII characters - will cause problems with reconstruction
    for i in range(127, 255):
        result = escape_json_value_inner(result, i)
    return result

def get_member_attribute_reconstruction(params, object_metadata_json):
    result = ""
    if "member_attributes" in object_metadata_json.keys():
        ma = object_metadata_json["member_attributes"]
        for att in ma.keys():
            result += att
            result += " = " 
            string_rep = str(ma[att])
            if isinstance(ma[att], str):
                string_rep = '"' + string_rep + '"'
            result += string_rep
            result += "\n"
    return result

def get_decompiled_code_object(params, python_version, marshalled_file_path):
    result = ""
    #result_temp = None
    if params.pycdc_path:
        try:
            argv = [params.pycdc_path, "-c", "-v", python_version, marshalled_file_path]
            run_result = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            result = run_result.stdout.decode()
        except Exception as e:
            result += f"Error decompiling '{marshalled_file_path}': {e}"
            print(f"Error decompiling '{marshalled_file_path}': {e}")
        
    else:
        result = "# No path to Decompyle++ / pycdc was specified"
    # work around weird debugging output in current version of Decompyle++
    #if result_temp:
    #    for l in result_temp.splitlines():
    #        ltrim = l.rstrip()
            
    
    return result

def get_first_digit_match(input_string, regex_string):
    result = None
    re_result = re.search(regex_string, input_string)
    if re_result:
        m = re_result.group()
        m = re.sub('[^0-9]', '', m)
        return m

def get_code_version(obj):
    result = ""
    # handle the bad old data from Python 2.x
    if isinstance(obj, str):
        if "version_info" in obj:
            verMaj = get_first_digit_match(obj, 'major=\d+,')
            verMin = get_first_digit_match(obj, 'minor=\d+,')
            try:
                intVerMaj = int(verMaj)
                intVerMin = int(verMin)
            except Exception as e:
                print(f"Error: Could not parse Python version information from '{obj}' parsed into {verMaj} and {verMin}: {e}")
            result = f"{verMaj}.{verMin}"
    else:
        if len(obj) > 1:
            result = f"{obj[0]}.{obj[1]}"
    return result

def process_code_object(params, module_output_file_path, code_object_json_path):
    is_code_object = True
    code_object_data = {}
    if os.path.isfile(code_object_json_path):
        code_object_data = get_data_from_json_file(code_object_json_path)
    else:
        is_code_object = False
    if not code_object_data:
        is_code_object = False
    if is_code_object:
        if "object_type" in code_object_data.keys():
            if code_object_data["object_type"] != "code_object":
                is_code_object = False
    if not is_code_object:
        #print(f"Ignoring '{code_object_json_path}' because it is not a code object")
        return
    
    print(f"Processing code_object at '{code_object_json_path}'")
    
    code_object_python_version = None
    code_object_source_code_file = None
    code_object_marshalled_file = None
       
    if "python_version" in code_object_data.keys():
        pv = code_object_data["python_version"]
        code_object_python_version = get_code_version(pv)
    
    if "source_code_file" in code_object_data.keys():
        code_object_source_code_file = code_object_data["source_code_file"]
    
    if "marshalled_file" in code_object_data.keys():
        code_object_marshalled_file = code_object_data["marshalled_file"]
    
    got_code_object_source = False
    reconstructed_code_object_header = None

    if not params.only_reconstructed_source:
        if code_object_source_code_file:
            append_content_to_reconstructed_source(params, "original code object source code", code_object_source_code_file, module_output_file_path, get_data_from_text_file(code_object_source_code_file))
            got_code_object_source = True
    
    # Only attempt to decompile code objects if no embedded source was retrieved
    if not got_code_object_source:
        reconstructed_code_object_header = f""
        if code_object_marshalled_file:
            decompiled = get_decompiled_code_object(params, code_object_python_version, code_object_marshalled_file)
            if decompiled:
                reconstructed_code_object_header += decompiled
        append_content_to_reconstructed_source(params, "reconstructed code object source code", code_object_marshalled_file, module_output_file_path, reconstructed_code_object_header)

def process_function(params, module_output_file_path, function_json_path, indent = "    "):
    is_function = True
    function_data = {}
    if os.path.isfile(function_json_path):
        function_data = get_data_from_json_file(function_json_path)
    else:
        is_function = False
    if not function_data:
        is_function = False
    if is_function:
        if "object_type" in function_data.keys():
            if function_data["object_type"] not in [ "function", "method" ]:
                is_function = False
    if not is_function:
        #print(f"Ignoring '{function_json_path}' because it is not a function")
        return
    
    function_type = function_data["object_type"]
    
    print(f"Processing {function_type} at '{function_json_path}'")
    
    function_name = None
    function_signature = None
    function_python_version = None
    function_source_code_file = None
    function_marshalled_file = None
    
    if "object_name" in function_data.keys():
        function_name = function_data["object_name"]
    
    if "signature" in function_data.keys():
        function_signature = function_data["signature"]
    
    if "python_version" in function_data.keys():
        pv = function_data["python_version"]
        function_python_version = get_code_version(pv)
    
    if "source_code_file" in function_data.keys():
        function_source_code_file = function_data["source_code_file"]
    
    if "marshalled_file" in function_data.keys():
        function_marshalled_file = function_data["marshalled_file"]
    
    got_function_source = False
    reconstructed_function_header = None

    if not params.only_reconstructed_source:
        if function_source_code_file:
            append_content_to_reconstructed_source(params, "original {function_type} source code", function_source_code_file, module_output_file_path, get_data_from_text_file(function_source_code_file))
            got_function_source = True
    
    # Only attempt to decompile code objects if no embedded source was retrieved
    if not got_function_source:
        reconstructed_function_header = f"{indent}def {function_name}{function_signature}:\n"
        if function_marshalled_file:
            decompiled = get_decompiled_code_object(params, function_python_version, function_marshalled_file)
            if decompiled:
                for l in decompiled.splitlines():
                    # add indent to each line
                    reconstructed_function_header += indent
                    reconstructed_function_header += l
                    reconstructed_function_header += "\n"
        append_content_to_reconstructed_source(params, "reconstructed {function_type} source code", function_marshalled_file, module_output_file_path, reconstructed_function_header)


def process_class(params, module_output_file_path, class_directory_path):    
    class_metadata_file_path = os.path.join(class_directory_path, METADATA_FILENAME)
    submodules_to_process = []
    classes_to_process = []
    functions_to_process = []
    is_class = True
    class_name = None
    class_data = {}
    if os.path.isfile(class_metadata_file_path):
        class_data = get_data_from_json_file(class_metadata_file_path)
    else:
        is_class = False
    if not class_data:
        is_class = False
    if is_class:
        if "object_type" in class_data.keys():
            if class_data["object_type"] != "class":
                is_class = False
    if not is_class:
        #print(f"Ignoring '{class_directory_path}' because it is not a class")
        return
        
    print(f"Processing class at '{class_directory_path}'")
    
    if "name" in class_data.keys():
        class_name = class_data["name"]
    
    #if "member_metadata" in class_data.keys():
    #    mm = class_data["member_metadata"]        
    #    (submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, None, mm, submodules_to_process, classes_to_process, functions_to_process)
    (submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, None, class_data, submodules_to_process, classes_to_process, functions_to_process)
    
    got_class_source = False
    reconstructed_class_header = None

    if not params.only_reconstructed_source:
        if "source_code_file" in class_data.keys():
            class_source_code_file = class_data["source_code_file"]
            append_content_to_reconstructed_source(params, "original class source code", class_source_code_file, module_output_file_path, get_data_from_text_file(class_source_code_file))
            got_class_source = True
    
    # Only attempt to decompile code objects if no embedded source was retrieved
    if not got_class_source:
        reconstructed_class_header = f"class {class_name}:\n"
        #for co in code_objects:
        #    process_code_object(params, module_output_file_path, os.path.join(directory_path, f"{co}.json"))
        reconstructed_class_header += get_import_reconstruction(params, class_data)
        reconstructed_class_header += get_member_attribute_reconstruction(params, class_data)
        append_content_to_reconstructed_source(params, "reconstructed class source code", class_metadata_file_path, module_output_file_path, reconstructed_class_header)
        
        for func in functions_to_process:
            process_function(params, module_output_file_path, os.path.join(class_directory_path, f"{func}.json"), indent = "        ")

def get_subobject_path(base_value, path_prefix):
    if not path_prefix:
        return base_value
    return os.path.join(path_prefix, base_value)
    
def get_child_object_list(params, path_prefix, key_value_collection, submodule_list, class_list, function_list):
    #print(f"Debug: k/v collection: {key_value_collection}")
    # if hasattr(key_value_collection, "keys"):
        # for mdk in key_value_collection.keys():
            # mdv = key_value_collection[mdk]
            # dir_name = mdk
            # if path_prefix:
                # dir_name = os.path.join(path_prefix, dir_name)
            # if mdv and isinstance(mdv, str):
                # if params.include_builtins or "built-in" not in mdv.lower():
                    # if 'function ' in mdv or 'method ' in mdv:
                        # if mdk not in [ "__doc__" ]:
                            # function_list.append(dir_name)
                    # if 'class ' in mdv:
                        # if mdk not in [ "__doc__" ]:
                            # class_list.append(dir_name)
                    # if 'module ' in mdv:
                        # include_module = True
                        # if mdk in params.ignored_modules:
                            # include_module = False
                        # if mdk in params.processed_modules:
                            # include_module = False
                        # submodule_list.append(dir_name)
    if hasattr(key_value_collection, "keys"):
        if "imported_modules" in key_value_collection.keys():
            for im in key_value_collection["imported_modules"]:
                include_module = True
                if im in params.ignored_modules:
                    include_module = False
                if im in params.processed_modules:
                    include_module = False
                if include_module:
                    submodule_list.append(get_subobject_path(im, path_prefix))
        if "classes" in key_value_collection.keys():
            for c in key_value_collection["classes"]:
                if c not in [ "__doc__" ]:
                    class_list.append(get_subobject_path(c, path_prefix))
        if "functions" in key_value_collection.keys():
            for f in key_value_collection["functions"]:
                if f not in [ "__doc__" ]:
                    function_list.append(get_subobject_path(f, path_prefix))     
        if "methods" in key_value_collection.keys():
            for m in key_value_collection["methods"]:
                if m not in [ "__doc__" ]:
                    function_list.append(get_subobject_path(m, path_prefix))
    return (submodule_list, class_list, function_list)

def process_module(params, directory_path):
    try:
        is_module = True
        module_data = {}
        module_metadata_file_path = os.path.join(directory_path, METADATA_FILENAME)
        if not os.path.isfile(module_metadata_file_path):
            is_module = False
        if is_module:
            module_data = get_data_from_json_file(module_metadata_file_path)
        if not module_data:
            is_module = False
        module_name = None
        module_original_file_path = None
        module_output_file_path = None
        module_package = None
        module_source_code_file = None
        submodules_to_process = []
        classes_to_process = []
        functions_to_process = []
        code_objects = []
        
        if is_module:
            if "object_type" in module_data.keys():
                if module_data["object_type"] != "module":
                    is_module = False
        
        if not is_module:
            #print(f"Ignoring '{directory_path}' because it is not a module")
            return
        print(f"Processing module at '{directory_path}'")

        if "code_objects" in module_data.keys():
            code_objects = module_data["code_objects"]

        if "member_metadata" in module_data.keys():
            mm = module_data["member_metadata"]
            if hasattr(mm, "keys"):
                if "__file__" in mm.keys():
                    if mm["__file__"] and mm["__file__"] != "None":
                        module_original_file_path = mm["__file__"]
                        mofp = get_output_relative_path(params, module_original_file_path)
                        mofp_split = os.path.splitext(mofp)                    
                        module_output_file_path = f"{mofp_split[0]}.py"

                if "__name__" in mm.keys():
                    if mm["__name__"] and mm["__name__"] != "None":
                        module_name = mm["__name__"]
                        params.processed_modules.append(module_name)

                if "__package__" in mm.keys():
                    module_package = mm["__package__"]
            
                #(submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, None, mm, submodules_to_process, classes_to_process, functions_to_process)
                

                #if "__builtins__" in mm.keys():
                    #(submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, "__builtins__", mm["__builtins__"], submodules_to_process, classes_to_process, functions_to_process)
                    #(submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, "__builtins__", module_data["__builtins__"], submodules_to_process, classes_to_process, functions_to_process)
            
            
        (submodules_to_process, classes_to_process, functions_to_process) = get_child_object_list(params, None, module_data, submodules_to_process, classes_to_process, functions_to_process)
        
        
        if not module_output_file_path:
            without_input_dir = directory_path
            l_id = len(params.input_dir)
            if len(without_input_dir) >= l_id:
                if without_input_dir[0:l_id] == params.input_dir:
                    without_input_dir = without_input_dir[l_id:]
            mofp = f"{without_input_dir}.py"
            #if not module_original_file_path:
            #    mofp = os.path.join(NO_ORIGINAL_PATH_PLACEHOLDER, mofp)
            module_output_file_path = get_output_relative_path(params, mofp)
        
        module_metadata = f"# Module name: {module_name}\n"
        module_metadata += f"# Package: {module_package}\n"
        module_metadata += f"# Original file path: {module_original_file_path}\n"
        append_content_to_reconstructed_source(params, "module metadata", module_metadata_file_path, module_output_file_path, module_metadata)
        
        got_module_source = False
        
        if not params.only_reconstructed_source:
            if "source_code_file" in module_data.keys() and module_data["source_code_file"] and module_data["source_code_file"] != "None":
                module_source_code_file = module_data["source_code_file"]
                append_content_to_reconstructed_source(params, "original module source code", module_source_code_file, module_output_file_path, get_data_from_text_file(module_source_code_file))
                got_module_source = True
        
        # Only attempt to decompile code objects if no embedded source was retrieved
        if not got_module_source:        
            for co in code_objects:
                process_code_object(params, module_output_file_path, os.path.join(directory_path, f"{co}.json"))
                
            reconstructed_module_header = ""
            reconstructed_module_header += get_import_reconstruction(params, module_data)
            reconstructed_module_header += get_member_attribute_reconstruction(params, module_data)
            append_content_to_reconstructed_source(params, "reconstructed module source code", module_metadata_file_path, module_output_file_path, reconstructed_module_header)
        
            for c in classes_to_process:
                process_class(params, module_output_file_path, os.path.join(directory_path, c))
            for func in functions_to_process:
                process_function(params, module_output_file_path, os.path.join(directory_path, f"{func}.json"))            

        # process any sub-modules
        for submodule in submodules_to_process:
            process_module(params, os.path.join(directory_path, submodule))
        
    except IOException as e:
        print(f"Error processing module at path {directory_path}: {e}")

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
    params = process_params()

    print(BANNER)

    parser = argparse.ArgumentParser(
        description="Reconstruct source code from the output of recursive_marshal.py")

    parser.add_argument("--input-dir", type=str, required=True, 
        help="Base path to recurse through for input files (e.g. /tmp/marshalled)")
    
    parser.add_argument("--output-dir", type=str, required=True, 
        help="Base path to write output (e.g. /home/user/recovered_source)")

    parser.add_argument("--assume-base-path", type=str, 
        help=f"Prefix to remove from output paths when generating the reconstructed source tree (e.g. /home/user/my_script), will be replaced with {BASE_PATH_PLACEHOLDER}")

    parser.add_argument("--ignore-module", action='append', nargs='*', required=False,
        help="Ignore (do not attempt to reconstruct) module(s) with the following name. May be specified multiple times, e.g. --ignore-module os --ignore-module sys --ignore-module json. IMPORTANT: applies to modules with the specified name at any point in the tree. For example, --ignore-module sys will ignore the top-level Python 'sys' library, but also a nonstandard 'custom_module.sys'.")
    
    parser.add_argument("--pycdc-path", type=str, 
        help="Path to the Decompyle++ 'pycdc' binary, e.g. /home/user/pycdc/pycdc. Required for decompiling code objects.")

    parser.add_argument("--only-embedded-source", type=str2bool, nargs='?',
        const=True, default=False,
        help="Only include embedded source code in the output. In other words, do not attempt to decompile any code objects, even if there is no corresponding embedded source code.")

    parser.add_argument("--only-reconstructed-source", type=str2bool, nargs='?',
        const=True, default=False,
        help="Only include reconstructed/decompiled source code in the output. In other words, do not include embedded source code, even though it would most likely provide a more accurate reconstruction of the original script files.")

    parser.add_argument("--include-builtins", type=str2bool, nargs='?',
        const=True, default=False,
        help="Include 'built-in' objects in the script output.")
        
    parser.add_argument("--include-delimiter-comments", type=str2bool, nargs='?',
        const=True, default=False,
        help="Includes comments in reconstructed source code to make it more clear where the data came from.")

    args = parser.parse_args()
    
    if args.input_dir:
        params.input_dir = os.path.abspath(args.input_dir)
    
    if args.output_dir:
        params.output_dir = os.path.abspath(args.output_dir)
    
    if args.assume_base_path:
        params.assume_base_path = args.assume_base_path

    if args.pycdc_path:
        params.pycdc_path = args.pycdc_path
    
    if args.only_embedded_source:
        params.only_embedded_source = args.only_embedded_source
        
    if args.only_reconstructed_source:
        params.only_reconstructed_source = args.only_reconstructed_source
        
    if params.only_embedded_source and params.only_reconstructed_source:
        print("Error: only one of --only-embedded-source or --only-reconstructed-source may be specified. If neither is specified, the script will use embedded source where possible, and fall back to reconstructed source where no embedded source is available.")
        sys.exit(1)

    if args.include_builtins:
        params.include_builtins = args.include_builtins

    if args.include_delimiter_comments:
        params.include_delimiter_comments = args.include_delimiter_comments

    # get top-level modules from input
    top_level_modules = []
    
    for dir_entry in os.listdir(params.input_dir):
        dir_path = os.path.join(params.input_dir, dir_entry)
        if os.path.isdir(dir_path):
            top_level_modules.append(dir_path)
            params.processed_modules.append(dir_entry)
    
    for tlm in top_level_modules:
        process_module(params, tlm)
