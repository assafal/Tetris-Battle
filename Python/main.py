
from PIL import Image
import numpy as np
import string
import math
import mif
from AI import *
from Cossack_Anima import *
TILE_SIZE = 16
MAX_DELTA = 4

C_X_TILES = int(800 / TILE_SIZE)
C_Y_TILES = int(480 / TILE_SIZE)

SPLASH_SCREEN = {}

SPLASH_SCREEN[0]   = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[1]   = '11111112345671328763184653418375841541842736111111'
SPLASH_SCREEN[2]   = '11111118427351784532167364513211851381748637111111'
SPLASH_SCREEN[3]   = '11111111125111361111111471114811471421741111111111'
SPLASH_SCREEN[4]   = '11111111164111741111111651118311231561561111111111'
SPLASH_SCREEN[5]   = '11111111187111382756111231117482741741487583111111'
SPLASH_SCREEN[6]   = '11111111142111238748111841115371111871583275111111'
SPLASH_SCREEN[7]   = '11111111183111671111111781118612111461111186111111'
SPLASH_SCREEN[8]   = '11111111147111851111111281115417211251111143111111'
SPLASH_SCREEN[9]   = '11111111138111353672111531116311641741756842111111'
SPLASH_SCREEN[10]  = '11111111125111624356111651114711341561845673111111'
SPLASH_SCREEN[11]  = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[12]  = '11111456381111581113547281258463154111116485231111'
SPLASH_SCREEN[13]  = '11111231152112113113563451845376184111115765781111'
SPLASH_SCREEN[14]  = '11111631146115114111135111112511123111114811111111'
SPLASH_SCREEN[15]  = '11111484671182116411182111113511146111113711111111'
SPLASH_SCREEN[16]  = '11111411111142734811148111117211124111116256371111'
SPLASH_SCREEN[17]  = '11111656281152672511127111118411187111113534671111'
SPLASH_SCREEN[18]  = '11111761145184117611158111112611152111118411111111'
SPLASH_SCREEN[19]  = '11111831113126112311146111114511143111115311111111'
SPLASH_SCREEN[20]  = '11111351142125113511137111118311183546312563471111'
SPLASH_SCREEN[21]  = '11111623561145116411156111114511156782318463251111'
SPLASH_SCREEN[22]  = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[23]  = '111111PRESS1START1FOR1SINGLE1PLAYER1GAME1111111111'
SPLASH_SCREEN[24]  = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[25]  = '111111PRESS1SELECT1FOR1BATTLE1GAME1111111111111111'
SPLASH_SCREEN[26]  = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[27]  = '111111PRESS1B1FOR1AI1DEMO1MODE11111111111111111111'
SPLASH_SCREEN[28]  = '11111111111111111111111111111111111111111111111111'
SPLASH_SCREEN[29]  = '11111111111111111111111111111111111111111111111111'


SCREEN_MAP = {}

