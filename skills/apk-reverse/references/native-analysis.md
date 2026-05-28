# Native Library Analysis Reference

## Identify JNI Exports

JNI functions follow naming convention: `Java_<package>_<class>_<method>`

```bash
# nm — show exported symbols
nm -D --defined-only libnative.so | grep Java_
# or
readelf -s libnative.so | grep Java_

# objdump — disassemble JNI export
objdump -d --start-address=<addr> libnative.so | head -100
```

## radare2 Workflow

```bash
r2 -A libnative.so      # open + auto-analyse (slow for large libs)

# Essential commands:
afl                      # list all functions
afl | grep Java_         # filter JNI exports
pdf @ sym.Java_com_example_App_nativeCheck   # disassemble function
px 64 @ 0x1234           # hex dump 64 bytes at offset
iz                       # strings in data sections
iS                       # sections
ii                       # imports
```

### r2 scripting (batch analysis)
```bash
r2 -qc 'aaa; afl; q' libnative.so > functions.txt
r2 -qc "aaa; pdf @ sym.Java_com_example_check; q" libnative.so
```

## Ghidra Headless (CLI)

```bash
# Import + analyse without GUI
$GHIDRA_HOME/support/analyzeHeadless /tmp/ghidra_proj MyProject \
  -import libnative.so \
  -postScript ExportFunctions.java \
  -scriptPath /path/to/scripts

# Export decompiled C (requires script)
# Use built-in: DecompileHeadless or custom ExportToC.java
```

### Key Ghidra operations (GUI)
- **Symbol Tree → Exports** — jump straight to JNI functions
- **Function → Decompile** — C pseudocode view
- **Search → Scalars** — find hardcoded constants
- **References → Find References** → trace data flows
- **Defined Strings** → strings window (`Window > Defined Strings`)

## Anti-Analysis Techniques in .so

| Technique | Detection | Counter |
|---|---|---|
| `ptrace(PTRACE_TRACEME)` | `strace` shows it | Frida: hook `ptrace`, return 0 |
| `/proc/self/status` TracerPid check | grep in Ghidra | Patch conditional branch |
| Integrity check (CRC of .so) | Look for hash comparisons | NOP the check in smali or patch .so |
| String encryption in .so | No readable strings | Run + memhook decrypt func |
| Packed .so (UPX/custom) | Entropy check: `binwalk libnative.so` | `upx -d libnative.so` or dump from memory |

## Dump from Memory (rooted / Frida)

When .so is loaded but stripped on disk:
```javascript
// Frida: dump loaded module from memory
const mod = Process.getModuleByName('libnative.so');
const dump = mod.base.readByteArray(mod.size);
const f = new File('/data/local/tmp/libnative_dump.so', 'wb');
f.write(dump);
f.close();
// adb pull /data/local/tmp/libnative_dump.so
```

## binwalk / entropy analysis

```bash
binwalk libnative.so             # identify embedded files / packing
binwalk -E libnative.so          # entropy graph (high = encrypted/compressed)
binwalk -e libnative.so          # extract embedded content
```
