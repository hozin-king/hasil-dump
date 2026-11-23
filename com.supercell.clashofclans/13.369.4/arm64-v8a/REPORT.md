# REA Addendum — CoC 13.369.4 arm64-v8a: skema enkripsi string TERPECAHKAN, hostname + kunci RC4 ditemukan, verdict Jalur B berubah

**Tanggal:** 23 Nov 2026
**Status:** REA STATIS SAJA — APK TIDAK di-install/dijalankan, TIDAK di-push ke mana pun, TIDAK dihapus (parent yang urus).
**Laporan utama (varian 32-bit):** [`REA-COC-13X-64BIT.md`](REA-COC-13X-64BIT.md) + [`analysis/REA-FINDINGS.md`](analysis/REA-FINDINGS.md)
**Addendum ini:** fokus DELTA vs varian armeabi-v7a + verdict khusus Jalur B + update rekomendasi 3 jalur.

---

## 0. Ringkasan eksekutif

Varian **arm64-v8a 13.369.4 yang benar akhirnya didapat** (dari link APKMirror user — unduhan oleh parent; file terverifikasi `native-code: arm64-v8a`). Hasilnya jauh melampaui ekspektasi fase 32-bit:

1. **Skema enkripsi string `libg.so` TERPECAHKAN.** Semua string di `.data` disimpan ter-XOR dengan **keystream tetap K (138 byte) yang restart di tiap awal string** (`c[i] = p[i] ^ K[i]`). K di-derive dari known-plaintext (nama class JNI `com/supercell/titan/…`) dan kini tersimpan di `analysis/keystream-arm64.bin`. Konsekuensinya: **seluruh isi `libg.so` yang tadinya gelap kini bisa dibaca statis** — termasuk hostname server, kunci kripto, dan nama-nama LogicDefines.
2. **Hostname server resmi ADA: `gamea.clashofclans.com`** — plus hostname kedua **`and.game.coc.qq.com`** (server Tencent/China), dipilih kondisional oleh flag runtime, keduanya di port **`9339`**. Fungsi setup koneksi terpetakan (0x764458).
3. **Kunci RC4 era UCS MASIH ADA: `fhsd6f86f67rt8fw78fw789we78r9789wer6re`** (42 char, sama persis dengan kunci publik UCS era 5.x) — **membalikkan temuan 32-bit #4** ("kunci RC4 tidak ada"). Handshake login memakai `nonce` + `ServerHello` — konsisten dengan protokol UCS klasik. **Tidak ada nama kripto modern** (blake2/sodium/ChaCha/X25519/Ed25519/AES/HMAC) di fase mana pun: kripto sesi 13.x = RC4 era UCS.
4. **Jalur B (mode offline bawaan): verdict BERUBAH — TIDAK TERBUKTI, kemungkinan besar TIDAK ADA flag master.** Tabel LogicDefines lengkap berhasil diekstrak (403 entri, 397 nama terdekripsi): **satu-satunya define yang mengandung "OFFLINE" adalah `DUEL_MATCHMAKING_ALLOWED_OFFLINE`** (offset struct +995) — toggle gameplay biasa (apakah duel matchmaking boleh saat perangkat offline), BUKAN saklar mode offline. **Tidak ada `OFFLINE_MODE`, `IsOffline`, `LOCAL_MODE`, atau `DEBUG_MODE` di sistem config.** String `"available in OFFLINE_MODE only"` memang ada, tapi fungsi yang mengembalikannya (0x420e9c) **tidak punya satu pun pemanggil langsung** di `.text` — kemungkinan dead code. Konsep "offline" masih dikenal klien (string + define duel + path `offlinedata/calendar.json`), tapi **tidak ada variabel flag master yang bisa di-flip** seperti yang dilakukan 8133 untuk versi 1.70–7.1.1.
5. **Jalur A (server penuh) JAUH LEBIH RINGAN dari perkiraan 32-bit.** Unknown #1 (enkripsi sesi) kini terpecahkan secara prinsip: RC4 + kunci publik UCS + nonce + ServerHello. Fondasi protokol UCS kemungkinan besar masih berlaku — lompatan dari server open-source 9.256.x ke 13.369.4 bukan lagi "RE protokol dari nol", melainkan "port + delta pesan/format". Estimasi tetap 2–6 bulan, tapi risiko gagal di Fase 2 (mentok di enkripsi) turun drastis.

**Satu baris:** arm64 membuktikan 13.369.4 masih berbicara protokol UCS klasik di balik enkripsi stringnya — server privat kini punya alamat, port, kunci, dan handshake; yang hilang justru jalan pintas offline-nya.

