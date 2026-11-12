# Laporan Dump & REA — 3 File Google Drive

Tanggal analisis: 21 Oktober 2026 (WIB). Metode: unduh resmi via gdown dari link user →
ekstraksi ZIP penuh → apktool 2.10.0 (decode manifest/resources/smali) → JADX 1.5.1
(dekompilasi DEX → Java) → strings/readelf pada DEX & library native.
Batasan VM: tidak ada Ghidra/IDA, jadi analisis native berhenti di level
ELF header/strings/symbol — bukan pseudocode.

Lokasi hasil:

- Unduhan asli: `~/workspace/rea-drive-dump/downloads/`
- Per aplikasi: `extracted/<app>/bundle/` (APK hasil bongkar .apks),
  `extracted/<app>/raw-base/` (isi base.apk mentah), `extracted/<app>/apktool/`
  (manifest terbaca + res + smali), `extracted/<app>/jadx/` (sumber Java hasil dekompilasi)

---

## Ringkasan cepat

| # | File Drive | Aplikasi | Package | Versi | Ukuran unduhan |
|---|------------|----------|---------|-------|----------------|
| 1 | `Radar Cuaca_2.5.9.apks` | Weather Radar (radar cuaca) | `com.weatherradar.liveradar.weathermap` | 2.5.9 (code 180) | 25.681.871 byte |
| 2 | `MonitorWorld_1.3.0.apks` | MonitorWorld (monitor peristiwa global) | `app.monitorworld` | 1.3.0 (code 17) | 8.358.043 byte |
| 3 | `Ticarisk_1.7.apks` | Ticarisk (pembungkus WebView situs ticarisk.com) | `com.mare.sal` | 1.7 (code 8) | 3.427.895 byte |

Ketiganya: aplikasi Kotlin, minSdk 24, targetSdk 35/36, format bundle `.apks`
(base + split config), memakai Firebase, dan **semuanya dilindungi PairIP**
(`com.pairip.licensecheck.LicenseActivity` ada di ketiga manifest). Tidak ada
satu pun yang memakai root/Xposed — semua fitur berjalan sebagai aplikasi biasa.

---

## 1. Radar Cuaca — "Weather Radar"

**ID unduhan Drive:** `1omYckQ1JxlR7lP8A3CKHUI7QHWOsZw_3`

### Identitas

- Label: "Weather Radar" (`@string/app_name`)
- Package: `com.weatherradar.liveradar.weathermap`
- versionName 2.5.9, versionCode 180, minSdk 24, targetSdk 35
- base.apk 38.695.267 byte (2 DEX: classes.dex 8,8 MB + classes2.dex 9,1 MB)
- Izin penting: lokasi presisi + lokasi latar belakang, notifikasi,
  `USE_FULL_SCREEN_INTENT`, getar, wake lock, rangkaian izin Ad Services.

### Isi dump

- Bundle: `base.apk`, `split_config.arm64_v8a.apk`, `split_config.xxhdpi.apk`
- raw-base: 4.076 file (±54 MB); apktool: 28.354 file; jadx: 23.675 file
  (19.335 berkas .java, 199 di antaranya kode milik aplikasi sendiri)
- Split arm64 berisi 3 library native (ELF64 AArch64):
  `libpairipcore.so` (609 KB, mesin proteksi PairIP),
  `libsigner.so` (1,0 MB, cek tanda tangan), `libdatastore_shared_counter.so` (7 KB)
- `assets/`: 42 file ±9,7 MB — termasuk `audience_network.dex` (iklan Facebook)
  dan ±16 file bernama acak 16 karakter bertipe "data" (kontainer terenkripsi,
  ciri khas PairIP), `Privacy.html`, skrip jembatan Adjust (`adjust*.js`).

### Daftar fitur (dengan bukti)

Radar & cuaca inti:

1. **Radar hujan/peta cuaca langsung** — TileServer `api.weather.com/v3/TileServer`
   + produk vektor 601/603, paket `ui/maps/`, string grup `radar_*`, `timeline_*` (59 string).
