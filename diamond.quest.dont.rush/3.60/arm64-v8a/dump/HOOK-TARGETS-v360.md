# Peta Target Hook Terverifikasi — Diamond Quest: Don't Rush! v3.60

Tanggal: 22 Oktober 2026
Sifat: **analisis statis READ-ONLY** untuk tim perbaikan Hozin Diamond Mod. Tidak ada kode mod yang ditulis/diubah di sini.
Basis bukti: dump 21 Okt 2026 di `~/workspace/rea-defender/` (`REPORT.md` + `ANALISIS-LANJUT.md`), diverifikasi ulang di level **dex/bytecode** dengan androguard 4.1.4 atas `extracted/base/classes4.dex` (scan invoke/field-ref seluruh dex itu) + `nm -D` atas `libgdx.so`. Semua descriptor di bawah adalah nama asli di dex, bukan nama JADX.

---

## 1. Verifikasi versi & hash — COCOK PERSIS

| Item | Di aplikasi mod (HP user) | Di dump | Status |
|---|---|---|---|
| Nama game | Diamond Quest: Don't Rush! | Diamond Quest: Don't Rush! | ✅ |
| Package | `diamond.quest.dont.rush` | `diamond.quest.dont.rush` | ✅ |
| versionName / versionCode | v3.60 (code 200271) | 3.60 / 200271 (`apktool.yml` di `extracted/manifest_dump/`) | ✅ |
| SHA-256 classes4.dex | awalan `842…`, potongan `…bc5038645b…` | `842e21bc5038645bb32042e35985c1177c60651caf322d99056d8b6f9cf07dfd` | ✅ **persis** — `842` + `e21` + `bc5038645b` muncul berurutan di awal hash dump |
| SHA-256 berkas .apks | — | `dcf56d9985246163d65a617b6a917ed67d0dc61aa8b70da199722a9b248f6859` | (dari REPORT.md, diaudit ulang sebagian cocok) |
| MD5 classes4.dex | — | `0858cabaf6efae90469439fda3fd0770` (8.439.724 byte) | — |

**Kesimpulan §1: dump yang ada ADALAH v3.60 code 200271 yang sama dengan yang terpasang di HP user.** Semua target di laporan ini sah untuk versi itu. Seluruh kelas gameplay target berada di **classes4.dex** — konsisten dengan fakta aplikasi mod me-hash tepat dex ini.

### Peta nama (JADX ↔ descriptor dex asli)

| Peran | Nama JADX (laporan lama) | Descriptor dex asli |
|---|---|---|
| World / panggung grid | `i1.C0358s0` (dari `i1.s0`) | `Li1/s0;` (super `Lj1/c;`) |
| Badan fisik pemain | `i1.C0293I` (dari `i1.I`) | `Li1/I;` (super `Li1/y;`) |
| Avatar pemain | `i1.C0301c0` (dari `i1.c0`) | `Li1/c0;` (super `Li1/e;`) |
| Objek dasar | `i1.C0304e` (dari `i1.e`) | `Li1/e;` |
| Objek berfisika | `i1.C0366y` (dari `i1.y`) | `Li1/y;` (super `Li1/G0;`) |
| SecureInt | `h1.C0284b` (dari `h1.b`) | `Lh1/b;` |
| Game + flag cheat global | `f1.C0278a` / `f1.a` | `Lf1/a;` (super `LQ1/b;`) |
| Pembungkus energi profil | `s1.C0402b` (dari `s1.b`) | `Ls1/b;` |

Field World yang dirujuk terus-menerus: `Li1/s0;->A Li1/c0;` (avatar), `Li1/s0;->x0 Li1/I;` (badan checkpoint), `Li1/s0;->y0 I` (alasan kematian tertunda), `Li1/s0;->r`/`s [[Li1/e;` (dua grid hunian), `Li1/s0;->t [[I`, `Li1/s0;->D Li1/s0$d;` (status stage), `Li1/s0;->T Ls1/b;` (energi), `Li1/s0;->U Ll1/e;` (profil), `Li1/s0;->c0 Lf1/a;` (game). Objek mana pun mencapai World lewat `Li1/e;->b Li1/s0;`.

