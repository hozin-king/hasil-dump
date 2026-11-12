# REA — Super Kick Off ("Superkickoff") v4.3.4

Analisis statis bundle `Superkickoff_4.3.4_1_b8ul.apks` (base.apk 83,5 MB + split_config.arm64_v8a.apk 34,9 MB + split bahasa `in` + split density xxhdpi). Analisis saja, tanpa build mod.

## 1. Identitas

| Item | Nilai |
|---|---|
| Package | `app.superkickoff` |
| Label | **Superkickoff** |
| Versi | versionName **4.3.4**, versionCode **119** |
| Activity utama | `app.superkickoff.MainActivity` (Flutter, embedding v2) |
| minSdk / targetSdk | 32 (Android 12+) / 36 |
| Application class | default (tidak ada `android:name` khusus di `<application>`) |
| Izin penting | INTERNET, `com.android.vending.BILLING`, AD_ID, ACCESS_NETWORK_STATE, WAKE_LOCK, VIBRATE, FOREGROUND_SERVICE, AdServices (topics/attribution/ad_id), C2DM/FCM |

**Sertifikat:** base.apk dan split arm64 ditandatangani sertifikat yang **identik** (SHA-256 `3e70d122b905f4e445e18932482174ea1240d2f14cc1ebeb96b1190aaec6dd16`) → split memang pasangan build yang sama. Catatan: DN sertifikatnya generik ("CN=Android, O=Google Inc.") plus Source Stamp — pola khas bundle hasil **re-sign/repack** (bukan kunci developer asli dari Play), jadi berkas ini sebaiknya diperlakukan sebagai hasil repack pihak ketiga.

## 2. Arsitektur — Flutter, logika di Dart AOT

Seluruh logika game adalah **Dart yang di-AOT-compile** ke `libapp.so`. Lapisan Java/Kotlin hanya berisi engine Flutter + plugin + SDK iklan/billing. Tidak ada logika game di dex.

### Native libs (split arm64, 12 berkas)

| Lib | Ukuran | Fungsi |
|---|---|---|
| `libapp.so` | 20.054.920 | **Kode game (Dart AOT snapshot)** |
| `libflutter.so` | 11.747.864 | Engine Flutter |
| `libsqlite3.so` | 1.732.360 | SQLite (database musim bawaan / sqflite) |
| `libtt_ugen_layout.so` | 440.672 | Pangle (ByteDance Ads) |
| `libnms.so` | 302.248 | Komponen SDK iklan ByteDance/Pangle |
| `libdartjni.so` | 131.400 | Plugin dartjni |
| `libapminsighta/b.so` | ±100–124 KB | APMInsight (monitoring Pangle/ByteDance) |
| `libpglarmor.so` | 68.776 | **Pangle** — terbukti dari simbol JNI `Java_com_bytedance_sdk_component_pglcrypt_PglCryptUtils_bc`. **Bukan PairIP.** |
| `libbuffer_pgl.so`, `libfile_lock_pgl.so`, `libdatastore_shared_counter.so` | kecil | Util Pangle/AndroidX datastore |

### Dex (6 berkas, ±44 MB — hampir semua SDK)

- **Iklan:** AdMob (google_mobile_ads + meta-data APPLICATION_ID ada di manifest, nilai tidak ditampilkan), **Unity Ads** (SDK penuh, ribuan referensi kelas), **Meta Audience Network** (dex terpisah di `assets/audience_network/`), **Pangle/ByteDance OpenAds** (aktivitas TT* lengkap). AppLovin hanya disebut sebagai nama partner mediasi (2 string) — SDK penuhnya **tidak terbukti** ada. IronSource/Vungle/Chartboost/InMobi: tidak ada.
- **Billing ganda:** Play Billing (ProxyBillingActivity + izin BILLING) **dan Amazon IAP** (`com.amazon.device.iap.ResponseReceiver`, 135 referensi) — pola khas lapisan pembelian **RevenueCat** (lihat bawah).
- **Firebase (plugin Flutter resmi):** core, **auth**, **database (Realtime Database)**, **functions (Cloud Functions)**, analytics, crashlytics, remote config + Google Sign-In.
- **Play Integrity API terbundel** di dex (`com/google/android/play/core/integrity`, ±101 referensi kelas).
- Plugin lain: shared_preferences, image_picker, file_picker, share_plus, device_info_plus, package_info_plus, url_launcher, webview_flutter, UCrop (potong gambar — avatar/logo tim).

### Paket Dart (dari string snapshot `libapp.so`, 52.744 string)

Paket kunci: `purchases_flutter` (**RevenueCat** — ada `Util/Helpers/RevenueCatHelper.dart` milik game sendiri), `hive_ce` (database lokal Hive), `sqflite_common`, `dio` + `http`, `firebase_auth`, `firebase_database`, `google_mobile_ads`, `audioplayers`, `syncfusion_flutter_charts` (grafik statistik/keuangan), `app_tracking_transparency`, `archive` + file picker (ekspor/impor berkas).

### Seberapa terbaca logikanya?

