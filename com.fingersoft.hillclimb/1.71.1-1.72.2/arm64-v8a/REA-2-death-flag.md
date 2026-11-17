# REA-2: Mekanisme "mati" Hill Climb Racing 1 — di luar rantai flag kematian

**Tanggal:** 17 Nov 2026
**Target:** Hill Climb Racing 1 `com.fingersoft.hillclimb` **v1.72.2** (code 936, game terpasang di POCO user)
**Binary yang dianalisis:** `libgame.so` arm64 SHA-256 `307f6b87dfae712a0496fb4396ff56682bde50350744789dd1875d7d74d77a49`
(dikonfirmasi identik dengan libgame.so di dalam XAPK resmi 1.72.2 yang diunduh untuk riset ini)
**Lanjutan dari:** `~/workspace/rea-hcr-death/REPORT.md` (514 baris) dan
`~/workspace/goals/hozin-hcr-mod-aplikasi-root-mod-menu-hill-climb-racing/GOAL.md`
**Status:** RISET SAJA. Tidak menyentuh `~/workspace/hozin-hcr-mod/`, tidak ada implementasi.

## 0. Ringkasan eksekutif — jawaban singkat

**Laporan user (17 Nov 17:41, tes v1.7 di POCO):** *"God cuma nahan screen game over, selain itu ya tetep bisa mati."*

**Mekanisme "mati" yang sebenarnya, dalam satu paragraf:**

God mode v4 (NOP 3 situs `strb` penulis flag `[PlayerCar+0x32f]` + v3 yang mem-patch
predikat mati `0x3b2f94` + v2 yang me-NOP 2 store timer) hanya menahan **cabang
timer game-over**. Tapi flag kematian itu masih bisa ter-set oleh **12 situs setter
lain yang TIDAK di-NOP v4** (stuck/terbalik diam `0x5053f4` + `0x50bfbc`, jatuh
`0x4efae4`, detachment `0x50e570`, akumulator `0x3d488c`, kill-zone `0x4c9dfc`,
hazard `0x4ec2a8`/`0x5d09fc`, countdown `0x52d610`, pemicu stage `0x4cb98c`,
switch `0x3ab7b0`). Dan yang paling penting: **v3 mem-patch predikat (sebuah
fungsi), tapi 31 dari 32 pembaca flag membaca byte flag itu LANGSUNG (`ldrb
[x,#0x32f]`) tanpa lewat predikat** — jadi mereka tetap melihat "mati" begitu flag
ter-set oleh situs mana pun. Dua pembaca itulah yang membunuh kendaraan secara
fisik:

1. **`0x524f0c` (update per-mobil):** begitu flag set (dan `[car+0x519]==0`),
   memanggil `DestroyBody` (`0x6d20c0`) untuk **tiga body driver**
   `[car+0x840]`, `[car+0x848]`, `[car+0x858]`, lalu men-null-kan pointer-nya.
   Driver dihapus dari dunia fisika — kendaraan kehilangan pengemudi, tidak bisa
   dikendarai, meski layar game over tertahan.
2. **`0x560970` (fungsi cleanup per-mobil):** begitu flag set, memanggil slot
   vtable `0x200` (destroy joint) pada joint `[car+0x788]` dan pada **kepala
   `[car+0x2d0]`** — kepala/driver terlepas dari kendaraan.

Itulah "tetep bisa mati": game-over screen ditahan v2/v3, tapi driver sudah
dihancurkan/dilepas oleh pembaca langsung flag. **Koreksi besar terhadap laporan
death pertama: situs A v4 (`0x3b0ddc`, kategori kontak `0x10000`) BUKAN "kepala
kena tanah" — itu detektor GOAL stage ballsports** (teks `"GOAL !!"`,
`GameContentLayer.cpp`; file `assets/stages/party/ballsports/goal.json` ada;
fixture kepala di data game berkategori default 1, bukan `0x10000`). Jadi dari 3
situs v4, hanya B (`0x3ad494`) dan C (`0x4eff98`) yang benar-benar terkait kepala;
A adalah patch yang tidak ada hubungannya dengan kematian kepala (tidak merugikan,
tapi juga tidak melindungi).

