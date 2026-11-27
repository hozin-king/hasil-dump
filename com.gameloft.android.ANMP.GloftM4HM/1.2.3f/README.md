# Modern Combat 4: Zero Hour — v1.2.3f — REA + Audit Cheat

REA statis saja (tidak pernah install / tidak pernah jalankan APK).
Tanggal REA: 27 Nov 2026. Sumber APK: apkvision.org
(download page `games/action/modern-combat-4-zero-hour-3190/download/v1.2.3f-apk`,
file langsung `dl.apkvision.org/modern-combat-4-zero-hour/Modern-Combat-4-v1.2.3f-APKVISION.apk`).

## 0. Identitas APK

| Field | Nilai |
|---|---|
| Package | `com.gameloft.android.ANMP.GloftM4HM` |
| versionName / versionCode | `1.2.3f` / `12330` |
| minSdk / targetSdk | 29 / 35 |
| Ukuran APK | 1.296.856.042 byte (~1,21 GiB) |
| SHA-256 APK | `bd6a9819e9e807e960118f9b6d4809d6773623705870d5bee52875b9f805f03b` |
| Magic | ZIP (`PK\x03\x04`), `file` = Android package (APK), with AndroidManifest.xml |
| Penanda tangan | **APKVISION.ORG (self-signed, CN=APKVISION.ORG)** — lihat bawah |
| Skema tanda tangan | APK Signature Scheme v2 + v3 |
| Permission | INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, WAKE_LOCK (hanya 4; tanpa storage, tanpa billing) |
| Activities (3) | `com.apkvision.mc4av.SetupActivity` (main), `com.gameloft.android.ANMP.GloftM4HM.MC4`, `...MyVideoView` |
| Services / Receivers | tidak ada |
| DEX | 3 file: classes.dex 73.272 B (41 kelas), classes2.dex 69.848 B (19 kelas, `io.avm.r7.*`), classes3.dex 7.376 B (3 kelas, `org.apkvision.mc4.*`) |

## 1. PERINGATAN: ini REPACK APKVision, bukan APK asli Gameloft

Bukti (semua dari analisis statis):

- Main activity = `com.apkvision.mc4av.SetupActivity` — installer APKVision.
  Method-nya: `extract(File)`, `hasBundledData()`, `startGame()`. Tugasnya
  mengekstrak OBB dari `assets/gamedata.zip` ke folder OBB perangkat.
- Tanda tangan APK = sertifikat self-signed `APKVISION.ORG`, bukan Gameloft.
- DEX berisi kode APKVision: `com.apkvision.mc4av.*` (SetupActivity, Gamepad,
  Signature — overlay gambar), `org.apkvision.mc4.*` (Entry, SetupUi), dan
  `io.avm.r7.*` (19 kelas obfuscated, runtime translator — lihat §3).
- `Gamepad` (APKVision) menambah dukungan kontroler/gamepad yang tidak ada
  di rilis asli.
- Repo ini tetap memakai package + version asli Gameloft karena itulah
  identitas gamenya; yang direpack adalah pembungkus + cara jalan di HP
  64-bit (lihat §3).

## 2. Engine

- **Bukan Unity, bukan Unreal.** Engine proprietary Gameloft ("glitch"
  engine — namespace `glitch::` di semua simbol C++), render Collada,
  fisika **Havok** (`hkpRigidBody`, `hkpEntity`, `hkcdTreeQueries`),
  UI **Scaleform GFx** (`gameswf`, file `.swf` di string: `menu_multiplayer_new.swf`,
  `mainmenu_new.swf`), audio OpenSL ES, jaringan libcurl + OpenSSL.
