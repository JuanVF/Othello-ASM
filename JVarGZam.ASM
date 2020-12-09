include macros.ASM

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

   ; Variables para pLine
    pLine_x0 dw 0
    pLine_y0 dw 0 
    pLine_x1 dw 0
    pLine_y1 dw 0

    ; Variables de archivos

    handleax dw ? ; handler auxiliar
    handleRW dw ? ; hanlder de lectura escritura

    buffy db 128 dup ('\n') ; buffer para R/W
    header db '   Othelo Juego', 0AH, 'Blancas     Negras', 0AH; 35
    fileName db 'log0000.txt', 0 ; nombre del archivo
   
    stringToWrite db '  b12        n32', 0AH ; 

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


; --- start keyboard stuff

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


; --- end keyboard stuff


; --- start drawing stuff
    ; E: pLine_x0 - EL x inicial
    ;    pLine_y0 - El y inicial
    ;    pLine_x1 - El x final
    ;    pLine_y1 - El y final
    ; S: lastLineSize - Tamano de la linea
    ; D: Dibuja una linea en pantalla
    pLine proc 
        PUSHS <ax, bx, cx, dx>
        ; Variables para el algoritmo
        pLine_x     equ word ptr [bp-2]
        pLine_y     equ word ptr [bp-4]
        pLine_dx    equ word ptr [bp-6]
        pLine_dy    equ word ptr [bp-8]
        pLine_incYi equ word ptr [bp-10]
        pLine_incXi equ word ptr [bp-12]
        pLine_incYr equ word ptr [bp-14]
        pLine_incXr equ word ptr [bp-16]
        pLine_Av    equ word ptr [bp-18]
        pLine_AvR   equ word ptr [bp-20]
        pLine_AvI   equ word ptr [bp-22]
        
        ; Reservar espacio
        push bp
        mov bp, sp
        sub bp, 24

        ; Inicializacion de variables

        mov pLine_x, 0
        mov pLine_y, 0
        mov pLine_dx, 0
        mov pLine_dy, 0
        mov pLine_incYi, 0
        mov pLine_incXi, 0
        mov pLine_incYr, 0
        mov pLine_incXr, 0
        mov pLine_Av, 0
        mov pLine_AvR, 0
        mov pLine_AvI, 0

        ; Logica del algoritmo

        ; dy = pLine_y1 - pLine_y0
        mov ax, pLine_y1
        mov bx, pLine_y0

        sub ax, bx

        mov pLine_dy, ax

        ; dy = pLine_x1 - pLine_x0
        mov ax, pLine_x1
        mov bx, pLine_x0

        sub ax, bx

        mov pLine_dx, ax

        ; Incremento en y para las secciones de avance 
        ; inclinado
        mov bx, pLine_dy
        JMPIFS bx, pLine_dyneg
            ; incYi = 1
            mov pLine_incYi, 1
            jmp pLine_dyif_end

        pLine_dyneg:
            ; dy = -dy
            C2 pLine_dy
            ; incYi = -1
            mov pLine_incYi, -1

        pLine_dyif_end:

        ; Incremento en x para las secciones de avance 
        ; inclinado
        mov bx, pLine_dx

        JMPIFS bx, pLine_dxneg
            mov pLine_incXi, 1
            jmp pLine_dxif_end

        pLine_dxneg:
            C2 pLine_dx
            mov pLine_incXi, -1

        pLine_dxif_end:

        ; Incremento para las secciones de avance recto
        mov ax, pLine_dx
        mov bx, pLine_dy

        JMPIFL ax, bx, pLine_dx_less_dy
            ; incYr = 0
            mov pLine_incYr, 0
            ; incXr = incXi
            movV pLine_incXr, pLine_incXi
            jmp pLine_dx_less_dy_end
        pLine_dx_less_dy:
            ; incXr = 0
            mov pLine_incXr, 0
            ; incYr = incYi
            movV pLine_incYr, pLine_incYi

            ; dx <=> dy
            XCHGV pLine_dx, pLine_dy 

        pLine_dx_less_dy_end:

        ; Inicializar algunas variables
        ; x = pLine_x0
        movV pLine_x, pLine_x0

        ; y = pLine_y0
        movV pLine_y, pLine_y0

        ; avR = 2 * dy
        CLEAN <dx>
        mov ax, pLine_dy
        mov bx, 2
        mul bx

        mov pLine_avR, ax

        ; av = avR - dx
        mov ax, pLine_avR
        mov bx, pLine_dx
        sub ax, bx
        
        mov pLine_aV, ax

        ; avI = av - dx
        mov ax, pLine_aV
        mov bx, pLine_dx
        sub ax, bx
        
        mov pLine_aVi, ax

        ; Bucle para el trazado de lineas
        pLine_trazado:
            ; Dibujamos el pixel
            mov dx, pLine_y
            mov cx, pLine_x
            mov al, black

            call pDrawPixel

            ; Condicion parada
            mov ax, pLine_x
            JMPIFN ax, pLine_x1, pLine_trazado_ok

            mov ax, pLine_y
            JMPIF ax, pLine_y1, pLine_end_trazado

            pLine_trazado_ok:

            ; Comparamos si av >= 0
            mov ax, pLine_aV
            JMPIFS ax, pLine_av_signed
                ; X = X + IncXi
                mov ax, pLine_x
                mov bx, pLine_IncXi

                add ax, bx
                mov pLine_x, ax

                ; Y = Y + IncYi
                mov ax, pLine_y
                mov bx, pLine_IncYi

                add ax, bx
                mov pLine_y, ax

                ; aV = av + avI
                mov ax, pLine_aV
                mov bx, pLine_aVi

                add ax, bx
                mov pLine_aV, ax

                jmp pLine_av_signed_endif
            pLine_av_signed:
                ; X = X + IncXr
                mov ax, pLine_x
                mov bx, pLine_IncXr

                add ax, bx
                mov pLine_x, ax

                ; Y = Y + IncYr
                mov ax, pLine_y
                mov bx, pLine_IncYr

                add ax, bx
                mov pLine_y, ax

                ; aV = av + aVr
                mov ax, pLine_aV
                mov bx, pLine_aVr

                add ax, bx
                mov pLine_aV, ax

            pLine_av_signed_endif:
            jmp pLine_trazado
        pLine_end_trazado:

        ; Recuperar el BP
        pop bp

        POPS <dx, cx, bx, ax>

        ret
    pLine endP

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
    
    ; E/S : N/A
    ; D: Se encarga de dibujar la base del tablero
    pDrawBoard proc
        PUSHS <bx, cx, dx>

        ; Dibujamos toda la pantalla de
        mov bh, green
        mov cl, 8
        mov ch, 4
        mov dl, 70
        mov dh, 30

        call pDrawBlock

        ; Pintamos las lineas horizontales
        mov cx, 8

        mov pLine_x0, 60
        mov pLine_x1, 640

        mov pLine_y0, 64
        mov pLine_y1, 64

        pDrawBlock_hlines:
            call pLine

            add pLine_y0, 52
            add pLine_y1, 52
        loop pDrawBlock_hlines

        ; Pintamos las lineas verticales
        mov cx, 8

        mov pLine_x0, 60
        mov pLine_x1, 60

        mov pLine_y0, 64
        mov pLine_y1, 480

        pDrawBlock_vlines:
            call pLine

            add pLine_x0, 52
            add pLine_x1, 52
        loop pDrawBlock_vlines

        POPS <dx, cx, bx>

        ret
    pDrawBoard endP
; --- end drawing stuff

; --- start files stuff 

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



; --- ends files stuff 

main:
    call pOpen
   ; call pGraphicMode 
   ; call pDrawBoard


loopTeclas: ; no sale a menos que sea ESC
	call pInput
	jmp loopTeclas


fin:
    CLOSEM handleRW ; cerramos el archivo de juego
    mov ax, 4C00h    ; protocolo de finalización del programa.
    int 21h

codigo ends

end inicio