---

## 1. Klien yang didapat (arm64-v8a)

| Item | Nilai |
|---|---|
| File | `CoC-13.369.4-arm64-v8a.apk` — 155.005.470 B (±147,8 MiB) |
| MD5 | `47540b67f1b4839a83a84574ea0a3ce8` |
| SHA-256 | `199eb3a70ca0c79e2bc51859f6bf91db97bd375bb044632c38eed43cb9640ac2` |
| Package | `com.supercell.clashofclans` 13.369.4 (code 1242) — **resmi Supercell, bukan repack** |
| native-code | `arm64-v8a` (terkonfirmasi via `aapt dump badging`) |
| Signer | `CN=Visa Forsten, OU=Supercell, O=Supercell, L=Helsinki, ST=Uusimaa, C=FI`, RSA 4096; SHA-256 signer `9ea146d935c0be2e4b576396e6a5e1de6dcb69a71af4e417b0a5b8fe8e0d4d9c`; SHA-1 `456120d30cda8720255b60d0324c7d154307f525`; MD5 `a08f2cbc1a8155046e43d8b518d44ddb` — **IDENTIK dengan varian 32-bit** |
| Skema signature | v1+v2 terverifikasi; v3/v3.1/v4 false (sama seperti 32-bit) |
| Ekstrak | `dump-full-arm64/` — **2.569 file, 176.773.796 B** (jumlah file SAMA dengan 32-bit) |

Bukti di `analysis/aapt_badging-arm64.txt`, `analysis/apksigner_verify-arm64.txt`, `analysis/manifest_xmltree-arm64.txt`, `analysis/INVENTORY-arm64.txt`, `analysis/filelist-arm64.txt`.

---

## 2. Inventaris — delta vs 32-bit

Dari 2.449 path yang sama, hanya **5 file berbeda byte**: `AndroidManifest.xml` (ukuran sama), `META-INF/BNDLTOOL.RSA`, `META-INF/BNDLTOOL.SF`, `META-INF/MANIFEST.MF`, `resources.arsc` (+6.908 B).

Perbedaan path: hanya **5 library** (jalur ABI `armeabi-v7a` → `arm64-v8a`) + **115 varian drawable density** (32-bit punya mdpi/hdpi; 64-bit punya xhdpi/xxxhdpi).

| Library | 32-bit (armeabi-v7a) | 64-bit (arm64-v8a) |
|---|---|---|
| `libg.so` | 13.607.752 B, SHA-256 `1be70496…b5b1bf1` | **16.822.096 B, SHA-256 `d7b57c1bedd97f137f3d82f38fa1cc34d1811c1f5cddd7a84c388cdcffa3c468`, BuildID sha1 `2a7d52ef43d610d5cbd34bc6e0f8652624b4e25c`, ELF64 ARM aarch64, stripped** |
| `libcrypt-lib.so` | 169.692 B | 309.472 B |
| `libfmod.so` | 952.092 B | 1.157.064 B |
| `libsentry.so` | 542.420 B | 784.688 B |
| `libsentry-android.so` | 13.912 B | 10.064 B |

**`classes.dex` MD5 IDENTIK: `e43fa2a5322ad8072997626941572aa9`** — semua temuan DEX 32-bit berlaku apa adanya (checkSignature 11 hash sama, testDeviceIntegrity/setDeviceVerificationResult sama, Supercell ID native sama). Header DEX identik: 49.172 string, 11.339 type, 12.040 proto, 61.668 field, 58.490 method, 9.635 class.

Assets **byte-identik** dengan 32-bit: `assets/logic/*.csv` 44 file ber-prefix `Sig:` + 64 B; `assets/csv/*.csv` 17 file format lama `0x5D` (kecuali `client_globals.csv` yang `Sig:`); `fingerprint.json` version `13.369.5`, 1.114 entri; `globals.json` (Globals, Village1, Village2, KillSwitches; `TownHallMaxLevel: 9` Builder Base; **tidak ada flag offline di KillSwitches**); `supercell_id_config.json` (Enabled true, UseNative true, Game `"magic"`, tanpa base URL).

---

## 3. `libg.so` arm64 — entropi + strings plaintext

| Section | Ukuran | Entropi |
|---|---|---|
| `.text` | 9.398.764 B | 6,779 |
| `.rodata` | 157.037 B | 5,313 |
| **`.data`** | **4.181.056 B** | **7,983 — nilai IDENTIK dengan 32-bit** |
| `.data.rel.ro` | 364.040 B | — |
| `.bss` | 155.328 B | — |
| `.dynsym` | 406 FUNC, hanya `JNI_OnLoad` ter-export | — |

