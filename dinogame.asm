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

    ;road texture: draw every column of the road strip once
    xor ax, ax                       ; x = 0
initroad:
    call roadcol
    inc ax
    cmp ax, 320
    jb initroad

    ;dino colours: set palette entries 10, 11, 12, 13, 14 (R, G, B each 0-63)
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
    mov al, 6                        ; index 14: cactus, dark green (6,26,20)
    out dx, al
    mov al, 26
    out dx, al
    mov al, 20
    out dx, al

    ;dino: body plus the first running leg frame
    call drawdino

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

    ;random seed: read the BIOS tick counter from memory 0040:006C
    ;(just a memory read, no interrupt is hooked)
    push ds
    mov ax, 0x0040
    mov ds, ax
    mov ax, [0x006C]
    pop ds
    mov [seed], ax

    ;game loop: one frame per pass, the delay at the end sets the speed
gameloop:
    mov ah, 1                        ; BIOS: is a key waiting? (does not wait)
    int 0x16
    jnz quit                         ; any key quits

    call scrollroad                  ; road moves every frame

    inc word [cloudtick]             ; clouds move every 'cloudrate' frames
    mov ax, [cloudtick]
    cmp ax, [cloudrate]
    jb noclouds
    mov word [cloudtick], 0
    call scrollclouds
noclouds:

    inc word [legtick]               ; legs swap every 'legrate' frames
    mov ax, [legtick]
    cmp ax, [legrate]
    jb nolegs
    mov word [legtick], 0
    xor byte [legframe], 1           ; 0 -> 1 -> 0 ...
    call drawlegs
nolegs:

    call spawncactus                 ; maybe start a new cactus
    call movecacti                   ; move, draw, check collisions

    cmp byte [cactnear], 0           ; a cactus touched the dino's area?
    je nodino
    call drawdino                    ; then draw the dino again on top
nodino:

    cmp byte [gameover], 1
    je over

    call delay
    jmp gameloop

over:
    mov ah, 0                        ; game over: freeze until a key is pressed
    int 0x16
    jmp exitgame

quit:
    mov ah, 0                        ; take the pressed key out of the buffer
    int 0x16

exitgame:
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

; draws a bitmap, every character is a 2x2 block
; DI=bitmap AX=x BX=y, size in bmpcols/bmprows, bmpopaque=1 fills dots with sky
drawbmp:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov [bmpx], ax
    mov bp, [bmprows]
bmprow:
    mov ax, [bmpx]                   ; x back to the left edge every row
    mov cx, [bmpcols]
bmpcol:
    cmp ax, 0                        ; off the left edge?
    jl bmpnext
    cmp ax, 318                      ; off the right edge?
    jg bmpnext
    mov dl, [di]                     ; current character
    mov si, colmap
bmpfind:
    mov dh, [si]                     ; look it up in the colour table
    cmp dh, 0
    je bmpempty                      ; not in the table: empty
    cmp dh, dl
    je bmpfound
    add si, 2
    jmp bmpfind
bmpfound:
    mov dl, [si+1]                   ; colour of this character
    xor dh, dh
    mov si, dx
    push cx
    mov cx, 2
    mov dx, 2
    call fillrect
    pop cx
    jmp bmpnext
bmpempty:
    cmp byte [bmpopaque], 0          ; transparent: leave what is there
    je bmpnext
    push cx                          ; opaque: paint sky (1 colour per row)
    mov cx, 2
    mov dx, 1
    mov si, bx
    add si, 32                       ; sky colour of row y = 32 + y
    call fillrect
    inc bx
    inc si
    call fillrect
    dec bx
    pop cx
bmpnext:
    inc di                           ; next character
    add ax, 2                        ; next block to the right
    dec cx
    jnz bmpcol
    add bx, 2                        ; next row down
    dec bp
    jnz bmprow
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; paints a box in sky colours, used to erase
; AX=x BX=y CX=width DX=height
skyfill:
    push ax
    push bx
    push cx
    push dx
    push si
    cmp ax, 0                        ; starts left of the screen?
    jge sfleftok
    add cx, ax                       ; cut off the part left of x = 0
    xor ax, ax
