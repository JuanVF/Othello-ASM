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
; 7) Awaiting...
; ...
; N) Amen
; ----------------------------------------------------------
datos segment

datos ends

; Esto es para indicar el tipo de stack que se va a usar
pila segment stack 'stack'

    ; Variables globales para pLine
    pLine_x0 dw 0
    pLine_y0 dw 0 
    pLine_x1 dw 0
    pLine_y1 dw 0

    dw 256 dup (?)

pila ends


; Aqui va toda la logica del programa
codigo segment

    assume cs:codigo, ds:datos, ss:pila

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

    inicio:
        mov ax, ds
        mov es, ax 

        mov ax, datos
        mov ds, ax

        mov ax, pila
        mov ss, ax

        call pGraphicMode

        call pDrawBoard

        mov ax, 4C00h    ; protocolo de finalización del programa.
        int 21h

codigo ends

end inicio