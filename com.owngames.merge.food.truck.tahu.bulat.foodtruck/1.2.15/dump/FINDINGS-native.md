# FINDINGS — Native (Food Truck City 1.2.15 / code 35)

Semua .so hanya ada di split `config.arm64_v8a` (ABI arm64-v8a saja).
Toolchain: NDK Clang 9.0.8. Semua ELF64 AArch64.

## 1. Daftar library

| Library | Ukuran | Peran |
|---|---|---|
| `libnative-lib.so` | 1.800.352 B | Kode game (stripped, hanya .dynsym) |
| `libownengine.so` | 2.271.472 B | Framework Own Engine (UI, save, IAP, GPGS) |
| `libownbox2d.so` | 551.080 B | Fisika Box2D |
| `libownlibxml.so` | 1.983.848 B | XML (konfigurasi level) |

`libnative-lib.so` butuh `libownlibxml` + `libownengine` + EGL/GLESv2/log/m/dl/c
(render OpenGL ES, bukan Unity/Godot).

## 2. OwnSaveData (libownengine.so mengekspor, libnative-lib.so mengimpor)

Ekspor `libownengine.so`:
- `_ZN11OwnSaveData4loadEv` (0xf4f28)
- `_ZN11OwnSaveData4saveENSt6__ndk112basic_string...` (0xf4dd0, overload string)
- `_ZN11OwnSaveData4saveEPc` (overload char*)
- `_ZN11OwnSaveDataC1ENSt6__ndk112basic_string...S6_` (0x1490b4 di Tahu Bulat;
  di sini C1/C2 string + char*)
- `OwnIAPManager::getItemDesc/getPriceFor/isUdahBeliIAP/setMyGameId`
- `OwnGPGSManager::doLoadCloud/doSaveCloud` (cloud save Google Play Games)
- `Java_com_owngames_ownengine_sdk_iap_IAPManager_IAPDataBought__...`
  (jembatan JNI IAP)

Impor `libnative-lib.so`: ketiga simbol OwnSaveData
(`save(char*)` GOT 0x1b5260, `load()` GOT 0x1b5fe8,
`C1(string,string)` GOT 0x1b6e40).

## 3. Konstruktor save — 4 file save, masing-masing key DES sendiri

PLT stub `OwnSaveDataC1` = **0x79460**
(`adrp x16,#0x1b6000; ldr x17,[x16,#0xe40]` → GOT 0x1b6e40).
Ditemukan **4 call site BL** ke stub ini di `.text` (capstone + pyelftools,
pemetaan PLT via decode adrp+ldr tiap stub — 1.452 target terpetakan):

| Call site | File save (arg 1) | Keterangan |
|---|---|---|
| 0xdc7f8 | `Config` | string literal .rodata 0x1672dd |
| 0xdd7c4 | `Data` | string literal .rodata 0x1683a6 |
| 0xe9334 | `Achievement` | string literal .rodata 0x167d10 |
| 0xf019c | `AnalyticData` | string literal .rodata 0x16839e |

Pola tiap call site (contoh 0xdc7f8): `operator new(56)` → bangun 2
`std::string` sementara di stack dari literal .rodata via ctor string
(`bl 0x766e0`) → `x0=this, x1=&filename, x2=&key` → `bl OwnSaveDataC1`
→ simpan pointer ke member objek.

**Nama file save + key TIDAK tersimpan sebagai literal polos yang mudah
dicari** (raw byte search `Datadata`/`.own`/`.bin` di .so dan dex: 0 hit) —
keduanya baru terlihat setelah tracing BL ke PLT stub + resolve ADRP+ADD
di tiap call site. String `Config`/`Data`/`Achievement`/`AnalyticData`
sendiri adalah literal .rodata biasa.

**Nilai key DES TIDAK ada di dump publik ini.** Key disimpan hanya di file
lokal peneliti untuk keperluan decrypt save user + merge Save Tool v1.2.0.
Yang dicatat di sini: nama file + alamat konstruksi saja.

## 4. Anti-cheat / root detect

- String search `libnative-lib.so` (`root|magisk|frida|xposed|ptrace|
  TracerPid|safety|integrity|cheat|tamper`): **tidak ada hit relevan**
  (hanya `PopToRoot`, `moveRootChildToFront`, `strictRoot` — istilah
  scene-graph, bukan deteksi).
- Tidak ada deteksi root / emulator / Play Integrity / anti-tamper yang
  teridentifikasi di library native.

## 5. Network (native strings)

- `https://own-games.com/privacypolicy.php`
- `https://play.google.com/store/apps/details?id=com.owngames.merge.food.truck.tahu.bulat.foodtruck`
- `https://play.google.com/store/apps/details?id=com.owngames.tahubulat`
- Tidak ada endpoint API lain di native strings.
