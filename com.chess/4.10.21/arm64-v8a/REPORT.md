# Laporan Dump & REA Penuh — Chess.com "Chess / Catur" (com.chess)

Tanggal analisis: 22 Oktober 2026 (WIB)
Metode: unduh via Google Drive API (CLI `hatch_gws_cli drive files get`, alt=media) → verifikasi MD5/SHA-256 → unzip inventaris penuh (APKS + 4 APK) → androguard 4.1.4 (manifest, izin, sertifikat) → binutils (`readelf`/`nm`/`strings`) untuk seluruh 32 berkas `.so` → ekstraksi string 11 dex (±615 ribu string) untuk endpoint & arsitektur.
Catatan: analisis statis murni — APK tidak dijalankan, server Chess.com tidak dihubungi. Tidak ada Java/keytool/apksigner di VM ini; sertifikat dibaca via androguard (hasilnya konsisten antar keempat APK).

---

## 1. Identitas file (terverifikasi dari file-nya sendiri)

| Item | Nilai |
|---|---|
| Nama file | `Catur_4.10.21-googleplay.apks` |
| Ukuran | 119.043.199 byte (±119 MB); MD5 `a9da44e5e8b237b9615bfd1f33066c7b` (cocok dengan metadata Drive) |
| SHA-256 | `9246bc1aef737e6fb360449f444dd4bcbd3f44dd8ba17448340c9d292dfc6e73` |
| Isi APKS | `base.apk` 149.982.732 byte + `split_config.arm64_v8a.apk` 39.893.824 + `split_config.in.apk` 643.481 (bahasa Indonesia) + `split_config.xxhdpi.apk` 1.088.392 — total tak-terkompresi 191.608.429 byte |
| Package | `com.chess` |
| Nama aplikasi | "Chess" (judul listing Play Store Indonesia: "Catur") |
| Versi | versionName **4.10.21-googleplay**, versionCode **280090** |
| SDK | minSdk 28, targetSdk 36 |
| Activity utama | `com.chess.splash.SplashActivity` |
| Izin (30) | INTERNET, `com.android.vending.BILLING`, READ_CONTACTS, lokasi kasar+halus, BLUETOOTH (SCAN/CONNECT — papan catur fisik "connected boards"), USE_BIOMETRIC, POST_NOTIFICATIONS, DETECT_SCREEN_CAPTURE, izin iklan AdServices/AD_ID, dll. |

### Vonis keaslian: **BUILD ASLI Play Store (Chess.com), BUKAN modifan pihak ketiga**

- Sertifikat penanda tangan (sama di keempat APK): `CN=Anton Shapovalov, OU=developer, O=Jetmind, L=Kharkov`, self-signed, serial `0x4b24f06a`, SHA-256 sertifikat `aa8c9ff93efbdc4226a113e49fc9645b2c02092a314305da2d76be6cdf8abfc3`. Ini sertifikat rilis resmi aplikasi Chess.com (`com.chess`).
- Skema tanda tangan **v2 + v3 aktif**, v1 tidak. Ada `META-INF/BNDLTOOL.SF/.RSA` → APKS dibangkitkan **bundletool** dari AAB, persis pola dump Play Store.
- Semua endpoint di dalam kode mengarah ke `*.chess.com`; tidak ada paket asing/pintu belakang ala mod pihak ketiga.

---

## 2. Dump penuh — inventaris isi

