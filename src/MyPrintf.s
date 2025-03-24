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
    push r11
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
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
;           CONSTS

LENGTH_BUFFER                   equ     20d
LENGTH_ERORR_UNKN_SPECFR_STRING equ     38d

;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section     .data

JumpTable:                   dq PrintBinary,           PrintChar,             PrintDecimal,          UnknownSpecifierError
                             dq UnknownSpecifierError, UnknownSpecifierError, UnknownSpecifierError, UnknownSpecifierError
                             dq UnknownSpecifierError, UnknownSpecifierError, UnknownSpecifierError, UnknownSpecifierError
                             dq UnknownSpecifierError, PrintOct,              UnknownSpecifierError, UnknownSpecifierError
                             dq UnknownSpecifierError, PrintString,           UnknownSpecifierError, UnknownSpecifierError
                             dq UnknownSpecifierError, UnknownSpecifierError, PrintHex

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
    mov r11, rsp
    pop r10
    PUSH_6_PARAM                                    ;| Пушу 6 параметров в стек
    mov r8, rsp                                     ;| сохраняется адрес последнего пуша
    add r8, 24                                      ;| + 16, т.к. rodata(+8) и адрес при push rbx(+8) - скип
    mov rsi, rdi                                    ;| rsi - Msg
    lea rdi, Buffer                                 ;| rdi - Buffer

    xor r9, r9

    mov al, '%'                                     ;| кладу в al - '%', чтобы в функции scasb сравнивать al и [rdi]

    .MainCycle:

        cmp rdi, Buffer + LENGTH_BUFFER             ;\ - проверяю в начале не заполнен ли буфер
        jne  .BufferIsOk                            ;/

        call BufferResetMain
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
        call SyscallPrint                               ;\ - завершение функции
        pop rsp                                     ;|
        mov [rsp], r10                              ;|
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
    sub bl, 'b'

    cmp bl, 0x0
    jb UnknownSpecifierError

    cmp bl, 0x19
    ja UnknownSpecifierError

    jmp [JumpTable + 8 * rbx]
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintChar:

    call SetChar
    inc r9
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
SetChar:

    mov bl, byte [r8]           ;\ <=> mov byte from stack to buffer
    mov byte [rdi], bl          ;/

    inc rdi                     ;\ - rdi++ чтобы установить правильное смещение буфера
    add r8, 8                   ;| - r8 += 8 чтобы установить правильное смещение для аргументов в стеке
    inc rsi                     ;/ - rsi++ чтобы установить правильное смещение в форматной строке

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
PrintString:
    mov rbx, rax
    mov rdx, rdi
    push rsi
    mov rdi, [r8]
    mov rsi, rdi

    call Strlen
    mov rdi, rdx

    cmp rcx, LENGTH_BUFFER - 10
    ja .LongString

    mov rax, rcx
    add rcx, rdi

    cmp rcx, Buffer + LENGTH_BUFFER
    mov rcx, rax

    jb .BufferIsOk

    push rsi
    push rcx
    call BufferResetMain
    pop rcx
    pop rsi

.BufferIsOk:
    rep movsb

.End:
    add r8, 8
    pop rsi
    inc rsi
    mov rax, rbx
    ret

.LongString:
    push rcx
    push rsi
    call BufferResetMain
    pop rsi
    pop rcx

    mov rdx, rcx      ;| Argument: (rdx) - length source string (buffer)
    mov rax, 0x01     ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01     ;| stdout
    syscall
    mov rdi, Buffer
    jmp .End
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------

; Strlen counts the number of characters in the string until it reaches the '$' character
; ENTRY: None
; EXIT:  CX - result
; DESTR: AL, RCX

Strlen:

    mov al, 0x0
    xor rcx, rcx
    dec rcx
    repne scasb
    neg rcx
    sub rcx, 2

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
NumberHandler:

    std
    push rax
    inc rsi

    inc r9

    mov  rbx,  [r8]
    push rbx

    call LengthNumber
    add rdi, rax                        ;| add the length of the number (in bytes) to the buffer address
    call CheckBuffer

    pop rbx
    push rdi

    xor rax, rax

.SetNumber:
    mov al, bl
    and al, dl

    mov al, [TableHexDigits + rax]
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
    inc eax
    shr rbx, cl
    jmp .Cycle

.End:
    dec eax
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
CheckBuffer:

    cmp rdi, Buffer + LENGTH_BUFFER             ;| - проверяю не заполнен ли буфер
    jb .BufferIsOK                              ;| - если буфер не заполнен  => ret
    call BufferReset                            ;| - в противном случае => очистка буфера

    .BufferIsOK:
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
BufferReset:

    push rsi
    push rcx
    push rax
    push rdx
    sub rdi, rax
    call SyscallPrint                          ;| - call functions which printing all buffer
    pop rdx
    pop rax
    pop rcx
    pop rsi

    lea rdi, Buffer                             ;\ - set new buffer
    add rdi, rax                                ;/

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
BufferResetMain:

    push rsi
    call SyscallPrint
    pop rsi

    mov al, '%'
    lea rdi, Buffer
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
SyscallPrint:

    mov rsi, Buffer   ;| Argument: (rsi) - address source string (buffer)
    sub rdi, rsi      ;|
    mov rdx, rdi      ;| Argument: (rdx) - length source string (buffer)

    mov rax, 0x01     ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01     ;| stdout
    syscall

    ret
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
PrintDecimal:



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
    cmp rdi, Buffer
    je .BufferIsClean

    call BufferResetMain

.BufferIsClean:
    mov rsi, ErrorUnknownSpecifierString    ;| Argument: (rsi) - address source string (buffer)
    mov rdx, LENGTH_ERORR_UNKN_SPECFR_STRING;| Argument: (rdx) - length source string (buffer)

    mov rax, 0x01                           ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01                           ;| stdout
    syscall

    mov rdi, Buffer
    mov al, '%'

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
