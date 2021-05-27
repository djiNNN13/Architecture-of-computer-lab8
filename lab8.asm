IDEAL              ; Директива - тип Асемблера tasm
MODEL SMALL     ; Директива - тип моделі пам'яті
STACK 256   ; Директива - розмір стеку
 
;------------------------ІІ.МАКРОСИ---------------------------------------------------
; Макрос для ініціалізації
MACRO MInit
    mov ax, @data  ; ax <- @data
    mov ds, ax	; ds <- ax	
    mov es, ax	 ; es <- ax	
ENDM MInit        
;------------------ІІІ.ПОЧАТОК СЕГМЕНТУ ДАНИХ-----------------------------------------
DATASEG

namemsg db "---------Team 2---------",0
menu1 db "Calculate",0
menu2 db "Play",0
menu3 db "Creators",0
menu4 db "Exit",0
helpmsg db "Use arrows for navigation and press Enter",0
aboutmsg db 'Kashtalyan, Kobylynskyi, Hodnev',0
expmsg db "(-7+3)*2/4+2=",0

a1 EQU -7
a2 EQU 3
a3 EQU 2
a4 EQU 4
a5 EQU 2

MSECONDS EQU 2000
FREQ EQU 600
PORT_B EQU 61H
COMMAND_REG EQU 43H ; Адреса командного регістру
CHANNEL_2 EQU 42H ; Адреса каналу 2

; Структура для пунктів меню
Struc Item
	location  dw ?
	next dw ?
	previous dw ?
	function dw ?
Ends Item

; Ініціалізація структур
about Item <0,0,0>
count Item <1338,0,0>
sound Item <0,0,0>
exitI Item <0,0,0>

exCode db 0

;------------------IV.ПОЧАТОК СЕГМЕНТУ КОДУ-------------------------------------------
CODESEG
Start:
MInit       ; Виклик макросу ініціалізації
mov ax, 03
int 10h		; Очищення екрану
mov ax, 2103h       
mov bl, 00
int 10h		; Вимикаємо блимання
mov ax, 0B800h    
mov es, ax	

xor di, di
mov dh, 0
mov dl, 032h 	; Колір фону
mov cx, 2000 	; Заповнюємо весь відеобуфер
background:
	call VideoDraw
	loop background
	
mov di, 856   		; Зміщення блоку меню
mov dh, 0 		
mov dl, 094h 	; Колір меню
xor ax, ax
mov al, 112		; Відступ
	
push di
mov cx, 10 				; Довжина меню
menu_print:
	push cx
	mov cx, 24 	; Ширина меню
	menu_print_inn:
		call VideoDraw
		loop menu_print_inn
	pop cx
	add di, ax
	loop menu_print
pop di
mov dl, 077h
	
mov si, offset namemsg  ; Виводимо текст 
call PrintMenu            

add di, 112	; Йдемо на наступний рядок
	
; Ініціалізуємо змінні структур
mov ax, offset count  
mov [exitI.next], ax
mov [sound.previous], ax
mov ax, offset sound  
mov [count.next], ax
mov [about.previous], ax

mov ax, offset about  
mov [sound.next], ax	
mov [exitI.previous], ax
mov ax, offset exitI  
mov [about.next], ax
mov [count.previous], ax

mov ax, [count.location] 
add ax, 160
mov [sound.location], ax
add ax, 160
mov [about.location], ax	
add ax, 160
mov [exitI.location], ax

mov ax, offset Calculate
mov [count.function], ax	
mov ax, offset Beep
mov [sound.function], ax
mov ax, offset Authors
mov [about.function], ax
mov ax, offset exit
mov [exitI.function], ax

; Вивід пунктів меню
mov bx, offset count
mov di, [bx]
mov si, offset menu1   
call PrintMenu      
mov bx, [bx+2]         
mov di, [bx]        
mov si, offset menu2    
call PrintMenu        
mov bx, [bx+2]       
mov di, [bx]	
mov si, offset menu3     
call PrintMenu      
mov bx, [bx+2]       
mov di, [bx]	
mov si, offset menu4     
call PrintMenu      

mov bx, offset count
call Select      	; Виділяємо перший елемент
	 
mov di, 2760	;Зміщення тексту
mov si, offset helpmsg	
call PrintText        

; Обробка та зчитування символів
Main:
	call ReadC     
    cmp ah, 50h     ;50h = ↑
	je Up			
	cmp ah, 48h     ;48h = ↓
	je Down	
    cmp ah, 1ch		;1ch = Enter
	je EnterF					
	jmp Main   ; Якщо символ неправильний, продовжуємо зчитувати

;-------------FUNCTION UP----------------
Up:
	call Unselect     
	mov bx, [bx+2]    
	call Select       
	jmp Main     

;-------------FUNCTION DOWN----------------
Down:
	call Unselect     
	mov bx, [bx+4]    
	call Select       
	jmp Main     

;-------------FUNCTION ENTER----------------
EnterF:
	call ClearBack    
	mov di, 3040   
	mov dl, 07Ch      
	mov ax,[bx+6]     
	jmp ax          ; Переходимо до функції обробки

