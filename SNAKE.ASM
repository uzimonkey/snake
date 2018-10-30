; ex: set tabstop=10
.MODEL LARGE, STDCALL
.386

INCLUDE SCREEN.INC

; Constants
STARTING_SPEED	EQU	10

DELTA_RIGHT	EQU	2
DELTA_LEFT	EQU	-2
DELTA_UP		EQU	-SCREEN_WIDTH * 2
DELTA_DOWN	EQU	SCREEN_WIDTH * 2

KEY_ESC		EQU	001H
KEY_RIGHT		EQU	04DH
KEY_LEFT		EQU	04BH
KEY_UP		EQU	048H
KEY_DOWN		EQU	050H


; Variables
DATA	SEGMENT PUBLIC 'DATA'
speed		DW	STARTING_SPEED

snake_x		DW	SCR_WIDTH/2
snake_y		DW	SCR_HEIGHT/2
snake_dx		DW	1
snake_dy		DW	0
DATA	ENDS


; Code
CODE	SEGMENT	PUBLIC 'CODE'
	ASSUME	cs:CODE, ds:DATA, ss:STACK
main	PROC	FAR
	mov	ax, DATA
	mov	ds, ax
	call	scr_init

@@loop:	mov	cx, ds:[speed]
@@:	call	scr_vsync
	loop	@b

	; Move the character
	mov	ax, snake_x
	add	ax, snake_dx
	mov	snake_x, ax
	mov	ax, snake_y
	add	ax, snake_dy
	mov	snake_y, ax

	; Display the character
	; INVOKE	set_pixel, snake_x, snake_y

	call	input
	jmp	@@loop
main	ENDP


; Quit to DOS
quit	PROC	NEAR
	call	scr_quit
	mov	ah, 04CH		; Exit
	int	21H
quit	ENDP


; Handle input
input	PROC	NEAR
	mov	ah, 001H		; Check for key
	int	16H
	jnz	@f		; Done if there are no keys in buffer
	ret

@@:	mov	ah, 000H		; Remove from buffer
	int	16H

	cmp	ah, KEY_ESC
	jnz	@f
	jmp	quit

@@:	cmp	ah, KEY_RIGHT
	jnz	@f
	mov	snake_dx, 1
	mov	snake_dy, 0
	jmp	input

@@:	cmp	ah, KEY_LEFT
	jnz	@f
	mov	snake_dx, -1
	mov	snake_dy, 0
	jmp	input

@@:	cmp	ah, KEY_UP
	jnz	@f
	mov	snake_dy, -1
	mov	snake_dx, 0
	jmp	input

@@:	cmp	ah, KEY_DOWN
	jnz	input
	mov	snake_dy, 1
	mov	snake_dx, 0

	jmp	input
input	ENDP
CODE	ENDS

STACK	SEGMENT	PARA STACK 'STACK'
	DW	64 DUP (?)
STACK	ENDS

END	main