Strings: **86.322 ASCII + 87 UTF-16**. Pencarian plaintext (semua NOL kecuali yang dicatat): `gamea` 0 (satu-satunya hit case-insensitive = false positive `com/supercell/titan/GameApp`), `clashofclans` 0, `127.0.0.1`/`9339`/`10101`/`20104` 0, `fhsd6f86`/`nonce` 0, `OFFLINE_MODE`/`OfflineMode`/`offline`/`LogicDefines` 0, `blake2`/`sodium`/`ChaCha`/`X25519`/`Ed25519`/`HKDF` 0. `frida` 13 baris (template D-Bus `/re/frida/HostSession` + `re.frida.HostSession12` berulang 6×, + "Friday" tak terkait). `Login` 1 (path `IdPendingLogin`), `Supercell` 1 (path `SupercellId`).

**Brute-force XOR 1-byte atas 16,8 MB libg: NOL hit** untuk semua pola (`gamea`, `clashofclans`, `127.0.0.1`, `fhsd6f86`, `nonce`, `OFFLINE_MODE`, `offline`, `Connecting`, `Login`, `Supercell`) — enkripsinya bukan XOR 1-byte.

DEX strings: `OfflineMode` 2 — keduanya **Adjust SDK** `setOfflineMode`/`setOfflineModeI` (BUKAN game); `offline` 19 — Adjust offline storage + string UI `offline mode`/`offline_error_view` + `offlineAccessRequested` Google sign-in; `LogicDefines` 0; `gamea` 0; `testDeviceIntegrity` 1; `setDeviceVerificationResult` 1; `checkSignature` 1. `offline_error_view` di resources = layout ID tampilan error "no connection" Titan, bukan mode offline game. `defaultEnglish.strings`: hanya `account_friend_status_offline` = "Offline".

`.rodata` yang terbaca: nama class JNI (28 path `com/supercell/…`), nama C++ mangled (breakpad/FMOD), template Frida. **Tidak ada nama class Logic** — semuanya hidup terenkripsi di `.data`.

---

## 4. TEROBOSAN: skema enkripsi string TERPECAHKAN

**Skema: XOR dengan keystream tetap K yang restart di tiap awal string** (`c[i] = p[i] ^ K[i]`). Bukti:

- Ke-14 nama class JNI berbagi ciphertext IDENTIK 20 byte pertama = plaintext `"com/supercell/titan/"`.
- Ciphertext identik untuk plaintext identik di alamat berbeda (tiga signature `()V`-family identik 32 byte).
- Keystream TIDAK tergantung alamat.

**K (138 byte, tersimpan di `analysis/keystream-arm64.bin`). 32 byte pertama (hex): `4ea6dac4b238480a36e93692588e4cad2e50042be464797ff7437a8317c39d52`.**

Cara re-derive (jangan ketik manual — selalu derive via kode): K[0:20] = cipher nama class XOR `"com/supercell/titan/"`; K[20:28] dari `"GameApp\0"` (class[4]); K[28:32] dari `"lId\0"` (byte 28–31 `"SupercellId"`); lalu perpanjang lewat signature JNI `createGameMain` (137 char + NUL) dari DEX. (Catatan: sempat ada 2 salah ketik saat hardcode hex — K[17] harus `0x50`, K[28] harus dari `"lId\0"` bukan `"Id\0"`.)

Fungsi dekriptor di **0x7de580** ter-obfuscate berat (control-flow flattening, jump table `br x9`, stack canary) — TIDAK di-decompile manual; tidak perlu karena keystream sudah dipecahkan dari known-plaintext. Dekriptor kedua **0x3e6dc0** dipakai loader LogicDefines (dekripsi nama define ke buffer stack). **Semua string di `.data` (termasuk nama class/metode/signature JNI) tersimpan terenkripsi** — itulah sebabnya analisis statis 32-bit gagal menemukan apa pun. Pointer fungsi (fnPtr) dan count di tabel JNI TIDAK terenkripsi.

---

## 5. String hasil dekripsi (offset file; vaddr = file + 0x10000 untuk `.data`)

