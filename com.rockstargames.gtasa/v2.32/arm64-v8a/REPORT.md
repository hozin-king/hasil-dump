> Catatan arsip: Target yang disebut laporan hanya "GTA San Andreas (Android)" — package memakai package Play standar game tersebut. Laporan ini tentang lib Cheat Menu v2.32 (plugin AML 64-bit), bukan APK game.

# REA — libCheatMenu64.so

**File:** `~/workspace/user/files/libCheatMenu64_0_k8rh.so`
**Tanggal analisis:** 2026-11-08
**Metode:** analisis statis saja (`readelf`, `nm`, `strings`, `objdump`). Binary STRIPPED dan VM ini **tidak punya Ghidra/Hopper/IDA**, jadi tidak ada dekompilasi/pseudocode. Semua kesimpulan di bawah didukung string/simbol yang benar-benar ada di file; perilaku runtime **tidak** diverifikasi.

---

## 1. Identitas file

| Item | Nilai |
|---|---|
| Nama file | `libCheatMenu64_0_k8rh.so` |
| Ukuran | 1.784.544 byte |
| SHA-256 | `1c678b9ea476c8db83cbbdcb228f180c84d2dd955d4f2d29506e6e11ff043082` |
| BuildID (sha1) | `137305a44f7244fafa5c0452d70e686bce5c91f3` |
| Format | ELF 64-bit LSB shared object, ARM aarch64, dynamically linked |
| SONAME | `libCheatMenu64.so` |
| Simbol | STRIPPED (tidak ada symbol table, hanya dynamic symbols) |
| Entry point | `0x0` (library, bukan executable) |
| Compiler | Android NDK Clang 20.0.0 (r547379), dengan PGO + BOLT + LTO + MLGO (`.comment`: `Android (13065274, +pgo, +bolt, +lto, +mlgo, based on r547379) clang version 20.0.0`) |
| Android note | `NT_VERSION` berisi `r39-beta1` (NDK r39 beta) |
| Arsip tertanam | tidak ada (0 signature ZIP, 0 DEX, 1 ELF) |

---

## 2. Kesimpulan utama

File ini adalah **Cheat Menu v2.32 for SA Android by ARM** — sebuah **mod menu (trainer) untuk GTA San Andreas versi Android**, dalam bentuk **plugin AML (Android Mod Loader)** 64-bit.

Bukti identitas (string literal di dalam file):

- `Cheat Menu v2.32`
- `Cheat Menu v2.32 for SA Android by ARM`
- `Plugin version: 2.32 WIP`
- `ARM Cheat Menu`
- `Basic Design & Features are from Grinch_ Cheat Menu`
- `ARM & Grinch_`
- Upstream: `https://github.com/user-grinch/Cheat-Menu`
- Kredit: `ocornut, [-=KILL MAN=-], Grinch_, DK22Pac, gta-reversed contributors, Marzer`

Ini **bukan** mod untuk game lain. Game yang ditargetkan adalah **GTA San Andreas (mobile/Android)** — lihat §3.

---

## 3. Game yang ditargetkan — GTA San Andreas (Android)

| Bukti | Keterangan |
|---|---|
| `San Andreas` | Nama game di string |
| `GTA SA Source Code` | Referensi source/reverse-engineering GTA SA |
| `libGTASA.so` | Library game GTA SA Android yang di-hook/dimuat saat runtime |
| `gta-reversed` | Proyek reverse-engineering GTA SA (re3/reVC family) |
| `net.rusjj.gtasa.utils` | Package SAUtils — plugin utilitas GTA SA oleh RusJJ |
| `Game Package: ` / `Actual Game Package: ` | String format yang dipakai untuk menampilkan/memeriksa package game yang sedang berjalan |
| `CPed`, `CEntity`, `RwV3d`, `IKChainManager_c::LookAt` | Kelas internal GTA SA (RenderWare): `CPed` = pedestrian/karakter, `CEntity` = entitas dunia |
| `cheats.dat`, `weapons.dat`, `carcols.dat`, `addonskin.dat`, `cutscenes.dat`, `timecyc.dat`, `timecyc_24h.dat`, `colorcycle.dat`, `colorcycle_24h.dat` | File data asli GTA SA (`data/*.dat`) yang dibaca/diedit menu ini |
| `ImGui_ImplRenderWare_CreateDeviceObjects` | Backend rendering ImGui untuk **RenderWare** — engine grafis GTA SA (III/VC/SA) |