sfleftok:
    mov si, ax
    add si, cx
    cmp si, 320                      ; goes past the right edge?
    jle sfrightok
    mov cx, 320
    sub cx, ax                       ; cut off the part past x = 319
sfrightok:
    cmp cx, 0                        ; nothing left to paint?
    jle sfdone
sfrow:
    mov si, bx
    add si, 32                       ; sky colour of row y = 32 + y
    push dx
    mov dx, 1
    call fillrect
    pop dx
    inc bx
    dec dx
    jnz sfrow
sfdone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; dino body (first 15 rows) and the current legs
drawdino:
    mov di, dino
    mov ax, 30                       ; x
    mov bx, 132                      ; y (132 + 20*2 = 172, top of the ground)
    mov word [bmpcols], 21
    mov word [bmprows], 15
    mov byte [bmpopaque], 0
    call drawbmp
    mov di, dinorun1
    cmp byte [legframe], 0
    je ddlegs
    mov di, dinorun2
ddlegs:
    mov ax, 30
    mov bx, 162                      ; legs start 15 rows down (132 + 15*2)
    mov word [bmprows], 5
    call drawbmp
    ret

; erase old legs and draw the next leg frame
drawlegs:
    mov ax, 38                       ; leg area: x 38-61, y 162-171
    mov bx, 162
    mov cx, 24
    mov dx, 10
    call skyfill
    mov di, dinorun1
    cmp byte [legframe], 0
    je dllegs
    mov di, dinorun2
dllegs:
    mov ax, 30
    mov bx, 162
    mov word [bmpcols], 21
    mov word [bmprows], 5
    mov byte [bmpopaque], 0
    call drawbmp
    ret

; moves the road left by roadspeed pixels
; like the book scrolling (7.6) but sideways
scrollroad:
    push ds
    mov ax, 0xA000                   ; DS = ES = screen, so MOVSB copies screen to screen
    mov ds, ax
    mov bx, 172*320                  ; first road row
    mov dx, 12                       ; 12 road rows
srrow:
    mov di, bx                       ; destination: start of the row
    mov si, bx
    add si, [cs:roadspeed]           ; source: 'roadspeed' pixels to the right
    mov cx, 320
    sub cx, [cs:roadspeed]           ; (DS is the screen now, so variables use CS:)
    rep movsb
    add bx, 320                      ; next row
    dec dx
    jnz srrow
    pop ds

    mov ax, [roadspeed]              ; the road has moved forward
    add [roadpos], ax
    mov ax, 320
    sub ax, [roadspeed]              ; new columns on the right edge
srnew:
    call roadcol
    inc ax
    cmp ax, 320
    jb srnew
    ret

; draws one road column at x = AX from the road tile
roadcol:
    push ax
    push bx
    push cx
    push si
    push di
    mov di, ax
    add di, 172*320                  ; screen offset of row 172, column x
    mov si, [roadpos]
    add si, ax
    and si, 63                       ; wrap around the 64-wide tile
    add si, road
    mov cx, 12                       ; 12 rows
    mov bl, 204                      ; ground colour of row 172
rcrow:
    mov al, [si]
    cmp al, '#'
    jne rcnotline
    mov al, 172                      ; '#' = road line (light tan)
    jmp rcput
rcnotline:
    cmp al, '*'
    jne rcnotpebble
    mov al, 112                      ; '*' = pebble (dusty pink)
    jmp rcput
rcnotpebble:
    mov al, bl                       ; '.' = plain ground of this row
rcput:
    mov [es:di], al
    add di, 320                      ; next row down
    add si, 64                       ; next tile row
    inc bl                           ; ground gets darker each row
    loop rcrow
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; moves cloud rows 20-95 left by 1 pixel
; left pixel goes to the right side so clouds come back
scrollclouds:
    push ds
    mov ax, 0xA000                   ; DS = ES = screen
    mov ds, ax
    mov bx, 20*320                   ; first cloud row
    mov dx, 76                       ; rows 20 to 95
scrow:
    mov al, [bx]                     ; save the leftmost pixel
    mov si, bx
    inc si
    mov di, bx
    mov cx, 319
    rep movsb                        ; shift the row left by 1
    mov [es:di], al                  ; old leftmost pixel goes to x = 319
    add bx, 320
    dec dx
    jnz scrow
    pop ds
    ret

