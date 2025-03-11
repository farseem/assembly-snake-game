
.extern getScreenWidth
.extern getScreenHeight
.extern board_init
.extern board_put_char
.extern game_exit
.extern usleep

.section .bss
    apples: .skip 320       # Number of apple should be less than or equal 20 (320 = 20 * 16)
    snake: .skip 2560       # Circular buffer for snake body, max 160 (x, y) pairs so upto lenght of 80, if you change this don't forget to update snake_max_length
    
.section .data
    initial_snake_length: .quad 5   # Initial length of the snake
    number_of_apples: .quad 3       # Number of apples, the number should be less than or equal 20
    snake_head: .quad 0     # Index of the head of the snake in the buffer
    snake_tail: .quad 0     # Index of the tail of the snake in the buffer
    snake_head_x: .quad 0           
    snake_head_y: .quad 0     
    snake_max_length: .quad 80      # If you change this number should also update the 'snake' variable in bss
    current_direction: .byte 0      # 0 = RIGHT, 1 = LEFT, 2 = UP, 3 = DOWN
    grow_snake: .quad 1
    apple_counter: .quad 0
    screen_width: .quad 0
    screen_height: .quad 0
    snake_speed: .quad 0            # Setting snake speed to '0' that is default, it will be increased every time snake eats an apple             
    start_time: .quad 0

.section .text
.globl start_game

start_game:
    pushq %rbp
    mov %rsp, %rbp

    andq $-16, %rsp

    mov %rdi, initial_snake_length
    mov %rsi, number_of_apples

    xor %rdi, %rdi          
    xor %rsi, %rsi          
    xor %rdx, %rdx          
    xor %rcx, %rcx
    xor %r8, %r8
    xor %r9, %r9

    call board_init         # Initialize the game board using ncurses

    sub $8, %rsp
    call getScreenHeight 
    add $8, %rsp

    mov %rax, screen_height

    movq %rax, %rdi  
    shr  $1, %rdi       # Divide RDI by 2 (arithmetic right shift) to get the center of the screen
    push %rdi           # Push the halved screen height onto the stack to preserve the result
    
    sub $8, %rsp
    call getScreenWidth  
    add $8, %rsp

    mov %rax, screen_width

    movq %rax, %rsi
    shr  $1, %rsi       # Divide RDI by 2 (arithmetic right shift) to get the center of the screen

    pop  %rdi  

    movq initial_snake_length, %rbx

    # Initialize snake's position at the center
    movq %rsi, snake_head_x  # Set the x-position of the first segment (tail of the snake)
    movq %rdi, snake_head_y  # Set the y-position of the first segment

# Drwaing initial apples according the number passed as argument
mov number_of_apples, %rbx          # Loop counter
.draw_apple:
    mov apple_counter, %r15
    call get_random_x
    mov %rax, %rdi             
    lea apples(,%r15,8), %r9    
    mov %rdi, (%r9)                 # Store the x-coordinate in the array

    call get_random_y
    mov %rax, %rsi             
    lea apples(,%r15,8), %r9   
    mov %rsi, 8(%r9)                # Store the y-coordinate in the array

    add $2, %r15                    # Increment index (16 bytes = 2 entries)
    cmp $42, %r15                   # Making sure that it does not exceed buffer size (20 pairs)
    
    jl .no_reset
    xor $0, %r15               
    jmp .end_draw_apple_loop

.no_reset:
    mov %r15, apple_counter     

    mov $42, %rdx              # ASCII for '*' into %rdx (character)
    call board_put_char        # Draw the apple on the board
    
    dec %rbx                   
    jnz .draw_apple            

.end_draw_apple_loop:


# Investigate the apple positions array
# Debug purpose code
/*mov $0, %r14                  
movq number_of_apples, %rbx                
.inspect_apple:
    lea apples(,%r14,8), %r9       

    mov (%r9), %r11              # Load x-coordinate
    mov 8(%r9), %r12             # Load y-coordinate

    add $2, %r14                 # Advance to the next snake segment
    dec %rbx
    jnz .inspect_apple           # Continue inspecting until done
*/

