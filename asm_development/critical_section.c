#include <pthread.h>
#include <stdio.h>
 
/* https://docs.oracle.com/cd/E19683-01/806-6867/sync-12/index.html */

 /* 

	gcc -o critical_section-x32 -O0 -m32 -fPIC critical_section.c -m32 -lpthread
	gcc -o critical_section-x64 -O0 -m64 -fPIC critical_section.c -m64 -lpthread
*/

pthread_mutex_t count_mutex;
long long count;

void
increment_count()
{
	    pthread_mutex_lock(&count_mutex);
    count = count + 1;
	    pthread_mutex_unlock(&count_mutex);
}

long long get_count()
{
    long long c;
    
    pthread_mutex_lock(&count_mutex);
	    c = count;
    pthread_mutex_unlock(&count_mutex);
	    return (c);
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