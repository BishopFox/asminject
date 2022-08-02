#include <stdio.h>
 
 /* 

	gcc -o copy_64_bit_values-x32 -O0 -m32 -fPIC copy_64_bit_values.c -m32
	gcc -o copy_64_bit_values-x64 -O0 -m64 -fPIC copy_64_bit_values.c -m64
*/

int main(int argc, char *argv[]) {
	char *testString1 = "Test message";
	char *formatString = "Output: %s\n";
	long int bignum = 0x00007ffed5d20000;
	long int bignum2 = &argv[0];
	char *hexString = "Output: %llx\n";
	int i;
 
    printf(formatString, testString1);
	printf(hexString, bignum);
	
	for (i = 0; i < 10; i++)
	{
		bignum2 = bignum2 + (i * bignum2);
		printf(hexString, bignum2);
		bignum = bignum + (i * bignum);
		printf(hexString, bignum);
	}
 
    return (0);
}