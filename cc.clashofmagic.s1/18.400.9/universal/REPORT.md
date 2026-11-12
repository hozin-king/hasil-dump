# Laporan Dump & REA — "Magic S1" (Clash of Magic)

Tanggal analisis: 22 Oktober 2026 (WIB)
Metode: unduh dari CDN operator (`cdn-s3.clashofmagic.net`) → unzip penuh → aapt2/apksigner → strings/readelf/nm atas lib native → JADX per-kelas atas paket operator → inventaris aset. Analisis statis murni; tidak ada server yang dihubungi, tidak ada klien yang dijalankan/diubah.

---

## 1. Identitas (terverifikasi dari file)

| Item | Nilai |
|---|---|
| Nama file | `Magic_S1-18.400-R2.apk` |
| Ukuran | 597.114.243 byte (±597 MB) |
| SHA-256 | `d48bd64a08510e170776a6d62cdea288f2148714640980df58ceafde25bbebd4` |
| Package | `cc.clashofmagic.s1` |
| Nama tampil | "Magic S1" |
| Versi | versionName **18.400.9** / versionCode **3714** (penomoran mengikuti Clash of Clans 18.400; `assets/build.tag` = `18_400_7`) |
| SDK | minSdk 24 / targetSdk 35 / compileSdk 35 |
| Kelas Application | `com.atrasis.main.AtrasisApplication` |
| Aktivitas peluncur | `com.atrasis.main.AtrasisGameApp` (label "Magic S1"), mewarisi `com.supercell.titan.GameApp` |
| Aktivitas lain milik operator | `com.atrasis.main.GateActivity`, `com.atrasis.main.WebFallbackActivity` |
| Deeplink | `clashofmagic-s1` (assets/config.json) |
| Izin mencolok | `MANAGE_EXTERNAL_STORAGE` (akses semua berkas — diminta saat jalan), `INTERNET`, `com.android.vending.BILLING`, `com.supercell.id.SHARED_DATA_ACCESS`, notifikasi, AD_ID |

Isi ZIP: 5.427 entri — 7 dex utama + 2 dex di aset, 18 lib `.so` × 2 ABI (arm64-v8a & armeabi-v7a), aset 624 MB.

## 2. Vonis tanda tangan: BUKAN Supercell — tanda tangan ulang operator

- Penandatangan tunggal: **CN=Patrik Super** (SHA-256 sertifikat `ab838d3842a52a4eaccd9a3e800ca32b4c0e506d0995e18684f69a1f89fc6d01`).
- Ini **bukan** sertifikat rilis Supercell. Kesimpulan: basisnya adalah **klien gim Supercell asli** (seluruh mesin, aset, dan framework identik dengan rilis resmi) yang **ditandatangani ulang dan ditambal oleh operator pihak ketiga** — fondasinya proyek **Atrasis** (peluncur klien server privat CoC; kelas `com.atrasis.*`, lib `libatrasis.so`, domain `atrasis.net`/`atrasisclash.net`).

## 3. Peta lib native (per ABI; angka = arm64-v8a)

| Lib | Ukuran | Peran (bukti) |
|---|---|---|
| `libg.so` | 24.353.576 | **Mesin gim utama** — klien "magic" + framework **titan** Supercell (render Vulkan sc3d). Jalur build terbaca di strings: `/build/workspace/magic/client/...`, `/build/workspace/magic/titan/...` (MessageManager, BillingManager, AllianceWarManager, dsb) |
| `libapp.so` | 14.353.328 | Kode Dart AOT **Flutter** — antarmuka Supercell ID modern |
| `libflutter.so` | 11.037.032 | Runtime Flutter |
| `libscid_sdk.so` | 2.267.048 | SDK native **Supercell ID** (juga NEEDED oleh libg) |
| `libatrasis.so` | 602.064 | **Jembatan JNI operator** (`Atrasis_init`, `JNI_OnLoad`, `Java_com_atrasis_main_AtrasisGameApp_initConfig__Ljava_lang_String_2`, `nOnDispose`, `nDebugAction`, callback iklan MediationManager, callback `NativeHTTPClientManager`) |
| `libfmod.so` | 1.179.776 | Audio FMOD (standar Supercell) |
| `libsentry.so` + `libsentry-android.so` | 704.344 + 16.832 | Pelaporan crash **Sentry** |
| `libc++_shared.so` | 1.292.904 | Runtime C++ (libc++) |
| `libapminsighta/b.so`, `libnms.so`, `libtt_ugen_layout.so`, `libpglarmor.so`, `libbuffer_pgl.so`, `libfile_lock_pgl.so` | kecil–sedang | Rumpun iklan/telemetri **ByteDance Pangle** |
| `libimage_processing_util_jni.so`, `libdatastore_shared_counter.so` | kecil | JNI AndroidX (CameraX/Datastore) |

