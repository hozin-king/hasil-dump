# REA — Mario Wonder (port Android, proyek Belmante)

**Tanggal analisis:** 26 Oktober 2026 (WIB)
**Metode:** Analisis STATIS saja. Tanpa uji runtime, tanpa koneksi ke server game, tanpa login/akun, tanpa instalasi di perangkat. Tidak ada IL2CPP dump dan tidak ada tabel offset per-fungsi dalam laporan ini.

## 1. Ringkasan eksekutif

- **File terverifikasi:** APK **dan** file data `M.WONDER.zip` keduanya terverifikasi penuh (ukuran byte persis dengan header server MediaFire, SHA-256 dihitung, ZIP valid, CRC lolos).
- **Resmi Nintendo atau bukan:** **BUKAN resmi Nintendo.** Ini adalah port/rekompilasi komunitas: paket `io.github.belmantegu.wonderrecomp`, label `Wonder`, versi `0.3.0`, penanda tangan kunci debug Android generik, dan aplikasi dinyatakan `debuggable`.
- **Arsitektur:** Bukan port native biasa dan bukan Unity/Unreal. Ini adalah **launcher + runtime rekompilasi Switch (recompilation/HLE)**: kode Java/Kotlin launcher kecil (139.032 byte `classes.dex`) + library native rekompilasi `libwonder.so` (187.886.744 byte) + `libnximport.so` (1.008.400 byte, dekripsi/ekstraksi RomFS) + shader Vulkan hasil terjemahan `assets/spirv.zip` (114.734.320 byte, 12.752 entri `.spv`).
- **Online/offline:** **Offline lokal sebagai bawaan.** Manifest tidak mendeklarasikan permission apa pun — termasuk tidak ada `INTERNET`. DEX tidak mengandung domain game, login, akun, billing, atau server apa pun; satu-satunya URL eksternal adalah kanal YouTube proyek. Layanan online/akun/teman Switch di dalam `libwonder.so` hanya muncul sebagai simbol SDK Nintendo (`nn::`) yang dirutekan lewat stub HLE IPC, bukan koneksi nyata ke Nintendo.
- **Ekonomi/IAP:** **Tidak ada.** Tidak ada string billing/purchase di DEX, tidak ada `BillingClient`, tidak ada toko, tidak ada mata uang berbayar di dalam APK. Progres game sepenuhnya lokal (`user/save`).
- **Vonis singkat:** Mod solo/offline lokal layak *dipertimbangkan* — terutama lewat jalur save lokal dan opsi launcher yang sudah ada — tetapi **belum ada satu pun fitur cheat yang terverifikasi** dan tidak boleh diklaim jadi sampai riset runtime. Semua yang bersifat online, bypass sesi/token/anticheat, bypass pembelian, dan klaim/distribusi sebagai produk resmi Nintendo **ditolak**.

## 2. Identitas file

### 2.1 APK — `m.wonder.apk` (terverifikasi)

| Item | Nilai |
|---|---|
| Sumber | [tautan unduhan dihapus — minta ke Alyaa] |
| Nama di MediaFire | `m.wonder.apk`, tipe `Compressed Archive (.APK)` |
| Ukuran di halaman | 169.63 MB |
| Ukuran byte persis (terverifikasi) | 177.865.109 byte |
| Header server (`content-length`) | 177.865.109 byte — cocok persis |
| SHA-256 | `8cce8ee2a4adc1a51f11ee03fd51c203b561bf868eeaacd4c5080c3a686fb594` |
| ZIP valid | Ya, 59 entri |
| Diunggah (MediaFire) | 2026-10-18 19:32:21 |
| Link unduhan langsung (dari HTML halaman, diverifikasi header `application/vnd.android.package-archive`) | `[tautan unduhan dihapus — minta ke Alyaa]` (token signed dihilangkan dari laporan; link lengkap tersimpan di `apk_direct.txt` di workdir) |

### 2.2 File data — `M.WONDER.zip` (menunggu verifikasi akhir)

