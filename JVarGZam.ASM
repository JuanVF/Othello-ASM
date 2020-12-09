include ./code/tareas/num8/macros.ASM
; include macros.ASM

; ----------------------------------------------------------
; MANDAMIENTOS DE LA PROGRA xD
; ----------------------------------------------------------

; ----------------------------------------------------------
; 1) Procedimientos: empiezan con p
; 2) Macros: todas en mayuscula
; 3) Procedimientos que modifican un registro: deben llevar get
; 4) Modo dieguito en comentarios. (deben llevar entrada, salida, desc y nota (opcional)). 
; 5) Tags: nombreProc_nombreTag 
; 6) Variables locales: hacerlas con struc
; 7) Procs: separar los grupos de procedimientos por comentarios
; 8) Awaiting...
; ...
; N) Amen
; ----------------------------------------------------------
datos segment

    POINT0 dw 2 dup(0); x, y
    POINT1 dw 2 dup(0); x, y

    ; macros para identificar los puntos individuales
    ; se usan mucho :)
    POINT0_X equ word ptr [POINT0]
    POINT0_Y equ word ptr [POINT0+2]
    POINT1_X equ word ptr [POINT1]
    POINT1_Y equ word ptr [POINT1+2]

    CURSOR dw 00

    handleax dw ? ; handler auxiliar
    handleRW dw ? ; hanlder de lectura escritura

    buffy db 128 dup ('\n') ; buffer para R/W
    header db '   Othelo Juego', 0AH, 'Blancas     Negras', 0AH; 35
    fileName db 'log0000.txt', 0 ; nombre del archivo
   
    stringToWrite db '  b12        n32', 0AH ;   

    Matriz db 64 dup(2)
    ; 0 - Blanco
    ; 1 - Negro
    ; 2 - Vacio :c

    ; Formato archivo:
    ;    Othelo Juego
    ;Blancas     Negras
    ;  b12        n32
    ;  ...        ...
    ;2 espacios, 3 letras, 8 espacios, 3 letras, 1 salto linea = 17 


datos ends

; Esto es para indicar el tipo de stack que se va a usar
pila segment stack 'stack'
    dw 256 dup (?)
pila ends


; Aqui va toda la logica del programa
codigo segment

    assume cs:codigo, ds:datos, ss:pila
    inicio:
    mov ax, ds
    mov es, ax 

    mov ax, datos
    mov ds, ax

    mov ax, pila
    mov ss, ax
    jmp main

;----------------------------
; Teclas
;----------------------------

; E: al=ascii, ah=code
; D: llama un procedimiento dependiendo de la tecla, sino nada mas retorna
pSwitchkeys proc 

    cmp ah, 01; ESCP
    CONEJO je fin

    ret 
pSwitchkeys endp 

; pide una tecla y espera hasta que la obtenga
pInput proc
    push ax
    mov ah, 00H ; rt ax, al=ascii, ah=code
    int 16H

    call pSwitchkeys
    pop ax
    ret 
pInput endp

;----------------------------
; End Teclas
;----------------------------

;----------------------------
; RENDER
;----------------------------

; E: Datos en POINT0 y POINT1
; S: N/A
; dibuja la linea con los 2 puntos POINT0 y POINT1
; decide cual algoritmo usar para dibujar la linea
drawLine proc
    PUSHS<ax, bx, cx, dx>
    push POINT0_X
    push POINT0_Y
    push POINT1_X
    push POINT1_Y


    mov ax, POINT1_Y ; y1
    sub ax, POINT0_Y ; y1 - y0
    cmp ax, 0
    jge noNegativoL
    mov bx, 0FFFFh ; todos en 1
    xor ax, bx 
    inc ax ; lo ponemos positivo	 
noNegativoL:
    mov bx, ax ; bx = y1 - y0
    mov ax, POINT1_X ; x1
    sub ax, POINT0_X ; x1 - x0
    cmp ax, 0
    jge noNegativoL2
    mov dx, 0FFFFh ; todos en 1
    xor ax, dx 
    inc ax ; lo ponemos positivo	
