begin:
        jmp start

mytext  db 'L', 0x07, 'a', 0x07, 'b', 0x07, 'e', 0x07, 'l', 0x07, ' ', 0x07,\
           'o', 0x07, 'f', 0x07, 'f', 0x07, 's', 0x07, 'e', 0x07, 't', 0x07, ':', 0x07,

start:
        ;文件名c05_mbr.asm
        ;文件说明: 硬盘主引导扇区代码
        ;创建日期: 2021-12-02 22:01

        ;设置数据段的基地址
        mov ax, 0x7c0                ;0x07c0:0x0000开始的段，物理地址是0x7c00
        mov ds, ax

        mov ax, 0xb800               ;指向文本模式的显示缓冲区
        mov es, ax

        ;以下显示字符串"Label offset:"
        cld
        mov si, mytext
        mov di, 0
        mov cx, (start-mytext)/2
        rep movsw

        mov ax, number                ;取得标号number的偏移地址

        mov bx, ax
        mov si, 10                    ;除数
        mov cx, 5                     ;控制循环次数

digit:
        xor dx, dx
        div si
        mov [bx], dl                  ;保存每一位上的数字
        inc bx
        loop digit

        mov bx, number
        mov si, 4
show:
        mov al, [bx+si]                  ;取保存的数位的值
        add al, 0x30
        mov ah, 0x07                  ;设置字符的属性
        mov [es:di], ax               ;设置显存
        add di, 2
        dec si
        jns show

        jmp $

number  db 0, 0, 0, 0, 0


current:
        times 510-($-$$) db 0
        db 0x55, 0xAA
