> Catatan arsip: Arsitektur tidak ditegaskan di laporan (APK tunggal 482 MB, repack/mod) — memakai `universal`.

# REA — Free Fire MAX OB53 "FREE-MOD" (kipasff.id)

**Tanggal:** 11 Nov 2026 · **Direktori kerja:** `~/workspace/rea-freefire-ob53/`
**Tujuan:** REA + dump penuh APK dari tautan user. **Analisis saja — tidak ada build/mod/cheat yang dibuat, tidak ada riset ESP/aimbot.**
**Sumber:** [tautan unduhan dihapus — minta ke Alyaa] (tautan langsung, HTTP 200)

---

## 1. Identitas APK

| Item | Nilai |
|---|---|
| File | `OB53-FFKIPAS-FREE-MOD-kipasff.id.apk` |
| Ukuran | **482.020.850 B** (~460 MB) |
| SHA-256 | `1fbec09fa1b82f4c39da5844f5118c706dd07f98e7c20afc3607d60143e77ec2` |
| SHA-1 | `227462819b89e7895c08841d8eb30968c8e0a0f5` |
| Package | `com.dts.freefiremax` (Free Fire MAX) |
| Versi | **2.124.1** (versionCode 2019117601) — `assets/android/versioninfo` juga `2.124.1` |
| SDK | minSdk 21, targetSdk 35, compileSdk 35 |
| Engine | Unity IL2CPP (`libil2cpp.so` 183.978.224 B arm64, `libunity.so` 21.163.488 B) |
| apksigner | **Verifies** (skema v1+v2+v3), 1 signer |

### VONIS: REPACK / MOD — BUKAN file resmi Garena

Bukti penentu ada di sertifikat penanda tangan:

| Item | Nilai |
|---|---|
| Signer DN | `CN=FreeFire, OU=Test, O=PrivateServer, L=SG, ST=SG, C=SG` |
| Self-signed | Ya (issuer = owner) |
| Serial | `d7acf8927bf76ad5` |
| Valid from | **2026-04-08 23:31:17 UTC** (hari rilis OB53) s/d 2053-08-24 |
| Algoritma | SHA384withRSA, RSA 2048-bit |
| SHA-256 cert | `f99ce2163089fcd51f28baa39bb48c03c720e5e14acf211aaad285e7acf0b25c` |
| SHA-1 cert | `43962e165fd8ec7f65763255bf6a483c1a7becf5` |
| MD5 cert | `d0279e565a62e6c9f3aec6a51ace8fc7` |

Ini kunci **test buatan repacker** (`OU=Test`, `O=PrivateServer`), dibuat pada hari rilis OB53 (8 Apr 2026) lalu dipakai menandatangani ulang APK. Sertifikat resmi Garena berbeda — sebagai pembanding, tiap build mod di situs seperti HappyMod membawa signer berbeda-beda (mis. v2.114.1 SHA-256 `39356CAC…`, v2.112.1 `501FFFDD…`, v2.109.1 `CA49D7C4…`), dan tidak satu pun cocok dengan `f99ce216…`. Nama file (`FREE-MOD`) + host pihak ketiga (kipasff.id, bukan Play Store) konsisten dengan vonis ini.

**Catatan:** "Verifies" dari apksigner hanya berarti tanda tangan konsisten secara internal — bukan berarti signernya Garena.

---

## 2. Isi: game resmi yang ditandatangani ulang

Di balik re-sign, isinya adalah game Free Fire MAX OB53 yang asli:

- **Versi cocok dengan OB53 resmi:** 2.124.1; OB53 rilis 8 Apr 2026 (freefiremania); `classes.dex` bertanggal 2026-04-09. Versi saat ini (Nov 2026) adalah **OB55 2.133.1** (16 Sep 2026) — file ini **tertinggal 2 patch**.
- **Firebase resmi:** `assets/google-services.json` → project `free-fire-8cd39` (project Garena untuk Free Fire).
- **Endpoint SDK resmi:** dex mengarah ke `connect.garena.com`, `msdk.garena.com` (plus `testconnect`/`devconnect` milik Garena) — **tidak ada redirect ke private server**.
- **Manifest standar:** application `com.dts.freefireth.FFApplication`, main activity `FFMainActivity`, `debuggable=false`, `allowBackup=false`. Komponen lain semuanya SDK standar (Garena Auth, GGPay, Firebase, VK, LINE, Twitter, AppsFlyer). **Tidak ada activity/service mod-menu tambahan.**
- **Native libs standar** (arm64-v8a + armeabi-v7a): `libil2cpp.so`, `libunity.so`, `libmain.so`, `libGGP.so` (anti-cheat Garena, 8.742.176 B), `libAkSoundEngine.so`, `libFFWebRequest.so`, `libFFVoiceMagicVoiceEngine.so`, dsb. **Tidak ada .so injeksi bernama mod.**
- **Dex:** `classes.dex` (9.129.252 B) + `classes2.dex` + `classes3.dex`, kelas ter-obfuscate (R8) seperti build rilis biasa.
- **Tidak ada string "kipas"/"kipasff" di mana pun** dalam APK (dex, .so, assets, manifest).

## 3. Dump IL2CPP — metadata ter-obfuscate, berhasil dipecahkan

`assets/bin/Data/Managed/Metadata/global-metadata.dat` (52.684.964 B) **ter-obfuscate XOR 0xE8** (byte tunggal): 4 byte pertama `47 f3 59 12` XOR `E8` = `AF 1B B1 FA` = magic IL2CPP `0xFAB11BAF`, **metadata version 31**. Setelah de-obfuscate (parser `il2cpp_dump_ff.py`, salinan de-obfuscate di `dump/global-metadata.deobfuscated.dat`):

- **43.698 tipe** (`dump/types.txt`), **211.782 method** (`dump/methods.txt`), **438.775 field**
- Namespace terbesar: `COW` (15.529 tipe — namespace internal game), `proto` (3.657), `message` (3.259), `System`, `UnityEngine`, `GarenaMSDK`, `FFNetwork`, `FFVoice`
- Tidak ditemukan tipe/method mod: **0 hasil** untuk aimbot / wallhack / mod-menu / godmode / no-recoil / unlimited ammo / auto-aim / cheat / inject / bypass. Hit "ESP" semuanya legitimate (`ESPKillOperateNoti`, `ESparkAvatarType`, `ESparkPet*` — fitur "Spark" game; `*Resp` = Response).
- Anti-cheat tampak di dump: `proto.ReportGGPInfo`, `tcp.EmulatorCheckPlayersNtf`, `proto.AccountEmulatorTagInfo`, `tcp.EmulatorPlayerNtf`.
- Anomali dicatat (bukan vonis): `libunity.so` melaporkan Unity `2018.4.11f1`, sementara metadata v31 berformat era Unity 2022.3 — kemungkinan build engine kustom Garena atau string versi lama; tidak diinterpretasi lebih jauh.

Hash native lib (arm64-v8a) untuk pembanding di masa depan:
- `libil2cpp.so` SHA-256 `176bd8a9500e41cd06f1077f2f1a5a2fce9d69f6a3dd2b700dafbae476119e7a`
- `libGGP.so` SHA-256 `8508f92a413ba9c795f05d0937ebbf822a43f618ecff97a77934c8f8e81015fa`
- `libunity.so` SHA-256 `e3fa55e4cf8732ba895b678541c5e568999d6a1a34f898fc7b02cf086026d4c7`

## 4. Apa yang diubah — sejauh bisa dibuktikan statik

