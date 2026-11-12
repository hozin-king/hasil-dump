# Defend The Bunker — Mod Menu Gabung v2: catatan build

Repo: `hozin-king/hozin-bunker-mod` (privat), folder `modmenu/`.
Commit: `ab6946792dfcbcf387c89884c875536bd9bae72d` di `main`.
CI: run dispatch `39697559829` (success), run tag `39697833763` (success).
Rilis: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v2
APK: `DefendTheBunker-ModMenu-v2.apk`, 12.407.018 byte.
Dex CI == dex build lokal byte-per-byte (classes.dex `adf732f5…`,
classes2.dex `467693c9…`). Sertifikat == v1 (`f7a4306a…`) → bisa dipasang
menimpa modmenu-v1 tanpa uninstall & tanpa kehilangan simpanan.

Dua pekerjaan: (1) perbaiki tombol MOD yang tidak muncul di v1;
(2) tambah 10 level baru (31–40) yang **didesain orisinal** (bukan klon).

---

## 1. Diagnosis menu v1 & perbaikannya

### Akar masalah (terbukti dari kode, bukan tebakan)

Aktivitas launcher = `com.appon.defendthebunker.TowerDefenderMidlet`
extends `Utility.GameActivity`. Alur `GameActivity.onCreate` (smali):

1. `invoke-super AppOnAdActivity.onCreate` — kelas induk tidak pernah
   memasang content view.
2. Membuat `RelativeLayout ll`, lalu `setContentView(ll)`.
3. Membuat `DrawView` (SurfaceView game) dan menambahkannya fill-parent
   ke `ll`.

Patch P6 v1 menyisipkan `ModMenu.init(...)` **tepat setelah langkah 1**,
yaitu SEBELUM `setContentView`. Karena `init` dipanggil dari thread UI,
`Activity.runOnUiThread()` berjalan **sinkron di tempat**: tombol ditambah
ke content parent yang saat itu masih kosong. Sesaat kemudian
`setContentView(ll)` memanggil `removeAllViews()` pada content parent
yang sama → **tombol terhapus**, dan tidak ada pemasangan ulang sesudahnya.
Panel tidak pernah bisa dibuka karena tombolnya tidak ada.

Bukti pendukung: patch koin (di `TowerEngine`) bekerja di HP user →
dex gabung & patch memang tereksekusi; kegagalan murni soal pemasangan UI.

### Perbaikan v2 (patch P6a/P6b/P6c, menggantikan P6)

- **P6a** — `ModMenu.init` dipanggil di **akhir** `onCreate` (setelah
  content view + DrawView terpasang semua).
- **P6b** — `ModMenu.ensureInstalled` di akhir `onResume`.
- **P6c** — `ModMenu.ensureInstalled` tepat setelah super di
  `onWindowFocusChanged`.
- `ModMenu` ditulis ulang: pemasangan **idempoten** — tombol dicari lewat
  tag `"hozin_mod_button"` di **DecorView** (parent paling atas yang tidak
  pernah diganti `setContentView`; fallback `android.R.id.content`),
  bila sudah ada cukup `bringToFront()` + dipastikan VISIBLE; tombol diberi
  elevation 100 agar di atas SurfaceView. `init` juga menjadwalkan
  pemasangan ulang via Handler +600ms dan +2000ms.
- **Penanda diagnosis:** Toast `"MOD MENU AKTIF"` (LENGTH_LONG) satu kali
  per proses saat pemasangan pertama berhasil. Bila Toast muncul tapi
  tombol tidak terlihat → masalah z-order; bila Toast pun tidak muncul →
  kode menu tidak jalan. (Toast ini penanda sementara v2.)
- Patch fitur P1–P5 v1 **tidak diubah sama sekali** (terverifikasi dari
  diff final: TowerEngine/Character/GameThread identik dengan v1).

---

## 2. Audit struktur jumlah level (30 → 40)

Basis: smali APK asli + kode sumber hasil decompile. Semua struktur yang
terikat jumlah level ditemukan & diperluas **serentak**:

| Struktur | Lokasi | Perubahan |
|---|---|---|
| `WaveCreator.levelsArray` (`int[30][][]`) | `Levels/WaveCreator.<init>` | Blok pertumbuhan setelah iput bawaan: array baru `[40]`, `System.arraycopy` 30 lama, 10 level baru dibangun & disimpan (L1) |
| `mapAsPerLevel` int[30] | payload `:array_101` | ukuran 30→40; payload 40 entri (30 asli + 10 desain) |
| `heartForLevels` int[35] | payload `:array_102` | ukuran 35→40; 30 entri pertama dipertahankan, 10 terakhir diganti desain |
| `moneyForLevels` int[30] | payload `:array_103` | sama seperti map |
| `weaponsAvailabeForLevels` int[35] | payload `:array_104` | ukuran 35→40; 10 baru = 9 (semua senjata) |
| `weaponsFighterAvailabeForLevels` int[30] | payload `:array_105` | ukuran bersama v0; 10 nilai desain |
| `weaponsMinesAvailabeForLevels` int[30] | payload `:array_106` | ukuran bersama v0; 10 nilai desain |
| `TowerCanvas.Score` int[30] | `<clinit>` TowerCanvas | 0x1e→0x28; payload 40 nol |
| `ChallengesMenu.LEVEL_MEDELS` Integer[30] | `<clinit>` ChallengesMenu | ukuran 0x28; blok aput indeks 30–39 ditambah (nilai 3 = tanpa medali) |
| `GallaryScreen.MAX_CHALLANGES` | field = 0x1e | → 0x28 (40 kotak level = 5 layar: 4×9 + 4) |
| literal batas di `GallaryScreen.calculateParameters` | `const/16 v1, 0x1e` | → 0x28 (jumlah layar) |
| literal di `checkSelectedBox` | `const/16 v5, 0x1e` | → 0x28 |
| literal di `paintGallaryBox` | `const/16 v2, 0x1e` | → 0x28 |
| literal di `pointerReleasedForDots` | `const/16 v2, 0x1e` dan klem `const/16 v3, 0x1d` | → 0x28 dan → 0x27 (indeks maks 39) |
| `InGameMenu.removeSkip` | `const/16 v1, 0x1d` (>= 29) | → 0x27 (tombol skip hilang hanya di level terakhir = 40) |

**Sengaja TIDAK diubah** (bukan soal jumlah level):
`GallaryScreen.PADDING_OF_DOTS` (0x1e = spasi piksel antar titik navigasi)
dan dua literal `0x1e` di `drawDots` yang berasal darinya.

### Pengaman terkait (temuan audit, sumber crash potensial)

1. **`AdsConstants.LeaderBoardKeys` hanya berisi 30** ID leaderboard Play
   Games asli. Tiga loop mengiterasi `Score.length` sambil mengindeks
   `LeaderBoardKeys[i]` → pada level 31–40 akan
   ArrayIndexOutOfBounds. Diperbaiki dengan membatasi loop ke
   `LeaderBoardKeys.length` (L8a `TowerCanvas.SubmitScore`, L8b
   `TowerCanvas.showLeaderBoard`, L8c `WinMenu.setValue`) dan intent di
   `SubmitScore` dijaga: indeks ≥ 30 membuka daftar semua leaderboard
   (L8d). **Tidak ada ID leaderboard palsu yang dibuat.**
2. **Simpanan lama menimpa array progres:** `TowerDefenderMidlet.loadRMS()`
   mengganti `TowerCanvas.Score` & `LEVEL_MEDELS` dengan salinan dari
   penyimpanan (30 entri pada simpanan dari game asli/v1) → array menyusut
   lagi → crash di level 31–40. Diperbaiki: `ModActions.
   normalizeLevelArrays()` (pad Score→40 nol, medali→40 nilai 3, null
   dirapikan) dipanggil di akhir `loadRMS` (L9).
3. **Format gelombang:** tiap wave = 6 int `[Soldier, BomberMan, Vehical,
   Bike, Tank, Helicoptor]` (urutan argumen `WaveCreator.createWave`).
   Objek musuh satu gelombang dibuat sekaligus saat level dimuat, jadi
   total per gelombang dibatasi ≤ 185 (level bawaan terpadat ≈ 320 total
   per level; desain baru per gelombang jauh di bawah beban per-gelombang
   level bawaan terberat). Register blok pertumbuhan memakai v5–v15
   (register ukuran `new-array` & daftar `invoke` format smali maksimal
   v15 — percobaan pertama dengan v59–v64 ditolak assembler, sudah
   diperbaiki & terbukti assemble).
