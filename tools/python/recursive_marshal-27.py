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
        print("{name}\t{obj}".format(name, obj))

def escape_json_value_inner(json_string, chr_num):
    return json_string.replace(chr(chr_num), '\\\\u00' + '{0:0{1}x}'.format(chr_num, 2))

def escape_json_value(json_string):
    #result = json_string.replace('"', '\\\\"')
    result = json_string
    # backslash
    result = escape_json_value_inner(result, 92)
    for i in range(0, 32):
        #result = result.replace(chr(i), '\\\\u00' + '{0:0{1}x}'.format(i, 2))
        result = escape_json_value_inner(result, i)
    # double quote
    result = escape_json_value_inner(result, 34)
    # high ASCII characters - will cause problems with reconstruction
    for i in range(127, 256):
        result = escape_json_value_inner(result, i)
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
                    result += '{}:{},'.format(json_dump_string(k), json_dump_string(o[k]))
                    n += 1
                if n > 0:
                    result = result[0:-1]
                result += "}"
                return result
    except Exception as e:
        result = ""
    if isinstance(o, (list, tuple, set)):
        result = "["
        n = 0
        for e in o:
            result += "{},".format(json_dump_string(e))
            n += 1
        if n > 0:
            result = result[0:-1]
        result += "]"
        return result
    result = str(o)
    if isinstance(o, str):
        result = escape_json_value(result)
        result = '"' + result + '"'
    return result

def dump_code_object(parent_object_type, object_type, code_object, current_path, name, is_builtin, signature):
    try:
        out_name_base = "{}/{}/{}".format(recursive_marshal_base_dir, current_path, name)
        try:
            os.makedirs(os.path.dirname(out_name_base))
        except:
            pass
        out_name_src = ""
        out_name_bin = ""
        try:
            co_source = inspect.getsource(code_object)
            out_name_src = "{}.py".format(out_name_base)
            with open(out_name_src, "w") as source_file:
                source_file.write(co_source)
                print("Wrote source code for {} {}/{} to {}".format(object_type, current_path, name, out_name_src))
        except Exception as e:
            print("Couldn't get source code for {} {}: {}".format(object_type, current_path, e))
            out_name_src = ""
        try:
            out_name_bin = "{}.bin".format(out_name_base)
            with open(out_name_bin, "wb") as marshal_file:
                marshal.dump(code_object, marshal_file)
            print("Writing marshalled {} code object to {}".format(object_type, out_name_bin))
        except Exception as e:
            print("Couldn't write marshalled {} code object for {}: {}".format(object_type, current_path, e))
            out_name_bin = ""
        co_metadata = { "parent_type": parent_object_type, "object_type": object_type, "is_builtin": is_builtin, "object_name": name, "path": current_path, "python_version": sys.version_info }
        if out_name_src != "":
            co_metadata["source_code_file"] = out_name_src
        if out_name_bin != "":
            co_metadata["marshalled_file"]  = out_name_bin
        if signature:
            co_metadata["signature"] = "{}".format(signature)
        out_name_json = "{}.json".format(out_name_base)
        try:
            with open(out_name_json, "w") as json_file:
                json_file.write(json_dump_string(co_metadata))
        except Exception as e:
            print("Couldn't write JSON data for {} {}: {}".format(object_type, current_path, e))
    except Exception as e:
        print("Couldn't export {} code object {}: {}".format(object_type, current_path, e))

def get_user_attributes(c):
    class_attributes = dir(c)
    result = []
    for att in class_attributes:
        if att in [ "__annotations__", "__builtins__", "__cached__", "__file__", "__loader__", "__name__", "__package__", "__spec__", "iterated_objects", "sys_module" ]:
            continue
        attv = getattr(c, att)
        if base_class_attributes.count(att):
            continue
        if callable(attv):
            continue
        if inspect.ismodule(attv):
            continue
        #if inspect.isclass(attv):
        #    continue
        #if inspect.isfunction(attv):
        #    continue
        result += [att]
    return result

# BEGIN: https://stackoverflow.com/questions/2677185/how-can-i-read-a-functions-signature-including-default-argument-values
from collections import namedtuple

DefaultArgSpec = namedtuple('DefaultArgSpec', 'has_default default_value')

def _get_default_arg(args, defaults, arg_index):
    if not defaults:
        return DefaultArgSpec(False, None)

    args_with_no_defaults = len(args) - len(defaults)

    if arg_index < args_with_no_defaults:
        return DefaultArgSpec(False, None)
    else:
        value = defaults[arg_index - args_with_no_defaults]
        if (type(value) is str):
            value = '"%s"' % value
        return DefaultArgSpec(True, value)

def get_method_sig(method):
    argspec = inspect.getargspec(method)
    arg_index=0
    args = []

    for arg in argspec.args:
        default_arg = _get_default_arg(argspec.args, argspec.defaults, arg_index)
        if default_arg.has_default:
            args.append("%s=%s" % (arg, default_arg.default_value))
        else:
            args.append(arg)
        arg_index += 1
    return "(%s)" % (", ".join(args))