SCREEN_MAP[0]   = '00000000000000000000000000000000000000000000000000'
SCREEN_MAP[1]   = '00000000000000000000000000000000000000000000000000'
SCREEN_MAP[2]   = '000000000bbbbbbbbbb0bbbbbbbbbb0bbbbbbbbbb000000000'
SCREEN_MAP[3]   = '00000000r1111111111s1111111111s1111111111l00000000'
SCREEN_MAP[4]   = '00000000r11STATS111s1LINES1111s1TOP1SCOREl00000000'
SCREEN_MAP[5]   = '00000000r1111111111s1111111111s1111111111l00000000'
SCREEN_MAP[6]   = '00000000r1122211111lzzzzzzzzzzr1111000011l00000000'
SCREEN_MAP[7]   = '00000000r1112111111sggggggggggs1111111111l00000000'
SCREEN_MAP[8]   = '00000000r1111111111sggggggggggsGAME1SCOREl00000000'
SCREEN_MAP[9]   = '00000000r1133311111sggggggggggs1111111111l00000000'
SCREEN_MAP[10]  = '00000000r1111311111sggggggggggs1111000011l00000000'
SCREEN_MAP[11]  = '00000000r1111111111sggggggggggs1111111111l00000000'
SCREEN_MAP[12]  = '00000000r1144111111sgggggggggglzzzzzzzzzz000000000'
SCREEN_MAP[13]  = '00000000r1114411111sggggggggggs1111111111l00000000'
SCREEN_MAP[14]  = '00000000r1111111111sggggggggggs11NEXT1111l00000000'
SCREEN_MAP[15]  = '00000000r1115511111sggggggggggs1111111111l00000000'
SCREEN_MAP[16]  = '00000000r1115511111sggggggggggs1111111111l00000000'
SCREEN_MAP[17]  = '00000000r1111111111sggggggggggs1111111111l00000000'
SCREEN_MAP[18]  = '00000000r1116611111sggggggggggs1111111111l00000000'
SCREEN_MAP[19]  = '00000000r1166111111sgggggggggglzzzzzzzzzz000000000'
SCREEN_MAP[20]  = '00000000r1111111111sggggggggggs1111111111l00000000'
SCREEN_MAP[21]  = '00000000r1177711111sggggggggggs11LEVEL111l00000000'
SCREEN_MAP[22]  = '00000000r1171111111sggggggggggs1111111111l00000000'
SCREEN_MAP[23]  = '00000000r1111111111sggggggggggs1111111111l00000000'
SCREEN_MAP[24]  = '00000000r1888811111sggggggggggs1111111111l00000000'
SCREEN_MAP[25]  = '00000000r1111111111sggggggggggltttttttttt000000000'
SCREEN_MAP[26]  = '00000000r1111111111sggggggggggl0000000000000000000'
SCREEN_MAP[27]  = '000000000tttttttttt0tttttttttt00000000000000000000'
SCREEN_MAP[28]  = '00000000000000000000000000000000000000000000000000'
SCREEN_MAP[29]  = '00000000000000000000000000000000000000000000000000'

AI_SCREEN_MAP = {}

AI_SCREEN_MAP[0]   = '00000000000000000000000000000000000000000000000000'
AI_SCREEN_MAP[1]   = '000bbbbbbbbbb0bbbbbbbbbb00bbbbbbbbbbb0bbbbbbbbbb00'
AI_SCREEN_MAP[2]   = '00r1111111111s1111111111lr1111111111s1111111111l00'
AI_SCREEN_MAP[3]   = '00r11STATS111s1SCORE1111lr1AI1SCORE1s11ROUNDS11l00'
AI_SCREEN_MAP[4]   = '00r1111111111s1111111111lr1111111111s1111111111l00'
AI_SCREEN_MAP[5]   = '00r1111111111s1110000011lr1110000011s1111000111l00'
AI_SCREEN_MAP[6]   = '00r1122211111lzzzzzzzzzzlrzzzzzzzzzzszzzzzzzzzzl00'
AI_SCREEN_MAP[7]   = '00r1112111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[8]   = '00r1111111111sgggggggggglrggggggggggs11NEXT1111l00'
AI_SCREEN_MAP[9]   = '00r1133311111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[10]  = '00r1111311111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[11]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[12]  = '00r1144111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[13]  = '00r1114411111sgggggggggglrggggggggggszzzzzzzzzzl00'
AI_SCREEN_MAP[14]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[15]  = '00r1115511111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[16]  = '00r1115511111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[17]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[18]  = '00r1116611111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[19]  = '00r1166111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[20]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[21]  = '00r1177711111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[22]  = '00r1171111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[23]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[24]  = '00r1888811111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[25]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[26]  = '00r1111111111sgggggggggglrggggggggggs1111111111l00'
AI_SCREEN_MAP[27]  = '000tttttttttt0tttttttttt00tttttttttt0tttttttttt000'
AI_SCREEN_MAP[28]  = '00000000000000000000000000000000000000000000000000'
AI_SCREEN_MAP[29]  = '00000000000000000000000000000000000000000000000000'

BACK_CODE = {}
BACK_CODE['l'] = 0
BACK_CODE['b'] = 1
BACK_CODE['r'] = 2
BACK_CODE['t'] = 3
BACK_CODE['s'] = 4 # l+r
BACK_CODE['z'] = 5 # t+b
BACK_CODE['a'] = 6 # all
BACK_CODE['g'] = 7 # grid


