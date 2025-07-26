minimax(Board, Player, Depth, BestMove, Value) :-
    generate_moves(Board, Player, Moves),
    (   best(Moves, Board, Player, Depth, BestMove, Value)
        ->  true  % Find best move, use it
        ;   [FirstMove|_] = Moves,  % Choose first movement
            BestMove = FirstMove,
            Value = -10000
        ).

% best(+Moves, +Board, +Player, +Depth, -BestMove, -BestValue)
best([], _, _, _, none, -10000).
best([Move|Rest], Board, Player, Depth, BestMove, BestValue) :-
    make_move(Board, Move, NewBoard),
    switch_player(Player, Opponent),
    NewDepth is Depth - 1,
    mintowin(NewBoard, Opponent, NewDepth, Value),
    best(Rest, Board, Player, Depth, TempMove, TempValue),
    (
        Value > TempValue ->
        BestMove = Move,
        BestValue = Value
    ;
        BestMove = TempMove,
        BestValue = TempValue
    ).

% maxtowin(+Board, +Player, +Depth, -Value)
maxtowin(Board, Player, 0, Value) :-
    evaluate(Board, Player, Value), !.
maxtowin(Board, Player, Depth, Value) :-
    generate_moves(Board, Player, Moves),
    best(Moves, Board, Player, Depth, _, Value).

% mintowin(+Board, +Player, +Depth, -Value)
mintowin(Board, Player, 0, Value) :-
    evaluate(Board, Player, Value), !.
mintowin(Board, Player, Depth, Value) :-
    generate_moves(Board, Player, Moves),
    worst(Moves, Board, Player, Depth, _, Value).

% worst(+Moves, +Board, +Player, +Depth, -WorstMove, -WorstValue)
worst([], _, _, _, none, 10000).
worst([Move|Rest], Board, Player, Depth, WorstMove, WorstValue) :-
    make_move(Board, Move, NewBoard),
    switch_player(Player, Opponent),
    NewDepth is Depth - 1,
    maxtowin(NewBoard, Opponent, NewDepth, Value),
    worst(Rest, Board, Player, Depth, TempMove, TempValue),
    (
        Value < TempValue ->
        WorstMove = Move,
        WorstValue = Value
    ;
        WorstMove = TempMove,
        WorstValue = TempValue
    ).

% Moves Wrapper [FR, FC, TR, TC]
make_move(Board, [FR, FC, TR, TC], NewBoard) :-
    make_move(Board, FR, FC, TR, TC, NewBoard).

% Heuristic
evaluate(Board, Player, Score) :-
    count_pieces(Board, '●', BlackCount),
    count_pieces(Board, '♛', BlackKings),
    count_pieces(Board, '○', WhiteCount),
    count_pieces(Board, '♕', WhiteKings),
    (Player == '●'
        -> Score is (BlackCount + 3*BlackKings) - (WhiteCount + 3*WhiteKings)
        ;  Score is (WhiteCount + 3*WhiteKings) - (BlackCount + 3*BlackKings)
    ).

count_pieces([], _, 0).
count_pieces([Row | Rest], Piece, Count):-
    count_pieces_row(Row, Piece, RowCount),
    count_pieces(Rest, Piece, RestCount),
    Count is RowCount + RestCount.

count_pieces_row([], _, 0).
count_pieces_row([Piece|Rest], Piece, Count):-
    count_pieces_row(Rest, Piece, Ncount),
    Count is Ncount + 1.

count_pieces_row([_|Rest], Piece, Count):-
    count_pieces_row(Rest, Piece, Count).


generate_moves(Board, Player, Moves) :-
    length(Board, N),
    findall([FR, FC, TR, TC],
            (between(1, N, FR),
             between(1, N, FC),
             between(1, N, TR),
             between(1, N, TC),
             valid_move(Board, Player, FR, FC, TR, TC)),
            Moves).

alpha_beta(Board, Player, Depth, Alpha, Beta, BestMove, Value) :-
    generate_moves(Board, Player, Moves),
    (   alpha_beta_best(Moves, Board, Player, Depth, Alpha, Beta, none, BestMove, Value)
    ->  true  % Find best move, use it
    ;   [FirstMove|_] = Moves,  % Choose first movement
        BestMove = FirstMove,
        Value = -10000
    ).
    % alpha_beta_best(Moves, Board, Player, Depth, Alpha, Beta, none, BestMove, Value).

% alpha_beta_best(+Moves, +Board, +Player, +Depth, +Alpha, +Beta, +CurrentBestMove, -BestMove, -BestValue)
alpha_beta_best([], _, _, _, _, _, CurrentBestMove, CurrentBestMove, -10000).
alpha_beta_best([Move|Rest], Board, Player, Depth, Alpha, Beta, CurrentBestMove, BestMove, BestValue) :-
    make_move(Board, Move, NewBoard),
    switch_player(Player, Opponent),
    NewDepth is Depth - 1,
    alpha_beta_min(NewBoard, Opponent, NewDepth, Alpha, Beta, Value),
    (
        Value > Alpha ->
        NewAlpha = Value,
        NewBestMove = Move
    ;
        NewAlpha = Alpha,
        NewBestMove = CurrentBestMove
    ),
    (
        NewAlpha >= Beta ->
        BestMove = NewBestMove,
        BestValue = NewAlpha
    ;
        alpha_beta_best(Rest, Board, Player, Depth, NewAlpha, Beta, NewBestMove, BestMove, BestValue)
    ).

% alpha_beta_min(+Board, +Player, +Depth, +Alpha, +Beta, -Value)
alpha_beta_min(Board, Player, 0, _, _, Value) :-
    evaluate(Board, Player, Value), !.
alpha_beta_min(Board, Player, Depth, Alpha, Beta, Value) :-
    generate_moves(Board, Player, Moves),
    alpha_beta_worst(Moves, Board, Player, Depth, Alpha, Beta, none, _, Value).

% alpha_beta_worst(+Moves, +Board, +Player, +Depth, +Alpha, +Beta, +CurrentWorstMove, -WorstMove, -WorstValue)
alpha_beta_worst([], _, _, _, _, _, CurrentWorstMove, CurrentWorstMove, 10000).
alpha_beta_worst([Move|Rest], Board, Player, Depth, Alpha, Beta, CurrentWorstMove, WorstMove, WorstValue) :-
    make_move(Board, Move, NewBoard),
    switch_player(Player, Opponent),
    NewDepth is Depth - 1,
    alpha_beta_max(NewBoard, Opponent, NewDepth, Alpha, Beta, Value),
    (
        Value < Beta ->
        NewBeta = Value,
        NewWorstMove = Move
    ;
        NewBeta = Beta,
        NewWorstMove = CurrentWorstMove
    ),
    (
        Alpha >= NewBeta ->
        WorstMove = NewWorstMove,
        WorstValue = NewBeta
    ;
        alpha_beta_worst(Rest, Board, Player, Depth, Alpha, NewBeta, NewWorstMove, WorstMove, WorstValue)
    ).

% alpha_beta_max(+Board, +Player, +Depth, +Alpha, +Beta, -Value)
alpha_beta_max(Board, Player, 0, _, _, Value) :-
    evaluate(Board, Player, Value), !.
alpha_beta_max(Board, Player, Depth, Alpha, Beta, Value) :-
    generate_moves(Board, Player, Moves),
    alpha_beta_best(Moves, Board, Player, Depth, Alpha, Beta, none, _, Value).