> Catatan arsip: File sumber bernama `DEEPDIVE.md`, disalin sebagai `REPORT.md`.

# Deep Dive — Lahelu 1.7.0 (com.lahelu)

**Tanggal:** 12 Okt 2026
**Sumber:** `base.apk` + `classes.dex`/`classes2.dex` + `assets/index.android.bundle` (Hermes v96)
**Metode:** analisis statis saja (strings dex + strings bundle Hermes).

> Catatan: bundle Hermes menyimpan string saling menempel tanpa pemisah,
> sehingga beberapa string terpotong/bergabung. Yang dilaporkan di sini hanya
> yang terkonfirmasi dari pola jelas. Tidak ada secret/API key yang ditulis —
> sesuai aturan, hanya jenis + lokasi + format.

---

## 1. Alur Login

### Terkonfirmasi
- **Endpoint login:** `/api/user/login` (ditemukan di JS bundle).
- **Login Google didukung:** native module `@react-native-google-signin/google-signin`
  terkonfirmasi di dex (`com/reactnativegooglesignin/...`), plus string
  `after_login_with_google` di bundle. Client ID dari env var `V_GOOGLE_CLIENT_ID`.
- **Kemungkinan login username-only:** string `username_only` muncul tepat sebelum
  `/api/user/login` — dugaan (belum terkonfirmasi): login pakai username saja
  atau username + password, tanpa OTP.
- **Token:** string `accessToken`, `idToken`, `AuthToken` ada di bundle — token
  dipakai, tapi format header HTTP-nya (mis. `Authorization: Bearer`) tidak
  terkonfirmasi dari strings.

### Tidak ditemukan
- **Tidak ada Firebase Auth / OTP SMS** (0 class `firebase/auth`).
- **Tidak ada login Apple / Facebook** terdeteksi.
- Nama screen alur login tidak bisa diekstrak (kode JS ter-obfuscasi R8 + Hermes).

---

## 2. API yang Dipakai

### Base URL — TIDAK hardcoded
Base URL berasal dari **environment variable build-time** (prefix `V_`), nilainya
tidak ada di APK. Daftar lengkap env var yang ditemukan di bundle:

| Env var | Dugaan fungsi |
|---|---|
| `V_APP_API_URL` / `V_APP_API_URLS` / `V_API_URLS` | Base URL API utama (untuk path `/api/*`) |
| `V_MAIN_URL` | URL utama/web |
| `V_CHAT_URL` | Server chat → `chat.lahelu.com` |
| `V_CDN_URL` | CDN |
| `V_GOOGLE_CLIENT_ID` | Google Sign-In |
| `V_GOOGLE_ANALYTICS_ID` | Analytics |
| `V_ONESIGNAL_APP_ID` | Push notification |
| `V_REVENUE_CAT_API_KEY` | RevenueCat (IAP) |
| `V_ENV` | Environment (dev/prod) |

### Domain terkonfirmasi
- `chat.lahelu.com` — chat (socket.io terdeteksi, 6 referensi)
- `cache.lahelu.com` — config/CDN (`/banner-config.json`)
- `hot-updater.lahelu.com` — update OTA (HotUpdater)
- `lahelu-ai.sgp1.digitaloceanspaces.com` — CDN aset/gambar

### Endpoint `/api/*` (47 path, dari JS bundle)
> Base URL dari env var di atas. Beberapa path terpotong akibat string menempel;
> yang bertanda (?) perlu verifikasi runtime.

**User & Auth:**
- `/api/user/login` ← login
- `/api/user/edit`, `/api/user/follow`, `/api/user/unfollow`
- `/api/user/get-follow-status`, `/api/user/get-followers`, `/api/user/get-following`
- `/api/user/get-search-user`, `/api/user/get-username`
- `/api/user/redeem-referral`
- `/api/user/get-cgl-detail`, `/api/user/set-cgl` (CGL = campaign?)

**Post & Komentar:**
- `/api/post/create`, `/api/post/remove`, `/api/post/edit` (?)
- `/api/post/get-thread`, `/api/post/get-topic-post`, `/api/post/get-hashtag-post`
- `/api/post/download-watermarked`
- `/api/comment/create` (?), `/api/comment/get-post-comment`

**Chat:**
- `/api/chat/rooms`, `/api/chat/dm-candidates`, `/api/chat/uploads/url` (?)
- `/api/meme/chat/:roomId/info` (?)

