;=============================================================================
SECTION header vstart=0                                            ;定义用户程序头部段
    program_length  dd program_end                                 ;程序总长度[0x00]

    ;用户程序入口点
    code_entry      dw start                                       ;程序入口点代码段的偏移地址[0x04]
                    dd section.code.start                          ;程序入口点代码段地址[0x06](入口点代码段地址就是代码段内第一个元素的汇编地址，它是相对于整个程序开头(0)的)

    realloc_tbl_len dw (header_end-code_segment)/4                 ;段重定位表项个数[0x0a]


    ;段重定位表
    code_segment  dd section.code.start                            ;[0x0c]
    data_segment  dd section.data.start                            ;[0x10]
    stack_segment  dd section.stack.start                          ;[0x14]

    header_end:

;=============================================================================
SECTION code align=16 vstart=0                                     ;定义代码段（16字节对齐）

  start:
       ;初始执行时，DS和ES指向用户程序头部段，CS指向当前代码段
       mov ax, [stack_segment]
       mov ss, ax
       mov sp, stack_pointer                                       ;设置初始的栈顶指针，等同于 mov sp, 256 ，因为给栈段预留了256字节的空间

       mov ax, [data_segment]                                      ;设置DS指向用户程序自己的数据段
       mov ds, ax                                                  ;必须要在完成所有的准备工作之后，才切换DS指向用户程序自己的数据段，
                                                                   ;因为上面的准备工作都需要用到用户程序头部段的数据

       mov ax, 0xb800                                              ;设置ES指向显存
       mov es, ax

       mov si, message
       mov di, 0

  next:
       mov al, [si]
       cmp al, 0
       je exit
       mov byte [es:di], al
       mov byte [es:di+1], 0x07
       inc si
       add di, 2
       jmp next

  exit:
       jmp $
;=============================================================================
SECTION data align=16 vstart=0                                     ;定义数据段（16字节对齐）
       message        db 'hello world.', 0

;=============================================================================
SECTION stack align=16 vstart=0                                    ;定义栈段（16字节对齐）
                       resb 256
       stack_pointer:

;=============================================================================
SECTION trail align=16                                             ;定义尾部段（16字节对齐）
program_end:
