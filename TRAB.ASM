.model small

CR		equ		13
LF		equ		10


.stack
.data
	hello_world db "Hello, World!",CR,LF,0

.code
.startup
	lea 	bx , hello_world
	call 	print_string

.exit

;================================
; PRINT_STRING
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
