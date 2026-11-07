[org 0x100]
jmp start

; macro: x, y, w, h, colour
%macro RECT 5
    mov ax, %1
    mov bx, %2
    mov cx, %3
    mov dx, %4
    mov si, %5
    call fillrect
%endmacro

;macro: ek simple cloud (x, y, colour)
%macro CLOUD 3
    RECT %1+10, %2,    30, 6, %3     ; upar ka chhota hissa
    RECT %1,    %2+6,  50, 6, %3     ; beech ka chauda hissa
    RECT %1+5,  %2+12, 40, 4, %3     ; neeche ka patla hissa
%endmacro

<<<<<<< HEAD
start:
    mov ax, 0x0013
    int 0x10
    mov ax, 0xA000
    mov es, ax
    cld

    call setpal
    call drawsky

    ;clouds (x, y, colour)                
    CLOUD 20,  25, 8                 ; pink
    CLOUD 130, 45, 8                 ; pink
    CLOUD 230, 20, 9                 ; yellow
    CLOUD 60,  80, 9                 ; yellow

    call drawground

    mov ah, 0
    int 0x16

    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21


;palette
setpal:
    ;cloud colours: index 8 aur 9          
    mov dx, 0x3C8
    mov al, 8
    out dx, al
    mov dx, 0x3C9
    mov al, 63                       ; index 8: pink (63,30,40)
    out dx, al
    mov al, 30
    out dx, al
    mov al, 40
    out dx, al
    mov al, 63                       ; index 9: yellow (63,55,20)
    out dx, al
    mov al, 55
    out dx, al
    mov al, 20
    out dx, al

    ;sky: index 32 se, 172 colours
    mov dx, 0x3C8
    mov al, 32
    out dx, al
    mov si, seg1
    mov word [seglen], 172
    call grad

    ;land: index 204 se, 28 colours
    mov dx, 0x3C8
    mov al, 204
    out dx, al
    mov si, seg2
    mov word [seglen], 28
    call grad
    ret

grad:
    mov cx, [seglen]
    xor bx, bx
.n:
    push si
    mov di, 3
.c:
    xor ah, ah
    mov al, [si]
    mov bp, ax
    mov al, [si+3]
    xor ah, ah
    sub ax, bp
    imul bx
    idiv word [seglen]
    add ax, bp
    mov dx, 0x3C9
    out dx, al
    inc si
    dec di
    jnz .c
    pop si
    inc bx
    loop .n
    ret

drawsky:
    xor di, di
    mov al, 32
    mov bx, 172
.s:
    mov ah, al
    mov cx, 160
    rep stosw
    inc al
    dec bx
    jnz .s
    ret

drawground:
    mov di, 172*320
    mov al, 204
    mov bx, 28
.g:
    mov ah, al
    mov cx, 160
    rep stosw
    inc al
    dec bx
    jnz .g
    ret

;fillrect

; AX=x BX=y CX=width DX=height SI=colour

fillrect:
    push ax
    push bx
    push cx
    push dx
    push di
    push bp
    mov di, bx
    shl di, 6                ; y*64
    shl bx, 8                ; y*256
    add di, bx               ; y*320
    add di, ax               ; + x
    mov ax, si               ; AL = colour
    mov bp, cx               ; width yaad rakho
.row:
    mov cx, bp
    push di
    rep stosb                ; ek row bharo
    pop di
    add di, 320              ; agli row
    dec dx
    jnz .row
    pop bp
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

seg1:   db 15,4,33,  63,48,20
seg2:   db 22,10,30,  2,1,5
seglen  dw 0
=======
mov word [es:2250], 0x3DDB
mov word [es:2252], 0x3DDC
mov word [es:2254], 0x3DDC
mov word [es:2256], 0x3DDB
mov word [es:2258], 0x3DDB
mov word [es:2260], 0x3DDB
mov word [es:2262], 0x3DDB
mov word [es:2264], 0x3DDB
mov word [es:2266], 0x3DDC
mov word [es:2268], 0x3DDC

mov word [es:2412], 0x3DDF
mov word [es:2414], 0x3DDB
mov word [es:2416], 0x3DDB
mov word [es:2418], 0x3DDB
mov word [es:2420], 0x3DDB
mov word [es:2422], 0x3DDB
mov word [es:2424], 0x3DDF
mov word [es:2426], 0x3DDF