| Perubahan | Status bukti |
|---|---|
| Tanda tangan ulang (re-sign) dengan kunci test `O=PrivateServer` | **TERBUKTI** (sertifikat, §1) |
| Tambahan .so injeksi / mod-menu / activity / service | **TIDAK ADA** (inventaris lib + manifest + dex bersih) |
| String cheat (aimbot/ESP/wallhack/diamond hack/dll.) di dex & libil2cpp.so | **TIDAK ADA** (0 hasil; satu false positive `UnlimitedDiscountResult` = nama tipe diskon game) |
| Redirect server / private server | **TIDAK ADA** (SDK tetap ke domain Garena) |
| String "kipas"/"kipasff" di dalam APK | **TIDAK ADA** |
| Patch byte-level di `libil2cpp.so` (mis. bypass anti-cheat, tweak damage/aim) | **TIDAK BISA DIBUKTIKAN / DIBANTAH statik** — butuh APK resmi 2.124.1 sebagai pembanding byte-per-byte; tidak tersedia (APKPure API 403, Play Store tidak menyediakan APK langsung). Hash di §3 dicatat untuk pembanding kelak. |

## 5. Klasifikasi server vs lokal

Free Fire adalah **battle royale full-online**. Yang server-gated (tidak bisa diubah dari klien):

- **Diamond, coin, rank, skin, unlock karakter/senjata, inventory, hasil match, kill/damage** — semua divalidasi server. Tidak ada mod klien yang bisa memberi "unlimited diamond/money" secara nyata.
- Pembelian (IAP) lewat `GarenaMSDK.SDKIAP` + `GGPayActivity` — server-verified.

Yang lokal (klien saja):

- Pengaturan grafis/sensitivitas, konfigurasi lokal, cache aset, tampilan.
- Mod-menu pada APK sejenis umumnya hanya mengubah hal visual/klien — dan tetap berisiko ban.

**Anti-cheat aktif di build ini:** `libGGP.so` + tipe pelaporan GGP + emulator check. Klien yang ditandatangani ulang terdeteksi lewat mismatch tanda tangan + Play Integrity — **risiko ban akun nyata** bila dipakai login ke akun utama.

## 6. Vonis jujur

1. **File ini REPACK/MOD (re-sign), bukan resmi Garena** — terbukti dari sertifikat test `O=PrivateServer` yang dibuat pada hari rilis OB53.
2. **Isinya game OB53 asli** (2.124.1) — tidak ditemukan payload mod/malware secara statik: tidak ada .so injeksi, mod-menu, cheat string, redirect server, atau jejak "kipas" di dalam APK.
3. **Klaim "FREE MOD" (unlimited diamond/dll.) tidak didukung bukti apa pun di dalam file** — dan secara arsitektur tidak mungkin: ekonomi game server-side. Bila situs menjanjikan itu, itu iklan palsu.
4. **File sudah kedaluwarsa 2 patch** (OB53 Apr 2026 vs OB55 saat ini) — kemungkinan besar tidak bisa dipakai untuk matchmaking saat ini (forced update) dan makin mudah ditandai.
5. **Batas analisis:** patch byte-level di `libil2cpp.so` tidak bisa dipastikan tanpa APK resmi pembanding. Analisis statik tidak bisa menjamin tidak ada yang disisipkan di native code — hanya bisa menyatakan tidak ada indikator yang ditemukan.

**Rekomendasi:** jangan install di HP utama / jangan login akun utama. Bila user tetap ingin mencoba, risikonya: ban akun, tidak bisa update/matchmaking karena versi lama, dan tidak ada jaminan keamanan dari repacker pihak ketiga.

## 7. File kerja

- `OB53-FFKIPAS-FREE-MOD-kipasff.id.apk` — APK asli (482 MB)
- `apk_contents.txt` — daftar isi APK (43.619 entri)
- `extracted/` — hasil extract (1,4 GB)
- `dump/types.txt` (43.698), `dump/methods.txt` (211.782), `dump/global-metadata.deobfuscated.dat`
- `il2cpp_dump_ff.py` — parser metadata v31 XOR 0xE8