4. Otomatis ikut 40 tanpa patch: `WaveCreator.getTotalLevels()` =
   `levelsArray.length`, `InGameMenu.skip()` memakai
   `LEVEL_MEDELS.length`, logika medali & `setCurrentLevel` mengindeks
   lewat `USER_CURRENT_LEVEL_ID`.
5. Menu: `unlockAll()` kini membuka **40** level, editor skor/medali
   mencakup level **1–40** (`levelCount()` min 40).

---

## 3. Sepuluh level baru — desain orisinal

Roster musuh memakai 6 tipe yang benar-benar ada di mesin game:
Soldier, BomberMan, Vehical, Bike, Tank, Helicoptor. Format data mengikuti
format mesin (keharusan teknis); **isi** — komposisi gelombang, tempo,
uang awal, kurva jumlah — disusun baru per level. Kesulitan juga naik
otomatis dari rumus HP mesin (mis. HP kendaraan/tank/helikopter =
`3 + level/5` lapis). Uang awal & hearts adalah parameter desain per level.

Format gelombang di bawah: `[Soldier, BomberMan, Vehical, Bike, Tank,
Helicoptor]` per gelombang.

### L31 — GERBANG PATAH (peta 5, uang 550, hearts 10, 8 gelombang, 401 musuh)
Konsep: gerbang pembuka babak baru — infanteri & peledak kelas menengah,
kendaraan lapis ringan menyusul belakangan; mengajarkan pemain bahwa
babak 31+ menuntut pertahanan campuran sejak awal.
Gelombang: `[25,10,0,0,0,0] [20,15,2,0,0,0] [30,10,3,5,0,0] [15,20,5,5,0,0]
[25,15,5,10,1,0] [10,10,8,10,2,0] [30,20,5,10,2,2] [20,20,10,15,3,3]`
Pembeda: satu-satunya level baru yang eskalasinya "buku teks" (tiap tipe
musuh diperkenalkan berurutan) — jembatan dari level 30.

### L32 — ARUS MOTOR (peta 3, uang 450, hearts 10, 9 gelombang, 529 musuh)
Konsep: tema kecepatan murni — gelombang didominasi Bike yang datang
seperti arus lalu lintas; infanteri hanya pengalih perhatian.
Gelombang: `[0,0,0,20,0,0] [10,0,0,25,0,0] [15,5,0,30,0,0] [0,10,0,35,0,0]
[20,10,2,30,0,0] [10,0,0,40,1,0] [25,15,0,35,1,2] [15,20,3,40,2,2]
[30,20,5,45,2,4]`
Pembeda: uang awal sengaja kecil (450) — pemain dipaksa memilih senjata
anti-cepat, bukan menumpuk senjata berat.

### L33 — HUJAN BAJA (peta 2, uang 500, hearts 10, 9 gelombang, 466 musuh)
Konsep: tema udara — helikopter mulai dari 5 lalu menumpuk bertahap
sampai jadi mayoritas gelombang; darat hanya cukup untuk mengganggu
pertahanan anti-udara pemain.
Gelombang: `[10,0,0,0,0,5] [10,5,0,0,1,8] [15,5,0,5,1,10] [10,10,2,5,2,12]
[20,10,0,0,2,15] [15,15,3,10,2,15] [20,10,5,10,3,18] [25,15,5,10,3,20]
[30,20,5,15,4,25]`
Pembeda: kurva helikopter monoton naik (satu-satunya level bertema
satu-sumber ancaman yang tumbuh terus).

### L34 — KONVOI MAUT (peta 5, uang 550, hearts 10, 9 gelombang, 447 musuh)
Konsep: tema konvoi lapis baja — Vehical & Tank lambat berlapis-lapis
tanpa gelombang cepat; ujian DPS berkelanjutan, bukan reaksi.
Gelombang: `[0,0,10,0,2,0] [5,0,12,0,3,0] [5,5,15,0,3,0] [10,5,15,5,4,0]
[10,10,18,5,4,2] [15,10,20,5,5,2] [15,15,20,10,6,3] [20,15,25,10,6,4]
[25,20,25,10,8,5]`
Pembeda: nol Bike di semua gelombang — kebalikan persis L32.

