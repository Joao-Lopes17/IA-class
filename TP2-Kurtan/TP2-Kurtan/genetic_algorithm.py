import random
import matplotlib.pyplot as plt
from dataclasses import dataclass
import numpy as np
from kurtan_utils import GameState, apply_pull, find_gate_position, find_key_position, is_box_stuck, manhattan
from copy import deepcopy

from tabuleiro import BOX, BOX_ON_TARGET, TARGET_POSITIONS, WALL

@dataclass
class GAResult:
    NumEvaluations: int
    Cost: float
    tmax: int
    popSize: int
    crossProb: float
    mutProb: float
    u: any
    s: any
    Fit: list

# GA Genetic Algorithm
#   Make t = 0;
#   Initialize the population P(0), at random.
#   Evaluate P(0)
#   Repeat step 1 to 5 (until close to saturation)
#     Step 1 t = t+1
#     Step 2 Select the fittest from P(t-1) to build P(t)
#     Step 3 Cross P(t)
#     Step 4 Mutate some solution from P(t)
#     Step 5 Evaluate P(t)
    
def genetic_algorithm(data, tmax, popSize, crossProb, mutProb, sense):

    num_evaluations = 0
    found_optimum = False

    pop = get_initial_population(data, popSize)
    pop_fit = evaluate_population(data, pop)
    num_evaluations += popSize

    Fit = []
    MeanFit = []

    fu, _ = get_best_fitness(pop_fit, sense)
    Fit.append(fu)
    MeanFit.append(np.mean(pop_fit))

    t = 0
    while t < tmax and not found_optimum:
        # Step 1 Increment iteration index
        t += 1
        # Step 2 Select the fittest from P(t-1) to build P(t)
        pop = select(pop, pop_fit)
        # Step 3 Cross P(t)
        pop = cross(data, pop, crossProb)
        # Step 4 Mutate some solution from P(t)
        pop = mutate(data, pop, mutProb)
        # Step 5 Evaluate P(t)
        pop_fit = evaluate_population(data, pop)

        num_evaluations += popSize
        fu, _ = get_best_fitness(pop_fit, sense)
        print(f"Generation {t}, Best Fitness = {fu}")
        Fit.append(fu)
        MeanFit.append(np.mean(pop_fit))

        if is_optimum(fu, data):
            found_optimum = True

    fu, I = get_best_fitness(pop_fit, sense)
    u = pop[I[0]]

    print('BestCost:', fu)
    print('NumEvaluations:', num_evaluations)

    # Plot absolute fitness over generations
    plt.figure(1)
    plt.plot(Fit)
    plt.title("Best Fitness over Generations")
    plt.xlabel("Generation")
    plt.ylabel("Best Fitness")
    plt.grid(True)

    # Plot fitness percentage vs. optimum
    i = list(range(1, t + 2))
    Fit_pct = [f / data['optimum'] * 100 for f in Fit]
    MeanFit_pct = [m / data['optimum'] * 100 for m in MeanFit]
    plt.figure(2)
    plt.plot(i, Fit_pct, 'k-', label='Pop Max')
    plt.plot(i, MeanFit_pct, 'k:', label='Pop Mean')
    plt.xlabel('Generation no.')
    plt.ylabel('Fitness (%)')
    plt.axis([1, t + 1, 50, 110])
    plt.legend()
    plt.grid(True)
    plt.show()

    return GAResult(num_evaluations, fu, tmax, popSize, crossProb, mutProb, u, u, Fit)

# Genetic algortihm utility functions
def get_initial_population(data, pop_size):
    return [generate_random_move_sequence(data['N']) for _ in range(pop_size)]

def generate_random_move_sequence(data, length=10):
    return [random.choice(['up', 'down', 'left', 'right']) for _ in range(length)]

def evaluate_population(data, population):
    return [eval_func(individual, data) for individual in population]