def SplitImg(fname, top_offset, bot_offset,kys):
    img = Image.open(fname)

    p = np.array(img)

    borders = []

    for c in range(p.shape[1]):
        # for r in img.size[1]:
        if p[:, c].min() > 240:
            borders.append(c)
    for i in borders:
        for j in range(1, MAX_DELTA):
            if i + j in borders:
                borders.remove(i + j)

    print(borders)

    # for ind in range(1, len(borders)):
    #     temp = img.crop((borders[ind - 1] + 1, top_offset, borders[ind] + 1, img.size[1] - bot_offset))
    #     temp.show()

    out = {}

    for ind in range(1, len(borders)):

        out[kys[ind-1]] = np.zeros((TILE_SIZE, TILE_SIZE))

        dy = (img.size[1] - bot_offset) - top_offset
        dx = borders[ind] - borders[ind-1]

        out[kys[ind-1]] = np.pad(p[top_offset:(img.size[1] - bot_offset), borders[ind-1] : borders[ind],0], ((0,TILE_SIZE-dy),(0,TILE_SIZE-dx)), 'constant', constant_values=(255))

        idx = {}
        idx[3] = [out[kys[ind-1]] < 64 ]
        idx[2] = np.logical_and([out[kys[ind-1]] >= 64] , [out[kys[ind-1]] < 128 ])
        idx[1] = np.logical_and([out[kys[ind-1]] >= 128] , [out[kys[ind-1]] < 196 ])
        idx[0] = np.logical_and([out[kys[ind-1]] >= 196] , [out[kys[ind-1]]  < 256 ])

        for i in range(4):
            out[kys[ind - 1]][idx[i][0]] = i

    return out

def WriteMif(lst, fname, line_len):

    ln = math.ceil(len(lst) /line_len)

    arr = np.zeros((ln,line_len) ,dtype=np.uint8)

    for i in range(ln):
        arr[i,:] = lst[i*line_len : (i+1)*line_len]


    with open(fname, 'w') as f:
        mif.dump(arr,f, packed=True, width=line_len*8, data_radix='HEX')

    return

def ArrToByte(arr):

    lst = []
    for k in arr.keys():

        for r in range(TILE_SIZE):
            for c in range(0,TILE_SIZE,4):
                val = (arr[k][r,c+3] << 6) + (arr[k][r,c+2] << 4) + (arr[k][r,c+1] << 2) + arr[k][r,c]
                lst.append(val)
    return lst

def StrToByte(dict):
    lst = []

    for k in dict.keys():

        for t in dict[k]:
            if str.isdigit(t):
                if t == '0':
                    lst.append(0)
                    lst.append(8 << 1)
                else:
                    lst.append(int(t)-1)
                    lst.append((1 << 6))
            elif str.islower(t):
                    lst.append(0)
                    lst.append(BACK_CODE[t] << 1)
            else:
                lst.append(string.ascii_uppercase.index(t) << 3)
                lst.append((2<<6) + (string.ascii_uppercase.index(t) >> 7))


    return lst

def CreateSplashAnima(dict):
    bricks = []
    text = []
    out = []


    for k in dict.keys():
        for ind, t in enumerate(dict[k]):
            if str.isdigit(t) and int(t) > 1:
                bricks.append((k,ind))
            elif not(str.isdigit(t)):
                text.append((k,ind))


    tmp = bricks.copy()
    random.shuffle(bricks)

    for ind in tmp:
        val = dict[ind[0]][ind[1]]
        out.append(int(val) - 1)
        out.append((1 << 6))
    for ind in text:
        val = dict[ind[0]][ind[1]]
        out.append(string.ascii_uppercase.index(val) << 3)
        out.append((2 << 6) + (string.ascii_uppercase.index(val) >> 7))

    #for val in tmp[-21:]:
    #    lst.remove(val)

    for val in bricks:
        add = val[0]*C_X_TILES + val[1]
        out.append(add % 256)
        out.append(add >> 8)
    for val in text:
        add = val[0]*C_X_TILES + val[1]
        out.append(add % 256)
        out.append(add >> 8)

    return out