mov word [es:2574], 0x3DDB
mov word [es:2576], 0x3DDC
mov word [es:2580], 0x3DDB
mov word [es:2582], 0x3DDC

RET
dinofloor:
mov ax, 0xb800
mov es, ax
mov di,0
mov cx, 80*18

blankabove:
mov word [es:di], 0x3020
add di, 2
loop blankabove


Ground:
Firstlayer:

mov di, 160*17
mov cx, 20
space1:
mov word [es: di], 0x0ADB
add di, 8
loop space1

mov di, 160*17
mov cx, 16
space1.1:
mov word [es: di], 0x2020
add di, 10
loop space1.1


mov di, 160*18
mov cx, 80*2
line1:
mov word [es: di], 0x0ADB
add di, 2
loop line1




Secondlayer:

mov di,160*19
mov cx, 20
space2:
mov word [es: di], 0x2020
add di, 8
loop space2


mov di,160*19
mov cx, 12
whiterender:
mov word [es: di], 0x02DB
add di, 12
loop whiterender

mov di,160*20
mov cx, 80*2
line2:
mov word [es: di], 0x2020
add di, 2
loop line2

Thirdlayer:

mov di,160*20
mov cx, 20
space3:
mov word [es: di], 0x0ADB
add di, 8
loop space3

mov di,160*21
mov cx, 80*2
line3:
mov word [es: di], 0x0ADB
add di, 2
loop line3

Fourthlayer:

mov di,160*21
mov cx, 16
space4:
mov word [es: di], 0x6020
add di, 10
loop space4

mov di,160*21
mov cx, 12
blackrender:
mov word [es: di], 0x0720
add di, 12
loop blackrender

mov di,160*22
mov cx, 80*2
line4:
mov word [es: di], 0x6020
add di, 2
loop line4

Fifthlayer:
mov di,160*23
mov cx, 80*2
line5:
mov word [es: di], 0x6020
add di, 2
loop line5

mov di,162*23
mov cx, 10
space5.1:
mov word [es: di], 0x0720
add di, 16
loop space5.1

mov di,160*24
mov cx, 20
space5.2:
mov word [es: di], 0x4020
add di, 8
loop space5.2

mov di,160*25
mov cx, 40
space5.3:
mov word [es: di], 0x4020
add di, 4
loop space5.3
RET
smallcloud:
mov word [es:di+4], 0x3FDC
mov word [es:di+6], 0x3FDC

mov word [es:di+160], 0x3FDC
mov word [es:di+162], 0x3FDB
mov word [es:di+164], 0x3FDB
mov word [es:di+166], 0x3FDB
mov word [es:di+168], 0x3FDB
mov word [es:di+170], 0x3FDC
RET
bigcloud:
mov word [es:di+8], 0x3FDC
mov word [es:di+10], 0x3FDC
mov word [es:di+12], 0x3FDC

mov word [es:di+162], 0x3FDC
mov word [es:di+164], 0x3FDC
mov word [es:di+166], 0x3FDB
mov word [es:di+168], 0x3FDB
mov word [es:di+170], 0x3FDB
mov word [es:di+172], 0x3FDB
mov word [es:di+174], 0x3FDB
mov word [es:di+176], 0x3FDC
mov word [es:di+178], 0x3FDC

mov word [es:di+320], 0x3FDC
mov word [es:di+322], 0x3FDB
mov word [es:di+324], 0x3FDB
mov word [es:di+326], 0x3FDB
mov word [es:di+328], 0x3FDB
mov word [es:di+330], 0x3FDB
mov word [es:di+332], 0x3FDB
mov word [es:di+334], 0x3FDB
mov word [es:di+336], 0x3FDB
mov word [es:di+338], 0x3FDB
mov word [es:di+340], 0x3FDC
RET
start:
call dinofloor
call dino
mov di, 360
call bigcloud
mov di, 900
call smallcloud
mov di, 276
call bigcloud
 mov ax, 0x4C00
    int 0x21
>>>>>>> fff29e6e8962699e7e0f9164576516895af721b3