---

## 2. KEBAL (god mode) — dua jalur kematian, dua titik tutup

Game tidak punya HP pool. Kematian = kejadian hazard → respawn checkpoint. Ada **dua jalur independen**; menutup satu saja BUKAN god mode penuh.

### 2.1 Jalur A — API kematian World (tile bahaya & jatuh)

**Target utama:**

```
Li1/s0;->k0(I)V        public — SATU-SATUNYA pintu kematian jalur tile/jatuh
```

`k0` hanya menulis field `Li1/s0;->y0 I` (alasan). Konsumennya adalah update frame World:

```
Li1/s0;->G2(F)V        — membaca y0, mengeksekusi respawn (pindah ke checkpoint
                         Li1/s0;->x0 Li1/I;, buang sprite, A.I0(reason) efek "pecah"),
                         lalu mereset y0. Juga pemanggil Li1/s0;->q(I I Z)V.
Li1/s0;->k0(I)V        — iput ke y0 terkonfirmasi di bytecode k0.
```

**Pemanggil `k0` di seluruh classes4.dex (scan invoke lengkap — hanya dua):**

```
Li1/I;->U0(F)V                       -> k0(1) dan k0(2)
Li1/I;->o(Ljava/lang/String; F F)V   -> k0(3)
```

**Pengumpan di `Li1/I;` (badan pemain):**

```
private Li1/I;->U0(F)V   — timer hazard per frame; dipanggil hanya dari Li1/I;->x0(F)V
public  Li1/I;->o(Ljava/lang/String; F F)V — callback jatuh/keluar area dari fisika dasar -> k0(3)
private field Li1/I;->s0 F — akumulator paparan hazard
```

Bukti bytecode `U0` (verbatim, diringkas):

```
iget-object v0, v6, Li1/e;->b Li1/s0;
const/16    v1, 223
invoke-virtual v0, v1, Li1/s0;->s1(I)Z        // tile di bawah pemain bermasker 223 (bahaya)
...
iget        v0, v6, Li1/I;->s0 F
add-float/2addr v0, v7                        // s0 += delta
iput        v0, v6, Li1/I;->s0 F
const/high16 v2, 1065353216                   // 1.0f
cmpl-float  v7, v7, v2
if-ltz      ...                               // paparan >= 1,0 detik
const/4     v0, 1
invoke-virtual v7, v0, Li1/s0;->k0(I)V        // k0(1)
...
const/16    v5, 32
invoke-virtual v0, v5, Li1/s0;->s1(I)Z        // masker 32 (checkpoint berbahaya)
const-string v5, "energyCheckpoint"
invoke-virtual v0, v5, Li1/s0;->P0(Ljava/lang/String;)Z   // energi checkpoint dibayar?
... (bila tidak) akumulasi sama -> Li1/s0;->k0(I)V dengan alasan 2
```

Jalur energi penyelamat (membaca SecureInt energi — **jangan disentuh**, lihat §5):

```
Li1/s0;->P0(Ljava/lang/String;)Z   public — cek+potong energi bernama ("energyCheckpoint", "energyLift", "energyInWater", ...)
Li1/s0;->p0(Ljava/lang/String;)Z   public
Li1/s0;->q0(Ljava/lang/String; I)Z public — implementasi potong via Li1/s0;->T Ls1/b; -> Ls1/b;->z(I)V
```

### 2.2 Jalur B — urutan kematian di avatar (tertindih batu, tenggelam, laser)

Jalur ini **tidak lewat `k0`** sama sekali:

```
private Li1/c0;->O0(Z Z)V   — urutan kematian avatar (animasi/sfx mati)
  pemanggil (scan lengkap classes4.dex): Li1/c0;->I0(I)V dan Li1/c0;->x0(F)V

public  Li1/c0;->Z0(Li1/y;)V — handler "tertimpa objek jatuh": set stun (field p0/i0 di c0),
  pemanggil TUNGGAL: Li1/y;->x0(F)V (langkah fisika mendeteksi objek jatuh mendarat di sel pemain)
public  Li1/c0;->x0(F)V      — update per frame avatar; di dalamnya timer angkat (vs field ambang
  dari properti "liftCounterThreshold") & timer tenggelam (vs "waterCounterThreshold")
  -> gagal bayar energi -> O0(...)
protected Li1/c0;->E(Li1/e; I)V — callback tabrakan antar-objek avatar; type 2 = laser
  (jalur energi "energyRedLaser"); diteruskan dari Li1/I;->E(Li1/e; I)V
protected Li1/I;->E(Li1/e; I)V  — callees terverifikasi: invoke-super Li1/e;->E + Li1/c0;->E
protected Li1/e;->E(Li1/e; I)V  — callback dasar semua objek
```

### 2.3 Rekomendasi titik hook kebal (untuk tim perbaikan)

1. `Li1/s0;->k0(I)V` → no-op menutup jalur A sepenuhnya (hanya 2 pemanggil, keduanya di `Li1/I;`).
2. `Li1/c0;->O0(Z Z)V` → no-op menutup seluruh jalur B di satu titik (hulu dari animasi mati; pemanggilnya hanya `I0(I)V` dan `x0(F)V` di kelas yang sama).
3. Alternatif yang lebih hulu untuk B: `Li1/c0;->Z0(Li1/y;)V` (batu) + timer di `x0(F)V` (air/angkat) — lebih banyak titik, tidak disarankan dibanding no. 2.
4. Menang/stage selesai **bukan** jalur kematian dan tidak boleh ikut tertutup: `private Li1/c0;->d1()V` (pintu keluar) → `Li1/s0;->J1()V` (pemanggil tunggal `d1`) → `Li1/s0;->q(I I Z)V` (komit hasil ke profil lokal; pemanggil lain: `G2(F)V`).

---

## 3. TEMBUS (no-clip) — predikat grid World + keputusan gerak avatar

Collision 100% lokal, berlapis grid, tanpa komponen jaringan (kelas World nol panggilan soket). Tidak ada target native untuk fitur ini.

### 3.1 Predikat tabrakan di World (`Li1/s0;`, semua public)

```
Z Li1/s0;->W0(I I I)Z   — (x, y, mask): objek di sel lolos uji flag F(mask);
                          dipakai avatar dengan mask 6144
Z Li1/s0;->d1(I I I)Z   — (x, y, flag): uji H(flag) pada objek sel (flag 1/8/64/2048/4194304)
Z Li1/s0;->f1(I I)Z     — kedalaman air (grid tinggi Li1/s0$d;->h) — rasio >= 0,74 penghalang
Z Li1/s0;->g1(I I)Z     — pendamping f1 (di dalam air >= 0,49)
Z Li1/s0;->h1(I I)Z     — grid Li1/s0$d;->j[x][y] == 1
Z Li1/s0;->s1(I)Z       — (mask & o0) != 0 — bitmask tipe tile di bawah objek
                          (dipakai I.U0 dengan 223/32, avatar dengan 8)
Li1/e;  Li1/s0;->E0(I I)Li1/e;  — ambil objek sel dari grid r
Li1/e;  Li1/s0;->x0(I I)Li1/e;  — ambil objek sel dari grid s
Li1/x;  Li1/s0;->z0(I I)Li1/x;  — ambil entri grid ketiga
```

Registrasi hunian: `private Li1/y;->H0(Z I I)V` menandai footprint objek ke grid World (menempati/melepas).

### 3.2 Lapisan keputusan gerak (avatar)

