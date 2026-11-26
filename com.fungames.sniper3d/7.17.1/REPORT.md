# REA — Sniper 3D (Sniper 3D Gun Shooter) 7.17.1 — dump + mekanisme save

- **Package:** `com.fungames.sniper3d`
- **Versi:** 7.17.1, versionCode 34473 (arm64-v8a, minSdk 25, targetSdk 36)
- **XAPK sumber:** `Sniper_3D_Gun_Shooting_Games_7.17.1_APKPure.xapk`,
  252.499.091 byte, SHA-256
  `820ec3646aebf915804671b1a577b0d06dbfbc1c1ab4725a65d4c4094e09f956`
  (base APK 201.387.377 B + `config.arm64_v8a.apk` 51.107.446 B)
- **Signer APK:** CN=Rafael G. J., SHA-256
  `22fb84f6216e9a62af2776ec896bc83d6295f0b245783f86091e3e4c8cc4af96`
- **Tanggal REA:** 26 Nov 2026 (statis saja; APK tidak di-install/dijalankan)
- **Catatan:** laporan REA terpisah untuk v7.15.0 (audit injector, 17 Nov 2026)
  sudah ada sebelumnya di working dir lokal (`REPORT.md` lama) dan tidak
  disentuh; laporan ini khusus v7.17.1 + mekanisme save.

## Engine

- **Unity 6000.3.21f1 (Unity 6), IL2CPP**, metadata v39.
  `libil2cpp.so` 139.574.544 B, `global-metadata.dat` 23.059.484 B,
  29.403 type definition, 183.583 method, 125.003 field.
  Dump via Il2CppDumper v39 (butuh .NET 8; metadata v39).
- `libunity.so`, `libmain.so`, `libpitaya-android.so` (Pitaya — framework
  server game NetEase), Firebase C++ (Analytics/App/Crashlytics),
  AppLovin, Tapjoy, lofelt.
- Dibangun di atas paket platform Wildlife Studios
  (`com.wildlifestudios.platform`): akun via PlatformAccountManager
  (Google Play Games, Facebook, Google Sign-In), store/IAP via Google
  Play Billing (permission `com.android.vending.BILLING`).

## Mekanisme save — KETEMU + TERVERIFIKASI (format + cipher + kunci)

File save user (`savegame_0_r4cg.bin`, 20.251 byte, nama file `savegame`):

```
[0..3]  magic "FSD1" (SaveDocument.BinaryTag)
[4..7]  uint32 LE = CRC32(payload) XOR keyInt
[8]     version: 1 = payload terenkripsi RC4, 0 = plaintext
[9..]    payload = serialisasi biner SaveDocument (RC4 bila version 1)
```

- **Cipher: RC4 standar** (KSA + PRGA, tanpa drop) — class
  `TFG.Core.SaveStream.Rc4` (`.ctor` 0x6C2BC0C, `SetKey` 0x6C2C14C,
  `GetNextMask` 0x6C2C294). Kunci 16 byte.
- **Integritas: CRC-32 zlib** atas payload TERENKRIPSI
  (`SaveStream.Crc32`, DefaultSeed 0xFFFFFFFF, `Add` 0x6C2BD64),
  disimpan sebagai `stored = CRC32 XOR keyInt`,
  `keyInt = BitConverter.ToUInt32(key, 0)`.
- **Payload** (setelah RC4): `int32 Version` + root `SaveObject`
  (count int32; tiap entri: string key length-prefixed UTF-8 7-bit,
  byte `SaveValueType` 0 Invalid / 1 Object / 2 Array / 3 String /
  4 Number (double) / 5 Bool, lalu nilai; Object rekursif, Array =
  count + elemen bertipe). Kunci dilewatkan `KeyStore.Get()` saat baca.
- **Derivasi kunci** (`TFG.Core.App`, `get_SaveGameKey` 0x39A8A1C,
  `SaveGameKeyFromUserId` 0x39B4954, `App..cctor` 0x39B78C8):
  kunci default = `App.DefaultSaveGameKey` (static byte[] 16 byte,
  offset statis 0x1A0, diinisialisasi di `App..cctor` dari blob
  `<PrivateImplementationDetails>`); bila userId ada, kunci =
  `Guid(userId).ToByteArray()` XOR mask, byte per byte (16 byte).
