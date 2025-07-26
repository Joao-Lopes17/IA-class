% Read a move input from the user
readMove(FromRow, FromCol, ToRow, ToCol) :-
    repeat,
    write('Choose a movement (ex: 2b 3a):'), nl,
    read_line_to_string(user_input, Input),
    (
        split_string(Input, " ", "", [FromStr, ToStr]),
        parse_position(FromStr, FromRow, FromCol),
        parse_position(ToStr, ToRow, ToCol)
    ->
        true
    ;
        write('Invalid input. Try again.'), nl,
        fail
    ).

parse_position(Str, Row, Col) :-
    string_chars(Str, [RowChar, ColChar]),
    atom_number(RowChar, Row),
    char_code(ColChar, Code),
    Col is Code - 96.

% Piece types
player_piece('●', '●').
player_piece('●', '♛').
player_piece('○', '○').
player_piece('○', '♕').

opponent_piece('●', '○').
opponent_piece('○', '●').
opponent_piece('●', '♕').
opponent_piece('○', '♛').

promote_piece('○', Row, N, '♕') :- Row =:= N.
promote_piece('●', Row, _, '♛') :- Row =:= 1.
promote_piece(Piece, _, _, Piece).

% Access a cell
get_piece(Board, Row, Col, Piece) :-
    length(Board, N),
    RowIdx is N - Row,
    ColIdx is Col - 1,
    nth0(RowIdx, Board, RowList),
    nth0(ColIdx, RowList, Piece).

in_bounds(N, Row, Col) :-
    Row >= 1, Row =< N,
    Col >= 1, Col =< N.

% Check for any capture possibility
has_capture(Board, Player) :-
    length(Board, N),
    between(1, N, Row),
    between(1, N, Col),
    get_piece(Board, Row, Col, Piece),
    player_piece(Player, Piece),
    directions(Piece, Dirs),
    member((DR, DC), Dirs),
    ToRow is Row + 2*DR,
    ToCol is Col + 2*DC,
    MidRow is Row + DR,
    MidCol is Col + DC,
    in_bounds(N, ToRow, ToCol),
    in_bounds(N, MidRow, MidCol),
    get_piece(Board, MidRow, MidCol, MidPiece),
    get_piece(Board, ToRow, ToCol, '.'),
    opponent_piece(Player, MidPiece),
    !.

% Validate if a move is allowed
valid_move(Board, Player, FR, FC, TR, TC) :-
    (
        has_capture(Board, Player) ->
            is_capture(Board, Player, FR, FC, TR, TC)
        ;
            is_simple_move(Board, Player, FR, FC, TR, TC)
    ).

is_simple_move(Board, Player, FR, FC, TR, TC) :-
    length(Board, N),
    RowFromIdx is N - FR,
    ColFromIdx is FC - 1,
    RowToIdx is N - TR,
    ColToIdx is TC - 1,

    nth0(RowFromIdx, Board, RowFrom),
    nth0(ColFromIdx, RowFrom, Piece),
    nth0(RowToIdx, Board, RowTo),
    nth0(ColToIdx, RowTo, Target),

    player_piece(Player, Piece),
    Target = '.',

    RowDiff is TR - FR,
    ColDiff is TC - FC,
    abs(RowDiff, AbsRow),
    abs(ColDiff, AbsCol),
    AbsRow =:= AbsCol,  % Diagonal

    (
        Piece == Player ->  % Peão normal
            (
                AbsRow =:= 1,
                (Player = '○', RowDiff =:= 1;
                 Player = '●', RowDiff =:= -1)
            )
        ;
        % Dama: verifica caminho livre em diagonal
        check_diagonal_clear(Board, FR, FC, TR, TC)
    ).

check_diagonal_clear(Board, FR, FC, TR, TC) :-
    RowStep is sign(TR - FR),
    ColStep is sign(TC - FC),
    check_diagonal_clear(Board, FR, FC, TR, TC, RowStep, ColStep).

check_diagonal_clear(Board, FR, FC, TR, TC, RowStep, ColStep) :-
    NextR is FR + RowStep,
    NextC is FC + ColStep,
    (NextR =:= TR, NextC =:= TC -> true ; (
        get_piece(Board, NextR, NextC, '.'),
        check_diagonal_clear(Board, NextR, NextC, TR, TC, RowStep, ColStep)
    )).

