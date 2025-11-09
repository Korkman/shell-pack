#!/bin/sh
{
	# Creates test files for qmount testing
	set -eu
	
	IMGDIR="./test-qmount-files"
	FILE_NTFS="$IMGDIR/test-ntfs.dd"
	FILE_CRYPTO="$IMGDIR/test-crypto.dd"
	
	mkdir -p "$IMGDIR"
	rm -f "$FILE_NTFS" "$FILE_CRYPTO"
	
	dd if=/dev/zero "of=$FILE_NTFS" bs=1M seek=100 count=1
	LOOP_NTFS=$(losetup -f --show "$FILE_NTFS")
	parted "$LOOP_NTFS" mklabel msdos mkpart primary ntfs 1MiB 100% set 1 boot on
	partprobe "$LOOP_NTFS"
	mkfs.ntfs --quick "${LOOP_NTFS}p1"
	losetup -d "$LOOP_NTFS"
	
	echo "password" > "$IMGDIR/keyfile.bin"
	
	dd if=/dev/zero "of=$FILE_CRYPTO" bs=1M seek=100 count=1
	LOOP_CRYPTO=$(losetup -f --show "$FILE_CRYPTO")
	parted "$LOOP_CRYPTO" mklabel msdos mkpart primary 1MiB 100%
	cryptsetup luksFormat "$LOOP_CRYPTO" --iter-time 100 --batch-mode < "$IMGDIR/keyfile.bin"
	cryptsetup luksOpen "$LOOP_CRYPTO" qmountTestCrypt < "$IMGDIR/keyfile.bin"
	losetup -d "$LOOP_CRYPTO" # mark for autoclear
	pvcreate /dev/mapper/qmountTestCrypt
	vgcreate qmountTestCryptVG /dev/mapper/qmountTestCrypt
	lvcreate -L 50M -n qmountTestCryptLV qmountTestCryptVG
	parted /dev/qmountTestCryptVG/qmountTestCryptLV mklabel gpt mkpart primary 1MiB 50% mkpart primary 50% 100%
	mkfs.ext4 /dev/mapper/qmountTestCryptVG-qmountTestCryptLV1
	mkfs.ext4 /dev/mapper/qmountTestCryptVG-qmountTestCryptLV2
	#lvcreate --snapshot --name qmountTestCryptLV3 --size 10M qmountTestCryptVG/qmountTestCryptLV
	kpartx -d /dev/mapper/qmountTestCryptVG-qmountTestCryptLV
	vgchange -an qmountTestCryptVG
	cryptsetup luksClose qmountTestCrypt
	
	exit
}
