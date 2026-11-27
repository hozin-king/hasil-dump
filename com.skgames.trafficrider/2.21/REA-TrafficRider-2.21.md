# REA — Traffic Rider 2.21 (com.skgames.trafficrider, code 1010)

Tanggal: 27 Nov 2026. Perintah user 15:02 WIB: dump full + REA karena
pengali kecepatan di injector TR "auto-keluar" setelah game update padahal
diminta tahan update, dan anti-kick skor gagal (diagnosis HP 14:58:
god/noclip/speed aktif, anti-kick skor gagal).

## 1. Identitas sumber (terverifikasi)

| Item | Nilai |
|---|---|
| Paket | `com.skgames.trafficrider` |
| versionName / versionCode | **2.21 / 1010** (aapt, minSdk 32, targetSdk 36) |
| Sumber | APKMirror, diunggah 13 Nov 2026, bundle `.apkm` 10 split, arm64-v8a + arm-v7a, Android 12L+ |
| File sumber | `browser-download-...-com.skgames.trafficrider_2.21-1010_2arch_8feat_....apkm` — **183.835.295 byte**, SHA-256 `fdcd4485f0597d51cd364405c274af79acf9023c4530633846f603f096cd0596` |
| `libil2cpp.so` (arm64) | 67.925.912 byte, SHA-256 `87be919cb1d66141d069adb2950fb7d8b969d2a8b9d3fa473eef579bbdf6c363`, stripped |
| `libunity.so` (arm64) | 22.677.952 byte |
| Unity | **6000.5.11f1** (dari string libil2cpp.so) |
| Metadata | `global-metadata.dat` 9.655.896 byte, magic `0xFAB11BAF`, **version 107** |
| IAP / lisensi | `com.android.vending.BILLING` + `CHECK_LICENSE` ada — IAP TIDAK disentuh |

Catatan jujur (wajib): game IL2CPP **tidak membawa `Assembly-CSharp.dll`
asli** — kode C# sudah dikompilasi menjadi native `libil2cpp.so`. DLL di
folder `dump/DummyDll/` adalah **dummy hasil Il2CppDumper** (hanya
signature tipe/metode, tanpa isi kode). "Decompile" di sini = dump.cs +
dummy DLL + disassembly native terarah (capstone) di sekitar fungsi hook,
BUKAN decompile C# penuh ala dnSpy (tidak mungkin untuk IL2CPP; VM juga
tidak punya Ghidra/IDA).

## 2. Cara dump — masalah metadata v107 (dan solusinya)

Dumper lama menolak metadata ini:

- Il2CppDumper lama (`~/workspace/tools/il2cppdumper/`, Perfare, ≤ v29)
  dan MyDearMoon v1.4.0 sama-sama menolak: "not a supported version[107]"
  / "encrypted or obfuscated (Magic: 0xFAB11BAF instead of 0xFAB11BAF)"
  (magic-nya cocok — penolakannya soal versi/layout, bukan enkripsi).
  Patch byte versi 107→106 pada salinan metadata juga tidak membantu.
- Penyebab: angka **107 di Unity 6.5.1 adalah nomor saja** — layout-nya
  tetap **v106.0** (106.1 butuh Unity ≥ 6.6.0a6). Rodroid
  (`rodroidmods/rodroid-il2cppdumper`) mendukung v104–108 tapi hanya GUI
  (Tauri), tidak ada CLI headless yang bisa dipakai di VM ini.

Dua jalur dikerjakan, keduanya saling memvalidasi:

### Jalur A — parser Python sendiri (`il2cpp106.py`)

Ditulis dari layout struct rodroid (`structures.rs` / `base.rs` /
`elf.rs` / `section_helper.rs`):

- Header metadata dibaca penuh (semua section, triple
  offset/size/count); section terbukti kontigu. Hasil: **12.869 type
  definition, 86.704 method, 53.565 field, 92.087 parameter,
  125 image/assembly**.
- Registrasi ditemukan dengan algoritma rodroid `find_code_registration_2019`
  (string `mscorlib.dll` → modul → array `code_gen_modules` → walk-back)
  dan `find_metadata_registration_v21` (dua count 12.869 yang sama).
