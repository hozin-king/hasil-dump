# Cinta di Citampi (Citampi Stories) — Full Dump + REA

- **Game:** Citampi Stories (label "Citampi Stories")
- **Package:** `com.ikanasinproduction.cintadicitampi`
- **Versi:** **1.87.5**, versionCode **667** (rilis APKPure 20 Nov 2026)
- **Target:** arm64-v8a, minSdk 29 (Android 10), targetSdk 36 (Android 16)
- **Developer:** Ikan Asin Production (signer `O=Ikan Asin Production`)
- **Sumber:** XAPK APKPure — `Cinta_di_Citampi_1.87.5_APKPure.xapk`
- **Tanggal REA:** 26 Nov 2026

## Hash (SHA-256)
- XAPK: `e760b0638ec26f42833c9e63dd23bc82371908de415d80f7a911ae3f75e116b9` (275.728.420 B)
- base APK: `619244495b7a43f8d10fd4504e99416d83b6ec759647b71cce875677f73cf757` (236.013.570 B)
- config `arm64_v8a` APK: `f705ee4344a13fae46489e33e4419e9caec5d396373eab0047544b9997030418` (39.676.012 B)
- `global-metadata.dat`: `d1676d5e7fe89d65f3295c0a4d02cfb2fb1bc59b10067c911b12c083bb96b946` (13.258.060 B)
- `libil2cpp.so`: `ce2a180b…` (93.227.296 B) — lengkap di `dump/hashes.txt`
- Signer: APK Signature Scheme **v3**, 1 signer, RSA 2048,
  cert SHA-256 `b3cf2753b91b097e1903d308c70a3c10f096d0282da430424a1aa1ef5fdf4321`
  (lengkap: `dump/signer.txt`)

## Engine
**Unity 6000.3.21f1 (Unity 6), IL2CPP**, metadata version 39.
Il2CppDumper v39 berhasil (CodeRegistration `0x5090fe0`,
MetadataRegistration `0x5247278`). 12 dex: **89.447 class, 580.099 method,
311.472 field, 573.928 string**. 25 native lib (AArch64). Detail:
`dump/FINDINGS-dex.md`, `dump/FINDINGS-native.md`.

## Mekanisme save data — PRIORITAS (ketemu + terverifikasi)
Save offline = **JSON UTF-8 dienkripsi AES-256-CBC (PKCS7)**. Format file `.sav`:
`[0]` = `dictSeed` (selalu `0xff`); `[1..48]` = IV (16 B) + Key (32 B)
yang dipermutasi via `System.Random(dictSeed)`; `[49..]` = ciphertext.
Kunci/IV **acak per file** (dibangkitkan saat save ditulis) dan tersimpan di
dalam file itu sendiri — **tidak ada kunci hardcoded di APK**.

- Kelas: `Ikaan.Utility.IkaanDataFormat` (`Encode` RVA `0x24816E4`,
  `Decode` RVA `0x2481FF0`, `_getIndiciesMap` RVA `0x2481E40`);
  `saveHelper` (baca RVA `0x2322E60`, tulis RVA `0x23234AC`,
  `checkTampering` RVA `0x2317A48`, autosave = slot 9 → `save09.sav`).
- Jebakan RNG: `System.Random` di game ini memakai seeding .NET Core
  (`SeedArray[55] = 161803398 - |seed|`, 54 iterasi shuffle) — varian klasik
  .NET Framework menghasilkan nilai salah mulai sample ke-3. Diverifikasi
  10/10 melawan .NET 8 + disassembly ctor Random (`0x4442358`).
- **Decrypt terverifikasi:** `save00_0_sgx4.sav` (81.441 B) → JSON valid,
  **376 entri** `{key, value}`; `save09_1_74mu.sav` (81.505 B) → JSON valid,
  **377 entri**. Key antara lain `MONEY`, `BANK_MONEY_SAVING`,
  `FURNITURE_LEVEL`, `COOKING_LEVEL`, `MANAGEMENT_SKILL`, … (nama key saja;
  **nilai save user tidak disertakan di repo ini**).
- Decryptor: `citampi_decrypt.py` di folder ini (tanpa kunci hardcoded —
  kunci dibaca dari header tiap file). Cara pakai:
  `python3 citampi_decrypt.py <file.sav>` → menulis `<file.sav>.decrypted.json`.
- Detail lengkap: `dump/FINDINGS-save.md`.