| Item | Nilai |
|---|---|
| Sumber | [tautan unduhan dihapus — minta ke Alyaa] |
| Nama di MediaFire | `M.WONDER.zip`, tipe `Compressed Archive (.ZIP)` |
| Ukuran di halaman | 3.51 GB |
| Ukuran byte menurut header server (`content-length`) | 3.769.577.350 byte |
| Diunggah (MediaFire) | 2026-10-18 19:46:11 |
| Ukuran byte persis (terverifikasi) | 3.769.577.350 byte |
| SHA-256 | `a650a43213019056fd7bc06a2fa06a4f6d42580082638ae83cb04462ba940462` |
| ZIP valid | Ya, `testzip` lolos (CRC semua entri OK) |
| Jumlah entri | 2 |
| Total uncompressed | 3.769.108.524 byte |
| Total compressed | 3.769.576.948 byte (selisih 402 byte dari ukuran file = overhead header/direktori ZIP) |
| Status | **Terverifikasi penuh** |

## 3. Identitas aplikasi (dari `aapt dump badging` + manifest hasil apktool)

- **Package:** `io.github.belmantegu.wonderrecomp`
- **Label:** `Wonder`
- **versionName / versionCode:** `0.3.0` / `3`
- **compileSdk / targetSdk / minSdk:** 35 / 35 / 30
- **ABI:** hanya `arm64-v8a`
- **Aktivitas utama (launcher):** `io.github.belmantegu.wonderrecomp.LauncherActivity` (exported, `sensorLandscape`)
- **Aktivitas lain:** `OptionsActivity`, `LayoutEditorActivity`, `GameActivity` (exported, `singleTask`, proses `:game`, `android.app.lib_name = wonder`)
- **`application-debuggable`: `true`** — build debug, bukan build rilis yang dikeraskan.
- **Kategori:** `game`, `largeHeap = true`, `extractNativeLibs = true`
- **Fitur wajib:** `android.hardware.vulkan.version` versi `0x00403000` (Vulkan 1.3); gamepad dan touchscreen tidak wajib.
- **Permission:** **tidak ada sama sekali** di manifest hasil decode — tidak ada `INTERNET`, `READ/WRITE_EXTERNAL_STORAGE`, `ACCESS_NETWORK_STATE`, atau permission kustom. Ini adalah bukti paling kuat bahwa APK ini, apa adanya, tidak dirancang untuk berbicara ke server mana pun.

### 3.1 Penanda tangan — bukti bukan resmi Nintendo

Hasil `apksigner verify --print-certs`:

- **Signer #1 certificate DN:** `C=US, O=Android, CN=Android Debug`
- **SHA-256 sertifikat:** `51d65525a35a9a3d4d8c9d196c495a8cd31d3f222b5522bada89ab55084be766`
- **SHA-1 sertifikat:** `db353a6a2bc8f1497af5416ef6768584440826f7`
- **MD5 sertifikat:** `6ac047e7f610fd6b0017b83fb7656890`

Ini adalah kunci debug Android generik, bukan kunci rilis Nintendo, bukan kunci penerbit komersial, dan tidak dapat dibandingkan dengan build resmi mana pun karena tidak ada build resmi Android untuk game ini. Dikombinasikan dengan namespace `io.github.belmantegu`, kesimpulan "port komunitas, bukan produk Nintendo" sudah tertutup dari identitasnya saja, sebelum melihat isi.

## 4. Bukti proyek Belmante / rekompilasi (dari string DEX)

Launcher ini secara eksplisit menyatakan dirinya sebagai proyek non-profit yang **tidak menyertakan** game, keys, maupun firmware:

> "Non-profit project. It includes no code, assets, keys or firmware of the game. Nintendo and Super Mario are trademarks of Nintendo."
>
> "The launcher does not include the game, keys or firmware. Choose the folder that has YOUR prod.keys (+ title.keys) and your dump of Super Mario Bros. Wonder 1.0.0 (the cartridge .xci, or .nsp). Put only the 1.0.0 dump there, no updates: the recompiled code is for 1.0.0. The phone reads the files where they are and extracts them to the app's own folder."
>
> "The recompiler, runtime and launcher are by the project. The game runs only from files you dump from your own console."

Artinya, secara desain:

1. **APK saja tidak bisa menjalankan game.** Ia membutuhkan dump milik pengguna sendiri: `Super Mario Bros. Wonder 1.0.0` dalam bentuk `.xci` atau `.nsp`, **tanpa update** (kode rekompilasi hanya untuk 1.0.0), plus `prod.keys` (+ `title.keys`) dari konsol sendiri (disebutkan diambil lewat `Lockpick_RCM`).
2. **Peran `M.WONDER.zip` adalah sebagai sumber impor mentah** (lihat §7): berisi dump `M.Wonder.xci` + `Keys.zip` (`prod.keys`/`title.keys`), bukan bagian dari APK dan bukan data hasil impor. Launcher juga menerima "XCI or NSP + prod.keys, or a data .zip" sebagai sumber impor — paket ini memakai jalur pertama.
3. **Satu-satunya domain eksternal di DEX** adalah `https://www.youtube.com/@belmante` ("Projeto Belmante"). Tidak ada domain Nintendo, tidak ada domain game, tidak ada API.
4. **Bahasa UI ganda Inggris–Portugis Brasil** (mis. "Iniciar Super Mario Bros. Wonder", "Projeto Belmante", "Grava user/save em um .zip para backup") — konsisten dengan proyek komunitas Brasil, bukan lokalisasi resmi Nintendo.
5. **Shader memakai translator Ryujinx (MIT) secara offline**, font Fredoka (SIL OFL), ikon Lucide (ISC) — semua dicantumkan di string lisensi DEX.

## 5. Arsitektur / engine

Bukan Unity, bukan Unreal, tidak ada `libil2cpp.so`, tidak ada `libunity.so`. Strukturnya:

| Komponen | Ukuran | Peran (dari nama + string) |
|---|---|---|
| `lib/arm64-v8a/libwonder.so` | 187.886.744 byte | Kode game hasil rekompilasi Switch → ARM64 + runtime HLE (stripped, ELF64 AArch64, BuildID sha1 `2585b683db58147f15dff110f8eee854a152e88d`). Dependensi dinamis hanya `libandroid.so`, `liblog.so`, `libaaudio.so`, `libm.so`, `libdl.so`, `libc.so`. |
| `assets/spirv.zip` | 114.734.320 byte | 12.752 shader Vulkan hasil terjemahan (`.spv`) + `results.tsv` (2.587.571 byte). `assets/spirv.id` berisi `0006206b84b1cfac`. Tanpa shader ini game tidak bisa start — string DEX: "this APK has no assets/spirv.zip … so the game cannot start yet". |
| `lib/arm64-v8a/libnximport.so` | 1.008.400 byte | Importer native: membaca NCA/RomFS, mendekripsi dengan `prod.keys`/`title.keys`, mengekstrak ke `extract/romfs`. String kuncinya menegaskan nilai key tidak pernah ditampilkan ("keys: %zu named keys, %zu title keys (values are never shown)"). |
| `classes.dex` | 139.032 byte | Launcher Java/Kotlin saja: `LauncherActivity`, `GameActivity`, `OptionsActivity`, `LayoutEditorActivity`, `ImportJob`, `ZipImporter`, `NativeImporter`, `Diagnostics`, `FpsOverlay`, `GameConfig`, kontrol sentuh, editor layout. |
| `assets/launcher/` | — | `background.jpg` (784.945 byte), `logo.png` (131.196 byte) — aset launcher proyek, bukan aset game. |
| `assets/links/belmante.jpg` | 7.606 byte | Gambar tautan proyek. |
| `assets/fonts/` | — | `Fredoka.ttf`, `shared_5.ttf`. |

### 5.1 Runtime HLE — bukti stub, bukan layanan nyata

`libwonder.so` mengandung simbol SDK Nintendo (`nn::`) dalam jumlah besar — itu wajar untuk kode Switch yang direkompilasi — tetapi konteksnya adalah HLE:

