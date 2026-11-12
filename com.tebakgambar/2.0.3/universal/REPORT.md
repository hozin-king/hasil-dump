# Dump + REA — Tebak Gambar v2.0.3 (Flutter)

Tanggal analisis: 22 Oktober 2026
Sumber: `downloads/Tebak Gambar_2.0.3.apks` (23.799.488 byte, SHA-256 `7666317a321ff49072936348b3397c57a29252752e5b4d70524e8df1ae463916`)
Metode: ekstraksi split, androguard (manifest/dex), `strings` pada `libapp.so`, inspeksi ZIP, serangan known-plaintext `bkcrack` 1.8.1. Tanpa eksekusi dinamis, tanpa membangun mod.

---

## 1. Identitas aplikasi

| Item | Nilai |
|---|---|
| Nama | Tebak Gambar |
| Package | `com.tebakgambar` |
| versionName / versionCode | 2.0.3 / 15029 |
| minSdk / targetSdk | 24 (Android 7.0) / 36 (Android 16) |
| Activity utama | `com.tebakgambar.MainActivity` (satu-satunya kelas milik aplikasi di dex) |
| Framework | Flutter (embedding v2), Dart AOT — logika game 100% di `libapp.so` |
| Dart snapshot hash | `ace654289f5abc240509fc941453ebc5` (compressed-pointers, arm64, release) |
| Distribusi | Google Play (stamp `STAMP_TYPE_DISTRIBUTION_APK`, splits wajib dari Play) |
| Tanda tangan | Skema v2+v3 aktif; sertifikat penanda tangan: CN=`tebakgambar.com` (self-issued, subjek = penerbit), SHA-256 `91a1b9ec76b7460230d2b157e944904542c0ad637de9a46a5b233675b6efc911`, serial `0x2afc92aa` |

Isi .apks (5 split):

| File | Ukuran | Isi |
|---|---|---|
| `base.apk` | 26.544.157 byte | dex, aset Flutter, 400 zip level |
| `split_config.arm64_v8a.apk` | 19.898.949 byte | semua `.so` (hanya arm64-v8a) |
| `split_config.xxhdpi.apk` | 87.660 byte | drawable xxhdpi |
| `split_config.in.apk` | 20.889 byte | sumber daya bahasa Indonesia |
| `split_config.ms.apk` | 20.889 byte | sumber daya bahasa Melayu |

Tidak ada split armeabi-v7a/x86 — perangkat 32-bit tidak didukung.

## 2. Native library (semua di split arm64)

| .so | Ukuran | SHA-256 (awal) | Keterangan |
|---|---|---|---|
| `libflutter.so` | 11.580.816 | `bc65ea225336…` | Engine Flutter |
| `libapp.so` | 8.258.448 | `d60898c1f417…` | Kode Dart AOT aplikasi (stripped, simbol snapshot Dart saja) |
| `libdatastore_shared_counter.so` | 7.112 | `d3e48717c9aa…` | Penunjang AndroidX DataStore |

Tidak ada `.so` pihak ketiga lain: tidak ada SDK iklan native tambahan, tidak ada anti-cheat native, tidak ada lib game komersial.

## 3. Dex / shell Android

4 dex di base.apk: `classes.dex` 8.162.180, `classes2.dex` 215.488, `classes3.dex` 8.426.716, `classes4.dex` 2.259.308 byte — isinya pustaka standar (Google Play Services, Firebase, AdMob, AndroidX) dan plugin Flutter.

Kelas milik aplikasi hanya 8, semuanya di `classes4.dex`: `com.tebakgambar.MainActivity` + kelas `R$*`. `MainActivity` adalah turunan standar `FlutterActivity` (template Flutter, `GeneratedPluginRegistrant` standar). **Tidak ada logika game, kunci, atau password di lapisan Java/Kotlin** — semua di Dart.

