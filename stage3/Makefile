all: 

$(BOOT_BIN): boot.asm
	$(AS) -f bin boot.asm -o $(BOOT_BIN)

# 2. 汇编 isr.asm 为目标文件
isr.o: isr.asm
	$(AS) -f elf isr.asm -o isr.o

# 3. 编译 kernel.c 为 kernel.o
kernel.o: kernel.c
	$(CC) $(CFLAGS) -c kernel.c -o kernel.o

# 4. 链接生成 kernel.elf
$(KERNEL_ELF): $(OBJ)
	$(LD) $(LDFLAGS) -o $(KERNEL_ELF) $(OBJ)

# 5. 提取纯二进制 kernel.bin
$(KERNEL_BIN): $(KERNEL_ELF)
	objcopy -O binary $(KERNEL_ELF) $(KERNEL_BIN)

# 6. 拼接 bootloader 和内核为完整映像
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMAGE)

# 7. QEMU 启动系统
run: $(OS_IMAGE)
	qemu-system-i386 -drive format=raw,file=$(OS_IMAGE),index=0,if=floppy

# 8. 清理所有中间文件
clean:
	rm -f *.o *.bin *.elf $(OS_IMAGE)

.PHONY: all run clean
