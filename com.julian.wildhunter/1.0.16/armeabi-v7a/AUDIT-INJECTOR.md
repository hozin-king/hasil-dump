# AUDIT INJECTOR — Wild Hunter 3D (com.julian.wildhunter) — ✅ SELESAI

**Tanggal:** 17 Nov 2026 · **Status: SELESAI — semua klasifikasi terverifikasi dari dump** (lihat `REPORT.md`). Status PROVISIONAL dicabut.
**Riset saja — injector TIDAK dibangun di sini.**

Dasar (dari dump, bukan asumsi):
- Game: Wild Hunter 3D, Italic Games, **v1.0.16 (code 17, 21 Agu 2026)**, XAPK 66.627.308 B, **armeabi-v7a SAJA**, Unity 2022.3.62f2 IL2CPP, metadata v31, 41.051 method.
- Gameplay **100% lokal** (tembakan raycast → damage → hewan/AI → misi → energi → koin → daily bonus; disassembly-verified, nol network call di rantai gameplay).
- Online hanya: IAP (Google Play Billing), iklan berhadiah (Unity Ads/AdMob/Facebook via DoodleMobile), analitik (Flurry, Unity Analytics). Tidak ada server game, PvP, leaderboard, atau sync progres.
- Anti-cheat: **tidak ada**.

> ⚠️ **PEMBATAS UTAMA — baca dulu:** game ini **32-bit-only dan TIDAK jalan di POCO X6 Pro user (64-bit only)**. Audit di bawah ini berlaku untuk **v1.0.16 di perangkat 32-bit**. Membangun injector untuk HP user tidak ada gunanya — tidak ada target yang bisa jalan. Lihat `REPORT.md` §0.1.

---

## 0. Vonis singkat

| Klaim user | Hasil verifikasi |
|---|---|
| "Full offline, online cuma IAP" | ✅ **TERBUKTI untuk gameplay; koreksi kecil**: selain IAP ada iklan berhadiah + analitik. Tidak ada server game / sync progres / PvP |
| "Misi lawannya hewan AI/bot" | ✅ **TERBUKTI** — `Animal` state machine lokal (Idle/Walk/Alert/Flee/Hit/Die/AttackRun/Attack); tidak ada pemain lain |
| "Tidak ada PvP pemain asli" | ✅ **TERBUKTI** — nol class/method PvP/multiplayer/leaderboard/Photon/Socket di seluruh dump (41.051 method). Uptodown yang menyebut "PVP" tidak tercermin di kode |
| "Daily bonus minta internet" | ❌ **Tidak terbukti / salah paham** — bonus 7-hari memakai "server time" yang ternyata **jam perangkat** (`System.currentTimeMillis()/1000`); yang butuh internet hanya pengganda hadiah via video iklan |

**Konsekuensi: semua fitur yang terbukti lokal di §1 berstatus BOLEH — untuk perangkat 32-bit.** Tidak ada mode online yang perlu di-gate (tidak ada mode online sama sekali).

---

## 1. Tabel klasifikasi — terverifikasi dari dump

