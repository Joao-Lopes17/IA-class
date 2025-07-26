from copy import deepcopy

WALL = 'X'
PLAYER = 'P'
BOX = '@'
BOX_ON_TARGET = '$'
TARGET = '*'
GATE = 'G'
KEY = 'K'
EMPTY = ' '

TARGET_POSITIONS = [(1, 3), (1, 5), (2, 4)]

class GameState:
    def __init__(self, board=None, key_picked=False, key_visible=False, game_over=False):
        self.board = board if board else self.initial_board()
        self.key_picked = key_picked
        self.key_visible = key_visible
        self.game_over = game_over
        self.player_pos = self.find_player()

    def initial_board(self):
        return [
            ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X'],
            ['X', 'X', ' ', '*', ' ', '*','X', 'X', 'X', 'X'],
            ['X', ' ', ' ', '@', '*', ' ','X', 'X', 'X', 'X'],
            ['X', ' ', 'G', 'P', '@', '@','X', 'X', 'X', 'X'],
            ['X', ' ', ' ', ' ', ' ', ' ',' ', 'X', 'X', 'X'],
            ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X']
        ]

    def find_player(self):
        for i, row in enumerate(self.board):
            for j, cell in enumerate(row):
                if cell == PLAYER:
                    return (i, j)
        return None

    def is_within_bounds(self, x, y):
        return 0 <= x < len(self.board) and 0 <= y < len(self.board[0])

    def cell_at(self, x, y):
        return self.board[x][y] if self.is_within_bounds(x, y) else None

    def cell_under(self, x, y):
        return TARGET if (x, y) in TARGET_POSITIONS else EMPTY

    def move(self, direction):
        if self.game_over:
            return False, "Game is over."

        dx, dy = direction_to_delta(direction)
        px, py = self.player_pos
        nx, ny = px + dx, py + dy

        if not self.is_within_bounds(nx, ny):
            return False, "Out of bounds."

        target_cell = self.cell_at(nx, ny)

        if target_cell in [EMPTY, TARGET]:
            self.update_board(px, py, nx, ny)
        elif target_cell == GATE and self.key_picked:
            self.update_board(px, py, nx, ny, win=True)
            self.game_over = True
        elif target_cell == KEY and self.key_visible:
            self.key_picked = True
            self.update_board(px, py, nx, ny)
        elif target_cell in [BOX, BOX_ON_TARGET]:
            if self.push_box(px, py, nx, ny, dx, dy, target_cell):
                self.update_board(px, py, nx, ny)
            else:
                return False, "Cannot push box."
        else:
            return False, "Invalid movement."

        if self.check_all_boxes_on_targets() and not self.key_visible:
            self.key_visible = True
            self.place_key()

        return True, "Moved."

    def update_board(self, px, py, nx, ny, win=False):
        if (px, py) in TARGET_POSITIONS:
            self.board[px][py] = TARGET
        else:
            self.board[px][py] = EMPTY

        self.board[nx][ny] = '♛' if win else PLAYER
        self.player_pos = (nx, ny)

    def push_box(self, px, py, bx, by, dx, dy, box_type):
        nx, ny = bx + dx, by + dy
        if not self.is_within_bounds(nx, ny):
            return False

        dest_cell = self.cell_at(nx, ny)
        if dest_cell not in [EMPTY, TARGET]:
            return False

        # move box
        self.board[nx][ny] = BOX_ON_TARGET if dest_cell == TARGET else BOX
        self.board[bx][by] = TARGET if (bx, by) in TARGET_POSITIONS else EMPTY
        return True

    def check_all_boxes_on_targets(self):
        for x, y in TARGET_POSITIONS:
            if self.board[x][y] not in [BOX_ON_TARGET]:
                return False
        return True

    def place_key(self):
        for i, row in enumerate(self.board):
            for j, cell in enumerate(row):
                if cell == EMPTY:
                    self.board[i][j] = KEY
                    return
                
    def is_goal_state(self):
        return self.check_all_boxes_on_targets() and self.key_picked and self.game_over

    def clone(self):
        new_state = GameState(deepcopy(self.board), self.key_picked, self.key_visible, self.game_over)
        new_state.player_pos = self.player_pos
        return new_state

    def print_board(self):
        for row in self.board:
            print(' '.join(row))
        print()

def direction_to_delta(direction):
    return {
        'up': (-1, 0),
        'down': (1, 0),
        'left': (0, -1),
        'right': (0, 1)
    }[direction]