```
private Li1/c0;->m1(I I I I Z)V  — pembantu keputusan gerak avatar: memeriksa sel tujuan
                                   dengan predikat §3.1 sebelum melangkah
public  Li1/c0;->g1(F)V          — integrasi gerak avatar per frame; SATU-SATUNYA pembaca
                                   field kecepatan z0 (3x iget, lihat §4)
public  Li1/c0;->K0()Z           — cek dorong batu: tetangga kelas Li1/Q; -> Q.J0(arah);
                                   batu hanya bergeser bila lolos uji collision yang sama
public  Li1/c0;->x0(F)V          — update per frame avatar (memanggil E/O0/jalur gerak)
public  Li1/y;->x0(F)V           — langkah fisika objek jatuh/bergerak: menjepit posisi
                                   ke target sel & menghentikan kecepatan saat terhalang;
                                   di sinilah deteksi "objek jatuh menimpa pemain" -> A.Z0
private Li1/y;->I0(F)V           — langkah fisika kedua (JADX gagal men-decompile utuh
                                   method ini di analisis 21 Okt — rincian barisnya
                                   TIDAK ditemukan; yang terverifikasi hanya descriptor
                                   + field-ref-nya ke Li1/s0;->A)
```

### 3.3 Catatan gating

Predikat §3.1 **dipakai bersama** oleh pemain, musuh, dan fisika — mengubah return predikat secara global akan mengubah perilaku semua objek. Titik yang spesifik-pemain adalah lapisan §3.2 (`m1`/`g1`/`x0` di `Li1/c0;` dan `Li1/I;`), atau gating per-instance di pemanggil (bandingkan `this` dengan `Li1/s0;->A`). Pemilihan strategi adalah keputusan tim perbaikan; yang terverifikasi di sini adalah daftar titiknya.

Menonaktifkan collision **tidak menyentuh SecureInt**: flag cheat global `Lf1/a;->O` tidak punya jalur dari kode collision/gerak (penulis flag hanya dua — §5.2).

---

## 4. SPEED — field kecepatan avatar + integrasi delta-time

Kecepatan **data-driven per peta** (properti TMX), bukan konstanta global. Tidak ada validasi timing di klien maupun di skema pesan server (tidak ada field durasi di satu pun pesan CS; `playTime` hanya statistik lokal/telemetri).

### 4.1 Avatar (target utama)

```
private field Li1/c0;->z0 F    — kecepatan avatar, satuan px/detik
  DITULIS hanya di: Li1/c0;->J(Lcom/badlogic/gdx/maps/MapProperties;)V  (1x iput)
  DIBACA  hanya di: Li1/c0;->g1(F)V                                     (3x iget)
```

Bukti bytecode `Li1/c0;->J` (verbatim, diringkas):

```
const/high16 v0, 1084227584        // 5.0f  — default properti "velocity" (ubin/detik)
const-string v1, "velocity"
const/high16 v1, 1116733440        // 72.0f — pengali ubin->px
iput         v0, v3, Li1/c0;->z0 F // z0 = velocity * 72  (default 360 px/detik)
const/high16 v0, 1065353216        // 1.0f  — default "liftCounterThreshold"
const-string v1, "liftCounterThreshold"
const-string v1, "waterCounterThreshold"
```

`J` sendiri dipanggil secara polimorfik lewat rantai `Li1/e;->J(MapProperties;)V` saat objek dibuat oleh pemuat peta World (`Li1/s0;->H(...)V` dan `Li1/s0;->F1(...)Li1/e;` adalah situs dispatch eksternal yang terverifikasi; setiap override `J` di `Li1/*` memanggil invoke-super ke induknya — termasuk `c0.J` dan `y.J`).

Dua titik hook yang bersih:

1. **After-hook `Li1/c0;->J(...)V`** → kalikan `z0` dengan faktor. Satu-satunya penulis field; berlaku sejak avatar spawn/respawn.
2. **Hook `Li1/c0;->g1(F)V`** → skala argumen delta. Satu-satunya pembaca `z0`; tapi `g1` juga menampung logika gerak lain — rincian baris `g1` **tidak dibedah** dalam pass ini (yang terverifikasi: descriptor + statusnya sebagai pembaca tunggal `z0`).

