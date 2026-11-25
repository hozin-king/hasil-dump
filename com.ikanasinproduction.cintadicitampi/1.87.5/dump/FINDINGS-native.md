# FINDINGS-native.md — Lapisan Native Cinta di Citampi 1.87.5

## Engine
- **Unity 6000.3.21f1 (Unity 6)**, scripting backend **IL2CPP** (bukan Mono).
- `libil2cpp.so` 93.227.296 B (SHA-256 `ce2a180b…`), `libunity.so` 24.693.136 B
  (SHA-256 `788469dd…`), `assets/bin/Data` 10.967 file,
  `global-metadata.dat` 13.258.060 B, **metadata version 39**.
- Il2CppDumper v39 berhasil: `dump.cs` (34 MB), `il2cpp.h` (92 MB),
  `script.json` (96 MB), `stringliteral.json` (29.966 entri), DummyDll (23 MB).
  CodeRegistration `0x5090fe0`, MetadataRegistration `0x5247278`.
  (Output mentah Il2CppDumper TIDAK ikut di-push — terlalu besar; hanya
  ringkasan + token + disassembly pilihan di `dump/`.)
- `lib_burst_generated.so` — Burst compiler (job system Unity).

## Inventaris native (25 .so, `dump/native-libs.txt`, `dump/hashes.txt`)
Semua di `config.arm64_v8a.apk → lib/arm64-v8a/` (AArch64, ET_DYN):

| lib | ukuran | keterangan |
|---|---|---|
| libil2cpp.so | 93,2 MB | game code (IL2CPP) — butuh `libpairipcore.so` |
| libunity.so | 24,7 MB | Unity runtime — butuh `libpairipcore.so`, `libmain.so` |
| libFirebaseCppApp-13_9_0.so | 5,9 MB | Firebase C++ App |
| libsqliteJni.so | 2,1 MB | SQLite JNI — butuh `libpairipcore.so` |
| libsigner.so | 1,3 MB | Adjust SDK signature helper (bukan anti-cheat game) |
| libcrashlytics-common.so | 0,9 MB | Firebase Crashlytics |
| libapplovin-native-crash-reporter.so | 0,9 MB | AppLovin crash reporter |
| libpairipcore.so | 0,6 MB | **PairIP protector core** (stripped, string ter-obfuskasi) |
| libtt_ugen_layout.so | 0,4 MB | layout lib (TikTok/Pangle UGC) |
| libnms.so | 0,3 MB | NMS (network/security helper) |
| libcrashlytics-handler.so | 0,2 MB | Crashlytics handler |
| libFirebaseCppAnalytics/Messaging/RemoteConfig/Crashlytics.so | 47–95 KB | Firebase C++ |
| libpglarmor.so | 69 KB | ByteDance PGL crypt (`PglCryptUtils`) |
| libapminsighta/b.so | 102/124 KB | APM insight (Pangle) |
| libcrashlytics-trampoline.so | 9 KB | Crashlytics trampoline |
| libbuffer_pgl.so | 9 KB | PGL buffer |
| libmain.so | 7 KB | Unity main entry |
| libfile_lock_pgl.so | 6 KB | PGL file lock |
| libdatastore_shared_counter.so | 7 KB | datastore counter |
| lib_burst_generated.so | 5 KB | Burst stubs |

## PairIP
- `libpairipcore.so` (608.192 B) ter-link sebagai `DT_NEEDED` oleh
  `libil2cpp.so`, `libunity.so`, dan `libsqliteJni.so` — protector terintegrasi
  di build-time, bukan injeksi runtime.
- Binary stripped; string yang terbaca hampir semuanya runtime C++
  (`libc++abi`, `libunwind`) — string internal protector ter-enkripsi/
  ter-obfuskasi, jadi kemampuan deteksi spesifiknya **tidak dapat dipastikan
  dari analisis statis ini**. Bukti keberadaan: nama lib + dependensi + pola
  umum PairIP (app protection / anti-tamper komersial).
- `libpglarmor.so` + `libbuffer_pgl.so` + `libfile_lock_pgl.so` = komponen
  ByteDance PGL (Pangle) — proteksi/kripto sisi iklan, JNI
  `Java_com_bytedance_sdk_component_pglcrypt_PglCryptUtils_bc`.