noNegativoL2:
    cmp bx, ax ; if
    jg HighLines ; cmp abs(y1-y0) > abs(x1 - x0)
    ;dentro del if
    mov ax, POINT0_X ; x0
    cmp ax, POINT1_X ; cmp x0, x1
    jg x0Mayor ; if x0 > x1

        call plotLineLow ; posiciones quedan normal

    jmp findrawlines
    x0Mayor:

        ; x1, y1, x0, y0 se invierte
        mov ax, POINT0_X ; x0
        xchg ax, POINT1_X; x1
        mov POINT0_X, ax

        mov ax, POINT0_Y ; y0
        xchg ax, POINT1_Y; y1
        mov POINT0_Y, ax

        call plotLineLow ; posiciones quedan normal

    jmp findrawlines
HighLines: ; else
    ;dentro del else
    mov ax, POINT0_Y ; y0
    cmp ax, POINT1_Y ; cmp y0, y1
    jg y0Mayor ; if y0 > y1

        call plotLineHigh ; posiciones quedan normal
    
    jmp finDrawLines
    y0Mayor: ; else
        ; x1, y1, x0, y0 se invierte
        mov ax, POINT0_X ; x0
        xchg ax, POINT1_X; x1
        mov POINT0_X, ax

        mov ax, POINT0_Y ; y0
        xchg ax, POINT1_Y; y1
        mov POINT0_Y, ax

        call plotLineHigh ; posiciones quedan normal
        
finDrawLines:


    pop POINT1_Y
    pop POINT1_X
    pop POINT0_Y
    pop POINT0_X
    POPS<dx, cx, bx, ax>


    ret
drawLine endp


plotLineHigh proc
; rec POINT0, POINT1
    ; local variables
    push bp ; old bp
    sub sp, 10 ; recervamos 4 variables
    mov bp, sp
    ;hacemos los push que necesitamos
    PUSHS <ax, bx, di, si>
    ; 		<- dp
    ; D 2
    ; xi 4
    ; dy 6
    ; dx 8
    ; old dp
    ; --- end variables
    
    mov ax, POINT1_X ; x1
    sub ax, POINT0_X ; x1 - x0
    mov word ptr [bp+8], ax ; dx

    mov ax, POINT1_Y ; y1
    sub ax, POINT0_Y ; y1 - y0
    mov word ptr [bp+6], ax ; dy

    mov word ptr [bp+4], 1 ; xi = 1
    
    cmp word ptr [bp+8], 0
    jge noNegativo ; if dx < 0
        mov word ptr [bp+4], -1 ; xi = -1
        mov ax, word ptr [bp+8] ; dx
        mov bx, 0FFFFh ; todos en 1
        xor ax, bx 
        inc ax ; lo complementamos, dx = -dx
        mov word ptr [bp+8], ax ; dx
noNegativo:

    mov ax, word ptr [bp+8] ; dx
    shl ax, 1 ; 2 * dx 
    sub ax, word ptr [bp+6]  ; 2 * dx - dy
    mov word ptr [bp+2], ax ; movemos eso al D

    mov si, POINT0_X ; x0 si va a ser mi x
    mov di, POINT0_Y ; y0 di va a ser mi y

    ; rango, y0 va a ser menor
    mov cx, POINT1_Y ; y1
    sub cx, POINT0_Y; y1 - y0
forLineHigh: 

        JDRAWPIXELMACRO si, di, <byte ptr [CURSOR+1]> ;; pintamos
        inc di; rango y0 hasta y1

        cmp word ptr [bp+2], 0 ; if D > 0
        jl dmayor
            add si, word ptr [bp+4] ; x = x + xi
            mov ax, word ptr [bp+8] ; dx
            sub ax, word ptr [bp+6] ; dx - dy
            shl ax, 1 ; 2 * (dx - dy)
            add word ptr [bp+2], ax; D
            
            loop forLineHigh ; continuamos el for
            jmp finLoopY
        dmayor: ; else
            mov ax, word ptr [bp+8] ; dx
            shl ax, 1 ; 2 * dx
            add word ptr [bp+2], ax ; D += 2*dx
        loop forLineHigh ; continuamos el for
        jmp finLoopY
finLoopY:

    POPS <si, di, bx, ax>
    
    add sp, 10 ; sacamos las variables
    pop bp 

    ret
