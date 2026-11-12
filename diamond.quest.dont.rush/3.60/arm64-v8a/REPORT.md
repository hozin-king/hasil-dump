# Laporan Dump + REA — "Diamond Quest_3.60.apks"

Tanggal analisis: 21 Oktober 2026
Sumber: Google Drive (file ID `1WFpYPifmfFO1xh66kXYkCaD3HKhlj88l`)
Metode: gdown → unzip split → REA `inspect-android-package` (JADX headless MCP) + JADX 1.5.1 + apktool 2.10.0 + analisis strings/ELF. Analisis native terbatas strings & simbol ekspor (VM ini tidak punya Ghidra/IDA). **Tidak ada cheat yang dibangun — analisis saja.**

> Catatan soal nama: user menyebut game ini "Defender". Di dalam file **tidak ditemukan** nama/mode "Defender"; identitas file adalah **Diamond Quest: Don't Rush!**. Yang paling dekat dengan kesan "defender" adalah stage objektif "DEFEAT ..." (melawan bos) — label persis "defender" **tidak terkonfirmasi**.

---

## 1. Identitas game

| Item | Nilai | Bukti |
|---|---|---|
| Nama file | `Diamond Quest_3.60.apks` | unduhan Drive |
| Ukuran | 78.447.435 byte (78,4 MB) | `ls` |
| SHA-256 (APKS) | `dcf56d9985246163d65a617b6a917ed67d0dc61aa8b70da199722a9b248f6859` | sha256sum |
| MD5 (APKS) | `579dcc9aa6940545894faeccbbc6cae9` | md5sum |
| Nama game | **Diamond Quest: Don't Rush!** | string App Store di kode: `apps.apple.com/us/app/diamond-quest-dont-rush/id1490427031`; URL Play Store di `f1/C0278a.java` |
| Package | `diamond.quest.dont.rush` | AndroidManifest (apktool) |
| Versi | versionName **3.60**, versionCode **200271** | apktool.yml |
| minSdk / targetSdk | 23 / 36 | apktool.yml |
| Engine | **libGDX** (Java) + Spine (animasi) | `libgdx.so`, `libgdx-freetype.so`, `liblibgdx-oboe.so`; import `com.esotericsoftware.spine` di kelas Game |
| Kelas utama | Application: `com.mygdx.game.AdjustApplication`; Launcher: `com.mygdx.game.DiamondQuestLauncher`; Game: `f1.a` (obfuscated, extends Game libGDX) | manifest + jadx classes6/classes4 |
| SHA-256 base.apk | `52d124849dd7fbe8f0274085d79f55bdadb1ac7560c71366b327d3d887005b37` | REA inspect |
| Tanda tangan | Sertifikat Play App Signing (Owner `CN=Android, O=Google Inc.`), bundle hasil bundletool (`BNDLTOOL.RSA`) | keytool / META-INF |
| Total dump | **771 MB** (downloads 75 MB, extracted 687 MB, analysis 9,2 MB) | `du` |

### Isi bundle (.apks)
| Split | Ukuran | Isi |
|---|---|---|
| `base.apk` | 107.680.607 byte | kode (9 file dex, ±38.716 kelas menurut REA), aset game 58 MB |
| `split_config.arm64_v8a.apk` | 8.492.742 byte | 18 native lib arm64-v8a (**satu-satunya ABI** di bundle) |
| `split_config.in.apk` | 45.465 byte | sumber daya bahasa Indonesia |
| `split_config.xxhdpi.apk` | 300.870 byte | sumber daya densitas xxhdpi (kebanyakan ikon SDK iklan) |

---

## 2. Inventaris native lib (semua arm64-v8a, di split ABI)

| Lib | Ukuran | Fungsi (bukti) |
|---|---|---|
| `libgdx.so` | 163.888 | Inti libGDX (`Java_com_badlogic_gdx_*`) |
| `libgdx-freetype.so` | 797.976 | Font FreeType libGDX |
| `liblibgdx-oboe.so` | 2.895.672 | Audio Oboe untuk libGDX (paket `barsoosayque.libgdxoboe`) |
| `libsigner.so` | 1.366.632 | **Adjust SDK** — `Java_com_adjust_sdk_sig_NativeLibHelper_nSign`. *Bukan* PairIP |
| `libpglarmor.so` | 61.200 | **ByteDance Pangle** — `Java_com_bytedance_sdk_component_pglcrypt_PglCryptUtils_bc` (kripto SDK iklan) |
| `libnms.so` | 281.896 | ByteDance Pangle — string `com.pgl.ssdk.ces.a` |
| `libtobEmbedPagEncrypt.so` | 8.184 | Pangle — `PangleEncryptUtils_ttEncrypt/ttDecrypt` |
| `libapminsighta.so` / `libapminsightb.so` | 97.488 / 110.432 | ByteDance APM Insight (pemantau crash Pangle) |
| `libapplovin-native-crash-reporter.so` | 867.928 | AppLovin MAX crash reporter |
| `libtt_ugen_layout.so` | 360.968 | Pangle (TikTok Ads) layout |
| `libavcodec.so` / `libavformat.so` / `libavutil.so` / `libswresample.so` | 438.320 / 253.896 / 539.200 / 75.392 | FFmpeg (pemutar video iklan) |
| `libbuffer.so` / `libfile_lock.so` / `libdatastore_shared_counter.so` | 9.992 / 9.992 / 7.112 | AndroidX DataStore/WorkManager |

