.MODEL SMALL, STDCALL
.386

SCR_INTERNAL	EQU	1
INCLUDE SCREEN.INC

DATA	SEGMENT
scr_back	DB	(SCR_WIDTH * SCR_HEIGHT) / 2 DUP(0)
scr_chars:	
	DW	(SCR_BACKGND SHL 6) OR (SCR_BACKGND SHL 4) OR SCR_PIX_BLANK		; 00
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE1 SHL 4) OR SCR_PIX_LOWER		; 01
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE2 SHL 4) OR SCR_PIX_LOWER		; 02
	DW	0							; 03
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE1 SHL 4) OR SCR_PIX_UPPER		; 10
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE1 SHL 4) OR SCR_PIX_FULL		; 11
	DW	(SCR_FORE2 SHL 6) OR (SCR_FORE1 SHL 4) OR SCR_PIX_UPPER		; 12
	DW	0							; 13
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE2 SHL 4) OR SCR_PIX_UPPER		; 20
	DW	(SCR_FORE1 SHL 6) OR (SCR_FORE2 SHL 4) OR SCR_PIX_UPPER		; 21
	DW	(SCR_BACKGND SHL 6) OR (SCR_FORE2 SHL 4) OR SCR_PIX_FULL		; 22
	DW	0							; 23
	DW	0							; 30
	DW	0							; 31
	DW	0							; 32
	DW	0							; 33

old_mode	DB	0
DATA	ENDS


CODE	SEGMENT
	ASSUME cs:CODE, ds:DATA
scr_init	PROC NEAR
	mov	ax, SCR_VID_MEM
	mov	es, ax

	; Save old mode
	mov	ah, 00FH
	int	10H
	mov	old_mode, al
	cmp	al, 03h
	je	@f

	; Set mode and clear screen
	mov	ax, 00003H
	int	10h
@@:	call	scr_clear

	; Hide the cursor
	mov	ah, 002H
	mov	bh, 0
	mov	dh, SCR_WIDTH+1
	mov	dl, SCR_HEIGHT+1
	int	10H
	
	ret
scr_init	ENDP


scr_quit	PROC NEAR
	mov	ah, 0
	mov	al, old_mode
	int	10H
	ret
scr_quit	ENDP


scr_clear	PROC NEAR
	
	; Clear the back buffer
	cld
	mov	di, OFFSET scr_back
	xor	ax, ax
	mov	cx, (SCR_WIDTH * SCR_HEIGHT) / 4	; Doing this by words, so divide by 2 again
	rep	stosw

	; Clear the screen
	xor	di, di
	mov	ax, SCR_PIX_BLANK
	mov	cx, SCR_WIDTH * SCR_HEIGHT
	rep	stosw

	ret
scr_clear	ENDP


scr_vsync	PROC NEAR
	mov	dx, 003DAH

@@:	in	al, dx
	and	al, 008H
	jnz	@b

@@:	in	al, dx
	and	al, 008H
	jz	@b
	ret
scr_vsync	ENDP

; scr_set	PROC NEAR, x:BYTE, y:BYTE
; 	ret
; scr_set	ENDP
CODE	ENDS

END
