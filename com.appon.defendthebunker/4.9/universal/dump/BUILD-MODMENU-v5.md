# Defend The Bunker — Mod Menu Gabung v5 (catatan build)

Dibangun 22 Okt 2026 dari hasil uji HP user atas v4 (tombol MOD terlihat,
uang & skor jalan; keluhan: uang terasa terbatas + angka panjang, resume
rusak, Level Maker tidak bisa dimainkan, minta 100 level + navigasi
cepat, tower & musuh baru). Semua warisan v1–v4 utuh (jendela
WindowManager, iklan mati, skor ×100, snapshot, unlock, DYOM).

Verifikasi: `verify_v5.py` (work-v5) — **56 cek, 56 lulus** atas decompile
APK final lokal. Sertifikat sama dengan v1–v4
(SHA-256 `f7a4306a…c257f3`) → timpa pasang. **BELUM diuji runtime di HP.**

## 1. Uang & format angka
- Titik format terbukti: skor & uang HANYA digambar di
  `HudMenu.paintScore`/`paintcoins` (StringBuilder `"" + nilai` →
  GFont.drawPage). Keduanya kini melewatkan nilai ke
  `ModFormat.compact(int)`: <1000 polos; ≥1000 diskala k/M/B dengan
  maks ±3 digit signifikan, DIPOTONG bukan dibulatkan
  (999999→"999k", 5170600→"5.17M", 44209999→"44.2M").
- Pagu uang tak terbatas 999999 → **99.999.999** (0x5f5e0ff) di getMoney
  & setMoney. Keamanan: skor dasar maks per level sesudah konten baru
  = 563.225 (L86) → ×100 + uang maks = 156.322.499 ≪ 2³¹−1. Tidak
  overflow.

## 2. Konten baru (gambar digambar BARU, bukan tint)
**Riwayat aset:** generasi pertama (lukis semi-realistis) DITOLAK user
22 Okt ("burik banget" — detail render jadi lumpur piksel di ukuran
sprite) dan TIDAK dipakai di APK final. **Digenerate ulang** dengan
pendekatan berbeda: desain flat ala sprite J2ME sejak awal (siluet
kuat, detail minimal, palet terbatas), lalu pipa proses
(`process_sprites2.py`) menambah pengaman anti-burik: sesudah
downscale, warna dikuantisasi ke ≤14 warna TANPA dither (bidang rata,
tepi tegas). Keterbacaan diuji visual pada ukuran sprite asli sebelum
dipakai (lembar pratinjau `work-v5/preview_v5_assets.png`); warna
perisai pose depan-B disamakan ke abu-abu pose-A agar siklus tidak
berkedip warna. Hasil akhir: 18 PNG di `modmenu/sprites/`, ditanam ke
file .GT oleh `modmenu/gt_assets.py` (parser GTantra terverifikasi
round-trip; entri lama byte-identik — dibuktikan verify_v5):
- weapons.GT: +modul 91 (Railgun 58×52), 92 (Tesla 56×62); +frame
  113–116 (dasar + recoil); +anim 29–32.
- soldier.GT: +modul 53–64 & frame 53–64 (Pelari depan/samping 38×60/
  46×60, Perisai 44×62/40×62 — pose A langkah lebar & pose B kaki
  rapat, +varian balik untuk arah kiri); +anim 9–16.
- weapons_selection.GT: +modul ikon 41–44 (ikon diturunkan dari sprite
  tower final agar gaya konsisten); +frame 48–53.

**ANIMASI (bukti dari dump asli):** siklus jalan tentara bawaan =
**8 entri animasi** (soldier.GT anim 0–5: 4 pose gambar × 2 varian,
timer 0); arah belakang bawaan memakai frame depan + flag balik;
animasi senjata bawaan umumnya **2 frame, timer 1**. Musuh baru
memakai mekanisme GAnim yang sama dengan panjang siklus yang sama:
8 entri = 2 pose kaki gambar nyata (A/B) bergantian + bob sumbu-y
pada entri pose B + fase balik (flag entri) untuk tampak depan;
belakang = flag balik penuh seperti bawaan. Perbedaan jujur: bawaan
menggambar 8 pose unik; di sini 2 pose unik × fase bob/balik (8
entri, ritme & panjang siklus identik). Tower baru: anim 2 frame —
diam = bob halus 1px, aktif = frame dasar ↔ frame recoil (modul
bergeser +2px). Semua ini diverifikasi terprogram (cek ANIM di
verify_v5).

Tower baru (kelas Java baru `modmenu/mod-src/game/`, subclass jalur
asli, dibuat lewat cabang baru `Background.createWeaponObject` id
99/100 + cabang `WeaponPopup.fillWeaponPopup` indeks 8/9; array popup
diperpanjang 8→10 di akhir `<init>` WeaponPopup):
- **Railgun** (extends LaserWeapon): damage 800.000 (±2,3× Laser —
  tertinggi, satu target tanpa area), jangkauan 260 (terjauh),
  harga 250 (termahal), anim 29/30.
- **Tesla Arc** (extends MissileLaunchWeapon): damage 520.000
  (±1,5× Missile), jangkauan 250, harga 200, anim 31/32; interval
  tembak memakai konstanta bersama kelas rudal.
- Muncul hanya di level dengan availableWeapons=9 (level mod 31–100) —
  konsisten progresi late-game.

