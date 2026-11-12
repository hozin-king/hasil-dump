# Defend The Bunker — Mod Menu Gabung v3: catatan build

Repo: `hozin-king/hozin-bunker-mod` (privat), folder `modmenu/`.
Commit sumber (lokal): `cb7d12e`; commit remote hasil push: `47c0f1c78b9c9c5dc3fb71529e35e30ac1c48e9e` di `main` (terverifikasi via API; tree memuat semua file baru).
CI: run dispatch `39701425992` (success), run tag `39701593744` (success).
Rilis: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v3
APK: `DefendTheBunker-ModMenu-v3.apk`, 12.415.210 byte (aset release & artifact CI id `12393495502`).
Dex CI == dex build lokal byte-per-byte (classes.dex `4ee0c825…`, classes2.dex `467693c9…` — classes2 sama dengan v2, memang tidak disentuh).
Sertifikat == v1/v2 (`f7a4306a…`) → bisa dipasang menimpa modmenu-v1/v2 tanpa uninstall & tanpa kehilangan simpanan.

Empat fitur baru di atas v2 (isi v2 tidak berubah — lihat verifikasi):
pengali skor ×100, save tengah permainan + "Lanjutkan", unlock selalu
aktif, Level Maker ala DYOM. Ditambah popup kredit "Mod by" (scope
tambahan user di tengah pengerjaan).

---

## 1. Pengali skor ×100 selalu aktif (patch SCORE)

**Titik kait — tepat satu, terbukti dari kode:** satu-satunya tempat skor
bertambah selama permainan adalah di `TowerEngine.removeNon_AlivedCharacters()`:

```java
if (!character.isTargetFound()) {   // musuh mati terbunuh pemain
    getInstance().setScore(getInstance().getScore() + character.getScoreCost());
    ... setMoney(getMoney() + character.getMoneyCost());
}
```

Patch menyisipkan `mul-int/lit8 v6, v6, 0x64` tepat sesudah
`move-result v6` dari `getScoreCost()` dan sebelum `add-int/2addr v5, v6`
— jadi yang dikalikan adalah **tambahan skor per musuh** (harga skor:
Soldier 50, BomberMan 100, Vehical 250, Bike 150, Tank 500, Helicoptor
250). Konsekuensi konsisten di semua permukaan: skor berjalan & HUD
(`getScore()`), total akhir `score + money` di `WinMenu.setValue` yang
ditulis ke `TowerCanvas.Score[level]`, semuanya ×100 dari sumber yang
sama. Tidak ada pengali di `setScore`, di jalur load/save, atau di editor
skor (editor tetap menulis nilai persis yang diketik user) → **tidak ada
dobel-kali**.

**Keamanan overflow (dihitung persis, bukan dikira):** skor dasar
maksimum per level dihitung dari data gelombang ke-40 level (30 asli dari
initializer `WaveCreator` + 10 desain v2): maksimum = **282.100** di
level 40. ×100 = 28.210.000; ditambah uang maksimum 999.999 → 29.209.999,
jauh di bawah batas int32 (2.147.483.647, margin ±73×). Tanpa klem
tambahan. Medali berbasis persen nyawa bunker (bukan skor), jadi ambang
medali tidak berubah.

## 2. Save tengah permainan + "Lanjutkan" (patch R1–R5 + `ModState`)

### Kenapa titik kaitnya di `TowerEngine.loadWave()`
Alur muat level mesin: `ChallengesMenu.levelSelected(i)` →
`TowerEngine.setCurrentLevel(i)` + `TowerCanvas.setCanvasGameState(6)` →
utas loading `LoadingEngineStateClass.setLoadingState()` menjalankan
`resetEngine()` (skor=0, wave=-1) → `loadLevel(i)` (uang/nyawa/senjata
dari array per-level) → `levelIncremental()` (wave 0). Sesudah banner
gelombang (state 12) selesai, mesin memanggil `TowerEngine.loadWave()`
yang memuat musuh gelombang berjalan lewat
`waveCreator.loadWave(map, level, USER_CURRENT_WAVE_ID)`. Kepala
`loadWave()` adalah satu-satunya titik yang (a) dilewati tepat sebelum
tiap gelombang mulai, (b) sesudah SELURUH reset loading selesai, dan
(c) sebelum musuh dibuat — tempat yang benar untuk menerapkan restore
dan untuk snapshot awal gelombang.

