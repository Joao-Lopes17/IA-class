:- dynamic board/1, key_picked/1, key_visible/1, game_over/1.

% Target positions
place_is_target(1, 3).
place_is_target(2, 4).
place_is_gate(3, 2).
place_is_key(1, 1).

key_picked(false).
key_visible(false).
game_over(false).

board([
    ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X'],
    ['X', ' ', ' ', '*', ' ', ' ',' ', 'X', 'X', 'X'],
    ['X', ' ', ' ', '@', '*', ' ',' ', 'X', 'X', 'X'],
    ['X', ' ', 'G', 'P', '@', ' ',' ', 'X', 'X', 'X'],
    ['X', ' ', ' ', ' ', ' ', ' ',' ', 'X', 'X', 'X'],
    ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X']
]).

print_board([]).
print_board([Row | Rest]) :-
    print_row(Row), nl,
    print_board(Rest).

print_row([]).
print_row([Cell | Rest]) :-
    write(Cell), write(' '),
    print_row(Rest).

find_player(Board, X, Y) :-
    nth0(X, Board, Row),
    nth0(Y, Row, 'P').

move(_Direction) :-
    game_over(true), !,
    write('Game over. Use restart_game to play again.'), nl.

move(Direction) :-
    board(Board),
    find_player(Board, X, Y),
    ( move_player(Board, Direction, X, Y, TempBoard) ->
        maybe_show_key(TempBoard, FinalBoard),
        retract(board(Board)),
        assert(board(FinalBoard)),
        print_board(FinalBoard),
        check_win(FinalBoard)
    ;   write('Invalid move.'), nl, false).

move_player(Board, up, X, Y, NewBoard) :-
    NewX is X - 1,
    handle_move(Board, X, Y, NewX, Y, NewBoard).
move_player(Board, down, X, Y, NewBoard) :-
    NewX is X + 1,
    handle_move(Board, X, Y, NewX, Y, NewBoard).
move_player(Board, left, X, Y, NewBoard) :-
    NewY is Y - 1,
    handle_move(Board, X, Y, X, NewY, NewBoard).
move_player(Board, right, X, Y, NewBoard) :-
    NewY is Y + 1,
    handle_move(Board, X, Y, X, NewY, NewBoard).

handle_move(Board, X, Y, NewX, NewY, NewBoard) :-
    is_within_bounds(Board, NewX, NewY),
    nth0(NewX, Board, Row),
    nth0(NewY, Row, TargetCell),
    (
        % Move to an empty cell
        TargetCell = ' ',
        update_board(Board, X, Y, NewX, NewY, NewBoard)
    ;
        % Move to a gate cell(only with a key)
        TargetCell = 'G',
        key_picked(true),
        replace(Board, X, Y, ' ', TempBoard),
        replace(TempBoard, NewX, NewY, '♛', NewBoard),
        write('You won!'), nl,
        retract(game_over(false)),
        assert(game_over(true)),
        write('Game over. Use restart_game to play again.'), nl
    ;
        % Move to target '*'
        TargetCell = '*',
        update_board(Board, X, Y, NewX, NewY, NewBoard)
    ;
        % Move to key 'K'
        TargetCell = 'K',
        key_visible(true),
        retract(key_picked(false)),
        assert(key_picked(true)),
        write('Key picked up! Gate can now be opened.'), nl,
        update_board(Board, X, Y, NewX, NewY, NewBoard)
    ;
    
        % Push box '@' or '$'
        (member(TargetCell, ['@', '$']),
         push_box(Board, X, Y, NewX, NewY, TempBoard, TargetCell),
         update_board(TempBoard, X, Y, NewX, NewY, NewBoard))

    ), !.


push_box(Board, X, Y, NewX, NewY, NewBoard, BoxType) :-
    NextX is NewX + (NewX - X),
    NextY is NewY + (NewY - Y),
    is_within_bounds(Board, NextX, NextY),
    nth0(NextX, Board, Row),
    nth0(NextY, Row, NextCell),
    (NextCell = ' '; NextCell = '*'),
    update_box(Board, NewX, NewY, NextX, NextY, TempBoard, BoxType),
    NewBoard = TempBoard.


update_board(Board, X, Y, NewX, NewY, NewBoard) :-
    cell_at(Board, X, Y, OldCell),
    (OldCell = 'P', cell_under(Board, X, Y, UnderOld), true ; UnderOld = ' '),
    (UnderOld = '*' -> replace(Board, X, Y, '*', TempBoard) ; replace(Board, X, Y, ' ', TempBoard)),
    replace(TempBoard, NewX, NewY, 'P', NewBoard).

cell_at(Board, X, Y, Cell) :-
    nth0(X, Board, Row),
    nth0(Y, Row, Cell).

cell_under(_, X, Y, '*') :-
    place_is_target(X, Y).
cell_under(_, _, _, ' ').

update_box(Board, X, Y, NewX, NewY, NewBoard, BoxType) :-
    nth0(NewX, Board, Row),
    nth0(NewY, Row, DestCell),
    (
        DestCell = '*' ->
            NewBox = '$'
        ;
            NewBox = '@'
    ),
    replace(Board, X, Y, ' ', TempBoard1),
    (BoxType = '$', place_is_target(X, Y) ->
        replace(TempBoard1, X, Y, '*', TempBoard2)
    ;
        TempBoard2 = TempBoard1
    ),
    replace(TempBoard2, NewX, NewY, NewBox, NewBoard).


check_key_pickup(Board) :-
    \+ (member(Row, Board), member('@', Row)).

% maybe_show_key_state(+Board, +KeyVisibleIn, -KeyVisibleOut, -NewBoard)
maybe_show_key_state(Board, false, true, NewBoard) :-
    \+ (member(Row, Board), member('@', Row)),  % all boxes placed
    write('[INFO] Key appeared in the room.'), nl,
    place_key(Board, NewBoard).  % place the key
maybe_show_key_state(Board, KeyVisible, KeyVisible, Board).

maybe_show_key(BoardIn, BoardOut) :-
    key_visible(Visible),
    maybe_show_key_state(BoardIn, Visible, NewVisible, TempBoard),
    (Visible \= NewVisible ->
        retractall(key_visible(_)),
        assert(key_visible(NewVisible))
    ;
        true
    ),
    BoardOut = TempBoard.

place_key(Board, NewBoard) :-
    place_key_in_empty(Board, NewBoard).

place_key_in_empty([], []).
place_key_in_empty([Row | Rest], [NewRow | Rest]) :-
    replace_first_empty(Row, NewRow),
    !.
place_key_in_empty([Row | Rest], [Row | NewRest]) :-
    place_key_in_empty(Rest, NewRest).

replace_first_empty([' ' | Rest], ['K' | Rest]) :- !.
replace_first_empty([Cell | Rest], [Cell | NewRest]) :-
    replace_first_empty(Rest, NewRest).


check_win(_Board) :-
    game_over(true),
    !.
check_win(_).

is_within_bounds(Board, X, Y) :-
    length(Board, NumRows),
    nth0(0, Board, Row),
    length(Row, NumCols),
    X >= 0, X < NumRows,
    Y >= 0, Y < NumCols.

replace([Row | Rest], 0, Y, NewElem, [NewRow | Rest]) :-
    replace_row(Row, Y, NewElem, NewRow).
replace([Row | Rest], X, Y, NewElem, [Row | NewRest]) :-
    X > 0,
    X1 is X - 1,
    replace(Rest, X1, Y, NewElem, NewRest).

replace_row([_ | Rest], 0, NewElem, [NewElem | Rest]).
replace_row([Cell | Rest], Y, NewElem, [Cell | NewRest]) :-
    Y > 0,
    Y1 is Y - 1,
    replace_row(Rest, Y1, NewElem, NewRest).

% Short commands
u :- move(up).
d :- move(down).
l :- move(left).
r :- move(right).

start_game :-
    retractall(board(_)),
    retractall(key_picked(_)),
    retractall(key_visible(_)),
    retractall(game_over(_)),
    assert(key_picked(false)),
    assert(key_visible(false)),
    assert(game_over(false)),
    Board = [
        ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X'],
        ['X', ' ', ' ', '*', ' ', ' ',' ', 'X', 'X', 'X'],
        ['X', ' ', ' ', '@', '*', ' ',' ', 'X', 'X', 'X'],
        ['X', ' ', 'G', 'P', '@', ' ',' ', 'X', 'X', 'X'],
        ['X', ' ', ' ', ' ', ' ', ' ',' ', 'X', 'X', 'X'],
        ['X', 'X', 'X', 'X', 'X', 'X','X', 'X', 'X', 'X']
    ],
    assert(board(Board)),
    print_board(Board).

restart_game :-
    write('Restarting the game...'), nl,
    start_game.