; starts a new cactus at x=320 when the gap is over
spawncactus:
    mov ax, [roadspeed]
    sub [nextgap], ax                ; road moved, gap gets smaller
    cmp word [nextgap], 0
    jg spdone
    mov bx, 0                        ; find a free cactus slot
spfind:
    cmp byte [cacton+bx], 0
    je spfree
    inc bx
    cmp bx, 3
    jb spfind
    mov word [nextgap], 20           ; all slots busy, try again soon
    jmp spdone
spfree:
    mov byte [cacton+bx], 1
    call random
    and ah, 1                        ; random type: 0 = small, 1 = big
    mov [cacttype+bx], ah
    mov si, bx
    shl si, 1                        ; word index
    mov word [cactx+si], 320         ; starts just past the right edge
    call random
    mov al, ah
    xor ah, ah
    and al, 127                      ; random 0-127
    add ax, 120                      ; next gap: 120-247 pixels
    mov [nextgap], ax
spdone:
    ret

; moves cacti left, draws them and checks for a hit
movecacti:
    mov byte [cactnear], 0
    mov bx, 0                        ; slot number
mcloop:
    cmp byte [cacton+bx], 0
    jne mcactive
    jmp mcnext
mcactive:
    push bx
    mov si, bx
    shl si, 1                        ; si = word index into cactx
    mov ax, [roadspeed]
    sub [cactx+si], ax               ; move left with the road

    mov bl, [cacttype+bx]            ; look up size and bitmap of this type
    xor bh, bh
    shl bx, 1
    mov ax, [cactcols+bx]
    mov [bmpcols], ax
    mov ax, [cactrows+bx]
    mov [bmprows], ax
    mov di, [cactbmp+bx]
    mov dx, [cacty+bx]               ; dx = top y
    mov cx, [bmpcols]
    shl cx, 1                        ; cx = width in pixels
    mov ax, [cactx+si]               ; ax = new x

    push ax                          ; erase the strip it just left (right side)
    push cx
    push dx
    add ax, cx                       ; x + width
    mov bx, dx
    mov cx, [roadspeed]
    mov dx, [bmprows]
    shl dx, 1                        ; height in pixels
    call skyfill
    pop dx
    pop cx
    pop ax

    mov bp, ax
    add bp, cx
    cmp bp, 0                        ; fully off the left edge?
    jg mcvisible
    pop bx
    mov byte [cacton+bx], 0          ; free the slot
    jmp mcnext
mcvisible:
    mov bx, dx                       ; draw it, '.' painted with sky
    mov byte [bmpopaque], 1
    call drawbmp
    mov byte [bmpopaque], 0

    cmp ax, 80                       ; close to the dino? redraw dino later
    jge mcfar
    mov byte [cactnear], 1
mcfar:
    cmp byte [hitcheck], 0           ; collisions turned off?
    je mcnohit
    mov bp, ax
    add bp, 2                        ; cactus left edge (inside the outline)
    cmp bp, 66                       ; dino hitbox right edge
    jge mcnohit
    mov bp, ax
    add bp, cx
    sub bp, 2                        ; cactus right edge
    cmp bp, 32                       ; dino hitbox left edge
    jle mcnohit
    mov byte [gameover], 1           ; boxes overlap: hit!
mcnohit:
    pop bx
mcnext:
    inc bx
    cmp bx, 3
    jae mcdone
    jmp mcloop
mcdone:
    ret

; random number in AX, seed = seed*25173 + 13849
random:
    push dx
    mov ax, [seed]
    mov dx, 25173
    mul dx
    add ax, 13849
    mov [seed], ax
    pop dx
    ret

; delay with two empty loops, bigger delaycount = slower
delay:
    push cx
    mov cx, [delaycount]
dlouter:
    push cx
    mov cx, 3000
dlinner:
    loop dlinner
    pop cx
    loop dlouter
    pop cx
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
; the game draws rows 1-15 from here and the legs from dinorun1/dinorun2

dinorun1: db '....xx####xx###x.....'
          db '......x##x.x##x......'
          db '......x##x.x###x.....'
          db '......x###x.xxx......'
          db '.......xxx...........'

