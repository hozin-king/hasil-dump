# Pola Injector Tiga Proyek — UE Hook vs HCR Mod vs Diamond Mod

Laporan READ-ONLY (tidak ada file repo yang diubah). Semua klaim dikutip ke
file:baris. Konteks kegagalan Diamond Mod v1 di HP (22 Okt 2026): payload
probe di-dlopen dari `/data/local/tmp` → `couldn't map segment 1: Permission
denied`; payload utama dlopen OK tapi boot berhenti di `fail_no_vm`.

Sumber yang dibaca:

- UE Hook: `~/workspace/hozin-ue-hook/app/src/main/java/com/hozinking/uehook/MainActivity.java`,
  `.../cpp/injector/injector.c`, `.../cpp/payload/payload.cpp`
- HCR Mod: `~/workspace/hozin-hcr-mod/app/src/main/java/com/hozinking/hcrmod/ModInjector.java`,
  `.../cpp/injector/injector.c`, `.../cpp/payload/payload.cpp`,
  `.../cpp/payload/payload_probe.cpp`, `.../cpp/CMakeLists.txt`
- Diamond Mod: `~/workspace/hozin-diamond-mod/...` (struktur sejajar),
  `.../cpp/bootstrap.cpp`, `.../cpp/payload.cpp`, `.../cpp/payload_probe.cpp`,
  `hooks/src/com/hozinking/diamondmod/hook/Entry.java`, `.../cpp/CMakeLists.txt`

CATATAN KEADAAN REPO DIAMOND: source v1 yang ter-commit (HEAD `2e0b593`,
yang menjadi basis APK rilis v1) dipakai sebagai rujukan "v1" di bawah.
Saat laporan ini ditulis, working tree `hozin-diamond-mod` punya perubahan
BELUM ter-commit di `bootstrap.cpp` saja (`git status`: ` M
app/src/main/cpp/bootstrap.cpp`, +135/−6) — itu draf perbaikan yang sedang
berjalan; isinya diringkas di §5 karena membenarkan analisis v1.

---

## 1. STAGING — di mana payload ditaruh sebelum dlopen

### 1a. UE Hook — TANPA staging copy; path nativeLibraryDir langsung

- Injector dipanggil dengan path payload persis dari direktori lib APK
  aplikasi mod sendiri:
  `MainActivity.java:127-131` — `libDir =
  getApplicationInfo().nativeLibraryDir; injector = libDir +
  "/libinjector.so"; payload = libDir + "/libpayload.so";` lalu
  `RootUtil.su(injector + " " + pid + " " + payload)`.
- Yang masuk `/data/local/tmp` di UE hanya file teks: config
  `uehook.conf`, dump `uehook_dump.txt`, trigger `uehook_trigger`
  (`MainActivity.java:30-32`). Tidak ada `cp` .so ke mana pun.
- Status verifikasi: desain ini di kode memang begitu; tidak ada bukti di
  repo bahwa jalur ini sudah lolos uji perangkat (payload UE murni native,
  lihat §3).

### 1b. HCR Mod — copy ke /data/local/tmp, chmod 644, TANPA chcon

- Path staging: `ModInjector.java:30-31` —
  `PAYLOAD_TMP_PATH = "/data/local/tmp/hcr_payload.so"`,
  `PROBE_TMP_PATH = "/data/local/tmp/hcr_payload_probe.so"`; dependensi
  DT_NEEDED ikut di-stage berdampingan: `libc++_shared.so`, `libdobby.so`
  (`ModInjector.java:36-37`).
- Perintah staging persis (`stagePayload`, `ModInjector.java:284-299`):
  `cp -f '<nativeLibraryDir>/<name>' '<dest>' && chmod 644 '<dest>'`
  (sebagai root via `RootUtil.su`), diverifikasi dengan `ls -l`.
- Alasan tertulis di kode (`ModInjector.java:32-37` + komentar
  `stagePayload`): direktori privat `/data/app/...` tidak bisa dibaca UID
  aplikasi lain (SELinux MLS) → dlopen return NULL; dependensi ditaruh
  berdampingan karena linker bionic mencarinya di direktori yang sama
  dengan library yang di-dlopen.
