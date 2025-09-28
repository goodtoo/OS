AS       = nasm
CC       = gcc
LD       = ld
OBJCOPY  = objcopy

CFLAGS   = -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector
LDFLAGS  = -T kernel.ld -nostdlib -m elf_i386
ASFLAGS_ELF32 = -f elf32

BOOT_BIN   = boot/boot.bin
KERNEL_ELF = kernel/kernel.elf
KERNEL_BIN = kernel/kernel.bin
OS_IMAGE   = os-image

all: $(OS_IMAGE)

kernel/isr.o: kernel/isr.asm
	$(AS) $(ASFLAGS_ELF32) $< -o $@

kernel/idt.o: kernel/idt.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/kernel.o: kernel/kernel.c
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL_ELF): kernel/kernel.o kernel/idt.o kernel/isr.o
	$(LD) $(LDFLAGS) -o $@ $^

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOT_BIN): boot/boot.asm $(KERNEL_BIN)
	@size=$$(wc -c < $(KERNEL_BIN)); \
	secs=$$(( (size + 511) / 512 )); \
	echo "[INFO] kernel.bin = $$size bytes, $$secs sectors"; \
	$(AS) -f bin $< -o $@ -DKERNEL_SECTORS=$$secs

$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMAGE)

run: $(OS_IMAGE)
	qemu-system-i386 -hda $(OS_IMAGE) -boot c -serial stdio

# 备选：硬盘启动（通常支持LBA，更稳）
run-hd: $(OS_IMAGE)
	qemu-system-i386 -hda $(OS_IMAGE) -boot c -serial stdio

clean:
	rm -f boot/*.bin kernel/*.o kernel/*.elf kernel/*.bin $(OS_IMAGE)

.PHONY: all run run-hd clean

