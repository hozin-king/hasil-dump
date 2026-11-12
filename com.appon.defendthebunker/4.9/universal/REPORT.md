> Catatan arsip: Arsitektur tidak ditegaskan di laporan (APK tunggal, tanpa info lib) — memakai `universal`.

# Laporan Dump & Analisis — Defend The Bunker

Tanggal analisis: 21 Oktober 2026 (WIB)
Metode: gdown (unduh) → unzip → REA `inspect-android-package` (JADX headless) → apktool (manifest) → JADX decompile penuh (7.539 kelas, selesai 99%+, semua kelas game terbaca) → verifikasi silang smali (apktool) untuk parser format GT.
Catatan batas alat: VM ini tidak punya Ghidra/IDA — tidak relevan di sini karena paket ini **tidak mengandung kode native sama sekali**.

---

## 1. Identitas game (terverifikasi dari file)

| Item | Nilai |
|---|---|
| Nama file | `Defend The Bunker_4.9.apk` |
| Ukuran | 12.273.389 byte (±12,3 MB), APK tunggal (tanpa split) |
| SHA-256 | `d714be183bc1e5c0a4a876a22cddb7f1cb6abf7cbbf650160f32f044a0979e57` |
| Nama game | Defend The Bunker |
| Package | `com.appon.defendthebunker` |
| Versi | 4.9 (versionCode 41), minSdk 26, targetSdk 36 |
| Pengembang | AppOn Software Pvt. Ltd. (India) |
| Activity utama | `com.appon.defendthebunker.TowerDefenderMidlet` |
| Usia desain | Kredit dalam game: "Defend The Bunker v 1.7 ~ 2012" — game era J2ME yang di-port ke Android dan terus dibungkus ulang (nama kelas "Midlet", metode `loadRMS`/`saveRMS` = emulasi RecordStore J2ME) |

File unduhan menamai dirinya persis "Defend The Bunker" — identitas sesuai sebutan user, terkonfirmasi.

## 2. Engine & native lib

- **Native lib: TIDAK ADA.** Isi APK tidak mengandung satu pun file `.so` di ABI mana pun (`extractNativeLibs=false`, hanya `classes.dex` + `classes2.dex`, gabungan ±15,5 MB bytecode). Jadi tidak ada libil2cpp/libUE4/libgodot/libgdx/libcocos — semua pertanyaan "mesin native apa" gugur.
- Engine-nya adalah **framework Java murni buatan AppOn sendiri**:
  - `com.appon.gtantra` — **GTantra**, mesin grafis/animasi 2D (parser format `.GT`, font bitmap, tilemap, tint). Nama format aset `.GT` berasal dari sini.
  - `com.appon.effectengine` — mesin efek partikel (`.effect`).
  - `com.appon.miniframework` — framework UI/event.
  - `com.appon.defendthebunker` — logika game (74 kelas hasil decompile).
- Sisanya SDK standar: Google Play Services (Ads/AdMob, Games), Firebase/analytics bawaan Play Services, Dagger (di dex2, untuk SDK iklan), Kotlin stdlib, dan SDK iklan internal AppOn (`com.appon.adssdk`) + modul billing AppOn (`com.appon.billing`).
- **Proteksi komersial: tidak ada.** Tidak ditemukan PairIP, Promon, FairGuard, V-Key, ACE, atau sejenisnya — konsisten dengan tidak adanya lapisan native. Obfuscation: nama kelas/metode game **tidak diobfuscate** (nama asli terbaca jelas: `TowerEngine`, `WaveCreator`, `SQLGlobalStorage`, dst.).

## 3. Aset grafis

Semua aset **polos, tidak terenkripsi** (PNG/JPG/OGG standar + format biner kustom `.GT`/`.tl`/`.menuex`/`.effect` tanpa enkripsi — header `.GT` terstruktur terbaca: nomor versi, jumlah palet, tabel warna).

