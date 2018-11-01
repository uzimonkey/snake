.MODEL LARGE, STDCALL
.386

INCLUDE SCREEN.INC

DATA		SEGMENT PUBLIC 'DATA'
scr_chars	DW	(SCR_BACKGND SHL 12) OR (SCR_BACKGND SHL 8) OR SCR_PIX_BLANK		; 00  00
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_UPPER		; 01  02
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_UPPER		; 02  04
		DW	0									; 03  06
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_LOWER		; 10  08
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_FULL		; 11  0A
		DW	(SCR_FORE2 SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_LOWER		; 12  0C
		DW	0									; 13  0E
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_LOWER		; 20  10
		DW	(SCR_FORE2 SHL 12) OR (SCR_FORE1 SHL 8) OR SCR_PIX_UPPER		; 21  12
		DW	(SCR_BACKGND SHL 12) OR (SCR_FORE2 SHL 8) OR SCR_PIX_FULL		; 22  14
		DW	0									; 23  16
		DW	0									; 30  18
		DW	0									; 31  1A
		DW	0									; 32  1B
		DW	0									; 33  2C

old_mode	DB	0
DATA		ENDS


CODE		SEGMENT PUBLIC 'CODE'
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
@@:		call	scr_clear

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
		; Clear the screen
		xor	di, di
		mov	ax, scr_chars[0]
		mov	cx, SCR_WIDTH * SCR_HEIGHT
		rep	stosw

		ret
scr_clear	ENDP


scr_vsync	PROC NEAR
		mov	dx, 003DAH

@@:		in	al, dx
		and	al, 008H
		jnz	@b

@@:		in	al, dx
		and	al, 008H
		jz	@b
		ret
scr_vsync	ENDP


scr_set		PROC NEAR, x:BYTE, y:BYTE, color:BYTE
		pusha

		movzx	cx, x			; cx = x
		movzx	dx, y			; dx = y

		; si = ((y/2 + SCR_WIDTH) + x) * 2
		mov	si, dx
		shr	si, 1
		imul	si, SCR_WIDTH
		add	si, cx
		shl	si, 1
		mov	ax, es:[si]		; read screen char

		bt	dx, 0			; odd row?
		mov	dh, 11111100B		; dh = inverse mask
		mov	dl, color		; dl = color
		jnc	@f
		rol	dh, 2
		rol	dl, 2

@@:		mov	cx, 16			; max 16 screen chars
		xor	bx, bx			; bx = character offset
@@:		cmp	ax, scr_chars[bx]	; is this it?
		je	@f
		add	bx, 2
		loop	@b
		xor	bx, bx			; it was invalid, call it empty

@@:		shr	bx, 1			; convert from offset back to packed pixel
		and	bl, dh			; clear the bits
		or	bl, dl			; set new bits
		shl	bx, 1			; bx *= 2, we're addressing words
		mov	ax, scr_chars[bx]	; get new screen char
		mov	es:[si], ax		; display it

		popa
		ret
scr_set		ENDP


scr_line	PROC NEAR, x1:BYTE, y1:BYTE, x2:BYTE, y2:BYTE, color:BYTE
		ret
scr_line	ENDP


CODE		ENDS

END