## CodeStage Anti-Cheat Toolkit (ACTk) — di IL2CPP
Tipe-tipe ACTk **hadir di binary** (`dump.cs`):
- `InjectionDetector` (TypeDefIndex 12220), `ObscuredCheatingDetector` (12222),
  `SpeedHackDetector` (12223), `TimeCheatingDetector` (12236),
  `WallHackDetector` (12239), `ObscuredPrefs` (12155),
  `ObscuredFilePrefs` (12142), `ObscuredFile` (12135),
  `ObscuredTypesNewtonsoftConverter` (12190), `ACTkDetectorBase<T>` (12218),
  `SpeedHackProofTime`, `ObscuredString/Int/Float/...`.
- String literal terkait: `"[ACTk] WallHack Detector: ..."`,
  `"[ACTk] ObscuredFile: ..."`, `"CodeStage.AntiCheat.Utils|..."`.
- **Catatan jujur:** tidak ditemukan referensi langsung dari kode game ke
  `*.Instance` / `StartDetection()` detector-detektor itu di `dump.cs` —
  library ter-include di build, tetapi pemakaian aktifnya **tidak terkonfirmasi
  dari dump statis ini**. Yang terkonfirmasi aktif adalah anti-tamper buatan
  game sendiri (`saveHelper.checkTampering`, validasi server — lihat
  FINDINGS-save.md).
- Kelas game sendiri: `CurrencyChangeDetector` (TypeDefIndex 836, memantau
  perubahan mata uang via event).

## Root / emulator / Play Integrity
- **Tidak ditemukan** detektor root/emulator/Play Integrity yang eksplisit di
  string IL2CPP maupun metadata (pencarian kata kunci `root|magisk|supersu|
  xposed|frida|safetynet|playintegrity|integrity|emulator|bluestacks` hanya
  menghasilkan noise kata umum, mis. "root" pada "RootTransform"/"GC roots";
  satu string menarik: `"treating as real device, not emulator"` — dari
  library device-info/analytics, bukan bukti detektor root).
- Yang ada adalah proteksi di atas (PairIP, PGL, ACTk library, validasi
  build-hash server `/validate_buildhash`).

## Endpoint network (dari `stringliteral.json` + metadata strings)
- **Backend game:** `https://api.ikaanstudio.com/` — `/saveGame/upload`,
  `/saveGame/download`, `/saveGame/downloadSuspiciousState`,
  `/comparingValues/`, `/validate_buildhash`, `/validate_newlootboy`,
  `/update_newlootboy`, `/update_newpurchase`, `/download_purchase`,
  `/time_server`, `/version_androidRelease`, `/version_androidBeta`,
  `/version_*Json` (cgscene, conversation, cutscene, device, npcdata,
  petdata, resource, textlibrary), `/download_*Json`, `/CGImages`,
  `/citampi_online_event`.
- **MongoDB Atlas Data API:** `https://ap-southeast-1.aws.data.mongodb-api.com/app/data-pvaem/endpoint/`
  (`data/v1/`, `getsequence`, `getservertime`).
- **Noctua SDK:** `https://sdk-api-v2.noctuaprojects.com`,
  `https://sandbox-sdk-api-v2.noctuaprojects.com`,
  `https://geoip.noctuaprojects.com`,
  `https://liveops-progress-tracker.noctuaprojects.com`,
  `https://sdk-tracker.noctuaprojects.com`, `https://noctua.gg`.
- **Lainnya:** `https://worldtimeapi.org` (server waktu cadangan),
  `https://app.adjust.com/1ov3t8e0` (Adjust), `https://www.ikanasinproduction.com`,
  Firebase (`*.googleapis.com` via SDK), `https://discord.gg`, `https://forms.gle`.

## Ekspor simbol
- `dump/exports-libil2cpp.so.txt` (2.503 dynsym), `exports-libunity.so.txt`,
  `exports-libpairipcore.so.txt`, `exports-libpglarmor.so.txt`,
  `exports-libsigner.so.txt`, `exports-libmain.so.txt`, `exports-libnms.so.txt`,
  `exports-libsqliteJni.so.txt` — dicatat via pyelftools (`.dynsym`).
  Kebanyakan lib stripped: `.dynsym` berisi import; tidak ada `.symtab`.
- String native: `dump/libunity.strings.txt`, `dump/strings-libpairipcore.so.txt`,
  `dump/strings-libpglarmor.so.txt`, `dump/strings-libsigner.so.txt`,
  `dump/strings-libnms.so.txt`, `dump/strings-libmain.so.txt`,
  `dump/libil2cpp.strings.txt`, `dump/global-metadata.strings.txt`.
