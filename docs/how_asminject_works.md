# How asminject.py works

<a href="../README.md">[ Back to the main README.md ]</a>

* [An introduction to code injection](#an-introduction-to-code-injection)
* [Determining which code to overwrite](#determining-which-code-to-overwrite)
* [Overwriting code without crashing the target process](#overwriting-code-without-crashing-the-target-process)
* [Writeable versus executable memory](#writeable-versus-executable-memory)
* [Communicating with the target process](#communicating-with-the-target-process)
* [Performing complex tasks inside the target process](#performing-complex-tasks-inside-the-target-process)
* [Cleaning up](#cleaning-up)

## An introduction to code injection

Consider a hypothetical back-end/batch process that loads data from a file, processes it, and then sends it over the network to another system:

<img src="How_asminject_Works-01.PNG" width="376" height="335" alt="[ Instruction flow in a target process ]">

At a high level, code injection tools hijack the normal flow of execution to insert additional operations. In the diagram below, the batch process still performs its standard work, but the injected code also transmits a copy of the resulting data to the attacker:

<img src="How_asminject_Works-02.PNG" width="632" height="470" alt="[ An attacking process replaces instructions in the target process to accomplish the attacker's goal ]">

You may be wondering "If the attacker has access to inject code into the process, why wouldn't they just copy the data from wherever the batch process is getting it?", and sometimes the answer is "that's probably exactly what the attacker would do", but sometimes tampering with an existing process is significantly easier. The process may be transparently decrypting the data using the permissions of the account it's running as. The code may be heavily obfuscated, and figuring out how to perform equivalent processing on the data might therefore be extremely complicated. The attacker might wish to help evade detection by establishing a persistent presence in a long-running process instead of attracting attention by starting a new process. The potential reasons are limitless. Most attackers will expend the least amount of effort necessary to achieve their goals, and sometimes the least amount of effort involves injecting new code into an existing process.

The "nuts and bolts" low-level view of the code-injection process is more complicated. Increasing the level of detail a bit, consider the following individual steps that might take place within just the "load data from disk" block from the first diagram:

<img src="How_asminject_Works-03.PNG" width="585" height="664" alt="[ Logical flow of a data-loading function in a target process ]">

When tampering with the memory of an existing process, the most significant initial building blocks are the ability to read existing data, or overwrite it with something else. Most complex functionality will be achieved by actual code that's written to memory. In modern computing systems, instructions typically need to be located in memory that's marked as executable, meaning that unless the attacker has performed a detailed analysis of the specific target binary, they're going to have to start out by overwriting some existing logic in the target process, but the more of the existing code is overwritten, the harder it will be to keep the target process stable during the injection and after the attacker's goals have been accomplished. In the diagram below, the attacker's code has overwritten the fourth, fifth, and sixth steps of the `Load_Data` function with new instructions that allocate a new, larger block of memory, load additional attacker-specified instructions into that new block of memory, and then redirect execution to those additional instructions. By asking the target process to allocate new memory, the attacker can specify an effectively unlimited amount of additional code without being constrained by having to figure out something that's safe to overwrite.

<img src="How_asminject_Works-04.PNG" width="846" height="710" alt="[ The attacking process overwrites three steps in the existing function ]">

When the target process reaches the "jump to new block" step, there is an additional set of instructions waiting to be executed at the new location. In the diagram below, the new instructions restore the original version of the `Load_Data` function, send the attacker a copy of the processed data over a secure channel, and then jump back to the original location in the `Load_Data` function.

<img src="How_asminject_Works-05.PNG" width="756" height="1408" alt="[ The injected code allocates a new block of memory containing additional code and jumps to it ]">

In other words, by the time the last new instruction is executed, the target process jumps back to the instructions that would have been present had they not been overwritten by the attacker, and the target process finishes its work normally.

<img src="How_asminject_Works-06.PNG" width="756" height="1408" alt="[ The additional injected code restores the original function, performs the attacker's tasks, and then returns to the original function so that the process completes normally ]">

This view still glosses over numerous important details, but those will be covered in the sections that follow.

## Determining which code to overwrite

## Overwriting code without crashing the target process

### Stopping the target process

### Preserving CPU and program state

## Writeable versus executable memory

## Communicating with the target process

## Performing complex tasks inside the target process

## Cleaning up


