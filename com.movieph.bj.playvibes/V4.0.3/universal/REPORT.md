# REA REPORT — CinemaID V4.0.3

> **Sifat laporan:** analisis statis saja (apktool + aapt2 + dexdump + strings + readelf).
> TIDAK dibuat mod, patch, bypass, maupun APK hasil modifikasi.
> File sumber HANYA dibaca dari kiriman user, tidak disebarluaskan dan tidak
> di-push ke GitHub mana pun.
>
> - File: `CinemaID_V4.0.3_0_l57z.apk`
> - Ukuran: 46.356.223 byte (~44,2 MiB)
> - SHA-256: `9e2fc26ad5de5b9e8bde61a25020b027677b83639169852ee563b650bcdcb23d`
> - Tanggal analisis: 5 November 2026 (WIB)
> - Bukti mentah: `work/` (ziplist, badging, manifest hasil apktool, daftar
>   kelas dexdump, strings) di folder yang sama dengan laporan ini.

## 1. Identitas

| Item | Nilai |
|---|---|
| Label (semua locale) | CinemaID |
| Package name | `com.movieph.bj.playvibes` |
| versionName | V4.0.3 |
| versionCode | 40003 |
| minSdk | 24 (Android 7.0) |
| targetSdk | 33 (Android 13) |
| compileSdk / platform build | 34 (Android 14) |
| Application class | `com.mgs.carparking.app.AppApplication` |
| Jumlah DEX | 9 (`classes.dex` … `classes9.dex`, total ~66 MB tidak terkompres) |
| Jumlah kelas (dexdump) | 54.854 deskriptor kelas |
| Layout XML | 686 file |

**Arsitektur native yang dibundel:** `arm64-v8a` dan `armeabi-v7a`
(semua .so di bawah ada di kedua ABI).

| .so (arm64-v8a) | Ukuran | Keterangan |
|---|---|---|
| `libpp_hls.so` | 2.913.576 | Player HLS milik Pangle (ByteDance) |
| `libjiagu_sdk_pp_hlsProtected.so` | 759.104 | Varian terproteksi SDK Pangle (jiagu = proteksi/integritas Pangle) |
| `libjiagu_sdk_OSETSDKProtected.so` | 765.640 | Varian terproteksi SDK OSET/OKT |
| `libsls_producer.so` | 825.280 | Producer log Aliyun SLS |
| `libapplovin-native-crash-reporter.so` | 860.200 | Crash reporter AppLovin |
| `libtt_ugen_layout.so` | 440.672 | Layout engine TikTok/Pangle (ugen) |
| `libnms.so` | 293.672 | Komponen native SDK (tidak teridentifikasi pasti) |
| `libpglarmor.so` | 68.600 | Komponen proteksi Pangle |
| `libpl_droidsonroids_gif.so` | 41.040 | GIF (android-gif-drawable) |
| `libapminsighta/b.so` | ~102/124 KB | APM insight (ad SDK) |
| `libbuffer_pgl.so`, `libfile_lock_pgl.so` | kecil | Utilitas Pangle |
| `libtobEmbedPagEncrypt.so` | 8.304 | Enkripsi embed Pangle |

Tidak ada .so milik engine game/Unity dan tidak ada .so dengan nama yang
mengarah ke DRM Widevine/ExoPlayer native — pemutaran bertumpu pada
player Java/Kotlin (Media3/ExoPlayer dari SDK iklan + DKVideoPlayer,
lihat §3) dan player HLS Pangle.

## 2. Manifest

### 2.1 Atribut application (bukti)

- `allowBackup="true"`, `largeHeap="true"`, `extractNativeLibs="false"`,
  `requestLegacyExternalStorage="true"`, `supportsRtl="true"`,
  `theme="@style/BrowserTheme"` (tema bernama "Browser" — lihat §5).
- `usesCleartextTraffic="true"` DAN `networkSecurityConfig` yang
  mengizinkan cleartext untuk SEMUA host serta mempercayai sertifikat
  `user` + `system` (lihat §4).
- **Tidak ada** atribut `debuggable` → `debuggable=false` (default).

### 2.2 Permission (35 entri)

Normal/rendah risiko: INTERNET, ACCESS_NETWORK_STATE,
CHANGE_NETWORK_STATE, ACCESS_WIFI_STATE, CHANGE_WIFI_STATE,
CHANGE_WIFI_MULTICAST_STATE, VIBRATE, WAKE_LOCK, FOREGROUND_SERVICE,
RECEIVE_BOOT_COMPLETED, FLASHLIGHT, AD_ID + AD_SERVICES (attribution,
topics, ad id), BIND_GET_INSTALL_REFERRER_SERVICE, BIND_APPHUB_SERVICE
(AppLovin), permission dinamis internal app sendiri.

