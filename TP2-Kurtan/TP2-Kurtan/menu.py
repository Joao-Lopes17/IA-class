from pyswip import Prolog
from simulated_annealing import run_simulated_annealing
from genetic_algorithm import run_genetic_algorithm
import os

def show_menu():
    print("====== Kurtan Game Menu ======")
    print("1. Player Mode")
    print("2. Iterative Deepening Mode")
    print("3. A* (Best-First Search) Mode")
    print("4. Simulated Annealing Mode (Python)")
    print("5. Genetic Algorithm Mode (Python)")
    print("Choose an option (1-5): ", end='')

def run_player_mode():
    print("Player mode selected.")
    os.system("swipl -g start_game -s tabuleiro.pl")

def run_iterative_deepening():
    print("Iterative Deepening selected.")
    prolog = Prolog()
    prolog.consult("tabuleiro.pl")
    prolog.consult("IT.pl")
    query = "solve_ids."
    for result in prolog.query(query):
        print("Solution found!")

def run_astar():
    print("A* selected.")
    prolog = Prolog()
    prolog.consult("astar.pl")
    query = "show_path"
    for result in prolog.query(query):
        print("Solution found!")

def main():
    show_menu()
    try:
        option = int(input())
    except ValueError:
        print("Invalid input.")
        return

    if option == 1:
        run_player_mode()
    elif option == 2:
        run_iterative_deepening()
    elif option == 3:
        run_astar()
    elif option == 4:
        run_simulated_annealing()
    elif option == 5:
        run_genetic_algorithm()
    else:
        print("Invalid option. Please choose a number between 1 and 5.")

if __name__ == "__main__":
    main()
