# 工具链
AS = nasm
CC = i686-elf-gcc
LD = i686-elf-ld
OBJCOPY = i686-elf-objcopy

CFLAGS = -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector
LDFLAGS = -T kernel.ld -nostdlib

# 文件名
BOOT_BIN = boot.bin
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
OS_IMAGE = os-image

# 所有目标
all: $(OS_IMAGE)

# 汇编 bootloader（实模式+保护模式跳转）
$(BOOT_BIN): boot.asm
	$(AS) -f bin boot.asm -o $(BOOT_BIN)

# 汇编 ISR 中断处理代码
isr.o: isr.asm
	$(AS) -f elf isr.asm -o isr.o

# 编译内核 C 代码
kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

# 链接内核
$(KERNEL_ELF): kernel.o isr.o
	$(LD) $(LDFLAGS) -o $(KERNEL_ELF) kernel.o isr.o

# 转换为裸机二进制格式
$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $(KERNEL_ELF) $(KERNEL_BIN)

# 拼接 bootloader + kernel 成完整磁盘映像
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMAGE)

# 启动 QEMU 虚拟机运行系统
run: $(OS_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),index=0,if=floppy

# 清理构建生成的文件
clean:
	rm -f *.bin *.img *.o *.elf os-image

.PHONY: all clean run