**Istilah Inggris game untuk "kepala kena tanah / kena benturan": "DRIVER DOWN"**
(`assets/translations/en.po`, `src/common/GameLayer.cpp`: *"Text displayed when
the game ends because the driver's head has hit something"*). Varian: `"DRIVER
DOWN & OUT OF FUEL"`, `"NECK FLIP"` (flip yang mematahkan leher — achievement),
`"GAME OVER!"`, `"GOAL !!"`, `"GOAL REACHED !!"`, `"JUMP FAILED !!"`,
`"CANNON LOST !!"`.

**Kandidat perbaikan paling menjanjikan (detail di §7):** P0 — lumpuhkan efeknya
langsung di blok destroy `0x524f0c` (ubah `cbz` di `0x524f10` jadi lompat selalu)
dan/atau blok detach `0x560970` (ubah `cbz` di `0x560974`), sehingga driver tidak
pernah dihancurkan/dilepas apa pun yang terjadi pada flag. Alternatif P1 — NOP
ke-12 situs setter tersisa. Keduanya masih butuh konfirmasi runtime (gejala visual
persis + tes POCO).

---

## 1. Disassembly penuh fungsi ketiga situs v4 — apa lagi yang mereka lakukan

### 1.1 Situs A — `0x3b0ddc`: contact handler `0x3b0604–0x3b176c`

Fungsi ini adalah **BeginContact handler Box2D** (`0x4f4b68` diduga `BeginContact`,
dari laporan death). Alurnya (diringkas dari disassembly penuh):

- Membandingkan `[fixture+0x10]` kedua objek yang bertabrakan dengan `0x10000`.
- **Cabang `0x10000` (yang memuat `0x3b0ddc`):**
  - `0x3b0dd0`: `bl 0x3c4798` (fungsi "goal tercapai" — lihat §1.4).
  - `0x3b0ddc`: `strb w9, [x19, #0x32f]` — **SET flag kematian** (byte asli
    `09 bd 0c 39`; di-NOP v4).
  - `0x3b0de0`: `strb w9, [x19, #0x266]` — **SET vehicle flag** (byte asli
    `69 9a 09 39`; **TIDAK di-NOP v4**).
  - Menampilkan string di `0x1d29e7` = **`"GOAL !!"`** (terkonfirmasi di
    `en.po` baris 3010–3012, `#: src/common/GameContentLayer.cpp`).
  - Latch sekali-per-run: `[ui+0x7e9]=1` (dicek di `0x3b0da4` — cabang GOAL hanya
    fire sekali per run).
- **Cabang kedua — kategori `0x100`, bila `[x26]==10`:**
  - `0x3b0fe8`: `bl 0x3c4798` (fungsi yang sama).
  - `0x3b0ff4`: `strb w9, [x19, #0x266]` — vehicle flag lagi (byte `69 9a 09 39`).
  - `0x3b0ff8`: `strb w9, [x8, #0x333]` — **flag sekunder kematian**
    (byte `09 cd 0c 39`; pembaca: `0x3ac998`, `0x3ad8d8`, `0x4fbcbc`, `0x4fbdf8`).
  - Sebelumnya di cabang ini ada logika hancurkan objek: panggil vtable slot
    `0x30` + slot `0x298` pada objek, `bl 0x67e27c`, lalu `str xzr` (null-kan).
- Ekor handler (`0x3b1858`/`0x3b187c`): `str wzr, [x8, #0x3a0]` — me-nol-kan
  counter airborne `[car+0x3a0]` (lihat §2.5).

**Kesimpulan situs A:** ini BUKAN detektor kepala. Ini detektor **kontak dengan
fixture kategori `0x10000` = objek GOAL stage** (ballsports). Buktinya:
teks `"GOAL !!"`, latch sekali-per-run, panggilan analitik/event `0x599348`
dengan argumen jarak `[x19+0x53c]`, dan file `assets/stages/party/ballsports/goal.json`
(sensor fixture, `attachBody: true`). **NOP v4 di `0x3b0ddc` tidak melindungi
dari kematian kepala — ia hanya mencegah event GOAL men-set flag kematian.**
(Dan sebaliknya: tanpa NOP itu, menyentuh GOAL di stage ballsports akan men-set
flag mati — perilaku yang memang "benar" menurut desain game? Tidak: GOAL
seharusnya mengakhiri run dengan kemenangan, bukan kematian. Flag di sini lebih
tepat dibaca "run berakhir", bukan "driver mati" — lihat §6.)

### 1.2 Situs B — `0x3ad494`: fungsi cek titik `~0x3ad120–0x3ad6e4+`

Fungsi besar per-frame (start persisnya belum dipetakan — tidak ada prolog
`stp x29,x30` dalam 0x2000 byte ke belakang; fungsi ini > 8 KB atau memakai pola
prolog berbeda):

- `0x3ad2dc–0x3ad308`: memanggil getter posisi kepala `getter(car,1)` (slot
  vtable `0x70` pada `[car+0x258]`), menghitung sesuatu, menulis
  `[run+0x299] = (int)(s0/100.0) & 1`.
- `0x3ad310–0x3ad33c`: memuat objek dari `[x27]` (daftar mobil?), memanggil slot
  `0xb0`; bila hasilnya 1..29, membaca guard `[x20+0x4f7]`; bila guard set,
  **`str wzr, [x19, #0x294]`** — me-reset `[car+0x294]` ke 0.
- **Blok utama (mengandung `0x3ad494`):** saat `[car+0x294] > 0,5` → memanggil
  slot vtable `0x200` (**detach**) pada objek `[car+0x410]`; saat
  `[car+0x294] > [car+0x184]` → **clear guard `[car+0x4f7]` di `0x3ad414`**
  (reset detach) + clear `[run+0x291]` + mengisi list titik via `bl 0x4eee28`
  → loop membandingkan tiap titik vs transform body → bila `s8 < s0` →
  `strb` di **`0x3ad494`** (byte asli `09 bd 0c 39`; di-NOP v4) + `[run+0x298]=1`.
- `0x3ad720` (masih dalam fungsi yang sama, setelah situs B): membaca
  **[vehicle+0x266]** — situs B ikut membaca vehicle flag.

**Kesimpulan situs B:** ini detektor **"kepala di bawah permukaan"** yang asli
(perbandingan ketinggian titik-vs-body). Efek sampingnya justru penting: fungsi
ini juga **me-reset guard detach `[car+0x4f7]`** dan **me-detach objek
`[car+0x410]`** saat `[car+0x294] > 0,5` — dua efek yang TIDAK disentuh v4
(v4 hanya me-NOP `strb` flag-nya). Bila `[car+0x410]` adalah joint/body yang
menahan driver, detach ini bisa ikut berkontribusi pada "driver lepas" meski
flag tidak pernah ter-set. **Perlu konfirmasi runtime** (identitas `[car+0x410]`
belum terpetakan).

### 1.3 Situs C — `0x4eff98`: fungsi bersama `0x4ef7d8` (44 caller per-mobil)

- Memanggil `getter(car,1)` = posisi kepala → `bl 0x3a5a94` (query spasial,
  19 caller) pada objek `[car+0x298]+0x560` → `[hasil+0x2e0]` → `[itu+0x20c]`
  dibandingkan dengan **7** → bila sama → `strb` di **`0x4eff98`** (byte asli
  `68 be 0c 39`; di-NOP v4).
- **Setelah `strb`, fungsi LANJUT TANPA SYARAT:** memanggil slot vtable `0x498`
  pada `[car+0x468]` dengan argumen **5,0**. Tidak ada efek samping kematian
  lain di fungsi ini — slot `0x498` kemungkinan efek visual/suara (belum
  dipetakan; bukan DestroyBody/detach).

**Kesimpulan situs C:** detektor **"kepala menyentuh objek tipe 7"** yang asli
(tipe 7 belum dipastikan = tanah; query `0x3a5a94` dipakai 19 tempat). Efek
sampingnya (slot `0x498` + 5,0) tidak terkait kematian — aman, bukan penyebab
"tetep bisa mati".

### 1.4 Fungsi `0x3c4798` — yang dipanggil situs A (3 caller: `0x3b0dd0`, `0x3b0fe8`, `0x62e508`)

- Set latch `[ui+0x7e9]=1` (dicek di `0x3b0da4` — cabang GOAL hanya fire sekali
  per run); bila `[ui+0x6db]` sudah 1 → return.
- Bila global `[0x8776a8]==10` → set `[ui+0x6db]=1` + tail-call `0x599348`
  (analitik/event, argumen jarak `[x19+0x53c]`).
- Bila tidak → `ldr x0,[x19,#0x3a8]; bl 0x3b1758` → **set `[vehicle+0x266]=1`**
  (setter `0x3b1758`: `strb w8, [x0, #0x266]` di `0x3b175c`, byte `08 98 09 39`).
- Lanjutan (`0x3c4830+`): setelah setter, tail-call `0x59877c` (event dengan
  jarak + nilai global) — murni analitik, bukan kematian.

**Setter `0x3b1758` punya 9 `bl` caller:** `0x3bfc50`, `0x3bff78`, `0x3c4294`,
`0x3c4834`, `0x3c738c`, `0x3c74b0`, `0x3c759c`, `0x3c7784`, `0x4ec41c`.
**`0x3b7c70` (end-run helper) punya 4 caller:** `0x3b7b0c`, `0x3c77e0`,
`0x3c9588`, `0x3d1804`.

---

---

## 2. Semua jalur kematian / run-end lain yang tidak lewat 3 situs v4

### 2.1 Daftar lengkap 15 setter flag + 1 clearer (dari laporan death, diverifikasi ulang)

| # | Alamat `strb` | Fungsi / konteks | Pemicu | Di-NOP v4? |
|---|---|---|---|---|
| 1 | `0x3b0ddc` | contact handler | kontak kategori `0x10000` (**GOAL**, bukan kepala — §1.1) | **YA** |
| 2 | `0x3ad494` | cek titik | titik di bawah transform body ("kepala di bawah permukaan") | **YA** |
| 3 | `0x4eff98` | query kepala | kepala menyentuh objek tipe 7 | **YA** |
| 4 | `0x5053f4` | stuck, BadCar `~0x5052xx` | kontak + speed < 1,0 selama > ambang `[car+0x864]` (timer `[car+0x860]`) — **terbalik diam** | TIDAK |
| 5 | `0x50bfbc` | stuck, mobil lain `~0x50bfxx` | pola sama (timer `[car+0x874]`, ambang `[car+0x878]`) | TIDAK |
| 6 | `0x4efae4` | fall `0x4efa70` | slot Stage `0x340` true DAN posisi-Y chassis < batas slot `0x348` (**−100,0**) | TIDAK |
| 7 | `0x4efb18` | fall `0x4efa70` (sama) | slot Stage `0x350` true — base class selalu false (semua = `0x5f23ac`) → **praktis tidak pernah fire** | TIDAK |
| 8 | `0x50e570` | detachment `~0x50e4xx` | jarak 2 titik objek `[car+0x300]` (slot vtable 0 dan 8) **> 1,0** (digate predikat) | TIDAK |
| 9 | `0x3d488c` | akumulator `0x3d4780` | `[run+0x5f8]` += 0,1/0,08 per frame; bila **≥ 100,0** → set flag | TIDAK |
| 10 | `0x4c9dfc` | kill-zone stage | posisi kepala masuk kotak bahaya | TIDAK |
| 11 | `0x4ec2a8` | hazard proximity | jarak kepala ke titik hazard **< 4,0** (+ `bl 0x6d2224`) | TIDAK |
| 12 | `0x52d610` | countdown (FastBike?) | countdown `[car+0x780]` mencapai 0 | TIDAK |
| 13 | `0x4cb98c` | pemicu stage | `[obj+0x290]` (float) > 1,0 + kondisi `0x4cbc14` | TIDAK |
| 14 | `0x5d09fc` | hazard stage | setelah `bl 0x6d2224` (buat objek fisika) | TIDAK |
| 15 | `0x3ab7b0` | switch alasan | satu case switch; set `[run+0x69f]=1`, tampil string `0x1f1000+0x115`, set `[car+0x333]=1` → set flag | TIDAK |
| — | `0x3d17bc` | respawn/reset | **satu-satunya CLEARER** (`strb wzr` = clear flag) saat respawn/restart | — |

**12 dari 15 setter tetap aktif di bawah god mode v4.** Tiga yang paling mungkin
menewaskan user saat "kepala kena tanah lalu mobil terbalik":

- **`0x5053f4` (stuck) — kandidat #1.** Skenario persisnya: kepala kena tanah →
  mobil terbalik → roda tidak menyentuh tanah dengan kecepatan < 1,0 m/s →
  timer `[car+0x860]` terus naik melewati ambang `[car+0x864]` → flag set.
  Disassembly lengkap fungsi stuck (`0x505340–0x50543c`) terkonfirmasi di REA-2:
  `[car+0x31c]` = bitmask kontak; bila ada kontak, `[car+0x3a0]` di-nol-kan dan
  posisi-X chassis disimpan di `[car+0x3a4]`; bila tidak ada kontak,
  `[car+0x3a0]++`; kecepatan dihitung dari `[chassis+0x50]`/`[+0x54]`
  (`sqrt(vx²+vy²)`); bila speed > 1,0 → timer di-reset; bila timer melewati
  ambang → `strb` di `0x5053f4` (byte `68 be 0c 39`); di akhir fungsi,
  `[car+0x7b0]`/`[car+0x7b8]` di-nol-kan dan `[car+0x31c]` di-clear.
- **`0x50e570` (detachment) — kandidat #2.** Saat kepala/body terlepas > 1,0
  dari titik acuannya (mis. driver terlempar dari jok saat benturan), flag set.
  Ini jalur yang secara harfiah berarti "driver lepas".
- **`0x4efae4` (fall) — kandidat #3** bila mobil jatuh keluar dunia (< −100).
  Dua `strb` di fungsi ini terkonfirmasi (`0x4efae4` dan `0x4efb18`, keduanya
  byte `68 be 0c 39`); fungsi juga me-nol-kan `[car+0x3a0]` di `0x4efae8`/`0x4efb1c`.

### 2.2 Jalur timer paralel — vehicle flag `[x+0x266]` (TIDAK di-NOP v4)

Vehicle flag punya **6 akses di seluruh binary** — 3 penulis, 1 bulk-copy, 2 pembaca:

| Alamat | Jenis | Isi |
|---|---|---|
| `0x3b0de0` | penulis | `strb w9, [x19, #0x266]` (byte `69 9a 09 39`) — cabang GOAL contact handler |
| `0x3b0ff4` | penulis | `strb w9, [x19, #0x266]` (byte `69 9a 09 39`) — cabang `0x100` contact handler |
| `0x3b175c` | penulis | `strb w8, [x0, #0x266]` (byte `08 98 09 39`) — setter `0x3b1758`, 9 caller |
| `0x6aa068` | bulk-copy | fungsi salin state (bukan setter kematian — menyalin banyak byte sekaligus, termasuk `+0x266`) |
| `0x3ad720` | pembaca | di fungsi situs B |
| `0x3af088` | pembaca | fungsi slot pembaca |

**Jalur timer paralel (`0x3c76d8`):** bila state `[x26]==0x25`/`0x2b` DAN
`[vehicle+0x266]` set → timer `[run+0x62c]` += dt, store di **`0x3c76fc`**
(byte `60 2e 06 bd`, `str s0, [x19, #0x62c]`) → > 4,0 dtk → `bl 0x3c2c0c`
(end-run helper, 7 caller: `0x3c72ec`, `0x3c7518`, `0x3c76ac`, `0x3c7708`,
`0x3c7960`, `0x3c9774`, `0x3ca8e0`). **Store timer ketiga ini TIDAK di-NOP
oleh v2** (v2 hanya NOP `0x3c7748` + `0x3c77d4`). Artinya: begitu vehicle flag
ter-set (mis. lewat contact handler yang tidak di-NOP), ada jalur timer kedua
menuju end-run yang tidak ditahan v2 — meski jalur ini hanya aktif di state
`0x25`/`0x2b` (bukan state mengemudi normal), ia tetap lubang di god mode.

### 2.3 Slot vtable `0xb8` (`0x4f78e8`) — KOREKSI: bukan "driver lepas"

Laporan death pertama menyebut slot ini "driver lepas/mati". Disassembly penuh
REA-2 mengubah pemahaman ini:

```
0x4f78e8: (slot 0xb8)
0x4f78f4: ldrb w8, [x0, #0x4f7]     ; guard "sudah diproses"
0x4f78fc: cbnz w8, ret               ; bila sudah 1 → return
0x4f7904: slot 0xa8 = ([car+0x3a0] > 0)   ; counter airborne
0x4f790c: tbnz w0, #0, ret           ; bila airborne (>0) → return
0x4f7918: slot 0xa0 = predikat mati  ; baca flag
0x4f7920: tbnz w0, #0, ret           ; bila mati → return
0x4f7924: ... panggil slot 0x138 (0x4eed54) pada chassis ...
0x4f7928: (impuls rotasi 2D ke body chassis, field +0xc/+0x3c/+0x50/+0x58/+0xa4/+0xac/+0xd8)
0x4f79xx: nol-kan angular velocity; set [car+0x4f7]=1
```

Slot ini fire **hanya bila: belum diproses + SEDANG KONTAK (`[car+0x3a0]==0`) +
HIDUP**. Itu kondisi "mendarat / bersentuhan pertama kali", bukan "driver lepas".
Slot `0x138` yang dipanggilnya (`0x4eed54`, helper rekursif `0x4eeca0`) adalah
**"kumpulkan semua body yang terikat ke chassis + jumlahkan massanya ke
`[car+0x414]`"** (walk pohon body via `[x+0x90]`/`[x+0x18]`, simpan list di
`[car+0x520]`/`[car+0x528]`). Jadi slot `0xb8` kemungkinan besar adalah
**handler landing/impact** (sekali per pendaratan; guard di-reset oleh fungsi
situs B di `0x3ad414` saat `[car+0x294] > [car+0x184]`). Identitas pastinya
**belum terbukti** — tapi yang pasti: ini BUKAN mekanisme penghancur driver.
Dipanggil HANYA via vtable (0 `bl` langsung); scan pola `ldr [x,#0xb8]`+`blr`
menemukan ~290 situs (sebagian besar bukan PlayerCar — offset vtable umum).