# Drwing the initial snake according to the size passed as argument
mov snake_head_x, %rdi
mov snake_head_y, %rsi
movq initial_snake_length, %rbx

.draw_initil_snake:
    mov $0, %r15                    
    mov snake_head_x, %rdi          
    mov snake_head_y, %rsi          

    movq initial_snake_length, %rbx                
    
.loop:
    lea snake(,%r15,8), %r9       

    push %rdi
    push %rsi

    mov %rdi, (%r9)              
    mov %rsi, 8(%r9)             

    movb $48, %dl                # ASCII for '0'

    call board_put_char          # Draw snake part

    pop %rsi
    pop %rdi

    inc %rdi                     # Move to the right
    add $2, %r15                 # Advance buffer index
    
    dec %rbx
    jnz .loop

    mov %rdi, snake_head_x       # Save head x-position after initial draw
    mov %rsi, snake_head_y       # Save head y-position after initial draw
    
    # Set the snake head pointer to initial snake length
    mov initial_snake_length, %r15
    imul $2, %r15
    mov %r15, snake_head
    # Set the snake tail pointer to 0
    mov $0, %rax
    mov %rax, snake_tail

/*
    # Debug purpose code
    # Investigate the snake array
    mov $0, %r14                  # Reset index for inspection
    movq $5, %rbx                # Reset length for inspection loop
.inspect_snake:
    lea snake(,%r14,8), %r9       # Compute buffer address

    mov (%r9), %r11              # Load x-coordinate
    mov 8(%r9), %r12             # Load y-coordinate

    # For debugging purposes, you can output or store the x and y coordinates
    # You could use an appropriate function here to print the values if needed
    # For example:
    # mov %rdi, %rdx              # Load x-coordinate into %rdx
    # mov %rsi, %rcx              # Load y-coordinate into %rcx
    # call print_coordinates      # Custom function to print the values

    inc %r14                      # Advance to the next snake segment
    inc %r14
    dec %rbx
    jnz .inspect_snake           # Continue inspecting until done
*/

call set_timer

.move_snake:
    pushq %rdi
    pushq %rsi
    
    call check_timer

    # Draw snake at the new position (head)
    call update_head

    /*
    Erase snake tail segment:
    If the grow_snake is set to 1:false then the tail segment is erased.
    Otherwise (when snake eats an apple) we skip updating the tail segment to grow the snake by a segment.
    */
    mov grow_snake, %rax            
    cmp $0, %rax                    
    je .skip_update_tail            

    call update_tail                

    .skip_update_tail:
        mov $1, grow_snake          
        
    popq %rsi         
    popq %rdi   

    /* 
    Set the delay in microseconds based on the speed counter that is increased on each apple eating.
    The default is 400000 milliseconds (0.4 seconds).
    Substracting the (speed counter * 10000 millieconds) to increase the speed every time (10000 milliseconds less delay in every speed increase)
    */    
    mov snake_speed, %rax    
    mov %rax, snake_speed         
    imul $10000, %rax        
    mov $400000, %rdi       
    sub %rax, %rdi          # Subtract the multiplication result from 400000

    sub $8, %rsp
    call usleep            
    add $8, %rsp           

    call detect_key

    mov current_direction, %al 
    
    cmp $0, %al  # Check if RIGHT
    je .right_move

    cmp $1, %al  # Check if LEFT
    je .left_move

    cmp $2, %al  # Check if UP
    je .up_move

    cmp $3, %al  # Check if DOWN
    je .down_move

    # If none of the conditions match, do nothing

    .right_move:
        mov snake_head_x, %r12 
        inc %r12               
        mov %r12, snake_head_x 
        jmp .end_move

    .left_move:
        mov snake_head_x, %r12 
        dec %r12               
        mov %r12, snake_head_x 
        jmp .end_move

    .up_move:
        mov snake_head_y, %r12 
        dec %r12              
        mov %r12, snake_head_y
        jmp .end_move

    .down_move:
        mov snake_head_y, %r12 
        inc %r12                    
        mov %r12, snake_head_y      
        jmp .end_move

    .end_move:
        # Continue with other instructions

    # Repeat the move loop indefinitely
    jmp .move_snake

