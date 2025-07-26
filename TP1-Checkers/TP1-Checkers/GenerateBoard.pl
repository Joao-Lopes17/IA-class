:- consult('minimax.pl').
:- consult('ValidMoves.pl').

% Generate the initial board
generateBoard(N, Board) :-
    length(Board, N),
    numlist(1, N, Rows),
    PiecesRows is ceiling(N / 2) - 1,
    ParityOffset is N mod 2,
    maplist(initRow(N, PiecesRows, ParityOffset), Rows, Board).

initRow(N, PiecesRows, ParityOffset, RowIndex, Row) :-
    length(Row, N),
    numlist(1, N, Cols),
    maplist(initCell(N, PiecesRows, ParityOffset, RowIndex), Cols, Row).

initCell(_, PiecesRows, ParityOffset, Row, Col, '●') :- 
    Row =< PiecesRows,
    (Row + Col + ParityOffset) mod 2 =:= 1.
initCell(N, PiecesRows, ParityOffset, Row, Col, '○') :- 
    Row >= N - PiecesRows + 1,
    (Row + Col + ParityOffset) mod 2 =:= 1.
initCell(_, _, _, _, _, '.') :- !.

% Display the board
printBoard(Board) :-
    length(Board, N),
    write('  '), printColumnHeaders(N),
    printRows(Board, N, N),
    write('  '), printColumnHeaders(N), nl.

printRows([], _, _).
printRows([Row|Tail], RowNum, N) :-
    write(RowNum), write(' '), 
    printRow(Row),
    write(RowNum), nl,
    NextRowNum is RowNum - 1,
    printRows(Tail, NextRowNum, N).

printRow([]).
printRow([Cell|Tail]) :-
    write(Cell), write(' '),
    printRow(Tail).

printColumnHeaders(N) :-
    numlist(1, N, Cols),
    maplist(printColumnLetter, Cols),
    nl.

printColumnLetter(Col) :-
    CharCode is Col + 64,
    char_code(Char, CharCode),
    write(Char), write(' ').

% PvP Game loop
game_loop(Board, Player) :-
    printBoard(Board),
    format('~w player turn. ', [Player]),
    readMove(FromRow, FromCol, ToRow, ToCol),
    (
        valid_move(Board, Player, FromRow, FromCol, ToRow, ToCol)
        ->  make_move(Board, FromRow, FromCol, ToRow, ToCol, NewBoard),
            ( abs(FromRow - ToRow) =:= 2,
              can_continue_capture(NewBoard, Player, ToRow, ToCol)
              ->  printBoard(NewBoard),
                  Code is ToCol + 96,
                  char_code(ColChar, Code),
                  format('You can capture another piece. Try playing with the piece ~w~w.~n', [ToRow, ColChar]),
                  game_loop(NewBoard, Player)
              ;   switch_player(Player, NextPlayer),
                  ( check_game_over(NewBoard, Player)
                    -> true  % fim do jogo, não continua
                    ;  game_loop(NewBoard, NextPlayer)
                  )

            )
        ;   write('Invalid play. Try again.'), nl,
            game_loop(Board, Player)
    ).

% Helps print AI movements
column_letter(1, 'a').
column_letter(2, 'b').
column_letter(3, 'c').
column_letter(4, 'd').
column_letter(5, 'e').
column_letter(6, 'f').
column_letter(7, 'g').
column_letter(8, 'h').

% PvC Game loop
game_loop_vs_ai(Board, Player) :-
    length(Board, N),
    (
        Player == '○'
        ->  printBoard(Board),
            format('~w player turn. ', [Player]),
            readMove(FR, FC, TR, TC),
            ( valid_move(Board, Player, FR, FC, TR, TC)
              -> make_move(Board, FR, FC, TR, TC, NewBoard)
              ; write('Invalid play. Try again.'), nl, 
                game_loop_vs_ai(Board, Player), 
                fail
            )
        ;   write('AI is choosing...'), nl,
            (
                N =< 5
                ->  minimax(Board, Player, 3, [FR, FC, TR, TC], _)
                ;   alpha_beta(Board, Player, 3, -100000, 10000, [FR, FC, TR, TC], _)
            ),
            make_move(Board, FR, FC, TR, TC, NewBoard),
            column_letter(FC, FromColChar),
            column_letter(TC, ToColChar),
            format('AI played ~w~w -> ~w~w.~n', [FR, FromColChar, TR, ToColChar])
    ),
    (
        check_game_over(NewBoard, Player)
        -> start_game
        ;  switch_player(Player, NextPlayer),
           game_loop_vs_ai(NewBoard, NextPlayer)
    ).
