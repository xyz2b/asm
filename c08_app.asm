;=============================================================================
SECTION header vstart=0                                            ;定义用户程序头部段
    program_length  dd program_end                                 ;程序总长度[0x00]

    ;用户程序入口点
    code_entry      dw start                                       ;程序入口点代码段的偏移地址[0x04]
                    dd section.code_1.start                          ;程序入口点代码段地址[0x06](入口点代码段地址就是代码段内第一个元素的汇编地址，它是相对于整个程序开头(0)的)

    realloc_tbl_len dw (header_end-code_1_segment)/4                 ;段重定位表项个数[0x0a]


    ;段重定位表
    code_1_segment  dd section.code_1.start                            ;[0x0c]
    code_2_segment  dd section.code_2.start                            ;[0x10]
    data_1_segment  dd section.data_1.start                          ;[0x14]
    data_2_segment  dd section.data_2.start                          ;[0x18]
    stack_segment   dd section.stack.start                           ;[0x1c]

    header_end:

;=============================================================================
SECTION code_1 align=16 vstart=0                                     ;定义代码段1（16字节对齐）
  put_string:                                                        ;显示串(0结尾)
                                                                     ;输入：DS:BX = 串地址
      mov cl, [bx]
      or cl, cl                                                      ;判断cl是否等于0(即判断是否是字符串结束标志)，or指令操作同一个寄存器比cmp更高效，同时它也会影响ZF(零标志位)标志位（该条指令在功能上等同于 cmp cl, 0）
      jz .exit                                                       ;遇到了字符串结束字符0，退出当前子过程
      call put_char
      inc bx                                                         ;下个字符
      jmp put_string

    .exit:
      ret
;-----------------------------------------------------------------------------
  put_char:                                                          ;显示一个字符
                                                                     ;输入：cl = 字符ASCII
      push ax
      push bx
      push cx
      push dx
      push ds
      push es

      ;以下取当前光标位置

;-----------------------------------------------------------------------------
  start:
       ;初始执行时，DS和ES指向用户程序头部段，CS指向当前代码段
       mov ax, [stack_segment]
       mov ss, ax
       mov sp, stack_pointer                                       ;设置初始的栈顶指针，等同于 mov sp, 256 ，因为给栈段预留了256字节的空间

       mov ax, [data_1_segment]                                      ;设置DS指向用户程序自己的数据段
       mov ds, ax                                                  ;必须要在完成所有的准备工作之后，才切换DS指向用户程序自己的数据段，
                                                                   ;因为上面的准备工作都需要用到用户程序头部段的数据
       mov bx, msg0
       call put_string                                             ;显示第一段信息

  exit:
       jmp $
;=============================================================================
SECTION code_2 align=16 vstart=0                                     ;定义代码段2（16字节对齐）


;===============================================================================
SECTION data_1 align=16 vstart=0

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. '
         db '2011-05-06'
         db 0

;=============================================================================
SECTION stack align=16 vstart=0                                    ;定义栈段（16字节对齐）
                       resb 256
       stack_pointer:

;=============================================================================
SECTION trail align=16                                             ;定义尾部段（16字节对齐）
program_end:
