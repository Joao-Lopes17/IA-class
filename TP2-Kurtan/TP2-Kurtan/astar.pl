:- consult('Tabuleiro.pl').

% ----------------------------------
% Auxiliar predicates
% ----------------------------------

% Remove the first occurance of X on the list
remove(X, [X|T], T).
remove(X, [H|T], [H|R]) :-
    X \= H,
    remove(X, T, R).

% Distance beetween two points using Manhattan distance
manhattan((X1, Y1), (X2, Y2), D) :-
    D is abs(X1 - X2) + abs(Y1 - Y2).


free_cell(X, Y, Boxes) :-
    \+ member((X,Y), Boxes),
    board(Board),
    nth0(X, Board, Row),
    nth0(Y, Row, Cell),
    Cell \= 'X'.

% ----------------------------------
% Inicial state, goal and board
% ----------------------------------

% Inicialize the game state
init_state(estado(PlayerPos, BoxesPos, false)) :-
    board(Board),
    find_player(Board, Px, Py),
    findall((Bx, By),
            (nth0(Bx, Board, Row), nth0(By, Row, Cell), member(Cell, ['@', '$'])),
            BoxesPos),
    PlayerPos = (Px, Py).

% Goal state: all boxes on targets and player at gate
goal_state(estado(Pos, Boxes, true)) :-
    forall(place_is_target(X,Y), member((X,Y), Boxes)),
    place_is_gate(XG, YG),
    Pos = (XG, YG).


find_player(Board, Px, Py) :-
    nth0(Px, Board, Row),
    nth0(Py, Row, 'P').


% ----------------------------------
% Successors (possible moves)
% ----------------------------------

% Rule to pick up key if it is on the players position and not picked up yet
successor(estado((X,Y), Boxes, false), estado((NX,NY), Boxes, true), Move) :-
    member(Move-Diff, [up-( -1,  0),
                       down-( 1,  0),
                       left-( 0, -1),
                       right-( 0,  1)]),
    Diff = (DX, DY),
    NX is X + DX,
    NY is Y + DY,
    format('Trying to pick up key at (~w, ~w)...~n', [NX, NY]),
    place_is_key(NX, NY),
    free_cell(NX, NY, Boxes),
    format('Key picked up at ~w!~n', [Move]).

% Pick up key if player is on the key position and did not picked it up yet
successor(estado(Pos, Boxes, false), estado(Pos, Boxes, true), pick_key) :-
    place_is_key(X, Y),
    Pos = (X, Y).

% Normal movement
successor(estado((X,Y), Boxes, KP), estado((NX,NY), Boxes, KP), Move) :-
    member(Move-Diff, [up-( -1,  0),
                       down-( 1,  0),
                       left-( 0, -1),
                       right-( 0,  1)]),
    Diff = (DX, DY),
    NX is X + DX,
    NY is Y + DY,
    \+ member((NX, NY), Boxes),
    free_cell(NX, NY, Boxes).

% Push box movement
successor(estado((X,Y), Boxes, KP), estado((NX,NY), NewBoxes, KP), Move) :-
    member(Move-Diff, [up-( -1,  0),
                       down-( 1,  0),
                       left-( 0, -1),
                       right-( 0,  1)]),
    Diff = (DX, DY),
    NX is X + DX,
    NY is Y + DY,
    member((NX, NY), Boxes),       % There is a box to push
    BX2 is NX + DX,
    BY2 is NY + DY,
    free_cell(BX2, BY2, Boxes),    % Next cell is free
    remove((NX, NY), Boxes, TempBoxes),
    NewBoxes = [(BX2, BY2)|TempBoxes].

% ----------------------------------
% A* Heurístic
% ----------------------------------

heuristic(estado((X,Y), Boxes, false), H) :-
    % If it does not have a key, distance to it
    place_is_key(KX, KY),
    manhattan((X,Y), (KX, KY), H).

heuristic(estado((X,Y), Boxes, true), H) :-
    % If it has a key, distance to the gate
    place_is_gate(GX, GY),
    manhattan((X,Y), (GX, GY), H).

% ----------------------------------
% A* principal
% ----------------------------------

astar_search([node(State, Path, _)|_], _, Path) :-
    goal_state(State), !.

astar_search([node(State, Path, Cost)|Open], Closed, FinalPath) :-
    findall(
        node(Succ, [Move|Path], NewCost),
        (successor(State, Succ, Move),
         \+ member_state(Succ, Closed),
         NewCost is Cost + 1),
        Successors),
    append(Open, Successors, OpenTmp),
    sort_nodes(OpenTmp, OpenSorted),
    astar_search(OpenSorted, [State|Closed], FinalPath).

sort_nodes(Nodes, Sorted) :-
    map_list_to_pairs(node_f, Nodes, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

node_f(node(State, _Path, Cost), F) :-
    heuristic(State, H),
    F is Cost + H.

% Verify if the state is on the list
state_equal(estado(PosJ1, PosC1, KP1), estado(PosJ2, PosC2, KP2)) :-
    PosJ1 == PosJ2,
    sort(PosC1, SortedC1),
    sort(PosC2, SortedC2),
    SortedC1 == SortedC2,
    KP1 == KP2.

member_state(State, [H|_]) :- state_equal(State, H), !.
member_state(State, [_|T]) :- member_state(State, T).

astar(StartState, PathMoves) :-
    astar_search([node(StartState, [], 0)], [], RevPath),
    reverse(RevPath, PathMoves).

% ----------------------------------
% Print found path
% ----------------------------------

print_moves([]).
print_moves([M|Ms]) :-
    writeln(M),
    print_moves(Ms).

show_path :-
    write('Calculating path with A*...'), nl,
    init_state(S),
    ( astar(S, Path) ->
        write('Path found:'), nl,
        writeln(Path),
        print_moves(Path)
    ;   write('No path found.'), nl
    ).
