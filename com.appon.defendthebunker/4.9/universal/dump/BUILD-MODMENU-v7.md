# Defend the Bunker — Laporan Bangun Mod Menu Gabung v7

Tanggal: 22 Oktober 2026. Repo: `hozin-king/hozin-bunker-mod`.
Pemicu: uji HP user atas v6 (22 Okt 20:41) — uang 99,9M terbukti
(patokan per tick jalan), Railgun & Tesla tampil di bar pembangunan
semua level, **tetapi tidak bisa dipilih dan tidak ada penempatannya**.
Perintah user: "Gas, tambahkan semua yang terbukti bisa ke v7"
(+ 6 fitur yang disarankan asisten).

---

## 1. AKAR BUG RAILGUN/TESLA (terbukti dari decompile, dua gerbang)

Railgun (id 99) & Tesla (id 100) menempel di UJUNG vektor popup
pembangunan (`WeaponPopup.poupVector`: indeks 0 = tombol kembali,
lalu senjata bawaan level, lalu keduanya). Tampilan sudah benar sejak
v5/v6 (guard gambar `size <= TOTAL_WEAPON_COUNT`=9; vektor maks 9
entri) — yang membunuh adalah dua gerbang warisan game asli yang
tidak pernah tersentuh patch v1–v6:

**Gerbang 1 — klem seleksi (`WeaponPopup.handledPointerPressed/ReleasedWeaponPopup`).**
Kedua handler menghitung ulang indeks dari posisi sentuh, lalu di
ekor method: `if (iteamSelectedIndex > waveCreator.getWeaponsAvailabeForLevels(USER_CURRENT_LEVEL_ID)) iteamSelectedIndex = 0;`
(handler lepas juga meneruskan pilihan sebagai batal). Indeks popup
0 adalah tombol kembali, jadi senjata ke-k duduk di indeks k; klem
memakai jumlah senjata BAWAAAN level. Akibat per level (avail =
senjata bawaan): Tesla selalu gugur kecuali avail≥8 (indeksnya
avail+1); Railgun gugur bila avail≤1 (indeks avail > avail? tidak —
Railgun di indeks avail selalu lolos klem; lihat gerbang 2).

> Koreksi atas diagnosis awal: pada level dengan avail kecil,
> Railgun lolos klem tetapi tetap mati oleh gerbang 2.

**Gerbang 2 — jebakan state 21 (`WeaponPopup.keyPressedWeaponPopup`).**
Sesudah `buyWeapon(false)` + `createWeaponObject()`, klausa
`(!isFighterMinesPopup && getIteamSelectedIndex() == 7) { setEngineState(21); return; }`
mengalihkan ke state 21 = sapuan serang jet (`TowerEngine.handleEngineUpdate`
state 21 membunuh karakter di depan FIGHTER_X_POSITION) dan RETURN —
tanpa `updateWeapon()`, tanpa `keyPressedWeapon()`, tanpa penempatan.
Di game asli klausa ini kode mati (vektor popup pembangunan maks 7
entri → indeks 0–6; indeks 7 tak tercapai) dan pasangan sahnya hanya
popup jet/ranjau (`isFighterMinesPopup && indeks==1` = jet id 97).
Railgun di popup ber-avail 7 menempati persis indeks 7 → selalu
teralihkan. Pemeriksaan pasangan yang sama di
`Background.keyPressedWeapon` (`indeks != 7` menggerbang pembukuan
pasca-tanam: flag tanam/reset indeks/UI) — di sana kondisinya terbalik
sehingga jalur Railgun (indeks 7) justru terlewat dari pembukuan;
keduanya diselaraskan.

### Fix (patch V7-T1..T4 di apply_patches.py)
- **T1/T2**: batas klem di kedua handler diganti dari
  `getWeaponsAvailabeForLevels(level)` menjadi `poupVector.size()-1`
  (indeks terakhir vektor popup yang benar-benar terisi; register
  hasil & label dipertahankan — patch bedah blok, pola persis dari
  decompile apktool segar, asersi exact-match).
- **T3**: konstanta pembanding klausa di keyPressedWeaponPopup
  `0x7 → 0x63` (tak pernah tercapai: vektor maks 10 entri) — klausa
  kembali mati seperti di game asli; klausa fighter (indeks 1) utuh.