**Bukan game lain:** tidak ada string package/nama game lain (tidak ada `com.fingersoft`, `com.tencent`, `com.dts`, dsb.). Satu-satunya game yang dirujuk adalah GTA SA.

---

## 4. Arsitektur & cara kerja (yang bisa dibuktikan dari statis)

### 4.1 Plugin AML (Android Mod Loader)
Ekspor dinamis (defined) yang menjadi API plugin AML:

| Simbol | Alamat | Arti |
|---|---|---|
| `OnModPreLoad` | `0x158b34` | Dipanggil AML sebelum game dimuat |
| `OnModLoad` | `0x158c70` | Dipanggil AML saat mod dimuat |
| `OnAllModsLoaded` | `0x15933c` | Dipanggil setelah semua mod AML dimuat |
| `__GetModInfo` | `0xa4100` | Mengembalikan info plugin (diisi saat runtime — isi statis `modinfo` di `.data` masih kosong, jadi nama/author/versi dari fungsi ini tidak bisa dibaca statis) |
| `amlStub` (BSS) | `0x1bcc78` | Stub interface AML |
| `modinfo` (data) | `0x1b7670` | Struct info plugin (diisi runtime) |

- Tidak ada `JNI_OnLoad` / simbol `Java_*` — **bukan library JNI**, melainkan plugin native murni yang dimuat AML.
- `INIT_ARRAY` berisi 138 konstruktor (1104 byte / 8), `FINI_ARRAY` 16 byte — inisialisasi C++ statis yang substansial.
- `BIND_NOW` / `FLAGS_1 NOW` — semua simbol di-resolve saat load (bukan lazy).

### 4.2 Dependensi runtime
- **NEEDED (link-time):** hanya `liblog.so`, `libc.so`, `libm.so`, `libdl.so`. Tidak ada `libEGL`/`libGLES`/`libandroid` di NEEDED — grafis ditangani lewat game (RenderWare) itu sendiri.
- **Di-load saat runtime via `dlopen`/`dlsym`:** `libAML.so` (loader), `libGTASA.so` (game), `libCheatMenu64.so` (dirinya sendiri).
- **Dependensi plugin wajib:** **SAUtils v1.6** (oleh RusJJ). String:
  - `Click Me To Download SAUtils v1.6`
  - `SAUtils is not installed or too old!`
  - `This Mod need the latest version of SAUtils plugin!`
  - `I'M Requesting the latest SAUtils to be Installed!!!`
  - Package: `net.rusjj.gtasa.utils`
- **Versi AML minimum:** ada pemeriksaan versi AML, dengan pesan:
  - `Please update the AML to the latest version!`
  - `The AML version is too old!`
  - `Uhhh, I don't want this AML version! Update it please!!!`
  - Interface: `AMLConfig`, `AMLInterface`, `net.rusjj.aml`

### 4.3 UI — Dear ImGui di atas RenderWare
- Library **Dear ImGui** di-embed utuh (ratusan simbol `ImGui*`, `ImGuiContext`, `ImFontAtlas`, `ImDrawList`, dsb.).
- Backend khusus: `ImGui_ImplRenderWare_CreateDeviceObjects` — menu digambar lewat RenderWare game, bukan overlay Android terpisah.
- Konfigurasi memakai **toml++** (`toml2v3`, `toml::parse`) — file konfigurasi berformat TOML (`.toml`).
- Log: `%s/CheatMenu.log`; direktori data: `ARM/CheatMenu/` (dan `ARM.CheatMenu`).
- Bahasa: hanya string `English` + `Language` yang ditemukan; ada pesan `No language is loaded! Cheat Menu is sad:(` — file bahasa dimuat eksternal (TOML), tidak tertanam.
- Musik butuh plugin terpisah: `Cheat Menu need BASSMod to play music!`, `Music player need BASSMod plugin!`

### 4.4 Updater & koneksi luar
URL yang tertanam (tidak ada bukti ia dihubungi saat analisis statis — hanya string yang ada):

| URL | Fungsi (dari konteks string) |
|---|---|
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/update.txt` | Cek update (`CheckUpdate`, `Currently there is no update`) |
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/quiz.txt` | `Cheat Menu - Quiz of the month` (`Quiz`) |
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/` | Basis updater |
| `https://github.com/user-grinch/Cheat-Menu` | Upstream source |
| `https://discord.gg/rtBfy5AWSE` | Discord (`Report any issues or give ideas for this mod through the Discord link above`, `Discord`, `Credits`) |
| `https://modsfire.com/qtRMJ0PmV40t0C1` | Link download (modsfire) |
| `https://teer.id/arm.com` | Donasi/situs author |
| `https://youtube.com/` | Referensi YouTube |
| `https://projectcerbera.com/gta/sa/tutorials/handling` | Tutorial handling GTA SA |

