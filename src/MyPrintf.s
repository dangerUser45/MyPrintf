;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
;           MACRO

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
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
;           CONSTS

LENGTH_BUFFER                   equ     64d
LENGTH_ERORR_UNKN_SPECFR_STRING equ     38d

;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
section     .data

JumpTable:                   dq PrintBinary
                             dq PrintChar
                             dq PrintDecimal
                             times 'o' - 'd' - 1 dq UnknownSpecifierError
                             dq PrintOct
                             times 's' - 'o' - 1 dq UnknownSpecifierError
                             dq PrintString
                             times 'x' - 's' - 1 dq UnknownSpecifierError
                             dq PrintHex

Buffer:                      db LENGTH_BUFFER dup(0x0)
TableHexDigits:              db "0123456789abcdef"
ErrorUnknownSpecifierString: db  0x1B, 0x5B, 0x33, 0x31, 0x3B, 0x31, 0x6D, "%(ERROR: UNKNOWN SPECIFIER)", 0x1B, 0x5B, 0x30, 0x6D
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------

section .note.GNU-stack
section .text
    global MyPrintf

;-------------------------------------------------------------------------------------------------------;
; DESCRIPTION: printf to stdout                                                                         ;
; ENTRY:   None                                                                                         ;
; EXIT:    None                                                                                         ;
; DESTROY: RAX, RBX, RCX, RDX, RDI, RSI, R8, R11                                                        ;
;-------------------------------------------------------------------------------------------------------;
MyPrintf:
    mov r11, rsp
    pop r10
    PUSH_6_PARAM                                    ;| Пушу регистры в стек
    mov r8, rsp                                     ;| сохраняется адрес последнего пуша
    add r8, 24                                      ;| + 16, т.к. rodata(+8) и адрес при push rbx(+8) - скип
    mov rsi, rdi                                    ;| rsi - Msg
    lea rdi, Buffer                                 ;| rdi - Buffer



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
; DESCRIPTION:  Specifiers are processed                                                                ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8  - stack address where the current parameter is stored                               ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      RBX, RDI, RSI                                                                           ;
;-------------------------------------------------------------------------------------------------------;
ProcessingSpecifier:

    inc rsi                                         ;| skip '%' in format string

    xor rbx, rbx
    mov bl, byte [rsi]

    cmp bl, '%'
    jne .Next
    mov byte [rdi], bl
    inc rsi
    inc rdi
    ret

    .Next:
    cmp bl, 'b'
    jb UnknownSpecifierError

    cmp bl, 'x'
    ja UnknownSpecifierError

    jmp [JumpTable + 8 * (rbx - 'b')]
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  put char in buffer                                                                      ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8  - stack address where the current parameter is stored                               ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      BL                                                                                      ;
;-------------------------------------------------------------------------------------------------------;
PrintChar:

    mov bl, byte [r8]                               ;\ <=> mov byte from stack to buffer
    mov byte [rdi], bl                              ;/

    inc rdi                                         ;\ - rdi++ чтобы установить правильное смещение буфера
    add r8, 8                                       ;| - r8 += 8 чтобы установить правильное смещение для аргументов в стеке
    inc rsi                                         ;/ - rsi++ чтобы установить правильное смещение в форматной строке

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  printf string from parametr with specifier %s                                           ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8  - stack address where the current parameter is stored                               ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      RAX, RBX, RCX                                                                           ;
;-------------------------------------------------------------------------------------------------------;
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

    mov rdx, rcx                                        ;| Argument: (rdx) - length source string (buffer)
    mov rax, 0x01                                       ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01                                       ;| stdout
    syscall
    mov rdi, Buffer
    jmp .End
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Strlen counts the number of characters in the string                                    ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8 - stack address where the current parameter is stored                                ;
;                                                                                                       ;
; EXIT:         RCX - length of string                                                                  ;
; DESTROY:      AL, RCX                                                                                 ;
;-------------------------------------------------------------------------------------------------------;
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
; DESCRIPTION:  Numbers with base divisible by 2 are converted to ASCII-code and put into the buffer    ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8 - stack address where the current parameter is stored                                ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      RAX, RBX, RCX , RDX                                                                     ;
;-------------------------------------------------------------------------------------------------------;
NumberHandler:

    std
    push rax
    inc rsi

    mov  rbx,  [r8]
    push rbx
    call LengthNumber

    test rbx, rbx
    jns .NumIsPositive
    neg rbx
    inc rax
    mov dh, 0x1

.NumIsPositive:
    add rdi, rax                                        ;| add the length of the number (in bytes) to the buffer address
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

    cmp dh, 0x1
    jne .SkipMinus
    mov al, '-'
    stosb

.SkipMinus:
    pop rdi
    inc rdi

    add r8, 8
    pop rax
    cld
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Strlen counts the number of characters in the string                                    ;
; ENTRY:        CL - number of bits defining one digit in the current number system                     ;
;                                                                                                       ;
; EXIT:         EAX - quantity of digits in number                                                      ;
; DESTROY:      RAX, RBX                                                                                ;
;-------------------------------------------------------------------------------------------------------;
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
; DESCRIPTION:  The buffer is checked for overflow                                                      ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      None                                                                                    ;
;-------------------------------------------------------------------------------------------------------;
CheckBuffer:

    cmp rdi, Buffer + LENGTH_BUFFER                 ;| - проверяю не заполнен ли буфер
    jb .BufferIsOK                                  ;| - если буфер не заполнен  => ret
    call BufferReset                                ;| - в противном случае => очистка буфера

    .BufferIsOK:
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Resets the buffer - syscall, which prints the contents of the
;               buffer and then sets rdi to the beginning for future use                                ;

; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      None                                                                                    ;
;-------------------------------------------------------------------------------------------------------;
BufferReset:

    push rsi
    push rcx
    push rax
    push rdx
    sub rdi, rax
    call SyscallPrint                               ;| - call functions which printing all buffer
    pop rdx
    pop rax
    pop rcx
    pop rsi

    lea rdi, Buffer                                 ;\ - set new buffer
    add rdi, rax                                    ;/

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  It works similarly to the “BufferReset” function                                        ;
;               but it is used in the main loop in main                                                 ;
;                                                                                                       ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      None                                                                                    ;
;-------------------------------------------------------------------------------------------------------;
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
; DESCRIPTION:  Displays the contents of the buffer                                    ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8 - stack address where the current parameter is stored                                ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      RAX, RDX, RSI, RDI                                                                      ;
;-------------------------------------------------------------------------------------------------------;
SyscallPrint:

    mov rsi, Buffer                                 ;| Argument: (rsi) - address source string (buffer)
    sub rdi, rsi                                    ;|
    mov rdx, rdi                                    ;| Argument: (rdx) - length source string (buffer)

    mov rax, 0x01                                   ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01                                   ;| stdout
    syscall

    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Puts numbers in hexadecimal format into the ASCII - codes buffer                        ;
; ENTRY:        None                                                                                    ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      CL, DL                                                                                  ;
;-------------------------------------------------------------------------------------------------------;
PrintHex:

    mov dl, 0xf
    mov cl, 4

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Strlen counts the number of characters in the string                                    ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               RBX - the base of the number system, i.e. 10d                                           ;
;               R8 - stack address where the current parameter is stored                                ;
;
; EXIT:         None                                                                                    ;
; DESTROY:      AL, RCX                                                                                 ;
;-------------------------------------------------------------------------------------------------------;
PrintDecimal:

    push rsi
    mov eax, [r8]

    mov ebx, 10d
    test eax, eax
    jns .NumberIsPositive

.NumberIsNegative:
    mov byte [rdi], '-'
    inc rdi
    neg eax

.NumberIsPositive:
    xor edx, edx
    call LengthNumberDecimal

    add rdi, rcx
    push rdi

    mov esi, eax
    mov rax, rcx
    call CheckBuffer
    mov eax, esi

.Cycle:

    xor edx, edx
    div ebx
    add dl, '0'
    mov byte [rdi], dl
    dec rdi
    test eax, eax
    jne .Cycle

.End:
    pop rdi
    inc rdi
    pop rsi
    inc rsi
    mov al, '%'
    add r8, 8
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Strlen counts the number in decinal format                                              ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               RBX - the base of the number system, i.e. 10d                                           ;
;               R8 - stack address where the current parameter is stored                                ;
;
; EXIT:         None                                                                                    ;
; DESTROY:      RCX, RDX                                                                                ;
;-------------------------------------------------------------------------------------------------------;
LengthNumberDecimal:

    push rax
    xor rcx, rcx

.Cycle:
    xor rdx, rdx
    div rbx
    inc rcx
    test rax, rax
    jne .Cycle

    dec rcx
    pop rax
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Puts numbers in octal format into the ASCII - codes buffer                              ;
; ENTRY:        None                                                                                    ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      CL, DL                                                                                  ;
;-------------------------------------------------------------------------------------------------------;
PrintOct:

    mov dl, 0x7
    mov cl, 3

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Puts numbers in binary format into the ASCII - codes buffer                              ;
; ENTRY:        None                                                                                    ;
;                                                                                                       ;
; EXIT:         None                                                                                    ;
; DESTROY:      CL, DL                                                                                  ;
;-------------------------------------------------------------------------------------------------------;
PrintBinary:

    mov dl, 0x1
    mov cl, 1

    call NumberHandler
    ret
;--------------------------------------------------------------------------------------------------------
;////////////////////////////////////////////////////////////////////////////////////////////////////////
;--------------------------------------------------------------------------------------------------------
; DESCRIPTION:  Error handling of incorrect specifier (unprocessed ASCII code after ‘%’)                ;
; ENTRY:        RDI - address buffer; RSI - address format string                                       ;
;               R8 - stack address where the current parameter is stored                                ;
;                                                                                                       ;
; EXIT:        None                                                                                     ;
; DESTROY:     RAX                                                                                      ;
;-------------------------------------------------------------------------------------------------------;
UnknownSpecifierError:

    push rsi
    cmp rdi, Buffer
    je .BufferIsClean

    call BufferResetMain

.BufferIsClean:
    mov rsi, ErrorUnknownSpecifierString                    ;| Argument: (rsi) - address source string (buffer)
    mov rdx, LENGTH_ERORR_UNKN_SPECFR_STRING                ;| Argument: (rdx) - length source string (buffer)

    mov rax, 0x01                                           ;| write64 (rdi, rsi, rdx) ... r10, r8, r9
    mov rdi, 0x01                                           ;| stdout
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
