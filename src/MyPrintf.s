
;=======================================================================================;
;   rax - storage '%'                                                                   ;
;   rbx - not used (callee-save register)                                               ;
;                                                                                       ;
;   rcx - not used                                                         \            ;
;   rdx - not used                                                         | registers  ;
;   rdi - address of buffer                                                | for        ;
;   rsi - address of format string                                         | parametres ;
;   r8  - address for param in stack                                       |            ;
;   r9  - counter for param in stack                                       /            ;
;                                                                                       ;
;   rsp - stack top                                                                     ;
;   rbp - stack bottom (callee-save register)                                           ;
;                                                                                       ;
;   r10 - address of arguments in stack                                                 ;
;   r11 - register for indexing in jump table                                           ;
;   r12 - not used (callee-save register)                                               ;
;   r13 - not used (callee-save register)                                               ;
;   r14 - not used (callee-save register)                                               ;
;   r15 - not used (callee-save register)                                               ;
;   r16 - not used (callee-save register)                                               ;
;=======================================================================================;
;--------------------------------------------------------------------------------
;           MACRO

%macro PUSH_6_PARAM 0x0
    push r9     ; sixth argument
    push r8     ; fifth argument
    push rcx    ; fourth  argument
    push rdx    ; third argument
    push rsi    ; second argument
    push rdi    ; first argument
    push rbx
%endmacro
;--------------------------------------------------------------------------------
%macro POP_6_PARAM 0x0
    pop rbx
    pop rdi    ; first argument
    pop rsi    ; second argument
    pop rdx    ; third argument
    pop rcx    ; fourth  argument
    pop r8     ; fifth argument
    pop r9     ; sixth argument
%endmacro
;--------------------------------------------------------------------------------
%macro SYSCALL_PRINT 0x0
    mov rsi, Buffer   ;| Argument: (rsi) - address source string (buffer)
    sub rdi, rsi      ;|
    mov rdx, rdi      ;| Argument: (rdx) - length source string (buffer)

    mov rax, 0x01     ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01     ;| stdout
    syscall
%endmacro
;--------------------------------------------------------------------------------
%macro SET_CHAR 0x0
    mov rbx, [r8]               ;\ <=> mov byte from stack to buffer
    mov [rdi], rbx              ;/

    inc rdi                     ;\ - rdi++ чтобы установить правильное смещение буфера
    add r8, 8                   ;| - r8 += 8 чтобы установить правильное смещение для аргументов в стеке
    inc rsi                     ;/ - rsi++ чтобы установить правильное смещение в форматной строке
%endmacro
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section     .data

JumpTable:  dq CaseB,       CaseC,       CaseD,       CaseDefault
            dq CaseDefault, CaseDefault, CaseDefault, CaseDefault
            dq CaseDefault, CaseDefault, CaseDefault, CaseDefault
            dq CaseDefault, CaseO,       CaseDefault, CaseDefault
            dq CaseDefault, CaseS,       CaseX

Buffer:     db 128 dup(0x0)
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
;           CONSTS

LENGTH_BUFFER               equ         128d

;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section .note.GNU-stack
section .text
    global MyPrintf

;--------------------------------------------------------------------------------
MyPrintf:

    PUSH_6_PARAM                                    ;| Пушу 6 параметров в стек
    mov r8, rsp                                     ;| сохраняется адрес последнего пуша
    add r8, 16                                      ;| + 16, т.к. rodata(+8) и адрес при push rbx(+8) - скип
    mov rsi, rdi                                    ;| rsi - Msg
    lea rdi, Buffer                                 ;| rdi - Buffer

    xor r9, r9

    mov al, '%'                                     ;| кладу в al - '%', чтобы в функции scasb сравнивать al и [rdi]

    .Cycle:

        cmp rdi, Buffer + LENGTH_BUFFER             ;\ - проверяю в начале не заполнен ли буфер
        je .BufferReset                             ;/

        mov dl, byte [rsi]                          ;\ - проверка текущего байта на '\0'
        cmp dl, 0x0                                 ;|
        je .EndPrintf                               ;/ - Если да => завершение функции, если нет => продолжаем

        mov rbx, rdi
        mov rdi, rsi                                ;| - проверяем format string на '%'
        scasb                                       ;|
        mov rdi, rbx                                ;/

        jne .PutInBuffer                            ;\ - если нет '%' => кладём символ в буфер
        call ProcessingSpecifier                    ;| - если да      => вызываем обработчика спецификаторов
        jmp .Cycle                                  ;/

    .EndPrintf:
        SYSCALL_PRINT                               ;\ - завершение функции
        POP_6_PARAM                                 ;|
        ret                                         ;/

    .PutInBuffer:
        movsb                                       ;\
        movsb                                       ;| - move byte from format string to buffer
        jmp .Cycle                                  ;/

    .BufferReset:
        push rsi
        SYSCALL_PRINT                               ;\ - call functions which printing all buffer
        pop rsi                                     ;|

        lea rdi, Buffer                             ;| - set new buffer
        mov al, '%'                                 ;|
                                                    ;|
        jmp .Cycle                                  ;/
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
ProcessingSpecifier:
    inc rsi

    xor rbx, rbx
    mov bl, byte [rsi]
    sub rbx, 'b'

    cmp bl, 0x0 - 0x1
    ja CaseDefault

    cmp bl, 0x19
    ja CaseDefault

    jmp [JumpTable + 8 * rbx]

    CaseB:
        ;call PrintBinary
        ret

    CaseC:
        call PrintChar
        ret

    CaseD:
        ;call PrintInteger
        ret

    CaseO:
        ;call PrintOct
        ret

    CaseX:
        ;call PrintDex
        ret

    CaseS:
        ;call PrintString
        ret

    CaseDefault:
        ret

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintChar:

    cmp r9, 6 - 1
    je  .Counter_equal_six_param
    jb  .Counter_below_six_param
    jmp .Counter_above_six_param

    .Counter_below_six_param:
    inc r9
    .Counter_above_six_param:
    SET_CHAR
    ret

    .Counter_equal_six_param:
    inc r9
    SET_CHAR
    add r8, 8
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
ExitProgram:

    mov rax, 0x3C      ; exit64 (rdi)
    xor rdi, rdi
    syscall

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
