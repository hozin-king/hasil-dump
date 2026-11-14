# REA + Dump — Traffic Rider v2.20 (SK Games)

**Status: ANALISIS SAJA. Tidak ada mod/menu/injector yang dibangun di repo ini, dan file game tidak diunggah/disebarkan ke mana pun.**
Tanggal analisis: 13–14 November 2026 (WIB). Target: mode solo/offline saja.
Versi sebelumnya di repo ini: `2.11` (dump + REA 2 Nov 2026).

## 1. Identitas file

| Item | Nilai |
|---|---|
| Sumber | XAPK resmi (tautan unduhan dihapus — minta ke Alyaa) |
| File unduhan | `trafficrider-v220.xapk` — 198.643.687 byte |
| SHA-256 XAPK | `a08838916024b2ef3bf97db6dc5c82e8efa27d927c5ad207c33e0263879779cf` |
| Tipe | Zip archive (XAPK v2, tanpa OBB) |
| Isi XAPK | `com.skgames.trafficrider.apk` (base, 48.309.255 byte), `config.arm64_v8a.apk` (split, 32.110.362 byte), 8 split asset pack, `icon.png`, `manifest.json` |
| Package | `com.skgames.trafficrider` |
| versionName / versionCode | `2.20` / `1006` (terverifikasi manifest.json XAPK + apktool.yml) |
| ABI | `arm64-v8a` saja (native lib hanya ada di split `config.arm64_v8a`) |
| minSdk / targetSdk | 29 / 36 |
| Activity utama | `com.unity3d.player.UnityPlayerActivity` |
| SHA-256 base APK | `0a777ddb99eaa62fcf496bb6daed7cc1f951709de3a03b471c65a41e48b4e35b` |
| SHA-256 split APK | `a5a22093a8775abbb9cb53d1c6ff201fd54e0904b47b24e7ee50026a1fc7b81c` |