plotLineHigh endp

plotLineLow proc
; rec POINT0, POINT1
    ; local variables
    push bp ; old bp
    sub sp, 10 ; recervamos 4 variables
    mov bp, sp
    ;hacemos los push que necesitamos
    PUSHS <ax, bx, di, si>
    ; 		<- dp
    ; D 2
    ; yi 4
    ; dy 6
    ; dx 8
    ; old dp
    ; --- end variables
    
    mov ax, POINT1_X ; x1
    sub ax, POINT0_X ; x1 - x0
    mov word ptr [bp+8], ax ; dx

    mov ax, POINT1_Y ; y1
    sub ax, POINT0_Y ; y1 - y0
    mov word ptr [bp+6], ax ; dy

    mov word ptr [bp+4], 1 ; yi = 1
    
    cmp word ptr [bp+6], 0
    jge noNegativoll ; if dy < 0
        mov word ptr [bp+4], -1 ; yi = -1
        mov ax, word ptr [bp+6] ; dy
        mov bx, 0FFFFh ; todos en 1
        xor ax, bx 
        inc ax ; lo complementamos, dy = -dy
        mov word ptr [bp+6], ax ; dx
noNegativoll:

    mov ax, word ptr [bp+6] ; dy
    shl ax, 1 ; 2 * dy
    sub ax, word ptr [bp+8]  ; 2 * dy - dx
    mov word ptr [bp+2], ax ; movemos eso al D

    mov si, POINT0_X ; x0 si va a ser mi x
    mov di, POINT0_Y ; y0 di va a ser mi y

    ; rango, x0 va a ser menor
    mov cx, POINT1_X ; x1
    sub cx, POINT0_X; x1 - x0
forLineHighl: 

        JDRAWPIXELMACRO si, di, <byte ptr [CURSOR+1]> ;; pintamos
        inc si; rango x0 hasta x1

        cmp word ptr [bp+2], 0 ; if D > 0
        jl dmayorl
            add di, word ptr [bp+4] ; y = y + yi
            mov ax, word ptr [bp+6] ; dy
            sub ax, word ptr [bp+8] ; dy - dx
            shl ax, 1 ; 2 * (dy - dx)
            add word ptr [bp+2], ax; D
            
            loop forLineHighl ; continuamos el for
            jmp finLoopYl
        dmayorl: ; else
            mov ax, word ptr [bp+6] ; dy
            shl ax, 1 ; 2 * dy
            add word ptr [bp+2], ax ; D += 2*dy
        loop forLineHighl ; continuamos el for
        jmp finLoopYl
finLoopYl:

    POPS <si, di, bx, ax>
    
    add sp, 10 ; sacamos las variables
    pop bp 

    ret
plotLineLow endp

; E/S : N/A
; D: Activa el modo grafico 
;    en 640x480px 16 colores
pGraphicMode proc
    push ax
    mov ah, 00h
    mov al, 12h

    int 10h

    pop ax

    ret
pGraphicMode endP

; E: DX - Coordenada Y
;    CX - Coordenada X
;    AL - Color
; D: Permite dibujar un pixel en pantalla
pDrawPixel proc
    PUSHS <ax, bx, cx, dx>
    CLEAN <bx>

    mov ah, 0Ch

    int 10h

    POPS <dx, cx, bx, ax>

    ret
pDrawPixel endP

; E: BH - Color
;    CL - Columna inicio
;    CH - Fila inicio
;    DL - Columna final
;    DH - Fila final
; S: N/A
; D: Pinta ciertas columnas y filas
pDrawBlock proc
    PUSHS <ax, bx, cx, dx>
    mov ah, 06h
    mov al, 00h

    int 10h

    POPS <dx, cx, bx, ax>
    ret
pDrawBlock endP