- **Temuan kunci: pointer-pointer di `.data.rel.ro`/`.data` file ini
  berisi 0 di disk** — nilai aslinya hanya ada di `.rela.dyn` sebagai
  addend relokasi `R_AARCH64_RELATIVE` (420.014 entri). Semua baca pointer
  harus lewat peta relokasi (`relmap[VA]`, fallback isi on-disk). Inilah
  alasan scan naif (baca pointer mentah) menemukan "kandidat" palsu dan
  modul 0.
- Hasil: `CodeRegistration @ VA 0x3c247b8`,
  `MetadataRegistration @ VA 0x3d78d30`, 125/125 modul termuat, jumlah
  method pointer semua modul = **86.704 = persis jumlah method di
  metadata**. RVA method = `module_ptrs[(token & 0xFFFFFF) - 1]` di image
  masing-masing; **77.680/86.704 RVA non-nol, 0 di luar segmen executable**.
- Dua selisih layout vs rodroid (dicatat jujur, tidak memengaruhi RVA):
  (a) `Il2CppCodeRegistration` biner ini memakai urutan
  **(pointer, count)**, bukan (count, pointer) seperti dibaca rodroid —
  buktinya slot [0]=ptr + [1]=87, [2]=ptr + [3]=92.524, dst; dan
  `codeGenModules` ada di slot 16/17 (fork menemukan CR di 0x3c247c0,
  satu slot sesudah hitungan saya — struct 17 slot, bukan 18).
  (b) `Il2CppCodeGenModule` Unity 6.5 **tidak lagi membawa back-pointer**
  `metadata_registration`/`code_registration` (slot 15/16 = 0 di semua
  125 modul); ada 3 slot tambahan di ekor struct (nilai `3, 0xe00d64, 2`
  pada modul mscorlib — tujuan belum teridentifikasi).

### Jalur B — fork Il2CppDumper snowyegret23 (validasi independen)

Fork `snowyegret23/Il2CppDumper` (commit `2a10ec57`, .NET 8, sudah ada di
`~/workspace/rea-trafficrider-v220/dumper-run/`) dijalankan dengan
`dotnet Il2CppDumper.dll` atas lib + metadata 2.21 — **berhasil penuh**:
`CodeRegistration : 3c247c0`, `MetadataRegistration : 3d78d30` (MR sama
persis dengan jalur A; CR beda 8 byte, lihat butir (a) di atas),
`dump.cs` + `DummyDll` + `il2cpp.h` + `script.json` +
`stringliteral.json`. (Peringatan "This file may be protected" dari
fork hanya karena `JNI_OnLoad` ada — bukan proteksi nyata; dump tetap
jalan sampai selesai.)

**Validasi silang: 77.680/77.680 RVA hasil parser Python IDENTIK dengan
RVA di `dump.cs` fork (irisan dua arah kosong — nol selisih).** Semua
angka di laporan ini memakai RVA yang sudah tervalidasi dua jalur.

Isi dump (folder `dump/`):

| File | Ukuran | Keterangan |
|---|---|---|
| `dump.cs` (+ `.gz`) | 27.473.617 byte | SHA-256 `adb41b1648b369f0a6a611fa5d8da3cdc4eb97b2d8dad8b679346703f279af04`; di-gzip karena > 25 MB (batas blob API) |
| `DummyDll/` (126 DLL) | 19 MB total | Dummy Il2CppDumper, termasuk `Assembly-CSharp.dll` 998.912 byte, SHA-256 `7ae36b89fb2ab269431b65865e5dfee17a67cf91168c6d7ea75dc154e30c60e7` |
| `il2cpp.h` (+ `.gz`) | 72.989.371 byte | header C++ hasil generate |
| `script.json` (+ `.gz`) | 75.302.246 byte | `ScriptMethod` (address + signature), dipakai IDA/Binja |
| `stringliteral.json` | 1.560.248 byte | string literal metadata |
| `il2cpp106.py` | — | parser Python jalur A (dokumentasi metode + bisa dipakai ulang) |

`libil2cpp.so` mentah TIDAK di-upload (sesuai aturan).

## 3. Jawaban utama — kenapa pengali kecepatan "auto-keluar"

Ringkasan satu kalimat: **bukan pengali kecepatannya yang pecah — yang
pecah adalah anti-kick skor; pada kecepatan tinggi skor melonjak melewati
ambang tendangan, game menendang ke lobby, dan user merasakannya sebagai
"game auto-keluar saat pakai speed".** Rantai sebabnya, terbukti di level
instruksi:

1. **Update 2.20 → 2.21 menggeser semua kode**: kode game **+0x98 /
   +0xA4** (152/164 byte), kode engine Unity **+0x158** (344 byte).
   Contoh: `HandleSpeed` 0x1C6C108 → 0x1C6C1A0; `Crash` 0x1C6C688 →
   0x1C6C720; `OnTriggerEnter` 0x1C6D844 → 0x1C6D8E8;
   `GameManager.FixedUpdate` 0x1C46EC0 → 0x1C46F58; `LoadMenuScene`
   0x1C86CEC → 0x1C86D90 (tabel lengkap §5).
2. **Pola byte fallback injector mati total di 2.21.** 13 dari 14 pola
   32-byte v2.20/v2.11 di `patterns.h` injector v1.3 mencatat **0 hit**
   di `.text` 2.21 (hanya pola `MM_FIXEDUPDATE_V220` yang masih cocok 1x
   di 0x1C6A644 — prologuenya kebetulan tidak berubah). Penyebabnya
   instruksi `ADRP` di dalam prologue: immediate-nya mengodekan jarak
   halaman ke target data, dan target itu ikut bergeser — jadi byte
   prologue berubah meski logika fungsi sama.
3. **God/noclip/speed tetap "aktif" di HP karena jalur UTAMA injector
   adalah resolusi nama IL2CPP** (`il2cpp_class_from_name` +
   `il2cpp_class_get_method_from_name`), yang tidak peduli alamat —
   nama method tidak berubah antar versi. Jadi hook-hook itu selamat;
   injector sekarang berjalan dengan satu kaki (bila resolusi nama
   gagal, tidak ada fallback pola yang hidup).
4. **Anti-kick skor TIDAK punya jalur nama** — ia mem-patch SATU
   instruksi `bl LoadMenuScene` dengan mencocokkan **kata mesin
   hardcode v2.20 `0x9400FF4C`** dan menuntut tepat 1 hit di
   `FixedUpdate + 0xFC` (`payload.cpp` ~1153-1156). Di 2.21 kata di
   alamat itu adalah **`0x9400FF4F`** (displacement BL bertambah 12 byte
   karena `LoadMenuScene` bergeser +0xA4 sementara situs BL hanya +0x98)
   → 0 hit → patch dilewati (fail-closed) → status persis seperti
   diagnosis HP: *"anti-kick skor gagal (tendangan skor masih aktif)"*.
5. **Mekanisme tendangannya** (`GameManager.FixedUpdate`, RVA 2.21
   **0x1C46F58**, disassembly lengkap di `disasm/gm_fixedupdate_2.21.txt`):
   tiap 0,5 detik (`scoreCheckTimer` +0x34; `fmov s1, #0.5`), bila
   `score > oldScore + 500000.0f` (konstanta float di rodata VA
   **0xA98FB0**; field `oldScore` +0x38, `score` +0x3C — float biasa,
   BUKAN Obscured), maka `bl LoadMenuScene` (0x1C86D90) di **+0xFC**.
   Pada 2000 km/h satu CloseCall ≈ (2000−100)×20+500 = 38.500 poin;
   13+ close call dalam satu jendela 0,5 detik melampaui 500.000 →
   lobby. Patch limiter 500 km/h (`mov w8, #500.0f`, kata
   `0x52A87F48` di **+0x448**) TIDAK berubah di 2.21 — kata itu
   version-independent sehingga patch limiter masih jalan; yang mati
   hanya NOP tendangan skor. Ada tendangan kedua di **+0x47C**
   (`bl LoadMenuScene`, kata **0x9400FE6F**) untuk pelanggaran batas
   500 km/h — patch limiter yang berhasil membuat jalur ini tidak
   tercapai, tapi bila limiter gagal, tendangan inilah yang jalan.

Jadi perbaikan rebuild (bukan bagian REA ini — menunggu perintah user):
ganti kata tendangan skor ke **`0x9400FF4F`** (atau cari BL ke
`LoadMenuScene` lewat resolusi nama + offset +0xFC, jangan cocokan kata
hardcode), dan ganti semua pola fallback ke pola 2.21 di
`patterns_v221.h` (18 pola, semua terverifikasi unik — §6). Lebih tahan
update lagi: cari `bl` ke `LoadMenuScene` secara struktural (scan BL di
`FixedUpdate` yang targetnya = RVA `LoadMenuScene` hasil resolusi
nama), bukan kata mesin tetap.

