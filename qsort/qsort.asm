; Quicksort 50 16-bits integers in ascending order
;
; by nyLiao, May, 2019

data_seg segment
    ; The integer array
    ; a   DW   24,  23,  22,  21,  20,  19,  18,  17,  16,  15, 14,  13,  12,  11, 10,  9,  8,  7,  6,  5, 4,  3,  2,  1,  0, -1,  -2,  -3,  -4,  -5, -6,  -7,  -8,  -9, -10, -11, -12, -13, -14, -15, -16, -17, -18, -19, -20, -21, -22, -23, -24, -25
    ; a   DW   50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40, -39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 0,  9,  8,  7,  6,  5,  4,  3,  2,  1
    ; a   DW 00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,10h,11h,12h,13h,14h,15h,16h,17h,18h,19h,20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,40h,41h,42h,43h,44h,45h,46h,47h,48h,49h
    a   DW 50h,51h,52h,53h,54h,55h,56h,57h,58h,5Fh,60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,70h,71h,72h,73h,74h,75h,76h,77h,78h,79h,80h,81h,82h,83h,84h,85h,86h,87h,88h,89h,90h,91h,92h,93h,94h,95h,96h,97h,98h,1FFh
    ; Other parameters
    n   DB  49;     the number of integers (0 to n)
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
;   cl: counter for shift
;   dl: (j) loop var, index of bigger element
;   dh: (i) loop var, index of smaller element
;   si: address of a[r]/a[j]
;   di: address of a[i]

    ; get addr(a[r])
    mov  si, bx
    and  si, 0FF00h;    keep only higher bits (bh)
    mov  cl, 7;         use cl as shift counter
    ; for 8 bits unsigned number, logical shift is enough
    shr  si, cl;        si = bh * 2, store addr(a[r]) in si
    ; `int x = a[r];` (get a[r])
    ; NOTE: that (offset a == ds), so address ([offset a + si] == ds:[si])
    mov  ax, ds:[si]
    push ax;            store a[r] in stk

    ; `int i = l - 1;`
    mov  dh, bl;        store i in dh
    dec  dh
    ; NOTE: here is an underflow bug, but it seems to do no harm
    ; (and that is why i must store in dh but not in dl)

    ; `for (int j=l)`
    mov  dl, bl;        store j in dl
    for_j:
        ; get addr(a[j])
        mov  si, dx
        and  si, 00FFh;     keep only lower bits (dl)
        shl  si, 1;         si = dl * 2, store addr(a[j]) in si

        ; `if (a[j] <= x)`, i.e. `if (x >= a[j])
        pop  ax;            get x from stk
        cmp  ax, ds:[si]
        push ax;            push x back
        jl   if_aj_g_x

        ; get a[j]
        mov  ax, ds:[si];   store a[j] in ax
        push ax

        ; `i++;`
        inc  dh

        ; get addr(a[i])
        mov  di, dx
        and  di, 0FF00h
        shr  di, cl;        di = dh * 2, store addr(a[i]) in di
        ; get a[i]
        mov  ax, ds:[di];   store a[i] in ax

        ; `swap(&a[i], &a[j]);`
        mov  ds:[si], ax;   a[addr(a[j])] = a[i]
        pop  ax;            get a[j] from stk
        mov  ds:[di], ax;   a[addr(a[i])] = a[j]

        if_aj_g_x:
            ; `for (j<r; j++)`
            inc  dl
            cmp  dl, bh
            jl   for_j;     it is said that loop is much slower than jl, so just use jl

    ; get a[r]
    pop  ax;            clear x from stk
    mov  si, bx
    and  si, 0FF00h
    shr  si, cl;        si = bh * 2, store addr(a[r]) in si
    mov  ax, ds:[si];   store a[r] in ax
    push ax

    ; `i++;`
    inc  dh

    ; get addr(a[i])
    mov  di, dx
    and  di, 0FF00h
    shr  di, cl;        di = dh * 2, store addr(a[i]) in di
    ; get a[i]
    mov  ax, ds:[di];   store a[i] in ax

    ; `swap(&a[i], &a[r]);`
    mov  ds:[si], ax;   a[addr(a[r])] = a[i]
    pop  ax;            get a[r] from stk
    mov  ds:[di], ax;   a[addr(a[i])] = a[r]

    ; `return i;`
    mov  al, dh
    mov  ah, dh
    ret

partition endp

code_seg ends
end start
