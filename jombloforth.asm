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
	; cld                      ; Clear direction flag
	; mov var_S0,rsp           ; Save the initial data stack pointer in FORTH variable S0
	; mov rbp,return_stack_top ; Initialize the return stack
	; call set_up_data_segmt
	; mov rsi,cold_start
	; NEXT
	mov rax, 60                ; exit (for now)
	mov rdi, 0
	syscall

section .rodata
cold_start:
	; QUIT
	db 0

section .rodata

;; Various flags for the dictionary word header
F_IMMED: db 0x80
F_HIDDEN: db 0x20
F_LENMASK: db 0x1f

;; Holds previously defined word
;; Starts as null/zero
%define link 0

;; Macro for defining forth word
;;
;;     defword name, label, flag
;;
%macro defword 3
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

;; If flag not supplied, it defaults to 0
%macro defword 2
	defword %1, %2, 0
%endmacro

;; Macro for defining native word
;;
;;     defcode name, label, flag
;;
%macro defcode 3
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

;; If flags not supplied, it default to 0
%macro defcode 2
       defcode %1, %2, 0
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
