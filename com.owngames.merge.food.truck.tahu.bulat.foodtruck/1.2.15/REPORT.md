# REPORT — Food Truck City (Food Truck Tahu Bulat) 1.2.15

**Dump full + REA statis (tanpa install / tanpa jalankan APK).**

- **Judul:** Food Truck City (judul Indonesia: Food Truck Tahu Bulat)
- **Package:** `com.owngames.merge.food.truck.tahu.bulat.foodtruck`
- **Version:** 1.2.15 / versionCode 35
- **Developer:** Own Games
- **Sumber APK:** APKPure (XAPK), diunduh via browser
  — `Food_Truck_City_1.2.15_APKPure.xapk`, 24.989.058 byte,
  SHA-256 `e6d7270b420751455c3a5089c5623890b022f66bfd8583101ad6598e4faefeba`
- **Tanggal analisis:** 26 November 2026
- **ABI yang dianalisis:** arm64-v8a (satu-satunya ABI di XAPK)

> **Catatan keamanan:** sesuai aturan REA, APK sumber dihapus total setelah
> hasil ini ter-push. Nilai kunci enkripsi save game **tidak** dicantumkan
> di laporan publik ini (hanya nama file + alamat fungsi konstruksi).

## Ringkasan

Food Truck City adalah game simulasi/idle tycoon (merge food truck, bangun
kota) dari Own Games — studio yang sama dengan Tahu Bulat. Engine-nya
**bukan Unity/Godot**, melainkan framework C++ sendiri ("Own Engine"):
`libnative-lib.so` (kode game) + `libownengine.so` (UI, save, IAP, cloud)
+ Box2D (fisika) + libxml (konfigurasi), render OpenGL ES.

**Temuan terpenting:** format save game **sama persis dengan Tahu Bulat**
— `OwnSaveData`, cipher DES/ECB/PKCS5Padding, file di disk = nama file +
`"data"`. Ada **4 file save** (`Config`, `Data`, `Achievement`,
`AnalyticData`), masing-masing dengan key DES sendiri, dibangun di
`libnative-lib.so`. File save kiriman user (`Datadata_1_hjdc.bin`,
1.936 byte) adalah save `Data` — **decrypt terverifikasi: JSON valid,
39 top-level key**. Ke-17 key Tahu Bulat semuanya gagal ke file ini,
sesuai dugaan bahwa key-nya berbeda per game.

Tidak ditemukan deteksi root / emulator / Play Integrity / anti-cheat
di dex maupun native. IAP memakai Google Play Billing (katalog produk
tidak literal di APK). Satu-satunya backend game: OwnConnect
(`ownconnect.tahoogle.com`).

## 1. Identitas APK

| Item | Nilai |
|---|---|
| Package | `com.owngames.merge.food.truck.tahu.bulat.foodtruck` |
| versionName / versionCode | 1.2.15 / 35 |
| minSdk / targetSdk / compileSdk | 21 / 34 / 34 |
| Nama aplikasi | Food Truck City |
| Main activity | `com.owngames.merge.MainActivity` |
| Base APK | 18.193.805 byte |
| XAPK total | 24.989.058 byte (6 entri: base + config.fr/en/arm64_v8a/mdpi + manifest.json) |
| Signing | v1 + v2 + v3, self-signed gaya AOSP (CN=Android, OU=Android, O=Google Inc.), SHA-256 `192ab9cce76fbdeeacdc1a1b6d1d9af825d97e70d42db4a9b2121b884002db95` |

Permission (10): INTERNET, ACCESS_NETWORK_STATE, WRITE_EXTERNAL_STORAGE,
READ_EXTERNAL_STORAGE, BILLING, AD_ID, WAKE_LOCK, RECEIVE_BOOT_COMPLETED,
FOREGROUND_SERVICE, BIND_GET_INSTALL_REFERRER_SERVICE.

