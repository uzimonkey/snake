; ex: set tabstop=10
.MODEL SMALL, STDCALL
.386

; Constants
VID_MEM		EQU	0B800H
SCREEN_WIDTH	EQU	80
SCREEN_HEIGHT	EQU	25 * 2

PIXEL_BACKGROUND	EQU	07000H
PIXEL_FOREGROUND	EQU	00100H
PIXEL_EMPTY	EQU	00020H OR PIXEL_BACKGROUND OR PIXEL_FOREGROUND
PIXEL_TOP		EQU	000DFH OR PIXEL_BACKGROUND OR PIXEL_FOREGROUND
PIXEL_BOTTOM	EQU	000DCH OR PIXEL_BACKGROUND OR PIXEL_FOREGROUND
PIXEL_FULL	EQU	000DBH OR PIXEL_BACKGROUND OR PIXEL_FOREGROUND

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
old_mode		DB	0	; VGA mode before set

speed		DW	STARTING_SPEED

snake_x		DW	SCREEN_WIDTH/2
snake_y		DW	SCREEN_HEIGHT/2
snake_dx		DW	2
snake_dy		DW	0

pixels		DW	PIXEL_TOP, PIXEL_BOTTOM
DATA	ENDS


; Prototypes
set_pixel		PROTO,	x:WORD, y:WORD


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
	mov	ax, snake_x
	add	ax, snake_dx
	mov	snake_x, ax
	mov	ax, snake_y
	add	ax, snake_dy
	mov	snake_y, ax

	; Display the character
	; mov	WORD PTR es:[bx], SNAKE_PIXEL
	INVOKE	set_pixel, snake_x, snake_y

	call	input
	jmp	@@loop
main	ENDP


; Quit to DOS
quit	PROC	NEAR
	mov	ah, 0		; Set old video mode
	mov	al, old_mode
	int	10H


	mov ah, 04CH		; Exit
	int 21h
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


; Clear the screen
clear_screen	PROC	NEAR
	cld
	xor	di, di
	mov	ax, PIXEL_EMPTY
	mov	cx, SCREEN_WIDTH * SCREEN_HEIGHT
	rep	stosw
	ret
clear_screen	ENDP


; Set a virtual pixel on the screen
set_pixel		PROC NEAR, x: WORD, y: WORD
        mov	di, y

        ; Select top or bottom pixel
        mov	bx, di
        and	bx, 001H
        shl	bx, 1
        mov	ax, pixels[bx]

        ; Calculate offset and draw pixel
        shr	di, 1		; Divide di by 2 to account for double rows
        imul	di, SCREEN_WIDTH	; Multiply by screen width
        add	di, x		; Add x
        shl	di, 1		; Multiply by 2 for attribute/char pairs
        mov	es:[di], ax

        ret
set_pixel		ENDP


; Wait for vsync
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
