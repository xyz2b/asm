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
      mov dx, 0x3d4
      mov al, 0x0e
      out dx, al
      mov dx, 0x3d5
      in al, dx                                                      ;光标的高8位
      mov ah, al

      mov dx, 0x3d4
      mov al, 0x0f
      out dx, al
      mov dx, 0x3d5
      in al, dx                                                      ;光标的低8位
      mov bx, ax                                                     ;BX=代表光标位置的16位数

      cmp cl, 0x0d                                                   ;回车符？
      jnz .put_0a
      mov bl, 80                                                     ;计算光标在当前行行首时的位置数值
      mov ax, bx
      div bl
      mul bl
      mov bx, ax                                                     ;BX=光标处于当前行首时的位置数值
      jmp .set_cursor                                                ;设置光标位置


  .put_0a:
      cmp cl, 0x0a                                                   ;换行符？
      jnz .put_other                                                 ;普通字符
      add bx, 80                                                     ;计算光标在下一行当前列时的位置数值
      jmp .roll_screen                                               ;判断光标位置是否超界，超界需要滚屏


  .put_other:
      mov ax, 0x8b00
      mov es, ax
      shl bx, 1                                                      ;将bx左移一位，即乘以2，因为bx是光标的当前位置，
      mov [es:bx], cl                                                ;但是一个字符在显存中需要占用两个字节，所以将当前光标位置（即当前字符需要在屏幕中显示的位置）乘以2，即得到屏幕中显示的位置在显存中对应的位置
      mov byte [es:bx+1], 0x07

      ;以下将光标位置推进一个字符
      shr bx, 1                                                      ;bx此时是上面显示字符在显存中的内存地址，要转换为屏幕中的光标位置，需要除以2
      inc bx                                                         ;光标向后移动一格


  .roll_screen:
      cmp bx, 2000                                                   ;光标超出屏幕需要滚屏？
      jl .set_cursor                                                 ;光标没有越界，就设置光标
                                                                     ;如果光标越界，就不会跳转，就顺序往下执行，进行滚屏
      ;将第二行开始到最后一行的数据，移动到从第一行开始的位置
      push bx
      mov ax,0xb800
      mov ds,ax
      mov es,ax
      cld
      mov si,0xa0                      ;第二行开始的位置对应在显存中的偏移量
      mov di,0x00                      ;第一行开始的位置对应在显存中的偏移量
      mov cx,1920                      ;需要移动的字符数，需要移动的字节数为其乘以2，因为一个字符在显存中占两个字节，所以下面直接用movsw，一次移动一个字，即不需要乘以2了
      rep movsw

      ;清除屏幕最后一行
      mov bx,3840                      ;最后一行开始的位置对应在显存中的偏移量
      mov cx,80                        ;一行总共80个字符
 .cls:
      mov word[es:bx],0x0720           ;黑底白字的空格
      add bx,2
      loop .cls

      ;将光标设置为最后一行开始的位置
      ;mov bx,1920                     ;滚屏之后，不能直接将光标位置设置为最后一行的起始位置，因为如果是换行符的话，光标最后应该停留在最后一行对应到光标此时所在列的位置，而不一定是行首位置
      pop bx                           ;上面使用push bx，保存光标最后应该停留的位置（1.显示一个字符之后的光标位置，2.换行之后的光标位置），这里pop弹出恢复
      sub bx, 80                       ;减80，正好将超出屏幕的一行减去，将光标挪到最后一行对应位置

  .set_cursor:
     mov dx, 0x3d4
     mov al, 0x0e
     out dx, al
     mov dx, 0x3d5
     mov al, bh
     out dx, al

     mov dx, 0x3d4
     mov al, 0x0f
     out dx, al
     mov dx, 0x3d5
     mov al, bl
     out dx, al

     pop es
     pop ds
     pop dx
     pop cx
     pop bx
     pop ax

     ret
;-----------------------------------------------------------------------------
  start:
       ;初始执行时，DS和ES指向用户程序头部段，CS指向当前代码段
       mov ax, [stack_segment]
       mov ss, ax
       mov sp, stack_pointer                                       ;设置初始的栈顶指针，等同于 mov sp, 256 ，因为给栈段预留了256字节的空间

       mov ax, [data_1_segment]                                    ;设置DS指向用户程序自己的数据段1(data_1)
       mov ds, ax                                                  ;必须要在完成所有的准备工作之后，才切换DS指向用户程序自己的数据段，
                                                                   ;因为上面的准备工作都需要用到用户程序头部段的数据
       mov bx, msg0
       call put_string                                             ;显示第一段信息

       ;ES此时还是指向用户程序头部段
       push word [es:code_2_segment]                               ;向栈中压入code_2代码段的段地址
       mov ax, begin
       push ax                                                     ;向栈中压入code_2代码段的偏移地址
       retf                                                        ;从栈中弹出偏移地址到IP，弹出段地址到CS，从而跳到code_2执行

  continue:
       mov ax, [es:data_2_segment]                                 ;设置DS指向用户程序自己的数据段2(data_2)
       mov ds, ax

       mov bx, msg1                                                ;显示第二段信息
       call put_string

       jmp $
;=============================================================================
SECTION code_2 align=16 vstart=0                                     ;定义代码段2（16字节对齐）
  begin:
       push word [es:code_1_segment]                                 ;向栈中压入code_1代码段的段地址
       mov ax, continue
       push ax                                                       ;向栈中压入code_1代码段的偏移地址
       retf                                                          ;从栈中弹出偏移地址到IP，弹出段地址到CS，从而跳到code_1执行

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
