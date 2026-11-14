# REA — libGGP.so (Garena Game Protector / Bifrost) — Free Fire MAX 2.132.1

File: `libGGP.so` — 9.420.464 byte, SHA-256
`fb14ebf2ce0d95230cec782e542b10a8596debe65d6ac33e271b8f60df7336a8`
Sumber: `hasil-dump/com.dts.freefiremax/2.132.1/arm64-v8a/dump/libGGP.so`
(diekstrak dari bundle `.apkm` resmi 2.132.1, `split_config.arm64_v8a.apk`).
Working copy analisis: `~/workspace/rea-ffmax-ggp/libGGP.so` (hash sama, terverifikasi).
Analisis statis READ-ONLY — file tidak dijalankan, tidak di-load ke proses apa pun.

## 0. Ringkasan eksekutif

`libGGP.so` adalah anti-cheat Garena Game Protector (GGP) untuk Free Fire MAX
2.132.1 — dan dari bukti internal file ini, **file ini sendiri adalah Bifrost**
(mesin anti-cheat Tencent/ACE): SONAME internal-nya `libBifrost.so`, bukan
`libGGP.so`. Ini mengoreksi laporan REA FF Max 24 Okt 2026 yang menyatakan
"tidak ada `libBifrost.so` di bundle": benar tidak ada *file terpisah*
bernama itu, tetapi Bifrost hadir di dalam file ini.

File ini **dikemas/dienkripsi dan sengaja dibuat tahan analisis statis**:
tabel simbol dinamis diacak (bahkan entri simbol ke-0 yang wajib nol pun berisi
sampah), string terenkripsi (entropi ~7,9 bit/byte), section header digunduli,
tidak ada impor fungsi lewat PLT sama sekali, dan satu-satunya kode yang
terbaca jelas adalah constructor `.init_array` yang (a) mendekode pointer
dengan XOR, (b) memanggil `mprotect` langsung lewat `svc` untuk membuat
sebuah region menjadi RWX, lalu (c) melompat lewat pointer hasil dekode.
Pola ini konsisten dengan stub *self-decrypting*: isi sebenarnya baru
terbuka saat library di-load.

**Yang bisa dipastikan dari analisis statis:** identitas file, toolchain
(NDK r21e, clang/LLD 9.0.9), SONAME Bifrost, tidak adanya impor PLT, pola
init stub, dan ketiadaan string deteksi dalam bentuk plaintext.
**Yang TIDAK bisa dipastikan:** cara kerja deteksinya (apa yang diperiksa,
apa yang dikirim, dan ke mana) — semuanya tersembunyi di balik enkripsi dan
hanya bisa dilihat lewat analisis runtime, yang tidak dilakukan di sini.

Laporan ini adalah **karakterisasi, bukan cara bobol**. Tidak ada resep
bypass/disable GGP, tabel offset/kandidat hook untuk evasi, patch, atau
instruksi mematikan proteksi di laporan ini. Temuan yang hanya berguna
untuk evasi ditulis sebagai "teramati, detail tidak dipublikasikan".

## 1. Identitas & keaslian

| Item | Nilai |
|---|---|
| File | `libGGP.so` |
| Ukuran | 9.420.464 byte |
| SHA-256 | `fb14ebf2ce0d95230cec782e542b10a8596debe65d6ac33e271b8f60df7336a8` |
| Format | ELF64, little endian, AArch64, `ET_DYN` (shared object) |
| Entry point (ELF header) | `0xf600` — menunjuk ke byte acak, **bukan kode valid** (decoy) |
| SONAME | **`libBifrost.so`** (bukan `libGGP.so`) |
| Build ID (GNU) | `7e2ecc0fe84254eefce4813a47b9d54229e6ebc2` |
| Toolchain | NDK **r21e** (build 7075529), clang **9.0.9**, linker **LLD 9.0.9** |
| Program headers | 8 (2× LOAD, DYNAMIC, 2× NOTE, GNU_EH_FRAME, GNU_STACK, GNU_RELRO) |
| Section headers | 25 — sebagian besar digunduli (NULL); hanya `.dynstr`, `.dynamic`, satu PROGBITS tanpa nama, satu NOBITS, dan shstrtab yang tersisa |
| `.symtab` / `.strtab` | **Tidak ada** (stripped) |
| Debug info | Tidak ada |