# END: https://stackoverflow.com/questions/2677185/how-can-i-read-a-functions-signature-including-default-argument-values


def iteratively_dump_object(object_type, object_name, o, current_path, d, max_d, export_builtins):
    global obj_counter
    global iterated_objects
    object_metadata = { "name": object_name, "path": current_path, "object_type": object_type }
    out_name_json = "{}/{}/___exported_object_metadata___.json".format(recursive_marshal_base_dir, current_path)
    try:
        os.makedirs(os.path.dirname(out_name_json))
    except:
        pass
    
    out_name_src = "{}/{}/___exported_object_source___.py".format(recursive_marshal_base_dir, current_path)
    try:
        object_source = inspect.getsource(o)        
        with open(out_name_src, "w") as source_file:
            source_file.write(object_source)
            print("Wrote entire source code for object {} to {}".format(current_path, out_name_src))
    except Exception as e:
        print("Couldn't get source code for {}: {}".format(current_path, e))
        out_name_src = ""
    
    if out_name_src != "":
        object_metadata["source_code_file"] = out_name_src
    
    member_metadata = {}
    member_imports = []
    member_attributes = {}
    member_code_objects = []
    member_classes = []
    member_functions = []
    member_methods = []
    member_routines = []
    
    
    try:
        for name, obj in inspect.getmembers(o):
            member_metadata[name] = obj
            obj_path = "{}/{}".format(current_path, name)
            obj_counter +=1
            obj_to_recurse = None
            recurse_obj_type = None
            is_builtin = inspect.isbuiltin(obj)
            if export_builtins or not is_builtin:
                if inspect.iscode(obj):
                    member_code_objects.append(name)
                    dump_code_object(object_type, "code_object", obj, current_path, name, is_builtin, None)
                if inspect.ismodule(obj):
                    #print("Module: {}".format(name))
                    if name not in member_imports:
                        member_imports.append(name)
                    if name not in iterated_objects:
                        iterated_objects.append(name)
                        obj_to_recurse = obj
                        recurse_obj_type = "module"
                if inspect.isclass(obj):
                    member_classes.append(name)
                    if name not in ["__class__", "__base__", "__ctype_be__", "__ctype_le__"]:
                        #print("Class: {}".format(name))
                        #print_members(obj)
                        obj_to_recurse = obj.__dict__
                        recurse_obj_type = "class"
                got_code_object = False
                if inspect.ismethod(obj):
                    member_methods.append(name)
                    #print("Method: {}".format(name))
                    #print_members(obj)
                    signature = get_method_sig(obj.__func__)
                    dump_code_object(object_type, "method", obj.__func__.__code__, current_path, name, is_builtin, signature)
                    #dump_code_object(obj, current_path, name)
                    got_code_object = True
                if inspect.isfunction(obj):
                    member_functions.append(name)
                    #print("Function: {}".format(name))
                    #print_members(obj)
                    signature = get_method_sig(obj)
                    dump_code_object(object_type, "function", obj.__code__, current_path, name, is_builtin, signature)
                    got_code_object = True
                if not got_code_object:
                    if inspect.isroutine(obj):
                        member_routines.append(name)
                        #print("Routine: {}".format(name))
                        #print_members(obj)
                        object_function = None
                        if hasattr(obj, "__func__"):
                            object_function = obj.__func__
                        if not object_function:
                            if hasattr(obj, "__code__"):
                                object_function = obj
                        if object_function:
                            signature = get_method_sig(object_function)
                            dump_code_object(object_type, "routine", object_function.__code__, current_path, name, is_builtin, signature)
                
                if obj_to_recurse and d < max_d:
                    if obj_path not in iterated_objects:
                        iterated_objects.append(obj_path)
                        iteratively_dump_object(recurse_obj_type, name, obj, obj_path, d+1, max_d, export_builtins)
    except Exception as e:
        print("Error getting members for {}: {}".format(current_path, e))
    object_metadata["member_metadata"] = member_metadata
    object_metadata["member_attributes"] = member_attributes
    object_metadata["imported_modules"] = member_imports
    object_metadata["code_objects"] = member_code_objects
    object_metadata["classes"] = member_classes
    object_metadata["functions"] = member_functions
    object_metadata["methods"] = member_methods
    object_metadata["routines"] = member_routines
    try:
        with open(out_name_json, "w") as json_file:
            json_file.write(json_dump_string(object_metadata))
    except Exception as e:
        print(f"Error writing JSON to {out_name_json}: {e}")

# avoid dictionary length from changing during iteration errors
mod_list = []
for sys_module in sys.modules:
    mod_list.append(sys_module)

#for sys_module in sys.modules:
for sys_module in mod_list:
    if sys_module not in iterated_objects:
        #print("Module: {}".format(sys_module))
        iterated_objects.append(sys_module)
        iteratively_dump_object("module", sys_module, sys.modules.get(sys_module), sys_module, 0, 10, True)