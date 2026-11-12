> Catatan arsip: Modul Zygisk (bukan APK): `Zygisk-ImGui` v1.0.0, author JR, nama modul "Free Fire". Package game target tidak disebut di laporan, jadi memakai slug modul. `customize.sh` membuka channel Telegram pembuat saat install.

# REA — Zygisk Module "Free Fire" (Zygisk-ImGui v1.0.0, author JR)

Sumber: `~/workspace/user/files/zygisk_0_gkup.zip`
SHA-256 zip: `18180f1e51aaf321aaf87782c0d950c768c60a4a5986f1d91d793a7ec70378b7`
Tanggal analisis: 12 Nov 2026 (statik saja — tanpa Ghidra/IDA, tanpa runtime).

## 1. Dump penuh (isi zip)

| File | Ukuran | Keterangan |
|---|---|---|
| `META-INF/com/google/android/update-binary` | 612 B | installer Magisk standar (template) |
| `META-INF/com/google/android/updater-script` | 8 B | `#MAGISK` |
| `customize.sh` | 163 B | skrip install (lihat §3) |
| `module.prop` | 88 B | `id=Zygisk-ImGui`, `name=Free Fire`, `version=v1.0.0`, `versionCode=1`, `author=JR` |
| `zygisk/arm64-v8a.so` | 1.143.016 B | payload utama (ARM64) |

Tidak ada: `service.sh`, `post-fs-data.sh`, `system/`, `sepolicy.rule`, file
32-bit (`armeabi-v7a.so` tidak ada — ARM64 saja), README, atau file config.

SHA-256 `zygisk/arm64-v8a.so`:
`b6edd9e750460f0a5fc09067640cb24a343b6a5a7d2f9cba60c83a04c2712465`

## 2. Payload `arm64-v8a.so` (statik)

- ELF 64-bit LSB, ARM aarch64, shared object, **stripped**, SONAME `libVM.so`,
  BuildID sha1 `3cd493befb67160197db3da0fcdbdaa34d72a50f`.
- NEEDED: `liblog`, `libandroid`, `libEGL`, `libGLESv3`, `libGLESv2`,
  `libGLESv1_CM`, `libz`, `libc`, `libm`, `libdl`.
- Simbol dinamis terdefinisi: 1948 (mayoritas libc++ `__ndk` + Dobby).
- Simbol kunci (terbukti dari `nm -D`):
  - `zygisk_module_entry` — entry point modul Zygisk (asli).
  - `DobbyHook`, `DobbySymbolResolver`, `A64HookFunction`,
    `A64HookFunctionV`, `CodePatch` — **framework hooking Dobby** (dibangun
    dari source di GitHub Actions — ada path `/Users/runner/work/Dobby/...`).
  - Impor runtime: `dlopen`, `dlsym`, `pthread_*`, `open`/`fopen`/`fread`/
    `fwrite`, `eglQuerySurface`, `getpid`.
- String kunci (terbukti dari `strings`):
  - API IL2CPP lengkap: `il2cpp_domain_get`, `il2cpp_class_from_name`,
    `il2cpp_class_get_method_from_name`, `il2cpp_class_get_methods`,
    `il2cpp_field_get_offset`, `il2cpp_field_static_get_value/set_value`,
    `il2cpp_method_get_name/param`, `il2cpp_image_get_name`,
    `il2cpp_string_new/chars`, `il2cpp_object_new`, `il2cpp_array_new`,
    `libil2cpp.so`, `Assembly-CSharp.dll`, `Player`.
  - ImGui: `imgui.ini`, `imgui_impl_opengl3`, `imgui_log.txt` + impor GL
    (`glCreateShader`, `glDrawElements`, `glGenTextures`, ...).
  - Pemindaian memori: `/proc/%d/maps`, `/proc/self/maps`,
    `/system/bin/app_process64`, `/system/build.prop`,
    `get_process_map_with_proc_maps`, `/libart.so`, `/libc.so`.
  - Menu: hanya string pendek `Menu`, `close`, `free`, `open`.
  - Compiler: clang 7.0.2 (NDK r328903) + clang 12.0.8 (NDK r416183c1)
    — dua toolchain, konsisten dengan Dobby (12.0.8) + payload (7.0.2).

## 3. `customize.sh` (perilaku install)

Skrip 163 byte: men-decode satu blob base64 lalu `eval`. Hasil decode-nya
adalah perintah yang membuka tautan Telegram `t.me/marcosmodsxo`
(channel promosi pembuat). Perintah ini TIDAK dijalankan saat analisis —
hanya dibaca sebagai temuan. Artinya: setiap kali modul ini di-install
lewat Magisk, installer membuka channel Telegram pembuatnya.

## 4. Vonis (dengan bukti)

- **Ini modul cheat game Unity/IL2CPP, target Free Fire** (module.prop
  `name=Free Fire`; IL2CPP API + `Assembly-CSharp.dll`; overlay ImGui +
  Dobby). Arsitektur khas mod-menu: cari method game lewat API IL2CPP,
  hook dengan Dobby, tampilkan menu ImGui di atas render OpenGL.
- **Daftar fitur TIDAK bisa dipastikan dari analisis statik.** Tidak ada
  satu pun nama fitur (aimbot/ESP/headshot/dll) dalam plaintext; tidak
  ada nama package target (`com.dts.*`) maupun nama method game dalam
  string. Satu blob biner ~12 KB di `.rodata` berisi data ter-encode
  (bukan XOR 1-byte — diuji semua 256 kunci, tidak ada decode yang
  menghasilkan teks terbaca); kemungkinan besar di sanalah string menu /
  nama method / config disembunyikan (atau itu aset font/gambar).
- **Tidak ada string anti-deteksi** (magisk hide / bypass / SafetyNet /
  root) dalam plaintext; tidak ada URL server / C2; tidak ada string
  kredensial.
- **Tidak ada hook eglSwapBuffers sebagai impor** — render overlay
  kemungkinan dipasang lewat `dlsym` runtime atau lewat hook method
  game (tidak terlihat statik).

## 5. Batasan analisis

- Tanpa Ghidra/IDA/Hopper di VM ini, dekompilasi pseudocode TIDAK
  tersedia; tanpa runtime (game + perangkat), perilaku hook, daftar
  fitur, dan target method TIDAK bisa dikonfirmasi.
- Untuk memastikan fitur + method yang di-hook, jalurnya: jalankan di
  perangkat dengan Frida/`libriru` tracing, atau dekompilasi dengan
  Ghidra di luar VM ini.

## 6. Catatan keamanan

- Modul ini JANGAN di-install sembarangan: selain risiko ban akun Free
  Fire (game online), `customize.sh`-nya membuka tautan luar saat
  install, dan isi blob ter-encode tidak bisa diaudit dari sini.
- REA ini analisis saja — bukan pembuatan/pemasangan injector.