Jauh lebih tertutup daripada game Java:
- Yang pulih dengan mudah: **nama 499 berkas Dart game** (`package:super_kickoff/...`), string literal (label UI, nama event analitik, fragmen endpoint, nama mata uang), dan struktur folder yang memetakan fitur secara akurat.
- Yang **tidak** pulih: kode Dart menjadi machine code ARM64 di `libapp.so`. Tidak ada decompiler setara jadx untuk snapshot Dart AOT; analisis fungsi per fungsi butuh parsing snapshot (kelas Doldrums/reFlutter) atau instrumentasi runtime, dan offset-nya berubah tiap build. Nama fungsi di snapshot juga sebagian ter-mangle (`...@1416519833`).
- Kesimpulan: peta fitur bisa dibuat akurat dari string, tapi "alamat fungsi" ala game Java **tidak ada** di sini.

## 3. Isi & mode permainan — football manager simulator, bukan arcade

Nama file Dart membuktikan genrenya: ini **simulator manajer sepak bola** berbahasa Spanyol (pengembang Amerika Latin) dengan kedalaman besar:

- **Mode karier lokal ("Partida")**: skuad (Plantilla), taktik/formasi, kontrak & gaji, transfer & peminjaman (Cesion), stadion & kapasitas, sponsor (Patrocinio), keuangan lengkap (Finanzas: gaji, traspasos, grafik), akademi (Fuerzas Basicas), riwayat musim/trofi, penghargaan Ballon d'Or, penalti & VAR di simulator pertandingan (`Util/Algoritmos/AlgPartido.dart`, `SimuladorBackgroundCopasInternacionales.dart`).
- **Kompetisi**: liga banyak negara (LigaMX, Argentina, Colombia, Guatemala, dll. — `FixtureLigas`, `Copium_Ligas_V14` = basis data liga komunitas), Champions League Eropa/Asia/Afrika, Concacaf, Leagues Cup, Piala Dunia antar-negara & antarklub. Database skuad historis terbundel sebagai aset: `1998.db` s.d. `2026.db` (+ `2026_w_.db`) — bisa main dengan skuad era klasik.
- **Item habis pakai (UsoItems)** yang dibeli/dipakai di karier: Bebida Energetica (minuman energi), Kit Medico, Kit Estadio, Kit Apelacion, Pase Anti-Despido (anti-pecat), Poder Extra, ubah nama tim/stadion, ubah pemain jadi superstar, dan **pemain Legenda** acak.
- **Login** Google/Apple via Firebase Auth (`Login/Login.dart`, `WizardNuevoUsuario.dart`), profil tersinkron (`ModelosJSON/PerfilFirebase.dart`).

### Lapisan online — asinkron, BUKAN PvP real-time

Bukti online: backend sendiri (`cloud.superkickoff.org`, `superkickoff.org/api`, `superkickoff.online/api` — dio/http), Firebase Auth + Realtime Database + Cloud Functions, **Ranking** global dengan pencarian nama pengguna (`Menu/Ranking/ModalBusquedaRanking.dart`, model `RankingMundial`), liga & aset **komunitas** (`LigaSuperkickoff`, `AssetComunidad`, forum di `superkickoff.app/forums/`), event & hadiah (`Evento`, `Recompensa`), serta pembuatan pemain akademi yang memunculkan peringatan khusus bila tidak ada internet (`FuerzasBasicas/AlertaNoHuboInternet.dart`) — indikasi generasi pemain muda divalidasi/dibuat di server.

Bukti negatif PvP: **tidak ada** Photon/PlayFab/Nakama/socket matchmaking di dex maupun string Dart, tidak ada berkas/istilah "multiplayer/matchmaking/PvP" sama sekali. Pertandingan persahabatan (Amistosos) adalah melawan tim AI.

**Vonis bentuk game:** inti permainan (simulasi karier) berjalan **lokal di perangkat**; lapisan akun, ranking, toko, event, dan konten komunitas berjalan **online asinkron**. Tidak terbukti ada pertandingan langsung melawan manusia.

## 4. Ekonomi

- **Mata uang premium: "Superkickoff Coins"** ("Superki coins"). Bukti string: `SUPERKICKOFF COINS`, `Not enough coins`, event `COINSOBTENIDAS`, `SINCOINS`, `TUNECESITASCOINS`.
- **Sumber coins:** beli di Tienda (kartu `CardCoins`), **gratis lewat iklan video** (`coins_gratis_video`), **tukar kode** (`CANJEARCOINS` / "Redeem coins"), hadiah event.
- **Pemakaian coins:** item UsoItems, **buka pack pemain** (`RespuestaPackJugadores`, `ERRORABRIENDOPACK`), dan **ditukar menjadi uang klub** di karier (`Finanzas/ModalCambioCoins.dart`, event `CAMBIOCOINS`, `coins_antes`/`coins_despues` = sebelum/sesudah — pola pencatatan transaksi).
- **Langganan VIP:** paywall RevenueCat (`StartScreen/Tienda/PaywallSuscripciones.dart`, `CardSuscripcion`, string entitlement `suscripcion_VIP`, `SUSCRIPCION_ACTIVA`). RevenueCat memvalidasi struk pembelian di server RevenueCat/Play — **server-validated**.
- **Pencatatan transaksi di server:** model `TransaccionTienda` + `ArticulosTienda` (katalog toko dari JSON server), riwayat pembelian (`Tienda/ModalHistorial`), dan string error **`ERROR_USUARIO_ABUSIVO`** (penolakan pengguna "abusif") menunjukkan backend ikut mengawasi transaksi. Indikasi kuat saldo coins terikat akun & divalidasi server; bukti mutlaknya baru bisa didapat dari uji runtime, jadi vonis coins di bawah ditulis sebagai "server (indikasi kuat)".
- **Simpanan karier lokal:** model-model Hive (`Database/Modelos/*.g.dart` — Equipo, Jugador, Temporada, Torneo, Contrato, Transferencia, dll.) di penyimpanan privat aplikasi (pola standar Hive = folder dokumen aplikasi), plus database SQLite bawaan untuk data musim. Progres karier tidak tampak disinkronkan per-nilai ke server selain profil & ranking.