def main():

    bytes = []
    blocks = {}

    bytes += ArrToByte(SplitImg('Fonts_upper_16.bmp', 3, 3, string.ascii_uppercase))
    bytes += ArrToByte(SplitImg('Fonts_symbols_16.bmp', 3, 3, [0,1,2,3,4,5,6,7,8,9]))

    bytes += [0]*48*16 # 192-36*4=48

    back_l = np.zeros((16, 16), dtype=int)

    back_l[:,0] = 1
    back_l[:,1] = 1
    back_l[:,2] = 2

    blocks['l'] = back_l

    blocks['b'] = np.rot90(back_l)
    blocks['r'] = np.rot90(blocks['b'])
    blocks['t'] = np.rot90(blocks['r'])
    blocks['lr'] = blocks['l'] + blocks['r']
    blocks['tb'] = blocks['t'] + blocks['b']
    blocks['all'] = blocks['l'] + blocks['r'] + blocks['t'] + blocks['b']

    back_g = 2*np.ones((16, 16), dtype=int)
    back_g[:, 0] = 3
    back_g[:, 15] = 3
    back_g[0, :] = 3
    back_g[15, :] = 3

    blocks['g'] = back_g

    bytes += ArrToByte(blocks)
    #bytes += [0] * 4 * 16  # 224-(192+7*4))=4

    blocks = {}
    blocks['g'] = np.tri(16, 16, 0, dtype=int)
    bytes += ArrToByte(blocks)

    WriteMif(bytes,'../sim/modelsim/symbols_rom.mif',16)
    WriteMif(bytes,'../synth/symbols_rom.mif',16)

    bytes = StrToByte(SCREEN_MAP)
    WriteMif(bytes,'../sim/modelsim/screen_map_rom.mif',2)
    WriteMif(bytes,'../synth/screen_map_rom.mif',2)

    bytes = StrToByte(AI_SCREEN_MAP)
    WriteMif(bytes, '../sim/modelsim/ai_screen_map_rom.mif', 2)
    WriteMif(bytes, '../synth/ai_screen_map_rom.mif', 2)

    bytes = CreateSplashAnima(SPLASH_SCREEN)

    WriteMif(bytes,'../sim/modelsim/splash_rom.mif',2)
    WriteMif(bytes,'../synth/splash_rom.mif',2)

    #img.show()

def BricksMain(fname):

    Bricks = {}


    Bricks[1] = Brick(1, [(0,0),(-1,0), (1,0) , (0,-1)])
    Bricks[2] = Brick(2, [(0,0),(-1,0), (-2,0), (0,1)])
    Bricks[3] = Brick(3, [(0,0),(-1,0), (0,1), (1,1)])
    Bricks[4] = Brick(4, [(0,0),(-1,0), (-1,1), (0,1)])
    Bricks[5] = Brick(5, [(0,0),(-1,1), (0,1), (1,0)])
    Bricks[6] = Brick(6, [(0,0),(0,1), (1,0), (2,0)])
    Bricks[7] = Brick(7, [(0,0),(-3,0), (-2,0), (-1,0)])

    Moves = [Insert_New, Down, Left, Right, CW, CCW]

    Res = {}

    for b in Bricks:
        item = Bricks[b]
        Res[item.code] = {}
        for r in range(4):
            Res[item.code][r] = []
            for m in Moves:
                Res[item.code][r].append(item.Move(m))
            item.RotCW()

#    pprint.pprint(Res)
    with open(fname, 'w') as f:

        f.write('(\n')
        for brick in Res:
            f.write('\t(\n')
            for rot in Res[brick]:
                f.write('\t\t(\n')
                for mv in Res[brick][rot]:
                    line = ''
                    temp = list(mv)
                    ln = len(temp[0])
                    if ln < 4:
                        temp[0] += [(0,0)]*(4-ln)
                        temp[1] += [(0,0)]*(4-ln)
                    st = ((''.join(map(str,temp)).replace('[','(')).replace(']',')')).replace(')(', '),(')
                    line += '\t\t\t(' + str(ln) +',' + st+ '),\n'
                    f.write(line)
                f.write('\t\t),\n')
            f.write('\t),\n')
        f.write(');\n')





if __name__ == '__main__':
    main()
    #BricksMain('brick_move_map.txt')
    #AIMain()
    #CossackMain()