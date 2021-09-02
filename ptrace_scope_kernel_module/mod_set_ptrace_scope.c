#include <asm/page.h>
#include <linux/bug.h>
#include <linux/ctype.h>
#include <linux/debugfs.h>
#include <linux/errno.h>
#include <linux/init.h>
#include <linux/kallsyms.h>
#include <linux/kernel.h>
#include <linux/kobject.h>
#include <linux/kprobes.h>
#include <linux/kthread.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/pagemap.h>
#include <linux/sched.h>
#include <linux/slab.h>
#include <linux/sort.h>
#include <linux/stop_machine.h>
#include <linux/sysctl.h>
#include <linux/sysfs.h>
#include <linux/time.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#include <linux/vmalloc.h>
#include <stddef.h>

/* 
Custom kernel module for changing the Yama ptrace_scope value even when it has been set to 3
Version 1.0
Ben Lincoln, Bishop Fox, 2021-09-01 */

/*
The Yama security module for Linux includes a value named ptrace_scope that lets administrators control broad restrictions on the use of ptrace-related permissions (attaching a debugger, accessing /proc/<pid>/mem, and so on). Most Linux users eventually become familiar with the values 0, 1, and possibly even 2. However, the module also supports a lesser-known setting of 3, which prevents the use of ptrace-related features altogether, and is supposed to be impossible to changed to any other value without a reboot. (https://www.kernel.org/doc/Documentation/security/Yama.txt)

Users with the ability to load arbitrary kernel modules can reset the value back to 0 without rebootinng by building and loading this kernel module, which locates the appropriate table and makes changes directly in kernel memory. This can be helpful in at least two scenarios:

* An administrator has accidentally set the ptrace_scope value to 3, and wants to use ptrace capabilities to resolve a production issue without causing an outage.
* A penetration tester wishes to illustrate the futility of enforcing kernel-level security controls against users with the ability to execute code in the kernel.

To build and install:
	apt-get install build-essential linux-headers-`uname -r`
	make
	sudo insmod mod_set_ptrace_scope.ko

To uninstall after use:
	sudo rmmod mod_set_ptrace_scope
	
In use:

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

*/
/*
Originally based in part on:
 https://blog.sourcerer.io/writing-a-simple-linux-kernel-module-d9dc3762c234 
 https://github.com/jirislaby/ksplice/blob/master/kmodsrc/ksplice.c
 https://stackoverflow.com/questions/1184274/read-write-files-within-a-linux-kernel-module
 https://stackoverflow.com/questions/58512430/how-to-write-to-protected-pages-in-the-linux-kernel
 https://gist.github.com/ulexec/7eaa4c4042e66b37d310cfbd645ac10b
*/

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ben Lincoln");
MODULE_DESCRIPTION("A Linux kernel module that re-enables ptrace by setting /proc/sys/kernel/yama/ptrace_scope to 0 unnder all connditions");
MODULE_VERSION("1.0");

#define YAMA_SCOPE_DISABLED	0
#define YAMA_SCOPE_RELATIONAL	1
#define YAMA_SCOPE_CAPABILITY	2
#define YAMA_SCOPE_NO_ATTACH	3

// copy/paste of the same function in https://github.com/jirislaby/ksplice/blob/master/kmodsrc/ksplice.c (GPLv2)
static void *map_writable(void *addr, size_t len, int is_module_memory)
{
	void *vaddr;
	int nr_pages = DIV_ROUND_UP(offset_in_page(addr) + len, PAGE_SIZE);
	struct page **pages = kmalloc(nr_pages * sizeof(*pages), GFP_KERNEL);
	void *page_addr = (void *)((unsigned long)addr & PAGE_MASK);
	int i;

	if (pages == NULL)
	{
		pr_info("map_writable: pages was null\n");
		return NULL;
	}

	for (i = 0; i < nr_pages; i++)
	{
		if (is_module_memory < 1)
		{
			pages[i] = virt_to_page(page_addr);
			WARN_ON(!PageReserved(pages[i]));
		}
		else
		{
			pages[i] = vmalloc_to_page(page_addr);
		}
		if (pages[i] == NULL)
		{
			pr_info("map_writable: pages[%i] was null\n", i);
			kfree(pages);
			return NULL;
		}
		page_addr += PAGE_SIZE;
	}
	vaddr = vmap(pages, nr_pages, VM_MAP, PAGE_KERNEL);
	kfree(pages);
	if (vaddr == NULL)
	{
		pr_info("map_writable: vaddr was null\n");
		return NULL;
	}
	return vaddr + offset_in_page(addr);
}

