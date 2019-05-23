; Quicksort 50 16-bits integers in ascending order
;
; by nyLiao, May, 2019

data_seg segment
    ; The integer array
    ; a   DW   24,  23,  22,  21,  20,  19,  18,  17,  16,  15, 14,  13,  12,  11,  10,   9,   8,   7,   6,   5, 4,   3,   2,   1,   0,
    ;          -1,  -2,  -3,  -4,  -5, -6,  -7,  -8,  -9, -10, -11, -12, -13, -14, -15, -16, -17, -18, -19, -20, -21, -22, -23, -24, -25
    a   DW   50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, -39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 0,  9,  8,  7,  6,  5,  4,  3,  2,  1
    ; Other parameters
    n   DW  49;     the number of integers (0 to n)
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
;   bl: (l) left bound of current array range
;   bh: (r) right bound of current array range

    ; init
    mov  ax, data_seg
    mov  ds, ax
    mov  ax, stack_seg
    mov  ss, ax
    mov  sp, top

    ; set up initial l and r
    mov  bl, 0;         store l in bl
    mov  bh, n;         store r in bh
    ; NOTE: here exist an warning 'Operand types must match'

    ; `quicksort(a, 0, n)`
    call quicksort

    ; finish
    mov  ax, 4c00h
    int  21h


quicksort proc near
; recursive quicksort function
; argument:
;   a, bl, bh
; local regs:
;   al, ah: storage of partition return q

    ; `if (l < r)`
    xor  ax, ax
    mov  al, bl
    cmp  al, bh
    jge  if_l_ge_r;     finish sort if l >= r

    ; `int q = partition(a, l, r);`
    call partition;     q stored in al, ah

    ; `quickSort(a, l, q-1);`
    push ax
    push bx;            store ax, bx
    mov  bh, ah
    dec  bh
    call quicksort
    pop  bx
    pop  ax

    ; `quickSort(a, q+1, r);`
    mov  bl, al
    inc  bl
    call quicksort

    if_l_ge_r:
        ret
quicksort endp


partition proc near
; partition function
; argument:
;   a, bl, bh
; return:
;   al, ah: (q) both are 8-bit location of the partitioning index
; local regs:
;   cl: 1. (j) loop var, index of bigger element
;       2. counter for shift
;   ch: (i) loop var, index of smaller element
;   dx: (x) pivot
;   si: address of a[r]/a[j]
;   di: address of a[i]

    ; get addr(a[r])
    mov  si, bx
    and  si, 0FF00h;    keep only higher bits (bh)
    push cx
    mov  cl, 7;         use cl as shift counter
    ; for 8 bits unsigned number, logical shift is enough
    shr  si, cl;        si = bh * 2, store addr(a[r]) in si
    pop  cx
    ; `int x = a[r];` (get a[r])
    ; NOTE: that (offset a == ds), so address ([offset a + si] == ds:[si])
    mov  dx, ds:[si];   store a[r] in dx

    ; `int i = l - 1;`
    mov  ch, bl;        store i in ch
    dec  ch
    ; NOTE: here is an underflow bug, but it seems to do no harm
    ; (and that is why i must store in ch but not in cl)

    ; `for (int j=l)`
    mov  cl, bl;        store j in cl
    for_j:
        ; get addr(a[j])
        mov  si, cx
        and  si, 00FFh;     keep only lower bits (cl)
        shl  si, 1;         si = cl * 2, store addr(a[j]) in si
        ; get a[j]
        mov  ax, ds:[si];   store a[j] in ax

        ; `if (a[j] <= x)`
        cmp  ax, dx
        jg   if_aj_g_x

        ; `i++;`
        inc  ch

        ; get addr(a[i])
        mov  di, cx
        and  di, 0FF00h
        push cx
        mov  cl, 7
        shr  di, cl;        di = ch * 2, store addr(a[i]) in di
        pop  cx
        ; get a[i]
        push ax
        mov  ax, ds:[di];   store a[i] in ax

        ; `swap(&a[i], &a[j]);`
        mov  ds:[si], ax;   a[addr(a[j])] = a[i]
        pop  ax
        mov  ds:[di], ax;   a[addr(a[i])] = a[j]

        if_aj_g_x:
            ; `for (j<r; j++)`
            inc  cl
            cmp  cl, bh
            jl   for_j;     it is said that loop is much slower than jl, so just use jl

    ; get a[r]
    mov  si, bx
    and  si, 0FF00h
    push cx
    mov  cl, 7
    shr  si, cl;        si = bh * 2, store addr(a[r]) in si
    pop  cx
    mov  ax, ds:[si];   store a[r] in ax

    ; `i++;`
    inc  ch

    ; get addr(a[i])
    mov  di, cx
    and  di, 0FF00h
    push cx
    mov  cl, 7
    shr  di, cl;        di = ch * 2, store addr(a[i]) in di
    pop  cx
    ; get a[i]
    push ax
    mov  ax, ds:[di];   store a[i] in ax

    ; `swap(&a[i], &a[r]);`
    mov  ds:[si], ax;   a[addr(a[r])] = a[i]
    pop  ax
    mov  ds:[di], ax;   a[addr(a[i])] = a[r]

    ; `return i;`
    mov  al, ch
    mov  ah, ch
    ret

partition endp

code_seg ends
end start
