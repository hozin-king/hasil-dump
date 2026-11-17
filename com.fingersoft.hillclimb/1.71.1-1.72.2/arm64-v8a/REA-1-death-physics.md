# REA "Fisika Kematian" Hill Climb Racing 1 v1.72.2

**Target:** `com.fingersoft.hillclimb` v1.72.2 — `libgame.so` arm64 stripped, 8.883.448 byte
(`~/workspace/hcrx-1.72.2/arm64/lib/arm64-v8a/libgame.so`).
**Tanggal:** 17 Nov 2026. **Status:** statis saja, tanpa menjalankan game, tanpa mengubah binary.

Dokumen pendahulu: `~/workspace/hozin-hcr-mod/docs/fuel_analysis.md` (predikat, timer,
game-over, fuel — untuk 1.71.1, diverifikasi ulang di 1.72.2) dan
`~/workspace/hozin-hcr-mod/flip-probe/PROBE.md` (getter sudut slot `0x70`, rantai pointer
`thiz+0x3a8 → vehicle → +0x258 → body`).

---

## 0. Ringkasan eksekutif

1. **Predikat kematian `0x3b2f94` BUKAN penghitung kontak — ia hanya PEMBACA FLAG.**
   Implementasi di balik vtable slot `0xa0` adalah satu fungsi bersama semua mobil,
   `0x4f78c8`: `ldrb w0, [x0, #0x32f]; ret`. Jadi "fisika kematian" sebenarnya adalah:
   **siapa yang menulis `[PlayerCar+0x32f] = 1`, dan atas dasar apa.**
2. **TIDAK ADA satu "cek kepala vs tanah" tunggal.** Ada **15 situs yang men-SET flag**
   (dan 1 situs yang me-RESET-nya), tersebar di 5 keluarga pemicu: kontak fisika,
   perbandingan posisi/ketinggian, timer/accumulator, kill-zone stage, dan
   detachment (bagian mobil lepas). Yang paling dekat dengan "kepala kena tanah":
   `0x3b0ddc` (kontak kategori `0x10000`), `0x3ad494` (titik vs transform body),
   `0x4eff98` (query spasial di posisi "kepala", tipe 7).
3. **TIDAK ADA struktur tulang/ragdoll bernama Driver/Head/Ragdoll di binary.**
   RTTI tidak mengenal class bernama itu. Driver dimodelkan sebagai **2–3 body fisika
   terpisah** di dalam `PlayerCar` (`+0x2d0` = kandidat kepala, `+0x2d8` = badan utama,
   `+0x2e0`/`+0x2e8` = bagian lain/roda). Tidak ada "bone/rig" — kematian diputuskan
   dari **posisi/kontak body**, bukan dari sendi tulang.