### 1.1 Layout segment

- LOAD RX: offset `0x0`, vaddr `0x0`, ukuran `0x11d3e0` (~1,15 MB) — kode +
  rodata.
- LOAD RW: offset `0x11d4a0`, vaddr `0x1214a0`, file `0xd308`, mem `0x10628`
  — data + BSS (`0x3318` NOBITS).
- PROGBITS tanpa nama: offset `0x120000`, ukuran `0x7db77b` (~8,2 MB) —
  sebagian besar isi file berada di sini; tidak ada nama section sehingga
  batas kode/rodata/data tidak bisa dipisahkan secara statis.
- GNU_STACK: RW (bukan `RWE`) — stack tidak executable.
- GNU_RELRO: `0x11d4a0–0x11ff…` — sebagian data read-only setelah relokasi.
- `DT_FLAGS`: `BIND_NOW` (+ `FLAGS_1: NOW`) — binding segera saat load.

### 1.2 Toolchain (bukti dari string ident)

String ident compiler muncul 4× di file (beberapa object file):

```
Android (7019983 based on r365631c3) clang version 9.0.9
(https://android.googlesource.com/toolchain/llvm-project
a2a1e703c0edb03ba29944e529ccbf457742737b) (based on LLVM 9.0.9svn)
Linker: LLD 9.0.9 (https://android.googlesource.com/toolchain/llvm-project ...)
```

Catatan Android (`NT_VERSION`) mengodekan NDK **r21e** (build 7075529).
Artinya komponen ini dibangun dengan toolchain NDK r21 (~2021) — konsisten
dengan pustaka anti-cheat yang dipertahankan lintas versi game, bukan
dibangun ulang tiap rilis.

### 1.3 SONAME: file ini adalah Bifrost

`readelf -d` menunjukkan:

```
0x000000000000000e (SONAME)  Library soname: [libBifrost.so]
```

Satu-satunya kemunculan string `Bifrost` di seluruh file 9,4 MB adalah
di sini (offset `0xf59`, di ekor `.dynstr`). Nama file di APK
(`libGGP.so`) adalah nama muat (*load name*); identitas internal-nya
Bifrost — mesin anti-cheat Tencent (ACE). **Koreksi atas REA FF Max
24 Okt §2:** kalimat "tidak ada `libBifrost.so` di bundle ini" hanya benar
dalam arti tidak ada file terpisah bernama demikian. Bifrost-nya sendiri
ada — di dalam `libGGP.so` ini.

## 2. Stack / teknologi

- **Bahasa: C++** — dibuktikan string runtime yang ter-link statis:
  `libc++` NDK (`NSt6__ndk1...`, `std::thread`, `recursive_mutex`),
  `libc++abi` (`__cxa_guard_*`, `__cxa_...`), dan **demangler Itanium**
  lengkap (`...itanium_demangle...MemberExprE` dsb.). String-string ini
  adalah satu-satunya plaintext terstruktur yang besar di file.
- **Tidak ada JNI.** 0 hit untuk `JNI` / `Java` / `Java_` di seluruh file.
  Library ini tidak mengekspor fungsi JNI; semua inisialisasi berjalan
  lewat constructor `.init_array` saat `dlopen`/`System.loadLibrary`.
- **Tidak ada impor fungsi lewat PLT.** `PLTRELSZ = 0`; seluruh 2.286
  relokasi adalah `R_AARCH64_RELATIVE` (RELACOUNT = 2.286 = total).
  Library tidak memanggil fungsi libc/liblog/libdl lewat PLT sama sekali.
- **DT_NEEDED (hanya 5):** `liblog.so`, `libdl.so`, `libz.so`,
  `libc.so`, `libm.so`. Karena tidak ada relokasi simbolik, pustaka-pustaka
  ini hanya dimuat, bukan diikat simbolnya saat load.
