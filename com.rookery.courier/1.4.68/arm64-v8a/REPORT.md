# REA — Roost Social: Penpal & Friends 1.4.68

**Tanggal analisis:** 9 Nov 2026 (WIB)
**Sumber:** link APKPure `[tautan unduhan dihapus — minta ke Alyaa]`
**Metode:** analisis statis (aapt2, apksigner, apktool 2.10.0, JADX, strings, dexdump). **APK tidak diinstal, tidak dijalankan.** Tidak ada analisis runtime/dinamis.
**Status:** dump penuh tersedia di `dump/` (lihat §6).

---

## 1. Identitas

| Item | Nilai |
|---|---|
| Nama aplikasi | Roost (lengkap: "Roost Social: Penpal & Friends") |
| Package | `com.rookery.courier` |
| Versi | **1.4.68 / versionCode 109** |
| Developer | Good Egg LLC |
| File sumber | XAPK APKPure, 159.490.611 byte |
| SHA-256 XAPK | `c87aee7faec029308ede7b679d8357367848508889e34fadd2ae8f9dc0074ca0` |
| minSdk / targetSdk / compileSdk | 26 (Android 8.0) / 36 / 36 (platform 16) |
| Arsitektur | **arm64-v8a saja** (tidak ada armeabi-v7a/x86) |
| Kategori | Sosial; rating konten Teen |

### Verifikasi tanda tangan vs klaim APKPure

| Item | Hasil |
|---|---|
| SHA-256 file XAPK | `c87aee7f…` — **COCOK** dengan yang diklaim APKPure |
| Sertifikat SHA-1 | `f4ae0e755c519d34b96e995e8d5d78e1a668682a` — **COCOK** dengan yang diklaim APKPure |
| Sertifikat SHA-256 | `3ea12af02e9da495fe8f83671a59fceb86918cad37e32d29870b38ccc9ef757f` |
| Penanda tangan | `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US`, RSA 4096-bit — sertifikat **Google Play App Signing** (bukan sertifikat developer langsung) |
| Skema tanda tangan | v2 ✓, v3 ✓, v1 ✗, v3.1 ✗, v4 ✗; SourceStamp terverifikasi; **1 signer** |
| `apksigner verify` | OK |

**Kesimpulan identitas:** file ini adalah APK asli yang ditandatangani lewat Play App Signing; hash dan tanda tangannya cocok dengan klaim APKPure. Tidak ada indikasi repack dari sisi tanda tangan.

### Isi XAPK (split APK)

| File | Ukuran | SHA-256 |
|---|---|---|
| `com.rookery.courier.apk` (base) | 114.318.904 | `2d8b6f9cf0b106a722bf6dff81722c3528328876858f2f523499e52ceae3d7bc` |
| `config.arm64_v8a.apk` (native libs) | 44.840.008 | `eff1a551ae1e3099de89afd553ecb329b9beaeb117f924e8fb55a7b7a3539307` |
| `config.xxhdpi.apk` (resources) | 329.033 | `a0f392d052979e3c97c2862579d6d15617c291719e5ada2a347e2d0cf2a7ea0c` |
| `manifest.json` (manifest APKPure) | 2.086 | — |

Tidak ada file OBB di dalam XAPK; semua konten ada di base APK + 2 split di atas.

---

## 2. Inventaris

### 2.1 Framework / engine

- **Native Android (Kotlin), UI berbasis View — BUKAN Unity, BUKAN Flutter, BUKAN React Native** (tidak ada `libunity.so`/`libflutter.so`/hermes; hanya 2 class `androidx/compose` — Compose praktis tidak dipakai).
- 4 file DEX, total ±36,5 MB: `classes.dex` 9,4 MB, `classes2.dex` 9,0 MB, `classes3.dex` 12,6 MB, `classes4.dex` 5,5 MB.
- **37.060 class, 206.427 method, 165.890 string** (total keempat DEX).
- Kode aplikasi sendiri hanya **578 class** di `com.rookery.courier`, dan mayoritas sudah di-obfuscate R8 (nama paket pendek: `ha`, `Ac`, `E9`, `n9`, `xb`, …). Yang luput dari obfuscation terutama paket `core/models` (nama dipertahankan demi serialisasi JSON) — dari sanalah sebagian besar temuan struktur data berasal.
- `android:allowBackup="false"`, `extractNativeLibs="false"`, `largeHeap="true"`.

### 2.2 Manifest — permissions (37 izin, sesuai klaim APKPure)

