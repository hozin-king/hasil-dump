# REA REPORT — Plants vs. Zombies 2 FREE (com.ea.game.pvzfree_row) 3.18.0 / versionCode 3180

**Tanggal REA:** 16 Nov 2026
**Target:** `com.ea.game.pvzfree_row`, versionName **3.18.0**, versionCode **3180**, arm64-v8a
**Sumber:** XAPK APKPure `[tautan unduhan dihapus — minta ke Alyaa]pure.net/b/XAPK/com.ea.game.pvzfree_row?versionCode=3180&nc=arm64-v8a&sv=24`
**Metode:** statis saja (aapt/aapt2, readelf, nm, strings, dexdump, objdump). **Ghidra/IDA/Hopper TIDAK ADA di VM** — tidak ada dekompilasi pseudocode; semua klaim di bawah berbasis simbol/string yang terbukti ada. **Tidak ada runtime probe** di tahap ini.
**Lokasi dump:** `~/workspace/rea-pvz2/` (XAPK + `dump/` + `analysis/`)

---

## 1. Artefak yang diunduh & diverifikasi

| Artefak | Ukuran | SHA-256 |
|---|---|---|
| `pvzfree_row-3180.xapk` | 130.798.560 B (125 MB) | `da4fb7a927ec80099d82dbaa346ecb9ccd46604ba228f83c2bdfe8fbb1b17624` |
| `com.ea.game.pvzfree_row.apk` (base) | 103.344.664 B | `899ced8815fce3a2713991dd7e92a1d42bfa8f58ff11b21d5f7bcaa3d9ea869c` |
| `config.arm64_v8a.apk` (split, berisi semua .so) | 15.226.069 B | `6d290b20ac9c9dd9b30fd5cddbb240b05f51db0350a9831541821aee3d168949` |
| `config.armeabi_v7a.apk` (split, tidak dipakai — target arm64) | 12.195.051 B | — |

- **XAPK TIDAK berisi OBB.** Isi XAPK: base APK + 2 split config + `manifest.json` + `icon.png` (192×192).
- **Game mengunduh resource saat pertama jalan** (string UI: "Download der Ressourcen…", "Connexion au serveur de téléchargement...") + **validasi lisensi Google Play** (`CHECK_LICENSE`, string: "game could not be validated by Google Play"). Definisi level/tanaman/zombie (compiled definition files — simbol `DefinitionReadCompiledObbFile` / `DefinitionReadCompiledFile`) ikut diunduh, **bukan** di dalam APK ini. Konsekuensi: REA statis APK saja **tidak bisa melihat** data level/tanaman/arena — itu ada di konten unduhan.
- **Signer APK:** CN=EAM, OU=EAM, O=EAM (EA Mobile), SHA-256 `5bff7d614e1ba11a566abb589c863b013f79aa747bd2146733366c5625a5f0d2`.

## 2. Identitas aplikasi

| Field | Nilai |
|---|---|
| Package | `com.ea.game.pvzfree_row` |
| versionName / versionCode | 3.18.0 / 3180 |
| minSdk / targetSdk | 24 / 37 |
| Launcher activity | `com.ea.game.pvzfree_row.PvZActivity` |
| Permission penting | `INTERNET`, `BILLING` (IAP), `CHECK_LICENSE`, `ACCESS_NETWORK_STATE`, `AD_ID`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `RECEIVE` (C2DM/push) |
| Billing client | Google Play Billing **8.0.0** (`billing.properties`) |

## 3. Native libraries (config.arm64_v8a.apk)

| Library | Ukuran | SHA-256 (16 hex pertama) | Keterangan |
|---|---|---|---|
| **libpvz.so** | **50.117.680 B** | `079a0c71a67ae61f…` (full di bawah) | **Game engine utama** |
| libNimble.so | 119.040 B | `0f9737e0c37734e3…` | EA Nimble — JNI bridge tipis, **NOT stripped, ada debug_info** |
| libc++_shared.so | 1.794.776 B | `f9992c4ba6b7c5a7…` | STL runtime |
| libcrashlytics*.so (4 file) | 9.216–864.616 B | — | Firebase Crashlytics |
| libapplovin-native-crash-reporter.so | 860.200 B | `ecf2a7327be48287…` | AppLovin crash reporter |
| libgluads_shared.so | 375.952 B | `f57904ad7d76b275…` | Glu ads |
| libtapjoy.so | 301.656 B | `7510326e5e905529…` | Tapjoy ads |
| libdatastore_shared_counter.so | 7.112 B | `d3e48717c9aa147e…` | — |