**Packing/obfuscation:** libg.so adalah ELF AArch64 normal — header & tabel section utuh (13 section PROGBITS), daftar NEEDED normal (`libscid_sdk`, `libfmod`, `libsentry`, `libEGL`, `libc++_shared`, …), entry point 0x1740000. **Tidak ada tanda packer/app-shield** (beda dengan kasus HCR2 yang section-nya dimusnahkan). Strings jalur sumber & pesan assert Supercell terbaca luas; yang disembunyikan rilis Supercell seperti biasa hanyalah nama/simbol kripto (lihat §6).

## 4. Peta DEX (9 berkas; dump di `dump-dex/`)

| Dex | Ukuran | Isi dominan |
|---|---|---|
| `classes.dex` | 8.834.420 | SDK: ByteDance APM Insight, IronSource, AppsFlyer |
| `classes2.dex` | 468 | Nyaris kosong (stub) |
| `classes3.dex` | 8.536.700 | ByteDance/Pangle + **`com.atrasis.main`** — seluruh kode operator (lihat §5) |
| `classes4.dex` | 8.738.248 | Campuran SDK iklan |
| `classes5.dex` | 7.667.924 | IronSource (dominan), HelpShift, jembatan Unity Ads |
| `classes6.dex` | 9.130.720 | Sentry + **`com.supercell.titan`** (GameApp & framework Java) + **`com.supercell.id`** |
| `classes7.dex` | 4.586.032 | Kotlin stdlib/runtime |
| `assets/audience_network/classes.dex` + `classes2.dex` | 57.076 + 5.237.600 | Meta Audience Network (dimuat dinamis) |

**Fakta arsitektur penting: logika gim TIDAK ada di dex.** Dex hanya berisi framework Java titan, Supercell ID, lapisan operator Atrasis, dan tumpukan SDK iklan/analitik (IronSource/LevelPlay, Pangle, AppsFlyer, HelpShift, Sentry). Seluruh permainan berjalan di `libg.so`.

Kode operator yang berhasil di-decompile utuh tersimpan di `analysis/atrasis_src/` (AtrasisGameApp, GateActivity, GateVerifier).

## 5. Arsitektur klien & cara ia diarahkan ke server pihak ketiga (TERBUKTI dari file)

Urutan boot yang terbaca dari kode:

1. **Gerbang verifikasi operator ("Gate")** — `GateActivity` membuat `GateVerifier("https://gate.atrasis.net")` lalu POST JSON ke **`https://gate.atrasis.net/verify`** berisi info perangkat: brand, model, versi OS, `build_fingerprint`, board, hardware, product, bootloader, ABI yang didukung, metrik layar, nama paket, timestamp — plus flag `is_physical_device` dari **heuristik emulator** (fingerprint/model mengandung "generic/emulator/sdk_gphone", hardware "goldfish/ranchu/vbox86", dsb).
   - Respons **HTTP 204 = lolos**: dibuat berkas penanda kosong bernama `allowed` di filesDir (kunjungan berikutnya langsung lolos tanpa POST), lalu `AtrasisGameApp` dimulai.
   - Selain 204 / error jaringan: pengguna dialihkan ke `WebFallbackActivity` yang membuka **`https://www.atrasisclash.net/forum/`**.
   - Ini pada dasarnya **gerbang anti-emulator/anti-bot milik operator** di sisi klien — bukan autentikasi akun.
2. **Lapisan Atrasis menempel pada kerangka Supercell** — `AtrasisGameApp extends com.supercell.titan.GameApp`; konfigurasi diteruskan ke native lewat JNI **`initConfig(String)`** di `libatrasis.so` (yang juga mengekspor `Atrasis_init`, `nDebugAction`, dan callback HTTP/iklan). Ada pula **DebugMenuOverlay** + `nDebugAction(String,int)` — menu debug operator tertanam di klien.
3. **Server gim** — string konfigurasi di dalam `libg.so` sendiri memuat host operator:
   - **`s1.clashofmagic.cc`** (host server gim S1),
   - **`link-s1.clashofmagic.cc`** (http & https — layanan "link device" ala pola resmi `link.clashofclans.com` yang juga masih ada string-nya).
   - Tidak ada alamat IP literal di strings; port TCP tidak tampil sebagai string (di kode native) — **angka port persisnya belum terkonfirmasi dari pembacaan ini**.
