.MODEL SMALL
.386

; Constants
VID_MEM		EQU	0B800H
SCREEN_WIDTH	EQU	80
SCREEN_HEIGHT	EQU	25

EMPTY_PIXEL	EQU	00000H
SNAKE_PIXEL	EQU	07020H

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
DATA	SEGMENT
old_mode		DB	0
speed		DW	STARTING_SPEED
snake_offset	DW	((SCREEN_HEIGHT/2) * SCREEN_WIDTH + SCREEN_WIDTH/2) * 2
snake_move	DW	2
DATA	ENDS

; Code
CODE	SEGMENT	PUBLIC 'CODE'
	ASSUME	cs:CODE, ds:DATA, ss:STACK
main	PROC	FAR
	mov	ax, DATA
	mov	ds, ax
	mov	ax, VID_MEM	; Text-mode memory
	mov	es, ax

	mov	ah, 0FH		; Save the video mode
	int	10H
	mov	old_mode, al


	mov	ax, 00003H	; Set video mode
	int	10H
	call	clear_screen

	mov	ah, 02H		; Hide the cursor
	mov	bh, 0
	mov	dh, SCREEN_WIDTH+1
	mov	dl, SCREEN_HEIGHT+1
	int	10h

@@loop:	mov	cx, ds:[speed]
@@:	call	vsync
	loop	@b

	; Move the character
	mov	bx, snake_offset
	add	bx, snake_move
	mov	snake_offset, bx

	; Display the character
	mov	WORD PTR es:[bx], SNAKE_PIXEL

	call	input
	jmp	@@loop
main	ENDP


quit	PROC	NEAR
	mov	ah, 0		; Set old video mode
	mov	al, old_mode
	int	10H


	mov ah, 04CH		; Exit
	int 21h
quit	ENDP


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
	mov	snake_move, DELTA_RIGHT
	jmp	input

@@:	cmp	ah, KEY_LEFT
	jnz	@f
	mov	snake_move, DELTA_LEFT
	jmp	input

@@:	cmp	ah, KEY_UP
	jnz	@f
	mov	snake_move, DELTA_UP
	jmp	input

@@:	cmp	ah, KEY_DOWN
	jnz	input
	mov	snake_move, DELTA_DOWN

	jmp	input
input	ENDP

clear_screen	PROC	NEAR
	cld
	xor	di, di
	mov	ax, EMPTY_PIXEL
	mov	cx, SCREEN_WIDTH * SCREEN_HEIGHT
	rep	stosw
	ret
clear_screen	ENDP

vsync		PROC	NEAR
	mov	dx, 003DAH
 
@@:	in	al, dx		; Wait until out of vertical sync
	and	al, 008H
	jnz	@b

@@:	in	al, dx		; Wait until vertical sync starts
	and	al, 008H
	jz	@b

	ret
vsync	ENDP
CODE	ENDS

STACK	SEGMENT	PARA STACK 'STACK'
	DW	64 DUP (?)
STACK	ENDS

END	main