Activities: MainActivity + OwnConnect SDK (Login/Register/Password/Contact/
Report/UploadAttachment) + Facebook + AdMob + Play Games. Services:
Firebase/AdMob/WorkManager/AppMeasurement. Providers: FirebaseInitProvider,
FileProvider, Facebook, PlayGames, MobileAdsInitProvider.

## 2. DEX

- **Single `classes.dex`**: 7.461.256 byte, 11.080 class, 55.460 method,
  31.147 field (bukan multidex).
- Top package: `com.google` 6.758 class (Firebase, AdMob, Play Games, Play
  Billing), `com.facebook` 566 class, `com.owngames` 144 class.
- Class `Lcom/owngames/ownengine/io/OwnSaveData;` **ada** di dex
  (`doLoad`/`doSave`/`loadData`), tapi **0 method Java memanggilnya** —
  jalur save sepenuhnya native.
- `JavaHelper`: 0 hit (tidak ada tabel key Java seperti Tahu Bulat).
- String `Datadata`/`owndata`/`.own`/`saveDataName`/`encryptCode`: 0 hit di dex.
- Detail: `dump/dump-dex.txt`, `dump/classes.txt`, `dump/FINDINGS-dex.md`.

## 3. Engine — native C++ (Own Engine), bukan Unity/Godot

| Library | Ukuran | Peran |
|---|---|---|
| `libnative-lib.so` | 1.800.352 B | Kode game (stripped) |
| `libownengine.so` | 2.271.472 B | Framework Own Engine |
| `libownbox2d.so` | 551.080 B | Fisika Box2D |
| `libownlibxml.so` | 1.983.848 B | XML konfigurasi |

Bukti: tidak ada `libunity.so`/`libgodot`; `libnative-lib.so` me-link
EGL/GLESv2; aset konfigurasi XML plaintext (`LevelData.xml`,
`lang_en.xml`, `lang_id.xml`, `tutorial.xml`); audio `.oga`/`.ogm`
dengan nama file ter-obfuscate; toolchain NDK Clang 9.0.8.

## 4. Format save game — OwnSaveData + DES/ECB (sama seperti Tahu Bulat)

Empat file save, dibangun via `OwnSaveDataC1(string filename, string key)`
di `libnative-lib.so` (PLT stub 0x79460, GOT 0x1b6e40):

| File (di disk) | Call site BL | Literal .rodata |
|---|---|---|
| `Configdata` | 0xdc7f8 | `Config` @ 0x1672dd |
| `Datadata` | 0xdd7c4 | `Data` @ 0x1683a6 |
| `Achievementdata` | 0xe9334 | `Achievement` @ 0x167d10 |
| `AnalyticDatadata` | 0xf019c | `AnalyticData` @ 0x16839e |

Cipher DES/ECB/PKCS5Padding; file di disk = nama file + `"data"`.
Nama file + key tidak tersimpan sebagai literal polos yang mudah dicari —
baru terungkap setelah tracing BL ke PLT stub + resolve ADRP+ADD di tiap
call site (pemetaan PLT: decode adrp+ldr tiap stub, 1.452 target).

**Verifikasi decrypt (file user `Datadata_1_hjdc.bin`, 1.936 byte =
242 blok × 8 byte):** DES/ECB terkonfirmasi (blok berulang 47× di ekor);
ke-17 key Tahu Bulat **gagal semua**; dengan key file `Data` dari
`libnative-lib.so` → **JSON valid, 39 top-level key** (daftar nama field
di `dump/FINDINGS-save.md` — tanpa nilai). Key Config/Achievement/
AnalyticData terhadap file ini gagal, sebagaimana mestinya.

Cloud save juga tersedia via `OwnGPGSManager::doSaveCloud/doLoadCloud`
(Google Play Games) — tidak dianalisis runtime.

Detail: `dump/FINDINGS-save.md`, `dump/FINDINGS-native.md`.

## 5. IAP

- Google Play Billing Client (SkuDetails/ProductDetails,
  `ProxyBillingActivity`/`V2`, string `Error acknowledge purchase!`).
