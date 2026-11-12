# Defend The Bunker — Mod Menu Gabung v6 (di atas v5)

Basis: v5 (commit remote `62179613`). Commit v6: `616e8bc30a73cbc5273dd36491893448aa9f34bf`
(push Git Data API dari repo root sesudah `git add -A`; gh_push.py tidak ada di
VM — pola pengganti yang sama seperti insiden 19 Okt, surrogate `custom.github`).
CI hijau semua: Android CI `39765384914` (push), Build Mod Menu `39765450287`
(workflow_dispatch — push hanya memicu Android CI, pola sama seperti v5),
Build Mod Menu `39765961267` (tag `modmenu-v6`).
Release: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v6
APK: `DefendTheBunker-ModMenu-v6.apk`, 12.468.458 byte, sertifikat
`f7a4306a4bd0d1e5112f7c195eb3ff3c79a4a8db4e48552623f0d5ce01c257f3` — sama
dengan v1–v5, bisa timpa pasang. SHA-256 APK CI:
`5ed24a222b0159494ea2c8483660c841544eb7f28f98cc6a3641089f83d9e5e3`.
Verifikasi: `~/workspace/rea-bunker/work-v6/verify_v6.py` — **74 cek, 74 lulus**
atas binary CI (dan hasil sama atas build lokal). Semua isi v5 dipertahankan;
data level dibandingkan byte-per-entri ke APK v5: 100 level × 6 array +
payload gelombang 8-kolom **seluruhnya identik**.

Pemicu: uji HP user atas v5 (22 Okt 17:26) — uang "99.9M" & skor "614k" tampil
benar dan tombol MOD tampil, tapi (1) uang terasa tetap berkurang, (2) tower
baru tidak muncul di level awal, (3) senjata spesial masih terbatas, (4)
permintaan layar menyala hanya selama bermain.

## 1. Uang dipatok (tidak berkurang sama sekali)

**Akar (dari kode, decompile v5 ter-patch):** semua transaksi uang terbukti
melewati pasangan `TowerEngine.getMoney()/setMoney(I)V`:

- beli tower — `WeaponPopup`: `setMoney(getMoney() − weaponCost)`;
- upgrade — `WeaponUpgradePopup` (2 titik setMoney dari getMoney);
- jual/refund — `Background`: `setMoney(getMoney() + …)`;
- upah bunuh — `TowerEngine`: `setMoney(getMoney() + getMoneyCost())`.

Patch lama P1/P2 (sejak v1) memang mematok nilai yang lewat pasangan itu ke
`0x5f5e0ff` (99.999.999) selama `ModConfig.unlimitedCoins` aktif. Yang TIDAK
tertahan adalah **field mentah** `TowerEngine.money:I`, yang ditulis langsung
tanpa lewat setter hanya di jalur awal level (`TowerEngine.<init>`,
`loadLevel` ±baris 5413, `resetEngine` ±baris 6248, dan
`TowerEngine$LoadingEngineStateClass` via synthetic `access$502`) dan dibaca
mentah oleh jalur kosmetik (`calculate(Z)V` total menang, `setLostText`).
Jadi nilai yang "hidup" di field bisa berada di bawah pagu di antara
transaksi — itulah yang terasa sebagai "uang berkurang".

**Fix:** penahan berkala di loop permainan. `GameThread.run()` adalah loop
render/update tunggal game (anchor `WAIT_TIME` + `Thread.sleep` berada DI
DALAM loop, `goto` kembali ke kepala loop — terbukti dari smali). Patch P5
diperluas: sesudah blok pengali kecepatan disisipkan
`invoke-static {}, Lcom/hozin/modmenu/ModState;->pinMoneyTick()V`.
`ModState.pinMoneyTick()` (Java): bila toggle aktif →
`TowerEngine.getInstance().setMoney(99999999)`, dibungkus try/catch. Setiap
iterasi loop field dipatok lagi lewat setter (yang sendiri ter-patch
menjaga pagu), jadi di jalur baca/tulis mana pun uang kembali ke
99.999.999 dalam maksimal satu frame. Format ringkas k/M v5 tidak berubah.

**Bukti cek:** `pinMoneyTick` tepat 1× di `GameThread.run`, posisinya sesudah
blok speedMul dan sebelum `Thread.sleep`; badan `pinMoneyTick` membaca
`unlimitedCoins` dan memanggil `setMoney` dengan konstanta `0x5f5e0ff`;
konstanta pagu di `TowerEngine` tetap tepat 2×.