Permission (15): INTERNET, ACCESS_NETWORK_STATE, WAKE_LOCK, VIBRATE, POST_NOTIFICATIONS, FOREGROUND_SERVICE, READ/WRITE_EXTERNAL_STORAGE (legacy), AD_ID (`com.google.android.gms.permission.AD_ID`), ACCESS_ADSERVICES_AD_ID / ATTRIBUTION / TOPICS, BIND_GET_INSTALL_REFERRER_SERVICE, RECEIVE (C2DM/FCM), READ_GSERVICES, dan permission internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

`allowBackup=false`, `usesCleartextTraffic=false` (traffic HTTP ke API lama tetap ada di kode — lihat §6, kemungkinan cleartext diizinkan per-domain lewat networkSecurityConfig).

## 4. SDK pihak ketiga (dari manifest, dex, dan method-channel Dart)

| Kategori | SDK | Bukti |
|---|---|---|
| Iklan | **Google AdMob saja** (`google_mobile_ads`) | App ID `ca-app-pub-7269282889157841~9996822413`; ≥7 ad unit ID di `libapp.so` (`…/8476394341`, `…/7877628547`, `…/4537149333`, `…/5227414476`, `…/5133520483`, `…/6227110304`, `…/5087813675`) + 2 unit di resources (`…/1760629611`, `…/7807163213`). Mediasi hanya adapter AdMob bawaan — tidak ada AppLovin/Unity/ironSource |
| Backend/Auth | **Firebase**: Core, Auth, Analytics, Crashlytics, Messaging (FCM), Remote Config | Registrar lengkap di manifest; project `tebak-gambar-ios` (DB `https://tebak-gambar-ios.firebaseio.com`, storage `tebak-gambar-ios.firebasestorage.app`, web client id `993131471052-…apps.googleusercontent.com`) |
| Login | Google Sign-In (Firebase Auth) | `google_sign_in`, aset `google.png`; aset `apple.png` ada (login Apple relevan di iOS); ikon Facebook hanya untuk tautan halaman sosial — **tidak ada Facebook Login SDK** |
| Pembelian | `in_app_purchase` (plugin terdaftar di Dart) | Tapi: **tidak ditemukan produk, harga, atau fitur premium/langganan apa pun di strings** — tidak ada "premium", "remove ads", "no ads", VIP. Indikasi plugin disertakan tapi monetisasi praktisnya iklan saja (perlu verifikasi dinamis untuk kepastian 100%) |
| Lainnya | sqflite (DB lokal), `archive` (ZIP), PointyCastle (kripto Dart: AES/GCTR, AEAD, ChaCha20-Poly1305, kurva EC), `audioplayers` (suara .wav), `share_plus`, `image_picker`, `flutter_local_notifications`, `webview_flutter`, `url_launcher`, `shared_preferences`, `path_provider` | strings `libapp.so` + registrant |

## 5. Fitur game (dari strings `libapp.so`)

