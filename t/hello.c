#include <stdio.h>
#include <stdlib.h>

int main (int argc, char **argv) {
    if (argc > 1) {
        printf("%s\n", argv[1]);
    }
    printf("hello world!\n");
    return 0;
}
