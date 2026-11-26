# REA — Istana Virtual (com.istana.akun) 0.1.28

- **Aplikasi:** Istana Virtual
- **Package:** `com.istana.akun`
- **Versi:** 0.1.28 (versionCode 1028), compileSdk 34, targetSdk 34, minSdk 24
- **Ukuran APK:** 2.208.861 byte
- **SHA-256 APK:** `e422c604b6ff82e007d4b8a1c8ffb858eebd2e43f9dfffcee1495ef5c1f160e8`
- **Signer:** self-signed, CN=Istana Akun, O=Istana, C=ID
  - SHA-256 cert: `58c5ebe7765dd8950635b24f69ca6a93925eb2cc0dd15f395616280c57ae4175`
  - SHA-1 cert: `b7d571841635a9d731eacfd7ca649d997141ee6b`
  - APK Signature Scheme v2 (bukan v3)
- **Tanggal dump:** 26 Nov 2026
- **Metode:** statis saja (APK tidak pernah di-install/dijalankan)

## Ringkasan

Istana Virtual adalah **kontainer WebView multi-akun** untuk 16 layanan web
(AI, sosmed, email) — tiap layanan dibuka di WebView-nya sendiri dengan
profil terisolasi per akun, sehingga satu layanan bisa login banyak akun
sekaligus. Akses aplikasi digembok **lisensi server-side** (aktivasi +
validasi berkala ke Vercel, diikat ke `android_id` perangkat). Ada
self-updater yang mengunduh APK baru dan memverifikasi SHA-256 sebelum
install. Tidak ada game, tidak ada native lib, tidak ada aset konten —
seluruh isi aplikasi adalah UI + logika lisensi/akun/update.

Versi ini adalah versi terbaru di kanal update resmi saat dump dibuat
(24 Nov 2026, `android-latest.json` menunjuk SHA-256 yang sama persis
dengan APK ini).

## Katalog layanan (16, hardcoded di `Services.<clinit>`)

| Kategori | Layanan | URL |
|---|---|---|
| AI | Flow | https://flow.google |
| AI | Suno | https://suno.com |
| AI | ElevenLabs | https://elevenlabs.io |
| AI | Claude | https://claude.ai |
| AI | ChatGPT | https://chatgpt.com |
| AI | Gemini | https://gemini.google.com |
| AI | Dola | https://www.dola.com/ |
| AI | Muse AI | https://muse.ai |
| AI | Cue by Manus | https://cue.im |
| SOSMED | YouTube | https://youtube.com |
| SOSMED | Instagram | https://instagram.com |
| SOSMED | Threads | https://www.threads.com/ |
| SOSMED | Facebook | https://facebook.com |
| AKUN | Gmail | https://mail.google.com |
| AKUN | Outlook | https://outlook.live.com |
| AKUN | Proton Mail | https://mail.proton.me |

Konstruktor `Service(id, nama, url, kategori, singkatan 2 huruf, <int>,
logoResId)` — singkatan dipakai sebagai avatar teks bila logo gagal dimuat
("logo akun … gagal dimuat").

## Arsitektur

- Satu `classes.dex` (286.896 byte, dex 037): 3.005 string, 765 type,
  2.228 method, 951 field, 395 class — 10 di antaranya milik aplikasi
  (`com.istana.akun.*`), sisanya AndroidX/Kotlin stdlib. R8 dipakai
  (nama class/helper ter-obfuscate: `t3`, `h3`, `q6`, `p0`, `k0`…),
  tapi nama class aplikasi + string tidak di-obfuscate.
- **Tanpa native lib** (`lib/` kosong), **tanpa aset konten**
  (hanya `assets/dexopt/baseline.prof*`). UI dibangun programatik
  (LinearLayout/TextView/Button/PopupWindow/Dialog di `MainActivity` +
  `Ui`); `res/` hanya berisi 40 file logo/ikon (vektor + PNG).
- Satu activity: `MainActivity` (launcher). Provider: FileProvider
  (`com.istana.akun.fileprovider`) + `androidx.startup`.
- Permission: INTERNET, WRITE_EXTERNAL_STORAGE (maxSdk 28),
  REQUEST_INSTALL_PACKAGES (untuk install update sendiri).
- Preferensi `istana_virtual`: tema terang/gelap, bahasa, layout
  tab/list, gaya kartu (glass/clay/bubble/aurora).

## Lisensi (server-side)

- Endpoint (Vercel):
  - `POST https://istana-akun.vercel.app/api/license/activate`
  - `POST https://istana-akun.vercel.app/api/license/validate`
- Device binding: `Settings.Secure.android_id` (disimpan di
  `LicenseManager.c`).
- Body validate: `{licenseKey, deviceId, deviceInfo}` dengan
  `deviceInfo = {deviceType: "Android", hostname: <Build.BRAND>,
  model: "<BRAND> <MODEL>"}`.
- Respons: `status` (`active`/`revoked`/`expired`), `plan`,
  `expires_at` (ISO UTC `yyyy-MM-dd'T'HH:mm:ss[.SSS]'Z'`), `lifetime`.
  HTTP 403 + pesan mengandung "dinonaktifkan"/"dicabut"/"revoked"/
  "tidak aktif" → lisensi dicabut; 410 → kedaluwarsa.
- State lisensi tersimpan sebagai JSON
  `{key, plan, expires_at, lifetime, last_validated_at, adverse?}`
  di CryptoStore key `"license-state"` (terenkripsi, lihat bawah).