# Function that sets the timer; Called at the begining of the game and everytime snake eats an apple to reset the timer.
set_timer:
    mov $201, %rax          
    xor %rdi, %rdi          
    syscall                 
    mov %rax, start_time    # save the starting time in a variable
    
    ret

    /*  
    Function that checks if the timer passed 30 seconds, if so the game is over. 
    If the snake eats an apple the timer is reset to 0. 
    So as long as it's keeps eating apples withough giving 30 seconds break game continues.
    */
check_timer:
    mov start_time, %r8
    # Calculate elapsed time
    mov $201, %rax          
    xor %rdi, %rdi          
    syscall                 
    sub %r8, %rax    
    
    cmp $30, %rax       # If an no apples is eaten for 30 seconds then the game is over.
    jge game_over
    ret

update_head:
    sub $8, %rsp

    mov snake_head, %r8           # Load the current snake_head index

    lea snake(,%r8,8), %r9        # Compute buffer address for the head
    movq snake_head_x, %rdi       # Load the current x-coordinate of the snake head
    mov %rdi, (%r9)               # Store the x-coordinate in the snake array

    movq snake_head_y, %rsi       # Load the current y-coordinate of the snake head
    mov %rsi, 8(%r9)              # Store the y-coordinate in the snake array

    # Check boundary
    call check_bounds
    
    # Push x and y coordinates for board_put_char
    push %rdi
    push %rsi

    movb $48, %dl                 # ASCII for '0'
    
    call board_put_char           # Draw snake part at the new position
    
    pop %rsi
    pop %rdi

    # Check for collision with apples
    mov $0, %r14                  # Reset index for apple inspection
    movq $20, %rbx                # Number of apples to check (max 20)

.check_apple_eating:
    lea apples(,%r14,8), %r10     # Compute buffer address for the current apple
    mov (%r10), %r11              # Load x-coordinate of the apple
    mov 8(%r10), %r12             # Load y-coordinate of the apple

    cmp %rdi, %r11                # Compare snake_head_x with apple_x
    jne .no_collision             # If not equal, skip to next
    cmp %rsi, %r12                # Compare snake_head_y with apple_y
    jne .no_collision             # If not equal, skip to next

    # Collision detected
    push %rdi 
    mov %r14, %rdi
    call handle_apple_eating  # Call a separate function to handle collision
    
    pop %rdi    

    jmp .apple_eating_handled

.no_collision:
    add $2, %r14                    # Move to the next apple (16 bytes per apple)
    dec %rbx                        # Decrement counter
    jnz .check_apple_eating         # Continue if apples remain

.apple_eating_handled:
    # Now check for collision with snake body
    mov snake_tail, %r14          # Start scanning from the tail index
    mov snake_head, %r15          # Load the current snake_head index

.check_self_collision:
    cmp %r14, %r15                # If tail == head, we are done scanning
    je .no_self_collision

    lea snake(,%r14,8), %r9       # Compute buffer address for the current snake segment
    mov (%r9), %r11               # Load x-coordinate of the segment
    mov 8(%r9), %r12              # Load y-coordinate of the segment

    cmp %rdi, %r11                # Compare snake_head_x with segment_x
    jne .next_segment
    cmp %rsi, %r12                # Compare snake_head_y with segment_y
    jne .next_segment

    # Collision detected with snake body
    call game_over                  
    jmp .done                       

.next_segment:
    add $2, %r14                    # Move to the next segment (16 bytes per segment)
    mov %r14, %rax
    mov snake_max_length, %r9       # Circular increment logic
    xor %rdx, %rdx
    div %r9
    mov %rdx, %r14
    jmp .check_self_collision

.no_self_collision:
    # Update the snake_head index (circular increment)
    mov snake_head, %rax          # Load the current snake_head index
    add $2, %rax                  # Increment the index
    mov snake_max_length, %r9     # Load the snake length (circular buffer size)
    xor %rdx, %rdx                # Clear %rdx for division
    div %r9                       # Perform modulo: %rax / %r9
    mov %rdx, snake_head          # Store the remainder as the new snake_head index

    add $8, %rsp
    ret

