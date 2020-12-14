include ./code/tareas/num8/macros.ASM
;include macros.ASM

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

    C_COLOR db white

    ; Animacion render del home
    AN_POINT0 dw 2 dup(0); x, y
    AN_POINT1 dw 2 dup(0); x, y

    AN_POINT0_X equ word ptr [AN_POINT0]
    AN_POINT0_Y equ word ptr [AN_POINT0+2]

    AN_POINT1_X equ word ptr [AN_POINT1]
    AN_POINT1_Y equ word ptr [AN_POINT1+2]

    ; Archivos
    handleax dw ? ; handler auxiliar
    handleRW dw ? ; hanlder de lectura escritura

    buffy db 128 dup ('\n') ; buffer para R/W
    header db '   Othello Juego', 0AH, 'Negras     Blancas', 0AH; 36
    fileName db 'log0000.txt', 0 ; nombre del archivo
   
    stringToWrite db '  n12        b32', 0AH ;  


    ; Informacion de la UI
    gameTitle  db "Othello", 00h 
    gameTurn   db "Turno de:", 00h
    gameP1     db "blancas",00h
    gameP2     db " negras", 00h
    gamePosTxt db "Pos: ", 00h
    gamePos    db "  ", 00h
    gameAbout  db "F1:", 00h
    gameAbout2 db "   -Ayuda", 00h
    gameAbout3 db "   -Acerca de", 00h
    gameAbout4 db "F2:", 00h
    gameAbout5 db "   -Juega IA", 00h
    gameAbout6 db "ESC:", 00h
    gameAbout7 db "   -Sale de la app", 00h

    ; En esta variable se van a poner los mensajes
    ; La unica restriccion es usar un asciiz
    gameMessage db 40 dup(" "), 00h

    homePlayB db "Jugar con negras", 00h
    homePlayW db "Jugar con blancas", 00h
    homeHelp db "Ayuda", 00h

    homeInfo  db "Teclas de uso:", 00h
    homeInfo2 db "Flechas: [<-][->]", 00h
    homeInfo3 db "Acceder: [Enter]", 00h

    ; Esto le permite a la pantalla de ayuda saber de donde vuelve
    aboutFrom db STAGE_HOME

    aboutInfo  db "Autores: Vargas-Juan && Zamora-Gerald Programa: Othello", 00h
    aboutInfo2 db "Desc: Juego del Othello con IA integrada", 00h
    aboutInfo3 db "-Ayuda- ", 00h
    aboutInfo4 db "Pantalla Inicio: ", 00h
    aboutInfo5 db "- Esc: salir del juego", 00h
    aboutInfo6 db "- Flecha <-: seleccionar opcion de la izquierda", 00h
    aboutInfo7 db "- Flecha ->: seleccionar opcion de la derecha", 00h
    aboutInfo8 db "- Enter: entra a la opcion seleccionada", 00h
    aboutInfo9 db "Pantalla Juego: ", 00h
    aboutInfo10 db "- F1 - Entra a esta pantalla de ayuda", 00h
    aboutInfo11 db "- F2 - La IA juega el movimiento actual", 00h
    aboutInfo12 db "- Esc: salir del juego", 00h
    aboutInfo13 db "- Entrada de juego: digitar numeros (0-7)", 00h
    aboutInfo14 db "Pantalla Ayuda: ", 00h
    aboutInfo15 db "- Esc: vuelve a la pantalla anterior", 00h

    homeSelected db 00h

    isIAPlaying db 00h

    ; Seleccion de pantalla
    currentStage db STAGE_HOME

    ; Formato archivo:
    ;    Othelo Juego
    ;Blancas     Negras
    ;  b12        n32
    ;  ...        ...
    ;2 espacios, 3 letras, 8 espacios, 3 letras, 1 salto linea = 17 

    ; Matriz
    ; 0 - Negro
    ; 1 - Blanco
    ; 2 - Vacio :c
    Matriz db 64 dup(2)
    vel db 1, -1, 1, 0, 1, 1, 0, -1, 0, 1, -1, -1, -1, 0, -1, 1 ; posiciones para moverse en la matriz sin hacer un for doble

    toPlay dw 00h
    turn dw 0 ; 0 = Blanco, 1 = negro ; 0 = filas, 1 = columnas

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
; Utils
;----------------------------

