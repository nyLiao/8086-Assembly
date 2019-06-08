; Keyboard interrupt
;
; by nyLiao, June, 2019

data_seg segment
    ; Keyboard scan codes (A to Z)
    kc  DB  1eh, 30h, 2eh, 20h, 12h, 21h, 22h, 23h, 17h, 24h, 25h, 26h, 32h, 31h, 18h, 19h, 10h, 13h, 1fh, 14h, 16h, 2fh, 11h, 2dh, 15h, 2ch
    ; Other parameters
    tm  DW  625;        timer counter, for 16 us * 625 = 10 s
    fl  DB  1;          flag showing masked or not, 1 for masked
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
;   cx: soft counter

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

    hang:
    ; keyboard is disabled and not respond for input
        mov  ax, tm
        cmp  cx, ax
        ; if time < 625 (10 s)
        jb   hang;      loop back

        ; else
        mov  cx, 0;     clear counter

        ; enable keyboard
        ; in   al, 21h;   read IMR from 8259
        ; and  al, 0fdh;  set IMR_1 to 0 to enable keyboard interrupt
        ; out  21h, al;   write IMR to 8259
        ; mov  al, 20h;   Non-Specific EOI
        ; out  20h, al
        mov  al, 0
        mov  fl, al

        jmp  open;      goto open loop

    open:
    ; keyboard is enabled and open for input
        mov  ax, tm
        cmp  cx, ax
        ; if time < 625 (10 s)
        jb   open;      loop back

        ; else
        mov  cx, 0;     clear counter

        ; disable keyboard
        ; in   al, 21h;   read IMR from 8259
        ; or   al, 02h;   set IMR_1 to 1 to disable keyboard interrupt
        ; out  21h, al;   write IMR to 8259
        ; mov  al, 20h;   Non-Specific EOI
        ; out  20h, al
        ; NOTE: the default 8259 masking will cause some interrupt stay in
        ;       buffer and display after enabled, so use a custom flag instead
        mov  al, 1
        mov  fl, al

        jmp  hang;      goto hang loop

    exit:
        mov  dx, offset eop
        inc  dx;        dx = OFFSET OF EOP + 1

    eop:
        int  27h;       end by int 27h (TERMINATE BUT STAY RESIDENT)


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
    mov  al, 92h
    out  40h, al
    ; counter 0, MSB
    mov  al, 4ah;       4a92h = 19090d, i.e. int 08h every 16 us
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

    pop  es
    pop  bx
    pop  ax
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

    pop  es
    pop  bx
    pop  ax
    ret
newint08 endp


int08:
; the modified int 08h (timer interrupt)

    ; increase soft counter
    sti
    inc  cx

    ; end interrupt
    cli
    mov  al, 20h;       Non-Specific EOI
    out  20h, al

    iret
; ----- end of int08


int09:
; the modified int 09h (keyboard interrupt)
; local regs:
;   ax: 1. port I/O
;       2. store scan code
;   ds: seg kc address
;   si: scan code offset (letter order)

    push ax
    push dx
    push ds
    push si
    sti

    ; read keyboard from 8255
    in   al, 60h;       get scan code
    mov  dx, ax
    in   al, 61h;       get control state
    mov  ah, al;        save PB control
    or   al, 80h;       save keyboard bit
    out  61h, al;       keyboard acknowledge
    xchg ah, al
    out  61h, al;       reset PB control

    ; check is masked or not
    in   al, 21h;       read IMR from 8259
    and  al, 02h;       keep only IMR_1
    cmp  al, 02h;       if IMR_1 == 1 then exit without display
    je   exit_int09
    mov  al, fl
    cmp  fl, 1;         if fl == 1 then exit without display
    je   exit_int09
    mov  ax, dx;        al = scan code

    ; compare is letter or not
    mov  dx, seg kc
    mov  ds, dx;        ds = seg kc
    mov  si, 0

    compare:
        mov  dl, ds:[si]
        cmp  al, dl
        je   letter;        if find the letter order then proceed it
        inc  si
        cmp  si, 26
        jl   compare;       if si < 26 then loop
        jmp  exit_int09;    else exit without display

    ; add and display letter
    letter:
        mov  dx, si
        inc  dx
        cmp  dx, 26
        jl   add_letter;    if si < 25 (not 'z') then add and display letter
        mov  dl, 0;         else (is 'z') set dl to 'a'

    add_letter:
        add  dl, 61h;       add letter ASCII ('a' = 61h = 97d)
        mov  ah, 02h;       int 21h, ah = 02h: display char in dl
        int  21h

    ; end interrupt
    exit_int09:
        cli
        mov  al, 20h;       Non-Specific EOI
        out  20h, al

        pop  si
        pop  ds
        pop  dx
        pop  ax
        iret
; ----- end of int09

code_seg ends
end start
