.model small

CR		equ		13
LF		equ		10


.stack
.data
	hello_world db "Hello, World!",CR,LF,0
	str_result  db "Resultado: ", CR, LF, 0
	filename db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	values	dw 0,0,0,0
.code
.startup
	lea 	bx , hello_world
	call 	print_string

	call 	read_filename

	lea 	bx , str_result
	call 	print_string

	lea		bx , filename
	call	print_string

.exit

;================================
; READ_FILENAME (name->data.filename)
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
	mov		byte ptr[di], 0

	jmp read_fim

read_naoacabou:
	mov	byte ptr[di], al
	inc dx
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
