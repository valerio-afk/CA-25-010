%define CLOCK_MONOTONIC 1

section .data

    grid_size dd 10
    start_position dd 4,2
    offsets dd -2, 2, 2, 2, -2, -2, 0, 3, 2, -2, 3, 0, -3, 0, 0, -3
    stack_no_value dd 0xffffffff

    int_fmt db "%3d ",0
    newln db 10,0
    elapsed_time_fmt db 10,10,"Elapsed time: %ld.%09ld seconds", 10, 0 

    init_stack_size dd 32


section .text
    global main
    extern printf
    extern malloc
    extern free
    extern memset
    extern realloc
    extern clock_gettime
    extern qsort

print_grid:
    ; create stack frame
    push rbp
    mov rbp, rsp

    xor rbx, rbx ; init ebx to 0
    mov r13d, [grid_size]
    imul r13d, [grid_size] 

    mov r12, rdi ; save pointer to grid

.print_grid_loop:
    cmp ebx,r13d ; compare if we have printed all the numbers
    je .print_grid_return

    mov rdi, int_fmt ; first param - format for printf
    mov esi, [r12+rbx*4]
    xor eax,eax
    call printf

    inc ebx ; increment counter

    ;calculate the modulo of ebx and gridsize (idiv uses 128bit extended rax/rdx)
    mov eax, ebx
    cqo ; register extension
    mov ecx, [grid_size]
    idiv rcx

    test rdx, rdx ; rdx contains reminder
    jnz .print_grid_loop ; if reminder is != 0, repet
    mov rdi, newln ; print \n
    xor eax,eax
    call printf

    jmp .print_grid_loop


.print_grid_return:
    pop rbp
    xor rax,rax
    ret


set_value:
    ;rdi - pointer to grid
    ;esi - grid_size
    ;rdx - row, columns
    ;ecx - value

    ; small fn - no need to play with the stack
    ; extract row and column from edx

    ;most significant bytes - column
    ;least significant bytes - row
    push rbp
    mov rbp, rsp
    
    push r12 ; this is callee-saved, so let's save it
    push r13

    xor r12, r12
    mov r12d, edx ; row
    shr rdx, 32
    mov r13d, edx ; column

    ;calculate row*gridsize + column

    imul r12d, esi
    add r12d, r13d
    shl r12d,2 ; multiply by 4 (int)

    mov [rdi+r12], ecx

    pop r13
    pop r12
    pop rbp

    ret

stack32_create: ; function to create a malloc'd stack
    ; create stack frame
    ; rdi, pointer to int
    push rbp
    mov rbp, rsp
    ;STACK: rbp

    push rbx
    ;STACK: rpb, rbx
    
    mov ebx, [init_stack_size]
    mov [rdi], ebx ; save the size of the stack on the pointed variable
    mov dword [rdi+4], 0 ; save the stack top idx on the pointer variable
    shl ebx,2 ; multiply the initial stack size by 4 (size of int)

        
    xor rdi, rdi
    mov edi,ebx
    call malloc

    pop rbx
    pop rbp
    ret

stack32_push: ; function to add element on stack (realloc if necessary)
    ;rdi = pointer to pointer to stack (double pointer)
    ;rsi = pointer to int (top,length)
    ;edx = value to push

    ;create stack frame
    push rbp
    mov rbp, rsp
    ;STACK: rbp

    mov r10d, [rsi] ; stack size
    mov r11d, [rsi+4] ; stack top

    ;check if we reached the top of the stack
    ;if so, apply realloc
    cmp r11d, r10d
    jl .stack32_push_perform
    ; grow stack by 2
    shl r10d,3 ; multiply by 8 because it's 2 * sizeof(int)
    
    push rdi ; save these registers on stack
    push rsi ; save these registers on stack
    push r10 ; save these registers on stack
    push r11 ; save these registers on stack
    push rdx ; save these registers on stack

    ;STACK: rbp, rdi, rsi, r10, r11

    mov rdi,[rdi] ; pointer to array to be realloced
    mov esi, r10d
    call realloc
    
    pop rdx ; restore registers from stack
    pop r11 ; restore registers from stack
    pop r10 ; restore registers from stack
    pop rsi ; restore registers from stack
    pop rdi ; restore registers from stack

    ;STACK: rbp

    mov [rdi], rax ; save realloced address
    shr r10d,2 ; divide by 4 because I don't need the sizeof(int) anymore
    mov [rsi], r10d ; update stack size
    

