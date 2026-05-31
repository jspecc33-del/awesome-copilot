# Frida Hook Library

## Root Detection Bypass

```javascript
Java.perform(() => {
  // RootBeer / common root checks
  const RootBeer = Java.use('com.scottyab.rootbeer.RootBeer');
  RootBeer.isRooted.implementation = function() { return false; };

  // Generic pattern: any method named isRooted / isDeviceRooted
  Java.enumerateLoadedClasses({
    onMatch(name) {
      try {
        const cls = Java.use(name);
        ['isRooted','isDeviceRooted','checkRoot','detectRoot'].forEach(m => {
          if (cls[m]) {
            cls[m].implementation = function() {
              console.log(`[bypass] ${name}.${m}`);
              return false;
            };
          }
        });
      } catch(_) {}
    },
    onComplete() {}
  });
});
```

## SSL Pinning Bypass (manual targets)

```javascript
Java.perform(() => {
  // OkHttp3 CertificatePinner
  const CertPinner = Java.use('okhttp3.CertificatePinner');
  CertPinner.check.overload('java.lang.String', 'java.util.List').implementation =
    function(host, certs) { console.log('[bypass] OkHttp pin: ' + host); };

  // TrustManager (accepts all)
  const TrustManager = Java.registerClass({
    name: 'com.frida.TrustAll',
    implements: [Java.use('javax.net.ssl.X509TrustManager')],
    methods: {
      checkClientTrusted(chain, authType) {},
      checkServerTrusted(chain, authType) {},
      getAcceptedIssuers() { return []; }
    }
  });

  const SSLContext = Java.use('javax.net.ssl.SSLContext');
  SSLContext.init.overload(
    '[Ljavax.net.ssl.KeyManager;',
    '[Ljavax.net.ssl.TrustManager;',
    'java.security.SecureRandom'
  ).implementation = function(km, tm, sr) {
    this.init(km, [TrustManager.$new()], sr);
  };
});
```

## Crypto Intercept (log encrypt/decrypt)

```javascript
Java.perform(() => {
  const Cipher = Java.use('javax.crypto.Cipher');
  Cipher.doFinal.overload('[B').implementation = function(input) {
    const result = this.doFinal(input);
    console.log('[Cipher] algo:', this.getAlgorithm());
    console.log('[Cipher] input:', input ? Java.array('byte', input) : null);
    console.log('[Cipher] output:', result);
    return result;
  };
});
```

## Intent Intercept

```javascript
Java.perform(() => {
  const Intent = Java.use('android.content.Intent');
  Intent.putExtra.overload('java.lang.String','java.lang.String').implementation =
    function(key, val) {
      console.log(`[Intent] ${key} = ${val}`);
      return this.putExtra(key, val);
    };
});
```

## SharedPreferences Dump

```javascript
Java.perform(() => {
  const Activity = Java.use('android.app.Activity');
  Activity.getSharedPreferences.implementation = function(name, mode) {
    const prefs = this.getSharedPreferences(name, mode);
    const all = prefs.getAll();
    const keys = all.keySet().toArray();
    keys.forEach(k => console.log(`[Prefs:${name}] ${k} = ${all.get(k)}`));
    return prefs;
  };
});
```

## Class Method Tracer (generic)

```javascript
// Trace all methods on a class
function traceClass(targetClass) {
  Java.perform(() => {
    const cls = Java.use(targetClass);
    const methods = cls.class.getDeclaredMethods();
    methods.forEach(m => {
      const name = m.getName();
      try {
        cls[name].overloads.forEach(overload => {
          overload.implementation = function(...args) {
            console.log(`[trace] ${targetClass}.${name}(${JSON.stringify(args)})`);
            const ret = overload.apply(this, args);
            console.log(`[trace] → ${JSON.stringify(ret)}`);
            return ret;
          };
        });
      } catch(_) {}
    });
  });
}
traceClass('com.example.AuthManager');
```

## Native Hook (ARM64)

```javascript
// Hook by export name
Interceptor.attach(Module.getExportByName('libnative.so', 'check_license'), {
  onEnter(args) {
    console.log('[native] check_license arg0:', args[0].readUtf8String());
  },
  onLeave(retval) {
    console.log('[native] ret:', retval.toInt32());
    retval.replace(ptr(1));  // force return 1 (success)
  }
});

// Hook by offset (when stripped — use r2/Ghidra to find offset)
const base = Module.getBaseAddress('libnative.so');
Interceptor.attach(base.add(0x12345), {
  onEnter(args) { console.log('[offset hook] hit'); }
});
```

## Memory Search (find key at runtime)

```javascript
// Search all memory for a known string pattern
Process.enumerateRanges('r--').forEach(range => {
  Memory.scanSync(range.base, range.size, '41 50 49 4B 45 59').forEach(match => {
    console.log('[memscan] found at', match.address, match.address.readByteArray(32));
  });
});
```