/* Begin: borrowed from https://github.com/zizzu0/LinuxKernelModules/blob/main/FindKallsymsLookupName.c (GPL) */

#define KPROBE_PRE_HANDLER(fname) static int __kprobes fname(struct kprobe *p, struct pt_regs *regs)

long unsigned int kln_addr = 0;
unsigned long (*kln_pointer)(const char *name) = NULL;

static struct kprobe kp0, kp1;

KPROBE_PRE_HANDLER(handler_pre0)
{
	kln_addr = (--regs->ip);
  
	return 0;
}

KPROBE_PRE_HANDLER(handler_pre1)
{
	return 0;
}

static int do_register_kprobe(struct kprobe *kp, char *symbol_name, void *handler)
{
  int ret;
  
  kp->symbol_name = symbol_name;
  kp->pre_handler = handler;
  
  ret = register_kprobe(kp);
  if (ret < 0) {
    pr_err("register_probe() for symbol %s failed, returned %d\n", symbol_name, ret);
    return ret;
  }
  
  pr_info("Planted kprobe for symbol %s at 0x%p\n", symbol_name, kp->addr);
  
  return ret;
}

/* End: borrowed from https://github.com/zizzu0/LinuxKernelModules/blob/main/FindKallsymsLookupName.c (GPL) */


