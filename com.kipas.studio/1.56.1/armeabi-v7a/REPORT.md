> Catatan arsip: File ini REPACK/MOD (bukan resmi Garena): package diubah dari `com.dts.freefireth` menjadi `com.kipas.studio`. Versi 1.56.1, 32-bit (armeabi-v7a) saja.

# REA — FF OLD 2020 CHRONO (64-bit) — LAPORAN PENUH (STATIS SAJA)

> Metode: analisis statis saja. TANPA uji runtime, TANPA koneksi ke server
> game, TANPA dump IL2CPP, TANPA tabel offset. APK game TIDAK dikirim ke
> user, TIDAK di-upload, TIDAK dimasukkan ke repo, dan TIDAK ada mod yang
> dibuat dari laporan ini.

## 0. Jawaban singkat: berapa bit lib-nya?

**32-bit. Bukan 64-bit.**

- Folder `lib/` HANYA berisi `armeabi-v7a` — 14 file, **tanpa
  `arm64-v8a` sama sekali**.
- Header ELF kelima library yang diperiksa (`libil2cpp.so`,
  `libunity.so`, `libanogs.so`, `libmain.so`, `libkipas.so`) semuanya
  `EI_CLASS = 01` = 32-bit.
- Jadi nama file "64 bit" itu **menyesatkan**: isi APK ini 32-bit murni.
  Di HP 64-bit, APK seperti ini hanya bisa jalan lewat kompatibilitas
  32-bit (armeabi-v7a) bila perangkat masih mendukungnya — itu pun
  belum diuji runtime di sini, jadi tidak diklaim pasti jalan di POCO
  X6 Pro atau perangkat lain.

## 1. Sumber dan identitas file

- Tautan yang diberikan user:
  `[tautan unduhan dihapus — minta ke Alyaa]`
- File lokal yang dianalisis:
  `~/workspace/rea-ff-old-2020-chrono/FF_OLD_2020_CHRONO_64bit.apk`
- Nama file di MediaFire: `FF OLD 2020 CHRONO( 64 bit ).apk`,
  quick key `[disensor]`, privasi `public`, tanpa proteksi password.
- Ukuran: **710.746.964 byte (677,82 MiB)**.
- SHA-256 yang dihitung dari file lokal:
  `c000e73fa324592db2eb0cc7e267b39b5eb80cf52ac7cb78c75aba303db104d2`
  — cocok dengan hash metadata MediaFire.
- ZIP valid, **783 entri**.
- Catatan provenance: unduhan pertama dari VM sempat tertahan halaman
  verifikasi manusia MediaFire ("Help us verify you're not a human",
  form reCAPTCHA); tidak ada bypass captcha yang dilakukan. File lokal
  ini kemudian diperoleh dan SHA-256-nya dicocokkan sebelum analisis.

## 2. Manifest

- Package: **`com.kipas.studio`** — BUKAN package Free Fire resmi.
- Version: versionName **`1.56.1`**, versionCode **`2019113979`**.
- Label aplikasi: **`CHRONO PROJECT`**.
- minSdkVersion: **21**; targetSdkVersion: **29**;
  compileSdkVersion: **29** (Android 10); install-location:
  `preferExternal`; OpenGL ES 2.0.
- Activity peluncur (launchable-activity):
  **`com.kstudio.bootstrap.ObbBootstrapActivity`** — activity bootstrap
  milik repacker, bukan activity game asli.
- Activity game asli yang masih dipertahankan di dalam manifest:
  `com.dts.freefireth.FFMainActivity`.
- Activity login/pembayaran yang masih ada: Garena auth
  (`com.beetalk.sdk.GarenaAuthActivity`, `BTLoginActivity`,
  `GGPluginActivity`), Facebook (`FacebookActivity`,
  `CustomTabMainActivity`), Google Sign-In (`SignInHubActivity`,
  `GoogleApiActivity`), LINE (`LineAuthenticationActivity`),
  Garena Pay (`com.garena.pay.android.GGPayActivity`), Google Play
  Billing (`ProxyBillingActivity`), Unity downloader
  (`UnityDownloaderActivity`).
- Permission kunci: `INTERNET`, `ACCESS_NETWORK_STATE`,
  `ACCESS_WIFI_STATE`, `RECORD_AUDIO`, `BLUETOOTH`,
  `com.android.vending.BILLING`, `com.android.vending.CHECK_LICENSE`,
  `READ/WRITE_EXTERNAL_STORAGE`, `READ_PHONE_STATE`, `WAKE_LOCK`,
  `VIBRATE`, `FOREGROUND_SERVICE`, `RECEIVE_BOOT_COMPLETED`.
- Tidak ada tanda `debuggable` yang terbaca dari manifest.

