#!/usr/bin/env bash
# Firmware initial triage — Phase 1 of reverse-engineering-firmware skill
# Usage: analyze.sh <firmware.bin> [output-dir]
set -euo pipefail

FIRMWARE="${1:-}"
OUT="${2:-output}"

if [[ -z "$FIRMWARE" || ! -f "$FIRMWARE" ]]; then
  echo "Usage: $0 <firmware.bin> [output-dir]" >&2
  exit 1
fi

mkdir -p "$OUT"
echo "[*] Analyzing: $FIRMWARE"
echo "[*] Output:    $OUT"

# --- File type ---
echo "\n=== FILE TYPE ==" > "$OUT/binwalk-report.txt"
file "$FIRMWARE" | tee -a "$OUT/binwalk-report.txt"

# --- Binwalk signature scan ---
echo "\n=== BINWALK SIGNATURES ===" >> "$OUT/binwalk-report.txt"
binwalk "$FIRMWARE" | tee -a "$OUT/binwalk-report.txt"

# --- Entropy analysis ---
echo "\n=== ENTROPY ANALYSIS ===" >> "$OUT/binwalk-report.txt"
binwalk -E "$FIRMWARE" 2>&1 | tee -a "$OUT/binwalk-report.txt"
echo "[!] If entropy >0.95 throughout, firmware may be encrypted."

# --- Architecture detection from ELF headers ---
echo "\n=== ARCHITECTURE DETECTION ===" >> "$OUT/binwalk-report.txt"
binwalk -A "$FIRMWARE" 2>&1 | head -40 | tee -a "$OUT/binwalk-report.txt"

# --- String extraction ---
echo "\n=== KEY STRINGS (passwords/keys/ips) ===" >> "$OUT/binwalk-report.txt"
strings "$FIRMWARE" | grep -iE \
  'password|passwd|secret|token|api.?key|private.?key|admin|root|192\.168|10\.0\.0|telnet|ssh|backdoor' \
  | sort -u | head -100 | tee -a "$OUT/binwalk-report.txt"

echo "\n[+] Report written to $OUT/binwalk-report.txt"
echo "[*] Next: binwalk -e -M --run-as=root '$FIRMWARE' -C '$OUT/extracted/'"