2. **Cuaca saat ini** — `ui/details/current/CurrentActivity`, API AccuWeather
   `currentconditions/v1/`.
3. **Ramalan per jam 72 jam & harian 15 hari** — endpoint AccuWeather
   `forecasts/v1/hourly/72hour/`, `forecasts/v1/daily/15day/`.
4. **Detail angin** — `ui/details/wind/WindActivity`, model `data/model/accurate/weather/daily/wind`.
5. **Kualitas udara (AQI) + polutan** — `ui/details/aqi/QualityActivity`,
   API `api.waqi.info/feed/geo`, string grup `pollutants_*`.
6. **Pencarian lokasi & geocoding** — `ui/search/SearchLocationActivity`,
   AccuWeather geoposition/topcities + Mapbox `geocoding/v5/mapbox.places`.
7. **Lokasi saya** — `ui/mylocation/MyLocationActivity`.

Bencana & lingkungan:

8. **Fire Center: risiko kebakaran hutan, peta titik api, berita api** —
   string grup `fire_center_*` ("Closest active fire is ... away", "Fire Map",
   "Fire News"), model `ui/maps/ibm/model/fires`.
9. **Gempa bumi + skala dampak magnitudo** — string `magnitude_1..9`.
10. **Pelacak badai tropis/siklon** — `api.weather.com/v2/tropical/currentposition`
    + `projectedpath`, model `ui/maps/ibm/model/tropical`, string
    `iap_hurricane_tracker`, `lbl_des_cyclone_iap`.
11. **Indeks UV, matahari & bulan (fase bulan, sunrise)** — string
    `lbl_uv_index*`, `lbl_sun_moon`, `lbl_moon_phase`, `lbl_full_moon/new_moon`.

Notifikasi & widget:

12. **Peringatan cuaca (alerts) + alert untuk lokasi favorit/bookmark** —
    string `lbl_alerts`, `lbl_alerts_for_bookmarks`, `WeatherAlarmReceiver`.
