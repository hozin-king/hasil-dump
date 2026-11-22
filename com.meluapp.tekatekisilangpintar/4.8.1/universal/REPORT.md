# REA + Dump — TTS Pintar — Teka Teki Silang (`com.meluapp.tekatekisilangpintar`) v4.8.1 / code 189

Tanggal: 12 Nov 2026. Analisis statik saja, tanpa runtime, tanpa build/mod.

## 0. Vonis singkat

**File ASLI — build resmi Google Play, bukan repack/mod.** Bukti: apksigner lolos di base APK + ketiga split; signer = sertifikat Google Play App Signing (`CN=Android, OU=Android, O=Google Inc.`, RSA 4096); stamp Play di manifest (`com.android.stamp.source = https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK`); apksigner `Verified for SourceStamp: true`; semua split memakai signer yang sama; tidak ada jejak repack (tidak ada sertifikat debug/self-signed, tidak ada tambahan file asing).

**Aplikasinya: TTS Pintar — game teka-teki silang (TTS) berbahasa Indonesia, native Android (Kotlin/Java), bukan Unity.** Mode: TTS (crossword), Tebak Kata, Kuis, Word Connect, Word Search, Word Chain. Ekonomi sepenuhnya berbasis koin in-game — **tidak ada In-App Purchase** (tidak ada BillingClient dipakai kode aplikasi, tidak ada SKU ditemukan). Koin, hint, nyawa, dan unlock level semuanya **LOKAL (SQLite)**; yang server-gated hanya cloud save (Play Games Snapshots), ranking/Play Games, verifikasi lisensi (PairIP), dan iklan reward. Satu-satunya proteksi nyata adalah **PairIP** (verifikasi lisensi Play) + obfuscation R8 — tidak ada deteksi root, tidak ada SSL pinning, tidak ada anti-tamper lain.

## 1. Perolehan

- Tautan user: `[tautan unduhan dihapus — minta ke Alyaa]`
- Jalur: tautan langsung **berhasil** (HTTP 200, 17.540.420 byte, CDN `data.winudf.com`, URL bertanda tangan — token tidak disimpan/dikutip di laporan ini). Tidak perlu jalur API.
- Konsistensi ukuran: `manifest.json` di dalam XAPK mencatat `total_size = 17.538.553` = jumlah keempat APK di dalamnya (15.970.947 + 61.849 + 87.920 + 1.417.837); file XAPK yang diunduh 17.540.420 byte (selisih = overhead zip + manifest.json) — konsisten, unduhan lengkap.
- Cross-check metadata API APKPure (SHA-1 dari `api_response.bin`): **tidak dilakukan** — tidak ada helper API yang tersedia di VM ini, dan verifikasi tanda tangan (apksigner + Play App Signing + source stamp) sudah menjadi bukti otentisitas yang lebih kuat daripada metadata API.

## 2. Identitas & verifikasi

| Item | Nilai |
|---|---|
| File | `tekateki.xapk` |
| Ukuran XAPK | 17.540.420 byte |
| SHA-256 XAPK | `8c759f6835b3411212a484879fd3491b6e265aef19e050b0119470e4670b2c0c` |
| SHA-1 XAPK | `0605fc96a06ee78433286d5f8d899431f0f0601b` |
| Package | `com.meluapp.tekatekisilangpintar` |
| versionName / versionCode | 4.8.1 / 189 |
| minSdk / targetSdk / compileSdk | 24 / 35 / 35 (Android 15) |
| Label aplikasi | TTS Pintar™ (short: TTS Pintar) |
| Launcher activity | `com.meluapp.tekatekisilangpintar.MainActivity` (portrait, singleTop) |
| Isi XAPK (5 entri) | base APK 15.970.947 B + `config.arm64_v8a.apk` 1.417.837 B + `config.en.apk` 61.849 B + `config.xhdpi.apk` 87.920 B + `manifest.json` 1.134 B (xapk_version 2). **Tidak ada OBB.** |
| Base APK SHA-256 | `2147a0ce54477f52697d4544851b18687fdf4b04b0138808712f35dafccddf0f` |
| Base APK SHA-1 | `f28537f1b02bcb678edd9048beb844ab41ef209f` |
| apksigner | **Verifies** (base + ketiga split, exit 0); `Verified for SourceStamp: true` |
| Signer DN | `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US` |
| Signer SHA-256 | `ba6be7049f34bf714c2c5f2cfacebe44a6a350ffa394397bc0d41cedcc840fda` |
| Signer SHA-1 / MD5 | `7c2837cf04aa1f37522b110ca5bdfe2b9f54f0a9` / `34e5a49a7d7e4791f54e4ed6f3b3346e` |
| Kunci signer | RSA 4096 — sertifikat Play App Signing Google |
| Source stamp | `com.android.stamp.source = https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK`, `com.android.vending.splits.required = true` |
| Developer | Meluapp (meluapp.com, ttspintar.id, facebook.com/ttspintar; ada versi iOS di App Store) |