- **T4**: pasangan di Background.keyPressedWeapon identik `0x7 → 0x63`.

### Bukti jalur utuh (level awal, avail=2: Machine Gun + Laser)
- **Pemilihan**: tekan ikon Railgun → indeks 2 ≤ size−1 → tidak
  ter-reset; isWeaponAvailable(99) = cek uang (lolos: uang unlimited).
- **Pembuatan**: keyPressedWeapon → keyPressedWeaponPopup →
  buyWeapon(false) (uang ≥ 250 ✓) → createWeaponObject membaca
  `elementAt(2).getWeaponID()` = 99 → cabang BARU → RailTowerWeapon.
- **Penempatan**: klausa indeks==7 tidak lagi menelan (indeks 2; dan
  untuk avail 7, indeks 7 juga aman) → updateWeapon() →
  Background.keyPressedWeapon → isStandinTileValid + belum tertanam
  → buyWeapon(true) → addElement + BinaryInsertionSort.
- **Penembakan**: loop senjata TowerEngine.handleEngineUpdate
  generik (isAttachedToEnemy → reduceHelth) — Railgun/Tesla subclass
  Weapon yang sama seperti tower bawaan.
- Verifikasi terprogram: 18 cek V7 dalam verify_v7 (92 total) atas
  decompile APK final, termasuk "WeaponPopup 0 referensi
  getWeaponsAvailabeForLevels" dan "rantai create→update→tanam utuh".

**Karakter bidik warisan (bukan cacat, didokumentasikan jujur):**
Railgun extends LaserWeapon → target darat saja; Tesla extends
MissileLaunchWeapon → target udara (helikopter) saja — persis aturan
tower bawaan sekelasnya (teks help Missile asli memang menulis
"Can Damage Flying Units only").

## 2. STATUS 6 FITUR

| Fitur | Status | Bukti jalur kode |
|---|---|---|
| a. Markas kebal | **Sudah ada sejak v1 — terverifikasi ulang** | Patch P3 melewati SATU-SATUNYA titik pengurangan `TowerEngine.TOWER_HELTH` (di removeNon_AlivedCharacters, cabang musuh mencapai target) bila `ModConfig.godMode`; checkbox menu "God Mode Bunker" sudah ada. TOWER_HELTH = nyawa ♥ HUD. |
| b. Pengali damage ×2/×5/×10 | **Sudah ada — tetap** | Patch P4 mengalikan `Character.reduceHelth(int)` (satu-satunya pengurang HP karakter; dipanggil semua senjata & ledakan) dengan `ModConfig.damageMul`; sentinel −1 (bunuh instan) tidak dikalikan. Menu: pemilih siklus tunggal {1,2,5,10}. |
| c. Kecepatan ×1,5/×2/×3 | **Terbit — disempurnakan** | Loop tunggal GameThread (draw+update lalu sleep sisa WAIT_TIME=76 ms) mengatur musuh & menara seragam. P5 kini: `WAIT_TIME*100/speedMul` dengan speedMul persen {100,150,200,300} = 1x/1,5x/2x/3x. Nilai lama 1/2/3 ter-reset ke 100 saat load. |
| d. Buka semua menara & level | **Sudah ada sejak v3 — tetap** | `ModActions.unlockAll()` selalu-aktif: MAX_UNLOCKED_LEVELS=100 & lastAvailableWeapon=TOTAL_WEAPON_COUNT−1 ditulis via GlobalStorage (kunci penyimpanan resmi game) + field statik. Catatan: popup pembangunan digerakkan tabel per-level game (weaponsAvailabeForLevels), bukan lastAvailableWeapon — karena itu fix klem T1/T2 tetap diperlukan dan sudah dibuat. |
| e. Musuh membeku | **BARU — terbit** | `ModConfig.freezeEnemies` (persist "frz") + patch V7-F1 di kepala `Character.updateCharacters()` (final di kelas dasar, tidak di-override subclass mana pun — satu pintu update SEMUA tipe musuh) + V7-F2 di kepala `WaveCreator.getWaveCharacter()` (spawn ikut berhenti). Loop senjata tidak disentuh → menara tetap mengunci & menembak target yang sudah di medan. Checkbox "Musuh Membeku". |
| f. Lewati Gelombang | **BARU — terbit** | `ModActions.skipWave()`: (1) buang antrean `WaveCreator.getWave()` (belum pernah masuk medan → tanpa hadiah, setara resetWave bawaan); (2) `setHelthOfCharacter(0)` ke semua karakter aktif → frame berikutnya removeNon_AlivedCharacters memprosesnya lewat jalur kematian RESMI (skor+uang bunuh cabang !isTargetFound; nyawa tidak berkurang) → isWaveComplete → state 22 → levelIncremental / onSingleLevelComplete diputuskan mesin game. Tombol "Lewati Gelombang Ini" + Toast. False bila tak ada gelombang berjalan. |

