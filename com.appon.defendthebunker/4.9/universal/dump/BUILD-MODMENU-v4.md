# Defend The Bunker — Mod Menu Gabung v4: catatan build

Repo: `hozin-king/hozin-bunker-mod` (privat), folder `modmenu/`.
Commit sumber (lokal): `97620ee`; commit remote hasil push: `c9a21ed6c268191db64f0b7b5e2b67ae7dbff61c` di `main` (terverifikasi via API; tree memuat `modmenu/gen_levels.py` + workflow v4).
CI: run dispatch `39728066781` (success), run tag `39728073213` (success), Android CI `39728032047` (success).
Rilis: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v4
APK: `DefendTheBunker-ModMenu-v4.apk`, 12.419.306 byte (aset release & artifact CI id `12403154479`; salinan di `~/workspace/your_files/`).
Dex CI == dex build lokal byte-per-byte (classes.dex `c86efab7bd…`, classes2.dex `467693c9fb…` — classes2 sama dengan v2/v3, memang tidak disentuh).
Sertifikat == v1/v2/v3 (`f7a4306a…`) → bisa dipasang menimpa modmenu-v1/v2/v3 tanpa uninstall & tanpa kehilangan simpanan.

Empat perubahan di atas v3 (isi v3 tidak berubah — lihat verifikasi):
floating window beneran, iklan dinonaktifkan, level bawaan 40 → 55
dari generator, dan Generator Level di dalam Level Maker.

---

## 1. Floating window beneran (fix bug utama v3)

**Akar masalah (terbukti):** `DrawView.<init>` di smali game memanggil
`setZOrderOnTop(true)` → permukaan SurfaceView game berada DI ATAS
semua view jendela utama. Tombol MOD v1–v3 yang ditempel ke DecorView
berada di jendela utama, jadi tertutup permukaan game dan tidak pernah
terlihat di HP (2 screenshot user: layar judul & dalam permainan).
Toast dan AlertDialog tetap muncul karena keduanya jendela terpisah —
konsisten dengan semua gejala.

**Fix (murni kode mod, nol patch game):** `ModMenu.installNow()` kini:
1. Bila tombol panel sudah terpasang → selesai.
2. `tryInstallOverlay()`: ambil token dari
   `decorView.getWindowToken()` (null → gagal sopan), buat tombol MOD
   baru, tambahkan lewat WindowManager dengan
   `WindowManager.LayoutParams(WRAP_CONTENT, WRAP_CONTENT,
   TYPE_APPLICATION_PANEL, FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT)`,
   `lp.token = token`, gravity TOP|LEFT, x/y = 14. Jendela panel
   menempel token activity adalah jendela terpisah yang dirender di
   atas jendela utama — termasuk di atas SurfaceView z-order-on-top.
   **Bisa digeser:** OnTouchListener mencatat posisi awal + koordinat
   mentah saat ACTION_DOWN, memperbarui `lp.x/lp.y` +
   `updateViewLayout()` saat ACTION_MOVE, dan memperlakukan ACTION_UP
   sebagai ketukan (buka panel) hanya bila gerak total ≤ 12 px.
   Panelnya sendiri tetap AlertDialog v3 (jendela sendiri, terbukti
   bekerja).
3. Bila panel gagal (token belum ada di akhir onCreate dsb) →
   `installFallbackDecor()` = cara lama v2/v3 persis (tag
   `hozin_mod_button`, bringToFront). Retry terjadwal +600/+2000 ms
   dan kait onResume/onWindowFocusChanged (P6b/P6c, tidak berubah)
   memanggil `ensureInstalled` lagi; begitu token tersedia, tombol
   naik ke jendela panel dan tombol cadangan DecorView dicabut
   (`removeDecorFallback()`). Toast "MOD MENU AKTIF" + popup kredit
   kini dipicu dari `onButtonInstalled()` — sekali per proses, jalur
   mana pun yang berhasil lebih dulu.
4. `setZOrderOnTop` game TIDAK disentuh (risiko render).

Popup kredit diperbarui: judul "Defend The Bunker — Mod Menu v4",
isi "Mod by Hozin King" + baris "Menu Melayang • Tanpa Iklan •
55 Level + Generator • Pengali Skor ×100 • Lanjutkan Permainan •
Level Maker". Guard sekali per proses & isFinishing/isDestroyed utuh.

## 2. Iklan dinonaktifkan (patch ADS, di kelas SDK sendiri)

Situs panggil iklan dari kode game (terinventaris dari smali):
`AppOnAds.loadAd(I)V` dipanggil dari TowerCanvas 3×, TowerEngine 2×,
MenuScreen 1×; `openApponGiftBox()` dari MenuScreen 1×;
`RewardedVideoAd.showRewardedAd()` dari GameActivity 1×. Tidak ada
panggilan AdMob langsung dari paket game (semua lewat AppOn).

Patch ADS menonaktifkan **method penampilnya di kelas SDK**
(badan diganti `return-void`, header dipertahankan):
- `AppOnAds.loadAd(I)V` — jalur utama: mem-post runnable penampil
  interstitial/house-ad ke handler iklan.
- `AppOnAds.loadAd()V` — memuat InterstitialAd AdMob langsung
  (unit `ca-app-pub-1894651206126589/4943086955`).
- `AppOnAds.openApponGiftBox()V` — dialog gift-box promosi AppOn.
- `AppOnAds.showHouseAd()V` — penampil house-ad AppOn.
- `videoads/RewardedVideoAd.showRewardedAd()V` — penampil video
  berhadiah. **Konsekuensi jujur:** hadiah dari menonton video
  (rewarded) juga tidak akan diberikan lagi — jalurnya memang iklan.

Kelas TIDAK dihapus; lifecycle `AppOnAdActivity` (superclass
GameActivity) TIDAK disentuh sama sekali — diverifikasi: onCreate
masih memanggil invoke-super, dan `AppOnAds` tidak lagi mereferensikan
`InterstitialAd;->load`. Analytics tidak disentuh (bukan penampil).

## 3. Level bawaan 40 → 55 via generator (patch L1–L9 diperluas)

**Generator:** `modmenu/gen_levels.py` — prosedural DETERMINISTIK
(seed tetap per nomor level; output identik lokal & CI). 15 tema
berbeda karakter untuk L41–55: SERBUAN FAJAR (rush infanteri),
KABUT PELEDAK (bomber), JALUR NGEBUT (motor+kendaraan),
SAYAP HITAM (helikopter), DINDING PLAT (lapis baja), ATRISI PANJANG
(12 gelombang kecil, hati 8), PASANG GANDA (gelombang bergantian
darat/udara), BANJIR RINGAN (unit ringan massal), TAMENG BERJALAN
(tank tameng + heli), SETENGAH ABAD (seimbang besar), RITME PECAH
(ukuran gelombang sangat tidak rata), KEPUNG TOTAL, LANGIT TERBELAH
(udara + baja), GERBANG AKHIR, HARI PENENTUAN (finale 12 gelombang,
penutup dinding tank 28 + heli 38 — berbeda dari penutup L40).

Syarat yang diasertakan DI GENERATOR: peta tidak berurutan sama
(termasuk terhadap L40 peta 5), anggaran musuh rata-rata naik
bertahap antar level, format mesin (6 kolom, per tipe ≤ 99, total
per gelombang ≤ 185, 8–12 gelombang), dan keunikan tanda tangan
lengkap (peta+uang+nyawa+fighter+ranjau+semua gelombang) terhadap
seluruh level 1–55. Untuk level 1–40, generator membandingkan hash
tanda tangan `EXISTING_SIG_HASHES` yang dihitung dari payload smali
APK asli + desain 31–40 (bukan dari jadx — jadx terbukti menebak
konstanta simbolik pada `moneyForLevels`, smali adalah kebenaran).

**Perluasan struktur (semua dari 41 → 56 entri):** konstanta
L1/L2a/L2b/L4a/L5a 0x29 → 0x38; growth levelsArray kini menulis 25
level (indeks 30–54) + placeholder slot cadangan di indeks 55
(0x37); payload per-level L2c 55 entri; Score L4b 56 nol; LEVEL_MEDELS
L5b aput s/d 55; `MAX_CHALLANGES` 0x37 (galeri 55 kotak) + batas
L6b–L6e 0x37 + klem L6f 0x36; removeSkip L7 0x36. Pengaman
LeaderBoardKeys tetap: hanya 30 ID asli, tanpa ID palsu (loop
dibatasi panjang kunci, intent ≥ 30 dialihkan ke daftar semua
leaderboard — utuh dari v2). `getTotalLevels()` dinamis dari
`levelsArray.length` → otomatis 56.

**Slot cadangan PINDAH 40 → 55:** `CustomLevels.INDEX = 55`;
`ModActions.TOTAL_LEVELS = 55`, `ARRAY_LEVELS = 56`
(normalisasi simpanan lama memperpanjang ke 56). Data level buatan
tersimpan (SharedPreferences `hozin_custom_levels`, JSON by id)
tidak disentuh → level buatan user dari v3 tetap ada; snapshot
"Lanjutkan" v3 yang menunjuk slot 40 akan gugur sendiri secara aman
(`ModState` memvalidasi level ≤ INDEX & install ulang by id).

**Isi 40 level pertama TIDAK berubah** — diverifikasi: payload
per-level [30:40] dan 100 payload gelombang 31–40 identik dengan
APK v3. **Overflow skor dihitung ulang dengan 55 level:** skor dasar
maksimum kini 432.100 (level 53); ×100 + uang 999.999 = 44.209.999,
jauh di bawah int32.