- **Satu-satunya panggilan sistem yang terlihat statis:** 2 instruksi
  `svc #0` yang selaras (aligned) di seluruh segmen RX — keduanya di
  constructor dan keduanya `mprotect` (nomor syscall 226, lihat §4).
  Tidak ada `svc` lain yang selaras di file.
- **Tidak ada `libanogs.so` / `libanort.so` / `libFFWebRequest.so` yang
  terlihat di file ini** (0 hit) — nama-nama itu disebut di REA FF Max §2
  sebagai library lain di split arm64, bukan bagian dari `libGGP.so`.

## 3. Temuan per area

### 3.1 Tabel simbol dinamis: diacak dengan sengaja

`.dynsym` berisi 90 entri (offset `0x4e0`, `SYMENT` 24). Hasil parse
langsung (Python, `struct` Elf64_Sym):

- **Entri ke-0 (null symbol) tidak nol**: `st_name=0, st_info=0xa7,
  st_shndx=47875, st_value=0x7ba8d46, st_size=378769304`. Dalam ELF yang
  valid, entri 0 wajib seluruhnya nol. Ini bukti langsung bahwa tabel
  simbol **sengaja diacak**, bukan rusak karena pemotongan.
- 86 dari 90 entri memiliki `st_value` di luar rentang file dan
  `st_shndx` acak (ribuan). Hanya 4 entri ekor (86–89) berpenampilan
  wajar (`st_value=0`, ukuran 4/8) — tetapi `st_name=0` (nama kosong),
  sehingga tetap tidak teridentifikasi.
- `readelf --dyn-syms`, `nm -D`, dan `objdump -T` semuanya melaporkan
  **0 simbol** (readelf gagal karena section header digunduli;
  llvm-readelf mem-parse sampah).
- `.dynstr` (1.068 byte, offset `0xd50`): ~600 byte pertama berentropi
  tinggi (acak); hanya ekornya yang terbaca — nama library
  (`libBifrost.so`, `libc.so`, `libdl.so`, `liblog.so`, `libm.so`,
  `libz.so`) dan string versi `LIBC`.
- `VERNEED` (3 entri) masih utuh dan valid: versi `LIBC` dibutuhkan
  dari `libc.so`, `libdl.so`, `libm.so`. `VERSYM` utuh tetapi tidak
  informatif (hampir semua bernilai 2). `GNU_HASH` (`nbuckets=3`,
  `symoffset=86`) dan SysV `HASH` (`nbucket=67, nchain=90`) konsisten
  dengan 90 entri — tetapi rantai hash-nya menunjuk ke entri yang
  diacak, sehingga tidak berguna untuk pemulihan nama.

**Kesimpulan: tidak satu pun nama fungsi impor/ekspor yang bisa
dipulihkan secara statis dari file ini.** Daftar impor/ekspor =
TIDAK DAPAT DIPASTIKAN (bukan "kosong" — tabelnya ada, isinya diacak).

### 3.2 Strings: verifikasi ulang klaim 0-hit REA 24 Okt

`strings -a` (min. 4 karakter) menghasilkan 95.226 baris — sebagian
besar adalah derau dari region terenkripsi (rangkaian printable acak
3–8 karakter yang tersebar merata di semua region 1 MB file).

| Kata kunci (case-insensitive) | Hit | Keterangan |
|---|---|---|
| magisk, xposed, frida, root, ptrace, hook, cheat, ban, integrity, emulator, debug, busybox, supersu, zygisk, lsposed, substrate, TracerPid, selinux | **0** | Klaim REA 24 Okt **TERKONFIRMASI** |
| `su` | 86 | Semua fragmen acak (`29sU`, `}Thsu_i` …) — tidak ada `/system/bin/su` atau sejenisnya |
| `gdb` | 7 | Fragmen acak (`Gdb*`, `Gdbr`) — bukan string deteksi |
| `Bifrost` | 1 | Hanya SONAME `libBifrost.so` |
| `GGP`, `garena`, `tencent`, `ACE` | 0 | Tidak ada penanda vendor/nama produk lain |
| `JNI`, `Java` | 0 | Tidak ada ekspor JNI |
| `pthread`, `socket`, `maps`, `memfd`, `seccomp` | 0 | Tidak ada string API deteksi yang terbaca |
| `dlopen` | 1 | Satu kemunculan (`dlopen: `) tanpa konteks yang bisa dipastikan — bukan bukti call site |
| `android` | 10 | Hanya string ident compiler (clang/LLD, lihat §1.2) |
| URL/domain | 1 | Hanya `android.googlesource.com/toolchain/llvm-project` (jejak toolchain) — **tidak ada domain/IP/C2 apa pun** |
| Path `/proc`, `/sys`, `/data`, `/system` | 0 | Tidak ada path deteksi yang terbaca |

Plaintext yang benar-benar terstruktur di file hanya empat kelompok:
(1) nama library + `LIBC` di ekor `.dynstr`; (2) pesan runtime
`libc++`/`libc++abi` (mutex, thread, `__cxa_guard`, demangler);
(3) string ident compiler/LLD; (4) satu string format
`%/libthor_utils.so` (lihat §3.4).

### 3.3 Entropi: kode dan data terenkripsi/diobfuscate

| Region | Entropi |
|---|---|
| PROGBITS tanpa nama (0x120000, ~8,2 MB) | **7,914 bit/byte** |
| Segmen LOAD RX (0–0x11d3e0) | 7,764 bit/byte |
| Window 0x100000 (region string libc++) | 6,472 bit/byte |
| `.dynstr` | 7,349 bit/byte |

Kode ARM64 normal berada di kisaran ~7,0–7,5 bit/byte; nilai 7,76–7,91
mendekati acak dan konsisten dengan kode/data yang **dienkripsi atau
diobfuscate berat**, bukan kode compiler biasa. Region yang masih
terbaca (window 0x100000, entropi 6,47) adalah tempat string runtime
C++ berada. Bersama temuan §3.1 dan §3.2, ini membentuk gambaran
tiga lapis: (a) string terenkripsi, (b) simbol diacak, (c) kode
di-entry tidak valid — lihat §4.

### 3.4 Satu-satunya referensi eksternal yang terbaca: `libthor_utils.so`

Satu kemunculan string `%/libthor_utils.so` (offset file `0x10afa9`),
diapit byte acak di satu sisi dan string format libc++
(`h%x`, `%llx@%llx`, `thread constructor failed`) di sisi lain.
Awalan `%` menunjukkan ini bagian dari format string pembangun path
(mis. pola `%s/libthor_utils.so`).

Yang bisa disimpulkan: library ini **mengenal nama `libthor_utils.so`**
— komponen pendamping yang kemungkinan dimuat saat runtime.
Yang TIDAK bisa dipastikan: apakah file itu dimuat, dari path mana,
dan untuk apa — tidak ada call site yang bisa dilacak secara statis
(simbol diacak, tidak ada impor PLT). Nama "thor" sendiri tidak
dijelaskan lebih jauh di file ini.

### 3.5 Entry point dan FINI: bukan kode

- Byte di entry point ELF (`0xf600`) dan di sekitar alamat FINI
  (`0x10b00–0x10b4c`) adalah byte acak yang **tidak bisa di-disassembly**
  (Capstone: 0 instruksi valid). Entry point sebuah `.so` memang
  diabaikan loader, tetapi fakta bahwa isinya bukan kode — bersama
  §3.1–§3.3 — memperkuat bahwa sebagian besar file ini bukan kode
  yang bisa dibaca langsung, melainkan muatan terobfuscate yang baru
  bermakna setelah didekode saat load.

## 4. Constructor `.init_array`: stub dekode + `mprotect` (aliran umum)