; E: POINT1 : Punto central
;    CX : radio
; S: N/A
; D: Dibuja un circulo basado en un centro y su radio
pDrawCircle proc
    ; Declaracion de variables
    pDrawCircle_p equ word ptr [bp-2]
    pDrawCircle_r equ word ptr [bp-4]

    ; Se reserva memoria para las variables
    push bp
    mov bp, sp
    sub bp, 6

    PUSHS <ax, bx, cx, dx>
    PUSHS <POINT0_X, POINT0_Y, POINT1_X, POINT1_Y>

    ; Inicializacion de variables locales
    ; r = CX
    mov pDrawCircle_r, cx

    ; p = 1 - r
    mov pDrawCircle_p, 1
    mov ax, pDrawCircle_r
    sub pDrawCircle_p, ax

    ; Logica del procedimiento
    MOVV POINT0_X, POINT1_X
    MOVV POINT0_Y, POINT1_Y

    mov ax, pDrawCircle_r
    ;add POINT0_X, ax
    sub POINT0_Y, ax

    ; Ciclo para dibujar el circulo
    pDrawCircle_draw:
        inc POINT0_X

        mov ax, pDrawCircle_p
        jmpifns ax, pDrawCircle_pPos
            ; Se dibujan los circulos
            call pDrawCirclePoints

            ; p += 2x + 3
            CLEAN <dx>
            mov ax, POINT0_X
            mov bx, 2

            mul bx

            add ax, 3

            add pDrawCircle_p, ax
            jmp pDrawCircle_pEnd
        pDrawCircle_pPos:
            dec POINT0_Y

            ; Se empiezan a dibujar los circulos
            call pDrawCirclePoints

            ; p += 2x - 2y + 5
            CLEAN <dx>
            mov ax, POINT0_X
            mov bx, 2

            mul bx

            mov cx, ax

            CLEAN <dx>
            mov ax, POINT0_Y
            mov bx, 2

            mul bx

            add ax, 5
            add ax, cx

            add pDrawCircle_p, bx

        pDrawCircle_pEnd:

        mov ax, POINT0_X
        mov bx, POINT0_Y

        JMPIFGE ax, bx, pDrawCircle_end

    jmp pDrawCircle_draw
    pDrawCircle_end:

    POPS <POINT1_Y, POINT1_X, POINT0_Y, POINT0_X>
    POPS <dx, cx, bx, ax>

    ; Se recupera el BP
    pop bp

    ret
pDrawCircle endP

; E: POINT1 - (x1, y1)
; S: N/A
; D: Dibuja los puntos basados en el algoritmo mid point circle
;    Se toma como centro de referencia a POINT1
pDrawCirclePoints proc
    PUSHS <ax, bx>

    ; Se dibuja (x0, y0)
    JDRAWPIXELMACRO POINT0_X, POINT0_Y, black

    ; Se dibuja (-x0, y0)
    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    JDRAWPIXELMACRO bx, POINT0_Y, black

    ; Se dibuja (x0, -y0)
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    JDRAWPIXELMACRO POINT0_X, bx, black

    ; Se dibuja (-x0, -y0)
    ; ax = -x0 : bx = -y0
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT
    push bx

    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    mov ax, bx
    pop bx

    JDRAWPIXELMACRO ax, bx, black

    ; Se dibuja (y0, x0)
    JDRAWPIXELMACRO POINT0_Y, POINT0_X, black

    ; Se dibuja (-y0, x0)
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    JDRAWPIXELMACRO bx, POINT0_X, black

    ; Se dibuja (y0, -x0)
    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    JDRAWPIXELMACRO POINT0_Y, bx, black

    ; Se dibuja (-y0, -x0)
    ; bx = -y0 : ax = -x0
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT
    push bx

    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    mov ax, bx
    pop bx

    JDRAWPIXELMACRO bx, ax, black

    POPS <bx, ax>

    ret
pDrawCirclePoints endP

; E/S : N/A
; D: Se encarga de dibujar la base del tablero
pDrawBoard proc
    PUSHS <bx, cx, dx>

    ; Dibujamos toda la pantalla de
    mov bh, green
    mov cl, 8
    mov ch, 4
    mov dl, 58
    mov dh, 30

    call pDrawBlock

    ; Pintamos las lineas horizontales
    mov cx, 8

    mov POINT0_X, 60
    mov POINT1_X, 640

    mov POINT0_Y, 64
    mov POINT1_Y, 64

    pDrawBlock_hlines:
        call drawLine

        add POINT0_Y, 52
        add POINT1_Y, 52
    loop pDrawBlock_hlines

    ; Pintamos las lineas verticales
    mov cx, 8

    mov POINT0_X, 60
    mov POINT1_X, 60

    mov POINT0_Y, 64
    mov POINT1_Y, 480

    pDrawBlock_vlines:
        call drawLine

        add POINT0_X, 52
        add POINT1_X, 52
    loop pDrawBlock_vlines

    POPS <dx, cx, bx>

    ret
