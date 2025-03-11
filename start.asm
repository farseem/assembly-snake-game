.extern start_game
.extern game_exit

.section .data                
    initial_snake_length: .quad 5   # Initial length of the snake
    number_of_apples: .quad 3       # Number of apples
    arg_error_msg: .asciz "Error: Two integer arguments are required.\n"

.section .text

_start:
    # Check argc
    mov (%rsp), %rdi
    
    cmp $3, %rdi                # If argc == 3 (program + 2 args)
    jne .arg_error_handler      # Else, print arg error and exit

    # Load address of the first argument (argv[1])
    lea 16(%rsp), %rbx
    mov (%rbx), %rsi
    call atoi                   # Convert the argument to an integer
    mov %rax, initial_snake_length

    # Load address of the second argument (argv[2])
    lea 24(%rsp), %rbx
    mov (%rbx), %rsi
    call atoi                   # Convert the argument to an integer
    mov %rax, number_of_apples

    call .done_arg_processing
    
# Print the error message and exit
.arg_error_handler:
    lea arg_error_msg(%rip), %rsi 
    call game_exit;
    

.done_arg_processing:    
    mov initial_snake_length, %rdi
    mov number_of_apples, %rsi
    call start_game

# Function to convert string to integer
atoi:
    xor %rax, %rax             
    xor %rcx, %rcx             
atoi_loop:
    movzbq (%rsi), %rcx        
    test %rcx, %rcx            
    jz atoi_done               
    sub $48, %rcx              
    imul $10, %rax             
    add %rcx, %rax             
    inc %rsi                   
    jmp atoi_loop              
atoi_done:
    ret