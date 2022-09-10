# asminject.py troubleshooting

<a href="../README.md">[ Back to the main README.md ]</a>

* [Extract Python code from a running Python process](#extract-python-code-from-a-running-python-process)

## asminject.py loops indefinitely waiting for a new communication address

If the target process isn't actively performing work that results in system calls being issued, `asminject.py` may loop forever waiting for the payload, e.g.:

```
[*] Waiting for payload to update the state value to switch_to_new_communication_address (0xa31804) at address 0x7ffda0b36e98
[*] Waiting for payload to update the state value to switch_to_new_communication_address (0xa31804) at address 0x7ffda0b36e98
[*] Waiting for payload to update the state value to switch_to_new_communication_address (0xa31804) at address 0x7ffda0b36e98
[*] Waiting for payload to update the state value to switch_to_new_communication_address (0xa31804) at address 0x7ffda0b36e98
[*] Waiting for payload to update the state value to switch_to_new_communication_address (0xa31804) at address 0x7ffda0b36e98
```

This is because `asminject.py` needs the target process to issue a syscall in order to hijack execution. Try doing something that will cause the target process to do work. For example, if it's a web server, send a request to its service port.