# REA — Clash of Clans 5.2 "Nara Patch" v1.5

**Sumber:** GitHub `Nara-ctrl/nara-game-client`, rilis `1.5_coc` (tautan unduhan langsung disensor — minta ke Alyaa bila perlu)
**Tanggal analisis:** 23 Nov 2026 (statis saja — APK **tidak** di-install, **tidak** dijalankan)

## 1. Identitas

| Item | Nilai |
|---|---|
| Package name | `com.narapatch.clashofclans` (resmi Supercell: `com.supercell.clashofclans`) |
| versionName / versionCode | `5.2` / `512` |
| minSdk / targetSdk | 15 / 18 (Android 4.0.3 / 4.3 — era 2013) |
| Ukuran APK | 48.403.876 B (±46,2 MiB) |
| SHA-256 APK | `d740d9ba7e7e70eeabc7ace304a7d0283aadaaa8fdfc2f401ae8aff69d21b6b2` |
| Label aplikasi | `Clash of Clans` (tidak diganti) |
| Activity utama | `com.supercell.clashofclans.GameApp` |
| ABI | **armeabi-v7a saja (32-bit)** — tidak ada arm64-v8a |
| Debuggable | **Tidak** (tidak ada atribut `android:debuggable` di manifest) |
| allowBackup | `false` |
| Basis klien | CoC 5.2, build 27 Sep 2013 (`assets/version.number`: version=5, build=2, content_revision=1) |
| Skema tanda tangan | v1 + v2 + v3 terverifikasi (apksigner); v3.1/v4 tidak |

### Signer (1 signer)

- **Subject/Issuer (self-signed):** `CN=Nara Archieve, OU=?Nara, O=?Ranker, C=ID`
- Serial `2a195c97`; berlaku **26 Okt 2026 – 13 Okt 2076**; RSA 2048-bit, SHA256withRSA
- SHA-256: `EB:E3:39:8E:AA:A3:40:FA:59:D7:B2:30:A4:14:F8:3B:DD:44:12:3F:BD:A3:70:C0:24:FA:5F:FD:60:31:5E:66`
- SHA-1: `13:6B:FF:08:36:37:15:63:E2:C8:DF:53:AA:39:1B:D2:CC:CE:1C:C8`
- Alias keystore: `NARA` (`META-INF/NARA.RSA`, `.SF`, `MANIFEST.MF` — "Created-By: Android Gradle 8.0.2")

### Permissions

