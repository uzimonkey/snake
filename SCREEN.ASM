.MODEL LARGE, STDCALL
.386

INCLUDE SCREEN.INC

DATA	SEGMENT PUBLIC 'DATA'
scr_back	DB	(SCR_WIDTH * SCR_HEIGHT) / 2 DUP(0)
scr_chars DW	(SCR_BACKGND SHL 12) OR (SCR_BACKGND SHL 8) OR SCR_PIX_BLANK	; 00
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_LOWER		; 01
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_LOWER		; 02
	DW	0							; 03
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_UPPER		; 10
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_FULL		; 11
	DW	(SCR_FORE2 SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_UPPER		; 12
	DW	0							; 13
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_UPPER		; 20
	DW	(SCR_FORE1 SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_UPPER		; 21
	DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_FULL		; 22
	DW	0							; 23
	DW	0							; 30
	DW	0							; 31
	DW	0							; 32
	DW	0							; 33

old_mode	DB	0
DATA	ENDS


CODE	SEGMENT PUBLIC 'CODE'
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
	mov	cx, (SCR_WIDTH * SCR_HEIGHT) / 2	; Doing this by words, so divide by 2
	rep	stosw

	; Clear the screen
	xor	di, di
	mov	ax, scr_chars
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

scr_set	PROC NEAR, x:WORD, y:WORD
	mov	si, y		; y
	shr	si, 2		; / 4
	imul	si, SCR_WIDTH	; * width
	add	si, x		; + x
	xor	bx, bx		; bx = 0
	mov	bl, scr_back[si]	; si = back buffer offset

	mov	al, 00111111B	; al = inverse mask
	mov	ah, 01000000B	; ah = value
	mov	cl, 4		; cl = after shifter

	bt	y, 1		; if y&2
	jnc	@f
	mov	cl, 0		; already in lowest nibble
	ror	al, 4
	ror	ah, 4

@@:	bt	y, 0		; if y&1
	jnc	@f
	ror	al, 2		; we want lower 2 bits of nibble
	ror	ah, 2

@@:	and	bl, al		; clear nibble
	or	bl, ah		; set nibble
	mov	scr_back[si], bl	; store in back buffer

	shr	bl, cl		; shift nibble into least significant bits
	and	bl, 00FH		; get rid of most significant nibble
	shl	bl, 1		; multiply by 2, we're addressing words
	mov	ax, scr_chars[bx]	; get screen char

	mov	di, y
	shr	di, 1
	imul	di, SCR_WIDTH
	add	di, x
	shl	di, 1		; * 2
	mov	es:[di], ax	; display

	ret
scr_set	ENDP
CODE	ENDS

END