## 3. Ringkasan aplikasi

Game TTS (teka-teki silang) Indonesia, gratis + iklan, tanpa IAP. Dari manifest + strings + aktivitas:

- **Mode permainan** (aktivitas): TTS (crossword), Tebak Kata (`GuessGameActivity`), Kuis (`QuizActivity`), Word Connect (`WordConnectActivity`), Word Search (`WordSearchActivity`), Word Chain (`WordChainActivity`), plus halaman Kunci Jawaban (`TTSKeyActivity`), Rank (`RankActivity`), Ijazah/diploma (`IjazahActivity`), tema/paket/level (`GameThemeActivity`, `GamePackActivity`, `GameLevelActivity`), Cloud Save (`CloudSaveActivity`), FAQ, Toko (`StoreActivity`).
- **Level**: berurutan dan harus dibuka satu per satu ("Selesaikan level sebelumnya untuk membuka level ini"); paket level harus dibuka berurutan ("Selesaikan paket level sebelumnya untuk membuka paket level ini"); jumlah level **terbatas** — FAQ: "Maaf ya, untuk saat ini levelnya sudah habis… Tunggu update selanjutnya yah" dan "level %1$d dan seterusnya akan ditambah saat ada update". Konten level **dibuat sendiri oleh developer** — FAQ: "Level TTS ini dibuat sendiri, dilindungi oleh hukum dan tidak boleh digandakan".
- **Sumber kata & definisi** (dari string FAQ/about): KBBI (Kemendikdasmen), WordNet (Princeton University), Open English WordNet (CC BY 4.0), Wikipedia & Wiktionary (CC BY-SA 4.0). Lisensi WordNet 3.0/3.1 ikut dibundel di `assets/licenses/`.
- **Ekonomi koin** (detail di §7): koin didapat dari menang level (+25), bonus harian, dan iklan reward (+25); dipakai untuk membuka level TTS UMUM dan "membuka semua Level TTS". Toko (`StoreActivity`) menukar koin ("TUKAR KOIN") — bukan uang asli.
- **Hint ("bantuan")**: per level, 1 hint mengisi 1 kotak dengan huruf benar, maks 1 kali per soal; bonus hint lewat iklan reward; hint bonus **tidak tersimpan** bila meninggalkan halaman ("Gunakan semua bonusnya sebelum kamu meninggalkan halaman ini yah, takutnya hilang ngga ke-save").
- **Nyawa**: bisa didapat lagi dengan menonton iklan sampai selesai ("nyawa lagi jika menonton iklan (sampai selesai, jangan di skip)").
- **Iklan**: mediasi berat — AdMob (app ID `ca-app-pub-4261802186339848~9379774222`), AppLovin MAX, Unity Ads, ironSource LevelPlay, InMobi, Vungle, Mintegral, Fyber/Inneractive. Iklan reward memberi koin / hint / nyawa.
- **Cloud save & sosial**: Google Play Games (Snapshots untuk cloud save; rank/achievements) + Firebase (Analytics + Realtime Database terkonfigurasi, lihat §6).

## 4. Struktur & dump

### 4.1 Teknologi

