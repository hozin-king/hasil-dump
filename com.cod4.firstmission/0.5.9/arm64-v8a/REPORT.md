> Catatan arsip: file sumber bernama `REA-COD4-v0.5.9.md`, disalin sebagai `REPORT.md`.

# REA — COD4 Android Launcher v0.5.9 (ARM64, APKVision)

- File: `COD4-v0.5.9-ARM64-APKVision.apk`, 49,5 MB (51.937.?? byte di disk, unzip total 56.984.324)
- SHA-256: `a3b27a738b94dfddfa9e71ea43838946dce3a7bed9362f1f113b94f07935622c`
- Package: `com.cod4.firstmission`, versionCode 26, versionName 0.5.9, minSdk 24, targetSdk 36
- Label: "COD4 Android Launcher", landscape, permission: INTERNET + ACCESS_NETWORK_STATE, usesCleartextTraffic=true
- Aktivitas: MainActivity (launcher), MultiplayerActivity (proses `:mp`), CampaignActivity (proses `:sp`), DriverProbeActivity (proses `:gpu_probe`)
- Metode: apktool 2.10.0 decode + `strings`/`nm`/`readelf` pada .so. Tidak ada Ghidra/IDA di VM, jadi tidak ada dekompilasi native penuh — kesimpulan di bawah dari string, simbol JNI, dan smali launcher, bukan dari pseudocode.

## Ini bukan game Android native biasa

APK ini adalah launcher + engine port, bukan game Unity/IL2CPP:

- `lib/arm64-v8a/libcod4first.so` ~10,9 MB — engine campaign (SP)
- `lib/arm64-v8a/libcod4mp.so` ~10,9 MB — engine multiplayer (MP), CoD4X
- `lib/arm64-v8a/libc4vk.so` ~0,9 MB, `libc4icd_hal.so` — terjemahan Vulkan (ANGLE/AdrenoTools)
- `libhook_impl.so`, `libmain_hook.so`, `libfile_redirect_hook.so`, `libgsl_alloc_hook.so` — hook launcher
- `assets/cod4x/` — `cod4x_patch.ff`, `cod4x_patchv2.ff`, `cod4x_ambfix.ff`, `jcod4x_00.iwd`
- `assets/drivers/` — paket driver Vulkan (PanVK, Mali, Mesa Turnip, RADV)
- Java launcher (`com.cod4.firstmission`): kontrol sentuh, DriverHub, AssetDownload, Cod4xResources, ConsoleKeyboard, ServerAddress, connectServer()
- Data game asli COD4 (map, model, suara) TIDAK penuh di APK ini — launcher mengunduh/memeriksa resource CoD4X dari `raw.githubusercontent.com/callofduty4x/CoD4x_Client_pub/.../assets/cod4x/zone/` dan resource lain saat instalasi/koneksi. Jadi patch statis APK saja belum cukup; cheat runtime harus jalan setelah engine + data ter-load.

## Bukti multiplayer online nyata (bukan bot-only)

- `MultiplayerActivity` + `MainActivity.connectServer()`: dialog input alamat, kirim perintah konsol `connect <alamat>` ke engine MP.
- String MP: `globalservers`, `%d servers parsed`, `sv_maxclients`, `sv_pure`, `sv_punkbuster`, `cl_punkbuster`, `was kicked for cheating`, `SV_SendMessageToClient`, `CL_ParseServerMessage`, `CG_ProcessSnapshots: Server time went backwards`.
- Server bersifat host-authoritative untuk snapshot, configstring, dan validasi. `sv_cheats` di MP hanya berlaku bila server mengaktifkannya — server publik tidak.
- Launcher sendiri membedakan lokal vs remote: string UI menyebut sv_cheats hanya efektif di mesin lokal dan bila tidak ada pemain remote asli; bot AI dikendalikan skrip GSC.

## Bukti teknis untuk ESP / aimbot / teleport (di level engine)

Ada, di kedua .so (stripped, hanya JNI `Java_com_cod4_firstmission_MainActivity_native*` yang diekspor):

