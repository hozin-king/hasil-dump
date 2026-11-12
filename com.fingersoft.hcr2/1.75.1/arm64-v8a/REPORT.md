# Laporan REA Penuh — Hill Climb Racing 2 v1.75.1

Tanggal bedah: 22 Oktober 2026 · Sumber: file Google Drive yang dikirim user
Folder kerja: `~/workspace/rea-gdrive-20261022/`

---

## 1. Identitas (terbukti dari file)

| Item | Nilai |
|---|---|
| Nama file unduhan | `Hill Climb Racing 2_1.75.1.apks` (184.549.185 byte) |
| SHA-256 (.apks) | `b768d0e51681193d29d62e837cf45b1a0c597dd3f354838cab37cd53f2dc031a` |
| Format | Android App Bundle ter-zip (.apks): base.apk + 5 split |
| Nama game | Hill Climb Racing 2 |
| Package | `com.fingersoft.hcr2` |
| versionName / versionCode | 1.75.1 / 740 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 |
| Sertifikat penanda tangan | **ASLI Fingersoft** — DN `CN=Developer, O=Fingersoft, C=FI`, SHA-256 cert `d8789081e1fc1d91efa1eb742e3ee66be858dfd07e1fe56fe87b00d1bceaea12`, plus Google Source Stamp. **Bukan APK modifan.** |
| Activity launcher | `com.fingersoft.hcr2.AppActivity` |

Isi bundle:

| Split | Isi |
|---|---|
| `base.apk` (210.443.733 byte) | Kode (10 dex), resources, seluruh assets (167 MB) |
| `split_config.arm64_v8a.apk` (32,4 MB) | Semua library native arm64-v8a (base.apk tidak punya folder `lib/`) |
| `split_config.in.apk` | Konfigurasi bahasa (in = Indonesia) |
| `split_config.xxhdpi.apk` | Konfigurasi densitas layar |
| `split_gpdeku.apk` + `split_gpdeku.config.arm64_v8a.apk` | Modul Google Play "Deku" (screen capture untuk perekaman gameplay Play Games) + lib nativenya |

## 2. Engine & arsitektur

- **Engine: Cocos2d-x (C++)** — dibuktikan oleh `libcocos2dcpp.so` (36,3 MB) dan struktur assets khas Cocos (`Common/ui/cocosstudio/*.csb` = Cocos Studio FlatBuffers, `.plist` partikel, shader `.vsh/.fsh`, RUBE = format Box2D).
- **Lapisan Java/Kotlin**: 10 file dex (±85 MB total, mayoritas SDK iklan/analitik/Firebase/Play Games). Kelas milik Fingersoft ada di `classes5.dex` (2.424 referensi `com/fingersoft`) — sudah di-JADX (3.938 file .java hasil dekompilasi di `extracted/jadx_classes5/`).
- **Jembatan Java↔native**: `com.fingersoft.hcr2.AppActivity` mendeklarasikan ±121 method `native` (121 simbol `Java_com_fingersoft_hcr2_AppActivity_*` diekspor `libcocos2dcpp.so`): status VIP/langganan, iklan, A/B test, bahasa, dsb. Logika permainan sendiri hidup di C++.
- Paket internal Fingersoft di Java: `account_sdk` (Fingersoft ID), `billing`, `fs_android_ads`, `fsnewpromotion`, `home` (backend profil/DB), `liveops_sdk`, `hcr2`.

## 3. Inventaris library native (arm64-v8a saja)

| Library | Ukuran | Peran (bukti) |
|---|---|---|
| `libcocos2dcpp.so` | 36.340.288 | Engine Cocos2d-x + seluruh logika game; OpenSSL ter-link statis (ribuan simbol `AES_*`, `EVP_*`, `SSL_*` di .dynsym — itu OpenSSL bawaan, bukan bukti enkripsi aset). Ekspor terverifikasi: 2.557 nama bersih (JNI + OpenSSL + libc++); **simbol C++ game TIDAK diekspor** (visibility internal, .symtab dibuang) |
| `libfingersoft_hcr2.so` | 7.465.456 | Lib native Fingersoft (jembatan/SDK internal). Hanya mengekspor `JNI_OnLoad`; 217 impor libc/jaringan. **.text entropi 8.00 = terenkripsi** (lihat §6) |
| `libgpdeku.so` | 376.464 | Google Play Deku screen-capture (`Java_com_google_android_play_deku_screencapture_*`). **Bukan** lib kripto — dugaan awal dari namanya gugur oleh simbolnya sendiri |
| `libbts.so` | 974.512 | Promon backtrace-support (`no.promon.*`, Crashpad, PtraceHook) — komponen ekosistem **Promon** (crash reporting/shield) |
| `libwtp.so` | 944.896 | Promon juga (PtraceHook identik) |
| `libcrashlytics*.so` (4) | ±1,2 MB | Firebase Crashlytics |
| `libapplovin-native-crash-reporter.so` | 843.152 | AppLovin (iklan) |
| `libdatastore_shared_counter.so` | 7.112 | Pembantu AndroidX DataStore |