- **Script decrypt:** `dump/sniper3d_decrypt.py` (tanpa kunci hardcoded;
  terima `--key <32 hex>` atau `--userid <guid> --mask <32 hex>`,
  bisa `--encrypt-back` untuk verifikasi round-trip). Detail format
  lengkap di `dump/save_format.txt`.

## Status decrypt file user — TERBLOKIR (butuh userId Guid)

- File user: magic FSD1, version 1 (RC4), stored `0x8b51c701`,
  CRC32(payload) `0xb396da36` → keyInt `0x38c71d37`.
- KeyInt ini **tidak cocok** dengan kunci default (mask) → file ini
  ditulis dengan **kunci per-user** (Guid userId XOR mask).
- 4 byte pertama Guid bisa dipulihkan dari keyInt (dicatat lokal saja,
  untuk verifikasi saat user memberikan Guid-nya); 12 byte sisanya
  tidak ada di dalam file dan tidak bisa di-brute-force (96 bit).
- **Yang dibutuhkan untuk menyelesaikan decrypt: userId Guid pemain**
  (string format `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, terlihat di
  profil/akun game atau di file PlayerPrefs di folder yang sama).
  Setelah Guid diberikan:
  `python3 sniper3d_decrypt.py savegame_0_r4cg.bin --userid <guid> --mask <mask>`.
- Script sudah **divalidasi end-to-end** dengan uji round-trip
  (enkripsi → dekripsi → enkripsi-ulang byte-identik, baik dengan
  kunci default maupun kunci per-user dari Guid uji). File asli user
  TIDAK pernah di-decrypt; isinya tidak pernah dibaca selain header
  9 byte + CRC32 payload, dan tidak ada isinya di repo ini.
- **Nilai mask (DefaultSaveGameKey) TIDAK ada di repo ini.**
  Mask tersimpan lokal saja di working dir REA
  (`sniper3d_decrypt_LOCAL_ONLY.py`, tidak di-push).

## Proteksi / anti-cheat yang ditemukan

- **Play Integrity API** dipakai (string `IntegrityPrepare`,
  `IntegrityRequest`, `IntegrityStandardValidatorService`,
  `Play Core returned null IntegrityManager/StandardIntegrityManager`).
- Ada UI ban cheater server-side (`CheaterBanPopupContent/Title`).
- Ada string `Invalid MAC - file may have been tampered with!`
  (cek MAC pada suatu file — pemakaian aktif tidak dikonfirmasi statis).
- **Tidak ditemukan:** detektor root/emulator/Magisk/Xposed eksplisit,
  SafetyNet, atau native lib anti-cheat (tidak ada PairIP/PGL/EAC).
  Provider "cheat" yang ada (`StoreCheatsProvider`,
  `WalletCheatProvider`) adalah cheat debug internal paket platform
  Wildlife, bukan cheat untuk pemain.
- IAP via Google Play Billing (server-side); cloud save via Pitaya.

## Batasan jujur

- REA statis saja; game tidak dijalankan, tidak ada server yang disentuh.
- Arti field di dalam save (nama kunci hasil decrypt) belum bisa
  dipetakan sebelum decrypt berhasil — parser menampilkan kunci apa
  adanya seperti tersimpan di file (KeyStore mapping di-resolve runtime).
- Tidak ada cheat/editor mata uang yang dibangun dari hasil ini.

## Isi folder ini

```
REPORT.md                  laporan ini
dump/
  sniper3d_decrypt.py      script decrypt (tanpa kunci hardcoded)
  save_format.txt          spesifikasi format + derivasi kunci
  apk_info.txt             aapt badging + signer + hash APK/XAPK
  libs.txt                 daftar native lib
  classes_save.txt         kutipan dump.cs (App, SaveDocument, SaveStream,
                           SaveValue, KeyStore, SaveFile)
  strings_save.txt         string literal terkait save/integrity
  disasm/                  disassembly ARM64 (capstone) fungsi kunci:
    dump_disasm_loadfrombinary.txt, dump_disasm_savetobinary.txt,
    dump_disasm_getsavegamekey.txt, dump_disasm_savegamekeyfromuserid.txt,
    dump_disasm_app_cctor.txt, dump_disasm_crc32add.txt
```
