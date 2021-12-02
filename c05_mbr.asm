begin:
        jmp start

mytext  db 'L', 0x07, 'a', 0x07, 'b', 0x07, 'e', 0x07, 'l', 0x07, ' ', 0x07,\
           'o', 0x07, 'f', 0x07, 'f', 0x07, 's', 0x07, 'e', 0x07, 't', 0x07, ':', 0x07,

start:
        ;文件名c05_mbr.asm
        ;文件说明: 硬盘主引导扇区代码
        ;创建日期: 2021-12-02 22:01


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

        mov ax, number        ;取得标号number的偏移地址
        mov bx, 10

        ;设置数据段的基地址
        mov cx, cs
        mov ds, cx

        ;求个位上的数字
        xor dx, dx
        div bx
        mov [0x7c00+number+0x00], dl     ;保存个位上的数字

        ;求十位上的数字
        xor dx, dx
        div bx
        mov [0x7c00+number+0x01], dl     ;保存十位上的数字

        ;求百位上的数字
        xor dx, dx
        div bx
        mov [0x7c00+number+0x02], dl     ;保存百位上的数字

        ;求千位上的数字
        xor dx, dx
        div bx
        mov [0x7c00+number+0x03], dl     ;保存千位上的数字

        ;求万位上的数字
        xor dx, dx
        div bx
        mov [0x7c00+number+0x04], dl     ;保存万位上的数字

        ;显示万位上的数字
        mov al, [0x7c00+number+0x04]
        add al, 0x30
        mov [es:0x1a], al
        mov byte [es:0x1b], 0x07

        ;显示千位上的数字
        mov al, [0x7c00+number+0x03]
        add al, 0x30
        mov [es:0x1c], al
        mov byte [es:0x1d], 0x07

        ;显示百位上的数字
        mov al, [0x7c00+number+0x02]
        add al, 0x30
        mov [es:0x1e], al
        mov byte [es:0x1f], 0x07

        ;显示十位上的数字
        mov al, [0x7c00+number+0x01]
        add al, 0x30
        mov [es:0x20], al
        mov byte [es:0x21], 0x07

        ;显示个位上的数字
        mov al, [0x7c00+number+0x00]
        add al, 0x30
        mov [es:0x22], al
        mov byte [es:0x23], 0x07

again:
        jmp again

number  db 0, 0, 0, 0, 0


current:
        times 510-($-$$) db 0
        db 0x55, 0xAA