## 4. Inventaris aset (14.366 file, 167 MB, di `assets/`)

| Ekstensi | Jumlah | Status |
|---|---|---|
| .png | 7.115 | **Polos** — magic PNG valid |
| .txt | 2.046 | Polos (mayoritas file penanda 0 byte di folder tekstur mobil) |
| .json | 1.794 | **1.717 TERENKRIPSI** (game, di `Common/`) · 77 polos (Spine `skeleton.json` di `HD/textures/animations/`) |
| .csb | 1.255 | Polos — FlatBuffers Cocos Studio (header `14 00 00 00`) |
| .plist | 549 | Polos — XML |
| .ogg | 447 | Polos — magic `OggS` valid |
| .obj / .mtl | 276 / 209 | Polos — teks Blender |
| .rube | 191 | **SEMUA TERENKRIPSI** (level/fisika Box2D) |
| .dat | 105 | Campuran: protobuf polos & varian entropi-tinggi (lihat §5.3) |
| .atlas, .vsh/.fsh, .po, .fnt, .ttf, .js, dll | sisanya | Polos |

Struktur konten: `Common/` (json level & konfigurasi, textures mobil/pengemudi, audio, rube, cups, ghosts, particles, shaders, translations) dan `HD/` (tekstur & UI resolusi tinggi).

## 5. Enkripsi aset — fokus khusus

### 5.1 Yang terenkripsi, persisnya

Tepat **1.908 file**: seluruh `.rube` (191) + `.json` milik game (1.717) — level, konfigurasi mobil/part, `transform.json`, `particleVariants.json`, definisi cup, dsb. Ini data gameplay inti. Tekstur, audio, UI, model 3D, dan terjemahan **tidak** dienkripsi.

### 5.2 Karakteristik format (terbukti statistik dari seluruh korpus)

1. Setiap file diawali 8 byte konstan: **`12 13 AA 12 13 BA 13 BA`**. (Tidak ada byte ke-9+ yang bersama — jadi ini header format tetap 8 byte, atau blok pertama dari plaintext yang sama persis; belum bisa dipisahkan tanpa kode dekripsinya.)
2. Ukuran **semua** file terenkripsi kelipatan 8 byte → cipher blok 64-bit dengan padding (keluarga TEA/XTEA/Blowfish/DES/CAST), atau muatan yang diselaraskan 8 byte.
3. **Nol blok 8-byte berulang** di 738.563 blok korpus → **bukan ECB**; ada difusi antarblok (CBC/CTR/whole-file) atau cipher balok-utuh.
4. XOR dua ciphertext sejenis hanya nol di 8 byte pertama → bukan XOR kunci-periodik sederhana; keystream tidak dipakai ulang secara naif.
5. Entropi isi ±7,8–7,96 (acak penuh setelah header).

### 5.3 Uji dekripsi yang dijalankan — SEMUA NEGATIF (0 hit)

Korpus kunci: **40.668 string kandidat** (strings dari wilayah plaintext `libcocos2dcpp.so` + `libfingersoft_hcr2.so`, konstanta string Java hasil JADX classes5, tebakan nama game/studio) → **115.383 kunci turunan** (raw-16 zero-pad, MD5, SHA-256[0:16]). Validasi dua file berbeda + syarat plaintext JSON (`{` + karakter JSON wajar pada rantai blok CBC).

| Algoritma | Mode yang diuji | Hasil |
|---|---|---|
| XTEA (32 putaran) | ECB blok 0 & blok@8; CBC rantai blok 1–2; kedua endianness kata & kunci | 0 hit (±1,85 jt kombinasi pada uji CBC saja) |
| TEA | Sama seperti XTEA | 0 hit |
| XXTEA (konvensi xxtea-c, termasuk word panjang-awal) | Seluruh file, offset 0 & 8, 83.950 kombinasi × 2 file | 0 hit |
| Blowfish | CBC, kunci record 16B & string mentah (4–56B) | 0 hit |
| DES | CBC, kunci 8B | 0 hit |
| CAST5 / ARC2 | CBC, kunci 16B | 0 hit |

Script reproduksi: `work/brute_xtea.c`, `work/brute_xxtea.c`, `work/brute_cbc.c`, `work/brute_more.py`, karakterisasi format di `work/decrypt_hcr2_assets.py`. Folder `decrypted_samples/` **sengaja kosong** — tidak ada satu pun sampel yang berhasil didekripsi, dan tidak ada hasil karangan yang ditampilkan sebagai dekripsi.