def get_best_fitness(pop_fit, sense):
    if sense == 'maximize':
        best_val = max(pop_fit)
    elif sense == 'minimize':
        best_val = min(pop_fit)
    else:
        raise ValueError("sense must be 'maximize' or 'minimize'")
    indices = [i for i, val in enumerate(pop_fit) if val == best_val]
    return best_val, indices

# Selection
def select(pop, pop_fit, tournament_size=2):
    new_pop = []
    for _ in range(len(pop)):
        competitors = random.sample(list(zip(pop, pop_fit)), tournament_size)
        winner = min(competitors, key=lambda x: x[1])[0]  # menor custo
        new_pop.append(winner)
    return new_pop

# Crossover
def cross(data, pop, cross_prob):
    new_pop = []
    for i in range(0, len(pop), 2):
        parent1 = pop[i]
        if i + 1 >= len(pop):
            new_pop.append(parent1)
            break
        parent2 = pop[i + 1]

        if random.random() < cross_prob:
            point = random.randint(1, len(parent1) - 2)
            child1 = parent1[:point] + parent2[point:]
            child2 = parent2[:point] + parent1[point:]
            new_pop.append(child1)
            new_pop.append(child2)
        else:
            new_pop.append(parent1)
            new_pop.append(parent2)
    return new_pop

# Mutation
def mutate(data, population, mut_prob):
    for individual in population:
        if random.random() < mut_prob:
            idx = random.randint(0, len(individual)-1)
            individual[idx] = random.choice(['up', 'down', 'left', 'right'])
    return population

def eval_func(individual, data):
    state = GameState(deepcopy(data['board']))
    total_distance = 0
    penalty = 0
    real_moves = 0
    for move in individual:
        success, _ = state.move(move)
        if not success:
            continue  # Try net moves
        else:
            real_moves += 1
            print("----------------------------------")
            print("After moving:", move)
            state.print_board()
            print("Player position:", state.player_pos)
            if is_box_stuck(state, move):
                print("Box stuck. before pull.")
                pulled = apply_pull(state, move)
                print("----------------------------------")
                if pulled:
                    state = pulled

        if state.is_goal_state():
            return 0
    board = state.board
    box_positions = []

    # 1. If the key is not visible, calculate the distance of the boxes to the targets
    if not state.key_visible:
        for i, row in enumerate(board):
            for j, cell in enumerate(row):
                if cell in [BOX, BOX_ON_TARGET]:
                    box_positions.append((i, j))

        for (bx, by) in box_positions:
            if (bx, by) not in TARGET_POSITIONS:
                distances = [manhattan((bx, by), (tx, ty)) for (tx, ty) in TARGET_POSITIONS]
                if distances:
                    total_distance += min(distances)

            # Penalise stuck boxes
            blocked_sides = 0
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = bx + dx, by + dy
                if not state.is_within_bounds(nx, ny):
                    blocked_sides += 1
                else:
                    neighbor = state.cell_at(nx, ny)
                    if neighbor in [WALL, BOX, BOX_ON_TARGET]:
                        blocked_sides += 1
            if blocked_sides >= 3:
                penalty += 20

    else:
        if not state.key_picked:
            key_pos = find_key_position(state.board)
            penalty += manhattan(state.player_pos, key_pos)
        else :
            gate_pos = find_gate_position(state.board)
            penalty += manhattan(state.player_pos, gate_pos)
    return real_moves + penalty + total_distance

def is_optimum(fitness, data):
    return fitness <= data['optimum']  # Define the optimum condition

# Run the genetic algorithm
def run_genetic_algorithm():
    print("Genetic Algorithm (Python) selected.")
    tmax = 100
    popSize = 30
    crossProb = 0.8
    mutProb = 0.2
    sense = 'minimize'
    N = 10  # Number of movements in the sequence
    optimum = 0 

    initial_state = GameState()
    data = {
        'N': N,
        'optimum': optimum,
        'board': initial_state.board
    }

    genetic_algorithm(
        data, tmax, popSize, crossProb, mutProb,
        sense
    )

    print("Final solution:")
