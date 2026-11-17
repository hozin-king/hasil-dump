# AUDIT INJECTOR — Sniper 3D v7.15.0 (com.fungames.sniper3d)

**Tanggal:** 17 Nov 2026 · **Dasar:** `REPORT.md` (dump Cpp2IL + ISIL, 179.074 method) + file referensi `~/workspace/user/files/ESP_3_thnu.h`.
**Riset saja — injector TIDAK dibangun di sini.**

---

## 0. Vonis singkat

| Klaim user | Hasil verifikasi |
|---|---|
| "Misi lawannya bot/AI" | ✅ **TERBUKTI** — NPC misi disimulasi penuh di client (`Person._currentHealth` double lokal, raycast lokal, damage lokal) |
| "Online cuma buat beli item" | ❌ **TIDAK TEPAT** — online juga: sync progres/wallet/energi, leaderboard, chat/clan, Arena real-time |
| "Arena lawannya bot, bukan pemain asli" | ❌ **TIDAK TERBUKTI** — Arena adalah PvP real-time (matchmaking + game server + relay tembakan lawan + **validasi tembakan server**). Bot hanya terbukti sebagai pengisi roster; client tidak bisa memastikan satu match isinya bot semua |

**Konsekuensi:** 6 fitur yang diminta user **BOLEH masuk daftar saran HANYA untuk mode misi, dengan gate mode misi + fail-closed**. Di Arena semuanya **DITOLAK** sebagai kelas. IAP/toko/currency **DITOLAK** seluruhnya.

---

## 1. Tabel klasifikasi — 6 fitur yang diminta user

### 1.1 Ringkasan per fitur × mode

| # | Fitur | Mode misi (solo vs AI) | Mode Arena/PvP | Sifat teknis |
|---|---|---|---|---|
| 1 | **Aimbot / aimlock** (kunci bidikan ke target) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** | Lokal di misi (Transform musuh + raycast client); di Arena tembakan divalidasi server |
| 2 | **Auto-aim saat zoom/scope** (otomatis bidik saat membuka scope) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** | Sama seperti #1; pemicu = status zoom (`Zoom.IsZoomingIn` / scope aktif) |
| 3 | **ESP** (kotak + bar HP + nama, metode Canvas-JNI `ESP_3_thnu.h`) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** | Rendering Canvas-JNI bisa dipakai; data posisi/nyawa lokal di misi |
| 4 | **No recoil** (di game ini = no-spread + no-sway) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** | Field lokal `WeaponData.Spread` / `_spreadAmount` / `Stability`; di Arena reload & tembakan disync ke server |
| 5 | **No reload** (tembak terus tanpa reload) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** | `ClipSize`/`ReloadTime` lokal; di Arena reload dikirim ke server (`SendReload`) |
| 6 | **Zoom jauh** (pembesaran scope melebihi batas normal) | ✅ **BOLEH** — gate misi | ❌ **DITOLAK** (tetap OFF di Arena) | Murni kamera/FOV lokal (`MaxZoom`, `Zoom.ScaleMax`) — **tidak ada validasi server**; tapi di Arena tetap dimatikan karena memberi keunggulan vs pemain asli |

### 1.2 Detail per fitur

#### 1 — Aimbot / aimlock

- **Cara kerja (misi):** enumerasi `Person` di scene → ambil posisi kepala (head bone / `AttachToHead`) → hitung arah bidik dari kamera → tulis arah tembak sebelum `Weapon.ShootTest`/raycast, atau putar kamera ke target. Target terdekat ke crosshair / dengan prioritas (headshot).
- **Dasar bukti:** `Person.transform`, `_currentHealth`/`_health` (double lokal), `_alive`/`_dead`; `Weapon.ShootTest` raycast lokal (`TestDistance = 6000f`); `Weapon.HitInfo.IsHeadShot()`; tidak ada pengiriman tembakan ke server selama misi.
- **Risiko (misi):** sedang. Gameplay lokal, tapi `SyncPlayerCampaign` melaporkan hasil misi ke server + `MetagameAnalytics.CheaterDetected` + penandaan cheater server (ban/suspend) ada. Pola mustahil (headshot 100%, misi selesai dalam detik) bisa ditandai — ambang tidak terlihat dari dump.
- **Arena: DITOLAK.** Tembakan lawan divalidasi server (`ArenaCharacterMessenger.OnShotMsgValidated`); `SendShot(target, headShot, hasHit, layerDamage, hitPosition, shotOrigin, shotDirection, ...)` dikirim ke server. Aimbot di sini = cheat PvP lawan pemain asli (atau lawan yang tidak bisa dipastikan bot).

#### 2 — Auto-aim saat zoom/scope

- **Cara kerja (misi):** sama seperti #1, tapi aktif hanya saat scope terbuka (`Zoom.IsZoomingIn` / `HasToggledZoom` / scope aktif). Saat zoom, snap bidikan ke kepala musuh terdekat dalam kerucut pandang; lepas saat scope ditutup.
- **Dasar bukti:** `Zoom` static class (`ScaleMax/Min/Step`, `IsZoomingIn/IsZoomingOut`); `WeaponData.MaxZoom`/`ZoomLevels`/`GetZoom(level)`; aim assist bawaan game (`Game.Scripts.AimHelper`) hanya dot UI — **bukan** auto-aim, jadi fitur ini murni tambahan injector.
- **Risiko (misi):** sama seperti #1.
- **Arena: DITOLAK.** Alasan sama seperti #1.

#### 3 — ESP (metode Canvas-JNI dari `ESP_3_thnu.h`)

- **Cara kerja (misi):** overlay `CanvasView` transparan di atas game (JNI) → tiap frame: enumerasi `Person` → `Camera.main.WorldToScreenPoint` (atau proyeksi manual dari matriks kamera) → gambar dengan metode file referensi: `DrawBox` (kotak musuh), `DrawHorizontalHealthBar` (`_currentHealth`/`_health` — hijau >60%, kuning 30–60%, merah <30%), `DrawText` (nama/jarak), `DrawLine` (garis ke musuh), `DrawCrosshair`.
- **Penilaian file referensi:** sisi **rendering BISA dipakai** (tidak bergantung engine). Yang **tidak ada** di file itu dan harus dibangun: enumerasi musuh, proyeksi 3D→layar, `CanvasView` Java (metode `DrawLine/DrawText/DrawFilledCircle` dengan signature persis di file), `StructsCommon.h` (`Color`, `Vector2`, `Rect`), filter mode misi. Detail lengkap: `REPORT.md` §8.
- **Risiko (misi):** rendah–sedang. ESP hanya membaca + menggambar (tidak mengubah gameplay); tapi tetap berjalan di proses game dan bisa terdeteksi Play Integrity / penandaan server bila dikombinasikan dengan pola main abnormal.
- **Arena: DITOLAK.** ESP vs pemain asli = cheat PvP (melihat posisi lawan). Tidak ada pengecualian "lawan bot" karena komposisi match tidak bisa dipastikan (§7 REPORT.md).

#### 4 — No recoil (no-spread + no-sway)