- Entitas client: `CG_GetEntity`, `CG_GetLocalClientGlobals(...)->nextSnap`, `cgameGlob->predictedPlayerState.clientNum`, `cg_ents_mp.cpp`, `cg_players_mp.cpp`, `cg_snapshot_mp.cpp`, `cg_view_mp.cpp`, `cg_pose_mp.cpp`.
- Tulang/posisi: `AimTarget_GetTagPos: Cannot find tag [%s] on entity`, matriks tulang `boneMatrix`, `CG_GetPlayerViewOrigin`, `CG_FOV ... PROJECTION_MODE`, `refdef`.
- Aim assist bawaan engine (bukan aimbot eksternal): `aim_autoaim_enabled`, `aim_autoaim_region_width/height`, `aim_lockon_enabled`, `aim_lockon_strength`, `aim_lockon_region_*`, `aim_slowdown_enabled`, `aim_slowdown_yaw_scale`, `aim_turnrate_*`, file sumber `src/aim_assist/aim_assist.cpp`, `aim_target_mp.cpp`.
- Teleport / gerak bebas bawaan SP: `cg_ufo`, `cg_noclip`, `setviewpos`, `cg_setviewpos`, `noclip`. Di MP, `setviewpos` dibatasi server (`isn't very useful when server controlled`).
- Cheat gate bawaan: `%s is cheat protected`, `sv_cheats`, `Allow server side cheats`, `Enable cheats on the server`, `Saving games from the console is cheat protected`.
- SP juga punya: `mis_cheat`, `cheat_points`, `cheat_items_set1/2`, opsi Android `cheats=%d` di `ANDROID_OPTIONS`.

Artinya, secara teknis: ESP (proyeksi posisi entitas lewat refdef), aimbot (hitung sudut ke tag kepala lalu tulis viewangle), dan teleport (tulis origin / setviewpos) adalah pola yang dikenal untuk engine Quake3 turunan ini — TAPI di MP publik semuanya melawan otoritas server + sv_pure + PunkBuster, dan akan di-snap-back, ditolak, atau di-kick.

## Klasifikasi server vs lokal (verdict per fitur)

| Fitur | Campaign solo (SP) | MP server sendiri, bot saja, 0 pemain remote | MP publik / server orang lain, vs pemain asli |
|---|---|---|---|
| ESP (kotak/nama/HP musuh) | Bisa, sebagai overlay debug lokal | Bisa, lawan bot lokal saja | DITOLAK — keunggulan real-time vs manusia |
| Auto-aim / aim assist bawaan (tuning dvar) | Bisa | Bisa | DITOLAK bila mengubah aim vs manusia |
| Aimbot / aim headshot (snap ke tag kepala) | Bisa secara teknis, solo saja | Bisa, lawan bot lokal saja | DITOLAK — aimbot vs manusia |
| Teleport / noclip / setviewpos | Bisa (cg_ufo/cg_noclip bawaan) | Bisa di server sendiri | DITOLAK + tidak efektif (server authoritative, kick) |
| God / unlimited ammo via sv_cheats | Hanya bila sv_cheats aktif lokal | Hanya bila server sendiri set sv_cheats 1 | Tidak bisa / DITOLAK |

Aturan gate yang wajib bila ada build lanjutan: mod menu HARUS mati total (fail-closed) begitu mode MP dengan pemain remote terdeteksi — bukan sekadar toggle manual. Deteksi yang dipakai: proses `:mp` + koneksi ke alamat non-lokal, atau ada client remote di snapshot/server. Tanpa gate ini, build tidak dibuat.

## Yang belum terverifikasi (jangan diklaim)

- Offset pasti entity list, refdef, viewangle, dan tag_head di build ARM64 ini — butuh runtime scan di HP root (proses `:sp`/`:mp` hidup, data ter-load), bukan dari string saja.
- Apakah server komunitas tertentu mengaktifkan sv_pure/PunkBuster secara ketat — bervariasi per server, tapi string di atas membuktikan mekanismenya ada.
- Performa / stabilitas port ini di POCO X6 Pro — belum dites di HP.
- Legalitas data COD4 asli — APK ini launcher/port komunitas (CoD4X), bukan rilis resmi Activision di Play Store. Jangan distribusikan ulang data game berhak cipta.

## Kesimpulan

Audit selesai. Cheat/mod menu model ESP + aimbot + teleport + headshot SECARA TEKNIS memungkinkan di engine ini, TAPI hanya sah dibangun untuk Campaign solo atau server bot lokal. Untuk MP publik vs pemain asli, jawabannya tidak — ditolak, dan secara teknis juga akan kena snap-back/kick.