| Komponen | Isi |
|---|---|
| DEX | **11 berkas** di base.apk (`classes.dex` … `classes11.dex`, total ±108,6 MB) — kode Kotlin/Java aplikasi (173 activity) + library |
| Lib native | **32 berkas `.so`, SEMUA di split arm64** — hanya ABI **arm64-v8a** (tidak ada 32-bit sama sekali) |
| `assets/*.bin` (14) | Buku pembukaan **Polyglot** per gaya/kepribadian bot (header terbaca "Created by Polyglot"): aggressive, balanced, beginner, classical, f-pawner, fischer, gambit, indian, nakamura, offbeat, positional, quick_queen, rensch, winger |
| `assets/bots_avatars/` | 196 berkas avatar bot |
| `assets/clubs/`, `assets/courses/`, `assets/events/` | Bundle React Native **Module Federation** (Re.Pack) — fitur yang dimuat sebagai "remote": clubs, courses, events |
| `assets/*.json` | Animasi Lottie (emoji, confetti, course_complete, daily_bonus, benchmark, capture, chase, …) |
| `assets/sounds/` | 66+ efek suara termasuk puzzle-path |
| `assets/cee_version.json` | `{"libcee": "1.193.1", "uci": "1.130.70"}` |
| Penyimpanan lokal | `chess.db`, `gameSettingsStore.db`, `gameplayLiveSettingsStore.db`, `gamesCount.db`, `membershipSnapshotStore.db`, DataStore + MMKV |

---

## 3. Bedah semua lib `.so` (32 berkas, semua ELF64 AArch64, semua stripped `.symtab`)

### 3a. Lib spesifik game (Chess.com)

| Lib | Ukuran | Karakterisasi |
|---|---|---|
| **libcee.so** | 50.655.696 | **Mesin catur proprietari Chess.com** ("CEE") + *explanation engine*. API C publik 27 fungsi `CEE_*` (CEE_Init, CEE_NewFeature, CEE_Run, CEE_Play, CEE_GetLastMove, CEE_GetUpdate, CEE_AddArtifactFromFile, CEE_IsValidGamePoint, …). Skema protobuf tertanam: `chesscom/explanation_engine/v1` (bot.proto, search.proto, skills.proto, speech.proto, stats.proto, tcn.proto) dan `chesscom/engine/v1` (strength.proto, evaluation.proto). Memuat sesi **UCI internal** (`cee_uci_main`, `UCI_parse_setoption`, opsi UCI_Elo, UCI_Chess960, UCI_Variant, UCI_AnalyseMode) dan enum engine eksternal: STOCKFISH_9_FAIRPLAY_1, STOCKFISH_12, 15, 15.1_NNUE, 16_NNUE, 16_1_NNUE, 18_NNUE, STOCKFISH_RELABELED. 36.460 dynsym (mayoritas artefak C++/protobuf), ±87.960 string terbaca, layout section normal, entropi wajar → **tidak di-pack**. Inilah otak untuk: lawan bot, coach, hint, penjelasan langkah, sebagian game review. |
| **libcee_driver.so** | 1.513.688 | **Executable PIE mandiri** (bukan .so biasa), menaut libcee.so. Menjalankan CEE di luar proses app: mode `-f/--file` (jalankan berkas perintah lalu keluar), `-s/--socket` (server **Unix domain socket** untuk request CEE), `-u/--uci` (mode UCI dari berkas perintah). Kemungkinan besar perkakas internal/tooling yang ikut terkemas. |
| **libcee-wrapper.so** | 7.544 | Jembatan JNI tipis: 13 export `Java_com_chess_compengine_wrapper_JniCeeWrapper_*` → lapisan Kotlin `com.chess.compengine.*` yang dipakai fitur versus-bots & coach. |

### 3b. Lib keamanan / atestasi

| Lib | Ukuran | Karakterisasi |
|---|---|---|
| **libapproov.so** | 244.664 | **Approov SDK (CriticalBlue)** — atestasi aplikasi untuk melindungi API. Export JNI: `AttestationServicesAndroid.service`, `NetworkServicesAndroid.ping/readLastPingTime`. Endpoint atestasi ditemukan di dex: `https://attest.approoval.com/token`. Inilah anti-tamper utama aplikasi (bukan Play Integrity — string Play Integrity/SafetyNet/RootBeer **tidak ditemukan** di dex; Approov melakukan pemeriksaan lingkungannya sendiri secara native, perilaku runtime-nya tidak bisa dikonfirmasi statis). |
| **libnhook.so** | 273.832 | **Confiant SDK** (`com.confiant.android_sdk`) — hook metode ART (`nativeInstallHook`, `getOriginalCallPolicy`, dst.) untuk **integritas iklan / anti-malvertising** di WebView iklan. BUKAN anti-cheat game. |
| libcrashlytics*.so (4) | 232.384 / 865.608 / 222.400 / 4.752 | Firebase Crashlytics. Impor ptrace/fork/execv = mesin penanganan crash standar, bukan anti-debug yang diarahkan ke pemain. |