### Desain
- **Isi snapshot** (SharedPreferences privat `hozin_snapshot`): indeks
  level, indeks gelombang, uang (`getMoney()`), nyawa bunker
  (`TOWER_HELTH`), skor terkumpul (`getScore()`), dan untuk level
  buatan: id + nama level buatannya.
- **Kapan disimpan:** (R1) di kepala `loadWave()` — yaitu awal tiap
  gelombang; (R4) di ekor `GameActivity.onPause()` sesudah invoke-super,
  hanya bila sesi level aktif — menyimpan nilai TERKINI gelombang yang
  sedang berjalan (melanjutkannya mengulang gelombang itu dari awal
  dengan uang/nyawa/skor terkini). Bila proses dibunuh tanpa onPause,
  snapshot awal gelombang terakhir tetap utuh.
- **Alur restore:** tombol **"Lanjutkan: Level X • Gelombang Y"** (atau
  nama level buatan) di panel mod — tampil hanya bila snapshot ada.
  Klik → (untuk level buatan: data level dipasang dulu ke slot cadangan
  dari simpanan JSON) → restore disimpan sebagai *pending* di
  `ModState` → `setCurrentLevel(level)` + `setCanvasGameState(6)` —
  jalur yang sama persis dengan galeri. Di kepala `loadWave()` pertama
  sesudah itu, `onEnterWave()` menerapkan: `USER_CURRENT_WAVE_ID =
  wave`, `setScore(skor)`, `setMoney(uang)`, `TOWER_HELTH = nyawa` —
  lalu snapshot ditulis ulang dengan nilai yang sama (idempoten).
  Catatan: `setMoney` tunduk pada patch P2 — bila toggle uang tak
  terbatas aktif, uang hasil restore menjadi 999999 (konsisten dengan
  perilaku toggle, bukan bug).
- **Kapan terhapus:** (R2) kepala `WinMenu.setValue(int)` — hanya jalur
  menang; (R3) kepala `TowerEngine.GameOverChack()` — terhapus hanya
  bila `TOWER_HELTH <= 0` benar-benar terjadi; (R5)
  `TowerCanvas.setCanvasGameState(6)` — state 6 hanya dipasang oleh
  `levelSelected`, jadi memulai level manual dari galeri menggugurkan
  snapshot lama (start dari tombol Lanjutkan / Level Maker dijaga
  `startGuard` sekali pakai agar tidak ikut menggugurkan); menghapus
  level buatan yang ditunjuk snapshot juga menggugurkannya.
- **Yang TIDAK dipulihkan (jujur):** senjata yang sudah terpasang di
  lapangan (`weaponVector` dibangun ulang oleh alur muat level; tidak
  ada jalur serialisasi objek Weapon yang terbukti aman dari kode) dan
  posisi musuh tengah gelombang. Kelanjutan selalu = awal gelombang
  snapshot, tanpa senjata lapangan, dengan uang/nyawa/skor snapshot.

## 3. Unlock semua level — selalu aktif

Implementasi v2 (`ModActions.unlockAll()`: `MAX_UNLOCKED_LEVELS = 40`,
`lastAvailableWeapon = 8`, disimpan via `GlobalStorage.addValue` dengan
kunci yang sama seperti game) kini **dipanggil otomatis dari
`ModMenu.init`** setiap game dibuka (dan ditegaskan lagi saat panel menu
dibangun), jadi tidak lagi bergantung tombol. Tombol manual tetap ada
dan idempoten. Terverifikasi di APK final: `ModMenu` memanggil
`unlockAll()` ≥2 titik (init + showMenu).

## 4. Level Maker ala DYOM (`CustomLevels` + UI di `ModMenu`)