### L35 — TETESAN ABADI (peta 3, uang 400, hearts 8, 12 gelombang, 445 musuh)
Konsep: tema atrisi — 12 gelombang kecil yang tidak pernah memberi jeda
panjang; uang awal terendah (400) dan hearts dikurangi (8): ujian
efisiensi & perbaikan menara, bukan kekuatan kasar.
Gelombang: `[12,4,0,0,0,0] [14,4,1,2,0,0] [12,6,1,2,0,0] [16,6,2,4,0,0]
[14,8,2,4,1,0] [18,8,2,6,1,0] [16,10,3,6,1,1] [20,10,3,8,1,1]
[18,12,4,8,2,1] [22,12,4,10,2,2] [20,14,5,10,2,2] [26,16,5,12,3,3]`
Pembeda: jumlah gelombang terbanyak kedua (12) dengan gelombang terkecil
— satu-satunya level "tetesan" di seluruh game.

### L36 — DUA MUSIM (peta 4, uang 500, hearts 10, 10 gelombang, 750 musuh)
Konsep: tema dua musim — gelombang ganjil = musim darat (infanteri &
kendaraan berat, udara nol), gelombang genap = musim udara (Bike +
helikopter, darat ringan). Pemain tidak bisa memakai satu komposisi
pertahanan untuk dua gelombang berurutan.
Gelombang: `[30,15,5,0,2,0] [0,5,0,25,0,12] [25,20,8,0,3,0] [5,10,0,30,0,15]
[35,20,10,5,4,0] [10,10,0,35,1,18] [30,25,10,10,5,2] [15,15,0,40,2,20]
[40,25,12,15,6,5] [20,20,5,45,3,22]`
Pembeda: pola selang-seling ekstrem — tidak ada level lain (lama maupun
baru) yang berganti tema tiap gelombang.

### L37 — BANJIR BESI (peta 2, uang 600, hearts 10, 10 gelombang, 1.098 musuh)
Konsep: tema banjir unit ringan — Vehical & Bike dalam angka massal;
tekanan datang dari jumlah, bukan ketebalan armor.
Gelombang: `[20,0,15,20,0,0] [25,5,18,25,0,0] [20,10,20,30,1,0]
[30,10,22,30,1,2] [25,15,25,35,2,2] [35,15,25,40,2,4] [30,20,28,40,3,4]
[40,20,30,45,3,6] [35,25,30,50,4,6] [40,25,30,45,4,6]`
Pembeda: total musuh menembus 1.000 dengan unit ringan — ujian senjata
area & ranjau, bukan anti-tank.

### L38 — LANGIT MERAH (peta 5, uang 550, hearts 10, 10 gelombang, 926 musuh)
Konsep: tema sinergi lapis — Tank berjalan di depan sebagai tameng,
helikopter menyerang dari belakangnya; membunuh tameng dulu atau
anti-udara dulu adalah dilema di setiap gelombang.
Gelombang: `[15,15,0,0,3,8] [20,20,2,5,3,10] [15,25,3,5,4,12]
[25,20,5,10,4,14] [20,25,5,10,5,16] [30,25,8,15,5,18] [25,30,8,15,6,20]
[35,30,10,20,6,22] [30,35,10,20,7,24] [40,35,12,25,8,28]`
Pembeda: satu-satunya level di mana Tank & Helicoptor selalu muncul
berpasangan menaik bersama dari gelombang pertama.

### L39 — AMBANG RUNTUH (peta 3, uang 650, hearts 10, 11 gelombang, 1.467 musuh)
Konsep: pra-klimaks — tanpa pemanasan: semua tipe sudah besar sejak
gelombang pertama, dan setiap gelombang berikutnya menaikkan semua tipe
sekaligus. Ujian konsistensi sebelum level terakhir.
Gelombang: `[25,20,8,15,3,8] [30,20,10,20,4,10] [25,25,12,20,5,12]
[35,25,12,25,5,14] [30,30,15,25,6,16] [40,30,15,30,6,18] [35,35,18,30,7,20]
[45,35,18,35,7,22] [40,40,20,35,8,24] [50,40,20,40,8,26] [45,35,18,32,8,22]`
Pembeda: gelombang pertama terberat di antara semua level baru — tidak
ada kurva pembuka sama sekali.

