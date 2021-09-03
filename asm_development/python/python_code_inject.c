#include "Python.h"
#include <stdio.h>

/* 

	gcc -o python2.7_code_inject-x32 -I/usr/include/python2.7 -O0 -m32 -fPIC python_code_inject.c -lpython2.7 -m32
	gcc -o python3.9_code_inject-x32 -I/usr/include/python3.9 -O0 -m32 -fPIC python_code_inject.c -lpython3.9 -m32
	gcc -o python2.7_code_inject-x64_ -I/usr/include/python2.7 -O0 -m64 -fPIC python_code_inject.c -lpython2.7 -m64
	gcc -o python3.9_code_inject-x64 -I/usr/include/python3.9 -O0 -m64 -fPIC python_code_inject.c -lpython3.9 -m64
	gcc -o python2.7_code_inject-arm32-eabi -I/usr/include/python2.7 -O0 -fPIC -pie python_code_inject.c -lpython2.7 
	gcc -o python3.7_code_inject-arm32-eabi -I/usr/include/python3.7 -O0 -fPIC python_code_inject.c -lpython3.7m 
*/
 
int main(int argc, char **argv)
{ 
    PyGILState_STATE python_handle1;
    PyGILState_STATE python_handle2;
	
	Py_Initialize();
	python_handle1 = PyGILState_Ensure();
	PyRun_SimpleString("print('OK 1');");
	python_handle2 = PyGILState_Ensure();
	PyRun_SimpleString("print('OK 2');");
	PyGILState_Release(python_handle2);
	PyGILState_Release(python_handle1);
	Py_Finalize();
 
    return (0);
}