### 4.2 Objek berfisika (musuh/batu/dll — bila ingin speed global objek)

```
Li1/y;->J(Lcom/badlogic/gdx/maps/MapProperties;)V
  const/high16 1086324736   // 6.0f  — default properti "gravity"  -> field Li1/y;->T F (x72)
  const        1060320051   // 0.7f  — rasio "gravitySide"         -> field Li1/y;->U F
private/public fields Li1/y;:
  W F — kecepatan berjalan objek (ditulis <init>, K0(I)V, x0(F)V, d0(Li1/e;)V;
        dibaca ekstensif di x0(F)V — integrator fisika)
  T F — gravity (px/detik^2 setelah x72), U F — gravitySide
public Li1/y;->K0(I)V — penentu arah/kecepatan awal (banyak menulis W)
```

Kelas objek lain membaca properti `velocity`/`speed` masing-masing di `J`-nya sendiri dengan pola identik (default per kelas berbeda-beda, 5,0–6,0) — daftar lengkapnya ada di ANALISIS-LANJUT.md §3.1; tidak ada satu konstanta global untuk diubah.

### 4.3 Yang TIDAK ada

- Tidak ada tick tetap / konstanta `MAX_SPEED` global di dex.
- Tidak ada pemeriksaan "waktu tempuh minimum per peta" di klien.
- `libgdx.so` tidak berisi logika kecepatan game (lihat §6.3).

---

## 5. Anti-cheat SecureInt & pelaporan root/sesi — konfirmasi untuk v3.60

Karena dump ini **adalah** v3.60, temuan 21 Okt berlaku langsung untuk v3.60; tidak ada dump versi lain untuk dibandingkan, jadi "perubahan antarversi" **tidak ditemukan** (tidak ada basis pembanding). Yang di bawah adalah keadaan v3.60 yang terverifikasi ulang di level dex:

### 5.1 SecureInt (`Lh1/b;`, classes4.dex)

Field: enam `int` privat `a b c d e f` (dua salinan nilai terenkripsi XOR + offset). Method: `a()I` (baca+verifikasi), `c(I)V` (tulis), `b(Lh1/b;)Z`, `d(Lh1/b;)V`, `<init>()V`, `<init>(I)V`.

Bukti bytecode `Lh1/b;->a()I` (verbatim penuh):

```
iget  v0, v3, Lh1/b;->b I
iget  v1, v3, Lh1/b;->a I
xor-int/2addr v0, v1
iget  v1, v3, Lh1/b;->c I
sub-int/2addr v0, v1            // nilai1 = (b ^ a) - c
iget  v1, v3, Lh1/b;->e I
iget  v2, v3, Lh1/b;->d I
xor-int/2addr v1, v2
iget  v2, v3, Lh1/b;->f I
sub-int/2addr v1, v2            // nilai2 = (e ^ d) - f
if-eq v0, v1, +005h
const/4 v1, 1
sput-boolean v1, Lf1/a;->O Z    // tidak cocok -> flag cheat global = true
return v0
```

Pemakai terkonfirmasi: profil `Ll1/e;` (gem `o`, diamond `p`, energy `w`, + 4 SecureInt lain dan peta item `IntMap Q`), dan pembungkus energi `Ls1/b;` (field `c d e p q r s : Lh1/b;`; delta energi lewat `Ls1/b;->z(I)V`).

### 5.2 Flag cheat global — KOREKSI atas laporan lama

`public static Lf1/a;->O Z`. Laporan 21 Okt menyebut flag ini "hanya diset di satu tempat di seluruh basis kode". **Scan `sput` di classes4.dex menemukan DUA penulis:**

```
Lh1/b;->a()I                                            [sput-boolean -> Lf1/a;->O]
Lcom/gdx/diamond/socket/handler/RemoteManager;->act(F)V [sput-boolean -> Lf1/a;->O]
```

