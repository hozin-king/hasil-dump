> Catatan arsip: Analisis penuh libCheatMenu64.so (599 baris) — pendamping REPORT.md yang sudah ada.

# REA — libCheatMenu64_0_v8e4.so (Full Dump + Analisis Statis)

**File:** `~/workspace/user/files/libCheatMenu64_0_v8e4.so`
**Tanggal analisis:** 2026-11-12
**Metode:** analisis **statis saja** (`readelf`, `nm`, `strings`, disassembly AArch64).
Binary STRIPPED dan VM ini **tidak punya Ghidra/Hopper/IDA** — tidak ada
dekompilasi/pseudocode. Semua temuan di bawah diverifikasi langsung dari file
ini (hash, string, simbol, dan disassembly). Perilaku runtime **tidak**
diverifikasi. Laporan ini dibuat dari nol terhadap file ini; laporan lama
(8 Nov 2026, file `libCheatMenu64_0_k8rh.so`) hanya dipakai di akhir sebagai
cross-check (§13), bukan sebagai sumber.

> **Klasifikasi temuan** — setiap butir ditandai:
> - **[TERBUKTI STATIS]** — ada di file (string/simbol/instruksi yang terbaca).
> - **[INFERENSI]** — kesimpulan logis dari bukti statis, tapi belum tentu
>   benar tanpa runtime.
> - **[TIDAK BISA DIVERIFIKASI STATIS]** — butuh runtime/decompiler.

---

## 1. Identitas file

| Item | Nilai |
|---|---|
| Nama file | `libCheatMenu64_0_v8e4.so` |
| Ukuran | 1.784.544 byte |
| SHA-256 | `1c678b9ea476c8db83cbbdcb228f180c84d2dd955d4f2d29506e6e11ff043082` |
| BuildID (sha1) | `137305a44f7244fafa5c0452d70e686bce5c91f3` |
| Format | ELF 64-bit LSB shared object, ARM aarch64, dynamically linked |
| SONAME | `libCheatMenu64.so` |
| Simbol | STRIPPED (tidak ada symbol table, hanya dynamic symbols) |
| Entry point | `0x0` (library, bukan executable) |
| Compiler | Android NDK Clang 20.0.0 (r547379), PGO + BOLT + LTO + MLGO |
| Android note | `NT_VERSION` berisi `r39-beta1` (NDK r39 beta) |
| Linker | LLD 20.0.0 |
| `BIND_NOW` / `FLAGS_1 NOW` | ya — semua simbol di-resolve saat load |
| Arsip tertanam | tidak ada (0 signature ZIP, 0 DEX, 1 ELF) |

**[TERBUKTI STATIS]** Identitas mod (dari string + disassembly `__GetModInfo`):

- `Cheat Menu v2.32`
- `Cheat Menu v2.32 for SA Android by ARM`
- `Plugin version: 2.32 WIP`
- `Basic Design & Features are from Grinch_ Cheat Menu`
- Upstream: `https://github.com/user-grinch/Cheat-Menu`
- Kredit: `ocornut, [-=KILL MAN=-], Grinch_, DK22Pac, gta-reversed contributors, Marzer`

Konstruktor `ModInfo` (di `__GetModInfo+0x54`, alamat `0xa4154`) dipanggil
dengan empat string — diverifikasi lewat decode instruksi `adr`/`adrp` +
pembacaan `.rodata`:

| Argumen | Nilai |
|---|---|
| ID internal | `ARM.CheatMenu` |
| Nama tampil | `ARM Cheat Menu` |
| Versi | `2.32` |
| Author | `ARM & Grinch_` |

Struct `modinfo` di `.data` (`0x1b7670`) dalam keadaan statis **hampir kosong**
(128 byte pertama: 10 byte non-nol saja — dua integer kecil `0x2e`/`0x2c`,
satu integer `0x1388`, dan dua float `-1.0`); string diisi saat runtime oleh
konstruktor di atas. **[TERBUKTI STATIS]**

---

## 2. Kesimpulan utama

File ini adalah **Cheat Menu v2.32 for SA Android by ARM** — sebuah **mod menu
(trainer) untuk GTA San Andreas versi Android**, dalam bentuk **plugin AML
(Android Mod Loader)** 64-bit. **[TERBUKTI STATIS]**

Poin-poin terpenting dari analisis ini (yang sebagian tidak ada di laporan
lama):

1. **Cek versi di kode ≠ teks di UI**: kode memeriksa SAUtils **≥ 1.5.1** dan
   AML **≥ 1.3.0**, padahal teks UI menyebut SAUtils **v1.6** (§5.2).
2. **Ada cek plugin keempat**: `ImGuiVirtualKeyboard` v0.2 (`imguikeyboard`)
   dan plugin `net.rusjj.timecyc24` — keduanya tidak disebut di laporan lama
   (§5.2, §5.3).
3. **`/proc/self/maps` BUKAN anti-tamper**: dipakai helper `0x9d6d4` untuk
   mencari base address `libGTASA.so` — cara standar mod AML me-resolve
   alamat fungsi game (§8).
4. **`fork`/`execvp` satu-satunya di binary adalah pembuka URL `xdg-open`**
   (idiom desktop Linux) — bukan downloader, bukan root, bukan tamper (§8).
5. **Tidak ada impor network sama sekali** (tanpa `socket`/`connect`/`curl`/
   SSL) — updater tidak bisa melakukan HTTP sendiri; mekanisme pengambilan
   `update.txt`/`quiz.txt` **tidak bisa ditentukan dari statis** (§7).
6. **Versi game yang ditampilkan hardcode**: halaman About menampilkan
   `2.10 64bit` bila base address `libGTASA.so` ditemukan, `Unknown` bila
   tidak — tidak ada pembanding string versi game (§5.4).

---

## 3. Game yang ditargetkan — GTA San Andreas (Android)

| Bukti | Keterangan |
|---|---|
| `San Andreas` | Nama game di string |
| `libGTASA.so` | Library game yang di-`dlopen` dan dipindai base-nya (§8) |
| `gta-reversed` | Proyek reverse-engineering GTA SA |
| `net.rusjj.gtasa.utils` | Package SAUtils — plugin utilitas GTA SA oleh RusJJ |
| `CPed`, `CEntity`, `RwV3d`, `IKChainManager_c::LookAt` | Kelas internal GTA SA (RenderWare) |
| `ImGui_ImplRenderWare_CreateDeviceObjects` | Backend ImGui untuk RenderWare — engine GTA SA |
| `data/*.dat` | File data asli GTA SA yang dibaca (§6.4) |
| `2.10 64bit` | Label versi game yang ditampilkan di halaman About |

**[TERBUKTI STATIS]** Tidak ada string package/nama game lain (tidak ada
`com.fingersoft`, `com.tencent`, `com.dts`, dsb.). Satu-satunya game yang
dirujuk adalah GTA SA.

---

## 4. Arsitektur & cara kerja

### 4.1 Plugin AML — ekspor dinamis

| Simbol | Alamat | Arti |
|---|---|---|
| `OnModPreLoad` | `0x158b34` | Dipanggil AML sebelum game dimuat |
| `OnModLoad` | `0x158c70` | Dipanggil AML saat mod dimuat |
| `OnAllModsLoaded` | `0x15933c` | Dipanggil setelah semua mod AML dimuat |
| `__GetModInfo` | `0xa4100` | Mengembalikan info plugin |
| `amlStub` (BSS) | `0x1bcc78` | Stub interface AML |
| `modinfo` (data) | `0x1b7670` | Struct info plugin (diisi runtime, §1) |

- Tidak ada `JNI_OnLoad` / simbol `Java_*` — **bukan library JNI**, melainkan
  plugin native murni yang dimuat AML. **[TERBUKTI STATIS]**
- `.init_array` berisi 138 entri — tetapi **isinya 0 di dalam file** dan
  diisi lewat relokasi saat load (`.rela.dyn` 4647 relokasi); daftar
  konstruktor C++ tidak bisa dibaca statis. **[TIDAK BISA DIVERIFIKASI STATIS]**

### 4.2 Helper internal penting (fungsi statis tanpa nama)

| Alamat | Fungsi | Bukti |
|---|---|---|
| `0x9d6c0` | `dlsym(gameHandle, name)` — resolve simbol dari game | `ldr x8,[0x1bb0e0]` lalu `b dlsym@plt` |
| `0x9d6d4` | `dlopen("libGTASA.so")` + pindai `/proc/self/maps` cari base address game, simpan di BSS `0x1bb0e0` (handle) dan `0x1bb0e8` (base) | `fopen` → `fgets` (0x7ff) → `strstr(line,"libGTASA.so")` → `strtoul(line,16)` |
| `0x1a0660` | Veneer `free(x0)` | `bti c; b 0x1a0658` → `b free@plt` |
| `0xa41ec` | Helper log (format + `__android_log_write`) | `vsnprintf` lalu `__android_log_write` |
| `0xa4574`, `0xa4708` | Helper AML (registrasi entri About / ambil string konfigurasi) | Dipanggil berulang dari `OnModPreLoad` dengan kunci string |
| `0x158f6c` | Fungsi besar (disebut dari `OnModLoad`) — pemuat konfigurasi/menu | `sub sp,#0x1f0`, memakai tabel TOML |

Pemanggil `0x9d6c0`/`0x9d6d4` tidak terlacak sebagai `bl` langsung —
kemungkinan dipanggil lewat function pointer atau konstruktor `.init_array`
yang ter-relokasi. **[TIDAK BISA DIVERIFIKASI STATIS]**

### 4.3 Dependensi runtime

**NEEDED (link-time):** hanya `liblog.so`, `libc.so`, `libm.so`, `libdl.so`.
Tidak ada `libEGL`/`libGLES`/`libandroid` — grafis ditangani lewat game
(RenderWare) itu sendiri. **[TERBUKTI STATIS]**

**Di-load saat runtime via `dlopen`/`dlsym`:** `libAML.so` (loader),
`libGTASA.so` (game), `libCheatMenu64.so` (dirinya sendiri).
**[TERBUKTI STATIS]**

**Library yang di-embed (simbol defined):**

- **Dear ImGui 1.92.6 WIP (19252)** — UI menu (ratusan simbol `ImGui*`).
- **toml++ v3** (`toml2v3`, `toml::parse`) — parsing konfigurasi TOML.
- **stb** (`stbsp_snprintf`, `stbsp_sprintf`, `stbsp_vsprintf`).
- **RenderWare backend** — `ImGui_ImplRenderWare_CreateDeviceObjects`.
- **Game math** — `CQuaternion`, `IKChainManager_c::LookAt`, `g_boneNodeMan`,
  `g_ikChainMan` (global GTA SA).

### 4.4 Impor menonjol (124 undefined symbols)

- **Loading dinamis:** `dlopen`, `dlsym`, `dl_iterate_phdr`, `getauxval`.
- **Proses:** `fork`, `execvp`, `waitpid`, `exit`, `abort` — **satu-satunya**
  pemakaian `fork`/`execvp` adalah pembuka URL `xdg-open` (§8).
- **File & direktori:** `fopen`/`fread`/`fwrite`/`fseek`/`fgets`/`fclose`,
  `opendir`/`readdir`/`closedir`, `mkdir`, `stat`, `remove`.
- **Threading:** `pthread_mutex_lock/unlock`, `pthread_cond_wait/broadcast`,
  `pthread_rwlock_*`, `pthread_once`, `pthread_key_create`.
- **Sistem:** `__system_property_get`, `syscall`, `clock_gettime`,
  `localtime`/`strftime`.
- **Logging:** `__android_log_write`, `syslog`, `openlog`/`closelog`.
- **C++:** `__cxa_atexit`, `__cxa_finalize`, `__stack_chk_fail`, `__*_chk`.
- **TIDAK ADA impor network:** tanpa `socket`, `connect`, `getaddrinfo`,
  `send`, `recv`, `curl`, SSL, `inet_*`. **[TERBUKTI STATIS]**

---

## 5. Disassembly fungsi-fungsi kunci AML

Disassembly lengkap ada di `disasm_OnModPreLoad.txt`,
`disasm_OnModLoad.txt`, `disasm_OnAllModsLoaded.txt`,
`disasm_GetModInfo.txt` (plus `disasm_full_text.txt`, 274.118 baris).
Xref string + pemanggilan ada di `analysis_xref_*.txt`.
Catatan alat: `objdump` sistem (x86-only) **tidak bisa** membongkar AArch64
(`can't disassemble for architecture UNKNOWN!`); disassembly di sini memakai
`llvm-objdump` dari Android NDK 26.1.10909125.