; Обробка виразу
Calculate:
	mov si, offset expmsg
	call PrintText	; Виводимо вираз
	mov di, 3040          
	add di, 160
	call PrintText	; Виводимо змінні
	push bx
	xor dx, dx		; dx <- 0
	mov ax, a1		; ax <- a1
	mov bx, a2		; bx <- a2
	add ax, bx		; ax <- a1-a2


	mov bx, a3 		; bx <- a3
	imul bx 		; ax <- ax*bx
	
	mov bx, a4		; bx <- a4
	idiv bx			; ax <- ax*bx
	
	mov bx, a5		; bx <-a5
	add ax, bx		; ax <- ax+bx
	mov dl, 03Fh
	mov di, 2746
	add di, 320
	call PrintResult	; Виводимо результат
	pop bx
	jmp Main		; Продовжуємо зчитувати

Beep:
	call SoundF
	jmp Main  
	
Authors:
	mov si, offset aboutmsg
	call PrintText	; Відображаємо результати
	jmp Main   

Exit:
     mov ax, 0700h	; Очистка екрану
     mov bh, 03h	; Параметр для кольору символів,
     mov cx, 0h    
     mov dx, 184fh  
     int 10h        
     mov ah, 04Ch ; Номер вектора переривання DOS для виходу
     int 21h

;------------PROCEDURE VIDEO DRAW------------------
PROC VideoDraw
	mov [es:di], dh
	inc di
	mov [es:di], dl
	inc di
	ret
ENDP

;------------PROCEDURE SELECT------------------
PROC Select
	mov di, [bx]
	inc di
	mov dl, 03Fh ; Колір фону вибраного пункту меню
; Обмеженння виділеного рядка
	mov cx, 24
	sub cx, 2
	SelectPoint:
		mov [es:di], dl ; Змінюємо колір
		add di, 2 ; Переходимо до іншого кольору
		loop SelectPoint
	ret
ENDP
;------------PROCEDURE CLEARBACK------------------
PROC ClearBack
	mov di, 3040
	mov dh, 0 ; Пустий символ
	mov dl, 03Fh ; Колір фону виводу тексту
	mov cx, 480
	marker_to_clear:
		call VideoDraw
		loop marker_to_clear
	ret
ENDP

;------------PROCEDURE UNSELECT------------------
PROC Unselect
	mov di, [bx]
	inc di
	mov dl, 01Fh ; Колір фону 
	mov cx, 24
	sub cx, 2
	UnselectPoint:
		mov [es:di], dl ; Змінюємо колір
		add di, 2 ; Переходимо до наступного кольору
		loop UnselectPoint
	ret
ENDP


;------------PROCEDURE PRINT MENU------------------
PROC PrintMenu
	mov dl, 01Fh
	read_item:
		mov dh, [si] ; Читаємо символ з SI
		cmp dh, 0 ; Рядки закуінчуються 0, якщо бачимо 0 - закінчуємо роботу
		jne draw_item
		ret
		
	draw_item:
		call VideoDraw 
		inc si
		jmp read_item		
	ret
ENDP
;------------PROCEDURE PRINT TEXT------------------
PROC PrintText
	mov dl, 03Fh
	read_str:
		mov dh, [si] ; Читаємо символ з SI
		cmp dh, 0 ; Рядки закуінчуються 0, якщо бачимо 0 - закінчуємо роботу
		jne draw_str
		ret
		
	draw_str:
		call VideoDraw 
		inc si
		jmp read_str		
	ret
ENDP

;------------PROCEDURE PRINT RESULT-----------------
PROC PrintResult
	cmp ax, 0
	jge positive ; Якщо число більше 0, не відображаємо "-" 
	mov dh, '-'
	call VideoDraw ; Виводимо мінус
	neg ax
	positive:    ; Виводимо число
		add ax, 30h
		mov dh, al
		call VideoDraw
		ret
ENDP

;------------PROCEDURE READ------------------
PROC ReadC
	mov ah, 0
	mov di, 3040
	int 16h
	ret	
ENDP
;------------PROCEDURE SOUND------------------
PROC SoundF
 ;--- дозвіл каналу 2 встановлення порту В мікросхеми 8255
 in al,PORT_B ;Читання
 OR al,3 ;Встановлення двох молодших бітів
 out PORT_B,al ;пересилка байта в порт B мікросхеми 8255

 ;--- встановлення регістрів порту вводу-виводу
 mov AL,10110110B ;біти для каналу 2
 out COMMAND_REG,al ;байт в порт командний регістр

 ;--- встановлення лічильника
 mov ax,1190000/FREQ ;Встановлення частоти звуку
 out CHANNEL_2,AL ;відправка AL
 mov al,ah ;відправка старшого байту в AL
 out CHANNEL_2,al ;відправка старшого байту

 call Timer
 ;--- виключення звуку
 in al,PORT_B ;отримуємо байт з порту В
 and al,11111100B ;скидання двох молодших бітів
 out PORT_B,al ;пересилка байтів в зворотному напрямку
 ret
 ENDP SoundF

;-----------PROCEDURE TIMER-------------------
PROC Timer
push cx
mov cx, MSECONDS
loop1:                 
  push cx               
  mov  cx,  MSECONDS
  loop2:
     loop loop2
  pop  cx
  loop loop1
pop cx
ret
ENDP Timer
END Start