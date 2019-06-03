; Keyboard interrupt
;
; by nyLiao, June, 2019

data_seg segment
    ; Keyboard scan codes (A to Z)
    kc  Db  1eh, 30h, 2eh, 20h, 12h, 21h, 22h, 23h, 17h, 24h, 25h, 26h, 32h, 31h, 18h, 19h, 10h, 13h, 1fh, 14h, 16h, 2fh, 11h, 2dh, 15h, 2ch
    ; Other parameters

data_seg ends


stack_seg segment
    stk DB  100 DUP(0); stack
    top EQU 100;        stack top
stack_seg ends


code_seg segment
    assume cs:code_seg, ds:data_seg, ss:stack_seg
start:
; main codes
; global regs:

    ; init
    mov  ax, data_seg
    mov  ds, ax
    mov  ax, stack_seg
    mov  ss, ax
    mov  sp, top

    ; init processors
    call far ptr init8259;
    call far ptr init8253;

    ; overwrite interrupts
    call far ptr newint09;
    call far ptr newint08;








init8259 proc far
; initialize PIC 8259

    push ax

    ; ICW_1
    mov  al, 13h
    out  20h, al
    ; ICW_2
    mov  al, 08h
    out  21h, al
    ; ICW_4
    mov  al, 09h
    out  21h, al

    pop  ax
    ret

init8259 endp


init8253 proc far
; initialize PIT 8253

    push ax

    ; control word register
    mov  al, 36h
    out  43h, al
    ; counter 0, LSB
    mov  al, 20h
    out  40h, al
    ; counter 0, MSB
    mov  al, 4eh;       4e20h = 20000d
    out  40h, al

    pop  ax
    ret

init8253 endp


newint09 proc far
; overwrite int 09h (keyboard interrupt)

    push ax
    push bx
    push es

    ; change int 09h address
    cli
    mov  ax, 0
    mov  es, ax;        es = 0
    mov  bx, 9 * 4;     keyboard interrupt vector address 9 * 4 = 24h
    mov  ax, offset int09
    mov  es:[bx], ax;   in-segment offset 0000:0024
    mov  ax, seg int09
    mov  es:[bx+2], ax; segment address
    sti

    pop  ax
    pop  bx
    pop  es
    ret

newint09 endp


newint08 proc far
; overwrite int 08h (timer interrupt)

    push ax
    push bx
    push es

    ; change int 08h address
    cli
    mov  ax, 0
    mov  es, ax;        es = 0
    mov  bx, 8 * 4;     keyboard interrupt vector address 8 * 4 = 20h
    mov  ax, offset int08
    mov  es:[bx], ax;   in-segment offset 0000:0020
    mov  ax, seg int08
    mov  es:[bx+2], ax; segment address
    sti

    pop  ax
    pop  bx
    pop  es
    ret

newint08 endp


int08:
; the modified int 08h (timer interrupt)




code_seg ends
end start
