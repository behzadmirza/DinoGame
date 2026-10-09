[org 0x100]

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

 mov ax, 0x4C00
    int 0x21


