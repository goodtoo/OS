// kernel.c

typedef unsigned char  uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int   uint32_t;

void kernel_main() {
    volatile uint16_t* video_memory = (uint16_t*)0xB8000;
    const char* message = "Hello from kernel!";
    uint16_t color = 0x0F00; // 黑底白字（高字节属性）

    for (int i = 0; message[i] != '\0'; i++) {
        video_memory[i] = (color | message[i]);
    }

    // 死循环，等待中断等事件
    while (1) {
        __asm__ volatile ("hlt");
    }
}
