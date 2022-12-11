from bricks import *
import random
import copy

C_MAX_X = 10
C_MAX_Y = 20

C_DOWN_PHASE = 3

Bricks = {}

Bricks[1] = Brick(1, [(0, 0), (-1, 0), (1, 0), (0, -1)], [(5, 1), (5, 1), (5, 0), (5, 1)])
Bricks[2] = Brick(2, [(0, 0), (-1, 0), (-2, 0), (0, 1)], [(6, 0), (5, 2), (4, 1), (5, 0)])
Bricks[3] = Brick(3, [(0, 0), (-1, 0), (0, 1), (1, 1)], [(5, 0), (5, 1), (5, 1), (5, 1)])
Bricks[4] = Brick(4, [(0, 0), (-1, 0), (-1, 1), (0, 1)], [(5, 0), (5, 1), (5, 1), (5, 0)])
Bricks[5] = Brick(5, [(0, 0), (-1, 1), (0, 1), (1, 0)], [(5, 0), (5, 1), (5, 1), (5, 1)])
Bricks[6] = Brick(6, [(0, 0), (0, 1), (1, 0), (2, 0)], [(4, 0), (5, 0), (5, 1), (5, 2)])
Bricks[7] = Brick(7, [(0, 0), (-3, 0), (-2, 0), (-1, 0)], [(6, 0), (5, 3), (4, 0), (5, 0)])


class Board:

    def __init__(self):
        self.Map = {}

        for y in range(C_MAX_Y):
            self.Map[y] = [0] * C_MAX_X

    def GetPositions(self, brick):

        res = Board()

        for x in range(C_MAX_X):
            for y in range(C_MAX_Y):
                res.Map[y][x] = 1
                for delta in brick:
                    if x + delta[0] < 0 or x + delta[0] > C_MAX_X - 1 or y + delta[1] < 0 or y + delta[1] > C_MAX_Y - 1:
                        res.Map[y][x] = 0
                        break
                    else:
                        if self.Map[y + delta[1]][x + delta[0]]:
                            res.Map[y][x] = 0
                            break
        return res

    def Update(self, brick, idx, col, row):

        res = Board()
        res.Map = copy.deepcopy(self.Map)

        for delta in brick:
            res.Map[row + delta[1]][col + delta[0]] = idx

        res.RemoveLines()
        return res

    def RemoveLines(self):

        for y in range(C_MAX_Y):
            if 0 not in self.Map[y]:
                for k in range(y,0,-1):
                    self.Map[k] = self.Map[k-1]
                self.Map[0] = [0] * C_MAX_X


    def GetMaxRow(self, start):

        res = [-1] * C_MAX_X

        for x in range(C_MAX_X):
            for y in range(start, C_MAX_Y):
                if self.Map[y][x]:
                    res[x] = y
                else:
                    break
        return res

    def Score(self):

        res = 0

        for y in range(C_MAX_Y):
            for x in range(C_MAX_X):

                if self.Map[y][x]:
                    points = (C_MAX_Y-y) * 2

                    if x == 0 or x == C_MAX_X-1:
                        edge = 1
                    else:
                        edge = 0

                    if y < C_MAX_Y-1:
                        if self.Map[y+1][x] == 0:
                            points *= (2 + edge*2)

                    val = points - 1*edge

                    res += val

        return res

    def Print(self):

        for y in range(C_MAX_Y):
            print( self.Map[y])
        input("Press Enter to continue...")





def AIMain():


    Moves = [Insert_New, Down, Left, Right, CW, CCW]

    BrickMap = {}

    for b in Bricks:
        item = Bricks[b]
        BrickMap[item.code] = {}
        for r in range(4):
            BrickMap[item.code][r] = []
            for m in Moves:
                BrickMap[item.code][r].append(item.Move(m))
            item.RotCW()

    cur_board = Board()

    score = 1
    cur_brick  = 7 # random.randint(1, 7)
    cur_rot    = 1 # random.randint(0, 3)
    next_brick = [7,6,6,1,7,3,7,5,4,3] # random.randint(1, 7)
    next_rot   = [0,2,2,3,2,3,2,0,1,0]  # random.randint(0, 3)

    # Game Loop
    while score < 1000:

        [score, col, row, r] = ScoreBoards(BrickMap, cur_board, [cur_brick, next_brick[0]])

        if r < 0:
            break
        target = [ col, row, r]
        path = GetPath(BrickMap, cur_board, cur_brick, cur_rot, target)
        cur_board = cur_board.Update(BrickMap[cur_brick][r][0][0], cur_brick, col,row)

        cur_brick = next_brick[0]
        cur_rot = next_rot[0]
        next_brick.pop(0) # = random.randint(1, 7)
        next_rot.pop(0) # = random.randint(0, 3)
        print(score)
        #cur_board.Print()


