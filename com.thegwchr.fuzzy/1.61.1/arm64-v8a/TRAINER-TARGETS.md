# Pemetaan Target Trainer — GTAV Mobile "Fuzzy" 1.61.1 (story mode saja)

**Tanggal:** 22 November 2026
**Sumber:** dump teks `~/workspace/rea-gtav-mobile/dump-full/` (exports dinamis + strings `libgtav.so`) — **APK/.so sudah dihapus**, jadi pemetaan ini level NAMA/SIMBOL, bukan alamat.
**Ruang lingkup:** trainer STORY MODE offline saja. Online (server privat "Gooneral Wheelchair Social Club", pemain beneran) TIDAK masuk — cheat lawan pemain nyata tidak dibangun.

## 1. Temuan kunci: tabel native GTA V lengkap ada di dalam game

`libgtav.so` mendaftarkan native script GTA V sebagai wrapper C++ (`scrWrapped_*` via
`SetupScriptCommands` per grup). Total ±40 grup, ±5.700 wrapper — ini tabel native yang
sama dengan yang dipakai trainer PC (ScriptHookV/Menyoo). Artinya trainer tidak perlu
menebak fungsi: panggil native berdasarkan hash, persis pola PC.

| Grup | Jumlah | Isi relevan |
|---|---|---|
| network_commands | 858 | cek sesi online (lihat §4) |
| vehicle_commands | 774 | kendaraan |
| ped_commands | 656 | ped / armour |
| hud_commands | 525 | HUD |
| graphics_commands | 454 | grafis |
| stats_commands | 454 | stat / progres |
| task_commands | 398 | task AI |
| misc_commands | 385 | cuaca, super jump |
| money_commands | 333 | uang |
| audio_commands | 285 | audio |
| camera_commands | 265 | kamera |
| player_commands | 253 | pemain / wanted |
| entity_commands | 216 | entity / health / teleport |
| object_commands | 210 | objek / pickup uang |
| socialclub_commands | 170 | Social Club |
| weapon_commands | 123 | senjata / ammo |
| + 24 grup lain | ±1.000 | streaming, clock, fire, path, dsb. |

## 2. Target per fitur (semua terbukti ADA sebagai wrapper native)

### God mode / health
- `SET_PLAYER_INVINCIBLE` (player_commands) — god mode pemain.
- `SET_PLAYER_INVINCIBLE_BUT_HAS_REACTIONS` — god mode tapi tetap bereaksi (jatuh dsb.).
- `SET_ENTITY_HEALTH` / `GET_ENTITY_HEALTH` (entity_commands) — set nyawa entity apa pun.
- `SET_ENTITY_INVINCIBLE` (entity_commands).
- `SET_PLAYER_HEALTH_RECHARGE_MULTIPLIER` / `SET_PLAYER_HEALTH_RECHARGE_MAX_PERCENT` — regen.
- Kelas pendukung di strings: `CPedHealthDataNode`, `CVehicleHealthDataNode`,
  `CPhysicalHealthDataNode`, `CPlayerSpecialAbilityManager`, `CGameLogic::ResurrectLocalPlayer`.

### Wanted level
- `SET_PLAYER_WANTED_LEVEL`, `SET_PLAYER_WANTED_LEVEL_NOW`, `CLEAR_PLAYER_WANTED_LEVEL`.
- `SET_WANTED_LEVEL_DIFFICULTY`, `RESET_WANTED_LEVEL_DIFFICULTY`,
  `SET_WANTED_LEVEL_MULTIPLIER`, `SET_PLAYER_WANTED_LEVEL_NO_DROP`,
  `SET_PLAYER_WANTED_CENTRE_POSITION`, `SET_WANTED_LEVEL_HIDDEN_ESCAPE_TIME` (+RESET).
- `SET_WANTED_RESPONSE_NUM_PEDS_TO_SPAWN` / RESET (misc_commands).

### Senjata / ammo
- `GIVE_WEAPON_TO_PED`, `GIVE_WEAPON_OBJECT_TO_PED`,
  `GIVE_WEAPON_COMPONENT_TO_PED` / `..._TO_WEAPON_OBJECT`.
- `SET_PED_AMMO`, `SET_PED_AMMO_BY_TYPE`, `SET_PED_AMMO_TO_DROP`.
- `SET_PED_ARMOUR`, `ADD_ARMOUR_TO_PED` (ped_commands).

### Kendaraan
- `CREATE_VEHICLE` (spawn kendaraan apa pun), `SET_VEHICLE_FIXED` (perbaiki),
  `SET_VEHICLE_ENGINE_HEALTH`, `SET_VEHICLE_UNDRIVEABLE`.

### Teleport / dunia
- `SET_ENTITY_COORDS`, `SET_ENTITY_COORDS_NO_OFFSET`,
  `SET_ENTITY_COORDS_WITHOUT_PLANTS_RESET`, `GET_ENTITY_COORDS`.