**Sensitif / perlu diperhatikan:**
| Izin | Keterangan |
|---|---|
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Lokasi presisi (dipakai Mapbox + fitur "Safari Zones"/pen-pal berdasarkan wilayah) |
| `RECORD_AUDIO` | Rekam audio (kemungkinan voice note) |
| `CAMERA` | Kamera (scan dokumen ML Kit, foto profil/surat) |
| `READ_CONTACTS` | Baca kontak |
| `POST_NOTIFICATIONS` | Notifikasi (FCM) |
| `DETECT_SCREEN_CAPTURE` | Deteksi screenshot |
| `USE_BIOMETRIC`, `USE_FINGERPRINT` | Biometrik |
| `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED` | Background + reminder streak saat boot |
| `com.android.vending.BILLING` | Play Billing (pembelian/subscription) |
| `com.android.vending.CHECK_LICENSE` | Play License check (PairIP, lihat §3.3) |

**Lainnya:** `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `VIBRATE`, `READ_GSERVICES`, `BIND_GET_INSTALL_REFERRER_SERVICE`, `C2DM.RECEIVE`, 1 izin signature internal, dan **17 izin badge launcher** (Samsung/HTC/Sony/Huawei/Oppo/dll. — hanya untuk angka badge ikon, bukan akses data).

### 2.3 Komponen (dari AndroidManifest.xml hasil apktool)

- **14 activity.** Launcher: `com.rookery.courier.MainActivity` (exported, `singleTop`). Sisanya milik library: AppAuth (`AuthorizationManagementActivity`, `RedirectUriReceiverActivity`), Firebase Auth (`GenericIdpActivity`, `RecaptchaActivity`), ML Kit Document Scanner, Play Billing (`ProxyBillingActivity`, `ProxyBillingActivityV2`), `com.pairip.licensecheck.LicenseActivity`, Google Sign-In, Play Core.
- **Deep link (autoVerify):** host `roostsocial.app` dengan path `activities`, `care-room`, `shop`, `stormpost`, plus `firebase.auth`.
- **Service:** `RoostFirebaseMessagingService` (FCM), AppMeasurement, ML Kit, Room, Transport.
- **Receiver:** `EggStreakReminderReceiver`, `EggStreakBootReceiver` (pengingat streak harian), `FirebaseInstanceIdReceiver`, `ProfileInstallReceiver`.
- **Provider:** `FileProvider` (`com.rookery.courier.fileprovider`), `FirebaseInitProvider`, `MlKitInitProvider`, `androidx-startup`.

### 2.4 Native libs (split arm64_v8a, semua stripped, aarch64)

| Library | Ukuran | Fungsi |
|---|---|---|
| `libmapbox-maps.so` | 19.076.384 | Mapbox Maps (peta) |
| `libtranslate_jni.so` | 16.361.048 | ML Kit Translate (terjemah surat) |
| `libmapbox-common.so` | 6.935.104 | Mapbox Common |
| `libc++_shared.so` | 1.292.896 | C++ runtime |
| `liblanguage_id_l2c_jni.so` | 1.019.560 | ML Kit Language ID |
| `libimage_processing_util_jni.so` | 29.008 | ML Kit image utils |
| `libandroidx.graphics.path.so` | 10.096 | AndroidX graphics |
| `libdatastore_shared_counter.so` | 7.112 | DataStore |
| `libsurface_util_jni.so` | 4.832 | Surface utils |

Total native ±44,8 MB. Semua stripped (tanpa simbol debug). Tidak ada native game engine — game "Stormpost" (bullet-hell) datanya berupa JSON + audio di `assets/skyward/`, logikanya di kode Kotlin.

### 2.5 Ukuran per komponen besar (base APK, file >5 MB)

| File | Ukuran | SHA-256 |
|---|---|---|
| `classes3.dex` | 12.552.848 | `c02f0102bede6d8ec327d7dde34d5b6b3feadc0fa20cccbf50aa84dc1a27656a` |
| `classes.dex` | 9.437.048 | `13d2ea52696420a225e5a651a48175f22b473b51482528cc90274600d717af2b` |
| `classes2.dex` | 9.045.112 | `006cd481d66b473340e261c66a37dcd8a762ed4f34a247507e2c1e0e99e778a0` |
| `classes4.dex` | 5.463.308 | `0582b5ffbadeb644eac47f35b898d7b9e433258e72f19405cc9013cdf9755dd6` |
| `libmapbox-maps.so` | 19.076.384 | `2035f6699899df5c97da3184233616fd28f6930550e92b94a73165f1b8546d6e` |
| `libtranslate_jni.so` | 16.361.048 | `35b3d0366291347e3f25e80e809ee398d716aea49cd03278007fedd526a1496f` |
| `libmapbox-common.so` | 6.935.104 | `ab9b624b930b5d7cd71733743bde00ff2f509bfe5346e273c6e8fcb2a2aef828` |
| `res/raw/tropical_quest.m4a` | 3.381.924 | — |
| `assets/bundled_bird_types.json` | 2.047.838 | — |

### 2.6 Assets penting

- `assets/bundled_bird_types.json` (2,0 MB) — **katalog 1.015 jenis burung** (nama, tier, rarity, kecepatan/stamina dasar, nama ilmiah, status konservasi, habitat, dsb.). URL aset mengarah ke `gs://rookery-291d9.firebasestorage.app/bird-types/…`.
- `assets/bundled_birds/` (38 MB, 3.045 file webp) — sprite burung (profile/idle/flight).
- `assets/skyward/` (19 MB) — konten game Stormpost: `content-v4.json` (skema lengkap: arena, musuh, boss, chapter, upgrade, balance, scoring, unlock), audio musik/SFX.
- `assets/paywall_benefits_default.json` (v9) — tabel benefit paywall (lihat §3.4).
- `assets/country_stamps/` (6,2 MB), `assets/achievement_stamps/` (1,9 MB), `assets/scratchpad-content/` (992 KB), `assets/letters/` (328 KB), `assets/tflite_langid.tflite.jpg` (312 KB, model language-ID).
- `assets/licenses/`, `assets/sdk_versions`, `assets/dexopt`, `assets/care_room`.

