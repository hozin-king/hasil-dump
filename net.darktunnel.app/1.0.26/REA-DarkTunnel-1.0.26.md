# REA — DarkTunnel 1.0.26 (versionCode 32) — `net.darktunnel.app`

**Method:** static analysis only (Phase 0 triage → Phase 1 static, per `reverse-engineering` skill).
No install, no run, no emulation. No sample config was decrypted; no decryptor was built.

**Input (verified on disk):**

| Item | Value |
|---|---|
| Source file | `browser-download-20261127T115511.130177214Z-2-DarkTunnel_-_SSH_DNSTT_V2Ray_1.0.26_APKPure.xapk` (APKPure) |
| Size | 14,968,543 B |
| SHA-256 | `2423343d80257d0adbf4d40da3266f9ff0d5b57291f962d2de45f52598932e00` |
| Format | Valid XAPK (zip). Manifest: package `net.darktunnel.app`, version 1.0.26, versionCode 32, minSdk 24, targetSdk 36 |
| Source file kept? | **Yes — NOT deleted** (user rule 27 Nov 18:40: delete only when the user says the work is done or he gives up) |

**Upstream engine:** `github.com/aztecrabbit/libdarktunnel` (Go module path inside the binary).
The public GitHub repo of that name returns 404 (private/renamed) — checked 27 Nov 2026.

---

## 1. Summary — the locked-config mechanism (the question asked)

`encryptedLockedConfig` is a **double-encrypted, base64url-wrapped msgpack blob**.
There is **no KDF and no per-device/per-user key** — both keys and the IV are hardcoded
constants in `libgojni.so`, identical on every install. The only device binding is an
allow-list of hashed hardware IDs checked at tunnel start.

| Layer | Cipher | Key | IV | Encoding | Plaintext |
|---|---|---|---|---|---|
| Outer | **AES-256-CFB** (decrypt = `newCFB(..., true)`) | 32-byte hardcoded ASCII constant, `.rodata` vaddr `0x343455` | 16-byte hardcoded global (`.data` slice header `0x1d48390`, backing `.noptrdata` `0x1c70c80`) | base64 **URL** encoding, with padding (`base64.URLEncoding`) | msgpack `LockedConfigToExport` |
| Inner | **AES-192-CFB** (decrypt = `newCFB(..., true)`) | 24-byte hardcoded ASCII constant, `.rodata` vaddr `0x336e61` | **same 16 bytes** as the outer IV (slice header `.data` `0x1d48310`, backing `.noptrdata` `0x1c70c60`; a third header at `0x1d483b0` / `0x1d48370` holds the same bytes) | base64 **URL** encoding, with padding (same shared `Encoding` global at `.bss` `0x1d66680`) | msgpack `lockedConfigJSON` (the actual tunnel config) |

**Key/IV values are NOT in this report.** Lengths and locations are above; the values live
only in a local-only file on the analysis machine (`LOCAL_ONLY_key_material.txt`, never pushed).

**Decrypt flow (unlock, at tunnel start) — `(*Ma).A` → `NewCa`:**
1. `liblockedconfig.Dtocfrome(s)`: base64url-decode → AES-256-CFB decrypt → msgpack
   `(*LockedConfigToExport).UnmarshalMsg`. If this succeeds, the inner ciphertext field is
   decrypted with `liblockedconfig.Dtoc` (AES-192-CFB on raw bytes, same 24-byte key) and a
   `Ca` object is built; `(*Ca).Err` validates it (including the hardware-ID check).
2. If step 1 fails, fallback: `libdarktunnel.dtoc22(s)` — base64url-decode → AES-192-CFB
   decrypt → `lockedConfigJSON.UnmarshalMsg` (legacy single-layer format).
3. If both fail, `newCa22` fallback.

**Encrypt flow (lock, in the app UI) — Java `Libdarktunnel.e(...)` → Go `libdarktunnel.E`:**
1. The creator pastes a newline-separated hardware-ID list. `E` normalises it
   (`strings.Replace(s, "\r\n", "\n", -1)`, `strings.genSplit(s, "\n", -1)`, `TrimSpace`,
   skip empty) and hashes **each** ID with `hashHardwareId`.