Easter egg: `Hey look it's ARM's Birthday. Thanks for the support everyone.`

---

## 5. Fitur-fitur (dari string menu & kunci konfigurasi)

Total ±712 kunci CamelCase (sebagian noise dari simbol C++), terorganisir dalam tab-tab berikut (string `*Tab` / `*TabBar` / `*Page`):

`CheatsTab`, `PlayerTab`, `VehicleTab`, `WeaponTab`, `SpawnTab`, `TeleportTab`, `PedTab`, `TimecycTab`, `Timecyc24hTab`, `MusicTab`, `AnimationTab`, `AppearanceTab`, `ColorsTab`, `CustomizeTab`, `CutsceneTab`, `FreeCamTab`, `LocationTab`, `ParticleTab`, `TaskTab`, `SceneTab`, `VisualTab`, `SettingsTab`, `AboutTab`, `CheckboxesTab`, `MenusTab`, `OverlayTab`, `PedSkinTab`, `CustomSkinTab`

### 5.1 Player
`GodMode`, `InfiniteAmmo`, `HealthRegen`, `MaxHealth`, `MaxArmour`, `Armour`, `Money` (dengan `StatsMoneyList`), `WantedLevel`, `NotWanted`, `StatHealth`, `StatStamina`, `StatFat`, `StatMuscle`, `BodyFat`, `BodyMuscle`, `BodySkinny`, `BodyChangeToCJ`, `Speed`, `AnimSpeed`, `Playtime` (`Playtime: %d hour %d min %d sec`), `CopyPlayerCoord`, `VecPlayer`, `Player on fire` (pesan status).

### 5.2 Vehicle
`FixVehicle`, `FlipVehicle`, `VehicleFlipNoBurn` (`NoBurnFlip`, `NoBurnFlipTip`), `VehHealth`, `VehSetSpeed`, `VehLockSpeed`, `BlowUpCars`, `InvisibleCar`, `StayOnBike`, `RemoveVehInRadius`, `EnterNearVeh`, `LockDoor`, `NoVehAround`, `VehComp` (komponen: `VehCompAll`, `VehCompDamage`, `VehCompFix`, `VehCompOpen`, `VehCompPop`), kategori `Cars`, `Bikes`, `Boats`, `Planes`, `Helis`, `VehicleNames`, `##VehSpawn` (spawn kendaraan), `UnlockAllCity`.

### 5.3 Weapon
`Weapon`, `InfiniteAmmo`, `Ammo`, `AimSkinChanger` (`AimSkinChangerTip`), `MoveAim` (`MoveAimTip`), `WeaponPage` / `WeaponTabBar`.

### 5.4 Teleport & Spawn
`Teleport`, `TeleportPage` / `TeleportTabBar`, `ToCoord`, `Coordinate`, `CopyPlayerCoord`, `OverlayCoords`, `LocationTab`, `LocationName`, `SpawnTab`.

### 5.5 Ped (NPC)
`PedTab`, `PedPage`, `PedSkinTab`, `PedSkinChild`, `CustomSkinTab`, `ModelList`, `InvalidModelMsg`, `AimSkinChanger`, plus sederet aksi ped yang sangat banyak, contoh: `Kill ped on foot`, `Kill ped with car`, `Kill ped from boat`, `Kill ped group on foot`, `Arrest ped`, `Cop arrest ped`, `Cop hassle ped`, `Gang hassle ped`, `Gang hassle vehicle`, `Follow ped footsteps`, `Follow sexy ped`, `Group stare at ped`, `Stare at ped`, `Signal at ped`, `Walk with ped`, `Walk alongside ped`, `Wait for ped`, `Medic treat injured ped`, `Investigate dead ped`, `Drag ped from car`, `Car set ped in as driver`, `Car set ped in as passenger`, `Set ped as auto driver`, `Toggle ped threat scanner`, `OverlayPedTasks`, `Group hassle sexy ped`, `Kill ped on foot stealth`, `Kill ped on foot while ducking`.

### 5.6 Waktu, cuaca & timecycle
`SetTime`, `SetTimeTotalMin`, `FreezeTime`, `FreezeGameTime`, `FreezeMissionTimer`, `SyncTimeEnabled`, `SyncToSystemTime`, `SetWeather`, `SetWeatherID`, `CurrentWeather`, `NextWeather`, `WeatherLock`, `WeatherExtraSunny`, `WeatherCloudy`, `WeatherFoggy`, `WeatherRainy`, `WeatherSandstorm`, `WeatherThunderstorm`, `Wait for dry weather`, `ReloadTimecyc`, `TimecycTab`, `Timecyc24hTab`, `TimecycColors`, `TimecycMisc`, `TimecycReload`, `Timecyc subtab`, `SunSize`, `SunCore`, `SunCorona`, `CloudAlpha`, `FluffyClouds`, `LowClouds`, `FogEffect`, `FogStart`, `GrainEffect` (`GrainEffectTip`).

### 5.7 Kamera & visual
`FreeCamTab`, `FreeCamFOV`, `FreeCamInfo`, `CameraZoom`, `CameraZoomLock` (`CameraZoomNote`, `CameraZoomWarn`), `TopDownCamZoom`, `CinematicStunt`, `CinematicStuntJump`, `TransparentMenu`, `BigMessageAlpha`, `BigMessageX`, `Colorcycle`, `OverlayTab`, `OverlayCoords`, `OverlayLockPos`, `OverlayPlaytime`, `TimerCounterHideState`, `TimerCounterWasDisplayed`.

### 5.8 Animasi, musik & lain-lain
- `AnimationTab`, `Anim`, `AnimSpeed`, `Anim looped middle`, `Timed anim`, `Climb`, `Boxing`, `BigHead`, `BigButt`, `AlwaysSkid`, `CinematicStuntJump`.
- `MusicTab`, `MusicPlayer`, `AutoTunes` (`AutoTunesTip`), `SpwnRndmTunes`, `BASS` (butuh plugin BASSMod).
- `CheatsTab` dengan `CheatActivatedMsg` / `CheatDeactivatedMsg` / `CheatMsg`; `cheats.dat` game dipakai sebagai sumber cheat bawaan (tidak ditemukan string kode cheat klasik seperti `HESOYAM`/`BAGUVIX` di dalam library — cheat bawaan dibaca dari file data game, bukan dari library ini).
- `CutsceneTab`, `ParticleTab`, `SceneTab`, `VisualTab`, `AppearanceTab`, `CustomizeTab`, `SettingsTab`, `AboutTab`, `CheckboxesTab` (daftar toggle), `MenusTab`, `MenuPage` / `MenuTabBar`, `MainMenu`, `GamePage` / `GameTabBar`.
- Pesan error khas: `Cheat Menu Is Not Feeling Good:(`, `Be in a vehicle first!`, `This warning brought to you by the Cheat Menu`.

> Catatan: daftar di atas adalah **nama fitur/kunci yang terbaca dari string**, bukan verifikasi bahwa tiap fitur berfungsi. Library ini STRIPPED sehingga kaitan tiap kunci ke alamat fungsi tidak bisa dipetakan tanpa dekompilasi.

---

## 6. Dependensi (library & impor)

### 6.1 NEEDED (readelf -d)
| Library | Keterangan |
|---|---|
| `liblog.so` | Android logging (`__android_log_write`) |
| `libc.so` | C library + pthread + dlopen |
| `libm.so` | Matematika (`sinf`, `cosf`, `powf`, `atan2f`, `sqrt` family) |
| `libdl.so` | `dlopen` / `dlsym` |

### 6.2 Impor menonjol (124 undefined symbols, `nm -D`)
- **Loading dinamis:** `dlopen`, `dlsym`, `dl_iterate_phdr`, `getauxval` — memindai dan memuat library game/loader saat runtime.
- **Proses:** `fork`, `execvp`, `waitpid`, `exit`, `abort` — bisa menjalankan proses anak (kemungkinan terkait download/install SAUtils atau helper; tujuan pastinya tidak bisa dipastikan dari statis).
- **File & direktori:** `fopen`/`fread`/`fwrite`/`fseek`, `opendir`/`readdir`/`closedir`, `mkdir`, `stat`, `remove` — membaca file data game & konfigurasi, menulis log.
- **Threading:** `pthread_mutex_lock/unlock`, `pthread_cond_wait/broadcast`, `pthread_rwlock_*`, `pthread_once`, `pthread_key_create` — menu berjalan multi-thread.
- **Sistem:** `__system_property_get` (baca properti Android, mis. versi/device), `syscall`, `clock_gettime`, `localtime`/`strftime` (penanda waktu, playtime).
- **Logging:** `__android_log_write`, `syslog`, `openlog`/`closelog`.
- **C++:** `__cxa_atexit`, `__cxa_finalize`, `__stack_chk_fail`, `__*_chk` (fortify).

