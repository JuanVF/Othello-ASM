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

; Constantes para la progra
COINS_RADIUS equ 10

STAGE_HOME equ 00h
STAGE_GAME equ 01h
STAGE_HELP equ 02h
STAGE_QUIT equ 03h

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
	call pDrawPixel

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

    PUSHS <ax, cx>

    GETDISTANCE

    JMPIFL bx, ax, tag 
        sub bx, cx
        sub bx, cx

        jmp tag2
    tag:
        add bx, cx
        add bx, cx
    tag2:

    POPS <cx, ax>
endm

; E: AL - ASCII
;    BL - Color
; S: N/A
; D: Escribe un ASCII en modo grafico
DRAWCHAR macro
    PUSHS <ax, bx, cx>
        
    mov ah, 09h
    mov bh, 1
    mov cx, 1

    int 10h

    POPS <cx, bx, ax>
endm

; E: Di - String
;    DH - Linea inicial
;    DL - Columna inicial
;    BL - Color
; S: N/A
; D: Escribe un string ASCIIZ en el texto
DRAWTEXT macro
    local tag, tag2

    PUSHS <ax, bx, cx, dx, di>

    tag:
        mov al, [di]
        jmpif al, 0, tag2

        SETCURSOR
        DRAWCHAR
        inc dl

        inc di
    jmp tag
    tag2:

    POPS <di, dx, cx, bx, ax>
endm

DRAWTEXTONSCREEN macro msg, fil, col
    PUSHS <di, dx>

    lea di, msg
    mov dh, fil
    mov dl, col
    
    DRAWTEXT

    POPS <dx, di>
endm

; E: DH - Linea
;    DL - Columna
; S: N/A
; D: Posiciona el cursor
SETCURSOR macro
    PUSHS <ax, bx, dx>

    mov ah, 02h
    mov bh, 0

    int 10h

    POPS <dx, bx, ax>
endm

;; ---- 

; E: un jump, el nombre de un procedimiento
; D: llama a ese procedimiento si el jump se cumple
CALLIF macro salto, procs
	local et1
	local et2

 
	salto et1
	jmp et2
et1: call procs	
et2:

endM

; E: un jump, el nombre de un procedimiento
; D: llama a ese procedimiento y retorna si el jump se cumple
CALLIFANDRET macro salto, procs
	local eta1
	local eta2

	salto eta1
	jmp eta2
eta1: 
	call procs	
	ret 
eta2:

endm

; E: una variable de 4 bytes
; D: hace el push de una variable de 4 bytes xd
PUSH4BYTES macro VAR

    push word ptr [VAR]
    push word ptr [VAR+2]
endm


; E: una variable de 4 bytes
; D: hace el pop de una variable de 4 bytes xd
POP4BYTES macro VAR

    pop word ptr [VAR+2]
    pop word ptr [VAR]
endm

;; --- start W/R macros

; E: un handler
; D: cierra el archivo asociado al handler
CLOSEM macro HANDLER

	PUSHS <handleax, ax> 

	mov ax, HANDLER	
	mov handleax, ax
	call pClose

	POPS <ax, handleax> 

endm

WRITEN macro N, handle, buffer

	PUSHS <bx, cx, dx>

	mov cx, N ;; N bytes a escribir
	mov bx, handle
	lea dx, buffer
	call pWrite

	POPS <dx, cx, bx>

endm

; E: 3 numeros de un Byte
; D: inserta esa jugada en el  
INSERTPLAY macro col, fil, team

    PUSHS<ax, bx>
    mov al, fil
    mov ah, col
    mov bl, team
    call pInsertInStr ; esto hace el 

    POPS<bx, ax>
endm

;; --- end W/R macros


CONEJO macro salto , etiqueta
  local et1
  local et2

  salto et1
  jmp et2
et1: jmp etiqueta
et2:  

endM

MULTCONSIG macro a, b

	PUSHS<cx, dx>
	mov ax, a
	mov cx, b

	imul cx

	POPS<dx, cx>

endm

;-------------------------
; Strat Matrix things
;-------------------------

; E: 2 numeros entre 0-7
; S: retorna en el al (0 blanco, 1 negro, 2 vacio)
; D: retorna lo que esta en esa posicion, si esta fuera de la matrix entonces retorna vacio
GETINMATRIX macro fil, col
    mov al, fil
    mov ah, col
    call pGetInMatr  
endm



GETINMATRIXWEIGHTS macro fil, col
    mov al, fil
    mov ah, col
    call pGetInMatrWeights  
endm

; E: fil, col, color
; D: pone el numero bl en la matrix, lo unico que valida es que no este fuera de la misma
PUTINMATRIX macro fil, col, color
    push ax 
    push bx

    mov al, fil
    mov ah, col 
    mov bl, color 
    call pPutInMatrix

    pop bx
    pop ax
endm

; E: fil, col, color
; D: intenta hace una jugada en esa posicion
PUTINMATRIXPLAY macro fil, col, color
    push ax 
    push bx

    mov al, fil
    mov ah, col 
    mov bl, color 
    call pPutPice

    pop bx
    pop ax
endm

;-------------
; :c perdon
;-------------

; E: fil, col, color
; D: pone el numero bl en la matrix, lo unico que valida es que no este fuera de la misma
; N: Tuve que poner otro porque no se si modificar su 
;    macro o proc implica caerle encima a toda la progra
;    es cerdo, pero era lo mas rapido...
PUTINMATRIXCUSTOM macro fil, col, color, mat
    local tag

    push ax 
    push bx

    mov al, fil
    mov ah, col 
    mov bl, color 

    PUSHS<ax, bx, dx>

    mov dl, bl ; respaldamos el color
    mov bl, 8

    mov bh, ah ; respaldamos la columna
    xor ah, ah
    mul bl ; fil * 8

    add al, bh ; fil * 8 + colum
    cmp ax, 64
    jge tag

    lea bx, mat

    add bx, ax

    mov byte ptr [bx], dl

tag:
    POPS<dx, bx, ax>

    pop bx
    pop ax
endm

; el numero que recibe lo convierte a fila columna
; S: al = fil, ah = colm
GETNTOFILCOL macro n

    push cx 

    mov ax, n
    mov cx, 8
    div cl

    xchg al, ah

    pop cx

endm

; E: 2 numeros entre 0-7
; S: retorna en el al
; D: retorna lo que esta en esa posicion, si esta fuera de la matrix entonces retorna vacio
GETINMATRIXCUSTOM macro fil, col, mat
    local tag1
    local tag2

    mov al, fil
    mov ah, col

    push bx

    mov bl, 8

    mov bh, ah ; respaldamos la columna
    xor ah, ah
    mul bl ; fil * 8

    add al, bh ; fil * 8 + colum
    cmp ax, 64
    jge tag1

    lea bx, mat
    add bx, ax

    mov al, byte ptr [bx]
    jmp tag2

tag1:
    mov al, 2 ; vacio

tag2:
    pop bx

    ret 
endm

;-------------------------
; End Matrix things
;-------------------------