### 3c. Lib platform/framework (React Native & pendukung)

| Lib | Ukuran | Peran |
|---|---|---|
| libreactnative.so | 6.763.936 | Inti React Native (arsitektur baru/Fabric+TurboModule) |
| libhermesvm.so | 2.460.728 | VM JavaScript **Hermes** (bytecode) |
| libappmodules.so | 1.833.240 | Modul native aplikasi hasil codegen RN — termasuk **RNChessBoardView** (komponen papan catur Fabric untuk fitur RN), RNCWebView, RNVideoPlayer, Bugtivity |
| librive-android.so | 7.869.400 | Animasi Rive (283 export JNI) |
| libjsi.so | 395.912 | JavaScript Interface RN |
| libfbjni.so | 177.000 | JNI helper Facebook |
| libhermestooling.so | 138.504 | Perkakas Hermes |
| libcallstack-repack.so | 65.928 | Runtime **Re.Pack** (Module Federation) — memuat remote clubs/courses/events |
| libNitroModules.so | 979.432 | react-native-nitro-modules |
| libNitroMmkv.so | 459.576 | MMKV versi Nitro |
| libmmkv.so | 358.160 | MMKV (penyimpanan key-value Tencent) |
| libreact_codegen_RNCSlider.so / _rnscreens / _rnsvg / _safeareacontext + librnscreens.so | 236.840 / 930.672 / 787.944 / 157.760 / 100.904 | Codegen komponen RN pihak ketiga |
| libnative-filters.so / libnative-imagetranscoder.so / libimagepipeline.so | 23.712 / 585.376 / 8.760 | Pipeline gambar Fresco |
| libdatastore_shared_counter.so | 7.784 | Pendukung native AndroidX DataStore |
| libandroidx.graphics.path.so | 10.096 | Path grafis AndroidX |
| libkt.so | 4.184 | Executable PIE mungil (trampoline Kotlin/Native) |
| libc++_shared.so | 1.292.904 | Runtime C++ standar |

**Tidak ada** `libil2cpp.so`/`global-metadata.dat` (bukan Unity), tidak ada Unreal/Godot. Tidak ada packer komersial pada lib mana pun (section & string normal di semua berkas).

Impor "mencurigakan" lintas lib semuanya jinak & terjelaskan: crashlytics-handler/trampoline (dlopen/dlsym untuk crash), hermesvm (mprotect untuk eksekusi bytecode), approov (socket untuk ping atestasi), libcee (system@LIBC), jsi/reactnative (popen — perkakas dev RN). Tidak ada impor ptrace anti-debug di lib game.

---

## 4. Di mana logika game hidup

**Hibrida tiga lapis:**

1. **Native Kotlin/Java (dominan)** — 11 dex, 173 activity: live chess (`com.chess.live.*`, `com.chess.internal.live.*`, `LiveChessService`), daily chess, puzzles (`RatedPuzzlesGameActivity`, `RushPuzzlesGameActivity`), lessons, membership/paywall, profil, fair play (`com.chess.fairplay.*`, `GameStartChecksDelegate`). UI campuran Views + Compose.
2. **React Native / Hermes (minoritas)** — hanya fitur "remote" Module Federation yang bundle-nya ada di assets: **clubs, courses, events**. Papan catur untuk fitur RN disediakan sebagai komponen native (RNChessBoardView).
3. **Native C++ (mesin)** — libcee.so: perhitungan langkah bot, evaluasi, penjelasan coach, hint. Berjalan **di perangkat** lewat JNI (`com.chess.compengine`) untuk permainan vs bot (`com.chess.features.versusbots.*`, ada `BotGamesArchive` lokal dan `BotScoresSync` untuk sinkronisasi hasil).