- `SET_CLOCK_TIME` (clock_commands), `SET_WEATHER_TYPE_NOW` (+PERSIST),
  `SET_SUPER_JUMP_THIS_FRAME` (misc_commands).

### Uang — ADA, tapi jalurnya tidak sesederhana "set uang"
- `money_commands` (333 wrapper) berisi `MoneyInterface::EarnCash` / `SpendCash`,
  `MoneyInterface::ConsumeCashProduct`, `CPickupManager::CreateSomeMoney`,
  `object_commands::CommandCreateMoneyPickups`.
- **Tidak ditemukan** satu native `SET_MONEY` langsung. Uang story mode mengalir lewat
  `MoneyInterface`/stat — rute trainer yang realistis: `EarnCash` / spawn pickup uang /
  edit stat. Perlu verifikasi runtime; jangan janjikan "uang tak terbatas 1 klik"
  sebelum terbukti.

## 3. Cara trainer jalan (pola PC, diadaptasi ke port ini)

1. **Panggil native by hash** — seperti ScriptHookV: cari tabel registrasi native di memori
   saat runtime, lalu panggil `SET_PLAYER_INVINCIBLE` dsb. lewat `rage::scrThread`.
2. **Thread sendiri** — infrastruktur ada: `rage::scrThread`, `rage::scrProgram`,
   `CTheScripts::GtaStartNewThreadWithProgramId`, `CGameScriptHandlerMgr::GetScriptId`.
   Trainer jalan sebagai script thread sendiri, tick per frame.
3. **Loader** — dua jalur yang masuk akal:
   - (a) Injector root pola HCR/HSW (ptrace GETREGSET, stage `.so` dari nativeLibraryDir,
     status via file 666 pre-create) — pola yang sudah terbukti di POCO.
   - (b) Nempel ke rantai hook bawaan port: APK sudah membawa `libmain_hook`
     (hook `android_dlopen_ext`), `libfile_redirect_hook`, `libgsl_alloc_hook`,
     `libfzvulkan` (adrenotools) — port ini memang dimuat lewat hook chain.
4. **Menu** — game render Vulkan (`libfzvulkan`); overlay butuh ImGui yang paham Vulkan,
   atau pakai infra sentuh bawaan launcher (JNI: `nativeTouchDrawList`,
   `nativeTouchEditor`, `nativeTouchGlyph`, `nativeTouchHint`, `nativeTouchPreview`).
5. **Pengaman wajib** — version gate Fuzzy 1.61.1 saja, fail-closed (native tidak ketemu =
   fitur mati, bukan crash), dan gate solo (§4).

## 4. Gate solo-only (bisa diimplementasikan)

- Native `NETWORK_IS_IN_SESSION` / `NETWORK_IS_SESSION_STARTED` (network_commands).
- Flag native `rage::s_InOnlineSession` + JNI `nativeInOnlineSession`
  (launcher sudah mengeksposnya ke Java).
- Aturan: trainer MENOLAK aktif selama sesi online berjalan; hanya story mode.

## 5. Yang BELUM bisa dipetakan dari dump teks (batas jujur)

- **Tidak ada RVA/alamat.** Dump hanya berisi export dinamis (488 baris — cuma 3 simbol
  `rage::*`, semuanya helper kompresi tekstur `grcBcFormat`) + strings. Simbol internal
  RAGE (`CPed`, `CPlayerInfo`, dst.) hidup di `.symtab` `libgtav.so` — file `.so`-nya
  sudah dihapus sesuai aturan. Alamat hanya bisa didapat dengan: unduh ulang APK →
  ekstrak `libgtav.so` → `llvm-nm`/Ghidra → hapus lagi. Itu keputusan terpisah.
- **Alamat wrapper native tidak ada di dump.** Nama `scrWrapped_*` membuktikan wrapper
  ADA, tapi alamatnya harus dicari di memori saat runtime (tabel registrasi native).
- **Belum ada verifikasi runtime.** Game belum pernah jalan di sini; data ±64 GB belum
  ada; tidak ada klaim soal kelancaran, crash, atau deteksi.
- **Uang** (§2) dan **struktur field** (offset health di `CPed`, dsb.) belum terpetakan —
  butuh `.so` + analisis lanjutan.
- **Deteksi anti-cheat server privat tidak diketahui.** Server "Gooneral" milik operator;
  perilaku server terhadap trainer tidak bisa ditebak dari statis. Alasan tambahan
  kenapa trainer HANYA untuk story mode offline.

## 6. Estimasi kasar (bila lanjut ke build)

- Riset alamat + pola native (butuh `.so` lagi): ±0,5–1 hari.
- Loader + thread script + menu dasar + 5–6 fitur inti (god, wanted, health, ammo,
  teleport, kendaraan): ±2–4 hari kerja, TANPA jaminan sampai ada game jalan di POCO
  buat ngetes (butuh install APK + unduh 64 GB + akun server operator — risiko di
  laporan REA §6–7 tetap berlaku).
- Build TIDAK dipesan di sini — pemetaan saja, sesuai perintah user.
