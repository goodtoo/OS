all: os-image

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

os-image: boot.bin
	cp boot.bin os-image

run: os-image
	qemu-system-i386 -drive format=raw,file=os-image,index=0,if=floppy

clean:
	rm -f *.bin *.img *.o *.elf os-image