; E/S: N/A
; D: Hace un delay de 1/15 segundos
pDelay proc
    pushs <ax, cx, dx>
    
    mov cx, 02h
    mov dx, 49F0h
    mov ah, 86h
    int 15h 
    
    pops <dx, cx, ax>

    ret
pDelay endP 

; E/S: N/A
; D: Este es el procedimiento vacio
; N: E
pInitGame proc
    ret
pInitGame endP

;----------------------------
; End Utils
;----------------------------

;----------------------------
; Start Teclas
;----------------------------

; E: N/A
; S: AL - ASCII digitado
;    AH - Scan Code
; D: Retorna en AX los datos de la tecla digitada
; N: La uso en el stage home y help :)
pGetKeyPressed proc
    mov ah, 11h
    int 16h
    ret
pGetKeyPressed endP

clearkeyboardbuffer proc 
; AX is clobbered
    PUSHS <ax, ds>
    CLEAN <ax>
    mov ax, 0040h
    mov ds, ax
    mov ax, ds:[001Ah]
    mov ds:[001Ch], ax
    POPS <ds, ax>
    ret
clearkeyboardbuffer endP

; D: recetea el siguiente movimiento a columna
pResetPosition proc 
    mov byte ptr [turn+1], 0 ; 0 = filas, 1 = columnas
    ret 
pResetPosition endP 

; E: al= numero + 30h
; S: pone el numero en toPlay
; D: cuando precionan un numero, lo pone en la columna o fila, dependiendo de [turn+1]
; si iban las negras entonces guarda la jugada en el archivo, no hace nada mas que meter esa jugada
; en el string para meterlo en el archivo posteriormente
pPutNumber proc 

    sub al, 30h

    cmp byte ptr [turn+1], 0 ; 0 = filas, 1 = columnas
    je pPutNumber_filas

;-------- columnas --------
    mov byte ptr [toplay+1], al ; movemos el numero a las columnas

    PUTINMATRIXPLAY <byte ptr[toplay]>, <byte ptr[toplay+1]>, <byte ptr[turn]> ; en la matriz
    cmp di, 0
    CALLIFANDRET je, pResetPosition ; si no se pudo jugar esa posicion

    INSERTPLAY <byte ptr[toplay]>, <byte ptr[toplay+1]>, <byte ptr[turn]> ; en el string

    mov byte ptr [turn+1], 0 ; para que sigan las filas de nuevo 

    cmp byte ptr[turn], 0 ; si es negro lo guardamos en le file  
    je pPutNumber_blanca 
        ; eran negras
        call pWriteString ; lo guardamos en file
        mov byte ptr [turn], 0 ; para que sigan las blancas
        
    jmp pPutNumber_fin
pPutNumber_blanca:

        ; eran blancas
        call pWriteString ; lo guardamos en file
        mov byte ptr [turn], 1 ; para que sigan las negras
    jmp pPutNumber_fin
;-------- filas --------
pPutNumber_filas:
    
    mov byte ptr [toplay], al ; movemos el numero a las filas
    mov byte ptr [turn+1], 1 ; para que sigan las columnas 

pPutNumber_fin:

    ret 
pPutNumber endp  

; E: al=ascii, ah=code
; D: llama un procedimiento dependiendo de la tecla, sino nada mas retorna
pSwitchkeys proc 
    
    cmp ah, F1_KEY
    jne pSwitchkeys_f2

    mov aboutFrom, STAGE_GAME
    mov currentStage, STAGE_HELP

    jmp pSwitchkeys_noNumero
pSwitchkeys_f2:
    cmp ah, F2_KEY
    jne pSwitchkeys_esc

    mov isIAPlaying, 1

    jmp pSwitchkeys_noNumero
pSwitchkeys_esc:
    cmp ah, 01; ESCP
    CONEJO je fin

    cmp al, 30h
    jl pSwitchkeys_noNumero

    cmp al, 37h
    jg pSwitchkeys_noNumero

    call pPutNumber; si era numero

pSwitchkeys_noNumero:

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
; Start Matrix operations
;----------------------------

