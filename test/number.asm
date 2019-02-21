extern printf

section .data
align 8
var_BASE: dq 8

section .text

NUMBER:
    ; in non-forth env, we don't need to pop/push the stack
    ; pop rcx                 ; length of string
    ; pop rdi                 ; start address of string
    call .NUMBER
    ; push rax                ; parsed number
    ; push rcx                ; number of unparsed characters (0 = no error)
    ret

.NUMBER:
    xor rax, rax
    xor rbx, rbx

    test rcx, rcx           ; trying to parse a zero-length string is an error, but will return 0.

    jz .ret

    mov rdx, [var_BASE]     ; get BASE (in dl)

    ; Check if first character is '-'.
    mov bl, [rdi]           ; bl = first character in string
    inc rdi
    push rax                ; push 0 on stack
    cmp bl, '-'             ; negative number?
    jnz .convert
    pop rax
    push rbx                ; push <> 0 on stack, indicating negative
    dec rcx
    jnz .loop
    pop rbx                 ; error: string is only '-'.
    mov rcx, 1
    ret

    ; Loop reading digits.
.loop:
    imul rax, rdx           ; rax *= BASE
    mov bl, [rdi]           ; bl = next character in string
    inc rdi

    ; Convert 0-9, A-Z to a number 0-35.
.convert:
    sub bl, '0'             ; < '0'?
    jb .finish
    cmp bl, 10              ; <= '9'?
    jb .digit
    sub bl, 17              ; < 'A'? (17 is 'A'-'0')
    jb .finish
    add bl, 10

.digit:
    cmp bl, dl              ; >= BASE?
    jge .finish

    ; OK, so add it to rax and loop.
    add rax, rbx
    dec rcx
    jnz .loop

    ; Negate the result if first character was '-' (saved on the stack).
.finish:
    pop rbx
    test rbx,rbx
    jz .ret
    neg rax

.ret:
    ret

section .text
global main
main:
    mov rdi, str    ; address
    mov rcx, [len]  ; len
    call NUMBER
    mov rsi, rax
    mov rdi, format
    xor rax, rax
    call printf

section .data
align 8
str: db "31"
align 8
len: dq 2
format: db "%d",0x0A,0x00