---

## 3. Permukaan menarik

### 3.1 Backend — Firebase project `rookery-291d9`

| Layanan | Bukti |
|---|---|
| Firebase Auth (+ reCAPTCHA, Google Sign-In, AppAuth) | `GenericIdpActivity`, `RecaptchaActivity`, `net.openid.appauth`, string `www.recaptcha.net/recaptcha/api3` |
| Cloud Functions | `https://us-central1-rookery-291d9.cloudfunctions.net` (nama fungsi individual tidak bisa dipulihkan dari analisis statis — dipanggil lewat Firebase Functions SDK dari kode ter-obfuscate) |
| Firestore | Koleksi terlihat di string: `birds`, `letters`, `shop_event_v1`; model `User` lengkap dengan field profil |
| Firebase Storage | `rookery-291d9.firebasestorage.app`, `firebasestorage.googleapis.com/v0`, `…/bird-types/…` |
| Remote Config | `firebaseremoteconfig.googleapis.com`, `firebaseremoteconfigrealtime…`; paywall JSON lokal adalah fallback/default |
| FCM | `RoostFirebaseMessagingService`, `firebase.messaging.default_notification_channel_id = default` |
| App Check + **Play Integrity** | Registrar `FirebaseAppCheckPlayIntegrityRegistrar` di manifest |
| Analytics / Crashlytics | AppMeasurement aktif; **Crashlytics dimatikan** (`firebase_crashlytics_collection_enabled = false`) |

### 3.2 Domain / endpoint hardcoded lain

- `https://roostsocial.app` (+ `/terms`, `/privacy`, `/invite/`, `/profile/`, `/activities/`, `/legal/art-challenge-rules`, `/legal/artist-agreement`)
- Mapbox (`mapbox.com`, `api.mapbox.com` via SDK), OpenStreetMap, Overture Maps
- `https://klipy.com` (GIF picker)
- `https://www.gbif.org` (sumber data keanekaragaman burung — cocok dengan field nama ilmiah/status konservasi di katalog burung)
- Google Play Games (`googleapis.com/auth/games`), AdServices (`googleadservices.com`), `play.google.com/store/account/subscriptions`
- **Token/kunci yang tertanam:** Mapbox public token (`pk.eyJ…`, di `res/values`) dan Firebase client API key (`AIza…`, di resources) — keduanya adalah kunci *klien* yang memang dirancang tertanam di aplikasi (bukan rahasia server). Nilai lengkapnya **sengaja tidak ditulis di laporan ini**.

### 3.3 Proteksi: PairIP + lisensi Play