Musuh baru (subclass jalur darat; spawn oleh method baru
`WaveCreator.spawnModWave` dari kolom gelombang 6/7 SESUDAH 6 tipe
asli, dijaga panjang array agar level bawaan 6-kolom aman; loop
bantuan loadWave diklem ke 6; skor computeTotalScore: indeks 6→75,
7→300):
- **Pelari** (extends SoldierCharacter): HP 35 (paling rapuh), speed 8
  (tercepat di game, di atas Bike 7), skor 75, uang 2.
- **Pembawa Perisai** (extends BomberManCharacter): HP 1.500 (antara
  Vehical 1.000 dan Tank 5.000; darat), speed 3, skor 300, uang 4.
- Batas jujur: animasi mati musuh baru mewarisi animasi mati kelas
  induknya (field animasi mati privat di Character); musuh baru muncul
  di ekor gelombang; level buatan Level Maker tidak memakai musuh baru
  (JSON tetap 6 angka, kolom 6/7 diisi 0).

## 3. Fix resume "Lanjutkan"
Akar masalah dari kode (dua-duanya terbukti):
1. Snapshot v3/v4 TIDAK PERNAH menyimpan tower terpasang — hanya
   level/gelombang/uang/nyawa/skor.
2. (Sama dengan bug Level Maker) data yang dipasang ke WaveCreator
   hilang karena `loadEngine()` membuat WaveCreator baru.
- Snapshot v5 memuat `towers`: `id,x,y,upgrade;…` dari
  `getWeaponVector()` — x/y dibaca dari FIELD mentah `machineX/machineY`
  via refleksi (getter publik mengurangi offset kamera), id mengikuti
  dispatch createWeaponObject (91–98 + 99/100; Rail/Tesla dicek
  SEBELUM kelas induknya). Fighter tidak disimpan (bukan tower
  terpasang).
- Pemulihan di kait baru R7 `ModState.onLevelIncremental()` di kepala
  `WaveCreator.levelIncremental()` — titik pertama sesudah loadLevel
  di utas pemuat; bendera sekali pakai. Tower dibangun ulang dengan
  konstruktor persis createWeaponObject (termasuk
  `MinesWeapon.createMine()`), field mentah + upgrade +
  isMachinePanted dipasang, lalu ditambahkan ke vektor senjata.
- Catatan jujur: teori "snapshot tertimpa sesi baru" sebagai penyebab
  "balik ke stage 1" tidak terbukti penuh dari kode statis; yang
  terbukti adalah dua akar di atas. Uji runtime yang menentukan.

## 4. Fix Level Maker
Akar terbukti: `TowerEngine.loadEngine()` membuat WaveCreator BARU
setiap mulai level; `CustomLevels.install()` v3/v4 menulis ke instans
lama yang terbuang → slot terbaca placeholder kosong.
Fix: `CustomLevels.arm()` menyimpan id level terpilih secara persisten
(prefs `hozin_custom_levels`/`armed`); kait baru R6
`ModState.onLoadLevel()` di kepala `TowerEngine.loadLevel(int)`
memasang data ter-arm ke WaveCreator mesin SAAT INI tepat sebelum
loadLevel membacanya. Kegagalan install oportunistik tidak lagi
membatalkan permainan.

## 5. Level 100 + slider
- `gen_levels.generate_levels_56_100()`: 45 level (L56 FAJAR PELARI …
  L100 HARI TERAKHIR), gelombang 8 kolom; Pelari berbobot sejak L56,
  Perisai sejak L58; total musuh naik bervariasi 1.293 (L56) → 2.125
  (L100); asersi: tanda tangan unik 1–100, tipe baru ≥15 per level
  (pembeda struktural dari 1–55), peta tidak berurutan sama, kesulitan
  tidak turun. Isi 1–55 TIDAK berubah (dibuktikan: 55 entri pertama
  payload per-level & 6 kolom pertama gelombang 31–55 identik APK v4;
  hash tanda tangan 1–40 == data asli).
- Struktur: semua ukuran 56→101 (levelsArray, array per-level, Score,
  LEVEL_MEDELS), galeri 100 kotak (MAX_CHALLANGES 0x64, klem 0x63),
  removeSkip ≥99, slot Level Maker pindah ke indeks 100.
- Navigasi: di panel MOD ada slider (SeekBar 1–100) + label angka +
  tombol "Main Level Terpilih" → `ModActions.quickPlayLevel` (unlock
  otomatis + jalur start yang sama dengan galeri). Tanpa 100 tombol —
  ringan, tidak lag.

## Rilis
- Push dari repo ROOT sesudah `git add -A` (58 file; tepat 18 sprite
  baru terdaftar, tidak ada sisa aset generasi tertolak): commit lokal
  `f6a2e67`, commit remote **`62179613`** (terverifikasi API).
- CI: Android CI `39735728213` sukses; Build Mod Menu dispatch
  `39735998357` sukses (run push tidak terpicu oleh filter paths+tags —
  quirk lama); run tag `39736318018` sukses.
- Release: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v5
  — aset `DefendTheBunker-ModMenu-v5.apk` **12.468.458 byte** (build
  CI, apktool 2.10.0; build lokal 12.558.570 byte dengan apktool
  2.9.3). APK CI diverifikasi ulang dengan verify_v5: **56/56 lulus**,
  sertifikat `f7a4306a…` sama dengan v1–v4, dan disalin ke
  `~/workspace/your_files/DefendTheBunker-ModMenu-v5.apk`.
- Pratinjau aset baru untuk user: `work-v5/preview_v5_assets.png`
  (ukuran asli + zoom), `work-v5/preview_v5_walk_cycle.png` &
  `preview_v5_walk_shield.png` (strip 8 frame siklus jalan).
