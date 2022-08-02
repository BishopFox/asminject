#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

 /* 
	Based partly on https://gist.github.com/tailriver/30bf0c943325330b7b6a
	gcc -o dlopen-x32 -O0 -m32 -fPIC dlopen.c -m32 -ldl
	gcc -o dlopen-x64 -O0 -m64 -fPIC dlopen.c -m64 -ldl
*/

int main(int argc, char** argv)
{
	void *handle;
    void (*target_function)();
	const char *target_function_name = "__DT_INIT";

    handle = dlopen(argv[1], RTLD_NOW);
	
    if (!handle) {
        fprintf(stderr, "Error: %s\n", dlerror());
        return 1;
    }

    *(void**)(&target_function) = dlsym(handle, target_function_name);
    if (!target_function) {
        /* no such symbol */
        fprintf(stderr, "Error: %s\n", dlerror());
        dlclose(handle);
        return 1;
    }

    //target_function();
    dlclose(handle);

    return 0;
}