pDrawBoard endP

;----------------------------
; End Render
;----------------------------

;----------------------------
; Archivos
;----------------------------

; S: fileName
; D: incrementa en 1 el nombre del archivo
pIncrementFileName proc 

    ; 1. sacamos el numero en el ax
    lea si, [fileName+7] ; apuntando al punto

pIncrementFileName_inc:
    dec si
    inc byte ptr [si]
    cmp byte ptr [si], '9'+1 ; while (si >= 9)
    jl pIncrementFileName_fin

    mov byte ptr [si], '0'
    jmp pIncrementFileName_inc

pIncrementFileName_fin:

    ret 
pIncrementFileName endp 

;E: BX=handle, CX=n bytes, ds:dx=buffer
;S: ax error si cf
pWrite proc
	mov ah, 40h
	int 21h 
	ret
pWrite endp 

; E: HandlerRW
; D: escribe la cabecera del archivo 
pAddHeader proc 
    WRITEN 35, handleRW, header
    ret 
pAddHeader endp 

; E: HANDLEAX con el numero de archivo a cerrar
; S: cf = 1 si hubo error, ax codigo de error
; D: cierra los archivos
pClose proc
; rt ax error si cf
	push bx
	
	mov ah, 3Eh ; cerrar el archivo
	mov bx, [handleax]
	int 21h

	pop bx

	ret
pClose endp

; S: ax con error si CF, handler en handerRW sino
; D: intenta crear el archivo que esta en la var fileName 
pCreate proc

	push cx
	
	mov ah, 3Ch  ; crear el archivo  
    lea dx, fileName
    mov cx, 5 ; type file
    int 21h

    mov [handlerw], ax ; movemos el handler
    ; imprimimos la cabecera
    call pAddHeader

	pop cx

	ret
pCreate endp

; S: fileName con el nombre del archivo, ax con el numero de handler
; D: intenta abrir el archivo log0000.txt, sino existe lo crea, si existe crea su consecutivo
pOpen proc 

 ; abir file:
	mov ah, 3Dh
	lea dx, [filename]
	mov al, 2 ; RW
	int 21h
    CALLIFANDRET jc, pCreate ; si no existe lo intentamos crear
    
    CLOSEM ax ; se tiene que cerrar aunque falle el crear

    ; si llega aqui es porque el archivo ya existia
    call pIncrementFileName ; incrementamos el numero de archivo

    call pOpen
    ret 
pOpen endp 

; E: al = fil, ah = col, bl = team(0 = blancas, 1 = negras)
pInsertInStr proc 

    lea si, stringToWrite
    add si, 3

    cmp bl, 0
    je pInsertInStr_blancas
    ; esto son las negras
    add si, 11        
pInsertInStr_blancas:

    add al, 30h ; para pasarlo a string
    add ah, 30h ; para pasarlo a string
    mov byte ptr [si], ah
    inc si
    mov byte ptr [si], al

    ret 
pInsertInStr endp 


; E: stringToWrite, handleRW
; D: escribe al final del archivo los primeros 17 bytes que esten en stringToWrite 
pWriteString proc 
    WRITEN 17, handleRW, stringToWrite
    ret 
pWriteString endp 

;----------------------------
; End Archivos
;----------------------------

main:
    ;call pOpen

    call pGraphicMode 
    call pDrawBoard

    mov POINT0_X, 150
    mov POINT0_Y, 140

    mov POINT1_X, 150
    mov POINT1_Y, 150

    mov cx, 10

    call pDrawCirclePoints

    jmp fin


loopTeclas: ; no sale a menos que sea ESC
	call pInput
	jmp loopTeclas

fin:
    ;CLOSEM handleRW ; cerramos el archivo de juego
    mov ax, 4C00h    ; protocolo de finalización del programa.
    int 21h

codigo ends
end inicio