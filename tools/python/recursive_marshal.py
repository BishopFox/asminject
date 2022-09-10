#!/usr/bin/env python3 

import inspect
import marshal
import os
import sys

# base directory for export
recursive_marshal_base_dir = "/tmp/marshalled"

obj_counter = 0
# preload this list with any libraries that are problematic to export, like inspect
iterated_objects = [ "ctypes", "inspect" ]

def print_members(o):
    for name, obj in inspect.getmembers(o):
        print(f"{name}\t{obj}")

def escape_json_value(json_string):
    result = json_string.replace('"', '\\\\"')
    for i in range(0, 31):
        result = result.replace(chr(i), '\\\\u00' + '{0:0{1}x}'.format(i, 2))
    return result

# faux function because json module is not available by default
def json_dump_string(o):
    result = ""
    try:
        if hasattr(o, "keys"):
            keys = getattr(o, "keys")
            if callable(keys):
                result = "{"
                n = 0
                for k in o.keys():
\                    result += f'"{escape_json_value(k)}":{json_dump_string(o[k])},'
                    n += 1
                if n > 0:
                    result = result[0:-1]
                result += "}"
                return result
    except Exception as e:
        result = ""
    result = str(o)
    result = escape_json_value(result)
    return '"'+result+'"'

def dump_code_object(parent_object_type, object_type, code_object, current_path, name, is_builtin, signature):
    try:
        out_name_base = f"{recursive_marshal_base_dir}/{current_path}/{name}"
        os.makedirs(os.path.dirname(out_name_base), exist_ok=True)
        out_name_src = ""
        out_name_bin = ""
        try:
            co_source = inspect.getsource(code_object)
            out_name_src = f"{out_name_base}.py"
            with open(out_name_src, "w") as source_file:
                source_file.write(co_source)
                print(f"Wrote source code for {current_path}/{name} to {out_name_src}")
        except Exception as e:
            print(f"Couldn't get source code for {current_path}")
            out_name_src = ""
        try:
            out_name_bin = f"{out_name_base}.bin"
            print(f"Writing code to {out_name_bin}")
            with open(out_name_bin, "wb") as marshal_file:
                marshal.dump(code_object, marshal_file)
        except Exception as e:
            print(f"Couldn't write marshalled code object for {current_path}: {e}")
            out_name_bin = ""
        co_metadata = { "parent_type": parent_object_type, "object_type": object_type, "is_builtin": is_builtin, "object_name": name, "path": current_path, "python_version": sys.version_info }
        if out_name_src != "":
            co_metadata["source_code_file"] = out_name_src
        if out_name_bin != "":
            co_metadata["marshalled_file"]  = out_name_bin
        if signature:
            co_metadata["signature"] = f"{signature}"
        out_name_json = f"{out_name_base}.json"
        try:
            with open(out_name_json, "w") as json_file:
                json_file.write(json_dump_string(co_metadata))
        except Exception as e:
            print(f"Couldn't write JSON data for {current_path}: {e}")
    except Exception as e:
        print("Couldn't export code object {0}: {1}".format(current_path, e))

def iteratively_dump_object(object_type, o, current_path, d, max_d, export_builtins):
    global obj_counter
    global iterated_objects
    object_metadata = { "path": current_path, "object_type": object_type }
    out_name_json = f"{recursive_marshal_base_dir}/{current_path}/___exported_object_metadata___.json"
    os.makedirs(os.path.dirname(out_name_json), exist_ok=True)
   
    out_name_src = f"{recursive_marshal_base_dir}/{current_path}/___exported_object_source___.py"
    try:
        object_source = inspect.getsource(o)        
        with open(out_name_src, "w") as source_file:
            source_file.write(object_source)
            print(f"Wrote entire source code for object {current_path} to {out_name_src}")
    except Exception as e:
        print(f"Couldn't get source code for {current_path}: {e}")
        out_name_src = ""
    
    if out_name_src != "":
        object_metadata["source_code_file"] = out_name_src
    
    member_metadata = {}
    
    try:
        for name, obj in inspect.getmembers(o):
            member_metadata[name] = obj
            obj_path = f"{current_path}/{name}"
            obj_counter +=1
            obj_to_recurse = None
            recurse_obj_type = None
            is_builtin = inspect.isbuiltin(obj)
            if export_builtins or not is_builtin:
                if inspect.iscode(obj):
                    dump_code_object(object_type, "code_object", obj, current_path, name, is_builtin, None)
                if inspect.ismodule(obj):
                    #print(f"Module: {name}")
                    if name not in iterated_objects:
                        iterated_objects.append(name)
                        obj_to_recurse = obj
                        recurse_obj_type = "module"
                if inspect.isclass(obj):
                    if name not in ["__class__", "__base__", "__ctype_be__", "__ctype_le__"]:
                        #print(f"Class: {name}")
                        #print_members(obj)
                        obj_to_recurse = obj.__dict__
                        recurse_obj_type = "class"
                #if inspect.ismethod(obj):
                    #print(f"Method: {name}")
                    #print_members(obj)
                    #dump_code_object(obj, current_path, name)
                if inspect.isfunction(obj):
                    #print(f"Function: {name}")
                    #print_members(obj)
                    signature = inspect.signature(obj)
                    dump_code_object(object_type, "function", obj.__code__, current_path, name, is_builtin, signature)
                
                if obj_to_recurse and d < max_d:
                    if obj_path not in iterated_objects:
                        iterated_objects.append(obj_path)
                        iteratively_dump_object(recurse_obj_type, obj, obj_path, d+1, max_d, export_builtins)
    except Exception as e:
        print(f"Error getting members for {current_path}: {e}")
    object_metadata["member_metadata"] = member_metadata
    with open(out_name_json, "w") as json_file:
        json_file.write(json_dump_string(object_metadata))

# avoid dictionary length from changing during iteration errors
mod_list = []
for sys_module in sys.modules:
    mod_list.append(sys_module)

#for sys_module in sys.modules:
for sys_module in mod_list:
    if sys_module not in iterated_objects:
        #print(f"Module: {sys_module}")
        iterated_objects.append(sys_module)
        iteratively_dump_object("module", sys.modules.get(sys_module), sys_module, 0, 10, True)