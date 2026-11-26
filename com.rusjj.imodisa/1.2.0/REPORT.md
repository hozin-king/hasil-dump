# REA — imodisa 1.2.0 (`com.rusjj.imodisa`)

> Analisis statis saja (static analysis). APK **tidak pernah di-install atau dijalankan**.
> Sumber: `imodisa_1.2.0_0_z1dd.apks` (2.822.386 B, SHA-256 `3eaf731c07701c59e20bd46697f3bc192c194e398b0de65653dd6fcb8857837d`).
> Tanggal analisis: 26 Nov 2026. Tool: androguard 4.1.4, aapt, readelf/nm, capstone (untuk verifikasi).

## 1. Identitas

| Field | Nilai |
|---|---|
| Nama aplikasi | **imodisa** (label launcher: `imodisa`) |
| Tagline (dari string resource) | **"Disassembler for modders"** / ID: "Disassembler untuk modder" |
| Package | `com.rusjj.imodisa` |
| Versi | **1.2.0** (versionCode 10200) |
| Jenis file | Split APK bundle (`.apks`, 3 entri) |
| minSdk / targetSdk / compileSdk | 26 / 36 / 36 (Android 16) |
| Main activity | `com.rusjj.imodisa.ui.HomeActivity` |
| Penanda distribusi | `com.android.stamp.source = https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK` (didistribusikan lewat Google Play) |
| Penanda tangan (signer) | Self-signed, DN `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US`, serial `104646291067031387517289514138100109389404368660`, berlaku 18 Okt 2026 → 18 Okt 2056 |
| Fingerprint cert | SHA-256 `8A:91:A8:BC:4B:22:79:57:01:30:58:10:AE:3F:C4:2B:E2:13:C1:E0:10:41:B2:17:86:72:03:C9:40:AE:18:45`; SHA-1 `02:1C:28:E5:BA:27:97:72:FB:7B:F5:52:2C:DC:43:CC:34:97:4D:3D` |
| Skema tanda tangan | base.apk: v2 + v3 (tanpa v1); kedua split: v1 + v2 + v3 |

**Catatan soal sertifikat (TERVERIFIK):** DN sertifikat ini **persis sama** dengan template DN kunci uji AOSP (testkey) — `CN=Android, OU=Android, O=Google Inc.` — tapi fingerprint-nya **tidak cocok** dengan fingerprint kunci uji AOSP yang dipublikasikan (SHA-1 kunci uji publik yang dikenal: `61:ED:37:7E:85:D3:86:A8:DF:EE:6B:86:4B:D8:5B:0B:FA:A5:AF:81`). Jadi ini **bukan** kunci publik AOSP — private key-nya dipegang developer — tapi pemakaian DN template kunci uji adalah praktik yang lemah/membingungkan dan tidak memberi jaminan identitas apa pun.

### Isi bundle (3 split)

| Split | Ukuran | SHA-256 | Isi |
|---|---|---|---|
| `base.apk` | 3.533.060 B | `e9aa979c2a563e47a24faddd85febe144984a361439393ef4bf7987aefa06bec` | dex + resource + manifest |
| `split_config.arm64_v8a.apk` | 4.878.758 B | `e14149f5d9f97d5540603be3710051c4258a4986dc804e5b59da085dd2c2d265` | `lib/arm64-v8a/libimodisa.so` (4.822.224 B) |
| `split_config.in.apk` | 102.809 B | `29fd0167cdccc9e37dc7012d1d84f0849b95190849877eee4268901c6e7283b5` | resource bahasa Indonesia (`resources.arsc`) |

Manifest base: `requiredSplitTypes="base__abi"`, `com.android.vending.splits.required=true`.
`extractNativeLibs=false` (library native dimuat langsung dari dalam APK), `allowBackup=false`, `largeHeap=true`, `usesCleartextTraffic=true`.

## 2. Apa itu imodisa — satu kalimat

**imodisa adalah workbench reverse-engineering di HP Android, ala IDA/Ghidra mini: disassembler + decompiler (pseudocode) + patcher untuk file biner (DEX, ELF, Mach-O, PE), dengan asisten AI dan server MCP lokal.**