4. **KOREKSI audit lama: Box2D ADA di binary.** Audit sebelumnya ("tidak ada bukti
   Box2D") salah karena pencarian stringnya terlalu sempit. RTTI membuktikan class
   Box2D terkompilasi (`b2ChainShape`, `b2CircleShape`, `b2PolygonShape`, semua joint,
   `b2ContactListener`, `b2ParticleSystem`). Tidak ada vtable `b2Body`/`b2World`/
   `b2Fixture`/`b2Contact` — konsisten dengan Box2D (class-class itu tidak punya
   fungsi virtual).
5. **Aliran kematian:** sumber (15 situs) → flag `[PlayerCar+0x32f]` → predikat
   `0x3b2f94` → **timer `[run+0x62c]` 4,0 detik** → game over `0x3b7c70`
   (dipanggil di `0x3c77e0`). Ada jalur paralel: flag `[vehicle+0x266]` (setter
   `0x3b1758`, dipanggil di `0x3c7784`) yang dipakai cabang lain untuk memicu
   game-over/UI.
6. **Kandidat patch BARU di sumber (bukan di return predikat):** NOP-kan `strb` di
   `0x3b0ddc`, `0x3ad494`, dan/atau `0x4eff98` — ketiganya adalah cek "kepala".
   Keuntungan vs god mode v3: flag tidak pernah ter-set, sehingga **semua** pembaca
   flag (32 situs `ldrb`, bukan hanya predikat) melihat "hidup" — tidak ada animasi/
   efek samping "driver mati tapi game jalan".

---

## 1. Metode & batasan alat

- Tanpa Ghidra/Hopper/IDA di VM. Yang dipakai: Capstone 5.0.7 (`hcrdis.py`),
  `objdump`/`readelf`/`strings`, dan scan encoding instruksi mentah atas `.text`
  (`0x2f59b0–0x801398`).
- Rekonstruksi vtable: parse `.rela.dyn` (52.117 entri `R_AARCH64_RELATIVE`) +
  scan `.data.rel.ro` (vaddr `0x809050`, size `0x6cfa8`) cari run ≥8 pointer ke
  `.text` → **675 kandidat vtable, 662 bernama via RTTI** (typeinfo di vtable−8).
  File kerja: `vtables.py` → `vtables.json`.
- Semua alamat di laporan ini adalah **offset file = alamat virtual** (binary
  non-PIE di alamat ini; verifikasi silang dengan PROBE.md cocok).
- **Batasan:** nama class/fungsi dari RTTI saja; nama field/offset adalah
  rekonstruksi dari pola akses (bukan simbol). Arti semantik (mis. "kategori
  0x10000 = kepala") adalah inferensi dari konteks kode — ditandai sebagai
  **inferensi** bila belum bisa dibuktikan statis. Nilai konstanta float dibaca
  dari `.rodata` via pemetaan segmen `readelf -lW`.

---

## 2. Anatomi predikat kematian

### 2.1 Trampolin `0x3b2f94`

```
0x3b2f94: ldr x0, [x0, #0x258]     ; x0 = vehicle + 0x258 = PlayerCar*
0x3b2f98: ldr x8, [x0]             ; x8 = vtable PlayerCar
0x3b2f9c: ldr x1, [x8, #0xa0]      ; slot 0xa0 (idx 20)
0x3b2fa0: br  x1                   ; tail-call
```

Byte: `00 2c 41 f9 …`. 12 caller `bl`, 0 `b` (identik dengan PROBE.md).

### 2.2 Implementasi: `0x4f78c8` — satu fungsi untuk SEMUA mobil

```
0x4f78c8: ldrb w0, [x0, #0x32f]    ; byte 00 bc 4c 39
0x4f78cc: ret
```

Semua class `PlayerCar*` (Jeep, Bike, dst; 98 slot vtable) berbagi slot `0xa0` =
`0x4f78c8`. **Predikat = `return car->dead_flag`**. Tidak ada fisika di sini.

### 2.3 Statistik akses flag `[PlayerCar+0x32f]`

| Jenis | Jumlah | Keterangan |
|---|---|---|
| `strb` (penulis) | 16 | 15× set `=1`, 1× clear `=0` (`0x3d17bc`) |
| `ldrb` (pembaca) | 32 | termasuk predikat `0x4f78c8`, contact handler `0x4f4b68`, dan 30 situs lain |

Implikasi penting: god mode v3 (patch return predikat) hanya membutakan **satu**
dari 32 pembaca. Patch di sumber (flag tidak pernah ter-set) membutakan semuanya.

---

## 3. Struktur data kunci (rekonstruksi)

### 3.1 `PlayerCar` (this = `x19` di kebanyakan fungsi)

| Offset | Isi (inferensi) | Bukti |
|---|---|---|
| `+0x258` | — (di `vehicle`, bukan car) | `vehicle+0x258` = `PlayerCar*` |
| `+0x2a0` | pointer world/factory (arg ctor `x3`) | ctor `0x4ed6d8`: `str x25,[x19,#0x2a0]`; Jeep ctor `0x4f923c` |
| `+0x2a8` | pointer objek dunia (arg ctor `x2`) | ctor: `str x28,[x19,#0x2a8]`; dibaca contact handler `0x4f4b68` (`ldrb w8,[x8]`) |
| `+0x2b0` | objek UI/teks | dipakai `0x3c4424` (tampil teks) |
| `+0x2b8` | body factory (`[x24+0x10]`) | Jeep ctor `0x4f9350`; dipakai `bl 0x6d1ea4` (create body) |
| `+0x2d0` | **body #2 — kandidat KEPALA** | getter arg=1 kembalikan posisinya (via vtable+`0x3b8`); diregistrasi ke world (`0x4f9fb8`, flag 1) |
| `+0x2d8` | **body utama (chassis)** | dibuat `bl 0x6d1ea4` (`0x4f9868`); `+0xc` = posisi (x,y); `+0x50` = kecepatan (2 float); `+0xa0` = massa |
| `+0x2e0` | body #3 | dibandingkan di contact handler; ditulis di ctor per-mobil (`0x504f98`, `0x50bb28`, …) |
| `+0x2e8` | body #4 | idem (`0x504fc8`, `0x50bb58`, …) |
| `+0x298` | pointer objek (dipakai query `0x4eff58`: `[obj+0x560]`) | — |
| `+0x300` | objek "kepala/driver" lain | dipakai cek detachment `0x50e570` (vtable+0 / +8) |
| `+0x31c` | **bitmask kontak** (bitwise OR di contact handler) | `0x4f4b68`: `[x19+0x31c] |= [x20+0x10]`; dibaca cek "stuck" |
| `+0x32f` | **DEATH FLAG (byte)** | predikat `0x4f78c8`; 15 setter + 1 clearer |
| `+0x330` | flag kontak (ditulis contact handler) | `strb` di `0x439a30`, `0x4f4c2c`, `0x50f6f8`; dibaca 15 situs |
| `+0x333` | flag sekunder kematian (kasus switch `0x3ab7b0`) | `strb w21,[x8,#0x333]` sebelum set death |
| `+0x3a0` | counter int (init 6 di ctor; di-nol-kan saat mati) | getter slot `0xa8` = `([x0+0x3a0] > 0)`; `str wzr,[x19,#0x3a0]` di `0x4efae8`/`0x4efb1c` |
| `+0x3a4` | float, disalin dari `[body+0xc]` | `0x505394`, `0x50bf5c` |
| `+0x3a8` | float 20.0 (init `0x41a00000`) | ctor `0x4ed824` |
| `+0x3e4` | int 10 (init) | ctor `0x4ed818` |
| `+0x3f0` | float 5.0 (init `0x40a00000`) | ctor; dipakai fuel (`0x3bfdb4`) |
| `+0x3f8` | float 5.0 | ctor `0x4ed844` |
| `+0x408` | byte 1 | ctor `0x4ed868` |
| `+0x418` | float 1.0 | ctor `0x4ed86c` |
| `+0x438` | **`Stage*`** (arg ctor `x5`) | `str x26,[x19,#0x438]` di ctor `0x4ed85c` |
| `+0x4f0` | float 0.3 (`0x3e99999a`) | ctor `0x4ed8b0` |
| `+0x4f7` | byte guard "driver lepas" (slot `0xb8`) | `0x4f78e8` |
| `+0x718` | float 1.0 — laju konsumsi fuel | ctor `0x4ed8e0`; dibaca fuel drain |
| `+0x780` | float countdown (cek `0x52d610`) | `fsub s0,s0,s8` s/d 0 → mati |
| `+0x860`/`+0x864` | timer / ambang "stuck" (BadCar) | `0x5053d8` |
| `+0x874`/`+0x878` | timer / ambang "stuck" (mobil lain) | `0x50bfa0` |

### 3.2 `Stage` (`[PlayerCar+0x438]`, 180 slot vtable)

| Slot | Fungsi | Arti |
|---|---|---|
| `0x340` | `0x5f2398`: `ldrb w0,[x0,#0x3d4]; ret` | baca flag `[Stage+0x3d4]` |
| `0x348` | `0x5f23a0`: return `-100.0f` (`0xC2C80000`) | konstanta "batas bawah dunia" (base class; semua subclass Stage sama) |
| `0x350` | `0x5f23ac`: `mov w0,wzr; ret` | selalu false (base class) |
| `0x500` | dipakai `0x4ef7d8`: hasil dibandingkan `#4` | mode/state stage (4 = ?) |
| `0x510` | berbeda per subclass | kemungkinan "stage id" (dibanding `0x2b`=43, `0x14`=20, `0x1f`=31, `0`=0, `0x16`=22) |
| `0x518` | dipakai `0x4efc64` | bool stage |

### 3.3 Body (`[car+0x2d8]` dan `[car+0x2d0]`)

- Dibuat via `bl 0x6d1ea4` (factory `[car+0x2b8]`, definisi di stack) — `0x4f9868`.
- Layout (dari pola akses, BUKAN layout `b2Body` standar): `+0xc`/`+0x10` = posisi
  (x,y); `+0x2c` = 2 float (dipakai hitung energi kinetik `massa·|v|²` di
  `0x4f9880`); `+0x50`/`+0x54` = kecepatan (dipakai cek "stuck");
  `+0xa0` = massa; `+0xa8` = float lain.
- Punya vtable sendiri (slot `0x80`/`0x88` = transform titik; slot `0x510` =
  dipakai `0x3d4800`; slot `0x258` = dipakai `0x5cda58`; slot `0x3b8` =
  dipanggil getter arg=1 untuk `[car+0x2d0]`).

### 3.4 Getter sudut — vtable slot `0x70` (`0x4f4b30`, 42 refs vtable)

```
arg 0: ldp s0, s1, [body+0xc]            ; posisi body utama
arg 1: bila [this+0x2d0] != NULL, panggil vtable+0x3b8 padanya
       ; → posisi body #2 (kandidat kepala)
```

Dipakai flip (PROBE.md) DAN dipakai cek kematian `0x4eff98`/`0x4c9dfc` dengan
arg=1 — yaitu **posisi kepala**. Satuan/arti s0 vs s1 belum diputuskan statis
(probe dinamis tahap 2 yang menjawab).

### 3.5 Fungsi slot `0xb8` — `0x4f78e8` (46 refs, semua `PlayerCar*`)

Fungsi "driver lepas/mati" (inferensi): guard `[this+0x4f7]`; bila slot `0xa8`
(`[this+0x3a0] > 0`) false DAN predikat (`0xa0`) false → panggil slot `0x138`
(`0x4eed54`) dengan arg `[this+0x2d8]`, lalu lakukan matematika rotasi 2D pada
objek `[this+0x2d8]` (field `+0xc`, `+0x3c`, `+0x50`, `+0x58`, `+0xa4`, `+0xac`,
`+0xd8`) dan set `[this+0x4f7]=1`. Hanya dipanggil via vtable (0 `bl` langsung).

### 3.6 Contact handler — `0x4f4b68` (bukan di vtable; 46 `bl`, satu per mobil)

Diduga callback `BeginContact` Box2D (perlu verifikasi): arg
`(car, x1, x2, x3)`; bandingkan `[car+0x2d8]`/`[car+0x2e0]`/`[car+0x2e8]`
dengan argumen; baca kategori kontak `[x20+0x10]`/`[x20+0x14]` (nilai 5, 2, 8);
OR bitmask ke `[car+0x31c]`; set `[car+0x330]=1` pada kontak tipe 5/2; **baca**
(menulis TIDAK) flag kematian `[car+0x32f]`.

---

## 4. Aliran kematian lengkap

```
SUMBER (15 situs set flag — §6)
        │
        ▼
[PlayerCar+0x32f] = 1            (flag kematian; 1 situs clearer 0x3d17bc me-reset-nya)
        │
        ├─► predikat 0x3b2f94 → 0x4f78c8 (baca flag)
        │         │
        │         ├─► caller 0x3c7724 (state==3): timer [run+0x62c] += dt
        │         │     → bila [run+0x6db]==0 & [run+0x7bb]==0: [run+0x6db]=1
        │         │     → bila state global & ~2 == 8 & [run+0x7e9]:
        │         │       bl 0x3b1758 @0x3c7784  →  [vehicle+0x266]=1
        │         │
        │         ├─► caller 0x3c779c (state!=3): timer [run+0x62c] += dt
        │         │     → bila timer > 4.0 detik: bl 0x3b7c70 @0x3c77e0 (END-RUN)
        │         │       → cek 0x3d08e0, [run+0x589], [run+0x841], [run+0x2a1]/[run+0x2a2]
        │         │       → set [run+0x2a2]=1
        │         │
        │         ├─► caller 0x3c7f68 / 0x3c8070: set [run+0x5a0]=1 (sekali),
        │         │     bila mati → muat konstanta float (dipilih [run+0x650])
        │         │     → 0x3c8304 (kemungkinan parameter animasi/efek kematian)
        │         │
        │         ├─► caller 0x3c9520: loop resource ke-2 — bila mati, hitung ulang
        │         │     loop; bila resource [run+0x624] ≤ 0 → timer [run+0x628] 4 dtk
        │         │     → bl 0x3b7c70 (END-RUN)
        │         │
        │         └─► caller 0x3caba8, 0x3cb0dc, 0x3ce698, 0x3ce6f4, 0x5cda18, 0x60851c:
        │               pilih string alasan game-over / telemetri / aksi bila hidup
        │
        └─► pembaca flag langsung lain (31 situs ldrb): contact handler 0x4f4b68,
            slot 0xb8 (0x4f78e8), cek-cek stage 0x4c9dfc/0x4cb98c/0x50e570, …
```

**Jalur flag paralel (tanpa lewat timer):** `0x3af088` = `ldrb w0,[x0,#0x266]; ret`
(baca flag vehicle); `0x3b1758` = `strb [x0,#0x266]=1; ret` (set flag).
Di `0x3c76d8` (state `0x25`/`0x2b`): bila flag `[vehicle+0x266]` set → timer
`[run+0x62c]` += dt → bila > 4.0 → `bl 0x3c2c0c` (tail-call ke `0x3c29e8`;
kemungkinan pemicu game-over/UI akhir run — BELUM dipastikan).
`0x3c2c0c` juga memanggil vtable+`0xc8`/`+0x2d0` pada `[run+0x590]`/`[run+0x6a0]`
bila kondisi global terpenuhi. `0x3c2c0c` dipanggil dari 7 situs
(`0x3c72ec`, `0x3c7518`, `0x3c76ac`, `0x3c7708`, `0x3c7960`, `0x3c9774`, `0x3ca8e0`).

**Catatan:** "game-over `0x3c7784`" di fuel_analysis.md adalah **call site**
`bl 0x3b1758` di cabang A (bukan fungsi game-over itu sendiri). Fungsi end-run
yang besar adalah `0x3b7c70` (dipanggil di `0x3c77e0`).

### 4.1 Resource ke-2 (bukan fuel)

- `[run+0x624]` init 100.0; dikuras via `0x3d3384` (hanya 2 caller, di loop
  `0x3c94c8`); bila ≤ 0 → timer `[run+0x628]` += dt, flag `[run+0x650]`=1,
  bila > 4.0 → `bl 0x3b7c70`. `[run+0x620]`/`[run+0x608]` dibandingkan dengan
  konstanta `0x1fdfb8` = 0.01 dan di-set 0.0125 (`0x3c343958`) bila di bawahnya.
- Kemungkinan besar "udara/oksigen" untuk stage Bulan/bawah air — **inferensi**,
  belum dipastikan (nama stage tidak terbaca statis).
- Di-reset ke 100.0 oleh fungsi respawn yang juga me-clear death flag (`0x3d1784`).

---

## 5. Tabel 12 caller predikat `0x3b2f94`

| # | Caller | Fungsi pemuat | Yang diperiksa sebelum memanggil | Peran |
|---|---|---|---|---|
| 1 | `0x3c7724` | update besar `0x3c585c` | state `[x26]==3`, guard `[run+0x39b]==0`, `[run+0x630]==0` | **Timer kematian cabang A** → timer `[run+0x62c]` += dt → set `[run+0x6db]` + setter flag `0x3b1758` @`0x3c7784` |
| 2 | `0x3c779c` | update besar `0x3c585c` | state≠3, guard `[run+0x630]==0`, `[run+0x843]==0`, `[run+0x840]==0` | **Timer kematian cabang B** → timer > 4.0 → `bl 0x3b7c70` @`0x3c77e0` (END-RUN) |
| 3 | `0x3c7f68` | update utama `0x3c6840` | `[run+0x5a0]==0` (lalu di-set 1), `[x23]` > ambang | Bila mati → muat konstanta float (pilih `[run+0x650]`) → `0x3c8304` |
| 4 | `0x3c8070` | update utama `0x3c6840` | cabang lain update utama; `[run+0x5a0]==0` (lalu di-set 1) | Sama seperti #3, cabang berbeda |
| 5 | `0x3c9520` | loop resource `0x3c94c8` | `[run+0x624]` di 0–15 | Bila mati → hitung ulang loop resource ke-2 |
| 6 | `0x3caba8` | update besar | flag `[vehicle+0x266]`, `[run+0x79d]`, `[vehicle+0x26c]` | Pilih string alasan game-over (dead + `[run+0x650]` → string lain) |
| 7 | `0x3cb0dc` | update besar | — (langsung) | Bila mati → tampilkan string `0x1cb000+0xac0` + toast (`0x5e1fa4`, s0=0.75) |
| 8 | `0x3ce698` | fungsi ringkasan `0x3d4780` | — | Bila mati + `[run+0x650]` → bangun string varian (alasan) |
| 9 | `0x3ce6f4` | fungsi ringkasan `0x3d4780` | — | Bila mati → bangun string varian (alasan) |
| 10 | `0x3d4840` | fungsi akumulator `0x3d4780` | `[run+0x5f8]` += 0.1/0.08 per frame | Bila hidup → clamp `[run+0x608]`; bila `[run+0x5f8]` ≥ 100.0 → **SET FLAG** (`0x3d488c`) |
| 11 | `0x5cda18` | fungsi akumulator `0x5cd9c0` | flag `[x0+0x219]`; akumulator `[x0+0x21c]` += arg | Bila mati → kirim event telemetri `0x6d0f64` |
| 12 | `0x60851c` | fungsi scan list `0x6080dc` | scan list: `[item+0x258]&~1 == 2` | Bila **hidup** → `bl 0x3b3000` + aksi (s0=-8.0, s1=3.0, s2=1.0) |

Fungsi update utama 1.72.2 = `0x3c6840` (prologue cocok `SLOWMO_FN_PROLOGUE`;
`mov x19,x0` di `0x3c687c`; arg x0 = struct run).

---

## 6. Tabel 16 situs penulis flag `[PlayerCar+0x32f]`

Semua `strb` 4 byte; byte setter `09 bd 0c 39` (`strb w9,[x8,#0x32f]`) atau
`68 be 0c 39` (`strb w8,[x19,#0x32f]`); clearer `bf be 0c 39`
(`strb wzr,[x21,#0x32f]`).

### 6.1 Keluarga A — kontak / posisi kepala (paling relevan dengan pertanyaan user)

| Situs | Fungsi | Pemicu (bukti disassembly) | Status |
|---|---|---|---|
| `0x3b0ddc` | handler kontak `~0x3b0xxx` | Salah satu objek tabrakan punya `[obj+0x10] == 0x10000` → tampil string `0x1d2000+0x9e7` + `bl 0x3c4798` → **SET flag** + `[run+0x266]=1` | **Kandidat utama "kepala kena tanah"** — kategori `0x10000` (bit 16) belum dipastikan milik kepala vs tanah; perlu runtime |
| `0x3ad494` | cek titik `~0x3ad3xx` | Untuk tiap item di list `[x22+0x30]`: titik `[item+0xc]`/`[item+0x10]` vs hasil vtable body `+0x80`/`+0x88` (pilih flag `[run+0x290]`); bila `s8 < s0` → **SET flag** + `[run+0x298]=1` + tampil string `0x1f6000+0x71e` | **Kandidat "kepala di bawah permukaan"** — perbandingan ketinggian titik-vs-body |
| `0x4eff98` | fungsi bersama `0x4ef7d8` (44 caller per-mobil) | `getter(car, 1)` = posisi kepala → `bl 0x3a5a94` (query spasial, objek `[car+0x298]+0x560`) → `[hasil+0x2e0]` → `[itu+0x20c] == 7` → **SET flag** | **Kandidat "kepala menyentuh objek tipe 7"** — query dipakai 10+ tempat; tipe 7 belum dipastikan (kemungkinan tanah) |
| `0x50e570` | fungsi per-mobil `~0x50e4xx` | Jarak antara titik objek `[car+0x300]` (vtable+0/+8) dan titik `(s9,s10)` **> 1.0** → **SET flag** (bila predikat belum true) | **Detachment** — bagian (kepala/driver) lepas > 1.0 dari titik acuan |

### 6.2 Keluarga B — cek per-frame / jatuh

| Situs | Fungsi | Pemicu | Status |
|---|---|---|---|
| `0x4efae4` | `0x4efa70` (dipanggil 46×, sekali/frame/mobil) | Slot Stage `0x340` (`[Stage+0x3d4]`) true DAN posisi body-Y `s9=[body+0x10]` < hasil slot Stage `0x348` (**-100.0f**) → **SET flag** + `[car+0x3a0]=0` | Jatuh keluar dunia (di bawah -100). Base Stage tidak override slot ini |
| `0x4efb18` | `0x4efa70` (sama) | Slot Stage `0x350` true (base class selalu false → praktis tidak pernah fire dari base) → **SET flag** + `[car+0x3a0]=0` | Mati bila ada subclass Stage yang override `0x350` (tidak ada di 1.72.2 — semua = `0x5f23ac`) |
| `0x4ec2a8` | objek stage `0x4eaf84` | Bila predikat false: `getter(car,1)` (posisi kepala) vs titik `[obj+0x1a0]+0xc`; jarak **< 4.0** → `bl 0x6d2224` + **SET flag** (`w20`=1, dikonfirmasi `mov w20,#1` di `0x4ec1dc`/`0x4ec21c`) + vtable+`0x238`/`0x240` | Proximity hazard stage (fungsi yang sama juga memberi skor 100 bila `[obj+0x228]-[obj+0x22c] > 3.0`) |

### 6.3 Keluarga C — "stuck" (terbalik diam)

| Situs | Fungsi | Pemicu | Status |
|---|---|---|---|
| `0x5053f4` | BadCar `~0x5052xx` | Bitmask kontak `[car+0x31c]` ≠ 0 DAN speed `|[body+0x50]| < 1.0` selama > `[car+0x864]` detik (timer `[car+0x860]` += dt `s8`) → **SET flag** | Mati karena stuck/terbalik diam |
| `0x50bfbc` | mobil lain `~0x50bfxx` | Pola sama persis (timer `[car+0x874]`, ambang `[car+0x878]`) → **SET flag** | Sama, mobil lain |

### 6.4 Keluarga D — timer / accumulator / kill-zone

| Situs | Fungsi | Pemicu | Status |
|---|---|---|---|
| `0x3d488c` | akumulator `0x3d4780` (0 `bl` langsung — dipanggil via vtable) | `[run+0x5f8]` += 0.1 (`0x1fd780`) atau 0.08 (`0x1fe18c`) per frame (pilih via body vtable+`0x510` + cek `0x5f1060`); bila ≥ 100.0 → clamp 100.0 + **SET flag** | Meter tak dikenal — kemungkinan "heat"/"damage"/meter stage; **belum dipastikan**. 0.1/frame ≈ 100 dalam ~16,7 dtk @60fps |
| `0x52d610` | fungsi kecil `0x52d5bc` (FastBike?) | Bila `[car+0x7b0]` == arg `x2` dan countdown `[car+0x780]` (init ≠ 0) -= dt mencapai 0 → **SET flag** | Countdown terkait objek spesifik |
| `0x4c9dfc` | objek stage `~0x4c9dxx` | Bila predikat false: titik `getter(car,1)` (s9,s10) masuk kotak: `[obj+0x1b4] < s9 < [obj+0x1bc]` DAN `s10 ≤ min([obj+0x1c0],[obj+0x1b8]) - 15` → **SET flag** | **Kill-zone** stage (kotak bahaya) |
| `0x4cb98c` | fungsi stage `~0x4cb8xx` | Bila predikat false DAN `0x4cbc14` true DAN `[obj+0x290]` (float) > 1.0 → **SET flag** | Pemicu stage (loop item 0x38, `bl 0x6cf6f4`) |
| `0x5d09fc` | fungsi hazard `~0x5d09xx` | Setelah `bl 0x6d2224` (buat objek fisika): **SET flag** pada mobil dari `[[x19+0x198]+0x18]` | Hazard stage (konteks kabur — fungsi besar pembangun objek) |

### 6.5 Keluarga E — switch alasan & reset

| Situs | Fungsi | Pemicu | Status |
|---|---|---|---|
| `0x3ab7b0` | switch alasan `~0x3ab7xx` | Satu case switch (nilai dibandingkan `0x22`, `0x1f`, …): set `[run+0x69f]=1`, tampil string `0x1f1000+0x115` (`0x3c4424`, s0=1.5), set `[car+0x333]=1` → **SET flag** | Alasan kematian spesifik (case mana belum dipetakan penuh) |
| `0x3d17bc` | fungsi respawn/reset `~0x3d1784` | Reset `[run+0x624]`=100.0, `[run+0x884]` += dt; bila predikat true → **`strb wzr` = CLEAR flag** | **Satu-satunya clearer** — dipakai saat respawn/restart |

---

## 7. Pencarian "kepala vs tanah" — temuan & yang TIDAK ditemukan

### 7.1 Yang ADA (bukti)

- **Kontak kategori `0x10000`** (`0x3b0ddc`): satu-satunya situs yang mati
  **langsung dari sebuah tabrakan** dengan membandingkan field kategori kedua
  objek (`[x22+0x10]` / `[x23+0x10]` vs `0x10000`). Ini pola klasik
  "fixture kepala (kategori X) menyentuh fixture tanah".
- **Perbandingan ketinggian titik** (`0x3ad494`): iterasi list titik, bandingkan
  dengan transform body — pola klasik "apakah titik kepala berada di bawah
  permukaan tanah".
- **Query spasial di posisi kepala** (`0x4eff98`): ambil posisi kepala via
  `getter(car,1)`, tanyakan "apa yang ada di titik ini" (`0x3a5a94`), cek tipe
  hasil == 7.
- **Kill-zone & proximity** (`0x4c9dfc`, `0x4ec2a8`): kotak/bola bahaya yang
  memakai posisi kepala (`getter(car,1)`).
- **Detachment** (`0x50e570`): kepala lepas > 1.0 dari acuan → mati.

### 7.2 Yang TIDAK ADA (jujur)

- **Tidak ada class `Driver` / `Head` / `Ragdoll` / `Neck` / `Helmet` / `Rider`
  di RTTI.** (Daftar lengkap class Box2D yang ADA: `b2ChainShape`,
  `b2CircleShape`, `b2EdgeShape`, `b2PolygonShape`, `b2DistanceJoint`,
  `b2FrictionJoint`, `b2GearJoint`, `b2MotorJoint`, `b2MouseJoint`,
  `b2PrismaticJoint`, `b2PulleyJoint`, `b2RevoluteJoint`, `b2RopeJoint`,
  `b2WeldJoint`, `b2WheelJoint`, `b2ContactListener`, `b2ParticleSystem`.)
- **Tidak ada struktur "bone/rig"** — tidak ada array sendi, tidak ada nama tulang.
  Driver adalah body fisika biasa (kemungkinan 2 body: chassis + kepala, plus
  roda sebagai body terpisah).
- **Identitas `[car+0x2d0]` sebagai "kepala" BELUM terbukti statis.** Fakta yang
  pasti: itu body kedua yang diregistrasi ke world, dan `getter(arg=1)`
  mengembalikan posisinya. Penulis field `+0x2d0` tidak ditemukan di region
  kode `PlayerCar` (kemungkinan ditulis helper shared di luar region itu).
  Yang pasti ditulis di ctor per-mobil: `+0x2d8` (chassis, `0x4f9868`),
  `+0x2e0`/`+0x2e8`/`+0x300` (bagian lain).
- **Kategori `0x10000` dan tipe `7` belum dipetakan ke "kepala" vs "tanah"** —
  butuh data runtime (lihat §9).
- **Fungsi `0x3d4780` (akumulator `[run+0x5f8]`) tidak punya `bl` langsung** —
  dipanggil via vtable; identitas stage/mode-nya belum dipastikan.
- Arti s0 vs s1 hasil getter (posisi X/Y vs sudut?) belum diputuskan — probe
  dinamis tahap 2 (PROBE.md) yang menjawab.

---

## 8. Kandidat patch BARU (di sumber, bukan di return predikat)

Semua patch berupa **NOP 4 byte** (`1f 20 03 d5`) atas instruksi `strb` penanda
kematian, ATAU patch kondisi di atasnya. NOP hanya mematikan **satu jalur** —
kombinasikan bila perlu. **Jangan build/push tanpa perintah user; ini hanya
kandidat hasil REA.**

### Kandidat 1 — matikan kontak kepala-vs-tanah (`0x3b0ddc`) ⭐ paling langsung

| | |
|---|---|
| Alamat | `0x3b0ddc` |
| Byte asli | `09 bd 0c 39` (`strb w9, [x8, #0x32f]`) |
| Patch | `1f 20 03 d5` (NOP) |
| Efek | Tabrakan kategori `0x10000` tidak lagi membunuh. Pesan teks (`0x3b0dac`) tetap tampil — kosmetik saja, atau NOP-kan juga `bl 0x3c4424` di `0x3b0dc8` bila mengganggu |
| Risiko | **Rendah–sedang.** Bila `0x10000` ternyata bukan "kepala" melainkan kategori lain (mis. "bahan peledak"), patch ini mematikan jalur itu juga — tapi tetap hanya satu jalur dari 15. Bila ini SATU-SATUNYA jalur "kepala kena tanah", hasilnya = god mode yang bersih |

### Kandidat 2 — matikan cek ketinggian titik (`0x3ad494`) ⭐

| | |
|---|---|
| Alamat | `0x3ad494` |
| Byte asli | `09 bd 0c 39` (`strb w9, [x8, #0x32f]`) |
| Patch | `1f 20 03 d5` (NOP) |
| Efek | Perbandingan titik-vs-body tidak lagi membunuh; `[run+0x298]=1` + teks tetap jalan |
| Risiko | **Rendah.** Jalur ini kemungkinan "kepala di bawah tanah" versi geometris (bukan kontak). Bila digabung dengan Kandidat 1, dua jalur kepala utama mati |

### Kandidat 3 — matikan query spasial kepala (`0x4eff98`)

| | |
|---|---|
| Alamat | `0x4eff98` |
| Byte asli | `68 be 0c 39` (`strb w8, [x19, #0x32f]`) |
| Patch | `1f 20 03 d5` (NOP) |
| Efek | "Apa yang ada di posisi kepala" (tipe 7) tidak lagi membunuh. Fungsi ini bersama (`0x4ef7d8`, 44 caller) — berlaku semua mobil |
| Risiko | **Rendah.** Alternatif lebih halus: ubah `cmp w8, #7` di `0x4eff8c` menjadi nilai yang tidak pernah cocok — tapi NOP lebih aman (tidak mengubah logika lain) |

### Kandidat 4 — bekukan timer kematian di sumber (bukan flag-nya)

| | |
|---|---|
| Alamat | `0x3c7748` (cabang A) dan `0x3c77d4` (cabang B) |
| Byte asli | `str s0, [x19, #0x62c]` (timer += dt) |
| Patch | NOP kedua `str` (4 byte masing-masing) |
| Efek | Timer `[run+0x62c]` tidak pernah naik → `bl 0x3b7c70` (END-RUN) tidak pernah fire meski flag set |
| Risiko | **SEDANG — mirip god mode v2.** Flag tetap ter-set → pembaca flag lain (contact handler, slot `0xb8`, UI alasan) tetap melihat "mati": driver bisa tampak lepas/mati secara visual sementara kendaraan tetap jalan; dan setter `[vehicle+0x266]` di cabang A (`0x3c7784`) tetap jalan. Lebih kotor dari Kandidat 1–3. Hanya pakai bila Kandidat 1–3 belum cukup |

### Kandidat 5 — matikan cek "stuck" (`0x5053f4` + `0x50bfbc`)

| | |
|---|---|
| Alamat | `0x5053f4`, `0x50bfbc` |
| Byte asli | `68 be 0c 39` (keduanya) |
| Patch | `1f 20 03 d5` di keduanya |
| Efek | Mobil terbalik diam tidak lagi mati karena stuck |
| Risiko | **Rendah.** Bila mobil benar-benar stuck, run tidak berakhir sendiri — user restart manual. Berguna sebagai pelengkap (mobil terbalik di 82 m pada tes god mode v3 kemungkinan mati via jalur ini bila bukan via kontak) |

### Kandidat 6 — matikan cek jatuh (`0x4efae4` + `0x4efb18`) — TIDAK DISARANKAN SENDIRIAN

| | |
|---|---|
| Alamat | `0x4efae4`, `0x4efb18` |
| Patch | NOP keduanya |
| Efek | Jatuh di bawah -100 tidak membunuh |
| Risiko | **TINGGI (soft-lock).** Mobil jatuh selamanya tanpa game over — layar kosong, harus restart manual. Hanya berguna bila digabung dengan "respawn otomatis" |

### Rekomendasi kombinasi

- **Minimal & bersih:** Kandidat 1 + 2 (+ 3 bila masih mati). Ketiganya mematikan
  jalur "kepala" di sumber; flag tidak pernah ter-set; semua 32 pembaca melihat
  "hidup"; timer tidak pernah jalan; tidak ada efek samping visual "driver mati".
- **Bila masih ada kematian misterius:** tambah Kandidat 5 (stuck) lalu
  Kandidat 4 (bekukan timer — terakhir, karena efek samping visual).
- **Jangan sentuh:** Kandidat 6 sendirian; clearer `0x3d17bc` (itu reset yang
  berguna); return predikat `0x4f78c8` sudah dipatch v3 — patch sumber adalah
  pengganti/pelengkap, bukan duplikat.

### Catatan verifikasi patch

- Setelah patch, verifikasi runtime: mobil terbalik + kepala menyentuh tanah
  > 4 detik → tidak game over; `[PlayerCar+0x32f]` tetap 0 (baca via probe);
  kendaraan tetap responsif (gas/rem/balik).
- Bila satu kandidat tidak cukup, tambahkan satu per satu (jangan semua sekaligus)
  supaya jalur mana yang sebenarnya membunuh bisa diidentifikasi.

---

## 9. Yang masih butuh data runtime dari HP

1. **Kategori `0x10000` (`0x3b0ddc`) itu apa?** Probe: log `[obj+0x10]` kedua
   objek saat tabrakan kepala-vs-tanah terjadi; bandingkan dengan tabrakan
   roda-vs-tanah dan chassis-vs-tanah.
2. **Tipe `7` (`0x4eff98`) itu apa?** Probe: log hasil `0x3a5a94` (query di
   posisi kepala) + `[hasil+0x20c]` saat kepala menyentuh tanah vs saat kepala
   di udara.
3. **Apakah `[car+0x2d0]` benar kepala?** Probe: log posisi `getter(car,1)`
   vs posisi visual kepala driver di layar (bandingkan dengan `getter(car,0)` =
   chassis). Bila `getter(car,1)` mengikuti kepala saat mobil terbalik → terbukti.
4. **Meter `[run+0x5f8]` (`0x3d4780`) itu apa?** Probe: log nilainya per frame
   di tiap stage; di stage mana ia naik 0.1 vs 0.08; apakah ia "heat"/"damage".
5. **Resource ke-2 `[run+0x624]` itu apa?** Probe: di stage mana ia berkurang;
   apakah "udara" (Bulan/bawah air).
6. **Satuan getter sudut:** `s0`/`s1` = (x,y) posisi atau (sudut, …)? Probe
   dinamis tahap 2 (PROBE.md) — panggil langsung getter sudut dari hook_update
   dan bandingkan dengan `[vehicle+0x66c]`.
7. **Fungsi `0x3c2c0c` / `0x3c29e8`:** pemicu game-over/UI akhir run jalur flag
   paralel — belum dipastikan; probe: log kapan ia dipanggil relatif terhadap
   `[vehicle+0x266]=1`.
8. **Case switch `0x3ab7b0`:** nilai switch mana yang masuk ke case ini
   (alasan kematian apa) — butuh trace nilai `w8` sebelum switch.

---

## 10. Lampiran — alamat kunci

| Alamat | Peran |
|---|---|
| `0x3b2f94` | Predikat kematian (trampolin vtable slot `0xa0`) |
| `0x4f78c8` | Implementasi predikat: `ldrb w0,[x0,#0x32f]; ret` |
| `0x4f78d0` | Slot `0xa8`: `([x0+0x3a0] > 0)` |
| `0x4f78e8` | Slot `0xb8`: fungsi "driver lepas" (rotasi 2D + set `[this+0x4f7]`) |
| `0x4f4b30` | Getter sudut/posisi slot `0x70` (arg 0 = chassis, arg 1 = kepala) |
| `0x4f4b68` | Contact handler (diduga `BeginContact` Box2D) |
| `0x4efa70` | Cek per-frame: Stage flag + jatuh < -100 + Stage `0x350` |
| `0x4ef7d8` | Fungsi bersama per-frame (44 caller): berisi cek query kepala `0x4eff98` |
| `0x3c585c` | Fungsi update besar (caller timer `0x3c7724`/`0x3c779c`) |
| `0x3c6840` | Fungsi update utama (caller `0x3c7f68`/`0x3c8070`) |
| `0x3c77e0` | `bl 0x3b7c70` — END-RUN setelah timer > 4.0 dtk |
| `0x3c7784` | `bl 0x3b1758` — set flag `[vehicle+0x266]=1` |
| `0x3b7c70` | Fungsi end-run besar |
| `0x3c2c0c` | Helper akhir run (7 caller; tail-call `0x3c29e8`) |
| `0x3b1758` | Setter `[x0+0x266]=1` |
| `0x3af088` | Pembaca `[x0+0x266]` |
| `0x3d17bc` | Clearer flag kematian (`strb wzr,[x21,#0x32f]`) — respawn |
| `0x4ed6d8` | Konstruktor base `PlayerCar` (46 caller) |
| `0x4ed608` | Inisialisasi statik (bukan ctor mobil) |
| `0x3d4780` | Fungsi akumulator `[run+0x5f8]` (via vtable; 0 `bl` langsung) |
| `0x3a5a94` | Query spasial "objek di titik" (10+ caller) |
| `0x6d1ea4` | Create body (factory `[car+0x2b8]`) |
| `0x3b7c70` | End-run (lihat atas) |

**File kerja:** `hcrdis.py` (disassembler Capstone), `vtables.py` →
`vtables.json` (675 vtable, 662 bernama), `caller_A_0x3c585c.txt`,
`caller_B_0x3c7f40.txt`.

**Tidak dilakukan:** menjalankan game, mengubah binary, mengunggah data ke pihak
ketiga, build/push apa pun.