| Aset | Isi | Resolusi/ukuran |
|---|---|---|
| `assets/xres/map1..6.jpg` | Latar 6 peta | 1441×1281 dan 1361×1361 (230–659 KB per berkas) |
| `assets/xres/menu.jpg`, `splash.jpg` | Menu & splash | 1280×800 |
| `assets/xres/fighter_plane.png` | Sprite PNG terbesar | 482×545 |
| PNG UI lain (`b_pause`, `button100`, ikon, dst.) | Tombol/HUD | mayoritas 100×100, di bawah 340 px |
| `assets/xres/*.GT` (soldier 157 KB, vehicales 207 KB, weapons 144 KB, weapons_selection 282 KB, effects 98 KB, hud 9 KB) | Sheet animasi sprite (tentara, kendaraan, senjata, efek) format GTantra: **berbasis palet warna** (indeks 1 byte/piksel) berisi SEMUA frame satu kelompok | dimensi per-frame persis tidak terkonfirmasi, tetapi total byte per berkas membatasi ukuran frame ke orde puluhan piksel |
| `assets/xres/background.tl` | Data tile latar | 15 KB |
| `assets/sound/*.ogg` (17 berkas) | Suara tembakan/ledakan/kendaraan + musik | standar Ogg Vorbis |

Mesin mendukung 6 tingkat folder aset resolusi: `lres, mres, hres, xres, xhres, xlarges` (kelas `Resources`), tetapi **APK ini hanya mengirim `xres`** — tidak ada folder `xhres`/`xlarges` di dalam paket. Tabel internal `imagesTakenFromArtist` membatasi karya artis maksimum **800×1280** untuk semua tingkat teratas.

## 4. Cara game me-render (inti pertanyaan upscale)

Bukti dari kode (`DrawView`, `GameCanvas`, `TowerCanvas`, `Constants`, `GTantra`, `Resources`):

1. Game digambar dengan **Android Canvas 2D di atas `SurfaceView` layar penuh** pada resolusi panel asli perangkat (`onMeasure` = lebar/tinggi display maksimum). Tidak ada framebuffer internal beresolusi rendah, tidak ada RenderScale (itu konsep URP Unity), tidak ada `r.ScreenPercentage` (itu Unreal), tidak ada `Screen.SetResolution` — **tidak ada satu pun "knob resolusi render"** karena mesinnya bukan Unity/Unreal.
2. Logika & tata letak game ditulis dalam **ruang koordinat virtual 320×240** (`MASTER_VERSION_WIDHT=320`, `MASTER_VERSION_HEIGHT=240`, warisan versi master J2ME), lalu semua koordinat/ukuran diskalakan ke layar nyata dengan faktor persen (`Constants.portStaticConst()`: `xScale = (SCREEN_WIDTH − 320) × 100 / 320`). Di HP 2400×1080, faktor skalanya ±650–750%.
3. Sprite `.GT` direkonstruksi piksel-per-piksel menjadi `Bitmap` ARGB pada ukuran frame aslinya (`Bitmap.createBitmap(RetriveImageData(...), width, height)` di `GTantra`), lalu digambar ke Canvas; PNG dimuat dengan `Bitmap.createScaledBitmap(..., filter=true)` ke ukuran target hasil skala koordinat, dan `Paint` utama memakai `setFilterBitmap(true)` + anti-alias. Artinya pemulus (interpolasi bilinear) **sudah aktif** — gambar sudah "diperhalus", hanya saja detail sumbernya memang tidak ada.
4. Menu pengaturan dalam game: tidak ditemukan pengaturan kualitas/grafik/resolusi apa pun (hanya suara dan sejenisnya). `TILE_SIZES = {32, 40, 60, 80, 120, 160}` adalah pilihan ukuran tile peta per tingkat resolusi perangkat, bukan pengaturan pengguna.

### Kesimpulan upscale

**Tidak bisa dengan cara "viral" (menaikkan resolusi render internal), karena tidak ada resolusi render internal yang ditahan rendah.** Game ini sudah me-render pada resolusi penuh layar HP. Yang membuatnya terlihat buram/pixelated di HP modern adalah **resolusi aset sumbernya**:

- sprite & animasi dibuat untuk layar 320×240 (format palet, frame kecil),
- karya gambar terbesar yang dikirim hanya setara tingkat `xres` (maks. artis 800×1280; PNG sprite ≤ 482×545; latar peta 1441×1281 adalah satu-satunya aset yang relatif tajam).

Tidak ada data gambar beresolusi lebih tinggi yang "terkunci" di dalam APK untuk dibuka — folder `xhres`/`xlarges` yang didukung mesin **tidak disertakan** pengembang.

