#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>

 /* 

	gcc -o launch_thread-x32 -O0 -m32 -fPIC launch_thread.c -m32 -lpthread
	gcc -o launch_thread-x64 -O0 -m64 -fPIC launch_thread.c -m64 -lpthread
*/

pthread_t thread_id;

void * f(void *args)
{
    printf("This statement executed in a new thread\n");
	
	return NULL;
}

int main(void)
{
	int returncode;
	printf("This statement executed in the main thread before launching a new thread\n");
	returncode = pthread_create(&(thread_id), NULL, &f, NULL);
	if (returncode != 0)
	{
	printf("Return code from pthread_create: [%i], %s\n", returncode, strerror(returncode));
	}
	else
	{
		printf("Return code from pthread_create: 0\n");
	}
	printf("This statement executed in the main thread after launching a new thread\n");
	
	sleep(10);
	return 0;
}