`DT_INIT_ARRAY` menunjuk satu constructor di `0x71434`
(`DT_FINI_ARRAY`: `0x10b3c`, `0x10b2c` — keduanya di region yang tidak
terbaca, lihat §3.5). Disassembly dengan Capstone (AArch64) atas
constructor ini — satu-satunya fungsi yang terbaca jelas di file —
menunjukkan alur berikut, **dideskripsikan secara umum**:

1. **Dekode pointer dengan XOR.** Constructor memuat nilai dari
   `.data.rel.ro` (region `0x12d000`/`0x123000`), meng-XOR dengan
   konstanta, lalu mengurangkan/menambahkan untuk memperoleh alamat
   sebenarnya. Konstanta XOR pertama yang teramati: `0x9abf1458`.
   Setiap blok memakai konstanta berbeda — pola yang sama berulang
   di seluruh constructor.
2. **Menyiapkan region RWX lewat syscall langsung.** Dari alamat hasil
   dekode, constructor menghitung rentang yang dibulatkan ke batas
   halaman (percobaan pertama 4 KB, fallback 16 KB — menangani
   perangkat dengan halaman 16 KB), lalu memanggil `mprotect`
   (syscall AArch64 nomor 226, `svc #0`, `w2 = 7` =
   `PROT_READ|PROT_WRITE|PROT_EXEC`) — **langsung via `svc`, bukan
   lewat libc**, konsisten dengan tidak adanya impor PLT.
3. **Dispatch lewat pointer hasil dekode.** Setelah itu constructor
   berlanjut sebagai rangkaian blok-blok kecil yang masing-masing
   berakhir dengan `br x8` — lompat tidak langsung ke alamat yang
   baru saja didekode (pola yang sama berulang: muat indeks teracak
   dari tabel → `eor` dengan konstanta per-situs → hitung
   `table + index*8` → muat pointer → tambah konstanta → `br`).
   Ini adalah dispatch aliran-kontrol terobfuscate: urutan eksekusi
   sebenarnya tidak bisa diikuti tanpa mendekode tabel pointer saat
   runtime.

Alur di atas — dekode pointer, buka proteksi tulis-eksekusi, lalu
melompat ke kode hasil dekode — adalah pola stub *self-decrypting*:
constructor menyiapkan dan membuka muatan yang masih terenkripsi di
file. **Detail lebih jauh (tabel pointer lengkap, kunci per-situs,
isi region yang dibuka) tidak dipublikasikan di sini**, karena hanya
berguna untuk evasi. Untuk karakterisasi, cukup dicatat: proteksi
dibangun untuk didekode saat load, bukan dibaca statis.

## 5. Perbandingan dengan REA FF Max 24 Okt 2026 (§2/§5)

| Klaim REA 24 Okt | Hasil verifikasi ulang dari file ini |
|---|---|
| `libGGP.so` 9,4 MB, ELF stripped, tanpa dynamic symbol | **TERKONFIRMASI + diperkuat.** Bukan hanya stripped: `.dynsym` diacak (entri null tidak nol), `.dynstr` sebagian acak, section header digunduli, tidak ada `.symtab`. |
| "Tidak ada `libBifrost.so` di bundle" | **DIKOREKSI.** Tidak ada *file terpisah* bernama itu — tetapi SONAME `libGGP.so` ini adalah `libBifrost.so`. File ini sendiri adalah Bifrost. |
| 0 hit untuk magisk/xposed/frida/root/ptrace/hook/cheat/ban/integrity; string terenkripsi | **TERKONFIRMASI.** 0 hit untuk semua kata itu (plus busybox/supersu/zygisk/lsposed/substrate/TracerPid/selinux/emulator/debug). Entropi region utama 7,76–7,91 bit/byte. |
| GGP ikut dikirim (stripped); ruang lingkup deteksi tidak bisa dipastikan dari string statis | **TERKONFIRMASI.** Tidak ada string deteksi, endpoint, atau perilaku yang bisa dipastikan dari statis. |
| `libanogs.so`/`libanort.so` ada di split arm64 | **Tidak dapat dipastikan dari file ini.** 0 hit di `libGGP.so`; nama itu milik library lain di split, bukan bagian file ini. |
| "Tidak ada `libBifrost.so`" sebagai bukti Bifrost absen | **Ditarik.** Kehadiran Bifrost justru terkonfirmasi lewat SONAME (lihat §1.3). |

