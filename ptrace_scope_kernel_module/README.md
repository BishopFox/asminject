# mod_set_ptrace_scope

The Yama security module for Linux includes a value named ptrace_scope that lets administrators control broad restrictions on the use of ptrace-related permissions (attaching a debugger, accessing /proc/[pid]/mem, and so on). Most Linux users eventually become familiar with the values 0, 1, and possibly even 2. However, the module also supports a lesser-known setting of 3, which prevents the use of ptrace-related features altogether, and is supposed to be impossible to changed to any other value without a reboot. (https://www.kernel.org/doc/Documentation/security/Yama.txt)

Users with the ability to load arbitrary kernel modules can reset the value back to 0 without rebootinng by building and loading this kernel module, which locates the appropriate table and makes changes directly in kernel memory. This can be helpful in at least two scenarios:

* An administrator has accidentally set the ptrace_scope value to 3, and wants to use ptrace capabilities to resolve a production issue without causing an outage.
* A penetration tester wishes to illustrate the futility of enforcing kernel-level security controls against users with the ability to execute code in the kernel.

This kernel module was based in part on the following:

* https://blog.sourcerer.io/writing-a-simple-linux-kernel-module-d9dc3762c234 
* https://github.com/jirislaby/ksplice/blob/master/kmodsrc/ksplice.c
* https://stackoverflow.com/questions/1184274/read-write-files-within-a-linux-kernel-module
* https://stackoverflow.com/questions/58512430/how-to-write-to-protected-pages-in-the-linux-kernel
* https://gist.github.com/ulexec/7eaa4c4042e66b37d310cfbd645ac10b

To build and install:
	apt-get install build-essential linux-headers-`uname -r`
	make
	sudo insmod mod_set_ptrace_scope.ko

To uninstall after use:
	sudo rmmod mod_set_ptrace_scope
	
In use:

```
# cat /proc/sys/kernel/yama/ptrace_scope

0

# echo 1 > /proc/sys/kernel/yama/ptrace_scope

# cat /proc/sys/kernel/yama/ptrace_scope

1

# echo 0 > /proc/sys/kernel/yama/ptrace_scope

# cat /proc/sys/kernel/yama/ptrace_scope
0

# echo 3 > /proc/sys/kernel/yama/ptrace_scope

# cat /proc/sys/kernel/yama/ptrace_scope     
3

# echo 0 > /proc/sys/kernel/yama/ptrace_scope

echo: write error: invalid argument

# cat /proc/sys/kernel/yama/ptrace_scope

3

# echo "oh noes! The production server is throwing errors for 15% of customers! If only I could attach a debugger to the application without rebooting!"

# make

...omitted for brevity...

# insmod mod_set_ptrace_scope.ko

# dmesg

...omitted for brevity...
[1414596.341915] Existing table state: table name 'ptrace_scope', current ptrace value is 0x3 (@ 0xbbfe2058), max length is 0x4, mode is 0x1a4, process handler is @ 0x000000003c69efd1, extra1 (min value) is 0x0 (@ 0x00000000c65e7065), extra2 (max value) is 0x3 (@ 0x00000000802ca259)
[1414596.341943] Got address 0x0000000062dccddf for remapped writable version of the yama sysctl table
[1414596.341953] Current data is 0x000000006eee2eaa
[1414596.341965] Current ptrace value: 0x3
[1414596.341974] Minimum ptrace value: 0x0
[1414596.341985] Maximum ptrace value: 0x3
[1414596.341996] Updating pointers
[1414596.342004] Setting current ptrace value
[1414596.342012] Setting minimum ptrace value
[1414596.342019] Setting maximum ptrace value
[1414596.342028] Updated yama sysctl table state: table name 'ptrace_scope', current ptrace value is 0x0 (@ 0xbbfe2058), max length is 0x4, mode is 0x1a4, process handler is @ 0x000000003c69efd1, extra1 (min value) is 0x0 (@ 0x00000000c65e7065), extra2 (max value) is 0x3 (@ 0x00000000802ca259)

# cat /proc/sys/kernel/yama/ptrace_scope

0

# rmmod mod_set_ptrace_scope
```


## Version history

### 1.0 (2021-09-01)

* Initial release