Satu-satunya jalur menaikkan ketajaman secara teknis (analisis saja, tidak dikerjakan): mengganti berkas aset dengan versi hasil upscale (PNG/JPG bisa diganti langsung karena polos; sheet `.GT` harus di-upscale lalu ditulis ulang mengikuti format GTantra — formatnya tidak terenkripsi dan parsernya, `GTantra.Load([BZ)V`, tersedia untuk dipelajari), lalu membungkus ulang APK. Hasilnya tetap interpolasi/upscale buatan — bukan detail asli — dan di luar cakupan tugas analisis ini.

## 5. Arsitektur: online/offline, penyimpanan, anti-cheat

- **Offline penuh untuk gameplay.** Tidak ditemukan satu pun endpoint server game di seluruh strings dex — hanya URL iklan (AdMob/Google Ads), iklan rumah AppOn (`http://www.appon.co.in/HouseAdsNew/`), dan layanan Google standar. Koneksi `INTERNET` dipakai untuk iklan (dan Play Games bila pengguna masuk — callback `onSignInSucceeded/onSignInFailed` ada, sifatnya opsional).
- **Login tidak wajib.** Game jalan tanpa akun.
- **Ekonomi & progres 100% lokal:**
  - `TowerEngine`: field `money` dan `score` adalah `int` biasa (uang awal per level dari `WaveCreator.getCurrentLevelMoney(...)`), lengkap dengan setter polos.
  - Penyimpanan: database SQLite lokal bernama `gamedata` di `/data/data/com.appon.defendthebunker/databases/` berisi **satu blob Hashtable Java terserialisasi polos** (`ObjectOutputStream`, tanpa enkripsi/tanpa tanda tangan) melalui `SQLGlobalStorage`, ditambah SharedPreferences bernama `GlobalStorage` (`GlobalStorage.java`).
  - Kunci-kunci yang disimpan antara lain: `MAX_UNLOCKED_LEVELS`, `LEVEL_SCORE`, `LEVEL_MEDELS`, `lastAvailableWeapon`, `premium`, `uid`.
- **Premium/IAP:** flag `premium` dibaca dari penyimpanan lokal yang sama untuk menentukan versi premium (bebas iklan); pembelian melalui modul billing AppOn/Play Billing (`itemPurchaseSuccess`). Tidak ada verifikasi server milik pengembang yang ditemukan.
- **Anti-cheat: tidak ada.** Tidak ditemukan pemeriksaan integritas simpanan, tidak ada deteksi root, tidak ada pemeriksaan tanda tangan APK, tidak ada SafetyNet/Play Integrity di kode game/framework (pencarian menyeluruh atas pola-pola tersebut nihil). Yang ada hanya iklan + billing standar Play.

## 6. Gameplay (dari bukti file)

- Genre: **tower defense 2D** satu layar bergulir kamera (ada `CAMERA` dengan camX/camY) berbasis tile.
- Pemain menempatkan senjata statis untuk menghadang gelombang musuh yang berjalan menuju **bunker** (digambar dari `bunker.png` di tile target peta): jenis senjata dari kode & aset: gun/senapan mesin, slower (pelambat), bom tower, fire blower (penyembur api), laser, rudal (missile launcher), ranjau (mines), dan dukungan pesawat tempur (fighter) — masing-masing dengan harga & radius siaga (`WEAPON_*_ALERT_DIAMETER`, `WeaponLocable`).
- Musuh (`view/Characters`): tentara (Soldier), motor (Bike), tank (Tank), helikopter (Helicoptor), pengebom (BomberMan), kendaraan umum (Vehical) — nyawa di field `lifeOfCharacter`/`helthOfCharacter` (int + fixed-point), dikurangi oleh damage senjata secara lokal.
- Struktur konten: **6 peta** (map1–6.jpg) dan **±29 definisi level/gelombang** ter-hardcode di `WaveCreator.levelsArray` (tiap level = daftar gelombang berisi jumlah musuh per 6 tipe), plus mode `ChallengesMenu`, medali per level (bronz/silver/gold), dan skor per level.
- Sumber daya inti dalam permainan: **uang (money)** untuk membeli/menempatkan senjata, diperoleh dari membunuh musuh; kekalahan bila musuh menghancurkan/melewati bunker (`lostMenu`), kemenangan bila semua gelombang habis (`winMenu`).

