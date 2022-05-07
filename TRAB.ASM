.model small

CR		equ		13
LF		equ		10


.stack
.data
	text_intro 		db "Digite o nome do arquivo (max:12)",CR,LF,">>> ",0
	text_file  		db CR,LF,"Arquivo Escolhido: ", 0
	text_openerr	db CR,LF,"Erro ao abrir arquivos!",CR,LF,0
	text_inerr		db CR,LF,"Erro ao abrir o arquivo de entrada!",CR,LF,0
	text_opensuc	db CR,LF,"Sucesso ao abrir os arquivos!",CR,LF,0
	text_outerr		db CR,LF,"Erro ao abrir o arquivo de saida!",CR,LF,0
	text_digiterr	db CR,LF,"Digito Invalido!",CR,LF,0
	text_parseerr	db CR,LF,"Erro ao ler o arquivo ",CR,LF,0
	text_space		db " ",0
	text_charreport db CR,LF," Novo Byte: ",0
	text_outfileis  db CR,LF,"O arquivo de saida eh: ",0
	text_eof		db CR,LF,"EOF!",CR,LF,0
	text_outext		db ".res",0

	values			db 0,0,0,0
	values_i		dw 0

	file_handle		dw 0
	filename 		db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	out_filename	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	out_filename_t	db "a.out",0
	out_filehandle	dw 0

	file_buffer		db 0,0,0

.code
.startup

	;;------------------------------
	;; Getting the filename.
	;;------------------------------
	lea 	bx , text_intro
	call 	print_string

	mov		bx, 12
	call 	read_filename

	lea 	bx , text_file
	call 	print_string

	lea		bx , filename
	call	print_string

	;;------------------------------
	;; Handling the output file
	;;------------------------------
	call	make_outfile_name

	lea		bx, text_outfileis
	call	print_string

	lea		bx, out_filename
	call	print_string

	;;------------------------------
	;; Opening the files and checking
	;;------------------------------
	call 	open_file

	cmp		file_handle,0
	jz		main_open_fail

	call	open_outfile
	cmp		out_filehandle,0
	jz		main_open_fail

	jmp		main_open_success

main_open_fail:
	lea		bx , text_openerr
	call	print_string
	jmp 	end_main


	;;------------------------------
	;; Parsing the file.
	;;------------------------------
main_open_success:

	mov		ah,40h
	mov		bx,out_filehandle
	mov		cx,20
	mov		dx, offset text_opensuc
	int 	21h

;	lea		bx, text_opensuc
;	call	fprint_string

;	lea		bx , text_opensuc
;	call	print_string

;	call 	parse_file

	;;------------------------------
	;; Printing the results.
	;;------------------------------



end_main:
	lea bx,values

	mov bx, 0
	mov cx, 0

	mov al, byte ptr [values + bx]
	call print_number
	call print_space


.exit

;================================
; PARSE_FILE  (no params, everything is global)
;================================
parse_file proc near
	mov	bx,file_handle		;; - parameter
	cmp bx,0
	jz	parsefile_end

parsefile_readnext:
	mov ah, 3fH				;; "READ" interrupt
	mov	bx,file_handle		;; - parameter
	mov	cx,1				;; - parameter: numbytes to read
	lea	dx, file_buffer		;; - parameter: DS:DX is the buffer

	int 21h

	jc	parsefile_error		;; error condition is carry flag.
	cmp ax,0				;; number of bytes actually read.
	jz	parsefile_eof

	lea	bx, file_buffer
	mov	al, [bx]
	call sumchar

	;; Printing the char for test purpouses.
		lea	bx,text_charreport
		call print_string

		lea	bx, file_buffer
		mov	al, [bx]
		call print_number

	jmp parsefile_readnext

parsefile_error:
	lea 	bx, text_parseerr
	call 	print_string
	call	print_number	;; err code in ax, print_number prints al
	jmp		parsefile_end

parsefile_eof:

	lea		bx, text_eof
	call	print_string

parsefile_end:

	ret
parse_file endp
;================================
; SUMCHAR	 (al=char)
; checks if the char does contribute in the sum
; sums at one of the four values accordingly.
; prints it at the file too.
;================================
sumchar proc near

	cmp al,7FH ; último caractere de controle é 0x1F, e o primeiro visível é 0x20
	jnc sumchar_invalid


	lea bx,values
	add bx,values_i
	add byte ptr [bx], al

	call write_outfile

	add values_i,1
	cmp values_i,3 ; A ordem é 0,1,2,3,0,1,2,3 ... Reseta do 3 pro 0.
	jnz sumchar_nao_overflow
	mov	values_i,0
sumchar_nao_overflow:

sumchar_invalid:
sumchar_end:
	ret

sumchar endp
;================================
; PRINT_SPACE (no param, no result. Just covenience)
;================================
print_space proc near
	push 	ax
	push 	bx
	push 	cx

	lea		bx,text_space
	call	print_string

	pop		cx
	pop		bx
	pop 	ax

	ret
