; Various sub-routines that will be useful to the boot loader code	

; Output Carriage-Return/Line-Feed (CRLF) sequence to screen using BIOS

Console_Write_ASCII:
    mov        ah, 0Eh
    mov        al, byte [si]			; take the byte from the location of the pointer
    cmp        al, 32					; compare the ascii value so it's not junk
    jbe        Console_Write_Underscore	; write an underscore if junk
    int        10h						
    ret

Console_Write_Underscore:
    mov     ah, 0Eh
    mov     al, 5Fh						; Output underscore
    int     10h
    ret
	
Console_Write_Space:
    mov        ah, 0Eh
    mov        al, 20h					; Output space
    int        10h
    ret

Console_Write_CRLF:
	mov 	ah, 0Eh						; Output CR
    mov 	al, 0Dh
    int 	10h
    mov 	al, 0Ah						; Output LF
    int 	10h
    ret

; Write to the console using BIOS.
; 
; Input: SI points to a null-terminated string

Console_Write_16:
	mov 	ah, 0Eh						; BIOS call to output value in AL to screen

Console_Write_16_Repeat:
	lodsb								; Load byte at SI into AL and increment SI
    test 	al, al						; If the byte is 0, we are done
	je 		Console_Write_16_Done
	int 	10h							; Output character to screen
	jmp 	Console_Write_16_Repeat

Console_Write_16_Done:
    ret

; Write string to the console using BIOS followed by CRLF
; 
; Input: SI points to a null-terminated string

Console_WriteLine_16:
	call 	Console_Write_16
	call 	Console_Write_CRLF
	ret
	
;move 8 bit value to bx before calling
Console_Write_Hex_8:
    mov     cx, 2						; create loop for two outputs
    rol     bx, 8						; rotate the 2 bytes so they are read the correct way
	call	Hex_Loop					; call the hex loop to output to screen
	ret
	
;move 16 bit value to bx before calling
Console_Write_Hex_16: 
	mov		cx, 4						; create loop for four outputs
	
Hex_Loop:
	rol		bx, 4						; each 4 bits is a hex value
	mov		si, bx						
	and		si, 000Fh 
	mov		al, byte [si + HexChars] 	; use si as an index for looking up the chars
	mov		ah, 0Eh						; output to screen
	int		10h							; shift the mask
	loop	Hex_Loop
	ret
	
Console_Write_Int:
	mov		si, IntBuffer + 4
	mov		ax, bx
	
GetDigit:
	xor		dx, dx
	mov		cx, 10
	div		cx
	add		dl, 48
	mov		[si], dl				; dl to point to position of si
	dec		si						; move si back to point back down the number
	cmp		ax, 0
	jne		GetDigit
	inc 	si						; increment si to point back to the beginning
	call	Console_Write_16
	ret
	
IntBuffer	db '     ', 0

HexChars	db '0123456789ABCDEF'