`RemoteManager.act(F)V` adalah handler yang mengirim `CSCheat{type=0}` (TYPE_MEMORY) dan memicu dialog kunci lokal bila konfigurasi server mengizinkan — konsisten bahwa ia ikut menandai flag saat memproses. Koreksi ini tidak mengubah vonis risiko; ia meluruskan peta penulis flag.

### 5.3 Sesi & pelaporan (tidak berubah di v3.60)

- Transport: Socket.IO persisten ke `http://diamond.onebi.net:9096/` (HTTP polos), handler connect/disconnect/reconnect di `L1/a;`; manajer `Lcom/gdx/diamond/socket/handler/RemoteManager;` (classes4.dex).
- `CSInitSession` saat sesi tersambung membawa: `accessToken`, `advertId`, `cheat` (flag tersimpan persisten di pref `sync_pref`/`Ll1/g;`), **`rooted`**, `sha` (isi persisnya tidak terkonfirmasi), `platform`, `version=147`, `timeZone`, `locale`, `name`.
- Sumber nilai `rooted`: `DiamondQuestLauncher.f()Z` mengembalikan `CommonUtils.isRooted()` (util Firebase Crashlytics) — launcher mengimplementasikan `RemoteManager.q` (listener platform). Jadi status root perangkat **dilaporkan di setiap init sesi**, bersama flag `cheat` persisten.
- `CSCheat` type 0 = memori (jalur `act()` di atas); type 1 = MD5 pref lokal tidak cocok saat muat (`Lg2/e;->I` → `RemoteManager.cheat(...)`, `data` = nama kelas pref). Lock akun: `SCLock`/`lock_account`, flag `lock` persisten di `Ll1/g;`.
- Heartbeat khusus aplikasi: **tidak ditemukan**. Yang terkonfirmasi hanya ping/pong bawaan Socket.IO + pesan sinkron waktu energi (`CSSyncTime`/`SCSyncNextTime`, field `lastSyncEnergyTime`) — tidak ada pesan "masih hidup" berkala lain yang teridentifikasi di inventaris pesan `com/gdx/diamond/remote/message/*`.
- Tidak ada anti-cheat native: tidak ada lib PairIP/Promon/FairGuard/ACE di bundle; `libsigner.so` adalah Adjust SDK, `libpglarmor.so`/`libnms.so` adalah Pangle (iklan).

---

## 6. Catatan VM/JNI — relevan dengan `fail_no_vm`

### 6.1 Bagaimana game memuat native-nya

- `android:name` Application = `com.mygdx.game.AdjustApplication` (classes6.dex) — `onCreate` hanya `Adjust.initSdk(...)`.
- Launcher = `com.mygdx.game.DiamondQuestLauncher` (classes6.dex) extends `LU1/b;` (backend `com.badlogic.gdx.backends.android.AndroidApplication` yang ter-obfuscate). `onCreate` → inisialisasi backend dengan game baru `new Lf1/a;()` (method `o()` di launcher) → backend memanggil `GdxNativesLoader.load()`.
- `GdxNativesLoader` → `SharedLibraryLoader` memuat `"gdx"`: bukti di `com/badlogic/gdx/utils/SharedLibraryLoader.java:306` `System.loadLibrary(mapLibraryName)` (dan jalur ekstrak `System.load(...)` di :446). `libgdx-freetype.so` dan `liblibgdx-oboe.so` dimuat loader ekstensi libGDX masing-masing dalam jendela startup yang sama.
- Jadi urutannya: proses start → `Application.onCreate` → `Activity.onCreate` → `System.loadLibrary("gdx")` → loop render GL mulai. Semua kelas gameplay (`Li1/*`, classes4.dex) adalah **Java murni** — tidak ada method native di jalur kebal/tembus/speed.

### 6.2 Multi-process: TIDAK ADA