**Kesimpulan native:** tidak ada `libil2cpp.so`, `libUnreal.so`, atau lib engine lain. Tidak ada lib anti-cheat native komersial — **PairIP, Promon, V-Key, FairGuard, ACE, Tencent/NetEase protect: TIDAK ditemukan**. Semua lib adalah engine libGDX + tumpukan SDK iklan (AppLovin MAX, ironSource/LevelPlay, Unity Ads, Yandex, InMobi, BidMachine, Mintegral, Fyber, Facebook) + Adjust + Firebase.

---

## 3. Arsitektur: ONLINE-FIRST, ekonomi di server

### 3.1 Backend & protokol
- Klien **Socket.IO** persisten ke **`http://diamond.onebi.net:9096/`** (HTTP polos, bukan HTTPS) — bukti: kelas `L1/a.java` baris 234 `C7562b.a("http://diamond.onebi.net:9096/", ...)` dengan handler connect/disconnect/reconnect.
- Protokol pesan CS (client→server) / SC (server→client) di paket `com.gdx.diamond.remote.*`, dikelola `com.gdx.diamond.socket.handler.RemoteManager` (1.556 baris). ±100 event, antara lain: `init_session`, `request_sync`, `set_score`, `buy`, `iap`, `restore_iap`, `open_chest`, `spin_wheel`, `gift_code`, `leader_board`, `daily_levels`, `download_map`, `search_user_level`, `login_facebook`, `lock_account`, `cheat`.

### 3.2 Sesi dibuka dengan laporan perangkat
`CSInitSession` (dikirim di `RemoteManager.onSessionConnected`) berisi: `accessToken`, `advertId`, `cheat` (flag cheat tersimpan), **`rooted`** (hasil deteksi root), **`sha`** (diisi dari objek listener platform — konteksnya terkait tanda tangan; isi persisnya tidak terkonfirmasi), `platform`, `version=147`, `timeZone`, `locale`, `name`.

### 3.3 Model data: lokal sebagai cache, server sebagai hakim
- Profil disimpan lokal sebagai JSON (libGDX Preferences): `sync_pref` (kelas `l1.g`: accessToken, userInfo, flag `lock`, flag `cheat`, `syncData`, timedSkins, `lastSyncEnergyTime`, dll) + profil pemain (kelas `l1.e`, 1.192 baris).
- Setiap perubahan nilai memicu pencatatan perubahan (`c(key, old, new)`) yang diunggah lewat `request_sync` (`CSRequestSync`: `TYPE_CHANGE`/`TYPE_COMPLETE`, `syncSequence`, `data`).
- Server membalas/menimpa lewat `SCRequestSync`, `SCUpdateData`, `SCAddItem*`, `SCDefineData` (konfigurasi game — harga/aturan — dikirim server sebagai string data), `SCDownloadMap` (peta level dari server).
- Transaksi ekonomi **diproses server**: beli (`CSBuy`), IAP (`CSIAP` + pesan "Verifying your purchase..." / "Unable to verify your purchase!"), buka peti (`CSOpenChest`), putar roda (`CSSpin`), kode hadiah (`CSGiftCode`), VIP (`CSVip`/`SCVip`).
- Energi beregenerasi berbasis **waktu server**: field `lastSyncEnergyTime`, pesan `CSSyncTime`/`SCSyncNextTime`.
- Bila soket putus, game menampilkan dialog jaringan (`checkShowDialogNetwork`). Login akun tidak wajib (token anonim), Facebook hanya penautan opsional (`CSLoginFacebook`).

**Vonis:** game ini *online-first / server-anchored*. Stage puzzle dimainkan lokal, tetapi progres, mata uang, inventaris, skor leaderboard, dan level harian/buatan pemain direkonsiliasi dengan server.

---

## 4. Proteksi & anti-cheat (lapisan Java/protokol — bukan native)

1. **SecureInt (kelas `h1.b` / `C0284b`)** — nilai penting disimpan sebagai *dua salinan terenkripsi XOR + offset acak per instance*:
   ```java
   int i = (b ^ a) - c;
   if (i != (e ^ d) - f) { C0278a.O = true; }  // tidak cocok => flag cheat global
   ```
   Setiap pembacaan nilai melakukan pemeriksaan silang ini. Pemakai terkonfirmasi di profil pemain `l1.e`: **`o` = gem, `p` = diamond, `w` = energy**, plus 4 SecureInt lain (q/r/s/t) dan peta jumlah item (`IntMap Q`) yang juga berisi SecureInt.
2. **Pelaporan cheat ke server (pesan `cheat` / `CSCheat`)**:
   - `type 0` = `TYPE_MEMORY` — dikirim `RemoteManager.act()` saat flag integritas memori terpicu; disertai kunci lokal paksa: dialog *"Your game is locked! Contact us for more information!"* +
...[truncated 7664 chars]