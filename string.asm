        ;从1加到100并显示累加结果
        jmp start
message db '1+2+3+...+100='

start:
        mov ax, 0x7c0            ;设置数据段的段基地址
        mov ds, ax

        mov ax, 0xb800           ;设置附加段基址到显示缓冲区
        mov es,ax

        ;以下显示字符串
        mov si, message
        mov di, 0
        mov cx, start-message
showmsg:
        mov al, [si]
        mov [es:di], al
        inc di
        mov byte [es:di], 0x07
        inc di
        inc si
        loop showmsg

        ;计算1到100的和
        xor ax, ax               ;ax用于存放累加结果
        mov cx, 1
summate:
        add ax, cx
        inc cx
        cmp cx, 100
        jle summate

        ;以下分解累加和的每个数位
        xor cx, cx               ;设置栈段的段基址
        mov ss, cx
        mov sp, cx

        mov bx, 10
        xor cx, cx
decompo:
        inc cx
        xor dx, dx
        div bx
        add dl, 0x30
        push dx
        cmp ax, 0
        jne decompo

shownum:
        pop dx
        mov [es:di], dl
        inc di
        mov byte [es:di], 0x07
        inc di
        loop shownum

        jmp $

        times 510-($-$$) db 0
        db 0x55, 0xAA