### 6.3 Library yang di-embed (simbol defined)
- **Dear ImGui** (UI menu) — ratusan simbol `ImGui*`, termasuk `ImGuiContext`, `ImFontAtlas`, `ImDrawListSplitter`, `ImTriangulator`.
- **toml++ v3** (`toml2v3`) — parsing konfigurasi TOML.
- **stb** (`stbsp_snprintf`, `stbsp_sprintf`, `stbsp_vsprintf`) — formatting string.
- **RenderWare backend** — `ImGui_ImplRenderWare_CreateDeviceObjects`.
- **Game math** — `CQuaternion` (operator `+ - * /`), `IKChainManager_c::LookAt`, `g_boneNodeMan`, `g_ikChainMan` (global GTA SA).

---

## 7. Ekspor / simbol dinamis

- **Defined:** ±584 simbol (mayoritas ImGui + toml++ + stb + C++ STL). Yang bermakna untuk modding: `OnModPreLoad`, `OnModLoad`, `OnAllModsLoaded`, `__GetModInfo`, `modinfo`, `amlStub`, `ImGui_ImplRenderWare_CreateDeviceObjects`, `IKChainManager_c::LookAt`, `g_boneNodeMan`, `g_ikChainMan`, `stbsp_*`.
- **Undefined (impor):** 124 simbol (lihat §6.2).
- Tidak ada ekspor fungsi cheat per fitur — fitur diakses lewat UI ImGui dan kunci konfigurasi, bukan lewat API publik.

---

## 8. Sections (ringkas)

| Section | Ukuran | Keterangan |
|---|---|---|
| `.text` | 0x108c94 (~1,07 MB) | Kode |
| `.rodata` | 0x3cb24 (~245 KB) | String & data konstanta |
| `.data.rel.ro` | 0x6a28 | Data relokasi read-only |
| `.data` | 0x3a78 | Data writable (termasuk `modinfo`) |
| `.bss` | 0x4a70 | Data zero-init (termasuk `amlStub`, `g_boneNodeMan`, `g_ikChainMan`) |
| `.init_array` | 0x450 (138 entri) | Konstruktor C++ |
| `.rela.dyn` | 0x1d820 (120.864 byte, 4647 RELACOUNT) | Relokasi dinamis |
| `.rela.plt` | 0x1c50 | Relokasi PLT |
| `.eh_frame` / `.gcc_except_table` | — | Exception handling C++ |
| `.note.android.ident` | — | NDK r39-beta1 |

---

## 9. Yang TIDAK bisa dijawab dari analisis ini

- **Apakah tiap fitur benar-benar bekerja** — butuh runtime (install di GTA SA Android + AML + SAUtils) atau dekompilasi Ghidra/IDA, yang tidak tersedia di VM ini.
- **Alamat/offset hook ke `libGTASA.so`** — binary stripped; tanpa dekompilasi, pemetaan kunci fitur → alamat fungsi game tidak bisa dilakukan.
- **Isi `modinfo` / `__GetModInfo`** — struct diisi saat runtime; pembacaan statis menghasilkan nilai kosong.
- **Apakah updater/download benar-benar berjalan** — URL ada sebagai string, tetapi tidak ada bukti runtime ia dihubungi, dan tidak ada analisis traffic.
- **Keamanan file** — tidak ditemukan string yang mengindikasikan pencurian data/kredensial; tetapi audit keamanan menyeluruh butuh dekompilasi dan tidak bisa disimpulkan dari strings saja.

---

## 10. Artefak

- Laporan ini: `~/workspace/rea-libcheatmenu64/REPORT.md`
- `elf_header.txt`, `elf_dynamic.txt`, `elf_sections.txt`, `elf_program.txt` — output `readelf`
- `dynsym.txt`, `dynsym_defined.txt` — output `nm -D`
- `strings_all.txt`, `strings_offsets.txt` — output `strings -a`
- `feature_keys.txt` — 712 kunci CamelCase yang diekstrak dari strings

**Alat:** `rea doctor` (npx rea-agents) — Hopper/Ghidra/IDA/JADX semuanya *missing* di VM ini; analisis dilakukan dengan binutils (`readelf`, `nm`, `objdump`, `strings`) + Python.
