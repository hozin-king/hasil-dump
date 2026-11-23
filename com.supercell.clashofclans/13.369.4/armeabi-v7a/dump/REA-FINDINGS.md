# REA — Clash of Clans 13.369.4 (varian armeabi-v7a) — Statis

**Tanggal analisis:** 23 Nov 2026 (statis saja — APK **tidak** di-install, **tidak** dijalankan)
**File lokal:** `~/workspace/rea-coc-13x/CoC-13.369.4-arm64.apk` (154.243.348 B,
MD5 `92c62442b6876c2373c579ac73f87060`, SHA-256 `ee077e5131e041b3bff68b008976afe38246aa8e748fe04e876bb40d77f411f7` — keduanya terverifikasi cocok)
**Sumber:** androidapks.com / androidapksfree CDN, 22 Jun 2020, diklaim varian "arm64-v8a nodpi"
**Pembanding:** `~/workspace/rea-clash-of-clans/REA-CLASH-OF-CLANS-NARA.md` (CoC 5.2 "Nara Patch" v1.5)

> ## ⚠️ KOREKSI VARIAN — BACA DULU
> Nama file menyesatkan. **Yang dianalisis ini adalah varian armeabi-v7a (32-bit), BUKAN arm64.**
> Bukti: `aapt dump badging` → `native-code: 'armeabi-v7a'`; `lib/` hanya berisi 5 file
> `armeabi-v7a` (tidak ada direktori `lib/arm64-v8a` sama sekali); kelima `.so` terverifikasi
> ELF32 ARM via `readelf`/`file`. APK ini adalah **base APK dari sebuah Android App Bundle**
> (signer `BNDLTOOL`, ada `res/xml/splits0.xml` — isinya hanya modul bahasa), jadi library
> arm64-v8a semestinya berada di split APK terpisah (`config.arm64_v8a`) yang **tidak ikut
> terunduh**. **Analisis `libg.so` arm64 BELUM didapat** (tautan APKMirror langsung dari user
> kena 403 dari VM — kemungkinan key kedaluwarsa + blok Cloudflare).
>
> Dampak: temuan DEX, manifest, assets, CSV, dan sebagian besar string protokol/kripto
> identik antar varian ABI, jadi temuan protokol di laporan ini tetap berlaku; tetapi
> **semua pernyataan tentang `libg.so` di bawah ini adalah tentang `libg.so` ARM32
> (13.607.752 B, SHA-256 `1be70496cf54591772c54a18215f0602fe27e1feb70bf18c9d995b6a0b5b1bf1`)**,
> bukan arm64. Pola/offset native arm64 bisa berbeda.

## 1. Identitas

| Item | Nilai |
|---|---|
| Package name | `com.supercell.clashofclans` (resmi Supercell — bukan repack) |
| versionName / versionCode | `13.369.4` / `1242` |
| minSdk / targetSdk | 16 / 29 (Android 4.1 / 10); compileSdk 29, platformBuildVersionName `10` |
| Ukuran APK | 154.243.348 B (±147,1 MiB); unzip 2.569 file, 172.833.040 B |
| Label aplikasi | `Clash of Clans` |
| Activity utama | `com.supercell.titan.GameApp` (dulu `com.supercell.clashofclans.GameApp` di 5.2) |
| Application class | `com.supercell.titan.TitanMultidexApplication` (extends `MultiDexApplication`) |
| ABI | **armeabi-v7a saja (32-bit)** — tidak ada arm64-v8a (lihat koreksi di atas) |
| Debuggable | **Tidak** (tidak ada atribut `android:debuggable` di manifest) |
| allowBackup | `true` (berubah dari `false` di 5.2); backupAgent `com.supercell.titan.PreferencesBackupAgent` |
| usesCleartextTraffic | `true` |
| Skema tanda tangan | v1 + v2 terverifikasi; v3 / v3.1 / v4 **tidak** |
| Signer (1 signer) | `CN=Visa Forsten, OU=Supercell, O=Supercell, L=Helsinki, ST=Uusimaa, C=FI` — RSA 4096-bit |
| Signer SHA-256 | `9ea146d935c0be2e4b576396e6a5e1de6dcb69a71af4e417b0a5b8fe8e0d4d9c` |
| Signer SHA-1 | `456120d30cda8720255b60d0324c7d154307f525` |
| Signer MD5 | `a08f2cbc1a8155046e43d8b518d44ddb` |
| META-INF signer | `BNDLTOOL.RSA` / `.SF` (App Bundle) — bukan nama orang seperti `NARA.RSA` di 5.2 |

