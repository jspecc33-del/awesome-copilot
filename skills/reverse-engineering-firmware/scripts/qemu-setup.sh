#!/usr/bin/env bash
# QEMU emulation setup for extracted firmware filesystem
# Usage: qemu-setup.sh <extracted-root> <architecture>
# Architectures: mips mipsel arm armhf arm64 x86 x86_64
set -euo pipefail

ROOT="${1:-}"
ARCH="${2:-mips}"

if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "Usage: $0 <extracted-root> <architecture>" >&2
  exit 1
fi

declare -A QEMU_BINS=(
  [mips]="qemu-mips-static"
  [mipsel]="qemu-mipsel-static"
  [arm]="qemu-arm-static"
  [armhf]="qemu-arm-static"
  [arm64]="qemu-aarch64-static"
  [x86]="qemu-i386-static"
  [x86_64]="qemu-x86_64-static"
)

QEMU_BIN="${QEMU_BINS[$ARCH]:-}"
if [[ -z "$QEMU_BIN" ]]; then
  echo "[!] Unknown architecture: $ARCH" >&2
  echo "[!] Supported: ${!QEMU_BINS[*]}" >&2
  exit 1
fi

QEMU_PATH="/usr/bin/$QEMU_BIN"
if [[ ! -f "$QEMU_PATH" ]]; then
  echo "[!] QEMU binary not found: $QEMU_PATH" >&2
  echo "[!] Install with: apt-get install qemu-user-static" >&2
  exit 1
fi

echo "[*] Setting up QEMU $ARCH emulation for $ROOT"

# Copy QEMU static binary into filesystem
mkdir -p "$ROOT/usr/bin"
cp "$QEMU_PATH" "$ROOT/usr/bin/$QEMU_BIN"
echo "[+] Copied $QEMU_BIN into $ROOT/usr/bin/"

# Mount required pseudo-filesystems
for mountpoint in proc sys dev dev/pts; do
  mkdir -p "$ROOT/$mountpoint"
done

mount -t proc /proc "$ROOT/proc" 2>/dev/null || true
mount -t sysfs /sys "$ROOT/sys" 2>/dev/null || true
mount --bind /dev "$ROOT/dev" 2>/dev/null || true
mount --bind /dev/pts "$ROOT/dev/pts" 2>/dev/null || true

echo "[+] Pseudo-filesystems mounted"
echo ""
echo "=== QEMU Chroot Ready ==="
echo "Run: chroot '$ROOT' /bin/sh"
echo ""
echo "=== Common next steps ==="
echo "  # Start web server"
echo "  chroot '$ROOT' /usr/sbin/httpd -p 8080 &"
echo "  curl http://localhost:8080/"
echo ""
echo "  # Start telnet daemon"
echo "  chroot '$ROOT' /usr/sbin/telnetd -l /bin/sh -p 9023 &"
echo "  telnet localhost 9023"
echo ""
echo "  # Check network interfaces inside chroot"
echo "  chroot '$ROOT' /sbin/ifconfig"
echo ""
echo "=== Cleanup ==="
echo "  umount '$ROOT/dev/pts' '$ROOT/dev' '$ROOT/sys' '$ROOT/proc'"