static int __init mod_set_ptrace_scope_init(void)
{
	struct ctl_table *yama_sysctl_table;
	struct ctl_table *yama_sysctl_table_readonly;
	int *yama_data_value_readonly;
	int *yama_min_value_readonly;
	int *yama_max_value_readonly;
	int *yama_data_value;
	int *yama_min_value;
	int *yama_max_value;
	int *table_page;
	int ret;
	int continue_processing = 1;
	pr_info("Locating and loading existing yama sysctl table data\n");

	/* This next section should automatically look up the address of the yama sysctl table 
		...but if it fails for some reason, comment out this block and hardcode it to the value
		found with cat /proc/kallsyms | grep yama_sysctl_table
		*/
	/* Begin: borrowed from https://github.com/zizzu0/LinuxKernelModules/blob/main/FindKallsymsLookupName.c (GPL) */
	ret = do_register_kprobe(&kp0, "kallsyms_lookup_name", handler_pre0);
	if (ret < 0)
	{
		return ret;
	}

	ret = do_register_kprobe(&kp1, "kallsyms_lookup_name", handler_pre1);
	if (ret < 0) {
		unregister_kprobe(&kp0);
		return ret;
	}

	unregister_kprobe(&kp0);
	unregister_kprobe(&kp1);

	pr_info("kallsyms_lookup_name address = 0x%lx\n", kln_addr);

	kln_pointer = (unsigned long (*)(const char *name)) kln_addr;

	pr_info("kallsyms_lookup_name address = 0x%lx\n", kln_pointer("kallsyms_lookup_name"));
	/* End: borrowed from https://github.com/zizzu0/LinuxKernelModules/blob/main/FindKallsymsLookupName.c (GPL) */
	
	yama_sysctl_table_readonly = (struct ctl_table *)kln_pointer("yama_sysctl_table");
	
	/* hardcoded option:
	
	yama_sysctl_table_readonly = (struct ctl_table *)0xffffffffbb79ea40; */
	
	yama_data_value_readonly = (int *)yama_sysctl_table_readonly->data;
	yama_min_value_readonly = (int *)yama_sysctl_table_readonly->extra1;
	yama_max_value_readonly = (int *)yama_sysctl_table_readonly->extra2;
	
	
	if (yama_data_value_readonly == NULL)
	{
		pr_err("Couldn't retrieve existing data value from yama sysctl table\n");
		continue_processing = 0;
	}
	
	if (continue_processing > 0)
	{
		pr_info("Real copy of yama sysctl table is at 0x%p. Current value is 0x%p\n", yama_sysctl_table_readonly, *yama_sysctl_table_readonly);
		pr_info("Existing table state: table name '%s', current ptrace value is 0x%x (@ 0x%x), max length is 0x%x, mode is 0x%x, process handler is @ 0x%p, extra1 (min value) is 0x%x (@ 0x%p), extra2 (max value) is 0x%x (@ 0x%p)\n", yama_sysctl_table_readonly->procname, *yama_data_value_readonly, yama_sysctl_table_readonly->data, yama_sysctl_table_readonly->maxlen, yama_sysctl_table_readonly->mode, yama_sysctl_table_readonly->proc_handler, *yama_min_value_readonly, yama_sysctl_table_readonly->extra1, *yama_max_value_readonly, yama_sysctl_table_readonly->extra2);
		
		yama_sysctl_table = map_writable(yama_sysctl_table_readonly, 0x80, 0);
		if (yama_sysctl_table == NULL)
		{
			pr_err("Couldn't map a writable version of the yama sysctl table\n");
			continue_processing = 0;
		}
		else
		{
			pr_info("Got address 0x%p for remapped writable version of the yama sysctl table\n", yama_sysctl_table);
			pr_info("Current data is 0x%p\n", *yama_sysctl_table);
		}
		
		if (continue_processing > 0)
		{
			/* get separate writable memory for the values that are pointed to */
			/* some Linux versions need is_module_memory set to 1, others 0
				I haven't figured out what the difference is, so this module just tries both ways
			*/
			yama_data_value = (int *)map_writable(yama_data_value_readonly, 0x8, 0);
			yama_min_value = (int *)map_writable(yama_min_value_readonly, 0x8, 0);
			yama_max_value = (int *)map_writable(yama_max_value_readonly, 0x8, 0);
			
			if (yama_data_value == NULL)
			{
				yama_data_value = (int *)map_writable(yama_data_value_readonly, 0x8, 1);
				yama_min_value = (int *)map_writable(yama_min_value_readonly, 0x8, 1);
				yama_max_value = (int *)map_writable(yama_max_value_readonly, 0x8, 1);
				if (yama_data_value == NULL)
				{
					pr_info("Couldn't retrieve current ptrace value\n");
					continue_processing = 0;
				}
			}
			
			if (continue_processing > 0)
			{
				pr_info("Current ptrace value: 0x%x\n", *yama_data_value);
			}
			
			if (yama_min_value == NULL)
			{
				pr_info("Couldn't retrieve ptrace minimum value\n");
				continue_processing = 0;
			}
			
			if (continue_processing > 0)
			{
				pr_info("Minimum ptrace value: 0x%x\n", *yama_min_value);
			}
			
			if (yama_max_value == NULL)
			{
				pr_info("Couldn't retrieve ptrace maximum value\n");
				continue_processing = 0;
			}
			
			if (continue_processing > 0)
			{
				pr_info("Maximum ptrace value: 0x%x\n", *yama_max_value);
			
			
				pr_info("Updating pointers\n");
				if (yama_data_value != NULL)
				{
					pr_info("Setting current ptrace value\n");
					*yama_data_value = YAMA_SCOPE_DISABLED;
				}
				if (yama_min_value != NULL)
				{
					pr_info("Setting minimum ptrace value\n");
					*yama_min_value = YAMA_SCOPE_DISABLED;
				}
				if (yama_max_value != NULL)
				{
					pr_info("Setting maximum ptrace value\n");
					*yama_max_value = YAMA_SCOPE_NO_ATTACH;
				}
				
				pr_info("Updated yama sysctl table state: table name '%s', current ptrace value is 0x%x (@ 0x%x), max length is 0x%x, mode is 0x%x, process handler is @ 0x%p, extra1 (min value) is 0x%x (@ 0x%p), extra2 (max value) is 0x%x (@ 0x%p)\n", yama_sysctl_table_readonly->procname, *yama_data_value_readonly, yama_sysctl_table_readonly->data, yama_sysctl_table_readonly->maxlen, yama_sysctl_table_readonly->mode, yama_sysctl_table_readonly->proc_handler, *yama_min_value_readonly, yama_sysctl_table_readonly->extra1, *yama_max_value_readonly, yama_sysctl_table_readonly->extra2);
			}
		}
	}
	return 0;
}
static void __exit mod_set_ptrace_scope_exit(void)
{
	pr_info("Re-enable ptrace kernel module exiting\n");
}
module_init(mod_set_ptrace_scope_init);
module_exit(mod_set_ptrace_scope_exit);