---
name: reverse-engineering-firmware
description: 'Use this skill to perform IoT firmware reverse engineering and security analysis. Trigger for prompts like "analyze this firmware", "extract filesystem from router firmware", "find hardcoded credentials in firmware", "emulate this IoT device", or "scan firmware for CVEs". Covers full workflow: acquisition, extraction, static analysis, credential harvesting, CVE scanning, and QEMU emulation.'
license: MIT
compatibility: 'Linux (Kali recommended). Requires binwalk, python3, squashfs-tools, jefferson, qemu-user-static, and firmwalker.'
metadata:
  version: '1.0.0'
  re_level: 5
  difficulty: Advanced
  timebox: '2-8 hours'
  category: 'IoT Security, Embedded Systems, Firmware Reverse Engineering'
  badges:
    - 'RE Level 5'
    - 'Firmware Analysis'
    - '⏱️ 2-8 hours'
  agents:
    - RE-Firmware-Analyst
    - security-manager
    - data-steward
  keywords:
    - firmware
    - binwalk
    - iot-security
    - router-analysis
    - embedded-systems
    - squashfs
    - jffs2
    - cramfs
    - qemu-emulation
    - cve-scanning
    - credential-extraction
    - vulnerability-assessment
argument-hint: 'Required: path to firmware binary. Optional: target architecture (mips/arm/x86), focus area (credentials|cve|emulation|all)'
---

# Reverse Engineering Firmware

Full IoT firmware security analysis: extract filesystems, harvest credentials, scan for CVEs, and emulate device behavior using QEMU. Only document findings traceable to actual firmware content — never assume or infer.

## Output Contract (Required)

Before finishing, all of the following must be true:

1. Binwalk analysis report exists at `output/binwalk-report.txt`.
2. Extracted filesystem is present at `output/extracted/`.
3. Credential findings documented in `output/credentials.txt` (empty if none found).
4. CVE scan results in `output/cve-report.txt`.
5. All hardcoded strings, keys, and certificates catalogued in `output/static-analysis.txt`.
6. Final summary includes architecture, OS, key findings, and recommended next steps.

## Workflow

Copy and track this checklist:

```
- [ ] Phase 1: Firmware acquisition and initial triage
- [ ] Phase 2: Extraction and filesystem identification
- [ ] Phase 3: Static analysis and credential harvesting
- [ ] Phase 4: CVE scanning and vulnerability assessment
- [ ] Phase 5: QEMU emulation (optional, if architecture supported)
- [ ] Phase 6: Report and recommendations
```

## Setup

Install required tools:

```bash
# Kali / Debian
apt-get install -y binwalk squashfs-tools jefferson qemu-user-static \
  qemu-system-arm qemu-system-mips firmwalker python3-pip
pip3 install cve-bin-tool

# Verify
binwalk --version
unsquashfs --version
```

## Phase 1: Firmware Acquisition and Triage

```bash
# Run the main analysis script
bash "$SKILL_ROOT/scripts/analyze.sh" <firmware.bin> [output-dir]
```

The script performs:
- File type identification (`file`, `binwalk -B`)
- Entropy analysis (`binwalk -E`) to detect compression/encryption
- String extraction for initial triage
- Architecture detection from ELF headers

If entropy is uniformly high (>0.95), the firmware may be **encrypted**. Check vendor documentation for decryption keys or look for update scripts in earlier firmware versions.

## Phase 2: Extraction and Filesystem Identification

Load [`references/filesystem-types.md`](references/filesystem-types.md) to identify the filesystem format.

```bash
# Automated extraction
binwalk -e -M --run-as=root <firmware.bin> -C output/extracted/

# Manual squashfs
unsquashfs -d output/squashfs-root output/extracted/_firmware.bin.extracted/*.squashfs

# Manual jffs2 (requires mtd-utils)
mkdir -p /tmp/jffs2-mount
modprobe mtdram total_size=65536 erase_size=256
modprobe mtdblock
dd if=<jffs2.img> of=/dev/mtd0
mount -t jffs2 /dev/mtdblock0 /tmp/jffs2-mount

# Manual cramfs
mount -t cramfs -o loop <cramfs.img> /mnt/cramfs
```

**Key directories to inspect after extraction:**

| Path | What to look for |
|------|------------------|
| `/etc/passwd`, `/etc/shadow` | Default credentials |
| `/etc/config/` | Device configuration |
| `/usr/sbin/`, `/bin/` | Binaries for further RE |
| `/etc/ssl/`, `/etc/certs/` | Hardcoded certificates/keys |
| `/www/`, `/htdocs/` | Web interface (XSS, auth bypass) |
| `/etc/init.d/` | Boot scripts, service config |

## Phase 3: Static Analysis and Credential Harvesting