**Berbahaya / sensitif (perlu diperhatikan):**

- `READ_PHONE_STATE`
- `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
  (+ `requestLegacyExternalStorage=true`)
- `READ_MEDIA_IMAGES`, `READ_MEDIA_AUDIO`, `READ_MEDIA_VIDEO`
- `CAMERA`, `RECORD_AUDIO`
- `READ_LOGS` — aplikasi bisa membaca log sistem (luas, jarang diminta
  aplikasi video biasa)
- `WRITE_APN_SETTINGS` — mengubah setting APN (sangat jarang, patut dicurigai)
- `SYSTEM_ALERT_WINDOW` + `SYSTEM_OVERLAY_WINDOW` — overlay di atas
  aplikasi lain (dipakai fitur floating window, lihat §3)
- `REQUEST_INSTALL_PACKAGES` — bisa memicu install APK lain
- `MOUNT_UNMOUNT_FILESYSTEMS` — praktisnya tidak diberikan ke aplikasi
  pihak ketiga modern, tapi tetap dideklarasikan
- `GET_TASKS`, `CONTROL_DISPLAY_BRIGHTNESS`

### 2.3 Komponen (112 activity, 19 service, 12 receiver, 16 provider)

**Exported = true yang relevan:**

- `com.mgs.carparking.ui.login.splash.SplashActivity` — LAUNCHER (MAIN)
- `com.mgs.carparking.ui.MainActivity` (singleTask, portrait)
- `com.mgs.carparking.jiajia.MJMainActivity` (singleTask)
- `com.mgs.carparking.ui.mine.collection.CollectionActivity`
- `com.facebook.CustomTabActivity` (standar Facebook SDK)
- `androidx.work` SystemJobService (digate permission BIND_JOB_SERVICE),
  DiagnosticsReceiver + ProfileInstallReceiver (digate DUMP),
  `com.mbridge.msdk.foundation.same.broadcast.NetWorkChangeReceiver`
  (Mintegral)

**Tidak ada komponen exported yang sensitif** (tidak ada activity/service/
receiver exported milik aplikasi sendiri yang membuka data internal,
dan semua 16 provider `exported=false`, termasuk FileProvider,
MainProvider yk, SLS provider, PictureFileProvider, dan provider-provider
init SDK iklan).

**Deep link / intent filter:**

- Skema: `http`, `https`, `fbconnect`, `@string/fb_login_protocol_scheme`,
  `sms`, `market` (tiga terakhir milik SDK Facebook/iklan).
- Host deep link aplikasi: hanya `cct.com.movieph.bj.playvibes`
  (host Custom Tab Facebook) — **tidak ditemukan skema/host deep link
  milik konten aplikasi sendiri** (mis. `cinemaid://`).

**Service penting milik aplikasi:**

- `com.mgs.carparking.androidupnp.service.ClingUpnpService` dan
  `SystemService` (keduanya `exported=false`) — DLNA/UPnP, dipakai fitur
  cast ke TV (Cling adalah library UPnP open-source).

## 3. Gambaran fitur dari DEX

### 3.1 Fungsi utama: aplikasi katalog + pemutar video (agregator)

Kode aplikasi sendiri (tidak diobfuscate) ada di paket
`com.mgs.carparking` — **1.012 kelas**, antara lain:

- Home/konten: `ui/homecontent` (list, rekomendasi, ranklist),
  `ui/channelcontent` (kategori/kanal, detail spesial),
  `ui/homecontent/videosearch` (pencarian video),
  `ui/homecontent/videodetail` (detail + pemutaran video)
- Akun: `ui/login` (LoginActivity, RegisterActivity, SplashActivity,
  SplashWxActivity — Wx = WeChat login), `ui/mine`
- Koleksi & riwayat: `ui/mine/collection`, `dbtable/VideoCollection`,
  `VideoLookHistory`, `SearchHistory`
- Unduhan: `ui/mine/DownloadVideoActivity`,
  `DownloadVideoPlayActivity`, `download/DownloadService`,
  `dbtable/VideoDownload`
