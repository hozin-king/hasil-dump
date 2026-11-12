# REA PENUH — Infinitode 2 R.1.9.2 (file Google Drive, 22 Okt 2026)

Analisis statis penuh atas file kiriman user. **Analisis saja — tidak ada cheat/mod yang dibangun, tidak ada bypass yang dilakukan.**

## 1. Identitas file

| Item | Nilai |
|---|---|
| Nama file di Drive | `Infinitode 2_R.1.9.2.apks` |
| Drive file ID | `1VMJupQAtCxyT4rWmvKsFEzunVRExuo3M` |
| Ukuran | 46.864.002 byte |
| MD5 (Drive) | `7a8baeb9a6fd980beaf4803c6ed0a4f5` — **identik** dengan hasil unduhan lokal (unduhan utuh) |
| SHA-256 | `1c5fb00b06e7474a863fd1fb57694fc49ab05a0f050c2b64f78c199a2e862f99` |
| Isi APKS | 4 split: `base.apk` (89.336.122 B) + `split_config.arm64_v8a.apk` (2.217.072 B) + `split_config.in.apk` (41.369 B, bahasa Indonesia) + `split_config.xxhdpi.apk` (263.402 B, densitas) |
| Game | **Infinitode 2** — tower defense oleh **Prineside** |
| Package | `com.prineside.tdi2` |
| Versi | versionName `R.1.9.2`, versionCode `1314`; minSdk 23, targetSdk 35, compileSdk 35 |
| Activity utama | `com.prineside.tdi2.AndroidLauncher` |
| Izin relevan | INTERNET, `com.android.vending.BILLING`, AD_ID + AdServices, WAKE_LOCK, VIBRATE, POST_NOTIFICATIONS |

### Keaslian / penandatangan — ORIGINAL, bukan modifan
Keempat split ditandatangani sertifikat yang sama persis:

- Subject/Issuer: `C=UA, ST=Kievska, L=Kiev, O=Prineside, OU=Developer, CN=Vadym Sakhno` (self-signed developer Prineside)
- Serial `0x1B6DF1EF`, berlaku 24 Jun 2016 – 18 Jun 2041
- SHA-256 sertifikat: `2C:3A:86:44:35:DD:39:EF:20:5D:E9:9B:83:8F:1F:2F:9C:2B:00:3F:17:5A:B6:29:45:80:C1:4D:04:0F:E7:DE`
- Nama blok tanda tangan `META-INF/BNDLTOOL.RSA` + file `stamp-cert-sha256` di base → pola standar distribusi Google Play yang digenerate bundletool dari AAB.

**Kesimpulan keaslian: rilis Play Store resmi Prineside, tidak di-re-sign pihak ketiga, tidak ada tambalan mod di dalam file ini.**

## 2. Hasil dump (ekstraksi penuh)

Lokasi: `~/workspace/rea-drive-20261022b/` — `apks_out/` (4 APK split), `extracted/base|arm64|in|xxhdpi/` (semua isi diekstrak), `analysis/` (dump strings dex game + daftar kelas).

- base.apk: **2.299 file**, 103.804.423 byte tidak terkompres.
- **12 DEX**: classes.dex … classes11.dex di base + `assets/audience_network.dex` (Facebook Audience Network, dimuat runtime).
- **Semua .so: 10 file, hanya ABI `arm64-v8a`** (dari split arm64; tidak ada armeabi-v7a/x86 — bundle ini 64-bit only). base.apk tidak memuat .so sama sekali.
- Aset game (plaintext): 88 peta level (`assets/levels/maps`), 80 skrip Lua (`assets/scripts/**`), konfigurasi JSON (`assets/res/*.json` — game-values, researches, tower-stats, basic-level-stages, daily-loot, trophies, achievements), resourcepack default, 52 mp3, shader GLSL.
- Sisa platform lain yang ikut terbawa (tidak aktif di Android): `assets/bin/steam_api64.dll` + `steamworks4j64.dll` (Steamworks desktop), `steam_appid.txt` berisi `937310`.