### Permissions (aapt dump badging — lengkap)

`com.android.vending.BILLING`, `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`,
`CHANGE_WIFI_STATE`, `ACCESS_WIFI_STATE`, `CAMERA` (uses-permission-sdk-23),
`com.google.android.finsky.permission.BIND_GET_INSTALL_REFERRER_SERVICE`,
`com.google.android.c2dm.permission.RECEIVE`, `WRITE_EXTERNAL_STORAGE`,
`READ_EXTERNAL_STORAGE`, `RECEIVE_BOOT_COMPLETED`.

**Diff vs 5.2** (`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `CHANGE_WIFI_STATE`,
`ACCESS_WIFI_STATE`, `READ_PHONE_STATE`, `BILLING`, `C2D RECEIVE`, `C2D_MESSAGE`,
`WRITE_EXTERNAL_STORAGE`):

| Perubahan | Keterangan |
|---|---|
| **HILANG: `READ_PHONE_STATE`** | Tidak lagi baca IMEI/identitas perangkat (OpenUDID masih ada sebagai service, tapi tanpa permission ini) |
| **HILANG: `…permission.C2D_MESSAGE`** | Custom C2D permission (dulu `com.narapatch…C2D_MESSAGE`) tidak ada — wajar, package resmi tidak memakainya dalam bentuk itu |
| **BARU: `CAMERA`** (sdk-23) | Untuk scan QR Supercell ID (invite teman via QR — lihat `defaultEnglish.strings`: "They can find your profile by scanning this QR code") + `com.journeyapps.barcodescanner.CaptureActivity` di manifest |
| **BARU: `READ_EXTERNAL_STORAGE`** (eksplisit) | Di 5.2 hanya tersirat dari WRITE |
| **BARU: `RECEIVE_BOOT_COMPLETED`** | Terkait push/Firebase + `PushMessageService` |
| **BARU: `BIND_GET_INSTALL_REFERRER_SERVICE`** | Install Referrer API (Play) — untuk atribusi Adjust |
| Tetap ada | `BILLING` (IAP nyata), `INTERNET`, `WAKE_LOCK`, WiFi-state, C2D `RECEIVE`, `WRITE_EXTERNAL_STORAGE` |

## 2. Inventaris ringkas

Detail lengkap (2.714 baris): [`analysis/INVENTORY.txt`](analysis/INVENTORY.txt).

- **DEX**: `classes.dex` **satu file saja**, 8.276.280 B, DEX v035,
  SHA-256 `17263fe664f3f5a17c0ffb3dc37123a6d0c1970f770d9d156e4690e97b646fa9`.
  Header counts: strings 49.172, types 11.339, protos 12.040, fields 61.668,
  methods 58.490, classes 9.635. Tidak ada `classes2.dex` (meski app class-nya
  `MultiDexApplication`). Bandingkan 5.2: 1.094.512 B, 939 class, 8.769 method.
  JADX 1.5.1: 6.190 file `.java` berhasil di-decompile, 9 error.
- **Native** (`lib/armeabi-v7a/`, semua ELF32 ARM, stripped):

  | File | Ukuran | SHA-256 |
  |---|---|---|
  | `libg.so` | 13.607.752 B | `1be70496cf54591772c54a18215f0602fe27e1feb70bf18c9d995b6a0b5b1bf1` |
  | `libfmod.so` | 952.092 B | `a7d6bf28b1f89a672197a081a4c80742813c4e3e33014a84859dac7192201c00` |
  | `libcrypt-lib.so` | 169.692 B | `100d0c9bbf80071769e7ba446658d2c41173ed419711c2d8e514c5f624e5891f` |
  | `libsentry.so` | 542.420 B | `897f63c69e5871f11ee4829d829e044d3a5ed2b6b23fef37339f7f5e09b0b365` |
  | `libsentry-android.so` | 13.912 B | `948a67e15d34b710da2ed4865a954d425e8bde09c4da84fd0f415d638a0c1eb1` |

  `libg.so`: BuildID SHA-1 `6a77041f591363b27cf48e79d13d6971a6c28e12`, 390 simbol
  dinamis, satu-satunya simbol ter-export yang bermakna `JNI_OnLoad` (+ import
  FMOD). Tidak ada `libfmodex.so` (5.2) — diganti `libfmod.so` (FMOD non-Ex).
  `libg.so` 13.x adalah 4,4× ukuran `libg.so` 5.2 (3.098.452 B).
- **Assets** (837 file, 144.848.817 B): `csv/` 17, `logic/` 44, `sc/` 168
  (113.295.190 B — tekstur game), `sc3d/` 57 (`.scw` animasi + `.ktx` tekstur 3D,
  baru — hero 3D), `sfx/` 488 (`.ogg`), `music/` 23, `font/` 7, `image/` 15,
  `localization/` 2 (`texts.csv` 1.886.057 B + `texts_patch.csv`), `shader/` 2,
  `titan/fonts/` 8, `fingerprint.json` (1.114 entri, `"version":"13.369.5"` —
  **fingerprint version 13.369.5 ≠ versionName APK 13.369.4**), `globals.json`,
  `globals_definition.json` (plaintext JSON — baru), `hs__data` (JSON
  `"HSCharacters"` — peta karakter Helpshift), `defaultEnglish.strings`,
  `supercell_id_config.json`.
- **Tidak ada lagi**: `assets/level/*.json` (5.2 punya 61 JSON: `townhall1–10.json`,
  `npc1–48.json`, `starting_home.json`) dan `assets/version.number` (5.2:
  `version=5, build=2, content_revision=1`). Data level/desain desa tidak lagi
  dibundel sebagai JSON plaintext.
- **res/**: 1.094 file, 2.284.420 B; `resources.arsc` 1.258.428 B.
- **SDK pihak ketiga di DEX** (masih aktif): Facebook SDK, Google Play Games /
  GMS, Firebase (Messaging/Analytics), Adjust, Branch, Helpshift, AppCenter,
  Sentry, Unity Ads, Chartboost (tidak terlihat lagi — tidak diverifikasi),
  **OpenUDID** (service `org.OpenUDID.OpenUDID_service` masih di manifest),
  MobileAppTracker, Tencent MSDK (`com.supercell.titan.tencent.MSDKManager` —
  hanya untuk build Tiongkok), Kakao.

## 3. Temuan kunci

### 3.1 Hostname server game TIDAK ditemukan di mana pun (plaintext)

- `gamea.clashofclans.com`: **0 kemunculan** di `libg.so`, `classes.dex`,
  `assets/`, dan `resources.arsc` (grep biner mentah, case-insensitive).
- `127.0.0.1` / `9339` / `10101` / `20104` / `LoginMessage` / `LoginOk`:
  **0 kemunculan** di DEX dan resources. Satu-satunya hit `gamea` di `libg.so`
  ternyata false positive (`GameApp` mengandung substring `gamea`).
- Satu-satunya host Supercell yang masih tampil plaintext adalah
  `https://supercell.helpshift.com/a/clash-of-clans/?p=web&s=supercell-id`
  (`assets/supercell_id_config.json` — link bantuan, bukan server game) dan
  `service.supercell.net`-style endpoint **tidak** ditemukan (berbeda dengan 5.2
  yang masih punya `https://service.supercell.net/tracking/login` di `libg.so`).
- **Penyebabnya terukur (§3.2): string `libg.so` ter-obfuscasi/terenkripsi.**
  Hostname, pesan login, dan kunci kripto hampir pasti berada di dalam blob
  terenkripsi itu — bukan karena tidak ada server, melainkan karena tidak bisa
  dibaca dari statis saja.

### 3.2 String `libg.so` terenkripsi / ter-obfuscasi (BERBEDA TOTAL dari 5.2)

Fakta:

- `.rodata` hanya 125 KB (offset `0x89d400`, size `0x1ea80`) dan isinya **hanya**
  nama class/method JNI (`com/supercell/titan/...`, `com/supercell/id/...`,
  `java/lang/String`, …), nama symbol libc, dan string compiler
  (clang 8.0.2, NDK r19c). **Tidak ada satu pun string game** (tidak ada
  "Connecting to…", tidak ada nama pesan, tidak ada URL) — padahal `libg.so`
  5.2 masih menampilkan `"Connecting to the production server..."` /
  `"Connecting to server at %s"` secara plaintext.
- `.data` (±4 MB, offset `0x8ea000`, size `0x3f0cb0`) ber-entropi **7,983**
  (mendekati acak 8,0); `.text` 6,865, `.rodata` 5,112. Printable-run ≥6 karakter
  di `.data` hanya berupa gibberish (`tqR&k^`, `7?xKqm`, …) — konsisten dengan
  tabel string terenkripsi, bukan string plaintext.
- Brute-force **single-byte XOR** atas seluruh 13,6 MB `libg.so` (256 kunci,
  numpy) untuk `gamea`, `clashofclans`, `supercell.net`, `127.0.0.1`,
  `Connecting`, `fhsd6f86`, `nonce`: **nol hit**. Jadi bukan XOR 1-byte sederhana.
- `strings -e l` (UTF-16): hanya 88 baris, tidak ada yang relevan.
- Section aneh: `__ETC__PII2` (PROGBITS, 0x1ef10 B, entropi 0 — isinya nol semua).

**Inferensi:** string game (termasuk hostname + materi kripto) disimpan
terenkripsi di `.data` dan didekripsi saat runtime — kemungkinan dengan kunci
yang diturunkan di runtime / di-embed di `.text`. Membuka ini butuh analisis
runtime (atau disassembly mendalam `libg.so`), bukan `strings`.

### 3.3 Materi kripto — hasil negatif yang penting

| Yang dicari | `libg.so` | `classes.dex` | `libcrypt-lib.so` |
|---|---|---|---|
| Kunci RC4 lama `"fhsd6f86f67rt8fw78fw789we78r9789wer6re"` | 0 | 0 | 0 |
| `"nonce"` (RC4 nonce era UCS) | 0 | 1 (bukan kripto — string acak di DEX) | 0 |
| `blake2` / `libsodium` / `sodium` / `nacl` | 0 | 0 | 0 |
| `Pepper` | 0 | 0 | 0 |
| `ChaCha` / `X25519` / `Ed25519` / `HKDF` | 0 | 0 | 0 |
| `AES` / `RC4` / `SHA256` (sebagai string) | 0 | 0 | 0 |

**Fakta:** kunci RC4 publik era UCS **tidak ditemukan** di klien 13.369.4 — jadi
**tidak bisa disimpulkan RC4 masih dipakai**; sama tidak bisanya menyimpulkan
sudah ganti ke libsodium/Blake2/dll. Implementasi kripto hidup di dalam
`libg.so` yang string-nya ter-obfuscasi (§3.2). Satu-satunya petunjuk kripto
plaintext di native adalah `KRSsl` dan `/dev/urandom` di `libg.so`, plus
`javax/crypto/Cipher` + `HmacSHA256` di `libcrypt-lib.so` — yang terakhir itu
milik Adjust, bukan protokol game (§3.6).

### 3.4 `libcrypt-lib.so` — BUKAN kripto game, melainkan Adjust Signature V2

Temuan baru vs 5.2 (5.2 tidak punya file ini):

- Hanya 2 export JNI: `Java_com_adjust_sdk_sigv2_NativeLibHelper_nOnResume`
  dan `Java_com_adjust_sdk_sigv2_NativeLibHelper_nSign`.
- Pemakai: `com.adjust.sdk.sigv2.NativeLibHelper` (jadx-out) —
  `System.loadLibrary("crypt-lib")`, `nSign(Context, Map, byte[], double, int,
  String, String)` menandatangani parameter request atribusi Adjust.
- Kunci HMAC: `KeystoreHelper` — alias AndroidKeyStore `"key2"`, kunci
  `HmacSHA256`, kunci terenkripsi disimpan di SharedPreferences `"adjust_keys"`
  (`"encrypted_key"`, transformasi `RSA/ECB/PKCS1Padding`). Namespace C++
  ter-obfuscasi: `obf_namespace::KeystoreHelper` / `EncryptionHelper`.
- **Kesimpulan: file ini hanya anti-spoofing atribusi install (Adjust) — tidak
  ada hubungannya dengan enkripsi sesi game / login 10101.** Jangan tertipu
  namanya.

### 3.5 `libsentry.so` + `libsentry-android.so` — crash reporting, DSN kosong

- `libsentry.so` = Sentry Native SDK (`sentry_init`, `sentry_capture_event`,
  `sentry_envelope_serialize`, …); `libsentry-android.so` = bridge JNI
  (`Java_io_sentry_android_ndk_SentryNdk_initSentryNative`).
- `GameApp` memuat `System.loadLibrary("sentry")` **sebelum** `fmod` dan `g`
  (urutan load: sentry → fmod → g).
- **Tetapi:** manifest `meta-data io.sentry.dsn` bernilai string **kosong**
  (`""`). Jadi di build ini Sentry kemungkinan tidak mengirim ke mana pun
  (atau DSN di-set runtime — tidak terbukti dari statis). Murni crash
  reporting, bukan proteksi / bukan kripto.

### 3.6 Jejak anti-tamper di `libg.so` (string D-Bus/Frida)

- `libg_strings.txt` baris 58701+ (berulang ≥5× di `.rodata`, offset
  `0x89ee00`, `0x89f854`, `0x8a2e91`, …): template pesan D-Bus
  `"/re/frida/HostSession"`, `"re.frida.HostSession12"`,
  `"EnumerateProcesses"`, `"GetAll"`, `"org.freedesktop.DBus.Properties"`.
- **Inferensi (belum terbukti):** ini konsisten dengan kode yang berbicara ke
  Frida HostSession via D-Bus — kemungkinan deteksi Frida (anti-instrumentasi)
  yang di-link statis ke `libg.so`. Alternatif: fixture/test data dari library
  yang di-bundle. Yang pasti: string Frida **ada** di dalam `libg.so` resmi —
  bukan dari tool analisis kami.

### 3.7 Alur login & integritas klien (DEX — semua game networking ada di native)

- **Tidak ada** alamat server, nomor pesan (10101/20104), atau logika protokol
  di DEX — semuanya di `libg.so`. Java hanya jembatan JNI.
- `GameApp.java` (jadx-out) — native method relevan:
  `createGameMain(AssetManager, …)`, `init(String)`, `start(String)`,
  `setDeviceVerificationResult(boolean, boolean, String)`,
  `setTencentLogin / setTencentLoggedOut / setTencentDiffLogin`,
  `setPushNotificationValues`, `handleDeeplinkURL`.
- **`checkSignature()` — GameApp.java:568–585 (BARU, penting buat private server):**
  menghitung SHA-1 dari signature APK → Base64, membandingkan dengan **11 hash
  hardcoded**; return `0` bila cocok, `1` bila tidak. Hash-nya:
  `RWEg0wzahyAlW2DQMkx9FUMH9SU=`, `LhjT+HJrHeYxMicWUY+yrsLr654=`,
  `xWj3NbEpQjAUk4KDgJo23qjr06Q=`, `HnxASw7gdJz5NmBsPsNM+dMoO+M=`,
  `dMbXe1xYkjRdd7GNjy67sFY8ZEQ=`, `gHww8K7HZ/6JahuUjUc5UYIWPxw=`,
  `vnSakMlp3zat4BU5Zq+5+GaQxNs=`, `KKyU591coRU1qKAWHNWOHCTcZCE=`,
  `d1MWeErwW+CGhfyQn6H31+iyFNc=`, `8FU+TGRw3LTOfWAxLrArYg==`,
  `lxlqmPxo9M7RQV9WroxWKfCja/g=`. Dipakai oleh pengecek di baris 585
  (`getInstance().checkSignature() == 0`). **Repack dengan signer lain akan
  gagal cek ini** (kecuali pemanggilnya mengabaikan hasil / cek native-nya
  berbeda — tidak diverifikasi dari statis).
- **`testDeviceIntegrity(byte[])` — GameApp.java:602:** body Java-nya **no-op
  stub** (hanya `getInstance()`); parameter `byte[]` mengisyaratkan payload
  atestasi dari native. `setDeviceVerificationResult(boolean, boolean, String)`
  adalah native method **tanpa satu pun pemanggil Java** yang ditemukan —
  dipanggil dari native (kemungkinan hasil SafetyNet/Play Integrity era 2020
  yang diteruskan ke `libg.so`). Tidak ada string `SafetyNet`/`attest`/
  `integrity` yang bermakna di DEX (hanya `testDeviceIntegrity` + string Room
  DB yang tidak terkait).
- **`GameApp.a()`** — nama file `SecurePreferences` di-obfuscasi: package name
  dibalik lalu di-XOR dengan array 24-int
  `{102, 76, 120, 89, 66, 57, 77, 56, 52, 65, 98, 101, 117, 115, 69, 82, 77,
  89, 57, 89, 70, 122, 86, 71}` → pref `"storage_new"`; pref lain
  `"storage"` / `"localPrefs"`, dikunci dengan `android_id`.
  `getBuildConfigFromGame()` membaca `BuildConfig` via refleksi
  (`sc_manifest_package_name`).
- **`isEmulator()`** ada (GameApp.java:594) — deteksi emulator berbasis thread
  `h` (detail tidak ditelusuri).
- **Tidak ada certificate pinning di Java** (grep `pinning|CertificatePinner|
  checkServerTrusted` di `com.supercell.*`: nol) — bila ada, pinning berada di
  native.
- **Supercell ID** — `assets/supercell_id_config.json`: `"Enabled": true`,
  `"UseNative": true`, `"Game": "magic"`, `"UseNativeFastSwitch": true`.
  Java hanya UI + plumbing token (`IdAccount` membawa `scidToken`,
  `IdPendingLogin`, `IdConnectedGame`, `IdFriend`); **base URL API Supercell ID
  tidak ada di DEX** — implementasi native di `libg.so`.
- **Google Play Games** — masih dipakai: class GMS `games/` lengkap di DEX,
  `GoogleServiceClient.signIn()` → native `onSignIn()` / `onSignInFailed()` /
  `onSignInCanceled()`. Login game tetap bisa lewat Play Games / Supercell ID /
  tanpa akun (alur persisnya di native).
- **Facebook** login/Graph masih ada (`NativeFacebookManager`, `FacebookActivity`).

### 3.8 Format data — CSV: format lama bertahan + lapisan tanda tangan baru

- **16 file `assets/csv/*.csv`**: masih format kompresi Supercell klasik —
  header `5d 00 00 04 00 …` (sama persis dengan 5.2). Contoh:
  `animations.csv` `5d 00 00 04 00 74 76 03 00 00 11 10 88 27 23 35`,
  `billing_packages.csv` `5d 00 00 04 00 0a 52 00 00 00 11 13 88 26 d3 4d`.
  `texts.csv` / `texts_patch.csv` juga `5d…`.
- **BARU — format `Sig:`**: seluruh **44 file `assets/logic/*.csv`**
  (data gameplay: `buildings.csv`, `characters.csv`, `heroes.csv`,
  `spells.csv`, `traps.csv`, `war.csv`, `townhall_levels.csv`, …) **dan**
  `assets/csv/client_globals.csv` diawali `Sig:` + **64 byte tanda tangan**,
  baru kemudian payload kompresi `5d 00 00 04 00 …` di offset 68.
  Contoh `buildings.csv` (15.761 B): offset 0–3 `Sig:`, offset 4–67 signature
  (`6e f7 fa df a2 92 a0 c4 …`), offset 68 `5d 00 00 04 00 d5 b0 02 00 00
  11 13 88 26 d3 4d …`.
  - `fingerprint.json` SHA-1 = SHA-1 **seluruh file termasuk prefix `Sig:`**
    (terverifikasi: `buildings.csv` → `4e2e1e23be0d42caf3f3b60a0a736ff84eb9c175`
    cocok dengan entri fingerprint).
  - **Inferensi:** 64 byte = panjang signature Ed25519 (atau HMAC-SHA512
    terpotong / signature 512-bit). Verifikasi tanda tangan ini kemungkinan
    dilakukan native saat load CSV — **CSV hasil modifikasi tanpa signature
    yang valid akan ditolak klien** (belum terbukti runtime, tapi ini fungsi
    paling masuk akal dari prefix tersebut). Ini adalah proteksi integritas
    data baru yang tidak ada di 5.2.
- **BARU — `assets/globals.json` + `globals_definition.json`**: JSON plaintext
  (tuning server-driven yang bisa di-override: `Globals`, `KillSwitches`,
  `Village1`/`Village2` — mis. `TownHallMaxLevel: 9` untuk Builder Base,
  `LegendLeagueTrophyChange`, `DuelBonus…`). Indikasi sebagian konfigurasi
  pindah dari CSV biner ke JSON yang diambil dari server.
- **`assets/hs__data`**: JSON `"HSCharacters"` (peta karakter Helpshift).
- **Tidak ada `assets/level/`**: desa/NPC tidak lagi dibundel sebagai JSON —
  data level kemungkinan disajikan server (via pesan home data) atau dikompil
  ke `.sc`/native.

## 4. Delta vs CoC 5.2 (Nara) — yang relevan buat private server

| Aspek | 5.2 (2013, Nara Patch) | 13.369.4 (2020, resmi, armeabi-v7a) |
|---|---|---|
| Package / signer | `com.narapatch…`, self-signed "Nara Archieve" 2026 | `com.supercell.clashofclans`, Supercell resmi (`CN=Visa Forsten…`, RSA 4096) |
| ABI | armeabi-v7a saja | **armeabi-v7a saja di file ini** (arm64 ada di split terpisah — belum didapat) |
| minSdk / targetSdk | 15 / 18 | 16 / 29 |
| DEX | 1.094.512 B, 939 class | 8.276.280 B, 9.635 class (7,6×) |
| `libg.so` | 3.098.452 B, string plaintext (hostname + "Connecting to the production server…") | 13.607.752 B, **string terenkripsi** (`.data` entropi 7,98; `.rodata` hanya nama JNI) |
| Hostname server | `127.0.0.1` (di-patch Nara; aslinya `gamea.clashofclans.com`) | **Tidak ditemukan plaintext di mana pun** |
| Kunci RC4 UCS `"fhsd6f86…"` + `"nonce"` | Ada (di server Nara `com.nara.server`) | **0 kemunculan** — RC4 tidak terkonfirmasi |
| Kripto baru (Blake2/sodium/dll) | — | **0 kemunculan plaintext** — algoritma tak teridentifikasi dari statis |
| CSV game | 31 file di `csv/`, format `0x5D` | 44 file di **`logic/`** + 17 di `csv/`; logic + `client_globals.csv` ber-prefix **`Sig:` + 64 B signature** |
| Level JSON | 61 file `level/*.json` (TH1–10, NPC 1–48) | **Hilang** — tidak ada `level/` |
| `version.number` | Ada (5.2) | **Hilang**; versi di `fingerprint.json` = `13.369.5` (≠ 13.369.4) |
| Server privat tertanam | Ada (`com.nara.server`, 127.0.0.1:9339) | **Tidak ada** |
| Cek signature APK | Tidak dilaporkan | **Ada** — `checkSignature()`, 11 hash Base64 SHA-1 hardcoded |
| Device integrity | Tidak ada | **Ada** — `testDeviceIntegrity(byte[])` stub + `setDeviceVerificationResult(...)` native |
| Supercell ID | Tidak ada | **Ada, native** (`UseNative: true`, Game `magic`) |
| Play Games | Ada (GMS lama) | Ada (GMS + `GoogleServiceClient` → native) |
| `READ_PHONE_STATE` | Ada | **Hilang** |
| `CAMERA` | Tidak ada | **Ada** (QR Supercell ID) |
| `libcrypt-lib.so` | Tidak ada | **Ada — Adjust Signature V2** (bukan kripto game) |
| `libsentry` | Tidak ada | **Ada — crash reporting, DSN kosong** |
| `libfmodex.so` | Ada (871.096 B) | Diganti `libfmod.so` (952.092 B) |
| OpenUDID | Ada | **Masih ada** (service di manifest) |
| allowBackup | `false` | `true` |
| `usesCleartextTraffic` | — (era lama) | `true` |
| Anti-Frida string | Tidak dilaporkan | Ada template D-Bus `re.frida.HostSession` di `libg.so` |

**Yang SAMA (masih berlaku dari 5.2):** format kompresi CSV `0x5D` untuk
file `csv/`; struktur `fingerprint.json` (SHA-1 per file); `sc/` sebagai
wadah tekstur (168 file, 113 MB); `BILLING` + IAP; arsitektur umum
Java-tipis + `libg.so` sebagai otak game + protokol biner via TCP.

## 5. Implikasi buat pembangunan private server 13.x

**Fakta yang membatasi (bukan opini):**

1. **Jalur 5.2 tidak bisa dipakai ulang begitu saja.** Kunci RC4 + `"nonce"`
   tidak ada di klien ini; hostname tidak ada di plaintext; pesan 10101→20104
   tidak bisa dikonfirmasi dari statis — jadi server Nara **tidak** bisa
   diarahkan ke klien 13.369.4 hanya dengan ganti IP.
2. **CSV bertanda tangan.** 44 CSV gameplay + `client_globals.csv` membawa
   prefix `Sig:` 64 byte. Bila verifikasi signature dilakukan klien (sangat
   mungkin), CSV modifikasi / CSV dari server privat harus membawa signature
   yang valid — kuncinya tidak ada di APK (publik key kemungkinan di `libg.so`
   yang ter-obfuscasi).
3. **Cek signature APK.** Repack dengan signer lain gagal
   `checkSignature()` (11 hash) — private-server client berbasis klien ini
   harus menonaktifkan/mengakali cek tersebut (patch `libg.so` + DEX) atau
   memakai signer yang hash-nya ada di daftar (tidak mungkin).
4. **Integritas perangkat.** Ada jalur `testDeviceIntegrity` /
   `setDeviceVerificationResult` — server resmi kemungkinan menolak klien yang
   gagal atestasi; server privat harus memutuskan apakah mengimplementasikan
   atau mengabaikan pesan ini (pesan/field-nya belum diketahui).
5. **Semua protokol ada di native yang ter-obfuscasi.** Tanpa `libg.so`
   arm64 (file ini 32-bit) dan tanpa analisis runtime, nomor pesan, format
   login, dan algoritma enkripsi sesi 13.x **belum diketahui**.

**Langkah berikut yang masuk akal (untuk diputuskan user):**

1. Dapatkan **varian arm64-v8a yang benar** (APKMirror — tautan langsung user
   kena 403 dari VM; perlu unduh manual / tautan baru) agar `libg.so` arm64
   tersedia untuk REA lanjutan.
2. Analisis **runtime** di perangkat (POCO user, root): jalankan klien
   resmi 13.369.4, amati koneksi (host/port — diduga `gamea.clashofclans.com:9339`
   tapi **belum terverifikasi**), dump string `libg.so` setelah dekripsi di
   memori, dan tangkap handshake login. Ini satu-satunya jalan yang realistis
   untuk menemukan hostname + kripto sesi era 13.x.
3. Alternatif tanpa runtime: disassembly `libg.so` ARM32 ini (Ghidra —
   tidak tersedia di VM saat ini) untuk menemukan fungsi dekripsi string dan
   kunci — pekerjaan besar, tapi file 32-bit ini sudah cukup sebagai bahan.

## 6. Batasan analisis

- **Statis saja**: APK tidak di-install/dijalankan; perilaku runtime (host
  aktual, apakah login jalan, apakah ada koneksi tak terduga) tidak diverifikasi.
- **`libg.so` tidak di-decompile**: tidak ada Ghidra/IDA di VM — analisis
  native hanya strings + simbol dinamis + header ELF + entropi section +
  brute-force XOR 1-byte. Patch/fungsi di luar string tidak bisa
  dikesampingkan.
- **Varian salah**: file ini armeabi-v7a, bukan arm64 seperti namanya;
  `libg.so` arm64 belum dianalisis.
- **CSV tidak di-decode**: payload `0x5D` tidak dibuka isinya (format kompresi
  Supercell — percobaan zlib/lzma di REA 5.2 gagal); isi tabel game tidak dibaca.
- **Signature `Sig:` tidak diverifikasi**: algoritma (Ed25519 vs HMAC) hanya
  inferensi dari panjang 64 byte; public key tidak ditemukan.
- **Fingerprint signer resmi** tidak bisa dibandingkan ke sumber publik
  (Supercell tidak mempublikasikan fingerprint) — tapi package + signer +
  `checkSignature()` sudah konsisten dengan build resmi.

## 7. Artefak yang dihasilkan

Semua di `~/workspace/rea-coc-13x/` (APK **tidak** dihapus, tidak di-push):

- `dump-full/` — unzip lengkap APK (2.569 file)
- `analysis/INVENTORY.txt` — inventaris 2.714 baris + daftar file lengkap
- `analysis/libg_strings.txt` — 120.612 string ASCII `libg.so`
- `analysis/libg_strings_utf16.txt` — 88 string UTF-16 `libg.so`
- `analysis/dex_strings.txt` — 92.723 string `classes.dex`
- `analysis/libcrypt_strings.txt` — 2.528 string `libcrypt-lib.so`
- `analysis/libfmod_strings.txt` — 10.040 string `libfmod.so`
- `analysis/aapt_badging.txt`, `analysis/apksigner_verify.txt`,
  `analysis/manifest_xmltree.txt`, `analysis/aapt_resources.txt`,
  `analysis/filelist.txt`
- `analysis/jadx-out/sources/` — 6.190 file Java hasil decompile JADX 1.5.1
  (9 error; log: `analysis/jadx.log`)
- `analysis/REA-FINDINGS.md` — file ini

## 8. Ringkasan satu paragraf

Ini **klien resmi CoC 13.369.4 (22 Jun 2020) varian armeabi-v7a** — bukan
repack, bukan arm64 seperti nama filenya: package `com.supercell.clashofclans`,
signer resmi Supercell (`CN=Visa Forsten…`, RSA 4096, v1+v2), 2.569 file,
DEX 8,3 MB / 9.635 class. Dibanding 5.2, klien ini jauh lebih tertutup:
string `libg.so` terenkripsi (`.data` entropi 7,98; hostname
`gamea.clashofclans.com` dan kunci RC4 lama **tidak ditemukan di mana pun**),
CSV gameplay (44 file di `logic/`) kini ber-prefix `Sig:` + tanda tangan
64 byte, ada cek signature APK (11 hash hardcoded) dan jalur verifikasi
integritas perangkat, Supercell ID sudah native, dan ada `libcrypt-lib.so`
(Adjust Signature V2 — bukan kripto game) serta Sentry (DSN kosong). Yang
tetap sama: format kompresi CSV `0x5D`, `fingerprint.json` SHA-1, dan
arsitektur Java-tipis + `libg.so` sebagai otak. **Untuk private server
13.x, pekerjaan 5.2 tidak bisa dipakai ulang** — butuh `libg.so` arm64 yang
benar plus analisis runtime untuk menemukan host, pesan login, dan enkripsi
sesi yang sebenarnya.
