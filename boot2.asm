; Second stage of the boot loader

BITS 16

ORG 9000h
	jmp 	Second_Stage

%include "functions_16.asm"
%include "bpb.asm"						; The BIOS Parameter Block (i.e. information about the disk format)
%include "floppy16.asm"					; Routines to access the floppy disk drive

;	Start of the second stage of the boot loader
	
Second_Stage:
	mov		[boot_device], dl			; Boot device number is passed in from first stage in DL. Save it to pass to kernel later.
	mov 	si, second_stage_msg		; Output our greeting message
    call 	Console_WriteLine_16
		
Prompt_User_Start_Sector:	
	mov		bx, 1						; bx used as flag set to 1 for first question
	mov		si, enter_start_msg			; prepare the message
	call	Console_Write_16			; print the enter number message
	mov		cx, 0						; set register to store the input to zero
	jmp		Get_Input					; jmp to get input
	
Prompt_User_Amount_Sector:
	mov		bx, 0						; bx used as flag set to 0 for second question
	mov		si, enter_amount_msg		; prepare the message
	call	Console_Write_16			; print the enter number message
	mov		cx, 0						; set register to store the input to zero
	
Get_Input:								; get input will eventually store the user's inputed number into cx
	mov		ah, 00h						; get the character the input and store in al
	int		16h
	
Check_Input:
	cmp		al, 0Dh						; check for the enter key/carriage return which will stop the input
	je		Input_Return
	cmp		al, '0'						; check our input is above zero
	jb		Get_Input
	cmp		al, '9'						; check our input is below nine
	ja		Get_Input
	mov		ah, 0Eh						; print the input to the screen
	int		10h
	
Convert_Digit:
	push	ax							; push ax to not ruin the input
	mov		ax, cx						
	push	cx							; push cx to not ruin the final register
	mov		cx, 10						; multiply cx by 10
	mul		cx							; first input will result in zero for cx
	pop		cx
	mov		cx, ax						; move the result we want from multiplication to cx
	pop		ax							; restore the input register
	sub		al, 30h						; convert al register from the ascii value
	mov		ah, 0						; add al to the cx register, so we must clear ah to only add the part we want
	add		cx, ax						
	jmp		Get_Input					; go back and get the other next input

Input_Return:							; by this point, the user's input number will be in cx
	call	Console_Write_CRLF			; Once input is complete, go to the next line ready to print further
	push	cx							; push the user's input to the stack so we can retrieve it later

Setup_Sector_Read:						
	cmp		bx, 0						; compare the question flag (first or second question?)
	jg		Prompt_User_Amount_Sector	; go to second question if not done
	pop		cx					
	mov		dx, cx						; store the most recent answer in dx while we retireve previous answer
	pop		cx							; pop cx the second time to get previous answer
	mov		ax, cx						; move user input start sector to ax
	mov		cx, dx						; move user input amount of sectors to cx
	
	push	cx							; push cx to avoid any changes from reading
    mov     bx, buffer_start			; set bx to our buffer					
    call    ReadSectors
    mov     si, buffer_start            ; initialize our pointer to the start
	pop		cx
	
	add		cx, cx						; read 2x16 lines foreach sector, so we must double the user input to use it as counter
									
Sector_Write_16:
	push	cx							; push cx to preserve the amount of times to read the sectors (from user input)
    mov     cx, 16						; setup loop so it runs through 16 lines (with each starting a new line)
	
Sector_WriteLine:
    push    cx							; push cx (2 of 3) to preserve counter
	
Sector_Write_Offset:
    mov     dx, si						; move current position into dx
    sub     dx, buffer_start            ; get the offset into dx
    push    si							; preserve the pointer to the offset 
    mov     bx, dx                		; move dx into bx for printing out
    push    si							; push the si pointer to not get changed by printing
    push    cx							; preserve cx from output manipulation by pushing
    call    Console_Write_Hex_16
	call	Console_Write_Space
	pop		cx							
	pop     si
	push 	cx							; push cx (3 of 3) to preserve counter
    mov     cx, 16                		; setup loop so it runs through 16 hex pairs (with spaces inbetween)
	
Sector_Write_Hex_8:
    mov     bx, [si]            		; take from the pointer location
    push    cx							; preserve cx from output manipulation by pushing
    push    si							; push the pointer to not get changed by printing
    call    Console_Write_Hex_8
	call    Console_Write_Space
    pop     si
    pop     cx							; pop cx (3 of 3) so the loop can decrement it
    inc     si							; increment the pointer along the buffer
    loop    Sector_Write_Hex_8			; loop until all 16 hex pairs have been outputed
    pop     cx							
    pop     si							; return pointer to pointing at offset from previous push
	mov     cx, 16						; setup loop so it runs through 16 ascii chars
	
Sector_Write_ASCII:
    push    si							; preserve the pointer before outputting ascii
    call    Console_Write_ASCII
    pop     si							; pop the pointer
    inc     si							; increment the pointer along the buffer (this time we will not reset it back)
    loop    Sector_Write_ASCII			; loop until all 16 characters have been outputed
    call    Console_Write_CRLF			; call for the next line
    pop     cx							; pop cx (2 of 3) so the loop can decrement it
    loop    Sector_WriteLine			; loop until all 16 Lines have been outputed
	
Handle_Output_Sections:
	pop		cx							; pop cx (1 of 3) for the sector segment
	dec		cx
	cmp		cx, 0						; have we printed enough lines the sector(s) asked?
	jg 		Wait_Continue_Press
	
Re_Prompt:
	call	Console_Write_CRLF			; Finished! The sector has been fully read and printed from user input!
	jmp		Prompt_User_Start_Sector	; Re-prompt the user for another sector to read and display							
	
Wait_Continue_Press:	
	push	cx							; preserve the counter for sector segment
	push	si							; preserve the pointer to the current position
	mov     si, continue_msg			; prepare the message prompt
	call    Console_WriteLine_16		; output the prompt for pressing a key to continue
	mov     ah, 00h						; wait for any key press
	int     16h                         
	pop 	si							; return pointer to its position ready to write the next 16 lines
	pop		cx
	call	Sector_Write_16
	
Safety_Halt:							; code should never reach here (this is for safety)
	hlt
			
enter_start_msg		db 'Enter the starting sector number: ', 0
enter_amount_msg 	db 'Enter the amount of sectors to read: ', 0
continue_msg		db 'Press any key to continue...', 0
second_stage_msg  	db 'Second stage of boot loader running', 0
boot_device		  	db  0
buffer_start		db 0D000h


       