### L40 — HARI PENGHABISAN (peta 5, uang 700, hearts 10, 12 gelombang, 1.770 musuh)
Konsep: klimaks penutup yang dirancang sebagai final — 11 gelombang
eskalasi penuh semua tipe, ditutup gelombang ke-12 yang berubah bentuk
total: dinding lapis baja `[15,10,5,10,30,40]` (30 Tank + 40 Helicoptor)
sebagai ujian terakhir. Uang awal terbesar (700) karena memang tidak ada
waktu membangun bertahap.
Gelombang: `[30,25,10,20,4,10] [35,25,12,25,5,12] [30,30,15,25,6,14]
[40,30,15,30,6,16] [35,35,18,30,7,18] [45,35,18,35,7,20] [40,40,20,35,8,22]
[48,40,20,38,8,24] [44,40,22,38,9,23] [48,40,22,40,9,24] [50,42,22,40,9,22]
[15,10,5,10,30,40]`
Pembeda: satu-satunya gelombang "dinding final" di game — komposisi
penutup yang sengaja tidak menyerupai gelombang mana pun sebelumnya.

Kurva kesulitan total musuh: 401 → 529 → 466 → 447 → 445 → 750 → 1.098 →
926 → 1.467 → 1.770 (turun-naik kecil antar-tema disengaja: tiap level
menguji keterampilan berbeda; tekanan puncak tetap di 39–40, ditambah
skala HP bawaan mesin yang naik per level).

---

## 4. Verifikasi

- Build lokal & CI sama-sama hijau; **dex CI identik byte-per-byte**
  dengan dex lokal terverifikasi (SHA-256 di atas).
- 34 patch lolos asersi pola persis (P1–P5, P6a–c, L1, L2a–c, L4a–b,
  L5a–b, L6a–f, L7, L8a–d, L9) — pola tidak cocok = build gagal keras.
- 52 cek konten terprogram atas decompile APK final, semua lulus:
  payload per-level 40 entri (30 pertama == asli, 10 terakhir == desain);
  100 payload gelombang baru == desain berurutan; blok pertumbuhan utuh;
  Score 40 nol; LEVEL_MEDELS terisi 0–39; MAX_CHALLANGES 0x28; removeSkip
  0x27; `init` tepat 1× di onCreate SETELAH setContentView;
  ensureInstalled di onResume & onWindowFocusChanged; loadRMS memanggil
  normalize; Toast & tag tombol ada.
- Diff ternormalisasi final vs v1 (dex1): berubah HANYA 8 file game
  (WaveCreator, TowerCanvas, TowerDefenderMidlet, GameActivity,
  ChallengesMenu, GallaryScreen, InGameMenu, WinMenu) + kelas modmenu —
  P1–P5 & ModConfig identik dengan v1. Sisa selisih vs APK asli adalah
  derau round-trip baksmali yang sama persis dengan v1 (mis. elisi
  `= false` pada field final) — set file derau v2 == v1 + 6 file patch
  baru di atas.
- `apksigner verify` OK; zipalign OK; sertifikat == v1.

## 5. Yang belum pasti (jujur)

- **Uji runtime tetap di HP user**: apakah Toast "MOD MENU AKTIF" muncul,
  tombol terlihat di atas SurfaceView pada perangkat nyata, dan 10 level
  baru dimainkan sampai selesai tanpa crash — verifikasi di sini statis
  (struktur & kode), bukan menjalankan game.
- Tempo jeda antar-musuh dalam gelombang memakai bawaan mesin (sama
  seperti level asli); yang dirancang adalah komposisi & jumlahnya.
- Skor level 31–40 tetap tersimpan & tampil lokal; leaderboard per-level
  untuk 31–40 tidak ada di Play Games (tidak dibuat palsu) — menu
  leaderboard membuka daftar semua leaderboard sebagai gantinya.