## 2. Senjata spesial (jet & ranjau) tidak pernah habis

**Akar:** tombol spesial di bar bawah adalah entri popup id 97 (jet/fighter,
biaya 0) & 98 (ranjau) di `WeaponPopup.fillWeaponPopup` dan
`Background.createActivePopup`. Ketersediaannya digerbang
`PopupObjects.isWeaponAvailable()`: id 97 butuh
`WaveCreator.getMAX_FIGHTER_AVAILABLE() > 0`, id 98 butuh
`getMAX_MINES_AVAILABLE() > 0`; label "5X"/"6X" digambar dari getter yang
sama di `Background.paintActives`. Pencarian menyeluruh atas semua `iput`
ke kedua field di seluruh smali: hanya `<init>` (0), kedua setter (dipanggil
`TowerEngine.loadLevel` dari array per-level `FIGHTER/MINES_AVAILABILITY`),
dan **satu-satunya pengurangan**: `WaveCreator.usingFighter()Z` &
`usingMines()Z` (pola identik: get → bila >0 kurangi 1 → iput → return true).

**Fix:** patch V6-S1/S2 `replace_method` kedua method itu menjadi: baca
getter; bila >0 return true **tanpa mengurangi**; bila 0 return false.
Stok awal per level tetap dipasang `loadLevel` (tidak diubah), gerbang
ketersediaan & tampilan hitungan asli tidak berubah — pemakaian tidak
pernah ditolak selama level menyediakan stok awal > 0 (semua level bawaan
menyediakan jet & ranjau; terverifikasi dari array per-level).

**Bukti cek:** badan final kedua method tanpa `sub-int` dan tanpa `iput`,
tetap memuat getter + `if-lez`; `loadLevel` tetap memanggil kedua setter
tepat 1×.

## 3. Layar menyala hanya selama di dalam permainan

**Peta state (terbukti dari kode):** `TowerCanvas.canvasGameState` dibaca
packed-switch di `updatGamePaint(I)V` dan `updateGame()V`: 0=logo,
2=loading menu, 3=menu utama (`MenuScreen`), 4=kredit, **5=pemilihan level
(`ChallengesMenu`)**, **6=loading masuk permainan** (transisi ke 8 via
`getLoadingPercentage`), **8=battle aktif** (`engineUpdate`; paint hanya
`enginePaint`), 9=transisi "Menu Loading" → state 2, **11=menu jeda
in-game** (`enginePaint` + `InGameMenu`). State sesi bermain = {6, 8, 11}.

**Fix:** satu-satunya titik yang dilewati SEMUA pergantian layar adalah
`TowerCanvas.setCanvasGameState(I)V`. Patch V6-K1 menyisipkan tepat sesudah
blok R5 v3 (register `p1` belum disentuh kode asli di titik itu):
`invoke-static {p1}, Lcom/hozin/modmenu/ModMenu;->onCanvasState(I)V`.
`ModMenu.onCanvasState(int)` (Java): state ∈ {6,8,11} →
`Window.addFlags(FLAG_KEEP_SCREEN_ON)`; state lain → `clearFlags(...)`;
dieksekusi di UI thread lewat `runOnUiThread`, di-dedupe per state, memakai
Activity statik yang sudah dirawat `init/ensureInstalled`. Keluar ke menu
utama/pemilihan level (state 3/5) flag dilepas → timeout layar normal lagi.

**Bukti cek:** kait tepat 1× di `setCanvasGameState`, posisinya sesudah
panggilan R5 `onLevelStartRequested` dan sebelum logika asli
(`const/16 v0, 0x8`); badan `onCanvasState` membandingkan konstanta
0x6/0x8/0xb; Runnable UI-nya memuat `Window.addFlags` + `clearFlags`
dengan konstanta `0x80` (FLAG_KEEP_SCREEN_ON).

## 4. Tower baru (Railgun & Tesla Arc) muncul di semua level

