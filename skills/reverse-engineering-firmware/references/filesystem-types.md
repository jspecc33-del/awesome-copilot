# Firmware Filesystem Types Reference

Quick identification and extraction guide for embedded Linux filesystem formats.

## Identification

```bash
# Binwalk identifies most automatically
binwalk <firmware.bin>

# Manual magic bytes
hexdump -C <firmware.bin> | head -4
```

| Format | Magic Bytes | Hex Offset | Tool |
|--------|------------|------------|------|
| SquashFS | `sqsh` / `hsqs` | 0x00 | `unsquashfs` |
| JFFS2 | `0x1985` (BE) / `0x8519` (LE) | 0x00 | `jefferson` / mtd-utils |
| CramFS | `0x28cd3d45` | 0x00 | `mount -t cramfs` |
| UBIFS | `0x31181006` | 0x00 | `ubireader_extract_files` |
| ext2/3/4 | `0xEF53` | 0x438 | `mount -o loop` |
| YAFFS2 | `0x03` | 0x00 | `unyaffs` |

## SquashFS

Most common in consumer routers (OpenWrt, DD-WRT, stock firmware).

```bash
# Extract
unsquashfs -d output/squashfs-root <squashfs.img>

# With alternate block size (some vendors use non-standard)
unsquashfs -b 65536 -d output/squashfs-root <squashfs.img>

# If standard unsquashfs fails, try sasquatch (handles vendor modifications)
sasquatch <squashfs.img>
```

**Variants to watch for:**
- Little-endian vs big-endian (MIPS = BE, ARM = LE typically)
- Non-standard compression: LZMA, LZO, ZSTD (require patched unsquashfs)
- Vendor-modified magic bytes (some Broadcom/Mediatek firmware)

## JFFS2

Common in older routers and embedded NOR flash devices.

```bash
# Method 1: jefferson (recommended)
pip3 install jefferson
jefferson -d output/jffs2-root <jffs2.img>

# Method 2: mtd-utils (requires kernel modules)
modprobe mtdram total_size=131072 erase_size=256
modprobe mtdblock
dd if=<jffs2.img> of=/dev/mtd0
mkdir /mnt/jffs2
mount -t jffs2 /dev/mtdblock0 /mnt/jffs2

# Unmount
umount /mnt/jffs2
rmmod mtdblock mtdram
```

## CramFS

Read-only compressed filesystem, older embedded devices.

```bash
# Mount directly
mkdir /mnt/cramfs
mount -t cramfs -o loop <cramfs.img> /mnt/cramfs

# Extract with cramfsck
cramfsck -x output/cramfs-root <cramfs.img>
```

## UBIFS (NAND flash)

Modern routers with NAND flash (OpenWrt 18+, enterprise devices).

```bash
pip3 install ubireader

# Extract from UBI image
ubireader_extract_images <ubi.img>
ubireader_extract_files <ubi.img>

# Or from raw NAND dump with UBI headers
ubireader_extract_files -o output/ubifs-root <nand-dump.bin>
```

## Encrypted Firmware

High entropy (>0.95) throughout = likely encrypted. Approaches:

1. **Check older firmware** — vendors sometimes introduced encryption in later versions; extract key/IV from older unencrypted version.
2. **Find update scripts** — `/etc/init.d/`, startup scripts may call decrypt utility with hardcoded key.
3. **UART/JTAG** — dump decrypted firmware directly from running device memory.
4. **Bootloader** — U-Boot environment may contain encryption key or decrypt before loading kernel.
5. **Binary diff** — compare encrypted and unencrypted versions to locate decrypt routine.