- **Native Android Kotlin/Java, bukan Unity.** Tidak ada `libunity.so` / `libil2cpp.so` / `libmain.so`; tidak ada folder `lib/` di base APK (native lib hanya di split `config.arm64_v8a.apk`).
- **4 file DEX** (total ±32 MB): `classes.dex` 8.566.720 B, `classes2.dex` 7.886.336 B, `classes3.dex` 10.929.072 B (kode aplikasi + sebagian SDK), `classes4.dex` 4.585.648 B (sebagian besar Unity Ads). 385 kelas di paket `com.meluapp.tekatekisilangpintar`.
- **Obfuscation R8**: kelas/metode aplikasi memakai nama satu huruf (`a`, `b`, … `z`, `a0`, `a1`, …) — nama aktivitas dan nama kelas publik dipertahankan, isi sudah di-obfuscate.
- **Room** hadir (`androidx.room.MultiInstanceInvalidationService`) — dipakai library; database aplikasi sendiri memakai `SQLiteOpenHelper` mentah (lihat §6).
- **Jetpack**: DataStore (`libdatastore_shared_counter.so`), WorkManager, Startup, Lifecycle, Emoji2, ProfileInstaller.
- **Jaringan**: OkHttp (okhttp3) + Retrofit-style; Picasso untuk gambar.

### 4.2 Native lib (split `config.arm64_v8a.apk` — hanya 3 file, semua AArch64, stripped)

| Lib | Ukuran | Keterangan |
|---|---|---|
| `libapplovin-native-crash-reporter.so` | 843.152 B | Crash reporter native milik AppLovin (2138 simbol dinamis). Bukan kode game. |
| `libdatastore_shared_counter.so` | 7.112 B | Jetpack DataStore shared counter (19 simbol dinamis). |
| `libunitycoherencenative.so` | 514.424 B | Unity **Coherence** bridge (`Java_com_unity3d_coherence_CoherenceBridge_*`) — dipakai internal oleh Unity Ads SDK. Bukan engine game; tidak ada lib Unity lain. |

Tidak ada lib game sendiri — seluruh logika game ada di DEX (Kotlin/Java).

### 4.3 Isi APK

- Base APK: 1.379 entri — `res/` 1.193, `assets/` 34, `kotlin/` 8, `META-INF/` 86, 4 dex. Aset hampir semuanya file SDK iklan (template AppLovin MAX / ironSource / Mintegral, OM SDK) + font `sniglet.ttf` + suara (`correct.mp3`, `wrong.mp3`, `winner_yay_v2.mp3`, `duplicate.mp3`) + `emojis.json` (266.453 B).
- **Tidak ada file data level** di `assets/` maupun `res/raw/` — konten level (kata + definisi) terkompilasi di DEX sebagai konstanta string (ratusan definisi Indonesia ditemukan di `classes3.dex`, mis. definisi dari KBBI/WordNet).
- `res/xml/network_security_config.xml`: hanya `cleartextTrafficPermitted=true` untuk `127.0.0.1` — tidak ada pinning di sini.
- `res/values/strings.xml`: 386 string (UI Indonesia).

## 5. Proteksi