---

## 5. Arsitektur ekonomi & progres: SERVER-AUTHORITATIVE (untuk semua yang berarti)

Bukti dari file:

- **Live chess = server relay.** Paket `com.chess.live.client.*` + `LiveChessService`, string WebSocket/RSocket, host `live.chess.com` / `live2.chess.com`. Langkah dikirim ke server, divalidasi & diteruskan server; jam dan hasil pertandingan ditentukan server. Daily chess juga server (`DailyGameSeekActivity`, properti statistik `StatsDailyProperty`).
- **Rating & statistik = catatan server.** Skema protobuf user-properties memuat `RatingsProperty`, `StatsLiveProperty`, `WDLProperty`, `TournamentStatsProperty`, `UserPuzzleStatsProperty`, `PuzzleRushProperty`, `LeagueProperty`, `UserStreakV2Property` — semua data akun yang disinkronkan dari server, bukan dihitung lokal.
- **Membership/premium = entitlement server.** Izin BILLING + BillingClient (Play Billing) untuk langganan; status langganan adalah `SubscriptionProperty` dari server; di perangkat hanya ada **snapshot cache** (`membershipSnapshotStore.db`). Gerbang fitur (`LessonPaywallGate`, `PuzzlePaywallGate`) membaca status itu. Fitur premium berat seperti **Game Review berjalan lewat server**: `wss://analysis.chess.com/v2/game-review` dan `https://analysis.chess.com/twirp/` (Twirp RPC) — tanpa entitlement valid di server, layanan ini tidak melayani.
- **Fair play = server.** Di klien ada paket `com.chess.fairplay`, dialog perjanjian FAIR_PLAY, penghitung laporan cheat, dan status penutupan akun `CLOSURE_STATUS_CHEATING_SANDBAGGING` / `_WITH_REPORT` / `_WITHOUT_REPORT` pada properti pengguna — klien hanya pelapor/penampil; **deteksi kecurangan engine adalah analisis korelasi pasca-pertandingan di server** (konsisten dengan adanya engine-id `STOCKFISH_9_FAIRPLAY_1` di dalam konfigurasi engine libcee). Mekanisme deteksi internal server tidak ada di dalam file (tidak bisa diverifikasi lebih jauh secara statis).
- **API dilindungi atestasi.** Approov (libapproov.so + token endpoint) menandai request API dari aplikasi resmi; request dari klien yang dimodifikasi berisiko ditolak di lapisan ini (perilaku persisnya runtime, belum terkonfirmasi statis).
- **Yang benar-benar lokal:** pengaturan & cache (DB-DataStore-MMKV di atas), arsip permainan bot, pass-and-play, dan **seluruh perhitungan engine vs bot** (libcee di perangkat — permainan vs komputer bisa berjalan offline; hasilnya kemudian disinkronkan via `BotScoresSync`).

Ekonomi: **tidak ada mata uang virtual** yang bisa diakumulasi/dimanipulasi di aplikasi ini — tidak ada soft/hard currency; satu-satunya "ekonomi" adalah langganan membership (server) dan data rating/statistik (server).

---

## 6. Vonis cheat per fitur (klasifikasi server-vs-lokal, berbasis bukti file)

