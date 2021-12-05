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
        mov ds, ax                               ;令DS和ES指向该段用于操作用户程序
        mov es, ax

        ;读取程序起始部分


;====================================================================================

;====================================================================================
        phy_base dd 0x10000

        times 510-($-$$) db 0
        db 0x55, 0xAA
