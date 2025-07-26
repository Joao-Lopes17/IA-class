from tabuleiro import (
    GameState, TARGET_POSITIONS,
    EMPTY, TARGET, PLAYER, BOX_ON_TARGET, BOX, WALL, GATE, KEY,
    direction_to_delta
)
import random

def apply_pull(state: GameState, d:str):
    px, py = state.player_pos
    print("Player position:", px, py)
    print("Applying pull in direction relative to player:", d)
    dx, dy = direction_to_delta(d)
    bx, by = px + dx, py + dy

    box_cell = state.cell_at(bx, by)
    behind_box_x, behind_box_y = bx + dx, by + dy
    print("Box position:", bx, by)
    print("Behind box position:", behind_box_x, behind_box_y)
    print("Box cell:", box_cell)
    # BOX_ON_TARGET
    if box_cell in [BOX] and state.is_within_bounds(behind_box_x, behind_box_y): 
        behind_cell = state.cell_at(behind_box_x, behind_box_y)
        print("Pulling box...")
        #WALL
        if behind_cell in [WALL, GATE, BOX, KEY]:
            new_state = state.clone()

            # Move player in the oposite direction
            new_state.board[px][py] = TARGET if (px, py) in TARGET_POSITIONS else EMPTY
            # Move box to the last player position
            new_state.board[px][py] = BOX_ON_TARGET if (px, py) in TARGET_POSITIONS else BOX
            # Clean the box last position
            new_state.board[bx][by] = TARGET if (bx, by) in TARGET_POSITIONS else EMPTY

            new_px, new_py = px - dx, py - dy
            new_state.board[new_px][new_py] = PLAYER
            new_state.player_pos = (new_px, new_py)

            print("Box stuck. After pull:")
            print("----------------------------------")
            new_state.print_board()
            return new_state
    print("Box cannot be pulled.")
    return None

def is_box_stuck(state: GameState, direction: str):
    px, py = state.player_pos
    dx, dy = direction_to_delta(direction)
    bx, by = px + dx, py + dy

    if not state.is_within_bounds(bx, by):
        return False  # Box is out of bounds

    box_cell = state.cell_at(bx, by)
    if box_cell not in [BOX]:
        return False  # Not a box

    blocked_sides = []
    for ddx, ddy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        nx, ny = bx + ddx, by + ddy
        if not state.is_within_bounds(nx, ny) or state.cell_at(nx, ny) in [WALL, BOX, BOX_ON_TARGET]:
            blocked_sides.append((ddx, ddy))
    print("Blocked sides:", blocked_sides)
    if len(blocked_sides) == 0:
        return False
    if len(blocked_sides) == 1:
        # Verify if a future position can be a corner
        forward_x, forward_y = bx + dx, by + dy
        if state.is_within_bounds(forward_x, forward_y):
            if stuck_helper(state, (forward_x, forward_y)):
                return True
            
    if len(blocked_sides) >= 3:
        return True
    if len(blocked_sides) == 2:
        # Check if the two blocked sides are opposite
        if (blocked_sides[0][0] != 0 and blocked_sides[1][1] != 0 or
            blocked_sides[0][1] != 0 and blocked_sides[1][0] != 0):
            return True
    return False
    
def stuck_helper(state: GameState, pos: tuple):
    x, y = pos
    wall_like = [WALL, BOX, BOX_ON_TARGET]
    blocked_sides = 0

    for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
        nx, ny = x + dx, y + dy
        if not state.is_within_bounds(nx, ny):
            blocked_sides += 1
        else:
            neighbor = state.cell_at(nx, ny)
            if neighbor in wall_like:
                blocked_sides += 1

    return blocked_sides >= 3  # Trap if the next posittion is limited


def find_key_position(board):
    for i, row in enumerate(board):
        for j, cell in enumerate(row):
            if cell == KEY:
                return (i, j)
    return None

def find_gate_position(board):
    for i, row in enumerate(board):
        for j, cell in enumerate(row):
            if cell == GATE:
                return (i, j)
    return None

def manhattan(p1, p2):
    return abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])
