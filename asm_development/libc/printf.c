#include <stdio.h>
 
 /* 

	gcc -o printf-x32 -O0 -m32 -fPIC printf.c -m32
	gcc -o printf-x64 -O0 -m64 -fPIC printf.c -m64
*/

int main() {
	char *testString1 = "Test message";
	char *formatString = "Output: %s\n";
	long int bignum = 0x00007ffed5d20000;
	char *hexString = "Output: %llx\n";
 
    printf(formatString, testString1);
	printf(hexString, bignum);
 
    return (0);
}