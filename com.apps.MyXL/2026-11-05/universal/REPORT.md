> Catatan arsip: Bukan versi aplikasi — ini analisis LOG myXL 5 Nov 2026 (folder memakai tanggal log).

# Analisis Log — myXL + Mini-App Short Drama

**Tanggal analisis:** 5 Nov 2026
**Sumber:** `20261105203242318.log` (162.183.880 B, 1.090.441 baris, dari `20261105203242318_1_xbn2.zip`)
**Metode:** statis (grep atas log). Tanpa akses perangkat, tanpa replay.

## Ringkasan sesi

| Item | Fakta |
|---|---|
| Aplikasi | `com.apps.MyXL` (Firebase: `com.apps.MyXL`, Crashlytics aktif) |
| Perangkat | POCO "duchamp" (POCO X6 Pro), jaringan 4G (`networkInfo":"4G"`) |
| Rentang log | **20:32:42 – 20:39:59 WIB, 5 Nov 2026** (±7 menit 17 detik) |
| Mini-app | Short Drama `2102020221203254` (Griver/Alipay container, `hybrid.alipay-eco.com`), bundle `.amr` v1.0.380 diunduh dari `cdn-myxl-superapp.marmot-cloud.com` |
| Crash | **Tidak ada** (`FATAL EXCEPTION`: 0) |
| Video | **Tidak ada video diputar** (`m3u8`: 0; halaman `webviewVideo` tidak pernah dibuka) |

## Alur pemakaian

Pengguna membuka mini-app Short Drama dan **hampir sepanjang sesi diam di halaman utama** (`pages/main/index`, 3.787 kemunculan). Kunjungan singkat: `rewards`, `profile`, `collect` (masing-masing 5x). API home dipanggil berulang: `shortDramaList`, `latestOnline`, `guessYouLike`, `tagList`, `userInfo`, `homePopup`, `externalBanner`, `lastWatchEpisode`, `bannerMenuList`, `channel/v1/list`.

## Temuan 1 — AppsFlyer gagal sepanjang sesi (analitik saja)

- **±2.690 `HttpException` AppsFlyer** (`com.appsflyer...HttpException: Failed/Unable`), mulai **20:32:43** — satu detik setelah sesi mulai — sampai akhir sesi (jeda 20:35–20:36).
- Endpoint: `1curle.inapps.appsflyersdk.com` dan `1curle.launches.appsflyersdk.com` (event/launch analytics).
- Dampak: **hanya analitik/atribusi yang tidak terkirim**. Aplikasi tetap jalan normal; ini bukan penyebab gangguan yang dirasakan pengguna.
- Dugaan: endpoint AppsFlyer tidak terjangkau dari koneksi ini (kemungkinan diblokir di level perangkat/jaringan — pengguna memakai HP root — atau memang tidak bisa dijangkau). Tidak bisa dipastikan dari log saja.

## Temuan 2 — Jaringan putus total di ±20:39:10 (50 detik terakhir)

- Error `network error` pertama muncul **20:39:10.097**. Sebelum itu: **nol** kegagalan request mini-app.
- Dalam ±50 detik terakhir: **443 `my.request.fail` (error=12, "network error")**, semuanya di menit 20:39:
  - `napi.bangdao-tech.com/monitor/collect`: **328** (74% dari semua kegagalan)
  - `napi.bangdao-tech.com/monitor/bind`: 20
  - `prod.shortdrama.space` (userInfo, tagList, shortDramaList, latestOnline, lastWatchEpisode, homePopup, guessYouLike, externalBanner): **10 kali masing-masing**
  - `prod.shortdrama.space` (mpEventTracking/report, bannerMenuList, channel/v1/list): **5 kali masing-masing**
- Pola `monitor/collect` 328x dalam <50 detik = **retry storm telemetri**: setiap request gagal memicu laporan monitoring, laporannya sendiri gagal, lalu dicoba lagi berulang-ulang.
- Kesimpulan: **bukan server Short Drama yang down** — kegagalan menimpa banyak host yang tidak berhubungan sekaligus (bangdao, shortdrama.space, appsflyer), dan mulai tiba-tiba setelah 6,5 menit normal. Ini pola **jaringan perangkat putus** (sinyal 4G hilang/berpindah, atau aplikasi ditutup/dibekukan) di akhir sesi.

## Temuan 3 — Noise inisialisasi (bukan error)

- `ClassNotFoundException: okhttp3.OkHttpClient` (285x) + `com.alibaba.griver.dark.resource.R` (34x), `SecurityGuardManager` (3x), `ANROptimizeHelper` (2x): container Griver/Alipay melakukan probe class opsional saat init. Bukan crash, bukan penyebab gangguan.
- `JSONException` (16x), `NullPointerException` (2x), `IllegalArgumentException: pins` (8x): kecil, tidak berkorelasi dengan kegagalan jaringan.
- Satu baris `No Network` di 20:32:42.666 (awal sesi, sekali saja) — kemungkinan log init SDK, bukan kondisi nyata, karena API setelahnya berjalan normal sampai 20:39.

## Yang TIDAK bisa disimpulkan dari log ini

- Apakah video drama bisa diputar / unlock berfungsi — tidak ada video yang dibuka dalam sesi ini.
- Penyebab pasti putusnya jaringan 20:39:10 (sinyal, perpindahan jaringan, aplikasi dibunuh sistem, atau HP terkunci) — log tidak mencatat peristiwa sistem itu.
- Apakah AppsFlyer diblokir sengaja (hosts/adblock) atau sekadar tidak terjangkau — perlu cek konektivitas langsung ke `1curle.inapps.appsflyersdk.com`.

## File kerja

- Log asli + laporan ini: `~/workspace/rea-log-20261105/`
- Bundle mini-app terkait (REA sebelumnya): `~/workspace/rea-shortdrama-myxl/REPORT.md`
