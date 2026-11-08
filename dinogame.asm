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

    ;dino colours: set palette entries 10, 11, 12, 13 (R, G, B each 0-63)
    mov dx, 0x3C8
    mov al, 10                       ; start writing at palette index 10
    out dx, al
    mov dx, 0x3C9
    mov al, 14                       ; index 10: body, forest green (14,34,16)
    out dx, al
    mov al, 34
    out dx, al
    mov al, 16
    out dx, al
    mov al, 56                       ; index 11: horns/spikes, bone (56,52,38)
    out dx, al
    mov al, 52
    out dx, al
    mov al, 38
    out dx, al
    mov al, 63                       ; index 12: eye, red (63,10,6)
    out dx, al
    mov al, 10
    out dx, al
    mov al, 6
    out dx, al
    mov al, 26                       ; index 13: belly/jaw, light green (26,46,20)
    out dx, al
    mov al, 46
    out dx, al
    mov al, 20
    out dx, al

    ;dino: read the bitmap one character at a time
    ;each character = one 2x2 pixel block, '.' = skip
    mov di, dino                     ; pointer to the bitmap
    mov bx, 132                      ; y (132 + 20*2 = 172, top of the ground)
    mov bp, 20                       ; 20 rows
dinorow:
    mov ax, 30                       ; x, back to the left edge every row
    mov cx, 21                       ; 21 columns
dinocol:
    mov dl, [di]                     ; current character
    mov si, 0                        ; 'x' = outline, black
    cmp dl, 'x'
    je dinoput
    mov si, 10                       ; '#' = body, green
    cmp dl, '#'
    je dinoput
    mov si, 13                       ; '+' = belly, light green
    cmp dl, '+'
    je dinoput
    mov si, 11                       ; '^' = horns/spikes, bone
    cmp dl, '^'
    je dinoput
    mov si, 12                       ; 'o' = eye, red
    cmp dl, 'o'
    je dinoput
    mov si, 15                       ; 'v' = teeth, white
    cmp dl, 'v'
    jne dinoskip                     ; anything else ('.') is not drawn
dinoput:
    push cx                          ; save column counter
    mov cx, 2                        ; width
    mov dx, 2                        ; height
    call fillrect                    ; draw block at (ax, bx) in colour si
    pop cx
dinoskip:
    inc di                           ; next character
    add ax, 2                        ; next block to the right
    loop dinocol
    add bx, 2                        ; next row down
    dec bp
    jnz dinorow

    ;score: hardcoded text in the top right, printed as it is
    ;each character is 3x5 from the font (2x2 blocks = 6x10 pixels)

    ;part 1: "HI 02547" in grey
    mov di, hitxt                    ; pointer to the grey text
    mov ax, 200                      ; x
    mov si, 7                        ; colour: grey
hichar:
    mov bl, [di]
    cmp bl, 0FFh                     ; end of text?
    je hidone
    cmp bl, 12                       ; space? draw nothing
    je hinext
    push di                          ; save text pointer
    push ax                          ; save this character's x
    xor bh, bh
    mov di, bx
    shl di, 4                        ; index*16
    sub di, bx                       ; index*15 = offset into the font
    add di, font
    mov bx, 8                        ; y
    mov bp, 5                        ; 5 rows
hirow:
    push ax
    mov cx, 3                        ; 3 columns
hicol:
    cmp byte [di], '#'
    jne hiskip
    push cx
    mov cx, 2
    mov dx, 2
    call fillrect
    pop cx
hiskip:
    inc di
    add ax, 2
    loop hicol
    pop ax
    add bx, 2
    dec bp
    jnz hirow
    pop ax
    pop di
hinext:
    inc di                           ; next character
    add ax, 8                        ; 6 pixel glyph + 2 gap
    jmp hichar
hidone:

    ;part 2: "00873" in white
    mov di, scoretxt                 ; pointer to the white text
    mov ax, 272                      ; x (200 + 9 chars * 8)
    mov si, 15                       ; colour: white