2. `liblockedconfig.NewLockedAppConfig(...)` builds the locked config (fields encrypted
   per-field with `util.Efroms`, three fields decrypted with `util.Dtos` first — see §5).
3. `liblockedconfig.Efromc`: msgpack `LockedConfig` → AES-192-CFB encrypt (24-byte key) →
   raw ciphertext bytes.
4. `liblockedconfig.Efromctoe`: that ciphertext becomes a field of `LockedConfigToExport` →
   msgpack → AES-256-CFB encrypt (32-byte key) → base64url encode → the final
   `encryptedLockedConfig` string stored in Room and exported in the `darktunnel://` link.

**Device binding — `hashHardwareId(hardwareID string) string`:**
- A package-level SHA-256 hasher (assigned in `libdarktunnel.init`, `Reset` at init) is
  **never Written to anywhere in the binary** (verified by scanning all references to the
  hasher global at `.bss` `0x1d67d00`).
- The function does `hex( Sum( SALT || hardwareID ) )`, where `Sum(b)` appends the digest
  to `b`. Because the hasher state is empty, the appended digest is SHA-256 of the empty
  string — a constant. So the output is effectively
  `hex( SALT || hardwareID || SHA256("") )`, with SALT = a 64-char hex string constant
  (`.rodata` vaddr `0x363197`, length 64).
- **Consequence (PROVEN from the construction): the "hash" is reversible** — the hardware ID
  is recoverable by hex-decoding the stored value and stripping the known salt prefix and
  the constant 32-byte suffix. It works as an allow-list check, not as a one-way hash.
- `(*LockedAppConfig).IsHardwareIdAllowed`: if the stored `HashedHardwareIdList` is empty,
  **any device is allowed** (returns true); otherwise the device's `hashHardwareId` output
  must equal one of the stored entries (string comparison).
- The IV is the same on every install, so device binding comes **only** from this hash
  check, not from the IV.

**What the user sample's alphabet proves (outer layer only, no decryption):**
The `encryptedLockedConfig` in `test_4_yb6k.dark` is 1932 chars, length ≡ 0 (mod 4),
contains `-` and `_`, contains `=` padding, contains no `+` or `/` → **base64 URL encoding
with padding** (`base64.URLEncoding`), consistent with the `DecodeString`/`EncodeString`
call sites on the shared `Encoding` global.

**No KDF exists on this path:** no PBKDF2 / scrypt / argon2 / bcrypt call anywhere in the
lock/unlock flow. `golang.org/x/crypto/scrypt` is linked into the binary but is never
called from the locked-config code (its only relevance is that the package is present).
Keys are used directly as AES keys.

---

## 2. Phase 0 — triage

### 2.1 XAPK contents

| File | Size (B) | Notes |
|---|---|---|
| `net.darktunnel.app.apk` (base) | 3,627,972 | `classes.dex` 7,438,748 B (single dex), manifest, resources |
| `config.arm64_v8a.apk` | 10,793,783 | native libs (arm64-v8a only) |
| `config.xxxhdpi.apk` + 21 locale splits (`config.en/ar/de/es/fr/hi/in/it/ja/ko/ms/my/pt/ru/th/tr/vi/zh`) | 24,985–37,373 each | resources only |
| `manifest.json` | — | XAPK manifest: `net.darktunnel.app`, 1.0.26 / 32 |

### 2.2 Manifest (base APK, apktool-decoded)