- **Application class adalah `com.pairip.application.Application`** — aplikasi dibungkus **PairIP** (proteksi komersial Android: anti-tamper + license check).
- Paket `com.pairip.licensecheck`: `LicenseClient` (cek lisensi berulang/`RepeatedCheckMetadata`, retry, `PAYWALL_INTENT`), `LicenseActivity`, `LicenseContentProvider`, `TrialClient`. Ini adalah wrapper atas **Google Play License Verification (LVL)** — aplikasi memverifikasi lisensi ke Play Store secara berkala, bukan sekali saat instal.
- **Firebase App Check dengan Play Integrity** aktif — request ke backend Firebase membawa attestation Play Integrity.
- **Tidak ditemukan** deteksi root/emulator di level kode aplikasi sendiri: string `isRooted`/`isEmulator`/`/system/xbin/su` yang ada berasal dari **Mapbox SDK** (telemetri info perangkat), bukan dari kode Roost.
- Implikasi: repack/modifikasi APK akan merusak tanda tangan Play App Signing → cek lisensi PairIP dan App Check Play Integrity akan gagal (lihat §4).

### 3.4 Monetisasi — paywall Supporter / Founder

Dari `assets/paywall_benefits_default.json` (v9, `is_active: true`):

| Benefit | Free | Supporter | Founder (sold out) |
|---|---|---|---|
| Training energy | 10 | 15 | 15 |
| Energy recharge | Standard | 20% lebih cepat | 20% lebih cepat |
| Monthly Epic+ Drop | — | ✓ | ✓ |
| Scratchpad backgrounds & stickers | — | ✓ | ✓ |
| Pen Pal requests | 5/hari | 20/hari | 20/hari |
| Pen Pal country filters & presets | — | ✓ | ✓ |
| Filter changes | 5/minggu | 25/minggu | 25/minggu |
| Gilded flight trail, badge, ad-free GIF picker | — | ✓ | ✓ |
| Founders wall, Cher Ami | — | — | ✓ |
| Handwriting fonts | 1 | 5 | 5 |

- **Monthly Epic+ Drop odds:** Epic 75%, Legendary 20%, Mythic 4%, Celestial 1%.
- **Product ID Play Billing yang ditemukan di kode:** `supporter_monthly` (subscription) dan `founders_membership`. Tidak ada harga di dalam APK — harga diambil dari Play Store saat runtime.
- **Toko (shop) digerakkan server:** model `ShopStorefront` (revision, rotation, schedule, deals, featured, events; batas `MAX_DOC_BYTES = 65536`, maks 4 event, 24 offer ID) — katalog/rotasi toko datang dari backend, bukan hardcoded.
- **Katalog burung lokal, kepemilikan server:** 1.015 jenis burung dibundel lokal (rarity: Common 102, Uncommon 307, Rare 250, Epic 206, Legendary 85, Mythic 53, Celestial 12; tier: starter-pigeon 102, common 307, special 296, epic 190, legendary 84, mythic 36). **0 burung punya `sku`** — burung tidak dijual langsung per SKU; didapat lewat drop/koleksi. Kepemilikan (`pigeonCount`, `codexCaughtCount`, `codexSeenCount`) tersimpan di profil User server.
- **Model `User` (server-synced):** `trainingEnergy`, `maxTrainingEnergy`, `energyRechargeRate`, `lastEnergyUpdate`, `nestSlotsOwned`, `supporterBadgeKind`, `level`/`experience`, `referralCode`/`referralStatus`/`qualifiedReferralCount`, `pendingLevelReward`, `pendingReferralGrant`, `ownedNestVisuals`, `equippedTrailSkinId`, `gameBests`, dsb.
- **Entitlement:** enum `SupporterEntitlement { ENTITLED, NOT_ENTITLED, UNKNOWN }` — status entitlement ditentukan server dan dipakai kode ter-obfuscate (`smali_classes3` paket `Ac`, `Db`, `Pb`, `Tb`).
- **Level akun:** `AccountLevels.MAX_LEVEL = 50`, dengan reward gates & thresholds.
- Pembelian memakai **Play Billing mentah** (bukan RevenueCat/Adapty): class `m9.C8481s` (ter-obfuscate) memanggil `launchBillingFlow` dengan `ProductDetails`; sebelum bayar ada cek "Account changed" (akun tidak boleh berganti di tengah transaksi).

### 3.5 Yang disimpan lokal vs server

