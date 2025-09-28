AS       = nasm
CC       = gcc
LD       = ld
OBJCOPY  = objcopy

CFLAGS    = -m32 -ffreestanding -nostdlib -fno-pie -fno-stack-protector
LDFLAGS   = -T kernel.ld -nostdlib -m elf_i386
ASFLAGS32 = -f elf32

BOOT_BIN   = boot/boot.bin
KERNEL_ELF = kernel/kernel.elf
KERNEL_BIN = kernel/kernel.bin
OS_IMAGE   = os-image

# 允许从命令行覆盖 QEMUFLAGS，例如：make run QEMUFLAGS="-no-reboot"
QEMUFLAGS ?=

all: $(OS_IMAGE)

# -------------------------
# 内核构建
# -------------------------
kernel/start.o: kernel/start.asm
	$(AS) $(ASFLAGS32) $< -o $@

kernel/isr.o: kernel/isr.asm
	$(AS) $(ASFLAGS32) $< -o $@

kernel/idt.o: kernel/idt.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/kernel.o: kernel/kernel.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/sched.o: kernel/sched.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel/pmm.o: kernel/pmm.c
	$(CC) $(CFLAGS) -c $< -o $@

# 只保留这一条链接规则：把 sched.o 纳入，并保证 start.o 在最前
$(KERNEL_ELF): kernel/start.o kernel/kernel.o kernel/sched.o kernel/idt.o kernel/isr.o kernel/pmm.o
	$(LD) $(LDFLAGS) -o $@ $^

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

# -------------------------
# Bootloader
# -------------------------
$(BOOT_BIN): boot/boot.asm $(KERNEL_BIN)
	@set -e; \
	size=$$(wc -c < $(KERNEL_BIN)); \
	secs=$$(( (size + 511) / 512 )); \
	echo "[INFO] kernel.bin = $$size bytes, $$secs sectors"; \
	rm -f $(BOOT_BIN); \
	nasm -f bin boot/boot.asm -o $(BOOT_BIN) -DKERNEL_SECTORS=$$secs -Wall -Werror -l boot/boot.lst; \
	if [ ! -s $(BOOT_BIN) ]; then echo "[ERROR] boot.bin is empty"; exit 1; fi; \
	if [ $$(wc -c < $(BOOT_BIN)) -ne 512 ]; then echo "[ERROR] boot.bin must be 512 bytes"; exit 1; fi; \
	sig=$$(dd if=$(BOOT_BIN) bs=1 skip=510 count=2 2>/dev/null | od -An -tx1 | tr -d ' \n'); \
	if [ "$$sig" != "55aa" ]; then echo "[ERROR] boot.bin missing 0x55AA (got $$sig)"; exit 1; fi

# -------------------------
# 镜像拼接
# -------------------------
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $(OS_IMAGE)

# -------------------------
# 运行 & 清理
# -------------------------
run: $(OS_IMAGE)
	qemu-system-i386 -fda $(OS_IMAGE) -boot a -serial stdio $(QEMUFLAGS)

clean:
	rm -f boot/*.bin boot/boot.lst kernel/*.o kernel/*.elf kernel/*.bin $(OS_IMAGE)

.PHONY: all run clean