- Fitur video: subtitle (476 hit string "Subtitle"), danmaku/barrage
  (17 hit), floating window (`util/floatUtil`), cast DLNA/UPnP,
  `widgets/dialog/downloadcomplete`, `VideoSkip`, `VideoStayTime`,
  `VideoShare`, `VideoAdLook` (tracking tontonan/iklan di database lokal)
- Lainnya: `ui/web` (WebView + GameActivity web), `ui/spiel`,
  `ui/mine/languageswitching` (ganti bahasa), `ui/mine/feedback`,
  `ui/mine/share`, `ui/mine/edit_mine`
- Database lokal (Room): koleksi, unduhan, riwayat tonton, riwayat cari,
  durasi tonton, skip, share, tayangan iklan — pola aplikasi video
  on-demand, bukan pemutar file lokal semata.

Tidak ditemukan katalog berbasis TMDB/IMDb (0 hit string `tmdb`/`imdb`),
tidak ada fitur shorts/drama vertikal (0 hit), dan tidak ada bukti
pembayaran langganan via Google Play Billing di kode aplikasi
(20 hit `billing` semuanya milik Unity Ads store bridge, yaitu SDK iklan).

Kata `vip` (54 hit) dan `premium` (9 hit) ada, tetapi tidak ditemukan
alurnya dipetakan sampai ke paywall dalam analisis statis ini —
kemungkinan penanda konten/level akun, bukan bukti IAP.

### 3.2 Library / SDK pihak ketiga yang terdeteksi

**Iklan & mediasi (dominan — mayoritas dari 54.854 kelas):**

- Google Mobile Ads (5.775 kelas `gms/internal/ads`) + Ad Manager
- AppLovin MAX (+ crash reporter native, AppLovinInitProvider)
- ironSource / LevelPlay (+ AdQuality SDK)
- Unity Ads (297 kelas `unity3d/ads/core/domain`)
- Pangle ByteDance (openadsdk, `pp_hls`, jiagu, ugen) — termasuk
  RewardVideoActivity
- Mintegral / Mbridge (playercommon ExoPlayer2)
- Vungle, Bigo Ads, InMobi, BidMachine, Fyber/Inneractive,
  Audience Network Facebook, AdMob mediation, SafeDK

**Konten / SDK aplikasi:**

- `com.yk.e` (211 kelas: activity RewardVideo/Web/Game, provider,
  subad, adview) — SDK konten/iklan pendamping aplikasi
- OKT SDK (`OKT_SDK_*` di manifest + aset `okt_sdk_config`,
  `okt_sdk_preset_1978`, `OSETSDKProtected.dat`) — lihat §3.3
- ExoPlayer/Media3 (via BidMachine + Mintegral), DKVideoPlayer
  (string UI berbahasa Mandarin — player open-source Tiongkok)
- Facebook SDK (login + Custom Tab), Google Play Services,
  AndroidX lengkap (Room, WorkManager, Navigation, Datastore),
  Glide (dengan `HttpsGlideModule` sendiri), RxJava, Picasso,
  PictureSelector (Luck), CustomActivityOnCrash, Cling UPnP,
  Aliyun SLS (logging)

**Obfuscation:** sebagian kelas memakai nama 1–2 huruf
(`a/b`, `z6`, `i9`, `ug`, `Lil/I1I`) dan beberapa nama kelas berisi
karakter Arab aneh (`adapter/۟ۢ۠ۡۨ`, `dbtable/ۣۢۢۥ`) — campuran
R8/ProGuard + kemungkinan teknik anti-analisis ringan. Namun paket
`com.mgs.carparking` sendiri TIDAK diobfuscate (nama paket/kelas
aplikasi terbaca jelas).

### 3.3 Endpoint / domain API yang terlihat (pola saja)

**Backend SDK konten (paling relevan dengan fungsi aplikasi):**

- OKT SDK host list (dari `assets/okt_sdk_config`, format asli):
  `https://sdkapi-ga.smallyy.com`, `https://sdkapi-ga.tworkkk.com`
- Privacy policy OKT: `https://www.oktdata.com/oktdata_privacy.html`
- Aset OKT lain: `okt_sdk_preset_1978` berisi blob base64 panjang
  (konfigurasi terenkripsi/terkode — **nilainya tidak disalin ke laporan
  ini**).

**String host lain yang patut dicatat (konteks belum dipetakan penuh):**

- `http://dg10.tv` (3 kemunculan di strings DEX, tanpa path) —
  kemungkinan host konten/fallback; perlu verifikasi runtime
