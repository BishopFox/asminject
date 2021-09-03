/*
 ============================================================================
 Name        : sp_linux_copy.c
 Author      : Marko Martinovic
 Description : Copy input file into output file
 ============================================================================
 
	 gcc -o copy_between_files-arm32-eabi -O0 -fPIC -pie copy_between_files.c
 */
 
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/types.h>
#include <unistd.h>
 
#define BUF_SIZE 8192
 
int main(int argc, char* argv[]) {
 
    int input_fd, output_fd;    /* Input and output file descriptors */
    ssize_t ret_in, ret_out;    /* Number of bytes returned by read() and write() */
    char buffer[BUF_SIZE];      /* Character buffer */
 
    /* Are src and dest file name arguments missing */
    if(argc != 3){
        printf ("Usage: cp file1 file2");
        return 1;
    }
 
    /* Create input file descriptor */
    input_fd = open (argv [1], O_RDONLY);
    if (input_fd == -1) {
            perror ("open");
            return 2;
    }
 
    /* Create output file descriptor */
    output_fd = open(argv[2], O_WRONLY | O_CREAT, 0644);
    if(output_fd == -1){
        perror("open");
        return 3;
    }
 
    /* Copy process */
    while((ret_in = read (input_fd, &buffer, BUF_SIZE)) > 0){
            ret_out = write (output_fd, &buffer, (ssize_t) ret_in);
            if(ret_out != ret_in){
                /* Write error */
                perror("write");
                return 4;
            }
    }
 
    /* Close file descriptors */
    close (input_fd);
    close (output_fd);
 
    return (EXIT_SUCCESS);
}