SHA-256 penuh libpvz.so: `079a0c71a67ae61fa98cd797dbb527e1c16fa0e409fe7f980c459afe1488dff5`
SHA-256 penuh libNimble.so: `0f9737e0c37734e37e48bf8a82cf60322c67426f0f52df978394af61144ce9c6`
BuildID libpvz.so: `8e40bdc91b1c112b29b4b4b587a04159`

### 3.1 libpvz.so — engine

- ELF 64-bit LSB, AArch64, DYN, **stripped (tidak ada static symtab)**.
- **TAPI: 87.313 simbol dinamis (.dynsym) — termasuk nama C++ lengkap (mangled) dari SEMUA kelas game.** 36.339 simbol `T` (text), 38.190 `W` (weak), 4.125 `B`, 3.453 `D`, 1.083 `R`, 3.468 `V`. Ini kabar terbaik untuk injector: hook bisa diikat lewat **nama simbol (dlsym)**, bukan pattern-scan buta.
- NEEDED: `libandroid, libc, libc++_shared, libdl, libEGL, libGLESv2, liblog, libm, libOpenSLES, libz, libNimble.so`. SONAME `libpvz.so`.
- Namespace terbanyak di .dynsym: `eastl` (13.225), `EA` (10.949), `Sexy` (8.676), `cocos` (6.125), `LawnApp` (454), `Board` (317), `PopCap` (273), `Zombie` (227), `Plant` (104), `ZenGarden` (96), `FEAST` (197), `TodLib` (171), `Challenge` (176), `dragonBones` (757), `glucentralservices` (518), `pvzcocos` (118).
- **Engine = PopCap SexyAppFramework + Cocos2d-x + Cocos Creator** (scene UI `.ccreator`: `GameBoardScene`, `LevelSelectionScene`, `CoverFlowScene`, `GenericPopupScene`, `MiniGameScene`, …) + EASTL + Glu Central Services. Bukan Unity, bukan Unreal.

### 3.2 libNimble.so — EA Nimble (platform SDK EA)

- Hanya JNI bridge: `EA::Nimble::getEnv()`, `EA::Nimble::findClass()`, `JNI_OnLoad`, memuat `com/ea/nimble/bridge/BaseNativeCallback` lewat classloader aplikasi. Logika Nimble yang sebenarnya ada di **Java (dex)**: `com.ea.nimble.*` (~200 class).
- Isi SDK Nimble (dari `dex_classes.txt`): `ApplicationEnvironment` (+ `IApplicationEnvironment$IntegrityTokenCallback`), `SynergyEnvironment` / `SynergyIdManager` / `SynergyNetwork` (backend EA "Synergy"), `mtx` / `NimbleMTX` / `SynergyCatalog` / `googleplay.GooglePlay` (+ `PurchaseTransactionVerifier`, `TransactionRecorder`, `BillingHelper`, `Security`), `tracking`, `pushtng`, `WebView`, `Persistence`, `Log`.

## 4. Endpoint network (dari strings libpvz.so)

| URL | Fungsi |
|---|---|
| `https://pvzfreegs.com/config/v1/version/android?version=` | Config server game (versi/konten) |
| `https://draper.popcap.com/` | Draper — telemetri/ads PopCap |
| `https://static-www.ecs.popcap.com/mobile_interstitials/…` | Iklan interstitial / XPromo |
| `https://help.ea.com/en/games/plants-vs-zombies/…` | Bantuan EA |
| `https://play.google.com/store/apps/details?id=com.ea.game.pvzfree_row` | Halaman Play Store |

## 5. Hook target yang TERBUKTI ADA (nama + alamat file offset)