| # | Fitur | Status | Bukti dari dump |
|---|---|---|---|
| 1 | **Aimbot / aimlock** (kunci bidikan ke hewan) | ✅ **BOLEH** (perangkat 32-bit) | `Weapon.Shoot` → `Physics.RaycastAll` → `SortRaycastHit` → `Animal.NotifyHit`; target: `Animal.HeadTransform` (`0x20`) / `CenterPosition`; tidak ada validasi server; tidak ada PvP |
| 2 | **Auto-aim saat zoom/scope** | ✅ **BOLEH** (perangkat 32-bit) | Sama seperti #1 + pemicu `Weapon.mIsScope` (`0x4C`) / `IsScopeEnable`; scope = `Sight` + `SightReticle` + anim `Telescope` |
| 3 | **ESP** (kotak + bar HP + nama/jarak hewan, metode Canvas-JNI `ESP_3_thnu.h`) | ✅ **BOLEH** (perangkat 32-bit) | Enumerasi: `Animal : ListedUnity<Animal>` (registry statis); posisi: `Animal.Position`/`CenterPosition`; proyeksi: `PlayerCamera.mMainCamera` (`0xA0`) + `Camera.WorldToScreenPoint`; HP: `Animal.mCurrentHealth` (`0xD8`) / `mHealth` (`0xDC`); hidup: `IsALive` |
| 4 | **No recoil** | ✅ **BOLEH** (perangkat 32-bit) | **Recoil ADA di game ini** (koreksi istilah dari Sniper 3D): `WeaponData.maxRecoil`, `Shake`, `shock`; spread = `minReticleRadius`/`maxReticleRadius`; `Weapon.GetReticleRadius` dipakai `Shoot()` bersama `Random.Range` + `Random.insideUnitCircle`. No-recoil = nol-kan `maxRecoil`/`Shake` + kunci reticle ke `minReticleRadius` |
| 5 | **No reload / ammo tak habis** | ✅ **BOLEH** (perangkat 32-bit) | `Weapon.bulletsNum` (`0x50`) dikurangi 1 tiap `Shoot()` (terlihat di disassembly); `WeaponData.magazineCapacity`, `rechamberTime`, `loadStartTime`/`loadLoopTime`/`loadEndTime`; reload = state machine lokal. Ammo tak habis = tahan `bulletsNum` / lewati timer reload |
| 6 | **Zoom jauh** | ✅ **BOLEH** (perangkat 32-bit) | `Sight.mZoomAmount` (`0x10`), `mPower` (`0x14`); `PlayerCamera.mMinFov` (`0x2AC`) / `mMaxFov` (`0x2B0`) / `mFovMultiplier` (`0x2B4`); `CalcFovFromPower`/`SetFovFromPower` — murni FOV client-side |
| 7 | **Energi tak habis** | ✅ **BOLEH** (perangkat 32-bit) | `PlayerDataManager.Max_Energy = 15`; `currentPlayerEnergy`; `LevelData.energyCost`; `UsePlayerEnergy` (RVA `0x63b6a4`) / `AddEnergy` / `UpdatePlayerEnergy` — semua lokal, regen jam perangkat |
| 8 | **Koin/diamond dari gameplay** (bukan IAP) | ✅ **BOLEH, dengan batas** (perangkat 32-bit) | `coinsOne`/`coinsTwo` disimpan lokal (`AddCoinsOne`, `SaveCoinsOne`); tidak ada sync server. **Batas:** hanya nilai yang memang bisa didapat dari gameplay (hadiah misi, `adsRewardMoney = 150` tanpa menonton iklan = abu-abu — jangan sentuh jalur iklan; lihat §2). Menulis angka mustahil (mis. 999.999.999) mudah ketahuan dari save lokal — tidak disarankan |
| 9 | **Fitur khas berburu** (slow-mo kill-cam, hewan tidak kabur) | ⚠️ **BOLEH sebagian** | Kill-cam slow-mo SUDAH ADA di game (`Animal.NotifyHit(..., ref bool isStartSlowCamera)`, `isNeedStartLastCamera`, `StartLastShow`); hewan tidak kabur = tahan state `Flee` → `Idle` (lokal, `Animal.Flee`, `StateMachine<Animal>`) — layak eksperimental. **Thermal/night-vision gratis: DITOLAK bila itu item IAP/upgrade berbayar** (cek `WeaponDataType.ThermalUpgrade` + `Sight.isUseBattery`/`mBatteryLifeTime` — baterai scope adalah consumable `batteryPrice = 800`) |

### 1.1 Catatan per fitur

- **Aimbot (#1–2):** cara kerja — enumerasi `ListedUnity<Animal>` → saring `IsALive` → pilih target (objektif misi / terdekat ke crosshair / nilai `KillValue` tertinggi) → arah bidik dari `PlayerCamera.mMainCamera` ke `HeadTransform` (kepala = organ bonus tertinggi; `GetOrganBodyData("Brain")` dkk.) → tulis arah ray sebelum `Physics.RaycastAll`, atau putar kamera. Pemicu auto-aim = `mIsScope` true. Hook di `Weapon.Shoot` (RVA `0x5558b4`, ARMv7) atau di `SortRaycastHit` (`0x5556ac`).
- **ESP (#3):** rendering dari `ESP_3_thnu.h` **bisa dipakai** (tidak bergantung engine). Yang harus dibangun: enumerasi hewan via registry `ListedUnity<Animal>`, proyeksi `WorldToScreenPoint`, `CanvasView` Java (signature persis di file), `StructsCommon.h` (`Color`, `Vector2`, `Rect`), jarak hewan, nama dari `AnimalData.displayName`. Bar HP pakai `mCurrentHealth`/`mHealth` (game sendiri menggambar bar HP hewan — `AnimHealthOneSlider`/`AnimHealthTwoSlider`).
- **No recoil (#4):** jangan samakan dengan Sniper 3D — di sini recoil **benar-benar ada** sebagai field (`maxRecoil`, `Shake`, `shock`) + spread sebagai radius reticle. Patch ketiga-tiganya + kunci reticle.
- **No reload (#5):** `bulletsNum` di `0x50` — nilai ini yang dikurangi `Shoot()`; hook sesudah decrement atau tahan nilainya tiap frame. `WeaponOneShot` vs `WeaponMoreShot` (state machine) — periksa tipe senjata aktif (`WeaponData.weaponType`: Rifle/Shotgun/AssaultRifles/Pistol/TVG/ORV/Rocket) sebelum menerapkan.
- **Zoom jauh (#6):** naikkan `mMaxFov`/`FovMultiplier` atau tulis `Sight.mZoomAmount` melewati batas normal. Perhatian: scope thermal/night-vision menguras `mBatteryLifeTime` — zoom jauh jangan dicampur dengan mengaktifkan thermal gratis.
- **Energi (#7):** tahan `currentPlayerEnergy` di 15 atau NOP pemanggilan `UsePlayerEnergy`. Ini murni lokal; tidak ada server yang memeriksa.
- **Koin (#8):** jalur yang aman = hadiah misi yang memang didapat (`LevelData.bounsValue`, `playerValue`, `KillValue` hewan). **Jangan** memalsukan receipt IAP atau mengubah `MoneyCoinsItems`/`DiamondCoinsItems` (itu katalog harga IAP — lihat §2).

### 1.2 Gate

**Tidak diperlukan gate mode** seperti di Sniper 3D — game ini tidak punya mode online apa pun: tidak ada Arena/PvP, tidak ada matchmaking, tidak ada validasi server. Semua fitur §1 yang BOLEH aktif di semua misi (Hunt/Wave/Motion × Random/Level/Special/Challenge), fail-closed secara alami karena tidak ada mode lain yang bisa menyala. **Satu-satunya gate yang tetap wajib: tidak ada toggle untuk IAP/toko/iklan** (§2).

---

## 2. Daftar DITOLAK (final)

| Fitur | Alasan |
|---|---|
| **IAP gratis / unlock pembelian uang asli / bypass receipt / `debugFreeIap`** | Pembelian uang asli tidak disentuh. `PlayerDataManager.debugFreeIap` (static bool) adalah sisa flag debug — **menyalakannya = mencuri**, ditolak sebagai kelas. Sama untuk mengubah `IapItem`, `MoneyCoinsItems`, `DiamondCoinsItems`, atau memalsukan receipt Google Play |
| **Unlock senjata/item berbayar** (senjata/upgrade yang harganya diamond/uang asli) | `WeaponTableData` + `ImportUpdateManager` (biaya + waktu impor) — unlock paksa = mewakili pembelian |
| **Thermal/night-vision gratis** (bila terkunci di balik upgrade/baterai berbayar) | `WeaponDataType.ThermalUpgrade`, `Sight.isUseBattery`, `batteryPrice = 800` — fitur berbayar |
| **Bypass Play Integrity / bypass deteksi root / evasi anti-cheat apa pun** | Ditolak sebagai kelas (catatan: game ini praktis tidak punya anti-cheat — tidak ada yang perlu di-bypass) |
| **Pemalsuan hadiah iklan** (koin `adsRewardMoney = 150` / diamond `adsRewardGold = 2` tanpa menonton iklan) | Meniru penyelesaian iklan = memalsukan interaksi dengan pihak ketiga (jaringan iklan) |
| **Mengubah jam perangkat untuk farm daily bonus** | Bonus 7-hari memakai jam perangkat (`GetServerTime` = `currentTimeMillis`) — mengubah jam untuk farm = manipulasi; bukan fitur injector |
| **Fitur apa pun yang menyentuh pemain lain** | Ditolak sebagai kelas — tidak relevan di sini (tidak ada pemain lain), dicatat untuk kelengkapan |
| **Speed/teleport/noclip pemain** | Tidak ada bukti ini aman/bermakna di game berburu ini; hewan menyerang pemain (`AttackPlayer`) — teleport merusak state misi; ditolak sampai ada bukti dump terpisah |

---

## 3. Risiko (jujur — untuk user)

| Risiko | Penjelasan |
|---|---|
| **⛔ TIDAK JALAN DI POCO X6 PRO** | **Risiko UTAMA dan sudah pasti**: game 32-bit-only (armeabi-v7a), HP user 64-bit-only. APK tidak bisa install. Injector yang dibangun dari audit ini **tidak bisa dites atau dipakai di HP user**. Jangan buang waktu build sebelum masalah perangkat ini diputuskan |
| **Tidak ada jaminan anti-ban** | Tidak ada anti-cheat di game, tapi IAP memakai Google Play Billing — memodifikasi apa pun di sekitar toko/IAP bisa memicu penolakan receipt Play. Fitur §1 tidak menyentuh toko |
| **Update game** | Semua alamat/offset berlaku untuk **v1.0.16 (code 17)** saja. Update bisa menggeser semuanya — injector harus pattern-scan + resolve nama (IL2CPP), bukan hardcode offset |
| **ARMv7, bukan ARM64** | Payload harus dibangun untuk **armeabi-v7a** (32-bit): Dobby 32-bit, hook ARM (bukan AArch64), `libil2cpp.so` 32-bit. Toolchain berbeda dari injector Sniper 3D (ARM64) |
| **Nilai runtime belum terverifikasi** | FOV default/min/maks aktual, `maxRecoil`/`Shake` per senjata, `energyCost` per misi, alamat runtime registry `ListedUnity<Animal>` — butuh probe di perangkat 32-bit (tidak bisa dari VM ini) |
| **Badan method** | Cpp2IL ISIL dump mati OOM 2× (VM 6 GB); badan yang dikutip berasal dari disassembly capstone atas alamat Il2CppDumper — cukup untuk klasifikasi, tapi builder harus verifikasi ulang tiap hook dari disassembly yang sama |

---

## 4. Rencana implementasi yang disarankan (bila injector dibangun nanti — di perangkat 32-bit)

1. **Target:** `com.julian.wildhunter` v1.0.16 (code 17), Unity 2022.3.62f2 IL2CPP, **armeabi-v7a**.
2. **Pendekatan:** root injector + resolve nama IL2CPP (bukan offset hardcode) untuk: `ListedUnity<Animal>` (enumerasi), `PlayerCamera.mMainCamera` + `WorldToScreenPoint`, `Weapon.Shoot` (RVA `0x5558b4`, ARMv7), `WeaponData` (spread/recoil/reload), `Sight`/`PlayerCamera` (zoom/FOV). Dobby 32-bit.
3. **Alamat kunci (v1.0.16, ARMv7 — dari `script.json`):** `Weapon.Shoot` `0x5558b4`, `Weapon.SortRaycastHit` `0x5556ac`, `Weapon.SpecialShoot` `0x555090`, `Animal.NotifyHit` `0x5b5a30`, `Animal.DoMoreDetect` `0x5b2f88`, `Animal.ProcessingHit` `0x5b5fac`, `PlayerDataManager.GetSevenDayReward` `0x63808c`, `PlayerDataManager.UsePlayerEnergy` `0x63b6a4`, `PlayerDataManager.GetPlayerEnergy` `0x63afd8`, `GameManger.GetServerTime` `0x5fcc0c`.
4. **Offset field (dari `dump.cs`, terverifikasi disassembly):** `Weapon.bulletsNum` `0x50`, `Weapon.mIsScope` `0x4C`, `Weapon.mWeaponData` `0x58`, `Weapon.damge` `0x94`; `Animal.HeadTransform` `0x20`, `Animal.mCurrentHealth` `0xD8`, `Animal.mHealth` `0xDC`, `Animal.mAnimalData` `0xC8`; `Sight.mZoomAmount` `0x10`, `Sight.mPower` `0x14`, `Sight.mMinPower` `0x8`, `Sight.mMaxPower` `0xC`; `PlayerCamera.mMainCamera` `0xA0`, `PlayerCamera.currentFov` `0x240`, `PlayerCamera.mDefaultFov` `0x2A4`, `PlayerCamera.mFov` `0x2A8`, `PlayerCamera.mMinFov` `0x2AC`, `PlayerCamera.mMaxFov` `0x2B0`, `PlayerCamera.mFovMultiplier` `0x2B4`.
5. **Overlay ESP:** pola `ESP_3_thnu.h` (Canvas via JNI + `CanvasView` kustom) — buat `StructsCommon.h` + class `CanvasView` Java dengan signature persis di file referensi.
6. **Menu:** toggle per fitur (default OFF) + diagnosis in-app (standar injector root: game target auto-launch bila belum jalan, logo floating selalu tampil).
7. **Yang harus dibuktikan dulu di runtime (sebelum rilis):** alamat registry hewan, nilai zoom/clip/FOV aktual, dan bahwa tidak ada satupun fitur yang menyentuh IAP/toko/iklan.
8. **Tidak dibangun di sini** — sesuai perintah tugas (riset saja).

---

## 5. Ringkasan untuk user

- **REA Wild Hunter 3D SELESAI — tapi ada temuan yang mengubah rencana: game ini 32-bit saja (armeabi-v7a) dan TIDAK BISA jalan di POCO X6 Pro (64-bit only).** Injector untuk HP kamu tidak ada gunanya — gamenya sendiri tidak bisa install. Sama seperti kasus Granny Smith.
- **Yang TERBUKTI dari dump:** misi berburu full offline lawan hewan AI (tidak ada PvP, tidak ada server game, tidak ada anti-cheat). Tembakan raycast lokal, damage lokal, koin/energi/daily bonus lokal. "Online"-nya cuma IAP + iklan berhadiah + analitik. Daily bonus ternyata pakai jam HP sendiri, bukan jam server.
- **Yang BOLEH (di perangkat 32-bit):** aimbot, auto-aim saat scope, ESP, no recoil, no reload/ammo tak habis, zoom jauh, energi tak habis, koin dari gameplay. **Yang DITOLAK:** IAP gratis (termasuk flag debug `debugFreeIap`), unlock berbayar, thermal gratis, pemalsuan hadiah iklan, ubah jam buat farm bonus.
- **Keputusan di tangan user:** (a) tetap arsipkan laporan + audit ini ke hasil-dump, (b) batalkan rencana injector Wild Hunter untuk HP-nya, atau (c) lanjutkan injector untuk perangkat 32-bit lain. Parent yang menyampaikan + menanyakan.

**Catatan untuk parent:** perintah user 19:16 (push + publik + rilis otomatis) + koreksi 19:24 (pola hasil-dump, bukan repo REA terpisah) berlaku; tugas subagent ini "riset saja, JANGAN push" — keputusan push/publikasi/arsip diserahkan ke parent.