- `https://7pyp.e97z.com/privacy.html`,
  `https://44kj.0t89s.com/error.png`,
  `https://kuht.52s7g.com/` — domain acak bergaya rotating host,
  umum pada backend aplikasi abu-abu
- `http://testhehe.com/test` — kemungkinan string uji yang tertinggal

**Yang TIDAK ditemukan:** tidak ada satu pun host API milik aplikasi
yang terekspos jelas dalam bentuk `https://api.<milik-app>.com/...`
di strings DEX. Alur API aplikasi kemungkinan diangkut lewat OKT SDK
(host di atas) dan/atau string yang dikodekan — pemetaan endpoint
lengkap butuh decompile jadx + tracing runtime (lihat §6).

**Credential/key (jenis saja, nilai disensor):**

- Ditemukan di manifest (hanya nama kuncinya, nilai TIDAK disalin):
  `OKT_SDK_APP_ID`, `OKT_SDK_APP_KEY`, `OKT_MAX_SDK_KEY`,
  `com.facebook.sdk.ApplicationId`, `com.facebook.sdk.ClientToken`,
  `com.google.android.gms.ads.APPLICATION_ID`,
  `com.google.android.gms.ads.AD_MANAGER_APP`, `UMENG_CHANNEL`
- String terkait token di DEX: konstanta `access_token`,
  `refresh_token`, `Authorization` ada (umum untuk login API).
  Nilai token/key apa pun tidak dicari dan tidak disalin.

## 4. Keamanan singkat

| Aspek | Temuan |
|---|---|
| Debuggable | TIDAK (`debuggable` tidak dideklarasikan → false) |
| Root detection | TIDAK DITEMUKAN — 0 kelas RootBeer/SafetyNet/PlayIntegrity/Magisk; tidak ada string `isRooted` di kelas aplikasi |
| Integritas / anti-tamper | Ada secara tidak langsung: SDK Pangle `jiagu` (proteksi) + `pglarmor`; tetapi tidak ada Play Integrity API |
| Certificate pinning | HANYA library: kelas `okhttp3/CertificatePinner` (5 kelas OkHttp) — tidak ada bukti pin aktif yang dikonfigurasi aplikasi; dan konfigurasi keamanan justru melemahkan: `usesCleartextTraffic=true` + `networkSecurityConfig` mengizinkan cleartext SEMUA host dan mempercayai sertifikat `user` → lalu lintas mudah diintersep (mitmproxy dengan CA user) |
| allowBackup | `true` — data aplikasi (termasuk database lokal & preferensi) bisa dicadangkan via adb backup |
| Penyimpanan token | TIDAK ADA `EncryptedSharedPreferences`; API `SharedPreferences` dipakai (string `getSharedPreferences` ada) + Room + DataStore (androidx) — indikasi token/riwayat tersimpan plaintext, belum bisa dipastikan tanpa tracing runtime |
| Permission berlebih | Ya — READ_LOGS, WRITE_APN_SETTINGS, REQUEST_INSTALL_PACKAGES, SYSTEM_ALERT_WINDOW, RECORD_AUDIO, CAMERA, READ_PHONE_STATE (lihat §2.2) |
| Signature | Self-signed modder, bukan sertifikat Play Store (lihat §5) |

## 5. Penilaian: resmi atau pihak ketiga?

**Kesimpulan: aplikasi PIHAK KETIGA (agregator video / repack),
bukan aplikasi resmi dari studio/Play Store.** Bukti per poin:

1. **Signature modder.** Sertifikat penanda APK:
   `CN=DESTASEOMODS, O=DESTASEOMODS, OU=DESTASEOMODS, L=Nganjuk,
   ST=Prindapan, C=ID`, self-signed, SHA-256
   `CD:91:F2:51:30:62:D2:30:94:D2:CF:F7:8D:07:AD:3B:30:69:CD:B6:2D:2A:AF:B5:14:BB:52:EE:29:F6:05:FA`,
   serial `5b05ac9b`, dibuat 13 Nov 2025, berlaku sampai 4104.
   Nama "DESTASEOMODS" + field lelucon ("Prindapan") adalah ciri
   sertifikat signer komunitas mod, bukan penerbit resmi.
2. **Repack/re-sign.** File `META-INF/DESTASEOMODS.*` dan
   `classes7.dex` bertanggal 22 Jan 2026, sementara 8 DEX lainnya
   bertanggal 10 Des 2025 — pola build ulang + tanda tangan ulang
   setelah build asli. (Ini sinyal kuat repack, bukan bukti mutlak
   perubahan isi dex 7.)