## 4. Generator Level di dalam game (menu Level Maker)

Entri baru "⚙ Generator Level" di daftar "Level Buatan Saya"
(indeks kedua, sesudah "＋ Buat Level Baru"). Form Bahasa Indonesia:
- **Nama** — otomatis terisi "Generator <n>" (n = jumlah level
  buatan + 1), bisa diganti.
- **Peta** — kolom angka; kosong = Otomatis (acak 0–5), atau 0–5.
- **Jumlah Gelombang** — 1–12 (bawaan 8).
- **Kesulitan** — radio Mudah / Sedang / Sulit / Brutal (bawaan
  Sedang): mengatur bobot tipe musuh, anggaran per gelombang
  (34/52/78/105), uang awal (300/450/600/800 + acak ≤ 100),
  pesawat (1–4) dan ranjau (2–5).
- **Seed** — opsional; angka dipakai langsung sebagai seed, teks
  lain di-hash, kosong = acak dari waktu. Seed sama + parameter sama
  = komposisi sama.

`CustomLevels.generate(...)` memakai `java.util.Random` ber-seed,
eskalasi gelombang 0,75× → 1,25× anggaran, jitter antar tipe, klem
per tipe/total mengikuti batas mesin, dan hasil WAJIB lolos
`CustomLevels.validate()` yang sama dengan editor manual (gagal =
null, tidak ada level setengah jadi). Level tersimpan ke daftar
level buatan yang sama dan dimainkan lewat jalur slot indeks 55
yang sama persis. Form menyatakan dengan terang: **tempo spawn
memakai bawaan mesin** (tidak ada parameter per level).

## 5. Verifikasi (terprogram, dijalankan pada build lokal DAN APK CI)

**48 cek konten, semua lulus** di kedua APK (skrip:
`~/workspace/rea-bunker/work-v4/verify_v4.py`), mencakup: pengali
skor ×100 satu titik & urutannya; kait R1–R5 utuh; konstanta
struktur 0x38 & placeholder slot 55; payload per-level 55 entri
(30 asli + 25 desain/generator tepat); 251 payload gelombang
31–55 == desain+generator berurutan; Score 56 nol; LEVEL_MEDELS
aput s/d 55; MAX_CHALLANGES 0x37; kompatibilitas payload 31–40
dengan APK v3; **55 tanda tangan level unik** dihitung dari data
APK final sendiri + hash 40 pertama cocok dengan hash generator;
`CustomLevels.INDEX = 0x37` di smali; UI generator (entri, form,
seed, kesulitan, kejujuran tempo ×2); floating window
(WindowManager, konstanta TYPE_APPLICATION_PANEL 0x3e8, token dari
getWindowToken dipasang ke LayoutParams, addView + updateViewLayout
+ MotionEvent di kelas ModMenu beserta inner class-nya, fallback
DecorView tetap ada); popup v4; lima method iklan no-op persis +
tidak ada lagi `InterstitialAd;->load` di AppOnAds + lifecycle
AppOnAdActivity utuh + kelas AppOnAds tetap ada; perhitungan
overflow 55 level. `apksigner verify` OK; zipalign OK; sertifikat
== v1/v2/v3.

## 6. Yang belum pasti (jujur — perlu uji runtime di HP user)

- **Visibilitas tombol di HP tetap perlu uji user.** Secara
  arsitektur jendela panel menempel token activity berada di atas
  jendela utama (dan permukaan SurfaceView z-order-on-top di
  dalamnya), dan panel AlertDialog v3 — yang kelas jendelanya sama —
  memang bisa tampil; tetapi tidak ada uji runtime di sini.
  Kemungkinan sisa: token belum tersedia pada percobaan awal
  (ditutup retry + onResume/onWindowFocusChanged + fallback),
  atau ROM (HyperOS) menahan jendela panel tanpa izin overlay —
  fallback DecorView membuat perilaku tidak lebih buruk dari v3.
- Rewarded video nonaktif berarti hadiah video di dalam game tidak
  lagi bisa diperoleh (lihat §2) — disengaja sebagai bagian dari
  mematikan iklan, bukan bug.
- Interaksi generator dalam game (form → simpan → mainkan level
  hasil generate sampai tamat) belum diuji runtime; logika
  generate lolos validasi yang sama dengan editor manual v3 dan
  jalur mainnya identik, tetapi kombinasi UI-nya baru.
- Snapshot "Lanjutkan" dari v3 yang menunjuk level buatan (slot 40
  lama) tidak bermigrasi (lihat §3) — snapshot level bawaan tetap
  berlaku karena indeks levelnya tidak berubah.