## 3. Engine & tempat logika game hidup

- **Engine: libGDX (Java)** — `libgdx.so` adalah backend native standar libGDX; tidak ada Unity/il2cpp (tidak ada `libil2cpp.so`/`global-metadata.dat`), tidak ada Unreal, tidak ada Cocos.
- **Logika game 100% di DEX (Java/Kotlin)**, terkonsentrasi di:
  - `classes9.dex` — inti game (4.199 referensi string `com/prineside/tdi2`), memuat `ProgressManager`, `ReplayManager`, `PurchaseManager`, `DailyQuestManager`, `LeaderBoardManager`, `PreferencesManager`, dll.
  - `classes8.dex` — game (lanjutan, 1.330 referensi) + `HeadlessReplayValidationGame`; sisanya InMobi/Mintegral/PGL ssdk.
  - `classes6.dex` — game (sebagian, 236 referensi) + Kotlin.
  - DEX lain = murni SDK: AndroidX/appcompat (classes.dex), AppLovin MAX mediation (classes4/5/10/11 — Chartboost, InMobi, Mintegral/mbridge, Bigo, Yandex, Vungle, Facebook, Pangle/ByteDance, TikTok events), protobuf (classes7), Firebase Analytics.
- Total **4.264 class descriptor** di bawah `com/prineside/tdi2` (managers, systems ECS, items, serializers, events, ui).
- Obfuskasi: **sebagian** — banyak nama method dimampatkan R8 menjadi satu huruf (a, b, c…), tetapi nama kelas dan sebagian besar API publik tetap terbaca (`addGreenPapers`, `calculateProgressHash`, `sendReplayToServer`, …). Aset JSON/Lua **plaintext penuh**.
- Serialisasi: **Kryo** (`com.esotericsoftware.kryo` + `com.prineside.kryo.FixedOutput`, `GameStateSerializer`, `kryo-registry.txt`) — fondasi desain simulasinya deterministik (state bisa diserialisasi & disimulasi ulang persis).
- **Modding resmi tersedia**: game memuat sistem mod Lua bawaan (`assets/mod_id_example.txt`, laman modding resmi Prineside, skrip Lua punya akses ke seluruh pohon kelas Java lewat LuaJ — dinyatakan eksplisit di komentar `assets/scripts/game/50_cmd.lua`).

## 4. Inventaris & karakterisasi SEMUA .so (arm64-v8a)

Semua: ELF 64-bit AArch64, section header utuh (tidak dimusnahkan), symtab ter-strip (hanya .dynsym — standar rilis), entropi normal (.text 6,56–6,89; tidak ada yang mendekati 8,00 → **tidak ada packer / kode terenkripsi** pada lapisan native), NEEDED hanya libc/libm/libdl/liblog (+libz, libandroid pada dua lib). **Tidak satu pun berisi logika game.**