- **Data & simpanan:** JSON di SharedPreferences privat
  `hozin_custom_levels` — banyak level, tiap level:
  `{id, name, map (0–5), money, hearts, fighter, mines,
  waves: [[S,B,V,Bk,T,H] × 1–12]}`. Format gelombang = format mesin
  persis (urutan argumen `WaveCreator.createWave`, sama seperti level
  31–40 v2). Bisa dibuat/diedit/dihapus dari panel mod (menu "Level
  Buatan (DYOM) — Buat & Mainkan"); editor per gelombang memakai satu
  kolom teks 6 angka dipisah koma (ringkas di layar HP) dengan
  penjelasan urutan tipe musuh.
- **Validasi sebelum simpan/main:** nama tak kosong; peta 0–5; uang
  0–99999; nyawa 1–99; fighter/mines 0–9; gelombang 1–12; tiap tipe
  0–99; total per gelombang 1–185 (batas aman yang sama dengan
  validasi desain v2); pesan kesalahan Bahasa Indonesia.
- **Jalur "Mainkan" (dari bukti kode):** data level ditulis ke **slot
  cadangan indeks 40** pada `WaveCreator` yang sedang hidup —
  `levelsArray[40]`, `mapAsPerLevel[40]`, `moneyForLevels[40]`,
  `heartForLevels[40]`, `weaponsAvailabeForLevels[40] = 9` (semua
  senjata, seperti level 31–40), `weaponsFighterAvailabeForLevels[40]`,
  `weaponsMinesAvailabeForLevels[40]`. Field-field itu privat di kelas
  asli, jadi penulisan lewat refleksi pada kelas aplikasi sendiri
  (nama & tipe field terverifikasi dari smali dan dicek ulang di
  verifikasi final). Lalu start memakai jalur galeri yang sama persis:
  `TowerEngine.setCurrentLevel(40)` + `setCanvasGameState(6)`.
  `loadLevel(40)` lolos gerbangnya karena `getTotalLevels()` kini 41.
- **Prasyarat patch (perubahan minimal atas patch v2, semua
  terdokumentasi di header `apply_patches.py`):** konstanta ukuran di
  L1/L2a/L2b/L4a/L5a 0x28 → 0x29; growth L1 menambah placeholder slot
  40 (1 gelombang kosong — tidak pernah bisa dipilih tanpa install,
  galeri tetap 40 kotak karena `MAX_CHALLANGES` tetap 40); payload L4b
  Score 41 nol; aput L5b s/d indeks 40. Isi 40 level pertama TIDAK
  berubah (payload per-level & 100 payload gelombang diverifikasi
  identik dengan APK v2).
- **Skor/medali level buatan:** jalur menang/kalah mesin menulis ke
  slot indeks 40 pada `TowerCanvas.Score`/`LEVEL_MEDELS` — slot milik
  mod sendiri, BUKAN slot 40 level bawaan (0–39 tidak pernah ditulis
  oleh sesi level buatan). Skor terbaik antar-level-buatan berbagi satu
  slot cadangan itu (panel Level Maker tidak menampilkan skor per
  level buatan agar tidak menyesatkan); tidak ada ID leaderboard palsu
  (loop submit tetap dibatasi 30 kunci asli oleh patch L8 v2).
- **Batasan jujur:** tempo spawn tidak punya parameter per level dalam
  format data mesin (jeda spawn diatur konstanta di
  `WaveCreator.getWaveCharacter`) → level buatan memakai tempo bawaan
  mesin; UI editor menyebutkannya terang-terangan. Peta dipilih dari
  6 peta bawaan (0–5), tidak ada editor peta.

## 5. Popup kredit "Mod by Hozin King"

Di `ModMenu.installNow()`, pada pemasangan pertama yang berhasil:
Toast "MOD MENU AKTIF" tampil lebih dulu (persis seperti v2), lalu
popup dijadwalkan **+1400 ms** lewat Handler UI utama →
`showCreditPopup()`: `AlertDialog` berjudul "Defend The Bunker — Mod
Menu v3", isi persis `Mod by Hozin King` + satu baris fitur v3
("Pengali Skor ×100 • Lanjutkan Permainan • Level Maker"), satu tombol
tutup **"Mainkan"**. Sekali per proses (flag statis `creditShown`),
batal diam-diam bila `act.isFinishing()` / `isDestroyed()` (API ≥17).
Hook-nya murni di kode mod (bukan patch game) — keberadaannya dicek di
verifikasi final (teks kredit, judul, guard, `postDelayed` sesudah
toast).

## 6. Patch yang berubah dari v2 (dan kenapa)

Hanya perubahan ukuran slot cadangan di atas (L1, L2a, L2b, L4a, L4b,
L5a, L5b) — isi datanya untuk 40 level pertama identik. Patch P1–P6,
L2c, L6, L7, L8, L9 tidak diubah isinya. Patch baru v3: SCORE, R1–R5
(total patch lolos asersi saat build: **41**).

## 7. Verifikasi (terprogram, dijalankan pada build lokal DAN APK CI)

**41 cek konten, semua lulus** di kedua APK (skrip:
`~/workspace/rea-bunker/work-v3/verify_v3.py`), mencakup: posisi &
keunikan pengali ×100 (satu titik, urutan benar, tidak ada pengali lain
di setScore/WinMenu); 5 kait ModState tepat 1× di posisi benar (R1 di
kepala loadWave, R4 sesudah invoke-super onPause, R5 + guard state 6);
ukuran 41 & placeholder slot 40; payload per-level (30 pertama == asli,
10 terakhir == desain) & 100 payload gelombang 31–40 == desain
(mengikuti urutan referensi `fill-array-data` — baksmali mengganti nama
label payload di APK final, jadi nama label tidak dipakai sebagai
bukti); Score 41 nol; LEVEL_MEDELS aput s/d 40; `MAX_CHALLANGES` tetap
40; kompatibilitas payload dengan APK v2; kelas `CustomLevels`/`ModState`
hadir + nama field refleksi persis terdeklarasi di `WaveCreator`; teks
UI Level Maker & kejujuran tempo; popup kredit (teks persis, judul,
guard, urutan sesudah toast); unlock dari init; kait menu P6a–c utuh;
markah fitur P1–P5 utuh; perhitungan overflow skor persis.

Diff ternormalisasi (buang `.line` + elisi nilai bawaan field) final vs
APK asli: file game yang berbeda substantif = **11 file yang sama
persis dengan set v1/v2** (WaveCreator, TowerCanvas, TowerDefenderMidlet,
TowerEngine, GameActivity, GameThread, Character, ChallengesMenu,
GallaryScreen, InGameMenu, WinMenu) + kelas `com.hozin.modmenu` —
v3 tidak menyentuh file game baru. `apksigner verify` OK; zipalign OK;
sertifikat == v1/v2.

## 8. Yang belum pasti (jujur — perlu uji runtime di HP user)

- **Belum ada uji runtime sama sekali** (seperti v1/v2): apakah tombol
  MOD + Toast + popup kredit tampil berurutan dengan nyaman, snapshot
  "Lanjutkan" benar-benar memulihkan sesi (termasuk sesudah proses
  dibunuh), dan level buatan bisa dimainkan tuntas — verifikasi di sini
  statis menyeluruh (struktur, posisi kait, dan semantik alur dari
  kode), bukan menjalankan game.
- Popup kredit memakai `AlertDialog` dari thread UI sesudah pemasangan
  menu; bila SDK iklan game membuka activity lain tepat di jendela
  +1400 ms itu, popup bisa tampil di atas konteks yang berganti —
  guard `isFinishing/isDestroyed` menahan crash, tetapi momen tampil
  persisnya hanya bisa dipastikan di perangkat.
- Restore di tengah level 1 (level indeks 0) dengan sesi bantuan
  (`isFirstHelpOver` belum selesai): alur bantuan mesin berjalan lebih
  dulu; restore teraplikasi di `loadWave()` pertama sesudahnya —
  secara kode konsisten, tetapi kombinasi ini yang paling layak diuji
  pertama di HP.
- Skor level buatan menempati slot cadangan bersama (lihat §4) — bukan
  per level buatan; disengaja dan didokumentasikan, bukan bug.