## IAP
Google Play Billing (274 class billingclient) + Unity Purchasing + **Noctua**
(`NoctuaIAPProcessor`, `sdk-api-v2.noctuaprojects.com`). `IAPLibrary` memuat
~60 product ID; **67 product ID** `com.ikanasinproduction.cintadicitampi.*`
(autosave, baju pink/alfa/yomart, motor, ojeg per area/toko, bundle 1–3,
kupon, kostum robot/pocong/anjing, interactive date, anak yatim, …).
Status IAP per produk disimpan di save (`ADSIAP`, `GO*IAP`, …), tetapi IAP
adalah pembelian server-side — server memvalidasi via
`/download_purchase`, `/update_newpurchase`, `/validate_newlootboy`.

## Anti-cheat / proteksi
- **PairIP** — `libpairipcore.so` ter-link sebagai `DT_NEEDED` oleh
  `libil2cpp.so`, `libunity.so`, `libsqliteJni.so` (protektor build-time;
  binary stripped, string ter-obfuskasi).
- **ByteDance PGL** — `libpglarmor.so` (`PglCryptUtils`) + `libbuffer_pgl.so` /
  `libfile_lock_pgl.so` (sisi iklan Pangle).
- **CodeStage Anti-Cheat Toolkit (ACTk)** — tipe `InjectionDetector`,
  `SpeedHackDetector`, `TimeCheatingDetector`, `WallHackDetector`,
  `ObscuredPrefs`/`ObscuredFilePrefs` hadir di binary; pemakaian aktifnya
  **tidak terkonfirmasi** dari dump statis (tidak ada referensi game-code ke
  `StartDetection()`/`Instance`).
- **Anti-tamper game sendiri (aktif):** `saveHelper.checkTampering` +
  validasi server — `dictSuspiciousState`, `bannedOnlineSaveIds`,
  `"Player is banned"`, endpoint `/comparingValues/`,
  `/validate_buildhash`, `/saveGame/downloadSuspiciousState`. Save yang
  di-tamper: `" was tampered! We won't merge CGdata and IAP values with
  this save slot"`.
- **Tidak ditemukan** detektor root/emulator/Play Integrity yang eksplisit.

## Network
- Backend game: `https://api.ikaanstudio.com/` (`/saveGame/*`,
  `/comparingValues/`, `/validate_buildhash`, `/time_server`,
  `/version_androidRelease`, `/download_*Json`, `/CGImages`, …)
- MongoDB Atlas Data API: `https://ap-southeast-1.aws.data.mongodb-api.com/app/data-pvaem/endpoint/`
- Noctua: `sdk-api-v2.noctuaprojects.com` (+ sandbox, geoip, liveops tracker)
- Lainnya: `worldtimeapi.org`, `app.adjust.com`, Firebase, AppLovin.

## Isi folder ini
- `REPORT.md` — laporan ini
- `citampi_decrypt.py` — decryptor save `.sav` (tanpa kunci hardcoded)
- `dump/` — bukti lengkap:
  - `manifest.txt`, `badging.txt` — AndroidManifest + info paket
  - `dex.txt`, `classes.txt` — 12 dex, 89.447 class
  - `hashes.txt` — SHA-256 XAPK/APK/dex/native/metadata
  - `signer.txt` — hasil apksigner (v3, Ikan Asin Production)
  - `native-libs.txt`, `exports-*.txt` — 25 .so + ekspor simbol
  - `libil2cpp.strings.txt`, `global-metadata.strings.txt`,
    `libunity.strings.txt`, `strings-lib*.so.txt` — string native
  - `tokens-save.txt`, `tokens-crypto.txt` — token il2cpp terkait save/kripto
  - `dis_*.txt` — disassembly ARM64: Encode/Decode/`_getIndiciesMap`,
    TryRead/TryWriteOfflineSlotFile, ctor + InternalSample `System.Random`
  - `rea-grep.txt` — scan kata kunci IAP/anti-cheat/root/network
  - `assets.txt` — inventaris assets
  - `FINDINGS-dex.md`, `FINDINGS-native.md`, `FINDINGS-save.md`
- **Tidak disertakan:** file `.sav` asli user, hasil decrypt JSON (berisi data
  save user), output mentah Il2CppDumper (`dump.cs`/`il2cpp.h`/`script.json`,
  ~250 MB — tersimpan lokal), dan APK/XAPK sumber (dihapus setelah push,
  sesuai aturan REA 22 Nov 2026).