; E: al= fil, ah = col, bl = color
; D: pone el numero bl en la matrix, lo unico que valida es que no este fuera de la misma
pPutInMatrix proc 

    PUSHS<ax, bx, dx>

    mov dl, bl ; respaldamos el color
    mov bl, 8

    mov bh, ah ; respaldamos la columna
    xor ah, ah
    mul bl ; fil * 8

    add al, bh ; fil * 8 + colum
    cmp ax, 64
    jge getInMatr_fin

    lea bx, Matriz
    add bx, ax

    mov byte ptr [bx], dl

getInMatr_fin:
    POPS<dx, bx, ax>

    ret 
pPutInMatrix endp


; E: al = fil, ah = colm
; S: al = (0 blanco, 1 negro, 2 vacio)
; D: retorna lo que esta en esa posicion, si esta fuera de la matrix entonces retorna vacio
pGetInMatr proc 

    push bx

    mov bl, 8

    mov bh, ah ; respaldamos la columna
    xor ah, ah
    mul bl ; fil * 8

    add al, bh ; fil * 8 + colum
    cmp ax, 64
    jge getInMatr_outOfRange

    lea bx, Matriz
    add bx, ax

    mov al, byte ptr [bx]
    jmp pgetInMatr_fin

getInMatr_outOfRange:
    mov al, 2 ; vacio

pgetInMatr_fin:
    pop bx

    ret 
pGetInMatr endp 

; E: al= fil, ah = col, dl = vx, dh = vy, bl = color
; S: al con el color
; D: comienza a buscar en esa direccion, si se encuentra uno de color bl pinta todo el path
pPath proc 

    PUSHS<bx, cx, dx>

    add al, dh
    add ah, dl

    mov cx, ax ; respaldamos ax
    GETINMATRIX al, ah
    cmp al, 2 ; si es vacio retorna 
    je pPath_fin

    cmp al, bl; si es igual al color retorna el color
    je pPath_fin

    ; sino:
    mov ax, cx; recuperamos
    call pPath

    cmp al, bl ; si es igual pintamos esa posicion
    jne pPath_fin

    PUTINMATRIX cl, ch, bl  ; si era igual  

pPath_fin:

    POPS<dx, cx, bx>
    ret 
pPath endp 

; E: al= fil, ah = col, bl = color
; S: di = 0 si no se pudo jugar esa posicion
; D: intenta poner una pieza en esa posicion
pPutPice proc 

    PUSHS<ax, bx, cx, dx>

    mov cx, 8 ; 8 posiciones a los lados
    lea si, vel
    xor di, di ; flag if hubo jugada, 0 = no, 1 = si

pPutPice_neighbors:

    mov dl, byte ptr [si] ; vy
    mov dh, byte ptr [si+1] ; vx

    push ax 
    add al, dh 
    add ah, dl
    GETINMATRIX al, ah

    cmp al, bl  
    je pPutPice_equals; si lo que esta en ese veciono es igual al color entonces continue
    pop ax 

    push ax 
    call pPath
    
    cmp al, bl
    jne pPutPice_equals ; si no encontro path entonces continuamos 
    
    mov di, 1
    pop ax 
    push ax
    PUTINMATRIX al, ah, bl ; encontramos path, ponemos esta posicion

pPutPice_equals:
    pop ax 

    inc si
    inc si
    loop pPutPice_neighbors

    POPS<dx, cx, bx, ax>
    ret
pPutPice endp