Bukti harfiah dari kode (string di `Lb/z;->c`, pembuat server MCP):

> "Tools on a binary open in imodisa (an Android disassembler and decompiler, IDA-like: functions, pseudocode, names, types, xrefs); addresses are hex."

Deskripsi asisten AI (string resource `2131296369`):

> "Ask the AI about the code. It decompiles, reads the disassembly, follows xrefs, searches names and strings, and can name, type and comment things for you. Where you are (function and cursor) goes along with each question."

## 3. Komponen aplikasi

### Manifest

- **Activities:** `HomeActivity` (launcher, exported), `DexActivity`, `WorkspaceActivity`, `AppPickerActivity`, `SettingsActivity`, `com.pairip.licensecheck.LicenseActivity` (tidak exported).
- **Services (foreground, dataSync):** `AssistantService` (AI), `ExportService`.
- **Permissions:** `INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `com.android.vending.CHECK_LICENSE`.
- **HomeActivity menangani intent VIEW/EDIT/SEND** untuk hampir semua tipe file: `application/octet-stream`, `application/x-sharedlib`, `application/x-executable`, `application/x-elf`, `application/x-object`, `application/x-mach-binary`, `application/x-msdownload` (PE), `application/x-dosexec`, `application/vnd.android.package-archive` (APK), `application/zip`, plus `*/*`, `application/*`, `text/*`, `image/*`, `audio/*`, `video/*`, `font/*`, `model/*`. Artinya aplikasi ini mendaftarkan diri sebagai pembuka file biner universal.

### Lapisan Kotlin (UI) — hanya 11 class aplikasi

| Class | Peran (terverifikasi) |
|---|---|
| `com.rusjj.imodisa.App` | `Application`; init SharedPreferences `"settings"`, store file di `getFilesDir()`, "importer" (`Lb/g`), hapus file temp saat start |
| `com.rusjj.imodisa.ui.HomeActivity` | Layar utama: daftar file/recent, buka file (intent VIEW/SEND) |
| `com.rusjj.imodisa.ui.DexActivity` | Layar analisis DEX: tab Disassembly, Pseudocode, Graph, Hex, Strings, Functions, Segments, Imports, Structures, Patch, Bookmarks, AI, Chats |
| `com.rusjj.imodisa.ui.WorkspaceActivity` | Workspace analisis file biner + panel server MCP (tampilkan URL + token) |
| `com.rusjj.imodisa.ui.AppPickerActivity` | Pilih aplikasi/file untuk dianalisis |
| `com.rusjj.imodisa.ui.SettingsActivity` | Pengaturan (endpoint AI, tema gelap/terang/sistem, dll.) |
| `com.rusjj.imodisa.ui.AssistantService` | Foreground service AI (WakeLock `imodisa:assistant`) |
| `com.rusjj.imodisa.ui.ExportService` | Foreground service ekspor (chat, fungsi .c/.s, pseudocode .c, header) |
| `com.rusjj.imodisa.ui.views.CodeEditText` | Editor kode (font JetBrains Mono) dengan syntax highlight per baris |
| `com.rusjj.imodisa.engine.NativeBridge` | Jembatan JNI ke `libimodisa.so` (lihat §4) |
| `com.rusjj.imodisa.ui.Hbz/ntfdfdnxofooegtfzikkztx/vlvypapvwqyvjabwwwrwyrwbmasqj` | Class tanpa method, hanya 3 field `int` statik bernama acak (`PKHMKSUXIB`, `ZECRFDOGBW`, `ZWXAUCAILK`) — kemungkinan marker/canary, bukan logika |

Sisa dex adalah library: Kotlin stdlib, AndroidX (R8-obfuscated, prefix `l.*`), kotlinx-coroutines, `org.json`, dan **PairIP** (`com.pairip.*`).

### Dex — angka

| Metrik | Nilai |
|---|---|
| Jumlah dex | 1 (`classes.dex`, 3.229.280 B, dex 037) |
| Strings | 12.237 |
| Methods | 9.152 |
| Fields | 5.996 |
| Classes | 1.461 |
| Class aplikasi (`com.rusjj.*`) | **11 (0,75%)** |

## 4. Mesin native — `libimodisa.so` (inti aplikasi)

| Field | Nilai |
|---|---|
| Path | `lib/arm64-v8a/libimodisa.so` (di split arm64) |
| Ukuran | 4.822.224 B |
| Format | ELF 64-bit LSB, AArch64, dynamically linked, **stripped** (simbol debug dibuang) |
| Build | clang 19.0.1 (Android r530567e), **+pgo +bolt +lto +mlgo** (optimasi berat) |
| `.text` | ±668 KB (offset 0x3d4190–0x477250) |
| `.rodata` | ±3,8 MB (kebanyakan tabel instruksi Capstone) |
| Simbol dinamis terdefinisi | 1.042 (kebanyakan internal Capstone/LLVM — tidak disembunyikan) |
| Simbol undefined (import) | 92 — hanya libc/pthread (`memcpy`, `pthread_*`, `dl_iterate_phdr`, `__system_property_get`, `openlog`/`syslog`) |
| JNI | Hanya `JNI_OnLoad` yang diekspor; method JNI didaftarkan dinamis via `RegisterNatives` (pola umum kode terproteksi) |

**Yang TIDAK ada di native lib (terverifikasi dari import):** tidak ada socket/connect/SSL (tidak ada jaringan dari native), tidak ada crypto (tidak ada AES/SHA/RSA import), tidak ada ptrace. Semua jaringan dilakukan dari sisi Kotlin (`java.net.HttpURLConnection`).

**Yang ADA di native lib (dari simbol + string):**
- **Capstone disassembler** (statis): `cs_open`, `cs_disasm_iter`, `cs_close`, backend `AArch64_*` dan `ARM_*` lengkap, plus layer LLVM MC (`MCInst_*`, `MCOperandInfo_*`).
- **ZSTD** (`ZSTD_createDStream`, `ZSTD_decompressStream`, `FSE_*`, `HUF_*`) — dekompresi.
- `__cxa_demangle` — demangle nama C++.
- String error khas Capstone (`Invalid csh (CS_ERR_CSH)`, `Invalid/unsupported architecture`, `ERROR: Could not find CS id for MCInst opcode: %d`).
- 9.791 string di `.so`, semuanya terbaca (tidak ada enkripsi string).

### API JNI — `NativeBridge` (semua method `native`, terverifikasi)

```
decodeBytes, demangle, engineVersion
disasmCreate / disasmDecode / disasmDestroy / disasmWalk / disasmCountUntil
disasmSizeAt / disasmBuildIndex / disasmBuildChunkIndex
imageCreate / imageDestroy
scanCode / scanStrings / scanRefsTo / scanCallTargets / scanJumpTargets
scanIndirectJumps / scanLiteralsIn / scanTargetsIn / scanTotalRefs / scanCountRefsTo / scanAddRefs / scanDestroy
searchText, findPattern
zstdCreate / zstdDecompress / zstdDestroy
```
`clinit` memuat library lewat properti sistem `imodisa.native.library`, fallback `System.loadLibrary("imodisa")`.

**Kesimpulan arsitektur:** UI Kotlin hanyalah kulit tipis; **seluruh otak (disassembler ARM/AArch64 + decompiler DEX/native + scanner xref/string) ada di `libimodisa.so`**. Ada juga package `com.rusjj.imodisa.decompiler.*` di dex (Expr/Node/Stmt/Op, `GotoElimination`) sebagai model data hasil decompile.

## 5. Fitur (dari string resource + kode)

- **Disassembly** ARM + Thumb + AArch64 (Capstone), "Create function (ARM/Thumb)", "Show graph", "Call graph", "Stack frame".
- **Decompiler / pseudocode**: "Show pseudocode", "Decompile again", "Decompile in new tab", "Unwrap gotos", "Hide/Show casts", "Split function", struktur C ("Create structure from…", impor header dari IDA, "Sintaks C… // +0x40 … // size 0x100"), "Reset names and types".
- **Patching**: "Patch and assemble…", "Quick patch", "Replace with NOP", "Edit bytes…", "Assemble…", "Revert patch", "Save patched file" (ID: "Simpan file yang dipatch…").
- **Analisis**: "Cross references (to …)", "Calls from / Callers of function", "Uses of …", "Find…", "Jump to …", "Search names and strings", "Mark unused instructions", "Collecting strings", "Scanning code", "Reading debug info", "Reading PDB" (dukungan PDB!), "Function…", "Segments", "Imports", "Strings" (C string, UTF-16), "Bookmarks".
- **Ekspor**: fungsi (.c, .s), pseudocode (.c), header C, chat AI.
- **AI Assistant** (lihat §6).
- **Server MCP lokal** (lihat §7).
- **Lainnya**: tema Gelap/Terang/Sistem, font JetBrains Mono, recent files, AppPicker.

## 6. Jaringan & AI

Transport: `java.net.HttpURLConnection` / `java.net.URL` (tanpa OkHttp/Retrofit). `usesCleartextTraffic=true` (diperlukan untuk endpoint lokal `http://127.0.0.1:…`).

### Provider LLM bawaan (tabel preset di `Lb/t0;-><clinit>` — terverifikasi)

| Provider | Base URL | Model default (contoh) | URL kelola kunci |
|---|---|---|---|
| OpenAI | https://api.openai.com/v1 | gpt-4.1, gpt-5, gpt-5-mini, gpt-oss-120b | — |
| Anthropic (Claude) | https://api.anthropic.com | — | console.anthropic.com |
| DeepSeek | https://api.deepseek.com/v1 | deepseek-chat, deepseek-reasoner, DeepSeek-V3.1 | platform.deepseek.com/api_keys |
| Groq | https://api.groq.com/openai/v1 | llama-3.3-70b-versatile | console.groq.com/keys |
| Mistral | https://api.mistral.ai/v1 | mistral-large-latest, mistral-medium-latest, codestral-latest | console.mistral.ai/api-keys |
| Cerebras | https://api.cerebras.ai/v1 | llama-3.3-70b | cloud.cerebras.ai |
| SambaNova | https://api.sambanova.ai/v1 | Meta-Llama-3.3-70B-Instruct | cloud.sambanova.ai |
| xAI | https://api.x.ai/v1 | grok-3-mini, grok-4 | console.x.ai |
| NVIDIA NIM | https://integrate.api.nvidia.com/v1 | nvidia/llama-3.1-nemotron-ultra-253b-v1, meta/Llama-4-Maverick-… | build.nvidia.com |
| GitHub Models | https://models.github.ai/inference | — | github.com/settings/personal-access-tokens ("free with a GitHub token") |
| Hugging Face | https://router.huggingface.co/v1 | deepseek-ai/DeepSeek-V3.1, Qwen/Qwen3-Coder-480B…, moonshotai/Kimi-K2-Instruct | huggingface.co/settings/tokens |
| OpenRouter | https://openrouter.ai/api/v1 | deepseek/deepseek-chat-v3.1:free, meta-llama/llama-3.3-70b-instruct:free | openrouter.ai/keys |
| Google Gemini | https://generativelanguage.googleapis.com/v1beta/openai | gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite | aistudio.google.com/apikey |
| Ollama (lokal) | http://127.0.0.1:11434/v1 | — | — |
| LM Studio (lokal) | http://127.0.0.1:1234/v1 | — | — |
| OpenCode Go | https://opencode.ai/inference/go/openai/v1 | kimi-k3 | — |
| Custom | endpoint OpenAI/Anthropic sendiri (`custom_openai`, `custom_anthropic`) | — | — |

Kunci API pengguna disimpan di SharedPreferences `"settings"` (key `api_key`/`apiKey`) — **tanpa enkripsi** (tidak ada `EncryptedSharedPreferences`, tidak ada pemakaian `javax.crypto.Cipher` di dex). Kunci dikirim sebagai `Authorization: Bearer <key>` ke provider yang dipilih. Pencarian web AI memakai `https://html.duckduckgo.com/html/` (`Lb/d1;->Z`).

Endpoint lain: `https://docs.google.com/forms/…` di `WorkspaceActivity.s0` (kemungkinan tautan feedback/laporan).

## 7. Server MCP lokal (Model Context Protocol)

Aplikasi menjalankan **server MCP di HP sendiri** agar AI eksternal (mis. Claude Desktop/CLI) bisa mengendalikan sesi analisis:

- **Bind:** `new ServerSocket(8765, 16, null)` di `Lb/f0;-><init>` — port **8765**, backlog 16, alamat `null` = **semua interface (0.0.0.0)**, fallback ke port acak bila 8765 terpakai. Thread daemon `"mcp-accept"`; tiap koneksi ditangani thread `"mcp-client"`.
- **Endpoint:** `/mcp` (akses `/` dibalas "the endpoint is /mcp", 404).
- **Auth:** header `Authorization: Bearer <token>` **atau** query `?token=…`; dibandingkan dengan `MessageDigest.isEqual` (constant-time — praktik yang benar). Token salah → pesan "missing or wrong token: send Authorization: Bearer <token> (shown in imodisa)".
- **Token:** dibuat sekali dari `SecureRandom` 24 byte, di-encode, disimpan di SharedPreferences `"settings"` key `"mcp_token"` (plaintext, persisten). Ditampilkan di UI WorkspaceActivity beserta URL `http://<IP-LAN>:8765/mcp` (O0 mengumpulkan alamat IPv4 semua interface non-loopback yang aktif; fallback `"localhost"`) dan contoh perintah curl `--header "Authorization: Bearer …"`.
- **Origin check:** header `origin` yang tidak diizinkan → 403 "origin not allowed".
- **Protokol:** JSON-RPC MCP — `initialize` (serverInfo `{name: "imodisa", version}`, `capabilities.tools.listChanged`, `instructions`), `resources/list`, `tools/list`, `tools/call`, `ping`, `prompts/list`; error `"unknown tool: …"`, `"method not found: …"`.
- **Tools yang diekspos** (dari string + dispatch `Lb/f0;->b`): `list_files`, `list_functions`, `list_imports`, `list_exports`, `list_types`, `disassemble`, `decompile`, `pseudocode`, `call_graph`, `patch`, `patch_bytes`, `create_function`, `comment`, `auto_comments`, `get_type`, pencarian, dll. — lengkap dengan `inputSchema`.
- **Perlindungan path:** `Lb/z;->b` menolak path yang keluar folder (`".."` → error `"…" leaves the folder"`).
- **Start/stop:** `Lb/z;->c` (buat server) / `Lb/z;->d` (tutup ServerSocket + semua socket klien); dipicu dari klik UI (`Ll/o7;->onClick`).
- **Deskripsi server (instruksi MCP):** "Tools on a binary open in imodisa (an Android disassembler and decompiler, IDA-like: functions, pseudocode, names, types, xrefs); addresses are hex. The binary: …"

## 8. Lisensi & proteksi (PairIP + Google Play LVL)

- **Application class di manifest adalah `com.pairip.application.Application`** (bukan `App` sendiri) — PairIP membungkus aplikasi. `Lcom/pairip/application/Application;` extends `Lcom/rusjj/imodisa/App;`.
- **PairIP LicenseClient** (`com.pairip.licensecheck.*`, lengkap di dex): implementasi Google Play **License Verification Library v2** — `checkLicense`, `bindToLicensingService`, `processResponse`, `reportSuccessfulLicenseCheck`, `scheduleRepeatedLicenseCheck`, `performLocalInstallerCheck`, `isLocalCheckPassed`, `getLicensePubKey`, `LicenseActivity` (dialog/paywall), trial (`checkTrialStatus`, `stopTrial`), `gracefulShutdownEnabled` / `eventualShutdownEnabled` / `scheduleAppShutdown`, `PAYLOAD_PAYWALL`, `MAX_RETRIES`. Permission `com.android.vending.CHECK_LICENSE` dipakai.
- **R8 obfuscation:** nyaris seluruh logika aplikasi di-rename ke package satu huruf (`a.*`, `b.*`, `f.*`, `g.*`, `l.*`, `m.*`, `n.*`, `o.*`, `p.*`, `y.*`) dengan nama class/method/field satu huruf. Nama class yang wajib dipertahankan (manifest) dan string resource tidak di-obfuscate.
- **Tidak ada enkripsi string** — semua string (endpoint, pesan error, teks UI) terbaca langsung dari dex.
- **Tidak ditemukan** di dex: deteksi root, deteksi emulator, deteksi Xposed/Frida, Play Integrity, pengecekan signature APK saat runtime (string `root`/`emulator`/`xposed`/`frida` yang ada hanya kebetulan dari konteks lain — `rootCause`, node `ROOT`, skrip Ghidra). Keamanan lisensi bertumpu pada PairIP + server Play.
- **Satu class aneh:** `ui/Hbz/ntfdfdnxofooegtfzikkztx/vlvypapvwqyvjabwwwrwyrwbmasqj` — tanpa method, hanya 3 field `int` statik bernama acak. Kemungkinan marker/canary untuk deteksi tamper, atau artefak R8; perannya tidak bisa dipastikan dari statis saja (INFERRED).

## 9. Penyimpanan data

- SharedPreferences `"settings"` (plaintext XML): pengaturan, daftar endpoint AI + **API key LLM (plaintext)**, **`mcp_token` (plaintext)**. `allowBackup=false` (tidak bisa diambil via `adb backup`).
- File store di `getFilesDir()` (`Ln/k` — "store"), file workspace + chat AI + hasil ekspor.
- Cache di `getCacheDir()`; file temp dihapus saat `App.onCreate`.
- Tidak ada database SQLite yang terlihat; tidak ada `EncryptedSharedPreferences`.

## 10. Celah & risiko (dari kode — bukan tebakan)

1. **Server MCP di semua interface (0.0.0.0:8765).** Siapa pun di jaringan lokal yang sama (Wi-Fi) bisa mencapai server ini. Satu-satunya pertahanan adalah token Bearer 24-byte acak (kuat) + origin check. Bila token bocor (mis. terlihat di layar/UI, atau dibaca aplikasi lain di HP root — token tersimpan plaintext), penyerang di LAN bisa menjalankan semua tools MCP: membaca file/biner yang dibuka, decompile, **patch bytes**, dll. Risiko nyata tapi butuh token.
2. **API key LLM tersimpan plaintext** di SharedPreferences. Di HP root, key bisa dibaca aplikasi lain; kunci juga dikirim ke provider pihak ketiga (by design — kunci milik pengguna).
3. **Cleartext diizinkan** (`usesCleartextTraffic=true`). Endpoint AI kustom bisa memakai `http://` tanpa TLS; endpoint lokal loopback memang butuh ini.
4. **Sertifikat memakai DN template kunci uji AOSP** (lihat §1) — bukan kunci publik, tapi praktik yang buruk dan membingungkan.
5. **Lisensi (PairIP/LVL) adalah client-side enforcement.** Seperti semua LVL, patch pada respons lisensi bisa membobolnya; PairIP menambah lapisan tamper-check, tapi efektivitasnya tidak bisa dinilai penuh dari statis saja.
6. **Tidak ada certificate pinning yang ditemukan** untuk panggilan API LLM (HttpURLConnection standar) — koneksi ke provider bergantung penuh pada TLS sistem.
7. **Tidak ada deteksi root/emulator/Frida** — aplikasi tidak menolak berjalan di lingkungan yang sudah di-root/di-instrumentasi.

## 11. Verdict: bisa dipahami atau tidak?

**Jawaban singkat: YA — sebagian besar bisa dipahami dari analisis statis saja.**

| Lapisan | Seberapa bisa dipahami | Alasan |
|---|---|---|
| **Apa aplikasinya & apa yang dilakukan** | **~95% — sangat bisa** | Manifest, 739 string resource EN + 727 string ID, endpoint, dan arsitektur semuanya eksplisit. Identitas, fitur, dan alur kerja jelas tanpa perlu menjalankan aplikasi. |
| **Lapisan Kotlin (UI + AI + MCP)** | **~60–70% — sebagian** | R8 mengacak nama class/method/field jadi satu huruf, jadi membaca alur butuh mengikuti string + xref. Tapi semua string plaintext, tidak ada enkripsi string, dan struktur (Activity/Service/NativeBridge) masih terbaca. |
| **Mesin native `libimodisa.so` (inti: disassembler + decompiler)** | **~20–30% secara statis** | Stripped, ~668 KB kode ARM64, algoritma decompiler kustom tanpa simbol. Yang bisa dipahami: ia memakai Capstone + ZSTD, daftar API JNI-nya lengkap, dan tidak ada jaringan/crypto. Cara kerja detail decompiler-nya butuh Ghidra + analisis dinamis. |
| **Logika server-side** | **Tidak bisa dari statis** | Verifikasi lisensi akhir ada di server Google Play; jawaban AI ada di server provider LLM. |
| **Keseluruhan** | **~70% — cukup untuk menjawab "ini aplikasi apa, ngapain aja, dan bagaimana cara kerjanya"** | Yang tidak bisa dijawab statis: detail algoritma decompiler native dan efektivitas proteksi PairIP terhadap patch. |

**Yang menghambat pemahaman penuh (konkret):**
- R8 obfuscation: ~1.450 dari 1.461 class memakai nama satu huruf; hanya 11 class `com.rusjj.*` yang namanya utuh.
- Native core stripped: 0 simbol fungsi aplikasi (hanya simbol Capstone/LLVM yang terekspos); JNI didaftar dinamis, bukan lewat nama `Java_*`.
- Optimasi PGO/BOLT/LTO/MLGO membuat disassembly native lebih sulit dibaca.
- Sebagian logika (lisensi, AI) hidup di server pihak ketiga.

**Yang membantu pemahaman:**
- 12.237 string dex + 9.791 string `.so` semuanya plaintext (tanpa enkripsi/obfuscasi string).
- API JNI lengkap dan bernama jelas (`disasmDecode`, `scanStrings`, `findPattern`, …).
- String resource UI lengkap dalam 2 bahasa (EN + ID) — fitur bisa dipetakan 1:1.
- Manifest + sertifikat + stamp Play memberi konteks distribusi.

## 12. Isi paket dump

```
com.rusjj.imodisa/1.2.0/
  REPORT.md                  (file ini)
  apk-info.txt               (identitas, sertifikat, permission, komponen)
  file-list.txt              (daftar file ketiga split)
  manifest.xmltree.txt       (manifest base, aapt)
  manifest_arm64.xmltree.txt (manifest split arm64)
  manifest_in.xmltree.txt    (manifest split in)
  resources_base.txt         (739 string resource, EN)
  resources_in.txt           (727 string resource, ID)
  strings.txt                (12.237 string dex)
  classes.txt                (1.461 class)
  methods.txt                (9.152 method)
  fields.txt                 (5.996 field)
  app_classes.txt            (11 class aplikasi)
  dex_summary.json           (ringkasan dex)
  rea_deep.txt               (disassembly class aplikasi + PairIP, 12.305 baris)
  rea_deep2.txt              (preset endpoint AI, server MCP, AssistantService)
  rea_deep3.txt              (pembuatan server MCP, token, handler klien)
  rea_deep4.txt              (dispatch JSON-RPC MCP, cek token, origin check)
  scripts/                   (dex_parse.py, inspect_apks.py, dump_resources.py,
                              rea_deep.py, rea_deep2.py, rea_deep3.py, rea_deep4.py)
  extract/
    base/                    (isi base.apk utuh, termasuk classes.dex)
    split_arm64/             (isi split arm64, termasuk lib/arm64-v8a/libimodisa.so)
    split_in/                (isi split in, termasuk resources.arsc ID)
```

## 13. Metode & batasan

- Hanya analisis statis: androguard 4.1.4 (`AnalyzeAPK`, `MethodAnalysis` via `dx.get_method_analysis`, `dx.strings` xref), `aapt dump xmltree`, `readelf`/`nm`/`strings`, `grep` atas string pool.
- APK tidak pernah di-install/dijalankan; tidak ada analisis dinamis, tidak ada pemalsuan lisensi, tidak ada percobaan koneksi ke server mana pun.
- Klaim yang ditandai TER VERIFIKASI dibuktikan dari bytecode/string/manifest yang dikutip; sisanya ditandai INFERRED.
- Perbedaan dengan dump Istana: aplikasi ini jauh lebih kompleks secara native (decompiler di `.so`), dan proteksinya memakai PairIP + Play LVL, bukan lisensi server sendiri.
