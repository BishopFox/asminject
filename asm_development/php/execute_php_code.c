#include "php.h"
#include "php_ini.h"
#include "sapi/embed/php_embed.h"

// https://flylib.com/books/en/2.565.1/calling_back_into_php.html
/* 

	gcc -o execute_php_code-x64 -I/usr/include/php/20190902 -I/usr/include/php/20190902/main -I/usr/include/php/20190902/Zend -I/usr/include/php/20190902/TSRM -I/usr/include/php/20190902/sapi -O0 -m64 execute_php_code.c -lphp7.4 -m64 -no-pie
	
	gcc -o execute_php_code-arm32-eabi -I/usr/include/php/20180731 -I/usr/include/php/20180731/main -I/usr/include/php/20180731/Zend -I/usr/include/php/20180731/TSRM -I/usr/include/php/20180731/sapi -O0 -fPIC execute_php_code.c -lphp7.3
*/

int main(int argc, char *argv[])
{
	char str[50];
	printf("Press enter to continue");
	gets(str);
	
	php_print_info(1);
   
	/* PHP_EMBED_START_BLOCK(argc, argv);
	zend_eval_string("echo 'Hello World!';", NULL, "Simple Hello World App" TSRMLS_CC);
	PHP_EMBED_END_BLOCK(); */
	return 0;
}