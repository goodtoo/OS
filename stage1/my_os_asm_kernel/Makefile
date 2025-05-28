all: os-image

boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot.bin

kernel.bin: kernel/kernel.asm
	nasm -f bin kernel/kernel.asm -o kernel.bin

kernel.pad: kernel.bin
	dd if=kernel.bin of=kernel.pad bs=512 count=8 conv=notrunc

os-image: boot.bin kernel.pad
	cat boot.bin kernel.pad > os-image

run: os-image
	qemu-system-i386 -drive format=raw,file=os-image,index=0,if=floppy

clean:
	rm -f *.bin *.pad os-image