### 5.4 Vonis enkripsi aset

**Algoritma dan kunci dekripsi aset berada di dalam kode native yang terenkripsi oleh app-shield (§6), sehingga tidak dapat dipulihkan dengan analisis statis di VM ini.** Yang menghalangi berlapis: (a) tidak ada decompiler native (Ghidra/IDA/Hopper tidak tersedia di VM — sesuai batas skill REA lokal); (b) simbol C++ game tidak diekspor; (c) wilayah kode yang relevan terenkripsi di file dan baru dibuka di memori saat runtime.

Yang dibutuhkan untuk menembusnya (di luar jangkauan tugas statis ini):
- **Dump memori runtime** di perangkat rooted (HP user sudah root): jalankan game, dump region `libcocos2dcpp.so`/`libfingersoft_hcr2.so` yang sudah terdekripsi dari `/proc/<pid>/mem`, ATAU hook (Frida/LSPosed) jalur pemuatan file Cocos untuk menangkap plaintext sesudah dekripsi / kunci saat dipakai. Dari plaintext + ciphertext yang berpasangan, skema bisa dibalik dan kunci diekstrak.
- Alternatif: ekstrak aset terdekripsi dari cache/data aplikasi setelah game berjalan (bila game menulis cache plaintext — belum terbukti).

### 5.5 File .dat (ghost & cup)

- Sebagian `.dat` adalah **protobuf polos**: `cup_*.dat` (isi nama cup, mis. `\n\x0e hill_climb_cup`) dan sebagian `ghost_*.dat` berisi nama pemain (`Francesco`, `jeep` — replay ghost pembalap lain).
- Sebagian `ghost_*.dat` lain (mis. `tutorial_5_bill_fast.dat`, `ghost_10_1_cuptown_easy.dat`) berentropi 7,96 tanpa header magic aset; **tahan** zlib/deflate/LZ4/Zstandard pada semua offset yang dicoba. Status: **belum terpecahkan** — kemungkinan memakai perlindungan native yang sama atau pemaketan kustom Fingersoft; dicatat apa adanya, tidak ditebak.

## 6. Proteksi aplikasi (app-shielding) — bukti

1. **Section header dimusnahkan/dikecilkan**: `libcocos2dcpp.so` hanya menyisakan 5 section; `readelf`/`nm` melaporkan 0 simbol padahal .dynsym nyata ada (dibaca manual lewat PT_DYNAMIC: ribuan entri). Pola pasca-proses protector.
2. **Segmen loader tambahan**: `libcocos2dcpp.so` punya pasangan LOAD ekstra di ekor file (offset 0x224C000+) dan **entry point ELF (0x2268F20) + DT_INIT tinggal di segmen tambahan itu**, bukan di badan utama — pola loader shield yang membuka badan terenkripsi saat load.
3. **Wilayah entropi 8.00 (maksimum) raksasa**: peta entropi per-256KB menunjukkan ±19 MB wilayah entropi 8,00 di `libcocos2dcpp.so` (offset ±0xE00000–0x204E7F0) dan ±2 MB lagi di ±0x680000; di `libfingersoft_hcr2.so` hampir seluruh .text (5,1 MB) berentropi 8,00. Kode ARM64 normal berentropi ±5–6,7 (terlihat di wilayah plaintext cocos 0x880000–0xDC0000, tempat .rodata/string terbaca). Kesimpulan: **kode dieksekusi dari hasil dekripsi runtime; file di disk terenkripsi sebagian besar.**
4. **Ekosistem Promon hadir**: `libbts.so` + `libwtp.so` adalah backtrace-support milik Promon (`no.promon.backtrace_support`, Crashpad, PtraceHook) — komponen yang lazim menyertai Promon SHIELD. (Nama produk tidak tertulis eksplisit di binary; atribusi "Promon" didukung lib pendamping ini, bukan klaim dari string shield itu sendiri.)
5. **Deteksi root**: manifest mendeklarasikan visibilitas paket untuk `com.topjohnwu.magisk`, `com.koushikdutta.superuser`, `com.noshufou.android.su`, `com.thirdparty.superuser` — daftar klasik aplikasi superuser yang dicek keberadaannya.
6. Lainnya: izin atestasi `com.amazon.privacypass.ATTEST` (varian Amazon), Google Source Stamp utuh, tanda tangan asli tidak berubah.

## 7. Perilaku aplikasi