| Fitur | Vonis | Alasan (bukti) |
|---|---|---|
| Suntik langkah / langkah ilegal di game online vs manusia | **TIDAK (server)** | Live chess relay server (live.chess.com, LiveChessService, validasi server); klien bukan penentu legalitas/hasil |
| Rating/Elo (bullet/blitz/rapid/daily) | **TIDAK (server)** | RatingsProperty & statistik adalah catatan server |
| Bantuan engine real-time saat lawan manusia (overlay best-move) | **SEBAGIAN secara teknis — DILARANG & risiko ban permanen** | Keadaan papan + engine kelas Stockfish memang ada di perangkat (libcee/UCI), jadi overlay analisis *secara teknis* bisa dihitung lokal. TAPI inilah persis yang dideteksi fair-play server (korelasi engine pasca-game; status penutupan akun CHEATING ada di skema) → akun ditutup. Bukan jalur yang disarankan untuk akun bernilai apa pun |
| Hint / best-move / analisis saat lawan BOT & latihan offline | **BISA PENUH (lokal)** | Engine 100% di perangkat (libcee via compengine); vs-bots berjalan lokal, arsip lokal |
| Modifikasi kekuatan bot (UCI_Elo, strength, buku Polyglot per persona) | **BISA (lokal)** | Parameter engine & 14 buku .bin dibaca dari perangkat oleh CEE (CEE_AddArtifactFromFile) — hanya memengaruhi permainan vs komputer |
| Rating puzzle & skor Puzzle Rush | **TIDAK (server)** | RatedPuzzlesGameActivity + UserPuzzleStatsProperty/PuzzleRushProperty disinkronkan ke server; attempt dinilai server |
| Membership/premium (lessons berbayar, game review penuh, bebas iklan) | **TIDAK — edit lokal hanya DISPLAY-ONLY** | Entitlement = SubscriptionProperty server + verifikasi Play Billing; cache lokal hanyalah snapshot; game review dilayani wss server yang memeriksa entitlement |
| Streak, XP, liga, achievement, progres lessons | **TIDAK (server)** | Properti akun tersinkron (UserStreakV2Property, LeagueProperty, CoursesProperty) |
| Tema papan / flair / kosmetik berbayar | **DISPLAY-ONLY** | Item adalah entitlement akun; mengganti aset lokal hanya mengubah tampilan sendiri, tidak mengubah kepemilikan di server |
| Edit save/DB lokal | **SEBAGIAN (lokal saja, tanpa dampak akun)** | chess.db & store lain = cache/pengaturan; data akun ditimpa sinkronisasi server |
| Speed hack | **Tidak applicable / TIDAK** | Tidak ada kategori speed di catur; jam pertandingan online ditegakkan server. Kecepatan search engine lokal hanya memengaruhi analisis lokal |
| God mode / damage / item spawn | **Tidak applicable** | Tidak ada HP/stat/item di game catur |

---

## 7. Saran (realistis)

1. **Untuk permainan online vs manusia: tidak ada permukaan cheat yang layak.** Seluruh hasil, rating, dan progres adalah server-authoritative, API dilindungi atestasi Approov, dan deteksi engine-assistance berjalan di server dengan sanksi penutupan akun. Mod menu/injektor untuk mode ini = jalan buntu teknis sekaligus risiko ban permanen.
2. **Satu-satunya permukaan lokal yang nyata adalah engine di perangkat (libcee).** Pemakaian sah yang masuk akal: alat **analisis & latihan** — overlay evaluasi/best-move untuk permainan vs bot, puzzle tak-berating, dan review pasca-game sendiri. Di wilayah ini semua BISA PENUH karena tidak ada server yang menentukan hasil.
3. **Premium tidak bisa "dibuka" dari klien secara bermakna** — yang bisa diubah lokal hanyalah tampilan gerbang; layanan premiumnya sendiri (game review, lessons) dilayani server berdasarkan entitlement.
4. Bila tujuannya riset engine: `libcee_driver.so` menyediakan antarmuka berkas/socket/UCI resmi dari pembuatnya sendiri untuk menjalankan CEE di luar aplikasi — jalur analisis yang bersih tanpa memodifikasi APK.
5. File ini adalah aset game komersial (engine proprietari + konten Chess.com) — simpan privat, jangan distribusikan ulang.

## 8. Yang belum terkonfirmasi (butuh runtime)

- Perilaku persis Approov saat aplikasi dimodifikasi/di-root (string statis tidak memuat logika root-check; Approov memeriksanya secara native/server-side).
- Seberapa jauh permainan vs bot bisa berjalan full-offline sebelum wajib sinkron (ada BotScoresSync; batas pastinya perilaku runtime).
- Sinyal fair-play apa saja yang dikumpulkan klien selama game berjalan (paket fairplay ada; daftar sinyalnya ter-obfuscate di dex).
