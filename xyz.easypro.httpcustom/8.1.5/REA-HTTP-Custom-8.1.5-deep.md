# REA Deep-Dive — HTTP Custom - AIO Tunnel VPN 8.1.5 (xyz.easypro.httpcustom)
## Mekanisme dekripsi `.hc` — cipher + KDF + aliran kunci

**Tanggal REA:** 27 November 2026 (round 2 — deep static, mengikuti skill
`reverse-engineering`: Phase 0 triage → Phase 1 static; output standard
summary → evidence → unresolved)
**Sumber APK:** APKMirror, diunggah 23 Nov 2026 (`.apkm`, 35.043.841 B,
SHA-256 `2a2304565ccb867a5e7e12e3a8cba5e85dc17fce20f5d70385972a620f221b90`)
**Metode:** REA statis saja — APK **tidak** di-install / tidak dijalankan, tidak ada emulator.
**Laporan round 1:** `REA-HTTP-Custom-8.1.5.md` (folder yang sama, commit `eaa4cf5`).
**Status APK sumber:** **TIDAK dihapus** — aturan 27 Nov 18:40: APK hanya dihapus bila user
menyatakan pekerjaan selesai atau menyerah; temuan masih terbuka, APK tetap disimpan.

## 0. Summary (satu paragraf)

Dekripsi `.hc` dilakukan oleh native `HcrNativeCodec.transform([B[BIJZI)Z`, yang
terdaftar di `libcodec.so` (`0x3174` → body `0x3184–0x405c`) dan memakai **stream
cipher custom berbasis SHA-256 counter-mode**: untuk tiap blok 32 byte data, keystream
= `SHA-256(state[0..30])` dengan state 30 byte = kunci 16 byte (argumen byte[]
kedua) + 1 byte int + 8 byte long big-endian + 1 byte boolean terbalik + 4 byte
counter big-endian, lalu data di-XOR in-place; SHA-256-nya ada dua varian
(one-shot wrapper B skalar dan C instruksi-crypto ARMv8) yang dipilih saat runtime
lewat `getauxval(AT_HWCAP)` bit SHA2. Kunci 16 byte itu **dipasok oleh pemanggil
native** — bagaimana password user diturunkan menjadi kunci 16 byte tersebut
(KDF) **belum terbukti** dan hidup di luar `transform`. Modul ChaCha20 +
HMAC-SHA-256 yang ada di `libruntime.so` **terbukti ada tapi bukan jalur `.hc`**
(`transform` tidak pernah memanggilnya).

---

## 1. Phase 0 — Triage

| Item | Hasil |
|---|---|
| File | `.apkm` (Android App Bundle): `base.apk` (13.512.655 B, 539 entri, 5 dex) + `split_config.arm64_v8a.apk` (29.074.396 B, 11 native lib) + 3 density split |
| Hash | `.apkm` SHA-256 `2a230456…b90` (lengkap di atas); `base.apk` `f925a859…`; split arm64 `c72a821b…` |
| Arsitektur | arm64-v8a saja; minSdk 29 / targetSdk 36 |
| Strings | Dex ter-obfuscate penuh (DexGuard); tidak ada string `"codec"`/`"f2c"` untuk `loadLibrary` di dex (hanya `"litevpn"`); nama class/method hasil obfuscation (`Lh/prnup/fnruxh/szepgyrk;`, `Ldev/epro/r0/…`) |
| Imports/exports | `libcodec.so`: 9 PLT stub (libc: memcpy, memset, getauxval, `__system_property_get`, strncmp, `__stack_chk_fail`, `__cxa_finalize/atexit`, `__register_atfork`); `libf2c.so`: 46 PLT (calloc, free, memset, getauxval, `__system_property_get`, strncmp, syscall, …); `libruntime.so`: crypto mandiri (tidak lewat PLT) |
| Packer/obfuscator | **DexGuard (Guardsquare) penuh**: string terenkripsi, tabel JNI dibangun saat runtime, `JNI_OnLoad` ter-obfuscate (trampoline `adr x17; eor; br`, control-flow flattening, blok decoy), computed-call (`target = nilai_tersimpan − alamat_JNI_fn; br`), decoder LEB128, mixing gaya murmur |
| Aplikasi | `com.pairip.application.Application` (PairIP); Room + SQLCipher; backup off; cleartext ditolak; tanpa cert pinning; engine Go 1.26.8 + Xray-core di `libaio.so` (transport, bukan `.hc`) |

