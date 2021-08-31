#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

 /* 

	gcc -o mmap-x32 -O0 -m32 -fPIC mmap.c -m32
	gcc -o mmap-x64 -O0 -m64 -fPIC mmap.c -m64
*/

int main(void) {
  char * mapped = mmap(
	0, // start wherever, I guess?
	0x8000,	// size to mapp
	PROT_READ|PROT_WRITE|PROT_EXEC, //rwx
	MAP_PRIVATE|MAP_ANONYMOUS, // allocate new
	-1,	// file descriptor -1 = new
	0	// offset of 0
	);
  if (mapped == MAP_FAILED) {
    perror("mmap failed");
    return 1;
  }

  strcpy(mapped, "BishopFox.com");

  printf("Verify data: %s\n", mapped);

  return 0;
}