## 3. Signer — BUKAN resmi Garena (repack pihak ketiga)

Bukti dari sertifikat di `META-INF/K-STUDIO.RSA` (bukan dari nama
pengunggah MediaFire):

- Issuer / Subject: **`O=K Studio, CN=K Studio`**.
- Algoritma: `sha256WithRSAEncryption`, kunci publik RSA 4096-bit.
- Serial: `5045254587405024668 (0x46045850fbafbd9c)`.
- Masa berlaku: **8 Okt 2026 – 23 Feb 2054** — sertifikat ini dibuat
  Oktober 2026, jadi jelas bukan sertifikat rilis Garena tahun 2020.
- Nama pengunggah MediaFire ("Kamera Iphone") hanya nama akun
  pengunggah dan **bukan** bukti signer; yang menentukan adalah
  sertifikat di atas.

Bukti repack lain yang konsisten:

- Package diubah dari `com.dts.freefireth` menjadi
  `com.kipas.studio`, label diubah menjadi `CHRONO PROJECT`.
- OBB game asli masih tertanam di dalam APK sebagai aset:
  `assets/kstudio/main.2019113979.com.dts.freefireth.obb`
  (**661.603.985 byte**) — jadi basisnya adalah Free Fire TH
  (`com.dts.freefireth`) versi 1.56.1.
- `assets/google-services.json` masih memakai project Firebase
  `free-fire-8cd39`, tetapi client package-nya tertulis
  `com.dts.freefireadv` — tidak cocok dengan package APK
  `com.kipas.studio` (ketidakcocokan khas repack).
- Library dan activity baru milik repacker: `libkipas.so`
  (335.104 byte) dan `com.kstudio.bootstrap.ObbBootstrapActivity`.

**Verdict: ini BUKAN APK resmi Garena. Ini repack/mod "CHRONO
PROJECT" oleh K Studio, berbasis Free Fire TH 1.56.1 lama.**
Konsekuensi praktis: APK ini tidak bisa menimpa/meng-update instalasi
Free Fire resmi (package dan signer berbeda), dan karena tidak ada
baseline Free Fire TH 1.56.1 asli yang dibandingkan di sini, analisis
statis ini **tidak bisa menyatakan repack ini bersih** — modifikasi
selain pergantian package/signer/bootstrap/libkipas tidak diaudit
satu per satu.

## 4. Engine dan library native

- Engine: **Unity**, versi terbaca dari header
  `assets/bin/Data/globalgamemanagers`: **`5.6.3f1`**.
- Scripting: **IL2CPP** — `libil2cpp.so` 59.115.964 byte dan
  `assets/bin/Data/Managed/Metadata/global-metadata.dat`
  15.592.256 byte. Tidak ada dump metadata yang dilakukan.
- `libunity.so`: 20.875.828 byte.
- Seluruh library hanya ada di `lib/armeabi-v7a` (total tidak
  terkompresi 95.965.836 byte):

| Library | Ukuran (byte) | Keterangan singkat |
|---|---|---|
| `libil2cpp.so` | 59.115.964 | Runtime IL2CPP game |
| `libunity.so` | 20.875.828 | Engine Unity |
| `libFirebaseCppApp-6_16_1.so` | 4.166.560 | Firebase |
| `libharfbuzz.so` | 4.131.080 | Text shaping |
| `libanogs.so` | 3.311.704 | Anti-cheat Garena (lihat §5) |
| `libyoume_voice_engine.so` | 2.158.420 | Voice chat dalam game |
| `libfreetype.so` | 1.069.136 | Font rendering |
| `libanort.so` | 480.472 | Komponen pendamping anti-cheat |
| `libkipas.so` | 335.104 | Library milik repacker (K Studio) |
| `libcrashmonitor.so` | 103.732 | Crash monitoring |
| `libFirebaseCppMessaging.so` | 94.752 | Firebase Messaging |
| `libFirebaseCppAnalytics.so` | 49.324 | Firebase Analytics |
| `libFirebaseCppCrashlytics.so` | 54.356 | Firebase Crashlytics |
| `libmain.so` | 19.404 | Entry point native Unity |

- Aset Unity lain: `assets/bin/Data/globalgamemanagers`
  (16.618.148 byte + 2 split), `sharedassets0.assets.split0/1`,
  `level0`, `unity default resources`, `unity_builtin_extra`, dan
  `SymbolMap-ARMv7` / `SymbolMap-x86` di
  `assets/bin/Data/Managed/` (keberadaan SymbolMap-x86 di aset
  tidak mengubah fakta folder `lib/` hanya armeabi-v7a).
