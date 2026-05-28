---
name: apk-reverse
description: >
  Full Android APK reverse engineering skill for Kali Linux. Covers the complete
  offensive analysis pipeline: static decompilation (APKTool, jadx), manifest and
  permission auditing, certificate and signing inspection, smali patching and
  repackaging, ProGuard/R8 deobfuscation, dynamic instrumentation (Frida,
  objection), SSL/TLS pinning bypass, traffic interception (Burp), MobSF
  automation, and native .so analysis (Ghidra, radare2). Use this skill whenever
  the user mentions APK, Android reverse engineering, smali, Frida hooks, cert
  pinning bypass, repackaging an app, analysing an Android binary, MobSF, jadx,
  APKTool, or any Android dynamic/static analysis workflow — even if they phrase
  it casually ("pull apart this apk", "hook this android app", "bypass ssl on
  android"). Trigger on any Android app security task.
---

# APK Reverse Engineering — Kali Linux

Full offensive Android analysis pipeline. All workflows assume Kali Linux with
standard tooling installed (see **Environment Setup** below). Follow the phase
that matches your goal; phases are independent but build on each other.

---

## Environment Setup

```bash
# Core tooling
sudo apt install -y apktool jadx adb android-tools-adb zipalign apksigner \
  default-jdk radare2 ghidra frida-tools

# Python tooling
pip install frida frida-tools objection

# MobSF (Docker)
docker pull opensecurity/mobile-security-framework-mobsf
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf

# Verify Frida server arch before pushing
adb shell getprop ro.product.cpu.abi   # e.g. arm64-v8a
# Download matching frida-server from https://github.com/frida/frida/releases
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
```

**Required env vars (set once):**
```bash
export ANDROID_HOME=/opt/android-sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

---

## Phase 1 — Reconnaissance

### Obtain the APK
```bash
# From device (installed app)
adb shell pm list packages | grep <name>           # find package name
adb shell pm path <package.name>                   # get on-device path
adb pull /data/app/<package>/<package>.apk .

# From Google Play (no device needed)
# Use gplaycli or apkeep:
pip install apkeep
apkeep -a <package.name> -d GooglePlay .
```

### Quick triage
```bash
file app.apk                          # confirm ZIP/APK
unzip -l app.apk                      # list contents without extracting
aapt dump badging app.apk             # package name, version, permissions, activities
aapt dump permissions app.apk         # dangerous permissions at a glance
strings app.apk | grep -E "(http|key|secret|token|api)" | sort -u
```

---

## Phase 2 — Static Analysis

### Decode with APKTool
```bash
apktool d app.apk -o app_decoded
# Output: smali/, res/, AndroidManifest.xml, assets/
```

### Decompile to Java with jadx
```bash
jadx -d app_java app.apk             # full decompile
jadx-gui app.apk                     # GUI (preferred for navigation)
# --deobf flag attempts basic deobfuscation
jadx --deobf -d app_java app.apk
```

### Manifest analysis
```bash
cat app_decoded/AndroidManifest.xml
# Key things to audit:
# - android:debuggable="true"         → attach debugger / Frida no-root
# - android:allowBackup="true"        → data extraction via adb backup
# - exported activities/providers     → attack surface
# - custom permissions                → privilege escalation paths
# - network_security_config ref       → cleartext / pinning config
grep -E "(debuggable|allowBackup|exported|usesCleartextTraffic)" app_decoded/AndroidManifest.xml
```

### Network security config
```bash
cat app_decoded/res/xml/network_security_config.xml
# Look for: <pin-set>, <trust-anchors>, cleartextTrafficPermitted
```

### Secrets / hardcoded strings
```bash
grep -rE "(api_key|secret|password|token|Bearer|AWS|firebase)" app_decoded/
grep -rE "https?://[a-zA-Z0-9./_-]+" app_decoded/smali/ | grep -v "schema.android"
# Also check assets/ and res/raw/
find app_decoded/assets/ -type f | xargs strings | grep -E "(key|token|secret)"
```

### Certificate inspection
```bash
unzip -p app.apk META-INF/*.RSA | keytool -printcert -v
# Or:
apksigner verify --verbose --print-certs app.apk
# Check: SHA-256 fingerprint, issuer (self-signed = dev/test build), validity
```

For detailed static reference → see `references/static-analysis.md`

---

## Phase 3 — Deobfuscation (ProGuard / R8)

```bash
# jadx --deobf handles simple cases
jadx --deobf --deobf-min 3 --deobf-use-sourcename -d app_java app.apk

# For heavy obfuscation: check if mapping file shipped in APK
unzip -p app.apk mapping.txt 2>/dev/null

# Rename smali classes using a mapping file
# If you recover a mapping.txt:
java -jar retrace.jar mapping.txt obfuscated-stack-trace.txt
```

**Manual deobfuscation heuristics:**
- Classes with single-letter names (`a`, `b`, `c`) → trace call chains from entry points
- String encryption → find decrypt method, replicate in Python, patch calls
- Reflection-heavy code → trace `Class.forName()`, `getMethod()`, `invoke()`

---

## Phase 4 — Smali Patching & Repackaging

```bash
# Edit smali directly (e.g. disable root check, flip boolean)
# Example: force method to return true
nano app_decoded/smali/com/example/RootCheck.smali
# Change: return v0  →  const/4 v0, 0x1 \n return v0

# Repackage
apktool b app_decoded -o app_patched.apk

# Align
zipalign -v 4 app_patched.apk app_aligned.apk

# Sign (debug key — generates one if missing)
keytool -genkey -v -keystore debug.keystore -alias androiddebugkey \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US"
apksigner sign --ks debug.keystore --ks-key-alias androiddebugkey \
  --ks-pass pass:android --key-pass pass:android \
  --out app_signed.apk app_aligned.apk

# Install
adb install -r app_signed.apk
```

For smali opcode reference → see `references/smali-ref.md`

---

## Phase 5 — Dynamic Analysis (Frida / objection)

### Start Frida server
```bash
adb shell "/data/local/tmp/frida-server &"
frida-ps -U                            # confirm device visible
frida-ps -Ua                           # list running apps
```

### Attach and explore
```bash
# Attach to running process
frida -U -n com.example.app -l hook.js

# Spawn (launch + hook from start — catches init code)
frida -U -f com.example.app -l hook.js --no-pause
```

### Common hook patterns

**Intercept method return value:**
```javascript
Java.perform(() => {
  const Target = Java.use('com.example.ClassName');
  Target.methodName.implementation = function (...args) {
    console.log('[*] methodName called, args:', JSON.stringify(args));
    const ret = this.methodName(...args);
    console.log('[*] return:', ret);
    return ret;  // or override: return true;
  };
});
```

**Enumerate loaded classes matching pattern:**
```javascript
Java.perform(() => {
  Java.enumerateLoadedClasses({
    onMatch: (name) => { if (name.includes('Auth')) console.log(name); },
    onComplete: () => {}
  });
});
```

### objection (higher-level Frida wrapper)
```bash
objection -g com.example.app explore

# Inside objection REPL:
android hooking list classes
android hooking list class_methods com.example.ClassName
android hooking watch class_method com.example.ClassName.checkLicense --dump-args --dump-return
android root disable                          # bypass root detection
android sslpinning disable                    # one-shot pinning bypass
android intent launch_activity com.example.HiddenActivity
```

For full Frida hook library → see `references/frida-hooks.md`

---

## Phase 6 — SSL/TLS Pinning Bypass

### Option 1: objection (fastest)
```bash
objection -g com.example.app explore
# android sslpinning disable
```

### Option 2: Frida script (more reliable)
```bash
# Use universal pinning bypass:
frida -U -f com.example.app -l https://raw.githubusercontent.com/httptoolkit/frida-android-unpinning/main/frida-script.js --no-pause
```

### Option 3: Smali patch (works without root)
```bash
# Decode, find OkHttp / TrustManager / CertificatePinner classes
grep -r "CertificatePinner\|checkServerTrusted\|hostnameVerifier" app_decoded/smali/
# Patch the validation method to be a no-op, repackage, sign
```

### Option 4: Network security config override
```xml
<!-- res/xml/network_security_config.xml — replace contents -->
<network-security-config>
  <base-config cleartextTrafficPermitted="true">
    <trust-anchors>
      <certificates src="system"/>
      <certificates src="user"/>
    </trust-anchors>
  </base-config>
</network-security-config>
```
Then patch AndroidManifest.xml to reference this config, repackage, sign.

### Burp interception setup
```bash
# Export Burp CA → install on device
# Settings > Security > Install from storage (or ADB push for rooted)
adb push burp_ca.crt /sdcard/
# On device: Settings > Security > Encryption & Credentials > Install cert

# Route traffic through Burp proxy
adb shell settings put global http_proxy <kali-ip>:8080
# Undo:
adb shell settings put global http_proxy :0
```

---

## Phase 7 — Native Library Analysis (.so)

```bash
# List native libs
find app_decoded/lib/ -name "*.so"
file app_decoded/lib/arm64-v8a/libnative.so   # confirm arch

# Strings
strings app_decoded/lib/arm64-v8a/libnative.so | grep -E "(key|secret|http|token)"

# radare2 (quick CLI analysis)
r2 -A app_decoded/lib/arm64-v8a/libnative.so
# Inside r2:
# afl          → list functions
# pdf @ sym.Java_com_example_NativeClass_method  → disassemble JNI entry
# iz           → strings

# Ghidra (full decompile)
ghidra &
# Import .so → Auto-analyse → CodeBrowser
# Filter functions: Java_* prefix = JNI exports
```

### Frida hooking native functions
```javascript
// Hook native export by name
Interceptor.attach(Module.getExportByName('libnative.so', 'Java_com_example_check'), {
  onEnter(args) { console.log('arg0:', args[0]); },
  onLeave(retval) { console.log('ret:', retval); retval.replace(1); }
});
```

For Ghidra workflow details → see `references/native-analysis.md`

---

## Phase 8 — MobSF Automated Scan

```bash
docker run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf
# Browse to http://localhost:8000
# Upload APK → full static + basic dynamic report
# API mode:
curl -F "file=@app.apk" http://localhost:8000/api/v1/upload \
  -H "Authorization: <mobsf-api-key>"
```

MobSF covers: manifest issues, hardcoded secrets, dangerous APIs, network config,
binary protections, trackers, CVSS scoring. Use as baseline before manual analysis.

---

## Output Format

For findings, use this structure:

```
## [Finding Title] — [Critical/High/Medium/Low/Info]
**Location:** class/file path or smali file
**Evidence:** exact string/code/method name
**Impact:** what an attacker can do
**Reproduction:** exact steps or command
```

---

## Quick Reference

| Goal | Tool | Command |
|---|---|---|
| Decode APK | apktool | `apktool d app.apk -o out` |
| Decompile Java | jadx | `jadx -d out app.apk` |
| Patch + repack | apktool + apksigner | `apktool b out -o patched.apk` |
| Bypass pinning | objection | `android sslpinning disable` |
| Hook method | Frida | `frida -U -f pkg -l hook.js` |
| Analyse .so | radare2 / Ghidra | `r2 -A lib.so` |
| Full auto scan | MobSF | `docker run ... -p 8000:8000` |
| Pull from device | adb | `adb pull /data/app/...` |