- Data game (2 GB) ada di OBB di dalam `assets/gamedata.zip`:
  `main.1100...obb` (2.052.015.324 B, 24 Jun 2019) + `patch.12222...obb`
  (15.093.838 B, 24 Jun 2019). Isi main OBB: 5 video briefing + subtitle
  11 bahasa, `TP_Transitions.trans`, `oconf.bar`, dan 6 pack data
  (`data_1` 518 MB … `data_6` 129 MB) yang masing-masing ternyata
  **arsip ZIP bersarang** dengan entri bernama angka (`29`, `26`, `13`, …).
  Patch OBB berisi `data_2/4/5/6` versi 4 Mei 2016.
- `assets/eventParameters.json`: definisi event analitik (Campaign Mission
  Finished/Interrupted/Skipped — accuracy, kills, headshots, xp_level, …).
- Java layer sangat tipis (41 kelas): JNI bridge `GL2JNILib`/`GL2JNIActivity`,
  `MC4`, `MyVideoView`, `GLSocialLib` (Facebook/GameAPI), `InAppBilling`
  (IAB Gameloft sendiri — bukan Google Play Billing), `GDRMPolicy` /
  `GameInstaller` (DRM/lisensi Gameloft), `SendInfo` (fingerprint perangkat:
  GLDID/GLUID, MAC, carrier, model).

## 3. Native libs — dan translator ARM32→ARM64

Hanya `lib/arm64-v8a/` (64-bit saja, tanpa armeabi-v7a):

| File | Ukuran | Mesin | Keterangan |
|---|---|---|---|
| `libModernCombat4.so` | 5.161.332 B | AArch64 | JNI bridge (GLES/EGL/OpenSLES/`libandroid`). Ekspor ~60 fungsi `Java_*` (GL2JNILib, MC4, GDRMPolicy, IAB, Social). Juga memuat string runtime translator (Italia — lihat bawah). |
| `libModernCombat4aot.so` | 105.536.968 B | AArch64 | **Hasil terjemahan AOT dari kode ARM32.** Hanya butuh `libdl`+`libc`. Ekspor cuma 8 fungsi: `aot_init`, `aot_entry`, `aot_function`, `aot_function_count`, `aot_function_thumb`, `aot_hook_point`, `aot_hook_point_count`, `aot_route_to_runtime`. Dibangun dengan Android clang 21.0.0 (+pgo +bolt +lto +mlgo). |
| `libModernCombat4arm32.so` | 24.855.648 B | **ARM (32-bit)** | **Engine game asli 32-bit.** SONAME aneh: `libAndroid.so`. Simbol C++ lengkap, TIDAK di-strip: **34.328 fungsi GLOBAL**. Inilah tempat semua logika game (health, damage, aim, multiplayer). |

Cara kerjanya (terbukti dari string di `libModernCombat4.so`):

- `un ELF ARM32` / `una libreria ARM32, la apre il dlopen del guest`
  ("sebuah library ARM32, dibuka oleh dlopen si guest")
- `Modern Combat 4: avvio del motore ARM32` ("memulai engine ARM32")
- ` %s%x JIT=%llx AOT=%llx;` — statistik JIT vs AOT
- File debug: `/sdcard/Android/data/.../files/aot_jit.txt`, `aot_skip.txt`
- Simbol translator: `aot::checker_svc`, `Cpu::run_nested`, `Cpu::load_state`,
  `AotCtx`, `aot_route_to_runtime`.

Artinya: engine 32-bit asli dijalankan di bawah **translator AOT/JIT**
(oleh APKVision — runtime `io.avm.r7.*` di DEX). Kode yang benar-benar
dieksekusi adalah hasil terjemahan di `libModernCombat4aot.so`, BUKAN
`libModernCombat4arm32.so` secara langsung. Konsekuensi untuk cheat:
alamat fungsi ARM32 yang tercantum di §7 adalah alamat *guest* — hooking
harus lewat `aot_hook_point` / tabel fungsi AOT, bukan patch byte mentah
di file `.so` ARM32 (patch itu tidak akan dieksekusi).

## 4. Proteksi — praktis TIDAK ADA

- **Tidak ada deteksi root / emulator / Magisk / Xposed / Frida.**
  Grep string di ketiga `.so` + semua string DEX: nihil (satu-satunya
  "root" adalah node scene Collada `CRootSceneNode`).