| # | Lib | Ukuran (B) | Peran (bukti) | Exports .dynsym | Catatan |
|---|---|---|---|---|---|
| 1 | `libgdx.so` | 163.888 | Backend native **libGDX** stok — JNI `Java_com_badlogic_gdx_graphics_g2d_Gdx2DPixmap_*` dsb. | 116 | Satu-satunya lib engine; 13 imports; LLD 14. Bukan kode game. |
| 2 | `libapminsighta.so` | 102.256 | **ByteDance APM Insight** (monitoring crash/kinerja untuk iklan Pangle) | 1 (`JNI_OnLoad`) | Import `fork`, `execlp`, `dlopen`, `dlsym` = pola proses anak pelapor crash. |
| 3 | `libapminsightb.so` | 124.352 | APM Insight bagian B | 71 | Pasangan lib #2. |
| 4 | `libapplovin-native-crash-reporter.so` | 860.200 | **AppLovin MAX** native crash reporter — JNI `Java_com_applovin_impl_sdk_NativeCrashReporter_{enable,disable,updateAdInfo}` | 1.994 | Simbol C++ kaya (tidak di-strip berlebihan); murni SDK iklan. |
| 5 | `libbuffer_pgl.so` | 9.000 | Pangle **GeckoX** mmap buffer — JNI `com.bykv.vk.openvk…MMapBuffer` | 12 | Util preload aset iklan. |
| 6 | `libfile_lock_pgl.so` | 6.312 | Pangle GeckoX file lock — JNI `…utils.FileLock` | 6 | Util SDK iklan. |
| 7 | `libdatastore_shared_counter.so` | 7.112 | **AndroidX DataStore** shared counter — JNI `androidx.datastore.core.NativeSharedCounter` | 9 | Komponen Jetpack standar. |
| 8 | `libnms.so` | 296.712 | **Pangle ssdk** — pengumpul sinyal lingkungan/fingerprint perangkat untuk anti-fraud *iklan* (string `com.pgl.ssdk.ces.a`, banner `0.6.11.30.08 by CZL`) | 1 (`JNI_OnLoad`) | Import `__system_property_read`; tabel charset kustom = encoding payload telemetrinya sendiri. **Bukan anti-cheat game** dan tidak menyentuh state game. |
| 9 | `libpglarmor.so` | 68.600 | Kripto SDK Pangle — JNI `Java_com_bytedance_sdk_component_pglcrypt_PglCryptUtils_bc` | 1 | Enkripsi request iklan Pangle (+libz). |
| 10 | `libtt_ugen_layout.so` | 440.672 | Layout engine template iklan Pangle/TikTok **UGen** — Facebook Yoga JNI (`facebook::yoga`, `YGJNIVanilla::registerNatives`) | 708 | Rendering template iklan. |

**Tidak ditemukan** di seluruh paket: lib anti-cheat/anti-tamper komersial (tidak ada PairIP, Arxan/Promon, Tencent ACE, `libsecurity`/sejenis), tidak ada lib game buatan Prineside sendiri — seluruh lapisan native adalah engine stok + SDK iklan + AndroidX.

## 5. Permukaan jaringan (server Prineside)

Host milik game (di luar host SDK iklan/analytics umum):

- `https://infinitode.prineside.com/?m=api&a=<aksi>` — API utama (66 aksi terenumerasi dari strings, daftar kunci di bawah).
- `https://dev.prineside.com/tdi2_player_actions_analytics/?action=submit` — pengiriman analitik aksi pemain.
- `https://dev.prineside.com/timestamp` + aksi `getTimestamp` — waktu server (jangkar anti manipulasi jam lokal untuk fitur berbasis waktu).
- `https://storage.prineside.com/files/i2/avatars/` — avatar pemain.
- `https://tracker.prineside.com/set_project.php` — tracker analitik.
- `https://files.prineside.com/static/…` — berkas statis opsional.

Aksi API yang menentukan vonis (dari 66 total): `signIn/signUp/signInWithGoogle/signInOrUpWithSteam/signOut`, `saveGame`, `loadGame`, `loadGameById`, `getSavedGamesList`, `deleteGame`, `addProgressRestorePoint`, `getProgressRestorePoints`, `submitGameReplay`, `getReplay`, `getBestGameReplay`, `getReplayForValidationV2`, `submitReplayValidation`, `getLeaderboards`, `getLeaderboardsRank`, `getAdvanceLeaderboardsRank`, `getBasicLevelsTopLeaderboards`, `getRuntimeLeaderboards`, `getSkillPointLeaderboard`, `getDailyQuestInfo`, `getDailyQuestMap`, `getDailyQuestHash`, `getDailyQuestLeaderboards`, `validateIAP`, `receiveIssuedItems`, `applySecretCode`, `getDynamicSettings`, `getPlayerMessages`, `logGameStart`, `createPasteBin` (berbagi peta), `steamTxnStart/GetProducts/Finalize` (transaksi Steam — kode bersama desktop).

Transport di kode game: `NetworkManager` + `AuthManager.HttpQueuedRequest` (HTTP antre milik game sendiri, di atas stack libGDX/Java). Tidak ada WebSocket/soket real-time untuk gameplay.

## 6. Sistem simpanan (save)