## 4. Proteksi / anti-cheat (temuan)

- **CodeStage Anti-Cheat Toolkit (ACTk) ADA sebagai library**
  (`ACTk.Runtime.dll`, 164 type) dengan `SpeedHackDetector`,
  `WallHackDetector`, `InjectionDetector`, `TimeCheatingDetector`,
  `ObscuredCheatingDetector`, `ObscuredFloat/Int/...`, `ObscuredPrefs`.
- **TAPI tidak ada satu pun pemakaian dari kode game**: nol referensi
  dari `Assembly-CSharp` ke tipe `CodeStage.*` manapun (cek `dump.cs`),
  skor disimpan sebagai **float biasa** (`GameManager.score` +0x3C,
  bukan Obscured), dan pencarian string nama detector di
  `datapack.unity3d` (bundle UnityFS, payload terkompresi LZ4 —
  pencarian string mentah tidak konklusif penuh) juga 0 hit.
  Kesimpulan: ACTk ter-link tapi **tidak ter-wire** sejauh yang bisa
  diobservasi; satu-satunya anti-cheat yang terbukti jalan adalah
  cek laju buatan game sendiri di `GameManager.FixedUpdate` (§3 butir 5).
  Peringatan lama tetap berlaku sebagai kehati-hatian: jangan pakai
  trik `Time.timeScale` (itu pola yang diawasi `SpeedHackDetector`
  bila sewaktu-waktu diaktifkan); jalur `curSpeed` di §5 bukan
  timeScale.
- **Tidak ditemukan** di kode game: deteksi root, deteksi emulator,
  Play Integrity, certificate pinning, atau cek integritas
  `libil2cpp.so` (tidak ada pemindaian hash library dari kode game).
  `libil2cpp.so` stripped (tidak ada `.symtab`), tapi `.dynsym` berisi
  1.376 simbol ekspor API il2cpp (`il2cpp_init`, dlsym-able) — inilah
  yang dipakai injector untuk resolusi nama.
- IAP: Unity Purchasing (`Unity.Purchasing.dll`, 415 type) + Google Play
  Games + Firebase App/Auth/RemoteConfig/Analytics. **Tidak dianalisis
  untuk cheat; leaderboard (`LeagueManager`, `TPGameServicesManager.PostScores`)
  hanya dicatat — skor hasil mod TIDAK boleh dikirim ke leaderboard.**

## 5. Tabel hook — RVA 2.21 vs 2.20 (referensi saja, bukan andalan)

Andalan = pola §6 + resolusi nama. Offset hardcoded di bawah hanya
referensi (akan geser lagi di update berikut).