update_tail:
    sub $8, %rsp
    # Compute index in the circular buffer
    mov snake_tail, %r8             # Load current tail index

    lea snake(,%r8,8), %r9          # Compute buffer address for the tail

    mov (%r9), %rdi                 # Load x-coordinate
    mov 8(%r9), %rsi                # Load y-coordinate

    push %rdi
    push %rsi
    
    # Erase the tail segment (set to space)
    movb $32, %dl                   # ASCII for space

    call board_put_char             # Draw space at tail position

    pop %rsi
    pop %rdi
    
    
    # Update the snake_tail index (circular increment)
    mov snake_tail, %rbx            # Load current snake_tail index
    add $2, %rbx                    # Increment by 2 (for x and y coordinates)
    
    mov snake_max_length, %r9       # Load total snake length
    # shl $1, %r9                   # Multiply length by 2 (size of the buffer)
    cmp %r9, %rbx                   # Compare updated index with buffer size
    jl .tail_update_done            # If less, no wrap-around needed
    xor %rbx, %rbx                  # Else, reset index to 0
    mov %rbx, snake_tail            # Save updated tail index
    
    .tail_update_done:
        mov %rbx, snake_tail         # Save updated tail index

    add $8, %rsp
    
    ret

# Function that checks the boundary conditions. Game is over if it meets any of the following case:
# -snake_head_x < 0    -snake_head_x > width      -snake_head_y < 0      -snake_head_y > height
check_bounds:

    mov snake_head_x, %rax              

    cmp $0, %rax               
    jl game_over                

    cmp screen_width, %rax      
    jg game_over                

    mov snake_head_y, %rax              
    
    cmp $0, %rax              
    jl game_over      

    cmp screen_height, %rax  
    jg game_over          

    # If no conditions matched, continue execution
    jmp .continue_game

.continue_game:
    ret

game_over:
    mov %rbp, %rsp
    popq %rbp
    
    # Print "Game Over" message
    mov $1, %rdi       
    lea msg_game_over(%rip), %rsi  # Address of the message
    mov $11, %rdx      
    mov $1, %rax       
    syscall

    # Exit the program
    call game_exit;

msg_game_over:
    .asciz "Game Over\n"

handle_apple_eating:
    # Updating grow_snake to 0:true so that the snake grows by 1 segment 
    mov $0, %r13
    mov %r13, grow_snake

    mov %rdi, %r14              # Index of colloided apple is passed to %rdi
    call reappear_apple

    # Increase the snake speed
    mov snake_speed, %r15
    inc %r15
    mov %r15, snake_speed  
    
    # Reset the timer
    call set_timer

    ret


/* 
    Function to reappear an apple after one is eaten by the snake.
    Before positioning an apple we check if there is an apple already exists
    and if there is a snake segment in the desired position. If there is any 
    existance of apple/snake segment we try to find another spot for the apple.
*/
reappear_apple:
    sub $8, %rsp                  
    mov %rdi, %r15                # Save the apple index in %r15
    push %r15                     # Need to store %r15 in the stack since %r15 is used and updated

.reposition_apple:
    call get_random_x             
    mov %rax, %rdi                
    call get_random_y             
    mov %rax, %rsi                

    # Check if an apple already exists at the new position
    xor %r14, %r14                # Start checking from the first apple
    mov number_of_apples, %rbx          
    call check_apple_exists
    cmp $0, %rax                  # Check if apple exists (1 = true, 0 = false)
    jne .reposition_apple         # If an apple exists, get new positions

    # Check if the snake exists at the new position
    xor %r14, %r14                # Start checking from the first snake segment
    mov snake_tail, %r15          
    call snake_exists
    cmp $0, %rax                  # Check if snake exists (1 = true, 0 = false)
    jne .reposition_apple         # If the snake exists, get new positions

    pop %r15
    # Store the new apple position
    lea apples(,%r15,8), %r9      # Address of the apple buffer for the current index
    mov %rdi, (%r9)               # Store x-coordinate
    mov %rsi, 8(%r9)              # Store y-coordinate

    # Draw the apple on the board
    mov $42, %rdx                 # ASCII for '*' into %rdx (character)
    call board_put_char           # Draw the apple on the board
    add $8, %rsp                  # Restore stack
    ret

