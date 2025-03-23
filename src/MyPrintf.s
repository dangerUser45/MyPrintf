;--------------------------------------------------------------------------------
;           MACRO
;
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
;           CONSTS

LENGTH_BUFFER                   equ     128d
LENGTH_ERORR_UNKN_SPECFR_STRING equ     38d

;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section     .data

JumpTable:                   dq CaseDefault, CaseB,       CaseC,       CaseD
                             dq CaseDefault, CaseDefault, CaseDefault, CaseDefault
                             dq CaseDefault, CaseDefault, CaseDefault, CaseDefault
                             dq CaseDefault, CaseDefault, CaseO,       CaseDefault
                             dq CaseDefault, CaseDefault, CaseS,       CaseDefault
                             dq CaseDefault, CaseDefault, CaseDefault, CaseX
                             dq CaseDefault, CaseDefault

Buffer:                      db LENGTH_BUFFER dup(0x0)
TableHexDigits:              db "0123456789abcdef"
ErrorUnknownSpecifierString: db  0x1B, 0x5B, 0x33, 0x31, 0x3B, 0x31, 0x6D, "%(ERROR: UNKNOWN SPECIFIER)", 0x1B, 0x5B, 0x30, 0x6D
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section .note.GNU-stack
section .text
    global MyPrintf
;--------------------------------------------------------------------------------
MyPrintf:

    pop r10
    PUSH_6_PARAM                                    ;| Пушу 6 параметров в стек
    mov r8, rsp                                     ;| сохраняется адрес последнего пуша
    add r8, 16                                      ;| + 16, т.к. rodata(+8) и адрес при push rbx(+8) - скип
    mov rsi, rdi                                    ;| rsi - Msg
    lea rdi, Buffer                                 ;| rdi - Buffer

    xor r9, r9

    mov al, '%'                                     ;| кладу в al - '%', чтобы в функции scasb сравнивать al и [rdi]

    .MainCycle:

        cmp rdi, Buffer + LENGTH_BUFFER             ;\ - проверяю в начале не заполнен ли буфер
        jne  .BufferIsOk                            ;/

        call BufferReset
        jmp .MainCycle

    .BufferIsOk:
        mov dl, byte [rsi]                          ;\ - проверка текущего байта на '\0'
        cmp dl, 0x0                                 ;|
        je .EndPrintf                               ;/ - Если да => завершение функции, если нет => продолжаем

        mov rbx, rdi
        mov rdi, rsi                                ;| - проверяем format string на '%'
        scasb                                       ;|
        mov rdi, rbx                                ;/

        jne .PutInBuffer                            ;\ - если нет '%' => кладём символ в буфер
        call ProcessingSpecifier                    ;| - если да      => вызываем обработчика спецификаторов
        jmp .MainCycle                              ;/

    .EndPrintf:
        SYSCALL_PRINT                               ;\ - завершение функции
        mov r8, rsp                                 ;|
        mov [r8], r10                               ;|
        ret                                         ;/

    .PutInBuffer:
        movsb                                       ;\
        movsb                                       ;| - move byte from format string to buffer
        jmp .MainCycle                              ;/
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
ProcessingSpecifier:

    inc rsi                                         ;| skip '%' in format string

    xor rbx, rbx
    mov bl, byte [rsi]
    sub bl, 'a'

    cmp bl, 0x0 - 0x1
    ja CaseDefault

    cmp bl, 0x19
    ja CaseDefault

    jmp [JumpTable + 8 * rbx]

    CaseB:
        call PrintBinary
        ret

    CaseC:
        call PrintChar
        ret

    CaseD:
        ;call PrintInteger
        ;ret

    CaseO:
        call PrintOct
        ret

    CaseX:
        call PrintHex
        ret

    CaseS:
        ;call PrintString
        ;ret

    CaseDefault:
        call UnknownSpecifierError
        ret

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintChar:

    SET_CHAR
    inc r9
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
NumberHandler:

    std
    push rax
    inc rsi
    inc r9

    mov rbx,  [r8]
    push rbx

    call LengthNumber

    pop rbx

    add rdi, rax                        ;| add the length of the number (in bytes) to the buffer address
    push rdi

    xor rax, rax

.SetNumber:
    mov al, bl
    and al, dl

    mov al, [TableHexDigits + rax]
    call CheckBuffer
    stosb

    shr rbx, cl
    cmp rbx, 0x0
    jne .SetNumber

    pop rdi
    inc rdi

    add r8, 8
    pop rax
    cld
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
LengthNumber:

    xor rax, rax

.Cycle:

    cmp rbx, 0x0
    je .End
    inc al
    shr rbx, cl
    jmp .Cycle

.End:
    dec al
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
CheckBuffer:

    cmp rdi, Buffer + LENGTH_BUFFER             ;\ - проверяю не заполнен ли буфер
    jne .BufferIsOK                              ;/
    call BufferReset

    .BufferIsOK:
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
BufferReset:

    push rdi
    push rsi
    push rdx
    push rcx
    push rax
    push rbx
    SYSCALL_PRINT                               ;\ - call functions which printing all buffer
    pop rbx
    pop rax
    pop rcx
    pop rdx
    pop rsi
    pop rdi                                     ;/

    lea rdi, Buffer                             ;\ - set new buffer
    mov al, '%'                                 ;|
                                                ;|
    ret                                         ;/
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintHex:

    mov dl, 0xf
    mov cl, 4

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintOct:

    mov dl, 0x7
    mov cl, 3

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintBinary:

    mov dl, 0x1
    mov cl, 1

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
UnknownSpecifierError:

    push rsi
    mov rsi, ErrorUnknownSpecifierString

    mov cx, LENGTH_ERORR_UNKN_SPECFR_STRING
    rep movsb
    pop rsi
    inc rsi
    add r8, 8

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
ExitProgram:

    mov rax, 0x3C      ; exit64 (rdi)
    syscall

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
