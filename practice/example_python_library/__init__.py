"""This is the description in example_python_library/__init__.py"""

__init_secret_value = "A very secret value that is only defined in example_python_library/__init.py__"

__all__ = ['ExampleClass']

class ExampleClass:
    CONST_1 = "Constant 1"
    
    def __init__(self):
        self.instance_var_1 = "Instance var 1"
    
    @staticmethod
    def ec_static_method_1(some_integer):
        print(some_integer)

def ExampleFunction(some_string):
    print("Module-level function")
    print(some_string)

@staticmethod
def ExampleStaticMethod(some_string):
    print("Module-level static method")
    print(some_string)

