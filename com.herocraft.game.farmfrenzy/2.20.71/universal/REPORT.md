> Catatan arsip: Arsitektur tidak ditegaskan di laporan (APK tunggal) — memakai `universal`.

# Laporan Dump & Analisis — Farm Frenzy (HeroCraft)

Tanggal analisis: 22 Oktober 2026 (WIB)
Metode: unzip (inventaris penuh) → aapt2 badging → apksigner/jarsigner (sertifikat) → apktool (manifest + smali) → JADX headless **per-kelas** untuk 27 kelas kunci (JADX penuh tidak dipakai; pola per-kelas sesuai pelajaran RAM ±7,9 GB) → verifikasi silang smali untuk angka & jalur kode.
Catatan: analisis statis murni — APK tidak dijalankan, server HeroCraft tidak dihubungi.

---

## 1. Identitas file (terverifikasi dari file-nya sendiri)

| Item | Nilai |
|---|---|
| Nama file | `Farm_Frenzy_2.20.71_14_r4dp.apk` |
| Ukuran | 7.386.714 byte (±7,4 MB), APK tunggal (tanpa split) |
| SHA-256 | `2922be133920d8569af3a308faae83554c18afcff7b5310c2eb07d218677761d` |
| Package | `com.herocraft.game.farmfrenzy` |
| Versi | versionName **2.20.71**, versionCode **22071** — nama file cocok dengan isi |
| SDK | minSdk 24, targetSdk 36, compileSdk 36 |
| Pengembang | HeroCraft (Kaliningrad, Rusia) |
| Activity utama | `com.herocraft.game.farmfrenzy.Application` (LAUNCHER, `singleTask`, `sensorLandscape`) |
| Izin | INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, VIBRATE, `com.android.vending.BILLING`, `com.android.vending.CHECK_LICENSE` |

### Vonis keaslian: **APK ASLI HeroCraft, BUKAN modifan pihak ketiga**

- Sertifikat penanda tangan tunggal: `CN=www.herocraft.com, OU=Mobile Games Development, O=Herocraft, L=Kaliningrad, ST=Kaliningrad, C=RU`, SHA-256 sertifikat `80e801731f9505faec3f43627a86b7c00a728ddae52f54165d2741e79a23357a`.
- Ditandatangani skema **v2 saja** (tidak ada blok v1 — `jarsigner` melaporkan "unsigned" karena hanya membaca v1; ini normal untuk APK modern).
- **Tidak ada kunci debug AOSP**, tidak ada paket asing mencurigakan (tidak ada kode tipe `com.savegame.*`/restore-save seperti temuan pada APK Fragger kiriman user yang terbukti modifan pihak ketiga). Semua kode non-library berada di paket resmi `com.herocraft.game.farmfrenzy`.

---

## 2. Dump penuh — inventaris isi

Total 215 berkas, 10.526.264 byte tidak terkompresi.

| Komponen | Isi |
|---|---|
| `classes.dex` | Tunggal, 5.149.800 byte. Berisi ±14 ribu kelas termasuk library; **kode game = 174 kelas** di `com/herocraft/game/farmfrenzy` |
| Lib native `.so` | **TIDAK ADA SAMA SEKALI** (0 berkas, semua ABI) — game 100% bytecode Java |
| `assets/s5/img/` | Sheet sprite PNG nama satu huruf (`a.png`…`l0.png`); terbesar `i.png` 1.531.995 byte |
| `assets/s5/f0..f4/` | Font bitmap (`font_0.dat` + `font_0.png`) |
| `assets/s5/a.l, b.l, c.l` | Data biner internal framework HeroCraft |
| `assets/s/*.mid` | 9 berkas musik MIDI |
| `assets/sn/*.ogg` | 17 efek suara Ogg Vorbis |
| `assets/trans_*` | Tabel lokalisasi 10 bahasa (de, en, es, fr, it, pl, pt, ru, tc, tr) + `assets/translate` |
| `assets/b.d` | Konfigurasi ter-obfuscate XOR (header terbaca `ADSF:`/`ADSS:`) — konfigurasi iklan/promo framework, **bukan** data gameplay |
| `assets/img/l1.png, l2.png` | Gambar kecil tambahan |
| Library ter-bundle | Google Play Services (base/basement/games), Firebase encoders/transport (pipa analitik), AndroidX, Guava, **Play Billing 8.0.0** |
| SDK iklan | **Tidak ditemukan** (tidak ada string/kelas AdMob, Unity Ads, AppLovin, ironSource, dsb.) |

## 3. Engine

**Framework kompatibilitas J2ME buatan HeroCraft sendiri.** Game ini adalah port dari Farm Frenzy klasik era J2ME:

- Kelas-kelasnya meniru API `javax.microedition` secara nama & perilaku: `MIDlet`, `Display`, `Canvas`, `RecordStore`, `Graphics`, `gameMIDlet`.
- Render: OpenGL ES lewat pembungkus sendiri (`GraphicsOGL`, `MidletViewOGL`) dengan jalur cadangan Canvas perangkat lunak (`AndroidCanvas`, `MidletViewCanvas`).
- Logika game **Java murni di DEX, nama kelas/metode TIDAK diobfuscate**: `farmSim` (simulasi), `game` (mesin status/meta), `animal`, `animalExt` (beruang/anjing/kucing), `newAnimal`, `house` (bangunan produksi), `well` (sumur), `store` (gudang), `car` (truk), `upgrade`, `grass`, `product`, `objFarm` (kelas dasar semua objek), `profile`, `menu`.
- `dConst` memuat 630 konstanta `CS_NUM_*` (offset gambar & angka tuning) — nilai pentingnya tersebar juga sebagai tabel di tiap kelas (lihat §5).

## 4. Arsitektur: online/offline, simpanan, anti-cheat

### Online/offline: **gameplay 100% offline & lokal**

- **Login tidak wajib.** Tidak ada sistem akun; Google Play Games ter-bundle tetapi masuknya opsional dan tidak ditemukan gerbang progres yang bergantung padanya.
- Lalu lintas jaringan yang ada hanya empat:
  1. `HCLib.downloadServerParams()` → `http://m.herocraft.com/external/api/game/get_constants?game_id=[gid]&prov_id=[pid]` — mengambil *global properties* HeroCraft (promo/konfigurasi framework) di thread latar, disimpan di RecordStore `AM_RS_NAME`. **Konstanta gameplay (harga, waktu, kapasitas) TIDAK berasal dari sini** — semuanya terkompilasi di kode (§5). Gagal unduh tidak menghalangi bermain.
  2. `http://gamestats.herocraft.com/game_event/` — telemetri event (`Statistic`, `HCAnalyticsProvider`).
  3. Verifikasi pembelian IAP: `Market$VerifyPurchase` → `http://chk.herocraft.com/store_verify/` dengan muatan bertanda tangan (`v=2&action=store_verify&data=[d]&sign=[s]&time=[t]&game_id=[gid]&store_id=[sid]&tag=[tag]`), ditambah verifikasi RSA lokal (`Security.verifyPurchase`, `SHA1withRSA` — kode IABUtil standar Google) dan cek lisensi LVL (`Licenser`, izin `CHECK_LICENSE`).
  4. Tautan berbagi sosial (Facebook/VK/Twitter) — kosmetik.

### Simpanan: **lokal, polos, tanpa enkripsi & tanpa integritas**

- Emulasi J2ME RMS: kelas `RecordStore` menyimpan record sebagai **file polos** lewat `Activity.openFileOutput` di penyimpanan privat aplikasi. Nama store: `farm2222` (data game utama), `farm_new`, `farmvip` (data VIP), `AM_RS_NAME` (parameter server/analitik). Manifest `allowBackup=true`.
- Isi simpanan dirangkai kelas `game` dari `DataBuffer`: `bankGame`, `moneyGame`, `CP_Max_Level`, plus blob `info()` per objek (house/well/store/animal/car menulis sendiri type/level/timeWorked/ dsb.).
- **Tidak ada enkripsi, tidak ada tanda tangan/checksum atas simpanan.** Kelas `CRC32` ada tetapi hanya dipakai widget UI `Ticker`; `javax.crypto.Cipher` hanya muncul di library Google.

### Anti-cheat / proteksi: **tidak ada untuk gameplay**

- Tidak ada deteksi root (pencarian Magisk/SuperSU/Xposed/Frida nihil — hit string yang mirip adalah positif palsu dari regex daftar TLD di library), tidak ada SafetyNet/Play Integrity, tidak ada pemeriksaan tanda tangan APK di kode game.

## 5. Sistem ekonomi & waktu (dari bukti kode)

### Uang — dua kolam, keduanya `int` polos lokal

- `farmSim.money` — uang tunai **di dalam level**; awal level = konfigurasi level `infoLevel[11]`. Semua pembelian memotong field ini (mis. `upgrade`: `p.money -= price[...]`; `well.addEvent`: `p.money -= price[level-1]`).
- `game.moneyGame` + `game.bankGame` — bank meta antar-level; `bankGame` menampung hasil akhir level (`bankGame += FarmSim.resultGame[6]`), keduanya disimpan/dimuat dari record `farm2222`. Pada inisialisasi profil baru di build ini, jalur reset mengeset `moneyGame = 200002`.

### Harga & kapasitas (tabel terkompilasi)

