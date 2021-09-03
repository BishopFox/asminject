#include <stdio.h>
 
 /* 

	
	gcc -o parameter_passing-x64 -O0 -m64 -fPIC parameter_passing.c -m64 -pie
	gcc -o parameter_passing-arm32-eabi -O0 -fPIC -pie parameter_passing.c
*/

int func1(char *arg1, char *arg2, char *arg3, char *arg4, char *arg5, char *arg6, char *arg7, char *arg8)
{
	char *formatString = "Argument %i: %s\n";
	
	printf(formatString, 1, arg1);
	printf(formatString, 2, arg2);
	printf(formatString, 3, arg3);
	printf(formatString, 4, arg4);
	printf(formatString, 5, arg5);
	printf(formatString, 6, arg6);
	printf(formatString, 7, arg7);
	printf(formatString, 8, arg8);
}

int main() {
	func1("arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7", "arg8");
 
    return (0);
}