## 2. Phase 1 — Static: tool table

| Kebutuhan | Tool yang dipakai | Catatan |
|---|---|---|
| Disassembly ARM64 | capstone 5.0.7 (`PYTHONNOUSERSITE=0`) | Linear disassembly gagal di code DexGuard (data terselip) — selalu `skipdata=True` atau range terarah |
| ELF/relokasi | pyelftools | `.rela.dyn`/`.rela.plt`, section map |
| DEX/apktool | apktool 2.10.0, parser dex kustom (`/tmp/dex_hcr2.py`) | Pitfall: field entries `class_data_item` harus dikonsumsi sebelum method, kalau tidak parsing method bergeser |
| Ghidra/IDA | **tidak tersedia di VM** | Semua temuan dari capstone + script xref/relokasi; tidak ada dekompilasi otomatis — pseudocode di bawah di-derive manual dari disassembly |
| Emulasi string | interpreter capstone kecil (`/tmp/emu_blocks3.py`, child) | Untuk decrypt nama method H1–H5 libf2c |

Konvensi: semua alamat adalah virtual address; di `.text` libcodec/libf2c
**file offset == vaddr**. `adr`/`adrp` di-print capstone sebagai alamat absolut.

## 3. Evidence — registrasi `transform` (PROVEN)

Dex: `Ldev/epro/httpcustom/protocol/ssh/HcrNativeCodec;` (`deep/base/classes.dex`,
class_def `@0xbaa54`); method 10688 `bikgltrptyrn` (public native), 10689
`cqbcgozgkzmi` (public static native), 10690 `transform` (public static final
native). `<clinit>` (`@0x225f4c`): `const/16 v0, #1205` (`0x4b5`) lalu
`invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)I`.
**Gate constant class ini = `0x4b5` = 1205** (bukan `0x48c` di brief awal —
itu gate class lain). Tidak ada pemanggil Java untuk `transform` di dex.

`libcodec.so` `JNI_OnLoad @ 0x406c` (size `0x14748`): `GetEnv` di `0x4c30`
(JavaVM idx 6, `JNI_VERSION_1_6`); `FindClass` di `0x1343c` dengan nama class
yang sudah di-decrypt ke `.bss 0x22648`; **`RegisterNatives` di `0x17430`**
(JNIEnv idx 215 = offset `0x6b8`, nMethods = 1). Array 3×u64 disalin dari
`.data.rel.ro 0x1e200` (reloc `R_AARCH64_RELATIVE`):

| field | nilai | menunjuk |
|---|---|---|
| name_ptr | `0x22679` | `.bss` — `"transform"` hasil decrypt (9 char + NUL) |
| sig_ptr | `0x22685` | `.bss` — `"([B[BIJZI)Z"` hasil decrypt (11 char + NUL) |
| fn_ptr | **`0x3174`** | `.text` — trampoline `transform` |

`0x3174`: trampoline 3 instruksi (`adr x17, #0x3184; orr; br`) → body nyata
**`0x3184–0x405c`** (954 instruksi, satu `ret` di `0x405c`). Sweep seluruh
`.text` libcodec: **tidak ada `RegisterNatives` lain** — libcodec hanya
mendaftarkan `transform`.

Dua native lain didaftarkan **lazy** lewat gate libf2c: `longktebfdic0`
impl `0xa6e350` membaca tabel record 12-byte di `0x92b7c + arg*12`; record
HcrNativeCodec (file `0x963f8`) = `(a=180, b=4041, count=2)` → tepat 2 method.
Tabel method `0xefa2d8` (entri 16 byte `{u32 idx1, u32 idx2, u64 fn_ptr}`,
`fn_ptr` = addend reloc `R_AARCH64_RELATIVE`): entry 4041 → **`0xacc224`**,
entry 4042 → **`0xaa89e0`**. Penugasan nama (INFERRED kuat, dari bentuk
implementasi — string nama/sig masih terenkripsi saat rest, lihat §9):
`0xacc224` meng-clobber `x2` dan return void ⇒ `bikgltrptyrn()V`;
`0xaa89e0` menyimpan `x2` (array arg) dan return `w0` ⇒
`cqbcgozgkzmi([Ljava/lang/Object;)I`. Urutan deklarasi Java cocok
(10688 lalu 10689).