- `allowBackup=true`, `extractNativeLibs=true`, `compileSdk 36`.
- Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE`,
  `POST_NOTIFICATIONS`, `WAKE_LOCK`, `READ_PHONE_STATE`,
  `READ/WRITE_EXTERNAL_STORAGE`, `AD_ID`, Shizuku API
  (`moe.shizuku.manager.permission.API_V23`).
- Components: `MainActivity` (exported, singleTask), `VpnService`
  (`BIND_VPN_SERVICE`, foregroundServiceType `specialUse`), Shizuku provider.
- **No `networkSecurityConfig`** in the manifest and no network-security-config XML in
  `res/xml/` (only `backup_rules.xml`, `data_extraction_rules.xml`,
  `image_share_filepaths.xml`, `splits0.xml`).

### 2.3 Native library inventory (`config.arm64_v8a.apk`, arm64-v8a only)

| Library | Size (B) | Notes |
|---|---|---|
| `libgojni.so` | 30,781,048 | **Go binary (gomobile), the whole engine.** Go BuildID present, stripped. pclntab: 35,131 functions, 2,405 files. `.text` vaddr `0x506e00`, file offset `0x502e00`, size `0xbdbd18`. |
| `libtun2socks.so` | 155,288 | VPN tunnel |
| `libtun2socks-udp.so` | 150,480 | VPN tunnel (UDP) |
| `libpdnsd.so` | 197,112 | DNS proxy |
| `libandroidx.graphics.path.so` | 10,096 | AndroidX |
| `libdatastore_shared_counter.so` | 7,112 | AndroidX DataStore |

No packer (not UPX / DexGuard-style packing). The dex is R8-obfuscated: smali packages
are unicode-obfuscated (`??.285`, `??.287`, `??.290`, `??.293`), but the names
`net.darktunnel.app`, `go/libdarktunnel/gojni`, `libdarktunnel` survive.

### 2.4 Link format (PROVEN, smali)

`darktunnel://` + Base64 **URL_SAFE | NO_WRAP** (flag `0xa`) of a JSON string
(`decoded/smali/??.290/??.34.smali`). The JSON has keys `type`, `name`,
`sshTunnelConfig`, `encryptedLockedConfig` (plus per-type config keys). Confirmed against
the user's sample file: `type=SSH`, `name="XL OPOK PREMIUM V1.15"`, `encryptedLockedConfig`
= 1932-char string; the outer layer is only base64.

### 2.5 Storage (PROVEN, smali)

Room table `tunnel_config_table` (`decoded/smali/??.287/?.2.smali:53`):
`id, type, name, sshTunnelConfig, sshDnsttTunnelConfig, openvpnTunnelConfig,
vmessTunnelConfig, vlessTunnelConfig, trojanTunnelConfig, shadowsocksTunnelConfig,
v2rayCustomConfigTunnelConfig, encryptedLockedConfig` (TEXT). Entity class
`??.293/?.24.smali` holds the same fields. The locked blob is stored verbatim as TEXT.

### 2.6 Java side does NO crypto (PROVEN)

Zero `javax/crypto/Cipher` / `SecretKeySpec` uses in the app (non-GMS) smali.
All encryption is in Go (`libgojni.so`).

---

## 3. Phase 1 — static analysis of `libgojni.so`

Go REA notes (method): the pclntab magic is `0xFFFFFFF1` at file offset `0x1440b80`
(vaddr `0x1448b80`); function addresses are entryoffs relative to `.text`. In this binary
a function's real body starts **0x50 bytes after** its pclntab entry (the 0x50 bytes before
are stub/trampoline code), and `BL` targets land +0x50 into the callee — names are resolved
by "greatest pclntab entry ≤ target". Capstone 5.0.7 (with `PYTHONNOUSERSITE=0`).
Pointers that read as 0 in the file are `R_AARCH64_RELATIVE` relocations (type 1027) in
`.rela.dyn`; the true address is the relocation addend.

### 3.1 The decrypt functions

**`libdarktunnel.dtoc22`** — vaddr `0x10d7e90` (pclntab), body `0x10d1970`, size `0x5e0`:
base64-decode (shared `Encoding` global `.bss` `0x1d66680`) → `crypto/aes.NewCipher`
(24-byte key, `.rodata` `0x336e61`) → `crypto/cipher.newCFB(block, iv, decrypt=true)`
(IV = global `[]byte` slice header `.data` `0x1d48310`) → `XORKeyStream` → msgpack
`(*lockedConfigJSON).UnmarshalMsg`.

