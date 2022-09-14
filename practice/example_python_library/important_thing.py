important_thing_secret_value = "A very secret value that is only defined in example_python_library/important_thing.py"

class important_class_1:
    class_variable_1 = "this is a class variable"

    def __init__(self):
        self.important_hardcoded_value = "A very secret value that is only defined in the __init__ function for important_class_1 in example_python_library/important_thing.py"
    
    def ic1_print_ihv(self):
        print(self.important_hardcoded_value)
    
    @staticmethod
    def ic1_static_print_ihv():
        print("A very secret value that is only defined in the static_print_ihv function for important_class_1 in example_python_library/important_thing.py")

def it_print_itsv():
    print(important_thing_secret_value)

@staticmethod
def it_static_print_itsv():
    print("A very secret value that is only defined in example_python_library/important_thing.py's static method it_static_print_itsv")