- Lokal: direktori `saves/` — **`saves/progress.sav`** dan `saves/settings.sav` (path dari `PreferencesManager.getProgressPrefsFilePath()/getSettingsPrefsFilePath()`), plus `saved-game.bin` untuk run yang sedang berjalan dan direktori replay (`getReplaysDirPath()`).
- Format progres: peta preferensi diserialisasi dengan **Kryo**, dibungkus **Base64** (`PreferencesManager.fromBase64/fromBytes/progressPrefsToBase64/settingsPrefsToBase64/getPrefMapForProgressSaveFile`).
- **Enkripsi save lokal: tidak ditemukan bukti AES/Cipher di kelas-kelas game** yang disurvei (referensi `javax/crypto` di paket berasal dari SDK — IronSource/ExoPlayer/TLS). Yang ada hanya hash konsistensi lokal non-kriptografis (lihat §8).
- Cloud: progres yang sama diunggah via `saveGame` saat masuk akun Prineside; server menyimpan **restore point** (`addProgressRestorePoint`/`getProgressRestorePoints`) — snapshot historis progres di sisi server. `IssuedItems` (item yang diterbitkan server: hadiah event/kode) dicatat terpisah di `issued-items-log.json` dan diterima via `receiveIssuedItems`.

## 7. Arsitektur ekonomi & progres — LOKAL dulu, server mengawasi yang terlihat publik

Inti ekonomi hidup **lokal** di `ProgressManager` (classes9.dex; 128 method). Bukti method: `addGreenPapers/removeGreenPapers`, `addAccelerators/removeAccelerators`, `addResources/setResources`, `setMoney`, `addItems/removeItems/sellItems`, `openPack`, `generateNewShopOffers`, `generateNewLuckyWheel`, `startCrafting`, `hasPermanentDoubleGain`, `enableDoubleGainPermanently/Temporary`, `isPremiumStatusActive`, `addIssuedPrizes`. Mata uang: Green Papers (soft, hasil main), **Accelerators (premium — bisa dibeli IAP, juga didapat dari loot)**, resource penambangan (ResourceType), item/inventory (ItemManager, `configs/InventoryItemCountLimits`).

Lapisan server di atasnya:

- **IAP divalidasi server**: aksi `validateIAP`; string kegagalan di kode: "failed to send IAP for validation", "failed to load validated transactions". Pembelian tidak bisa dipalsukan dari klien.
- **Hasil run yang masuk papan peringkat wajib berupa replay** dan divalidasi ulang (§8). Skor telanjang tidak diterima begitu saja.
- **Daily quest**: peta diunduh dari server dan diverifikasi hash MD5-nya (`DailyQuestManager.getDailyQuestHashFromServer`, `removeLoadedDailyQuestMapIfMd5HashDiffers`, aksi `getDailyQuestHash`).
- **Progres akun tersinkron ke cloud** + restore point server (§6) — progres hasil utak-atik yang disinkronkan berisiko terlihat/tertimpa dari snapshot server.
- GPGS (Play Games) hadir untuk achievement/auth pelengkap (`AchievementsClient`, `Games`), bukan otoritas ekonomi.

**Multiplayer: TIDAK ADA real-time.** Seluruh fitur online bersifat asinkron: akun + cloud save, leaderboard (berbasis replay), daily quest, berbagi peta buatan pemain (PasteBin), pesan pemain, kirim/voting musik. Inti permainan **single-player dan berjalan lokal**; tidak ada gating login paksa yang terlihat di kode (akun bersifat opsional — penilaian struktur kode; konfirmasi final perilaku offline penuh butuh runtime).

## 8. Anti-cheat / anti-tamper — arsitektural, bukan pelindung biner

