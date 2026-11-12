> Catatan arsip: Bukan APK mandiri — paket mini-program Short Drama (uid `2102020221203254`, v1.0.380) di dalam myXL SuperApp.

# REA — Short Drama Mini-App (myXL SuperApp)

**Tanggal analisis:** 5 Nov 2026
**Sumber:** `2102020221203254-1_0_380-whole-whole_0_vexu.amr` (1.361.725 B, dikirim user 5 Nov 2026 20:42 WIB)
**Metode:** statis saja (ekstrak + grep string). Tanpa runtime, tanpa akun, tanpa network call.

## Verdict

Ini **bukan APK dan bukan aplikasi mandiri**. Ini paket **mini-program Alipay AppX/Nebula** — aplikasi drama pendek ("Short Drama") yang berjalan **di dalam myXL SuperApp** (XL Axiata), versi **1.0.380**, app ID **2102020221203254**.

Bukti identitas:
- `Manifest.xml`: `<uid>2102020221203254</uid>`, `<version>1.0.380</version>`
- `appConfig.json`: `"sourceSite":"MYXL_SUPERAPP"`, `"newSourceSite":"GNETW7CN"`, `"acquireSite":"MYXL_SUPERAPP"`
- `index.worker.js`: string `MYXL_SHORTDRAMA` (40x), `myXL` (53x)
- `index.html`: bootstrap `af-appx` + `AlipayJSBridge`, worker `index.worker.js`
- `api_permission`: `validDomain: ["2102020221203254.hybrid.alipay-eco.com"]`

## Inventaris paket

| Item | Isi |
|---|---|
| Arsip luar | ZIP berisi `2102020221203254.tar` (4.038.656 B) + `CERT.json` (hash SHA-256 per file) + `Manifest.xml` |
| Hasil ekstrak | 58 file, 4,0 MB |
| Kode | `index.js` 1.135.450 B (UI/React), `index.worker.js` 2.131.083 B (logika + API) |
| Konfigurasi | `appConfig.json`, `manifest.json`, `package.json` (versi 1.0.380), `tabBar.json`, `api_permission` |
| Aset | ~50 gambar di `static/` (ikon tab, koin, tiket, voucher, dsb.) |
| Halaman | 30 halaman: `main`, `home/list`, `library`, `search`, `vip`, `faq`, `purchaseHistory`, `myCoins`, `ticketsBalance`, `rewardCoinsHistory`, `ticketsHistory`, `myVouchers`, `purchaseState`, `collect`, `viewHistory`, `rewards`, `ad`, `feedback`, `rewards/surveyProfile`, `profile`, `help`, `agreement`, `balanceAgreement`, `language`, `completeYourProfile`, `chooseYourDramaTaste`, `webviewVideo`, `webview`, `testApi` |

## Backend & domain

API utama: **`https://prod.shortdrama.space`** (25 referensi di worker).

Domain lain yang diizinkan (`api_permission` → `httpRequest.allowedDomain` + `Webview_Config.allowedDomain`):
- Video: `aws-video.shortdrama.space`, `video.shortdrama.space`, `oss-image.shortdrama.space`, `static.shortdrama.space`
- Pembayaran: `checkout.antom.com` (Antom — checkout Ant Group), `auth-cdn.truemoney.com` (TrueMoney)
- Platform/SDK: `napi.bangdao-tech.com`, `psm.bangdao-tech.com`, `test-napi.bangdao-tech.com` (Bangdao Tech), `unite-oss.bangdao-tech.com`
- Iklan/analitik: `google-analytics.com`, `pagead2.googlesyndication.com`, `effectivecpmnetwork.com`, `aompan.infergridplay.com`, `doalic.infergridplay.com`, `celino.infergridplay.com`, `krelink.top`, `reelsworld.space`, `racha.lumeflux.xyz`
- Font: `static.shortdrama.space` (DelaGothicOne, D-DIN-Bold), `at.alicdn.com`, `cdn2.dcloud.net.cn`