- **Tidak ada SafetyNet / Play Integrity / attestation.** Nihil di DEX
  maupun native.
- **Tidak ada cert pinning.** Semua endpoint game pakai **HTTP polos**
  (bukan HTTPS). OpenSSL hanya dipakai sebagai library umum (libcurl).
- **String tidak dienkripsi, simbol tidak di-strip.** 34.328 nama fungsi
  C++ mangled lengkap di `libModernCombat4arm32.so`, termasuk nama fungsi
  cheat (lihat §6–§7). `strings-*.txt` di dump ini adalah dump penuh.
- **DRM yang ada:** `GDRMPolicy` (Gameloft DRM — `nativeAllow(long)`,
  `processServer`, `setConst`/`setTime`) + lisensi installer
  (`GameInstaller.getPublicKey`, `initNative`). DRM ini soal lisensi
  pembelian, bukan anti-cheat gameplay.
- **IAP:** IAB Gameloft sendiri via IGP (`201205igp.gameloft.com`),
  bukan Play Billing (tidak ada permission billing).

## 5. Jaringan & multiplayer — arsitektur dan status

### 5.1 Endpoint (dari kode + `oconf.bar` di OBB)

`oconf.bar` (plaintext, dari main OBB):

```
XPlayerURL: http://gllive.gameloft.com/ope/GenericXPlayer_v1.php
GGI: 52283
XPPHPVerNo: 4
ChatServer: gllive.gameloft.com
ChatDomian: gllive.gameloft.com
ChatRoomDomian: conference.gllive.gameloft.com
GameVer: 1.1.0
GAME_PARAM_COUNT: 1
```

Endpoint lain di `libModernCombat4arm32.so`:

- `http://gllive.gameloft.com/ope/ServerConfig.php` — config server multiplayer
- `http://201205igp.gameloft.com/redir/` — IGP (pembelian / redirect layanan)
- `http://www.modern-combat.net/player.php`, `.../board.php` — profil & leaderboard
- `https://api.vk.com/...`, `http://api.vk.com/oauth/...` — integrasi VK
- `http://www.facebook.com/ModernCombat`, `https://twitter.com/gameloft`
- `nativeLoginToMultiplayerUseGPGS` — login multiplayer via Google Play Games

### 5.2 Arsitektur multiplayer: P2P, host = server

- `WorldSynchronizer`: `IsServer()`, `_IsMatchHost()`, `IsHostAlone()`,
  `SendWorldState()`, `SendMatchState()`, `GetNetworkGameObject()`,
  `SpawnNetworkObject()`, `GetHostPlayerNameWIFIONLY()`.
- `federation::RoomCore / Lobby / Matchmaker / Storage / Service` —
  lobby + matchmaking + pembuatan room (federation = layanan Gameloft LIVE).
- Ada sistem **report pemain** (`WorldSynchronizer::SendReportPlayer`,
  `EncodeReportPlayer` / `DecodeReportPlayer`, `reportPlayer` di UI
  Scaleform) — pemain bisa melaporkan cheater ke pemain lain. Tidak ada
  sistem anti-cheat otomatis (tanpa FairFight dkk).
- Modelnya: **host adalah server**. Pemain yang membuat match men-host
  gamenya di perangkatnya sendiri; pemain lain terhubung langsung ke host.
  Matchmaking/lobby saja yang lewat server Gameloft (GLLive). Gameplay
  (posisi, health, damage) dihitung di perangkat masing-masing lalu
  disinkronkan — tidak ada otoritas server atas nilai gameplay.

### 5.3 Status multiplayer: MATI (server Gameloft sudah dimatikan)

- Game dihapus dari Google Play **30 Sep 2023** (AppBrain).
- Sumber publik: "the online multiplayer is dead. Gameloft shut the servers
  off, so the PvP the game once had no longer connects" (apk-store.org);
  "Multiplayer online services are no longer reliably available" (zmamobile).