- **Play Integrity / SafetyNet: TIDAK ADA** — 0 referensi di seluruh 11 DEX.
- **Anti-tamper native / packer / pemeriksaan tanda tangan diri di kode game: tidak ditemukan** (referensi `getPackageInfo` bersifat generik milik SDK; tidak ada lib pelindung, section ELF utuh, entropi normal).
- **Deteksi root**: string jalur `su` (`/sbin/su`, `/data/local/su`, …) dan `isRooted` ada, tetapi milik **SDK iklan** (telemetri MRAID/SDK), bukan logika game.
- Pertahanan sebenarnya = **desain deterministik + validasi replay**:
  - Simulasi game deterministik berbasis Kryo (`GameStateSerializer`, seed `RandomXS128` terserialisasi). Setiap run direkam sebagai replay oleh `ReplayManager` (`saveReplay`, `sendReplayToServer`, `sendUnsentReplaysToTheServer`) dan dikirim via `submitGameReplay`.
  - Replay dapat **disimulasi ulang tanpa UI** oleh `HeadlessReplayValidationGame.headlessValidateGame` (classes8.dex; string log: "headlessValidateGame - parsing failed"). Server mendistribusikan replay untuk divalidasi (aksi `getReplayForValidationV2` → `submitReplayValidation`) — sistem validasi terdistribusi: hasil yang tidak bisa direproduksi simulasi stok akan menyimpang dan tertolak untuk keperluan peringkat.
  - `ProgressManager.calculateProgressHash()` — hash polinomial bergulir (×31) atas jumlah accelerators + green papers + resource. **Lemah dan mudah dihitung ulang** (bukan kriptografi); fungsinya penanda konsistensi murah yang ikut terkirim, bukan pengaman utama.
  - Jangkar waktu server (`getTimestamp`) + hash MD5 peta daily quest + validasi IAP server (§7).

## 9. Tabel vonis cheat per fitur (klasifikasi server-vs-lokal)

| Fitur | Vonis | Bukti / alasan |
|---|---|---|
| Uang dalam run (koin awal, STARTING_MONEY=200) | **BISA PENUH (lokal)** | Nilai konfigurasi plaintext `assets/res/game-values.json`; simulasi run berjalan lokal. |
| Nyawa markas / god mode (STARTING_HEALTH=20, DamageSystem lokal) | **BISA PENUH (lokal)** — untuk peringkat: **TIDAK** | Simulasi lokal deterministik; tetapi run yang disubmit ke leaderboard divalidasi ulang dari replay-nya, hasil mustahil menyimpang dari simulasi stok. |
| Damage / statistik tower | **BISA PENUH (lokal)** — untuk peringkat: **TIDAK** | `assets/res/tower-stats.json` plaintext + `TowerStatManager` lokal; alasan peringkat sama seperti di atas. |
| Speed permainan | **BISA PENUH (lokal)** | Simulasi lokal; game sendiri menyediakan pengali kecepatan. Replay peringkat tetap harus konsisten. |
| Green Papers (soft currency) | **BISA PENUH (lokal/offline)** | State lokal `ProgressManager.addGreenPapers`, tersimpan di `progress.sav` lokal. Peringatan: progres tersinkron cloud + restore point server bila akun masuk. |
| Resource & item / spawn item ke inventory | **BISA PENUH (lokal/offline)** | `ProgressManager.addResources/addItems`, `ItemManager` lokal. Item **terbitan server** (IssuedItems) adalah kanal terpisah — tidak bisa diterbitkan dari klien. |
| Unlock riset / level / trofi | **BISA PENUH (lokal/offline)** | `ResearchManager`/`ProgressManager` lokal; caveat sinkronisasi cloud sama seperti Green Papers. |
| Accelerators (mata uang premium) | **BISA SEBAGIAN** | Saldo adalah field lokal (`addAccelerators`) sehingga angka lokal bisa berubah, **tetapi** pembelian wajib `validateIAP` server, dan saldo ikut progres yang disinkronkan/dibandingkan server (restore point). Bukan kanal bersih; mengarang pembelian = TIDAK. |
| Pembelian IAP / Double Gain permanen / status premium berbayar | **TIDAK (server)** | `validateIAP` memvalidasi struk di server; `steamTxn*` untuk jalur Steam. Klien hanya mengirim bukti beli asli. |
| Skor leaderboard / peringkat daily quest | **TIDAK (server, tervalidasi)** | `submitGameReplay` + validasi ulang headless terdistribusi V2 (`getReplayForValidationV2`, `submitReplayValidation`) + hash MD5 peta dari server (`getDailyQuestHash`). |
| Manipulasi cloud save / progres pemain lain | **TIDAK (server)** | `saveGame/loadGame` terikat sesi akun terautentikasi (`AuthManager`); server memegang restore point historis. |
| Item terbitan server (IssuedItems) | **TIDAK (server)** | Diterbitkan server, diterima via `receiveIssuedItems`, dicatat di `issued-items-log.json`. |
| Mod gameplay lokal (tower/map/skrip kustom) | **BISA PENUH — lewat jalur RESMI** | Sistem mod Lua bawaan dengan akses pohon kelas penuh + editor peta + berbagi peta (`UserMapManager`, `createPasteBin`). Tidak perlu bypass apa pun. |