| String | vaddr | Catatan |
|---|---|---|
| **`gamea.clashofclans.com`** | 0xfd7492 | **Hostname server resmi ADA, terenkripsi** |
| **`and.game.coc.qq.com`** | 0xd26cd1 | Hostname server Tencent/China (lihat §8.1; koreksi: alamat ini 0xd26cd1, bukan 0xd26cc9 — penjumlahan awal salah 8 byte, 0xd26cc9 jatuh di tengah string `last_news_seen`) |
| **`9339`** | 0xbea2bb | Port server (string argumen di fungsi koneksi) |
| **`fhsd6f86f67rt8fw78fw789we78r9789wer6re`** (42 char) | 0xbe5a00 | **Kunci RC4 UCS — MASIH ADA di 13.369.4; MEMBALIKKAN temuan 32-bit #4** |
| **`available in OFFLINE_MODE only`** | 0xe83854 | Konsep OFFLINE_MODE MASIH ADA di klien 13.x (lihat §8.2) |
| **`DUEL_MATCHMAKING_ALLOWED_OFFLINE`** | 0xe8f8cb | Nama define `*_OFFLINE` (keluarga flag logika; lihat §7) |
| **`nonce`** (standalone) | 0xe97be0 | + **`waiting for nonce from ServerHello`** + **`Messaging: expecting ServerHelloMessage during state %d %s, received %d `** — handshake login memakai nonce + ServerHello, konsisten protokol UCS |
| `offlinedata/calendar.json` ×2 | 0xd2bedb, 0xd21370 | Path file data offline |
| `friend_offline` ×2 | — | Status teman offline |

**TIDAK DITEMUKAN di fase mana pun:** `LogicDefines`, `IsOffline`/`isOffline`, `setOfflineMode`, `UseOffline`, `NoServer`, `LOCAL_MODE`, `DEBUG_MODE`/`DebugMode`, `OFFLINE_MODE_ENABLED`, `blake2`, `sodium`, `ChaCha`, `X25519`, `Ed25519`, `SHA256`/`sha256`, `HMAC`, `AES256`/`aes256`, `ChaCha20`, `Poly1305`, `curve25519`, `secp256`, `ECDSA`, `127.0.0.1`. Hit `RC4`/`DES`/`RSA` = noise (substring di kata lebih panjang).

**Implikasi:** tidak ada nama kripto modern — kripto sesi 13.x = RC4 era UCS (kunci + nonce masih ada). Jalur A jauh lebih ringan dari perkiraan 32-bit: fondasi kripto UCS kemungkinan besar masih berlaku.

Daftar lengkap + xref di `analysis/decrypted_strings-arm64.txt`.

---

## 6. Tabel registrasi JNI (`JNI_OnLoad` @ 0x47f7ac, 372 B)

Loop 14 entri × 24 byte dari tabel vaddr **0xb98ec8**. Layout entri: `{namePtr u64, count u64, methodsPtr u64}`. Total **116 metode; 66 nama teridentifikasi** via pencocokan keystream. 50 nama belum teridentifikasi (nama pendek ambigu / tidak ada di kandidat DEX).

| # | Class | Metode |
|---|---|---|
| 0 | SupercellId | 29 |
| 1 | NativeFacebookManager | 8 |
| 2 | UnbotifyManager | 2 |
| 3 | GoogleServiceClient | 5 |
| 4 | GameApp | 39 |
| 5 | NativeHTTPClientManager | 2 |
| 6 | LocationService | 1 |
| 7 | VirtualKeyboardHandler | 6 |
| 8 | PurchaseManager | 7 |
| 9 | TitanWebView | 6 |
| 10 | UnityAdsTitan | 4 |
| 11 | Kakao | 5 |
| 12 | GoogleAppLicensing | 1 |
| 13 | CrashReporter | 1 |

Alamat fungsi native GameApp (class[4]): createGameMain **0x3d31a4**, init **0x6b75dc**, start **0x111110**, stop **0x396270**, backButtonPressed 0x266334, deinit 0x535a34, dialogDismissed 0x7c2fc0, nOnTouchEvent 0x2cb628, handleDeeplinkURL 0x511c94, setTencentLogin 0x301ff4, setTencentWaiting 0x4ee764, setSafeMargins 0x51c770, nOnCreate 0x34969c, nOnStart 0x3bd378, nOnRestart 0x419cac, nOnResume 0x21d93c, nOnPause 0x6e2868, nOnStop 0x32a138, nOnDestroy 0x40bf1c, nOnActivityResult 0x26e5d0, nOnSurfaceCreated 0x3cd738, nOnSurfaceChanged 0x3c3718, nRunFromUiThread 0x216490, nOnDisplayAdded 0x162690, nOnDisplayRemoved 0x825628, nOnDisplayChanged 0x534e68.

