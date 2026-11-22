# REA + Audit — Hungry Shark World 8.4.2 (versionCode 842)

**Tujuan:** persiapan root injector (solo/offline). Injector TIDAK dibangun di run ini.
**Tanggal dump:** 21 Nov 2026. **Status:** dump + REA + audit SELESAI.
**Lokasi kerja:** `~/workspace/rea-hungry-shark-world/`

---

## 1. Ringkasan eksekutif

| Item | Hasil |
|---|---|
| Game | Hungry Shark World (Ubisoft / Future Games of London) |
| Versi | **8.4.2, versionCode 842**, update 18 Nov 2026 ("EMBRACE THE NIGHT — Count Undersharker") |
| Paket | `com.ubisoft.hungrysharkworld` |
| Engine | **Unity 6000.3.10f1 (Unity 6.3), IL2CPP** — bukan Mono |
| Arsitektur | **arm64-v8a saja** (tidak ada 32-bit) |
| Metadata | `global-metadata.dat` 12.417.960 B, magic `0xFAB11BAF`, **versi 39** |
| `libil2cpp.so` | 72.561.352 B, stripped, BuildID `2206717056bdf4571ec12e74de02f3b1630c6c39`, **241 export `il2cpp_*`** (C API lengkap — resolver nama bisa dipakai) |
| `libunity.so` | 22.729.968 B |
| DEX | 7 file (`classes.dex`–`classes6.dex` + `audience_network.dex`), **50.653 class** |
| Type definitions | 15.380 (dump.cs 841.135 baris / 29,6 MB) |
| Anti-cheat | **CodeStage AntiCheat Toolkit AKTIF (terbukti di kode):** InjectionDetector, ObscuredCheatingDetector, SpeedHackDetector, WallHackDetector + `GameValidator` (FGOL) + mata uang `ObscuredInt` + cap harian gems + validasi IAP server-side (Houston) |
| Root detection | **TIDAK ADA** — tidak ada RootBeer / SafetyNet / Play Integrity / Frida / Magisk / Xposed di dump.cs, metadata strings, `libil2cpp.so`, `libubiservices.so`, maupun `libunity.so` |
| Signature check | Ada, di `GameValidator.StartBuildValidation` — bandingkan signature APK dengan 4 signature resmi; **injector root pada APK resmi TIDAK menyentuh signature → lolos** |
| Kesimpulan | **LAYAK dibangun sebagai root injector native (.so) solo/offline** dengan desain Traffic Rider (resolve nama IL2CPP + pattern-scan 32 byte + fail-closed). Fitur god mode / boost / damage / speed / bite TERBUKTI dari simbol. **Mata uang, IAP, game speed, dan unlock hiu berbayar DITOLAK** — semuanya punya jalur deteksi yang terbukti hidup di kode. |

---

## 2. Identitas file & inventaris dump

### 2.1 File sumber

| File | Ukuran | SHA-256 |
|---|---|---|
| `HungrySharkWorld-8.4.2.xapk` | 197.083.639 B | `45c83fd25712a53246a1a5c8e3d4aabf86eedd0577248add79c64f57c2e3dafd` |

SHA cocok dengan yang dipublikasikan di halaman apkpure.net. Diunduh dari mirror `d.apkpure.net` (link `d.apkpure.com` yang ditugaskan diblokir Cloudflare challenge; APKCombo minta login Cloudflare Access; APKMirror 403; Uptodown 404). **APK tidak diinstall, tidak dijalankan, tidak diupload ke mana pun.**

### 2.2 Isi XAPK (split APK, TANPA OBB)

| Split | Isi |
|---|---|
| `com.ubisoft.hungrysharkworld.apk` (base, ±152 MB) | DEX, `assets/bin/Data/` (globalgamemanagers + aset hash-named), `res/`, `META-INF/` |
| `config.arm64_v8a.apk` (±36 MB) | **Semua native lib** (`lib/arm64-v8a/`, 24 file .so) |
| `manifest.json` | version_code 842, version_name 8.4.2, min_sdk 25, target_sdk 36, total_size 196.722.900 |
| `icon.png` | Ikon |

Manifest: `compileSdk 36` (Android 16), `install-location internalOnly`. Signature APK `e3d6da236ed1df2c0d46476c7e90f2007a9a411e` (kunci Play Ubisoft, sama dengan versi lama). Permission: INTERNET, WAKE_LOCK, VIBRATE, BILLING (`com.android.vending.BILLING`), AD_ID, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, FOREGROUND_SERVICE, AD_SERVICES_* (attribution/ad-id/topics), C2D_MESSAGE/RECEIVE.

### 2.3 Inventaris dump (`dump/`)

| Path | Isi |
|---|---|
| `HungrySharkWorld-8.4.2.xapk` (root) | File XAPK asli |
| `dump/xapk/` | Isi XAPK yang diekstrak |
| `dump/base/` | Base APK terekstrak (DEX, assets, res, META-INF) |
| `dump/config/` | Config APK terekstrak (`lib/arm64-v8a/` — 24 .so) |
| `dump/dex/` | Output `dexdump` per DEX (`classes*.txt`, ±246 MB) + `all_classes.txt` |
| `dump/il2cpp/dump.cs` | 841.135 baris / 29.611.151 B, 15.380 type definitions (Il2CppDumper v39 fork) |
| `dump/il2cpp/script.json` | 1.585.018 baris / 77.669.456 B (RVA → nama method) |
| `dump/il2cpp/il2cpp.h` | 73.026.008 B |
| `dump/il2cpp/stringliteral.json` | 1.713.946 B |
| `dump/il2cpp/classes_index.json` | **Inventaris terparse: 13.662 class, 102.519 method, 44.993 field** (parser `dump.cs` buatan run ini) |
| `dump/il2cpp/hook_targets_8.4.2.yaml` | **18 target hook + field offset, dengan pola prologue 32 byte terverifikasi unik** |
| `dump/il2cpp/global-metadata.dat` | Salinan metadata (12.417.960 B) + `libil2cpp.so` |
| `dump/metadata_strings.txt` | 161.662 baris string metadata |

Total work dir ±1,4 GB (mayoritas `dump/dex` + `dump/il2cpp` — artefak deliverable, sengaja dipertahankan).

**Catatan tooling:** Il2CppDumper original (flylm) menolak metadata v39 ("not a supported version[39]"). Dipakai fork **roytu/Il2CppDumper branch v39** + .NET 8 SDK 8.0.428 (`~/.dotnet-sdk/`, staging `TMPDIR=~/workspace/tmp` karena /tmp 512 MB penuh). Dump selesai dengan peringatan "find JNI_OnLoad / This file may be protected" (heuristik dumper — output tetap lengkap + alamat valid, diverifikasi silang dengan disassembly).

### 2.4 Native lib utama (semua arm64-v8a, di `config/lib/arm64-v8a/`)

