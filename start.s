.globl _start

.text

_start:
        MOV     r1, #250
        MOV     r1, #250
        add     r1, #250
        MOV     SP, r1
        BL      main
        B       stall_loop
stall_loop:
        MOV     r6, #111
        B       stall_loop