- Bukti arsitektural: proyek komunitas **ModernCombat4Revived**
  (github.com/RedMemories/ModernCombat4Revived) menghidupkan lagi
  multiplayer dengan **mengganti meeting point Gameloft dengan DHT
  BitTorrent** — "There are no servers and no accounts. The player who
  creates a match hosts it on their own device… Players find each other
  through the public BitTorrent network (DHT), then connect directly to
  each other." Kalau server Gameloft masih hidup, penggantian ini tidak
  diperlukan.
- Catatan: DNS di VM REA tidak bisa dipakai sebagai bukti (egress proxy
  mengembalikan IP intercept untuk semua host).
- **Yang masih jalan:** campaign single-player penuh secara offline, dan
  multiplayer **lokal via Wi-Fi/LAN** (host di perangkat sendiri — mode
  ini tidak butuh server Gameloft sama sekali).

## 6. TEMUAN KUNCI: cheat bawaan game (debug switch)

Game ini punya **menu cheat bawaan** yang dikunci lewat satu system property.

Java `MC4.allowCheats()` (bytecode terbaca penuh via androguard):

```java
// pseudocode dari bytecode
boolean allowCheats() {
    try {
        return "1".equals(
            Class.forName("android.os.SystemProperties")
                 .getMethod("get", String.class)
                 .invoke(null, "debug.mc4.cheats"));
    } catch (Exception e) { return false; }
}
```

Jadi: **`setprop debug.mc4.cheats 1`** (butuh root — di HP root via
`setprop`/`resetprop`, atau `adb shell setprop` di build yang mengizinkan)
→ cheat diizinkan. Native-nya:

- `AndroidAllowCheats()` — `libModernCombat4arm32.so` @ `0x004d4f3c`
  (disassembly terverifikasi: membaca flag konfigurasi lalu return 0/1).
- `askForCheats(...)` — `0x0076e5a0`, 10.396 byte — logika menu cheat di
  UI Scaleform (`gameswf`).
- String `GodMode` polos ada di `.so` (kemungkinan label menu / kunci setting).

Ini jalur cheat termudah: bukan patch memori, melainkan **mengaktifkan
fitur yang memang sudah ada di dalam game**.

## 7. Fungsi kunci gameplay (alamat ARM32 guest di libModernCombat4arm32.so)

| Fungsi | Alamat | Ukuran | Keterangan |
|---|---|---|---|
| `AndroidAllowCheats()` | `0x004d4f3c` | 92 B | gerbang cheat (lihat §6) |
| `askForCheats(...)` | `0x0076e5a0` | 10.396 B | menu cheat Scaleform |
| `GameSettings::SetGodMode(bool)` | `0x0089e96c` | 84 B | nyalakan god mode |
| `GameSettings::IsInGodMode()` | `0x0089d3b0` | 112 B | cek god mode |
| `GameSettings::ToggleAutoAim()` | `0x0089fcc4` | 20 B | toggle auto-aim |
| `GameSettings::ToggleAutoAimGrenade()` | `0x0089fde8` | 20 B | toggle auto-aim granat |
| `Hud::UpdateAutoAim(int)` | — (simbol ada) | — | logika bidik otomatis per frame |
| `Hud::InAutoAimMode()` | — | — | status auto-aim |
| `Character::GetClosestEnemy(bool)` | `0x006cf244` | 320 B | musuh terdekat |
| `Character::GetVisibleEnemy(int)` | `0x006cf20c` | 40 B | musuh yang terlihat |
| `Character::IsEnemyCharacter()` | — | — | cek apakah karakter = musuh |
| `Character::SetHealthPoints(float)` | `0x006cd454` | 52 B | set HP |
| `Character::GetMaxHealthPoints(bool)` | `0x006df7f8` | 336 B | baca max HP |
| `Character::SetMaxHealthPoints(int)` | `0x006cd488` | 8 B | set max HP |
| `Character::DamageHealth(...)` | `0x006ef258` | 6.544 B | terima damage |
| `Character::DamageAllHealth(...)` | `0x006f0be8` | 44 B | damage ke semua HP |
| `Gameplay::RefillHealth(int&)` | `0x005a833c` | 192 B | isi ulang HP |
| `PlayerStats::DealDamageTo(Character*, float)` | `0x00643ebc` | 4 B | damage yang diberikan |
| `PlayerStats::ReceiveDamageFrom(Character*, float)` | `0x00643ec0` | 648 B | damage yang diterima |
| `Character::CheckHeadShotHit(...)` | — | — | deteksi headshot |
| `GameObject::GetPosition()` | — | — | baca posisi (vector3d) |
| `GameObject::SetPosition(vector3d)` | — | — | tulis posisi → teleport |
| `Hud::UpdateCharaterHealthBar(Character*)` | — | — | gambar health bar musuh (dipakai ESP) |