Manifest (apktool, `extracted/manifest_dump/AndroidManifest.xml`): **0 atribut `android:process`** di seluruh komponen (grep `process` = 0 hit). Application, launcher, SDK iklan, Firebase — semuanya berjalan di proses utama `diamond.quest.dont.rush`. Tidak ada proses kedua yang bisa menjadi sasaran suntik yang salah dari sisi game; bila payload mendarat di pid yang bukan proses utama ini, itu murni soal pemilihan pid di injector.

### 6.3 Isi native (untuk menutup pertanyaan "offset di lib")

`libgdx.so` (arm64-v8a, ELF64 AArch64, 163.888 byte): **116 simbol dinamis terdefinisi, semuanya ekspor JNI standar `Java_com_badlogic_gdx_*`** (mis. `Java_com_badlogic_gdx_graphics_g2d_Gdx2DPixmap_clear` @ `0x246d4`) — diverifikasi dengan `nm -D` pada pass ini. Tidak ada simbol/logika game di native. **Tidak ada target offset lib.so untuk kebal/tembus/speed — semuanya di dex.** Lib lain di bundle adalah SDK iklan/Adjust/Firebase (inventaris lengkap di REPORT.md §2).

### 6.4 Jalur paling wajar payload memperoleh JavaVM di proses ini

Fakta proses: proses aplikasi Android biasa (fork zygote) — ART dan `JavaVM` tunggalnya **sudah ada sejak proses lahir**, jauh sebelum kode game berjalan; `libart.so` pasti termuat. Konsekuensi untuk payload yang di-dlopen dari luar (injector root):

1. Payload yang masuk lewat dlopen eksternal **tidak** dipanggil `JNI_OnLoad`-nya oleh ART dan tidak diserahkan `JavaVM*` — itu hanya terjadi untuk lib yang dimuat lewat `System.loadLibrary`/`System.load` oleh kode aplikasi sendiri. Menunggu `JNI_OnLoad` = menunggu sesuatu yang tidak akan datang; gejala ini **konsisten** dengan status `fail_no_vm` (ini inferensi dari mekanisme Android, bukan dari membaca kode payload — kode payload di luar cakupan tugas ini).
2. Jalur standar yang tersisa dan paling wajar: **`JNI_GetCreatedJavaVMs`** — resolve simbolnya dari `libart.so` yang sudah termuat di proses yang sama (dlopen handle `libart.so` + `dlsym`, atau enumerasi `/proc/self/maps`), panggil untuk mendapat `JavaVM*`, lalu `GetEnv`/`AttachCurrentThread` untuk `JNIEnv*` di thread penyuntik; hook Java sebaiknya dipasang/dijalankan di thread GL (thread render libGDX) lewat antrean `Gdx.app.postRunnable` atau setara, karena objek World/avatar hidup di thread itu.
3. Timing aman: setelah `DiamondQuestLauncher.onCreate` selesai (native `gdx` termuat, `Lf1/a;.create()` berjalan) kelas-kelas classes4.dex sudah ter-load oleh PathClassLoader aplikasi; menyelesaikan `Li1/s0;`/`Li1/c0;` sebelum stage pertama dibuat tetap aman selama resolusi kelas ditunda sampai classloader aplikasi bisa dijangkau (mis. lewat `ActivityThread`/`LoadedApk`), bukan classloader sistem.

---

## 7. Yang tidak ditemukan / batas analisis