% Validate simple or capture move
is_simple_or_capture(Board, Player, FR, FC, TR, TC) :-
    length(Board, N),
    RowFromIdx is N - FR,
    RowToIdx is N - TR,
    ColFromIdx is FC - 1,
    ColToIdx is TC - 1,

    nth0(RowFromIdx, Board, RowFrom),
    nth0(ColFromIdx, RowFrom, Piece),
    nth0(RowToIdx, Board, RowTo),
    nth0(ColToIdx, RowTo, Target),

    player_piece(Player, Piece),
    Target = '.',

    RowDiff is TR - FR,
    ColDiff is TC - FC,
    abs(RowDiff, AbsRow),
    abs(ColDiff, AbsCol),

    (
        (Piece == Player ->
            (AbsRow =:= 1, AbsCol =:= 1,
             ((Player = '○', RowDiff =:= 1);
              (Player = '●', RowDiff =:= -1))
            ;
             AbsRow =:= 2, AbsCol =:= 2,
             MidRow is (FR + TR) // 2,
             MidCol is (FC + TC) // 2,
             MidRowIdx is N - MidRow,
             MidColIdx is MidCol - 1,
             nth0(MidRowIdx, Board, MidRowList),
             nth0(MidColIdx, MidRowList, MiddlePiece),
             opponent_piece(Player, MiddlePiece)
            )
        ;
        (AbsRow =:= 1, AbsCol =:= 1;
         AbsRow =:= 2, AbsCol =:= 2,
         MidRow is (FR + TR) // 2,
         MidCol is (FC + TC) // 2,
         MidRowIdx is N - MidRow,
         MidColIdx is MidCol - 1,
         nth0(MidRowIdx, Board, MidRowList),
         nth0(MidColIdx, MidRowList, MiddlePiece),
         opponent_piece(Player, MiddlePiece))
        )
    ).

% Capture move only
is_capture(Board, Player, FR, FC, TR, TC) :-
    is_simple_or_capture(Board, Player, FR, FC, TR, TC),
    abs(FR - TR) =:= 2,
    abs(FC - TC) =:= 2.

% Make the move
make_move(Board, FR, FC, TR, TC, NewBoard) :-
    length(Board, N),
    RowFrom is N - FR, ColFrom is FC - 1,
    RowTo is N - TR, ColTo is TC - 1,
    nth0(RowFrom, Board, RowF),
    nth0(ColFrom, RowF, Piece),
    promote_piece(Piece, TR, N, NewPiece),
    set_cell(Board, RowFrom, ColFrom, '.', TempBoard1),
    set_cell(TempBoard1, RowTo, ColTo, NewPiece, TempBoard2),
    ( abs(FR - TR) =:= 2 ->
        MidRow is (FR + TR) // 2,
        MidCol is (FC + TC) // 2,
        RowMidIndex is N - MidRow,
        ColMidIndex is MidCol - 1,
        set_cell(TempBoard2, RowMidIndex, ColMidIndex, '.', NewBoard)
    ;
        NewBoard = TempBoard2
    ).

% Check if player can continue to capture
can_continue_capture(Board, Player, Row, Col) :-
    get_piece(Board, Row, Col, Piece),
    directions(Piece, Dirs),
    length(Board, N),
    member((DR, DC), Dirs),
    MidRow is Row + DR,
    MidCol is Col + DC,
    ToRow is Row + 2*DR,
    ToCol is Col + 2*DC,
    in_bounds(N, MidRow, MidCol),
    in_bounds(N, ToRow, ToCol),
    get_piece(Board, MidRow, MidCol, MidPiece),
    get_piece(Board, ToRow, ToCol, '.'),
    opponent_piece(Player, MidPiece),
    !.

% Set cell in board
set_cell([Row|Rows], 0, Col, Value, [NewRow|Rows]) :-
    set_cell_in_row(Row, Col, Value, NewRow).
set_cell([Row|Rows], RowIndex, Col, Value, [Row|NewRows]) :-
    RowIndex > 0,
    NewRowIndex is RowIndex - 1,
    set_cell(Rows, NewRowIndex, Col, Value, NewRows).

set_cell_in_row([_|Tail], 0, Value, [Value|Tail]).
set_cell_in_row([Head|Tail], Col, Value, [Head|NewTail]) :-
    Col > 0,
    NewCol is Col - 1,
    set_cell_in_row(Tail, NewCol, Value, NewTail).

% Switch turns
switch_player('○', '●').
switch_player('●', '○').


% Directions for movement
directions('○', [(1,-1), (1,1)]).
directions('●', [(-1,-1), (-1,1)]).
directions(Piece, [(-1,-1), (-1,1), (1,-1), (1,1)]) :-
    (Piece = '♕'; Piece = '♛').

% Verify if the player has valid moves
has_valid_moves(Board, Player) :-
    length(Board, N),
    between(1, N, Row),
    between(1, N, Col),
    get_piece(Board, Row, Col, Piece),
    player_piece(Player, Piece),
    directions(Piece, Dirs),
    member((DR, DC), Dirs),
    (
        ToRow is Row + DR,
        ToCol is Col + DC,
        in_bounds(N, ToRow, ToCol),
        get_piece(Board, ToRow, ToCol, '.'),

        % Movimento simples
        is_simple_move(Board, Player, Row, Col, ToRow, ToCol)
    ;
        % Movimento de captura
        ToRow2 is Row + 2*DR,
        ToCol2 is Col + 2*DC,
        MidRow is Row + DR,
        MidCol is Col + DC,
        in_bounds(N, ToRow2, ToCol2),
        in_bounds(N, MidRow, MidCol),
        get_piece(Board, MidRow, MidCol, MidPiece),
        get_piece(Board, ToRow2, ToCol2, '.'),
        opponent_piece(Player, MidPiece)
    ),
    !.

% Verify if the game is over, and if it has ended annouce the winner
check_game_over(Board, Player) :-
    switch_player(Player, Opponent),
    \+ has_valid_moves(Board, Opponent),
    format('Game ended! ~w  player has won.~n', [Player]),
    !.

% Game is not over
check_game_over(_, _) :-
    fail.