- File status/boot/cmd/conf juga di `/data/local/tmp`; file yang DITULIS
  payload (UID game) disiapkan root lebih dulu: `touch … && : > … && chmod
  666` (`ModInjector.java:184-187`).

### 1c. Diamond Mod — IDENTIK dengan HCR (port langsung)

- `ModInjector.java:33-38` — `PAYLOAD_TMP_PATH =
  "/data/local/tmp/dq_payload.so"`, `PROBE_TMP_PATH =
  "/data/local/tmp/dq_payload_probe.so"`, `PINE_TMP_PATH =
  "/data/local/tmp/dq_libpine.so"`.
- Perintah staging persis sama: `cp -f '<src>' '<dest>' && chmod 644
  '<dest>'` (`stagePayload`, `ModInjector.java:286-302`); injector +
  payload native di-`chmod 755` (`ModInjector.java:218`); file status/boot
  disiapkan `chmod 666` (`ModInjector.java:186-189`).
- Perbedaan isi staging saja: HCR men-stage dependensi DT_NEEDED
  (`libc++_shared.so`, `libdobby.so`); Diamond men-stage `libpine.so` yang
  BUKAN DT_NEEDED payload — ia di-`System.load()` belakangan oleh dex
  (`Entry.java:57,95`: `PINE_PATH = TMP + "/dq_libpine.so"`, dimuat di
  `PineConfig.libLoader`). Payload Diamond sendiri menautkan STL statis
  (`CMakeLists.txt`: `-static-libstdc++`, komentar "Pelajaran HCR Mod"),
  dan readelf APK rilis membuktikan DT_NEEDED kedua payload Diamond hanya
  `liblog/libdl/libm/libc` (lihat §4).

### 1d. Konteks SELinux — TIDAK ADA di ketiga proyek

- `grep -rn "chcon|setenforce|restorecon|u:object_r"` di seluruh
  `app/src` ketiga repo + `hooks/` Diamond: **nol hasil**. Tidak ada proyek
  yang menyetel konteks SELinux file staging; file hasil `cp` oleh shell
  root mewarisi konteks bawaan `/data/local/tmp` apa adanya. Yang diatur
  hanya mode DAC (`chmod 644` untuk .so, `666` untuk file tulis-UID-game,
  `755` untuk injector).
- Implikasi: teori "probe gagal karena konteks SELinux file-nya beda"
  TIDAK didukung kode — probe dan payload utama di-stage dengan perintah,
  direktori, dan mode yang persis sama (lihat §4 untuk bukti readelf).

---

## 2. DLOPEN — mekanisme remote dlopen & penanganan error

### 2a. UE Hook — versi sederhana (offset dari libc)

- `injector.c:91-98`: `remote_dlopen = targ_libc + (local_dlopen -
  self_libc)` — offset dlopen dihitung dari base **libc.so** proses
  injector sendiri. (Kode Diamond/HCR sendiri mencatat ini sebagai bug:
  di bionic, dlopen ada di **libdl.so**, bukan libc — `injector.c:91-92`
  HCR/Diamond.)
- Trap: `PTRACE_ATTACH` → tulis path ke stack target via `PTRACE_POKETEXT`
  → set `x0=path, x1=2 (RTLD_NOW), lr=0, pc=remote_dlopen` → `PTRACE_CONT`
  → return menabrak lr=0 → SIGSEGV yang memang diharapkan
  (`injector.c:102-133`).
- Verifikasi hasil: MINIMAL — hanya membaca `x0` (handle) dan log
  `signal`/`handle` (`injector.c:128`). Tidak ada klasifikasi
  ok/null/crash, tidak ada pembacaan remote `dlerror()`, tidak ada
  verifikasi alamat terhadap `/proc/<pid>/maps`, tidak ada file hasil.

### 2b. HCR Mod & Diamond Mod — injector.c IDENTIK (selain nama)

`diff` kedua `injector.c` hanya beda awalan simbol (`hcr_`/`dq_`), tag
log, dan path file hasil. Mekanismenya:

- Resolusi alamat SEBELUM attach (`injector.c:176-223,287-296`):
  `remote_sym2()` — dlsym lokal simbol → cari modul pemiliknya di
  `/proc/self/maps` → base modul yang sama di target → `remote =
  targ_base + (local − self_base)`; khusus dlopen ada fallback
  `__loader_dlopen`. Alamat hasil WAJIB lolos `verify_xmap()`: harus
  berada di mapping ber-permisi `x` milik modul yang benar di
  `/proc/<pid>/maps`, kalau tidak inject dibatalkan sebelum target
  disentuh.
- Trap sama seperti UE (x0=path, x1=RTLD_NOW=2, lr=0, pc=remote_dlopen),
  `injector.c:329-338`.
- Klasifikasi hasil (`injector.c:339-384`): trap normal = `SIGSEGV`
  dengan `pc_after==0`; handle≠0 → `"ok"`; handle==0 → `"null"` lalu
  injector memanggil **remote dlerror()** (alamatnya diresolusi +
  diverifikasi xmap dengan cara yang sama) dan membaca string error
  dari memori target — dari sinilah teks `couldn't map … Permission
  denied` di log user berasal; pc≠0/signal lain → `"crash"` (target
  crash DI DALAM dlopen, mis. constructor payload).
- Hasil ditulis sebagai JSON ke `/data/local/tmp/<app>_mod_inject.json`
  (`{"dlopen":…,"signal":…,"handle":…,"pc_after":…,"dlerror":…}`) untuk
  dibaca aplikasi.
- Di sisi Java (kedua proyek sama): retry maks 3× dengan urutan path
  `[tmp, nativeLibraryDir, tmp]`, jeda ±1 dtk; berhenti dini pada `ok`
  atau `crash`; `null` → lanjut percobaan berikutnya; setelah gagal total
  → jalankan probe diagnostik (HCR `ModInjector.java:225-267`, Diamond
  `ModInjector.java:231-268` + `runProbe` di keduanya).

---

## 3. JAVAVM — siapa butuh VM, dan bagaimana memperolehnya

### 3a. UE Hook & HCR Mod — payload TIDAK memakai JavaVM sama sekali

- `grep JavaVM|JNIEnv|JNI_` di `payload/` kedua proyek: **nol hasil**.
- UE payload (`payload.cpp:71-110`): constructor hanya `pthread_create`;
  thread `sleep(1)`, self-test Dobby, lalu kerja native murni atas lib
  game Unreal.
- HCR payload (`payload/payload.cpp` header + `payload_probe.cpp:54-70`):
  constructor → thread menunggu `libgame.so` ter-load → pattern-scan →
  patch/Dobby native. Probe HCR pun murni native: constructor menulis
  breadcrumb `{"stage":"probe_loaded"}` + status JSON — TANPA JVM, jadi
  di HCR probe benar-benar mengisolasi "dlopen/injector" vs "init
  payload".
- Konsekuensi: **tidak ada pola akuisisi JavaVM "terbukti" di codebase
  kita selain milik Diamond sendiri** — dua proyek lain tidak pernah
  menghadapi masalah ini karena targetnya native (Unreal / Cocos2d-x).

### 3b. Diamond Mod v1 — satu-satunya akuisisi VM, dan titik gagalnya

Alur: constructor payload (`payload.cpp`, 7 baris) →
`dq_start_bootstrap(boot_path, entry_class)` (`bootstrap.cpp` v1:148-161)
→ thread detached → `wait_vm()` → AttachCurrentThread → cari classloader
aplikasi (retry 90×1 dtk) → muat dex tertanam via
`InMemoryDexClassLoader` → `Entry.init(app_loader)` → di sanalah Pine
dimuat dan hook dipasang (`Entry.java:88-101`). Jadi hook TIDAK pernah
dipasang sebelum seluruh rantai VM→classloader→dex→Entry berhasil.

`wait_vm()` v1 (`bootstrap.cpp` commit HEAD, baris 41-56) — PERSIS dua
jalur:

```cpp
void* art = dlopen("libart.so", RTLD_NOW | RTLD_NOLOAD);
if (art) get_vms = dlsym(art, "JNI_GetCreatedJavaVMs");
if (!get_vms) get_vms = dlsym(RTLD_DEFAULT, "JNI_GetCreatedJavaVMs");
if (!get_vms) return nullptr;            // <- menyerah SEKETIKA
for (int i = 0; i < 90; i++) { …poll 1 dtk… }
```