- Harga di dialog aktivasi: **Rp25.000 / Rp99.000 / Rp149.000**
  (placeholder kode: `ISTANA-XXXX-XXXX-XXXX`).
- Beli lisensi via WhatsApp: https://wa.me/6285799821453
  ("Halo, saya mau beli lisensi Istana Virtual").
- Kontak lain: Telegram https://t.me/heyetherium,
  Instagram https://www.instagram.com/istana.ai.

## Kripto lokal (`CryptoStore`)

- AndroidKeyStore, alias `"istana-akun-" + nama`, **AES-256, GCM,
  NoPadding**, `setRandomizedEncryptionRequired(true)`.
- Format simpan di SharedPreferences `"istana-akun-secrets"`:
  `Base64(IV) + "." + Base64(ciphertext)`; baca: split `"."`,
  GCMParameterSpec tag 128-bit, `AES/GCM/NoPadding`.
- Key yang dipakai: `"license-state"` (state lisensi),
  `"accounts"` (daftar akun). Kunci TIDAK hardcoded di APK —
  dibuat di Keystore perangkat, jadi data terenkripsi tidak bisa
  dibuka di perangkat lain.

## Akun (`AccountStore`)

- Daftar akun = JSONArray `[{id, serviceId, name, addedAt, favorite}]`,
  tersimpan terenkripsi (key `"accounts"`).
- Fitur: tambah akun (+), favorit (★/☆ toggle), hapus akun
  ("Akun … akan dihapus dari daftar, dan Anda akan keluar dari akun
  ini"), cari akun, "+ %d akun lainnya".
- Tiap akun dipasang ke WebView-nya sendiri via
  `WebViewCompat.setProfile(webView, <profile>)` (AndroidX
  MULTI_PROFILE) — sesi/cookie terisolasi antar akun. Bila perangkat
  tidak mendukung: "MULTI_PROFILE tidak didukung — sesi tidak
  terisolasi".
- WebView: JavaScript + DOM storage + database aktif, wide viewport,
  multiple windows, cookie pihak ketiga diterima, `WebViewClient` +
  `WebChromeClient` sendiri, `DownloadListener` sendiri.

## Jembatan JS + unduhan (`IstanaDownload`)

- `addJavascriptInterface(..., "IstanaDownload")` dengan callback
  `onBlobBase64(base64, mime)` / `onBlobError()`.
- Unduh file dari halaman web: injeksi JS `fetch(url)` → blob →
  FileReader → base64 → native; atau data-URL langsung.
- Unduhan diteruskan ke `DownloadManager` dengan header
  `User-Agent` + `Cookie` dari WebView, tujuan folder Downloads.
- Ekstensi ditebak dari magic bytes (`RIFF/WAVE`, `OggS`, `ftyp`,
  `%PDF`, `PNG`) + peta MIME↔ekstensi (.mp3/.m4a/.ogg/.wav/.webm/
  .mp4/.png/.jpg/.pdf, fallback `.bin`).

## Self-updater (`Updater`)

- Cek: `GET https://istana-akun.vercel.app/updates/android-latest.json`
  → `{version, version_code, url, sha256?, notes?}`; update bila
  `version_code > 1028`.
- Kanal ini LIVE saat dump (24 Nov 2026): versi 0.1.28/code 1028,
  sha256 sama dengan APK ini, notes "Download audio langsung bernama
  .mp3.", URL unduhan
  `https://istana-akun.vercel.app/downloads/istana-akun-android-arm64.apk`
  (nama file menyebut arm64, tapi APK ini tanpa native lib).
- Unduh di thread latar via `HttpURLConnection`, lalu **verifikasi
  SHA-256 file** (`Updater.d`, perbandingan case-insensitive)
  sebelum install; install via FileProvider + `ACTION_VIEW`
  `application/vnd.android.package-archive`.

## Proteksi / keamanan (hasil scan)

- **Tidak ada** deteksi root, emulator, Xposed/Frida, certificate
  pinning, Play Integrity, atau SafetyNet (scan keyword dex bersih —
  hit "root" hanya string konfigurasi FileProvider).
- Validasi lisensi sepenuhnya server-side; state lisensi lokal
  terenkripsi AES-GCM di Keystore (aman dari baca mentah).
- Update APK terverifikasi SHA-256 sebelum install (bagus).
- `allowBackup=true` di manifest (data app bisa di-backup via adb).
- Tidak ada kredensial/API key hardcoded yang ditemukan di dex
  (server Vercel + nomor WA + handle sosmed adalah satu-satunya
  endpoint/kontak).

## Isi folder dump ini

- `REPORT.md` — laporan ini
- `apk-info.txt` — badging aapt + SHA-256 + signer + isi kanal update
- `file-list.txt` — daftar isi APK + ukuran
- `manifest.xmltree.txt`, `resources.txt` — manifest + resource table
- `strings.txt`, `classes.txt`, `methods.txt`, `fields.txt`,
  `app_classes.txt` — dump tabel dex (parser `dex_parse.py`)
- `rea_deep.txt` — disassembly `Services.<clinit>`,
  `ServiceCategory.<clinit>`, `CryptoStore`, `LicenseManager`
- `rea_deep2b.txt` — disassembly `DeviceInfo`, `AccountStore`,
  `Updater`, string/API per method `MainActivity`, info signer,
  scan proteksi
- `dex_parse.py`, `rea_deep.py`, `rea_deep2.py` — script analisis
  yang dipakai (androguard 4.1.4)
- `extract/` — seluruh isi APK hasil unzip (AndroidManifest.xml,
  classes.dex, resources.arsc, res/, META-INF/, kotlin/, assets/)