Izin penting di manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `BILLING` (IAP), `AD_ID`, `VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `CHECK_LICENSE`, `READ_BASIC_PHONE_STATE`.

## 2. Engine & struktur

- **Unity (IL2CPP penuh)**. Bukti:
  - `lib/arm64-v8a/libunity.so` (22.677.952 byte, SHA-256 `415753e5de0635ebc57a51e23df94e2cffb4bbad81e1cf76be226d06feae2ae7`)
  - `lib/arm64-v8a/libil2cpp.so` (67.925.128 byte, SHA-256 `171debea63a2ff858203d39ef8faee2f9c853020d02e450e8d223df41b591326`)
  - `lib/arm64-v8a/libmain.so` (6.696 byte, SHA-256 `3dd4fe86a230a02a5c123e2275cf1df54ffdfe98cc27a9904ffc858097dccb0f`)
  - `assets/bin/Data/Managed/Metadata/global-metadata.dat` (9.655.816 byte, SHA-256 `0c0dd8b953889bcf682134653b841ddfbdd876b1030e5bf19bb695a92e78c719`)
  - Folder `Managed/` hanya berisi `Metadata/` + `Resources/` — **tidak ada DLL Mono** (murni IL2CPP).
- **Dump IL2CPP berhasil penuh** (Il2CppDumper lokal):
  - `dump/dump.cs` (27.473.393 byte, 3.165 class ter-parse, ±86.708 baris deklarasi method)
  - `dump/script.json.gz` (75.301.737 byte mentah → 5.558.239 byte gzip)
  - `dump/il2cpp.h.gz` (72.989.371 byte mentah → 1.999.838 byte gzip)
  - `dump/stringliteral.json` (1.560.245 byte, 18.437 string)
  - `dump/DummyDll/` (126 file, ±19 MB)
  - `dump/apk/AndroidManifest.xml` (hasil decode apktool dari base APK)
- Konvensi alamat di laporan ini: **RVA** = alamat virtual di dump; **file offset** = RVA − 0x4000 (terverifikasi lewat prolog fungsi yang ter-decode benar, sama seperti 2.11). Hook root-injector memakai alamat runtime = base `libil2cpp.so` + RVA.
- **File game (libil2cpp.so, XAPK, APK) TIDAK diarsipkan di repo ini** (sama seperti 2.11) — hanya dump turunan + laporan. Hash di atas cukup untuk verifikasi ulang.

## 3. Temuan per fitur (semua solo/offline)

### 3.1 Limiter kecepatan — `GameManager.FixedUpdate` (RVA 0x1C46EC0)

- Bila `GetSpeedKmh() > 500.0f` → `LoadMenuScene` langsung ke lobby, tanpa layar game-over.
- Konstanta 500.0f di VA 0x1C47308, word MOVZ `0x52A87F48` (offset +0x448 di dalam FixedUpdate).
- Speedometer di HUD tertinggal 1–2 frame dari `curSpeed` — saat kick, angka yang terlihat bisa lebih kecil dari nilai sebenarnya (mis. terlihat ±411 saat nilai sudah 617 dengan pengali 1,5x).
- Patch yang dipakai Traffic Rider Mod: v2.3 → 500.0f diganti 65536.0f; v2.4 → 655360.0f (`0x49200000`, MOVZ `0x52A92408`, terverifikasi clang). Scan tepat-1-hit + baca-balik, fail-closed.
- Konstanta 500.0f lain di dekatnya (VA 0x1C47CE0) adalah base SKOR, bukan limiter — tidak disentuh.

### 3.2 Anti-cheat skor — `GameManager.FixedUpdate` yang sama (RVA 0x1C46EC0)

- Tiap 0,5 detik (timer field `+0x34`, `Time.get_fixedDeltaTime`): bila `score` (field `+0x38`) naik lebih dari **500.000,0f** (konstanta rodata VA 0xA98F80) dari `oldScore` → `LoadMenuScene` (lobby). Instruksi kick: `bl` di offset **+0xFC**, word `0x9400FF4C`, target `0x1C86CEC` (= LoadMenuScene yang sama dengan §3.1).
- Mekanisme inilah penyebab kick di ±2000 km/h pada TR Mod v2.3 (limiter 500 sudah dipatch, tapi skor meledak): di 2000 km/h satu close call = **38.500 poin**; 13+ close call dalam satu jendela 0,5 detik (±277 m perjalanan) melampaui ambang.
- Patch yang dipakai TR Mod v2.4: NOP-kan SATU `bl` tersebut (`0x9400FF4C` → `0xD503201F`), syarat ganda fail-closed (tepat 1 hit di `[gm_fixed, gm_fixed+0x800)` DAN tepat di offset `+0xFC`, baca-balik). Skor **tidak diubah** — tetap terakumulasi normal, leaderboard tidak disentuh; hanya tendangannya yang dimatikan.
- Mekanisme sekunder `MotorMover.FixedUpdate` (posisi off-road + kecepatan → `Crash()`) TIDAK dipatch — perilaku vanilla.

### 3.3 Skor close call — `CloseCall` (RVA 0x1C47B3C)

- Tiap near-miss menambah `(speedKmh − 100) × 20 + 500` poin; **×2 saat wheelie**, **×3 di jalur lawan**.
- Memanggil `AddNitroTime` (RVA 0x1C6E540) — close call juga mengisi nitro.

### 3.4 `MotorMover` — field yang terverifikasi (v2.20)

| Field | Offset | Keterangan |
|---|---|---|
| `curSpeed` | 0x224 | m/s; ditulis langsung oleh hook speed TR Mod (torsi instan) |
| `curGear` | 0x124 | |
| `curRpm` | 0x128 | |
| `oldGasPressed` | 0x420 | |
| `oldBrakePressed` | 0x421 | |
| `vertical` | 0x2A8 | |

### 3.5 Kamera — `CameraMover.LateUpdate` (RVA 0x1C3E5FC)

- `cameraTrans` di offset `+0x120`; posisi digeser lewat `Transform.get/set_localPosition` (script.json: get `60160652 = 0x395FA8C`, set `60160844 = 0x395FB4C`).
- `cameraParentOffset` (0x1B4) dan `accelHeightOffset`/`accelForwardOffset` dihitung ulang tiap `LateUpdate`, jadi tidak bisa jadi input persisten; `currentFollowDistance` (0x104) tidak pernah dipakai `LateUpdate`.
- TR Mod v2.4 menggeser `cameraTrans.localPosition` setelah memanggil orig `LateUpdate` (naik/turun −2..+2 m, maju/mundur −5..+5 m).

### 3.6 Cuaca — `WeatherManager` (hanya bisa dibaca)

- `weatherList` 0x20, `evening/nightWeatherList`, `activeWeather` 0x70, `Weather.weatherName` 0x10.
- **Tidak ada method `SetWeather`** — hanya `SetRandomWeather` (RVA 0x1C88788) yang meng-apply ±7 setter Unity secara inline (`RenderSettings.set_fogColor/ambientLight`, `Camera.set_backgroundColor`, `Material.set_color/SetVector`, `Transform.set_position/Rotate`, lens flare).
- `SetRandomWeather` dan `GetActiveWeather` **tidak punya pemanggil `bl` di game** (scan seluruh .text: 0 caller) — menulis `activeWeather` saja tidak mengubah visual; mengedit list berarti menulis referensi objek ke managed heap tanpa write barrier GC (tidak aman). TR Mod v2.4 menampilkan daftar + cuaca aktif read-only, tanpa picker.

### 3.7 Kendaraan — `MotorManager` / `GameStateManager`

- 11 motor: Harley Davidson, ZX-10R, Ducati 1098R, Ninja 300, ZZR 1400, Hayabusa, Yamaha R1, Ducati Streetfighter, Multistrada, S1000RR, H2R.
- Indeks runtime dari statis `MotorManager.index*`; motor aktif dari `GameStateManager.selectedMotorIndex` (via `il2cpp_field_static_get/set_value`).
- Ganti motor **mid-run tidak mungkin** (motor di-spawn saat race start; tidak ada jalur respawn yang aman dari payload) — TR Mod v2.4 menulis `selectedMotorIndex`, berlaku untuk run berikutnya.

### 3.8 Nitro / wheelie (ada) — jump (tidak ada)

- Nitro: `curNitroTime` 0x358 / `maxNitroTime` 0x354; `AddNitroTime` (0x1C6E540) meng-cap ke max.
- Wheelie: `curWheelieValue` 0x334 / `curWheelieCharge` 0x338 / `maxWheelieValue` 0x33C; charge direset 0 di `PrepareToWheelie` (0x1C69BE0); cek "charged" berupa `>=`.
- TR Mod v2.4: toggle menulis ketiga meter ke max tiap FixedUpdate (guard NaN/rentang).
- **Jump TIDAK ADA di game** — tidak ada field/method Jump di `MotorMover`; yang ketemu hanya `CharacterController` Unity + DOTween.

## 4. Vonis per fitur (solo/offline saja)

| Fitur | Vonis | Bukti |
|---|---|---|
| Limiter kecepatan | Bisa dipatch (konstanta) | §3.1 |
| Anti-kick skor | Bisa dipatch (NOP 1 bl) | §3.2 |
| Skor / leaderboard | TIDAK diubah (server/leaderboard tidak disentuh) | §3.2 |
| Kamera (offset) | Bisa (hook LateUpdate) | §3.5 |
| Cuaca (ganti) | TIDAK bisa runtime (tanpa SetWeather) | §3.6 |
| Ganti motor mid-run | TIDAK bisa; run berikutnya bisa | §3.7 |
| Nitro / wheelie auto-full | Bisa (tulis meter) | §3.8 |
| Jump | TIDAK ADA di game | §3.8 |

## 5. Perbandingan dengan 2.11

- `libil2cpp.so` tumbuh 60.940.296 → 67.925.128 byte; `global-metadata.dat` 9.904.308 → 9.655.816 byte.
- `dump.cs` 23.581.644 byte (4.734 class) → 27.473.393 byte (3.165 class); `script.json` 65.612.470 → 75.301.737 byte; string literal 15.381 → 18.437.
- Mekanisme limiter 500 km/h dan anti-cheat skor sudah ada sejak 2.11 (bukan hal baru di 2.20); yang baru di 2.20 adalah pemetaan lengkap kamera/cuaca/motor/nitro/wheelie di atas.