- `upgrade.price[9][level]`: harga upgrade semua bangunan/kendaraan, rentang 200 → 120.000.
- `well.price = {19,17,15,14,7,3,0}` per level sumur; `well.WATERING = {600,440,300,200,...}` muatan yang terkuras per siraman.
- Gudang (`store`): `STORE_SIZE = {120, 200, 400, 800, 2000}` per level 1–5; ukuran produk `PROD_SIZE = {5,2,20,10,60,40,10,30,80,60}`; `store.current` = ruang terpakai; `isAddProduct()` menolak produk baru bila penuh.

### Waktu — **berbasis delta frame (tick), BUKAN jam dinding per objek**

Bukti inti di loop utama `farmSim`:

```java
int currentTimeMillis = (int) (System.currentTimeMillis() - this.oldTime);
this.currentTime += currentTimeMillis;
maybeAddBear(this.currentTime);
for (obj : this.obj) obj.next(currentTimeMillis);   // delta ms diteruskan ke semua objek
```

Artinya: setiap timer adalah **penghitung ms yang bertambah sebesar delta frame** selama permainan berjalan & tidak di-pause. **Tidak ada progres saat aplikasi ditutup** (penghitung tersimpan di tengah jalan di record simpanan, dilanjutkan saat level dimuat lagi). Tidak ada jam server yang terlibat.

| Sistem | Mekanisme (kelas → konstanta) |
|---|---|
| Produksi bangunan | `house.next`: `timeWorked += delta`; produk keluar bila `timeWorked > TIME_WORKED = 10.000 ms` (semua bangunan) |
| Sumur | `well`: isi ulang `TIME_WORKED = 3.000 ms`; menyiram rumput menguras muatan sebesar `WATERING[level]` & membayar `price[level]`; sumur level ≥5 = otomatis: tiap `TIME_WORKED_AUTO = 1.000 ms` membayar harga & menumbuhkan rumput selama uang cukup |
| Truk (jual hasil) | `car`: waktu jalan pulang-pergi `TIME_ROAD = {20000, 18000, 16000, 10000, 5000, 3000, 3000}` ms per level; pulang → muatan terjual jadi `farmSim.money` |
| Hewan produksi | `animal`: kekenyangan `stomach` (kapasitas `STOMACH = {50, 80, 150}` per tipe) berkurang `SPEED = {3, 8, 15}` tiap tick 1.000 ms; makan rumput memulihkannya; produk jatuh tiap `productTime == 20` tick (±20 detik); `stomach ≤ 0` → mati (urutan `isDeath` 0→9 lalu terhapus) |
| Beruang | Jadwal per level `bearTime[][]` (dari `game.getBearTime(level)`); `farmSim.maybeAddBear(currentTime)` memunculkan `animalExt` tipe 5; beruang berjalan (`modeBear`), **membunuh hewan ternak** saat bersinggungan (`farmSim.isAnimalDeath` lewat `crossingBear`); pemain mengklik berulang untuk mengandangkannya — beruang terkandangkan menjadi produk slot 9 di gudang (bisa dijual, tunduk pada ruang gudang). Anjing (animalExt) mengejar beruang; kucing mengumpulkan produk |
| Bintang level | Formula lokal di akhir level: waktu tempuh `currentTime < timeGold` → **3 bintang**, `< timeSilver` → 2, selain itu 1. `timeGold = infoLevel[19] × 1000`, `timeSilver = infoLevel[21] × 1000`; bonus uang per tingkat `moneyPlus = {infoLevel[18], [20], [22]}` |
| Struktur level | Peta 6 pulau (`TYPE_LEVEL = {0,1,2,3,4,4}`), indeks level = pulau×5 + tipe → ±30 level. Konfigurasi tiap level = tabel lokal `int[] infoLevel` (hewan awal indeks 6–10, uang awal 11, target, jadwal beruang, ambang emas/perak 19/21, bonus 18/20/22). Progres buka level = `game.CP_Max_Level` (int, tersimpan lokal; kode memeriksa misalnya `CP_Max_Level >= 24` untuk konten akhir) |
| Mode VIP/Nolimit | Store terpisah `farmvip` + `gameDataNolimit` + `game.startNolimit()` — mode main tanpa batas yang terkait pembelian (lihat §6 butir 11) |

## 6. Peta cheat (vonis per fitur)

Seluruh gameplay berjalan lokal tanpa verifikasi server, sehingga vonisnya seragam kuat — kecuali gerbang pembelian:

| # | Fitur kandidat | Vonis | Bukti |
|---|---|---|---|
| 1 | Uang tak terbatas | **LOKAL-BISA PENUH** | `farmSim.money`, `game.moneyGame`, `game.bankGame` int polos; semua potongan harga lokal; simpanan tanpa integritas |
| 2 | Produksi instan / tanpa timer | **LOKAL-BISA PENUH** | Semua timer = penghitung delta vs konstanta terkompilasi: `house.TIME_WORKED=10000`, `car.TIME_ROAD[]`, `well.TIME_WORKED=3000`, `animal productTime==20`. Menolkan konstanta/memaksa penghitung = instan. Tidak ada jam server |
| 3 | Kapasitas gudang tak terbatas | **LOKAL-BISA PENUH** | `store.STORE_SIZE[]` + gerbang `isAddProduct()` + `store.current`, semua lokal |
| 4 | Air/sumur tak terbatas | **LOKAL-BISA PENUH** | `well.price[]`, `WATERING[]`, `TIME_WORKED` konstanta lokal; sumur otomatis hanya digerbang `farmSim.money` (tertutup oleh #1). Catatan: "air" di game ini = muatan sumur untuk menyiram rumput, bukan tangki terpisah |
| 5 | Hewan tidak perlu pakan / tidak mati lapar | **LOKAL-BISA PENUH** | `animal.stomach` & laju kuras `SPEED[]` per tick 1 detik serta kematian di `proc <= 0` semua lokal |
| 6 | Beruang tidak menyerang / tidak muncul | **LOKAL-BISA PENUH** | Jadwal `bearTime[][]` + `maybeAddBear()` + jalur bunuh `crossingBear/isAnimalDeath` semua lokal; mematikan spawn atau jalur bunuhnya sama-sama lokal |
| 7 | Kendaraan instan | **LOKAL-BISA PENUH** | `car.TIME_ROAD[]` per level (20 dtk → 3 dtk); pengiriman hewan baru (balon/pesawat, `newAnimal`) juga timer lokal |
| 8 | Buka semua level | **LOKAL-BISA PENUH** | Progres = `game.CP_Max_Level` int di simpanan lokal polos; tidak ada komponen server |
| 9 | Bintang / skor maksimal | **LOKAL-BISA PENUH** | Rumus bintang membandingkan `currentTime` lokal vs `timeGold/timeSilver` lokal; `levelScore[]` lokal. Skor tidak dikirim ke papan peringkat resmi yang memengaruhi progres (`Statistic` hanya telemetri event) |
| 10 | Biaya upgrade nol | **LOKAL-BISA PENUH** | Tabel `upgrade.price[][]` lokal; semua cek & potong terhadap `farmSim.money` lokal |
| 11 | Mode VIP/Nolimit tanpa beli | **GERBANG IAP — bukan cheat gameplay** | Status VIP memang dibaca dari record lokal `farmvip`, tetapi pembelian sahnya diverifikasi server (`chk.herocraft.com/store_verify/` + RSA `SHA1withRSA` + LVL). Membuka gerbang berbayar pengembang dicatat sebagai fakta permukaan saja, di luar peta cheat gameplay (pola yang sama seperti catatan premium di REA Defend the Bunker) |

Catatan bangun (di luar vonis): tidak ada pemeriksaan tanda tangan/integritas di kode game, jadi tidak ada anti-tamper yang menghalangi APK hasil modifikasi untuk berjalan.

## 7. Ukuran dump

Total `~/workspace/rea-farmfrenzy/` = **60.790.195 byte (±60,8 MB)**, terdiri dari:

- `downloads/` — APK asli 7.386.714 byte
- `extracted/` — isi APK terekstrak penuh (10.526.264 byte)
- `analysis/` — `ziplist.txt`, `dex_strings_all.txt` (39.213 string), `herocraft_classes.txt` (174 kelas), output apktool (smali penuh + manifest), output JADX per-kelas (27 berkas .java kelas kunci game + `house.java`)

## 8. Yang tidak terkonfirmasi

- Pemetaan semantik **seluruh** indeks `infoLevel[]` (yang terverifikasi: 6–10 hewan awal, 11 uang awal, 18/20/22 bonus, 19/21 ambang emas/perak, 23+ target) dan arti persis 630 konstanta `dConst.CS_NUM_*` (hanya diperiksa seperlunya).
- Isi `assets/b.d` tidak didekode (obfuscate XOR; dari header & konteksnya itu konfigurasi iklan/promo framework, bukan data gameplay).
- Apakah endpoint `get_constants`/`store_verify` HeroCraft masih merespons di 2026 — tidak dihubungi (analisis statis); tidak relevan bagi konstanta gameplay yang terkompilasi lokal.
- Google Play Games ter-bundle, tetapi tidak ditemukan bukti achievement/leaderboard dipakai untuk progres; tidak ditelusuri sampai tuntas karena tidak memengaruhi vonis.
- Kondisi piksel-persis pembunuhan beruang (radius tabrakan di `crossingBear`) — mekanismenya terkonfirmasi, detail angkanya tidak ditelusuri.
- Kesetaraan versi Play Store terkini dengan build 2.20.71 ini — di luar jangkauan berkas yang diberikan.