def Dist(pos1, pos2):

    if pos1[2] > pos2[2] : # start > target
        r = 4 + pos2[2] - pos1[2]
    else:
        r = pos2[2] - pos1[2]

    return abs(pos1[0] - pos2[0]) + r # abs(pos1[1] - pos2[1]) + r

def GetPath(BrickMap, cur_board, cur_brick, cur_rot, target):

    maps = {}
    for r in range(4):
        maps[r] = cur_board.GetPositions(BrickMap[cur_brick][r][0][0])
    start = list(Bricks[cur_brick].init_pos[cur_rot]) + [cur_rot]
    return Path(maps,start,target)



def Path(maps, start, target):
    dist = 1

    OPS = [MDown, MLeft, MRight, Rot]
    #OPS = [MDown, Rot, MLeft, MRight]

    idx = 0

    open_nodes = [(start,0,0,idx)]
    used_nodes = []
    DeadEnd = False

    while open_nodes and dist:

        (cur_pos, cur_mv, down_counter, cur_idx) = open_nodes.pop(0)

        if DeadEnd:
            while cur_idx < used_nodes[0][2]:
               used_nodes.pop(0)
            idx = cur_idx

        dist = Dist(cur_pos, target)
        if open_nodes:
            used_nodes.insert(0, (cur_pos, cur_mv, cur_idx))
        DeadEnd = True

        for mv, op in enumerate(OPS):
            res = op(cur_pos, down_counter)

            if res:
                if maps[res[2]].Map[res[1]][res[0]]:

                    if Dist(res, target) <= dist:
                        idx += 1

                        if mv == 0 or down_counter==C_DOWN_PHASE-1:  # Down
                            new_down_counter = 1
                        else:
                            new_down_counter = (down_counter + 1) % (C_DOWN_PHASE)

                        open_nodes.insert(0,(res,mv, new_down_counter, idx))
                        DeadEnd = False

    if dist==0:
        print(used_nodes)
        return used_nodes




def ScoreBoards(BrickMap, start_board, bricks):

    best = [1000,-1,-1,-1]
    cur_brick = bricks.pop(0)

    cur_pos = {}
    max_row = {}
    for r in range(4):
        cur_pos[r] = start_board.GetPositions(BrickMap[cur_brick][r][0][0])
        max_row[r] = cur_pos[r].GetMaxRow(Bricks[cur_brick].init_pos[r][1])
        for col, row in enumerate(max_row[r]):
            if row >= 0:
                updated_board = start_board.Update(BrickMap[cur_brick][r][0][0], cur_brick, col, row)
                if bricks:
                    score = ScoreBoards(BrickMap, updated_board, bricks.copy())
                else:
                    score = [updated_board.Score(), col, row, r]
                if score[0] < best[0]:
                    best = [score[0], col, row, r]
    return best


def Rot(i, dcount):
    down = 0
    if dcount == C_DOWN_PHASE - 1:
        if i[1] < C_MAX_Y - 1:
            down = 1

    res = i.copy()
    res[1] += down

    if i[2] + 1 > 3:
        res[2] = 4 - i[2] - 1
    else:
        res[2] = i[2] + 1
    return res

def MLeft(i, dcount):
    down = 0
    if dcount == C_DOWN_PHASE-1:
        if i[1] < C_MAX_Y - 1:
            down = 1

    if i[0] > 0:
        return [i[0]-1, i[1]+down, i[2]]
    else:
        return 0

def MRight(i, dcount):

    down = 0
    if dcount == C_DOWN_PHASE - 1:
        if i[1] < C_MAX_Y - 1:
            down = 1

    if i[0] < C_MAX_X-1:
        return [i[0]+1, i[1]+down, i[2]]
    else:
        return 0

def MDown(i,dcount):
    if i[1] < C_MAX_Y - 1:
        return [i[0], i[1]+1, i[2]]
    else:
        return 0

def colors_256(color_):
    num1 = str(color_)
    num2 = str(color_).ljust(3, ' ')
    if color_ % 16 == 0:
        return (f"\033[38;5;{num1}m {num2} \033[0;0m\n")
    else:
        return (f"\033[38;5;{num1}m {num2} \033[0;0m")