| Lib | Ukuran | Keterangan |
|---|---|---|
| `libil2cpp.so` | 72.561.352 B | **Kode game (C# → native) + runtime IL2CPP.** Stripped. BuildID `2206717056bdf4571ec12e74de02f3b1630c6c39`. 241 export `il2cpp_*`. |
| `libunity.so` | 22.729.968 B | Engine Unity 6000.3.10f1 |
| `libubiservices.so` | 15.932.112 B | Bridge Ubisoft: `Java_com_ubisoft_bridge_NativeInterface_injectActivity`, signing request `Ubi-Signature`/`Ubi-Signature-timestamp`, `AntiReplay`. **Bukan anti-tamper APK** — signing request API Ubisoft. |
| `libFirebaseCppApp-12_10_1.so` | 6.040.520 B | Firebase |
| `libnative-eos.so` | 132.512 B | Epic Online Services (`EOS_Auth`, `EOS_Ecom` incl. checkout) |
| `libnms.so` | 297.832 B | (mediation/ads) |
| `libpglarmor.so` + `libbuffer_pgl.so` + `libfile_lock_pgl.so` + `libtobEmbedPagEncrypt.so` | 68.600 / 9.000 / 6.312 / 8.304 B | **ByteDance Pangle ad-SDK crypto (`ttEncrypt`/`ttDecrypt`). Bukan anti-cheat game.** |
| `libc++_shared.so`, `libmain.so`, `libGadsmeAndroidPlugin.so`, Crashlytics/AppLovin/dll | — | Pendukung standar |

**Tidak ada** `libpairip` / proteksi packer lain, tidak ada lib anti-cheat native khusus. Semua proteksi game ada di lapisan C# (bagian 4).

### 2.5 DEX / Java

- Activity utama: `com.fgol.interaction.UnityPlayerActivity` (subclass Unity player).
- `com.fgol.security.CertificateHelper` punya `getCertificateSignaturesSHA()` — **didefinisikan tapi ZERO caller di DEX** (dormant di lapisan Java; pemakaian native via JNI tidak bisa dikesampingkan, tapi tidak ada buktinya).
- Google Play Billing Client lengkap (`com/android/billingclient/api/*`, `BillingClientImpl`) + Amazon IAP (`com/amazon/device/iap/*`) + Unity IAP/Ads bridge. Play Integrity lib ter-bundle (`com.google.android.play:integrity@@1.3.0`) tapi **TIDAK ADA invoke ke sana di seluruh DEX** (dependensi transitif, bukan dipanggil dari Java; pemakaian C# via AndroidJavaObject tidak bisa dikesampingkan secara statis — dicatat sebagai caveat).
- **Tidak ada** kelas RootBeer / SafetyNet / PairIP / Frida / Magisk / Xposed.

---

## 3. Engine & arsitektur

- **Unity 6000.3.10f1, IL2CPP.** Bukan Mono — tidak ada `Assembly-CSharp.dll`; semua kode C# terkompilasi ke `libil2cpp.so` + `global-metadata.dat` (v39).
- Namespace kode game: `FGOL.*` (framework Ubisoft/FGOL: Billing, Save, Server, Ads, Auth, GameValidation, Encryption) + `Assets.Code.Game.*` + ribuan class di **namespace global** (tanpa namespace — ini tempat mayoritas logika gameplay: `PlayerControlGenericFish`, `Bank`, `MachineShark`, dst.). Namespace kosong ini penting untuk resolver: pakai `ns=""` untuk class gameplay.
- `il2cpp_*` C API lengkap dan ter-export (241 simbol, termasuk `il2cpp_domain_get`, `il2cpp_domain_get_assemblies`, `il2cpp_class_from_name`, `il2cpp_class_get_method_from_name`, `il2cpp_field_get_offset`, `il2cpp_init`, `il2cpp_resolve_icall`) — **persis export yang dipakai resolver Traffic Rider.** Jadi pendekatan resolve-nama bisa dipakai 1:1.
- **Satu-satunya arsitektur = arm64-v8a.** Target perangkat user (POCO X6 Pro, Dimensity 8300 Ultra, 64-bit only) cocok.

---

## 4. Proteksi & anti-cheat — TEMUAN UTAMA (terbukti dari kode + disassembly)

Game ini punya **tiga lapis proteksi yang semuanya terbukti ada di binary**. Ini bagian terpenting audit — baca sebelum memutuskan fitur apa pun.

### 4.1 Lapis 1 — CodeStage AntiCheat Toolkit (ACTk)

Empat detektor + satu callback manager, semuanya ada di binary (`CodeStage.AntiCheat.Detectors`):

| Detektor | Method | Cara kerja (dari field + method) | Yang dideteksi |
|---|---|---|---|
| `InjectionDetector` : `ActDetectorBase` | 26 | `StartDetection()` / `OnNewAssemblyLoaded` / `FindInjectionInCurrentAssemblies` / `AssemblyAllowed` — memeriksa assembly yang ter-load terhadap daftar `AllowedAssembly[]` (hash + public key token) | **Assembly managed yang di-inject** (DLL tambahan, mod loader managed) |
| `ObscuredCheatingDetector` : `ActDetectorBase` | 19 | Memeriksa integritas tipe `Obscured*` (nilai asli vs nilai palsu) | **Edit memori mentah pada nilai `ObscuredInt/Float/dll`** — termasuk mata uang |
| `SpeedHackDetector` : `ActDetectorBase` | 24 | Field `interval`, `maxFalsePositives`, `coolDown`; `Update()` membandingkan tick jam sistem vs tick game | **Manipulasi `Time.timeScale`** (game speed) |
| `WallHackDetector` : `ActDetectorBase` | 50 | `CaptureFrame` — render scene dari kamera kedua, bandingkan piksel | Wallhack/ESP (tidak relevan untuk injector ini) |
| `ActDetectorBase` | 14 | `autoStart`, `keepAlive`, `detectionEvent` (UnityEvent) + `detectionAction` (UnityAction) | Base class; detektor auto-start bila ditempatkan di scene |

**Callback yang terhubung (terbukti dari disassembly):** `AntiCheatManager` hanya punya 2 method: `.ctor` + `OnMemoryHackAttempt` (RVA `0x1E67234`). Disassembly `OnMemoryHackAttempt` menunjukkan alur lengkap:

1. Ambil objek "validation record" (singleton yang sama dipakai `GameValidator`).
2. Panggil pengecekan string internal (`0x229eba8`); bila lolos → return.
3. Bila tidak: tulis **`FlaggedReason = 105` (`HackerForMemoryHack`)** ke field record di offset +256.
4. Tail-call **`HSXAnalyticsManager.HackerDetected` (RVA `0x1D84358`)** — flag dilaporkan ke backend analytics Ubisoft.

Artinya: **deteksi memory hack → flag 105 → laporan analytics ke Ubisoft.** Callback ini bertanda tangan `void()` — cocok persis dengan `UnityAction` yang dipakai ACTk, dan pola ini adalah wiring standar ACTk via scene (autoStart + detection event di inspector). Penempatan di scene tidak bisa dibuktikan secara statis dari dump (scene tidak menyimpan nama method sebagai string untuk komponen tanpa field terserialisasi), tapi **asumsikan detektor AKTIF** — bukti wiring-nya ada di kode.

**Konsekuensi desain (penting):**
- **JANGAN inject assembly managed** (DLL/.NET) — `InjectionDetector` memang dirancang untuk itu. Injector harus **native .so murni** (Dobby hook) seperti Traffic Rider: .so native tidak menambah assembly managed → `InjectionDetector` buta terhadapnya.
- **JANGAN edit memori mentah nilai `ObscuredInt`** (mata uang) — `ObscuredCheatingDetector` memang dirancang untuk itu. Semua modifikasi nilai harus lewat pemanggilan API managed yang sah (mis. hook method yang memang mengubah nilai lewat jalur normal), bukan patch byte pada field `ObscuredInt`.
- **JANGAN sentuh `Time.timeScale`** — `SpeedHackDetector` memang dirancang untuk itu (lihat §7, game speed DITOLAK).
- **JANGAN hook/disable detektornya** — itu anti-cheat evasion, di luar scope. Desain fitur harus **tetap di bawah ambang trip wire**, bukan mematikan alarmnya.

### 4.2 Lapis 2 — `FGOL.GameValidation.GameValidator` (disassembly penuh)

Class `FGOL.GameValidation.GameValidator` + enum `FailedValidationReasons`:

```
HackerForUnrecognisedAPKSignature = 101    HackerForUnsignedAPK = 102
HackerForChecksumFailIPA = 103             HackerForOver1MilGems = 104
HackerForMemoryHack = 105                  HackerForSpeedHack = 106
CheaterForOverGemsLimitInOneSession = 201  CheaterForOverCoinsLimitInOneSession = 202
CheaterForOverPointsLimitInOneSession = 203 CheaterForOverPearlsLimitInOneSession = 204
PirateForFailedIAPValidation = 301
```

Field statis: `IsHacker` (bool), `FlaggedReason` (int). Method: `.ctor`, `StartBuildValidation()` (RVA `0x21C498C`), `CheckSaveAndUpdateStatus()` (RVA `0x21C4C88`).

**Keduanya didisassembly penuh dari `libil2cpp.so` dan TERBUKTI berisi logika nyata (bukan stub kosong):**

**`StartBuildValidation` (0x21C498C)** — cek signature APK:
- Guard run-once (static bool).
- Ambil daftar signature APK lewat PackageManager (panggilan interface slot 9 pada objek hasil `0x2057ab0`).
- Loop tiap signature; bandingkan dengan **4 string signature resmi** yang di-resolve (4 panggilan `String.Equals` per elemen). Bila **tidak ada satu pun yang cocok → `IsHacker = true`, `FlaggedReason = 101`**. Bila array signature kosong → **`FlaggedReason = 102`**.
- Ekor fungsi: resolve + cache singleton (Bank/GameDB) untuk pengecekan lanjutan.

**`CheckSaveAndUpdateStatus` (0x21C4C88)** — cek gems:
- Guard run-once.
- Panggil **`Bank.GetGems()` (RVA `0x1E60BAC`)** lalu bandingkan dengan konstanta **`950.001`** (`mov w8, #32497; movk w8, #14, lsl #16` = `0xE7C51` = 950.001).
- Bila `GetGems() >= 950.001` → tulis **`FlaggedReason = 104`** ke record (offset +256) + panggil `HSXAnalyticsManager.HackerDetected`.
- Bila `IsHacker` sudah set → jalur flag kedua (laporan juga).

**Status pemanggilan — jujur dan penting:** tidak ditemukan **caller managed** untuk kedua method ini di seluruh `dump.cs` (15.380 class), tidak ada referensi string di `stringliteral.json` (jadi bukan reflection by-name), dan tidak ada referensi di file scene. Keduanya **terimplementasi penuh tapi tidak terjangkau dari jalur panggilan mana pun yang bisa ditemukan di 8.4.2** — kemungkinan besar **kode legacy/dormant** (call site dicabut, atau dipanggil dari native plugin yang tidak terlihat). **JANGAN jadikan "tidak ada caller" sebagai alasan untuk aman:** kodenya hidup, terhubung ke analytics, dan update berikutnya bisa memasang kembali call site-nya. Ambang yang harus dipegang: **gems < 950.001** dan **APK resmi tidak direpack**.

**Implikasi untuk root injector (kabar baik):** injector root bekerja pada **APK resmi yang tidak diubah** — signature APK utuh → cek 101/102 lolos. Berbeda dengan mod APK repack (contoh: kasus Epic Conquest 2) yang pasti gagal cek ini.

### 4.3 Lapis 3 — Proteksi ekonomi & server

| Mekanisme | Bukti | Dampak |
|---|---|---|
| Mata uang `ObscuredInt` | `BankSaveSystem`: `earnedCoins`, `purchasedCoins`, `earnedGems`, `purchasedGems`, `earnedPearls`, `purchasedPearls`, `earnedEventCurrency`, `purchasedEventCurrency` — **semuanya `ObscuredInt`** (CodeStage, nilai terenkripsi di memori) | Edit memori mata uang = flag 105 |
| **Cap harian gems** | `PlayerProgress.gemCapData` (`DailyGemCapData.m_dailyGemCap`), `HasHitGemCap()` (0x1F6DD04), `AddToGemCap(int)` (0x1F6DE0C), `SetCurrentGemCap(int)`, `GetResetDateTime()` | Gems yang didapat per hari dibatasi — farming gems dibatasi di kode |
| Tracking per-sesi | `EventTrackerEarn.ProcessCurrencyEarned(bool, CurrencyType, int)`, `m_coinsEarnedThisSession`, `m_previousCoinsEarnedThisSession`, `m_otherCoinsEarnedThisSession`, `m_sessionCoinsSpent` / `m_sessionGemsSpent`, `sessionCoins` / `sessionGems`, `DebugField addSessionCoins/addSessionGems` | Mekanisme hidup untuk limit 201–204 (gems/coins/points/pearls per sesi) |
| Validasi IAP server-side | `FGOL.Billing.MonetisationCoreBridge` (35 method): `Init(Dictionary<string, PurchaseType> skus)`, `Purchase(string productId)`, `Verify(Transaction)` → **Houston** (`HoustonConfig`, `HoustonEnvironment`, `HoustonTransaction`, `ValidationResponseCallback`), `RestorePurchases()`, `GetProductIdForPurchasedIAPs()`, `CompleteTransactions()`; `IAPSaveSystem`, `TransactionsSave` | Receipt IAP diverifikasi ke server Ubisoft (Houston). Bypass IAP = flag 301. Produk: `FGOL.Billing.Product` (`m_productID`, `m_title`, `m_description`, `m_formattedPrice`, `m_currencyCode`) |
| Cloud save + komparator | `FGOL.Save.SaveGameManager` (31 method): `SaveToDisk()`, `Upload(User, callback)`, `SyncCloudSave(...)`, `CompareSaves(...)`, `ResolveConflict(...)`, `CorruptedSave(userID)`, `DeleteLocalSave(userID)`, `OverrideLocalSave(...)`; transport S3 (`FGOL.Server.S3AuthenticationV2/V4`, `S3Request`) | Save lokal bisa **ditimpa cloud** saat konflik; save korup bisa dihapus. Akun: `FGOLUsersLib.AuthManagerMono/Unity`, `CheckGameVersionResponse`, `GetServerTimeResponse`, `CloudCredentials` |
| Save terenkripsi | `FGOL.Encryption.AESEncryptor`: `Encrypt(byte[] key, byte[] iv, byte[] data)`, `Decrypt(...)`, `DecryptDecodeDeserialize(...)` | Edit file save langsung butuh kunci AES (tidak dikejar di run ini) |
| Leaderboard | `GooglePlayGames.PlayGamesLeaderboard.AddScore` (0x214DD44) | Skor sesi bisa terkirim ke leaderboard Play Games |

### 4.4 Yang TIDAK ada (sama pentingnya)

- **Tidak ada deteksi root** (RootBeer/SafetyNet/Play Integrity/Frida/Magisk/`/su`/Xposed) di dump.cs, metadata strings, `libil2cpp.so`, `libubiservices.so`, `libunity.so`. Satu-satunya hit "root" adalah `hasRoot_` = **RootObject** (manajemen memori C#, bukan deteksi root perangkat) dan `PathIsRooted` (System.Uri).
- **Tidak ada PairIP / packer / signature killer** di game ini (berbeda dengan mod APK Epic Conquest 2).
- **Tidak ada perintah cheat di debug console.** Console in-game (`IngameDebugConsole`) hanya punya perintah bawaan: `prefs.*`, `scene.load/loadasync/unload/restart`, `time.scale` (get/set). Tidak ada perintah god mode / tambah currency / unlock. (`DebugField addSessionCoins/addSessionGems` adalah enum field debug internal, bukan perintah console.)
- `CertificateHelper.getCertificateSignaturesSHA()` di DEX: **0 caller** (dormant). Play Integrity ter-bundle tapi **tidak dipanggil**.

---

## 5. Ekonomi game

### 5.1 Mata uang — `Bank.CurrencyType`

| Nilai | Mata uang |
|---|---|
| 0 | Coins |
| 1 | Gems |
| 2 | Pearls |
| 3 | EventCurrency |

### 5.2 API Bank (`Bank`, namespace global) — semua RVA terverifikasi

| Method | RVA | Keterangan |
|---|---|---|
| `AddCoins(int, bool premium)` | `0x1E6AAF0` | |
| `AddGems(int, bool premium)` | `0x1E6ABD0` | |
| `AddPearls(int, bool premium)` | `0x1E6ACB0` | |
| `AddEventCurrency(int, bool premium)` | `0x1E6AD90` | |
| `AddCurrency(CurrencyType, int, bool)` | `0x1E6AA90` | |
| `RemoveCoins / RemoveGems / RemovePearls / RemoveEventCurrency / RemoveCurrency` | `0x1E6B0FC` / `0x1E6B288` / `0x1E6B418` / `0x1E6B5A4` / `0x1E6AFF4` | |
| `GetCoins / GetGems / GetPearls / GetEventCurrency / GetBalance` | `0x1E60C38` / `0x1E60BAC` / `0x1E60CC4` / `0x1E6B730` / `0x1E6B7D8` | `GetGems()` dipakai `CheckSaveAndUpdateStatus` untuk ambang 950.001 |
| `SetCoins / SetGems / SetPearls / SetEventCurrency` | `0x1E6B8C8` / `0x1E6B8CC` / `0x1E6B8D0` / `0x1E6B8D4` | Setter langsung (dipakai sistem internal) |
| `Save()` | `0x1E6B7BC` | |
| `NotifyAndSave(bool, CurrencyType, bool)` | `0x1E6AE70` | Dipanggil tiap perubahan saldo |

**Peringatan:** method-method ini **secara teknis bisa dipanggil** lewat IL2CPP — penolakan fitur mata uang di §7 adalah keputusan **kebijakan + deteksi** (ObscuredInt + flag 104/105/201–204 + cap harian + cloud sync), bukan karena tidak bisa. Jangan jadikan keberadaan simbol ini sebagai pembenaran untuk membangun fitur mata uang.

### 5.3 IAP

Produk dibeli lewat `MonetisationCoreBridge` → `MonetisationCore` (native bridge) → verifikasi receipt ke **Houston** (server Ubisoft). Gems/coins juga dijual sebagai IAP (`purchasedCoins`/`purchasedGems` terpisah dari `earned*` di `BankSaveSystem`). Karena verifikasi di server, **tidak ada jalur client-side yang bisa membuat pembelian "gratis" tanpa ketahuan** (flag 301).

---

## 6. Fitur solo/offline yang FEASIBLE — dengan bukti simbol

Semua fitur di bawah ini **TERBUKTI dari simbol** (nama class/method/field + RVA + pola prologue). Pusatnya satu class: **`PlayerControlGenericFish`** (namespace global, base `PlayerControl`) — controller hiu pemain. Field kuncinya sudah dipetakan (offset lengkap di `hook_targets_8.4.2.yaml`).

### 6.1 God mode / nyawa tidak berkurang — ✅ TERBUKTI, prioritas 1

Bukti (class `PlayerControlGenericFish`):

| Simbol | RVA / offset | Peran |
|---|---|---|
| `m_invincible` | field `0x18B` | Flag invincible internal |
| `m_haltHealthDrain` | field `0x18C` | Hentikan health drain |
| `m_debugSetInvincible` | field `0x18D` | Flag debug invincible (game sendiri punya jalur ini!) |
| `SetInvincibleInternal(bool, bool)` | `0x1DC96E0` | Setter internal invincible |
| `SetInvincible(bool)` | `0x1DD0F78` | Setter publik |
| `SetInvincible(string key, float duration)` | `0x1DD0D70` | Invincible berdurasi (jalur buff) |
| `IsInvincible()` | `0x1DC99C8` | Getter |
| `SetHaltHealthDrain(bool)` | `0x1DD0F70` | Hentikan drain (pola unik, §8) |
| `InflictDamage(float, string, DamageType, ...)` | `0x1DCD738` | **Satu-satunya pintu damage masuk** (override). Hook → return = tidak ada damage |
| `InflictDrainDamage(float, float, string, DamageType)` | `0x1DCE2D8` | Damage drain (racun/drain) |
| `InflictBoostDamage(float)` | `0x1DCE5F0` | Damage dari boost |
| `UpdateHealth()` | `0x1DC830C` | Update health per frame |
| `GetModifiedDamageForCurrentHealth(float, bool)` | `0x1DC8148` | Modifikasi damage |
| `GetCurrentHealthDrain()` | `0x1DC5A9C` | Nilai drain saat ini (pola unik) |
| `m_healthDrainRate` / `m_healthDrainMultiplier` | field `0xEC` / `0x218` | Rate + multiplier drain |
| `MultiplyHealthDrain(float)` / `DivideHealthDrain(float)` | `0x1DC59D0` / `0x1DC59E0` | API multiplier drain |
| `SetInvincibleInternal` → `ComeBackToLife()` | `0x1DD0B34` | Resurrect |
| `EnterStateDie` / `UpdateStateDie` | `0x1DCFF44` / `0x1DD0368` | State mati (bila hook gagal, ini yang jalan) |

Pendukung:
- `HealthDrainModifier.SetMultiplier(float)` (`0x1E0CAC0`, pola unik) — set multiplier 0 = drain nol. Ada juga `SetValue` (`0x1E0B434`), `Activate`/`Deactivate`.
- `PlayerSharkInstance.get_healthDrainRate()` (`0x1DC7380`, pola unik) — hook getter → return 0 = tidak ada drain (jalur stat pipeline, paling bersih).
- `SharkHealthRegenerator` (field `healthRegenRate 0x20`, `healthRegenPreventsHealthDrain 0x2A`, `Update 0x1E0A7CC`) + `BuffHealthGain` — regen sebagai pelengkap.
- `DamageableBody.SetInvincibility(float)` (`0x1CE2B58`) — untuk entitas damageable lain (boss/cage), sekunder.
- `MachineShark` (base `MachineFish`): `OnCollisionEnter` (`0x1DA8C04`), `IsPressingBoost` (`0x1DAE484`), `get_isGoldRushActive` (`0x1DADCAC`).

**Desain yang disarankan:** hook `InflictDamage` → early return (seperti `MotorMover.Crash` di Traffic Rider) + set `m_haltHealthDrain = true` via `SetHaltHealthDrain(true)` sekali saat sesi mulai. Fail-closed: bila salah satu gagal, fitur mati (bukan setengah jalan).

### 6.2 Boost tidak habis — ✅ TERBUKTI, prioritas 1

| Simbol | RVA / offset | Peran |
|---|---|---|
| `m_boostUnlimited` | field `0x18E` | Flag boost unlimited internal |
| `m_debugSetBoostUnlimited` | field `0x18F` | Flag debug (game sendiri punya!) |
| `SetUnlimitedBoostInternal(bool, bool)` | `0x1DC99F8` | Setter internal (pola unik) |
| `SetUnlimitedBoost(string key, float duration)` | `0x1DD0E70` | Boost unlimited berdurasi (jalur buff) |
| `GetCurrentBoostDrain()` / `GetCurrentBoostDrainRaw()` | `0x1DC5B80` / `0x1DC5C20` | Nilai drain boost (pola unik) |
| `m_boostDrainRate` / `m_boostRegenRate` | field `0x13C` / `0x140` | Rate drain + regen |
| `set_boostDrainModifier(float)` | `0x1DC5998` | Setter modifier drain |
| `MultiplyAdditionalBoostDrainModifier` / `DivideAdditionalBoostDrainModifier` | `0x1DC59B0` / `0x1DC59C0` | API multiplier |
| `BuffUnlimitedBoost` (`OnStart 0x1CC1F20`, `OnFinish 0x1CC1F48`) | — | **Buff unlimited-boost LEGIT yang sudah ada di game** (sistem buff `BuffsController` di `PlayerControlGenericFish` field `0x98`) — fitur ini meniru mekanisme resmi game |
| `PlayerSharkInstance.get_sharkBoostDrainRate()` / `get_boostRegenTime()` | `0x1DD22AC` / `0x1DC74B4` | Stat pipeline |
| `UpdateBoost()` | `0x1DCE9EB4` | Update boost per frame |

**Desain yang disarankan:** panggil `SetUnlimitedBoostInternal(true, false)` sekali saat sesi mulai (atau hook `GetCurrentBoostDrain` → return 0). Keduanya lewat jalur resmi game — risiko deteksi paling rendah.

### 6.3 Damage multiplier — ✅ TERBUKTI

| Simbol | RVA / offset |
|---|---|
| `m_damageMultiplier` | field `0x228` |
| `get_damageMultiplier()` / `set_damageMultiplier(float)` | `0x1DC5A30` / `0x1DC5A38` |
| `m_bitePower` / `m_currentBitePower` / `m_bitePowerMultiplier` | field `0xE8` / `0x220` / `0x224` |
| `get_biteMultiplier()` / `set_biteMultiplier(float)` | `0x1DC5A10` / `0x1DC5A18` |
| `AddBiteStatBuff(string, float, float)` | `0x1DD0AE0` |
| `AddDamageReductionBuff(string, float, float)` | `0x1DD0B5C` (kebalikan — pengurang damage diterima) |
| `GetModifiedDamageForCurrentPets(...)` | `0x1DCDD38` |

### 6.4 Speed multiplier — ✅ TERBUKTI (bukan game speed!)

Ini **kecepatan hiu**, bukan `Time.timeScale` — jadi tidak menyentuh `SpeedHackDetector`.

| Simbol | RVA / offset |
|---|---|
| `m_baseSpeed` | field `0xD8` |
| `get_baseSpeed()` / `set_baseSpeed(float)` | `0x1DC5848` / `0x1DC5850` |
| `UpdateSpeed()` / `UpdateSpeedValue()` | `0x1DC8008` / `0x1DC75F4` |
| `AddSpeedStatBuff(string, float, float)` | `0x1DD09E8` |
| `SharkSpeedModifier.SetValue(float)` / `Activate()` / `Deactivate()` | `0x1E0B39C` / `0x1E0DDEC` / `0x1E0DE14` |
| `BoostSpeedModifier.Activate()` / `Deactivate()` | `0x1E461F0` / `0x1E46214` |
| `PlayerSharkInstance.get_speed()` / `get_boostSpeedScale()` | `0x1DD22A4` / `0x1DC73F4` |

### 6.5 Bite radius / makan lebih luas — ✅ TERBUKTI

| Simbol | RVA / offset |
|---|---|
| `m_biteRadius` / `m_biteRadiusFraction` | field `0x154` / `0xDC` |
| `SetBiteRadiusFraction(float)` | `0x1DC5A40` |
| `RefreshBiteRadiuses()` | `0x1DC5A48` |
| `SetCanEat(bool, bool)` | `0x1DCF31C` |
| `Eater` (mouth/bite/swallow/suction points, `SetGrabbed`, `Update_Managed 0x1CF4B9C`) | — |
| `BiteKill()` | `0x1DCA2CC` |
| `CheckStartBiteAttempt()` / `CheckAttackCollision()` | `0x1DCB31C` / `0x1DCCF50` |

### 6.6 Size multiplier — ✅ TERBUKTI

| Simbol | RVA / offset |
|---|---|
| `m_sizeMultiplier` / `m_size` | field `0x22C` / `0x230` |
| `get_sizeMultiplier()` / `set_sizeMultiplier(float)` | `0x1DC5C28` / `0x1DC5C30` |
| `AddSizeStatBuff(string, float, float)` | `0x1DD0AE0` |
| `UpdateSharkScale(bool)` | `0x1DC5C3C` |
| `PlayerSharkInstance.get_size()` | `0x1DD229C` |

### 6.7 Projectile immunity — ✅ TERBUKTI

| Simbol | RVA / offset |
|---|---|
| `projectileImmunity` | field `0x1D4` |
| `get_ProjectileImmunity()` / `set_ProjectileImmunity(bool)` | `0x1DC5D3C` / `0x1DC5D4C` |

### 6.8 Score multiplier — ✅ TERBUKTI, dengan caveat leaderboard

| Simbol | RVA |
|---|---|
| `GoldRushControllerOriginal.get_ScoreMultiplier()` | `0x1D4D034` (pola unik) |
| `GoldRushControllerTimed.get_ScoreMultiplier()` | `0x1D4F0F8` |
| `SessionDataManager.InitScoreMultiplierData(GameDB)` | `0x1D439D0` |
| `Explosive.SetScoreMultiplier(float)` | `0x1D245C8` |
| `Definitions.ScoreMultiplierData` (`m_ediblesRequired`, `m_multiplier`) | data-driven |
| `Definitions.ActiveFeatures.AccumulateScoreMultiplierDuringGoldRush()` / `...MegaGoldRush()` | `0x20F0FC0` / `0x20F1070` |
| `MachineShark.get_isGoldRushActive()` / `GoldRushStart()` / `GoldRushEnd()` | `0x1DADCAC` / `0x1DAE9D0` / `0x1DAE9DC` |

**Caveat:** skor sesi dikirim ke **Google Play Games leaderboard** (`PlayGamesLeaderboard.AddScore`). Fitur ini aman dipakai offline / saat tidak login Play Games; skor hasil mod yang tersubmit ke leaderboard berisiko ditandai dari sisi server. Disarankan: fitur score multiplier **default OFF** + peringatan di UI, atau nonaktifkan pengiriman leaderboard saat aktif (bila memungkinkan tanpa menyentuh kode leaderboard secara destruktif — perlu verifikasi dinamis).

### 6.9 Yang masih PERKIRAAN (belum terbukti cukup untuk dibangun)

| Kandidat | Status |
|---|---|
| **Gold Rush paksa aktif** | `GoldRushStart/End` ada, tapi logika pemicu gold rush (kondisi, durasi, reward) belum ditelusuri. Perlu uji dinamis. Jangan jadikan fitur v1. |
| **Unlock semua hiu** | Simbol ada (`SharkItemDataManager.IsSharkOwned 0x205F210`, `GetPurchasedSharks 0x205F090`, `PlayerProgress.CreateSharkProgress 0x1F6A254` / `SetSharkProgress 0x1F6A2B8`, `SharkProgress` + `SharkProgressSaveSystem`). Tapi status kepemilikan = **purchase state** yang tersinkronisasi ke cloud save dan terkait IAP — lihat §7. **Bukan fitur v1; butuh verifikasi dinamis + keputusan user.** |
| **Max level hiu yang SUDAH dimiliki** | `SharkProgress`: `speedLevel 0x20`, `biteLevel 0x24`, `boostLevel 0x28`, `currentLevel 0x2C`, `growthValue 0x34`, `gachaPoints 0x54` + semua setter. Secara teknis bisa, tapi level/upgrade juga terkait pembelian (coins/gems) dan tersimpan di cloud — **tahan dulu, verifikasi dinamis sebelum diputuskan.** |
| **Teleport / posisi** | Tidak ditemukan simbol teleport pemain yang jelas di run ini (`get_canTeleport` ada tapi override abstrak). Bukan fitur v1. |

---

## 7. Fitur yang DITOLAK

| Fitur | Alasan (dengan bukti) |
|---|---|
| **Gold / gems / pearls / event currency unlimited, tambah mata uang** (`Bank.AddCoins/AddGems/AddPearls/SetGems`, dsb.) | Simbol ADA dan bisa dipanggil, tapi: (1) semua saldo disimpan sebagai `ObscuredInt` → edit/panggil di luar jalur normal berisiko flag **105** (`ObscuredCheatingDetector`); (2) `GameValidator` flag **104** bila gems ≥ **950.001** (disassembly); (3) **cap harian gems** (`PlayerProgress.HasHitGemCap`); (4) limit per-sesi **201–204** (tracking hidup di `EventTrackerEarn`); (5) saldo tersinkronisasi cloud save (komparator bisa menimpa/menandai). |
| **IAP gratis / unlock pembelian / restore palsu** | Receipt diverifikasi server **Houston** (`MonetisationCoreBridge.Verify`) → flag **301** (`PirateForFailedIAPValidation`). Tidak ada jalur client-side. |
| **Game speed / `Time.timeScale`** | `SpeedHackDetector` hidup (interval + maxFalsePositives + coolDown) → flag **106**. Perintah console `time.scale` ada, tapi detektor mengawasinya. |
| **Unlock hiu berbayar / special shark** | Kepemilikan = purchase state (`IsSharkOwned`, `GetPurchasedSharks`, `GetIsSharkSpecial`); terkait IAP + cloud save. Sama dengan membeli item berbayar. |
| **Edit memori mentah nilai `ObscuredInt`** | Langsung memicu `ObscuredCheatingDetector` → flag **105** → laporan analytics. |
| **ESP / wallhack** | `WallHackDetector` ada; game ini arcade single-player — tidak ada kebutuhan, dan terdeteksi by design. |
| **Manipulasi skor leaderboard Play Games** | Skor tersubmit ke `PlayGamesLeaderboard.AddScore`; manipulasi skor untuk leaderboard = risiko sisi server. (Score multiplier lokal saat offline — lihat §6.8 — beda hal.) |
| **Matikan / bypass detektor anti-cheat** | Anti-cheat evasion — di luar scope. Fitur harus hidup DI BAWAH trip wire, bukan mematikan alarm. |
| **Repack / mod APK** | Signature check `GameValidator` (flag **101/102**) memang dirancang untuk ini. Injector root pada APK resmi adalah jalurnya. |

---

## 8. Rancangan tahan-update ala Traffic Rider

Kerangka acuan: `~/workspace/hozin-trafficrider-v13/app/src/main/cpp/payload/` — `il2cpp_resolve.h/.cpp` (resolver nama), `patterns.h` (pola 32 byte), `payload.cpp`, `payload_probe.cpp`. Aturan yang terbukti di sana berlaku 1:1 di sini.

### 8.1 Prinsip 1 — Resolve via nama IL2CPP (jalur utama)

Nama method/field managed **stabil antar update**; hanya alamat native yang pindah. Urutan resolver (sudah terbukti di Traffic Rider v2.0+):

```
il2cpp_domain_get
  → il2cpp_domain_get_assemblies
  → il2cpp_assembly_get_image
  → il2cpp_class_from_name(image, namespace, klass)
  → il2cpp_class_get_method_from_name(klass, name, argCount)
  → MethodInfo->methodPointer   (field pertama MethodInfo, offset 0)
Field: il2cpp_class_get_field_from_name → il2cpp_field_get_offset
```

Semua export yang dibutuhkan **ada** di `libil2cpp.so` 8.4.2 (241 export `il2cpp_*`). Catatan HSW: mayoritas class gameplay ada di **namespace global** (`ns=""`): `PlayerControlGenericFish`, `Bank`, `MachineShark`, `PlayerSharkInstance`, `HealthDrainModifier`, `GoldRushControllerOriginal`, `AntiCheatManager`. Class framework memakai namespace: `FGOL.GameValidation.GameValidator`, `FGOL.Billing.*`, `FGOL.Save.*`, `CodeStage.AntiCheat.Detectors.*`.

Panggil resolver **hanya setelah `il2cpp_thread_attach`** dan setelah domain siap (`il2cpp_ready()`); bila domain belum siap → retry sebentar, lalu fallback ke pola. Panggilan Unity hanya dari main thread (hook `UpdateHealth` / `FixedUpdate_Managed` — `PlayerControlGenericFish.FixedUpdate_Managed` RVA `0x1DCA260`, `MachineShark.Update_Managed` `0x1DA89B0`).

### 8.2 Prinsip 2 — Pattern-scan 32 byte (fallback), JANGAN base+RVA

Pelajaran Traffic Rider v1.1 (terbukti di perangkat): hash `libil2cpp.so` di perangkat **persis sama** dengan file REA, tapi ketiga prologue gagal bersamaan pada `base + RVA` — aritmetika base+RVA **salah secara sistematis** di perangkat. Aturan:

- Scan **mapping executable (r-xp) `libil2cpp.so` di memori** (`/proc/self/maps`), bukan file.
- Pola **32 byte** (16 byte TIDAK unik — di HSW ini, 16 byte pertama prologue muncul hingga **2.836x** di file; 32 byte unik untuk 17 dari 18 target).
- File offset untuk verifikasi offline = **RVA − 0x4000** (delta segmen LOAD#2; terverifikasi dengan disassembly).
- **Verifikasi keunikan per target per versi** — hitung kemunculan di segmen RX sebelum menerima pola.

Pola terverifikasi untuk 8.4.2 ada di **`dump/il2cpp/hook_targets_8.4.2.yaml`** (18 target). Ringkasnya:

| Target | RVA | 32-byte unik? |
|---|---|---|
| `PlayerControlGenericFish.SetInvincibleInternal` | `0x1DC96E0` | ✅ 1 |
| `PlayerControlGenericFish.SetUnlimitedBoostInternal` | `0x1DC99F8` | ✅ 1 |
| `PlayerControlGenericFish.InflictDamage` | `0x1DCD738` | ⚠️ **3** — butuh pola 48 byte / resolve nama |
| `PlayerControlGenericFish.UpdateHealth` | `0x1DC830C` | ✅ 1 |
| `PlayerControlGenericFish.GetCurrentHealthDrain` | `0x1DC5A9C` | ✅ 1 |
| `PlayerControlGenericFish.GetCurrentBoostDrain` | `0x1DC5B80` | ✅ 1 |
| `PlayerControlGenericFish.SetHaltHealthDrain` | `0x1DD0F70` | ✅ 1 |
| `Bank.AddCoins` / `Bank.AddGems` | `0x1E6AAF0` / `0x1E6ABD0` | ✅ 1 (audit saja — fitur DITOLAK) |
| `Bank.GetGems` | `0x1E60BAC` | ✅ 1 |
| `HealthDrainModifier.SetMultiplier` | `0x1E0CAC0` | ✅ 1 |
| `GoldRushControllerOriginal.get_ScoreMultiplier` | `0x1D4D034` | ✅ 1 |
| `GameValidator.CheckSaveAndUpdateStatus` | `0x21C4C88` | ✅ 1 (JANGAN SENTUH) |
| `GameValidator.StartBuildValidation` | `0x21C498C` | ✅ 1 (JANGAN SENTUH) |
| `SpeedHackDetector.Update` | `0x22B3F70` | ✅ 1 (JANGAN SENTUH) |
| `AntiCheatManager.OnMemoryHackAttempt` | `0x1E67234` | ✅ 1 (JANGAN SENTUH) |
| `PlayerSharkInstance.get_healthDrainRate` | `0x1DC7380` | ✅ 1 |
| `PlayerSharkInstance.get_maxHealth` | `0x1DD228C` | ❌ **11** — getter trivial, **WAJIB resolve nama** |

### 8.3 Prinsip 3 — Fail-closed + status JSON

- Tiap hook: resolve nama → bila gagal, scan pola → bila gagal / tidak unik, **hook TIDAK dipasang** dan status ditulis `gagal` (bukan ditebak).
- Status JSON runtime: alamat hasil resolve/scan, metode yang dipakai (nama vs pola), `versionCode` + BuildID `libil2cpp.so` yang ditemukan.
- **Version gate:** injector menolak aktif bila `versionCode != 842` (atau bila BuildID `libil2cpp.so` tidak cocok dengan yang dikenal) — tampilkan status, jangan hook buta.
- Satu global `orig` per hook (pelajaran injector sebelumnya). Hook ≤4 byte tidak ada di daftar ini (semua target adalah fungsi penuh).
- Instance `PlayerControlGenericFish`: dapatkan via `Object.FindObjectsOfType` (butuh `Il2CppType*` dari `il2cpp_class_get_type_obj`) atau dari field `m_machineFish` — verifikasi dinamis saat build.

### 8.4 Checklist tiap update game (wajib sebelum rilis ulang)

1. Unduh XAPK versi baru → catat versionCode + SHA + BuildID `libil2cpp.so`.
2. Dump ulang metadata (Il2CppDumper v39+; bila metadata naik versi, cari fork yang mendukung).
3. Verifikasi nama class/method/field di `dump.cs` baru masih ada (terutama `PlayerControlGenericFish`, `Bank`, `GoldRushControllerOriginal`).
4. Ekstrak ulang prologue 32 byte tiap target (file offset = RVA − 0x4000) + hitung keunikan di segmen RX; perbarui `hook_targets_<versi>.yaml`.
5. **Disassembly ulang `GameValidator.StartBuildValidation` + `CheckSaveAndUpdateStatus`** — cek apakah call site baru muncul, apakah ambang 950.001 berubah, apakah ada flag baru di enum.
6. Cek `DailyGemCapData` + `Bank.CurrencyType` + `MonetisationCoreBridge` (apakah Houston berubah).
7. Cek detektor ACTk (apakah ada detektor baru, mis. `TimeScaleDetector` / `MemoryHackDetector` terpisah).
8. Bila satu target hilang/berubah → fitur itu **nonaktif (fail-closed)** di versi itu, bukan diakali dengan offset lama.

---

## 9. Risiko — jujur

| Risiko | Bukti | Penilaian |
|---|---|---|
| **Flag anti-cheat → laporan ke Ubisoft** | `OnMemoryHackAttempt` menulis flag 105 + memanggil `HSXAnalyticsManager.HackerDetected`; `CheckSaveAndUpdateStatus` menulis flag 104 + laporan yang sama. Flag tersimpan di record validasi + dilaporkan via analytics. | **Risiko utama.** Konsekuensi persis di sisi server (peringatan / reset progres / ban akun Ubisoft) **tidak bisa dilihat dari client** — tidak ada layar ban di kode yang ditelusuri. Asumsikan akun bisa ditandai. Mitigasi: main di akun sekunder / offline, jangan sentuh mata uang, jangan sentuh timeScale, jangan inject assembly managed. |
| **Flag 101/102 (signature)** | `StartBuildValidation` membandingkan 4 signature resmi. | **Rendah untuk root injector** — APK resmi tidak diubah. Tinggi bila ada yang nekat repack. |
| **Flag 104 (gems ≥ 950.001)** | Disassembly `CheckSaveAndUpdateStatus`. | **Nol bila fitur mata uang tidak dibangun.** |
| **Flag 105 (memory hack)** | `ObscuredCheatingDetector` + `OnMemoryHackAttempt`. | **Rendah bila desain dipatuhi** (tidak ada edit memori `ObscuredInt`, tidak ada assembly managed). |
| **Flag 106 (speed hack)** | `SpeedHackDetector`. | **Nol bila game speed tidak dibangun.** Speed hiu (bukan timeScale) tidak menyentuh detektor ini. |
| **Flag 201–204 (limit per sesi)** | Tracking hidup di `EventTrackerEarn` + `Bank`. | **Nol bila mata uang tidak disentuh.** |
| **Flag 301 (IAP)** | Verifikasi Houston server-side. | **Nol bila IAP tidak disentuh.** |
| **Save korup / progres hilang** | `SaveGameManager.CorruptedSave` / `DeleteLocalSave`; save AES-encrypted; konflik cloud vs lokal (`CompareSaves` / `ResolveConflict` / `OverrideLocalSave`). | **Sedang.** Injector tidak menyentuh file save, tapi bila flag validasi memicu sesuatu di sisi save (belum ditelusuri sampai ke `SaveGameManager`), progres bisa terdampak. Mitigasi: backup save lokal sebelum tes; tes di akun sekunder. |
| **Cloud save menimpa progres lokal** | `SyncCloudSave` + komparator. | **Sedang.** Bila progres hasil mod tersimpan lalu cloud menganggapnya tidak valid / konflik, bisa revert. Tes dengan sinkronisasi cloud dimatikan dulu bila memungkinkan. |
| **Update game merusak injector** | Setiap update memindahkan RVA + bisa mengubah nama/field. | **Diharapkan terjadi.** Desain §8 (resolver + version gate + fail-closed) dibuat untuk ini. Injector lama di game baru = **tidak aktif**, bukan crash. |
| **Leaderboard Play Games** | `PlayGamesLeaderboard.AddScore`. | **Rendah–sedang.** Skor hasil mod (terutama score multiplier) bisa terkirim. Mitigasi: main offline / logout Play Games saat tes; score multiplier default OFF. |
| **Tidak ada deteksi root** | Tidak ada string/kelas deteksi root di seluruh binary. | **Rendah (per 8.4.2).** Root di perangkat user tidak terdeteksi game ini. Tetap waspada: update bisa menambahkannya; checklist §8.4 mencakup pengecekan ini tiap update. |
| **Crash game** | Hook di fungsi yang salah (pola tidak unik) = crash. | **Rendah bila pola 32 byte + verifikasi keunikan dipatuhi.** `InflictDamage` (uniq 3) dan `get_maxHealth` (uniq 11) adalah jebakan yang sudah ditandai — jangan di-hook via pola. |

**Catatan game ini:** single-player arcade dengan elemen online (event harian, IAP, cloud save, leaderboard, analytics). Semua fitur yang diusulkan di §6 bekerja **di dalam sesi solo** dan tidak menyentuh pemain lain — tidak ada PvP, tidak ada mode kompetitif real-time. Risiko utamanya adalah **akun** (flag analytics Ubisoft), bukan pemain lain.

---

## 10. Langkah berikut yang diusulkan

1. **Keputusan user (perlu jawaban):** setujui paket fitur v1 — god mode + boost tidak habis + damage multiplier + speed hiu + bite radius (+ score multiplier default OFF). Tanpa persetujuan ini, jangan bangun injector.
2. **Verifikasi dinamis (sebelum build penuh):** di POCO (rooted), konfirmasi instance `PlayerControlGenericFish` bisa ditemukan saat gameplay (`FindObjectsOfType`), satu hook percobaan (`GetCurrentHealthDrain` → 0) + pantau 1 sesi penuh tanpa flag yang terlihat (tidak ada crash, tidak ada popup validasi). Pakai akun sekunder + cloud sync dimatikan untuk tes pertama.
3. **Build injector** (tugas terpisah, atas perintah eksplisit): root inject `.so` mengikuti kerangka Traffic Rider — resolver nama IL2CPP (`il2cpp_resolve.h`), pola 32 byte (`patterns.h`), fail-closed + status JSON, version gate 842, tanpa assembly managed, tanpa sentuh detektor/validator/mata uang/timeScale.
4. **JANGAN dibangun:** mata uang, IAP, game speed, unlock hiu berbayar, ESP, bypass detektor, repack APK.
5. **Perawatan:** tiap update game → jalankan checklist §8.4; perbarui `hook_targets_<versi>.yaml` + laporan ini.

---

## 11. Batasan audit ini (jujur)

- **Statis saja.** APK tidak pernah diinstall/dijalankan; tidak ada analisis dinamis (Frida/logcat/gameplay). Semua klaim "aktif" untuk detektor didasarkan pada keberadaan kode + wiring callback, bukan observasi runtime. Penempatan detektor di scene tidak terverifikasi statis.
- **`GameValidator` tanpa caller.** Kedua method terimplementasi penuh (disassembly), tapi tidak ada jalur panggilan yang ditemukan. Status "dormant/legacy" adalah inferensi terbaik dari bukti yang ada, bukan kepastian. Perlakukan ambangnya sebagai hidup.
- **Nilai `DailyGemCapData.m_dailyGemCap`** tidak diekstrak (data-driven dari GameDB, bukan konstanta kode).
- **Konsekuensi flag di sisi server tidak diketahui** (peringatan/ban/reset) — tidak ada di client.
- **Kunci AES save tidak dicari** — di luar kebutuhan audit ini.
- **Scene/asset tidak diurai penuh** (aset hash-named; hanya diperiksa keberadaan string detektor/validator — tidak ditemukan di file scene).
- Parser `classes_index.json` mencakup 13.662 dari 15.380 type definitions (nested/compiler-generated tertentu tidak terparse — tidak memengaruhi temuan, karena semua class kunci terparse lengkap).

---

## Lampiran — file deliverable

- Laporan ini: `~/workspace/rea-hungry-shark-world/REA-HUNGRY-SHARK-WORLD.md`
- XAPK: `~/workspace/rea-hungry-shark-world/HungrySharkWorld-8.4.2.xapk`
- Dump: `~/workspace/rea-hungry-shark-world/dump/` (base, config, dex, il2cpp, xapk, metadata_strings.txt)
- Inventaris class terparse: `~/workspace/rea-hungry-shark-world/dump/il2cpp/classes_index.json`
- Target hook + pola: `~/workspace/rea-hungry-shark-world/dump/il2cpp/hook_targets_8.4.2.yaml`
