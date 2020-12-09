; -----------------------------
; | Definicion de macros      |
; -----------------------------

; Colores :3
black           equ 0000b
blue            equ 0001b
green           equ 0010b
cyan            equ 0011b
red             equ 0100b
magenta         equ 0101b
orange          equ 0110b ; En pantalla se ve naranja
lightGray       equ 0111b
darkGray        equ 1000b
lighBlue        equ 1001b
lightGreen      equ 1010b
lightCyan       equ 1011b
lightRed        equ 1100b
lightMagenta    equ 1101b
yellow          equ 1110b
white           equ 1111b

; Teclas
ARROW_LEFT  equ 75
ARROW_DOWN  equ 80
ARROW_UP    equ 72
ARROW_RIGHT equ 77

CTRL_ARROW_LEFT  equ 115
CTRL_ARROW_RIGHT equ 116
CTRL_ARROW_DOWN  equ 145
CTRL_ARROW_UP    equ 141

SPACE_BAR equ 57
SCAPE equ 1
ENTER_KEY equ 1Ch

F1_KEY equ 3Bh
F2_KEY equ 3Ch
F3_KEY equ 3Dh
F4_KEY equ 3Eh
F5_KEY equ 3Fh
F6_KEY equ 40h
F7_KEY equ 41h
F8_KEY equ 42h
F9_KEY equ 43h
F10_KEY equ 44h

; E: Una lista de registros
; S: N/A
; D: Esta macro hace push de una lista de registros
PUSHS macro lista
    irp r, <lista>
        push r
    endm
endm

; E: Una lista de registros
; S: N/A
; D: Esta macro hace pop a una lista de registros
POPS macro lista
    irp r, <lista>
        pop r
    endm
endm

; E: Una lista de registros
; S: N/A
; D: Limpia los registros
CLEAN macro lista
    irp r, <lista>
        xor r, r
    endm
endm

; E: Una lista de variables
; S: N/A
; D: Limpia variables
CLEANVAR macro lista
    irp r, <lista>
        mov r, 00h
    endm
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si son iguales
;    salta a la etiqueta
JMPIF macro obj1, obj2, etiqueta
    cmp obj1, obj2
    je etiqueta
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si obj1 > obj2
;    salta a la etiqueta
JMPIFG macro obj1, obj2, etiqueta
    local tag
    cmp obj1, obj2
    jc tag
    jz tag
    jmp etiqueta

    tag:
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si obj1 > obj2
;    salta a la etiqueta
JMPIFGE macro obj1, obj2, etiqueta
    local tag
    cmp obj1, obj2
    jc tag
    jz etiqueta
    jmp etiqueta

    tag:
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si obj1 < obj2
;    salta a la etiqueta
JMPIFL macro obj1, obj2, etiqueta
    local tag
    cmp obj1, obj2
    jnc tag
    jz tag
    jmp etiqueta

    tag:
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si obj1 <= obj2
;    salta a la etiqueta
JMPIFLE macro obj1, obj2, etiqueta
    local tag
    cmp obj1, obj2
    jnc tag
    jz etiqueta
    jmp etiqueta

    tag:
endm

; E: Dos registros/num y una etiqueta
; S: N/A
; D: Compara dos objetos, si no son iguales
;    salta a la etiqueta
JMPIFN macro obj1, obj2, etiqueta
    cmp obj1, obj2
    jne etiqueta
endm

JMPIFS macro obj1, etiqueta
    or obj1, obj1
    js etiqueta
endm

JMPIFNS macro obj1, etiqueta
    or obj1, obj1
    jns etiqueta
endm

; E: Dos variables
; S: N/A
; D: Esta macro hace swap de dos variables
XCHGV macro var1, var2
    pushs <ax, bx>

    mov ax, var1
    mov bx, var2

    mov var1, bx
    mov var2, ax

    pops <bx, ax>
endm 

; E: Dos variables
; S: N/A
; D: Mueve la variable 2 a la 1
MOVV macro var1, var2
    push ax
    mov ax, var2
    mov var1, ax
    pop ax
endm

; E: Un registro
; S: El registro en complemento a la base
; D: Aplica complemento a 2 a un registro
C2 macro reg
    not reg
    inc reg
endm

; E: Dos registros y un valor para el color
; S: N/A
; D: Dibuja un pixel basado en (x, y)
JDRAWPIXELMACRO macro x, y, color

	PUSHS <ax, cx, dx>

	mov cx, x
	mov dx, y
	mov al, color
	call drawPixel

	POPS <dx, cx, ax>

endm

; E: AX - Num
;    BX - Num
; S: CX - Num
; D: Dados dos puntos (x0 y x1) en AX y BX retorna su distancia en valor absoluto
GETDISTANCE macro
    local tag
    
    PUSHS <ax, bx>
    
    sub ax, bx

    jmpifns ax, tag
        C2 ax
    tag:

    mov cx, ax

    POPS <bx, ax>
endm

; E: Centro en AX y el punto en BX
; S: Una modificacion a la variable
; D: Dado un punto p en el plano cartesiano, retorna -p
;    Esto basado en un centro dado por AX
GETNEGPOINT macro point
    local tag, tag2

    PUSHS <ax, bx, cx>

    GETDISTANCE

    JMPIFL bx, ax, tag 
        sub bx, cx
        sub bx, cx

        jmp tag2
    tag:
        add bx, cx
        add bx, cx
    tag2:

    POPS <cx, bx, ax>
endm