| Fungsi | RVA 2.21 | RVA 2.20 | Geser | Peran |
|---|---|---|---|---|
| `MotorMover.HandleSpeed()` | `0x1C6C1A0` | `0x1C6C108` | +0x98 | **Speed multiplier** — kalikan `curSpeed` sesudah orig |
| `MotorMover.Crash()` | `0x1C6C720` | `0x1C6C688` | +0x98 | God mode (hook → return) |
| `MotorMover.OnTriggerEnter(Collider)` | `0x1C6D8E8` | `0x1C6D844` | +0xA4 | Noclip (hook → return) |
| `MotorMover.FixedUpdate()` | `0x1C6A644` | `0x1C6A5AC` | +0x98 | Host barrier-scan (pembatas) |
| `MotorMover.Update()` | `0x1C6CBCC` | `0x1C6CB34` | +0x98 | — |
| `MotorMover.HandleOffroadShake()` | `0x1C6CC94` | `0x1C6CBFC` | +0x98 | Bypass goyang off-lane |
| `MotorMover.HandleGear()` | `0x1C6C530` | `0x1C6C498` | +0x98 | Gigi (rantai GearRatio) |
| `MotorMover.ShiftGear(int)` | `0x1C6DF40` | `0x1C6DE9C` | +0xA4 | Gigi |
| `MotorMover.AddNitroTime(float)` | `0x1C6E5E4` | `0x1C6E540` | +0xA4 | Nitro |
| `MotorMover.CalculateEngineTorque()` | `0x1C6E038` | `0x1C6DF94` | +0xA4 | Torsi (alternatif jalur speed) |
| `MotorMover.HandleEngineSimulation()` | `0x1C6C640` | `0x1C6C5A8` | +0x98 | Simulasi mesin |
| `MotorMover.GetMaxSpeed()` | `0x1C6D704` | `0x1C6D660` | +0xA4 | Getter (mati — tak ada caller; jangan hook ini saja) |
| `MotorMover.GetSpeedMs()` | `0x1C6D70C` | `0x1C6D668` | +0xA4 | `curSpeed` (m/s) |
| `MotorMover.GetSpeedKmh()` | `0x1C6D714` | `0x1C6D670` | +0xA4 | `curSpeed × 3.6` (HUD/skor) |
| `GameManager.FixedUpdate()` | `0x1C46F58` | `0x1C46EC0` | +0x98 | Limiter + tendangan skor |
| `GameManager.GetScore()` | `0x1C46F20` | `0x1C46E88` | +0x98 | Skor berjalan |
| `GameManager.CloseCall(bool)` | `0x1C47BD4` | `0x1C47B3C` | +0x98 | Bonus near-miss |
| `TrafficManager.FixedUpdate()` | `0x1C82708` | `0x1C82664` | +0xA4 | Tangkap instance (ESP) |
| `CameraMover.LateUpdate()` | `0x1C3E694` | `0x1C3E5FC` | +0x98 | Offset kamera dunia |
| `Utility.LoadMenuScene()` | `0x1C86D90` | `0x1C86CEC` | +0xA4 | Target tendangan (lobby) |
| `Transform.get_position()` | `0x3960754` | `0x39605FC` | +0x158 | ESP/proyeksi |
| `Transform.set_position(Vector3)` | `0x3960828` | `0x39606D0` | +0x158 | ESP/kamera |
| `Camera.get_main()` | `0x3907258` | `0x3907100` | +0x158 | ESP |
| `Camera.WorldToScreenPoint(Vector3)` | `0x3906FC8` | `0x3906E70` | +0x158 | ESP |
| `Screen.get_width()` / `get_height()` | `0x3911278` / `0x39112A0` | `0x3911120` / `0x3911148` | +0x158 | ESP |
| `Object.get_name()` | `0x3955D04` | `0x3955BAC` | +0x158 | ESP |
| `BoxCollider.get_center()` / `get_size()` | `0x39BBECC` / `0x39BC07C` | `0x39BBD74` / `0x39BBF24` | +0x158 | ESP kotak 3D |

### Field offset penting (dari `dump.cs`, SAMA dengan v2.20 — tidak berubah)

`MotorMover` (223 field): `curSpeed` **+0x224** (float, m/s),
`baseSpeed` +0x228, `maxSpeed` +0x22C, `maxAcceleration` +0x230,
`handling` +0x234, `braking` +0x238, `curGear` +0x264 (int),
`curRpm` +0x268, `vertical` +0x2A8, `trans` +0x2D8,
`isCrashed` +0x311, `canPlayHit` +0x312, `curWheelieValue` +0x334,
`curWheelieCharge` +0x338, `maxWheelieValue` +0x33C,
`maxNitroTime` +0x354, `curNitroTime` +0x358,
`offroadShakeEnabled` +0x28, `offroadCurIntensity` +0x100,
`mp` +0x428 (`MotorProperties` → `data` +0x10 → `GearRatio` +0xC0).

`GameManager` (35 field): `scoreCheckTimer` +0x34,
`oldScore` +0x38, `score` +0x3C (float biasa),
`distanceInMeters` +0x44, `combo` +0x48, `maxCombo` +0x4C.

`TrafficMover`: `curSpeed` +0x78, `isActive` +0x80.

### Cara kerja speed yang benar (terverifikasi disassembly)

`HandleSpeed` (`disasm/handlespeed_2.21.txt`, RVA 0x1C6C1A0): rem
menulis `curSpeed` di +0x100 (`curSpeed − braking × dt`, dijaga ≥
`baseSpeed` +0x228); gas menulis lewat torsi + cap `maxSpeed` +0x22C
(di +0x114/+0x224: `new = min(new, maxSpeed)` — koreksi v1.6 injector
terkonfirmasi). `maxSpeed` saja tidak cukup (getter `GetMaxSpeed`
tidak punya caller). Jalur mod yang benar tetap: hook `HandleSpeed`,
sesudah orig kalikan `curSpeed` [+0x224] dengan N, dengan cap atas
waras (tanpa cap, pengali tumbuh geometris tiap frame → inf → crash,
terbukti di injector v1.7). Alternatif fisik: `HandleEngineSimulation`
/ `CalculateEngineTorque` (naikkan torsi — memengaruhi akselerasi +
RPM, bukan kecepatan puncak semata).

