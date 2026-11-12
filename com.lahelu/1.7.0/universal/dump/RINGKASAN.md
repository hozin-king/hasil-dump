# RINGKASAN — Lahelu 1.7.0 (build 17000)

Analisis statis 12 Okt 2026. File: `Lahelu_1.7.0_1_mn7m.apks` → `base.apk` (20MB) + split configs.

## Identitas
- Package: `com.lahelu` | App: Lahelu | Versi 1.7.0 (17000)
- minSdk 23, targetSdk 36 | 35 permissions (INTERNET, BILLING, POST_NOTIFICATIONS, storage, dsb)

## Total (2 dex: classes.dex 6.06MB + classes2.dex 6.56MB)
| Metrik | Jumlah |
|---|---|
| Class | **17.307** |
| Method | **100.187** |
| Field | **45.335** |

File detail: `classes.txt` (17.307 baris), `methods.txt` (100.187 baris).

## Framework: React Native (Hermes, New Architecture)
Bukti:
- `assets/index.android.bundle` (3,9MB — seluruh logika JS)
- `libhermes.so`, `libfabricjni.so`, `libreact_codegen_rncore.so`, `libreanimated.so`, `libworklets.so`, `librnscreens.so`, `librninstance.so`
- Font set react-native-vector-icons (MaterialCommunityIcons, FontAwesome, Feather, Entypo, AntDesign, dsb)
- 53 native library (.so) di `split_config.arm64_v8a.apk`, semua arm64-v8a

## Top 20 package (berdasarkan jumlah class)
1. `com.google.android` — 1688 (GMS/play services)
2. `com.revenuecat.purchases` — 1244 (**in-app purchase / subscription SDK**)
3. `com.facebook.react` — 1199 (React Native)
4. `io.grpc.internal` — 379
5. `com.onesignal.notifications` — 218 (**push notification**)
6. `androidx.appcompat.widget` — 210
7. `androidx.core.view` — 189
8. `androidx.media3.exoplayer` — 183 (**video player**)
9. `com.google.firebase` — 182
10. `com.facebook.imagepipeline` — 167 (Fresco)
11. `com.onesignal.inAppMessages` — 160
12. `s9` — 158 (obfuscated, kemungkinan kode app)
13. `w6` — 149 (obfuscated)
14. `com.google.protobuf` — 145
15. `C3` — 139 (obfuscated)
16. `k0` — 135 (obfuscated)
17. `Aa` — 131 (obfuscated)
18. `e7` — 128 (obfuscated)
19. `com.onesignal.core` — 117
20. `androidx.fragment.app` — 115

Package `s9`, `w6`, `C3`, `k0`, `Aa`, `e7` adalah hasil obfuscasi R8/ProGuard — hampir pasti kode milik Lahelu sendiri (nama class 1-2 huruf: `Ls9/A;`, `LC3/A0;`).

## Native library penting (53 total, arm64-v8a)
- `libhermes.so` (2,27MB) — JS engine
- `libfabricjni.so`, `libreactnativejni.so`, `libreact_codegen_rncore.so` — RN New Architecture
- `libreanimated.so`, `libworklets.so` — animasi
- `libhotupdater_recovery.so` — **HotUpdater OTA** (update JS tanpa rilis Play Store)
- `libimagepipeline.so`, `libnative-imagetranscoder.so`, `libglide-webp.so`, `librrc_image.so` — image pipeline (Fresco)
- `libjscinstance.so` — fallback JSC

## Jaringan / API (dari nama class & string)
- HTTP client: hanya 2 class `okhttp3` (transitif), **tanpa Retrofit** — networking kemungkinan besar via `fetch` di JS bundle (khas React Native).
- Domain terlihat di JS bundle: `lahelu-ai.sgp1.digitaloceanspaces.com` (CDN konten AI), `cache.lahelu.com` (CDN), `hot-updater.lahelu.com` (server OTA HotUpdater).
- Base URL API utama tidak hardcoded sebagai string polos (kemungkinan dirangkai runtime / diambil dari remote config).
- String mirip API key di dex: **0 ditemukan**.

## Catatan menarik
- **Monetisasi**: RevenueCat (1244 class) + permission BILLING → langganan/in-app purchase dikelola via RevenueCat.
- **Notifikasi**: OneSignal (notifications + inAppMessages + core ≈ 495 class).
- **Video**: ExoPlayer (media3) 183 class → pemutar video native (konten video/meme).
- **OTA update**: HotUpdater (`hot-updater.lahelu.com`) → logika JS bisa diupdate tanpa update APK.
- **Iklan**: permission ADSERVICES (Ad ID + Attribution) → ada atribusi iklan.
- Kode app sendiri ter-obfuscasi penuh (R8), jadi analisis nama class Java tidak informatif — logika bisnis ada di `index.android.bundle` (JS).