- String runtime: `ipc: %s cmd %u not implemented (stub ok)`, `ipc: no implementation for service '%s', using a stub`, `EnableBluetoothStub`, `out of HLE thunks`, `memory: thunk range … (only an address range for HLE calls, never mapped)`.
- Hitungan string kasar di `libwonder.so`: `multiplayer: 0`, `billing: 0`, `online: 25` (semuanya simbol `nn::account`/`nn::friends` seperti `DeclareOpenOnlinePlaySession`, `GetAccountOnlineStorageSettings` — yaitu antarmuka SDK, bukan implementasi jaringan), `server: 2292` (mayoritas `…Server` IPC/SDK, bukan alamat server), `socket: 505` (mayoritas `nn::socket` SDK).
- Tidak ada satu pun URL `https://` di `libwonder.so` kecuali `googlesource.com` (jejak toolchain clang Android) — tidak ada endpoint Nintendo, tidak ada endpoint game.

Kesimpulan arsitektur: **game berjalan lokal di atas runtime HLE; panggilan layanan Switch (akun, teman, online, save cloud) tidak memiliki backend nyata di APK ini.** Ditambah manifest tanpa permission `INTERNET`, fitur online asli Wonder secara praktis tidak dapat berfungsi dari APK ini, apa adanya.

### 5.2 Persyaratan perangkat (dari DEX + manifest)

- ARM 64-bit, Vulkan 1.3 (`android.hardware.vulkan.version >= 0x403000`).
- Render: mode Handheld 720p (lebih ringan, lebih banyak fps) atau TV 1080p (lebih tajam, lebih berat); FPS mode 60 (aturan game sendiri) atau 30 (mode 30 fps game pada kecepatan benar, frame 33 ms, lebih dingin/hemat baterai).
- Opsi launcher yang sudah ada (bukan cheat): `NX_FPS_CAP`, `NX_RENDER_RES`, `NX_FSR` (+ `NX_FSR_SHARP`), `NX_GPU_TURBO`, `NX_MEM_LIMIT_GB`, `NX_PIPELINED`, `NX_DISPLAY_HZ`, `NX_ULTRAWIDE`, `NX_TOUCH_*`, `NX_MUTE`, `NX_PIPELINE_CACHE`, `NX_AFFINITY`, `NX_PAD_BUFFERS`, `NX_SUBMIT_CHUNK_DRAWS`, `NX_HANDHELD`, plus AMD FidelityFX upscaling, VkPipelineCache di disk, editor layout tombol sentuh, dan overlay FPS.
- Contoh kinerja yang diklaim di string DEX (belum terverifikasi di perangkat): adegan air mancur dari 24 ke 60 fps di Galaxy S23 dengan pipeline otomatis.

## 6. Jalur online, IAP, akun, anti-cheat

| Jalur | Bukti statis | Vonis |
|---|---|---|
| Internet / domain game | Manifest: 0 permission. DEX: 0 domain game, 0 login, 0 akun, 0 server, 0 socket/TCP/UDP/DNS. Satu-satunya URL: `https://www.youtube.com/@belmante`. | Tidak ada jalur online di APK. |
| Akun Nintendo / login | DEX: `login: 0`, `account: 0` (di luar simbol SDK `nn::account` di `libwonder.so`). Tidak ada WebView login, tidak ada OAuth. | Tidak ada. |
| Multiplayer online / vs pemain asli | DEX: `multiplayer: 0`, `online: 0`, `friend: 0`, `lobby: 0`. Di `libwonder.so` hanya simbol SDK `nn::friends`/`nn::account` yang dirutekan ke stub HLE. | Tidak berfungsi dari APK ini; dan apa pun yang mengarah ke pemain asli tetap ditolak. |
| IAP / billing / toko | DEX: `billing: 0`, `purchase: 0`, `eshop: 0`. `libwonder.so`: `billing: 0`. Tidak ada `BillingClient`. | Tidak ada pembelian untuk di-bypass. |
| Anti-cheat | DEX: tidak ada string anti-cheat. `libwonder.so`: tidak ada string anti-cheat/integrity-check. Yang ada di DEX hanya diagnostik perangkat (`getprop` untuk `ro.board.platform`, `ro.soc.model`, `ro.hardware.vulkan`, `ro.hardware.egl`, dan pembacaan `/proc/` untuk diagnostik) — bukan deteksi root/cheat. | Tidak ada anti-cheat yang terdeteksi di launcher; ini bukan izin untuk membangun bypass apa pun. |
| Update / DLC | DEX secara eksplisit menolak update: "Put only the 1.0.0 dump there, no updates: the recompiled code is for 1.0.0". `dlc: 0`. | Tidak ada jalur update/DLC. |

### 5.3 Struktur impor yang diharapkan launcher (dari smali `ImportJob`/`ZipImporter`)

Launcher tidak hanya menerima folder dump mentah; ia juga menerima paket data yang sudah diekstrak. Bukti dari string smali:

- **Title ID yang dicari:** `010015100B514000` (ID judul Super Mario Bros. Wonder di Switch).
- **Sumber impor yang diterima:** folder berisi `.xci` (termasuk split `.xci.[0-9]+` / `.xc[0-9]`) atau `.nsp` + `prod.keys` (+ `title.keys`), **atau** sebuah data `.zip` yang sudah berisi hasil ekstraksi.
- **Folder internal hasil impor:** `analysis/` (berisi `main.bin`, `sdk.bin`), `extract/romfs`, `spirv/` (termasuk `spirv/results.tsv`, `spirv.id`, `shaders`), `user/`, plus berkas `app.txt`, `config.txt`, `data_root.txt`, `keys.txt`, dan `fonts/shared_5.ttf`.
- **Alur impor:** impor dapat dibatalkan dan dilanjutkan ("Import cancelled. What was already written is kept; the next import continues from there."), dan shader dari APK disalin terpisah (`.apk-shaders`).
- Implikasi untuk §7: bila `M.WONDER.zip` berisi `analysis/` + `extract/` + `spirv/` + `user/`, itu konsisten dengan paket data hasil impor yang siap dipakai launcher, bukan dengan dump mentah `.xci`/`.nsp`.

## 7. File data `M.WONDER.zip` — terverifikasi

**Isi ZIP luar (hanya 2 entri, tidak ada struktur folder hasil impor):**

| Entri | Ukuran uncompressed | Ukuran compressed | Kompresi |
|---|---|---|---|
| `M.Wonder.xci` | 3.769.099.776 byte | 3.769.568.200 byte | DEFLATE |
| `Keys.zip` | 8.748 byte | 8.748 byte | STORED |

### 7.1 `M.Wonder.xci` — dump cartridge Switch, bukan data hasil impor

- **Bukan** `.nsp`, bukan `.nca` terpisah, bukan folder `analysis/`/`extract/`/`spirv/`/`user/` hasil impor (semua kategori itu 0 entri di ZIP luar). Berbeda dengan hipotesis awal di §5.3, paket ini berisi **dump mentah cartridge** yang masih harus diimpor launcher lewat `libnximport.so`.
- **Bukti format XCI (hanya 512 byte header dibaca, tanpa mengekstrak isi game):** magic `HEAD` ditemukan di offset `0x100`, sesuai struktur header XCI. Byte awal header terenkripsi, sesuai desain XCI yang memerlukan `header_key` dari `prod.keys` untuk dekripsi.
- Ukuran XCI 3.769.099.776 byte (~3,51 GiB) adalah ukuran dump cartridge game ini, bukan ukuran aset Android. Setelah impor, launcher akan mengekstrak RomFS ke `extract/romfs` dan menghasilkan `analysis/` + `spirv/` sekitar 3,7 GB (sesuai peringatan launcher di §8) — jadi total di perangkat akan jauh lebih besar dari ukuran ZIP ini.
- **Tidak ada aset game yang diekstrak, disalin, atau dimasukkan ke laporan ini.** XCI tidak dibuka lebih jauh dari header 512 byte di atas; tidak ada NCA/RomFS/level/save yang dibaca dari dalamnya.

### 7.2 `Keys.zip` — berisi `prod.keys` dan `title.keys` (hanya nama file yang dicatat)

Daftar nama entri di dalam `Keys.zip` (dibaca dari metadata ZIP saja, **isi key tidak pernah diekstrak ke disk dan tidak pernah ditampilkan**):

- `Keys/prod.keys`
- `Keys/title.keys`
- `Keys/` (folder) dan berkas metadata macOS `__MACOSX/._Keys`, `__MACOSX/Keys/._prod.keys`, `__MACOSX/Keys/._title.keys` (jejak pembuatan ZIP di macOS, bukan isi game)