| Proteksi | Status | Bukti |
|---|---|---|
| **PairIP (verifikasi lisensi Play)** | **ADA — proteksi utama** | Application class = `com.pairip.application.Application`; `com.pairip.licensecheck.LicenseClient`, `TrialClient`, `LicenseActivity`, `LicenseResponseHelper`, `RepeatedCheckMetadata`, `LicenseContentProvider` (38 referensi di `classes1.dex`); permission `com.android.vending.CHECK_LICENSE`; `com.pairip.licensecheck.LicenseActivity` di manifest. Lisensi dicek berulang (repeated checks). |
| Play source stamp | Ada | `com.android.stamp.source = https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK`, apksigner `Verified for SourceStamp: true`. |
| Obfuscation | Ada (R8) | Kelas/metode aplikasi satu huruf (`a`–`z`, `a0`–`a1`…); 385 kelas di paket aplikasi. |
| Deteksi root / Magisk | **TIDAK ADA di kode aplikasi** | String `/cache/magisk.log`, `/data/adb/magisk`, `/sbin/.magisk`, `/system/bin/su`, `/system/xbin/su`, `test-keys` hanya ada di `com.inmobi.media.core.config.models.SignalsConfig$FraudSignals` — **fraud signal SDK iklan InMobi**, bukan proteksi aplikasi. |
| Deteksi Xposed / Frida | **TIDAK ADA** | Referensi `de.robv.android.xposed.XposedBridge` / `XC_MethodHook` hanya di Unity Ads ad-player JS bridge (bukan deteksi framework Xposed). Tidak ada string Frida. |
| SSL pinning | **TIDAK ADA** | NSC tanpa pin; tidak ada literal pin `sha256/` di DEX; string `CertificatePinner` yang ada hanya internal OkHttp (nama field + pesan error library), bukan pemakaian oleh aplikasi. |
| Anti-tamper lain | **TIDAK ADA** | Tidak ada cek integritas dex/signature di kode aplikasi selain PairIP + tanda tangan Play. |
| Deteksi emulator | **TIDAK ADA** | Tidak ditemukan string/pola deteksi emulator di kode aplikasi. |

## 6. Penyimpanan data

### 6.1 Lokal — SQLite (otoritas utama progres & ekonomi)

Helper: `com.meluapp.tekatekisilangpintar.Basic` extends `SQLiteOpenHelper` (`getReadableDatabase` / `getWritableDatabase`). Nama file DB **tidak berhasil dipulihkan secara statik** (tidak ditemukan literal nama file di sekitar konstruktor). Skema terbukti dari literal SQL di DEX:

| Tabel | Kolom (terbukti) | Isi |
|---|---|---|
| `tts` | `tts_level`, `tts_type`, `unlocked`, `saved` | Status tiap level TTS (`tts_type='GENERAL'` dkk.). Bukti: `SELECT unlocked FROM tts WHERE tts_type='…'`, `update tts set unlocked=1 where tts_level=…`, `update tts set saved=1 where tts_level=…`, `insert into tts(tts_level,unlocked) values…`, `UPDATE tts SET unlocked=1 WHERE tts_level<=4 / <=10 / >=…` |
| `stats` | `user_id`, `coins`, `lifetime_coins`, `last_daily_bonus_time` | Saldo koin + bonus harian. Bukti: `SELECT coins FROM stats`, `UPDATE stats SET coins = coins + …`, `UPDATE stats SET lifetime_coins = coins`, `SELECT last_daily_bonus_time FROM stats`, `UPDATE stats SET last_daily_bonus_time = ?`, `INSERT INTO stats(user_id,coins) VALUES(…)` |
| `settings` | `theme` | Tema tampilan. Bukti: `insert into settings(theme) values('red')`; nama tema di `Basic`: ARMY, BLUE, BLUE_DUSK, CARAMEL, CHERRY, CHESTNUT_ROSE, CHOCOLATE, DARK_BLACK, … |
| `level` | `type`, `theme`, `number` | Progres mode lain. Bukti: `INSERT INTO level(type,theme,number) VALUES …`, `UPDATE level SET unlocked=1 WHERE id=…` |
| `count` | `next_count` | Counter internal. Bukti: `insert into count(next_count) values (0)` |

Konten level (kata + definisi soal) **bukan** di database — terkompilasi di DEX sebagai konstanta string; database hanya menyimpan *status* (terbuka/tersimpan) dan *statistik*.

### 6.2 Lokal — SharedPreferences

Dipakai antara lain oleh `CloudSaveActivity` (`getSharedPreferences` + `getLong`/`putLong` — kemungkinan timestamp sinkronisasi terakhir). Kunci spesifik tidak dipulihkan (nama file tidak terlihat di sekitar pemakaian).

### 6.3 Server — Cloud save & Play Games

