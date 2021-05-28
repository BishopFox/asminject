# asminject
Heavily-modified fork of David Buchanan's dlinject project. Injects arbitrary assembly (or precompiled binary) payloads directly into Linux processes without the use of ptrace by accessing /proc/&lt;pid>/mem. Useful for certain post-exploitation scenarios, recovering content from process memory when ptrace is not available, and bypassing some security controls.