Artinya paket ini adalah **pasangan lengkap untuk impor launcher**: dump `M.Wonder.xci` (versi yang ditargetkan launcher adalah 1.0.0, tanpa update) + key yang dibutuhkan `libnximport.so` untuk mendekripsi header NCA dan memverifikasi SHA-256 blok RomFS. Tanpa `Keys.zip`, launcher akan menolak impor ("prod.keys was not found…", "the NCA header does not decrypt (header_key in prod.keys is wrong or missing)").

### 7.3 Apa yang TIDAK ada di dalam ZIP ini

- Tidak ada save (`user/save`), tidak ada level terpisah, tidak ada file konfigurasi launcher (`app.txt`, `config.txt`, `data_root.txt`), tidak ada `analysis/main.bin`, tidak ada shader `spirv/` — semua itu baru terbentuk **saat impor di perangkat**, bukan isi paket ini.
- Tidak ada `.nsp`, tidak ada update/DLC, tidak ada berkas `.nca` lepas.
- Tidak ada berkas akun, login, atau server apa pun.

### 7.4 Implikasi hukum/praktis (fakta, bukan penilaian moral)

- Paket ini berisi dump komersial Nintendo + key konsol dalam satu paket. Launcher sendiri dirancang untuk dump dan key **dari konsol milik pengguna sendiri**; paket yang dibagikan lewat MediaFire ini, apa pun asal-usulnya, **bukan** bagian dari APK dan **tidak boleh** didistribusikan ulang, dimasukkan ke repo, atau dikirim ke user sebagai "file game gratis". Laporan ini hanya mencatat keberadaan dan strukturnya, tanpa menyertakan isi, key, maupun aset apa pun.

## 8. Penyimpanan lokal / save / ekonomi game

- **Save lokal adalah satu-satunya ekonomi/progres.** Launcher menyediakan ekspor/impor save secara eksplisit:
  - Ekspor: "Writes user/save to a .zip for backup" → file `wonder-saves.zip`.
  - Impor: "Reads a saves .zip (from this or another device)", "Files with the same name in user/save are replaced", "Import saves?".
  - Jalur internal: `user/save`, `user/save/`.
- **Di sisi native**, save dikelola lewat SDK Nintendo (`nn::fs` SaveData: `MountSaveData`, `GetSaveDataSize`, `SaveDataFileSystemCore`, dsb.) — format save internal game, bukan JSON/file teks sederhana. Mengedit save mentah membutuhkan riset struktur save di runtime, bukan sekadar ubah angka di file teks.
- **Tidak ada sinkronisasi cloud yang berfungsi:** simbol `SaveDataTransferProhibiterForCloudBackUp`/`SaveDataBackupInfo` ada di SDK, tetapi tanpa permission internet dan tanpa backend, tidak ada validasi server atas save.
- **Data impor yang dihapus aman:** "Removes analysis / extract / spirv (about 3.7 GB). Saves stay. You will have to import the game again." — artinya data game hasil impor (~3,7 GB, cocok dengan ukuran `M.WONDER.zip`) terpisah dari save, dan menghapusnya tidak menghapus save.
- **Diagnostik lokal:** `nx.log` (+ `nx.log.prev`), `wonder-diagnostics.zip` (log + perangkat + pengaturan), `spirv/results.tsv`, `pipelines_%04x_%04x.bin`, `/analysis/main.bin`.

## 9. Permukaan mod solo/offline — layak dipertimbangkan vs ditolak

Semua yang di bawah ini berstatus **hipotesis statis, belum terverifikasi runtime**. Tidak ada satu pun yang boleh dikirim sebagai toggle jadi sampai pola/strukturnya terverifikasi di perangkat, sesuai aturan no-fake-toggle.

### 9.1 Layak dipertimbangkan (solo/offline lokal saja, perlu riset runtime)

