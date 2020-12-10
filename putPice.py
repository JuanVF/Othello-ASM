mtz = [] # 0 = - , 1 = B, 2 = N 

def putPice(fil, col, color):
    global mtz
    for i in range(-1, 2):
        for j in range(-1, 2):
            if((i,j) == (0,0)):
                continue
            if(mtz[fil+i][col+j] != color):
                if(path(fil, col, j, i, color) == color):
                    mtz[fil][col] = color



def path(fil, col, vx, vy, color):
    global mtz

    fil += vy
    col += vx
    if(mtz[fil][col] == '-'):
        return 2
    if(mtz[fil][col] == color):
        return color

    if(path(fil, col, vx, vy, color) == color):
        mtz[fil][col] = color
        return color
    return '-'




def printMatrix(mtz):
    print(end="  ")
    for i in range(8):
        print(i, end="  ")
    print("")
    i =0
    for row in mtz:
        print(i, end=" ")
        i += 1
        for column in row:
            print(column, end="  ")
        print("")



for row in range(8):
    mtz.append(['-','-','-','-','-','-','-','-'])


mtz[3][3] = 'B'
mtz[4][4] = 'B'

mtz[4][3] = 'N'
mtz[3][4] = 'N'



col = 0
col1 = 'B'
col2 = 'N'
color = 'N'

while (col != 9):
    printMatrix(mtz)
    print("turno de ", color)
    fil = int(input("Digite el fila "))
    col = int(input("Digite el columna "))
    putPice(fil, col, color)

    if(color == col1):
        color = col2
    else:
        color = col1

