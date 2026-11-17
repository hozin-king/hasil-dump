# com.fingersoft.hillclimb — Hill Climb Racing 1 (REA konsolidasi)

**Target:** Hill Climb Racing 1, `com.fingersoft.hillclimb`, `libgame.so` arm64 (cocos2d-x + Box2D).
**Versi yang dianalisis:** **1.72.2** (code 936, XAPK resmi 163.680.584 B, SHA-256
`f6a6a43fd7b00a2a149b77eb12577b986b84ee4fe3ea741850f6684c700e194c`) dan **1.71.1**
(SHA-256 `e27734f12fa574d2…`). `libgame.so` 1.72.2 SHA-256
`307f6b87dfae712a0496fb4396ff56682bde50350744789dd1875d7d74d77a49` — identik dengan
binary dari XAPK resmi (terverifikasi silang, REA-2 §5).
**Tanggal riset:** 17 Nov 2026. **Sifat:** analisis statis SAJA — tanpa menjalankan game,
tanpa mengubah binary. Laporan di folder `1.71.1-1.72.2/arm64-v8a/` adalah salinan
verbatim dari sesi REA (satu-satunya perubahan: tautan unduhan bertanda tangan di
REA-2 §5.1 disensor, sesuai aturan arsip).

Struktur folder ini mengikuti pola `com.fungames.sniper3d/`: laporan konsolidasi di
top-level + laporan per-sesi di folder versi. Binary `.so`/XAPK TIDAK diarsipkan
(aturan README arsip: APK mentah bukan hasil dump).

## Peta laporan

| # | File | Isi singkat |
|---|---|---|
| 1 | [`1.71.1-1.72.2/arm64-v8a/REA-1-death-physics.md`](./1.71.1-1.72.2/arm64-v8a/REA-1-death-physics.md) | REA pertama — "fisika kematian": predikat `0x3b2f94` hanya PEMBACA flag; 15 situs setter flag `[PlayerCar+0x32f]`; driver = 2–3 body fisika, tanpa ragdoll |
| 2 | [`1.71.1-1.72.2/arm64-v8a/REA-2-death-flag.md`](./1.71.1-1.72.2/arm64-v8a/REA-2-death-flag.md) | REA-2 — jalur mati DI LUAR rantai flag: 2 pembunuh fisik (`DestroyBody` + detach kepala); 31/32 pembaca flag baca byte langsung; istilah game "DRIVER DOWN" |
| 3 | [`1.71.1-1.72.2/arm64-v8a/REA-3-driver-toggles.md`](./1.71.1-1.72.2/arm64-v8a/REA-3-driver-toggles.md) | REA-3 — verdict 4 toggle driver (Pindah / Hapus / Shrink / Filter); Filter paling bersih; peringkat Hapus-B > Pindah > Filter > Shrink |
| 4 | [`1.71.1-1.72.2/arm64-v8a/REA-4-death-p0-coverage.md`](./1.71.1-1.72.2/arm64-v8a/REA-4-death-p0-coverage.md) | REA-4 — kenapa God v5 (P0) gagal di lapangan: BUKAN bug, tapi CAKUPAN (hanya 2 dari ~45 kendaraan; setter `strh` ke-16 luput; countdown `[run+0x630]/[run+0x634]`) |
| 5 | [`1.71.1-1.72.2/arm64-v8a/REA-speed-torque.md`](./1.71.1-1.72.2/arm64-v8a/REA-speed-torque.md) | REA Speed — struct car/body, `SetMaxMotorTorque`, torsi Jeep 23,0 × 1,046^(level−1); dasar Speed Instan + pengali torsi |
| 6 | [`1.71.1-1.72.2/arm64-v8a/REA-booster.md`](./1.71.1-1.72.2/arm64-v8a/REA-booster.md) | REA Booster — batas beli 10 ditegakkan di 3 tempat; cooldown state machine (NITRO 2 dtk, GRIP 18 dtk); inventaris = satu kunci `'hcr1-nitro'` |
| — | [`FILTER-MECHANISM.md`](./FILTER-MECHANISM.md) | Mekanisme Driver Tembus (Filter) yang dipakai mod v1.10/v1.10.1 — BUKAN patch kode, tapi perubahan data filter Box2D hidup via `SetFilterData` milik game |

## Temuan kunci (ringkas)

### Kematian driver — bukan satu cek, tapi flag + banyak penulis
- Predikat kematian `0x3b2f94` (vtable slot `0xa0`) hanya membaca flag
  `[PlayerCar+0x32f]` (`ldrb w0, [x0, #0x32f]; ret`, impl `0x4f78c8`). Pertanyaan
  sebenarnya: **siapa yang menulis flag = 1, dan atas dasar apa.**
- Ada **15 situs setter flag** (+1 clearer) dalam 5 keluarga pemicu: kontak fisika,
  perbandingan posisi/ketinggian, timer/accumulator, kill-zone stage, detachment.
  Yang paling dekat dengan "kepala kena tanah": `0x3b0ddc` (kontak kategori
  `0x10000`), `0x3ad494` (titik vs transform body), `0x4eff98` (query spasial di
  posisi "kepala", tipe 7). Situs A v4 (`0x3b0ddc`) ternyata detektor GOAL stage
  ballsports, BUKAN kepala kena tanah (koreksi REA-2).
- **Tidak ada class Driver/Head/Ragdoll** di binary (RTTI tidak mengenalnya).
  Driver = 2–3 body fisika terpisah di `PlayerCar` (`+0x2d0` = kandidat kepala,
  `+0x2d8` = badan utama/chassis, `+0x2e0`/`+0x2e8` = bagian lain/roda). Box2D ADA.
