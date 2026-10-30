#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/reboot.h>

int main(void) {
    printf("MyOS init starting...\n");
    fflush(stdout);
    /* mount proc/sys/dev minimally */
    system("mount -t proc proc /proc 2>/dev/null");
    system("mount -t sysfs sys /sys 2>/dev/null");
    system("mount -t devtmpfs dev /dev 2>/dev/null");
    /* drop to shell */
    pid_t p = fork();
    if (p == 0) {
        execl("/bin/sh", "sh", NULL);
        perror("exec sh");
        _exit(1);
    }
    int st;
    waitpid(p, &st, 0);
    printf("shell exited; rebooting\n");
    reboot(RB_AUTOBOOT);
    return 0;
}
