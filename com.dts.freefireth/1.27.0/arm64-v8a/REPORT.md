> Catatan arsip: File sumber bernama `ANALISIS.md`, disalin sebagai `REPORT.md`.

# Dump Free Fire 2019 — `ff2019.apk`

Sumber: [tautan unduhan dihapus — minta ke Alyaa] (diunduh 14 Okt 2026)
File: `ff2019.apk` — 485.114.879 byte, md5 `37e765365171c1d60d9d672e22b708b7`
Valid: ya (ZIP utuh, 23.136 entries, `unzip -t` OK)

## Identitas
- Package: `com.dts.freefireth` (varian TH), versionName `1.27.0`
- Sisa nama lama di manifest: `com.dts.privateprojectth` (provider authority dkk)
- Main activity: `com.dts.freefireth.FFMainActivity`

## Kenapa gagal install di POCO X6 Pro (jawaban pasti)
- Native lib HANYA 32-bit: `lib/armeabi-v7a` (12 lib) + `lib/x86` (11 lib)
- TIDAK ADA `lib/arm64-v8a` sama sekali
- POCO X6 Pro (Dimensity 8300, HyperOS/Android 14) tidak menyediakan ABI 32-bit
  → `INSTALL_FAILED_NO_MATCHING_ABIS: Failed to extract native libraries, res=-113`
- Koreksi dari dugaan awal: APK-nya TIDAK korup — ini build 2019 yang utuh dan valid,
  cuma memang 32-bit only. Tidak ada cara install di HP 64-bit-only ini.

## Struktur native (armeabi-v7a)
| lib | ukuran | peran |
|---|---|---|
| libil2cpp.so | 42 MB | SELURUH logika game (IL2CPP) — target utama pattern-scan/patch |
| libunity.so | 18 MB | Unity engine |
| libtersafe2.so | 3,5 MB | Anti-cheat Tencent "Tersafe" (sudah ada sejak 2019!) |
| libFirebaseCppApp-5.4.2.so | 2,9 MB | Firebase C++ |
| libyoume_voice_engine.so | 3,1 MB | Voice chat (YouMe) |
| libAudioPluginDtsXUltra.so | 2,3 MB | Audio plugin |
| libBugly.so | 145 KB | Crash reporting Tencent |
| libmain.so | 19 KB | Bootstrap Unity |
| libantidoente.so | 10 KB | kecil, nama aneh ("anti-doente"?) |
| libtprt.so, libFirebaseCppAnalytics.so, libFirebaseCppMessaging.so | kecil | pendukung |

## Lapisan Java & aset
- 4 dex (classes.dex 5,4 MB, classes2.dex 5,7 MB, classes3/4 kecil) — lapisan Java tipis:
  Garena SDK, auth, push, billing; logika game tidak di sini.
- `assets/bin/Data/`: 22.330 file nama hash (format Unity) — resource game.
- Tidak ditemukan `global-metadata.dat` di listing (mungkin diunduh terpisah / embed lain).

## MEKANISME PRIVATE SERVER (hasil REA + JADX, 14 Okt 2026)

Mod ini me-redirect game ke private server dengan patch **murni di lapisan Java** —
tepatnya di Garena BeeTalk SDK: `com.beetalk.sdk.SDKConstants` (decompile di `jadx_out/`).

**Tiga patch di `SDKConstants.java`:**
1. `sandboxMode` di-hardcode ke `GGEnvironment.TEST` (baris 74)
2. `getAppConfigURL()` (baris 310): ternary `TEST ? X : X` — KEDUA cabang diganti jadi
   `http://190.115.198.51:18000/app/info/get`
3. `getRootUrl()` (baris 334-351): SEMUA jalur return `http://190.115.198.51:18000` —
   termasuk jalur normal yang aslinya `String.format("https://%s.connect.garena.com", appId)`.
   Bukti patch: format string sudah tidak punya placeholder `%s` tapi `appId` masih di-pass
   (argumen mati).

**Efek:** semua API SDK (app info/config, guest register, token grant, friends, dsb.)
lari ke private server `190.115.198.51:18000`. Server itulah yang membalas
`/app/info/get` dengan alamat game server dsb. — client Unity/IL2CPP tinggal ikut.

**Yang TIDAK di-patch (bukti URL asli):**
- `PRODUCTION_HOST_FMT = "https://%s.connect.garena.com"`, `PRODUCTION_HOST_FALLBACK`,
  `TEST_HOST = "https://testconnect.garena.com"` — masih utuh di file yang sama
- `getSSOUrl()` masih ke `sso.garena.com` / `testsso.garena.com`
- crash log masih ke `http://203.116.180.99`

**Repack:** package diganti `com.dts.privateprojectth`, sign ulang self-signed
`CN=ff, O=study, C=BR` (bukan sertifikat Garena). IP private server TIDAK ada di
native libs — 100% patch Java. Sederhana tapi efektif karena semua URL terpusat
di satu class.

## Catatan untuk kerja modding
- Pola sama seperti HCR/UE Hook: game logic di `.so` IL2CPP 42MB → pattern-scan, bukan offset hardcode.
- Tersafe (anti-cheat) sudah aktif di era 2019 — inject ke proses FF = berhadapan dengan ini.
- Client 2019 tidak akan bisa online (server Garena menolak versi lawas) — nilai file ini
  murni untuk riset/utak-atik offline.