.stack32_push_perform:
    mov rcx,[rdi]
    lea r10d, [r11d*4]
    add rcx,r10
    mov [rcx], edx
    inc r11d
    mov [rsi+4], r11d

    pop rbp
    ret

stack32_pop: ; function to take an element from stack 
    ;rdi = pointer to pointer to stack (double pointer)
    ;rsi = pointer to int (top,length)

    ;create stack frame
    push rbp
    mov rbp, rsp
    ;STACK: rbp

    push r12 ; callee-saved registers
    push r13 ; callee-saved registers

    
    mov r12d, [rsi] ; stack size
    mov r13d, [rsi+4] ; stack top

    call stack32_peek

    cmp eax,[stack_no_value]
    je .stack32_pop_return

    dec r13d
    mov [rsi+4], r13d ; update stack top from pointer
.stack32_pop_return:
    pop r13
    pop r12
    pop rbp
    ret
   
stack32_peek: ; function to see the top of the stack withot popping it
    ;rdi = pointer to pointer to stack (double pointer)
    ;rsi = pointer to int (top,length)

    ;create stack frame
    push rbp
    mov rbp, rsp
    ;STACK: rbp

    mov r10d, [rsi] ; stack size
    mov r11d, [rsi+4] ; stack top

    mov eax, [stack_no_value] ; general value to say nothing is on the stack
    test r11d,r11d
    jz .stack32_pop_return
    
.stack32_pop_perform:
    dec r11d  ; decrement stack top
    mov rcx,[rdi] ; calculate the address where the element is
    lea r10d, [r11d*4]
    add rcx,r10
    mov eax, [rcx] ; move stack top to eax (return address)
.stack32_pop_return:
    pop rbp
    ret

warnsdorff:
    ;rdi - pointer to grid
    ;esi - grid size
    ;rdx - pointer to array
    ;rcx - number of moves

    push rbp
    mov rbp, rsp

    push rbx

    cmp rcx,1
    jle .end_warnsdorff ; no need to sort one move

    ; enough space to store (row,column,degree) for each move in the array
    sub rsp, 96

    xor r11, r11
    mov r10,rcx
    mov rbx,rdx

    ;copy array in rdx in array on stack and add degree
    .for_loop:
        cmp r11,r10
        je .end_for_loop

        
        mov rdx,[rbx+r11*8]  ; get row,col pair

        ;here I need to calculate a displacemet r11*12
        ;since I cannot multiply by 12, I use lea to multiply x4
        ;then imul to multiply x3

        lea r9,[r11*4]
        imul r9,3
        mov [rsp+r9], rdx ; copy row,col pair to array
        xor rcx,rcx ; null pointer - I just need the number of available moves
        call available_moves

        lea r9,[r11*4]
        imul r9,3
        mov [rsp+r9+8], eax

        inc r11
        jmp .for_loop

    .end_for_loop:

    ;call to qsort
    mov rdi, rsp ; pointer to array
    mov rsi, r10 ; numb of members
    mov rdx, 12 ; size of each member (3*4bytes)
    mov rcx, warnsdorff_comparator
    push r10
    call qsort
    pop r10

    ;now that they have been sorted, copy sorted array (without degree) back
    xor r11, r11
    .for_loop2:
        cmp r11,r10
        je .end_for_loop2

        lea r9,[r11*4]
        imul r9,3
        mov rax,[rsp+r9]
        mov [rbx+r11*8],rax

        inc r11
        jmp .for_loop2

    .end_for_loop2:


    add rsp, 96
.end_warnsdorff:
    pop rbx
    pop rbp
    ret