Fitur v6 semua tetap: uang dipatok per tick (pinMoneyTick), jet &
ranjau unlimited (V6-S1/S2), layar menyala hanya di battle (V6-K1),
ensureNewTowers (V6-T4).

## 3. PERUBAHAN FILE

- `modmenu/apply_patches.py` — docstring v7; P5 persen; patch baru
  V7-T1, V7-T2, V7-T3, V7-T4, V7-F1, V7-F2.
- `modmenu/mod-src/.../ModConfig.java` — freezeEnemies + "frz";
  speedMul persen + validasi migrasi.
- `modmenu/mod-src/.../ModActions.java` — skipWave() + import.
- `modmenu/mod-src/.../ModMenu.java` — SPD_STEPS persen + speedLabel;
  checkbox Musuh Membeku; tombol Lewati Gelombang Ini; kredit v7.
- `modmenu/mod-src/stubs/...` — TowerEngine.getWaveCharacterVector(),
  WaveCreator.getWave() (stub kompilasi saja).
- `modmenu/build-modmenu.sh` — nama output v7.
- `.github/workflows/build-modmenu.yml` — artefak & body rilis v7.
- Laporan ini: `rea-bunker/BUILD-MODMENU-v7.md`; verifikasi:
  `rea-bunker/work-v7/verify_v7.py` (92 cek).

## 4. VERIFIKASI

- Build lokal: `bash modmenu/build-modmenu.sh` — semua patch lolos
  asersi; APK 12.468.458 byte (kebetulan sama dengan v6: perubahan
  dex kecil terserap padding zip).
- Sertifikat APK v7 lokal == v6: SHA-256
  `f7a4306a4bd0d1e5112f7c195eb3ff3c79a4a8db4e48552623f0d5ce01c257f3`
  → timpa pasang aman.
- verify_v7.py atas decompile APK lokal: **92/92 lulus** (semua cek
  warisan v6 dibawa — payload data level dibandingkan terhadap APK
  v6 byte-for-byte — plus 18 cek khusus v7).
- CI: run pertama tag (39792830885) GAGAL di langkah "Install build
  tools" — `sdkmanager: command not found` (image runner tanpa SDK
  di PATH; bukan kesalahan kode). Workflow diperbaiki: bootstrap
  cmdline-tools resmi bila sdkmanager absen (commit remote
  64343f17; tag digeser ke commit itu). Run tag ulang 39793691263
  **hijau**; Android CI 39792797763 & 39793656443 **hijau**.
- Release: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v7
  — aset `DefendTheBunker-ModMenu-v7.apk` 12.468.458 byte, diunduh
  balik via API dan diverifikasi ulang: sertifikat SHA-256 sama
  (f7a4306a…257f3) + verify_v7 atas decompile APK CI = **92/92 lulus**.
  Salinan: `~/workspace/your_files/DefendTheBunker-ModMenu-v7.apk`.
- Commit sumber v7 (remote): `2048730a` (isi mod) + `64343f17` (fix CI).

## 5. BATAS JUJUR

- Belum diuji di perangkat — klaim runtime (pilih/tanam/tembak
  Railgun & Tesla, beku, skip) tetap langkah uji user; bukti di sini
  adalah jalur kode + verifikasi terprogram atas APK final.
- Skip gelombang: musuh yang persis mencapai target pada frame yang
  sama tetap memotong nyawa (aturan game; God Mode menutupnya).
- Railgun darat-saja & Tesla udara-saja = warisan kelas induk
  (lihat §1), bukan regresi v7.
