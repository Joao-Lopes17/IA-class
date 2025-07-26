:- consult('generateBoard.pl').
:- consult('minimax.pl').

start_game :-
    write('Welcome to the Checkers Prolog game!'), nl,
    write('Choose an option:'), nl,
    write('1 - Player vs Computer (5x5)'), nl,
    write('2 - Player vs Computer (8x8)'), nl,
    write('3 - Player vs Player (5x5)'), nl,
    write('4 - Player vs Player (8x8)'), nl,
    read(Option),
    (
        option_board_mode(Option, BoardSize, GameMode) ->
            generateBoard(BoardSize, Board),
            (   
                GameMode == pvp -> 
                    read_line_to_string(user_input, _),  % Limpar o buffer
                    game_loop(Board, '○')
            ;   GameMode == pvc -> 
                    read_line_to_string(user_input, _),  % Limpar o buffer
                    game_loop_vs_ai(Board, '○')
            )
    ;
        write('Invalid option. Please try again.'), nl,
        start_game
    ).

% Choose board size and mode according to the option choosen
option_board_mode(1, 5, pvc).
option_board_mode(2, 8, pvc).
option_board_mode(3, 5, pvp).
option_board_mode(4, 8, pvp).