- **Struktur**: 10 level × 20 soal = 200 soal reguler. Teks aturan bawaan: *"SETIAP LEVEL ADA 20 SOAL"* dan soal terakhir tiap level adalah **"Raja Gambar"** — kalahkan untuk membuka level berikutnya.
- **Jawaban diketik** dari gabungan gambar + huruf/suku kata di sekitar gambar (model `QuestionModel`, `SoalClueModel`, `CluePartModel(jawaban:…)`); ada status jawaban "benar / dikit lagi / salah" (aset popup).
- **Nyawa (life)** — `GameData(life: …)`. Bukan koin: **tidak ada mata uang "coin/koin" sama sekali di binary**.
- **Bantuan huruf**: membuka huruf jawaban, diperoleh dengan menonton iklan ("Dapatkan bantuan huruf dengan nonton iklan").
- **Kunci jawaban / free answer**: `FreeAnswerModel(quantity:…)`, `free_answer_quantity`, `free_answer_progress`. Diperoleh dari iklan rewarded ("Ambil kunci jawaban … dengan menonton iklan", "Kamu mendapatkan kunci jawaban gratis!"), konfigurasi reward bawaan `{"reward":"1","numOfWatch":"3"}` dan `{"reward":"1","numOfWatch":"1"}`.
- **Hint yang dibuat lokal**: strings `Generated hint: "…"`, `Hint length: …`, `hint_unlocked_<…>` — petunjuk diturunkan dari jawaban di perangkat.
- **Soal Receh** (`soalRecehIds`, `SoalRecehID`) — soal sisipan/hiburan antar soal reguler.
- **Event**: endpoint + model event (`RegularEventModel`, `EventQuestionModel`, `ClueEventModel`), banner event, dan halaman "home" dari `https://matchingimages.com/api/1.5/homes/active/2/`.
- **Iklan**: banner (`ads_banner`, CustomBannerModel dari server), interstitial (frekuensi diatur `interstitial_question_count` / `event_interstitial_question_count` — per sekian soal), rewarded + rewarded-interstitial (untuk bantuan & kunci jawaban), preload iklan (`preload_hint_ad`, `preload_free_answer_ad`).
- **Login & simpan progres**: login Google (Firebase Auth) → token sinkronisasi ke server sendiri ("Login agar levelmu tidak hilang"). Model `LoginRequest(oldSyncToken:…)`, `LoginResponse(syncToken:…)`.
- **Lainnya**: cek update paksa/lembut via Remote Config (`force_version_android`, `soft_version_android`), notifikasi FCM + lokal, bagikan hasil (share banner), intro 4 gambar, tautan sosial (Instagram/X/Facebook/TikTok/YouTube @tebakgambar_id) dan Tokopedia (merchandise).

## 6. Endpoint server (strings `libapp.so`)

| Endpoint | Fungsi |
|---|---|
| `https://api.tebakgambar.com/acn/v1/login` | Login + tukar sync token |
| `https://api.tebakgambar.com/v1/game/event` dan `/acn/v1/game`, `/v1/game/event/` | Data game & event |
| `https://api.tebakgambar.com` (base) + `getGameData` (dengan `game_token`) | Ambil/sinkron data pemain |
| `http://apis.tebakgambar.com/v4/SoalReguler/get/` | API lama daftar soal reguler (HTTP polos) |
| `https://matchingimages.com/api/1.5/homes/active/2/` | Konten home/event |
| Firebase (`tebak-gambar-ios.firebaseio.com`, firebasestorage) | Auth, Remote Config, FCM, Crashlytics, Analytics |

## 7. Mekanisme level & ZIP ber-password — temuan inti

### 7.1 Alur data level

1. Metadata level disimpan di SQLite lokal **`tebakgambar_levels.db`**, tabel:
   - `levels(id, title, subtitle, zipLevelUrl, iconUrl, frameUrl, achievementId, sliderId, quotes, version, color, backgroundColor, soalRecehIds)`
   - `questions(id, answer TEXT NOT NULL, imageUrl, levelId)` — **jawaban soal tersimpan teks polos di DB lokal ini** (diisi saat level diunduh/diinisialisasi).
   - `level_versioning(level_id, downloaded_version, is_downloaded, last_updated)` — versi per level; strings debug menunjukkan app membandingkan versi server vs lokal ("SERVER level:", "LOCAL level:", "Server returned NULL, keeping local level").
2. Paket soal per level berupa ZIP yang diunduh dari `zipLevelUrl`; bila unduhan gagal, app memakai **ZIP bawaan (bundled)** dari aset: "bundled ZIPs for level …", "Failed to initialize bundled levels".
3. Penjagaan progres lokal: app menolak lompat melewati batas buka ("…is beyond max unlocked level (…)").

### 7.2 ZIP bawaan — koreksi jumlah & dua skema berbeda

Total **400 zip**: **200 Android** (`assets/level/android-level-1..10/`, 20 per folder) + **200 iOS** (`assets/level/ios-level-1..10/`) yang ikut terbawa di APK Android. Keduanya skema berbeda total:

**Skema Android** (yang dipakai build ini):
- Nama file luar: 32 hex (pola MD5), nama file isi tunggal: 64 hex (pola SHA-256), keduanya unik per soal dan **bukan** hash dari isi/nama satu sama lain (diuji MD5/SHA-256 silang — tidak cocok; kemungkinan ID acak/hash dari URL/nama asli di server).
- Isi: 1 file, metode **Store** (tanpa kompresi), ukuran 6.720–33.013 byte (total android ±2,54 MB).
- Enkripsi: **ZipCrypto klasik (PKWARE)** — flag bit 0 aktif, tanpa extra-field WinZip AES (0x9901), extract-version 20. Dikonfirmasi `bkcrack -L`: `ZipCrypto / Store`.
- **Password TIDAK ditemukan sebagai string polos**: seluruh 12.491 string `libapp.so` diuji sebagai password (gagal), begitu juga daftar kandidat manual (nama paket, "smzip", `tebakgambar`, nama file, hash nama file, dsb). Kata `smzip` yang mencurigakan di strings ternyata bukan password. Kesimpulan: password **diturunkan/dirakit saat runtime** (mis. dari potongan string, hash, atau nilai response server) — perlu RE Dart lebih dalam (blutter/Frida) untuk memulihkannya secara statis.
- **Isi zip juga bukan gambar mentah standar**: serangan known-plaintext bkcrack atas header PNG (16 byte), JPEG/JFIF (12 byte), WebP-VP8 (offset 8 + "RIFF"), dan tanda tangan kontainer JPEG XL (12 byte) **semuanya menghabiskan ruang kunci 2³¹ tanpa hasil** → byte awal file isi bukan header format-format itu. Konsisten dengan skema iOS (di bawah): payload soal kemungkinan **ikut ter-encode/obfuscate** di dalam zip.

**Skema iOS** (tidak dipakai di Android, tapi membuka pola pikir pembuatnya):
- Nama file luar memakai karakter URL-escape (`wExXFha%7DjQ…`), nama isi 12 karakter acak (`jrqWH2OYwEwD`), metode **Deflate**, **tanpa password**.
- Isi bukan gambar: teks 62-simbol (huruf+angka+`{`+`}`) mirip base64 kustom, dengan **64 karakter awalan yang identik di semua file** → header ter-encode yang sama / enkripsi deterministik atas header gambar yang sama. Belum dipecahkan, dan tidak relevan untuk build Android.

### 7.3 Token game terenkripsi

`GameData` disinkronkan memakai **`game_token`** yang dienkripsi/didekripsi di perangkat ("Encrypt game token error:", "Decrypt game token error:", `game_token_synced`, `sync_token`, `old_sync_token`). String kripto PointyCastle (AES-GCTR, AEAD, "Key length not 128/192/256 bits") menunjukkan token ini blob terenkripsi, bukan JSON polos. Kunci tidak muncul sebagai string utuh di `libapp.so`.

## 8. Klasifikasi LOKAL vs SERVER

| Fitur | Klasifikasi | Bukti |
|---|---|---|
| Daftar level & soal (gambar) | **LOKAL (aset) + SERVER (pembaruan)** | 200 zip bawaan di APK; metadata + versi dari API, `zipLevelUrl` untuk unduh; fallback lokal saat server null/gagal |
| Jawaban soal | **LOKAL** | Kolom `questions.answer` teks polos di SQLite perangkat (diisi dari paket level) |
| Validasi jawaban (benar/salah/dikit lagi) | **LOKAL** | Perbandingan dengan `questions.answer` + pembuatan hint lokal di perangkat |
| Kunci level berikut / progres level | **LOKAL, disinkronkan** | Penjaga "max unlocked level" lokal; progres masuk `GameData` yang disinkronkan |
| Nyawa (life), jumlah free answer, hint | **LOKAL ↔ SERVER (sinkron via game_token terenkripsi)** | `GameData(life:…)`, `free_answer_quantity` di model data yang diambil dari `getGameData` server dan disimpan lokal; server dapat menimpa saat sinkron |
| Bantuan huruf & kunci jawaban gratis | **LOKAL (pemberian)**, pemicu iklan rewarded dari AdMob | Teks UI + konfigurasi reward bawaan |
| Iklan (banner/interstitial/rewarded, banner kustom) | **SERVER** (AdMob + konfigurasi server) | Ad unit ID, `interstitial_question_count`, `CustomBannerModel(imageUrl…)` |
| IAP / premium | **Tidak terbukti ada** | Plugin `in_app_purchase` terdaftar, nol produk/premium di strings |
| Login akun | **SERVER** | Firebase Auth (Google) + `api.tebakgambar.com/acn/v1/login`, sync token |
| Sinkron progres antar perangkat | **SERVER** | `oldSyncToken`/`syncToken`, `game_token` |
| Event & home | **SERVER** | Endpoint event + matchingimages.com |
| Leaderboard | **Tidak ditemukan** | Tidak ada string/fitur leaderboard di binary (hanya `achievementId` per level di skema DB) |
| Anti-cheat / deteksi root / cek tanda tangan | **Tidak ditemukan** | Tidak ada .so anti-cheat, tidak ada string deteksi root/integritas di Dart maupun dex |