dinorun2: db '....xx####xx###x.....'
          db '......x##x.x##x......'
          db '......x###xx##x......'
          db '.......xxx.x###x.....'
          db '............xxx......'

; running legs: 2 frames of 21 x 5, they replace dino rows 16-20
; dinorun1 = back foot down, front foot lifted
; dinorun2 = front foot down, back foot lifted

cactus1:  db '...xx...'
          db '..xc+x..'
          db '.xxc+x..'
          db 'xcxc+xx.'
          db 'xcxc+xcx'
          db 'xcxc+xcx'
          db 'xccc+xcx'
          db '.xxc+ccx'
          db '..xc+xx.'
          db '..xc+x..'
          db '..xc+x..'
          db '..xc+x..'
          db '...xx...'

cactus2:  db '....xx....'
          db '...xccx...'
          db '..xcc+cx..'
          db '.xxcc+cx..'
          db 'xcxcc+cxx.'
          db 'xcxcc+cxcx'
          db 'xcxcc+cxcx'
          db 'xcxcc+cxcx'
          db 'xcccc+cxcx'
          db '.xxcc+cccx'
          db '..xcc+cxx.'
          db '..xcc+cx..'
          db '..xcc+cx..'
          db '..xcc+cx..'
          db '..xcc+cx..'
          db '..xcc+cx..'
          db '...xxxx...'

; cactus1 = small cactus, 8 x 13 (16 x 26 pixels)
; cactus2 = big cactus, 10 x 17 (20 x 34 pixels)
; 'x' = black outline, 'c' = cactus green (palette 14), '+' = light stripe (palette 13)

road:     db '################################################################'
          db '.........###.........................##.............#...........'
          db '................................................................'
          db '..........*..**..................................**.............'
          db '.......................................................****.....'
          db '..........**..................................................**'
          db '.......**....*......................***.........................'
          db '............***..*.............**...............................'
          db '..***..........**..................***..........................'
          db '......*..........................................*..............'
          db '..................**....................................**......'
          db '............*....**..........**...........................****..'

; road tile: 64 x 12, repeated along the road (rows 172-183), 1 character = 1 pixel
; '#' = road line (palette 172), '*' = pebble (palette 112), '.' = ground

;colour table for drawbmp: character, palette colour ... 0 = end
colmap:   db 'x', 0                  ; outline: black
          db '#', 10                 ; dino body: green
          db '+', 13                 ; belly / stripe: light green
          db '^', 11                 ; horns and spikes: bone
          db 'o', 12                 ; eye: red
          db 'v', 15                 ; teeth: white
          db 'c', 14                 ; cactus: dark green
          db 0

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

;game settings: change these to tune the game
roadspeed:  dw 4                     ; road and cacti move this many pixels per frame (keep it even)
cloudrate:  dw 3                     ; clouds move 1 pixel every this many frames
legrate:    dw 4                     ; legs swap every this many frames
delaycount: dw 25                    ; frame delay, bigger = slower game
hitcheck:   db 1                     ; 1 = collisions on, 0 = off (for testing)

;game state
cloudtick:  dw 0                     ; frames since clouds last moved
legtick:    dw 0                     ; frames since legs last swapped
legframe:   db 0                     ; which leg frame is showing: 0 or 1
roadpos:    dw 0                     ; how far the road has moved in total
gameover:   db 0                     ; 1 = dino hit a cactus
cactnear:   db 0                     ; 1 = a cactus is close to the dino this frame
seed:       dw 0                     ; random number seed
nextgap:    dw 400                   ; pixels of road until the next cactus

;cacti: up to 3 on screen at once
cacton:     db 0, 0, 0               ; 1 = this slot has a cactus
cacttype:   db 0, 0, 0               ; 0 = small, 1 = big
cactx:      dw 0, 0, 0               ; x position (can go below 0)

;cactus types: index 0 = small, 1 = big
cactbmp:    dw cactus1, cactus2      ; bitmap
cactcols:   dw 8, 10                 ; columns
cactrows:   dw 13, 17                ; rows
cacty:      dw 146, 138              ; top y (172 - rows*2, stands on the ground)

;drawbmp settings
bmpcols:    dw 0
bmprows:    dw 0
bmpopaque:  db 0
bmpx:       dw 0