Fungsi API yang teridentifikasi di `index.worker.js` (nama fungsi; path REST-nya dibangun dinamis dari `baseUrl`, jadi tidak bisa dienumerasi statis): `getUserInfo`, `getOrderList`, `createOrder`, `createOrderForTicket`, `unlockEpisodeByTicket`, `getEpisodesUnlockProgress`.

## Monetisasi

- **Mata uang ganda:** koin + tiket. Top-up paket koin: `TOPUP_PKG_COIN_1/10/100/1000` (gambar paket di `static/`).
- **E-wallet lokal di kode:** GoPay (32x), DANA (5x), OVO (2x) — checkout lewat Antom + TrueMoney.
- **Unlock episode:** per episode pakai tiket/koin (`unlockEpisodeByTicket`, `createOrderForTicket`), ada paket "unlock semua episode tersisa" (`unlocked all the remaining episodes!`).
- **VIP:** halaman `vip` + komponen `VipBenefits`, `PayBox`, `VipIcon`.
- **Hadiah gratis:** check-in harian, nonton iklan (klaim koin), milestone nonton: 1/10/30/60 menit → 10 koin tiap milestone, survei profil (gender/taste) berhadiah koin.
- **Lokal:** locale `id` (48x) + `id-ID`, string `Rp` — pasar Indonesia.

## Video

- Format: HLS (`.m3u8`) dan MP4 dkk. — terdeteksi lewat regex pendeteksi ekstensi di worker (`mp4|mpg|...|m3u8`).
- Video di-host di `aws-video.shortdrama.space` / `video.shortdrama.space` (AWS).
- Halaman pemutar: `webviewVideo` (dan `webview` umum).
- **Tidak ditemukan indikasi DRM** (tidak ada string Widevine/FairPlay/DRM) dalam bundle statis — tapi ini BUKAN bukti tidak ada DRM: URL video diambil dari API saat runtime dan proteksinya (kalau ada) hidup di server/CDN, tidak kelihatan dari bundle.

## Auth & sesi

- Token-based: `accessToken` + `refreshToken` (dengan decorator/refresh otomatis), header `Authorization`.
- Login lewat myXL (host app) — `getUserInfo` via `my.canIUse("getOpenUser...")` (Alipay JSAPI user info).
- Request API memakai penandatanganan (fungsi `sign`, 83 pemanggilan) — detail mekanisme tidak dianalisis lebih dalam di laporan ini.

## Keamanan (observasi statis)

- **Tidak ada cleartext HTTP**: grep `http://` di `index.js` + `index.worker.js` = 0 hasil. Semua host memakai HTTPS.
- **Tidak ada bukti repack/mod di paket ini**: `CERT.json` berisi hash per file (tanda tangan paket), struktur konsisten dengan build mini-program resmi (Alipay AppX, uview-ui, dcloud). Tidak ada jejak patch, nama modder, atau string aneh.
- **Izin JSAPI luas** (`api_permission` → `JSAPI_List`): termasuk audio foreground, `getExtConfig`, translate, dsb. — wajar untuk mini-program, tapi permukaan API-nya besar.
- **Domain iklan pihak ketiga banyak** (infergridplay, effectivecpmnetwork, krelink, reelsworld, lumeflux) — pelacakan/iklan lewat beberapa jaringan sekaligus.
- **Batasan:** analisis statis tidak bisa membuktikan keamanan server (validasi unlock, harga, dan proteksi video semua di sisi `prod.shortdrama.space`), dan tidak bisa memastikan apakah konten dramanya berlisensi.

## Yang TIDAK bisa disimpulkan dari bundle ini

- Apakah unlock/bypass mungkin (butuh runtime + akun myXL; semua validasi di server).
- Apakah video bisa diunduh langsung (URL episode hanya ada saat runtime, setelah auth + unlock).
- Nama brand komersial aplikasinya di Play Store (bundle ini hanya dikenal sebagai `MYXL_SHORTDRAMA` / app ID 2102020221203254 di dalam myXL).

## File kerja

- Paket asli + hasil ekstrak: `~/workspace/rea-shortdrama-myxl/`
- Laporan ini: `~/workspace/rea-shortdrama-myxl/REPORT.md`
