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

;; see defining constant section
%include "unistd_64.inc"


;; MACRO DEFINITION
;; ----------------

;; The version of this program, not to be mistaken as how many years the
;; author has been single. Please increment this number each time one year passed.
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
	mov rbp, %1
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
	mov [var_S0], rsp         ; Save the initial data stack pointer in FORTH variable S0
	mov rbp, return_stack_top ; Initialize the return stack
	; call set_up_data_segment
	mov rsi, cold_start
	NEXT
	mov rax, __NR_exit        ; exit (for now)
	mov rdi, 0
	syscall

section .rodata
cold_start:
	; QUIT
	db 0

section .rodata

;; Various flags for the dictionary word header
%define F_IMMED 0x80
%define F_HIDDEN 0x20
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
		db name_len + %4
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
	global %2
	%2:
		dq code_%2

	;; native code
	section .text
	align 16
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
.next	NEXT

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
		set%-3 al
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
		set%-3 al
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
	mov rbx, [rsp+4]
	mov al, [rbx]
	pop rdi
	stosb
	push rdi
	inc qword [rsp+4]
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
		push qword [var_%2]
		NEXT

	;; data storage
	section .data
	align 8, db 0
	var_%2:
		dq %3
%endmacro

defvar "STATE", STATE
defvar "HERE", HERE
; defvar "LATEST", LATEST, name_SYSCALL0 ; uncomment after defining SYSCALL0
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

;; syscall number
;;
;;    sed 's/#/%/;s_/\*_;_;s_ \*/__' /usr/include/x86_64-linux-gnu/asm/unistd_64.h > unistd_64.inc
;;
;; see %include "unistd_64.inc" above

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

defo RDONLY, 0
defo WRONLY, 1
defo RDWR,   2

defo CREAT,    0o0100
defo EXCL,     0o0200
defo TRUNC,    0o1000
defo APPEND,   0o2000
defo NONBLOCK, 0o4000
;; TODO: Investigate this magic number

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
	add rbp, 4
	NEXT


;;;; PARAMETER (DATA) STACK

defcode "DSP@", DSPFETCH
	mov rax, rsp
	push rax
	NEXT

defcode "DSP!", DSPSTORE
	pop rsp
	NEXT

;;;; Data Segment
%define INITIAL_DATA_SEGMENT_SIZE 65535

section .text
set_up_data_segment:
	xor rdi, rdi
	mov rax, __NR_brk ; brk(0)
	syscall
	mov var_HERE, rax
	add rax, INITIAL_DATA_SEGMENT_SIZE
	mov rbx, rax
	mov rax, __NR_brk
	syscall
	ret

;;;; buffers allocation

%define RETURN_STACK_SIZE 8192
%define BUFFER_SIZE 4096

section .bss
align 4096
return_stack:
	resb RETURN_STACK_SIZE
return_stack_top:

align 4096
buffer:
	resb BUFFER_SIZE