13. **Pengingat acara berbasis cuaca** — string `radar_create_reminder`
    ("Create notifications for your events, get weather forecasts at the time
    your activity takes place").
14. **Notifikasi layar penuh (FSI)** — `todays/dialog/NotificationFSIActivity`,
    izin `USE_FULL_SCREEN_INTENT`.
15. **"Today weather news"** — berita cuaca harian; string izin overlay di
    `radar_description_today_weather_news_permission`; receiver
    `todays/NotificationNewReceiver`, `ScreenStateReceiver`.
16. **Belasan widget layar utama** — provider: Daily 4x2, Hourly 4x2/4x3,
    Info 4x2/4x4, seri SS 1x2/3x3/4x2 (`widgets/view/WidgetProvider*`),
    `WidgetConfigActivity`, tema widget (`theme/ThemeWidgetsActivity`,
    `data/model/wallpaper`), service data widget (`WidgetDataService` dkk.).

Lainnya:

17. **Kompas** — string `lbl_compass`/`compass`.
18. **Kalkulator** — string `lbl_calculator`.
19. **Premium/berlangganan** — `ui/premium/PremiumActivity`, `PremiumSaleActivity`,
    uji gratis 3 hari, login 5 hari berhadiah fitur premium
    (`lbl_day_sign_gift`), langganan dikelola Qonversion (`api.qonversion.io`)
    + Play Billing.
20. **Login akun** — layout `acivity_login.xml`, string `lbl_already_signed`.
21. **Monetisasi iklan berlapis** — AdMob + Facebook Audience Network
    (`assets/audience_network.dex`, layout `ad_native_banner_facebook.xml`) +
    mediasi Amobear (`analytics.amobear.com`, `core.adslib`), AppsFlyer, Adjust.
22. **Push FCM** — `config/fcm/MyFirebaseMessagingService`.
23. **Berbagi aplikasi & promosi** — `ui/share/ShareAppActivity`,
    `ui/promotion/PromotionActivity`, `ui/previews/PreviewActivity`.

### Catatan teknologi & proteksi

- Kotlin native (bukan Flutter/WebView), Room DB, WorkManager, arsitektur
  paket rapi (`data/model/accurate/...`, `ui/maps/ibm/...`).
- **PairIP**: `libpairipcore.so` + `LicenseActivity` + aset terenkripsi —
  sebagian kode/metode tervirtualisasi; dekompilasi JADX berhasil untuk
  mayoritas kelas (nama paket sendiri terbaca jelas), tetapi menyalin kode
  mentah ke aplikasi lain tidak realistis — fitur harus **ditulis ulang**.
- Sumber data berbayar/berkunci: AccuWeather, The Weather Company, Mapbox,
  WAQI — kunci API tidak ditemukan utuh di resources (google_api_key
  ter-redaksi oleh apktool), jadi endpoint-nya tidak bisa dipakai ulang begitu
  saja dari dump ini.

### Kelayakan porting ke Hozin Tools

| Fitur | Nilai porting | Catatan |
|---|---|---|
| Dashboard cuaca (saat ini/jam/harian) | **Tinggi — bisa ditulis ulang** | Pakai API gratis (Open-Meteo/BMKG); pola 1 activity BaseActivity cukup |
| Daftar gempa + magnitudo | **Tinggi** | API BMKG/USGS gratis; relevan untuk user Indonesia; Hozin Tools belum punya |
| Radar hujan (tile peta) | Sedang | Tile gratis ada (RainViewer); tile weather.com butuh kunci |
| AQI/polutan | Sedang | Open-Meteo Air Quality gratis; WAQI butuh token |
| Widget cuaca layar utama | Sedang | AppWidgetProvider murni Android, tanpa root; usaha menengah |
| Peringatan cuaca lokal | Sedang | WorkManager + notifikasi lokal bisa; FCM butuh server |
| Fase bulan/sunrise | Mudah | Perhitungan lokal murni |
| Kompas | Mudah | Sensor bawaan |
| Fire Center | Rendah–sedang | Data titik api (NASA FIRMS) butuh kunci & konteks global |
| Pelacak badai tropis | Rendah | Data khusus weather.com |
| Premium/iklan/login | Tidak relevan | Model bisnis aplikasi asal, bukan fitur alat |

Tidak ada fitur Radar Cuaca yang butuh root/Xposed.

---

## 2. MonitorWorld

**ID unduhan Drive:** `1MDP-qGHJWche8jfFZAmUvLvPT5S0sXSN`

### Identitas

- Label: "MonitorWorld"
- Package: `app.monitorworld`
- versionName 1.3.0, versionCode 17, minSdk 24, targetSdk 36
- base.apk 16.101.128 byte (3 DEX)
- Izin: lokasi kasar/presisi, notifikasi, `RECEIVE_BOOT_COMPLETED`, FGS, getar.
- Situs: `monitorworld.app`; backend API:
  `https://backend-kappa-gold-23.vercel.app/api` (ditemukan di DEX).

### Isi dump

- Bundle: `base.apk`, split arm64 (hanya `libandroidx.graphics.path.so` +
  `libdatastore_shared_counter.so` — tidak ada mesin native khusus),
  split bahasa `in` (Indonesia), split xxhdpi.
- raw-base: 373 file (±17 MB); apktool: 16.565 file; jadx: 14.072 file
  (13.678 berkas .java).
- Kode aplikasi sendiri **sangat ter-obfuscation** (paket huruf tunggal:
  `m6/`, `l/`, `U/`, `G0/`, `E5/`…), tetapi nama di lapisan API/model selamat:
  `app/monitorworld/core/network/api/WorldMonitorApi.java`,
  `core/model/MapLayer.java`, `core/database/MonitorDatabase.java` (Room).

### Daftar fitur (dengan bukti)

Bukti utama: 693 string UI + interface Retrofit `WorldMonitorApi` +
enum `MapLayer` + penerima `DiscountReminderReceiver`.

1. **Peta dunia peristiwa langsung dengan 14 lapisan** (enum `MapLayer` +
   string `map_layer_*`/`map_kind_*`): Conflicts, Conflict Zones, Earthquakes,
   Natural Events, Cyber Threats, Military Flights, Internet Outages,
   Pipelines, Strategic Waterways, Nuclear Facilities, Spaceports,
   Military Bases, Intel Hotspots (+ filter & pencarian di peta).
2. **Konflik/insiden bersenjata** — endpoint `conflict/v1/list-acled-events`
   & `list-ucdp-events` (sumber data ACLED + UCDP), detail insiden berisi
   severity/status/sumber/lokasi + bagikan (`conflicts_*`, 28 string).
3. **Intelijen negara** — `intelligence/v1/get-risk-scores`,
   `get-country-intel-brief`; **Country Intelligence Index (CII 0–100)**,
   daftar wilayah risiko tinggi per negara (AF, CN, IL, IR, RU, UA, US, …),
   sebagian dikunci Premium (`intel_upsell_*`).
4. **Ancaman siber** — `cyber/v1/list-cyber-threats`, detail berisi
   family/type/negara/severity (`cyber_*`).
5. **Gempa bumi** — `seismology/v1/list-earthquakes` (parameter min_magnitude).
6. **Peristiwa alam** — `natural/v1/list-natural-events` (`naturalevents_*`).
7. **Pemadaman internet** — `infrastructure/v1/list-internet-outages`.
8. **Aktivitas militer** — `military/v1/list-military-flights`
   (penerbangan militer langsung) + basis militer & fasilitas nuklir (statis
   di peta) (`military_*`).
9. **Penerbangan sipil: keterlambatan bandara** — `aviation/v1/list-airport-delays`
   (`aviation_*`).
10. **Iklim: anomali iklim** — `climate/v1/list-climate-anomalies` (`climate_*`).
11. **Pasar** — `market/v1/list-market-quotes`, `list-commodity-quotes`,
    `list-crypto-quotes`: ekuitas, komoditas, kripto + detail tren (`markets_*`).
12. **Ekonomi & rantai pasok** — `economic/v1/get-energy-prices`,
    `get-macro-signals`; `supply-chain/v1/get-chokepoint-status`
    (status titik sempit pelayaran), tarif pengiriman, tren tarif dagang,
    aliran perdagangan (`getShippingRates`, `getTariffTrends`, `getTradeFlows`).
13. **Maritim** — `maritime/v1/list-navigational-warnings`.
14. **Kemanusiaan** — `conflict/v1/get-humanitarian-summary`,
    `displacement/v1/get-displacement-summary` (pengungsian),
    `giving/v1/get-giving-summary` (Global Giving) (`displacement_*`, `giving_*`).
15. **Berita** — `news/v1/list-feed-digest`, terjemahan judul berita
    (`alerts_translate_headlines`), `positive-events/v1/list-positive-geo-events`
    (peristiwa positif).
16. **Prediksi** — `prediction/v1/list-prediction-markets`.
17. **Riset** — `research/v1/list-arxiv-papers` + `list-hackernews-items`.
18. **Webcam langsung** — string grup `webcams_*` + menu "Live Webcams".
19. **Citra satelit** — menu "Satellite Imagery" (`more_entry_satellite_imagery`).
20. **Alerts** — daftar peringatan per insiden + push FCM
    (`core/notification/MonitorWorldMessagingService`), pengingat diskon
    (`DiscountReminderReceiver`).
21. **Akun & langganan** — Firebase Auth (email/Google, reCAPTCHA,
    Credential Manager/passkey), langganan via **RevenueCat** (PaywallActivity,
    CustomerCenterActivity, paket annual/bimonthly; string `paywall_*` 100 buah),
    Play Billing + Amazon billing.
22. **Onboarding & pengaturan** — string `onb_*` (148), `settings_*` (45).

### Catatan teknologi & proteksi

- Kotlin + Jetpack Compose (single-activity `app.monitorworld.MainActivity`),
  Room, WorkManager, OkHttp/Retrofit, DataStore.
- Obfuscation R8 berat pada kode sendiri; tidak ada proteksi native selain
  PairIP license check.
- **Seluruh data berasal dari backend privat pengembang** (Vercel). Tanpa
  backend itu, aplikasi ini kosong — yang bisa di-porting adalah *konsep &
  tampilannya*, datanya harus dicari dari sumber publik lain.

### Kelayakan porting ke Hozin Tools

| Fitur | Nilai porting | Catatan |
|---|---|---|
| Peta peristiwa + lapisan (gempa, peristiwa alam) | **Sedang–tinggi (konsep)** | Data publik tersedia: USGS (gempa), NASA EONET (alam), GDACS; perlu WebView peta (Leaflet) — cocok dengan pola Hozin Tools |
| Daftar gempa global | **Tinggi** | USGS API gratis tanpa kunci (tumpang tindih dengan poin gempa Radar Cuaca — cukup buat satu) |
| Pasar (saham/komoditas/kripto) | Sedang | Ada sumber gratis terbatas (Stooq dsb.); bukan fokus Hozin Tools saat ini |
| Pemadaman internet | Sedang | Data IODA publik, niche |
| Konflik ACLED/UCDP, indeks intelijen, penerbangan militer | Rendah | Butuh akun/kunci/bas data berbayar & backend agregasi sendiri |
| Webcam langsung | Rendah–sedang | API Windy Webcams butuh kunci |
| Backend agregasi ala MonitorWorld | Rendah | Ini proyek server tersendiri, bukan fitur aplikasi |

Tidak ada fitur MonitorWorld yang butuh root/Xposed. Blocker-nya adalah
**data/backend**, bukan izin perangkat.

---

## 3. Ticarisk

**ID unduhan Drive:** `1TF7sojgrbA3V6CFX42E2Npm6Cau0bIf1`

### Identitas

- Label: "Ticarisk"
- Package: `com.mare.sal`
- versionName 1.7, versionCode 8, minSdk 24, targetSdk 36
- base.apk 6.460.560 byte (2 DEX; classes2.dex hanya 174 KB)
- Izin: notifikasi, FGS, boot completed, badge, baca/tulis penyimpanan,
  Ad Services. **Tanpa library native sama sekali** (tidak ada folder lib,
  split hanya berisi resources bahasa `in`/`ms` + xxhdpi).

### Isi dump

- raw-base: 685 file (±8,7 MB); apktool: 6.159 file (smali lengkap).
- Kode sendiri sangat kecil: paket `com/mare/sal` berisi ±40 kelas
  ter-obfuscation (nama satu huruf `A.smali`…`u.smali`) + yang terbaca jelas:
  `MainActivity`, `MainActivity$WebAppInterface`, `ApplicationClass`.
- `assets/`: `no_connection.html` (halaman offline), `webfonts/` Font Awesome
  (fa-solid/brands/regular woff2).

### Daftar fitur (dengan bukti)

Aplikasi ini **pembungkus WebView untuk situs `https://www.ticarisk.com`**
(bahasa Turki; "sohbet" = obrolan). Bukti: `MainActivity` memuat
`https://www.ticarisk.com/index.php`, menyuntikkan skrip jembatan, dan string
Turki di DEX ("Tarayıcı açılamadı", "Geçersiz giriş bağlantısı", dst.).

Fitur sisi web (terlihat dari skrip jembatan & string, bukan kode native):

1. **Platform web sosial/obrolan** — kelas halaman `ajax-page-chat`,
   `ajax-page-sohbet` di skrip JS yang disuntikkan.
2. **Halaman peta web** — kelas `hw-map-page` (satu-satunya halaman yang
   diizinkan pinch-zoom oleh jembatan).
3. **Puzzle/mini-game web** — kelas `ticarisk-puzzle-open`.
4. **Keanggotaan VIP & mata uang "diamond"** — string `vip`, `diamond`,
   `product_id` di lapisan billing.

Fitur sisi native (jembatan `WebAppInterface`, 29 metode `@JavascriptInterface`):

5. **Jembatan pembayaran Play Billing untuk web** — `initiatePurchase`,
   `checkPendingPurchases`, `confirmPurchaseReceived`,
   `confirmBackendSuccess`, `getProductPrices`, `restorePurchasesByType`,
   `manualSubscription/Unsubscription`, `onPaymentCancelled`.
6. **Jembatan notifikasi OneSignal** — `getCurrentPlayerID`,
   `requestOneSignalId`, `forceOneSignalIdRefresh`,
   `setUserNotificationPreference`, `markNotificationsAsRead`,
   `clearBadge`, cek/izin notifikasi (`checkNotificationPermission`,
   `requestNotificationPermission`, `isNotificationEnabled`).
7. **Login Google dari web** — `openGoogleSignIn`; sinkronisasi sesi
   `userLogin`/`logout` + cookie sesi persisten 5 tahun (skrip
   `setLongTermCookies`).
8. **Kontrol UX WebView** — pull-to-refresh bersyarat (`setPullToRefreshAllowed`,
   `setPageScrollAtTop`), kunci pinch-zoom di luar halaman peta
   (`setMapPinchZoomAllowed`), `onThemeChanged`, `retryConnection`,
   halaman offline lokal `file:///android_asset/no_connection.html`.
9. **Tautan keluar** — Telegram (`https://t.me/`), Instagram
   (`instagram://`), browser eksternal.
10. **Push** — OneSignal lengkap (FCM + HMS), Firebase Analytics.

### Catatan teknologi & proteksi

- WebView murni + satu activity; R8 obfuscation; PairIP license check
  (smali `pairip/` + `LicenseActivity`).
- **Fitur produknya hidup di server ticarisk.com**, bukan di APK — dump APK
  tidak menghasilkan fitur yang bisa disalin; yang ada hanya pola jembatannya.

### Kelayakan porting ke Hozin Tools

| Fitur | Nilai porting | Catatan |
|---|---|---|
| Pola WebView + JS bridge (billing/notifikasi/login) | Rendah–sedang | Pola umum; hanya berguna bila Hozin Tools suatu saat membungkus layanan web milik user sendiri |
| Platform Ticarisk itu sendiri | **Tidak bisa** | Layanan web pihak ketiga berbahasa Turki; di luar APK |

Tidak ada fitur Ticarisk yang butuh root/Xposed.

---

## Kesimpulan untuk integrasi Hozin Tools

1. **Tidak ada fitur root/Xposed di ketiga aplikasi** — semuanya aplikasi
   Play Store biasa. Penanda "butuh root/Xposed" tidak terpakai pada ketiganya.
2. **Yang paling realistis di-porting (ditulis ulang, bukan disalin):**
   - Modul **Cuaca** ala Radar Cuaca memakai API gratis (Open-Meteo/BMKG):
     cuaca saat ini, per jam, harian + AQI.
   - Modul **Gempa** (BMKG/USGS) — satu modul melayani gagasan Radar Cuaca
     maupun MonitorWorld.
   - Modul **Peta peristiwa global** ala MonitorWorld versi sederhana
     (Leaflet di WebView + USGS/EONET/GDACS).
   - Ekstra kecil: fase bulan/sunrise (hitung lokal), kompas (sensor).
3. **Yang terhalang data/backend, bukan teknologi:** radar tile premium,
   indeks intelijen & konflik MonitorWorld, Fire Center global, dan seluruh
   platform Ticarisk.
4. **Proteksi:** PairIP di ketiganya + R8 (MonitorWorld/Ticarisk) membuat
   penyalinan kode langsung tidak praktis; semua porting harus implementasi
   ulang dari perilaku yang teramati — sesuai bukti di laporan ini.
5. Repo Hozin Tools **tidak diubah sama sekali** dalam tugas ini; integrasi
   menunggu pilihan user atas daftar di atas.

### Statistik dump

| Aplikasi | File raw-base | File apktool | File jadx | Total ukuran folder |
|---|---|---|---|---|
| radarcuaca | 4.076 | 28.354 | 23.675 | ±548 MB |
| monitorworld | 373 | 16.565 | 14.072 | ±282 MB |
| ticarisk | 685 | 6.159 | 5.644 (4.916 .java; konsisten dengan bukti smali) | ±78 MB |