- **`Li1/c0;->g1(F)V` tidak dibedah baris-per-baris** pada pass ini. Terverifikasi: descriptor `g1(F)V`, statusnya sebagai satu-satunya pembaca `Li1/c0;->z0 F` (3 iget), dan posisinya di rantai gerak avatar. Isi internalnya (bagaimana delta & z0 diintegrasikan ke posisi) belum dibaca.
- **`Li1/y;->I0(F)V`** — JADX gagal men-decompile method ini (1.458 instruksi) di analisis 21 Okt dan pass ini tidak mengulang decompile-nya; yang terverifikasi hanya descriptor + referensi field-nya. Kesimpulan collision tidak bergantung pada isi `I0`.
- **Isi `sha` di `CSInitSession`** — tidak terkonfirmasi (sama seperti laporan awal).
- **Scan pemanggil/penulis di laporan ini berlingkup classes4.dex** (dex yang memuat seluruh logika gameplay + RemoteManager + SecureInt). Klaim "pemanggil tunggal" berarti tunggal di dalam dex itu, dan konsisten dengan temuan decompile penuh 21 Okt; pemanggil dari dex lain untuk method-method ini tidak ditemukan di laporan lama dan tidak di-scan ulang per-dex pada pass ini.
- **Logika validasi sisi server** (kewajaran skor/waktu/diamond) tidak ada di APK — di luar jangkauan analisis statis klien.
- Kode injector/payload mod **tidak dibaca** dalam tugas ini (READ-ONLY sisi game); §6.4 butir 1 ditandai sebagai inferensi mekanisme, bukan temuan atas kode payload.

---

## Lampiran — indeks target cepat (semua di classes4.dex)

| Fitur | Target | Descriptor | Peran |
|---|---|---|---|
| Kebal A | method | `Li1/s0;->k0(I)V` | pintu kematian tile/jatuh (tulis `y0`) |
| Kebal A | method | `Li1/s0;->G2(F)V` | konsumen `y0` / respawn + stage-end |
| Kebal A | method | `Li1/I;->U0(F)V` | timer hazard (pemanggil k0 alasan 1, 2) |
| Kebal A | method | `Li1/I;->o(Ljava/lang/String; F F)V` | callback jatuh (pemanggil k0 alasan 3) |
| Kebal B | method | `Li1/c0;->O0(Z Z)V` | urutan kematian avatar |
| Kebal B | method | `Li1/c0;->Z0(Li1/y;)V` | handler tertimpa batu |
| Kebal B | method | `Li1/c0;->x0(F)V` | timer tenggelam/angkat -> O0 |
| Kebal B | method | `Li1/c0;->E(Li1/e; I)V` | tabrakan antar-objek (laser) |
| Tembus | method | `Li1/s0;->W0(I I I)Z`, `d1(I I I)Z`, `f1(I I)Z`, `g1(I I)Z`, `h1(I I)Z`, `s1(I)Z` | predikat collision grid |
| Tembus | method | `Li1/s0;->E0(I I)Li1/e;`, `x0(I I)Li1/e;`, `z0(I I)Li1/x;` | pengambil objek sel |
| Tembus | method | `Li1/c0;->m1(I I I I Z)V`, `g1(F)V`, `K0()Z` | keputusan gerak avatar + dorong batu |
| Tembus | method | `Li1/y;->x0(F)V`, `H0(Z I I)V` | langkah fisika + registrasi grid |
| Speed | field | `Li1/c0;->z0 F` | kecepatan avatar px/detik (velocity×72) |
| Speed | method | `Li1/c0;->J(Lcom/badlogic/gdx/maps/MapProperties;)V` | penulis tunggal `z0` |
| Speed | method | `Li1/c0;->g1(F)V` | pembaca tunggal `z0` (integrasi gerak) |
| Speed | field | `Li1/y;->W F`, `T F`, `U F` | kecepatan/gravity objek fisika |
| Speed | method | `Li1/y;->J(Lcom/badlogic/gdx/maps/MapProperties;)V` | penulis gravity (6.0f×72, side 0.7f) |
| Konteks | method | `Li1/c0;->d1()V` -> `Li1/s0;->J1()V` -> `Li1/s0;->q(I I Z)V` | rantai menang/stage selesai (JANGAN ditutup) |
| Anti-cheat | class | `Lh1/b;` (`a()I` verifikasi) | SecureInt |
| Anti-cheat | field | `Lf1/a;->O Z` (static) | flag cheat global; penulis: `Lh1/b;->a()I`, `RemoteManager;->act(F)V` |
| Anti-cheat | method | `Ls1/b;->z(I)V` + field `Ls1/b;->c Lh1/b;` | delta energi (wilayah SecureInt — hindari) |