4. **Autentikasi akun = Supercell ID yang diarahkan ulang** — `assets/supercell_id_config.json`: `"Game": "magic"`, `"Environment": "magic-s1"`, `UseNative: true`, berkas UI `sc/supercell_id.sc`; libg memuat `id.supercell.com` dan lib `libscid_sdk.so` dirangkai sebagai NEEDED. Jadi alur login memakai infrastruktur Supercell ID dengan environment milik operator.
5. **Telemetri campuran** — string libg masih memuat endpoint Supercell asli: `report.mtech.supercell.com/v1/track`, `inventory.mtech.supercell.com/v1/serve` (dan varian `-dev`), `store.supercell.com`, `support.supercell.com`; ditambah Sentry (Flutter, DSN dari konfigurasi rilis — nilainya tidak tampil di strings), AppsFlyer, IronSource/LevelPlay, Pangle untuk iklan & atribusi.
6. **Pengawasan sisi operator** — `AtrasisGameApp.getInstalledBaseApks()` mengembalikan daftar **semua aplikasi terpasang beserta versionName-nya** ke sisi native (pola pemeriksaan klien lain/mod yang terpasang — fungsi anti-cheat/telemetri operator; pemakaian akhirnya di native tidak terbaca dari Java saja).
7. **Cek versi/paksa update** — `assets/fingerprint.json` = sidik jari SHA-1 per berkas aset (mekanisme "data version" Supercell; strings libg memuat kegagalan login karena versi data: `LoginFailed due to data version...`), ditambah SDK app-update bawaan (`app-update.properties`, client 2.1.0).

Protokol gim di native mempertahankan kerangka pesan Supercell (strings: `LoginMessage`, `LoginOkMessage received without proper validation`, `Server didn't reply to the LoginMessage in %i seconds`, `UseSessionToken`) — klien berbicara ke server yang meniru protokol resmi.

## 6. Kripto — yang terbukti vs yang belum

**Terbukti dari berkas:**
- Berkas grafis `.sc` memakai kontainer **"SC" versi 6** (magic `53 43 06...`) — format kontainer terkompresi khas Supercell.
- Hash aset: SHA-256 (string `SCFILE_FLAG_HASH_SHA256`), sidik jari berkas SHA-1 di fingerprint.json.
- `assets/logic/*.csv` (91 berkas data gim) tampil sebagai **data biner entropi-tinggi** — terenkripsi/terkompresi, tidak terbaca sebagai teks (berbeda dengan `globals.json` yang JSON polos).

**Belum terkonfirmasi dari berkas ini:**
- Skema enkripsi **transport sesi gim** (handshake & enkripsi stream antara klien–server S1): nama algoritma/kunci tidak muncul di strings libg (stripping khas rilis Supercell). Pola genre Supercell pada umumnya memakai enkripsi stream + pertukaran kunci pada handshake login, tetapi untuk build ini hal itu **tidak dibuktikan dari file** — perlu bedah disassembly libg untuk memastikannya, di luar cakupan dump ini.
- Literal string yang dioper ke `initConfig(String)` (dibentuk saat runtime).
- Port TCP server `s1.clashofmagic.cc`.

## 7. Aset (624 MB di dalam APK)

Struktur persis rilis CoC modern: `sc/` + `sc3d/` (grafis kontainer SC), `csv/` (25 berkas), `logic/` (**91 CSV data gim** — bangunan, unit, aliansi, dsb; biner terenkripsi/terkompresi), `globals.json` + `globals_definition.json` (**JSON polos terbaca** — nilai global & kill switches gim), `fingerprint.json`, `assets.scdb` (**SQLite** — basis data dependensi aset), `music/` + `sfx/` (FMOD), `ui/`, `localization/`, `helpshift/`, `flutter_assets/`, `supercell_id_config.json`, `titan/`, `sirius/`, `shaders/`, `video/`.

## 8. Ukuran dump

Total folder kerja `~/workspace/rea-clashofmagic/` ≈ **1,5 GB**:
- `downloads/` 570 MB (APK asli)
- `extracted/` 779 MB (seluruh isi APK terekstrak)
- `dump-libs/` 102 MB (18 `.so` × 2 ABI, struktur per ABI)
- `dump-dex/` 51 MB (9 berkas dex)
- `analysis/` 1,7 MB (ziplist, strings libg/libatrasis/libapp, sensus paket dex, sumber Java operator hasil decompile di `atrasis_src/`)

## 9. Yang tidak terkonfirmasi

1. Port TCP & alamat IP server S1 (host saja yang terbukti: `s1.clashofmagic.cc`).
2. Skema enkripsi transport sesi & manajemen kunci (perlu disassembly).
3. Literal konfigurasi runtime untuk `initConfig` dan pemakaian akhir daftar aplikasi terpasang di native.
4. Isi sebenarnya 91 berkas `logic/*.csv` (terenkripsi/terkompresi; tidak didekripsi pada tugas ini).
5. Nilai DSN Sentry produksi (digerakkan konfigurasi rilis, tidak tampil di strings).
6. Apakah `gate.atrasis.net` / `s1.clashofmagic.cc` aktif saat ini — tidak dihubungi; analisis ini statis sepenuhnya.
7. Decompile JADX dilakukan per-kelas untuk paket operator (`com.atrasis.main`) + sensus paket untuk sisanya; decompile menyeluruh 45 MB dex SDK iklan tidak dilakukan (tidak relevan dengan pertanyaan REA dan terbatas RAM).
