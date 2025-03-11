# assembly-snake-game
This project was to write a snake game with a defined set of features and environment setup.  
• The game is implemented in x86-64 assembly
• Is compilable with GNU as and linked with GNU GCC, used AT&T syntax-style assembly.
• Used GDB as debugging tool; that's an essential.  

Implemented features
---------------------
 - Configurable number of apples (more than 1) and initial snake length as command-line argument.
 - The snake grows when eating an apple.
 - The snake can be controlled by the arrow keys. 
    * If no arrow key is pressed, the snake moves in the direction it was last moving. 
    * It cannot move backwards.
 - The snake dies if it hits itself.
 - If the snake hits the end of the field (above, below, right, or left) it dies and the game is ended.
 - Apples are placed at random positions on the screen and when an apple is eaten, a new apple re-appears.
 - The size of the playfield (board) is the current size of the command window. It's calculated dynamically.
 - The snake starts at the middle of the board.

Implemented the following Extra features
---------------------------------------- 
• A speed increase feature, where the speed of the snake increases every time the snake eats an apple. 
  The speed increases by 10000 milliseconds. The default speed is .4 seconds (400000 milliseconds). 
  Since the increment is small, it is best visible while the  snake moves vertically. 
  
• Included an implementation of a timer that will end the game after a certain amount of time (30 seconds). 
  The timer is reset every time the snake eats an apple. If the snake is safe until it eats an apple every 30 seconds.
  
• Limited the apples to only appear in a space where neither the snake nor any other apple is present. If there is an apple
  or a snake segment present, did the apple reappearing task until there is no clash with the apple or snake. 
