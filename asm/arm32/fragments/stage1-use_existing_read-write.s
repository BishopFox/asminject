	ldr r11, [pc]
	b asminject_finish_use_existing_rw

asminject_existing_rw_address:
	.word [VARIABLE:READ_WRITE_ADDRESS:VARIABLE]
	.balign 4

asminject_finish_use_existing_rw:
