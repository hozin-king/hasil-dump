# Build Mod Menu Gabung v1 — Defend The Bunker

Tanggal: 22 Oktober 2026 (WIB)
Jenis: mod **digabung ke APK game** (mod menu di dalam game; bukan injector, tanpa root)
APK hasil: `DefendTheBunker-ModMenu-v1.apk`
Basis: APK asli v4.9 (versionCode 41), SHA-256 `d714be183bc1e5c0a4a876a22cddb7f1cb6abf7cbbf650160f32f044a0979e57` (terverifikasi sebelum mulai)

## Arsitektur

- Menu ditulis sebagai Java kecil (`com.hozin.modmenu`: `ModConfig`, `ModMenu`, `ModActions`) → javac (stub kelas game hanya untuk kompilasi) → d8 → smali (lewat APK dummy aapt2+apktool) → disisipkan ke dex1 proyek apktool.
- Kode game membaca konfigurasi dari field statik `ModConfig` secara langsung — setiap toggle menu terhubung ke patch-nya, tidak ada saklar mati.
- Pengaturan toggle disimpan di SharedPreferences `hozin_modmenu` (dimuat saat `ModMenu.init`).
- Tombol melayang "MOD" (pojok kiri atas) + panel `AlertDialog`, mengikuti pola build gabung lama yang sehat (hook di `GameActivity.onCreate` via `runOnUiThread`).

## Titik patch per fitur (semua diverifikasi ulang di smali decompile sendiri)

| # | Fitur | Berkas / metode | Patch |
|---|---|---|---|
| P1 | Uang tak terbatas | `TowerEngine.getMoney()I` | Bila `unlimitedCoins`: return `0xf423f` (999999) |
| P2 | Uang tak terbatas | `TowerEngine.setMoney(I)V` | Bila `unlimitedCoins`: argumen dipaksa 999999 sebelum `iput money` |
| P3 | God mode bunker | `TowerEngine.removeNon_AlivedCharacters()` — satu-satunya situs `TOWER_HELTH--` (sget/add-int/lit8 -0x1/sput) | Bila `godMode`: lewati pengurangan; sisa blok (musuh mati, `dangerHoldTime`, `GameOverChack`) tetap jalan |
| P4 | Pengali damage 1/2/5/10× | `Character.reduceHelth(I)V` (corong tunggal semua damage senjata: Gun/Laser/Bomb/FireBlast) | Kepala metode: bila argumen != -1, kalikan dengan `damageMul`. Sentinel -1 (ranjau & rudal, bunuh instan) TIDAK dikalikan |
| P5 | Pengali kecepatan 1/2/3× | `GameThread.run()` | Setelah `sget WAIT_TIME`: `div-int` dengan `speedMul` (register lokal baru v6, `.locals` 6→7). `speedMul` ∈ {1,2,3}, tidak pernah 0 |
| P6 | Pemasangan menu | `GameActivity.onCreate(Bundle)` | `invoke-static ModMenu.init(Activity)` tepat setelah `invoke-super AppOnAdActivity.onCreate` |
| A1 | Unlock semua level + senjata | Aksi menu (`ModActions.unlockAll`) | `ChallengesMenu.MAX_UNLOCKED_LEVELS = 30`; `WeaponPopup.lastAvailableWeapon = TOTAL_WEAPON_COUNT-1 = 8`; disimpan via `GlobalStorage.addValue("MAX_UNLOCKED_LEVELS"/"lastAvailableWeapon")` — API & kunci yang sama dengan `TowerDefenderMidlet` |
| A2 | Editor skor & medali 1–30 | Aksi menu (`ModActions.setScoreMedal`) | Tulis `TowerCanvas.Score[i]` + `ChallengesMenu.LEVEL_MEDELS[i]` (0=emas, 1=perak, 2=perunggu, 3=tanpa), simpan via `addValue("LEVEL_SCORE"/"LEVEL_MEDELS")` |

Alur uang terverifikasi menyeluruh: semua baca/tulis uang di game lewat `getMoney()/setMoney()` (cek keterjangkauan `WeaponPopup`/`PopupObjects`, potongan beli/upgrade, refund jual, HUD) — P1+P2 menutup semuanya.

## Anti-crash

- **Struktur data level TIDAK disentuh sama sekali** — tidak ada patch ke `WaveCreator`, daftar level, atau `GallaryScreen` (itu penyebab crash build 15 Okt 2026), dan tidak ada level custom di build ini.
- Setiap aksi menu dibungkus try/catch(Throwable) — kegagalan satu fitur tidak menjatuhkan game; patch game bersifat kondisional per toggle dan terisolasi per metode.
- Gerbang versi: patch hanya berlaku untuk versionCode 41 / v4.9 ini (pola smali persis diasersikan saat build; pola tidak cocok = build gagal keras, bukan patch paksa).

## Hasil verifikasi lokal

- `apksigner verify`: **Verifies** (v2 + v3, 1 signer, keystore mod alias `modkey`)
- `zipalign -c 4`: **OK**
- Badging: package `com.appon.defendthebunker`, versionCode **41**, versionName **4.9**
- Decompile ulang APK final → penanda patch ditemukan semua: `0xf423f` 2× di TowerEngine, `godMode` 1×, `damageMul` 1×, `speedMul` 1×, `ModMenu->init` 1×; 13 berkas smali `com/hozin/modmenu/` hadir.
- **Diff menyeluruh** decompile APK final vs APK asli (dinormalisasi dari perbedaan kosmetik nilai-bawaan field yang dibuang assembler saat round-trip): satu-satunya perbedaan substantif di seluruh pohon smali kedua dex adalah 4 berkas patch di atas + paket baru `com/hozin`. Semua berkas lain identik.
- Reproduksibilitas: `build-modmenu.sh` (skrip yang dipakai CI) dijalankan lokal menghasilkan `classes.dex` + `classes2.dex` **identik byte-per-byte** dengan build manual.
- Ukuran APK lokal: 12.402.922 byte.

## Build resmi — GitHub Actions (yang berlaku)

Sesuai arahan user, APK resmi di-build oleh CI, bukan build lokal VM:

- Proyek CI ditambahkan ke repo privat `hozin-king/hozin-bunker-mod` tanpa menyentuh kode/workflow/release injector yang sudah ada: folder `modmenu/` (apply_patches.py, mod-src, build-modmenu.sh, mod.keystore, original/DefendTheBunker_4.9.apk, README) + workflow baru `.github/workflows/build-modmenu.yml` (trigger: workflow_dispatch, push path `modmenu/**`, tag `modmenu-v*`).
- Commit remote: `b8f5a78e4433baaea14b8d2c63e06fa5eff5114b` (push dari root clone via gh_push.py; HEAD terverifikasi via API).
- Run CI: **39693716122** (workflow_dispatch di main) — **success**; **39693888320** (push tag `modmenu-v1`) — **success**.
- Release resmi: https://github.com/hozin-king/hozin-bunker-mod/releases/tag/modmenu-v1 — aset `DefendTheBunker-ModMenu-v1.apk` 12.402.922 byte dari run tag.
- APK hasil CI (artifact `defendthebunker-modmenu-apk` id 12389587771) diunduh dan kini menjadi berkas di `~/workspace/your_files/DefendTheBunker-ModMenu-v1.apk` (menimpa build lokal).
- Verifikasi APK CI: apksigner **Verifies** (v2+v3), zipalign **OK**, dan `classes.dex` + `classes2.dex` **identik byte-per-byte** dengan build lokal yang lolos diff menyeluruh di atas (classes.dex `e1d2b815…`, classes2.dex `467693c9…`) — seluruh patch terbukti ada di hasil CI.

## Fitur yang gugur

Tidak ada. Keenam fitur terhubung penuh ke titik kait terverifikasi.

## Langkah instal (untuk user)

1. (Opsional, HP root) Cadangkan simpanan: salin folder `/data/data/com.appon.defendthebunker/` (database `gamedata` + SharedPreferences `GlobalStorage`) ke tempat aman.
2. **Uninstall game asli** — tanda tangan APK mod berbeda, tidak bisa menimpa.
3. Pasang `DefendTheBunker-ModMenu-v1.apk`, buka game, tombol **MOD** muncul di pojok kiri atas.
4. Uji berurutan: uang (beli senjata mahal) → god mode (biarkan musuh mencapai bunker) → damage → kecepatan → unlock → editor skor/medali (cek setelah restart game).
5. Belum diuji runtime di HP — uji di perangkat tetap di tangan user.