**`liblockedconfig.Dtocfrome`** — vaddr `0x10c3fb0`, body `0x10c4000`, size `0x180`:
same shape, but `aes.NewCipher` with the **32-byte** key (`.rodata` `0x343455`, len `0x20`)
and IV from slice header `.data` `0x1d48390` → `(*LockedConfigToExport).UnmarshalMsg`.
Returns `(*LockedConfigToExport, error)`.

**`liblockedconfig.Dtoc`** — vaddr `0x10c30c0`, body `0x10c3110`, size `0x160`:
AES-192-CFB decrypt of **raw bytes** (no base64): key = 24-byte constant
(`ADRP 0x336000`), IV global `.data`, `aes.NewCipher` + `newCFB(decrypt=true)` +
`XORKeyStream`. Mirror of `Efromc`.

**`util.Dtos` / `util.Efroms` / `util.Efromba`** — field-level helpers (entryoffs in the
`util` range, `0x8709c0`–`0x870af0`): `Efroms` → `Efromba` → `aes.NewCipher` (24-byte key
`0x336e61`) + `newCFB(decrypt=false)` + `XORKeyStream` + base64 encode; `Dtos` is the
decrypt mirror (`newCFB(decrypt=true)`). (Note: the first 0x50 bytes of the `Dtos`
pclntab entry belong to a neighbouring `int → Efroms(FormatInt(x))` helper — the real
`Dtos` body starts at `0x870af0`.)

### 3.2 The encrypt functions (lock side)

**`liblockedconfig.Efromc`** — vaddr `0x10c2f50`, body `0x10c2fa0`, size `0x170`:
`(*LockedConfig).MarshalMsg` → `aes.NewCipher` (24-byte key `0x336e61`, len `0x18`) →
`newCFB(block, iv, decrypt=false)` (IV header `.data` `0x1d48370`) → `XORKeyStream` →
returns raw ciphertext bytes.

**`liblockedconfig.Efromctoe`** — vaddr `0x10c3e70`, body `0x10c3ec0`, size `0x140`:
`(*LockedConfigToExport).MarshalMsg` → `aes.NewCipher` (32-byte key `0x343455`) →
`newCFB(..., decrypt=false)` (IV header `.data` `0x1d48390`) → `XORKeyStream` →
`base64.EncodeString` (shared `Encoding` global `0x1d66680`) → returns the string.

**`libdarktunnel.E`** — vaddr `0x10d1aa0`, body `0x10d1af0`, size `0x610` (the lock
entry point; only caller is the gomobile JNI proxy `main.proxylibdarktunnel__E`, which is
exposed to Java as `Libdarktunnel.e(...)`, called from
`decoded/smali/??.290/??.34.smali:1942`):
`strings.Replace(input, "\r\n", "\n", -1)` → `strings.genSplit(s, "\n", -1)` → loop:
`TrimSpace`, skip empty, `hashHardwareId(part)`, append to a slice (growslice) →
`liblockedconfig.NewLockedAppConfig(...)` → per-field `util.Efroms` (×13) /
`util.Dtos` (×3) → `liblockedconfig.Efromc` → `liblockedconfig.Efromctoe` → returns the
final `encryptedLockedConfig` string.

### 3.3 The unlock entry points

**`libdarktunnel.NewCa`** — vaddr `0x10d10c0`, body `0x10d1110`, size `0x230` (only
caller: JNI proxy `main.proxylibdarktunnel__NewMa`, exposed as `Libdarktunnel.newMa`):
tries `Dtocfrome(s)`; on success builds a `Ca` from the returned `LockedConfigToExport`;
on error falls back to `dtoc22(s)` (legacy single-layer); if that also fails, `newCa22`.

**`(*Ma).A`** — vaddr `0x10d7210`, body `0x10d7260`, size `0x7b0` (tunnel start):
tries `Dtocfrome(s)`; on success decrypts the inner ciphertext with `Dtoc` and calls
`(*Ca).Err` (validation incl. hardware-ID check); on failure falls back to
`unmarshalEncryptedLockedConfig22` → `dtoc22`.

### 3.4 Device binding

