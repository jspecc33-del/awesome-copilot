# QEMU Firmware Emulation Guide

Full guide for emulating extracted IoT firmware using QEMU user-mode and system-mode emulation.

## Architecture Detection

```bash
# From ELF binaries in extracted filesystem
file extracted/bin/busybox
# Example output: ELF 32-bit MSB executable, MIPS, MIPS32 rel2 version 1

# From binwalk
binwalk -A <firmware.bin> | head -20

# From kernel image
strings extracted/boot/vmlinuz* 2>/dev/null | grep 'Linux version'
```

| Architecture | `file` output | QEMU binary |
|-------------|---------------|-------------|
| MIPS 32-bit BE | `MIPS, MIPS32` | `qemu-mips-static` |
| MIPS 32-bit LE | `MIPS, MIPS32 (rel2)` + `LSB` | `qemu-mipsel-static` |
| ARM 32-bit | `ARM, EABI5` | `qemu-arm-static` |
| ARM 64-bit | `ARM aarch64` | `qemu-aarch64-static` |
| x86 32-bit | `Intel 80386` | `qemu-i386-static` |
| x86 64-bit | `x86-64` | `qemu-x86_64-static` |

## Method 1: QEMU User-Mode (Chroot)

Best for: running individual binaries and services. Simpler setup.

```bash
# Install
apt-get install -y qemu-user-static

# Copy QEMU into extracted filesystem
cp /usr/bin/qemu-mips-static extracted/usr/bin/

# Mount pseudo-filesystems
mount -t proc /proc extracted/proc
mount -t sysfs /sys extracted/sys
mount --bind /dev extracted/dev
mount --bind /dev/pts extracted/dev/pts

# Chroot
chroot extracted/ /bin/sh

# Inside chroot — test binaries
/bin/busybox sh
/usr/sbin/httpd -p 8080 -h /www
```

## Method 2: QEMU System-Mode (Full Emulation)

Best for: network-level testing, boot sequence analysis, multi-service environments.

### MIPS Router (most common)

```bash
# Install system emulator
apt-get install -y qemu-system-mips

# Download a compatible kernel (OpenWrt works well for most routers)
wget https://downloads.openwrt.org/releases/22.03.5/targets/malta/be/openwrt-22.03.5-malta-be-vmlinux.elf

# Create disk image from extracted filesystem
cd extracted/
find . | cpio -o --format=newc | gzip > ../rootfs.cpio.gz
cd ..

# Boot
qemu-system-mips \
  -M malta \
  -kernel openwrt-22.03.5-malta-be-vmlinux.elf \
  -initrd rootfs.cpio.gz \
  -append "root=/dev/ram console=ttyS0" \
  -nographic \
  -net nic \
  -net user,hostfwd=tcp::8080-:80,hostfwd=tcp::8023-:23
```

### ARM Router

```bash
apt-get install -y qemu-system-arm

qemu-system-arm \
  -M vexpress-a9 \
  -kernel vmlinuz-arm \
  -initrd rootfs.cpio.gz \
  -append "root=/dev/ram console=ttyAMA0" \
  -nographic \
  -net nic \
  -net user,hostfwd=tcp::8080-:80
```

## Network Access

```bash
# Port forwarding (user-mode networking)
-net user,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443,hostfwd=tcp::8023-:23

# After boot, test services from host
curl http://localhost:8080/          # Web interface
telnet localhost 8023                # Telnet
ssh root@localhost -p 8022          # SSH
```

## FirmAE (Automated Emulation)

FirmAE automates the full emulation workflow for consumer routers:

```bash
git clone --recursive https://github.com/pr0v3rbs/FirmAE
cd FirmAE
./download.sh
./install.sh

# Emulate firmware automatically
./run.sh -r <brand> <firmware.bin>

# Check if emulation succeeded
./run.sh -a <brand> <firmware.bin>
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Exec format error` | Wrong QEMU binary for arch | Check `file` output, use correct QEMU |
| `No such file or directory` on valid path | Missing shared library | `chroot extracted/ ldd /path/to/binary` |
| Web server starts but returns 404 | Wrong webroot path | Check httpd config in `/etc/httpd.conf` or init script |
| Kernel panic in system mode | Incompatible kernel | Try OpenWrt kernel matching device architecture |
| Network unreachable in chroot | No network in chroot | Use `ip netns` or system-mode QEMU instead |

## Post-Emulation Testing

```bash
# Web interface enumeration
curl -v http://localhost:8080/
curl -v http://localhost:8080/cgi-bin/
nmap -sV -p 8080 localhost

# Authentication testing
curl -u admin:admin http://localhost:8080/
curl -u admin:password http://localhost:8080/
curl -u root:root http://localhost:8080/

# Check for command injection in web interface
curl -X POST http://localhost:8080/apply.cgi \
  --data 'action=ping&host=127.0.0.1;id'

# Capture network traffic
tcpdump -i any -w firmware-traffic.pcap &
# ... trigger device actions ...
kill %1
wireshark firmware-traffic.pcap
```