;----------------------------
; End Matrix operations
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
    pDrawCircle_err equ word ptr [bp-2]
    pDrawCircle_x equ word ptr [bp-4]
    pDrawCircle_y equ word ptr [bp-6]

    ; Se reserva memoria para las variables
    push bp
    mov bp, sp
    sub bp, 8

    PUSHS <ax, bx, cx, dx>
    PUSHS <POINT0_X, POINT0_Y, POINT1_X, POINT1_Y>

    ; Inicializamos las variables
    ; x = radius
    mov pDrawCircle_x, cx

    ; y = 0
    mov pDrawCircle_y, 0 

    ; err = 0
    mov pDrawCircle_err, 0

    ; Logica del algoritmo
    pDrawCircle_draw:
        ; Si x0 < y0 termina el loop
        mov ax, pDrawCircle_x
        mov bx, pDrawCircle_y
        jmpifl ax, bx, pDrawCircle_end

        ; POINT0 = POINT1
        MOVV POINT0_X, POINT1_X
        MOVV POINT0_Y, POINT1_Y

        ; Agregamos los puntos relativos
        add POINT0_X, ax
        add POINT0_Y, bx

        call pDrawCirclePoints

        ; si err <= 0
        mov ax, pDrawCircle_err
        jmpif ax, 0, pDrawCircle_zero
        jmpifns ax, pDrawCircle_ErrNotSigned
        pDrawCircle_zero:
            inc pDrawCircle_y
            
            ; err += 2y + 1
            CLEAN <dx>
            MULTCONSIG 2, pDrawCircle_y

            add pDrawCircle_err, ax

            inc pDrawCircle_err

            jmp pDrawCircle_ErrEnd
        ; si err > 0
        pDrawCircle_ErrNotSigned:
            dec pDrawCircle_x
            
            ; err -= 2x + 1
            CLEAN <dx>
            MULTCONSIG 2, pDrawCircle_x

            sub pDrawCircle_err, ax

            dec pDrawCircle_err

        pDrawCircle_ErrEnd:

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
    PUSHS <ax, bx, cx, dx>
    PUSHS <POINT0_X, POINT0_Y>

    JDRAWPIXELMACRO POINT1_X, POINT1_Y, C_COLOR

    ; Se dibuja (x0, y0)
    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR

    ; Se dibuja (-x0, y0)
    push POINT0_X
    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT
    mov POINT0_X, bx 

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR
    pop POINT0_X

    ; Se dibuja (x0, -y0)
    push POINT0_Y
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    mov POINT0_Y, bx

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR
    pop POINT0_Y

    ; Se dibuja (-x0, -y0)
    ; ax = -x0 : bx = -y0
    PUSHS <POINT0_X, POINT0_Y>
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    mov POINT0_Y, bx

    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    mov POINT0_X, bx

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR
    POPS <POINT0_Y, POINT0_X>

    ; Se voltean los puntos iniciales con respecto al origen POINT1
    ; no se pueden simplemente voltear (x, y) a (y, x)
    ; porque el punto origen es distinto para todos
    mov ax, POINT1_X
    mov bx, POINT0_X

    GETDISTANCE

    mov dx, cx

    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETDISTANCE

    ; cx = y con respecto al origen
    ; dx = x con respecto al origen
    MOVV POINT0_X, POINT1_X
    MOVV POINT0_Y, POINT1_Y

    add POINT0_X, cx
    add POINT0_Y, dx

    ; Se dibuja (y0, x0)
    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR


    push POINT0_Y
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    mov POINT0_Y, bx

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR
    pop POINT0_Y

    ; Se dibuja (y0, -x0)
    push POINT0_X
    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    mov POINT0_X, bx

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR

    pop POINT0_X
    ; Se dibuja (-y0, -x0)
    ; bx = -y0 : ax = -x0
    mov ax, POINT1_Y
    mov bx, POINT0_Y

    GETNEGPOINT

    mov POINT0_Y, bx

    mov ax, POINT1_X
    mov bx, POINT0_X

    GETNEGPOINT

    mov POINT0_X, bx

    JDRAWPIXELMACRO POINT0_X, POINT0_Y, C_COLOR

    POPS <POINT0_Y, POINT0_X>
    POPS <dx, cx, bx, ax>

    ret
pDrawCirclePoints endP

; E: El punto central del circulo en POINT1
; S: N/A
; D: Dibuja un circulo relleno en POINT1_X, POINT1_Y, de radio 10
pDrawFullCircle proc 
    push cx
    mov cx, COINS_RADIUS

    pDrawCoins_draw:
        MOVV POINT1_X, POINT0_X
        MOVV POINT1_Y, POINT0_Y
        
        PUSHS <POINT0_X, POINT0_Y, POINT1_X, POINT1_Y>
        call pDrawCircle
        POPS <POINT1_Y, POINT1_X, POINT0_Y, POINT0_X>

    loop pDrawCoins_draw

    pop cx
    
    ret
pDrawFullCircle endP

; E/S: N/A
; D: Dibuja una pantall negra
pBlackScreen proc
    PUSHS <bx, cx, dx>

    mov bh, black
    mov cl, 0
    mov ch, 0

    mov dl, 80
    mov dh, 30

    call pDrawBlock
    
    POPS <dx, cx, bx>

    ret