Alamat = offset dari base libpvz.so (dipakai dlsym via nama mangled; offset dicatat untuk pattern-scan fallback).

| Fungsi (demangled) | Alamat | Mangled |
|---|---|---|
| `Board::AddSunMoney(int)` | `0x1a12c74` | `_ZN5Board11AddSunMoneyEi` |
| `Board::TakeSunMoney(int)` | `0x19fa900` | `_ZN5Board12TakeSunMoneyEi` |
| `Board::CanTakeSunMoney(int)` | `0x1a12fb8` | `_ZN5Board15CanTakeSunMoneyEi` |
| `Board::AddPlant(int,int,SeedType,SeedType)` | `0x19f51ec` | `_ZN5Board8AddPlantEii8SeedTypeS0_` |
| `Board::CanPlantAt(int,int,SeedType,bool)` | `0x19f65c0` | `_ZN5Board10CanPlantAtEii8SeedTypeb` |
| `Board::GetCurrentPlantCost(SeedType,SeedType)` | `0x19fa87c` | — (lihat dynsym_demangled.txt) |
| `Board::InitLawnMowers()` | `0x19f15ac` | `_ZN5Board14InitLawnMowersEv` |
| `Board::RowHasLawnMower(int)` | `0x19f1844` | — |
| `Board::IterateLawnMowers(LawnMower*&)` | `0x19e86d4` | — |
| `Board::SetSuperMowerMode(bool)` | `0x1a0fb5c` | `_ZN5Board17SetSuperMowerModeEb` |
| `Board::UpdateSunSpawning()` | `0x1a02ee4` | — |
| `Board::UpdateGame()` | `0x1a04f3c` | — |
| `Board::StartLevel()` | `0x19f1cdc` | — |
| `Zombie::TakeDamage(int,unsigned int,bool)` | `0x1c75478` | `_ZN6Zombie10TakeDamageEijb` |
| `Plant::UpdateNeedsFood()` | `0x1b58664` | — |
| `Plant::SpikeRockTakeDamage()` | `0x1b4c2d0` | — |
| `Coin::GetSunValue()` | `0x1a42978` | — |
| `Coin::IsSun()` | `0x1a40f9c` | — |
| `SeedBank::AddSeed(SeedType)` | `0x1c45d9c` | — |
| `SeedBank::RefreshAllPackets()` | `0x1c46528` | — |
| `SeedBank::UpdateConveyorBelt()` | `0x1c46270` | — |
| `PlayerInfo::AddCoins(int,bool,…)` | `0x1b70f2c` | `_ZN10PlayerInfo8AddCoinsEibNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEN5eastl12basic_stringIcNS7_9allocatorEEESA_` |
| `PlayerInfo::GetCoins(bool)` | `0x1b72144` | `_ZN10PlayerInfo8GetCoinsEb` |
| `PlayerInfo::Check200kCoins(bool)` | `0x1b70c20` | — |
| `PlayerInfo::HandleInAppPurchase(int,int,int,…)` | `0x1b730bc` | — |
| `PlayerInfo::LoadDetails()` / `SaveDetails()` | `0x1b71350` / `0x1b71e50` | — |
| `PlayerInfo::ReadFromJSON()` / `WriteJSONToFile()` | `0x1b5f2b4` / `0x1b643d0` | — |
| `PlayerInfo::SyncDetails(Sexy::DataSync&,bool)` | `0x1b5ddc0` | — |
| `PlayerInfo::GetLevel()` / `SetLevel(int)` | `0x1b7212c` / `0x1b72868` | — |
| `LawnApp::DoCheatDialog()` | `0x1ac3798` | `_ZN7LawnApp13DoCheatDialogEv` |
| `LawnApp::FinishCheatDialog(bool)` | `0x1ac3840` | — |
| `LawnApp::HasSeedType(SeedType)` | `0x1ad40b8` | — |
| `LawnApp::GetSeedsAvailable()` | `0x1ad4030` | — |
| `LawnApp::GetAwardSeedForLevel(int)` | `0x1ad3f70` | — |
| `LawnApp::IsPlantsFromCoinsLevel()` | `0x1ad3b90` | — |
| `LawnApp::ShowLeaderboardScreen()` | `0x1b1571c` | — |
| `Store_GetCoinsForMtxItem(int,int&)` | `0x1caf900` | `_Z24Store_GetCoinsForMtxItemiRi` |
| `GetMoreCoinsScreen::PurchaseProduct(…)` | `0x1d0cfe8` | — |
| `JNI_OnLoad` (libpvz.so) | `0x26e6434` | — |

Daftar lengkap: `analysis/dynsym.txt` (mangled, 87.313 baris) dan `analysis/dynsym_demangled.txt` (36.339 simbol `T`).

## 6. Klasifikasi fitur — LOCAL vs SERVER-GATED

| Fitur | Vonis | Bukti |
|---|---|---|
| **Sun (matahari) di level** | **LOCAL** | `Board::AddSunMoney/TakeSunMoney/CanTakeSunMoney` murni in-memory; tidak ada pemanggilan server di jalur sun (tidak ada simbol network di sekitar Board). Sun = resource per-level, hilang saat level selesai. |
| **Lawn mower** | **LOCAL** | `Board::InitLawnMowers/RowHasLawnMower/IterateLawnMowers/SetSuperMowerMode(bool)` — logika lokal penuh. |
| **Kerusakan zombie / tanaman** | **LOCAL** | `Zombie::TakeDamage(int,unsigned,bool)` + `Plant::Update*` per tanaman — simulasi lokal penuh. |
| **Cooldown seed packet** | **BELUM PASTI (kemungkinan LOCAL)** | `SeedBank::RefreshAllPackets/UpdateConveyorBelt` ada; fungsi recharge timer persisnya belum diidentifikasi dari simbol saja — butuh probe runtime. |
| **Plant Food** | **BELUM PASTI** | `Plant::UpdateNeedsFood()` ada; tidak ada accessor `AddPlantFood/GetPlantFood` di .dynsym — counter kemungkinan member Board/data-driven. Butuh probe runtime. |
| **Coins (saldo)** | **LOCAL counter, TAPI pemberian via IAP = SERVER** | `PlayerInfo::AddCoins/GetCoins` lokal; save = JSON lokal (`WriteJSONToFile`). **Namun** pembelian koin lewat `NimbleMTX → Google Play Billing → PurchaseTransactionVerifier → SynergyCatalog` (verifikasi receipt di server). Tidak ada bukti server mengoreksi saldo koin saat load — **belum pasti**, butuh probe runtime (apakah profil/Synergy me-re-sync saldo). |
| **Gems (mata uang premium)** | **SERVER-GATED (DITOLAK)** | Tidak ada `AddGems/GetGems` di .dynsym sama sekali; tidak ada string UI "Gems" di resources. Gems hanya ada sebagai item MTX di katalog Nimble/Synergy (pembelian uang asli, receipt diverifikasi server). |
| **Unlock tanaman via beli** | **SERVER-GATED (DITOLAK)** | `LawnApp::FinishPlantSale`, `LoadProductsFile`, `GetMoreCoinsScreen::PurchaseProduct`, `PlayerInfo::HandleInAppPurchase` — jalur store/MTX. |
| **Unlock tanaman via progres level** | **LOCAL (kandidat, butuh probe)** | `LawnApp::GetAwardSeedForLevel`, `HasSeedType`, `GetSeedsAvailable` — pemberian lewat progres, bukan store. Belum ada bukti server memvalidasi tanaman terbuka saat sync profil. |
| **No Ads / Speed-Up bundle / Hard Nudge** | **SERVER-GATED (DITOLAK)** | `PlayerInfo::AddNoAdsExpiry/AddSpeedUpExpiry/AddHardNudgeExpiry`, SKU `NoAdsPackSKU [868917]`, `SpeedUpBundle*` — produk berbayar, expiry dicatat server. |
| **Level progression / bintang** | **LOCAL (kandidat, butuh probe)** | `PlayerInfo::GetLevel/SetLevel`, save JSON lokal + backup Google Play Games CloudSave (`CloudSave::CloudSaveService`, `GooglePlayGamesCloudSaveProvider`) — cloud save = backup/restore save lokal, **bukan** validasi server atas progres. |
| **Mode Arena / kompetitif PvP** | **TIDAK DITEMUKAN di build ini** | Nol simbol/string `Arena/Battlez/Tournament/Pursuit` di libpvz.so maupun dex. Leaderboard ada (`LawnApp::ShowLeaderboardScreen`, class `Leaderboard`, Google Play Games). Piñata mode ada (`Board::SetPinataMode`, `LawnApp::CanDoPinataMode`). Bila Arena ada, ia hidup di konten unduhan (OBB) — **gate tetap berlaku**: mod WAJIB nonaktif di mode ranking/kompetitif apa pun. |
| **Iklan / reward video** | **SERVER (iklan)** | `GetMoreCoinsScreen::OnRewardedVideoAdRewarded`, Draper/IronSource/AppLovin — di luar cakupan mod. |