scorechar:
    mov bl, [di]
    cmp bl, 0FFh                     ; end of text?
    je scoredone
    cmp bl, 12                       ; space? draw nothing
    je scorenext
    push di                          ; save text pointer
    push ax                          ; save this character's x
    xor bh, bh
    mov di, bx
    shl di, 4                        ; index*16
    sub di, bx                       ; index*15 = offset into the font
    add di, font
    mov bx, 8                        ; y
    mov bp, 5                        ; 5 rows
scorerow:
    push ax
    mov cx, 3                        ; 3 columns
scorecol:
    cmp byte [di], '#'
    jne scoreskip
    push cx
    mov cx, 2
    mov dx, 2
    call fillrect
    pop cx
scoreskip:
    inc di
    add ax, 2
    loop scorecol
    pop ax
    add bx, 2
    dec bp
    jnz scorerow
    pop ax
    pop di
scorenext:
    inc di                           ; next character
    add ax, 8                        ; 6 pixel glyph + 2 gap
    jmp scorechar
scoredone:

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

dino:   db '..........xx...xx....'
        db '.........x^^x.x^^x...'
        db '..........x^^xxx^^x..'
        db '..........x########x.'
        db '.........x##xx######x'
        db '.........x##oo######x'
        db '.........x##########x'
        db '.........x#####vxvxvx'
        db '.......x.x###+++++#x.'
        db '.x...xx^x######xxxx..'
        db 'x#xxx^x#########xx...'
        db 'x##^x#############x..'
        db 'x###############x#x..'
        db '.x#########++++#xx...'
        db '..xx######++###x.....'
        db '....xx####xx###x.....'
        db '......x##x.x##x......'
        db '......x##x.x##x......'
        db '......x###xx###x.....'
        db '.......xxx..xxx......'

; dino bitmap: 21 columns x 20 rows
; 'x' = black outline and brow     (palette 0)
; '#' = body, forest green         (palette 10: 14,34,16)
; '+' = belly and jaw, light green (palette 13: 26,46,20)
; '^' = horns and back spikes, bone (palette 11: 56,52,38)
; 'o' = eye, red                   (palette 12: 63,10,6)
; 'v' = teeth, white               (palette 15)
; '.' = empty, not drawn
; rows 1-3: horns, row 5: angry brow, row 6: red eye
; row 8: teeth, row 9: lower jaw, rows 10-11: back spikes
; row 12: arm, rows 13-15: tail and belly, rows 16-20: legs and feet

;font: each character is 3x5, '#' = draw, '.' = empty (15 bytes each)
font:   db '###'
        db '#.#'
        db '#.#'
        db '#.#'
        db '###'   ; 0

        db '.#.'
        db '##.'
        db '.#.'
        db '.#.'
        db '###'   ; 1

        db '###'
        db '..#'
        db '###'
        db '#..'
        db '###'   ; 2

        db '###'
        db '..#'
        db '###'
        db '..#'
        db '###'   ; 3

        db '#.#'
        db '#.#'
        db '###'
        db '..#'
        db '..#'   ; 4

        db '###'
        db '#..'
        db '###'
        db '..#'
        db '###'   ; 5

        db '###'
        db '#..'
        db '###'
        db '#.#'
        db '###'   ; 6

        db '###'
        db '..#'
        db '..#'
        db '..#'
        db '..#'   ; 7

        db '###'
        db '#.#'
        db '###'
        db '#.#'
        db '###'   ; 8

        db '###'
        db '#.#'
        db '###'
        db '..#'
        db '###'   ; 9

        db '#.#'
        db '#.#'
        db '###'
        db '#.#'
        db '#.#'   ; 10 = H

        db '###'
        db '.#.'
        db '.#.'
        db '.#.'
        db '###'   ; 11 = I

;score text, hardcoded for now
;each number is a font index: 0-9 = digits, 10 = H, 11 = I, 12 = space, 0FFh = end
hitxt:    db 10, 11, 12, 0, 2, 5, 4, 7, 0FFh     ; "HI 02547" (grey)
scoretxt: db 0, 0, 8, 7, 3, 0FFh                 ; "00873" (white)