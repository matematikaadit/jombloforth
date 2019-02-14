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
	lea rbp,[rbp-8]
	mov rbp,%1
%endmacro

%macro POPRSP 1
	mov %1,[rbp]
	lea rbp,[rbp+8]
%endmacro

;; First Non-Macro Word
section .text
DOCOL:
	PUSHRSP rsi
	add rax,8
	mov rsi,rax
	NEXT


global _start
_start:
	; cld			 ; Clear direction flag
	; mov var_S0,rsp		 ; Save the initial data stack pointer in FORTH variable S0
	; mov rbp,return_stack_top ; Initialize the return stack
	; call set_up_data_segmt
	; mov rsi,cold_start
	; NEXT
	mov rax,60 		 ; exit (for now)
	mov rdi,0
	syscall

section .rodata
cold_start:
	; QUIT
	db 0

section .rodata
F_IMMED: equ 0x80
F_HIDDEN: equ 0x20
F_LENMASK: equ 0x1f
%define link 0xFACEFEEDDEADBEEF
%define name(x) name_ %+ x

;; defword name, label, flags=0
%macro defword 2-3 0
;; linked list
section .rodata
align 8, db 0
global name_%2
name_%2:
	dq link
; %define link name(%2)
%strlen NAME_LEN %1
	db NAME_LEN | %3
	db %1
;; word definitions
align 8, db 0
global $%2
$%2:
	dq DOCOL

%endmacro

; defcode name, label, flags=0
%macro defcode 2-3 0
; linked list
section .rodata
align 8, db 0
global name_%2
name_%2:
	dq link
; %define link name(%2)
%strlen NAME_LEN %1
	db NAME_LEN | %3
	db %1
; word definition
align 8, db 0
global $%2
$%2:
 	dq code_%2

; the code
section .text

align 16
global code_%2
code_%2:

%endmacro

defcode "DROP",DROP
%define link name(DROP)
 	pop rax
 	NEXT

defcode "SWAP",SWAP
%define link name(SWAP)
	pop rax
	pop rbx
	push rax
	push rbx
	NEXT

defcode "DUP",DUP
%define link name(DUP)
	mov rax,[rsp]
	push rax
	NEXT