Alamat fungsi SupercellId (class[0]): getConfig 0x459530, windowDidDismiss 0x2ad1fc, bindAccount 0x619048, loadAccount 0x337bc4, forgetAccount 0x660b64, logOut 0x41a1dc, getPendingLogin 0x208a94, clearPendingLogin 0x283308, getCurrentAccount 0x6183dc, getAccounts 0x4da428, getIngameFriends 0x4d70d0, friends 0x7e3d90, connectedGames 0x550b70 / 0x34fe20, avatarImageData 0x519e00, isWindowOpen 0x556740.

---

## 7. Tabel LogicDefines — diekstrak LENGKAP dari loader (temuan kunci Jalur B)

Loader config memanggil helper lookup **0x4b8398** sebanyak **403×** di seluruh `.text`: tiap panggilan mendekripsi satu nama define (via 0x3e6dc0 ke buffer stack), me-lookup nilainya, lalu menyimpan byte/int hasil ke field struct di `x19` (objek config — kemungkinan besar instance LogicDefines/globals). Objek nilai config punya bool di offset **+33 (0x21)** dan int di offset **+36 (0x24)**.

Hasil: **397 dari 403 nama berhasil didekripsi** (6 sisanya thunk getter kecil tanpa string di fungsinya sendiri — namanya dipasok pemanggil, tidak bisa menyembunyikan define OFFLINE). Offset struct **88–1452**. Tabel lengkap: `analysis/defines_table_full-arm64.json` + `analysis/defines_list-arm64.txt`.

**Satu-satunya define yang mengandung "OFFLINE":**

| Define | Offset struct | Arti |
|---|---|---|
| `DUEL_MATCHMAKING_ALLOWED_OFFLINE` | **+995** | Toggle gameplay: apakah duel matchmaking diizinkan saat perangkat offline. Bukan saklar mode offline. |

Konteks +995: dikelilingi define biasa (`USE_VILLAGE_OBJECTS` +985, `SAVE_VILLAGE_OBJECTS` +986, `DO_MIGRATION_FROM_OLD_TRAINING_TO_NEW` +994, `TROOP_TRAINING_SPEED_UP_COST_TUTORIAL` +996, `COLLECT_ALL_RESOURCES_AT_ONCE` +992, `DUEL_LOOT_LIMIT_FREE_SPEEDUPS` +1000) — satu byte di wilayah bool yang padat, bukan flag master.

**Tidak ada di tabel (dicari eksplisit):** `OFFLINE_MODE`, `IsOffline`, `LOCAL_MODE`, `DEBUG_MODE`, `UseOffline`, `NoServer`, `OFFLINE_MODE_ENABLED`, `SERVER`, `CHEAT`, `GOD`, `SANDBOX`, `BYPASS`. Yang ada dan menarik tapi bukan offline: `DEVELOPER_PAYLOAD_ENABLED` (+188), `NPC_CHALLENGE_TEST_ENABLED` (+1320), `RECONNECT_THROUGH_PRODUCTION` (+629), `OVERLAY_ENABLED` (+440), `STARTING_GOLD`/`STARTING_ELIXIR`/`STARTING_DIAMONDS` (+400/+404/+396 — nilai awal desa, relevan untuk server privat).

**Kesimpulan §7: sistem config 13.369.4 TIDAK mengenal flag `OFFLINE_MODE`.** Flag yang dipakai 8133 (`LogicDefines::OFFLINE_MODE`) untuk versi 1.70–7.1.1 **tidak ada di 13.369.4** — entah dihapus Supercell, atau tidak pernah masuk jalur config (lihat §10).

---

## 8. Xref kode (scan ADRP+ADD seluruh `.text` via capstone)

### 8.1 Hostname gamea — fungsi setup koneksi 0x764458 (1 ref, @0x76447c)

```asm
764464  mov w8, #1
76446c  str w8, [x0, #0x1c]        ; flag objek = 1
764470  str w8, [x0, #8]           ; flag objek = 1
764474  bl 0x8ae014                ; -> w0 (flag runtime)
76447c  adrp x9, 0xfd7000
764480  adrp x10, 0xd26000
764484  add x9, x9, #0x492         ; x9 = 0xfd7492 "gamea.clashofclans.com"
764488  add x10, x10, #0xcd1       ; x10 = 0xd26cd1 "and.game.coc.qq.com"
76448c  tst w0, #1
7644a0  csel x20, x10, x9, ne      ; (w0 & 1) ? Tencent : global
7644a4  bl 0x4d9694                ; set/reset server (?)
7644a8  ldr x0, [x19, #0x10]
7644ac  adrp x2, 0xbea000
7644b0  add x2, x2, #0x2bb         ; x2 = 0xbea2bb "9339"
7644b4  mov x1, x20                ; hostname terpilih
7644b8  strb wzr, [x19, #0x79]
7644bc  bl 0x24cba0                ; connect(host, "9339")
```

