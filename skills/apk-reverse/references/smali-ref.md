# Smali Opcode Reference

Quick-reference for Dalvik/ART bytecode encountered during APK patching and repackaging.

---

## Registers

| Notation | Meaning |
|----------|---------|
| `v0`–`vN` | Local registers (numbered from 0) |
| `p0`–`pN` | Parameter registers (`p0` = `this` for instance methods) |
| `.registers N` | Total register count (locals + params) |
| `.locals N` | Local-only register count |

---

## Types

| Smali | Java |
|-------|------|
| `V` | void |
| `Z` | boolean |
| `B` | byte |
| `S` | short |
| `C` | char |
| `I` | int |
| `J` | long (uses 2 registers) |
| `F` | float |
| `D` | double (uses 2 registers) |
| `Ljava/lang/String;` | Reference type (L + slashed FQCN + ;) |
| `[I` | int array |
| `[Ljava/lang/String;` | String array |

---

## Move / Const

```smali
move v0, v1               # copy v1 → v0 (32-bit)
move-wide v0, v1          # 64-bit (long/double)
move-object v0, v1        # reference types
move-result v0            # capture return value of last invoke
move-result-wide v0       # 64-bit return
move-result-object v0     # object return
move-exception v0         # capture caught exception

const/4 v0, 0x1           # small constant (-8..7)
const/16 v0, 0x100        # 16-bit constant
const v0, 0x12345678      # 32-bit constant
const-wide v0, 0x1234567890abcdefL
const-string v0, "hello"
const-class v0, Ljava/lang/String;
```

---

## Arithmetic (32-bit int)

```smali
add-int v0, v1, v2        # v0 = v1 + v2
sub-int v0, v1, v2
mul-int v0, v1, v2
div-int v0, v1, v2
rem-int v0, v1, v2        # modulo
and-int v0, v1, v2
or-int  v0, v1, v2
xor-int v0, v1, v2
shl-int v0, v1, v2        # shift left
shr-int v0, v1, v2        # signed shift right
ushr-int v0, v1, v2       # unsigned shift right

add-int/2addr v0, v1      # v0 = v0 + v1 (compact form)
add-int/lit16 v0, v1, 5   # v0 = v1 + 5
add-int/lit8  v0, v1, 5
```

Suffix variants: `-long`, `-float`, `-double` for other primitives.

---

## Comparison

```smali
cmpl-float v0, v1, v2     # v0 = -1/0/1; NaN → -1
cmpg-float v0, v1, v2     # NaN → 1
cmpl-double v0, v1, v2
cmpg-double v0, v1, v2
cmp-long v0, v1, v2
```

---

## Branches

```smali
if-eq  v0, v1, :label     # v0 == v1
if-ne  v0, v1, :label
if-lt  v0, v1, :label
if-ge  v0, v1, :label
if-gt  v0, v1, :label
if-le  v0, v1, :label

if-eqz v0, :label         # v0 == 0 (null check for objects)
if-nez v0, :label
if-ltz v0, :label
if-gez v0, :label
if-gtz v0, :label
if-lez v0, :label

goto :label               # unconditional jump
goto/16 :label
goto/32 :label
```

---

## Switch

```smali
packed-switch v0, :pswitch_data_0    # dense integer table
sparse-switch v0, :sswitch_data_0    # key→label pairs

:pswitch_data_0
.packed-switch 0x0        # first key
    :case_0
    :case_1
.end packed-switch

:sswitch_data_0
.sparse-switch
    0x1 -> :case_a
    0x5 -> :case_b
.end sparse-switch
```

---

## Invoke

```smali
# instance method
invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

# constructor / private
invoke-direct {v0}, Ljava/lang/Object;-><init>()V

# static method
invoke-static {v0}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

# interface
invoke-interface {v0, v1}, Ljava/util/List;->add(Ljava/lang/Object;)Z

# super call
invoke-super {p0}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

# range forms (> 5 args)
invoke-virtual/range {v0 .. v5}, ...
```

After any invoke, capture the return value with `move-result` / `move-result-object` / `move-result-wide`.

---

## Field Access

```smali
iget v0, p0, Lcom/example/Foo;->mValue:I          # instance get
iput v1, p0, Lcom/example/Foo;->mValue:I          # instance put
iget-object v0, p0, Lcom/example/Foo;->mTag:Ljava/lang/String;
iput-object v1, p0, Lcom/example/Foo;->mTag:Ljava/lang/String;
iget-boolean / iget-byte / iget-char / iget-short
iget-wide / iput-wide                              # long / double

sget v0, Lcom/example/Foo;->sCounter:I            # static get
sput v1, Lcom/example/Foo;->sCounter:I            # static put
sget-object / sput-object / sget-boolean / sget-wide ...
```

---

## Arrays

```smali
new-array v0, v1, [I               # int[] of size v1
filled-new-array {v0,v1,v2}, [I   # int[]{v0,v1,v2}
fill-array-data v0, :array_data    # bulk fill

aget v0, v1, v2                    # v0 = v1[v2]  (int)
aput v0, v1, v2                    # v1[v2] = v0
aget-object / aput-object
aget-boolean / aput-boolean
aget-byte / aput-byte
aget-char / aput-char
aget-short / aput-short
aget-wide / aput-wide

array-length v0, v1                # v0 = v1.length
```

---

## Objects & Types

```smali
new-instance v0, Ljava/lang/StringBuilder;  # allocate (still need invoke-direct <init>)
instance-of v0, v1, Ljava/lang/String;      # v0 = (v1 instanceof String) ? 1 : 0
check-cast v0, Ljava/lang/String;           # ClassCastException if fails
```

---

## Return

```smali
return-void
return v0           # 32-bit primitive
return-wide v0      # 64-bit (long/double)
return-object v0    # reference type
```

---

## Exceptions

```smali
throw v0            # throw exception in v0

.catch Ljava/lang/Exception; {:try_start .. :try_end} :catch_label
.catchall {:try_start .. :try_end} :catch_all_label
```

---

## Common Patch Patterns

### Force method to return true
```smali
const/4 v0, 0x1
return v0
```

### Force method to return false / 0
```smali
const/4 v0, 0x0
return v0
```

### NOP out a call (remove without shifting registers)
```smali
# Replace invoke-* + move-result with nop(s)
nop
nop
```

### Skip a validation block
```smali
# Change: if-eqz v0, :fail
# To:     goto :success
goto :success
```

### Insert a log call
```smali
const-string v1, "TAG"
const-string v2, "patched here"
invoke-static {v1, v2}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I
move-result v0   # discard if needed
```