Bukti deduksi dari log lapangan + kode:

1. Breadcrumb `fail_no_vm` ditulis `bootstrap_thread` bila `wait_vm()`
   mengembalikan nullptr (v1 `bootstrap.cpp:119-120`).
2. Di log user, `fail_no_vm` SUDAH terbaca aplikasi pada ±26 detik
   setelah inject (23:15:39 → 23:16:05), padahal jalur polling
   `wait_vm` butuh 90 detik penuh sebelum menyerah. Satu-satunya jalur
   yang bisa menulis `fail_no_vm` secepat itu adalah `get_vms ==
   nullptr` — kedua resolusi simbol gagal, VM tidak pernah dicari.
3. Kenapa gagal, konsisten dengan kode: payload di-dlopen dari path
   `/data/local/tmp` sehingga berada di namespace linker hasil
   dlopen proses app; dari sana `dlopen("libart.so")` nama-pendek tidak
   menjangkau libart yang tinggal di namespace APEX `com.android.art`,
   dan `JNI_GetCreatedJavaVMs` tidak ada di cakupan `RTLD_DEFAULT`
   proses app. (Penjelasan namespace ini inferensi dari perilaku yang
   teramati + struktur kode; yang FAKTA kode: v1 tidak pernah mencoba
   path absolut APEX dan tidak punya jalur resolusi ketiga.)

Celah timing kedua (laten, dari kode): aplikasi hanya menunggu status
25 dtk pada run itu (log "maks 25 dtk"), sementara bootstrap punya DUA
loop 90×1 dtk bertingkat (VM, lalu classloader) sebelum `Entry.init`
jalan. Sekalipun resolusi simbol berhasil tapi VM/classloader lambat,
aplikasi akan menyatakan gagal lebih dulu.

---

## 4. Bukti readelf APK rilis Diamond v1 (artefak yang gagal di HP)

Dari `~/workspace/your_files/HozinDiamondMod-v1.apk`,
`lib/arm64-v8a/libpayload.so` vs `libpayload_probe.so`:

- DT_NEEDED keduanya IDENTIK: `liblog.so, libdl.so, libm.so, libc.so`
  (tidak ada `libc++_shared.so` — STL statis bekerja).
- PT_LOAD keduanya nyaris identik: 3 segmen, pola R-E / RW / RW, `Align
  0x1000`, ukuran segmen pertama 0x52a00 vs 0x52a10. Keduanya menanam
  `bootstrap.cpp` yang sama (`payload.cpp` & `payload_probe.cpp` hanya
  beda string entry class) — wajar ukurannya kembar.
- Kesimpulan: **tidak ada perbedaan struktural pada file** yang bisa
  menjelaskan kenapa probe gagal di-map ("segment 1") sementara payload
  utama lolos dari direktori + perintah staging yang sama. Penyebab
  perbedaan hasil map itu TIDAK ada di kode sumber maupun di artefak
  build; kandidatnya faktor runtime perangkat (kondisi file hasil
  staging di HP / keadaan proses saat injeksi kedua) — untuk
  dibuktikan dari log perangkat, bukan dari repo. Petunjuk yang sudah
  ada di kode: `stagePayload` mencatat hasil `ls -l` file staging ke
  log aplikasi (`ModInjector.java:299-301` Diamond) — baris itulah yang
  perlu diperiksa untuk file probe pada run yang gagal.

---

## 5. Draf perbaikan yang SUDAH ada di working tree (belum ter-commit)

`bootstrap.cpp` Diamond saat ini (diff +135/−6 dari HEAD) menulis ulang
resolusi VM persis di titik §3b:

1. `resolve_via_dlopen()` — coba `dlopen` RTLD_NOLOAD atas: `"libart.so"`,
   `/apex/com.android.art/lib64/libart.so`,
   `/apex/com.android.runtime/lib64/libart.so`, `/system/lib64/libart.so`,
   lalu dlsym `JNI_GetCreatedJavaVMs`; cadangan `RTLD_DEFAULT`.
