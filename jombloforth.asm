;; -*- nasm -*-
;;
;; Minimal FORTH compiler for Linux x86-64 systems.
;; Based on jonesforth <https://github.com/nornagon/jonesforth/>
;;
;; compile it with:
;;
;;     nasm -g -F dwarf -f elf64 -o jombloforth.o jombloforth.asm
;;     ld -o jombloforth jombloforth.o
;;
;;
;; UNLICENSE
;; ---------
;;
;; This is free and unencumbered software released into the public
;; domain.
;;
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;;
;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.
;;
;; For more information, please refer to <http://unlicense.org>


;; syscall number, generated using this command:
;;
;;    sed 's_#_%_;s_/\*_;_;s_ \*/__' /usr/include/x86_64-linux-gnu/asm/unistd_64.h > unistd_64.inc
;;
%include "unistd_64.inc"

;; see buffer allocation
%define RETURN_STACK_SIZE 8192
%define BUFFER_SIZE 4096



;; MACRO DEFINITION
;; ----------------

;; The version of this program, not to be mistaken as how many years the
;; author has been single. Please increment this number each time one year
;; passed.
%assign JOMBLO_VERSION 1
;; (that's a joke, btw)

;; Our first word
%macro NEXT 0
        lodsq
        jmp [rax]
%endmacro

;; Helper for pushing/popping from the return stack

%macro PUSHRSP 1
        lea rbp, [rbp-8]
        mov [rbp], %1
%endmacro

%macro POPRSP 1
        mov %1, [rbp]
        lea rbp, [rbp+8]
%endmacro

;; First Non-Macro Word
section .text
DOCOL:
        PUSHRSP rsi
        add rax, 8
        mov rsi, rax
        NEXT


global _start
_start:
        cld                       ; Clear direction flag
        ; Save the initial data stack pointer in variable S0
        mov [var_S0], rsp
        mov rbp, return_stack_top ; Initialize the return stack
        call set_up_data_segment
        mov rsi, cold_start
        NEXT

section .rodata
cold_start:
        dq QUIT

;; Various flags for the dictionary word header
%define F_IMMED   0x80
%define F_HIDDEN  0x20
%define F_LENMASK 0x1f

;; Holds previously defined word
;; Starts as null/zero
%define link 0

;; Macro for defining forth word
;;
;;     defword name, label, flag
;;
%macro defword 2-3 0
        %strlen name_len %1

        ;; dictionary word header
        section .rodata

        align 8, db 0
        global name_%2
        name_%2:
                dq link
                db name_len + %3
                db %1

        ;; update link to point to this word's header
        %define link name_%2

        ;; word definitions, starts with DOCOL
        align 8, db 0
        global %2
        %2:
                dq DOCOL
%endmacro


;; Macro for defining native word
;;
;;     defcode name, label, flag
;;
%macro defcode 2-3 0
        %strlen name_len %1

        ;; dictionary word header
        section .rodata
        align 8, db 0
        global name_%2
        name_%2:
                dq link
                db name_len + %3
                db %1

        ;; update link to point to this word's header
        %define link name_%2

        ;; word definition, link to the native code
        align 8, db 0
        global $%2             ; fix error for `WORD` which isn't valid label
        $%2:
                dq code_%2

        ;; native code
        section .text
        align 8
        global code_%2
        code_%2:
%endmacro

defcode "DROP", DROP
        pop rax
        NEXT

defcode "SWAP", SWAP
        pop rax
        pop rbx
        push rax
        push rbx
        NEXT

defcode "DUP", DUP
        mov rax, [rsp]
        push rax
        NEXT

defcode "OVER", OVER
        mov rax, [rsp+8]
        push rax
        NEXT

defcode "ROT", ROT
        pop rax
        pop rbx
        pop rcx
        push rbx
        push rax
        push rcx
        NEXT

defcode "-ROT", NROT
        pop rax
        pop rbx
        pop rcx
        push rax
        push rcx
        push rbx
        NEXT

defcode "2DROP", TWODROP
        pop rax
        pop rax
        NEXT

defcode "2DUP", TWODUP
        mov rax, [rsp]
        mov rbx, [rsp+8]
        push rbx
        push rax
        NEXT

defcode "2SWAP", TWOSWAP
        pop rax
        pop rbx
        pop rcx
        pop rdx
        push rbx
        push rax
        push rdx
        push rcx
        NEXT

defcode "?DUP", QDUP
        mov rax, [rsp]
        test rax, rax
        jz .next
        push rax
.next   NEXT

defcode "1+", INCR
        inc qword [rsp]
        NEXT

defcode "1-", DECR
        dec qword [rsp]
        NEXT

defcode "8+", INCR8
        add qword [rsp], 8
        NEXT

defcode "8-", DECR8
        sub qword [rsp], 8
        NEXT

defcode "+", ADD
        pop rax
        add [rsp], rax
        NEXT

defcode "-", SUB
        pop rax
        sub [rsp], rax
        NEXT

defcode "*", MUL
        pop rax
        pop rbx
        imul rax, rbx
        push rax
        NEXT

defcode "/MOD", DIVMOD
        xor rdx, rdx
        pop rbx
        pop rax
        idiv rbx
        push rdx
        push rax
        NEXT

;;;; Comparison Words

%macro defcmp 3
        defcode %1, %2
                pop rax
                pop rbx
                cmp rbx, rax
                set%+3 al
                movzx rax, al
                push rax
                NEXT
%endmacro

defcmp "=",  EQU, e
defcmp "<>", NEQ, ne
defcmp "<",  LT,  l
defcmp ">",  GT,  g
defcmp "<=", LE,  le
defcmp ">=", GE,  ge

%macro deftest 3
        defcode %1, %2
                pop rax
                test rax, rax
                set%+3 al
                movzx rax, al
                push rax
                NEXT
%endmacro

deftest "0=",  ZEQU,  z
deftest "0<>", ZNEQU, nz
deftest "0<",  ZLT,   l
deftest "0>",  ZGT,   g
deftest "0<=", ZLE,   le
deftest "0>=", ZGE,   ge

defcode "AND", AND
        pop rax
        and [rsp], rax
        NEXT

defcode "OR", OR
        pop rax
        or [rsp], rax
        NEXT

defcode "XOR", XOR
        pop rax
        xor [rsp], rax
        NEXT

defcode "INVERT", INVERT
        not qword [rsp]
        NEXT

;;;; Exiting a Word

defcode "EXIT", EXIT
        POPRSP rsi
        NEXT

;; Literal

defcode "LIT", LIT
        lodsq
        push rax
        NEXT

;;;; MEMORY

defcode "!", STORE
        pop rbx
        pop rax
        mov [rbx], rax
        NEXT

defcode "@", FETCH
        pop rbx
        mov rax, [rbx]
        push rax
        NEXT

defcode "+!", ADDSTORE
        pop rbx
        pop rax
        add [rbx], rax
        NEXT

defcode "-!", SUBSTORE
        pop rbx
        pop rax
        sub [rbx], rax
        NEXT

defcode "C!", STOREBYTE
        pop rbx
        pop rax
        mov [rbx], al
        NEXT

defcode "C@", FETCHBYTE
        pop rbx
        xor rax, rax
        mov al, [rbx]
        NEXT

defcode "C@C!", CCOPY
        mov rbx, [rsp+8]
        mov al, [rbx]
        pop rdi
        stosb
        push rdi
        inc qword [rsp+8]
        NEXT

defcode "CMOVE", CMOVE
        mov rdx, rsi
        pop rcx
        pop rdi
        pop rsi
        rep movsb
        mov rsi, rdx
        NEXT

;;;; BUILT-IN VARIABLE

%macro defvar 2-4 0, 0
        defcode %1, %2, %4
                push var_%2
                NEXT

        ;; data storage
        section .data
        align 8, db 0
        var_%2:
                dq %3
%endmacro

defvar "STATE", STATE
defvar "HERE", HERE
defvar "LATEST", LATEST, name_SYSCALL0
defvar "S0", S0
defvar "BASE", BASE, 10

%macro defconst 3-4 0
        defcode %1, %2, %4
                push %3
                NEXT
%endmacro

defconst "VERSION", VERSION, JOMBLO_VERSION
defconst "R0", R0, return_stack_top
defconst "DOCOL", __DOCOL, DOCOL

defconst "F_IMMED",   __F_IMMED,   F_IMMED
defconst "F_HIDDEN",  __F_HIDDEN,  F_HIDDEN
defconst "F_LENMASK", __F_LENMASK, F_LENMASK

%macro defsys 2
        %defstr name SYS_%1
        defconst name, SYS_%1, __NR_%2
%endmacro

defsys EXIT,  exit
defsys OPEN,  open
defsys CLOSE, close
defsys READ,  read
defsys WRITE, write
defsys CREAT, creat
defsys BRK,   brk

%macro defo 2
        %defstr name O_%1
        defconst name, __O_%1, %2
%endmacro

defo RDONLY,      0o
defo WRONLY,      1o
defo RDWR,        2o
defo CREAT,     100o
defo EXCL,      200o
defo TRUNC,    1000o
defo APPEND,   2000o
defo NONBLOCK, 4000o

;;;; RETURN STACK

defcode ">R", TOR
        pop rax
        PUSHRSP rax
        NEXT

defcode "R>", FROMR
        POPRSP rax
        push rax
        NEXT

defcode "RSP@", RSPFETCH
        push rbp
        NEXT

defcode "RSP!", RSPSTORE
        pop rbp
        NEXT

defcode "RDROP", RDROP
        add rbp, 8
        NEXT


;;;; PARAMETER (DATA) STACK

defcode "DSP@", DSPFETCH
        mov rax, rsp
        push rax
        NEXT

defcode "DSP!", DSPSTORE
        pop rsp
        NEXT

;;;; INPUT OUTPUT

defcode "KEY", KEY
        call _KEY
        push rax
        NEXT
_KEY:
        mov rbx, [currkey]
        cmp rbx, [bufftop]
        jge .full
        xor rax, rax
        mov al, [rbx]
        inc rbx
        mov [currkey], rbx
        ret

.full:
        xor rdi, rdi          ; stdin (0)
        push rsi              ; save rsi temporarily
        mov rsi, buffer       ; pointer to the buffer
        mov [currkey], rsi
        mov rdx, BUFFER_SIZE  ; how many bytes to read max
        mov rax, __NR_read    ; read(0, buffer, size)
        syscall
        test rax, rax
        jbe .eof
        add rsi, rax
        mov [bufftop], rsi
        pop rsi               ; restore it
        jmp _KEY

.eof:
        xor rdi, rdi
        mov rax, __NR_exit
        syscall

section .data
align 8, db 0
currkey:
        dq buffer
bufftop:
        dq buffer

defcode "EMIT", EMIT
        pop rax
        call _EMIT
        NEXT
_EMIT:
        mov rdi, 1             ; stdout (1)
        mov [emit_scratch], al ; save the byte to scratch buffer
        push rsi               ; save rsi temporarily
        mov rsi, emit_scratch
        mov rdx, 1             ; how many bytes to write
        mov rax, __NR_write    ; write(1, scratch, 1)
        syscall
        pop rsi                ; restore it
        ret

section .data
emit_scratch: db 0

defcode "WORD", WORD
        call _WORD
        push rdi
        push rcx
        NEXT

_WORD:
.ws:
        call _KEY
        cmp al, '\'
        je .comment
        cmp al, ' '
        jbe .ws

        mov rdi, word_buffer
.word:
        stosb
        call _KEY
        cmp al, ' '
        ja .word

        sub rdi, word_buffer
        mov rcx, rdi
        mov rdi, word_buffer
        ret

.comment:
        call _KEY
        cmp al, 0x0A
        jne .comment
        jmp .ws

section .data
word_buffer: times 32 db 0

defcode "NUMBER", NUMBER
        pop rcx
        pop rdi
        call _NUMBER
        push rax
        push rcx
        NEXT

_NUMBER:
        xor rax, rax
        xor rbx, rbx

        test rcx, rcx ; trying to parse zero-length string is an error, but will return 0.
        jz .ret

        mov rdx, [var_BASE] ; get BASE (in dl)
        mov bl, [rdi]       ; bl = first character in string
        inc rdi
        push rax            ; push 0 on stack
        cmp bl, '-'         ; negative number?
        jnz .convert
        pop rax
        push rbx            ; push <> 0 on stack, indicating negative
        dec rcx
        jnz .loop
        pop rbx
        mov rcx, 1
        ret

        ; Loop reading digits.
.loop:
        imul rax, rdx       ; rax *= BASE
        mov bl, [rdi]       ; bl = next character in string
        inc rdi

.convert:
        sub bl, '0'         ; < '0'?
        jb .finish
        cmp bl, 10          ; <= '9'?
        jb .numeric
        sub bl, 17          ; < 'A'? (17 is 'A'-'0')
        jb .finish
        add bl, 10

.numeric:
        cmp bl, dl          ; >= BASE?
        jge .finish

        ; OK, so add it to rax and loop
        add rax, rbx
        dec rcx
        jnz .loop

        ; Negate the result if the first character was '-' (saved on the stack)
.finish:
        pop rbx
        test rbx, rbx
        jz .ret
        neg rax

.ret:
        ret


;;;; Dictionary Looks Ups

defcode "FIND", FIND
        pop rcx
        pop rdi
        call _FIND
        push rax
        NEXT

_FIND:
        push rsi              ; save rsi so that we can use it in string comparison

        ; now we start searching the dictionary for this word
        mov rdx, [var_LATEST] ; LATEST points to name header of the latest word in the dictionary
.loop:
        test rdx, rdx         ; NULL pointer?
        je .notfound

        ; Compare the length expected and the length of the word.
        ; Note that if the F_HIDDEN flag is set on the word, then by a bit of trickery
        ; this won't pick the word (the length will appear to be wrong).
        xor rax,rax
        mov al, [rdx+8]              ; al = flags+length field
        and al, F_HIDDEN | F_LENMASK ; al = name length
        cmp al, cl                   ; Length is the same?
        jne .next

        ; Compare the strings in detail.
        push rcx         ; Save the length
        push rdi         ; Save the address (repe cmpsb will move this pointer)
        lea rsi, [rdx+9] ; Dictionary string we are checking against.
        repe cmpsb       ; Compare the strings.
        pop rdi
        pop rcx
        jne .next        ; Not the same.

        ; The strings are the same - return the header pointer in rax
        pop rsi
        mov rax, rdx
        ret

.next:
        mov rdx, [rdx] ; Move back through the link field to the previous word
        jmp .loop      ; .. and loop.

.notfound:
        pop rsi
        xor rax,rax ; Return zero to indicate not found.
        ret

defcode ">CFA", TCFA
        pop rdi
        call _TCFA
        push rdi
        NEXT

_TCFA:
        xor rax, rax
        add rdi, 8        ; skip link pointer
        mov al, [rdi]     ; load flags+len into al
        inc rdi           ; skip flags+len byte
        and al, F_LENMASK ; just the length, not the flags
        add rdi, rax      ; skip the name
        add rdi, 0b111    ; the codeword is 8-byte aligned
        and rdi, ~0b111
        ret

defword ">DFA", TDFA
        dq TCFA
        dq INCR8
        dq EXIT

;;;; Compiling

defcode "CREATE", CREATE
        ; Get the name length and address.
        pop rcx                 ; rcx = length
        pop rbx                 ; rbx = address of name

        ; Link pointer.
        mov rdi, [var_HERE]     ; rdi is the address of the header
        mov rax, [var_LATEST]   ; Get link pointer
        stosq                   ; and store it in the header.

        ; Length byte and the word itself.
        mov al, cl              ; Get the length.
        stosb                   ; Store the length/flags byte.
        push rsi
        mov rsi, rbx            ; rsi = word
        rep movsb               ; Copy the word
        pop rsi
        add rdi, 0b111          ; Align to next 8 byte boundary.
        and rdi, ~0b111

        ; Update LATEST and HERE.
        mov rax, [var_HERE]
        mov [var_LATEST], rax
        mov [var_HERE], rdi
        NEXT

defcode ",", COMMA
        pop rax
        call _COMMA
        NEXT

_COMMA:
        mov rdi, [var_HERE]    ; HERE
        stosq                   ; Store it.
        mov [var_HERE], rdi     ; Update HERE (incremented)
        ret

defcode "[", LBRAC, F_IMMED
        xor rax, rax
        mov [var_STATE], rax
        NEXT

defcode "]", RBRAC
        mov qword [var_STATE], 1
        NEXT

defword ":", COLON
        dq $WORD
        dq CREATE
        dq LIT, DOCOL, COMMA
        dq LATEST, FETCH, HIDDEN
        dq RBRAC
        dq EXIT

defword ";", SEMICOLON, F_IMMED
        dq LIT, EXIT, COMMA
        dq LATEST, FETCH, HIDDEN
        dq LBRAC
        dq EXIT


defcode "IMMEDIATE", IMMEDATE, F_IMMED
        mov rdi, [var_LATEST]
        add rdi, 8
        xor byte [rdi], F_IMMED
        NEXT

defcode "HIDDEN", HIDDEN
        pop rdi
        add rdi, 8
        xor byte [rdi], F_HIDDEN
        NEXT

defword "HIDE", HIDE
        dq $WORD
        dq FIND
        dq HIDDEN
        dq EXIT

defcode "'", TICK
        lodsq
        push rax
        NEXT

;;;; Branching

defcode "BRANCH", BRANCH
        add rsi, [rsi]
        NEXT

defcode "0BRANCH", ZBRANCH
        pop rax
        test rax, rax
        jz code_BRANCH
        lodsq
        NEXT

;;;; Literal String

defcode "LITSTRING", LITSTRING
        lodsq
        push rsi
        push rax
        add rsi, rax
        add rsi, 0b111
        and rsi, ~0b111
        NEXT

defcode "TELL", TELL
        mov rcx, rsi        ; save temporarily
        mov rdi, 1          ; 1st param = stdout(1)
        pop rdx             ; 3nd param = length of string
        pop rsi             ; 2nd param = the string
        mov rax, __NR_write
        push rcx            ; save previous value of rsi in the stack
        syscall
        pop rsi             ; restore rsi
        NEXT

;;;; Part of Testing

defword "FORTYTWO", FORTYTWO
	dq LIT
	dq 42
	dq EXIT

;;;; Quit and Interpret

defword "QUIT", QUIT
        dq R0, RSPSTORE
        dq INTERPRET
        dq BRANCH, -16

defcode "INTERPRET", INTERPRET
        call _WORD                  ; return rcx = length, rdi = pointer to word

        ; Is it in the dictionary?
        xor rax, rax
        mov [interpret_is_lit], rax ; Not a literal number (not yet anyway ...)
        call _FIND                  ; Return rax = pointer to header or 0 if not found
        test rax, rax               ; Found?
        jz .number

        ; In the dictionary. Is it an IMMEDIATE codeword?
        mov rdi, rax                ; rdi = dictionary entry
        mov al, [rdi+8]             ; Get name+flags.
        push ax                     ; Just save it for now
        call _TCFA                  ; Convert dictionary entry in rdi to codeword pointer
        pop ax
        and al, F_IMMED             ; Is IMMED flag set?
        mov rax, rdi
        jnz .exec                   ; If IMMED, jump straight to executing

        jmp .main

        ; Not in the dictionary (not a word) so assume it's a literal number.
.number:
        inc qword [interpret_is_lit]
        call _NUMBER            ; Returns the parsed number in rax, rcx > 0 if error
        test rcx, rcx
        jnz .numerror
        mov rbx, rax
        mov rax, LIT            ; The word is LIT

        ; Are we compiling or executing?
.main:
        mov rdx, [var_STATE]
        test rdx, rdx
        jz .exec                        ; Jump if executing.

        ; Compiling - just append the word to the current dictionary definition.
        call _COMMA
        mov rcx, [interpret_is_lit] ; Was it a literal?
        test rcx, rcx
        jz .next
        mov rax, rbx                    ; Yes, so LIT is followed by a number.
        call _COMMA
.next:
        NEXT

        ; Executing - run it!
.exec:
        mov rcx, [interpret_is_lit] ; Literal?
        test rcx, rcx               ; Literal?
        jnz .litexec

        ; Not a literal, execute it now.  This never returns, but the codeword will
        ; eventually call NEXT which will reenter the loop in QUIT.
        jmp [rax]

        ; Executing a literal, which means push it on the stack.
.litexec:
        push rbx
        NEXT

        ; Parse error (not a known word or a number in the current BASE).
.numerror:
        ; Print an error message followed by up to 40 characters of context.
        push rsi

        mov rdi, 2              ; 1st param: stderr(2)
        mov rsi, errmsg         ; 2nd param: error message
        mov rdx, errmsglen      ; 3rd param: length of string
        mov rax, __NR_write     ; write syscall
        syscall

        mov rsi, [currkey]      ; the error occurred just before currkey position
        mov rdx, rsi
        sub rdx, buffer         ; rdx = currkey - buffer (length in buffer before currkey)
        cmp rdx, 40             ; if > 40, then print only 40 characters
        jle .le
        mov rdx, 40
.le:
        sub rsi, rdx            ; rcx = start of area to print, rdx = length
        mov rax, __NR_write     ; write syscall
        syscall

        mov rsi, errmsgnl       ; newline
        mov rdx, 1
        mov rax, __NR_write     ; write syscall
        syscall
        pop rsi

        NEXT

section .rodata
errmsg: db "PARSE ERROR: "
errmsglen: equ $ - errmsg
errmsgnl: db 0x0A

section .data                   ; NB: easier to fit in the .data section
align 8
interpret_is_lit:
        dq 0                    ; Flag used to record if reading a literal

;;;; Odds and Ends

defcode "CHAR", CHAR
        call _WORD              ; Returns rcx = length, rdi = pointer to word.
        xor rax, rax
        mov al, [rdi]           ; Get the first character of the word.
        push rax                ; Push it onto the stack.
        NEXT

defcode "EXECUTE", EXECUTE
        pop rax                 ; Get xt into rax
        jmp [rax]               ; and jump to it.
                                ; After xt runs its NEXT will continue executing the current word.

defcode "SYSCALL3", SYSCALL3
        mov rcx, rsi            ; Save rsi
        pop rax                 ; System call number (see <asm/unistd.h>)
        pop rdi                 ; First parameter.
        pop rsi                 ; Second parameter
        pop rdx                 ; Third parameter
        push rcx                ; Save previous value of rsi on stack
        syscall
        pop rsi                 ; restore
        push rax                ; Result (negative for -errno)
        NEXT

defcode "SYSCALL2", SYSCALL2
        mov rcx, rsi
        pop rax                 ; System call number (see <asm/unistd.h>)
        pop rdi                 ; First parameter.
        pop rsi                 ; Second parameter
        push rcx
        syscall
        pop rsi
        push rax                ; Result (negative for -errno)
        NEXT

defcode "SYSCALL1", SYSCALL1
        pop rax                 ; System call number (see <asm/unistd.h>)
        pop rdi                 ; First parameter.
        syscall
        push rax                ; Result (negative for -errno)
        NEXT

defcode "SYSCALL0", SYSCALL0
        pop rax                 ; System call number (see <asm/unistd.h>)
        syscall
        push rax                ; Result (negative for -errno)
        NEXT


;;;; Data Segment
%define INITIAL_DATA_SEGMENT_SIZE 65536

section .text
set_up_data_segment:
        xor rdi, rdi
        mov rax, __NR_brk ; brk(0)
        syscall
        mov [var_HERE], rax
        add rax, INITIAL_DATA_SEGMENT_SIZE
        mov rdi, rax
        mov rax, __NR_brk
        syscall
        ret

;;;; buffers allocation

section .bss
align 4096
return_stack:
        resb RETURN_STACK_SIZE
return_stack_top:

align 4096
buffer:
        resb BUFFER_SIZE