- **Cloud save = Google Play Games Saved Games (Snapshots API)** — `CloudSaveActivity` memakai `com.google.android.gms.games.SnapshotsClient` / `Snapshot` / `DataOrConflict` secara langsung. Bukan Firebase RTDB.
- **Play Games**: `com.google.android.gms.games.APP_ID` (`@string/app_id`), `PlayGamesInitProvider`, scope `auth/games` + `auth/games_lite` + `auth/drive.appdata` (dipakai Saved Games). Rank/achievements (`RankActivity`, `IjazahActivity`) = server Google.
- **Firebase**: `FirebaseInitProvider`, `FirebaseDatabaseKtxRegistrar`, `DatabaseRegistrar`, Analytics, Installations; `firebase_database_url`, `google_api_key`, `project_id`, `gcm_defaultSenderId` ada di `values.xml` (nilai **tidak dikutip** di laporan ini). **Catatan**: tidak ditemukan pemakaian `FirebaseDatabase`/`DatabaseReference` oleh kode aplikasi di `classes3.dex` — kemungkinan Firebase dipakai untuk Analytics (event `FIREBASE EVENT COINS` tercatat) dan/atau konfigurasi, bukan sebagai otoritas data game. Pemakaian RTDB aktual **belum terverifikasi statik**.

### 6.4 Server — Iklan

Rewarded ads (koin/hint/nyawa) dilayani jaringan iklan (AdMob/AppLovin/Unity/dll.) — butuh internet + ketersediaan iklan. Event koin juga dicatat ke Firebase Analytics (server-side logging, bukan otoritas saldo).

## 7. Klasifikasi per fitur — LOKAL vs SERVER-GATED

| Fitur | Vonis | Bukti |
|---|---|---|
| **Koin** | **LOKAL** | `stats.coins` di SQLite; `UPDATE stats SET coins = coins + …`; didapat dari menang level (+25), bonus harian (`last_daily_bonus_time`), iklan reward (+25). Tidak ada validasi server atas saldo. |
| **Hint / bantuan** | **LOKAL** | Hitungan per level di sisi aplikasi; 1 hint = isi 1 kotak huruf benar; maks 1× per soal; bonus via iklan reward; bersifat sesi (hilang bila keluar halaman). Tidak ada endpoint hint. |
| **Nyawa** | **LOKAL** | Didapat lagi dengan menonton iklan sampai selesai. Tidak ada validasi server. |
| **Unlock level / paket level** | **LOKAL** | `tts.unlocked` di SQLite (`update tts set unlocked=1 …`); syarat buka = selesaikan level/paket sebelumnya; "buka semua level" dibeli dengan koin (`Koin untuk membuka semua Level TTS ?`). |
| **Tema / pengaturan** | **LOKAL** | Tabel `settings(theme)` di SQLite. |
| **Konten level (kata + soal)** | **LOKAL** | Terkompilasi di DEX; level baru hanya datang lewat update aplikasi (FAQ). |
| **Cloud save** | **SERVER-GATED** | Play Games Snapshots API (`SnapshotsClient`) — butuh akun Google + Play Games. |
| **Rank / Ijazah / achievements** | **SERVER-GATED** | Play Games (leaderboards/achievements). |
| **Verifikasi lisensi (PairIP)** | **SERVER-GATED** | `LicenseClient` + repeated checks ke Play; aplikasi harus terpasang dari Play dengan lisensi valid. |
| **Iklan reward (koin/hint/nyawa)** | **SERVER-GATED** | Butuh jaringan iklan + internet; stok iklan bisa habis (`MAAF STOK IKLAN SEDANG HABIS`). |
| **Hapus iklan / Premium / langganan** | **TIDAK ADA** | Tidak ditemukan produk hapus-iklan/premium/langganan. Lihat §8. |
| **In-App Purchase (apa pun)** | **TIDAK ADA** | Tidak ada pemakaian BillingClient oleh kode aplikasi (hanya SDK InMobi + Unity Ads yang memakai BillingClient untuk sinyal pembelian iklan); tidak ada SKU/product ID ditemukan; `StoreActivity` hanya menukar koin in-game (`TUKAR KOIN`, `BUY` = tukar koin). |