Lima helper registrasi runtime DexGuard di libf2c (masing-masing nMethods=1,
`ldr … #0x6b8` literal): H1 `0xb041b8` → `longktebfdic0` (`0xa6e350`),
H2 `0xc921b8` → `sztkyenenhhg1` (`0xb87388`), H3 `0xe13ed8` →
`spuvnvbaetzd2` (`0xd163c4`), H4 `0xe52724` → `nymwnkzmmdji3`
(`0xe335d0`), H5 `0xa27958` → `quqlxwmvimzd4` (`0xa26bb8`).
Nama-nama ini **ter-decrypt dan terverifikasi** lewat emulasi blok skalar
(seed `x24 = 0x1edac629fb939af5`).

## 4. Evidence — `transform`: cipher SHA-256 counter-mode (PROVEN)

Pseudocode di bawah **di-derive dari disassembly `0x3184–0x405c`** (bukan
dekompilasi otomatis; tiap langkah merujuk ke alamat):

```text
// JNI: transform(JNIEnv* env, jclass, byte[] data, byte[] key16, int c, long d, boolean e, int len) -> boolean
//   x0=env, x1=jclass, x2=data, x3=key16, w4=c, x5=d, w6=e, w7=len
// Prologue 0x3184: simpan arg ke stack (x0->[x29,#-0x90], x2->[x29,#-0x78],
//   x3->[x29,#-0x80], w4->[x29,#-0x84], x5->[x29,#-0x70], w6->[x29,#-0x94],
//   w7->[x29,#-0x88]); mixing decrypt DexGuard pada byte trampoline 0x3174.
//   0x3c70: alokasi buffer stack (struct 32 B, keystream 32 B, chunk 4096 B).

if GetArrayLength(key16) != 16:            // 0x3d0c-0x3d1c, idx 0x558
    return false                            // 0x3d40
if GetArrayLength(data) <= len:             // 0x3d24-0x3d3c
    return false
if len < 1:                                 // 0x3e08
    return true                             // 0x4060

state = zeroed 32-byte struct               // 0x3d58-0x3d64
GetByteArrayRegion(key16, 0, 16, state[0..16])   // 0x3d84-0x3da0, idx 0x640
if ExceptionCheck(): return false           // 0x3da4-0x3db8, idx 0x720
state[0x10]      = (byte) c                 // 0x3dc4, strb w24
state[0x11..0x18] = d big-endian            // 0x3dc8-0x3df8, lsr 0x38..0x08 + strb
state[0x19]      = (e == 0) ? 1 : 0         // 0x3dfc-0x3e0c, cset eq
// state[0x1a..0x1d] = counter, big-endian (diisi per blok, 0x3f28-0x3f30)
// state[0x1e..0x1f] = 0 (padding, tidak pernah ditulis)

keystream_fn = HWCAP_SHA2 ? sha256_oneshot_C : sha256_oneshot_B
    // 0x3d68 getauxval; 0x3d74 tst #0x40 (HWCAP_SHA2); 0x3d9c csel x19
    // GOT 0x1e5c8 -> 0x2488 (B), 0x1e5d0 -> 0x30f4 (C); reloc R_AARCH64_RELATIVE

processed = 0; block = 0                    // 0x3e18-0x3e1c
while processed < len:                      // 0x3e24, 0x3ee0-0x3ee4
    chunk = min(len - processed, 4096)      // 0x3e28-0x3e40
    GetByteArrayRegion(data, processed, chunk, buf)   // 0x3e34-0x3e50, idx 0x640
    if ExceptionCheck(): return false       // 0x3e54-0x3e68
    for off in 0..chunk step 32:            // 0x3eec-0x3ffc
        state[0x1a..0x1d] = block big-endian // 0x3f28 rev w20; stur [x1,#0x1a]
        block++
        keystream[0..32] = keystream_fn(out=keystream, in=state, len=30)
            // 0x3f2c-0x3f44, blr x8 (pointer di [x29,#-0x30]); w2 = 0x1e = 30
        buf[off .. off+min(32, chunk-off)] ^= keystream[0..]
            // 0x3f7c-0x3f90 XOR vektor 16 B; 0x3fb0-0x3fd4 XOR 4 B; 0x3fe0-0x3ff8 XOR 1 B
    SetByteArrayRegion(data, processed, chunk, buf)   // 0x3e84-0x3eb8, idx 0x680
    if ExceptionCheck(): return false       // 0x3ebc-0x3ed0
    processed += chunk                      // 0x3ed8
// exit 0x4010-0x4024: helper decrypt/wipe DexGuard 0x187c4 pada state (30 B),
// keystream (32 B), chunk buf (4096 B) — konsisten dengan secure cleanup
// material kunci; semantik output persisnya belum ditelusuri penuh (§9).
return true                                 // w26=1, 0x403c-0x405c
```