print_space endp
;================================
; PRINT_NUMBER (number enters at AL)
;================================
;; prints in base 16, and with trailing zeroes.
print_number proc near
	push 	bx
	push	cx

	mov		bl, al

	mov		cl,4 ;; 8 bits, prints two 4-bit values
	shr		al,cl
	call	print_digit
	shl		al,cl
	sub		bl,al	;; (XXXX) - (XX00) = (00XX)
	mov		al,bl
	call	print_digit

	pop		cx
	pop 	bx

	ret
print_number endp

;================================
; FPRINT_NUMBER (number enters at AL)
;================================
;; prints in base 16, in the outfile, and with trailing zeroes.
fprint_number proc near
	push 	bx
	push	cx

	mov		bl, al

	mov		cl,4 ;; 8 bits, prints two 4-bit values
	shr		al,cl
	call	fprint_digit
	shl		al,cl
	sub		bl,al	;; (XXXX) - (XX00) = (00XX)
	mov		al,bl
	call	fprint_digit

	pop		cx
	pop 	bx

	ret
fprint_number endp

;================================
; PRINT_DIGIT (n, 0 <= n < 16, at AL)
;================================
;; prints a single 'digit' in base 16.
print_digit proc near
	push bx
	push dx

	cmp 	al, 16
	jnc print_digit_too_large

	cmp 	al,9
	jnc 	print_digit_letter

print_digit_number:
	mov 	dl, '0'
	jmp 	print_digit_print
print_digit_letter:
	mov 	dl, 'A'
	sub		dl, 10	;; já começa em 10,

print_digit_print:
	add 	dl, al
	mov 	ah, 02H
	int		21h

	jmp print_digit_end


print_digit_too_large:
	lea 	bx,text_digiterr
	call 	print_string

print_digit_end:
	pop 	dx
	pop 	bx
	ret
print_digit endp

;================================
; FPRINT_DIGIT (n, 0 <= n < 16, at AL)
;================================
;; prints a single 'digit' in base 16 at the outfile.
fprint_digit proc near
	push bx
	push dx

	cmp 	al, 16
	jnc fprint_digit_too_large

	cmp 	al,9
	jnc 	fprint_digit_letter

fprint_digit_number:
	mov 	dl, '0'
	jmp 	fprint_digit_print
fprint_digit_letter:
	mov 	dl, 'A'
	sub		dl, 10	;; já começa em 10,

fprint_digit_print:
	add 	al, dl ;; so AL is the character to print

	lea		di, file_buffer ;; we need to write using a buffer.
	mov		byte ptr [di], al ;; character in the buffer
	lea		dx, file_buffer ;; we need to write using a buffer.


	mov		cx, 1 			;; one byte to write.
	mov		bx, out_filehandle

	mov 	ah, 40h
	int		21h

	jmp fprint_digit_end


fprint_digit_too_large:
	lea 	bx,text_digiterr
	call 	print_string

fprint_digit_end:
	pop 	dx
	pop 	bx
	ret
fprint_digit endp



;================================
; MAKE_OUTFILE_NAME (fills out_filename by looking at filename)
;================================
make_outfile_name proc near
	lea di,out_filename
	lea si,filename

makename_next:
	cmp byte ptr [si],0
	jz  makename_extension

	cmp byte ptr [si],'.'
	jz	makename_extension

	mov al, [si]
	mov [di], al
	inc di
	inc si

	jmp makename_next

makename_extension:
	lea si, text_outext

makename_extloop:
	cmp byte ptr [si],0
	jz  makename_end
	mov al, [si]
	mov [di], al
	inc di
	inc si

	jmp makename_extloop

makename_end:
	ret
make_outfile_name endp
;================================
; OPEN_OUTFILE ()
;================================
open_outfile proc near
	mov		ah, 3CH
	mov		cl, 0 	;; escrita
	lea		dx,out_filename

	int		21H

	jnc		openo_success

	lea		di, out_filehandle
	mov		[di], 0

	lea  bx,text_outerr
	call print_string
	jmp		openo_end
openo_success:
	mov		out_filehandle, ax
openo_end:
	ret
open_outfile endp
;================================
; WRITE_OUTFILE (al=byte)
;================================
write_outfile proc near

	call fprint_number

	cmp values_i, 3
	jnz write_not_newline

	push ax

	mov al, CR
	call write_outfile
	mov al, LF
	call write_outfile

	pop ax


write_not_newline:

	ret
write_outfile endp

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
	lea  bx,text_inerr ;; string para teste.
	call print_string

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
; FPRINT_STRING (bx=string)
;================================
fprint_string 	proc near
fprint_start:

	mov		dl, [bx]
	cmp		dl, 0
	je fprint_end

	push	bx
	push	cx

		;mov		dx,bx ; dx must point to string
		lea		dx, text_openerr

		lea		bx,out_filehandle
		mov		cx,1  ; n_bytes to write


		mov		ah,40h
		int 	21H

	pop		cx
	pop		bx

	inc		bx
	jmp		fprint_start


fprint_end:
	ret
fprint_string endp

;================================


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
