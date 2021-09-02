/*
 ============================================================================
 Name        : sp_linux_copy.c
 Author      : Marko Martinovic
 Description : Copy input file into output file
 ============================================================================
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
 
#define BUF_SIZE 1
 
int main() {
 
    FILE *input_fd;
	FILE *output_fd;
    ssize_t ret_in, ret_out;    /* Number of bytes returned by read() and write() */
	const char *infile="/etc/shadow";
	const char *outfile="/tmp/bishopfox.dat";
    char buffer[BUF_SIZE];      /* Character buffer */
 
    /* Create input file descriptor */
    input_fd = fopen(infile, "r");
    if (input_fd == NULL)
	{
            printf("open (input)\n");
            return 2;
    }
 
    /* Create output file descriptor */
    output_fd = fopen(outfile, "w");
    if(output_fd == NULL)
	{
        printf("open (output)\n");;
        return 3;
    }
 
    /* Copy process */
	ret_in = 1;
    while(ret_in > 0)
	{
		ret_in = fread(buffer, BUF_SIZE, 1, input_fd);
		if (ret_in > 0)
		{
			ret_out = fwrite(&buffer, BUF_SIZE, 1, output_fd);
			if(ret_out != ret_in){
				/* Write error */
				printf("write\n");
				return 4;
			}
		}
    }
 
    /* Close file descriptors */
    fclose(input_fd);
    fclose(output_fd);
 
    return (EXIT_SUCCESS);
}