### 5.1 `OnModPreLoad` — `0x158b34` (316 byte, berakhir `0x158c70`)

Mendaftarkan **5 entri halaman About** ke AML, masing-masing dengan pola yang
sama: panggil helper `0xa4574` (interface AML, kunci, nilai, grup), lalu
helper `0xa4708`, lalu `free` (`0x1a0660`) pada hasil dengan argumen mati
`w1 = 0x398` (920 — diabaikan oleh `free`; kemungkinan sisa argumen
sized-delete/level log yang tidak dipakai — **[INFERENSI]**).

| Entri | Kunci | Nilai |
|---|---|---|
| About | `Author` | `ARM` |
| About | `Credits` | `ocornut, [-=KILL MAN=-], Grinch_, DK22Pac, gta-reversed contributors, Marzer` |
| About | `Discord` | (tautan Discord, dimuat dari pointer `modinfo+0x2990`) |
| About | `Channel` | (tautan channel, dimuat dari pointer `modinfo+0x2990`) |
| About | `Version` | `2.32` |

Diakhiri lompatan ke `__GetModInfo+0x43c`. **[TERBUKTI STATIS]**

### 5.2 `OnModLoad` — `0x158c70` (berakhir `ret` di `0x158f68`)

Alur yang terpetakan dari disassembly:

1. **Panggil fungsi init internal `0x105d70`.**
2. **`dlopen("libAML.so", RTLD_NOW)` + `dlsym("GetInterface")`** →
   panggil `GetInterface("SAUtils")`, simpan pointer interface di BSS
   `0x1be0b0`.
3. **`GetInterface("ImGuiVirtualKeyboard")`** → bila NULL, status
   `not installed`; bila ada, panggil method interface offset `0x150`
   dengan argumen (`"imguikeyboard"`, `"0.2"`) — hasil bit 0 memilih status
   `installed` vs `installed but it is an old one:(`, lalu log dengan format
   `Virtual Keyboard is %s`. **[TERBUKTI STATIS]** — plugin keyboard virtual
   diperiksa versinya (minimum `0.2`).
4. **Cek SAUtils**: method interface offset `0x150` dengan
   (`"net.rusjj.gtasa.utils"`, `"1.5.1"`); bit 0 hasil disimpan sebagai flag
   di state struct (`+0x70`). **[TERBUKTI STATIS]**
5. **Cek AML**: method yang sama dengan (`"net.rusjj.aml"`, `"1.3.0"`);
   bit 0 disimpan di flag (`+0x6e`), dan flag `+0x6f` diset 1.
6. **Panggil `0x158f6c`** (fungsi besar — pemuat konfigurasi/menu,
   memakai tabel TOML), lalu inisialisasi struktur TOML
   (`unordered_map<string, toml::table>`) dan sorting (`__introsort` atas
   vector string — daftar model/nama).
7. **`GetInterface("BASS")`** → bila ada: panggil method interface offset
   `0x1b8` dengan `(-1, 0xac44, 0)` lalu dua pemanggilan interface lain
   (inisialisasi audio BASS); bila NULL: log
   `Cheat Menu need BASSMod to play music!` (level 5).
8. **Resolve fungsi OS & game** lewat helper `0x9d6c0`
   (`dlsym(gameHandle, nama)`):
   - `_Z18OS_ServiceOpenLinkPKc` (buka tautan di browser)
   - `_Z14OS_GetDateTimeP8DateTime`
   - `_Z20OS_SystemMemoryStatsPiS_S_`
   - `_ZN6CDebug22DebugDisplayTextBufferEv`
   - `_Z14AND_TouchEventiiii`
   - `_ZN8C_PcSave8SaveSlotEab`
9. **`srand@plt`**, lalu muat tabel konfigurasi TOML dengan kunci
   `CHTMNU` dan `DATEMNU`, panggil fungsi internal `0x159378` (frame menu,
   §5.4) dan `0x163648`.

**Diskrepansi versi [TERBUKTI STATIS]:** kode memeriksa SAUtils **≥ 1.5.1**,
tetapi teks yang ditampilkan ke pengguna menyebut **v1.6**
(`Click Me To Download SAUtils v1.6`, `SAUtils is not installed or too old!`,
`This Mod need the latest version of SAUtils plugin!`,
`I'M Requesting the latest SAUtils to be Installed!!!`). Artinya menu bisa
saja menerima SAUtils 1.5.1 sementara pesannya meminta 1.6 — atau sebaliknya
pemeriksaan 1.5.1 adalah pemeriksaan minimum lama yang pesannya belum
diperbarui. **[INFERENSI]**

### 5.3 `OnAllModsLoaded` — `0x15933c` (56 byte, `ret` di `0x159374`)

Fungsi ini **pendek** — jauh lebih pendek dari yang diasumsikan laporan lama
(rentang dump lama 0x15933c–0x159c00 sebenarnya berisi beberapa fungsi):

- Panggil method interface AML offset `0x10` dengan argumen
  `"net.rusjj.timecyc24"`.
- Bila hasilnya bit 0 set, tulis nilai `0x18` (= 24 desimal) ke global di
  `0x1baff8`. **[TERBUKTI STATIS]**

**[INFERENSI]:** ini adalah deteksi plugin Timecyc24 (mode timecycle 24 jam
milik RusJJ); nilai 24 kemungkinan menandai "timecyc24 tersedia". Fungsi
besar berikutnya (`0x159378`, dipanggil dari `OnModLoad`) adalah frame
menu utama — lihat §5.4.

### 5.4 Fungsi frame menu `0x159378` (dipanggil dari `OnModLoad`)

Dari xref string + pemanggilan di rentang ini:

- Format log: `%s/CheatMenu.log`.
- Jendela ImGui bernama `CheatMenu`; tombol tak terlihat `##TouchMe><`
  (kemungkinan tombol sentuh untuk membuka menu — **[INFERENSI]**).
