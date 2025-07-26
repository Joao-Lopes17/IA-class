# Artificial Intelligence (IA) Course Projects

This repository contains two academic projects developed as part of the **Artificial Intelligence** course in the [Bachelor’s Degree in Computer Engineering at ISEL](https://isel.pt).

Each project explores different AI techniques and problem-solving strategies using Prolog and Python.

---

## 📁 Project Structure

- [`TP1-Checkers`](./TP1-Checkers): A Prolog-based implementation of the classic Checkers game, including an AI opponent using minimax and the alpha-beta pruning algorithm.
- [`TP2-Kurtan`](./TP2-Kurtan): An automated solver for the Sokoban-inspired "Kurtan" game, using various search and optimization algorithms in Prolog and Python, such as Iterative-Deepening, A*, SA (Simulated Annealing) and GA (Genetic Algorithm, not yet implemented).

---

## ♟️ TP1 - Checkers Game (Prolog)

This project consists of implementing the game of **Checkers** in Prolog. It supports two modes:
- **Human vs Human**
- **Human vs Computer** (AI using **minimax** on a smaller board, and **alpha-beta pruning**, a more efficient version of minimax, on a normal board)

### Features
- Text-based interface (input via keyboard, output displayed in the console)
- Unicode rendering of pieces (● for black, ○ for white)
- Configurable board sizes (used for testing performance of the algorithms)
- AI opponent based on minimax and alpha-beta search with optional depth limitation


> The game board is implemented using Prolog lists. Input/output uses standard predicates such as `read/1` and `write/1`.

---

## 📦 TP2 - Kurtan Game Solver (Prolog + Python)

This project focuses on solving a variant of the **Sokoban** game called **Kurtan**. The goal is to push boxes to target positions, interact with gates and keys, and guide the player to a final goal cell.

### Game Mechanics
- The player can only **push** boxes (no pulling)
- **Keys** appear after a certain number of boxes are placed
- Picking up a key opens **gates**
- The character must reach the **gate cell** (`G`) after solving the puzzle and getting the key

### Algorithms Implemented

#### In Prolog:
- `Iterative Deepening` (uninformed search)
- `A* Search` or `Best-First Search` (informed search with admissible heuristics)

#### In Python:
- `Simulated Annealing` (metaheuristic optimization)

### Algorithms Not yet Implemented:
- `Genetic Algorithms` (evolutionary optimization)

> These algorithms are used to demonstrate and compare different approaches to problem-solving in AI, from classic search to probabilistic optimization.

---

## 🧠 Technologies Used

- **Prolog** (SWI-Prolog)
- **Python**

---

## 📚 References

- [Checkers (Wikipedia)](https://en.wikipedia.org/wiki/Checkers)
- [Sokoban (Wikipedia)](https://en.wikipedia.org/wiki/Sokoban)
- [Play Kurtan Online](https://www.myabandonware.com/game/kurtan-1vs/play-1vs)

---

## 📎 License

This repository was created for academic purposes and is shared for learning and reference. No commercial use intended.