Alamat lengkap + daftar simbol ada di `cheat-functions.txt`. Perhatian:
alamat di atas adalah alamat **guest ARM32** — kode yang dieksekusi
adalah hasil terjemahan AOT (§3), jadi hooking harus lewat
`aot_hook_point` / tabel AOT, bukan patch byte file `.so` ARM32.

## 8. AUDIT KELAYAKAN CHEAT

Berlaku untuk **campaign (lawan bot) dan multiplayer lokal (Wi-Fi/LAN)**.
Multiplayer online resmi sudah mati (§5.3), jadi tidak ada "cheat di ranked
online" yang bisa diuji — dan cheat melawan pemain sungguhan (mis. via
proyek Revived) adalah kategori yang tidak dibuatkan.

### 8.1 Auto aim — SANGAT LAYAK ✅

- Game **sudah punya auto-aim bawaan**: `ToggleAutoAim()`,
  `Hud::UpdateAutoAim()`, `Hud::InAutoAimMode()`, `GetClosestEnemy()`,
  `GetVisibleEnemy()`, `CheckHeadShotHit()`.
- Cara termudah: aktifkan flag auto-aim (atau lewat menu cheat §6).
  Untuk "aimbot" yang lebih kuat: hook `Hud::UpdateAutoAim` supaya
  bidikan selalu mengunci kepala musuh terdekat/terlihat — semua data
  (posisi musuh, garis pandang) sudah ada di klien.
- Nilai bidikan 100% client-side; tidak ada validasi server atas aim.
- Mode: campaign + MP lokal (sebagai host maupun client).

### 8.2 God mode — SANGAT LAYAK ✅

- Ada fungsi bawaan: `GameSettings::SetGodMode(true)` /
  `IsInGodMode()`. Alternatif: hook `Character::DamageHealth` (return
  tanpa mengurangi HP) atau `SetHealthPoints` (kunci HP di max).
- Cara termudah: menu cheat bawaan via `setprop debug.mc4.cheats 1` (§6).
- HP/damage dihitung di klien; tidak ada otoritas server.
- Mode: campaign sempurna. MP lokal: sebagai host dijamin; sebagai client,
  host menyinkronkan world state sehingga god mode tetap bekerja di sisi
  klien tapi bisa terlihat aneh oleh pemain lain.

### 8.3 Damage besar — LAYAK ✅

- `PlayerStats::DealDamageTo` / `Character::DamageHealth` /
  `DamageAllHealth` — hook salah satunya untuk mengalikan damage
  (mis. ×10) atau memaksa kill.
- Damage yang kamu berikan dihitung di klienmu lalu dikirim ke host/
  pemain lain, jadi berlaku di campaign + MP lokal.
- Mode: campaign + MP lokal.

### 8.4 ESP — LAYAK ✅ (butuh overlay)

- Semua data sudah ada di memori klien: daftar `Character` (musuh +
  teman), `GameObject::GetPosition()` tiap karakter, `IsEnemyCharacter()`,
  dan HUD sendiri sudah menggambar health bar musuh
  (`UpdateCharaterHealthBar`) — artinya klien selalu tahu posisi musuh,
  termasuk yang di balik dinding.
- Yang dibutuhkan: injector + overlay gambar (kotak/garis/nama di atas
  musuh). Tidak ada anti-overlay / anti-draw di game ini.
- Mode: campaign + MP lokal.

### 8.5 Teleport — LAYAK ✅

- `GameObject::SetPosition(vector3d)` + fisika Havok (`hkpRigidBody`) —
  posisi pemain 100% client-side. Tulis koordinat tujuan (mis. posisi
  musuh dari `GetClosestEnemy`) → teleport.
- Mode: campaign sempurna. MP lokal: sebagai host dijamin; sebagai client,
  posisi dikirim ke host — teleport jalan, tapi lompatan posisi bisa
  terlihat oleh pemain lain (tidak ada validasi anti-teleport di host,
  hanya sinkronisasi state).

### Ringkasan

| Fitur | Kelayakan | Butuh | Client/server | Mode |
|---|---|---|---|---|
| Auto aim | Sangat layak | aktifkan flag bawaan / hook UpdateAutoAim | client-side | campaign + MP lokal |
| God mode | Sangat layak | `SetGodMode(true)` / menu cheat (§6) | client-side | campaign + MP lokal |
| Damage besar | Layak | hook DealDamageTo/DamageHealth | client-side | campaign + MP lokal |
| ESP | Layak | baca posisi Character + overlay | client-side | campaign + MP lokal |
| Teleport | Layak | SetPosition | client-side | campaign + MP lokal |

Catatan umum: **tidak ada satu pun dari lima fitur ini yang butuh
membobol server** — semua nilai gameplay bersifat client-side dan game
ini tidak punya anti-cheat. Satu-satunya komplikasi teknis adalah lapisan
translator AOT (§3): hooking harus lewat `aot_hook_point`, bukan patch
mentah file `.so` ARM32. Dan semua fitur di atas praktis hanya berguna di
campaign + MP lokal, karena MP online resmi sudah mati.

## 9. Isi dump ini

- `README.md` — laporan ini (REA + audit cheat)
- `manifest.txt` — identitas APK (package, versi, SDK, activity, permission, tanda tangan)
- `libs.txt` — inventaris lib native + info ELF
- `strings-mc4.txt` — strings `libModernCombat4.so` (18.647 baris)
- `strings-arm32.txt` — strings `libModernCombat4arm32.so` (77.366 baris, termasuk 34.328 simbol)
- `strings-aot.txt` — strings `libModernCombat4aot.so` (618.880 baris)
- `cheat-functions.txt` — alamat fungsi kunci gameplay (ARM32 guest)
- `dex-classes.txt` — daftar kelas DEX
- `hosts-endpoints.txt` — host/endpoint + isi `oconf.bar`
- `oconf.bar` — config server plaintext dari main OBB (asli)
- `eventParameters.json` — definisi event analitik (asli dari assets)
- `obb_main_list.txt` / `obb_patch_list.txt` — isi kedua OBB

## 10. Batasan REA

- Statis saja: APK tidak pernah di-install / dijalankan. Tidak ada
  pengujian perilaku runtime (menu cheat §6 belum dibuktikan menyala di
  HP — butuh `setprop debug.mc4.cheats 1` di HP root + jalankan game).
- Status "multiplayer mati" didasarkan pada referensi kode + sumber
  publik (penghapusan dari Play Store 30 Sep 2023, pernyataan penutupan
  server, dan proyek Revived yang mengganti meeting point). Tidak ada
  traffic protokol game yang dikirim ke server mana pun.
- Alamat fungsi adalah alamat guest ARM32; pemetaan ke kode AOT yang
  dieksekusi harus lewat `aot_hook_point` (belum dipetakan di REA ini).
- APK sumber (1,3 GB) dihapus total setelah push dump ini terverifikasi,
  sesuai aturan REA.