- Kunci konfigurasi `CHTMNU` / `DATEMNU` dibaca di sini juga.
- **Cabang error** (bila AML/SAUtils tidak memenuhi syarat):
  - `Uhhh, I don't want this AML version! Update it please!!!`
  - `I'M Requesting the latest SAUtils to be Installed!!!`
  - `Cheat Menu Is Not Feeling Good:(`
  - Tombol `Click Me To Download SAUtils v1.6` → membuka
    `[tautan unduhan dihapus — minta ke Alyaa]`
  - `It is not a virus. Trust me. ARM ^-^`
- Fungsi halaman About (`0x1582c0`, sebelum `OnModPreLoad`) menampilkan
  `Game version:` diikuti **`2.10 64bit`** bila base address `libGTASA.so`
  ditemukan (nilai BSS `0x1bb0e8` ≠ 0), atau **`Unknown`** bila tidak.
  **[TERBUKTI STATIS]** — label versi hardcode; tidak ada pembanding string
  versi game.

### 5.5 `__GetModInfo` — `0xa4100`

Entri `__GetModInfo` sendiri sangat kecil (4 instruksi: ambil pointer dari
GOT lalu `ret`). Pekerjaan sebenarnya ada di fungsi-fungsi statis di
sekitarnya dalam rentang `0xa4100–0xa4300`:

| Alamat | Isi |
|---|---|
| `0xa4110` | `dlopen("libAML.so")` + `dlsym("GetInterface")` → panggil `GetInterface("AMLInterface")`, simpan hasilnya di BSS `0x1bcc70` |
| `0xa4154` | Konstruktor `ModInfo` — `ModInfo("ARM.CheatMenu", "ARM Cheat Menu", "2.32", "ARM & Grinch_")` (§1) |
| `0xa41a8` | Helper `strncpy` (maks 30 karakter + NUL) |
| `0xa41ec` | Helper log (`vsnprintf` + `__android_log_write`) |

**[TERBUKTI STATIS]**

---

## 6. Fitur-fitur (dari string menu & kunci konfigurasi)

### 6.1 Catatan metodologi — baca dulu

- `strings -a` menghasilkan **10.127 string**.
- Pencarian pola CamelCase (`^[A-Z][A-Za-z0-9]{2,}$`) menemukan **956
  kecocokan** — angka ini **mengandung banyak noise**: fragmen nama mangled
  C++ (`Th2A9`, `RHkh8`), string internal ImGui (`KeypadDivide`,
  `MouseMiddle`), nama hari (`Monday`, `Friday`), dan string UI satu kata.
  Jadi 956 **bukan** jumlah fitur.
- String nama tab (`*Tab`, `*TabBar`, `*Page`) ditemukan **50 kemunculan**
  (42 nama berbeda — beberapa muncul dua kali di alamat `.rodata` berbeda,
  mis. `PlayerPage`, `TeleportPage`, `PedPage`, `ScenePage`, `VehiclePage`,
  `WeaponPage`, `VisualPage`).
- Pengelompokan kunci per tab di `analysis_feature_keys_by_tab.txt` memakai
  **heuristik kedekatan alamat `.rodata`** (kunci ditetapkan ke tab
  terdekat sebelumnya). Ini **bukan** pemetaan yang diverifikasi — string
  satu tab tidak selalu berdekatan, dan satu blok besar (terutama
  `VisualPage`, 420 kunci mentah) menelan kunci dari banyak tempat.
  Daftar di §6.2 adalah **kurasi manual** dari kunci yang dikenali sebagai
  fitur, bukan hasil mentah.
- **Tidak ada satu pun fitur yang terverifikasi berfungsi** — semua daftar
  di bawah adalah nama fitur/kunci yang terbaca dari string, bukan bukti
  runtime. **[TERBUKTI STATIS untuk keberadaan string; TIDAK BISA
  DIVERIFIKASI STATIS untuk fungsi]**

### 6.2 Tab-tab menu (42 nama berbeda)

`GamePage`, `GameTabBar`, `CheatsTab`, `PlayerTab`, `PlayerTabBar`,
`PlayerPage`, `VehicleTab`, `VehicleTabBar`, `VehiclePage`, `WeaponTab`,
`WeaponTabBar`, `WeaponPage`, `SpawnTab`, `TeleportTab`, `TeleportTabBar`,
`TeleportPage`, `PedTab`, `PedPage`, `PedSkinTab`, `CustomSkinTab`,
`TimecycTab`, `Timecyc24hTab`, `MusicTab`, `AnimationTab`, `AppearanceTab`,
`AppearanceTabBar`, `ColorsTab`, `CustomizeTab`, `CustomizeTabBar`,
`CutsceneTab`, `FreeCamTab`, `LocationTab`, `ParticleTab`, `TaskTab`,
`SceneTab`, `SceneTabBar`, `ScenePage`, `VisualTabBar`, `VisualPage`,
`SettingsTab`, `AboutTab`, `CheckboxesTab`, `MenusTab`, `MenuTabBar`,
`MenuPage`, `OverlayTab`, `StyleTab`, `CurrentPage`.

### 6.3 Fitur per tab (kurasi)

**Player** — `GodMode`, `InfiniteAmmo`, `HealthRegen`, `MaxHealth`,
`MaxArmour`, `Armour`, `Money` (dengan `StatsMoneyList`), `WantedLevel`,
`NotWanted`, `StatHealth`, `StatStamina`, `StatFat`, `StatMuscle`,
`BodyFat`, `BodyMuscle`, `BodySkinny`, `BodyChangeToCJ`, `Speed`,
`AnimSpeed`, `Playtime` (`Playtime: %d hour %d min %d sec`),
`CopyPlayerCoord`, `VecPlayer`, `HighJump`, `SuperSprint`,
`InfniteEnergy` (sic), `NoDamage`, `Suicide`, `ThinBody`.

**Vehicle** — `FixVehicle`, `FlipVehicle`, `VehicleFlipNoBurn`
(`NoBurnFlip`, `NoBurnFlipTip`), `VehHealth`, `VehSetSpeed`,
`VehLockSpeed`, `BlowUpCars`, `InvisibleCar`, `StayOnBike`,
`RemoveVehInRadius`, `EnterNearVeh`, `LockDoor`, `NoVehAround`,
`VehComp` (`VehCompAll`, `VehCompDamage`, `VehCompFix`, `VehCompOpen`,
`VehCompPop`), kategori `Cars`, `Bikes`, `Boats`, `Planes`, `Helis`,
`VehicleNames`, `##VehSpawn`, `UnlockAllCity`, `SpwnInAir`,
`SpwnAsDriver`, `SpwnRndmTunes`, `PerfectHandling`, `NoParticles`.

**Weapon** — `Weapon`, `InfiniteAmmo`, `Ammo`, `AimSkinChanger`
(`AimSkinChangerTip`), `MoveAim` (`MoveAimTip`), `RapidFire`,
`NoSpread`, `FastReload`, `DualWield` (`DualWieldTip`), `LongRange`,
`HugeDamage`.

**Teleport & Spawn** — `Teleport`, `ToCoord`, `Coordinate`,
`CopyPlayerCoord`, `OverlayCoords`, `LocationTab`, `LocationName`,
`SpawnTab`, `VehicleNames`, `ModelList`, `InvalidModelMsg`,
`InvalidIDMsg`, `ToMarker`, `NoWaypoint`.

**Ped (NPC)** — `PedTab`, `PedPage`, `PedSkinTab`, `PedSkinChild`,
`CustomSkinTab`, `ModelList`, `AimSkinChanger`, plus sederet aksi ped,
contoh: `Kill ped on foot`, `Kill ped with car`, `Kill ped from boat`,
`Kill ped group on foot`, `Arrest ped`, `Cop arrest ped`,
`Cop hassle ped`, `Gang hassle ped`, `Gang hassle vehicle`,
`Follow ped footsteps`, `Follow sexy ped`, `Group stare at ped`,
`Stare at ped`, `Signal at ped`, `Walk with ped`, `Walk alongside ped`,
`Wait for ped`, `Medic treat injured ped`, `Investigate dead ped`,
`Drag ped from car`, `Car set ped in as driver`,
`Car set ped in as passenger`, `Set ped as auto driver`,
`Toggle ped threat scanner`, `OverlayPedTasks`, `Group hassle sexy ped`,
`Kill ped on foot stealth`, `Kill ped on foot while ducking`.

**Waktu, cuaca & timecycle** — `SetTime`, `SetTimeTotalMin`, `FreezeTime`,
`FreezeGameTime`, `FreezeMissionTimer`, `SyncTimeEnabled`,
`SyncToSystemTime`, `SetWeather`, `SetWeatherID`, `CurrentWeather`,
`NextWeather`, `WeatherLock`, `WeatherExtraSunny`, `WeatherCloudy`,
`WeatherFoggy`, `WeatherRainy`, `WeatherSandstorm`,
`WeatherThunderstorm`, `Wait for dry weather`, `ReloadTimecyc`,
`TimecycTab`, `Timecyc24hTab`, `TimecycColors`, `TimecycMisc`,
`TimecycReload`, `SunSize`, `SunCore`, `SunCorona`, `CloudAlpha`,
`FluffyClouds`, `LowClouds`, `FogEffect`, `FogStart`,
`GrainEffect` (`GrainEffectTip`).

**Kamera & visual** — `FreeCamTab`, `FreeCamFOV`, `FreeCamInfo`,
`CameraZoom`, `CameraZoomLock` (`CameraZoomNote`, `CameraZoomWarn`),
`TopDownCamZoom`, `CinematicStunt`, `CinematicStuntJump`,
`TransparentMenu`, `BigMessageAlpha`, `BigMessageX`,
`BigMessageInUse`, `Colorcycle`, `OverlayTab`, `OverlayCoords`,
`OverlayLockPos`, `OverlayPlaytime`, `TimerCounterHideState`,
`TimerCounterWasDisplayed`, `NightVision`, `InfraredVision`,
`TunnelVision`, `DarknessFilter`.

**Animasi, musik & lain-lain** — `AnimationTab`, `Anim`, `AnimSpeed`,
`Anim looped middle`, `Timed anim`, `Climb`, `Boxing`, `BigHead`,
`BigButt`, `AlwaysSkid`, `CinematicStuntJump`, `Jetpack`, `Ragdoll`,
`Sunbathe`, `Swim`, `MusicTab`, `MusicPlayer`, `AutoTunes`
(`AutoTunesTip`), `SpwnRndmTunes`, `BASS` (butuh plugin BASSMod).
`CheatsTab` dengan `CheatActivatedMsg` / `CheatDeactivatedMsg` /
`CheatMsg`; `cheats.dat` game dipakai sebagai sumber cheat bawaan
(**tidak ditemukan** string kode cheat klasik seperti `HESOYAM`/
`BAGUVIX` di dalam library — cheat bawaan dibaca dari file data game,
bukan dari library ini). `CutsceneTab`, `ParticleTab`, `SceneTab`,
`VisualTab`, `AppearanceTab`, `CustomizeTab`, `SettingsTab`, `AboutTab`,
`CheckboxesTab`, `MenusTab`, `OverlayTab`, `OverlayFPS`,
`OverlayRAMUsage`, `OverlayMI`.

**Pesan error khas** — `Cheat Menu Is Not Feeling Good:(`,
`Be in a vehicle first!`, `This warning brought to you by the Cheat Menu`,
`No language is loaded! Cheat Menu is sad:(`.

**Easter egg [TERBUKTI STATIS]** — `Hey look it's ARM's Birthday. Thanks
for the support everyone.` dan `Today is ARM's Birthday. Keep this as a
secret between us>_<`.

### 6.4 File data game yang dibaca (`data/*.dat`)

| String | Keterangan |
|---|---|
| `data/addonskin.dat` | Skin tambahan |
| `data/carcols.dat` | Warna kendaraan |
| `data/cheats.dat` | Cheat bawaan game |
| `data/cutscenes.dat` | Cutscene |
| `data/weapons.dat` | Senjata |
| `timecyc.dat`, `timecyc_24h.dat` | Timecycle |
| `colorcycle.dat`, `colorcycle_24h.dat` | Colorcycle |

Juga ada string `// Generated with Cheat Menu` (2 kemunculan) —
**[INFERENSI]** menu ini menulis/menghasilkan file data (kemungkinan
`timecyc.dat`/`colorcycle.dat` hasil edit) dengan header tersebut.

---

## 7. Updater & koneksi luar

### 7.1 URL yang tertanam (9 URL)