## 5. Proteksi

- **PairIP: TIDAK ada.** `libpglarmor.so` yang sekilas mirip adalah milik Pangle (bukti simbol JNI `com_bytedance_sdk_component_pglcrypt` di atas). Tidak ada `libpairipcore`/`libvmrunner`, tidak ada kelas `com.pairip` di dex/string.
- **Play Integrity API: terbundel** (±101 referensi kelas Play Core Integrity di dex, konsisten dengan aktivitas PlayCore di manifest). Apakah benar-benar *ditegakkan* saat runtime (mis. menolak klien hasil modifikasi) **tidak terbukti** dari analisis statis — bisa saja hanya dependensi plugin (RevenueCat/Firebase juga menarik Play Core).
- **Deteksi root/Frida/emulator:** tidak ditemukan string/indikator apa pun di `libapp.so` (pencarian frida/magisk/rootbeer/jailbreak kosong). Cek tanda tangan mandiri di kode Dart: **tidak terbukti**.
- Karena logika Dart adalah kode native AOT, "proteksi" praktisnya adalah arsitekturnya sendiri: tidak ada dex game yang bisa di-smali-patch.

## 6. Vonis cheat per fitur (server vs lokal dulu)

| Fitur | Vonis | Alasan & target |
|---|---|---|
| Uang klub, gaji, harga transfer, data pemain/tim di mode karier | **LOKAL — bisa secara teknis** | Data karier ada di box Hive lokal; target realistis = mengedit berkas simpanan Hive di penyimpanan aplikasi (perlu root untuk menulis ke data privat aplikasi lain, atau jalur ekspor/impor bila disediakan game). Kesulitan: **sedang** — format Hive biner bertipe (adapter `.g.dart` diketahui dari nama model), bukan tabel teks. |
| Hasil pertandingan / simulator (AlgPartido), cedera, sanksi | **LOKAL — sulit** | Logika di `libapp.so` (ARM64). Tidak ada hook Java; satu-satunya jalur adalah patch/instrumentasi native Dart AOT per build. Kesulitan: **tinggi**, kerapuhan tinggi. |
| Item UsoItems (kit medis, anti-pecat, legenda, dll.) | **Campuran — tidak aman disimpulkan lokal** | Item diperoleh lewat Tienda/transaksi yang tercatat (`TransaccionTienda`); jumlah item kemungkinan ikut tersimpan/diakui server. Tanpa bukti runtime, jangan dianggap lokal murni. |
| **Coins** | **SERVER (indikasi kuat) — jangan disentuh** | Terikat akun Firebase + API sendiri + pencatatan transaksi + error anti-abuse. Menambah coins lokal hampir pasti tertolak/terdeteksi saat sinkronisasi. |
| **Langganan VIP / pembelian pack & item berbayar** | **SERVER — ditolak** | Struk divalidasi RevenueCat + Play Billing/Amazon IAP di server. |
| **Ranking global (RankingMundial)** | **SERVER — ditolak** | Data leaderboard hidup di backend (RTDB/API + Cloud Functions); tidak ada target lokal yang berarti, dan memalsukannya berarti memanipulasi data kompetisi pengguna lain. |
| PvP real-time melawan manusia | **Tidak ada mode-nya (tidak terbukti)** | Tidak ditemukan matchmaking/socket/Photon/PlayFab/Nakama. Karena itu tidak ada kategori "bantuan saat PvP" untuk dinilai di game ini. |
| Iklan (AdMob/Unity/Meta/Pangle) | Di luar cakupan vonis cheat | Mediasi 4 jaringan; menghapus iklan bukan fitur yang dinilai di sini. |

### Ringkasan satu kalimat

Superkickoff adalah manajer sepak bola Flutter dengan karier **lokal** (simpanan Hive bisa diedit secara teknis, tapi logika Dart AOT membuat patch kode sangat sulit) dan lapisan akun/coins/VIP/ranking yang **server-validated** — jadi target lokal yang masuk akal hanya sebatas data karier offline, sedangkan semua yang bernilai uang/kompetitif terkunci di server.