/*
    Function to check if an apple already exists at the specified position.
    This function is anvoked from the reappear apple function to check if a apple already exists in that position.    
*/
check_apple_exists:
    lea apples(,%r14,8), %r10     # Compute buffer address for the current apple
    mov (%r10), %r11              # Load x-coordinate of the apple
    mov 8(%r10), %r12             # Load y-coordinate of the apple

    cmp %rdi, %r11                
    jne .not_exists               
    cmp %rsi, %r12                
    jne .not_exists               

    # Apple already exists at this location
    mov $1, %rax                  # Set return value to 1 (true)
    ret

.not_exists:
    add $16, %r14                 # Move to the next apple (16 bytes per apple)
    dec %rbx                      # Decrement counter
    jnz check_apple_exists        # Continue if apples remain

    # No apple exists at this location
    xor %rax, %rax                # Set return value to 0 (false)
    ret

/*
    Function to check if a snake segment exists at the specified position.
    This function is anvoked from the reappear apple function to check if a apple already exists in that position.    
*/
snake_exists:
    cmp %r14, %r15                # If tail == head, we are done scanning
    je .no_snake_segment_exists

    lea snake(,%r14,8), %r9       # Compute buffer address for the current snake segment
    mov (%r9), %r11               # Load x-coordinate of the segment
    mov 8(%r9), %r12              # Load y-coordinate of the segment

    cmp %rdi, %r11                
    jne .next_snake_segment
    cmp %rsi, %r12                
    jne .next_snake_segment

    # Collision detected with snake body
    mov $1, %rax                  # Set return value to 1 (true)
    ret

.next_snake_segment:
    add $2, %r14                  # Move to the next segment (16 bytes per segment)
    mov %r14, %rax
    mov snake_max_length, %r9     # Circular increment logic
    xor %rdx, %rdx
    div %r9
    mov %rdx, %r14
    jmp snake_exists

.no_snake_segment_exists:
    xor %rax, %rax                # Set return value to 0 (false)
    ret


# Function that returns a random number from 0 to the width of the screen
get_random_x:
    push %rdi            
    call rand            
    mov %rax, %rsi       

    call getScreenWidth     
    mov %rax, %rcx       

    xor %rdx, %rdx       
    mov %rsi, %rax       
    div %rcx             

    mov %rdx, %rax       
    pop %rdi             
    ret

# Function that returns a random number from 0 to the height of the screen
get_random_y:
    push %rdi            
    call rand            
    mov %rax, %rsi       

    call getScreenHeight    
    mov %rax, %rcx       

    xor %rdx, %rdx       
    mov %rsi, %rax       
    div %rcx             

    mov %rdx, %rax       
    pop %rdi             
    ret

detect_key:
    sub $8, %rsp 
    call board_get_key        # Call the function to get a keypress
    add $8, %rsp 
    cmp $0, %rax              # Check if no key was pressed
    je .no_key                # Skip if no keypress detected

    # Check for arrow keys
    cmp $258, %rax            
    je .key_down
    cmp $259, %rax            
    je .key_up
    cmp $260, %rax            
    je .key_left
    cmp $261, %rax            
    je .key_right
    jmp .no_key               

    # For each direction change key storke checking if it's valid (not opposite direction)
    # Update the current direction if the move is valid
    .key_right:
        cmpb $1, current_direction    # Compare current direction with 1 (LEFT)
        je .done                      # If the current direction is LEFT, skip updating

        movb $0, current_direction    # Set direction to RIGHT (2)
        jmp .done                     # Resume execution after processing

    .key_left:
        cmpb $0, current_direction    
        je .done                      

        movb $1, current_direction 
        jmp .done                  

    .key_up:
        cmpb $3, current_direction    
        je .done                      

        movb $2, current_direction 
        jmp .done                  

    .key_down:
        cmpb $2, current_direction      
        je .done

        movb $3, current_direction      
        jmp .done                  

    .no_key:
        jmp .done                       # No action for invalid keys

    .done:
        ret