| URL | Fungsi (dari konteks string/kode) |
|---|---|
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/update.txt` | Cek update (`CheckUpdate`, `Currently there is no update`) |
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/quiz.txt` | `Cheat Menu - Quiz of the month` (`Quiz`) |
| `https://raw.githubusercontent.com/ARAH64/Updater-mods/main/CM/` | Basis updater (dipakai dengan format `%s%s.mp3`) |
| `https://github.com/user-grinch/Cheat-Menu` | Upstream source |
| `https://discord.gg/rtBfy5AWSE` | Discord |
| `[tautan unduhan dihapus — minta ke Alyaa]` | Link download (SAUtils — tombol di cabang error) |
| `https://teer.id/arm.com` | Donasi/situs author |
| `https://youtube.com/@arm_chxd` | Channel YouTube author |
| `https://projectcerbera.com/gta/sa/tutorials/handling` | Tutorial handling GTA SA |

Tidak ada alamat IP literal. **[TERBUKTI STATIS]**

### 7.2 Cara kerja updater (dari disassembly 0x122200–0x123800)

Fungsi updater (di sekitar `0x122400` dan `0x122880`) memakai ketiga URL
di atas:

- **Update check**: URL `update.txt` disalin ke buffer (via `strlen`/
  `memcpy`), isinya diparse dengan **`atof`** (versi berupa angka desimal)
  lalu dibandingkan; bila tidak ada update tampil
  `Currently there is no update`. Kunci konfigurasi `CheckUpdate`
  dibaca dari tabel TOML. **[TERBUKTI STATIS untuk pemakaian URL + atof;
  INFERENSI untuk alur banding-versi]**
- **Quiz bulanan**: URL `quiz.txt` disalin ke buffer, diparse dengan
  **`atoi`**; ada string `Cheat Menu - Quiz of the month`, kunci `QDATE`,
  dan jawaban `wrong` / `correct`. **[TERBUKTI STATIS]**
- **Audio quiz**: format string `%s%s.mp3` digabung dengan URL basis
  updater — **[INFERENSI]** file audio quiz (mis. `.../CM/<nama>.mp3`)
  diunduh/diputar lewat BASS.
- Kunci terkait di TOML: `CheckUpdate`, `Quiz`, `QDATE`, `RAMUsageWarn`,
  grup `Extras`.

### 7.3 Pertanyaan yang belum terjawab soal updater

**[TIDAK BISA DIVERIFIKASI STATIS]** — Binary ini **tidak mengimpor fungsi
network apa pun** (§4.4) dan tidak ada string `curl`/`wget`/HTTP client.
Jadi dari analisis statis **tidak bisa ditentukan** bagaimana isi
`update.txt`/`quiz.txt` diperoleh saat runtime. Kemungkinan-kemungkinan
(yang semuanya belum terbukti):

1. Pengunduhan didelegasikan ke AML lewat interface (fungsi AML yang
   dipanggil lewat vtable — targetnya tidak bisa di-resolve statis).
2. URL hanya dibuka di browser lewat `OS_ServiceOpenLink` dan "cek update"
   sebenarnya manual.
3. Ada jalur unduh lewat plugin lain (SAUtils/BASS).

**Format isi `update.txt` / `quiz.txt` tidak bisa ditentukan dari binary**
— tidak ada contoh isi di dalam file. Yang pasti hanya: versi diparse
sebagai angka desimal (`atof`) dan quiz memakai angka bulat (`atoi`) plus
tanggal (`QDATE`).

> Peringatan: URL updater menunjuk ke repo `ARAH64/Updater-mods` — repo
> pihak ketiga yang isinya bisa berubah sewaktu-waktu tanpa mengubah binary
> ini. Keamanan isi file yang diunduh dari sana **tidak bisa dinilai** dari
> analisis ini.

---

## 8. Keamanan — cek root / anti-debug / anti-tamper

### 8.1 Hasil pencarian kata kunci

| Kata kunci | Hasil |
|---|---|
| `root` | 3 string — semuanya palsu positif: `CFileMgr::ms_rootDirName` (simbol game), `at root "%s"` (pesan TOML), `root table` (pesan TOML) |
| `magisk`, `supersu`, `/su`, `xposed`, `substrate`, `safetynet`, `play integrity`, `attest`, `jailbreak`, `tracer`, `isDebugger` | **tidak ada** |
| `frida` | 1 string — palsu positif: `Friday` (nama hari) |
| `ptrace`, `tamper`, `debug` (sebagai anti-debug) | **tidak ada** — `debug` hanya muncul di `DEBUG`, `Debug##Default`, dan simbol game (`CPlayerPed::bDebugPlayerInvincible`, `CDebug::DebugDisplayTextBuffer`, `CPostEffects::m_bRadiosityDebug`) |
| `bypass` | 2 string — simbol game (`CPostEffects::m_bRadiosityBypassTimeCycleIntensityLimit`, `CCheat::m_nLastScriptBypasstime`) |
| `signature`, `checksum`, `integrity`, `verify` | **tidak ada** (di luar simbol C++ generik) |
| `/proc/self/maps` | **1 string — dijelaskan di §8.2, BUKAN anti-tamper** |

**Kesimpulan [TERBUKTI STATIS]: tidak ada cek root, anti-debug, atau
anti-tamper di binary ini.** Tidak ada pemeriksaan Magisk/su/Frida/Xposed,
tidak ada `ptrace`, tidak ada verifikasi signature/checksum file.

### 8.2 `/proc/self/maps` — untuk mencari base address game

Satu-satunya pemakaian `/proc/self/maps` ada di helper `0x9d6d4`:

1. `dlopen("libGTASA.so", RTLD_NOW)` → handle disimpan di BSS `0x1bb0e0`.
2. `fopen("/proc/self/maps", "r")`, baca per baris (`fgets`, 0x7ff byte).
3. `strstr(baris, "libGTASA.so")` → bila cocok, `strtoul(baris, NULL, 16)`
   = alamat awal pemetaan → disimpan di BSS `0x1bb0e8`.
4. `fclose`.

Ini adalah **cara standar mod AML mendapatkan base address library game**
(untuk me-resolve alamat fungsi game di memori) — **bukan** deteksi
debugger/root/tamper. **[TERBUKTI STATIS dari disassembly]**

### 8.3 `fork` / `execvp` — pembuka URL `xdg-open`

Satu-satunya pemakaian `fork`/`execvp` di seluruh binary ada di fungsi
`0xb0694`–`0xb080c` / `0xb0810`:

- `fork()` → anak: `execvp("xdg-open", ...)` → induk: `waitpid()`.
- `xdg-open` adalah perintah pembuka URL/file standar **desktop Linux**.

**[TERBUKTI STATIS]** — ini pembuka tautan, bukan downloader, bukan
eksekutor perintah root, bukan anti-tamper. Di Android `xdg-open`
kemungkinan besar tidak ada sehingga jalur ini gagal diam-diam;
tautan di menu kemungkinan dibuka lewat `OS_ServiceOpenLink` yang
di-resolve di `OnModLoad` (§5.2). **[INFERENSI]**

### 8.4 Penilaian keamanan lain

- **Tidak ditemukan** string yang mengindikasikan pencurian data/kredensial,
  pengiriman data keluar, atau akses kontak/SMS/lokasi.
- **Tetapi**: audit keamanan menyeluruh **tidak bisa** disimpulkan dari
  strings saja — perilaku berbahaya bisa tersembunyi di kode yang
  di-obfuscate/inlined dan hanya terlihat lewat dekompilasi Ghidra/IDA atau
  analisis traffic runtime. **[TIDAK BISA DIVERIFIKASI STATIS]**
- Risiko nyata yang terlihat statis: updater mengambil file dari repo
  GitHub pihak ketiga (`ARAH64/Updater-mods`) yang isinya bisa berubah
  (§7.3); dan menu ini membaca/menulis file data game (`data/*.dat`) serta
  menulis log + konfigurasi ke penyimpanan.

---

## 9. Konfigurasi TOML, bahasa eksternal & struktur direktori

### 9.1 Format konfigurasi

- Parser **toml++ v3** tertanam (simbol `toml2v3`, `toml::parse`, pesan
  error TOML 1.0.0). **[TERBUKTI STATIS]**
- Satu-satunya string ekstensi yang ada: `.toml` (tanpa nama file lengkap
  di sampingnya). **[TERBUKTI STATIS]**
- Kunci konfigurasi yang terkonfirmasi dari disassembly: `CHTMNU`,
  `DATEMNU`, `QDATE`, `CheckUpdate`, `Quiz`, `RAMUsageWarn`, grup
  `Extras`, serta `Language` / `English`. **[TERBUKTI STATIS]**
- Nama file konfigurasi persisnya (mis. `CheatMenu.toml` atau sejenisnya)
  **tidak bisa ditentukan** dari binary — string nama file tidak ditemukan;
  kemungkinan nama file dibentuk dari pola `ARM/CheatMenu/%s` dengan
  argumen yang tidak terlacak statis. **[TIDAK BISA DIVERIFIKASI STATIS]**

### 9.2 File bahasa eksternal

- String: `Language`, `English`, `Loaded locale [ %s ] -> %s`,
  `No language is loaded! Cheat Menu is sad:(`, `##Locale`.
  **[TERBUKTI STATIS]**
- Hanya bahasa **English** yang disebut sebagai string; tidak ada string
  bahasa Indonesia di seluruh binary (pencarian kata Indonesia: nihil).
  **[TERBUKTI STATIS]**
- File bahasa dimuat eksternal (kemungkinan TOML juga — **[INFERENSI]**,
  karena parser TOML yang dipakai untuk konfigurasi); nama file bahasa dan
  daftar bahasa yang tersedia **tidak bisa ditentukan statis**.

### 9.3 Struktur direktori data

| String | Arti |
|---|---|
| `ARM/CheatMenu/` | Direktori data mod |
| `ARM/CheatMenu/%s` | Pola path file di dalam direktori data |
| `%s/CheatMenu.log` | File log (prefix path = direktori data AML) |
| `imgui.ini` | File state/layout ImGui |
| `ARM.CheatMenu` | ID internal mod (bukan path) |

**[TERBUKTI STATIS]** — di perangkat, direktori ini berada di bawah folder
data AML (biasanya di penyimpanan internal, path persisnya ditentukan AML
saat runtime). **[INFERENSI]**

---

## 10. Sections (ringkas)

| Section | Ukuran | Keterangan |
|---|---|---|
| `.text` | 0x108c94 (~1,07 MB) | Kode |
| `.rodata` | 0x3cb24 (~245 KB) | String & data konstanta |
| `.data.rel.ro` | 0x6a28 | Data relokasi read-only |
| `.data` | 0x3a78 | Data writable (termasuk `modinfo`) |
| `.bss` | 0x4a70 | Data zero-init (termasuk `amlStub`, `g_boneNodeMan`, `g_ikChainMan`, handle/base `libGTASA.so`) |
| `.init_array` | 0x450 (138 entri) | Konstruktor C++ (isi 0 di file — ter-relokasi saat load) |
| `.fini_array` | 0x10 (2 entri) | Destruktor (isi 0 di file) |
| `.rela.dyn` | 0x1d820 (4647 relokasi) | Relokasi dinamis |
| `.rela.plt` | 0x1c50 | Relokasi PLT |
| `.eh_frame` / `.gcc_except_table` | — | Exception handling C++ |
| `.note.android.ident` | — | NDK r39-beta1 |
| `.plt` | 0x1300 | Stub PLT |

**Simbol dinamis:** 584 defined, 124 undefined (`nm -D`).
**[TERBUKTI STATIS]**

---

## 11. Yang TIDAK bisa dijawab dari analisis ini

- **Apakah tiap fitur benar-benar bekerja** — butuh runtime (install di
  GTA SA Android + AML + SAUtils) atau dekompilasi Ghidra/IDA, yang tidak
  tersedia di VM ini.
- **Alamat/offset hook ke `libGTASA.so`** — binary stripped; tanpa
  dekompilasi, pemetaan kunci fitur → alamat fungsi game tidak bisa
  dilakukan. (Yang diketahui: base address game dicari lewat
  `/proc/self/maps`, §8.2.)
- **Isi `modinfo` lengkap** — string diisi runtime; yang terverifikasi
  hanya 4 argumen konstruktor (§1).
- **Mekanisme pengambilan `update.txt`/`quiz.txt`** — tanpa impor network,
  jalurnya tidak terlacak statis (§7.3).
- **Nama file konfigurasi & bahasa** — tidak ada string nama file lengkap
  (§9).
