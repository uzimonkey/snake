.MODEL LARGE, STDCALL
.386

INCLUDE SCREEN.INC

; Constants
STARTING_SPEED	EQU	5

DELTA_RIGHT	EQU	2
DELTA_LEFT	EQU	-2
DELTA_UP       	EQU	-SCREEN_WIDTH * 2
DELTA_DOWN	EQU	SCREEN_WIDTH * 2

KEY_ESC		EQU	001H
KEY_RIGHT	EQU	04DH
KEY_LEFT	EQU	04BH
KEY_UP		EQU	048H
KEY_DOWN	EQU	050H

LEVEL_SIZE	EQU	500		; Levels are 500 bytes


; Variables
DATA		SEGMENT PUBLIC 'DATA'
speed		DW	STARTING_SPEED

snake_x		DB	SCR_WIDTH/2
snake_y		DB	SCR_HEIGHT/2
snake_dx	DB	1
snake_dy	DB	0


; Levels
level1		DB	 0,  0,  0, 79
		DB	 0,  1,  0, 48
		DB	79, 01, 79, 48
		DB	 0, 49, 79, 49
level1_len	DW	$ - level1

levels		DW	level1, level1_len
num_levels	DW	($ - levels) / 4
DATA		ENDS

; Code
CODE		SEGMENT	PUBLIC 'CODE'
		ASSUME	cs:CODE, ds:DATA, ss:STACK

load_level	PROTO NEAR, level:WORD, level_len:WORD

main		PROC	FAR
		mov	ax, DATA
		mov	ds, ax
		call	scr_init

		; INVOKE	load_level, OFFSET level1

@@loop:		mov	cx, ds:[speed]
@@:		call	scr_vsync
		loop	@b

		; Move the character
		mov	al, snake_dx
		add	snake_x, al
		mov	al, snake_dy
		add	snake_y, al

		; Display the character
		INVOKE	scr_set, snake_x, snake_y, SCR_COLOR1

		call	input
		jmp	@@loop
main		ENDP


load_level	PROC NEAR level:WORD, level_len:WORD
		ret
load_level	ENDP


; Quit to DOS
quit		PROC NEAR
		call	scr_quit
		mov	ah, 04CH		; Exit
		int	21H
quit		ENDP


; Handle input
input		PROC	NEAR
		mov	ah, 001H		; Check for key
		int	16H
		jnz	@f			; Done if there are no keys in buffer
		ret

@@:		mov	ah, 000H		; Remove from buffer
		int	16H

		cmp	ah, KEY_ESC
		jnz	@f
		jmp	quit

@@:		cmp	ah, KEY_RIGHT
		jnz	@f
		mov	snake_dx, 1
		mov	snake_dy, 0
		jmp	input

@@:		cmp	ah, KEY_LEFT
		jnz	@f
		mov	snake_dx, -1
		mov	snake_dy, 0
		jmp	input

@@:		cmp	ah, KEY_UP
		jnz	@f
		mov	snake_dy, -1
		mov	snake_dx, 0
		jmp	input

@@:		cmp	ah, KEY_DOWN
		jnz	input
		mov	snake_dy, 1
		mov	snake_dx, 0

		jmp	input
input		ENDP
CODE		ENDS

STACK		SEGMENT	PARA STACK 'STACK'
		DW	64 DUP (?)
STACK		ENDS

END		main