**Catatan "Sync":** `PlayerInfo::SyncDetails(Sexy::DataSync&, …)` adalah serializer save/load framework Sexy (lokal), BUKAN sinkronisasi ke server. Jangan salah baca sebagai server-sync.

## 7. Anti-cheat / anti-tamper — apa yang TERBUKTI ADA

| Mekanisme | Bukti | Status |
|---|---|---|
| **EA Nimble — root detection API** | `com.ea.nimble.IApplicationEnvironment.isDeviceRooted()` (PUBLIC) + implementasi `ApplicationEnvironmentImpl.isDeviceRooted()` (classes2.dex) | **Kemampuan ADA.** Apakah game memanggilnya dan bertindak atas hasilnya — **TIDAK TERBUKTI dari statis** (butuh probe runtime). |
| **EA Nimble — Play Integrity token** | `IApplicationEnvironment$IntegrityTokenCallback`, `requestIntegrityToken` (native: `EA::Nimble::Base::ApplicationEnvironment::requestIntegrityToken`), header `X-Integrity-Key` + `glucentralservices::Tags::generateIntegrityKey` | **Token integritas diminta & dikirim ke server.** Server BISA menolak token dari perangkat/app yang dimodifikasi. Ini ancaman nyata untuk mod yang mengubah APK — **injector (tanpa ubah APK) jauh lebih aman**. |
| **EAIsDebuggerPresent()** | Simbol `_Z19EAIsDebuggerPresentv` di libpvz.so | Fungsi cek debugger ADA. Apakah dipanggil saat jalan — **tidak terbukti statis**. |
| **ptrace / fork / execv / system / __system_property_get diimpor libpvz.so** | `readelf` dynamic symbols | **Tujuan TIDAK TERBUKTI** — bisa dari crash reporter / OpenSSL fork handler (`openssl_get_fork_id` ada di .so yang sama). Jangan diklaim sebagai anti-debug tanpa probe. |
| **"Test-keys aren't accepted on this build."** | classes2.dex | Build debug/test-keys ditolak (kemungkinan dari Play Core / integrity). |
| **Validasi lisensi Google Play** | Permission `CHECK_LICENSE` + string "game could not be validated by Google Play" | APK modifikasi (re-sign) berisiko gagal validasi lisensi. Injector root (APK asli, tidak di-re-sign) menghindari ini. |
| **Root check ad SDK (bukan game)** | `io.bidmachine.DeviceInfo/DeviceUtils.isDeviceRooted()` (classes6/7.dex), "Rooted check failed" (classes5.dex, class belum teratribusi — kemungkinan ad SDK) | **Bukan mekanisme game** — jangan dihitung sebagai anti-cheat PvZ2. |
| Magisk / Xposed / Frida / SafetyNet | **NOL string di libpvz.so** | Tidak ada deteksi eksplisit terhadap tool-tool itu di native lib. |
| Signature check / checksum .so | **Tidak ditemukan** | Tidak ada simbol/string verifikasi signature di libpvz.so maupun dex (di luar Play Integrity token). |

