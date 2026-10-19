[org 0x100]
jmp start
dino:
mov word [es:1780], 0x3DDC
mov word [es:1782], 0x5DDC
mov word [es:1784], 0x5FDC
mov word [es:1786], 0x5DDC
mov word [es:1788], 0x5DDC
mov word [es:1790], 0x3DDC
mov word [es:1792], 0x3DDC

mov word [es:1940], 0x3DDB
mov word [es:1942], 0x3DDB
mov word [es:1944], 0x3DDB
mov word [es:1946], 0x3DDB
mov word [es:1948], 0x3DDF
mov word [es:1950], 0x3DDF
mov word [es:1952], 0x3DDF

mov word [es:2090], 0x3DDC
mov word [es:2098], 0x3DDC
mov word [es:2100], 0x3DDB
mov word [es:2102], 0x3DDB
mov word [es:2104], 0x3DDB
mov word [es:2106], 0x3DDF
mov word [es:2108], 0x3DDF
mov word [es:2110], 0x3DDF

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