| Data | Lokasi |
|---|---|
| Profil User, entitlement, energi, level/XP, referral, koleksi burung | **Server** (Firestore + Cloud Functions); di-cache lokal via Room (`RoostDatabase`) + DataStore |
| Katalog burung + sprite, konten game Stormpost (balance/difficulty), paywall default | **Lokal** (assets; katalog & balance bisa di-override server — ada field `revision`/`contentVersion`/`simulationVersion`) |
| Surat, teman pena, aktivitas | **Server** (koleksi `letters`, `birds`) |
| Toko/rotasi/deals | **Server** (`ShopStorefront` dari backend) |
| Surat draf, scratchpad, cache gambar | Lokal (cache dir / Room) |
| Backup | **Mati** (`allowBackup="false"`, `dataExtractionRules` + `backup_rules`) |

---

## 4. Penilaian modding (jujur, per fitur — server-side vs lokal)

**Tidak ada mod yang dibangun dalam analisis ini.** Penilaian di bawah hanya klasifikasi berdasarkan bukti statis.

| Fitur | Vonis | Bukti / alasan |
|---|---|---|
| **Unlock Supporter / Founder (premium)** | ❌ **TIDAK BISA** (server-side) | Entitlement `ENTITLED/NOT_ENTITLED` ditentukan server; benefit (energi, limit pen-pal) adalah field profil User yang di-sync dari Firestore; pembelian lewat Play Billing dan diverifikasi server. Flip flag lokal paling banter mengubah tampilan UI, server tetap menolak. |
| **Unlimited training energy** | ❌ **TIDAK BISA** (server-side) | `trainingEnergy`/`maxTrainingEnergy`/`lastEnergyUpdate` adalah field profil server; recharge dihitung server. |
| **Pen Pal requests tanpa batas** | ❌ **TIDAK BISA** (server-side) | Limit 5 vs 20/hari ditegakkan backend (Cloud Functions/Firestore). |
| **Unlock semua burung / koleksi** | ❌ **Tidak berguna** (server-side) | Katalog + sprite memang lokal, tapi kepemilikan (`pigeonCount`, `codexCaughtCount`) ada di profil server; drop bulanan (odds Epic 75% dst.) digerakkan server. |
| **Item toko / deals gratis** | ❌ **TIDAK BISA** (server-side) | Storefront (rotation, schedule, deals, revision) diambil dari server; harga & offer ID server. |
| **Ubah balance game Stormpost** (damage, upgrade, difficulty) | ⚠️ **Data lokal, tapi tidak viable** | `content-v4.json` memang file lokal — tapi mengubahnya butuh repack APK, dan repack merusak tanda tangan → **PairIP license check + App Check Play Integrity gagal** → aplikasi tidak lolos verifikasi lisensi dan request backend ditolak. Selain itu repack/distribusi mod dilarang dalam tugas ini. |
| **Hilangkan iklan / ad-free GIF picker** | ❌ **TIDAK BISA** (server-side) | Benefit Supporter, dikontrol entitlement server. |
| **Bypass lisensi / PairIP** | ❌ **DITOLAK** | PairIP adalah proteksi anti-tamper + LVL; bypass-nya di luar batas tugas ini (dan di luar batas asisten secara umum). |
| **Baca konten tanpa login / offline penuh** | ⚠️ Sebagian | Katalog burung, konten game, dan paywall default bisa dibaca offline (sudah ada di dump); tapi surat, teman pena, toko, dan drop butuh akun + server. |

**Ringkasan vonis:** semua yang bernilai uang (premium, energi, limit, burung, toko) adalah **server-side**. Satu-satunya yang "lokal" adalah data konten (katalog burung, balance game, paywall default) — dan itupun tidak bisa dimanfaatkan tanpa repack, yang justru memicu proteksi PairIP + Play Integrity.

---

## 5. Batasan jujur

- **Tidak ada analisis runtime:** APK tidak diinstal/dijalankan; tidak ada Frida, tidak ada Ghidra/IDA (tidak tersedia di VM ini) — tidak ada dekompilasi native mendalam. Semua `.so` stripped; analisis native hanya sebatas inventaris + strings.
- **Kode ter-obfuscate R8:** hanya 578 class aplikasi dan sebagian besar nama class/method sudah diganti (paket 1–2 huruf). Alur detail (mis. nama Cloud Function yang dipanggil, urutan validasi pembelian) tidak bisa dipulihkan penuh dari statis.
- **JADX:** 33.454 dari ~37.060 class berhasil di-decompile; **214 class gagal** decompile (error JADX). Smali lengkap tetap tersedia sebagai fallback.
- **Harga subscription & nama Cloud Function** tidak ada di APK (diambil dari Play Store / dipanggil via SDK) — tidak bisa dipastikan dari statis.
- **Token Mapbox & Firebase API key** memang tertanam di APK (kunci klien publik), tapi nilai lengkapnya sengaja tidak ditulis di laporan ini.
- **Tidak ada pengujian keamanan dinamis** (mis. apakah server benar-benar menolak entitlement palsu) — vonis "server-side" didasarkan pada arsitektur yang terlihat (model server-synced + Play Billing + App Check + PairIP), bukan pada percobaan bypass.