```bash
# Run credential extractor
python3 "$SKILL_ROOT/scripts/extract-creds.py" output/extracted/ output/credentials.txt

# Manual string search
grep -rn 'password\|passwd\|secret\|api_key\|token\|private_key' output/extracted/ \
  --include='*.conf' --include='*.cfg' --include='*.xml' --include='*.json'

# Find SUID binaries
find output/extracted/ -perm -4000 -type f 2>/dev/null

# Find world-writable files
find output/extracted/ -perm -o+w -type f 2>/dev/null

# Extract certificates and keys
find output/extracted/ -name '*.pem' -o -name '*.crt' -o -name '*.key' \
  -o -name '*.p12' -o -name '*.der' 2>/dev/null
```

**Credential patterns to check:**
- Default admin passwords in `/etc/passwd` (look for non-`x` password field)
- Hardcoded credentials in init scripts
- Private keys in `/etc/ssl/` or `/etc/dropbear/`
- Telnet/SSH backdoor accounts
- API tokens in web interface files

## Phase 4: CVE Scanning

```bash
# Identify software versions
find output/extracted/ -name '*.so*' | xargs strings | grep -oP '[a-zA-Z]+[ /v]\d+\.\d+' | sort -u

# Run cve-bin-tool
cve-bin-tool output/extracted/ --format json -o output/cve-report.json 2>/dev/null
cve-bin-tool output/extracted/ -o output/cve-report.txt 2>/dev/null

# Firmwalker (comprehensive scan)
bash /usr/share/firmwalker/firmwalker.sh output/extracted/ output/firmwalker-report.txt

# Check busybox version
strings output/extracted/bin/busybox 2>/dev/null | grep -i 'busybox v'

# Check kernel version
strings output/extracted/lib/modules/*/modules.dep 2>/dev/null | head -5
```

Load [`references/cve-scanning.md`](references/cve-scanning.md) for component-specific scanning guidance.

## Phase 5: QEMU Emulation

Load [`references/emulation-guide.md`](references/emulation-guide.md) for full emulation setup.

```bash
# Setup QEMU environment
bash "$SKILL_ROOT/scripts/qemu-setup.sh" output/extracted/ <architecture>

# Common architectures: mips mipsel arm armel arm64 x86
# Example: MIPS router
bash "$SKILL_ROOT/scripts/qemu-setup.sh" output/extracted/ mips
```

**Quick emulation test:**

```bash
# Copy QEMU binary into extracted filesystem
cp /usr/bin/qemu-mips-static output/extracted/usr/bin/

# Chroot into filesystem
chroot output/extracted/ /bin/sh

# Test web server
chroot output/extracted/ /usr/sbin/httpd -p 8080
curl http://localhost:8080/
```

## Phase 6: Report

Produce `output/REPORT.md` with:

```markdown
## Firmware Analysis Report

### Target
- File: <firmware.bin>
- Size: <size>
- Architecture: <mips|arm|x86>
- OS: <linux|vxworks|threadx>
- Kernel: <version if found>

### Key Findings
| Severity | Finding | Evidence |
|----------|---------|----------|
| CRITICAL | Hardcoded root password | /etc/passwd line X |
| HIGH | Private SSH key exposed | /etc/dropbear/dropbear_rsa_host_key |
| HIGH | CVE-XXXX-XXXX in <component> | <binary> version X.Y.Z |
| MEDIUM | Telnet enabled by default | /etc/init.d/telnetd |

### Credentials Found
<list from output/credentials.txt>

### CVEs
<summary from output/cve-report.txt>

### Recommended Next Steps
1. Dynamic analysis via QEMU emulation
2. Binary exploitation of <vulnerable binary>
3. Network traffic capture during boot
4. Compare with newer firmware version
```

## Anti-Patterns

| ❌ Don't | ✅ Do instead |
|---------|---------------|
| Assume default creds work | Test them against actual device |
| Skip entropy analysis | Always check — encrypted firmware needs different approach |
| Only check `/etc/passwd` | Search all config files, scripts, and binaries |
| Report CVEs without version confirmation | Confirm binary version before reporting CVE |
| Emulate without chroot setup | Follow emulation-guide.md for proper environment |

## Bundled Assets

| Asset | When to use |
|-------|-------------|
| [`scripts/analyze.sh`](scripts/analyze.sh) | Phase 1 — run first for triage |
| [`scripts/extract-creds.py`](scripts/extract-creds.py) | Phase 3 — credential harvesting |
| [`scripts/qemu-setup.sh`](scripts/qemu-setup.sh) | Phase 5 — emulation setup |
| [`references/filesystem-types.md`](references/filesystem-types.md) | Phase 2 — filesystem ID |
| [`references/cve-scanning.md`](references/cve-scanning.md) | Phase 4 — CVE scanning guide |
| [`references/emulation-guide.md`](references/emulation-guide.md) | Phase 5 — QEMU emulation guide |