**Vonis anti-cheat:** tidak ada anti-cheat "garis keras" (seperti Bifrost/GGP di Free Fire) di build ini. Perlindungan utamanya adalah **(a)** Play Integrity token via Nimble (server-side), **(b)** verifikasi receipt IAP di server (Nimble MTX), **(c)** validasi lisensi Google Play, **(d)** kemungkinan root check Nimble (belum terbukti dipakai). Semuanya **server-side / berbasis integritas aplikasi** — bukan deteksi hook runtime. Artinya: injector yang (1) tidak mengubah APK, (2) tidak menyentuh jalur IAP, (3) hanya aktif di mode solo/offline, punya peluang hidup paling besar. Tetap: **tidak ada jaminan** — server bisa memperketat kapan saja (lihat AUDIT-INJECTOR.md §risiko).

## 8. Temuan khusus

### 8.1 CheatDialog bawaan di binary rilis
`LawnApp::DoCheatDialog()` (`0x1ac3798`) + class `CheatDialog` (dengan `CheatDialog_LevelEditDialog` — dialog edit level) **ada di APK rilis**. Ini sisa fitur debug PopCap. **Trigger-nya TIDAK diketahui** dari statis (bukan tombol UI normal) — butuh probe runtime. Jangan dijadikan fitur andalan injector sebelum trigger terbukti; catat sebagai kandidat riset.

### 8.2 Force update & kill switch (remote config)
`assets/ConfigFile.json`: `Force_Update.Latest_version = 243911` (penomoran internal, BUKAN versionCode 3180), `Update_type = Recommended`; `KillSwitches` (KillDraper, KillRewardVideo, KillAdTelemetry, KillCCPA, KillIronSource…) — server bisa mematikan fitur dari jarak jauh. Store dikendalikan config: `SKUFilter.CoinSKU = [868916, 868915, 868914, 868930, 868929, 868913]`, `NoAdsPackSKU = [868917]`, `RestrictedSKU = [500093888, 500093886]`.

### 8.3 Save game = JSON lokal
`PlayerInfo::ReadFromJSON/TryParseJSON/WriteJSONToFile/LoadDetails/SaveDetails/LoadDetailsBackup/SaveDetailsBackup` — progres disimpan sebagai JSON di storage aplikasi (+ backup file). Cloud save hanya via Google Play Games (`CloudSaveService`), bukan server EA. Implikasi: nilai ekonomi lokal tersimpan plain (kemungkinan ter-obfuscate ringan — belum diperiksa isinya; butuh probe runtime untuk melihat file save asli).

## 9. Batasan REA ini (jujur)

1. **Tidak ada Ghidra/IDA/Hopper di VM** — tidak ada dekompilasi fungsi; alamat fungsi diketahui, isi fungsi TIDAK dibedah (kecuali lewat nama + signature).
2. **Tidak ada runtime probe** — semua "BELUM PASTI" di §6 butuh probe di HP (atau emulator) dengan game terinstal + akun tes.
3. **Konten unduhan (OBB/expansion) tidak dianalisis** — definisi level/tanaman/Arena hidup di sana; klasifikasi Arena = "tidak ditemukan di APK", bukan "tidak ada di game".
4. **Simbol .dynsym bisa hilang di update berikut** — bila EA men-strip .dynsym di rilis berikutnya, seluruh strategi dlsym runtuh ke pattern-scan (lihat AUDIT-INJECTOR.md).
5. **Perilaku server tidak bisa dipastikan dari klien** — apakah server mengoreksi saldo/progres saat sync hanya bisa dijawab lewat probe jaringan/runtime.

## 10. File kerja

- `pvzfree_row-3180.xapk` — XAPK asli (130.798.560 B)
- `dump/` — XAPK terekstrak + `dump/apk/` (base APK) + `dump/config-arm64/` (split arm64, berisi libpvz.so)
- `analysis/dynsym.txt` — 87.313 simbol dinamis (mangled)
- `analysis/dynsym_demangled.txt` — 36.339 simbol `T` (demangled)
- `analysis/strings_pvz.txt` — 163.636 string libpvz.so
- `analysis/strings_nimble.txt` — 725 string libNimble.so
- `analysis/dex_classes.txt` — 49.722 class dex