**Coiner (koin):**
- `/api/coiner/get-history`, `/api/coiner/gift-coins`, `/api/coiner/trade-cash` (?)

**Poll, Signal, Streak, Topic:**
- `/api/poll/create`, `/api/poll/vote`, `/api/poll/get`
- `/api/signal/create`, `/api/signal/register`, `/api/signal/giveaway`, `/api/signal/get-joined-topics`
- `/api/streak/get-active`, `/api/streak/get-progress`
- `/api/topic/edit`, `/api/topic/remove`, `/api/topic/get-user-topics`, `/api/topic/get-search-hashtag`

**Campaign, Notif, Report, Meta, Basic:**
- `/api/campaign/create`, `/api/campaign/cancel`, `/api/campaign/get-by-post`, `/api/campaign/get-leaderboard`, `/api/campaign/pick-winner`, `/api/campaign/get-user-campaign` (?)
- `/api/notif/remove`
- `/api/report/submit`, `/api/report/rejection` (?)
- `/api/meta/update`
- `/api/basic/get-constant`, `/api/basic/master-query`, `/api/basic/master-submit` (?)

---

## 3. Penyimpanan Lokal

### Terkonfirmasi
- **AsyncStorage standar** (`@react-native-async-storage`) — **tidak terenkripsi**.
  Data tersimpan plain di direktori aplikasi.
- **Tidak ada** MMKV, EncryptedSharedPreferences, atau react-native-keychain —
  tidak ada penyimpanan aman terdeteksi. Token/sesi kemungkinan tersimpan plain
  di AsyncStorage.

### Key yang teridentifikasi (dari bundle)
- `_store_subscription_renew`, `_store_subscription_cancel`, `_store_subscription_convert` — status langganan
- `_store_refund...` (terpotong) — terkait refund
- `@lahelu...` (terpotong) — prefix key aplikasi

---

## 4. In-App Purchase (IAP)

### Terkonfirmasi
- **RevenueCat SDK** native: 1.244 class (`com.revenuecat.purchases.*`).
- **Permission `BILLING`** di manifest.
- **API key dari env var `V_REVENUE_CAT_API_KEY`** — nilai key **tidak ada** di APK
  (tidak di dex, tidak di bundle). Yang ditemukan hanya:
  - Placeholder dokumentasi SDK (`goog_1a2b3c4d...` — contoh di string SDK, BUKAN key asli)
  - String error `configure({apiKey: "key"})` (pesan SDK, bukan key)
- **Fungsi purchase terdeteksi di bundle:** `setupPurchases`, `purchaseProduct`,
  `purchasePackage`, `purchaseStoreProduct`, `purchaseDiscountedProduct`,
  `presentCodeRedemptionSheet`, `getOfferings`, `getCurrentOfferingForPlacement`.
- **UI terkait:** string `purchase_plus_disclaimer`, `special_plus_badge_on_profile`
  — ada tier "Plus" dengan badge profil.
- **Persetujuan:** string `continuing you agree to: REVENUECAT` — ada layar persetujuan.

### Tidak ditemukan
- Nilai API key asli (build-time secret).
- Product ID / entitlement ID / offering ID spesifik (tidak hardcoded; kemungkinan
  diambil dari server atau dari env).
- Alur validasi purchase ke server Lahelu (tidak terlihat endpoint khusus;
  kemungkinan via RevenueCat webhook server-side).

---

## Ringkasan eksekutif

| Aspek | Temuan |
|---|---|
| Login | `/api/user/login` + Google Sign-In; tanpa OTP/Firebase Auth |
| API base URL | Tidak hardcoded — via env var `V_APP_API_URL` dkk (nilai tidak di APK) |
| Endpoint | 47 path `/api/*` terpetakan |
| Penyimpanan | AsyncStorage plain (tidak terenkripsi); tanpa secure storage |
| IAP | RevenueCat + BILLING; API key & product ID tidak di APK (build-time/server) |

**Implikasi keamanan (observasi, bukan penilaian):** token sesi kemungkinan
tersimpan plain di AsyncStorage; seluruh konfigurasi sensitif (API URL, RevenueCat
key, OneSignal ID) di-inject saat build sehingga tidak bisa diambil dari APK —
tapi endpoint API-nya terlihat jelas dari bundle.