**Yang terbukti dari sini:**

- **Cipher = stream cipher custom, SHA-256 counter-mode, blok 32 byte.**
  Keystream blok ke-`i` = `SHA-256(key16 || c_byte || d_BE || !e || ctr_BE)`,
  input 30 byte, output digest 32 byte, di-XOR ke data in-place.
- **Kunci = 16 byte (128-bit)**, dipasok langsung sebagai argumen byte[]
  kedua; panjangnya divalidasi harus tepat 16.
- **Tidak ada IV/nonce terpisah** — peran nonce diambil oleh field state:
  1 byte int + 8 byte long + 1 byte boolean + counter 4 byte.
- **Data diproses per chunk ≤4096 byte** (Get/SetByteArrayRegion) dan per
  blok 32 byte; counter global lintas chunk (di-init 0 sekali, naik per blok).
- **Return boolean**: `false` bila validasi gagal / exception JNI /
  keystream gagal; `true` bila selesai (termasuk `len < 1`).
- **Enkripsi dan dekripsi adalah operasi yang sama** (XOR stream) — tidak
  ada cabang mode terpisah di body; arah ditentukan (bila ada) oleh argumen
  boolean/int/long di state, bukan oleh code path berbeda.

## 5. Evidence — SHA-256 one-shot wrapper B/C + dispatch (PROVEN)

`.rodata` libcodec: H#1 `0xc70` (`6a09e667 bb67ae85 3c6ef372 a54ff53a
510e527f 9b05688c 1f83d9ab 5be0cd19`), K#1 `0xc90`, padding `80 00…` `0xd90`,
H#2 `0xf60`, padding#2 `0xf80`, byte `00…0f` `0xf50`.

- **Wrapper B `0x2488`** — `sha256_oneshot(out=x0, in=x1, len=x2)`:
  init state di stack dari H#1, `bl update#2 0x15c0` (state, in, len),
  `bl final#1 0x2308` (state, out=x0), return 0. (Argumen x1/x2 dipertahankan
  dari pemanggil — wrapper hanya menyimpan x0.)
- **Wrapper C `0x30f4`** — sama, dari H#2, `bl update#1 0x2508` +
  `bl final#2 0x2b70`. (Alamat start benar `0x30f4`, bukan `0x30f8` —
  dikonfirmasi reloc GOT `0x1e5d0` addend `0x30f4`.)
- **Dispatch CPU:** `getauxval` + `tst #0x40` (HWCAP_SHA2) → `csel`:
  SHA2 tidak ada → B; SHA2 ada → C. Kompresi SHA-256 instruksi-crypto
  (`sha256h/sha256h2/sha256su0/sha256su1`, `SHA256SU1` ×48) ada di
  `~0x25e4–0x2800`, yaitu di dalam update#1 (jalur C); update#2 (jalur B)
  adalah implementasi skalar (fungsi sigma `ror #6/#11/#25`, `#2/#13/#22`).
