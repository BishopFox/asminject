#include <pthread.h>
#include <stdio.h>
 
/* https://stackoverflow.com/questions/3508507/what-are-gcc-on-linuxs-equivalent-to-microsofts-critical-sections/19374236
   and https://stackoverflow.com/questions/53430194/pthread-recursive-mutex-initializer-np-error-in-qnx-7
 */

 /* 

	gcc -o critical_section-x32 -O0 -m32 -fPIC critical_section.c -m32 -lpthread
	gcc -o critical_section-x64 -O0 -m64 -fPIC critical_section.c -m64 -lpthread
*/

#  define PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP { { 0, 0, 0, 0, PTHREAD_MUTEX_RECURSIVE_NP, __PTHREAD_SPINS, { 0, 0 } } }

/* This is the critical section object (statically allocated). */
static pthread_mutex_t cs_mutex =  PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP;

void f()
{
    /* Enter the critical section -- other threads are locked out */
    pthread_mutex_lock( &cs_mutex );

    /* Do some thread-safe processing! */

    /*Leave the critical section -- other threads can now pthread_mutex_lock()  */
    pthread_mutex_unlock( &cs_mutex );
}

int main()
{
    f();

    return 0;
}

int main() {
	long long x;
	count = 0;
	char *llString = "Output: %llx\n";
 
	
	
	x = get_count();
	printf(llString, x);
	count++;
	x = get_count();
	printf(llString, x);
}