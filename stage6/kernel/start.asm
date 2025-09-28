; kernel/start.asm �� �̶��� 32-bit �ں���ڣ�ȷ��λ�� 0x1000
[BITS 32]
GLOBAL kernel_entry
EXTERN kernel_main

SECTION .text.start
kernel_entry:
    ; ��ѡ������һ�����Ա��
    mov word [0xB8000 + 80*4*2 + 0], 0x0F45    ; 'E'
    mov word [0xB8000 + 80*4*2 + 2], 0x0F4E    ; 'N'
    mov word [0xB8000 + 80*4*2 + 4], 0x0F54    ; 'T'  => �ڵ�5�п�ͷ��ʾ "ENT"

    call kernel_main

.hang:
    hlt
    jmp .hang