## 9. Kelayakan MOD (analisis saja — tidak dibangun)

### (a) Auto-jawab / tampilkan jawaban level saat ini — **BISA, jalur paling mudah dari semua fitur**

- Jawaban sudah ada **teks polos di SQLite perangkat** (`tebakgambar_levels.db` → `questions.answer`, terpetakan ke `levelId` + urutan soal). Tidak perlu memecahkan password ZIP sama sekali untuk fitur ini.
- Jalur gabung APK: kode menu (Java/Kotlin, dex tambahan) berjalan se-proses, membaca file DB yang sama di data aplikasi dan menampilkan jawaban soal aktif. Menentukan "soal yang sedang tampil" adalah satu-satunya bagian yang perlu dipetakan (urutan soal per level tersimpan di progres lokal; alternatif sederhana dan jujur: tampilkan daftar 20 jawaban level aktif bernomor — pengguna mencocokkan nomor soal).
- Jalur root: baca DB yang sama dari `/data/data/com.tebakgambar/` secara eksternal.
- Risiko: rendah. Lokal murni, tidak menyentuh server. Catatan: DB terisi setelah level diunduh/dibuka sekali.

### (b) Floating menu jendela melayang berlogo — **BISA, tapi JANGAN mengulang kesalahan Bunker**

- Flutter merender ke **SurfaceView milik engine** (`FlutterSurfaceView`; string `maybeResizeSurfaceView` di `libflutter.so`). View Android biasa yang ditempel ke DecorView/activity berisiko tertutup permukaan render — persis akar kegagalan tombol MOD Bunker v1–v3 (`setZOrderOnTop(true)` di game itu; di Flutter z-order diatur engine dan tidak bisa diandalkan dari sisi menu tempel).
- Jalur realistis, urut dari paling aman:
  1. **Overlay WindowManager beneran** dari kode yang digabung ke APK: jendela tipe panel bertoken activity (`TYPE_APPLICATION_PANEL`) atau `TYPE_APPLICATION_OVERLAY` (yang kedua butuh izin "tampil di atas aplikasi lain" dari pengguna). Jendela terpisah selalu di atas SurfaceView — menampung tombol berlogo (aset gambar sendiri) yang bisa digeser + panel menu. Inilah pola mod menu pada umumnya.
  2. **Root injector**: proses terpisah menggambar overlay sistem (butuh root/izin overlay), membaca DB game untuk jawaban. Lebih berat, tidak perlu untuk game ini.
- **Gabung APK lebih cocok daripada root injector di sini**: game offline-first, tanpa anti-cheat/deteksi root/cek tanda tangan yang ditemukan, dan data yang dibutuhkan (DB) berada di data aplikasi sendiri. Injector hanya unggul bila APK tidak boleh diubah tanda tangannya — di sini tidak ada bukti game memverifikasi tanda tangannya sendiri. Konsekuensi gabung: APK hasil mod bertanda tangan berbeda → harus copot pasang versi Play, dan progres lokal versi lama tidak ikut (progres akun bisa kembali lewat login).

### (c) Nyawa / free answer / hint tak terbatas — **MUNGKIN, tapi ini wilayah sinkron server**