**`libdarktunnel.hashHardwareId`** — vaddr `0x10d20b0`, body `0x10d2100`, size `0x180`:
`concatstring2(nil, SALT, hardwareID)` (SALT = 64-char hex string, `.rodata` `0x363197`)
→ `hash.Sum(concat)` on the package-level SHA-256 hasher (`.bss` `0x1d67d00`,
assigned in `libdarktunnel.init`, `sha256.(*digest).Reset` at init) → hex-encode the
result (`0123456789abcdef` nibble table `.rodata` `0x32bbe4`).
Only caller: `E`. The hasher global is referenced nowhere else for writing — the digest
appended by `Sum` is therefore SHA-256 of the empty string (constant).

**`(*LockedAppConfig).IsHardwareIdAllowed`** — vaddr `0x10c0720`, size `0xe0`:
reads `HashedHardwareIdList` (struct offset `0x70`/`0x78`); empty list → returns true;
otherwise string-compares the device's hash against each entry.
Msgpack field names present in the binary: `HardwareId`, `HardwareIdList`,
`HashedHardwareIdList`, `IsHardwareIdAllowed`, `hashedHardwareId`, `hashedHardwareIdList`.

**Where the device's own hardware ID comes from — UNRESOLVED:** no `ANDROID_ID`,
`Build.SERIAL`, `ro.serialno` or "hardware" string exists in the app smali or in
`libgojni.so` strings (searched). The lock UI passes the ID list as a plain string
parameter to `Libdarktunnel.e(...)`; how the app obtains the *current device's* ID for
the unlock check was not traced (likely a gomobile callback via the `Ia`/`Ib` interfaces
passed to `newMa`, or a value the Java layer supplies — not proven).

### 3.5 Related Go types (pclntab, PROVEN present)

`lockedConfigJSON`, `lockedSshConfig`, `lockedDnsttConfig`, `lockedInjectConfig`,
`lockedV2RayConfig` and `encryptedLocked*` variants, all with msgpack `UnmarshalMsg`;
`unmarshalEncryptedLockedConfig22`; `hashHardwareId`; `newCa22`, `NewCa`, `newCa`, `Ca`,
`Rb`, `Ma`, `Ia`, `Ib`, `R`, `E`, `init`. Linked crypto packages include `crypto/aes`
(+GCM), `crypto/chacha20poly1305`, `crypto/hkdf`, `crypto/hmac`, `crypto/sha256/512`,
`crypto/md5`, `crypto/des`, `crypto/rc4`, `golang.org/x/crypto/scrypt`. Only AES-CFB is
used on the locked-config path.

### 3.6 Protections (brief, as they bear on the mechanism)

- Obfuscation: R8 in dex (unicode-obfuscated package names); Go binary stripped but
  pclntab intact (all function/type names recoverable).
- Root/emulator detection: **none found** in the app smali or manifest (no RootBeer /
  `isRooted` / Magisk / SafetyNet / Play Integrity strings).
- Cert pinning: **none found** — no `CertificatePinner` / `pin-sha256` strings, no
  `networkSecurityConfig`.
- License check: the lock itself *is* the licensing mechanism (server-side licence
  server was not investigated; the `encryptedLockedConfig` path is fully client-side
  and uses only hardcoded keys).
- The above "none found" is scoped to the dex/manifest search; native-side checks inside
  `libgojni.so` were not exhaustively ruled out.

---

## 4. Evidence table