1. **Editor/penyalin save lokal (`user/save` via `wonder-saves.zip`).** Ini permukaan paling konkret karena launcher sendiri menyediakannya. Target yang masuk akal untuk diteliti: progres dunia/level yang terbuka, jumlah nyawa, koin bunga, badge yang terbuka, dan status penyelesaian level — semuanya lokal dan tidak divalidasi server. Risiko: format save internal Nintendo; salah edit bisa merusak save; wajib backup save asli dulu.
2. **Opsi performa launcher yang sudah ada.** `NX_FPS_CAP`, `NX_RENDER_RES`, `NX_FSR`, `NX_GPU_TURBO`, `NX_MEM_LIMIT_GB`, dan kawan-kawan adalah pengaturan resmi launcher, bukan cheat. Mengubahnya lewat UI/options yang sudah ada adalah jalur paling aman untuk "mod" performa.
3. **Riset memori runtime di `libwonder.so` (pola, bukan offset hardcode).** Karena game adalah kode native hasil rekompilasi (bukan IL2CPP), cheat seperti nyawa tak terbatas, kebal, atau koin tak terbatas — bila memang ada di memori game — hanya bisa dicari lewat pattern-scan di runtime pada build game yang ditarget, lalu diuji satu per satu. Sampai pola itu terverifikasi unik, fitur semacam itu wajib berstatus eksperimental/disabled.
4. **Co-op lokal satu perangkat (bila memang dimainkan bersama di layar yang sama).** Wonder aslinya punya co-op lokal. Bila dimainkan bersama di satu HP dan semua pemain di layar yang sama setuju, modifikasi progres lokal tidak merugikan pemain lain di luar perangkat. Ini *bukan* izin untuk multiplayer online.

### 9.2 Ditolak tegas

- **Cheat lawan pemain asli secara online** (termasuk fitur online Wonder seperti ruangan teman, papan, atau interaksi pemain lain bila suatu saat diaktifkan lewat jalur lain): ditolak. Sebagai tambahan faktual, dari APK ini fitur itu tidak berfungsi karena stub HLE + tanpa permission internet — jadi tidak ada yang bisa "diaktifkan" lewat mod ini.
- **Bypass sesi/token/anticheat, bypass login/akun Nintendo, spoofing identitas/lisensi:** ditolak. Tidak ada sesi/token nyata di APK ini untuk di-bypass, dan membangun jembatan ke layanan Nintendo bukan bagian dari REA ini.
- **Bypass pembelian berbayar / DLC / unlock berbayar:** ditolak. Tidak ada IAP di APK ini; dan game aslinya adalah produk berbayar Nintendo — mod ini tidak boleh dipakai untuk mengklaim atau mendistribusikan game itu sebagai gratis/resmi.
- **Klaim/distribusi sebagai produk resmi Nintendo, atau redistribusi aset komersial Nintendo:** ditolak. APK ini sendiri sudah menyatakan bukan produk Nintendo; laporan ini tidak menyertakan aset game, tidak menyertakan key, dan file data tidak dikirim ke user maupun diunggah ke repo mana pun.
- **Penggunaan `prod.keys`/`title.keys` orang lain atau dump yang bukan milik pengguna:** di luar REA ini. Desain launcher menuntut dump dan key dari konsol sendiri; laporan ini hanya mencatat keberadaan mekanisme itu, tanpa nilai key apa pun.

## 10. Catatan kejujuran dan batas analisis

- Analisis ini statis. Tidak ada klaim "berjalan di HP" sampai ada uji perangkat: impor data, `libwonder.so` ter-load, shader `spirv.zip` terbaca, dan game start.
- Kecepatan/kinerja (mis. klaim Galaxy S23 di string DEX) adalah klaim proyek, bukan hasil ukur di sini.
- Ukuran `M.WONDER.zip` (~3,7 GB) kebetulan mirip dengan pernyataan launcher "about 3.7 GB" untuk data hasil impor, tetapi verifikasi §7 membuktikan keduanya berbeda: ZIP ini adalah dump XCI mentah + key, sedangkan data hasil impor (~3,7 GB) baru terbentuk di perangkat setelah impor. Jangan menyamakan keduanya.
- `application-debuggable = true` + kunci debug generik berarti APK ini tidak boleh diperlakukan sebagai build produksi yang aman untuk akun penting apa pun; ia adalah build komunitas/debug.
- Tidak ada file APK/data yang dikirim ke user, diunggah ke mana pun, atau dimasukkan ke repo. Hanya laporan ini yang diserahkan ke parent.
