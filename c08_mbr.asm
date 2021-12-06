        ;文件名: c08_mbr.asm
        ;文件说明: 硬盘主引导扇区代码（加载程序）
        ;创建日期 2021-12-05 13:52

        app_lba_start equ 100                    ;声明常数（用户程序起始逻辑扇区号）

SECTION mbr align=16 vstart=0x7c00
        ;设置堆栈和指针
        xor ax, ax
        mov ss, ax
        mov sp, ax

        mov ax, [phy_base]                       ;计算用于加载用户程序的逻辑段地址
        mov dx, [phy_base+0x02]
        mov bx, 16
        div bx
        mov ds, ax                               ;令DS和ES指向用户程序所加载的段，用于操作用户程序
        mov es, ax

        ;读取程序起始部分，从硬盘上读取一个扇区
        xor di, di
        mov si, app_lba_start                    ;程序在硬盘上的起始逻辑扇区号
        xor bx, bx                               ;加载到DS:0x0000处
        call read_hard_disk_0

        ;获取用户程序的总字节数
        mov dx, [2]
        mov ax, [0]
        mov bx, 512                              ;每个扇区512字节
        div bx                                   ;计算用户程序所占的扇区总数，如果有余数，说明有个扇区未被填满
        cmp dx, 0
        jnz @1                                   ;未除尽，代表用户程序所占用的扇区数是ax+1，因为ax的值比实际扇区数少1，所以剩余要读的扇区总数就是ax，不需要再将ax减1了
        dec ax                                   ;除尽，代表用户程序所占用的扇区数是ax，因为之前已经读了一个扇区，所以剩余要读的扇区总数需要减1
  @1:
        cmp ax, 0                                ;考虑实际长度小于等于512个字节的情况，就是用户程序只占用一个扇区，上面已经读取完了一个扇区，不需要继续读取了，直接跳过后面继续读取的逻辑
        jz direct

        ;读取剩余的扇区
        push ds                                  ;后面需要改变ds，这里先压栈保存

        mov cx, ax                               ;循环次数（剩余扇区数）
  @2:
        mov ax, ds
        add ax, 0x20                             ;每次读取一个扇区，都默认读取到一个新的逻辑数据段（每个逻辑数据段的大小为一个扇区的大小512字节，因此相邻两个段的基地址差距就是0x20），
                                                 ;最先读取的那个扇区的起始逻辑地址是0x1000:0x0000，第二个扇区的起始逻辑地址是0x1020:0x0000，它们俩之间正好差距512字节
        mov ds, ax

        xor bx, bx                               ;每次读时，偏移地址始终为0x0000
        inc si
        call read_hard_disk_0
        loop @2

        pop ds                                   ;恢复数据段基址到用户程序头部段

  direct:
        ;计算用户程序入口点代码段基地址
        mov dx, [0x08]
        mov ax, [0x06]
        call calc_segment_base
        mov [0x06], ax                           ;回填修正后的用户程序入口点代码段的逻辑段地址（段重定位）

        ;开始处理用户程序段重定位表


;------------------------------------------------------------------------------------
read_hard_disk_0:                          ;从硬盘读取一个逻辑扇区
                                           ;输入：DI:SI = 起始逻辑扇区号
                                           ;      DS:BX = 目标缓冲区地址
        push ax
        push bx
        push cx
        push dx

        mov dx, 0x1f2
        mov al, 0x01                             ;读取一个扇区
        out dx, al

        mov dx, 0x1f3
        mov ax, si
        out dx, al                               ;LBA地址7-0

        inc dx                                   ;0x1f4
        mov al, ah
        out dx, al                               ;LBA地址15-8

        inc dx                                   ;0x1f5
        mov ax, di
        out dx, al                               ;LBA地址23-16

        inc dx                                   ;0x1f6
        mov al, 0xe0                             ;LBA28模式，主硬盘
        or  al, ah                               ;LBA地址27-24
        out dx,al

        ;1f7端口也是8位端口，所以通过al来传输数据
        mov dx, 0x1f7
        mov al, 0x20                             ;读命令
        out dx, al

        mov dx, 0x1f7
  .waits:
        in al, dx
        and al, 0x88
        cmp al, 0x08
        jnz .waits                         ;位7为0且位3为1，表明硬盘不忙，且硬盘已经准备好数据传输

        mov cx, 256                        ;总共要读取的次数，要读取一个扇区，一个扇区512字节，每次读取2个字节，所以需要读取256次
        mov dx, 0x1f0
  .readw
        in ax, dx
        mov [bx], ax
        add bx, 2
        loop .readw

        pop dx
        pop cx
        pop dx
        pop ax

        ret
;------------------------------------------------------------------------------------
calc_segment_base:                          ;计算用户程序入口点的16位段基地址
                                            ;输入：DX:AX = 用户程序入口点的32位汇编地址（相对于程序开头）
                                            ;返回：AX = 16位段基地址
       push dx

       add ax, [cs:phy_base]                ;如果有进位，则CF进位标志位为1
       adc dx, [cs:phy_base+0x02]           ;adc，除了正常的加法，还要加上执行该指令时FLAGS寄存器中进位标志位(CF)的值
       shr ax, 4                            ;逻辑右移指令
       ror dx, 4                            ;循环右移指令，将dx低四位(入口点汇编地址的高4位)移动到dx高四位
       and dx, 0xf000                       ;取dx高四位
       or  ax, dx                           ;用户程序入口点的16位段基地址

       pop dx

       ret
;====================================================================================

;====================================================================================
        phy_base dd 0x10000

        times 510-($-$$) db 0
        db 0x55, 0xAA