## 7. Peta cheat (analisis kelayakan — bukan pembuatan)

| Kandidat | Status | Alasan teknis berbasis bukti |
|---|---|---|
| Uang (money) tak terbatas | **LOKAL-BISA** | `money` int polos di `TowerEngine` dengan setter; tidak ada validasi/integritas; nilai awal per level dari tabel lokal `WaveCreator`. |
| Skor (score) | **LOKAL-BISA** | Field `int` polos yang sama; skor per level disimpan lokal (`LEVEL_SCORE`). Tidak ada server untuk membantah. |
| God mode (bunker tidak hancur / musuh tidak merusak) | **LOKAL-BISA** | Seluruh perhitungan damage & nyawa (`Character.lifeOfCharacter`, ledakan `Blast`) berjalan lokal di `TowerEngine`; tidak ada komponen server. Jalur persis titik kaitnya belum dipetakan baris-per-baris (itu pekerjaan tahap mod, di luar tugas ini). |
| Damage senjata besar | **LOKAL-BISA** | Konstanta damage/jangkauan senjata ada di kode lokal (`Constants`, kelas `view/Weapon/*`); musuh mengurangi nyawanya secara lokal. |
| Unlock semua level/peta & senjata | **LOKAL-BISA** | Kunci progres `MAX_UNLOCKED_LEVELS` & `lastAvailableWeapon` berada di penyimpanan lokal terserialisasi polos tanpa enkripsi/tanda tangan (SQLite `gamedata` + SharedPreferences `GlobalStorage`). |
| Premium (bebas iklan) tanpa beli | **LOKAL-BISA secara teknis** *(catatan: ini melewati gerbang berbayar pengembang — dicatat sebagai fakta teknis peta permukaan, bukan rekomendasi)* | Flag `premium` adalah string di penyimpanan lokal yang sama; tidak ada verifikasi server pengembang. |
| Speed hack (percepat permainan) | **LOKAL-BISA** | Loop game lokal (`GameThread`, `WAIT_TIME`, kecepatan musuh/senjata konstanta lokal, tombol fast-forward bawaan game bahkan sudah ada: `i_fastforward.png`). |
| Mod menu (overlay untuk fitur di atas) | **LOKAL-BISA secara teknis** | Semua target berada di proses yang sama, kode tidak diobfuscate, tidak ada anti-tamper/deteksi root untuk menghalangi. |
| Cheat yang butuh server (koin server, sinkron awan, papan peringkat resmi) | **SERVER-TIDAK / tidak relevan** | Tidak ada server game sama sekali; satu-satunya komponen daring adalah iklan & Play Games opsional. Skor tidak dikirim ke server pengembang. |

Tidak ada kandidat yang perlu ditandai PERLU-BUKTI-TAMBAHAN: seluruh permukaan permainan terbukti lokal dari decompile.

## 8. Ukuran dump

Total `~/workspace/rea-bunker/` = **99.552.678 byte (±99,6 MB; 130 MB ukuran tampak disk)**, terdiri dari:
- `downloads/` — APK asli 12.273.389 byte
- `extracted/` — isi APK terekstrak
- `analysis/` — hasil REA (`rea_inspect.json`), output apktool, strings dex lengkap, dan hasil decompile JADX (`jadx_out/`)

Berkas pendukung: `analysis/hash.txt` (SHA-256), `analysis/ziplist.txt` (daftar isi APK), `analysis/dex_strings_all.txt`, `analysis/appon_classes.txt`.

## 9. Yang tidak terkonfirmasi

- Dimensi piksel persis per-frame di dalam berkas `.GT` (parser `GTantra.Load` tidak ter-decompile bersih oleh JADX; struktur format terverifikasi dari smali — palet + data piksel terindeks — tetapi angka per-frame tidak dibaca satu per satu).
- Arti persis 6 kolom angka pada tiap gelombang di `WaveCreator.levelsArray` per tipe musuh (urutan tipe disimpulkan dari `characterHelpArray` & kelas karakter, bukan dari legenda eksplisit).
- Apakah versi Play Store terbaru (bila ada) identik dengan APK 4.9 ini — di luar jangkauan berkas yang diberikan.