3. **Nama internal menutupi fungsi.** Namespace kode
   `com.mgs.carparking` ("car parking") dan tema `BrowserTheme`
   untuk aplikasi video — pola penyamaran nama yang umum pada
   aplikasi agregator streaming agar lolos penapisan.
4. **Backend tidak transparan.** Tidak ada domain API resmi milik
   pengembang, tidak ada situs/Play listing yang terikat dari
   manifest; konten diangkut via SDK OKT dengan host bergaya
   rotating (`smallyy.com`, `tworkkk.com`) + host acak
   (`7pyp.e97z.com`, `44kj.0t89s.com`, `kuht.52s7g.com`, `dg10.tv`).
5. **Iklan mendominasi biner.** Mayoritas kelas adalah SDK mediasi
   iklan (Google, AppLovin, ironSource, Unity, Pangle, Mintegral,
   Vungle, Bigo, InMobi, BidMachine, Fyber) — monetisasi agresif
   khas agregator gratis, bukan aplikasi berlisensi.
6. **Permission berlebih.** READ_LOGS, WRITE_APN_SETTINGS,
   REQUEST_INSTALL_PACKAGES, overlay, dan akses media penuh tidak
   proporsional untuk sekadar menonton video.
7. **Ekosistem Tiongkok + pasar Indonesia.** Player DKVideoPlayer
   (Mandarin), login WeChat, SDK Pangle/Bigo/OKT, bersamaan dengan
   label `CinemaID`, package `movieph` (PH = Filipina?) dan
   localisasi `values-id` (Indonesia) — produk white-label yang
   diedarkan lintas negara Asia Tenggara dengan rebrand lokal.

**Yang TIDAK bisa disimpulkan dari analisis statis ini:** apakah
konten video di dalamnya berlisensi atau bajakan (butuh melihat
respons API/katalog saat runtime), dan apakah file ini hasil modifikasi
fitur (mis. premium dibuka) atau sekadar re-sign ulang dari APK asli
yang memang sudah seperti ini.

## 6. Saran tindak lanjut

1. **Runtime traffic (paling bernilai):** jalankan di perangkat/emulator
   terisolasi + mitmproxy (ingat: cleartext + user CA dipercaya,
   jadi intersepsi mudah) untuk memetakan: host API konten,
   endpoint katalog/detail/search, format respons, dari mana URL
   m3u8/MP4 berasal, dan apakah ada lisensi/DRM.
2. **Decompile jadx (bila tersedia):** fokus ke kelas berikut —
   `com.mgs.carparking.ui.homecontent.videodetail.*`,
   `netbean/*Entity`, `ui/homecontent/*ViewModel`,
   `download/DownloadService`, `ui/login/LoginActivity`,
   dan pemanggil OKT SDK — untuk memetakan alur API + login/token.
3. **Cek katalog runtime:** daftar kategori/kanal, contoh judul,
   dan sumber video (apakah mengarah ke CDN publik, agregator lain,
   atau host sendiri) — ini penentu legalitas konten.
4. **Cek perilaku iklan & permission runtime:** apakah READ_LOGS /
   REQUEST_INSTALL_PACKAGES / overlay benar-benar dipakai saat jalan,
   atau hanya deklarasi warisan SDK.
5. **Jangan instal di perangkat utama** sebelum langkah 1–4:
   permission + signature modder + backend tidak transparan membuat
   APK ini berisiko sebagai perangkat harian; pakai profil/perangkat
   terpisah bila harus dijalankan.
6. **Tidak disarankan membuat mod** dari APK ini tanpa hasil langkah
   1–3 (belum jelas apa yang dimodifikasi dari aslinya, dan konten
   kemungkinan besar agregasi tanpa lisensi yang jelas).

## 7. Catatan keterbatasan

- Tanpa jadx di VM ini, analisis berhenti di level daftar kelas,
  strings, manifest, dan aset — bukan decompile per-metode.
- Tanpa Ghidra/IDA/Hopper, .so native hanya dibaca header +
  strings permukaan.
- Endpoint API aplikasi belum terpetakan penuh (kemungkinan
  dikodekan/diangkut OKT SDK) — §3.3 hanya memuat yang terlihat.
- Semua klaim di atas merujuk ke artefak yang dikirim
  (SHA-256 di kepala laporan); APK dengan nama sama dari sumber
  lain bisa berbeda isinya.
