section .rodata
hwstr: db 'WORK', 0dh,0ah
hwsz: equ $-hwstr
ten: dq 10.0
decimal: dq 0.1
outfloat: db '%.5f', 0xa, 0x0

section .bss
buf: resb 256
buflen: equ $-buf
result: resq 1 ; храним конечный результат и выкидываем мусор из стека с пмощью этой переменной, так как st0-st7 - ограничен
help: resq 1 ; необходимая переменная для преобразовaния строки в число 



section .text
finit
extern printf
global main

decode:
        push rsi
        push rdx
        push rcx
        xor rcx, rcx
        xor rdx, rdx
        xor rcx, rcx
        jmp .cycle

.cycle:                   ; check byte
        mov cl, [rsi]
	cmp cl, 'p'
	je .load_pi
        cmp cl, '0'
	jb .action
	cmp cl, '9'
	ja .function
        jmp .begin_number

.begin_number:                 ; получаем 1 цифру старшего разряда и кладем ее на стек
	sub cl, '0'
	mov BYTE [help], cl
	fild WORD [help]
	inc rsi
	mov cl, [rsi]
	jmp .number

.action:                        ; проверяем символы на различные действия   
	cmp cl, '+'
	je .sum
	cmp cl, '-'
	je .dif
	cmp cl, '*'
	je .mul
	cmp cl, '/'
	je .div
	jmp .exit

.sum:				; описываем работу действий, считая, что числа лежат на стеке
	fadd st1, st0
	jmp .end_action

.dif:
	fsub st1, st0
	;fxch st0, st1
	jmp .end_action

.mul:
	fmul st1, st0
	jmp .end_action

.div:
	fdiv st1, st0
	jmp .end_action

.end_action:			; чтобы на стеке не было мусора, чистим его, а так как после любого действия стоит пробел, делаем [rsi+2]
	fstp QWORD [result]
	inc rsi
	inc rsi
	jmp .cycle

.load_pi:                        ; загружаем pi и возвращаемся в цикл
	inc rsi
	mov cl, [rsi]
	cmp cl, 'i'
	jne .exit
	fldpi
	inc rsi
	inc rsi
	jmp .cycle
		
.function:                  ; проверяем посимвольно на различные функцииб lnx, lgx, sin, cos, tg, ctg, ^, sqrt
	cmp cl, 's'
	je .sin_sqr
	cmp cl, 'c'
	je .cos_ctg
	cmp cl, 't'
	je .tan
	cmp cl, 'l'
	je .logarifm
	cmp cl, '^'
	je .stepen
	jmp .exit

.stepen:                     ; 2^х == 2 ^х, при записи в калькулятор, x - Натуральное 0-9
	inc rsi
	mov cl, [rsi]
	sub cl, '0'
	fst
	jmp .loop_stepen

.loop_stepen:
	cmp cl, 1
	je .end_stepen
	fmul st1, st0
	dec cl	
	jmp .loop_stepen

.end_stepen:
	fstp QWORD [result]
	inc rsi
	inc rsi
	jmp .cycle

.sin_sqr:
	inc rsi
	mov cl, [rsi]
	cmp cl, 'i'
	jne .root
	inc rsi
	mov cl, [rsi]
	cmp cl, 'n'
	jne .exit
	fsin
	inc rsi
	inc rsi
	jmp .cycle

.root:
	cmp cl, 'q'
	jne .exit
	inc rsi
	mov cl, [rsi]
	cmp cl, 'r'
	jne .exit
	fsqrt
	inc rsi
	inc rsi
	jmp .cycle

.cos_ctg:
	inc rsi
	mov cl, [rsi]
	cmp cl, 'o'
	je .cos
	cmp cl, 't'
	je .ctg
	jmp .exit

.cos:
	inc rsi
	mov cl, [rsi]
	cmp cl, 's'
	jne .exit
	fcos
	inc rsi
	inc rsi
	jmp .cycle

.tan:
	inc rsi
	mov cl, [rsi]
	cmp cl, 'g'
	jne .exit
	FPTAN
	fstp QWORD [result]
	inc rsi
	inc rsi
	jmp .cycle
	
.ctg:
	inc rsi
	mov cl, [rsi]
	cmp cl, 'g'
	jne .exit
	FPTAN
	fdiv st0, st1
	fxch
	fstp QWORD [result]
	inc rsi
	inc rsi
	jmp .cycle	

.logarifm:
	inc rsi
	mov cl, [rsi]
	cmp cl, 'g'
	je .log_10
	cmp cl, 'n'
	je .log_nat
	jmp .exit

.log_10:
	fld1
	fxch
	fyl2x
	fxch st0 ,st1
	fstp QWORD [result]
	fldl2t
	fdiv st1, st0
	fstp QWORD [result]
        inc rsi
        inc rsi
        jmp .cycle

.log_nat:
	fld1
        fxch
        fyl2x
        fxch st0 ,st1
        fstp QWORD [result]
        fldl2e
        fdiv st1, st0
        fstp QWORD [result]
        inc rsi
        inc rsi
        jmp .cycle


.number:                       ; обрабатываем число, таким образом, чтобы число лежало на вершине и не было какого-либо мусора
	cmp cl, '.'
	je .float_check		; если число не целое, то отправляем формировать дробную часть
	cmp cl, ' '
	je .space
	sub cl, '0'
	fld QWORD [ten]        ; ten - разряд
	fmul st0, st1
	mov BYTE [help], cl
	fild WORD [help]
	fadd st0, st1
	inc rsi
	mov cl, [rsi]
	fxch st0, st2
	fstp QWORD [result]
	fstp QWORD [result]
	jmp .number

.float_check:
	xor ah, ah   ; ah, bh регистры, необходимые для сохранения разрядности числа
	jmp .float

.float:
	inc rsi
	mov cl, [rsi]
	cmp cl, ' '
	je .space
	sub cl, '0'
	mov BYTE [help], cl
	fild WORD [help]
	inc ah
	mov bh, ah
	jmp .body_one

.body_one:
	cmp bh, 0
	je .body
	fld QWORD [decimal]
	fmul st1, st0
	fstp QWORD [result]
	dec bh
	jmp .body_one

.body:	
	fadd st1, st0
	fstp QWORD [result]
	jmp .float

.space:
	inc rsi
	jmp .cycle

.exit:
        fstp QWORD [result]
        pop rcx
        pop rdx
        pop rsi
        ret


read_buf:                 ; считываем строку
        push rbx 
        push rcx
        push rdx
        mov rax, 0x3
        mov rbx, 0x0
        mov rcx, buf
        mov rdx, 256
        int 80h
        pop rdx
        pop rcx
        pop rbx
        ret

println:
        mov rax, 0x4 ; write(fd, buf, size)
        mov rbx, 0x1 ; stdout
        mov rcx, hwstr ; buffer
        mov rdx, hwsz ;
        int 80h
        ret

main:
        push rbp
        mov rbp, rsp
        call read_buf
        mov BYTE [buf+rax], 0
        mov rsi, buf
        call decode
        movsd xmm0, QWORD [result]
        mov eax, 0x1
        mov rdi, outfloat
        call printf
	call println
	jmp .exit

.exit:
        xor eax, eax
        mov rax, 0x1
        xor rbx, rbx
        int 80h