Catatan kejujuran vonis: "BISA PENUH (lokal)" berarti state & simulasi terbukti lokal dari file. Apakah server menolak progres hasil editan saat sinkronisasi berikutnya **tidak dapat dibuktikan statis** (tidak ada bukti pemeriksaan hash progres menyeluruh di sisi server selain restore point & validasi replay untuk hasil peringkat) — ditandai sebagai risiko, bukan kepastian.

## 10. Saran cheat/mod yang realistis (sesuai batas: lokal/offline saja)

1. **Jalur resmi dulu — mod Lua bawaan.** Game ini memang dirancang bisa dimod: skrip Lua punya akses ke seluruh kelas Java. Untuk eksperimen gameplay lokal (stat tower, aturan gelombang, peta kustom), ini jalur paling bersih dan tidak menyentuh APK sama sekali.
2. **Edit save lokal `saves/progress.sav`** (Kryo + Base64, tanpa enkripsi yang ditemukan) untuk sumber daya/inventory/unlock pada permainan **offline tanpa akun tersinkron** — formatnya terdokumentasi oleh struktur `PreferencesManager` + serializer Kryo di dalam file ini sendiri. `calculateProgressHash` adalah hash polinomial sederhana (terbukti dari disassembly) sehingga konsistensi lokalnya dapat dihitung ulang.
3. **Patch DEX untuk mode offline** (ProgressManager/systems) secara teknis mudah karena logika terkonsentrasi di classes9.dex dan obfuskasi hanya parsial — konsekuensi wajib disampaikan: APK hasil re-sign kehilangan tanda tangan Prineside (putus update Play & fitur akun/GPGS), maka jalur ini hanya masuk akal untuk instalasi offline murni.
4. **Jangan sentuh** (server, akan tertolak/terdeteksi oleh desainnya sendiri): pemalsuan pembelian IAP, injeksi skor leaderboard/daily quest (replay divalidasi ulang), penerbitan item server, dan utak-atik cloud save. Di titik itu mod berhenti menjadi "cheat lokal" dan menjadi pemalsuan ke server — di luar batas yang digarap.

## 11. Belum terkonfirmasi (butuh runtime)

- Apakah progres lokal yang telah diubah ditolak/ditimpa server saat `saveGame` berikutnya (statis hanya membuktikan adanya restore point & sinkronisasi, bukan kebijakan penolakannya).
- Apakah validasi replay V2 dijalankan server sendiri atau mayoritas oleh klien lain (peer) — endpoint membuktikan mekanismenya ada dan aktif didesain, bukan siapa eksekutor dominannya.
- Perilaku offline penuh tanpa akun (tidak ada gating terlihat di kode; uji perangkat yang memastikan).
- Apakah flag Double Gain/premium di progres lokal diverifikasi ulang ke server saat mulai (string kegagalan validasi IAP menunjukkan verifikasi terjadi pada transaksi; verifikasi ulang berkala tidak terbukti statis).
- Langkah kompresi persis di dalam pembungkus save (Kryo terkonfirmasi; detail kompresi per segmen tidak dibedah sampai level instruksi).
