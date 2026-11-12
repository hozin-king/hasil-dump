# REA — Sand:box 21.192 "Rattlesnake"

**Tanggal analisis:** 5 Nov 2026
**Sumber:** `Sand___Box_21.192_Rattlesnake_0_pbca.apk` (5.169.234 B, SHA-256 `c53d7a9b2ed462a867144a77e43d67b554bd6a518f1f239b69157750e20e9b30`)
**Metode:** statis (apktool + dexdump + apksigner + strings). Tanpa install, tanpa runtime.

## Verdict: ASLI, bukan repack/mod

Ini **Sand:box resmi** (falling-sand simulator) dari developer aslinya. "Rattlesnake" **bukan** tag modder — itu nama resmi rilis ini (Sand:box menamai tiap rilis dengan spesies ular).

Bukti keaslian:
- Package `smellymoo.sand`, app name `Sand : Box`, versionName `21.192 Rattlesnake` (versionCode 21192)
- **1 signer, sertifikat asli developer**: `CN=rory renton` (Rory Renton = developer Sand:box), RSA 2048, berlaku 27 Mei 2015 – 14 Mei 2065, SHA-256 cert `9ce9d6108c271b7c62e4b2b7d5858a4b083ba5e9d91c78949f51b5799e0daea3`
- `apksigner verify`: **v1 ✓, v2 ✓** (v3/v3.1/v4 tidak dipakai build ini — normal), APK utuh, tidak di-re-sign pihak ketiga
- Jejak build asli: AGP 8.13.0, `baseline.prof`, path debug native `/home/smellymoo/Dropbox/Projects/sandbox/android/app/src/main/jni/engine.cpp`
- DEX hanya berisi 11 class aplikasi (`Main`, `Sand`, `Engine`, `Freemium`, `Settings`, `Save`, `Help`, `About`, `Welcome`, `Dev`, `ColorPicker`) + AndroidX/Kotlin + Play Billing — **tidak ada class tambahan/mod**

## Inventaris

| Item | Isi |
|---|---|
| Ukuran / file | 5.169.234 B, 785 file |
| DEX | 1 file `classes.dex` (1.313.668 B), 1.325 class |
| Native | `libsand.so` di 4 ABI (arm64-v8a 1.603.424 B, armeabi-v7a, x86, x86_64), 2.822 simbol export, JNI `Java_smellymoo_sand_Engine_*` (config, emulationloop, renderframe, sendarray, …) — engine simulasi |
| Aset | `assets/images/*.png` (ikon elemen: sand, fireflies, frogs, laser, nanobots, …), `assets/help.html` ("Sand:box user guide"), `assets/dexopt/baseline.prof` |
| SDK | compileSdk 36 (Android 16), targetSdk 36 |
| Permission | Hanya 3: `INTERNET`, `ACCESS_NETWORK_STATE`, `com.android.vending.BILLING` |
| Aktivitas | Main (launcher), Sand, About, Help, Welcome, Dev, Freemium, Settings, Save |
| IAP | Play Billing client 7.0.0; SKU diambil dari Play saat runtime (tidak ada product ID hardcoded di DEX) |

## Jaringan & privasi

- **Tidak ada SDK iklan/analitik sama sekali**: 0 class AdMob, Firebase, Analytics, Facebook, AppLovin, Unity, ironSource.
- URL di DEX hanya 2: schema XML Android + `play.google.com/store/apps/details` (tautan ke Play Store).
- URL di native lib hanya 1: `android.googlesource.com/toolchain/llvm-project` (jejak toolchain build).
- `allowBackup=true` (data save bisa ikut backup — risiko rendah untuk game sandbox), `extractNativeLibs=true`.
- Tanpa `networkSecurityConfig` eksplisit → default targetSdk 36 berlaku (cleartext diblokir).
- Tanpa root detection / tamper detection — wajar untuk game jenis ini.

## Potensi mod (verdict per fitur)

- **Game sepenuhnya offline** — simulasi berjalan lokal di `libsand.so`, save lokal. Tidak ada server, tidak ada lawan manusia.
- **Freemium/IAP (unlock berbayar) = gerbang pembelian nyata via Google Play Billing** → bypass-nya **DITOLAK** (kelas yang sama dengan penolakan bypass IAP/premium sebelumnya).
- Elemen/konten simulasi di native engine: modifikasi lokal mungkin secara teknis, tapi **tidak dibangun di sini** — kirim APK ini saja tanpa perintah mod.

## Yang TIDAK bisa disimpulkan statis

- Perilaku runtime (FPS, stabilitas di POCO) — perlu tes install.
- Apakah semua elemen terbuka di build ini atau ada yang terkunci di balik IAP — SKU hanya diketahui Play Store saat runtime.

## File kerja

- APK + hasil decode + laporan ini: `~/workspace/rea-sandbox-rattlesnake/`
- Laporan ini: `~/workspace/rea-sandbox-rattlesnake/REPORT.md`