- **Apakah updater/download benar-benar berjalan** — URL ada sebagai
  string, tetapi tidak ada bukti runtime ia dihubungi, dan tidak ada
  analisis traffic.
- **Keamanan file secara menyeluruh** — tidak ditemukan string berbahaya,
  tetapi audit menyeluruh butuh dekompilasi (§8.4).

---

## 12. Artefak

Semua di `~/workspace/rea-libcheatmenu64-full/`:

| File | Isi |
|---|---|
| `REPORT.md` | Laporan ini |
| `readelf_all.txt` | `readelf -a` lengkap (6.423 baris) |
| `elf_header.txt`, `elf_sections.txt`, `elf_program.txt`, `elf_dynamic.txt`, `elf_relocs.txt`, `elf_notes.txt`, `elf_comment.txt` | Potongan `readelf` |
| `dynsym_all.txt` (708 baris), `dynsym_defined.txt` (584), `dynsym_undefined.txt` (124) | `nm -D` |
| `strings_all.txt`, `strings_offsets.txt` | `strings -a` (10.127 string, dengan offset) |
| `disasm_full_text.txt` | Disassembly `.text` lengkap (274.118 baris, via NDK `llvm-objdump`) |
| `disasm_OnModPreLoad.txt`, `disasm_OnModLoad.txt`, `disasm_OnAllModsLoaded.txt`, `disasm_GetModInfo.txt` | Disassembly 4 fungsi kunci AML |
| `disasm_updater.txt`, `disasm_fork_exec.txt` | Disassembly fungsi updater & `fork`/`execvp` |
| `analysis_xref_OnModPreLoad.txt`, `analysis_xref_OnModLoad.txt`, `analysis_xref_OnAllModsLoaded.txt`, `analysis_xref_GetModInfo.txt`, `analysis_xref_updater.txt` | Xref string + pemanggilan per fungsi |
| `analysis_urls.txt` | 9 URL + domain + IP (nihil) |
| `analysis_files_paths.txt` | File `*.dat`, referensi `.toml`/bahasa, path |
| `analysis_versions_errors.txt` | String versi/identitas + error/peringatan |
| `analysis_antitamper.txt` | Hasil pencarian kata kunci anti-root/anti-debug/anti-tamper |
| `analysis_indonesian.txt` | Pencarian string Indonesia (nihil) |
| `analysis_feature_keys_by_tab.txt`, `analysis_feature_keys_summary.json` | 956 kunci CamelCase + 50 string tab (heuristik alamat `.rodata`) |
| `analyze.py` | Skrip analisis (string map, xref `adrp`+`add`, ekstraksi) |

**Alat:** `rea doctor` (npx rea-agents) — Hopper/Ghidra/IDA/JADX semuanya
*missing* di VM ini. Disassembly memakai `llvm-objdump` dari Android NDK
26.1.10909125 (objdump sistem hanya x86 dan menolak AArch64).
Analisis memakai binutils (`readelf`, `nm`, `strings`) + Python
(`analyze.py`) + capstone 5.0.7 untuk verifikasi decode instruksi.

---

## 13. Cross-check vs laporan lama (8 Nov 2026) — perbandingan saja

Laporan lama (`~/workspace/rea-libcheatmenu64/REPORT.md`, file
`libCheatMenu64_0_k8rh.so`) dibaca **setelah** analisis di atas selesai,
hanya untuk membandingkan. Hasil perbandingan:

| Butir | Laporan lama | Temuan file ini | Status |
|---|---|---|---|
| SHA-256 | `1c678b9e…f043082` | `1c678b9ea476c8db83cbbdcb228f180c84d2dd955d4f2d29506e6e11ff043082` | **Sama — file identik byte-per-byte** |
| Identitas (v2.32, ARM, Grinch_) | Sama | Sama | Cocok |
| Ekspor AML (`OnModPreLoad`/`OnModLoad`/`OnAllModsLoaded`/`__GetModInfo`) | Sama | Sama (alamat sama) | Cocok |
| SAUtils wajib v1.6 | Teks UI v1.6 | Teks UI v1.6, **tapi kode cek ≥ 1.5.1** | **Koreksi/pendalaman baru** |
| AML minimum | Pesan "too old" | Kode cek ≥ 1.3.0 | Pendalaman baru |
| `ImGuiVirtualKeyboard` v0.2 | Tidak disebut | Ada cek plugin + versi | **Baru** |
| `net.rusjj.timecyc24` di `OnAllModsLoaded` | Tidak disebut | Ada; simpan nilai 24 | **Baru** |
| `OnAllModsLoaded` | Diasumsikan fungsi besar | Nyatanya 56 byte; fungsi besar berikutnya `0x159378` | **Koreksi** |
| `/proc/self/maps` | Tidak dibahas | Dijelaskan: cari base `libGTASA.so`, bukan anti-tamper | **Baru** |
| `fork`/`execvp` | Disebut "kemungkinan terkait download/install SAUtils" | Ternyata pembuka URL `xdg-open` | **Koreksi** |
| Updater | URL + "tidak ada bukti runtime" | + alur parse `atof`/`atoi`, `%s%s.mp3`, `QDATE`, kunci TOML; mekanisme fetch tetap tak terjawab | Pendalaman |
| Kunci CamelCase | 712 | 956 (regex lebih longgar — termasuk noise) | Perbedaan metodologi, bukan isi |
| Tab menu | ±28 nama | 42 nama berbeda (50 kemunculan) | Pendalaman |
| `modinfo` statis | "masih kosong" | Hampir kosong + 2 integer kecil + 2 float `-1.0`; 4 string konstruktor terverifikasi | Pendalaman |
| `Game version:` / `2.10 64bit` | Tidak disebut | Ada; tampil `2.10 64bit` atau `Unknown` | **Baru** |
| Disassembly | Tidak ada (objdump sistem gagal) | Lengkap via NDK `llvm-objdump` | **Baru** |

**Kesimpulan cross-check:** kedua file identik; tidak ada temuan laporan lama
yang terbukti salah secara substansi kecuali tiga hal yang kini terkoreksi:
(1) fungsi `fork`/`execvp` bukan terkait download/install SAUtils,
(2) `OnAllModsLoaded` bukan fungsi besar, (3) cek versi SAUtils di kode
adalah 1.5.1 bukan 1.6. Selebihnya laporan lama cocok dan analisis ini
memperdalamnya.