| Claim | Evidence |
|---|---|
| Link = `darktunnel://` + base64url JSON | `decoded/smali/??.290/??.34.smali` (flag `0xa` = URL_SAFE\|NO_WRAP); sample file outer layer |
| `encryptedLockedConfig` stored as TEXT | `decoded/smali/??.287/?.2.smali:53` (CREATE TABLE), `:634`, `:647`; `:?.3.smali:112` (INSERT) |
| Java does no crypto | 0 `javax/crypto` uses in app smali |
| Engine = `github.com/aztecrabbit/libdarktunnel` | Go module path in pclntab; upstream repo 404 |
| Outer decrypt = AES-256-CFB, 32B key | `Dtocfrome` `0x10c4000`: `aes.NewCipher` key `.rodata 0x343455` len `0x20`; `newCFB(...,1)` |
| Inner decrypt = AES-192-CFB, 24B key | `dtoc22` `0x10d1970`: `aes.NewCipher` key `.rodata 0x336e61` len `0x18`; `newCFB(...,1)`; `Dtoc` `0x10c3110` same key |
| IV = same 16 bytes everywhere | `dtoc22` IV header `0x1d48310` → backing `0x1c70c60`; `Dtocfrome`/`Efromctoe` IV header `0x1d48390` → backing `0x1c70c80`; `Efromc` IV header `0x1d48370`; `util` IV header `0x1d483b0` → backing `0x1c70c90`; all three backings hold identical bytes |
| Base64 = URL encoding with padding | `DecodeString`/`EncodeString` on shared `Encoding` global `.bss 0x1d66680` in all four functions; sample string alphabet (`-`/`_` present, `+`/`/` absent, `=` padding, len % 4 == 0) |
| Double encryption (lock) | `E` → `Efromc` (AES-192) → `Efromctoe` (AES-256 + base64); `NewCa`/`(*Ma).A` try `Dtocfrome` first, then `dtoc22` |
| HWID hash = `hex(SALT \|\| hwID \|\| SHA256(""))` | `hashHardwareId` `0x10d2100`: `concatstring2` + interface `Sum` (itab fun[3] = `Sum`); hasher global `0x1d67d00` written only in `init`, never Written to (full ADRP scan) |
| Empty HWID list = any device allowed | `IsHardwareIdAllowed` `0x10c0770`: `cbz len → return 1` |
| Lock entry from Java | `decoded/smali/??.290/??.34.smali:1942` → `Libdarktunnel.e(...)` → `main.proxylibdarktunnel__E` → `libdarktunnel.E` |
| Unlock entry from Java | `Libdarktunnel.newMa` → `main.proxylibdarktunnel__NewMa` → `NewCa`; `(*Ma).A` at tunnel start |

## 5. Honest limits — UNPROVEN / UNRESOLVED

1. **Round-trip proof:** the mechanism was proven from disassembly only. No locked config
   was decrypted (the user's sample was not touched beyond the outer base64 layer and an
   alphabet check), so there is no byte-level round-trip confirmation.
2. **Which base64 `Encoding` exactly:** proven to be URL-with-padding by the sample
   alphabet + call sites; the runtime assignment site of the `Encoding` global
   (`0x1d66680`) was not traced (init.0 stores two other globals at `0x1d66e18`/`0x1d66e20`).
3. **The three `util.Dtos` calls inside `E`:** three input fields are decrypted before the
   lock is built — which fields and why (probably fields that arrive already-encrypted
   when re-locking) was not mapped to Java parameter names.
4. **Where the device's own hardware ID comes from** for the unlock check (§3.4).
5. **`(*Ca).Err` validation details** beyond the hardware-ID check (expiry? password?) —
   not disassembled.
6. **The second hasher global** (`.bss` `0x1d67d20`, used by `NewLockedAppConfig` /
   `IsPasswordAllowed`, same `Sum(b)` pattern) — presumably a password check; not traced.
7. **Field layout of `LockedConfigToExport` / `lockedConfigJSON`** (which msgpack field
   holds the inner ciphertext, which holds the hashed-ID list) — field names are known
   from strings, exact offsets were not fully mapped.
8. Native-side root/emulator detection was not exhaustively ruled out (§3.6).

## 6. Security notes (for the user, not a how-to)

- Both AES keys + the IV are hardcoded and identical in every copy of the app. Anyone
  who extracts them from the APK can decrypt any `encryptedLockedConfig` ever produced
  by this version. There is no per-user/per-device key and no KDF.
- The hardware-ID "hash" is reversible (the ID is present in hex), so the allow-list is
  not a cryptographic binding — it only stops casual reuse.
- The double layer (AES-192 inside AES-256) adds no security beyond the outer key, since
  both keys ship in the same binary.
- No credentials, server addresses, bug hosts, or SSH data from any config are included
  in this report. The user's sample config was not decrypted.

---

*Static REA only. Source XAPK retained on disk per user rule (27 Nov 18:40).*
*Key material values: local-only file, never pushed.*