pBlackScreen endP

; E/S : N/A
; D: Se encarga de dibujar la base del tablero
pDrawBoard proc
    PUSHS <bx, cx, dx>

    call pBlackScreen

    ; Dibujamos la base verde
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

    ; Elegimos el color
    mov al, black
    mov byte ptr [CURSOR+1], al

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

    ; Elegimos el color
    mov al, black
    mov byte ptr [CURSOR+1], al

    pDrawBlock_vlines:
        call drawLine

        add POINT0_X, 52
        add POINT1_X, 52
    loop pDrawBlock_vlines

    POPS <dx, cx, bx>

    ret
pDrawBoard endP

; E: La matriz
; S: N/A
; D: Se encarga de dibujar la matriz
pDrawCoins proc
    pushs <ax, bx, cx, dx, di>

    mov cx, 64
    mov dx, 0
    mov POINT0_X, 90
    mov POINT0_Y, 90
    
    lea di, matriz

    pDrawCoins_loop:
        ; Esto es lo que se podria cambiar por su getPosicion xD
        ; Obtenemos el color por el lugar de la matriz que recorremos
        mov C_COLOR, black
        mov al, [di]

        ; Si es dos no se renderiza nada
        jmpif al, 2, pDrawCoins_coin
        ; si no es 0 movemos el color a negro
        jmpif al, 0, pDrawCoins_C_COLOR
            mov C_COLOR, white

        pDrawCoins_C_COLOR:

        ; Se guarda el CX para no perder el contador del loop
        call pDrawFullCircle

        pDrawCoins_coin:
        add POINT0_X, 52
        inc dx
        inc di

        jmpifn dx, 8, pDrawCoins_jmp
            mov POINT0_X, 90
            add POINT0_Y, 52
            CLEAN <dx>

        pDrawCoins_jmp:
    loop pDrawCoins_loop

    pops <di, dx, cx, bx, ax>

    ret
pDrawCoins endP

; E: N/A
; S: N/A
; D: Se encarga de dibujar las posiciones de la matriz
pDrawPositions proc
    PUSHS <ax, bx, cx, cx>

    ; Dibujamos los de las columnas

    ; Posicion de cursor inicial
    mov dh, 3
    mov dl, 10

    mov al, '0'
    mov bl, white

    mov cx, 08

    pDrawPositions_cols:
        SETCURSOR
        DRAWCHAR

        add dl, 7
        inc al

        jmpifn cx, 5, pDrawPositions_l

        sub dl, 02

    pDrawPositions_l: loop pDrawPositions_cols

    ; Dibujamos los de las filas

    ; Posicion de cursor inicial
    mov dh, 5
    mov dl, 5

    mov al, '0'
    mov bl, white

    mov cx, 08

    pDrawPositions_row:
        SETCURSOR
        DRAWCHAR

        add dh, 3
        inc al

        jmpifn cx, 6, pDrawPositions_r

        add dh, 1

    pDrawPositions_r: loop pDrawPositions_row

    POPS <dx, cx, bx, ax>

    ret
pDrawPositions endP

; E: N/A
; S: N/A
; D: Se encarga de dibujar la info general del juego
pDrawInfo proc
    PUSHS <ax, bx, dx, di>

    mov bl, white

    ; Se dibuja el titulo del juego
    DRAWTEXTONSCREEN gameTitle, 2, 65

    ; Se escribe el texto de turno
    DRAWTEXTONSCREEN gameTurn, 4, 60

    ; Se dibujan los turnos
    lea di, gameP2

    JMPIF turn, 0, pDrawInfo_blacks
        lea di, gameP1
    pDrawInfo_blacks:

    mov dh, 4
    mov dl, 69

    DRAWTEXT

    ; Se dibuja lo que se ha escrito por teclado
    DRAWTEXTONSCREEN gamePosTxt, 6, 60

    lea di, gamePos
    mov al, byte ptr [toPlay]
    add al, 30h
    mov [di], al
    
    mov al, byte ptr [toPlay+1]
    add al, 30h
    mov [di+1], al

    DRAWTEXTONSCREEN gamePos, 6, 64

    DRAWTEXTONSCREEN gameAbout, 8, 60

    DRAWTEXTONSCREEN gameAbout2, 9, 60

    DRAWTEXTONSCREEN gameAbout3, 10, 60

    DRAWTEXTONSCREEN gameAbout4, 12, 60

    DRAWTEXTONSCREEN gameAbout5, 13, 60

    DRAWTEXTONSCREEN gameAbout6, 15, 60

    DRAWTEXTONSCREEN gameAbout7, 16, 60

    ; Aqui se escribe la notificacion
    ; Solo copie su mensaje a gameMessage y se va a mostrar
    ; Asegurese que sea ASCIIZ o va a dar errores.
    DRAWTEXTONSCREEN gameMessage, 1, 10

    POPS <di, dx, bx, ax>
    ret