`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `CHANGE_WIFI_STATE`, `ACCESS_WIFI_STATE`,
`READ_PHONE_STATE`, `com.android.vending.BILLING`, `com.google.android.c2dm.permission.RECEIVE`,
`com.narapatch.clashofclans.permission.C2D_MESSAGE`, `WRITE_EXTERNAL_STORAGE`
(+ `READ_EXTERNAL_STORAGE` tersirat). Ini persis set permission klien asli 2013 — tidak ada
permission baru yang ditambahkan oleh patch.

## 2. Verdict: REPACK / MOD — BUKAN klien resmi Supercell

Bukti (semua fakta dari artefak):

1. **Package name diganti** `com.supercell.clashofclans` → `com.narapatch.clashofclans`.
2. **Signer bukan Supercell**: sertifikat self-signed atas nama "Nara Archieve", dibuat
   26 Okt 2026 — 13 tahun setelah klien ini dibangun.
3. **Klien asli dari 2013** (versi 5.2, aset bertanggal 27 Sep 2013) dikemas ulang
   18 Nov 2026 (mtime file hasil repack).
4. **Server resmi diputus**: tidak ada lagi hostname Supercell di `libg.so`
   (`gamea.clashofclans.com` tidak ditemukan sama sekali); alamat server produksi
   diganti `127.0.0.1` (2 kemunculan, tepat di samping string
   `"Connecting to the production server..."` / `"Connecting to server at %s"`).
5. **Server privat tertanam di dalam APK** (lihat §3).

Perbandingan fingerprint signer resmi Supercell tidak dapat dilakukan dari sumber publik
(Supercell tidak mempublikasikan fingerprint sertifikatnya) — tapi verdict tidak
bergantung pada itu: package + signer + tanggal sertifikat sudah membuktikan repack.

## 3. Temuan kunci

### 3.1 Server privat "Nara Revive" tertanam di dalam aplikasi (offline, localhost)

Ini inti patch-nya. Paket Java baru **`com.nara.server`** (49 class, hasil decompile JADX,
`analysis/jadx-out/sources/com/nara/server/`) adalah implementasi server privat lengkap
— port Java dari pola server privat CoC era UCS (Ultrapowa Clash Server):

- **`AndroidServer.start(Context)`** dipanggil dari `GameApp.onCreate()` (sebelum
  `super.onCreate`), menjalankan thread daemon `NaraServerAccept` yang memanggil
  `Server.serve("127.0.0.1", 9339, …)` — server TCP yang **hanya bind ke loopback
  127.0.0.1:9339** (bukan 0.0.0.0 — tidak bisa dijangkau dari jaringan).
- **`Server.serve`**: backlog 8, maks 8 sesi bersamaan (Semaphore), thread
  `NaraHubChat` / `NaraHubClan` / `NaraSession`; log ke `nara_server.log`
  (di external files dir bila ada, kalau tidak di files dir).
- **Protokol**: pesan biner CoC klasik (login `10101` → `20104` LoginOk;
  perintah `10108` → `20108`; home data `24101`; NPC `24133`; klan `24301/24303`;
  chat `24715`; ranking `24403/24404`, dst), enkripsi **RC4** dengan kunci publik
  era UCS: key `"fhsd6f86f67rt8fw78fw789we78r9789wer6re"` + nonce `"nonce"`
  (`Data.RC4_KEY` / `RC4_NONCE` — kunci yang sudah lama beredar publik, bukan rahasia).
- **State lokal persisten**: `nara_state.json` di files dir aplikasi (maks 1 MB saat
  dibaca; tulis atomik via `.tmp` + rename + `.bak`).
- **Mode standalone**: `Server.main()` juga bisa jalan sebagai server desktop
  (`--port`, `--resources <n>`, `--stage`, `--no-tutorial`).
- **Tidak ada koneksi keluar dari paket server**: tidak ada `HttpURLConnection`,
  `URL`, atau soket klien di `com.nara.server` — server 100% lokal.
  Satu-satunya koneksi keluar adalah klien game itu sendiri ke endpoint SDK pihak
  ketiga / tracking Supercell (lihat §5).

### 3.2 Dunia game disimulasikan secara lokal ("multiplayer" palsu)

- **Ekonomi penuh di server lokal** (`Config.java`, ~2.700 baris): gold/elixir/dark/gems,
  bangunan, unit, spell, hero, antrean latih, shield, achievement, loot, trofi, XP —
  semua dengan clamp server-side (resource maks 1.000.000.000).
- **Default awal**: gold 1000, elixir 1000, **gems 500**, nama pemain `"Nara"`,
  stage `"full"`, tutorial aktif.
- **Stage `"full"`**: server memakai `assets/level/townhall<N>.json` sebagai template
  desa (dan desa lawan); `pickStage()` mengembalikan `"full"`.
- **Klan & chat bot** (`Hub.java`, `Data.java`): klan dummy (`"Nara Revive"`,
  `"Indo Warriors"`, `"Dragon Slayers"`, …), pesan chat bot multibahasa (termasuk
  Indonesia: *"halo semua", "wkwk", "gas push trophy"*), nama bot
  (`"Goblin King"`, `"Barbarian"`, `"Archer Queen"`, …), ranking dan pesan stream
  yang dibuat-buat. **Tidak ada pemain manusia lain** — semua lawan/klan/chat adalah
  simulasi lokal.
- **Level**: 48 base NPC (`npc1–48.json`) + `starting_home.json` +
  `townhall1–10.json` + 2 tutorial NPC.

### 3.3 Jejak modifikasi yang terukur (66 dari 507 file, 18 Nov 2026)

Perbandingan mtime di ZIP + hash SHA-1 vs `assets/fingerprint.json` (manifest asli
Supercell, 792 entri):

| Yang diubah | Bukti |
|---|---|
| `AndroidManifest.xml` | mtime 2026-11-18; package diganti |
| `classes.dex` | mtime 2026-11-18; +49 class `com.nara.server`, `GameApp` disisipi pemanggilan server |
| `META-INF/*` | ditandatangani ulang 2026-11-18 23:03 (NARA.RSA/SF) |
| `assets/level/*.json` (62 file) | semua ditulis ulang 2026-11-18 12:40; **isi berubah pada `townhall3–10.json`** (hash ≠ manifest asli — base TH3–TH10 sudah di-upgrade/dimaksimalkan, mis. `townhall10.json` = TH lvl 9 dengan bangunan lvl 10–11); file lain hash-nya tetap cocok (hanya serialisasi ulang) |
| `assets/sc/ui.sc`, `ui_lowres.sc` | hash SHA-1 ≠ manifest asli (konten UI diubah — kemungkinan branding/kustomisasi Nara; mtime file dipertahankan 2013, jadi tanggal ubahnya tidak terbukti dari metadata) |

**Tidak diubah (441 file, mtime tetap 27 Sep 2013):** `libg.so`, `libfmodex.so`,
31 CSV, 20 file `.sc` lainnya, `res/`, font, musik, dan semua aset lain.
Catatan: 444 entri fingerprint "hilang" adalah file suara `.caf` (format iOS) yang
memang tidak pernah disertakan di build Android (APK memakai `.ogg`, 222 file) —
bukan bukti penghapusan oleh patch.

### 3.4 Klien native di-patch minimal: hanya alamat server

- `libg.so` (3.098.452 B, SHA-256 `57073632…2172`, ARM 32-bit, stripped,
  12.208 simbol dinamis — termasuk FreeType yang di-link statis) **tidak lagi
  mengandung hostname Supercell**; satu-satunya alamat server adalah `127.0.0.1`.
- String lain yang masih ada: `https://service.supercell.net/tracking/login`
  (endpoint tracking Supercell) dan URL foto profil Facebook (`fbcdn.net`) —
  sisa klien asli, bukan tambahan Nara.
- `libfmodex.so` (871.096 B, SHA-256 `30c8c99d…84c8ac0`) = FMOD Ex, tidak berubah.

### 3.5 Komunitas & donasi Nara (string di DEX)

- "This project was created and developed by Nara Archieve through the \"revive\" project!"
- Discord: https://discord.gg/2dHDk36YBk · Telegram: https://t.me/+SptgKXM7uqA4OTA1
- Donasi: https://ko-fi.com/nara_archive · https://saweria.co/naraarchieve
- Pesan default klan: "Nara community clan. Welcome!"

### 3.6 SDK pihak ketiga era 2013 masih aktif di DEX

939 class / 8.769 method / 8.683 string. Selain `com.supercell.*` dan
`com.nara.server`, DEX berisi SDK asli 2013: **Chartboost**, **Facebook SDK**,
**Google Play Games / GMS**, **MobileAppTracker (TUNE)** + receiver
`INSTALL_REFERRER`, dan **`org.OpenUDID`** (layanan fingerprinting perangkat,
sudah lama deprecated). Semua ini akan tetap menghubungi server vendornya
masing-masing bila aplikasi dijalankan.

## 4. Inventaris ringkas

- **DEX**: `classes.dex` 1.094.512 B, DEX v035, 1 file saja.
  SHA-256 `d285a71f199b85ee3bc4f61039583cabd66b870c3d5491c81f8665060c211e9a`.
- **Native**: `lib/armeabi-v7a/libg.so` (3.098.452 B),
  `lib/armeabi-v7a/libfmodex.so` (871.096 B). Keduanya ELF32 ARM, stripped,
  dinamis. **Tidak ada arm64-v8a** → perangkat tanpa dukungan ABI 32-bit tidak
  bisa menjalankan APK ini.
- **Assets** (46 MB): `csv/` 31 file (terkompresi format Supercell — header
  `0x5D…`, bukan zlib polos; isi tidak bisa dibaca langsung, dan tabel gamenya
  justru di-hardcode di `Data.java`), `level/` 61 JSON, `sc/` 20,
  `sfx/ogg/` 222, `music/` 9, `font/` 4, `titan/` 6, `fingerprint.json`,
  `version.number`, `image/tileset.png`.
- **res/**: 143 file, 9 direktori; `resources.arsc` 122.616 B; label tetap
  "Clash of Clans"; tidak ada string "Nara"/"Revive" di resources.
- Inventaris lengkap (507 file + ukuran): `analysis/INVENTORY.txt`.
- Strings: `analysis/libg_strings.txt`, `analysis/dex_strings.txt`,
  `analysis/libfmodex_strings.txt`; decompile: `analysis/jadx-out/sources/`
  (316 class).

## 5. Keamanan — apa adanya

**Tidak ditemukan bukti malware** pada kode yang ditambahkan: tidak ada C2,
tidak ada kredensial/API key yang disisipkan, tidak ada pencurian data, tidak ada
dynamic code loading, tidak ada permission baru, dan server tambahannya hanya
mendengarkan di loopback (127.0.0.1:9339) sehingga tidak terekspos ke jaringan.
State game tersimpan lokal (`nara_state.json`, tanpa enkripsi — siapa pun yang
punya akses file bisa membaca/mengubahnya, tapi itu konsekuensi desain server
lokal, bukan backdoor).

Yang patut dicatat (risiko, bukan vonis):

1. **Repack dari sumber komunitas** (GitHub `Nara-ctrl`) — kepercayaan penuh pada
   pembuatnya; tidak ada cara memverifikasi bahwa `libg.so` 3 MB itu identik
   dengan biner asli 2013 selain dari tidak adanya indikator anomali yang
   ditemukan di analisis statis ini (tidak ada dekompilasi native mendalam —
   lihat §6).
2. **SDK kuno**: OpenUDID + `READ_PHONE_STATE` (baca IMEI/identitas perangkat),
   MobileAppTracker, Chartboost, Facebook SDK 2013 — semuanya mengirim data ke
   vendornya dengan asumsi keamanan satu dekade lalu. Ini bawaan klien asli,
   bukan tambahan Nara, tapi tetap berlaku bila aplikasi dijalankan.
3. **Koneksi keluar yang tersisa**: `service.supercell.net/tracking/login` dan
   endpoint SDK di atas; traffic *game*-nya sendiri 100% lokal.
4. **IAP tidak bisa jalan normal**: permission `BILLING` ada (bawaan 2013),
   tapi tidak ada server Supercell untuk memverifikasi pembelian — pembelian
   uang asli tidak punya jalur yang sah di build ini.
5. **Akun & progres tidak bisa dipindah ke game resmi**: semua data hidup di
   server lokal; package berbeda → tidak akan pernah sinkron dengan Supercell,
   dan memainkan klien hasil modifikasi terhadap server resmi adalah pelanggaran
   ToS (di sini tidak terjadi karena servernya lokal).

## 6. Batasan analisis

- **Statis saja**: APK tidak di-install/dijalankan; perilaku runtime (apakah
  server benar-benar naik, apakah game bisa login, apakah ada koneksi tak
  terduga saat jalan) tidak diverifikasi.
- **Tidak ada Ghidra/Hopper/IDA di VM** — `libg.so` hanya dianalisis lewat
  strings + simbol dinamis + header ELF. Patch native di luar string alamat
  server (mis. perubahan kecil pada fungsi) tidak bisa dikesampingkan sepenuhnya.
- **Tidak ada APK resmi CoC 5.2 sebagai pembanding** — kesimpulan "tidak diubah"
  untuk 441 file didasarkan pada mtime 2013 + hash vs `fingerprint.json` internal,
  bukan diff biner terhadap rilis resmi.
- **CSV tidak ter-decode**: file `assets/csv/*.csv` memakai kompresi Supercell
  (header `0x5D…`, percobaan `zlib` dan `lzma` FORMAT_ALONE gagal) — isinya
  tidak dibaca; tabel game diambil dari `Data.java` yang di-hardcode server.
- **Login handler** (`Session.handleLogin`) dibaca sebagian — balasan LoginOk
  (20104) diberikan tanpa autentikasi remote; cabang validasi detail (mis. cek
  versi/fingerprint klien) tidak ditelusuri baris per baris.
- Fingerprint signer resmi Supercell tidak tersedia publik, jadi perbandingan
  sertifikat resmi tidak dilakukan (tidak memengaruhi verdict — lihat §2).

## 7. Ringkasan satu paragraf

Ini **repack CoC 5.2 (2013) menjadi "private server offline"**: package diganti
ke `com.narapatch.clashofclans`, signer diganti sertifikat "Nara Archieve"
(26 Okt 2026), alamat server di `libg.so` di-patch ke `127.0.0.1`, dan sebuah
server privat lengkap (`com.nara.server`, port dari pola UCS, RC4 dengan kunci
publik era 2013) ditanam di dalam APK sehingga game berjalan sepenuhnya lokal
di port 9339 — dengan desa awal TH1–TH10 yang sudah dimodifikasi, klan/chat/
ranking bot, dan tanpa pemain manusia lain. 441 dari 507 file masih byte-identik
dengan aslinya; yang diubah hanya manifest, DEX, META-INF, 62 file level JSON,
dan 2 file tekstur UI. Tidak ditemukan indikator malware pada kode tambahan,
tapi ini tetap build komunitas tak resmi dengan SDK 2013 yang sudah usang.
