.model small

CR		equ		13
LF		equ		10


.stack
.data
	text_intro 		db "Digite o nome do arquivo (max:12)",CR,LF,">>> ",0
	text_file  		db CR,LF,"Arquivo Escolhido: ", 0
	text_openerr	db CR,LF,"Erro ao tentar abrir o arquivo!",CR,LF,0
	text_opensuc	db CR,LF,"Sucesso ao abrir o arquivo!",CR,LF,0
	values			dw 0,0,0,0

	file_handle		dw 0
	filename 		db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

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

	;;------------------------------

	call 	open_file

	lea		di, file_handle
	cmp		[di],0

	jz		did_not_open


	lea		bx , text_opensuc
	call	print_string
	jmp 	end_main

did_not_open:
	lea		bx , text_openerr
	call	print_string

end_main:
.exit

;================================
; OPEN_FILE	(file_handle=0 if failure)
;================================
open_file proc near
	push 	ax
	push	dx

	mov		ah, 3DH
	mov		al, 0
	lea		dx,filename

	int 	21H ;; retorna carry flag 0 se ok

	jnc		open_success

	lea		di, file_handle
	mov		[di], 0
	jmp		open_end

open_success:
	lea		di, file_handle
	mov		[di], ax

	; fallthrough
open_end:

	pop		dx
	pop		ax
	ret
open_file endp

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
