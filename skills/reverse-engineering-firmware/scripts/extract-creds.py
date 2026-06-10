#!/usr/bin/env python3
"""Credential harvester for extracted firmware filesystems.
Usage: extract-creds.py <extracted-root> <output-file>
"""
import os
import re
import sys
import stat
from pathlib import Path

CRED_PATTERNS = [
    (r'password\s*[=:]\s*["\']?([^\s"\',;#]+)', 'password'),
    (r'passwd\s*[=:]\s*["\']?([^\s"\',;#]+)', 'passwd'),
    (r'secret\s*[=:]\s*["\']?([^\s"\',;#]+)', 'secret'),
    (r'api[_\-]?key\s*[=:]\s*["\']?([^\s"\',;#]+)', 'api_key'),
    (r'token\s*[=:]\s*["\']?([^\s"\',;#]+)', 'token'),
    (r'private[_\-]?key\s*[=:]\s*["\']?([^\s"\',;#]+)', 'private_key'),
]

PASSWD_PATTERN = re.compile(
    r'^([^:]+):([^:*!]+):(\d+):(\d+):([^:]*):([^:]*):(.*)$'
)

SKIP_DIRS = {'proc', 'sys', 'dev', 'run', 'tmp'}
SKIP_EXTS = {'.jpg', '.jpeg', '.png', '.gif', '.mp3', '.mp4', '.gz',
             '.zip', '.tar', '.bin', '.img', '.so', '.o', '.a'}


def scan_passwd(root: Path, findings: list):
    for passwd_file in ['etc/passwd', 'etc/shadow']:
        p = root / passwd_file
        if not p.exists():
            continue
        for line in p.read_text(errors='ignore').splitlines():
            m = PASSWD_PATTERN.match(line.strip())
            if m:
                user, pw = m.group(1), m.group(2)
                if pw not in ('x', '*', '!', '', 'X'):
                    findings.append({
                        'file': str(p.relative_to(root)),
                        'type': 'passwd-plaintext',
                        'detail': f'user={user} password_field={pw}',
                        'line': line.strip(),
                    })
                elif passwd_file == 'etc/passwd' and pw == 'x':
                    # shadow in use — note the account
                    findings.append({
                        'file': str(p.relative_to(root)),
                        'type': 'passwd-account',
                        'detail': f'user={user} (shadow in use)',
                        'line': line.strip(),
                    })


def scan_keys(root: Path, findings: list):
    key_globs = ['**/*.pem', '**/*.key', '**/*.crt', '**/*.p12',
                 '**/*.der', '**/id_rsa', '**/id_dsa', '**/id_ecdsa']
    for pattern in key_globs:
        for p in root.glob(pattern):
            if p.is_file():
                content = p.read_text(errors='ignore')[:200]
                findings.append({
                    'file': str(p.relative_to(root)),
                    'type': 'key-or-cert',
                    'detail': content[:80].replace('\n', ' '),
                    'line': '',
                })


def scan_text_files(root: Path, findings: list):
    compiled = [(re.compile(p, re.IGNORECASE), label) for p, label in CRED_PATTERNS]
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for fname in filenames:
            fpath = Path(dirpath) / fname
            if fpath.suffix.lower() in SKIP_EXTS:
                continue
            try:
                s = fpath.stat()
                if s.st_size > 5 * 1024 * 1024:  # skip >5MB
                    continue
                content = fpath.read_text(errors='ignore')
            except (PermissionError, OSError):
                continue
            for lineno, line in enumerate(content.splitlines(), 1):
                for pattern, label in compiled:
                    m = pattern.search(line)
                    if m:
                        findings.append({
                            'file': str(fpath.relative_to(root)),
                            'type': label,
                            'detail': f'line {lineno}: {line.strip()[:120]}',
                            'line': line.strip(),
                        })


def main():
    if len(sys.argv) < 3:
        print(f'Usage: {sys.argv[0]} <extracted-root> <output-file>', file=sys.stderr)
        sys.exit(1)

    root = Path(sys.argv[1])
    out_file = Path(sys.argv[2])

    if not root.is_dir():
        print(f'[!] Not a directory: {root}', file=sys.stderr)
        sys.exit(1)

    findings = []
    print(f'[*] Scanning {root} for credentials...')

    scan_passwd(root, findings)
    scan_keys(root, findings)
    scan_text_files(root, findings)

    out_file.parent.mkdir(parents=True, exist_ok=True)
    with out_file.open('w') as f:
        f.write(f'# Credential Extraction Report\n')
        f.write(f'# Root: {root}\n')
        f.write(f'# Total findings: {len(findings)}\n\n')
        for i, finding in enumerate(findings, 1):
            f.write(f'[{i}] Type:   {finding["type"]}\n')
            f.write(f'    File:   {finding["file"]}\n')
            f.write(f'    Detail: {finding["detail"]}\n\n')

    print(f'[+] {len(findings)} findings written to {out_file}')


if __name__ == '__main__':
    main()
