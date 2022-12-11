from PIL import Image
import numpy as np
from main import *


def ReadImg(fname, ):

    img = Image.open(fname)

    p = np.array(img)

    return p

def CossackMain():

    name = 'Cossack_'
    SIZE = 64
    imgs = {}
    vals = []
    res = []
    for i in range(1,5):

        fname = name + str(i) + '_64.bmp'
        imgs[i] = ReadImg(fname)
        for k in imgs[i]:
            for j in k:
                if list(j) not in vals:
                    vals.append(list(j))
        for r in range(SIZE):
            for c in range(0,SIZE,2):
                # val = (vals.index(list(imgs[i][r,c+3])) << 6) + (vals.index(list(imgs[i][r,c+2])) << 4) + (vals.index(list(imgs[i][r,c+1])) << 2) +vals.index(list(imgs[i][r,c]))
                val = (vals.index(list(imgs[i][r,c+1])) << 4) +vals.index(list(imgs[i][r,c]))
                res.append(val)
#        imgs[i] = np.rot90(imgs[i])

    WriteMif(res,'../sim/modelsim/cossack_rom.mif',16)
    WriteMif(res,'../synth/cossack_rom.mif',16)

    return