- `OwnIAPManager` native: `getItemDesc` / `getPriceFor` /
  `isUdahBeliIAP` / `setMyGameId` + jembatan JNI `IAPManager_IAPDataBought`.
- **Tidak ada product ID / SKU literal** di dex maupun native — katalog
  kemungkinan dari Play Console / server. Tidak ada analisis bypass.

## 6. Anti-cheat / root detect

- **Tidak ditemukan.** String search native (`root|magisk|frida|xposed|
  ptrace|TracerPid|safety|integrity|cheat|tamper`): tidak ada hit relevan
  (hanya istilah scene-graph seperti `PopToRoot`).
- Dex: 121 hit `[root/debug]` semuanya generik; `AndroidRootResolver`
  adalah nama class Play Games, bukan deteksi root.
- Tidak ada SafetyNet / Play Integrity API di dex.

## 7. Network / endpoint

- `https://ownconnect.tahoogle.com/Forum/OCSDK2/` (backend forum OwnConnect)
- `https://own-games.com/privacypolicy.php`
- Play Store links (game ini + Tahu Bulat)
- Endpoint standar Google / Facebook / AdMob / Firebase (SDK).
- Tidak ada Supabase, tidak ada API game sendiri yang terlihat.

## 8. Iklan

- AdMob (SDK di dex) + Meta Audience Network (`audience_network.dex`
  3.167.108 byte di `assets/`).

## 9. Aset

- 477 file di `assets/`; direktori ter-obfuscate (`sxD/`, `435b9ifle6/`,
  `l_/`, `kil5bj/`, `43cfe/`, `ODC/`); sebagian besar audio `.oga`/`.ogm`
  + XML konfigurasi plaintext (`XML/LevelData.xml`, `lang_en.xml`,
  `lang_id.xml`, `tutorial.xml`).
- Aset terbesar: `audience_network.dex` (3,1 MB), `Jgc3j` (1,2 MB),
  audio `.ogm`/`.oga` s.d. ~930 KB.
- Detail: `dump/assets-inventory.txt`.

## 10. Metode

Analisis statis saja (androguard 4.1.4, capstone 5.0.7, pyelftools,
readelf/nm/strings). APK tidak di-install dan tidak dijalankan.
Pencarian konstruktor save: pemetaan PLT stub → GOT slot (decode
adrp+ldr), cari semua BL ke stub `OwnSaveDataC1`, lalu resolve string
argumen lewat ADRP+ADD mundur dari tiap call site. Dua jebakan parser
yang sempat menyesatkan: capstone mencetak target BL dengan prefix `#`
(`#0x79460`) dan immediate ADRP sebagai alamat halaman absolut —
keduanya sudah diperbaiki sebelum hasil final.

## 11. Isi folder dump

```
REPORT.md
dump/
  manifest-clean.txt            — AndroidManifest (bersih, via androguard)
  dump-dex.txt                  — ringkasan dex + strings penting
  classes.txt                   — 11.080 nama class dex
  dex-strings-interesting.txt   — strings dex terkurasi
  zip-inventory.txt             — isi XAPK + base APK
  assets-inventory.txt          — inventaris aset
  native-inventory.txt          — inventaris .so (ukuran, hash, NEEDED)
  hashes.txt                    — SHA-256 semua artefak sumber
  signer.txt                    — info signer + manifest
  libnative-lib-exports.txt     — simbol dinamis libnative-lib.so
  libownengine-exports.txt      — simbol dinamis libownengine.so
  libnative-lib-strings.txt(.gz)        — semua strings libnative-lib.so
  libownengine-strings.txt(.gz)         — semua strings libownengine.so
  libnative-lib-strings-interesting.txt — strings native terkurasi
  libownengine-strings-interesting.txt  — strings native terkurasi
  FINDINGS-dex.md               — temuan detail dex
  FINDINGS-native.md            — temuan detail native (call site save)
  FINDINGS-save.md              — format save + verifikasi decrypt
```