**Akar:** `WeaponPopup.fillWeaponPopup(I)V` mengisi vektor popup lewat loop
`v1 = 0..p1−1`, dengan `p1` = `weaponsAvailabeForLevels[level]` (data asli:
level 1 = 2, level 2–5 = 3, naik bertahap, 9 hanya mulai ±level 14 bawaan
dan level mod 31–100). Cabang v5 untuk Railgun/Tesla adalah `v1==7`/`v1==8`
— hanya tercapai bila p1 == 9. Sesudah loop, di label keluar `:cond_6`,
`popupWidth` dihitung dari `poupVector.size()`. Field `poupVector`,
`gTantraPopup`, `activeWeaponFrameID`, `inActiveWeaponFrameID` bersifat
private; `getPoupVector()` dan konstruktor `PopupObjects(GTantra, int,
int, int, int)` + `getWeaponID()` bersifat public (semua terverifikasi
dari smali). Pembuatan tower untuk id 99/100 di
`Background.createWeaponObject` sudah berlaku untuk semua level sejak v5;
`isWeaponAvailable` untuk 99/100 lewat jalur uang (getMoney ≥ biaya).

**Fix:** patch V6-T4 menyisipkan **sesudah label `:cond_6`, sebelum**
komputasi `popupWidth` (menyisip sebelum label = kode mati karena loop
keluar lewat `goto` ke label):
`invoke-static {p0}, Lcom/hozin/modmenu/ModActions;->ensureNewTowers(WeaponPopup)V`.
`ModActions.ensureNewTowers` (Java): scan `getPoupVector()` berdasarkan
`getWeaponID()` (anti-duplikat), baca 3 field private via refleksi, lalu
append entri yang belum ada dengan konstruksi persis cabang bawaan —
`new PopupObjects(g, aktif[8], nonaktif[8], 250, 99)` dan
`(g, aktif[9], nonaktif[9], 200, 100)`. Karena hook berjalan sebelum
`popupWidth` dihitung, entri tambahan ikut terhitung layout-nya. Data
level dan daftar senjata bawaan tidak disentuh (availabilitas level 1
tetap 2 — diverifikasi).

**Bukti cek:** kait tepat 1× di `fillWeaponPopup` dan posisinya sebelum
`iput popupWidth`; badan `ensureNewTowers` memuat `getPoupVector`,
`getWeaponID`, konstruktor `PopupObjects.<init>`, konstanta 0xfa/0xc8/
0x63/0x64, dan pembacaan refleksi `gTantraPopup`/`activeWeaponFrameID`.

## Perubahan file

- `modmenu/apply_patches.py` — docstring v6; P5 diperluas (pinMoneyTick);
  seksi v6 baru: V6-S1/S2 (replace usingFighter/usingMines), V6-K1
  (onCanvasState), V6-T4 (ensureNewTowers).
- `modmenu/mod-src/com/hozin/modmenu/ModState.java` — `pinMoneyTick()` +
  konstanta `MONEY_CAP`.
- `modmenu/mod-src/com/hozin/modmenu/ModMenu.java` — `onCanvasState(int)`
  (FLAG_KEEP_SCREEN_ON untuk state 6/8/11) + label kredit "Mod Menu v6".
- `modmenu/mod-src/com/hozin/modmenu/ModActions.java` — `ensureNewTowers`.
- `modmenu/mod-src/stubs/.../WeaponPopup.java` (+ `getPoupVector`) &
  stub baru `PopupObjects.java` — khusus kompilasi, tidak ikut di-dex.
- `modmenu/build-modmenu.sh` — nama output v6.
- `.github/workflows/build-modmenu.yml` — path artefak & isi rilis v6.

## Batas jujur

- **Belum diuji runtime di HP.** Yang terverifikasi: patch terpasang persis
  di binary final (74 cek atas decompile APK CI), CI hijau, sertifikat
  sama. Perilaku runtime yang masih perlu vonis user: (a) uang benar-benar
  tidak berkurang saat beli/upgrade; (b) jet/ranjau bisa dipakai
  berkali-kali; (c) layar tetap menyala saat battle dan kembali timeout
  di pemilihan level; (d) Railgun/Tesla tampil di popup level 1.
- Populasi popup menaikkan lebar popup di level awal (2 senjata bawaan +
  2 baru = 4 entri) — `popupWidth` dihitung ulang dari ukuran vektor
  sesudah hook, jadi layout mengikuti; bila di HP tampilannya sempit,
  itu kosmetik, bukan fungsi.
- Penahan uang berjalan per iterasi loop `GameThread.run()`; bila game
  dijeda total (utas berhenti), field tidak berubah juga — tidak ada
  transaksi yang berjalan saat utas berhenti.
- Jalur popup aktif spesial memakai hitungan yang sama; tidak ada jalur
  pengurangan lain (dibuktikan pencarian `iput` menyeluruh).
