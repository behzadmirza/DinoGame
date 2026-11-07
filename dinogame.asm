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