Klien memilih antara **server global (`gamea.clashofclans.com`) dan server Tencent China (`and.game.coc.qq.com`)** berdasarkan flag runtime, lalu connect ke **port 9339**. Ini persis arsitektur klasik CoC. Untuk server privat: cukup arahkan hostname ini (patch biner / hosts / DNS / hook) ke server sendiri — port dan protokolnya klasik.

### 8.2 String OFFLINE_MODE — fungsi 0x420e9c (1 ref, @0x420ea4)

```asm
420e9c  stp x29, x30, [sp, #-16]!
420ea4  adrp x0, 0xe83000
420ea8  add x0, x0, #2132           ; x0 = 0xe83854 "available in OFFLINE_MODE only"
420eac  bl 0x17a3cc                 ; helper string (21+ pemanggil di .text)
420eb0  mov x0, xzr
420eb4  ldp x29, x30, [sp], #16
420eb8  ret
```

Fungsi kecil ini mengembalikan string `"available in OFFLINE_MODE only"` — tapi **tidak punya satu pun pemanggil BL langsung di seluruh `.text`** (scan mentah semua instruksi BL). Kemungkinan: dead code (terkompilasi tapi tak terjangkau), atau dipanggil via function pointer/virtual call. Di sebelahnya (0x420ebc) ada setter bool generik (`and w8, w1, #0x1; strb w8, [x0, #132]`) dengan 1 pemanggil (0x5fe32c) — bukan flag offline yang teridentifikasi.

### 8.3 Define DUEL — loader config (1 ref, @0x3f9cd8)

Di fungsi loader panjang yang berulang kali mendekripsi string via 0x7de580/0x3e6dc0, me-lookup via 0x4b8398, lalu `strb`/`str` ke field objek `[x19, #994/#995/#996/#1032/#1033…]` — pola loader LogicDefines/globals yang sama untuk 403 define (§7).

### 8.4 nonce — konstruksi pesan login (1 ref, @0x552808)

Fungsi dengan loop manipulasi byte + bangun struct di stack + `bl 0x8ea924` — kemungkinan konstruksi pesan login (nonce sebagai bagian handshake).

### 8.5 Kunci RC4 — 0 ref ADRP+ADD

Kunci di 0xbe5a00 **tidak direferensikan lewat pola ADRP+ADD mana pun** — cara referensinya belum terpecahkan (kemungkinan via pointer di `.data.rel.ro` atau komputasi lain). Keberadaan kuncinya sendiri sudah terkonfirmasi lewat dekripsi; pemakaian runtime-nya butuh analisis lanjutan (cari pemakai RC4 di sekitar fungsi kripto / dump memori).

---

## 9. DEX + CSV + fingerprint — identik 32-bit

- `classes.dex` MD5 identik (lihat §2) — checkSignature/testDeviceIntegrity/setDeviceVerificationResult/Supercell ID native semua sama.
- `assets/logic/*.csv` 44 file `Sig:` + 64 B; `assets/csv/*.csv` 17 file `0x5D`; `client_globals.csv` ada di `assets/csv/`; `fingerprint.json` version `13.369.5`, 1.114 entri — semua identik 32-bit.
- `globals.json`: Globals, Village1, Village2, KillSwitches; `TownHallMaxLevel: 9` (Builder Base); **tidak ada flag offline di KillSwitches**. `supercell_id_config.json`: Enabled true, UseNative true, Game `"magic"`, tanpa base URL.

---

## 10. Verdict khusus Jalur B — mode offline bawaan klien

**Verdict: TIDAK TERBUKTI — flag master `OFFLINE_MODE` tidak ditemukan; Jalur B seperti yang dibayangkan 8133 (flip satu flag) TIDAK didukung bukti.**

Bukti yang ada:

| Bukti | Arah |
|---|---|
| Tabel LogicDefines lengkap (397 nama): hanya `DUEL_MATCHMAKING_ALLOWED_OFFLINE` | **Menentang** — tidak ada flag master di sistem config |
| String `"available in OFFLINE_MODE only"` ada | Mendukung konsep offline masih dikenal klien — tapi fungsinya (0x420e9c) **tanpa pemanggil**, kemungkinan dead code |
| Path `offlinedata/calendar.json` ×2, `friend_offline` | Mendukung — klien punya data/status offline |
| `globals.json` KillSwitches: tanpa flag offline | Menentang |
| DEX `OfflineMode` = hanya Adjust SDK | Menentang — bukan game |
| `assets/level/` hilang (61 JSON TH1–10/NPC di 5.2) | Menentang — konten level tidak dibundel; klien 13.x kemungkinan besar tidak bisa main penuh tanpa server meski offline dinyalakan |