- **Komponen**: launcher `AppActivity` (Cocos). Sisanya didominasi SDK: Firebase (analytics/auth/messaging/crashlytics), Play Games, ad SDKs (AppLovin, Facebook Audience Network — termasuk 2 dex di `assets/audience_network/`, Vungle, AdMob), Helpshift, AppsFlyer.
- **Izin penting**: INTERNET, ACCESS_NETWORK_STATE, WAKE_LOCK, BILLING (Play IAP), POST_NOTIFICATIONS, AD_ID, CHECK_LICENSE, FOREGROUND_SERVICE(+DATA_SYNC), READ_BASIC_PHONE_STATE.
- **Endpoint Fingersoft** (dari konstanta Java classes5):
  - `https://fsid.fingersoft.net` (+ `-dev`/`-staging`) — Fingersoft ID / akun
  - `https://acs3.fingersoft.net` — layanan akun/cloud
  - `https://ads3.fingersoft.net` (+ staging) — konfigurasi iklan sendiri
  - `https://errors.fingersoft.net` — pelaporan error
  - `https://fs-iap.eastus.cloudapp.azure.com` — validasi IAP di Azure
- **Penyimpanan lokal**:
  - AndroidX **Preferences DataStore** lewat `DataStoreManager` (Kotlin; kunci-nilai pengaturan & penyimpanan iklan `FSAdStorage`).
  - **Room DB terenkripsi** di paket `home`: `EncryptedDAO` + `EncryptorImpl` (sudah dibaca dari JADX) — skema: **AES-256/CBC/PKCS5Padding** dengan kunci AES acak per pengguna yang **dibungkus RSA/ECB/PKCS1Padding** (keypair pengguna); IV disimpan Base64. Ini enkripsi data profil/DB lokal, **bukan** enkripsi aset §5.
  - Data cup/ghost: protobuf (sebagian polos, lihat §5.5).

## 8. Batas alat (jujur)

- JADX tuntas untuk classes5 (3.938 file, 6 error dekompilasi kecil). 9 dex lain mayoritas SDK pihak ketiga; tidak di-JADX satu per satu karena bukan kode game.
- apktool decode penuh base.apk **tidak selesai dijalankan** di sesi ini; analisis manifest memakai `aapt2 dump badging/xmltree` + strings manifest biner (hasil komponen/izin identik sumbernya). Dump mentah lengkap (raw unzip) tersedia di `extracted/base_raw/`.
- Tidak ada Ghidra/IDA/Hopper di VM → tidak ada pseudocode native; analisis native berbasis readelf/PT_DYNAMIC/strings/disassembly spot-check + statistik entropi.

## 9. Vonis akhir

**Terbukti:**
- File = HCR2 v1.75.1 asli Fingersoft (sertifikat asli + stamp Google), bundle split standar.
- Engine Cocos2d-x; dump penuh selesai: seluruh .so per ABI, seluruh aset, JADX dex game.
- Aset polos untuk semua format kecuali data JSON/RUBE game.
- Enkripsi aset terkarakterisasi persis (1.908 file, header 8 byte `1213AA1213BA13BA`, kelipatan 8, non-ECB).
- Aplikasi dilindungi app-shield kelas komersial (kode native terenkripsi runtime; bukti entropi + loader + section yang dimusnahkan), dengan deteksi root berbasis daftar paket superuser.

**Belum terbukti / tidak berhasil:**
- Dekripsi aset .json/.rube: 7 keluarga cipher × ±2 jt kombinasi kunci string-turunan — semua negatif. Kunci+algoritma terkunci di kode native ter-shield; perlu dump runtime dari perangkat.
- File ghost .dat entropi-tinggi: belum terpecahkan (bukan kompresi umum).
- Atribusi nama produk shield: konsisten dengan ekosistem Promon, tanpa string penanda eksplisit.

## 10. Daftar file hasil kerja

```
downloads/Hill Climb Racing 2_1.75.1.apks        file asli unduhan (utuh, tidak diubah)
extracted/apks_contents/                          6 APK hasil ekstrak .apks
extracted/base_raw/                               dump mentah base.apk (14.366 aset, 10 dex, semua file)
extracted/split_arm64_raw/  split_gpdeku_raw/     dump mentah split berisi .so
extracted/jadx_classes5/                          dekompilasi Java/Kotlin dex game (3.938 file)
work/decrypt_hcr2_assets.py                       karakterisasi format enkripsi + kerangka dekripsi
work/brute_xtea.c  brute_xxtea.c  brute_cbc.c     harness uji cipher (C)
work/brute_more.py                                uji Blowfish/DES/CAST/ARC2 (Python/pycryptodome)
work/candidate_keys.txt  keys.bin  keys_labels.txt  korpus kunci kandidat & turunannya
work/evidence/                                    daftar simbol dynsym bersih, strings libcocos2dcpp
decrypted_samples/                                KOSONG — tidak ada dekripsi yang berhasil (jujur)
REPORT.md                                         laporan ini
```