- **Koreksi istilah:** game ini **tidak punya field "recoil"** (0 hasil string `recoil` di dump). Yang ada: **spread/bloom** (`WeaponData.Spread`, `spreadSensitivity`, `spreadRecoverSpeed`, `Weapon._spreadAmount`, `_shootInaccuracy`, `IncreaseSpread()`/`RecoverSpread()`, `Stability`) + goyangan kamera/napas (mekanik *hold breath*).
- **Cara kerja (misi):** tahan `_spreadAmount` di 0 / set `Spread` efektif 0 / bekukan sway kamera & napas — bidikan tidak melebar saat menembak.
- **Dasar bukti:** semua field di atas lokal di `WeaponData`/`Weapon`.
- **Risiko (misi):** rendah–sedang (sama seperti #1).
- **Arena: DITOLAK.** Spread memengaruhi hasil tembakan yang divalidasi server; menghilangkan spread = keunggulan vs pemain asli + pola hit abnormal.

#### 5 — No reload

- **Cara kerja (misi):** lewati timer reload (`ReloadTime` → 0 / skip coroutine `WaitAndReload` / `WeaponReloadFeedback`) atau tahan peluru magazen (`ClipSize` efektif tak berkurang) — tembak terus tanpa jeda reload.
- **Dasar bukti:** `WeaponData.ClipSize`, `ReloadTime` — field lokal; reload adalah coroutine lokal di misi.
- **Risiko (misi):** rendah–sedang (sama seperti #1).
- **Arena: DITOLAK.** Reload disinkronkan ke server: `ArenaCharacterMessenger.SendReload(duration)` dan `HandleReloadMsg`/`OnReloadMessageReceived` di sisi lawan. Melewati reload di Arena = state tidak konsisten dengan server + keunggulan vs pemain asli.

#### 6 — Zoom jauh

- **Cara kerja (misi):** naikkan `WeaponData.MaxZoom` / `Zoom.ScaleMax` (dan/atau `ZoomLevels`) melewati batas normal senjata — scope bisa memperbesar lebih jauh.
- **Dasar bukti:** `MaxZoom`, `ZoomLevels`, `GetZoom(level)`, `Zoom.ScaleMax/Min/Step` — semuanya field kamera client-side. **Tidak ada validasi server atas FOV/zoom** (FOV hanya dipakai lokal untuk rendering & hit-marker: `CameraInformation.cameraFieldOfView`).
- **Risiko (misi):** rendah — murni visual lokal, tidak mengubah damage/hit.
- **Arena: DITOLAK (tetap OFF).** Alasan: zoom BUKAN divalidasi server, tapi memberi keunggulan penglihatan vs pemain asli. Sesuai aturan klasifikasi tugas ini, yang masuk daftar saran hanyalah yang "terbukti lokal DAN hanya berfungsi di mode solo/AI" — zoom di Arena dinonaktifkan oleh gate yang sama dengan fitur lain. Bila suatu hari terbukti satu mode Arena isinya bot semua (butuh probe runtime, REPORT.md §10), barulah ini bisa ditinjau ulang — bukan sekarang.

---

## 2. Gate mode misi (wajib)

Semua fitur di atas **hanya boleh aktif di mode misi**. Desain gate:

1. **Deteksi mode:** aktif bila `LevelController` (misi) berjalan DAN `ArenaIngameController` / `ArenaMatchFluxController` TIDAK berjalan. Dua controller ini adalah class yang berbeda di dump — sinyal mode yang paling andal.
2. **Fail-closed:** bila mode tidak bisa dipastikan (keduanya ada / keduanya tidak ada / transisi scene) → **semua fitur MATI**.
3. **Auto-off:** saat pindah misi → Arena (atau sebaliknya), fitur mati otomatis tanpa perlu toggle manual. Toggle di menu injector hanya berfungsi sebagai *master switch* di dalam mode misi.
4. **Satu gate terpusat** (bukan per-fitur) — satu fungsi `isMissionMode()` yang dipakai semua hook. Bila gate gagal, fitur tidak jalan (bukan jalan dengan asumsi).
5. **Tidak ada toggle "Arena"** — menu injector tidak boleh menyediakan cara mengaktifkan fitur ini di Arena.

---

## 3. Daftar DITOLAK (jangan dibangun)

| Fitur | Alasan |
|---|---|
| Aimbot / aimlock / auto-aim / ESP di **Arena/PvP** | Lawan bisa pemain asli (PvP real-time terbukti: matchmaking + game server + `match.shotMsg`/`match.characterUpdate` + validasi tembakan server). Bot hanya pengisi roster — tidak bisa dipastikan. |
| Aimbot / ESP / no-recoil / no-reload / zoom di Arena **dengan dalih "lawannya bot"** | Klaim "Arena cuma bot" **tidak terbukti** dari dump (§7 REPORT.md). Satu match berisi satu pemain asli saja sudah cukup menjadikannya cheat PvP. |
| **Koin / diamond / token / energi tak terbatas** | Server-synced (`WalletCheatsHandler`, `SyncPlayerCampaign`, `Game.Energy.*` + jam server). Bukan lokal. |
| **IAP gratis / unlock pembelian uang asli / bypass receipt** | Receipt divalidasi server (`RECEIPT_FAILED_TO_VALIDATE`, `RECEIPT_INVALID`); Google Play Billing. Pembelian uang asli tidak disentuh. |
| **Unlock senjata/gear/mods premium** | Kepemilikan & upgrade disync metagame server; statistik lokal ≠ kepemilikan. |
| **Hadiah misi / reward multiplier** | Hadiah diberikan server (`CollectRewards`, `SyncPlayerCampaign`). |
| **Damage multiplier / one-hit kill (di luar mekanisme misi lokal)** | Damage misi memang lokal, tapi mengubah `WeaponData.Damage`/`DamageMultiplier` secara global juga memengaruhi Arena (tembakan divalidasi server) — dan tidak diminta user. Tidak disarankan; bila kelak dipertimbangkan, wajib gate misi yang sama + risiko ban dicantumkan. |
| **Speed hack / teleport / noclip** | Tidak diminta user; tidak ada bukti kebutuhan; berisiko tinggi + tidak relevan dengan gameplay sniper. |
| **Bypass Play Integrity / bypass deteksi root** | Play Integrity adalah anti-tamper utama game; mem-bypass-nya = evasi anti-cheat — ditolak sebagai kelas. |
| **Modifikasi `SyncPlayerCampaign` / laporan progres palsu** | Laporan progres ke server; memalsukannya = manipulasi data server. |
| **Fitur apa pun yang menyentuh chat/clan/leaderboard orang lain** | Online, menyangkut pemain lain. |

---

## 4. Risiko (jujur — untuk user)

| Risiko | Penjelasan |
|---|---|
| **Ban/suspend oleh server** | Server bisa menandai pemain sebagai cheater (`CheaterDetected`, `PlayerIsTaggedAsCheater`, popup ban/suspend berjangka). Ini mekanisme nyata di dump, bukan teori. |
| **Play Integrity** | Token integrity diminta per fitur (remote config). Token gagal / device tidak lolos = fitur server bisa ditolak. Titik pemakaian pastinya butuh probe runtime. |
| **Deteksi pola statistik** | Hasil misi dilaporkan ke server (`SyncPlayerCampaign`). Headshot 100% terus-menerus / waktu misi mustahil cepat bisa ditandai — ambang tidak terlihat dari dump. Saran praktis: jangan pakai semua fitur sekaligus secara ekstrem (mis. aimbot headshot-lock 100% + no-reload + misi 5 detik). |
| **Arena tidak sengaja aktif** | Bila gate mode gagal dan fitur menyala di Arena, risikonya langsung naik (validasi tembakan server + laporan pemain lain). Karena itu gate fail-closed adalah syarat mutlak, bukan opsional. |
| **Update game** | Semua alamat/offset dari dump ini berlaku untuk **v7.15.0 (code 33186)**. Update game bisa menggeser semuanya — injector harus pattern-scan, bukan hardcode offset. |
| **Tidak ada deteksi root client-side yang ditemukan** | `strings` dex: 0 hit root/magisk. Artinya risiko utama bukan dari deteksi root lokal, melainkan dari server (§4 REPORT.md). Jangan disimpulkan "aman dari ban". |

---

## 5. Rencana implementasi yang disarankan (bila injector dibangun nanti)

1. **Target:** `com.fungames.sniper3d` v7.15.0 (code 33186), Unity 6 IL2CPP, `libil2cpp.so` (135 MB).
2. **Pendekatan:** root injector (Dobby/substrate-style) + pattern-scan (bukan offset hardcode) untuk: `Person` (enumerasi + `_currentHealth`), `Camera.main` + `WorldToScreenPoint`, `Weapon.ShootTest`/`FireInternal`, `WeaponData` (Spread/ClipSize/ReloadTime/MaxZoom), `Zoom` (ScaleMax), `LevelController` vs `ArenaIngameController` (gate).
3. **Overlay ESP:** pola `ESP_3_thnu.h` (Canvas via JNI + `CanvasView` kustom) — buat `StructsCommon.h` + class `CanvasView` Java dengan signature persis di file referensi. Overlay transparan di atas activity game.
4. **Menu:** toggle per fitur (default OFF) + indikator mode (MISI / ARENA / UNKNOWN) + semua fitur auto-OFF di luar misi.
5. **Yang harus dibuktikan dulu di runtime (sebelum rilis):** alamat `Person`/`Camera` di memori, nama bone kepala, nilai `MaxZoom`/`ClipSize` aktual, perilaku gate saat transisi scene, dan bahwa tidak ada satupun fitur yang menyala di Arena (uji match Arena dengan fitur ON — harus tetap OFF).
6. **Tidak dibangun di sini** — sesuai perintah tugas (riset saja).

---

## 6. Ringkasan untuk user

- **Misi (solo vs AI): BOLEH** — aimbot/aimlock, auto-aim saat zoom, ESP (Canvas-JNI), no-recoil (no-spread), no-reload, zoom jauh. Semuanya dengan **gate mode misi + fail-closed**.
- **Arena/PvP: SEMUA DITOLAK** — dump membuktikan Arena itu PvP real-time lawan yang disinkronkan server (bukan "cuma bot"). Bot memang ada sebagai pengisi roster, tapi tidak bisa dipastikan — dan tembakan divalidasi server.
- **Uang (koin/diamond/energi/IAP): SEMUA DITOLAK** — server-side + receipt validation.
- **Risiko tetap ada** meski di misi: server bisa menandai cheater (ban/suspend) — jangan pakai secara ekstrem.
- **ESP_3_thnu.h: bisa dipakai** untuk sisi gambar; data musuh (posisi, nyawa) diambil dari game — caranya sudah dipetakan di `REPORT.md` §8.

**Catatan untuk parent:** MEMORY.md mencatat perintah user agar laporan REA/dump + injector APK Sniper 3D (dan Wild Hunter 3D) di-push ke GitHub + dipublikasikan permanen dengan rilis otomatis. Tugas subagent ini dibatasi "riset saja, JANGAN push" — keputusan push/publikasi diserahkan ke parent.