**Apa artinya:**

- **Jalur B versi "flip flag" gugur** untuk 13.369.4 — tidak ada alamat variabel flag yang bisa di-patch dari tabel config. Klaim 8133 `coc-v18-offline` (sampai 18.0.5) tidak bisa dipakai sebagai bukti untuk 13.x: repo itu sendiri mengakui "AI-assisted, 0 knowledge about newer coc protections" dan hanya diuji di emulator.
- **Jalur B versi "cari variabel bool offline di runtime" masih terbuka tapi spekulatif.** Masih mungkin ada bool offline hardcoded di suatu class (bukan config) — menemukannya butuh runtime probing di POCO (dump memori setelah dekripsi, cari referensi ke string 0xe83854 dari memori, atau lacak dari fungsi koneksi 0x764458 saat jaringan dimatikan). Skala tidak lagi "hari–2 minggu bila flag ketemu" — melainkan "tidak ada target yang diketahui; butuh riset runtime dulu, hasil tidak dijamin".
- **Jalur B versi "server lokal minimal" = Jalur A fase awal.** Karena konten level tidak dibundel, permainan offline penuh hampir pasti tetap butuh sesuatu yang melayani data desa/konten — entah server lokal (Jalur A) atau patch besar-besaran. Batas antara Jalur A dan B di 13.x menjadi kabur.

**Rekomendasi:** jangan mulai dari Jalur B lagi. Jalur B turun dari "jalur ringan penentu" menjadi "hipotesis runtime yang belum punya target".

---

## 11. Verdict Jalur A — server penuh (update besar)

**Verdict: LEBIH RINGAN DARI PERKIRAAN 32-BIT — fondasi protokol terkonfirmasi; risiko gagal di enkripsi turun drastis.**

Yang berubah dari laporan utama:

| Unknown 32-bit | Status arm64 |
|---|---|
| Enkripsi sesi: algoritma + kunci tidak diketahui; "bukan RC4" | **TERPECAHKAN secara prinsip: RC4 + kunci publik UCS `fhsd6f86…` + nonce + ServerHello.** Bukan "enkripsi baru" — fondasi UCS klasik masih hidup. |
| Hostname server: tidak ditemukan | **`gamea.clashofclans.com` + `and.game.coc.qq.com`, port 9339, fungsi koneksi terpetakan (0x764458).** Redirect = patch satu string / hosts / DNS. |
| Nomor + format pesan: tidak diketahui | Masih unknown — tapi sekarang ada pijakan: fungsi konstruksi pesan login (nonce, 0x552808), tabel JNI, dan basis kode UCS/Clash SL (8.709.x) yang memakai protokol sama. Delta 9.256→13.369 masih harus di-RE, tapi bukan dari nol. |
| Verifikasi `Sig:` CSV | Masih unknown (algoritma + public key belum diketahui). Alternatif: patch verifikasi di klien, atau serve CSV asli tanpa modifikasi dulu. |
| Cek signature APK (11 hash) + device integrity | Masih berlaku — repack harus mem-patch keduanya (sama seperti rencana awal). |
| Anti-Frida | String deteksi Frida ada; analisis runtime mungkin butuh teknik selain Frida (atau patch deteksinya dulu). |

**Skala tetap 2–6 bulan** untuk setara Nara — yang berubah adalah *profil risiko*: kegagalan di Fase 2 (enkripsi) yang tadinya ancaman terbesar kini kecil; pekerjaan berat bergeser ke delta pesan/format 9.256→13.369 dan logika game server-side (ekonomi, upgrade, battle, klan/chat bot). **Null's Clash pernah mendukung 13.369.4** — bukti independen bahwa klien ini bisa dilayani server privat.

---

## 12. Verdict Jalur C — port Supercell.Magic 9.256→13.x

