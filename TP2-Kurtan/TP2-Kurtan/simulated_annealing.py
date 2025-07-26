import random
import math
from dataclasses import dataclass
import matplotlib.pyplot as plt
from kurtan_utils import (
    apply_pull, find_gate_position, find_key_position, is_box_stuck
)
from tabuleiro import (
    GameState, TARGET_POSITIONS,
    EMPTY, TARGET, PLAYER, BOX_ON_TARGET, BOX, WALL, GATE, KEY,
    direction_to_delta
)

@dataclass
class SAResult:
    T: float
    NumEvaluations: int
    Cost: float
    Tmax: float
    Tmin: float
    R: float
    k: int
    best_state: any
    F: list
    final_solution: any

def simulated_annealing(Tmax, Tmin, R, k, data, sense='minimize'):
    t = 0
    T = Tmax
    num_evaluations = 0
    found_optimum = False

    u = get_initial_solution(data)
    fu = eval_func(u)
    num_evaluations += 1
    F = [fu]

    while not found_optimum:
        i = 0
        while i < k and not found_optimum:
            v = get_random_neigh(u)
            if( v == u ): continue
            fv = eval_func(v)
            num_evaluations += 1

            dif = fv - fu
            if sense == 'maximize':
                dif = -dif

            if dif < 0:
                u = v
                fu = fv
            else:
                prob = math.exp(-dif / T) if fu != 0 else 0
                if random.random() < prob:
                    u = v
                    fu = fv

            F.append(fu)

            if is_optimum(u):
                found_optimum = True

            i += 1

        t += 1
        T = Tmax * math.exp(-R * t)
        if T < Tmin:
            break

    print(f"Final cost: {fu}")
    print(f"Evaluations: {num_evaluations}")
    plt.plot(F)
    plt.title("SA Cost Evolution")
    plt.xlabel("Iterations")
    plt.ylabel("Cost")
    plt.show()

    print("Final solution:")
    u.print_board()
    return SAResult(T, num_evaluations, fu, Tmax, Tmin, R, k, u, F, u)

# Simulated Annealing Utitilities functions
DIRECTIONS = ['up', 'down', 'left', 'right']

def get_initial_solution(data):
    return GameState()

def get_random_neigh(state: GameState):
    for _ in range(10):
        new_state = state.clone()
        directions = DIRECTIONS.copy()
        random.shuffle(directions)
        for direction in directions:
            moved, _ = new_state.move(direction)
            print("----------------------------------")
            print("After moving:", direction)
            new_state.print_board()
            print("Player position:", new_state.player_pos)
            if moved:
                #caixa presa
                box_stuck = is_box_stuck(new_state, direction)
                if box_stuck:
                    print("Box stuck. before pull.")
                    pulled = apply_pull(new_state, direction)
                    print("----------------------------------")
                    if pulled:
                        return pulled
                return new_state
    return state

def eval_func(state: GameState):
    board = state.board
    total_distance = 0
    penalty = 0
    box_positions = []
    if not state.key_visible:
        for i, row in enumerate(board):
            for j, cell in enumerate(row):
                if cell in [BOX, BOX_ON_TARGET]:
                    box_positions.append((i, j))

        for (bx, by) in box_positions:
            if (bx, by) not in TARGET_POSITIONS:
                distances = [abs(bx - gx) + abs(by - gy) for (gx, gy) in TARGET_POSITIONS]
                if distances:
                    total_distance += min(distances)

            # Penalise stuck boxes
            blocked_sides = 0
            for dx, dy in [(-1,0), (1,0), (0,-1), (0,1)]:
                nx, ny = bx + dx, by + dy
                if not state.is_within_bounds(nx, ny):
                    blocked_sides += 1
                else:
                    neighbor = state.cell_at(nx, ny)
                    if neighbor in [WALL, BOX, BOX_ON_TARGET]:
                        blocked_sides += 1
            if blocked_sides >= 3:
                penalty += 20

     # 2. Penalise if the key is visible but not picked
    if state.key_visible and not state.key_picked:
        key_pos = find_key_position(board)
        if key_pos:
            px, py = state.player_pos
            kx, ky = key_pos
            dist_to_key = abs(px - kx) + abs(py - ky)
            penalty += 10 + dist_to_key

    # 3. Penalise if it has the key already but did not leave yet
    if state.key_picked and not state.game_over:
        # Find gate
        gate_pos = find_gate_position(board)
        if gate_pos:
            px, py = state.player_pos
            gx, gy = gate_pos
            dist_to_gate = abs(px - gx) + abs(py - gy)
            penalty += 10 + dist_to_gate

    return total_distance + penalty



def is_optimum(state: GameState):
    return state.key_picked and state.game_over

# Run the simulated annealing algorithm
def run_simulated_annealing():
    print("Simulated Annealing (Python) selected.")
    Tmax = 100
    Tmin = 0.001
    R = 0.01
    k = 10
    simulated_annealing(Tmax, Tmin, R, k, data={})