mov ax, 0xb800
mov ds, ax

mov byte [0x00], 0x41                   ;字符A的ASCII编码
mov byte [0x01], 0x04                   ;黑底红字，无闪烁

mov byte [0x02], 's'
mov byte [0x03], 0x04

mov byte [0x02], 's'
mov byte [0x03], 0x04

mov byte [0x02], 'e'
mov byte [0x03], 0x04

mov byte [0x02], 'm'
mov byte [0x03], 0x04

mov byte [0x02], 'b'
mov byte [0x03], 0x04

mov byte [0x02], 'l'
mov byte [0x03], 0x04

mov byte [0x02], 'y'
mov byte [0x03], 0x04

mov byte [0x02], '.'
mov byte [0x03], 0x04

times 510-0x5f db 0                  ;db位指令: 填充一个字节的数据，值为0                                     ;times位指令: 重复后面的位指令"db 0" 多少次

db 0x55, 0xAA                        ;有效的主引导扇区（512字节，不够需要填充）其最后的数据必须是十六进制的55和AA，否则主引导扇区就是无效的