pDrawInfo endP

pHomeAnimation proc
    PUSHS <ax, bx, cx>
    PUSHS <POINT0_X, POINT0_Y, POINT1_X, POINT1_Y>

    ; Punto cero de la animacion
    mov POINT0_X, 0
    mov POINT0_Y, 200

    mov POINT1_X, 640
    mov POINT1_Y, 200

    mov al, magenta 
    mov byte ptr [CURSOR+1], al

    call drawLine

    ; Aplicamos el efecto de animacion 8)
    MOVV POINT0_X, AN_POINT0_X
    MOVV POINT0_Y, AN_POINT0_Y

    MOVV POINT1_X, AN_POINT1_X
    MOVV POINT1_Y, AN_POINT1_Y

    mov al, magenta 
    mov byte ptr [CURSOR+1], al

    mov bx, 70 ; Es la distancia entre cada linea

    ; Dibujamos las lineas horizontales
    mov cx, 4
    pHomeAnimation_hor:
        call drawLine

        add POINT0_Y, bx
        add POINT1_Y, bx
    loop pHomeAnimation_hor

    add AN_POINT0_Y, 2
    add AN_POINT1_Y, 2

    ; Reseteamos la animacion
    mov ax, AN_POINT0_Y
    JMPIFN ax, 270, pHomeAnimation_reset
        MOVV AN_POINT0_Y, 200
        MOVV AN_POINT1_Y, 200
    pHomeAnimation_reset:

    ; Dibujamos las lineas verticales de la izquierda
    MOVV POINT0_X, 290
    MOVV POINT0_Y, 200

    MOVV POINT1_X, 270
    MOVV POINT1_Y, 480

    mov al, lighBlue 
    mov byte ptr [CURSOR+1], al

    mov cx, 6
    pHomeAnimation_verl:
        call drawLine

        sub POINT0_X, 50
        sub POINT1_X, 90

        mov ax, POINT1_X
        JMPIFNS ax, pHomeAnimation_verl_nsign
        MOVV POINT1_X, 0
        sub POINT1_Y, 110
    pHomeAnimation_verl_nsign:
    loop pHomeAnimation_verl

    ; Dibujamos las lineas verticales de la derecha
    MOVV POINT0_X, 330
    MOVV POINT0_Y, 200

    MOVV POINT1_X, 350
    MOVV POINT1_Y, 480

    mov al, lighBlue 
    mov byte ptr [CURSOR+1], al

    mov cx, 6
    pHomeAnimation_verr:
        call drawLine

        add POINT0_X, 50
        add POINT1_X, 90

        mov ax, POINT1_X
        JMPIFL ax, 640, pHomeAnimation_verr_nsign
        MOVV POINT1_X, 640
        sub POINT1_Y, 110
    pHomeAnimation_verr_nsign:
    loop pHomeAnimation_verr

    POPS <POINT1_Y, POINT1_X, POINT0_Y, POINT0_X>
    POPS <cx, bx, ax>

    ret
pHomeAnimation endP

; E/S: N/A
; D: Se encarga de dibujar los botones del home
pHomeInfo proc
    PUSHS <ax, bx, cx, dx>

    mov bl, magenta

    DRAWTEXTONSCREEN gameTitle, 6, 33

    ; Boton de play en blancas
    mov bl, white

    mov al, homeSelected
    JMPIFN al, 00h, pHomeInfo_playw_color
        mov bl, lighBlue

    pHomeInfo_playw_color:

    DRAWTEXTONSCREEN homePlayW, 9, 10

    ; Boton de play en negras
    mov bl, white

    mov al, homeSelected
    JMPIFN al, 01h, pHomeInfo_playb_color
        mov bl, lighBlue

    pHomeInfo_playb_color:

    DRAWTEXTONSCREEN homePlayB, 9, 30

    ; Boton de help
    mov bl, white

    mov al, homeSelected
    JMPIFN al, 02h, pHomeInfo_help_color
        mov bl, lighBlue

    pHomeInfo_help_color:

    DRAWTEXTONSCREEN homeHelp, 9, 50

    ; Info de ayuda para la UI
    mov bl, lightGray

    DRAWTEXTONSCREEN homeInfo, 2, 2
    DRAWTEXTONSCREEN homeInfo2, 2, 18
    DRAWTEXTONSCREEN homeInfo3, 2, 38

    POPS <dx, cx, bx, ax>
    ret
pHomeInfo endP

; E/S: N/A
; D: Escribe la info del acerca de y la ayuda
pAboutInfo proc
    push bx

    mov bl, white

    DRAWTEXTONSCREEN aboutInfo, 1, 1
    DRAWTEXTONSCREEN aboutInfo2, 2, 1
    DRAWTEXTONSCREEN aboutInfo3, 3, 1
    DRAWTEXTONSCREEN aboutInfo4, 4, 1
    DRAWTEXTONSCREEN aboutInfo5, 5, 1
    DRAWTEXTONSCREEN aboutInfo6, 6, 1
    DRAWTEXTONSCREEN aboutInfo7, 7, 1
    DRAWTEXTONSCREEN aboutInfo8, 8, 1
    DRAWTEXTONSCREEN aboutInfo9, 9, 1
    DRAWTEXTONSCREEN aboutInfo10, 10, 1
    DRAWTEXTONSCREEN aboutInfo11, 11, 1
    DRAWTEXTONSCREEN aboutInfo12, 12, 1
    DRAWTEXTONSCREEN aboutInfo13, 13, 1
    DRAWTEXTONSCREEN aboutInfo14, 14, 1
    DRAWTEXTONSCREEN aboutInfo15, 15, 1

    pop bx

    ret
pAboutInfo endP

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
    WRITEN 36, handleRW, header
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
pOpen proc ; se encarga de crear el archivo

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

; E: filename el nombre 
; S: handleRW
; D: abre un archivo que debe existir, y envia el cursor al final de este
pOpenAndSetEnd proc 

    PUSHS<ax, bx, cx, dx>
    mov ah, 3Dh ; lo abrimos 
	lea dx, [filename]
	mov al, 2 ; RW
	int 21h

    mov [handlerw], ax
 
    mov ah, 42h
    mov al, 02h ; end of file
    mov bx, [handlerw]
    xor cx, cx
    xor dx, dx
    int 21h

    POPS<dx, cx, bx, ax>

    ret 
pOpenAndSetEnd endp 

; E: stringToWrite, handleRW
; D: escribe al final del archivo los primeros 17 bytes que esten en stringToWrite 
pWriteString proc 
    ; 1. open file
   
    call pOpenAndSetEnd

    ; 2. write
    cmp byte ptr turn, 0
    jne pWriteString_blancas_turn

    WRITEN 13, handlerw, stringToWrite

    jmp pWriteString_fin
pWriteString_blancas_turn:
    WRITEN 4, handlerw, stringToWrite+13
    
pWriteString_fin:

    ; 3. close file
    CLOSEM handlerw 

    ret 
pWriteString endp 

;----------------------------
; End Archivos
;----------------------------

;----------------------------
; Manejador de pantallas
;----------------------------

; E/S: N/A
; D: Esta es el ciclo para la pantalla de juego
pStageGame proc

    pStageGame_loop: ; no sale a menos que sea ESC
        call pDrawBoard
        call pDrawCoins
        call pDrawPositions
        call pDrawInfo
        call pInput
        JMPIFN currentStage, STAGE_GAME, pStageGame_end
        jmp pStageGame_loop
    
    pStageGame_end:

    ret
pStageGame endP

; E: AH - Scan Code
; S: N/A
; D: Determina como interactuar con el home
pStageHomeKeys proc
    push bx

    JMPIFN ah, ENTER_KEY, pStageHomeKeys_left

        JMPIFN homeSelected, 2, pStageHomeKeys_game_b
            mov aboutFrom, STAGE_HOME
            mov currentStage, STAGE_HELP

            jmp pStageHomeKeys_end
        pStageHomeKeys_game_b:
        JMPIFN homeSelected, 0, pStageHomeKeys_game_w
            mov currentStage, STAGE_GAME
            mov turn, 1

            jmp pStageHomeKeys_end
        pStageHomeKeys_game_w:
            mov currentStage, STAGE_GAME
            mov turn, 0

            jmp pStageHomeKeys_end
    ; Evento de tecla izquierda
    pStageHomeKeys_left:
    JMPIFN ah, ARROW_LEFT, pStageHomeKeys_right
        dec homeSelected
        
        mov bl, homeSelected
        JMPIFNS bl, pStageHomeKeys_end
            mov homeSelected, 2
        jmp pStageHomeKeys_end

    ; Evento de tecla derecha
    pStageHomeKeys_right:
    JMPIFN ah, ARROW_RIGHT, pStageHomeKeys_end
        inc homeSelected
        
        mov bl, homeSelected
        JMPIFN bl, 3, pStageHomeKeys_end
            mov homeSelected, 0
    pStageHomeKeys_end:

    pop bx

    ret
pStageHomeKeys endP

; E/S: N/A
; D: Este se encarga de renderizar el home
pStageHome proc

    MOVV AN_POINT0_X, 0
    MOVV AN_POINT0_Y, 200

    MOVV AN_POINT1_X, 640
    MOVV AN_POINT1_Y, 200

    ; Es necesario que este en un loop para la animacion
    ; bien fancy -inserte estrellitas-
    pStageHome_loop:
        CLEAN <ax>
        call pBlackScreen
        call pHomeInfo
        call pHomeAnimation
        call pGetKeyPressed
        call pStageHomeKeys

        JMPIF ah, SCAPE, pStageHome_quit

        ; Se limpia el buffer del teclado
        ; Esto es sumamente necesario o 
        ; se va a quedar en bucle, 11h no lo limpia
        call clearkeyboardbuffer
        call pDelay
    JMPIF currentStage, STAGE_HOME, pStageHome_loop
    jmp pStageHome_end
    pStageHome_quit:
    mov currentStage, STAGE_QUIT

    pStageHome_end:

    ret
pStageHome endP

; E/S: N/A
; D: Es el acerca de
pStageHelp proc
    push ax

    pStageHelp_loop:

    ; Escribimos la info
    call pBlackScreen
    call pAboutInfo

    mov ah, 10h
    int 16h

    JMPIFN ah, SCAPE, pStageHelp_loop
    
    mov al, aboutFrom
    mov currentStage, al

    pop ax

    ret
pStageHelp endP

; E/S: N/A
; D: Es el manejador de que pantalla se debe renderizar
pManageStages proc
    push ax

    pManageStages_loop:
        mov al, currentStage

        JMPIF al, STAGE_GAME, pManageStages_game
        JMPIF al, STAGE_HOME, pManageStages_home
        JMPIF al, STAGE_HELP, pManageStages_help

        ; Se cambia a la pantalla de juego
        pManageStages_game:
        ; Aqui se inicia el juego
            call pInitGame
            call pStageGame
            jmp pManageStages_cons
        
        ; Se cambia a la pantalla home
        pManageStages_home:
            call pStageHome
            jmp pManageStages_cons

        ; Se cambia a la pantalla de ayuda
        pManageStages_help:
            call pStageHelp
            jmp pManageStages_loop
        pManageStages_cons:

        mov al, currentStage
    JMPIFN al, STAGE_QUIT, pManageStages_loop

    pop ax

    ret
pManageStages endP

;----------------------------
; End Manejador de pantallas
;----------------------------

main:
    call pOpen
    CLOSEM handleRW ; se abre cada que necesitemos el file

    ;mov byte ptr [MATRIZ+27], 1
    PUTINMATRIX 3, 3, 1
    PUTINMATRIX 4, 4, 1

    PUTINMATRIX 4, 3, 0
    PUTINMATRIX 3, 4, 0

    call pGraphicMode

    call pManageStages

fin:
    
    mov ax, 4C00h    ; protocolo de finalización del programa.
    int 21h

codigo ends
end inicio