### 2.4 `[car+0x3a0]` — counter frame tanpa kontak ("airborne"), bukan "timer mati"

- Init **6** di constructor.
- Di-nol-kan saat ada kontak: fungsi stuck `0x505390`, fungsi fall `0x4efae8` /
  `0x4efb1c`, `0x4fb368`, ekor contact handler `0x3b1858` / `0x3b187c`.
- Di-increment saat TIDAK ada kontak: `0x5053fc–0x505404` (`[car+0x3a0]++`).
- Pembaca: slot `0xa8` (`[car+0x3a0] > 0` = "sedang airborne"), dan
  flip-assist: `0x50f564` (hanya bila hidup DAN `[car+0x3a0] >= 6`),
  `0x50f8b0` (hanya bila hidup DAN `[car+0x3a0] >= 1`).

### 2.5 `[car+0x519]` — gate kedua yang belum terpetakan maknanya

Byte `[car+0x519]` dibaca di **11 situs** (`0x4f65e4`, `0x503474`, `0x50a6a4`,
`0x5161a4`, `0x5163e8`, `0x516b18`, `0x524f14`, `0x557cc4`, `0x5608dc`,
`0x5665f0`, `0x577b18`) — semuanya fungsi update per-mobil. Ia menjadi gate
kedua di kedua jalur penghancur driver (§3.2–3.3): destroy hanya jalan bila
`[car+0x519]==0`. Makna pastinya (mungkin "sudah di-cleanup" / "kendaraan
sedang di-reset" / "driver sudah terpasang") **tidak bisa dipastikan dari
disassembly statis** — perlu probe runtime.

---

## 3. Pembaca flag — mekanisme "mati" yang sebenarnya

### 3.1 Fakta kunci: predikat ≠ byte flag

Predikat mati (`0x3b2f94` → trampolin → slot vtable `0xa0` → implementasi
`0x4f78c8`: `ldrb w0, [x0, #0x32f]; ret`) adalah **sebuah fungsi**. God mode v3
mem-patch fungsi ini agar selalu mengembalikan 0 ("hidup"). Yang lewat predikat
hanyalah **12 caller trampolin** (dipetakan di laporan death).

Tapi ada **32 pembaca `ldrb [x,#0x32f]`** yang membaca byte flag **langsung**,
tanpa lewat predikat — dan mereka TIDAK terpengaruh v3 sama sekali:

```
0x4ef4bc  0x4efaec  0x4efe54  0x4f015c  0x4f0520  0x4f4bb8  0x4f4bcc  0x4f66e0
0x4f6754  0x4f78c8  0x4fafd4  0x4fb4d4  0x505b2c  0x505b70  0x50c770  0x50c7b4
0x50de04  0x50e8a8  0x50f564  0x50f8b0  0x510e00  0x5176a8  0x5176ec  0x524f0c
0x525860  0x5258a4  0x531a58  0x53ee44  0x560970  0x560b3c  0x56ec70  0x56ec80
```

Begitu flag ter-set oleh 12 situs non-v4 (§2.1), ke-31 pembaca langsung ini
tetap melihat "mati" — sementara 12 caller predikat (termasuk cabang timer
game-over) melihat "hidup". **Inilah celah arsitektural god mode v2/v3/v4:**
game-over screen ditahan, tapi dunia fisika sudah menganggap driver mati.

### 3.2 Pembaca `0x524f0c` — KANDIDAT UTAMA: DestroyBody tiga body driver

Disassembly blok (`0x524ee0–0x524f7c`, fungsi update per-mobil `0x524xxx`):

```
0x524f0c: ldrb w8, [x19, #0x32f]     ; byte flag — byte asli 68 be 4c 39
0x524f10: cbz w8, #0x524f80           ; bila hidup → lewati semua — byte 88 03 00 34
0x524f14: ldrb w8, [x19, #0x519]     ; gate kedua — byte 68 66 54 39
0x524f18: cbnz w8, #0x524f80          ; bila [car+0x519]!=0 → lewati — byte 48 03 00 35
0x524f1c: ldr x1, [x19, #0x840]
0x524f20: cbz x1, #0x524f30
0x524f24: ldr x0, [x19, #0x2b8]      ; world
0x524f28: bl #0x6d20c0               ; DestroyBody([car+0x840]) — byte 66 b4 06 94
0x524f2c: str xzr, [x19, #0x840]     ; null-kan — byte 7f 22 04 f9
0x524f30: ldr x1, [x19, #0x848]
0x524f34: cbz x1, #0x524f44
0x524f38: ldr x0, [x19, #0x2b8]
0x524f3c: bl #0x6d20c0               ; DestroyBody([car+0x848]) — byte 61 b4 06 94
0x524f40: str xzr, [x19, #0x848]     ; byte 7f 26 04 f9
0x524f44: ldr x1, [x19, #0x858]
0x524f48: cbz x1, #0x524f58
0x524f4c: ldr x0, [x19, #0x2b8]
0x524f50: bl #0x6d20c0               ; DestroyBody([car+0x858]) — byte 5c b4 06 94
0x524f54: str xzr, [x19, #0x858]     ; byte 7f 2e 04 f9
0x524f58: ... (lanjut: memanggil 0x6d0f64 dengan objek [car+0x850] — kemungkinan
         spawn efek/suara kematian; bukan penghancur)
```

**Inilah "mati" yang dilihat user.** Tiga body di `[car+0x840]` / `[car+0x848]` /
`[car+0x858]` dihancurkan dari dunia Box2D dan pointer-nya di-null-kan.
Body-body ini ditulis di banyak situs (23/27/18 situs `str x` — dibuat di
fungsi-fungsi per-mobil, mis. `0x5249e8`/`0x524a18`/`0x524a48` di fungsi yang
sama, `0x34f328`, `0x5028ac`, `0x5034dc`, `0x50c9f8`, `0x512c58`, `0x521898`,
`0x526868`, `0x528850`, `0x52bcb0`, `0x53dd34`, …) — **situs pembuatan persisnya
belum teridentifikasi** (belum ketemu constructor-nya), tapi dari konteksnya
(body driver yang dibuat per jenis kendaraan, dihancurkan saat mati, di-null-kan
setelahnya) identifikasi sebagai **body-body driver** adalah inferensi kuat.
Fungsi `0x6d20c0` sendiri terkonfirmasi sebagai DestroyBody (dipakai di
~30 tempat untuk menghancurkan body, selalu dengan argumen world `[x+0x2b8]`).

### 3.3 Pembaca `0x560970` — detach joint kepala + joint kendaraan

Disassembly blok (`0x5608c0–0x5609dc`, fungsi cleanup per-mobil):

```
0x5608dc: ldrb w8, [x19, #0x519]
0x5608e0: cbnz w8, #0x560970          ; bila [car+0x519]!=0 → lewati blok destroy
0x5608e4: ldr x1, [x19, #0x310]  → DestroyBody + null
0x5608f8: ldr x1, [x19, #0x308]  → DestroyBody + null
0x56090c: ldr x1, [x19, #0x828]  → DestroyBody + null
0x560914: ldr x1, [x19, #0x838]  → DestroyBody + null
0x560930: ldr x1, [x19, #0x840]  → DestroyBody + null   ; bl di 0x560938
0x560944: ldr x1, [x19, #0x848]  → DestroyBody + null   ; bl di 0x56094c
0x560960: ldr x0, [x19, #0x300]
0x56096c: bl #0x6cca64               ; (operasi pada objek [car+0x300])
0x560970: ldrb w8, [x19, #0x32f]     ; byte flag — byte asli 68 be 4c 39
0x560974: cbz w8, #0x560a00           ; bila hidup → lewati — byte 68 04 00 34
0x560978: ldr x0, [x19, #0x788]
0x56097c: cbz x0, #0x560a00
0x560980: ldr x8, [x0] ; ldr x8, [x8, #0x28] ; blr x8   ; slot 0x28
0x56098c: cmp w0, #2
0x560990: b.lt #0x560a00
0x560994: ldr x0, [x19, #0x788]
0x560998: ldr x8, [x0] ; ldr x8, [x8, #0x110] ; blr x8  ; slot 0x110 (get joint)
0x5609a4: ldr x8, [x0]
0x5609a8: ldr x1, [x19, #0x788]
0x5609ac: mov w2, #1
0x5609b0: ldr x8, [x8, #0x200] ; blr x8                  ; slot 0x200 = destroy joint
0x5609b8: ldr x0, [x19, #0x2d0]                          ; KEPALA
0x5609bc: ldr x8, [x0] ; ldr x8, [x8, #0x110] ; blr x8
0x5609c8: ldr x8, [x0]
0x5609cc: ldr x1, [x19, #0x2d0]
0x5609d0: mov w2, #1
0x5609d4: ldr x8, [x8, #0x200] ; blr x8                  ; destroy joint kepala
```

Begitu flag set: joint pada `[car+0x788]` dan joint pada **kepala
`[car+0x2d0]`** dihancurkan (slot `0x200`, `w2=1`). Kepala terlepas dari
kendaraan. Fungsi yang sama juga menghancurkan body `[car+0x310]` /
`[car+0x308]` / `[car+0x828]` / `[car+0x838]` / `[car+0x840]` / `[car+0x848]`
(bila `[car+0x519]==0`) — ini fungsi cleanup/teardown per-mobil yang berjalan
saat run berakhir atau kendaraan di-remove; gabungan keduanya berarti: saat
flag set, driver dihancurkan DAN dilepas.

### 3.4 Pembaca lain yang mengubah perilaku kendaraan saat flag set

| Alamat | Efek saat flag set |
|---|---|
| `0x505b2c`, `0x50c770`, `0x5176a8`, `0x525860` (getter posisi) + `0x505b70`, `0x50c7b4`, `0x5176ec`, `0x5258a4` (getter kecepatan) | Body yang dilacak diganti dari chassis/kepala ke `[car+0x2e8]` atau `[car+0x858]`/`[car+0x860]` — **kamera/game melacak bagian yang jatuh, bukan chassis**. Ini menjelaskan gejala "mobil jadi tidak bisa dikendarai / kamera mengikuti sesuatu yang jatuh". |
| `0x50f564`, `0x50f8b0` | Flip-assist (impuls angular) HANYA bila hidup DAN `[car+0x3a0] >= 6` / `>= 1` — saat mati, **tidak ada bantuan flip**; mobil terbalik tetap terbalik. |
| `0x531a58` | Logika achievement neckflip HANYA bila hidup. |
| `0x4f66e0`, `0x4f6754` | `[car+0x408] = (flag==0)`; bila flag set → `bl 0x3c6300`. |
| `0x3c7f68`, `0x3c8070` | Efek kematian (partikel via `bl 0x5e1de0`, konstanta float dari tabel `0x1ff038` dipilih `[run+0x650]`, latch `[run+0x5a0]`) — TAPI kedua blok ini memanggil **predikat** (`bl 0x3b2f94`), jadi **TIDAK fire bila v3 aktif**. Inilah satu-satunya bagian "kematian visual" yang berhasil ditahan v3. |
| `0x4ef4bc`, `0x4efe54`, `0x4f015c`, `0x4f0520`, `0x4f4bb8`, `0x4f4bcc`, `0x4fafd4`, `0x4fb4d4`, `0x50de04`, `0x50e8a8`, `0x510e00`, `0x53ee44`, `0x560b3c`, `0x56ec70`, `0x56ec80` | Pembaca langsung lain (konteks belum dipetakan satu-satu — sebagian di fungsi UI/AI/kamera; tidak ada yang memanggil DestroyBody selain §3.2–3.3). |

### 3.5 Rangkaian kejadian lengkap saat "kepala kena tanah" (god ON)

1. Kepala menyentuh tanah → situs B/C **sudah di-NOP** → flag TIDAK ter-set dari sini. ✓
2. Tapi benturan membuat mobil terbalik dan/atau driver terlempar:
   - Mobil terbalik + diam (speed < 1,0) + masih kontak → timer stuck
     `[car+0x860]` naik → **`0x5053f4` set flag**. (Paling mungkin.)
   - Atau driver terlepas > 1,0 dari titik acuan → **`0x50e570` set flag**.
   - Atau akumulator `[run+0x5f8]` mencapai 100 → **`0x3d488c` set flag**.
3. Flag set → **v3 (predikat) menahan cabang timer game-over** → layar game over
   tidak muncul. ✓ (inilah yang user lihat: "screen game over ketahan")
4. Tapi **pembaca langsung `0x524f0c`** melihat flag → **DestroyBody 3 body
   driver** → driver hilang dari dunia fisika. Dan **`0x560970`** → **joint
   kepala di-destroy** → kepala terlepas.
5. Getter posisi/kecepatan beralih melacak bagian yang jatuh; flip-assist mati.
   **Kendaraan tidak bisa digas/dikendarai lagi** — inilah "tetep bisa mati".

**Catatan kejujuran:** urutan persis langkah 2 (jalur mana yang fire duluan di
tes user) belum bisa dipastikan dari statis — butuh probe runtime (§8). Yang
terbukti dari disassembly adalah: flag BISA ter-set oleh 12 situs lain, dan
begitu ter-set, DestroyBody + detach joint PASTI berjalan meski v2/v3/v4 aktif.

---

## 4. Istilah Inggris game untuk benturan / kematian

Pencarian string di `libgame.so` 1.72.2 (`.rodata`) + `assets/translations/en.po`
(7605 baris, 1.72.2; 7419 baris di 1.71.1) untuk: hit, damage, dead, death, kill,
destroy, detach, fall, driver, ragdoll, gameover, crash, hurt, injure.

### 4.1 Istilah yang dipakai game (terkonfirmasi)

| Istilah (Inggris) | Arti di game | Sumber |
|---|---|---|
| **DRIVER DOWN** | **Teks saat game berakhir karena kepala driver kena sesuatu.** Komentar `.po`-nya persis: *"Text displayed when the game ends because the driver's head has hit something"* | `en.po` baris 2144–2147, `#: src/common/GameLayer.cpp`; string di `.rodata` 1.72.2: `0x1cbac0`, `0x1ce8ea`, `0x1d8953` |
| **DRIVER DOWN & OUT OF FUEL** | Driver down + bahan bakar habis bersamaan | `en.po` baris 2150–2154, `GameLayer.cpp` |
| **DRIVER DOWN!!** | Varian di stage Pinball | `en.po` baris 2156–2158, `#: src/common/PinballScene.cpp` |
| **OUT OF FUEL** | Bahan bakar habis | `.rodata`: `0x1ce8fb`, `0x1f7a15` |
| **NECK FLIP** | Flip yang mematahkan leher driver — achievement (bukan teks kematian langsung) | `.rodata`: `0x1da13f`, `0x1f246e`, `0x1f9396` |
| **GAME OVER!** | Layar akhir run | `.rodata`: `0x1f7e9b` |
| **GOAL !!** | Gol tercapai (stage ballsports) — **ini yang ditampilkan cabang situs A** | `en.po` baris 3010–3012, `#: src/common/GameContentLayer.cpp`; string situs A di `0x1d29e7` |
| **GOAL REACHED !!** | Gol tercapai (varian) | `en.po` baris 3014–3016, `#: src/common/GameLayer.cpp` |
| **JUMP FAILED!!** | Lompat gagal (string di dekat situs B) | `.rodata`: `0x1f671e` |
| **CANNON LOST!!** | Meriam hilang (string di dekat situs switch) | `.rodata`: `0x1f1115` |
| **HIT** / **RAT HIT!** / **TARGET HIT** | "Hit" untuk tabrakan/kena target di stage (bukan istilah kematian driver) | `en.po` (berbagai stage) |
| **ROLL CAGE** | Upgrade: *"Improved roll cage material can take more damage before breaking."* | `en.po`, `#: src/common/PlayerCarManager.cpp` — satu-satunya pemakaian kata "damage" yang terkait driver/kendaraan |

**Jawaban untuk dugaan user ("kek ke hit gitu dalam bahasa inggris apa gitu"):**
game ini tidak memakai kata "hit" untuk kematian kepala. Istilahnya adalah
**"DRIVER DOWN"** — dan teks itu muncul saat game berakhir karena kepala driver
kena sesuatu. Kata "damage" hanya muncul di deskripsi upgrade ROLL CAGE.
**Tidak ada kata "ragdoll" di string game** (dan tidak ada class Driver/Head/
Ragdoll di RTTI — driver = 2–3 body fisika biasa, lihat §5.4).

### 4.2 Xref string → fungsi (yang relevan)

- `"DRIVER DOWN"` (`0x1cbac0`/`0x1ce8ea`/`0x1d8953`): dipakai logika penampil
  alasan game-over di `GameLayer.cpp` — dibaca bila flag mati set (lewat
  predikat/trampolin, jadi **tertahan v3** — konsisten dengan laporan user:
  layar game over tidak muncul).
- `"GOAL !!"` (`0x1d29e7`): dipakai contact handler situs A (`0x3b0ddc`).
- `"JUMP FAILED!!"` (`0x1f671e`): dipakai fungsi situs B (`0x3adxxx`).
- `"CANNON LOST!!"` (`0x1f1115`): dipakai fungsi situs switch (`0x3ab7xx`).
- Fungsi lookup string/gettext `0x43fe9c`: **1874 caller** (dipakai di mana-mana).
- Fungsi `0x67e27c` (dipanggil contact handler cabang `0x100`): 209 caller.

---

## 5. Inventory SELURUH file APK HCR 1.72.2 (bukan cuma libgame.so)

### 5.1 Perolehan APK lengkap

- API APKPure terverifikasi (`api.pureapk.com/m/v3/cms/app_version`,
  header `x-sv: 29`, `x-abis: arm64-v8a,armeabi-v7a,armeabi`, `x-gp: 1`)
  mengembalikan daftar versi (protobuf, 523.603 B) — berisi **1.72.2 (code 936)**
  dan versi terbaru 1.73.3 (code 10222).
- URL XAPK 1.72.2 (signed, `vc=936`, ukuran `s=163680584`):
  [tautan unduhan bertanda tangan — disensor; minta ke Alyaa bila perlu]
  (parameter lengkap tidak diarsipkan).
- **Unduhan BERHASIL: `work/hcr-1.72.2.xapk`, 163.680.584 B (persis sesuai
  metadata), SHA-256 `f6a6a43fd7b00a2a149b77eb12577b986b84ee4fe3ea741850f6684c700e194c`.**
- Isi XAPK (22 file): `com.fingersoft.hillclimb.apk` (base, 158.979.725 B,
  SHA-256 `1c86306307921121450379856bc4ee9f98511cf5db97fc668db8e58baa1b92cc`),
  `config.armeabi_v7a.apk`, 18 split locale (`config.en/de/fr/...apk`),
  `config.mdpi.apk`, `icon.png`, `manifest.json`.
- **Verifikasi silang:** `libgame.so` arm64 dari split resmi =
  SHA-256 `307f6b87dfae712a0496fb4396ff56682bde50350744789dd1875d7d74d77a49` —
  **identik** dengan binary yang dianalisis di `~/workspace/hcrx-1.72.2/`.
  Semua offset di laporan ini adalah offset binary resmi 1.72.2.

### 5.2 Native libraries (`.so`) — semua logika game di libgame.so

Base APK **tidak punya** direktori `lib/` (App Bundle: native lib ada di split).
Split `config.arm64_v8a.apk` berisi 7 file `.so` saja:

| File | Peran |
|---|---|
| `lib/arm64-v8a/libgame.so` (8,8 MB) | **SELURUH logika game** (termasuk engine cocos2d-x yang di-link statis — TIDAK ada `libcocos2dcpp.so` terpisah di 1.72.2; juga tidak ada `libc++_shared.so` terpisah) |
| `lib/arm64-v8a/libcrashlytics.so` + `libcrashlytics-common.so` + `libcrashlytics-handler.so` + `libcrashlytics-trampoline.so` | Firebase Crashlytics (pelaporan crash) |
| `lib/arm64-v8a/libapplovin-native-crash-reporter.so` | Pelaporan crash AppLovin |
| `lib/arm64-v8a/libdatastore_shared_counter.so` | Counter DataStore (AndroidX) |

Split `config.armeabi_v7a.apk` berisi set yang sama untuk 32-bit (libgame.so
32-bit SHA-256 `0c586ab930f3bae64eaf3fe14e9f3477e6373bc42a22b81cf761050a3a6f7aaf` —
**tidak dianalisis**; POCO user 64-bit-only, yang relevan hanya arm64).
**Kesimpulan: tidak ada `.so` lain yang berisi logika game.** Semua mekanisme
kematian/damage/driver ada di `libgame.so`.

### 5.3 Aset base APK — 2391 file (1.72.2) vs 1.71.1

| Ekstensi | Jumlah (1.72.2) | Isi |
|---|---|---|
| `.png` | 1827 | Sprite, atlas, UI, stage |
| `.ogg` | 150 | Audio (musik + SFX, termasuk `8bit-gameover.ogg`) |
| `.json` | 146 | Definisi stage/kendaraan/fisika (RUBE) |
| `.po` | 73 | Terjemahan (termasuk `en.po` 7605 baris) |
| `.plist` | 71 | Efek partikel (api, asap, debu, dll) |
| `.fsh` / `.vsh` | 35 / 33 | Shader OpenGL |
| `.jpg` | 20 | Atlas/gambar |
| `.js` | 9 | **HANYA SDK iklan**: OMID (`omid-session-client-v1.js`, `omsdk-v1.js`), MRAID (`mraid.js`, `mraid-bridge.js`, `com.moloco.sdk.xenoss.sdkdevkit.mraid.js`), HelpShift (`Helpcenter.js`, `Webchat.js`), iAds (`index.js`, `sdk_controller.min.gz.js`) — **BUKAN logika game** |
| `.html` / `.css` / `.txt` / `.xml` / `.fnt` / `.ico` / `.gif` | 6 / 2 / 5 / 2 / 2 / 1 / 1 | Halaman bantuan/iklan, font, credit |
| `.rube` | 1 | `garage_physics.json` (fisika garasi, format RUBE) |
| `.dex` (di `assets/audience_network/`) | 2 | `classes.dex` + `classes2.dex` milik SDK iklan Audience Network |
| `.prof` / `.profm` | 1 / 1 | Profil ART |

**Tidak ada file Lua, tidak ada script game, tidak ada bytecode logika game di
aset.** Semua logika (termasuk kematian) ada di `libgame.so`. File-file data
yang relevan dengan kematian/driver:

- **`assets/vehicles/boringcar_model.json`** (dan `badcar_model.json`,
  `fastbike_model.json`, `projectcar_model.json`, `ufo_model.json`, …):
  definisi kendaraan (RUBE): `body` (chassis, roda, `driver-body`,
  `driver-head`), `joint` (`driverHeadJoint`, `torsoHeadDistanceJoint`,
  `frontSpring`, `rearSpring`, …), `image` (`Resources/driver-head.png`,
  nama `driver-head`, scale 0,96). **Driver dimodelkan sebagai body terpisah
  (kepala + torso) yang di-joint ke chassis** — cocok dengan disassembly
  (driver = 2–3 body: `[car+0x2d0]` kepala, `[car+0x2d8]` chassis,
  `[car+0x2e0]`/`[car+0x2e8]` lain).
- **`assets/vehicles/modifier_props.json`** (RUBE): body `driverHead` —
  circle radius 0,33, density 0,01, friction 0,75,
  **`filter-maskBits: 65534` (0xFFFE), TANPA `filter-categoryBits`** → category
  default Box2D = **1 (0x0001)**. Posisi (−0,3377, 0,8989), angle π, type 2
  (dynamic), massa 0,0034. **Ini bukti data-file bahwa kepala BUKAN kategori
  `0x10000`** — mendukung koreksi §1.1/§6. (Fixture lain: `fixture1`
  categoryBits 64 = 0x40, maskBits 65534.)
- **`assets/garage/garage_physics.json`** (RUBE): fisika garasi (assembly
  kendaraan: `engine_v8` dll, `collisionbitplanes`) — BUKAN definisi
  kategori kematian; tidak relevan dengan flag mati.
- **`assets/stages/party/ballsports/goal.json`** (RUBE): objek GOAL stage
  ballsports — sensor fixture (`"sensor": true`), `filter-categoryBits: 64`,
  `filter-maskBits: 65534`, `attachBody: true`, `useInGame: true`. Objek inilah
  yang memicu cabang `"GOAL !!"` di contact handler (situs A).
- **`assets/translations/en.po`** (7605 baris): semua string UI termasuk
  `"DRIVER DOWN"`, `"GOAL !!"`, `"NECK FLIP"`, `"ROLL CAGE"` (lihat §4).
- **`assets/stages/*/`**: definisi tiap stage (terrain, objek, hazard,
  kill-zone) — kill-zone/hazard di §2.1 merujuk ke objek-objek stage ini
  (koordinat kotak bahaya dibaca dari objek stage, bukan dari konstanta di
  binary).

### 5.4 Box2D — terkonfirmasi ADA (koreksi lama sudah benar)

RTTI di `libgame.so` mengenal: `b2ChainShape`, `b2CircleShape`,
`b2PolygonShape`, joint, `b2ContactListener`, `b2ParticleSystem`. Contact
handler `0x4f4b68` diduga `BeginContact`. Motor roda = joint motor Box2D
(sudah dipetakan di REA speed). **Tidak ada struktur tulang/ragdoll bernama**
(RTTI tidak mengenal Driver/Head/Ragdoll) — driver = body fisika biasa.

---

## 6. Koreksi terhadap laporan death pertama (`rea-hcr-death/REPORT.md`)

| # | Klaim lama | Koreksi REA-2 | Bukti |
|---|---|---|---|
| 1 | Situs A (`0x3b0ddc`): "kontak kategori `0x10000`" = **kepala kena tanah** (kandidat utama) | **SALAH.** Kategori `0x10000` = fixture **GOAL** stage ballsports. Cabang itu menampilkan `"GOAL !!"` + latch + analitik. | Teks `0x1d29e7` = `"GOAL !!"` (`en.po` 3010–3012, `GameContentLayer.cpp`); `goal.json` ada; fixture kepala berkategori default 1 (§5.3). Laporan death sendiri sudah memberi hedge ("belum dipastikan milik kepala vs tanah") — kini terjawab: bukan kepala. |
| 2 | `[run+0x624]` = "resource ke-2 / udara" (100,0, timer 4 dtk) | **SALAH — sudah dikoreksi REA speed: `[run+0x624]` adalah FUEL** (drain `dt×2,5×throttle×rate` di `0x3c9470–0x3c94b0`). | REA speed (`rea-hcr-speed/REPORT.md`). |
| 3 | Slot vtable `0xb8` (`0x4f78e8`) = "driver lepas/mati" | **SALAH / tidak terbukti.** Slot fire hanya saat kontak + hidup + belum diproses; memanggil slot `0x138` (kumpulkan body terikat + jumlah massa) lalu memberi impuls rotasi ke chassis. Kemungkinan besar **handler landing/impact**, bukan penghancur driver. | Disassembly penuh §2.3. |
| 4 | `0x6aa068` = setter ke-6 vehicle flag `[x+0x266]` | **Bukan setter kematian** — fungsi bulk-copy state (menyalin banyak byte sekaligus, termasuk `+0x266`). | Disassembly `0x6aa068` (copy byte dari `[x0+0x168..0x16b]` ke banyak offset). |
| 5 | `[car+0x3a0]` = "counter" (konteks kabur) | **Dipastikan: counter frame TANPA kontak (airborne).** Init 6; nol saat kontak; ++ saat tanpa kontak; gate flip-assist & slot `0xb8`. | Disassembly §2.4. |
| 6 | Getter slot `0x70` (`0x4f4b30`) = "getter sudut" (PROBE.md) | **SALAH — getter POSISI** (sudah dikoreksi REA speed). | REA speed. |
| 7 | Fungsi `0x4f0c88` = motor | **SALAH — pengendali partikel debu roda** (`CCParticleSystemQuad`, nilai 20/25/60 = partikel/detik). | REA speed. |
| 8 | Jumlah setter flag = 15 | **15 terkonfirmasi, tapi fungsi fall punya 2 `strb`** (`0x4efae4` + `0x4efb18` — yang kedua praktis tidak pernah fire karena slot Stage `0x350` selalu false di base class). Hitungan "15 situs" tetap benar sebagai jumlah *fungsi pemicu*; jumlah *instruksi* `strb` adalah 16. | Disassembly `0x4efa70–0x4efb60` (§2.1). |
| 9 | Flag `[car+0x32f]` = "flag mati" (semata) | **Lebih tepat: "run berakhir".** Flag di-set juga oleh event GOAL (bukan kematian) dan dibaca 32 tempat termasuk UI/kamera/AI. Nama "death flag" tetap dipakai di laporan ini demi konsistensi, tapi maknanya lebih luas. | §1.1, §3.1. |
| 10 | "Predikat hanya baca flag" (implikasi: patch predikat = god mode penuh) | **Tidak cukup.** Predikat hanya dipakai 12 caller; 31 pembaca langsung (`ldrb`) tidak lewat predikat — merekalah yang menghancurkan driver (§3). Laporan death baris 413 sudah memperingatkan risiko ini ("driver bisa tampak lepas/mati secara visual sementara kendaraan tetap jalan") — REA-2 membuktikan mekanismenya. | §3.1–3.3. |

**Koreksi teknis disassembly (berlaku umum):** target branch AArch64 =
`PC + imm×4`, dengan PC = alamat instruksi branch itu sendiri (tanpa +4).
Scan `bl_callers` awal yang memakai `off+4` menghasilkan 0 caller (salah);
setelah dikoreksi, hasilnya benar (mis. setter `0x3b1758` = 9 caller,
`0x3b7c70` = 4 caller, query `0x3a5a94` = 19 caller, gettext `0x43fe9c` =
1874 caller).

---

## 7. Kandidat patch baru (libgame.so 1.72.2 — offset = alamat VA, sama seperti pattern-scan v4)

Semua patch di bawah memakai NOP 4 byte `1f 20 03 d5` (kecuali dinyatakan lain).
**Urutan yang disarankan: P0 dulu (paling langsung menutup "mati"-nya), lalu
tambah P3 bila perlu; P1 adalah alternatif yang lebih invasif. Semua kandidat
MASIH BUTUH konfirmasi runtime** — belum ada yang terbukti di POCO.

### P0 — Lumpuhkan efek penghancur driver (REKOMENDASI UTAMA)

Targetnya bukan flag-nya, melainkan **akibat** flag: DestroyBody + detach joint.
Keuntungan: apa pun yang men-set flag (12 situs tersisa, bahkan situs yang
belum terpetakan), driver tidak pernah dihancurkan/dilepas. Game-over screen
tetap ditahan v2/v3.

| Sub-kandidat | Alamat | Byte asli | Patch | Efek yang diharapkan |
|---|---|---|---|---|
| P0a | `0x524f10` | `88 03 00 34` (`cbz w8, #0x524f80`) | ganti jadi `b #0x524f80` — byte `1c 00 00 14` (nilai `0x1400001C`, terverifikasi: imm26 = (0x524f80−0x524f10)/4 = 28); atau NOP-kan tiga `bl 0x6d20c0` di `0x524f28`/`0x524f3c`/`0x524f50` menjadi `1f 20 03 d5` + NOP-kan tiga `str xzr` nulling di `0x524f2c`/`0x524f40`/`0x524f54` | Blok DestroyBody 3 body driver tidak pernah jalan; pointer `[car+0x840]`/`[car+0x848]`/`[car+0x858]` tetap hidup. **Paling surgical: NOP 3× `bl` saja sudah cukup** (body tidak dihancurkan; nulling tanpa destroy hanya men-null-kan pointer lokal — tapi nulling itu sendiri harus ikut di-NOP, kalau tidak pointer hilang meski body masih ada). |
| P0b | `0x560974` | `68 04 00 34` (`cbz w8, #0x560a00`) | ganti jadi lompat selalu ke `0x560a00` — byte `23 00 00 14` (nilai `0x14000023`, terverifikasi: imm26 = (0x560a00−0x560974)/4 = 35) ATAU NOP-kan dua `blr` slot `0x200` (di `0x5609b4` dan `0x5609d8` — instruksi `blr` didahului `ldr x8, [x8, #0x200]` di `0x5609b0`/`0x5609d4`, byte `08 01 41 f9`) | Joint `[car+0x788]` dan joint kepala `[car+0x2d0]` tidak pernah di-destroy; kepala tetap menempel. |

**Catatan P0a:** encoding `b` sudah terverifikasi di atas (`0x1400001C` /
byte `1c 00 00 14` untuk lompat `0x524f10`→`0x524f80`; `0x14000023` / byte
`23 00 00 14` untuk `0x560974`→`0x560a00`) — tetap verifikasi ulang dengan
disassembler saat build (simulasi scan seperti v1.7).
**Catatan P0b:** fungsi `0x5608xx` juga menghancurkan body `[car+0x310]` /
`[car+0x308]` / `[car+0x828]` / `[car+0x838]` / `[car+0x840]` / `[car+0x848]`
saat `[car+0x519]==0` — itu blok cleanup yang berjalan saat run berakhir /
kendaraan di-remove. Bila P0a saja sudah cukup, P0b opsional; bila driver
masih "lepas" setelah P0a, tambahkan P0b.

### P1 — NOP ke-12 situs setter tersisa (tutup flag dari sumbernya)

| Alamat | Byte asli | Konteks |
|---|---|---|
| `0x5053f4` | `68 be 0c 39` | stuck BadCar (terbalik diam) |
| `0x50bfbc` | *(baca ulang sebelum pakai — belum dibaca di REA-2)* | stuck mobil lain |
| `0x4efae4` | `68 be 0c 39` | fall < −100 |
| `0x4efb18` | `68 be 0c 39` | fall, slot `0x350` (praktis tidak fire) |
| `0x50e570` | `68 be 0c 39` | detachment > 1,0 |
| `0x3d488c` | `09 bd 0c 39` | akumulator ≥ 100 |
| `0x4c9dfc` | `09 bd 0c 39` | kill-zone |
| `0x4ec2a8` | `14 bd 0c 39` | hazard proximity |
| `0x52d610` | `68 be 0c 39` | countdown |
| `0x4cb98c` | *(baca ulang sebelum pakai)* | pemicu stage |
| `0x5d09fc` | *(baca ulang sebelum pakai)* | hazard stage |
| `0x3ab7b0` | `15 bd 0c 39` | switch alasan |

Efek: flag tidak pernah ter-set oleh situs mana pun → semua 32 pembaca melihat
"hidup" → tidak ada DestroyBody/detach, tidak ada switch getter, flip-assist
tetap jalan. **Risiko:** paling invasif (12 patch); beberapa situs juga dipakai
logika stage yang sah (kill-zone/hazard/switch adalah bagian desain stage —
me-NOP mereka berarti stage kehilangan "bahaya"-nya, tapi untuk god mode itu
memang tujuannya). Sebagian byte asli belum dibaca di REA-2 (ditandai di atas)
— **baca dari binary sebelum build, jangan tebak**.

### P2 — NOP vehicle flag `[x+0x266]` (tutup jalur timer paralel)

| Alamat | Byte asli | Konteks |
|---|---|---|
| `0x3b0de0` | `69 9a 09 39` | cabang GOAL contact handler |
| `0x3b0ff4` | `69 9a 09 39` | cabang `0x100` contact handler |
| `0x3b175c` | `08 98 09 39` | setter `0x3b1758` (9 caller) |

Efek: jalur timer paralel `0x3c76d8`/`0x3c76fc` tidak pernah fire. **Bukan
pengganti P0/P1** — vehicle flag bukan jalur utama "mati" (§3), tapi lubang
kedua yang patut ditutup bila P0/P1 sudah jalan dan masih ada end-run misterius.

### P3 — Minimal: NOP stuck + detach saja (untuk tes cepat)

| Alamat | Byte asli | Konteks |
|---|---|---|
| `0x5053f4` | `68 be 0c 39` | stuck (terbalik diam) — kandidat #1 |
| `0x50e570` | `68 be 0c 39` | detachment — kandidat #2 |

Efek: menutup dua jalur yang paling mungkin aktif saat kepala kena tanah lalu
mobil terbalik. Bila setelah P3 user masih "bisa mati", tambah fall
`0x4efae4` + akumulator `0x3d488c`, lalu naik ke P0. **Keuntungan P3:** hanya
2 patch, risiko paling kecil, dan hasilnya langsung menunjukkan jalur mana yang
aktif (diagnostik lewat eliminasi).

### Catatan umum kandidat patch

- Semua offset di atas adalah **alamat virtual (VA) di `libgame.so` 1.72.2**,
  dipakai pattern-scan seperti v4 (bukan offset file mentah — untuk `.so`
  yang di-load, VA 0 = awal segmen; verifikasi dengan simulasi scan kedua
  binary seperti yang dilakukan v1.7: 13/13 pola OK).
- **JANGAN patch cek jatuh (`0x4efae4`) sendirian** tanpa menutup yang lain —
  mobil yang jatuh keluar dunia akan jatuh selamanya (soft-lock), sama seperti
  peringatan laporan death pertama.
- **JANGAN jadikan P1 sebagai satu-satunya pertahanan** tanpa P0: bila ada
  setter ke-16 yang belum terpetakan (mis. di fungsi yang belum dibaca),
  flag masih bisa ter-set dan DestroyBody tetap jalan. P0 adalah pertahanan
  di titik akibat — ia menutup semua setter, termasuk yang belum dikenal.

---

## 8. Probe runtime yang dibutuhkan dari HP user (POCO X6 Pro)

1. **Gejala visual persis saat "mati" (PALING PENTING — belum dikonfirmasi):**
   driver jatuh/terlepas dari mobil? Mobil berhenti total (tidak bisa digas)?
   Kamera mengikuti sesuatu yang jatuh? Layar apa yang muncul (tulisan apa —
   "DRIVER DOWN"? "GAME OVER!"? layar hitam? tidak ada tulisan)? Berapa lama
   setelah kepala kena tanah gejala muncul (langsung / setelah mobil diam
   beberapa detik)?
2. **Tes diskriminasi stuck vs detach:** god ON → balikkan mobil di tanah datar
   (tanpa benturan kepala keras) → diam 10 detik. Bila "mati" → jalur stuck
   (`0x5053f4`) terkonfirmasi. Lalu: god ON → lompat dari tebing dan mendarat
   terbalik tapi langsung gas lagi sebelum diam — bila tetap jalan, stuck
   makin terkonfirmasi.
3. **Log status saat kejadian:** `dflag`/`dtimer`/`gsrc` dari panel diagnosis
   (seperti log v1.7 17:32) — apakah `dflag` berubah 0→3 saat "mati"? Bila ya,
   flag ter-set oleh situs non-v4 (bukan B/C).
4. **Flip-back probe tahap 2** (sudah direncanakan, menunggu persetujuan user):
   build probe terpisah + tes ±3 menit (tegak → lompat+putar → mendarat
   terbalik + diam 10 dtk → lanjut; TANPA god mode) → kirim
   `/data/local/tmp/hcr_flip_probe_*.log` via MT Manager. Probe ini juga
   mengukur `[car+0x3a0]`, timer stuck `[car+0x860]`/ambang `[car+0x864]`,
   dan `[car+0x519]` saat kejadian — tiga nilai yang tidak bisa dipastikan
   dari statis.
5. **Data game di perangkat (tidak wajib, bila bisa dijangkau dari VM):**
   TIDAK dicoba di REA-2 — file save/config HCR di `/data/data/com.fingersoft.hillclimb/`
   tidak bisa dijangkau dari VM tanpa akses perangkat. Bila suatu saat bisa,
   yang dicari: apakah ada config kematian/damage di save (kemungkinan kecil —
   semua logika ada di binary).

---

## 9. Batas kejujuran + yang belum dikerjakan

### Terbukti dari disassembly (keyakinan tinggi)

- 32 pembaca `ldrb [x,#0x32f]`; 15 setter + 1 clearer; 12 setter tersisa aktif.
- Blok DestroyBody `0x524f0c` (3× `bl 0x6d20c0` + nulling) dan blok detach
  `0x560970` (slot `0x200` pada `[car+0x788]` + kepala `[car+0x2d0]`) —
  keduanya digate flag langsung, bukan predikat.
- Situs A = GOAL (teks `"GOAL !!"` + `goal.json` + kategori kepala = 1).
- `[run+0x624]` = FUEL; slot `0xb8` bukan penghancur driver; `[car+0x3a0]` =
  counter airborne; `[car+0x519]` = gate kedua (11 pembaca).
- Istilah Inggris: `"DRIVER DOWN"` (kepala kena sesuatu), `"NECK FLIP"`,
  `"GOAL !!"`, `"JUMP FAILED!!"`, `"CANNON LOST !!"`.
- Inventory APK 1.72.2 lengkap: XAPK resmi terverifikasi (SHA cocok), 7 `.so`
  di split arm64 (semua logika di `libgame.so`), 2391 aset, tidak ada script
  game (9 `.js` = SDK iklan), definisi driver di JSON kendaraan.

### Masih dugaan (butuh konfirmasi runtime)

- Jalur mana dari 12 setter yang fire duluan di tes user (dugaan terkuat:
  stuck `0x5053f4`, lalu detach `0x50e570`).
- Identitas pasti slot `0xb8` (dugaan: handler landing/impact) dan slot
  `0x498` di situs C (dugaan: efek visual/suara).
- Identitas `[car+0x410]` (objek yang di-detach fungsi situs B saat
  `[car+0x294] > 0,5`) dan `[car+0x468]` (objek slot `0x498`).
- Makna `[car+0x519]` dan state `[x26]==0x25`/`0x2b` (jalur timer paralel).
- Apakah "tipe 7" di situs C = tanah (dugaan kuat, belum terbukti).
- Situs pembuatan body `[car+0x840]`/`[car+0x848]`/`[car+0x858]`
  (constructor per-mobil belum teridentifikasi).
- Fungsi situs B awal (prologue — fungsi > 8 KB atau pola prolog berbeda;
  start persis belum ditemukan).

### Tidak bisa dijawab dari file statis saja

- Gejala visual persis saat "mati" (butuh mata user / video).
- Urutan temporal antar jalur saat benturan nyata.
- Apakah P0/P1/P3 benar-benar membuat kendaraan tetap bisa dikendarai
  (butuh tes POCO setelah implementasi).

### Sisa yang belum dikerjakan REA-2

- Start fungsi situs B (prologue) — tidak memengaruhi kesimpulan.
- `garage_physics.json` sudah diperiksa (RUBE garasi; bukan sumber kategori).
- Inventory aset 1.72.2 vs 1.71.1: **tidak bisa dibandingkan penuh** —
  ekstraksi 1.71.1 di workspace hanya parsial (307 file ter-list dari
  `apk1711/assets`, bukan 2370). Perbandingan kategori sudah cukup untuk
  kesimpulan (struktur aset sama; tidak ada script game di kedua versi).
- File data game di perangkat: tidak dijangkau (lihat §8 butir 5).

---

## Lampiran — file kerja

- Laporan ini: `~/workspace/rea-hcr-death-2/REPORT.md`
- Direktori kerja: `~/workspace/rea-hcr-death-2/work/`
  - `hcrdis.py` — disassembler AArch64 (Capstone) + utilitas scan
  - `vtables.json` — 675 vtable (dari REA-1)
  - `scan2.py`–`scan6.py` — scan pembaca/penulis/caller
  - `fn_*.txt` — disassembly fungsi-fungsi kunci (contact handler, situs B/C,
    `0x3c4798`, slot `0xb8`/`0x138`, stuck, fall, destroy `0x524f0c`,
    detach `0x560970`, dll)
  - `readers_ctx.txt`, `apk1711_list.txt`
  - `apk1711/` — ekstraksi base.apk 1.71.1 (parsial, 307 file ter-list)
  - `apkpure_1722.json` — respons API APKPure (protobuf, 523.603 B)
  - `xapk_1722_url.txt` — URL XAPK 1.72.2 (signed)
  - `hcr-1.72.2.xapk` — XAPK resmi 1.72.2, 163.680.584 B,
    SHA-256 `f6a6a43fd7b00a2a149b77eb12577b986b84ee4fe3ea741850f6684c700e194c`
  - `apk1722/` — ekstraksi XAPK (base APK + split; `base/assets/` = 2391 file)
- Referensi: `~/workspace/rea-hcr-death/REPORT.md` (laporan death pertama),
  `~/workspace/rea-hcr-speed/REPORT.md` (REA speed + torsi),
  `~/workspace/goals/hozin-hcr-mod-aplikasi-root-mod-menu-hill-climb-racing/GOAL.md`