---

## 6. Isi dump (`~/workspace/rea-roost-social/dump/`)

Total dump ±1,1 GB (termasuk `extract/` di luar `dump/`). Struktur:

```
~/workspace/rea-roost-social/
├── REPORT.md                  ← laporan ini
├── extract/                   ← hasil ekstrak XAPK (4 file: base APK + 2 split + manifest.json)
│   ├── com.rookery.courier.apk
│   ├── config.arm64_v8a.apk
│   ├── config.xxhdpi.apk
│   └── manifest.json
└── dump/
    ├── apk_contents/          ← isi base APK diekstrak utuh (5.008 file, 126 MB)
    │   ├── AndroidManifest.xml (biner), classes.dex…classes4.dex
    │   ├── assets/ (3.493 file: katalog burung, sprite, skyward, paywall…)
    │   ├── res/, resources.arsc, META-INF/
    ├── splits/
    │   ├── arm64_v8a/        ← lib/arm64-v8a/*.so (9 file, 43 MB) + manifest
    │   └── xxhdpi/           ← resource density split (628 KB)
    ├── apktool/               ← hasil `apktool d` (decode lengkap)
    │   ├── AndroidManifest.xml (sudah ter-decode, bisa dibaca)
    │   ├── res/ (782 file), assets/, kotlin/, original/, unknown/
    │   └── smali, smali_classes2, smali_classes3, smali_classes4/ (37.060 file .smali)
    ├── jadx/                  ← hasil decompile JADX (33.454 file .java, 320 MB)
    │   └── sources/com/rookery/courier/… (kode aplikasi; sisanya library ter-obfuscate)
    ├── strings/
    │   ├── classes.txt, classes2.txt, classes3.txt, classes4.txt (203.195 baris)
    │   └── native/*.txt       ← strings tiap .so (111.466 baris)
    ├── class_list.txt         ← daftar lengkap 37.060 class (dari dexdump)
    ├── apktool.log, jadx.log  ← log tool
    └── (file-file kerja lain)
```

**Cara membaca:**
- Mau lihat manifest/permissions/komponen → `dump/apktool/AndroidManifest.xml`.
- Mau cari string/URL/endpoint → `dump/strings/*.txt` (grep biasa).
- Mau baca logika aplikasi → `dump/jadx/sources/com/rookery/courier/` (model di `core/models/` paling mudah dibaca; sisanya ter-obfuscate) atau `dump/apktool/smali_classes2|3/...` untuk smali.
- Mau lihat data game/katalog → `dump/apk_contents/assets/skyward/content-v4.json`, `dump/apk_contents/assets/bundled_bird_types.json`, `dump/apk_contents/assets/paywall_benefits_default.json`.
- Mau cek native lib → `dump/splits/arm64_v8a/lib/arm64-v8a/`.

**Statistik dump:** 37.060 class • 206.427 method • 165.890 string (DEX) • 37.060 file smali • 33.454 file Java (214 gagal decompile) • 5.008 file konten APK • 3.493 file assets • 314.661 baris strings total.

---

## 7. Catatan keamanan untuk user

1. **File dari link APKPure itu asli** (hash + tanda tangan cocok, Play App Signing) — bukan repack.
2. **Izin yang paling sensitif:** lokasi presisi, kamera, rekam audio, baca kontak, deteksi screenshot. Saat install, periksa izinnya satu per satu; lokasi & kontak bisa ditolak kalau tidak butuh fitur peta/teman-dari-kontak.
3. **Akun & data ada di server Firebase developer** (bukan di HP) — termasuk surat dan lokasi. Itu wajar untuk aplikasi sosial, tapi sadar saja datanya tersimpan di server mereka.
4. **Jangan install versi "Mod Premium" aplikasi ini** yang beredar di situs mod (contoh: klaim "Unlimited Premium" untuk paket yang sama) — dari analisis ini premium-nya server-side, jadi mod seperti itu tidak bisa benar-benar membuka premium, dan besar kemungkinan disisipi sesuatu.