- DEX: `classes.dex` 7.736.916 byte + `classes2.dex` 60.752 byte.
- Billing: `billing.properties` (`billing_client=2.1.0`) + permission
  `BILLING` + `CHECK_LICENSE` + activity GGPay — jalur pembelian
  dalam aplikasi masih ada.

## 5. Anti-cheat, login, dan ekonomi

- **Anti-cheat masih ada:** `libanogs.so` + `libanort.so`
  (komponen anti-cheat Garena yang terbawa dari basis Free Fire TH),
  ditambah `libcrashmonitor.so` dan Firebase Crashlytics. Jadi klaim
  tersirat "versi lama = tanpa anti-cheat" **tidak terbukti** untuk
  file ini — komponennya ada di dalam APK.
- **Login wajib, multi-penyedia:** Garena (Beetalk SDK), Facebook,
  Google, LINE — semua activity-nya masih ada di manifest. Tidak
  ada bukti mode tamu/offline.
- **Ekonomi dalam aplikasi masih ada:** Google Play Billing 2.1.0,
  Garena Pay, dan permission `CHECK_LICENSE`.
- **Jaringan wajib:** permission `INTERNET` + login + billing +
  Firebase. Tidak ada bukti mode permainan offline.

## 6. Verdict server vs lokal

Klasifikasi ini konsisten dengan REA Free Fire Max 2.132.1
sebelumnya (game 100% online), dan diperkuat isi file ini sendiri:

- **Game 100% online (berdasarkan bukti statis):** match, akun,
  inventaris, karakter (termasuk Chrono), diamond/gold, bundle, dan
  pembelian semuanya lewat server Garena + login wajib. Tidak ada
  permukaan permainan offline/vs bot yang terbukti dari manifest,
  library, atau aset.
- **Perhatian versi lama:** ini basis versi 1.56.1 era 2020,
  sementara server Garena sekarang sudah jauh lebih baru. Secara
  statis tidak bisa dipastikan apakah login ke server saat ini masih
  diterima atau sudah ditolak — itu hanya bisa dipastikan lewat uji
  runtime, yang sengaja tidak dilakukan. Harapan realistisnya adalah
  versi ini sangat mungkin tidak lagi kompatibel dengan server
  sekarang, tetapi itu **dugaan kuat, bukan verdict terverifikasi**.

### Ditolak (tidak dibuat, tidak dibantu)

- Aimbot / aim-silent, ESP / wallhack, no recoil, speed, teleport,
  damage multiplier — semuanya melawan pemain asli online.
- Diamond / gold unlimited, item gratis, unlock karakter (termasuk
  Chrono), bundle/pass gratis — ekonomi dan inventaris server-side.
- Bypass `libanogs.so` / `libanort.so` (anti-cheat) dalam bentuk apa
  pun.
- Bypass login Garena/Facebook/Google/LINE, bypass billing / GGPay /
  lisensi.
- Mengklaim atau mendistribusikan repack ini sebagai APK resmi
  Garena — file ini terbukti repack K Studio (lihat §3).

### Tidak ada permukaan mod yang layak diidentifikasi

- Karena tidak ada mode offline/vs bot yang terbukti, tidak ada
  kategori cheat yang bisa dipindahkan ke "solo lokal yang aman"
  untuk file ini. Mod visual lokal pun tidak direkomendasikan:
  komponen anti-cheat masih ada di dalam APK, sehingga risiko flag/ban
  tetap berlaku, dan tidak ada mode offline untuk mengujinya dengan
  aman.
- **Rekomendasi: jangan bangun mod apa pun untuk file ini, dan jangan
  pakai akun utama untuk mencobanya.** Kalau user tetap ingin
  memastikan apakah versi lama ini masih bisa login, itu uji runtime
  di luar REA ini dan risikonya ditanggung sendiri (akun + keamanan
  repack pihak ketiga yang tidak bisa dinyatakan bersih).

## 7. Ringkasan untuk user

- File: Free Fire TH 1.56.1 yang di-repack menjadi "CHRONO PROJECT"
  oleh K Studio, package `com.kipas.studio`, signer K Studio
  (Okt 2026), **bukan resmi Garena**.
- **Lib-nya 32-bit saja (armeabi-v7a), bukan 64-bit** — nama file
  "64 bit" salah/menyesatkan.
- Engine Unity 5.6.3f1 + IL2CPP, anti-cheat anogs/anort masih ada,
  login + billing + ekonomi server-side, game 100% online menurut
  bukti statis.
- Tidak ada mod yang dibangun, tidak ada offset/dump, APK tidak
  dikirim dan tidak di-upload.
- Yang belum terverifikasi (butuh runtime, sengaja tidak dilakukan):
  apakah login ke server Garena saat ini masih diterima, dan apakah
  APK berjalan stabil di perangkat 64-bit lewat kompatibilitas 32-bit.
