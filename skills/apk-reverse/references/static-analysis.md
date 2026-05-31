# Static Analysis Reference

## jadx Advanced Usage

```bash
# Export as Gradle project (allows IDE import)
jadx --export-gradle -d app_project app.apk

# Deobfuscate with custom min length (avoids renaming short but meaningful names)
jadx --deobf --deobf-min 4 -d out app.apk

# Process multiple APKs (e.g. split APKs)
jadx -d out base.apk split_config.arm64_v8a.apk

# Quiet mode + error log only
jadx -q -d out app.apk 2>jadx_errors.txt
```

## APKTool Advanced

```bash
# Preserve resource names (prevents res/ renaming)
apktool d --no-res app.apk -o out

# Use specific framework (for vendor APKs)
apktool if framework-res.apk
apktool d vendor.apk -o out

# Verbose decode for debugging
apktool d -v app.apk -o out
```

## Interesting File Locations (post-decode)

| Path | What to look for |
|---|---|
| `AndroidManifest.xml` | exported components, debuggable, backup |
| `res/xml/network_security_config.xml` | pinning, cleartext |
| `res/values/strings.xml` | API keys, URLs, tokens |
| `assets/` | bundled DBs, config JSON, certs (.cer/.pem) |
| `assets/www/` | hybrid app JS (Cordova/Ionic) |
| `lib/` | native .so files |
| `META-INF/` | signing certs, manifest hashes |
| `smali**/` | disassembled bytecode (multidex = smali_classes2, 3...) |

## Multidex Handling

Apps with >65k methods use multiple DEX files:
```bash
unzip app.apk -d raw/
ls raw/*.dex          # classes.dex, classes2.dex, classes3.dex ...
# jadx handles multidex automatically
# APKTool: smali/ smali_classes2/ smali_classes3/ directories created
```

## Firebase / Google Services Extraction

```bash
cat app_decoded/assets/google-services.json   # project_id, api_key, app_id
# Also check:
grep -r "firebaseio\|googleapis\|firestore" app_decoded/res/
```

## Common Vulnerability Patterns (static)

### Hardcoded crypto keys
```bash
grep -rE "(SecretKeySpec|AES|DES|RC4|Blowfish)" app_decoded/smali/ | head -30
```

### SQL injection surface
```bash
grep -rE "(rawQuery|execSQL)" app_decoded/smali/
```

### Insecure SharedPreferences
```bash
grep -rE "MODE_WORLD_READABLE\|MODE_WORLD_WRITEABLE" app_decoded/smali/
```

### Exported content providers
```bash
grep -A5 'provider' app_decoded/AndroidManifest.xml | grep -v "<!--"
```

### Insecure file operations
```bash
grep -rE "(openFileOutput|getExternalStorage|Environment\.getExternal)" app_decoded/smali/
```

### WebView JS bridge (potential RCE)
```bash
grep -rE "(addJavascriptInterface|setJavaScriptEnabled|loadUrl)" app_decoded/smali/
```