warnsdorff_comparator:
    ;rdi - pointer to a
    ;rsi - pointer to b
    mov r8d,[rdi+8]
    mov r9d,[rsi+8]
    
    xor rax,rax
    xor rdx,rdx
    cmp r8d,r9d

    setg al
    setl dl
    sub rax,rdx
    ret


   
available_moves:
    ;rdi - pointer to grid
    ;esi - grid size
    ;rdx - row,column
    ;rcx - pointer to array of 64bytes

    ;caller-saved used registers:
    ;r8
    ;r9
    ;rdx
    ;rax

    push rbp
    mov rbp, rsp

    push r12 ; index in offset
    push r13 ; row
    push r14 ; col
    push r15 ; new row
    push rbx ; number of available moves


    xor r12, r12 
    xor rbx, rbx

    ; use SIMD registers / instructions (SSE2) to help me with coordinate operations

    pxor xmm0,xmm0
    movq xmm0, rdx  ; starting point
    
    pxor xmm4,xmm4
    movd xmm4, esi ; grid size
    pshufd  xmm4, xmm4, 0x00 ;broadcast grid_size to all the int32 in xmm4


    .for_loop_available_moves:
            ;check if we reached end of offset array
            cmp r12,8
            jge .end_available_moves

            pxor xmm1, xmm1
            movq xmm1, [offsets+r12*8] ; move a pair of offsets

            paddd xmm1,xmm0  ; (row,col) + (d-row,d-col)
           
            inc r12

            ;test if xmm1 is < 0 and >= gridsize

            ;first part: is xxm1<0 ?

            pxor xmm2,xmm2 ; zero vector for mask
            pcmpgtd  xmm2,xmm1 ; compare each int in xmm1 with 0 (xmm2) → xmm3[i] = 0xFFFFFFFF if xmm1[i] < 0

            pmovmskb eax, xmm2 ; extract one bit per byte (16 bits) to eax
            test    eax, eax          ; check if any of the bits are set
            jnz .for_loop_available_moves ; row,column is < 0

            ;test if xmm1 > grid size or xmm1==grid_size


            movaps xmm2,xmm1 ; copy value of xmm1 because I need later and xmm1 will undertake distructive operations    
            movaps xmm3,xmm1       

            pcmpgtd  xmm1,xmm4  ; compare each int in xmm0 with grid_size → xmm1[i] = 0xFFFFFFFF if xmm1[i] > grid_size
            pcmpeqd  xmm3, xmm4  ; compare each int in xmm0 with grid_size → xmm1[i] = 0xFFFFFFFF if xmm1[i] == grid_size
            por xmm1,xmm3      ; combine results
            pmovmskb eax, xmm1 ; get results like before
            test eax,eax
            jnz .for_loop_available_moves

            ; need to check if the cell is empty

            movd r13d, xmm2 ; row
            psrldq xmm2,4 ;4 byte shift
            movd r14d, xmm2 ; column

            mov edx, r13d
            imul edx, esi
            
            add edx,r14d
            mov eax,[rdi+rdx*4]
            test eax, eax
            jnz .for_loop_available_moves

            ; add locations on array
            ; if I have a null-pointer, no need to do anything furter
            test rcx, rcx
            jz .end_for_loop 

            mov [rcx+rbx*8], r13d
            mov [rcx+rbx*8+4], r14d

        .end_for_loop:
            inc rbx

            jmp .for_loop_available_moves

.end_available_moves:
    mov rax,rbx
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret


solver:
    ;rdi - pointer to grid
    ;esi - grid_size
    ;rdx - row, columns

    ; create stack frame
    push rbp
    mov rbp, rsp

    ;STACK: rbp

    push r15 ; callee-saved
    push r14 ; callee-saved
    push r13
    push r12
    push rbx
    push rdi
    push rsi ; save rsi instead of esi to mantain memory alignment
    
    ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi
    
    ;calculate goal number
    mov r15d, esi
    imul r15d, r15d
    ;r15d =  goal number

    ;allocate memory for stack and list of moves
    
    sub rsp, 8 ; reserve 2 int on the stack 
    ;first int: stack size
    ;second int; stack top idx
    mov rdi, rsp ; address of the allocated ints

    ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes)

    push rdx
    ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes), rdx
    
    call stack32_create
    pop rdx
    push rax
    ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes); address-to-stack

    ; add start position and number 1 to stack
    ; use rdx as start/current position pair
    ; use r14 to manipulate it
    mov r14, rdx

    mov rdi, rsp   ; pointer to pointer to array
    lea rsi, [rsp+8] ; pointer to stack infos
    mov edx, r14d  ; value to push (row)
    call stack32_push

    mov rdi, rsp   ; pointer to pointer to array
    lea rsi, [rsp+8] ; pointer to stack infos
    shr r14, 32    
    mov edx,r14d  ; value to push (column)
    call stack32_push

    mov rdi, rsp   ; pointer to pointer to array
    lea rsi, [rsp+8] ; pointer to stack infos
    mov edx, 1     ; starting value
    call stack32_push


    ;do the same passages as above to allocate a stack structure for moves
    sub rsp,8
    mov rdi,rsp
    call stack32_create
    push rax

    ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes); address-to-stack; (8bytes); address-to-moves


    .while_stack_is_not_empty:
        ;r15d =  goal number

        lea rdi, [rsp+16]
        lea rsi, [rsp+24]

        cmp dword [rsi+4], 0
        je .solver_ret ; stack is empty - finish to iter

        
        call stack32_pop
        mov r13d, eax ; number

        ;rdi and rsi are already set at this point
        call stack32_pop 
        mov ebx, eax ; column
        
        ;rdi and rsi are already set at this point
        call stack32_pop 
        mov r12d, eax ; row

        ;set popped value on grid
        mov rsi, [rsp+32] ; grid size
        mov rdi, [rsp+40] ; pointer to grid

        ;need to pack location now in rdx
        mov edx, ebx
        shl rdx, 32
        mov eax, r12d
        or rdx, rax

        mov ecx, r13d ; number
        call set_value

        ; add move to stack of moves
        mov rdi, rsp
        lea rsi, [rsp+8]
        mov edx, r12d ; row
        call stack32_push

        mov edx, ebx ; column
        call stack32_push

        mov edx, r13d ; number
        call stack32_push

        ; check if we are done
        cmp r13d, r15d
        je .solver_ret
        

        ;find available moves
        inc r13d ; increment to calculate next number to be inserted

        sub rsp, 64 ; reserve 64bytes on stack for the available moves (8 pairs * 4 bytes per number)
        ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes); address-to-stack; (8bytes); address-to-moves, 64bytes

        ; calling available location
        mov rdi, [rsp+104] ;pointer to grid
        mov rsi, [rsp+96] ; grid size
        mov edx, ebx
        shl rdx, 32
        or rdx, r12
        lea rcx, [rsp]
        call available_moves

        
        ;if I found moves, I need to extend the stack
        test rax,rax
        jz .if_no_valid_moves

        mov rbx, rax ; move number of found moves in rbx bc is callee-saved

        mov rdi, [rsp+104] ;pointer to grid
        mov rsi, [rsp+96] ; grid size
        lea rdx, [rsp]
        mov rcx, rax

        call warnsdorff

        

        .for_push_on_stack_valid_moves:
            ; i put the test on the bottom bc if I get here I surely have stuff to
            ; push on the stack of available moves

            dec rbx

            mov r12, [rsp+rbx*8] ; move pair in one move

            lea rdi, [rsp+80] ; pointer to pointer to array
            lea rsi, [rsp+88] ; pointer to stack infos
            mov edx, r12d  ; value to push (row)
            call stack32_push

            ; rdi and rsi are alraedy set at this point
            shr r12, 32 ; shift column coord
            mov edx, r12d  ; value to push (column)
            call stack32_push

            ; rdi and rsi are alraedy set at this point
            mov edx, r13d  ; value to push number
            call stack32_push

            test rbx, rbx
            jz .while_clean_up_stack ; repeat the outer while
            jmp .for_push_on_stack_valid_moves ; still have available moves 


    .if_no_valid_moves:
        ; this is the hard part - this is where the backtrack is implemented
        lea rdi, [rsp+80] ; pointer to pointer to array stack
        lea rsi, [rsp+88] ; pointer to stack infos
        call stack32_peek
        mov r14d, eax
        .while_pop_if:
            lea rdi, [rsp+64] ; pointer to pointer to array moves
            lea rsi, [rsp+72] ; pointer to array moves infos
            cmp dword [rsi+4],0
            je .while_clean_up_stack ; stack of moves is empty
            call stack32_peek
            cmp eax, r14d
            jl .while_clean_up_stack ; nothing else to pop
            call stack32_pop ; remove the number - not needed
            call stack32_pop ; pop column
            mov edx, eax
            shl rdx,32
            call stack32_pop ; pop row
            or rdx, rax

            ;now rdx contains packed coordinates popped from moves
            ;this is because a call to set value expects that in rdx
            xor rcx,rcx ; the value to set is 0

            mov rsi, [rsp+96] ; grid size
            mov rdi, [rsp+104] ; pointer to grid

            call set_value

            jmp .while_pop_if


    
    .while_clean_up_stack:
        add rsp, 64 ; i don't need the array of available moves in the stack anymore
        ;STACK: rbp, r15, r14, r13, r12, rbx, rdi, rsi, (8bytes); address-to-stack; (8bytes); address-to-moves
        jmp .while_stack_is_not_empty