## 6. Pola byte tahan update (2.21) — deliverable utama

`derive_patterns.py` membaca 32 byte prologue tiap target dari
`libil2cpp.so` 2.21 dan memastikan **tepat 1 kemunculan** di segmen
executable. `test_scan.cpp` (g++ host) memverifikasi ulang atas file
lib: **`HASIL: SEMUA POLA OK (18 pola)`** — tiap pola cocok tepat 1x di
file offset fungsi yang benar. `CameraMover.LateUpdate` butuh 36 byte
(32 byte tidak unik). File: `patterns_v221.h` (array C gaya injector),
`patterns_v221.json` (manifest), `derive_patterns.py`,
`test_scan.cpp`.

Patch words `GameManager.FixedUpdate` 2.21 (terverifikasi capstone):

| Patch | Kata 2.21 | Offset | Catatan |
|---|---|---|---|
| Limiter 500 km/h | `0x52A87F48` (`mov w8, #500.0f`) | +0x448 | **SAMA dengan v2.20** (version-independent) |
| Tendangan skor → NOP | **`0x9400FF4F`** (`bl LoadMenuScene`) | +0xFC | v2.20: `0x9400FF4C` — **ini yang mematikan anti-kick lama** |
| Tendangan limiter → NOP | `0x9400FE6F` (`bl LoadMenuScene`) | +0x47C | Cadangan bila limiter gagal |
| NOP | `0xD503201F` | — | Pengganti kedua BL di atas |

## 7. Kelas/metode terkait (ringkas, dari dump.cs)

- `MotorMover` (80 method, 223 field) — inti gerak motor pemain.
  `AIRacerMover` (36/83) — gerak AI; `AIRacerController` (20/44).
- `GameManager` (8/35) — skor + tendangan; `GameStateManager` (3/27);
  `Globals` (5/39).
- `InGameHUDManager` (174/450) — HUD/skor tampil;
  `LeagueManager` (109/37) — liga/leaderboard (jangan kirim skor mod);
  `SaveManager` (68/1) + `SaveConstants` (204 field) — simpanan;
  `PlayerStats` (100 field).
- `MissionManager` (20/5), `RaceManager` (26/26),
  `TrafficManager` (20/16), `TrafficMover` (12/58),
  `CrashScreenEffect` (27/64), `EngineTuning` (8/15),
  `StringEncryptor`, `XOREncryptionDecryption` (obfuskasi string/save).
- `Assembly-CSharp` total 457 type (global namespace), 125 image
  keseluruhan; `ACTk.Runtime.dll` 164 type (lihat §4).

## 8. Batasan & yang tidak dilakukan

- REA statis saja — APK tidak di-install/dijalankan; tidak ada injector
  baru yang dibangun (menunggu perintah user setelah laporan ini).
- Scope cheat solo/offline yang sudah ada di injector (god/noclip/
  speed/anti-kick skor/crash/trigger + fitur injector v1.3 lain:
  ESP, kamera, nitro/wheelie, gigi, offroad). Tidak ada jenis cheat
  baru; tidak ada online/leaderboard/IAP.
- `fields.py` (upaya awal baca field offset via parser Python)
  **gagal OOM di VM dan tidak diulang** — semua offset field di laporan
  ini diambil dari `dump.cs` fork yang tervalidasi (§2), bukan dari
  script itu.
- `CodeRegistration`/`CodeGenModule`: dua selisih layout vs rodroid
  dicatat di §2 (tidak memengaruhi RVA yang tervalidasi).

## 9. Isi paket hasil-dump

`com.skgames.trafficrider/2.21/`:
- `REA-TrafficRider-2.21.md` (laporan ini)
- `patterns_v221.h`, `patterns_v221.json`, `derive_patterns.py`,
  `test_scan.cpp`
- `il2cpp106.py` (parser metadata v106/v107 + relokasi RELA)
- `disasm/` — `handlespeed_2.21.txt`, `gm_fixedupdate_2.21.txt`,
  `crash_2.21.txt`, `trigger_2.21.txt` (capstone)
- `dump/` — `dump.cs.gz`, `DummyDll/` (126 DLL),
  `il2cpp.h.gz`, `script.json.gz`, `stringliteral.json`