## 8. Apa yang secara prinsip bisa di-mod (lokal) vs tidak bisa (server)

> Analisis saja — **tidak ada mod/injector yang dibangun** dalam REA ini, dan tidak ada fitur yang diklaim berfungsi tanpa bukti runtime.

**Secara prinsip bisa (semua otoritas lokal):** koin (`stats.coins`), hint, nyawa, unlock level/paket (`tts.unlocked`), tema — semuanya tersimpan di SQLite/SharedPreferences lokal tanpa validasi server yang ditemukan secara statik.

**Peringatan penting — gerbang PairIP:** mengubah APK lalu menandatangani ulang dengan kunci berbeda akan **merusak tanda tangan Play** yang diverifikasi PairIP (`LicenseClient` + repeated checks + `CHECK_LICENSE`). Aplikasi yang dimodifikasi dan di-re-sign **kemungkinan besar gagal verifikasi lisensi** dan menolak berjalan — PairIP adalah satu-satunya gerbang yang berdiri antara ekonomi lokal ini dan modifikasi APK. Menembus/menonaktifkan verifikasi lisensi adalah bypass proteksi dan **tidak dikerjakan** dalam analisis ini.

**Tidak bisa (server-gated):** cloud save (Play Games Snapshots), rank/achievements Play Games, status lisensi PairIP, dan reward iklan (butuh jaringan iklan + internet). Mengubah nilai lokal tidak mengubah apa pun di server.

## 9. Catatan & batas analisis

- Analisis **statik saja** (tanpa install, tanpa runtime, tanpa traffic capture). Vonis LOKAL vs SERVER didasarkan pada bukti kode (SQL, pemakaian API, manifest) — perilaku runtime (mis. apakah ada validasi server tersembunyi saat sinkronisasi) **belum terverifikasi**.
- Jumlah level persis **tidak berhasil dipulihkan secara statik** (konten level tersebar sebagai konstanta string di DEX yang ter-obfuscate; FAQ mengonfirmasi level terbatas dan ditambah lewat update).
- Nama file database SQLite **tidak berhasil dipulihkan secara statik**.
- Pemakaian Firebase Realtime Database aktual **tidak terkonfirmasi** (terkonfigurasi, tapi tidak ada pemakaian langsung oleh kode aplikasi yang ditemukan).
- Tidak ada kredensial/secret yang dikutip di laporan ini (kunci API Firebase, AdMob app ID hanya dicatat sebagai identifier publik dari manifest).

## 10. Daftar file dump

```
~/workspace/rea-tekateki-silang/
├── REPORT.md
├── tekateki.xapk                      # XAPK unduhan (17.540.420 B)
└── dump/
    ├── AndroidManifest.xml            # manifest ter-decode (apktool)
    ├── apksigner_verify.txt           # hasil apksigner verify --print-certs
    ├── xapk_manifest.json             # manifest.json dari XAPK
    ├── strings_values.xml             # res/values/strings.xml
    ├── readelf_libapplovin-native-crash-reporter.txt
    ├── readelf_libdatastore_shared_counter.txt
    ├── readelf_libunitycoherencenative.txt
    ├── nm_dyn_libapplovin-native-crash-reporter.txt
    ├── nm_dyn_libdatastore_shared_counter.txt
    ├── nm_dyn_libunitycoherencenative.txt
    ├── strings_libapplovin-native-crash-reporter.txt
    ├── strings_libdatastore_shared_counter.txt
    ├── strings_libunitycoherencenative.txt
    ├── strings/
    │   ├── all.txt                    # gabungan strings 4 dex (216.538 baris)
    │   ├── classes1.txt / classes2.txt / classes3.txt / classes4.txt
    │   └── app_classes.txt            # 385 kelas paket com.meluapp.tekatekisilangpintar
    ├── apktool/                       # hasil apktool --no-src (manifest + res + dex)
    ├── split_arm64/                   # isi config.arm64_v8a.apk (3 .so)
    └── xapk_contents/                 # isi XAPK (base APK + 3 split + manifest.json)
```
