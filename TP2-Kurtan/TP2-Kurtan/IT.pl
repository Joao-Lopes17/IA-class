:- consult('Tabuleiro.pl').

iterative_deepening(Start, Solution) :-
    iterative_deepening(Start, 1, Solution).

iterative_deepening(Start, Depth, Solution) :-
    format('Trying with deepth ~w~n', [Depth]),
    ( depth_limited_search(Start, [], Depth, Solution) ->
        true
    ;
        D2 is Depth + 1,
        iterative_deepening(Start, D2, Solution)
    ).

depth_limited_search(Node, _, 0, [Node]) :-
    goal_state(Node),
    format('Goal found: ~w~n', [Node]).

depth_limited_search(Node, Visited, Depth, [Node | RestPath]) :-
    Depth > 0,
    successor(Node, Next),
    \+ member(Next, Visited),
    format('Expanding: ~w, Depth remanining: ~w~n', [Next, Depth]),
    D1 is Depth - 1,
    depth_limited_search(Next, [Node | Visited], D1, RestPath).

% Get valid successor states (up, down, left, right)
successor(estado(Pos, Boxes, KeyPicked), estado(NewPos, NewBoxesSorted, NewKeyPicked)) :-
    direction(DX, DY),
    move(estado(Pos, Boxes, KeyPicked), DX, DY, estado(NewPos, NewBoxes, NewKeyPicked)),
    sort(NewBoxes, NewBoxesSorted).

% Directions
direction(-1, 0).  % up
direction(1, 0).   % down
direction(0, -1).  % left
direction(0, 1).   % right

% Get key move (when it is not picked up yet)
move(estado((X,Y), Boxes, false), DX, DY, estado((NX, NY), Boxes, true)) :-
    NX is X + DX,
    NY is Y + DY,
    place_is_key(NX, NY),
    valid_pos((NX, NY), false),
    \+ member((NX, NY), Boxes).

% Normal movement (does not metter if it has a key or not)
move(estado((X,Y), Boxes, KeyPicked), DX, DY, estado((NX, NY), Boxes, KeyPicked)) :-
    NX is X + DX,
    NY is Y + DY,
    \+ place_is_key(NX, NY),
    valid_pos((NX, NY), KeyPicked),
    \+ member((NX, NY), Boxes).

% Push box movement
move(estado((X,Y), Boxes, KeyPicked), DX, DY, estado((NX, NY), NewBoxes, KeyPicked)) :-
    NX is X + DX,
    NY is Y + DY,
    member((NX, NY), Boxes),
    NNX is NX + DX,
    NNY is NY + DY,
    valid_pos((NNX, NNY), KeyPicked),
    \+ member((NNX, NNY), Boxes),
    select((NX, NY), Boxes, Temp),
    NewBoxes = [(NNX, NNY) | Temp].

% Goal state: all boxes on targets and player at gate
goal_state(estado((X,Y), Boxes, true)) :-
    findall((TX, TY), place_is_target(TX, TY), Targets),
    sort(Boxes, SBoxes),
    sort(Targets, STargets),
    SBoxes == STargets,
    place_is_gate(GX, GY),
    X = GX,
    Y = GY.

% Valid position -> not walls, out of bounds, and if key is picked up, can be on gate
valid_pos((X, Y), KeyPicked) :-
    board(Board),
    is_within_bounds(Board, X, Y),
    cell_at(Board, X, Y, Cell),
    (
        KeyPicked = true, member(Cell, [' ', '*', 'G']);
        KeyPicked = false, member(Cell, [' ', '*'])
    ).

% Solve with iterative_deepening_ids
solve_ids :-
    board(Board),
    find_player(Board, PX, PY),
    findall((BX, BY),
            (nth0(BX, Board, Row), nth0(BY, Row, C), member(C, ['@', '$'])),
            Boxes),
    sort(Boxes, SortedBoxes),  % normalizar
    iterative_deepening(estado((PX, PY), SortedBoxes, false), Solution),
    print_solution(Solution).

print_solution([]).
print_solution([estado((X,Y), Boxes, Key) | Rest]) :-
    format('Player: (~w,~w), Boxes: ~w, Key: ~w~n', [X, Y, Boxes, Key]),
    print_solution(Rest).
