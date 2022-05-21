	ldr r10, [pc]
	b asminject_finish_use_existing_rx

asminject_existing_rx_address:
	.word [VARIABLE:READ_EXECUTE_ADDRESS:VARIABLE]
	.balign 4

asminject_finish_use_existing_rx:
