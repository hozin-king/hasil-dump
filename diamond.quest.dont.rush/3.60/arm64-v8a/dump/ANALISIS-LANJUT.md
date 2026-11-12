# Analisis Lanjutan Terarah — Diamond Quest: Don't Rush! (v3.60)

Tanggal: 21 Oktober 2026
Basis: dump yang sama dengan REPORT.md (`~/workspace/rea-defender/extracted/`, decompile JADX per-dex; inti game + protokol di `jadx_dex4/sources`). **Analisis bukti saja — tidak ada cheat yang dibangun.**
Fokus: 4 pertanyaan terbuka dari laporan awal — (1) god mode/damage, (2) laporan hasil stage `set_score`, (3) speed, (4) tembus/collision.

Ringkasan vonis:

| # | Pertanyaan | Vonis | Menyentuh SecureInt? |
|---|---|---|---|
| 1 | God mode / damage | **LOKAL-BISA** (alur di dalam stage 100% lokal; efek persisten tetap ditimpa server) | Hanya bila lewat ubah nilai energi/uang — jalur logika hazard tidak |
| 2 | Laporan hasil stage | **SERVER-TERVALIDASI** untuk hasil akhir (server menimpa balik), jalur klien tanpa tanda tangan | Ya — memalsukan angka profil = wilayah yang dijaga SecureInt + MD5 pref |
| 3 | Speed | **LOKAL-BISA** (data-driven per peta, delta-time, tanpa validasi timing) | Tidak |
| 4 | Tembus (collision) | **LOKAL-BISA** (collision murni lokal berlapis grid; World nol pesan soket) | Tidak |

---

## 1. GOD MODE / DAMAGE — alur damage & kematian pemain

### 1.1 Tidak ada "nyawa" — pemain mati per kejadian bahaya, lalu respawn di checkpoint

Game ini tidak memakai pool HP untuk pemain. Kematian dipicu kejadian (hazard) dan berujung respawn di checkpoint, dengan **energi sebagai "nyawa" berbayar** (revive/bertahan memakai pengeluaran energi). Kelas-kelas kuncinya:

- **World (panggung/grid): `i1.C0358s0`** (dari `i1.s0`, 3.043 baris) — simulasi grid: dua grid objek `r[][]`/`s[][]`, grid tinggi air `D.h[][]`, status stage di inner class `C0358s0.d` (penghitung `v` = diamond terkumpul, `d`, `b`, `l` = tool aktif).
- **Badan fisik karakter: `i1.C0293I`** (dari `i1.I`, extends `i1.C0366y`) — satu-satunya pemanggil API kematian World.
- **Avatar pemain: `i1.C0301c0`** (dari `i1.c0`, extends `i1.C0304e`) — animasi, status stun/tenggelam, urutan kematian `O0(...)`.
- **Objek dasar: `i1.C0304e`**; objek berfisika jatuh/bergerak: `i1.C0366y` (dari `i1.y`, extends `i1.G0`).

### 1.2 Siapa membunuh pemain — terpusat di `C0293I` + timer hazard di avatar

API kematian World adalah `C0358s0.k0(int reason)` yang hanya mengisi field `y0`; loop update World (`C0358s0` act, ±baris 1454) mengeksekusi respawn: pemain dipindah ke koordinat checkpoint (`x0` = state checkpoint `C0293I`), sprite lama dibuang, lalu `A.I0(reason)` memainkan urutan "pecah" (`effect/break`). **Hanya ada satu kelas pemanggil `k0`** di seluruh kode ter-decompile: `i1.C0293I`, dengan tiga alasan:

- `C0293I.U0(delta)`: berdiri di tile bertipe bitmask **223** (tile bahaya, mis. api) — akumulasi paparan `s0 += delta`; mencapai **1,0 detik → `k0(1)`**.
- Tile bitmask **32** (area checkpoint berbahaya): bila energi checkpoint tidak dibayar (`world.P0("energyCheckpoint")` gagal) → tahan; 1,0 detik → `k0(2)`.
- `C0293I.o(...)` (callback jatuh/keluar area dari fisika dasar) → **`k0(3)`** (jatuh ke jurang).

Jalur bahaya lain berjalan lewat timer di avatar `C0301c0.x0(float)`:

- **Tertimpa batu jatuh**: langkah fisika `C0366y.x0` mendeteksi objek jatuh (arah 0/1/2, flag `H(4096)`) mendarat tepat di atas sel pemain (`world.j1(x, y-1)` benar, tanpa penahan flag 8) → memanggil `world.A.Z0(obj)`. `C0301c0.Z0(C0366y)` menyetel status stun (`p0/i0`) dan mencatat log `hit_damage` (stub telemetri `E1`, no-op di kelas World). Timer stun `n0` dibandingkan `liftCounterThreshold` (properti TMX, default 1,0): bila `world.p0("energyLift")` (pengeluaran energi) berhasil → selamat; gagal → `O0(...)` = urutan kematian.
- **Tenggelam**: `world.f1(x,y)` (air dalam) → timer `o0` vs `waterCounterThreshold`; `p0("energyInWater")` gagal → mati tenggelam (`sfx_water_character_die` → `O0(true,true)`).
- **Laser**: tabrakan diteruskan `C0293I.E(obj, i)` → `C0301c0.E(obj, i)`: `i == 2` → efek `energyRedLaser`.

`p0(String)` di World = `C0358s0.q0(key, cost)`: memeriksa & memotong **energi** lewat `T.c.a()` / `T.z(-i)` (`T` = `s1.C0402b`, pembungkus energi profil) — **pembacaan energi ini membaca SecureInt** (lihat §5), tetapi sekadar membaca tidak memicu apa pun; yang berbahaya adalah mengubah nilainya.

### 1.3 Siapa memberi damage ke musuh/bos

Musuh adalah objek `G0/C0366y` lain di grid yang sama; mereka mati oleh simulasi yang sama: tertimpa objek jatuh (langkah fisika `C0366y.I0(float)`/`x0` + callback tabrakan antar-objek `C0304e.E(obj, type)`), dan oleh senjata pemain (status palu tersimpan di `G0`: JSON `sa.mCheckConsumeHammer`/`sa.mWeaponType`; `G0.x0` menembakkan `C0(weaponType)` saat flag konsumsi palu terpicu, dengan biaya energi lewat `q0`). Ambang bos datang dari **define data server**: `g1.C0280a` mem-parse `boss1_hard "24,20,16,12,8,4"`, `boss1_normal "18,14,8,3,0,0"`, `boss1_easy "12,8,3,0,0,0"` (kemungkinan ambang bintang/hit per tingkat kesulitan — makna persis tiap angka tidak terkonfirmasi dari klien). Catatan metode: `C0366y.I0(float)` (1.458 instruksi) gagal di-decompile JADX — kesimpulan arsitekturnya tegak dari pemanggil/penerima di sekitarnya, tetapi rincian baris di dalam `I0` tidak terbaca.

### 1.4 Akhir stage (menang) — murni lokal, dilaporkan belakangan

Menang: pemain memasuki pintu keluar → posisi keluar grid → `C0301c0.d1()` memanggil `world.J1()` → `C0358s0.q(i, i3, z)`:

```java
C0386a v = this.U.v(this.Z);              // profil bab (l1.a) untuk bab Z
v.t(this.V, v.p(this.V) + this.D.v);      // collectedDiamonds[mapId] += diamond run ini
this.U.m(this.Z, this.D.v);               // total profil (l1.e)
if (this.W == 0) this.U.o0(this.D.l);     // catat tool/weapon
```

Semua hanya mutasi objek profil lokal (`l1.e` + `l1.C0386a`). **Di dalam kelas World tidak ada satu pun pengiriman soket** (0 panggilan `L1.a.l().p(...)` di `C0358s0`); satu-satunya lalu lintas keluar selama bermain adalah telemetri `game.m.c("play_start", ...)` (→ `CSLog`/`log_event`: level, `energyStart`, `playCount`, `playTime`, `completeCount`) — analitik, bukan validasi. Tidak ada pesan per-hit, per-kematian, atau per-diamond ke server selama stage berjalan.

**Vonis 1: LOKAL-BISA** — alur damage/kematian/menang di dalam stage sepenuhnya lokal di klien (bukti: `C0293I` satu-satunya pemanggil `C0358s0.k0`; `C0358s0.q` hanya menulis profil lokal; nol soket di kelas World). Efek persistennya (progres) tetap di bawah otoritas server lewat jalur §2.

---

## 2. LAPORAN HASIL STAGE — isi `set_score` sebenarnya

### 2.1 `set_score` BUKAN laporan klien — itu koreksi server → klien

Tidak ada kelas `CSSetScore` di seluruh paket pesan. Yang ada hanya:

```java
// com/gdx/diamond/remote/message/game/SCSetScore.java
@Event(name = Events.SET_SCORE)   // "set_score"
public class SCSetScore extends SCBase {
    public int chapterId;
    public int[] chestStates;     // kelipatan 5: 4 kunci + 1 state per peti
    public int mapId;
    public int score;             // = collectedDiamonds untuk peta itu
}
```

`RemoteManager.onSetScore(SCSetScore)` (±baris 1176) **menuliskan nilai dari server ke profil lokal**: `eVar.v(chapterId).t(mapId, score)` (menimpa `collectedDiamonds[mapId]` di `l1.C0386a`) dan `eVar.T(...)` per grup 5 angka `chestStates` (menimpa status peti di `l1.e`). Jadi "score" di protokol ini ≡ **jumlah diamond terkumpul per peta**, dan arah otoritatifnya server → klien.

Field lain yang ditanyakan (hits/retries/waktu/bintang) **tidak ada** di `set_score`. Yang mendekati hanya statistik lokal per level `l1.f` (pref `stat_<chapter>_<mapId>_<version>`): `playCount`, `playTime` (float detik), `completeCount`, `energyConsume` — dipakai tampilan lokal & telemetri `play_start`, bukan field `set_score`. Ambang bintang bos ada di define data (§1.3), bukan dikirim per hasil.

### 2.2 Jalur sebenarnya hasil stage: `request_sync` — profil utuh, tanpa tanda tangan

Hasil stage masuk ke profil lokal (§1.4), lalu diunggah grosir oleh `RemoteManager.requestSync(int type)` (±baris 1385):

```java
CSRequestSync cs = new CSRequestSync();
cs.type = type;                                   // 0=TYPE_COMPLETE, 1=TYPE_CHANGE
cs.data = this.game.c.G(l1.e.R, l1.e.class);      // JSON profil utuh, terenkripsi
cs.syncSequence = ++this.syncSequence;            // urutan monoton
L1.a.l().p(cs);
```

- `CSRequestSync` hanya punya 3 field: `type`, `data`, `syncSequence`. **Tidak ada field checksum/tanda tangan/HMAC per pesan** (pencarian `MessageDigest`/Mac di paket remote/socket: nihil, kecuali MD5 pref lokal di bawah).
- `data` = `g2.e.G(...)` = `C(json)` — JSON profil dienkripsi **PBEWithMD5AndDES + Base64** (`a2.a`: salt tetap `{-57,115,33,-116,126,-56,-18,-103}`, iterasi 20, kata sandi dari `getHash()` internal klien). Ini obfuskasi transport yang kuncinya tertanam di klien — bukan tanda tangan dan bukan bukti integritas terhadap server.
- `syncSequence` berangkat dari nilai yang diberikan server di `SCSessionInfo.syncSequence` lalu naik +1 per sync — mekanisme **urutan/anti-replay dasar**, bukan validasi isi.
- Server dapat **menimpa seluruh profil lokal**: `g2.e.K(key, class, encrypted)` mengganti objek profil dari data server (dipakai jalur `SCRequestSync`/`SCUpdateData`), di luar koreksi per-peta `SCSetScore`.

Satu-satunya checksum di jalur ini bersifat **lokal**: `g2.e.D()` menyimpan pref sebagai `data` (terenkripsi) + `checksum` = **MD5(JSON polos)** (`g2.e.F`); saat muat (`g2.e.I`), MD5 dihitung ulang — tidak cocok → callback integritas `g2.c.a(key, class)` → jalur laporan cheat **type 1** (`RemoteManager.cheat(str, cls)` → `CSCheat{type=1, data=...}`). Ini mengawasi edit save offline, bukan mengesahkan skor ke server.

**Vonis 2: SERVER-TERVALIDASI untuk hasil akhir** — server menerima profil unggahan (tanpa tanda tangan yang bisa "menolak" rekayasa secara kriptografis), lalu mengirim balik nilai otoritatifnya (`SCSetScore`) dan dapat menimpa seluruh profil (`g2.e.K`, `SCUpdateData`, `SCDefineData`). Apakah server memeriksa kewajaran angka (mis. diamond > isi peta) adalah logika sisi server yang tidak ada di APK — **bagian itu tidak terkonfirmasi**; yang terbukti dari klien: tidak ada checksum/tanda
...[truncated 11838 chars] tangan atas isi, dan koreksinya berbentuk timpa-balik, bukan penolakan bertanda tangan.

**Risiko lock dari §2:** memalsukan hasil = mengutak-atik angka profil yang sama persis dengan wilayah jaga anti-cheat: lewat edit save → MD5 pref gagal → `CSCheat` type 1; lewat memori → ketidakcocokan SecureInt → type 0. Keduanya menandai akun secara persisten (lihat §5).

---

## 3. SPEED — di mana kecepatan ditentukan, ada validasi timing?

### 3.1 Kecepatan = properti per-objek dari file peta (TMX), bukan konstanta global

Setiap kelas objek membaca properti **`velocity`** dari `MapProperties` objek TMX-nya saat `J(MapProperties)`, dikali 72 (px per ubin):

- **Pemain** — `i1.C0301c0.J(...)`: `this.z0 = mapProperties.get("velocity", 5.0f) * 72.0f` → default **5,0 ubin/detik (360 px/detik)**.
- Objek/musuh lain pola sama: `i1.C0290F` (default 5,0), `i1.C0298b` (6,0), `i1.C0302d` (6,0), `i1.C0307f0`, `i1.C0359t`, `i1.C0360t0`, `i1.C0363v` (masing-masing defaultnya sendiri), `i1.F0` membaca properti `"speed"`.
- **Gravitasi** objek jatuh — `i1.C0366y.J(...)`: `"gravity"` default 6,0 × 72, `"gravitySide"` default 0,7 × gravity. Kecepatan jatuh terakumulasi/integrasi di `C0366y.x0(float)` menuju target sel (kecepatan `W`, posisi target `X/Y`), termasuk guliran batu (rotasi 360°/detik setelah 0,2 ubin).

Gerak diintegrasikan dari **delta time frame** (`x0(float f)` di `C0304e`/`C0366y`/`C0301c0`, loop `act` World) — tidak ada tick tetap dan tidak ada konstanta kecepatan pemain/musuh yang tertanam di kode; semua data-driven dari properti peta (yang TMX-nya terenkripsi di aset, lihat REPORT.md §5).

### 3.2 Validasi timing: tidak ditemukan

- Tidak ada field durasi/waktu stage di satu pun pesan CS (inventarisasi kelas pesan di `com/gdx/diamond/remote/message/*` pada §2.1/REPORT.md): tidak ada `time`, `duration`, atau cap waktu hasil.
- `playTime` hanya hidup di statistik lokal `l1.f` dan dikirim sebagai **telemetri** `play_start` via `CSLog` — tidak ada handler klien untuk penolakan berbasis waktu.
- Satu-satunya waktu dari server adalah regen energi (`CSSyncTime`/`SCSyncNextTime`, `lastSyncEnergyTime`) — tidak berhubungan dengan kecepatan bermain.
- Tidak ada pemeriksaan kewajaran waktu tempuh stage di klien (tidak ada konstanta "waktu minimum per peta" di kode ter-decompile).

**Vonis 3: LOKAL-BISA** — kecepatan pemain/musuh ditentukan lokal dari properti `velocity`/`gravity` per peta + integrasi delta-time (bukti: `C0301c0.J`, `C0366y.J`, `C0366y.x0`), dan **tidak terdeteksi validasi timing** di klien maupun di skema pesan ke server. Mengubah skala waktu/kecepatan tidak menyentuh SecureInt (tidak ada pembacaan nilai terjaga di jalur gerak). Risiko sisa sama seperti §1/§4: hasil stage yang lebih cepat tetap diunggah sebagai progres dan dapat ditimpa server; kewajaran sisi server tidak terkonfirmasi.

---

## 4. TEMBUS — collision pemain dengan dinding/batu/musuh/jebakan

### 4.1 Collision 100% lokal, berlapis grid — tidak ada komponen jaringan

Seluruh keputusan tabrakan diambil di klien oleh tumpukan berikut (semua di kelas World `i1.C0358s0` + objek `i1.*`):

1. **Registrasi hunian grid** — `i1.C0366y.H0(boolean, x, y)` menandai footprint objek ke grid World (`world.s2(...)` saat menempati, `world.V1(...)` saat melepas). Pengambilan objek per sel: `C0358s0.E0(x, y)` (grid `r[][]`) dan `C0358s0.x0(x, y)` (grid `s[][]`).
2. **Predikat tabrakan World** (dipanggil kode gerak pemain/musuh):
   - `W0(x, y, mask)` → objek di sel itu lolos uji bendera `F(mask)` (dipakai pemain dengan mask 6144 di `C0301c0.S0`);
   - `d1(x, y, flag)` → uji `H(flag)` pada objek sel (flag 1/8/64/2048/4194304 di berbagai jalur);
   - `f1(x, y)` / `g1(x, y)` → kedalaman air dari grid tinggi `D.h` (rasio ≥ 0,74 = dalam/penghalang, ≥ 0,49 = di dalam air);
   - `h1(x, y)` → grid `D.j[x][y] == 1`;
   - `s1(mask)` → `(mask & o0) != 0`, bitmask tipe tile di bawah pemain (dipakai `C0293I.U0` dengan 223/32 dan avatar dengan 8).
3. **Keputusan gerak pemain** — `i1.C0301c0.x0(float)` + pembantu `m1(...)`/`S0(...)`: memeriksa sel tujuan dengan predikat di atas, termasuk **mendorong batu**: `C0301c0.K0()` memeriksa tetangga kiri/kanan adalah objek kelas `Q` (batu) dan memanggil `Q.J0(arah)` — batu hanya bergeser bila lolos uji yang sama.
4. **Langkah fisika objek** — `i1.C0366y.I0(float)` (gagal decompile utuh; fragmen JADX menunjukkan uji `world.d1(d, y, 4194304)`) dan integrasi `C0366y.x0` yang menjepit posisi ke target sel dan menghentikan kecepatan (`W = 0`) saat target tercapai/terhalang.
5. **Tabrakan antar-objek** — callback `i1.C0304e.E(C0304e other, int type)` di kelas dasar semua objek; badan pemain `C0293I.E` meneruskan ke avatar `C0301c0.E` (type 2 = laser). Batu jatuh menimpa pemain bukan lewat `E`, melainkan deteksi posisi di `C0366y.x0` → `world.j1(x, y-1)` (apakah sel itu pemain) → `A.Z0(obj)` (§1.2). Musuh membunuh pemain lewat jalur tile/hazard yang sama (§1.2), bukan lewat pemeriksaan server.

### 4.2 Apakah menonaktifkan collision menyentuh SecureInt / server?

- **Tidak menyentuh SecureInt.** SecureInt (`h1.C0284b`) hanya dipakai nilai profil (gem/diamond/energy/item di `l1.e`). Bukti terkuat: flag cheat global `f1.C0278a.O` **hanya diset di satu tempat di seluruh basis kode** — `h1/C0284b.java:23`, di dalam verifikasi baca SecureInt. Tidak ada jalur dari kode collision/gerak ke flag itu.
- **Tidak ada laporan ke server dari collision.** Kelas World tidak mengirim pesan soket apa pun (§1.4); hasil tembus baru "terlihat" sistem lain hanya lewat konsekuensi normalnya (diamond terambil lewat `C0358s0.Z(int)` → `D.v` → `q()` → profil → sync §2; gerbang mata `invalid_eye` hanya log telemetri `c0.m.c(...)`).
- Satu-satunya persinggungan tidak langsung: bertahan dari hazard memakai `p0("energyLift"/"energyInWater"/"energyCheckpoint")` yang **membaca** SecureInt energi lewat `q0` — pembacaan sah tidak memicu flag; tembus yang melewatkan hazard justru menghindari jalur itu.

**Vonis 4: LOKAL-BISA** — collision dinding/batu/musuh/jebakan ditangani murni lokal oleh grid + predikat `W0/d1/f1/g1/h1/s1` dan callback `E` (bukti kelas/fungsi di §4.1); menonaktifkannya tidak menyentuh SecureInt dan tidak memicu laporan server apa pun. Risiko lock dari jalur ini: **tidak ada dari mekanik flag**; risiko yang tersisa hanya koreksi progres oleh server (§2) bila hasil tembus tercatat sebagai progres tidak wajar — penilaian kewajaran sisi server tidak terkonfirmasi.

---

## 5. Risiko lock akun — rangkuman mekanik flag persisten (dari REPORT.md §4, diverifikasi ulang)

1. **Pemicu type 0 (memori):** ketidakcocokan dua salinan SecureInt saat dibaca (`h1.C0284b.a()`) → `f1.C0278a.O = true` → `RemoteManager.act()` (±baris 488): `syncPreference.k(true)` (flag `cheat` **disimpan persisten** di `sync_pref`/`l1.g`), kirim `CSCheat{type=0}`, dan bila konfigurasi server `g1.h.v` mengizinkan → lock lokal paksa *"Your game is locked! Contact us for more information!"* + peringatan *"Any action try to hack will be recorded and punished!"*.
2. **Pemicu type 1 (save/pref):** MD5 pref tidak cocok saat muat (`g2.e.I`) → `RemoteManager.cheat(str, cls)` → `CSCheat{type=1, data=<nama kelas pref>}`.
3. **Persistensi lintas sesi:** flag yang tersimpan dilaporkan lagi di setiap `CSInitSession` (field `cheat`, bersama `rooted` dan `sha`), dan server dapat mengunci kapan pun lewat `SCLock`/`lock_account` (flag `lock` juga persisten di `l1.g`).
4. **Peta sentuhan per pertanyaan:**

| Jalur | Menyentuh SecureInt? | Jalur ke flag/lock |
|---|---|---|
| God mode via logika hazard (§1) | Tidak (hanya menghindari `k0`/timer) | Tidak ada |
| God mode via energi/uang tak terbatas | **Ya** — mengubah nilai yang dibaca `C0284b` | type 0 → dilaporkan + lock |
| Memalsukan hasil stage (§2) | **Ya** — wilayah profil yang sama | type 0/1 → dilaporkan + lock |
| Speed (§3) | Tidak | Tidak ada |
| Tembus (§4) | Tidak | Tidak ada |

---

## Yang tetap tidak terkonfirmasi

- Logika validasi sisi server (kewajaran skor/diamond/waktu) — tidak ada di APK; klien hanya membuktikan server berhak menimpa.
- Isi baris `i1.C0366y.I0(float)` dan `i1.C0366y.K0(int)` — JADX gagal men-decompile keduanya (348 & 1.458 instruksi); kesimpulan §1/§4 bertumpu pada pemanggil, penerima, dan kelas di sekelilingnya.
- Makna persis angka ambang bos `g1.C0280a` dan field `sha` di `CSInitSession` (sama seperti laporan awal).
- Apakah dialog jaringan dapat menjeda stage saat soket putus di tengah bermain — kelas World sendiri tidak memeriksa status soket sama sekali.