2. `resolve_via_elf()` — parse ELF libart yang SUDAH termuat:
   `dl_iterate_phdr` → PT_DYNAMIC → dynsym/strtab (hash & GNU hash) →
   alamat = load bias + `st_value`. Tidak lewat dlopen sama sekali
   (komentar kode menyebutnya pola kelas Frida).
3. Stage kegagalan kini dibedakan: `g_vm_fn_missing` memisahkan "fungsi
   tak ter-resolusi" dari "VM belum muncul" agar breadcrumb jujur.

Komentar kepala bloknya sendiri mencatat pelajaran lapangan v1 persis
seperti deduksi §3b (fail <30 dtk, namespace APEX, RTLD_DEFAULT kosong).

---

## 6. Perbandingan & rekomendasi untuk perbaikan Diamond

| Aspek | UE Hook | HCR Mod | Diamond v1 |
|---|---|---|---|
| Staging .so | path nativeLibraryDir langsung, tanpa copy | copy → `/data/local/tmp`, `chmod 644` | SAMA persis dengan HCR |
| chcon/konteks SELinux | tidak ada | tidak ada | tidak ada |
| Resolusi dlopen remote | offset dari base libc (usang) | modul pemilik simbol (libdl) + fallback `__loader_dlopen` + verify xmap | IDENTIK HCR |
| Klasifikasi hasil dlopen | tidak ada (log handle saja) | ok/null/crash + remote dlerror + JSON hasil | IDENTIK HCR |
| Probe diagnostik | tidak ada | native murni (isolasi dlopen murni) | bootstrap JVM penuh (tidak mengisolasi setajam HCR) |
| JavaVM | tidak dipakai | tidak dipakai | `dlopen("libart.so")` + `RTLD_DEFAULT` saja → `fail_no_vm` |
| Momen hook dipasang | constructor→thread, native | setelah `libgame.so` + scan pola | setelah VM→classloader→dex→`Entry.init` (rantai terpanjang) |

Rekomendasi konkret (berbasis bukti di atas):

1. **Staging: PERTAHANKAN pola HCR/Diamond** (copy ke `/data/local/tmp`
   + `chmod 644`). Itu satu-satunya pola staging yang di run gagal pun
   terbukti mengantar payload utama sampai `dlopen ok` dengan handle
   valid; pola UE (path native langsung) justru ditinggalkan oleh dua
   proyek sesudahnya dan tidak punya bukti lolos di perangkat.
   Kegagalan map pada probe tidak punya dasar perbedaan di kode/artefak
   — jangan "memperbaiki" staging membabi buta; buktikan dulu dari baris
   log `stagePayload: … (ls -l …)` untuk `dq_payload_probe.so` pada run
   gagal (ukuran file di perangkat vs di APK adalah cek pertama:
   salinan terpotong akan gagal map persis seperti ini).
2. **Akuisisi VM: adopsi urutan resolusi draf §5** — path absolut APEX
   dulu, `RTLD_DEFAULT` sebagai cadangan, dan parse-ELF `dl_iterate_phdr`
   sebagai jalur terakhir yang kebal namespace. Inilah satu-satunya
   titik di mana Diamond menyimpang dari semua pola lain: bukan karena
   proyek lain lebih baik, tapi karena Diamond satu-satunya yang butuh
   VM dan v1 hanya punya dua jalur yang sama-sama mati di namespace
   proses app. Tambahkan pembeda stage "fungsi tak ter-resolusi" vs "VM
   belum muncul" (sudah ada di draf) agar kegagalan berikutnya terbaca
   dalam sekali lihat.
3. **Selaraskan timing**: naikkan kesabaran aplikasi menunggu status
   (atau persingkat loop bootstrap) — 25 dtk di aplikasi vs 90+90 dtk
   di bootstrap adalah ketidakcocokan nyata di kode, akan menggigit
   begitu resolusi simbol beres tapi VM lambat.
4. **Probe**: pertimbangkan probe dua lapis ala HCR — probe native
   murni (breadcrumb+status, tanpa JVM) untuk isolasi dlopen, di
   samping probe JVM yang ada. Pada insiden ini probe JVM gugur di
   tahap map sehingga nilai isolasinya hilang; probe native akan tetap
   menjawab "injector sehat/tidak" dalam keadaan yang sama.