- **GOT:** `0x1e5c8` reloc RELATIVE addend `0x2488` (B); `0x1e5d0` addend
  `0x30f4` (C); `0x1e5d8` reloc GLOB_DAT (simbol 11) = pointer konteks
  DexGuard (dibaca di decryptor). PLT: `0x1a160` __cxa_finalize,
  `0x1a170` __cxa_atexit, `0x1a180` __register_atfork,
  `0x1a190` __stack_chk_fail, `0x1a1a0` memcpy, `0x1a1b0` getauxval,
  `0x1a1c0` memset, `0x1a1d0` __system_property_get, `0x1a1e0` strncmp.
- Catatan `adr`: immediate `adr` di file ini adalah alamat `.rodata`
  absolut (pre-relokasi) yang di-fixup saat load — terbukti dari data di
  alamat tujuan (B `adr x8, #0xc70` → H#1; C `adr x8, #0xf60` → H#2).

## 6. Evidence — runtime DexGuard libf2c + string decryptor (PROVEN)

- **Computed-call:** `target = nilai_tersimpan − alamat_JNI_fn; blr target`
  (`0xe89400–0xe89410`, GetStringUTFLength 0x540; `0xe6c7a8–0xe6c7e8`,
  GetArrayLength 0x558). Call graph statis sengaja tidak terlihat.
- **Decoder LEB128** `0xe6c7ec+` (`ldrsb`, `and 0x7f`, `bfi` 7/14/21/28,
  bit lanjutan 0x80).
- **Hash mixing** murmur (`mul 0x85ebca6b`, `ror #0x1b/#0x1a/#0x19`,
  `lsl #6`+`lsr #2`) di `0xe6c764–0xe6c7a4` dan kepala JNI_OnLoad.
- **`JNI_OnLoad` libf2c @ `0xe57a58`, size `0xaa40`:** trampoline → body
  `0xe57a68`; kunci decrypt `w10=0x3fedfed7`, `w13=0x194f5ce7`,
  `w21=0xd3338261`, `w22=0x28b411c7`, `w23=0x0d2bde4a`; loop
  `ldrb`→`add`/`eor`→`ror #0x1b`→`mul 0x85ebca6b`→`lsl #6`; sumber GOT
  `*(0xf52430)`, tujuan `0xf6664c` (ujung `.data`, sebelum `.bss 0xf666b0`).
- **Helper decrypt string libf2c:** `0xecadfc` (trampoline `0xecadec`,
  prime helper, loop `ldrb` + `mul 0x85ebca6b`/`ror`), `0xe62dac`
  (dispatcher, dipanggil impl lazy + gate), `0xed2924` (decrypt + cache
  `NewGlobalRef` 0xa8 / `DeleteLocalRef` 0xb8 — **bukan** registrar;
  scan index-add penuh: tidak ada pasangan yang jumlahnya `0x6b8`).
- **`.data.rel.ro` libf2c (0xefa220, 0x553b0): 22.193 klaster
  `[u64 meta][u64 fn_ptr]`** — format meta belum ter-decode penuh; klaster
  di `0xf4acf0` memuat dispatcher `0xe589c0`.
- **`.rodata` head libf2c:** tabel panjang u64 (`12, 8, 15, 61, 298, 363,
  172, 170, 135, 874, 600`, marker `0x0101010100000000`, …).
- **Pitfall scan JNI awal (dikoreksi):** pola `ldr xRt, [xRn, #0x5d8]`
  memberi false positive — `0x1887c`, `0x32ec`, `0x40b8`, `0x1935c` di
  libcodec semuanya load GOT `0x1e5d8` (konteks DexGuard), BUKAN
  `GetByteArrayElements`. Hit JNI dari scan pola harus diverifikasi per
  call-site (bentuk argumen), bukan dari offset saja.
- **Fungsi atomic/device-check libcodec:** `0x19d90` (atomic CAS),
  `0x19dc4` = `__system_property_get("ro.arch" @0x1070)` +
  `strncmp("exynos98" @0x1078, 10)`; padanan libf2c `0xef1c20`/`0xef1c54`
  (`"ro.arch" @0x8e2377`, `"exynos…" @0x8e2585`).

## 7. Evidence — crypto lain di aplikasi: ADA tapi BUKAN jalur `.hc` (PROVEN)

### 7.1 `libruntime.so` — ChaCha20 + HMAC-SHA-256 + SHA-256 (modul mandiri)

Klaster `0x684ab8–0x68b530` (dipetakan lewat xref `adrp`/`add`/`ldr` eksak):

- **ChaCha20, 4 wrapper + block `0x68846c`** (quarter-round `ror #16/#20/
  #24/#25` ≡ `rol 16/12/8/7`; block memuat state 16 word, loop 20 round,
  addback state + XOR data, counter naik per blok 64 B, path blok parsial):
  `0x688204` (DJB: counter 64-bit=0 + nonce 8 B), `0x6882b4` (IETF RFC 8439:
  counter 32-bit=0 + nonce 12 B), `0x68836c` (DJB, counter 64-bit dari arg),
  `0x688404` (IETF, counter 32-bit dari arg). Semua in-place, wipe state
  64 B setelahnya, return 0.
- **HMAC-SHA-256 textbook:** init `0x684ab8` (ipad `0x36`, opad `0x5c`,
  hash-kunci-bila->64 B), update `0x684d54`, final `0x684dac`, wipe
  ipad/opad; SHA-256 init `0x6889f4` / update `0x688a14` / final `0x689760`
  / kompresi `0x688d28`.
- **Mengapa bukan `.hc`:** scan `BL` seluruh `.text` libruntime — **tidak
  ada pemanggil langsung** ke wrapper ChaCha/HMAC mana pun, dan tidak ada
  pointer relokasi (`R_AARCH64_RELATIVE`, 6200 entri) maupun pointer mentah
  di `.data.rel.ro`/`.data` yang menunjuk ke entry crypto tersebut; dan
  yang menentukan — **`transform` (libcodec) hanya memanggil wrapper
  SHA-256 libcodec + fungsi JNI**, tidak pernah memanggil ke libruntime.
  Modul ini adalah kapabilitas crypto terpisah di aplikasi (kemungkinan
  dipakai komponen lain, mis. lapisan protokol/SSH), bukan dekripsi `.hc`.

### 7.2 `libcodec.so` — setup tabel XOR/SIMD saat init (PROVEN, bukan transform data)

Loop `0x18700–0x187ac`: blok 32 B dari `.rodata 0xfc8…` di-XOR dengan 32 B
material dari `[x14]` + counter vektor (`00…0f` dari `0xf50`, +`0x20` per
iterasi) → `.bss 0x22648…`; lalu salin `.rodata 0x1002…` → `.bss 0x22685…`
XOR konstanta `0x10…`/`0x20…`. Ini **generate/dekripsi tabel saat
load/init** (sumber/tujuan `.rodata`→`.bss`), bukan transform data.

### 7.3 `libf2c.so` — TIDAK ada cipher standar (PROVEN)

Scan konstanta + scan instruksi crypto ARMv8 seluruh `.text`: NOL
AES/ChaCha/SHA/DES/BLAKE2/PBKDF2/scrypt/Argon2/HKDF. Satu-satunya hit:
golden-ratio `0x9e3779b9` di offset `0x91528`.

### 7.4 `libaio.so` (Go/Xray) — transport, bukan `.hc` (PROVEN)

Crypto standar Go lengkap (AES S-box ×2, Te0, ChaCha, SHA-256/512,
BLAKE2b, PBKDF2/scrypt/HKDF) + simbol `deriveInproxyKey` /
`sealInproxyPayload` / `deriveOSSHKey` = crypto transport
(VLESS/VMess/Trojan/SS/dll.). Tidak ada jalur dari `transform` ke sini.

## 8. Aliran kunci + apa yang memberi makan derivasi

| Elemen | Status | Bukti |
|---|---|---|
| Kunci 16 byte → `transform` | PROVEN (posisi + validasi) | Argumen byte[] kedua; `GetArrayLength == 16` wajib; disalin ke `state[0..16]` |
| int `c` → `state[0x10]` (1 byte) | PROVEN (posisi); peran INFERRED | Hanya low byte dipakai; kemungkinan indeks kunci / versi / mode — belum terbukti |
| long `d` → `state[0x11..0x18]` BE | PROVEN (posisi); peran INFERRED | Kemungkinan device/session id / timestamp — belum terbukti |
| boolean `e` → `state[0x19]` = `!e` | PROVEN (posisi + inversi) | `cset eq`; kemungkinan arah enkrip/dekrip — belum terbukti |
| counter → `state[0x1a..0x1d]` BE | PROVEN | `rev w20`, naik per blok 32 B, global lintas chunk |
| Keystream = SHA-256(state 30 B) | PROVEN | Wrapper B/C, `len=0x1e`, XOR in-place 32 B/blok |
| **Password user → kunci 16 byte (KDF)** | **UNPROVEN** | Terjadi di **pemanggil native `transform`**, bukan di `transform` sendiri; pemanggil itu belum dilacak (tidak ada pemanggil Java; kandidat: native `bikgltrptyrn`/`cqbcgozgkzmi` libf2c atau code native lain) |

**Tidak ada nilai kunci mentah yang ditemukan/dipublikasikan.** Konstanta di
laporan ini adalah konstanta algoritma standar (SHA-256 H/K, ipad/opad,
`"expand 32-byte k"`) dan konstanta mixing DexGuard yang terlihat di code —
bukan kunci enkripsi `.hc`.

## 9. Penilaian akhir — PROVEN vs INFERRED vs UNPROVEN

### PROVEN

| # | Klaim | Bukti |
|---|---|---|
| P1 | Cipher `.hc` = **stream cipher custom SHA-256 counter-mode** (blok 32 B, state 30 B) | `transform` libcodec `0x3184–0x405c` (§4): keystream `SHA-256(state[0..30])`, XOR in-place, counter BE per blok |
| P2 | Kunci 16 byte, divalidasi `== 16`, dari argumen byte[] kedua | Prologue + `GetArrayLength` `0x3d0c` + `GetByteArrayRegion` ke `state[0..16]` |
| P3 | SHA-256 one-shot B (skalar) / C (instruksi-crypto), dispatch HWCAP_SHA2 | Wrapper `0x2488`/`0x30f4`, reloc GOT `0x1e5c8`/`0x1e5d0`, `csel` `0x3d9c`, kompresi `~0x25e4–0x2800` |
| P4 | `transform` terdaftar via `RegisterNatives` libcodec `0x17430`, fn `0x3174` | Tabel `.data.rel.ro 0x1e200`, nama/sig decrypt ke `.bss 0x22679`/`0x22685` |
| P5 | Lazy registration gate libf2c: record `(180, 4041, 2)` → `0xacc224`/`0xaa89e0` | `longktebfdic0 0xa6e350`, tabel `0xefa2d8`, reloc addend |
| P6 | String/kunci DexGuard di-decrypt runtime (mixing murmur + computed call) | JNI_OnLoad libf2c `0xe57a68`, helper `0xecadfc`/`0xe62dac`/`0xed2924`, decryptor libcodec `0x187c4` |
| P7 | `libruntime.so` berisi ChaCha20 (DJB+IETF) + HMAC-SHA-256 + SHA-256 | §7.1 (konstanta, block, 4 wrapper, HMAC init/update/final) |
| P8 | ChaCha20/HMAC **bukan** jalur `.hc`; `libf2c` tanpa cipher standar; `libaio` transport | §7.1–7.4 (tidak ada pemanggil; `transform` hanya panggil SHA-256 libcodec + JNI) |
| P9 | Dekripsi `.hc` bukan di Java | 0 `javax.crypto`; `transform` native tanpa pemanggil Java |

### INFERRED (kuat, berlabel)

| # | Klaim | Dasar | Yang kurang |
|---|---|---|---|
| I1 | `0xacc224` = `bikgltrptyrn()V`, `0xaa89e0` = `cqbcgozgkzmi([Ljava/lang/Object;)I` | Bentuk impl (clobber `x2`/return void vs simpan `x2`/return `w0`) + urutan deklarasi Java | String nama/sig hasil decrypt (butuh emulasi loop nama gate `0xa6e7ac–0xa6e9f8`, seed `0xcf55dd5da31417c5`) |
| I2 | Peran argumen `c`/`d`/`e` (indeks/versi, device/session id, arah) | Posisi byte di state | Semantik belum terbukti — hanya posisi + lebar yang pasti |
| I3 | Helper `0x187c4` di exit path = secure cleanup material kunci | Dipanggil pada state (30 B), keystream (32 B), chunk buf (4096 B) sebelum return | Semantik output persisnya belum ditelusuri |

### STILL UNPROVEN

- **U1.** KDF password → kunci 16 byte (algoritma, iterasi/salt, input:
  password saja? + device ID? + salt hardcoded?) — hidup di pemanggil
  native `transform`, belum dilacak.
- **U2.** Siapa yang memanggil `transform` (rantai native pemanggil) dan
  dari mana argumen `c`/`d`/`e`/`len` berasal.
- **U3.** Arti semantik `c`/`d`/`e` (lihat I2).
- **U4.** Nama/sig hasil decrypt untuk entry lazy 4041/4042 (lihat I1) dan
  signature + nama class kelima helper H1–H5 (butuh emulasi NEON/SIMD).
- **U5.** Bagaimana libcodec/libf2c di-load (tidak ada string
  `loadLibrary("codec"|"f2c")` di dex; kemungkinan loader DexGuard sendiri).
- **U6.** Format meta klaster `.data.rel.ro` libf2c (22.193 entri),
  `.init_array` libf2c (`0xf4f5e0`), dan qword ke-4 (+`0x18`) tabel H1–H5.
- **U7.** Round-trip proof — tidak ada sampel `.hc` di APK, jadi tidak ada
  verifikasi enkripsi/dekripsi ujung-ke-ujung terhadap file nyata.

## 10. Yang dibutuhkan untuk membuktikan U1–U7 (di luar scope statis)

- **Analisis dinamis** (di luar batas tugas ini; APK tidak pernah
  dijalankan): Frida di HP root user + sampel `.hc` dengan password yang
  diketahui → hook `transform` (libcodec `0x3184`) dan baca kunci 16 byte +
  argumen `c`/`d`/`e`/`len` dari stack/ register; hook pemanggilnya untuk
  melihat KDF; lalu verifikasi round-trip.
- **Emulasi statis lanjutan:** emulasi loop decrypt `JNI_OnLoad` libf2c
  (sumber GOT `*(0xf52430)` → buffer `0xf6664c`) + loop nama gate
  (`0xa6e7ac–0xa6e9f8`) untuk merekonstruksi tabel `JNINativeMethod` dan
  nama method lazy; emulasi computed-call dari pemanggil `transform`.
- **Tidak ada decryptor yang dibangun** untuk config orang lain; tidak ada
  credential/host/SSH yang dipanen dari config.

## 11. Artefak kerja (lokal, tidak di-push)

- `~/workspace/rea-httpcustom/deep/` — ekstraksi `.apkm`, disassembly
  (`dis_*.txt`, `dis_libruntime_688000.txt`, `dis_libcodec_3c00.txt`,
  `dis_libcodec_187c4.txt`), script (`scripts/const_hunt.py`,
  `crypto_scan.py`, `dis_range.py`, `dis_libcodec_sha.py`, `bl_scan.py`,
  `jni_array_scan.py`, `rt_xref.py`, `rt_xref2.py`, `rt_callers.py`,
  `rt_callers2.py`, `rt_rela.py`, `codec_rela.py`),
  `jni_registration_findings.md` (temuan registrasi JNI lengkap, child).
- Alat: capstone 5.0.7 (arm64), pyelftools, apktool 2.10.0.
  (`PYTHONNOUSERSITE=0` diperlukan untuk import capstone/pyelftools.)

---

*REA statis — HTTP Custom 8.1.5 — round 2 (deep), mengikuti skill
reverse-engineering (Phase 0 → Phase 1, summary → evidence → unresolved).
Cipher `.hc`: stream cipher custom SHA-256 counter-mode (PROVEN, libcodec
`transform` `0x3184–0x405c`); KDF password → kunci 16 byte: UNPROVEN
(hidup di pemanggil native, butuh analisis dinamis / emulasi lanjutan).*