- Dua pembunuh fisik di luar flag: `0x524f0c` (`DestroyBody` 3 body driver) dan
  `0x560970` (destroy joint kepala). 31 dari 32 pembaca flag membaca byte
  langsung — patch predikat saja tidak melindungi.

### Evolusi God Mode (v4 → v6) dan hasil lapangan
- **v4** (mod v1.7): NOP 3 situs `strb` (A `0x3b0ddc`, B `0x3ad494`, C `0x4eff98`).
  Tes POCO: inject + scan OK, tapi God tidak dinyalakan di run itu.
- **v5/P0** (mod v1.9/v1.9.1): lumpuhkan blok `DestroyBody` driver (`0x524f10`→`b`)
  + blok detach kepala (`0x560974`→lompat selalu). Tes POCO v1.9.1: GAGAL — God ON,
  tetap DRIVER DOWN di 1008m (1x NECK FLIP).
- **v6** (mod v1.10): P0c (3 situs region-1) + P1 (NOP 8 `strh`) + P2 (NOP 12
  `strb`) + P3 (P0 ke 6 kendaraan lain) + 4 toggle driver. Tes POCO v1.10:
  CRASH saat toggle Driver ditekan (diagnosis: toggle diterapkan ke fixture hidup
  tanpa validasi pointer + tanpa gate run aktif).
- **v1.10.1**: Hapus dikunci (tolak bila God OFF), validasi pointer via
  `/proc/self/maps`, gate run aktif, penangkap crash. Tes POCO 20:14 WIB:
  **TIDAK CRASH** — Filter ON + God sengaja OFF → run 15065m, 165x BACK FLIP,
  **0x NECK FLIP**, +6.093.240 koin, +23 gems, lalu DRIVER DOWN (diharapkan, God OFF).

### Kenapa P0 gagal (REA-4 — bukan bug, tapi cakupan)
- P0A = FastBike, P0B = OneWheeler saja dari ~45 kendaraan; run user pakai motor.
- Setter flag ke-16 luput: 8 situs `strh` (halfword write) — v4 hanya NOP `strb`.
- 12 setter `strb` lain + countdown baru `[run+0x630]`/`[run+0x634]` yang end-run
  tanpa baca flag. Rekonstruksi: NECK FLIP hanya bila flag CLEAR → mati datang
  setelah flip (kepala sentuh tanah → latch → `strh` set flag=1).

### Speed + torsi
- Kecepatan hidup di linear velocity body chassis `[body+0x50]`/`[body+0x54]`,
  angular `[body+0x58]`; torsi mesin di maxMotorTorque joint roda (`[joint+0xb8]`),
  di-set tiap frame dari stat mesin `[car+0x760]` (Jeep 23,0 × 1,046^(level−1)).
- `SetMaxMotorTorque` 1.72.2 `0x6ced10` / 1.71.1 `0x6be36c` (pola 56-byte UNIK).
  Pengali torsi saja TIDAK menaikkan top speed. Struct bergeser +0x18 antar versi
  (fuel `0x60c`→`0x624`, death timer `0x614`→`0x62c`, death flag `0x500`→`0x518`).

### Booster (v1.11, ditahan — menunggu tes v1.10.1)
- Batas beli 10 ditegakkan di 3 tempat (`PowerUpDialog.cpp`): handler plus
  1.72.2 `0x5adca8`/`0x5adcb0`, refresh dialog 3× `cmp w20,#0xa`, gerbang
  konfirmasi `cmp w0,#9` @ `0x5ae400`. Paket P-BUY-A: naikkan keempat konstanta
  (contoh 99; maks 4095).
- Inventaris = SATU kunci `'hcr1-nitro'` untuk 5 tipe; getter `0x5a6874`, setter
  `0x5a843c`, addNitro `0x5a8480`, subtractNitro `0x5a6ba4` (1.72.2).
- Cooldown state machine (0=ready, 1=aktif, 2=cooldown): NITRO 2,0 dtk, JUMP 0,5,
  BIGTIRES 10, GRIP 18, GLIDER 10; aktif NITRO 3 dtk, lain 10 dtk. P-CD-A
  (rekomendasi): `fmov s0` cooldown di ctor tiap tipe → `#0.0`. P-CD-E: NOP
  pemanggilan subtractNitro → stok tak berkurang. Profil lokal `UserDefault.xml`,
  0 panggilan jaringan di jalur beli/pakai.

### Driver Tembus (Filter) — mekanisme
Bukan patch kode di offset tetap seperti God. Yang diubah adalah **data hidup**:
field filter (`categoryBits`/`maskBits`/`groupIndex`) di dalam objek fixture
Box2D driver (`b2Fixture`), lewat fungsi `SetFilterData` **milik game sendiri**
(1.72.2 `0x6d0f64` / 1.71.1 `0x6c05c0`). Detail lengkap di
[`FILTER-MECHANISM.md`](./FILTER-MECHANISM.md). Hasil lapangan: 0x NECK FLIP
dalam run 15065m penuh backflip (Filter ON, God OFF).

## Batas kejujuran
- Semua temuan bersifat analisis statis; sebagian jalur (mis. countdown
  `[run+0x630]/[run+0x634]`, setter `strh` ke-16) direkonstruksi dari
  disassembly + log lapangan, belum semuanya terkonfirmasi probe runtime.
- Offset = offset file = VA (PIE, base 0) di `libgame.so` arm64. Pola byte
  16-byte situs kunci IDENTIK antara 1.72.2 dan 1.71.1 (REA Booster).
- Mod Hozin HCR Mod (v1.7–v1.10.1) dibangun dari laporan-laporan ini; repo mod
  terpisah (`hozin-king/hozin-hcr-mod`), TIDAK diarsipkan di sini.