## 6. Tabel temuan (karakterisasi)

| Temuan | Status | Bukti |
|---|---|---|
| File ini adalah Bifrost (SONAME `libBifrost.so`) | Terkonfirmasi | `DT_SONAME`, satu-satunya string `Bifrost` di file |
| Anti-cheat GGP FF Max 2.132.1 resmi | Terkonfirmasi | Asal dari bundle `.apkm` resmi (signer 111dots studio, REA 24 Okt §1); SONAME + string `libthor_utils.so` |
| Simbol impor/ekspor | TIDAK DAPAT DIPASTIKAN | `.dynsym` diacak (entri null ≠ 0); 0 nama terpulihkan |
| String deteksi (root/frida/magisk/dll.) | Tidak ada dalam plaintext | 0 hit; string terenkripsi (entropi ~7,9) |
| Endpoint/domain/IP/C2 | Tidak ada yang terbaca | 0 URL kecuali jejak toolchain LLVM |
| Cara kerja deteksi (apa diperiksa, apa dikirim) | TIDAK DAPAT DIPASTIKAN | Butuh analisis runtime; isi terenkripsi |
| Constructor: dekode pointer + `mprotect` RWX + dispatch tak langsung | Teramati (aliran umum) | Disassembly Capstone `0x71434` (2× `svc` mprotect, XOR key, pola `br x8` berulang) |
| Referensi ke `libthor_utils.so` | Teramati (1×) | String format di `0x10afa9`; pemuatan & tujuannya TIDAK DAPAT DIPASTIKAN |
| Toolchain NDK r21e / clang 9.0.9 / LLD 9.0.9 | Terkonfirmasi | String ident compiler (4×) + catatan Android |
| Ekspor JNI | Tidak ada yang terlihat | 0 hit `JNI`/`Java` |
| `libanogs`/`libanort` di dalam file ini | Tidak ada | 0 hit |

## 7. Risiko & catatan

- **Bypass/disable GGP = evasi deteksi pada game online** dan tetap
  **DITOLAK** (sama seperti vonis REA FF Max §4/§6: tidak ada mod FF Max
  yang dibangun). Laporan ini tidak berisi apa pun yang memungkinkan
  hal itu.
- Library ini dimuat saat game jalan dan constructor-nya aktif saat
  load; analisis di sini murni statis dan tidak menyentuh proses game.
- Karena isi terenkripsi, **tidak ada jaminan** bahwa daftar di atas
  lengkap — muatan yang baru terbuka saat runtime bisa berisi
  pemeriksaan tambahan yang tidak terlihat di sini.

## 8. Batas analisis ini (dinyatakan plain)

- Analisis **statis saja**: `readelf`/`llvm-readelf`, `strings`,
  hitung entropi, parse manual `.dynsym`/`.dynstr`/VERNEED/relokasi
  dengan Python, dan disassembly Capstone atas entry/INIT/FINI.
- **Tidak ada Ghidra/Hopper/IDA** di VM ini — dekompilasi/pseudocode
  tidak tersedia; hasil disassembly dibaca langsung dari instruksi.
- Tidak ada analisis runtime (tidak di-load, tidak di-debug, tidak ada
  packet capture) — semua yang terenkripsi dinyatakan
  TIDAK DAPAT DIPASTIKAN, bukan ditebak.
- Disassembly dibatasi pada constructor `.init_array` dan pemeriksaan
  entry/FINI; tidak ada pemetaan fungsi/offset untuk evasi.
- File unduhan asli dan working copy tidak diubah selama analisis
  (hash SHA-256 sama sebelum/sesudah: `fb14ebf2…7336a8`).
- Artefak pendukung: `strings_all.txt` (95.226 baris `strings -a`)
  di folder yang sama dengan laporan ini.