- Tidak ada koin; yang setara adalah `life`, `free_answer_quantity`, dan hint — semuanya di dalam `GameData`.
- Nilai hidup di cache lokal, tetapi `GameData` **diambil dari server (`getGameData`) dan disinkronkan dengan `game_token` terenkripsi**. Mengubah cache lokal berisiko ditimpa sinkron berikutnya; mengubah token butuh kunci enkripsi token (ada di kode Dart, belum dipulihkan — perlu blutter/Frida).
- Putusan jujur: **belum terverifikasi bisa** — perlu RE lanjutan atas format/kunci `game_token` dan perilaku server (apakah server memvalidasi kewajaran nilai). Jangan dijanjikan sebagai toggle jadi sebelum itu dibuktikan. Ini berbeda dari Bunker/Diamond yang datanya terbukti lokal.

### (d) Unlock semua level — **KEMUNGKINAN BESAR BISA (lokal)**

- Gerbangnya lokal: app sendiri memeriksa "max unlocked level" di perangkat, daftar level + soal sudah lengkap di aset/DB lokal.
- Jalur gabung: ubah penanda level terbuka/progres lokal maksimum. Risiko: progres adalah bagian dari `GameData` tersinkron — nilai hasil ubahan bisa ikut terkirim/tertimpa saat login sinkron. Aman untuk pemakaian offline/tanpa login; perilaku persisnya perlu uji dinamis.

### (e) Hapus iklan — **BISA (lokal)**

- Iklan murni AdMob dari lapisan Dart (`google_mobile_ads`) + banner kustom server. Menonaktifkan pemuatan iklan di lapisan gabungan (blokir inisialisasi/metode muat iklan, atau putuskan App ID AdMob di manifest + cegah kanal `plugins.flutter.io/google_mobile_ads`) adalah pola standar dan lokal.
- Efek samping yang harus diterima: bantuan huruf & kunci jawaban **didapat dari iklan rewarded** — menghapus iklan membunuh sumber bantuan itu (menu mod harus menggantinya, mis. tombol bantuan gratis di panel — itu perubahan perilaku, bukan sekadar hapus iklan).
- Banner kustom server berhenti tampil, tidak ada dampak gameplay.

### Ringkasan kelayakan

| Fitur mod | Bisa? | Jalur | Risiko utama |
|---|---|---|---|
| Tampilkan jawaban | Ya | Gabung APK, baca DB lokal | Rendah |
| Floating menu berlogo | Ya | Overlay WindowManager (gabung APK) | Jangan pakai view DecorView (pelajaran Bunker) |
| Unlock semua level | Kemungkinan besar | Ubah penanda progres lokal | Ditimpa sinkron akun |
| Life/free answer/hint ∞ | Belum terverifikasi | Perlu pecahkan `game_token` + uji validasi server | Server menimpa / memvalidasi |
| Hapus iklan | Ya | Matikan lapisan AdMob di gabungan | Rewarded mati → bantuan harus diganti dari menu |

## 10. Batasan analisis

- Analisis statis murni. Password ZIP dan kunci `game_token` **belum** dipulihkan: keduanya tidak berbentuk string polos di `libapp.so` (password teruji negatif atas 12.491 string + kandidat manual; serangan known-plaintext bkcrack negatif untuk PNG/JPEG/WebP/JXL). Pemulihan keduanya adalah pekerjaan RE Dart tahap berikutnya (blutter untuk peta kelas/fungsi snapshot hash `ace654289f…`, atau Frida di perangkat untuk menangkap password/kunci saat runtime) — tidak dikerjakan di sini sesuai batas waktu tugas.
- Klaim "tidak ada IAP/premium/leaderboard/anti-cheat" berbasis ketiadaan bukti di manifest + dex + seluruh strings Dart; verifikasi dinamis tetap penentu akhir.
- Isi 400 zip tidak dibuka (terenkripsi/ter-encode, lihat §7.2) — identitas "1 zip = 1 soal" disimpulkan dari hitungan (20 folder × 20 = 200 soal reguler, cocok dengan teks aturan game) dan skema DB, bukan dari membuka isinya.
