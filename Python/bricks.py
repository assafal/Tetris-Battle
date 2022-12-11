


class Brick:
    def __init__(self, code, pos, init_pos):
        self.code  = code
        self.pos = pos
        self.init_pos = init_pos

    def Move(self, MoveFunc):
        new_pos =[]
        WR = []
        ER = []

        for i in self.pos:
            new_pos.append(MoveFunc(i))

        for i in new_pos:
            if i not in self.pos or MoveFunc==Insert_New:
                WR.append(i)
        for i in self.pos:
            if i not in new_pos or MoveFunc==Insert_New :
                ER.append(i)

        return WR,ER

    def RotCW(self):
        (WR,ER) = self.Move(CW)
        for i in ER:
            self.pos.remove(i)
        for i in WR:
            self.pos.append(i)


def Insert_New(i):
    return i

def Down(i):
    return i[0], i[1]+1

def Left(i):
    return i[0]-1, i[1]

def Right(i):
    return i[0]+1, i[1]

def CW(i):
    if i[1]==0:
        return 0, i[0]
    elif i[0]==0:
        return -i[1], 0
    elif i[0] != i[1]:
        return i[0],-i[1]
    else:
        return -i[0],i[1]

def CCW(i):
    if i[1]==0:
        return 0, -i[0]
    elif i[0]==0:
        return i[1], 0
    elif i[0] != i[1]:
        return -i[0],i[1]
    else:
        return i[0],-i[1]



