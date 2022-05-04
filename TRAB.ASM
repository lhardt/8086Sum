.model small

CR		equ		13
LF		equ		10


.stack
.data
	text_intro db "Digite o nome do arquivo (max:12)",CR,LF,">>> ",0
	text_file  db CR,LF,"Arquivo Escolhido: ", 0
	filename db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	values	dw 0,0,0,0
.code
.startup
	lea 	bx , text_intro
	call 	print_string

	mov		bx, 12
	call 	read_filename

	lea 	bx , text_file
	call 	print_string

	lea		bx , filename
	call	print_string

.exit

;================================
; READ_FILENAME (bx=maxchars, name->data.filename)
;================================
read_filename proc near

read_start:

	push	ax
	push	dx

	mov		dx, 0

read_loop:

	lea		di, filename
	add		di, dx

	mov		ah,1
	int		21H
	cmp		al,CR
	jne		read_naoacabou

read_acabou:
	mov		byte ptr[di], 0

	jmp read_fim

read_naoacabou:
	cmp 	bx, 0
	je		read_acabou

	mov		byte ptr[di], al
	inc 	dx
	dec 	bx
	jmp 	read_loop

read_fim:

	pop		dx
	pop		ax
	ret
read_filename endp


;================================
; PRINT_STRING (bx=string)
;================================
print_string 	proc near
print_start:
	mov		dl, [bx]
	cmp		dl, 0
	je print_end

	push	bx
	mov		ah,2
	int 	21H
	pop		bx

	inc		bx
	jmp		print_start


print_end:
	ret
print_string endp

;================================
end