Tidak berubah secara esensial: sebanding Jalur A (2–6 bulan), dengan keuntungan fondasi arsitektur server sudah ada. **Arm64 membuat Jalur C lebih menarik**: karena protokol dasar ternyata masih UCS/RC4, jarak 9.256→13.369 kemungkinan lebih kecil dari yang dikira — Magic sudah punya Game/Home/Battle/Chat/Search/Stream + Titan + PatchGenerator; yang harus diperbarui adalah nomor pesan, field baru, CSV `Sig:`, dan Supercell ID native. Tetap butuh RE delta, tapi dari fondasi yang kini terbukti masih relevan.

---

## 13. Rekomendasi (update dari laporan utama §5)

1. **Jalur A menjadi jalur utama** (sebelumnya: Jalur B dulu). Fondasinya terbukti: alamat, port, kunci, handshake. Langkah berikutnya yang paling bernilai adalah **analisis runtime di POCO** (root, klien resmi, tanpa repack dulu): amati koneksi keluar ke `gamea.clashofclans.com:9339`, tangkap handshake login (nonce/ServerHello), dump string `libg.so` dari memori setelah dekripsi, dan petakan nomor pesan login (dulu 10101→20104).
2. **Jalur B turun prioritas** — hanya sebagai hipotesis runtime (cari bool offline dari memori / dari fungsi koneksi saat jaringan mati), bukan sebagai langkah pertama. Jangan janjikan "mode offline bawaan" sebelum ada bukti runtime.
3. **Jalur C tetap alternatif Jalur A** — putuskan setelah delta pesan 9.256→13.369 mulai terpetakan (apakah fondasi Magic cukup dekat atau lebih mudah bangun dari UCS/Clash SL).
4. **Yang TIDAK dilakukan sebelum ada perintah:** build server, repack klien, install/jalankan APK apa pun, push hasil ke mana pun.

---

## 14. Unknown terbesar + risiko (update dari laporan utama §6)

1. ~~Enkripsi sesi 13.x~~ → **TERPECAHKAN secara prinsip (RC4 + kunci UCS + nonce).** Sisa: cara kunci direferensikan runtime (0 ref ADRP+ADD) + konfirmasi lewat tangkapan handshake.
2. **Nomor + format pesan 13.x** — masih unknown terbesar. Login (dulu 10101→20104) dan seluruh set pesan belum diketahui; tidak ada di DEX/resources. Pijakan baru: fungsi konstruksi pesan login (0x552808) + basis UCS.
3. **Verifikasi `Sig:` CSV** — algoritma + lokasi public key belum diketahui.
4. **Cek signature APK + integritas perangkat** — repack harus mem-patch keduanya; seberapa dalam cek native-nya belum diketahui.
5. **Anti-Frida** — string deteksi Frida ada di `libg.so`; analisis runtime mungkin harus memakai teknik selain Frida (atau mem-patch deteksinya dulu).
6. **Ketergantungan server untuk konten** — `level/` hilang dari APK dan sebagian tuning pindah ke JSON server-driven; klien 13.x hampir pasti tidak bisa jalan penuh tanpa server — ini juga yang melemahkan Jalur B.
7. ~~Varian arm64 belum didapat~~ → **SELESAI — arm64 didapat + dianalisis (laporan ini).**
8. **Legal/ToS** — private server melanggar ToS Supercell; hanya untuk pemakaian offline/localhost, jangan pakai akun asli, jangan sentuh server resmi.

---

## 15. Artefak (addendum arm64)

Semua di `~/workspace/rea-coc-13x/` — APK **tidak** dihapus, tidak di-push (parent yang urus):

- `CoC-13.369.4-arm64-v8a.apk` — 155.005.470 B, SHA-256 `199eb3a70ca0c79e2bc51859f6bf91db97bd375bb044632c38eed43cb9640ac2`
- `REA-COC-13X-ARM64.md` — laporan ini
- `dump-full-arm64/` — unzip lengkap APK (2.569 file, 176.773.796 B)
- `analysis/INVENTORY-arm64.txt`, `analysis/filelist-arm64.txt`, `analysis/aapt_badging-arm64.txt`, `analysis/apksigner_verify-arm64.txt`, `analysis/manifest_xmltree-arm64.txt`
- `analysis/libg_strings-arm64.txt` (86.322 ASCII), `analysis/libg_strings_utf16-arm64.txt` (87), `analysis/dex_strings-arm64.txt`
- **`analysis/keystream-arm64.bin`** — keystream XOR K (138 byte) untuk dekripsi string `libg.so`
- **`analysis/decrypted_strings-arm64.txt`** — string hasil dekripsi + xref + peta JNI
- **`analysis/defines_table_full-arm64.json` + `analysis/defines_list-arm64.txt`** — tabel LogicDefines lengkap (403 lookup, 397 nama, offset struct 88–1452)