.solver_ret:
    pop rdi ; recover the address from the stack and put in on rdi to free memory
    call free
    add rsp, 8
    pop rdi ; recover the address from the stack and put in on rdi to free memory
    call free
    add rsp, 8
    pop rsi
    pop rdi
    pop rbx
    pop r12
    pop r13
    pop r14
    pop r15
    pop rbp
    ret





main:
    ; create stack frame
    push rbp
    mov rbp, rsp

    ;STACK: rbp
    ; preserving registers for calling convention
    push rbx
    push r15
    
    ; reserve memory on stack for grid
    xor rax,rax
    mov eax, [grid_size]
    imul rax,rax
    lea rbx,[rax*4]
    add rbx, 15 ; useful for memory alignment
    and rbx,-16 ; useful for memory alignment
    sub rsp,rbx
    mov r15, rsp ; r15 = pointer to grid (r15 is callee-saved)
    push rbx
    sub rsp, 32 ; reserve space for struct timespec

    ;STACK: rbp, rbx, r15, GRID (size of gridsize*grid_size*4) + padding; rbx (size of grid with padding); tstart;tend

    ;set grid to 0
    mov rdi, r15 ; first param: memory address
    xor rsi,rsi  ; second param: character (0)
    mov rdx, rbx ; number of bytes
    call memset

    ;get start time
    mov rdi, CLOCK_MONOTONIC
    lea rsi, [rsp+16]
    call clock_gettime

    mov rdi, r15
    mov esi, [grid_size]
    mov rdx, [start_position]

    
    call solver

    ;get end time
    mov rdi, CLOCK_MONOTONIC
    mov rsi, rsp
    call clock_gettime
    ; print grid
    mov rdi, r15
    mov esi, [grid_size]
    call print_grid



    ; compute the difference
    mov rax, [rsp]           ; tend.tv_sec
    sub rax, [rsp+16]         ; sec = tend - tstart
    mov rbx, [rsp + 8]       ; tend.tv_nsec
    sub rbx, [rsp + 24]     ; nsec = tend - tstart

    ; handle nanosecond underflow
    cmp rbx, 0
    jge .print_elapsed_time

    dec rax                   ; subtract 1 second
    add rbx, 1000000000       ; add 1_000_000_000 ns

.print_elapsed_time:
    mov rdi, elapsed_time_fmt
    mov rsi,rax
    mov rdx,rbx
    xor rax,rax
    call printf

    ; return
    ; restore stack
    add rsp,32
    pop rbx
    add rsp,rbx
    pop r15
    pop rbx
    pop rbp    

    xor rax, rax
    ret


section .note.GNU-stack progbits
