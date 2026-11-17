# REA-3: Empat pendekatan alternatif mencegah kematian driver Hill Climb Racing 1 — sebagai EMPAT TOGGLE terpisah

**Tanggal:** 17 Nov 2026
**Target:** Hill Climb Racing 1 `com.fingersoft.hillclimb` **v1.72.2** (code 936, game terpasang di POCO user); padanan 1.71.1 dicari di mana relevan
**Binary yang dianalisis:** `libgame.so` arm64 SHA-256 `307f6b87dfae712a0496fb4396ff56682bde50350744789dd1875d7d74d77a49` (1.72.2, identik dengan XAPK resmi); 1.71.1 di `~/workspace/hcrx/lib/arm64-v8a/libgame.so`
**Lanjutan dari:** `~/workspace/rea-hcr-death/REPORT.md` (514 baris) dan `~/workspace/rea-hcr-death-2/REPORT.md` (794 baris)
**Status:** RISET SAJA. Tidak menyentuh `~/workspace/hozin-hcr-mod/`, tidak ada implementasi.
**Keputusan desain user (18:23 WIB):** keempat pendekatan masing-masing dijadikan **FITUR TOGGLE sendiri** di mod menu (bukan satu toggle gabungan) — default OFF, independen, bisa dikombinasikan bila aman. Implementasi setelah laporan ini selesai (versi setelah v1.9). Laporan ini memuat desain per-toggle: nama, perilaku ON/OFF, reversibilitas, kombinasi, dan kelayakan.

## 0. Ringkasan eksekutif — verdict per pendekatan

| # | Pendekatan | Bisa? | Layak jadi toggle? | Yang ditutup | Yang TIDAK ditutup |
|---|---|---|---|---|---|
| 1 | **PINDAHKAN** driver (teleport kepala ke dalam chassis tiap frame) | **BISA** (dengan catatan) | **LAYAK, eksperimental** — paling rumit | B, C, kill-zone, hazard (semua yang membaca posisi kepala) | stuck, fall, detach, akumulator, countdown, stage-trigger, switch |
| 2 | **HAPUS** driver | **BISA — hanya varian B** (null `[car+0x2d0]`, "sembunyikan dari logika") | **LAYAK (varian B)** — paling sederhana + reversibel penuh. **Varian A (DestroyBody total) TIDAK LAYAK jadi toggle** (irreversibel di tengah run + risiko dangling pointer) | B, C, kill-zone, hazard (via fallback getter ke posisi chassis) | stuck, fall, detach, akumulator, countdown, stage-trigger, switch |
| 3 | **KECILKAN** driver (radius fixture kepala → 0,001) | **BISA** | **LAYAK** — paling aman, paling lemah | Kontak kepala (hampir tidak pernah menyentuh apa pun) | B, C, kill-zone, hazard, stuck, fall, detach, akumulator, countdown — **semua jalur kematian posisi/timer tetap aktif** |
| 4 | **MATIKAN TOTAL deteksi hit** (maskBits fixture kepala = 0) | **BISA** — paling bersih implementasinya | **LAYAK** — implementasi paling bersih dari keempatnya | SEMUA kontak kepala (dijamin nol kontak baru; kontak lama di-refilter) | B, C, kill-zone, hazard, stuck, fall, detach, akumulator, countdown — **semua jalur kematian posisi/timer tetap aktif** |

**Temuan terpenting (mengubah ekspektasi): TIDAK ADA SATU PUN dari keempat pendekatan yang sendirian mencegah "DRIVER DOWN".** Penyebabnya: tidak ada satu pun setter flag kematian yang bekerja lewat **kontak fixture kepala** (lihat §1.4) — dua setter kepala (B dan C) bekerja lewat **posisi** kepala, dan 10 setter lainnya lewat stuck/jatuh/jarak/timer/stage. Jadi pendekatan 3 dan 4 (yang mematikan kontak) **tidak menyentuh satu pun jalur kematian**; pendekatan 1 dan 2 (yang mengubah posisi kepala / menyembunyikan kepala dari logika) menutup jalur posisi kepala (B, C, kill-zone, hazard) tapi bukan jalur stuck/fall/detach/akumulator.

**Konsekuensinya untuk "god mode v6":** God Mode v5 (P0, sudah rilis di v1.9 — melumpuhkan blok DestroyBody `0x524f0c` + blok detach `0x560970`) **tetap satu-satunya pertahanan total**, karena ia bekerja di titik akibat, bukan di titik pemicu. Keempat toggle ini adalah **lapis pelengkap** (hardening + fitur seru), bukan pengganti God Mode. Kombinasi terkuat: **God Mode (P0) + Hapus Driver (varian B)** — P0 menutup akibat dari semua setter, Hapus-B menutup 4 setter posisi kepala di sumbernya. Urutan implementasi yang disarankan: **4 (Filter) → 2B (Hapus) → 1 (Pindah) → 3 (Kecilkan)** — dari yang paling mudah/aman ke yang paling rumit (detail §8).

**Koreksi terhadap asumsi awal tugas ini:** filter fixture kepala (`maskBits = 0`) **bukan** "mematikan total deteksi hit driver" dalam arti kematian — ia mematikan **tabrakan fisik** kepala, sementara deteksi kematian game ini sebagian besar **bukan** berbasis tabrakan. Nama toggle yang diusulkan ("Driver Tembus") mencerminkan kenyataan ini dengan jujur, bukan klaim god mode.

---

## 1. Fakta dasar bersama — anatomi driver (dipakai semua pendekatan)

### 1.1 Definisi driver di data game (Jeep, `boringcar_model.json`, 1.72.2)

`assets/vehicles/boringcar_model.json` (RUBE). Indeks body dipakai joint sebagai `bodyA`/`bodyB`:

| idx | Body | type | Posisi (x, y) | Fixture | cat | mask | density |
|---|---|---|---|---|---|---|---|
| 0 | rearWheel | 2 (dynamic) | (−1,322, −0,526) | rearWheel | 8 | 46022 (0xB3C6) | 0,265 |
| 1 | frontWheel | 2 (dynamic) | (1,019, −0,526) | frontWheel | 8 | 46022 | 0,265 |
| 2 | **head** | 2 (dynamic) | (−0,162, 0,593) | fixture8 (circle r=0,3014) | **32** | **63430 (0xF7C6)** | 0,01 |
| 3 | torso | 2 (dynamic) | (−0,162, 0,045) | fixture4 | **32** | **0** | 0,01 |
| 4 | chassis | 2 (dynamic) | (0, 0) | chassisFixture | 8 | 46022 | 0,51 |
| 5 | ground | 0 (static) | (0, −1,603) | fixture1 | 64 | 65470 (0xFFBE) | 1 |
| 6 | chassisBack | 2 | (−0,661, 0,092) | sensor | 0 | 0 | 0,01 |
| 7 | rearWheelBack | 1 (kinematic) | (−1,091, −0,526) | sensor | 0 | 0 | 0,01 |
| 8 | frontWheelBack | 1 (kinematic) | (1,303, −0,526) | sensor | 0 | 0 | 0,01 |

Dua fakta penting di tabel ini:

- **Torso sudah "ghost" dari sananya:** `maskBits = 0` — torso TIDAK bertabrakan dengan apa pun. Game sendiri sudah memakai trik "matikan tabrakan" untuk torso. Preseden bahwa filter=0 adalah teknik yang dipakai game sendiri, bukan hack liar.
- **Kepala TIDAK bertabrakan dengan chassis/roda/torso:** mask kepala `0xF7C6` = bit `{1,2,6,7,8,9,12,13,14,15}` → bertabrakan dengan kategori `{2,4,64,128,256,512,4096,8192,16384,32768}`. Kategori **8** (chassis, roda — bit 3) **tidak** ada di mask; kategori **32** (torso — bit 5) **tidak** ada di mask. Yang **ada**: kategori **64** (ground — bit 6) → kepala bertabrakan dengan tanah (dan sebaliknya: mask ground `0xFFBE` mengandung bit 5 → ground bertabrakan dengan kepala). Jadi kepala hanya benar-benar "menyentuh" tanah/objek stage — bukan kendaraannya sendiri.

Massa kepala: density 0,01 × luas lingkaran (π × 0,3014² ≈ 0,285) ≈ **0,0029 kg** (`modifier_props.json` menyebut 0,0034 kg). Kepala praktis tidak berbobot — ia tidak memengaruhi handling mobil; ia hanya "numpang" di joint.

### 1.2 Joint driver (dari JSON yang sama)

| Joint | type | bodyA ↔ bodyB | Anchor A (lokal) | Anchor B (lokal) | Batas / panjang |
|---|---|---|---|---|---|
| `driverHeadJoint` | revolute | torso (3) ↔ head (2) | (0, 0,2873) | (0, −0,2607) | limit **±0,4014 rad (±23°)** |
| `torsoHeadDistanceJoint` | distance | torso (3) ↔ head (2) | (0,2358, −0,0739) | (0,2510, −0,0599) | **length 0,5637**, damping 0,7, **TANPA frequencyHz (= 0 → RIGID, bukan pegas)** |
| `joint0` | revolute | chassis (4) ↔ torso (3) | (−0,157, −0,196) | (0,0047, −0,241) | limit **±0,01745 rad (±1°)** — torso praktis dilas ke chassis |

Verifikasi posisi kepala dari joint: pivot leher di torso + (0, 0,2873) = (−0,162, 0,332); pusat kepala = pivot + 0,2607 (jarak anchor B ke pusat) = (−0,162, 0,593) — **persis posisi head di JSON**. Artinya pose kepala sepenuhnya ditentukan kedua joint: ia hanya bisa mengayun ±23° di sekitar pivot leher, pada jarak tetap dari torso. **Kepala TIDAK bisa dipindah sembarangan selama kedua joint hidup** — ini batas fundamental pendekatan 1 (§2).

Koreksi terhadap catatan interim REA-3: `torsoHeadDistanceJoint` **tidak** punya `frequencyHz: 5` — field itu `None` di JSON (distance joint RIGID). Damping 0,7 tanpa frekuensi tidak berpengaruh.

### 1.3 Pointer-pointer di struct PlayerCar (1.72.2)

| Slot | Isi (terbukti / dugaan) | Bukti |
|---|---|---|
| `[car+0x2d0]` | **Sprite kepala** (objek polimorfik, BUKAN b2Body mentah) | Getter `0x4f4b30` memanggil virtual slot `0x3b8` padanya; ada null-check (lihat §1.5) |
| `[car+0x2d8]` | b2Body **chassis** | Getter membaca posisi langsung `[x8, #0x0c]`; handler kontak membandingkannya sebagai body |
| `[car+0x2e0]` / `[car+0x2e8]` | Body lain (kemungkinan roda — dipakai handler kontak untuk bitmask stuck) | Handler kontak `0x4f4b68` membandingkan ketiganya sebagai body |
| `[car+0x840]` / `[car+0x848]` / `[car+0x858]` | **3 body driver** (b2Body mentah; pemetaan mana-yang-kepala BELUM terbukti) | Destroyer `0x524f0c` menghancurkan ketiganya via `DestroyBody` + null-kan; situs pembuatannya belum teridentifikasi (REA-2 §3.2) |
| `[car+0x788]` | Joint (objek joint driver — dipakai blok detach) | Blok `0x560970`: cek null → slot `0x28` (hitung) → slot `0x110` (ambil joint) → slot `0x200` (destroy joint) |
| `[car+0x2b8]` | b2World | Destroyer memakainya sebagai argumen `DestroyBody(world, body)` |
| `[car+0x300]` | Objek acuan detachment | Setter detachment `0x50e570` mengukur jarak 2 titik objek ini |
| `[car+0x32f]` | Flag "run berakhir" (1 byte) | 15 setter + 32 pembaca (REA-2) |
| `[car+0x519]` | Gate kedua destroy/detach (makna belum pasti) | 11 pembaca; destroy hanya jalan bila `== 0` |

### 1.4 Peta 15 setter flag — APA yang dibaca masing-masing (menentukan cakupan tiap toggle)

Dari REA-2 §2.1 + disassembly lanjutan REA-3. Kolom "dibaca" adalah kunci: toggle hanya bisa menutup setter yang membaca sesuatu yang diubah toggle itu.

| # | Alamat | Pemicu | Yang dibaca | Ditutup oleh toggle… |
|---|---|---|---|---|
| 1 | `0x3b0ddc` | kontak kategori `0x10000` (**GOAL ballsports**, bukan kepala) | Kontak fixture GOAL | — (sudah di-NOP v4; bukan kepala) |
| 2 | `0x3ad494` | titik di bawah transform body ("kepala di bawah permukaan") | **Posisi kepala** via `getter(car,1)` | **1 (Pindah), 2B (Hapus)** |
| 3 | `0x4eff98` | kepala menyentuh objek tipe 7 (query spasial) | **Posisi kepala** via `getter(car,1)` + query `0x3a5a94` | **1 (Pindah), 2B (Hapus)** |
| 4 | `0x5053f4` | stuck — terbalik diam (speed < 1,0, timer `[car+0x860]` > ambang `[car+0x864]`) | Bitmask kontak `[car+0x31c]` (chassis/roda — **bukan kepala**) + kecepatan chassis | **TIDAK oleh satu pun dari keempatnya** (hanya God P0/P1) |
| 5 | `0x50bfbc` | stuck, mobil lain | Sama (pola sama) | **TIDAK** |
| 6 | `0x4efae4` | fall — posisi-Y chassis < −100 | Posisi-Y **chassis** | **TIDAK** |
| 7 | `0x4efb18` | fall, slot Stage `0x350` (praktis tidak pernah fire) | Slot stage | **TIDAK** |
| 8 | `0x50e570` | detachment — jarak 2 titik `[car+0x300]` > 1,0 | Objek `[car+0x300]` (bukan kepala) | **TIDAK** |
| 9 | `0x3d488c` | akumulator `[run+0x5f8]` ≥ 100 | Timer/akumulator (pemicu pastinya belum dipetakan) | **TIDAK** |
| 10 | `0x4c9dfc` | kill-zone stage | **Posisi kepala** masuk kotak bahaya | **1 (Pindah), 2B (Hapus)** |
| 11 | `0x4ec2a8` | hazard proximity — jarak kepala ke titik hazard < 4,0 | **Posisi kepala** | **1 (Pindah), 2B (Hapus)** |
| 12 | `0x52d610` | countdown `[car+0x780]` mencapai 0 | Countdown (FastBike?) | **TIDAK** |
| 13 | `0x4cb98c` | pemicu stage | `[obj+0x290]` + kondisi `0x4cbc14` | **TIDAK** |
| 14 | `0x5d09fc` | hazard stage | Setelah `bl 0x6d2224` (buat objek fisika) | **TIDAK** |
| 15 | `0x3ab7b0` | switch alasan | Satu case switch | **TIDAK** |

Kesimpulan peta ini: **hanya 4 dari 15 setter yang membaca posisi kepala** (B, C, kill-zone, hazard). Setter stuck — yang paling mungkin membunuh user di tes v1.7 (mobil terbalik + diam) — **tidak membaca kepala sama sekali**: ia membaca kontak chassis/roda + kecepatan chassis. Inilah alasan struktural mengapa pendekatan 3 dan 4 tidak bisa menjadi god mode.

### 1.5 Getter posisi kepala — null-check yang menentukan nasib pendekatan 2

`0x4f4b30` (getter posisi, slot vtable `0x70`, dipakai situs B, C, kill-zone, hazard):

```
0x4f4b30: stp x29, x30, [sp, #-0x10]!
0x4f4b38: tbz w1, #0, #0x4f4b58      ; arg1 bit0==0 → cabang chassis
0x4f4b3c: ldr x8, [x0, #0x2d0]       ; sprite kepala
0x4f4b40: cbz x8, #0x4f4b58          ; kepala NULL → FALLBACK ke chassis
0x4f4b44: ldr x9, [x8]              ; vtable sprite
0x4f4b48: mov x0, x8
0x4f4b4c: ldr x9, [x9, #0x3b8]      ; slot 0x3b8 = GetPosition
0x4f4b50: blr x9
0x4f4b54: b #0x4f4b60
0x4f4b58: ldr x8, [x0, #0x2d8]      ; chassis body
0x4f4b5c: ldp s0, s1, [x8, #0xc]    ; posisi langsung [chassis+0x0c]
0x4f4b60: ret
```

**Bila `[car+0x2d0]` di-null-kan, getter mengembalikan posisi CHASSIS, bukan crash.** Ini perilaku bawaan game (fallback yang disengaja — kemungkinan untuk kendaraan tanpa driver / mode tertentu), dan ini fondasi pendekatan 2 varian B: semua pembaca "posisi kepala" otomatis mengukur chassis. Posisi chassis saat mobil terbalik bertumpu di atap berada ~0,5 m di atas tanah (pusat chassis), sementara kepala normal berada di bawah permukaan tanah saat terbalik — jadi fallback ini menetralkan situs B/C secara posisi.

Peringatan yang sama pentingnya — blok detach `0x560970` **TIDAK** null-check `[car+0x2d0]`:

```
0x560970: ldrb w8, [x19, #0x32f]     ; flag
0x560974: cbz w8, #0x560a00           ; hidup → lewati blok
0x560978: ldr x0, [x19, #0x788]      ; joint
0x56097c: cbz x0, #0x560a00           ; joint NULL → lewati blok
0x560980: ... slot 0x28 / 0x110 / 0x200 pada joint ...
0x5609b8: ldr x0, [x19, #0x2d0]      ; KEPALA — tanpa cbz
0x5609bc: ldr x8, [x0] ; ldr x8, [x8, #0x110] ; blr x8
0x5609d4: ldr x8, [x8, #0x200] ; blr x8   ; destroy joint kepala
```

Jadi: bila `[car+0x2d0]` null DAN flag ter-set (oleh setter mana pun, mis. stuck) DAN `[car+0x788]` non-null → **null dereference di `0x5609bc` → crash**. Ini risiko utama pendekatan 2, dan alasan kombinasi dengan God Mode P0 menjadi penting (P0 mengubah `cbz` di `0x560974` jadi lompat selalu → blok ini tidak pernah jalan → risiko crash hilang). Detail di §3.4.

### 1.6 Layout Box2D yang dipakai semua pendekatan (terverifikasi dari disassembly)

**b2Fixture** (ukuran `0x50`), dari `b2Fixture::Create` (`0x6d0b5c`) + konstruktor/default-init (`0x6d0b28`):

| Offset | Field | Bukti |
|---|---|---|
| `+0x00` | density (float) | `str wzr, [x0]` (default 0) |
| `+0x08` | m_next (fixture berikutnya) | `str xzr, [x0, #8]` |
| `+0x10` | m_body | `stp xzr, xzr, [x0, #0x10]` |
| `+0x18` | m_shape | Clone via virtual slot `0x10` |
| `+0x20` | friction (float) | dari def `+0x10` |
| `+0x24` | restitution (float) | dari def `+0x14` |
| `+0x28` | m_proxies | `str xzr, [x0, #0x28]` |
| `+0x30` | m_proxyCount (int32) | `str wzr, [x0, #0x30]` |
| `+0x34` | **filter.categoryBits (u32)** | Default-init `strh w8=1, [x0, #0x34]`; `ShouldCollide` `ldrh w9, [x2, #0x34]` |
| `+0x38` | **filter.maskBits (u32)** | Default-init `str w9=0xffff, [x0, #0x38]`; `ShouldCollide` `ldr w8, [x1, #0x38]` |
| `+0x3c` | **filter.groupIndex (i32)** | `ShouldCollide` `ldrsh w8, [x1, #0x3c]`; Create `strh w8, [x0, #0x3c]` dari def `+0x28` |
| `+0x40` | isSensor (byte) | Create `strb w8, [x0, #0x40]` dari def `+0x1c` |
| `+0x48` | userData | Create `str x8, [x0, #0x48]` dari def `+0x08` |

Koreksi presisi: field filter di build ini berukuran **32-bit** (bukan u16 packed seperti Box2D stock) — terbukti dari `str w9, [x0, #0x38]` (store 32-bit nilai `0xffff`) dan `ldr w8, [x1, #0x38]` di `ShouldCollide`. Offsetnya sama dengan dugaan awal (`+0x34`/`+0x38`/`+0x3c`); yang dikoreksi hanya lebar field. Untuk menulis mask=0, pakai `str wzr` (32-bit) — paling bersih.

**b2Body** (offset yang dipakai laporan ini; terverifikasi dari `CreateFixture`, getter, dan REA speed): flags `+0x04`, posisi `+0x0c`/`+0x10`, linear velocity `+0x50`/`+0x54`, angular velocity `+0x58`, world `+0x68`, fixtureList `+0x80`, fixtureCount `+0x88`, massa `+0xa0`, invMass `+0xa4`, I `+0xa8`, invI `+0xac`. (Catatan: layout ini bergeser +8 dibanding Box2D 2.4 stock di paruh pertama struct — penyebab pastinya belum ditentukan; offset yang dipakai di sini semuanya dibaca dari kode, bukan dari header stock.)

**b2CircleShape**: vtable `+0x00`, type `+0x08`, **radius (float) `+0x0c`**, center m_p `+0x10`. (Layout stock `b2Shape`: `m_radius` di `+0x0c` untuk semua shape.)

**b2FixtureDef** (untuk konteks loader): shape `+0x00`, userData `+0x08`, friction `+0x10`, restitution `+0x14`, density `+0x18`, isSensor `+0x1c`, filter cat `+0x20` (u32), mask `+0x24` (u32), group `+0x28` (i32).

### 1.7 Dua fungsi Box2D kunci — alamat di KEDUA versi game

**`b2ContactFilter::ShouldCollide` (logika filter — stock Box2D, terverifikasi):**

```
1.72.2 @ 0x6d4188 ; 1.71.1 @ 0x6c37e8 (byte inti IDENTIK)
0x6d4188: bl #0x8013f0
0x6d418c: ldrsh w8, [x1, #0x3c]    ; groupIndex A
0x6d4190: cbz w8, #0x6d41ac
0x6d4194: ldrh w9, [x2, #0x3c]     ; groupIndex B
0x6d4198: cmp w9, w8, uxth
0x6d419c: b.ne #0x6d41ac
0x6d41a0: cmp w8, #0
0x6d41a4: cset w0, gt
0x6d41a8: ret
0x6d41ac: ldr w8, [x1, #0x38]      ; maskBits A
0x6d41b0: ldrh w9, [x2, #0x34]     ; categoryBits B
0x6d41b4: ldrh w10, [x1, #0x34]    ; categoryBits A
0x6d41b8: ldr w11, [x2, #0x38]     ; maskBits B
0x6d41bc: tst w8, w9               ; (maskA & catB) != 0 ?
0x6d41c0: cset w8, ne
0x6d41c4: tst w11, w10             ; (maskB & catA) != 0 ?
0x6d41c8: cset w9, ne
0x6d41cc: and w0, w8, w9           ; collide = keduanya non-nol
0x6d41d0: ret
```

Konsekuensi matematis: bila `maskBits` kepala = 0, maka `(maskA & catB) = 0` untuk **semua** B → `ShouldCollide` selalu false untuk pasangan yang melibatkan fixture kepala → **tidak ada kontak baru** yang dibuat untuk kepala. (Syarat kedua — `maskB & catA` — tidak relevan karena syarat pertama sudah 0.) Ini bukti formal pendekatan 4.

**`b2Fixture::SetFilterData` (cara "resmi" mengubah filter + refilter kontak lama):**

```
1.72.2 @ 0x6d0f64 ; 1.71.1 @ 0x6c05c0 (20 byte IDENTIK — satu pola scan untuk kedua versi)
byte: 28 10 40 79  29 00 40 f9  08 78 00 79  09 40 03 f8  01 00 00 14
0x6d0f64: ldrh w8, [x1, #8]    ; groupIndex dari struct filter (x1)
0x6d0f68: ldr x9, [x1]         ; categoryBits+maskBits (8 byte) dari struct filter
0x6d0f6c: strh w8, [x0, #0x3c] ; → fixture.groupIndex
0x6d0f70: stur x9, [x0, #0x34] ; → fixture.categoryBits+maskBits
0x6d0f74: b #0x6d0f78           ; tail-call Refilter (bendera ulang semua kontak body)
```

Struktur argumen `b2Filter` (12 byte): `categoryBits u32 @+0`, `maskBits u32 @+4`, `groupIndex i32 @+8`. Fungsi ini punya **82 `bl` caller** di binary (termasuk `0x524f7c` — dipanggil destroyer tepat setelah blok DestroyBody, kemungkinan game sendiri mengubah filter saat driver mati; dan banyak situs per-mobil `0x4c8570`, `0x4c9ea0`, `0x510f3c`/`54`/`6c`, …). `Refilter` (`0x6d0f78`) hanya dicapai lewat tail-call ini (0 `bl` langsung) — konsisten dengan `SetFilterData` sebagai satu-satunya API publik pengubah filter. Keuntungan memakai fungsi ini dibanding tulis memori mentah: `Refilter` menandai ulang kontak-kontak yang sudah ada, sehingga kontak lama yang melibatkan kepala ikut dihancurkan di step berikutnya (tulis mentah tidak me-refilter — kontak lama bertahan sampai AABB berpisah sendiri).

Koreksi terhadap catatan interim: situs `strh [sp, #0x38]` di `0x701920`/`0x701984` **BUKAN** pembangun `b2Filter` — itu kode libpng (`png_set_bKGD`, PLT stub `0x8031b0` → relokasi `png_set_bKGD`; struct di stack adalah `png_color_16`, bukan filter). Sudah dicabut dari bukti.

---

## 2. Pendekatan 1 — PINDAHKAN driver ("tempat orangnya dipindahkan")

### 2.1 Pertanyaan yang dijawab

Bisakah posisi body kepala dipindah (mis. ke dalam chassis / ke tempat yang tidak mungkin kena tanah)? Di mana posisi disimpan dan ditulis, apakah menulis `[head+0x0c]/[0x10]` tiap frame berantem dengan joint solver, dan apa efek sampingnya?

### 2.2 Bukti — di mana posisi disimpan dan siapa yang menuliskannya

- Posisi body ada di **`[b2Body+0x0c]` (x) / `[b2Body+0x10]` (y)** — dibaca langsung getter chassis (`ldp s0, s1, [x8, #0xc]`, §1.5) dan dipakai `CreateFixture` sebagai acuan proxy (`add x2, x19, #0xc`).
- Cara "resmi" menulis posisi adalah **`b2Body::SetTransform`** (teleport + sinkronisasi broadphase). Menulis float langsung ke `[body+0x0c]/[0x10]` tanpa sinkronisasi membuat AABB broadphase basi — tapi karena body kepala bergerak terus, `SynchronizeFixtures` (loop proxy di sekitar `0x6d0e80`, yang mengiterasi `[fixture+0x28]`/`[fixture+0x30]` dan memanggil AABB shape) menghitung ulang AABB dari posisi baru di step berikutnya. Praktik yang benar untuk payload: panggil `SetTransform` bila alamatnya ketemu, atau tulis posisi + panggil sinkronisasi; **jangan** tulis mentah tanpa sinkronisasi lalu berharap.
- **Joint yang mengikat kepala (bukti JSON §1.2):** `driverHeadJoint` (revolute, ±23°) + `torsoHeadDistanceJoint` (distance RIGID 0,5637 m). Pose kepala sepenuhnya ditentukan kedua joint ini. Selama keduanya hidup, kepala tidak bisa "tinggal" di dalam chassis — solver akan menariknya kembali ke pose duduk (±23° di sekitar pivot leher, pusat kepala di (−0,162, 0,593) relatif chassis).
- **Filter justru mendukung:** kepala vs chassis/roda **tidak bertabrakan** (mask kepala tidak mengandung kategori 8 — §1.1). Jadi kepala yang dipindah ke dalam chassis **tidak akan didorong keluar** oleh respons tabrakan. Satu-satunya yang "melawan" teleport adalah joint, bukan tabrakan.

### 2.3 Apakah teleport tiap frame berantem dengan joint solver?

Ya, tapi besarnya kecil — dan tidak merusak mobil. Alasannya massa: kepala ≈ 0,003 kg, torso ≈ 0,003 kg (density 0,01), sementara chassis berbobot kilogram (density 0,51, poligon besar). Impuls koreksi joint sebanding dengan massa yang dikoreksi — solver menarik kepala (ringan) kembali ke arah leher, dan reaksi ke torso/chassis (berat) praktis nol. Dampak yang tersisa:

- **Kepala bergetar/berpindah-pindah di antara step** (solver menariknya sebagian kembali tiap step, payload me-teleport ulang tiap frame). Apakah getaran ini TERLIHAT tergantung urutan sync sprite-vs-teleport: bila sprite membaca posisi SETELAH teleport (render pass sesudah update), yang tampil adalah posisi teleport — bersih. Bila sprite sync SEBELUM teleport, kepala tampak bergetar 60 Hz antara pusat chassis dan sebagian jalan ke leher. **Ini butuh probe runtime (lihat §9 butir 2)** — tidak bisa dipastikan dari statis.
- **Neck-flip berhenti terdeteksi:** deteksi neck-flip membaca sudut kepala relatif torso (pembaca flag `0x531a58` — logika achievement neckflip hanya bila hidup; sudutnya sendiri dihitung dari pose kepala). Kepala yang dipindah paksa tidak lagi berputar natural → achievement neck-flip kemungkinan tidak terpicu selama toggle ON. Ini efek samping yang bisa diterima (fitur skor, bukan kematian) — tapi harus jujur disampaikan ke user.
- **Tidak ada risiko double-destroy:** varian yang direkomendasikan (joint DIBIARKAN hidup, hanya teleport + nol-kan velocity) tidak menghancurkan apa pun — jadi jalur cleanup game (`0x560970`, `0x524f0c`) tetap berjalan normal bila flag ter-set.

Varian alternatif — hancurkan kedua joint kepala lalu teleport: fisika lebih bersih (tidak ada solver fight sama sekali; kepala jadi body bebas yang di-teleport), TAPI menghancurkan joint berarti bila flag ter-set nanti, blok detach `0x560970` akan memanggil destroy-joint pada joint yang sudah hancur (slot `0x200` tanpa pengecekan keberadaan — hanya cek `[car+0x788]` non-null dan hitungan slot `0x28` ≥ 2). Risiko double-destroy ini nyata meski kecil. **Rekomendasi: varian joint-dibiarkan-hidup sebagai implementasi default; varian hancurkan-joint hanya bila probe menunjukkan jitter tidak tertahankan.**

### 2.4 Seberapa jauh perlindungan posisi ini?

Target teleport: **pusat chassis** (`[chassisBody+0x0c]/[0x10]`). Alasan: pusat chassis adalah titik yang paling lama bertahan di atas tanah dalam segala orientasi — saat mobil terbalik bertumpu di atap, pusat chassis ~0,5 m di atas tanah; saat mobil miring, pusat chassis tetap di dalam siluet mobil. Dengan kepala di sana:

- Situs B ("kepala di bawah permukaan") → membaca posisi pusat chassis → di atas permukaan → **tidak fire** (selama mobil tidak jatuh ke jurang — fall tetap mengawasi chassis).
- Situs C (query zona tipe 7) → titik pusat chassis → tidak di dalam zona tanah → **tidak fire** (kecuali chassis sendiri masuk zona — mis. mobil tercebur ke kill-zone, yang memang seharusnya mati).
- Kill-zone (`0x4c9dfc`) + hazard (`0x4ec2a8`) → sama, membaca posisi kepala → kini posisi chassis → **tidak fire** kecuali chassis-nya sendiri yang masuk zona bahaya.
- **Tidak ditutup:** stuck (membaca kontak + kecepatan chassis — mobil terbalik diam tetap stuck), fall (Y chassis < −100), detachment (`[car+0x300]`), akumulator, countdown, stage-trigger, switch. **Jadi MOVE saja bukan god mode** — ia butuh God Mode (P0) sebagai pasangan.

Batas probabilitas: perlindungan ini **bukan absolut**. Saat mobil berguling keras / terpental, pusat chassis sesaat bisa menyentuh atau masuk sedikit ke bawah permukaan tanah (penetration sesaat sebelum solver mendorong keluar) — di frame itu situs B/C bisa membaca posisi "di bawah" dan fire. Praktiknya jendela ini kecil (1–2 frame), tapi bukan nol. Jujur: MOVE mengurangi kematian kepala dari "hampir pasti saat terbalik" menjadi "jarang, hanya saat penetrasi sesaat".

### 2.5 Desain toggle — "Driver Sembunyi 🫣"

| Aspek | Desain |
|---|---|
| **Nama toggle (diusulkan)** | **"Driver Sembunyi 🫣"** (alternatif: "Pindah Driver"). Alasan nama: yang dilihat user adalah driver "bersembunyi" di dalam mobil — kepala tidak lagi nongol di atas jok. |
| **Default** | **OFF** (sesuai aturan berdiri: semua fitur mulai OFF; user menyalakan manual). |
| **Saat ON** | Tiap frame, setelah step fisika (hook update yang sama dengan speed — panggil fungsi asli dulu, lalu teleport), payload: (1) baca posisi chassis `[chassisBody+0x0c]/[0x10]`; (2) tulis posisi kepala `[headBody+0x0c]/[0x10]` = posisi chassis (offset 0 — tepat di pusat; atau offset kecil +0,05 y agar tidak tepat di titik yang sama); (3) nol-kan linear velocity kepala `[headBody+0x50]/[0x54]` dan angular velocity `[headBody+0x58]` (supaya kepala tidak "terlempar" kembali oleh momentum); (4) bangunkan body bila tidur (flags `+0x04` bit sleep — pola yang sama dengan speed: `[body+4] \|= 2`, sleep timer 0). Joint DIBIARKAN hidup. Fail-closed: rantai pointer null / nilai NaN / \|posisi\| tidak waras → frame dilewati + log sekali (pola yang sama dengan speed v1.8). |
| **Saat dimatikan lagi (OFF)** | **Reversibel penuh, otomatis, dalam ~1 detik.** Payload berhenti menulis posisi; joint revolute + distance joint yang masih hidup menarik kepala kembali ke pose duduk (pivot leher, ±23°) secara natural lewat solver. Tidak ada state permanen yang diubah — tidak ada pointer di-null-kan, tidak ada body/joint dihancurkan, tidak ada byte di-patch (teleport adalah tulis memori per-frame, bukan patch kode). Satu-satunya "bekas": posisi kepala sesaat masih di dalam chassis sampai solver menariknya keluar — terlihat sebagai driver "muncul kembali" dari dalam mobil dalam beberapa frame. |
| **Status di overlay / JSON** | Field baru `"move": "aktif"/"nonaktif"` di `hcr_mod_status.json` + baris overlay "Driver sembunyi" (pola yang sama dengan `"p0"`, `"speed_instant"`). `cmd.json`: `"move_driver": true/false`. |
| **Kombinasi** | ✅ **+ God Mode (P0): DIREKOMENDASIKAN** — God menutup stuck/fall/detach yang tidak ditutup MOVE. ✅ **+ Filter (Driver Tembus): bermakna** — kepala yang di-teleport tidak akan menabrak tanah saat pusat chassis sesaat merosot (menutup jendela penetrasi §2.4). ✅ **+ Shrink (Driver Mungil): boleh, tapi hampir tidak ada nilai tambah** — kepala sudah di dalam chassis; radius kecil hanya mengurangi kemungkinan kepala menyembul keluar siluet saat mobil berguling. ❌ **+ Hapus Driver (varian B): TIDAK DISARANKAN** — redundan (keduanya menargetkan pemeriksaan posisi kepala yang sama) + konflik implementasi (Hapus men-null-kan `[car+0x2d0]`; MOVE butuh pointer kepala — harus diselesaikan lewat slot body `0x840`/`0x848`/`0x858`, bukan lewat `[car+0x2d0]`; bila keduanya ON, urutan terapannya rapuh). Pilih salah satu. |
| **Layak jadi toggle?** | **YA, dengan label eksperimental.** Alasan layak: reversibel penuh, tidak menghancurkan struktur apa pun, perlindungan posisi kepala nyata (4 setter), fail-closed mudah. Alasan eksperimental: butuh probe jitter (§9 butir 2) sebelum dinyatakan bersih; efek visual (driver di dalam mobil) aneh tapi bukan rusak; perlindungan tidak absolut. Bila probe menunjukkan jitter parah dan varian hancurkan-joint juga tidak diterima, toggle ini turun peringkat menjadi "jangan implementasi" — keputusan di tangan hasil probe, bukan asumsi. |

### 2.6 Yang masih dibutuhkan untuk implementasi MOVE

- Rantai pointer ke **body kepala (b2Body*)**: `[car+0x2d0]` adalah sprite, bukan body. Body kepala harus diambil dari salah satu slot `[car+0x840]`/`[car+0x848]`/`[car+0x858]` (identifikasi runtime, §9 butir 1) ATAU dari field body di dalam sprite (offset belum dipetakan — butuh REA lanjutan pada fungsi `GetPosition` slot `0x3b8`). Tanpa ini, teleport tidak bisa ditargetkan.
- Hook **pasca-step**: hook update yang ada (`0x3bd1dc`) dipakai speed untuk tulis SEBELUM step; MOVE butuh tulis SETELAH step (panggil original dulu, lalu teleport). Perlu dipastikan urutan sprite-sync vs teleport (§9 butir 2).
- Pola scan 1.71.1 untuk fungsi update (sudah ada dari speed — dipakai ulang).

---

## 3. Pendekatan 2 — HAPUS driver ("orangnya dihapus")

### 3.1 Dua varian — dan hanya satu yang layak jadi toggle

Permintaan "dihapus" punya dua pembacaan teknis yang SANGAT berbeda risikonya:

- **Varian A — HAPUS TOTAL (fisik):** panggil `DestroyBody` (`0x6d20c0`) untuk ketiga body driver `[car+0x840]`/`[car+0x848]`/`[car+0x858]` + null-kan ketiga slot + null-kan `[car+0x2d0]` (+ null-kan `[car+0x788]` untuk keamanan). Ini meniru persis apa yang dilakukan game sendiri di `0x524f0c` saat mati — hanya saja tanpa men-set flag.
- **Varian B — SEMBUNYIKAN (logika):** HANYA null-kan `[car+0x2d0]` (simpan pointer aslinya untuk restore). Body, joint, fixture, dan sprite kepala tetap hidup dan utuh — game hanya tidak bisa lagi "melihat" kepala lewat slot itu.

### 3.2 Bukti — apa yang terjadi pada tiap varian

**Varian A — game sendiri membuktikan body bisa dihancurkan saat hidup, TAPI:**
- Destroyer `0x524f0c` menghancurkan ketiga body + null-kan pointer — dan game terus berjalan setelahnya (run-end sequence). Jadi mesin Box2D + game mentoleransi ketiadaan ketiga body itu. **Namun** destroyer itu berjalan dalam konteks "flag sudah set" — semua pembaca flag sudah beralih mode (getter posisi beralih melacak bagian yang jatuh, flip-assist mati, dst — REA-2 §3.4). Bila kita menghancurkan body saat flag BELUM set (game masih mode "hidup"), ada pembaca yang tidak siap:
  - Sprite kepala di `[car+0x2d0]` menyimpan pointer body-nya sendiri (offset belum dipetakan). Bila body dihancurkan sementara sprite masih merender, `GetPosition` sprite (slot `0x3b8`) membaca body yang sudah di-free → **use-after-free** (crash atau posisi sampah). Satu-satunya yang mencegah ini adalah men-null-kan `[car+0x2d0]` juga — tapi itu justru varian B, dan sprite yang pointer-nya di-null-kan di struct car tetap ada di scene graph dan tetap merender (null-kan slot car tidak menghapus node cocos) — sprite akan merender di posisi terakhir / membeku, atau crash saat sync-nya membaca body yang hancur. **Perilaku sprite pasca-DestroyBody tidak bisa dipastikan dari statis.**
  - Joint yang menempel di body hancur ikut dihancurkan Box2D secara otomatis — itu aman. Tapi slot joint game (`[car+0x788]`) tidak di-null-kan oleh Box2D — game masih memegang pointer joint yang sudah mati → bila ada kode memanggil slot joint itu → use-after-free.
- **Irreversibel di tengah run:** `DestroyBody` tidak bisa di-undo. Body driver hanya dibuat ulang saat kendaraan di-spawn ulang (respawn / run baru). Toggle OFF di tengah run **tidak mengembalikan driver** — driver baru muncul di run berikutnya (dan payload harus menghapusnya lagi bila toggle masih ON). Ini melanggar ekspektasi dasar sebuah toggle ("matikan → kembali seperti semula").
- **Kesimpulan varian A: BISA secara teknis (game punya jalurnya), TAPI TIDAK LAYAK jadi toggle.** Alasan: irreversibel + risiko use-after-free sprite/joint yang tidak bisa dipastikan dari statis. Varian A hanya pantas sebagai eksperimen sekali-pakai dengan probe crash, bukan fitur menu.

**Varian B — bukti kuat dari getter (§1.5):**
- Null-kan `[car+0x2d0]` → getter posisi kepala mengembalikan **posisi chassis**. Semua pembaca posisi kepala (situs B, C, kill-zone, hazard — §1.4) otomatis mengukur chassis. Perlindungan posisinya **identik** dengan MOVE (kepala "diukur" di pusat chassis), tanpa teleport tiap frame, tanpa solver fight, tanpa menghancurkan apa pun.
- Kepala tetap hidup secara fisik: body + joint + fixture utuh, sprite tetap merender di pose duduk normal (sync sprite-body tidak lewat slot `[car+0x2d0]` — slot itu hanya dipakai logika car; rendering memakai scene graph). **Visual tidak berubah sama sekali** — driver tetap kelihatan duduk normal. Yang berubah hanya logika kematian yang "buta" terhadap kepala. (Ini mungkin terasa aneh bagi user yang membayangkan driver hilang secara visual — perlu dijelaskan: toggle ini menghapus driver dari *logika kematian*, bukan dari layar.)
- **Satu-satunya lubang crash:** blok detach `0x560970` membaca `[car+0x2d0]` tanpa null-check (§1.5). Skenario crash: toggle ON (slot null) → flag ter-set oleh setter lain (mis. stuck saat terbalik diam) → blok detach jalan → `[car+0x788]` non-null → `ldr x8, [x0]` pada `x0 = 0` → SIGSEGV. **Mitigasi (pilih satu):** (a) **kombinasikan dengan God Mode (P0)** — P0 mengubah `cbz` di `0x560974` jadi lompat selalu, blok detach tidak pernah jalan, lubang tertutup total; (b) null-kan juga `[car+0x788]` saat toggle ON — blok detach ter-skip di `0x56097c` (`cbz x0`) — tapi pembaca lain `[car+0x788]` belum dienumerasi, jadi mitigasi ini membawa risiko sendiri yang belum dipetakan; (c) jangan null-kan `[car+0x2d0]`, melainkan timpa dengan pointer chassis — getter akan membaca `[chassis]` sebagai "kepala" dan memanggil virtual `GetPosition` padanya… tidak, chassis adalah b2Body mentah tanpa vtable — `ldr x9, [x8]` akan membaca `m_type` (= 2) sebagai vtable → crash. **Mitigasi (a) adalah yang benar.** Toggle ini sebaiknya **direkomendasikan dipakai bersama God Mode** (atau payload menolak menyalakannya bila God Mode OFF — keputusan desain untuk builder; lihat §3.5).
- Pembaca `[car+0x2d0]` lain di luar getter + detach belum dienumerasi penuh (scan menemukan 548 situs `ldr [x?, #0x2d0]` di seluruh binary — sebagian besar field `+0x2d0` struct lain, bukan PlayerCar). Di fungsi per-mobil, yang terkonfirmasi memakai slot ini: getter `0x4f4b30` dan detach `0x5609b8`. **Sisa risiko ini hanya bisa ditutup probe runtime** (nyalakan toggle, main 1 menit, perhatikan crash — §9 butir 3).

### 3.3 Cakupan perlindungan varian B (sama dengan MOVE)

Ditutup: situs B, situs C, kill-zone, hazard (semua lewat getter → chassis). Tidak ditutup: stuck, fall, detachment, akumulator, countdown, stage-trigger, switch — sama persis dengan MOVE. **Bukan god mode sendirian; butuh God P0 sebagai pasangan.**

### 3.4 Desain toggle — "Hapus Driver 👻"

| Aspek | Desain |
|---|---|
| **Nama toggle (diusulkan)** | **"Hapus Driver 👻"** (alternatif: "Driver Hilang"). Catatan jujur untuk user: yang dihapus adalah driver dari *logika kematian* — secara visual driver tetap kelihatan duduk normal (varian B). Bila user mengharapkan driver hilang dari layar, itu varian A — yang ditolak di bawah. Nama tetap "Hapus Driver" karena itu bahasa user; deskripsi di menu harus menjelaskan efek sebenarnya. |
| **Default** | **OFF**. |
| **Saat ON (varian B)** | Payload menyimpan pointer asli `[car+0x2d0]` ke variabel (sekali, saat pertama kali diterapkan di run itu), lalu menulis `0` ke `[car+0x2d0]`. Sekali tulis — **bukan** per-frame (pointer tidak ditulis ulang game; bila game menulis ulang slot itu saat respawn, payload menerapkan lagi saat mendeteksi spawn baru — mekanisme re-apply yang sama dengan filter/shrink, §8.4). Tidak ada DestroyBody, tidak ada patch kode. |
| **Saat dimatikan lagi (OFF)** | **Reversibel penuh, instan.** Payload menulis kembali pointer asli yang disimpan ke `[car+0x2d0]`. Seketika itu juga getter kembali mengembalikan posisi kepala asli; situs B/C/kill-zone/hazard kembali aktif normal. Tidak ada yang perlu di-spawn ulang, tidak ada yang rusak permanen. Ini keunggulan utama varian B atas varian A. |
| **Syarat keamanan** | **Wajib dipasangkan dengan God Mode (P0) ATAU payload memberi peringatan.** Alasan: lubang crash blok detach `0x560970` bila flag ter-set saat slot null (§3.2). Rekomendasi desain: (a) bila God Mode ON → toggle bebas dinyalakan (lubang tertutup P0); (b) bila God Mode OFF → overlay menampilkan peringatan kecil ("disarankan nyalakan God Mode") ATAU payload otomatis men-null-kan juga `[car+0x788]` (mitigasi b — dengan risiko pembaca lain yang belum dipetakan; hanya bila probe §9 butir 3 membuktikan `[car+0x788]` aman di-null-kan). Keputusan akhir di tangan builder setelah probe — laporan ini tidak menetapkan mitigasi (b) sebagai aman. |
| **Status di overlay / JSON** | Field `"delhead": "aktif"/"nonaktif"` + baris overlay "Hapus driver". `cmd.json`: `"delete_driver": true/false`. Bila mitigasi (b) dipakai, tambah field `"delhead_joint": "ikut di-null-kan"`. |
| **Kombinasi** | ✅ **+ God Mode (P0): DIREKOMENDASIKAN / praktis wajib** (menutup lubang crash detach + menutup setter yang tidak ditutup varian B). ✅ **+ Filter (Driver Tembus): bermakna** — kepala tetap ada secara fisik (varian B tidak menghapus body); filter membuatnya tidak menabrak tanah → mengurangi kemungkinan mobil terbalik karena kepala menyangkut. ✅ **+ Shrink (Driver Mungil): boleh, redundan sebagian** — kepala tetap ada; shrink mengurangi kontaknya; filter saja sudah cukup (lihat matriks §7). ❌ **+ Pindah Driver (MOVE): TIDAK DISARANKAN** — redundan (keduanya menargetkan pemeriksaan posisi kepala) + konflik pointer (MOVE butuh pointer kepala; Hapus men-null-kannya). Pilih salah satu. |
| **Layak jadi toggle?** | **YA — varian B saja.** Alasan: implementasi paling sederhana dari keempatnya (satu tulis pointer + satu restore), reversibel instan, perlindungan posisi kepala nyata (4 setter), tidak menghancurkan struktur apa pun. Satu-satunya syarat: lubang crash detach harus ditutup (God P0). **Varian A: TIDAK LAYAK jadi toggle** — irreversibel di tengah run + risiko use-after-free sprite/joint yang tidak bisa dipastikan dari statis. Bila user tetap penasaran dengan varian A, itu eksperimen probe sekali-pakai (bukan fitur menu), dengan ekspektasi crash yang jujur. |

### 3.5 Catatan implementasi varian B untuk builder

- Simpan pointer asli **per run** (bukan sekali seumur hidup payload): kendaraan di-spawn ulang tiap run/respawn → pointer baru; payload harus menangkap nilai baru saat spawn dan menerapkan null lagi bila toggle masih ON.
- Jangan null-kan slot sebelum kendaraan ada (rantai `run+0x3a8 → vehicle → +0x258 → car` null → lewati, pola fail-closed yang sama dengan speed).
- Bila game menulis ulang `[car+0x2d0]` sendiri di tengah run (mis. saat ganti kendaraan di garasi), payload harus mendeteksi perubahan dan menerapkan lagi — cek berkala (tiap ~30 frame) sudah cukup; tulis pointer hanya bila nilainya bukan 0 dan toggle ON.

---

## 4. Pendekatan 3 — KECILKAN driver ("dikecilin SE-kecil mungkin")

### 4.1 Di mana ukuran fixture kepala didefinisikan

- **Data game:** `boringcar_model.json` — fixture kepala adalah circle **r = 0,3014** (dari loader RUBE; `modifier_props.json` punya definisi template berbeda r = 0,33 — yang dipakai Jeep adalah 0,3014 dari model kendaraan).
- **Memori runtime:** radius ada di **`[b2CircleShape+0x0c]`** (float) — shape dijangkau lewat **`[b2Fixture+0x18]`** (m_shape), fixture dijangkau lewat **`[b2Body+0x80]`** (m_fixtureList; `m_next` fixture di `+0x08` bila body punya >1 fixture). Rantai lengkap: `car → [car+0x840]/[0x848]/[0x858] (body driver) → [body+0x80] (fixtureList) → [fixture+0x18] (shape) → [shape+0x0c] (radius)`.
- **Satu-satunya fixture kepala:** body kepala punya 1 fixture (circle). Bila ragu, iterasi list dan cocokkan: shape type circle + radius ≈ 0,3014 + filter category 32.

### 4.2 Bisakah radius ditulis kecil sekali saat runtime?

**Ya.** Tulis float `0,001` (atau `0,01` — lihat §4.4 soal pilihan nilai) ke `[shape+0x0c]`. Dua hal yang perlu dipahami:

- **AABB broadphase:** mengubah radius langsung tidak memperbarui proxy AABB saat itu juga — TAPI Box2D menghitung ulang AABB dari shape di tiap step lewat `SynchronizeFixtures` (loop proxy di sekitar `0x6d0e80`: iterasi `[fixture+0x28]`/`[fixture+0x30]`, panggil AABB shape). Karena body kepala bergerak terus, AABB baru (mungil) berlaku **dalam 1 step**. Jadi shrink efektif hampir seketika.
- **Kontak yang sudah ada:** `b2Contact::Update` menghitung ulang manifold tiap step dari radius **saat ini** — begitu radius mengecil, overlap hilang → kontak berhenti menghasilkan impuls (meski objek kontaknya masih ada di list sampai AABB berpisah). Tidak ada `BeginContact` baru untuk kepala mungil.
- **Massa tidak berubah:** massa body dihitung sekali saat pembuatan fixture (density × luas). Mengecilkan radius tidak mengubah massa (tetap ~0,003 kg) — tidak ada efek samping fisika dari sisi massa. Juga tidak ada yang membaca radius untuk logika lain selain tabrakan (tidak ada pembaca radius di jalur kematian — semua setter kematian membaca posisi/kontak/timer, bukan radius).

### 4.3 Efek samping — apa yang masih "butuh" kepala berukuran normal?

- **Sensor GOAL (ballsports):** memakai fixture kategori `0x10000` (objek GOAL sendiri) — bukan fixture kepala. Tidak terpengaruh.
- **Deteksi flip / neck-flip:** membaca **sudut** kepala relatif torso (dan/atau kecepatan sudut) — bukan radius. Kepala mungil tetap berputar sama → neck-flip tetap terdeteksi (berbeda dengan MOVE yang mengubah pose). Ini keunggulan shrink atas MOVE: fitur skor tetap jalan.
- **Visual:** sprite kepala digambar dari node cocos (scale 0,96 di JSON `image`), BUKAN dari radius fixture. Mengecilkan fixture **tidak mengecilkan gambar kepala** — driver tetap kelihatan normal di layar; yang mengecil hanya "kotak tabrakan" tak terlihatnya. (Bila user mengharapkan kepala kelihatan mungil, itu urusan scale sprite — di luar pendekatan ini; perlu dijelaskan.)
- **Kepala tetap bisa "mati" secara posisi:** ini poin terpenting — **shrink tidak menutup satu pun setter kematian** (§1.4: B/C/kill-zone/hazard membaca posisi, bukan kontak; stuck membaca kontak chassis/roda). Kepala mungil tetap berada di posisi yang sama (di atas torso, di luar chassis) — saat mobil terbalik, posisi kepala tetap di bawah permukaan → situs B/C tetap fire. Shrink hanya membuat kepala **tidak pernah menyentuh** apa pun — ia tidak membuat kepala **tidak terdeteksi**.

### 4.4 Nilai radius — 0,001 vs 0,01

- `0,001` (1 mm): praktis nol kontak — bahkan debu/aspal yang menonjol tidak akan menyentuhnya. Risiko: radius 0 bisa memicu pembagian-nol di beberapa path Box2D (mis. `ComputeAABB` dengan radius 0 masih aman; tapi manifold dengan dua circle radius ~0 bisa menghasilkan normal tak terdefinisi — meski tanpa overlap, manifold tidak dihitung). Pilih `0,001` (bukan tepat 0) untuk menghindari edge case radius-nol.
- `0,01` (1 cm): masih sangat kecil (30× lebih kecil dari aslinya), tapi cukup "nyata" bagi solver bila sesuatu benar-benar menusuk titik itu. Lebih konservatif.
- **Rekomendasi: `0,001`.** Alasan: tujuannya "sekecil mungkin" (bahasa user); risiko radius-nol dihindari dengan tidak memakai 0 persis.

### 4.5 Desain toggle — "Driver Mungil 🔬"

| Aspek | Desain |
|---|---|
| **Nama toggle (diusulkan)** | **"Driver Mungil 🔬"** (alternatif: "Kepala Mungil"). Nama jujur: yang mengecil adalah hitbox kepala, bukan gambar driver (lihat §4.3). |
| **Default** | **OFF**. |
| **Saat ON** | Payload (1) identifikasi body kepala di antara `[car+0x840]`/`[car+0x848]`/`[car+0x858]` dengan memindai fixture-nya (circle, radius ≈ 0,3014 ± toleransi, category 32 — identifikasi runtime, §9 butir 1); (2) simpan radius asli (0,3014); (3) tulis `0,001` ke `[shape+0x0c]`; (4) terapkan ulang bila fixture dibuat ulang (respawn — cek berkala tiap ~30 frame: bila radius kembali ≈ 0,3014 dan toggle ON → tulis lagi). Sekali tulis per spawn sudah cukup (tidak perlu per-frame — radius tidak ditulis ulang game tiap frame). |
| **Saat dimatikan lagi (OFF)** | **Reversibel penuh, dalam 1 step.** Payload menulis kembali `0,3014` ke `[shape+0x0c]`. AABB dihitung ulang di step berikutnya; kontak kepala kembali normal seketika. Tidak ada state permanen. |
| **Status di overlay / JSON** | Field `"shrink": "aktif (0,001)"/"nonaktif"` + baris overlay "Driver mungil". `cmd.json`: `"shrink_driver": true/false`. |
| **Kombinasi** | ✅ **+ God Mode (P0): boleh** — God yang benar-benar mencegah kematian; shrink hanya mengurangi kepala menyangkut. ✅ **+ Filter (Driver Tembus): boleh, tapi redundan** — filter=0 sudah menghilangkan semua kontak; shrink tidak menambah apa-apa di atasnya (kepala sudah tidak bertabrakan). Bila keduanya ON, yang bekerja efektif hanya filter. ✅ **+ Hapus (varian B): boleh** — mekanisme berbeda (shrink = kontak, hapus = posisi logika); tidak ada konflik pointer. ✅ **+ Pindah (MOVE): boleh, nilai tambah kecil** — kepala sudah di dalam chassis; radius kecil hanya mengurangi kemungkinan kepala menyembul keluar siluet saat berguling. |
| **Layak jadi toggle?** | **YA — dengan ekspektasi yang jujur.** Alasan layak: implementasi paling aman (satu tulis float + restore), reversibel instan, tidak menyentuh struktur/pointer/joint, tidak ada risiko crash yang teridentifikasi, fitur skor (neck-flip) tetap jalan. Alasan ekspektasi harus dijaga: **toggle ini BUKAN god mode** — driver tetap bisa mati lewat B/C/stuck/dll. Nilainya adalah "kepala tidak pernah menyangkut di tanah/batu" (mengurangi mobil terbalik karena kepala tersangkut) + seru-seruan. Bila user menyalakannya sambil berharap tidak mati, ia akan kecewa — deskripsi menu harus jelas: "hitbox kepala jadi 1 mm — kepala hampir tidak pernah menyentuh apa pun (bukan god mode)". |

---

## 5. Pendekatan 4 — MATIKAN TOTAL deteksi hit body driver (filter fixture = 0)

### 5.1 Bukti — di mana filter disimpan, siapa yang membuat/meng-set-nya

- **Penyimpanan:** `b2Filter` di **`[b2Fixture+0x34]`** — `categoryBits u32 +0x34`, **`maskBits u32 +0x38`**, `groupIndex i32 +0x3c` (§1.6). Nilai awal kepala (dari JSON via loader RUBE): cat 32, mask 63430, group 0.
- **Pembuatan:** loader fixture RUBE (sekitar `0x663afc` — string `"filter-maskBits"` @ `0x1f5347`, `"filter-categoryBits"` @ `0x1faa3e`) membaca JSON → mengisi `b2FixtureDef` → `b2Body::CreateFixture` (`0x6cf3bc`) → `b2Fixture::Create` (`0x6d0b5c`) menyalin filter def ke fixture (`stur x9, [x0, #0x34]` + `strh w8, [x0, #0x3c]`, §1.6). Filter di-set **sekali saat load** dari JSON — game tidak mengubah filter kepala di tengah run (tidak ada `bl SetFilterData` yang menargetkan fixture kepala dalam permainan normal — 82 caller `SetFilterData` adalah untuk objek/stage lain; yang relevan: `0x524f7c` dipanggil destroyer saat mati, kemungkinan mengubah filter bagian yang mati).
- **Fungsi pengubah:** `b2Fixture::SetFilterData` — **1.72.2 @ `0x6d0f64`, 1.71.1 @ `0x6c05c0`**, byte 20 IDENTIK (`28 10 40 79 29 00 40 f9 08 78 00 79 09 40 03 f8 01 00 00 14`), 82 caller, tail-call `Refilter` (`0x6d0f78` / `0x6c05d4`) — §1.7. Argumen: pointer ke struct 12 byte `{cat u32, mask u32, group i32}`.
- **Penegak:** `b2ContactFilter::ShouldCollide` — **1.72.2 @ `0x6d4188`, 1.71.1 @ `0x6c37e8`**, logika stock (§1.7). Dengan `maskBits = 0`: `(maskA & catB) = 0` untuk semua B → **tidak ada kontak baru** untuk fixture kepala, terhadap fixture apa pun.

### 5.2 Cara mematikan — tulis langsung vs panggil SetFilterData

| Cara | Perintah | Kelebihan | Kekurangan |
|---|---|---|---|
| **A. Panggil `SetFilterData` (direkomendasikan)** | Bangun struct 12 byte `{32, 0, 0}` di stack payload → `bl 0x6d0f64(fixture, &filter)` | "Resmi" — `Refilter` menandai ulang kontak yang sudah ada → kontak lama kepala ikut dihancurkan di step berikutnya (efek seketika, termasuk bila kepala sedang bersentuhan saat toggle dinyalakan) | Butuh alamat fungsi (pattern-scan — pola 20 byte sudah ada, identik di kedua versi) + pemanggilan fungsi game dari payload (pola yang sama dengan Dobby-hook yang sudah dipakai; risiko rendah karena fungsi leaf kecil tanpa prologue) |
| **B. Tulis memori langsung** | `str wzr, [fixture+0x38]` | Paling sederhana; tidak butuh alamat fungsi | Kontak yang **sudah ada** saat toggle dinyalakan TIDAK di-refilter — bertahan sampai AABB berpisah sendiri (bisa 1–2 detik bila kepala sedang menempel di tanah). Kontak **baru** tetap dicegah (ShouldCollide dicek saat pasangan broadphase baru terbentuk). |

**Rekomendasi: cara A** (SetFilterData) — selisih kerumitannya kecil, hasilnya bersih (kontak lama ikut hilang). Cara B sebagai fallback bila pattern-scan SetFilterData gagal (status jujur `"pattern_filter": "gagal"` + toggle tetap bisa jalan dengan catatan kontak lama).

### 5.3 Apakah ini mematikan SEMUA kontak kepala tanpa mematikan kontak chassis/roda?

**Ya — selektif penuh.** Filter adalah properti **per-fixture**, bukan per-body atau per-world. Yang diubah hanya fixture kepala (fixture8, cat 32). Chassis (cat 8, mask 46022), roda (cat 8), torso (cat 32, mask 0 — sudah ghost), dan ground (cat 64) tidak disentuh → tabrakan mobil dengan tanah tetap normal, mobil tetap bisa jalan, roda tetap menapak. Satu-satunya yang berubah: kepala menjadi "hantu" — lewat menembus tanah, batu, dan objek stage tanpa tabrakan maupun `BeginContact`.

### 5.4 Apakah kategori kepala muncul di contact handler — dan apakah itu mengubah kesimpulan?

Ya, muncul — dan **tidak** mengubah kesimpulan. Handler kontak `0x3b0604` membandingkan kategori dengan `0x20` (32) di `0x3b113c`/`0x3b1178`:

```
0x3b112c: cmp w8, #0x10
0x3b1134: cmp w8, #0x800
0x3b113c: cmp w8, #0x20      ; kategori 32 = kepala/torso
0x3b1140: b.ne #0x3b115c
0x3b1144: ... w8 = 1 (boolean "kategori ini termasuk {0x10, 0x800, 0x20}")
...
0x3b11a0: ldr x26, [x23]
0x3b11b0: ldr w9, [x25, #0x14]
0x3b11c0: cmp w9, #0xa
0x3b11c8: b.ne #0x3b1260
0x3b11cc: ldr x21, [x26, #0x48]
0x3b11dc: bl #0x5ca00c
0x3b11e8: bl #0x5c9eb8       ; dua panggilan bila tipe objek lawan == 10
```

Cabang ini **tidak menulis flag kematian** (`strb [x19, #0x32f]` tidak ada di sekitarnya) — ia mengklasifikasikan kontak (boolean + dua panggilan bila tipe lawan == 10; kemungkinan SFX/partikel/skor, identitas pastinya belum dipetakan). Dengan filter=0, kontak kepala tidak pernah sampai ke handler ini — cabang klasifikasi itu pun tidak jalan untuk kepala. Tidak ada yang hilang dari sisi kematian (karena cabang ini bukan jalur kematian), dan kemungkinan yang hilang hanyalah efek suara/partikel saat kepala menyentuh sesuatu (belum terbukti — butuh probe: apakah ada suara "buk" saat kepala kena tanah yang hilang saat toggle ON).

### 5.5 Apa yang masih bisa membunuh driver bila filter kepala = 0?

**Semua yang tidak butuh kontak kepala** — yaitu semua 15 setter kecuali yang sudah di-NOP v4:

- **Situs B** (posisi kepala di bawah permukaan) — membaca posisi, bukan kontak → **tetap fire**.
- **Situs C** (query spasial zona tipe 7) — membaca posisi lewat query objek game sendiri (`0x3a5a94` mengiterasi list objek `[x0+0x40]` dengan virtual min/max, BUKAN Box2D — dibuktikan §1.5/REA-3 interim) → **tetap fire**.
- **Stuck** (`0x5053f4`) — membaca bitmask kontak **chassis/roda** + kecepatan chassis → **tetap fire** (dan ini jalur yang paling mungkin membunuh user).
- **Fall** (`0x4efae4`) — posisi-Y chassis → **tetap fire**.
- **Detachment** (`0x50e570`) — jarak objek `[car+0x300]` → **tetap fire**.
- **Akumulator** (`0x3d488c`), **kill-zone** (`0x4c9dfc` — posisi kepala → tetap fire), **hazard** (`0x4ec2a8` — jarak kepala → tetap fire), **countdown** (`0x52d610`), **stage-trigger** (`0x4cb98c`), **switch** (`0x3ab7b0`) → **tetap fire**.
- **GOAL** (`0x3b0ddc`) — sudah di-NOP v4; tidak terkait kepala.

Jadi jawaban jujur untuk pertanyaan user ("hit body-nya deteksinya dimatikan total — bisa?"): **tabrakannya bisa dimatikan total; deteksi kematiannya tidak** — karena deteksi kematian game ini tidak berbasis tabrakan kepala. Filter=0 membuat kepala menjadi hantu, bukan membuat driver abadi.

### 5.6 Desain toggle — "Driver Tembus 💨"

| Aspek | Desain |
|---|---|
| **Nama toggle (diusulkan)** | **"Driver Tembus 💨"** (alternatif: "Tanpa Tabrakan Driver" / "Driver Hantu 👻"). Nama jujur: kepala menembus segala hal — bukan "tidak bisa mati". |
| **Default** | **OFF**. |
| **Saat ON** | Payload (1) identifikasi fixture kepala (sama seperti shrink — pindai 3 body driver, cocokkan circle r≈0,3014 cat 32, §9 butir 1); (2) simpan filter asli `{32, 63430, 0}`; (3) panggil `SetFilterData(fixture, {32, 0, 0})` (cara A; fallback cara B bila pola tidak ketemu); (4) terapkan ulang bila fixture dibuat ulang (respawn — cek berkala tiap ~30 frame: bila `maskBits` kembali 63430 dan toggle ON → panggil lagi). |
| **Saat dimatikan lagi (OFF)** | **Reversibel penuh, dalam 1 step.** Payload memanggil `SetFilterData(fixture, {32, 63430, 0})` (filter asli yang disimpan). `Refilter` membuat kontak baru bisa terbentuk lagi begitu AABB kepala bersentuhan dengan sesuatu (kontak dibuat ulang oleh broadphase saat overlap — tidak perlu respawn). Tidak ada state permanen. |
| **Status di overlay / JSON** | Field `"filter": "aktif (mask 0)"/"nonaktif"` + `"pattern_filter": "ok"/"gagal"` + baris overlay "Driver tembus". `cmd.json`: `"filter_driver": true/false`. |
| **Kombinasi** | ✅ **+ God Mode (P0): DIREKOMENDASIKAN** — God yang menutup semua setter; filter hanya menghilangkan gangguan fisik kepala. ✅ **+ Pindah (MOVE): bermakna** — kepala yang di-teleport tidak akan menabrak tanah saat pusat chassis sesaat merosot (menutup jendela penetrasi MOVE). ✅ **+ Hapus (varian B): bermakna** — mekanisme berbeda (filter = kontak, hapus = posisi logika); tidak ada konflik. ✅ **+ Shrink (Driver Mungil): boleh, tapi redundan total** — filter=0 sudah menghilangkan semua kontak; radius kecil tidak menambah apa-apa. Bila keduanya ON, yang bekerja efektif hanya filter; bila filter dimatikan sementara shrink tetap ON, kepala kembali punya kontak tapi dengan radius 1 mm (perilaku fallback yang masuk akal). |
| **Layak jadi toggle?** | **YA — dan ini implementasi paling bersih dari keempatnya.** Alasan: memakai API resmi game (`SetFilterData`, 82 caller — pola yang sudah dipakai game sendiri), selektif per-fixture (chassis/roda tidak tersentuh), reversibel penuh via API yang sama, tidak ada pointer di-null-kan / joint dihancurkan / body dihapus, preseden di data game (torso sudah mask=0). Satu-satunya yang harus dijaga: **ekspektasi** — toggle ini mematikan tabrakan, bukan kematian. Deskripsi menu harus jelas: "kepala menembus tanah & rintangan — tidak menabrak apa pun (bukan god mode)". |

### 5.7 Yang masih dibutuhkan untuk implementasi FILTER (dan SHRINK)

- **Identifikasi fixture kepala saat runtime** (§9 butir 1): pindai ketiga slot body driver `[car+0x840]`/`[car+0x848]`/`[car+0x858]` → `[body+0x80]` fixtureList → cocokkan circle r≈0,3014 + cat 32. Tanpa identifikasi ini, payload tidak tahu fixture mana yang diubah (ketiga slot belum dipetakan mana-yang-kepala).
- **Pola scan `SetFilterData`:** 20 byte `28 10 40 79 29 00 40 f9 08 78 00 79 09 40 03 f8 01 00 00 14` — IDENTIK di 1.71.1 (`0x6c05c0`) dan 1.72.2 (`0x6d0f64`). Satu pola untuk kedua versi (verifikasi keunikan dengan simulasi scan seperti v1.7 — pola harus tepat 1 hit per binary; bila >1 hit, persempit dengan konteks sekitar).
- **Pola scan 1.71.1 untuk rantai car** (sudah ada dari v1.7/v1.8 — dipakai ulang).

---

## 6. Bonus — pendekatan ke-5 (dan varian lain yang dievaluasi)

### 6.1 Jadikan fixture kepala SENSOR (`isSensor = 1`, `[fixture+0x40]`)

**Evaluasi: TIDAK direkomendasikan — lebih lemah dari filter, tanpa keuntungan.**

Dalam Box2D stock, fixture sensor **tetap** membuat kontak dan **tetap** memanggil `BeginContact` (hanya respons tabrakan fisiknya yang dimatikan). Jadi sensor-izing kepala: (a) tidak menghentikan handler kontak melihat sentuhan kepala (cabang klasifikasi `0x3b113c` tetap jalan — bila ada efek suara/partikel, tetap jalan); (b) tidak menghentikan satu pun setter kematian posisi (B/C/kill-zone/hazard tetap membaca posisi); (c) secara fisik sama dengan filter (tidak ada dorongan), tapi dengan kontak yang tetap ada (lebih banyak kerja untuk game, tanpa manfaat). Satu-satunya perbedaan vs filter: sensor masih "mendengarkan" sentuhan. Untuk tujuan mencegah kematian, sensor adalah **filter yang lebih buruk** — tidak ada alasan memilihnya. Cara implementasi (bila tetap mau): tulis byte `1` ke `[fixture+0x40]` (isSensor) — reversibel (tulis `0` kembali). **Verdict: jangan implementasi; filter sudah mencakup dan melampaui ini.**

### 6.2 Hancurkan HANYA `torsoHeadDistanceJoint` (kepala menggantung di pivot leher)

**Evaluasi: TIDAK cukup sendirian — hanya berguna sebagai sub-langkah MOVE.**

Bila distance joint dihancurkan sementara revolute joint dibiarkan, kepala menggantung di pivot leher (torso + (0, 0,2873)) dengan ayunan ±23° — pusat kepala tetap di sekitar (−0,162, 0,571), **di atas torso, di luar chassis**. Saat mobil terbalik, kepala tetap menjadi titik terendah → situs B/C tetap fire. Jadi pendekatan ini tidak melindungi apa pun sendirian. Nilainya hanya sebagai bagian dari MOVE varian "hancurkan joint" (§2.3): dengan distance joint hancur + revolute dipertahankan, teleport ke pusat chassis lebih mudah (solver hanya melawan revolute, bukan distance rigid). **Verdict: bukan toggle sendiri; catat sebagai opsi implementasi MOVE.**

### 6.3 Hook `BeginContact` game dan buang kontak yang melibatkan fixture kepala

**Evaluasi: BISA, tapi strictly lebih buruk dari filter.**

Handler kontak game (`0x3b0604`, dan `0x4f4b68` yang diduga `BeginContact`) bisa di-hook (Dobby) untuk mengabaikan pasangan kontak yang salah satu fixturenya adalah fixture kepala. Hasil akhirnya **identik** dengan filter=0 (tidak ada kontak kepala yang diproses game) — tapi dengan biaya: hook fungsi hot-path yang dipanggil tiap kontak di seluruh dunia (bukan hanya kepala), risiko salah identifikasi argumen fixture, dan risiko crash bila signature handler salah ditebak. Filter mencapai hasil yang sama dengan **satu tulis filter** tanpa hook. **Verdict: jangan implementasi; filter adalah cara yang benar untuk ini.**

### 6.4 Ubah `categoryBits` kepala jadi 0 (bukan `maskBits`)

**Evaluasi: varian dari pendekatan 4, bukan pendekatan baru.**

`ShouldCollide` butuh KEDUA syarat: `(maskA & catB) != 0` DAN `(maskB & catA) != 0`. Menol-kan `categoryBits` kepala (syarat kedua = 0 untuk semua B) juga mematikan semua kontak kepala — hasil identik dengan menol-kan `maskBits`. Bedanya: bila suatu saat game mengubah mask kepala (tidak ada bukti ia melakukannya), cat=0 tetap melindungi; sebaliknya mask=0 juga tetap melindungi bila game mengubah cat. Keduanya setara; mask=0 dipilih karena `SetFilterData` dengan `{32, 0, 0}` mempertahankan kategori asli (lebih mudah dibaca di log/debug — fixture tetap teridentifikasi sebagai kategori 32). **Verdict: catat sebagai alternatif implementasi filter; tidak perlu toggle sendiri.**

### 6.5 Bekukan kepala dengan menulis posisi ke titik aman DINAMIS (mis. 1 m di atas chassis)

**Evaluasi: varian dari MOVE, bukan pendekatan baru.**

Target teleport tidak harus pusat chassis — bisa titik di atas chassis (mis. chassis + (0, 1,0)). Kelebihannya: kepala lebih jauh dari tanah saat terbalik (margin lebih besar dari penetrasi sesaat). Kekurangannya: kepala melayang 1 m di atas mobil — visual lebih aneh (driver terbang di atas mobil), dan joint solver melawan lebih keras (jarak dari pose natural lebih jauh → koreksi lebih besar → jitter lebih terlihat). Pusat chassis adalah kompromi terbaik (margin cukup + visual paling tidak aneh). **Verdict: catat sebagai parameter tuning MOVE (offset teleport configurable), bukan toggle sendiri.**

---

## 7. Matriks kombinasi — toggle mana boleh digabung

Keputusan user: keempat toggle independen, bisa dikombinasikan bila aman. Matriks ini yang menentukan "bila aman".

| Kombinasi | Status | Alasan |
|---|---|---|
| **God Mode (P0) + apa pun** | ✅ **Direkomendasikan untuk semua** | God bekerja di titik akibat (blok destroy/detach); keempat toggle bekerja di titik pemicu/posisi/kontak. Tidak ada state bersama, tidak ada konflik. God menutup semua yang tidak ditutup keempat toggle (stuck/fall/detach/akumulator/dll) — dan menutup lubang crash Hapus-B (§3.2). |
| **Pindah + Hapus** | ❌ **Tidak disarankan** | Redundan (keduanya menargetkan pemeriksaan posisi kepala yang sama) + konflik implementasi (Hapus men-null-kan `[car+0x2d0]`; Pindah butuh pointer kepala — harus lewat slot body `0x840`+, rapuh). Pilih salah satu. |
| **Pindah + Filter** | ✅ **Bermakna** | Filter menutup jendela penetrasi MOVE (kepala yang di-teleport tidak menabrak tanah saat pusat chassis sesaat merosot). |
| **Pindah + Shrink** | ⚠️ Boleh, nilai tambah kecil | Kepala sudah di dalam chassis; radius kecil hanya mengurangi kemungkinan kepala menyembul keluar siluet saat berguling. Aman, tapi hampir tidak ada efek. |
| **Hapus + Filter** | ✅ **Bermakna** | Mekanisme berbeda (Hapus = posisi logika, Filter = kontak). Kepala tetap ada secara fisik (Hapus-B tidak menghapus body) → filter mencegahnya menyangkut di tanah. |
| **Hapus + Shrink** | ⚠️ Boleh, redundan sebagian | Sama seperti Hapus+Filter tapi lebih lemah (shrink hanya mengurangi kontak, bukan menghilangkan). Aman. |
| **Filter + Shrink** | ⚠️ Boleh, **redundan total** | Filter=0 sudah menghilangkan semua kontak; shrink tidak menambah apa-apa. Tidak ada risiko — hanya tidak bermakna. Perilaku fallback masuk akal: bila filter dimatikan sementara shrink tetap ON, kepala kembali punya kontak tapi radius 1 mm. |
| **Keempatnya sekaligus (tanpa God)** | ⚠️ Boleh, tapi **tetap bukan god mode** | Stuck/fall/detach/akumulator/countdown/stage-trigger/switch tetap aktif → driver tetap bisa mati (terbalik diam → stuck). Jangan jual kombinasi ini sebagai god mode. |
| **Keempatnya + God** | ✅ **Kombinasi maksimum** | Semua jalur pemicu posisi/kontak ditutup + semua akibat ditutup. Inilah "god mode v6" yang sebenarnya: God (P0) sebagai fondasi + 4 toggle sebagai lapis. |

**Aturan praktis untuk menu:** tidak ada pasangan yang crash bila digabungkan (semua kombinasi "aman" dalam arti tidak crash — kecuali Hapus-B tanpa God, yang punya lubang crash bila flag ter-set, §3.2). Yang ada adalah pasangan **redundan** (Filter+Shrink, Pindah+Hapus) — menu tidak perlu melarangnya secara teknis; cukup tidak merekomendasikannya (atau biarkan user mencoba — tidak ada yang rusak).

---

## 8. Rekomendasi utama — god mode v6

### 8.1 Peringkat toggle (untuk mencegah kematian)

| Peringkat | Toggle | Alasan |
|---|---|---|
| 1 | **Hapus Driver (varian B)** | Perlindungan posisi kepala (4 setter) + implementasi paling sederhana (satu tulis pointer + restore) + reversibel instan + tidak ada solver fight. Satu-satunya syarat: pasangkan dengan God P0 (lubang crash detach). |
| 2 | **Driver Sembunyi (MOVE)** | Perlindungan posisi kepala yang sama (4 setter), tanpa null-kan pointer (tidak ada lubang crash detach). Harganya: hook per-frame + risiko jitter visual (butuh probe) + perlindungan tidak absolut (jendela penetrasi). |
| 3 | **Driver Tembus (Filter)** | Implementasi paling bersih (API resmi game) + selektif + reversibel. Tapi **nol** perlindungan kematian — nilainya adalah menghilangkan gangguan fisik kepala, bukan mencegah mati. |
| 4 | **Driver Mungil (Shrink)** | Paling aman (satu tulis float), tapi paling lemah — versi probabilistik dari filter, tanpa keunggulan lain kecuali neck-flip tetap jalan (itu pun filter juga tidak merusak neck-flip — neck-flip membaca sudut, bukan kontak). |

### 8.2 Kandidat implementasi per toggle (untuk builder, versi setelah v1.9)

| Toggle | Mekanisme | Alamat / pola (1.72.2) | Alamat / pola (1.71.1) |
|---|---|---|---|
| Driver Sembunyi | Teleport per-frame pasca-step: `[headBody+0x0c]/[0x10]` = `[chassisBody+0x0c]/[0x10]`; nol-kan `[headBody+0x50]/[0x54]` + `[headBody+0x58]` | Rantai car sudah ada (v1.8); body kepala dari slot `0x840`/`0x848`/`0x858` (identifikasi runtime §9.1) | Sama (rantai car sudah ada) |
| Hapus Driver | Tulis `0` ke `[car+0x2d0]` (simpan pointer asli); restore saat OFF | Slot `+0x2d0` (sudah dikenal) | Sama |
| Driver Mungil | Tulis `0,001` ke `[shape+0x0c]`; restore `0,3014` saat OFF | Rantai: body → `[+0x80]` fixtureList → `[+0x18]` shape → `[+0x0c]` radius | Sama |
| Driver Tembus | `SetFilterData(fixture, {32, 0, 0})`; restore `{32, 63430, 0}` saat OFF | `SetFilterData` @ `0x6d0f64` | `SetFilterData` @ `0x6c05c0` |
| (pola scan) | Pola SetFilterData (20 byte, identik kedua versi) | `28 10 40 79 29 00 40 f9 08 78 00 79 09 40 03 f8 01 00 00 14` | sama |

### 8.3 Urutan implementasi yang disarankan

1. **Driver Tembus (Filter) dulu** — membuktikan rantai identifikasi fixture kepala (§9.1) dengan risiko paling kecil; pola scan sudah ada dan identik di kedua versi; hasilnya langsung terlihat (kepala menembus tanah).
2. **Hapus Driver (varian B)** — memakai rantai car yang sudah ada; satu tulis pointer; validasi keamanan lewat probe §9.3 (dengan God ON dulu).
3. **Driver Sembunyi (MOVE)** — butuh hook pasca-step + probe jitter; paling banyak tuning.
4. **Driver Mungil (Shrink)** — terakhir (paling kecil nilainya; memakai identifikasi fixture yang sama dengan Filter, jadi murah bila Filter sudah jalan).

### 8.4 Kebutuhan bersama keempat toggle (untuk builder)

- **Identifikasi body/fixture kepala saat runtime** (§9.1) — prasyarat Filter + Shrink + MOVE.
- **Re-apply saat spawn/respawn:** kendaraan (body/fixture/joint) dibuat ulang tiap run/respawn → filter/radius/pointer kembali ke nilai JSON. Payload harus memeriksa berkala (tiap ~30 frame cukup — murah: 3 body × 1 fixture) dan menerapkan ulang bila nilai sudah kembali ke default sementara toggle ON. Untuk Hapus-B: periksa `[car+0x2d0]` berkala (bila bukan 0 dan toggle ON → null-kan lagi). Untuk MOVE: per-frame (sudah sifatnya).
- **Status JSON + overlay:** field baru `"move"`, `"delhead"`, `"shrink"`, `"filter"` (aktif/nonaktif) + `"pattern_filter"` (ok/gagal) di `hcr_mod_status.json`; baris overlay masing-masing; `cmd.json`: `"move_driver"`, `"delete_driver"`, `"shrink_driver"`, `"filter_driver"` (boolean, default false). Reset/disarm (ModInjector, onDestroy, doExit) ikut memperbarui field baru — pola yang sama dengan speed/torsi v1.8.
- **Fail-closed di mana-mana:** rantai pointer null / nilai NaN / nilai tidak waras → lewati + log sekali (pola v1.8). Toggle tidak boleh crash game bila game belum spawn / kendaraan berganti / versi game berubah.
- **Pattern-scan, bukan hardcode:** semua alamat fungsi (SetFilterData, update) dicari via pola seperti v1.7/v1.8; alamat slot struct (`+0x2d0`, `+0x840`, dsb) adalah offset layout — tetap seperti pola yang sudah dipakai (offset struct stabil antar versi 1.71.1→1.72.2 kecuali pergeseran +0x18 yang sudah ditangani pola `_1722`).

---

## 9. Probe runtime yang dibutuhkan dari HP user (POCO X6 Pro)

Semua probe memakai build berisi toggle (atau build probe khusus bila builder memilih begitu). Urutan sesuai kebutuhan implementasi.

1. **Identifikasi body kepala (PALING PENTING — prasyarat Filter/Shrink/MOVE).** Probe (bisa dilakukan payload sendiri + dilaporkan ke status/log, tanpa perlu mata user): untuk tiap slot `[car+0x840]`/`[car+0x848]`/`[car+0x858]`, baca `[body+0x80]` (fixtureList) → fixture → `[fixture+0x18]` (shape) → baca type + radius `[shape+0x0c]` + filter cat `[fixture+0x34]`; laporkan ketiganya (posisi body `[body+0x0c]/[0x10]` juga). **Keputusan yang diambil dari probe ini:** slot mana yang merupakan body kepala (yang fixturenya circle r≈0,3014 cat 32). Tanpa ini, Filter/Shrink/MOVE tidak bisa ditargetkan.
2. **MOVE — jitter atau bersih?** Nyalakan "Driver Sembunyi" → main 30 detik (jalan biasa + lompat + terbalik). Perhatikan: apakah kepala tampak bergetar/berkedip antara pusat chassis dan leher, atau diam rapi di dalam mobil? Apakah ada suara/gangguan handling? **Keputusan:** bila bersih → MOVE layak penuh; bila bergetar → coba varian hancurkan-joint, atau turunkan prioritas MOVE.
3. **Hapus-B — aman tanpa crash? (PALING KRITIS untuk keamanan.)** Tahap A (wajib): God Mode ON + Hapus ON → main 2 menit termasuk sengaja terbalik diam 10 detik (memicu stuck → flag set → blok detach di-skip P0). Harus **tidak crash**. Tahap B (hanya bila builder ingin validasi mitigasi tanpa God — dan user bersedia ambil risiko crash sekali): God OFF + Hapus ON → terbalik diam sampai flag set → perhatikan apakah game crash (lubang `0x5609bc`) atau selamat. **Keputusan:** bila tahap A lolos → Hapus-B rilis dengan rekomendasi "pakai bersama God"; bila tahap B juga lolos (tidak crash) → lubang detach ternyata tidak terpicu di praktik (mis. `[car+0x788]` ternyata null saat itu) → Hapus-B boleh standalone. Bila tahap B crash → Hapus-B **wajib** God (atau mitigasi b).
4. **Filter/Shrink — konfirmasi efek + konfirmasi batas.** Nyalakan "Driver Tembus" → arahkan kepala ke tanah/batu → kepala harus menembus (tidak menabrak). Lalu (dengan God OFF, hati-hati): tabrakkan kepala → driver **tetap bisa mati** (situs B/C) — ini BUKAN kegagalan toggle; ini bukti yang diharapkan bahwa filter bukan god mode. Sampaikan ke user sebelum tes supaya tidak dikira toggle rusak.
5. **Suara/partikel kepala (opsional):** dengan Filter ON, apakah ada suara "buk"/partikel yang hilang saat kepala menyentuh tanah (cabang `0x3b113c`)? Bila ada yang hilang, catat sebagai efek samping kosmetik.
6. **Probe lama yang tetap berlaku (REA-2 §8):** gejala visual persis saat "mati"; tes diskriminasi stuck vs detach (balik di tanah datar, diam 10 dtk); log `dflag`/`dtimer`/`gsrc` saat kejadian; flip-back probe tahap 2 (menunggu persetujuan user).

---

## 10. Batas kejujuran — apa yang terbukti, apa yang masih dugaan

### Terbukti dari disassembly / data game (keyakinan tinggi)

- Layout `b2Fixture` (filter cat/mask/group di `+0x34`/`+0x38`/`+0x3c`, 32-bit), `b2Body` (posisi `+0x0c`, velocity `+0x50`, fixtureList `+0x80`), `b2CircleShape` (radius `+0x0c`) — dibaca dari `CreateFixture`/`Create`/`ShouldCollide`/getter.
- `ShouldCollide` (`0x6d4188` / `0x6c37e8`) logika stock; mask=0 → tidak ada kontak baru untuk fixture itu.
- `SetFilterData` (`0x6d0f64` / `0x6c05c0`, 20 byte identik, 82 caller, tail-call Refilter) — cara resmi ubah filter.
- Getter posisi kepala (`0x4f4b30`) null-check `[car+0x2d0]` → fallback chassis.
- Blok detach (`0x560970`) membaca `[car+0x2d0]` tanpa null-check (gated flag + `[car+0x788]`).
- Situs C (`0x3a5a94`) adalah query list objek game sendiri (bukan Box2D) — filter/radius tidak memengaruhinya.
- Data Jeep (`boringcar_model.json`): fixture kepala cat 32 mask 63430 r=0,3014; torso mask 0; kepala tidak bertabrakan dengan chassis/roda/torso; joint driver (revolute ±23° + distance rigid 0,5637 m); torso praktis dilas ke chassis (±1°).
- Cabang kategori `0x20` di handler kontak (`0x3b113c`) tidak menulis flag kematian.
- Peta 15 setter + apa yang dibaca masing-masing (§1.4) — dari REA-2 + disassembly REA-3.
- Koreksi: situs `strh [sp, #0x38]` di `0x701920` adalah kode libpng (`png_set_bKGD`), bukan pembangun filter — sudah dicabut.
- Koreksi: `torsoHeadDistanceJoint` tidak punya `frequencyHz` (rigid), bukan "freq 5".
- Koreksi: field filter 32-bit (bukan u16 packed) — offset sama, lebar berbeda.

### Masih dugaan / inferensi kuat (butuh konfirmasi runtime)

- Pemetaan mana dari `[car+0x840]`/`[car+0x848]`/`[car+0x858]` yang merupakan body kepala (inferensi kuat "ketiganya body driver" dari konteks destroyer; mana-yang-kepala belum terbukti) — probe §9.1.
- `[car+0x2e0]`/`[car+0x2e8]` = body roda (dugaan dari pemakaian handler kontak untuk bitmask stuck).
- `[car+0x788]` = joint driver (dugaan dari pemakaian blok detach).
- Perilaku sprite kepala pasca-DestroyBody varian A (use-after-free atau beku) — tidak bisa dipastikan dari statis; alasan varian A ditolak sebagai toggle.
- Urutan sync sprite vs teleport MOVE (apakah kepala tampil bersih atau bergetar) — probe §9.2.
- Apakah cabang `0x3b113c` menghasilkan suara/partikel yang akan hilang bila filter ON — probe §9.5.
- Fungsi `SynchronizeFixtures` menghitung ulang AABB dari radius baru dalam 1 step — inferensi dari Box2D stock + loop proxy yang teramati di `0x6d0e80`; belum dibuktikan untuk build ini secara langsung.
- Identitas pasti `[car+0x300]` (objek detachment), `[car+0x410]` (objek detach situs B), makna `[car+0x519]`, pemicu akumulator `[run+0x5f8]` — tetap terbuka dari REA-2.

### Tidak bisa dijawab dari file statis saja

- Gejala visual persis tiap toggle di HP (jitter MOVE, tampilan driver Hapus-B, suara Filter).
- Apakah kombinasi keempat toggle + God benar-benar membuat kendaraan tidak bisa mati dalam permainan nyata (butuh tes POCO setelah implementasi).
- Apakah ada setter ke-16 yang belum terpetakan (P0 menutupnya di titik akibat; keempat toggle tidak).

---

## Lampiran — alamat kunci + pola scan + file kerja

### Alamat kunci (VA di `libgame.so`)

| Item | 1.72.2 | 1.71.1 |
|---|---|---|
| `b2Fixture::SetFilterData` | `0x6d0f64` | `0x6c05c0` |
| `b2Fixture::Refilter` (tail-call dari SetFilterData) | `0x6d0f78` | `0x6c05d4` |
| `b2ContactFilter::ShouldCollide` | `0x6d4188` | `0x6c37e8` |
| `b2Fixture::Create` | `0x6d0b5c` | (tidak dicari — tidak dibutuhkan toggle) |
| `b2Body::CreateFixture` (pemanggil Create, 1 caller `0x6cf40c`) | `0x6cf3bc` | — |
| `b2Body::DestroyBody` | `0x6d20c0` | — |
| Getter posisi kepala (slot vtable `0x70`) | `0x4f4b30` | — |
| Query spasial situs C | `0x3a5a94` | — |
| Contact handler (cabang `0x20` di `0x3b113c`) | `0x3b0604–0x3b176c` | — |
| Blok destroy driver | `0x524f0c` (P0a `0x524f10`) | P0a `0x51a920` |
| Blok detach kepala | `0x560970` (P0b `0x560974`) | P0b `0x556380` |

### Pola scan untuk builder

- **SetFilterData (kedua versi, 20 byte identik):** `28 10 40 79 29 00 40 f9 08 78 00 79 09 40 03 f8 01 00 00 14` — verifikasi tepat 1 hit per binary (seperti verifikasi v1.7: 13/13 pola). Bila >1 hit, persempit dengan konteks (fungsi setelahnya ber-prologue `stp x29, x30`).
- **ShouldCollide (inti, kedua versi identik):** mulai `28 78 c0 79 e8 00 00 34 49 78 40 79 3f 21 28 6b 81 00 00 54 1f 01 00 71 e0 d7 9f 1a` — hanya untuk verifikasi layout, bukan untuk patch.

### File kerja

- Laporan ini: `~/workspace/rea-hcr-death-3/REPORT.md`
- Direktori kerja: `~/workspace/rea-hcr-death-3/work/` — `scan.py`, `scanw.py` (disassembler Capstone + utilitas scan; binary 1.72.2 di `~/workspace/hcrx-1.72.2/arm64/lib/arm64-v8a/libgame.so`, binary 1.71.1 di `~/workspace/hcrx/lib/arm64-v8a/libgame.so`)
- Referensi: `~/workspace/rea-hcr-death/REPORT.md`, `~/workspace/rea-hcr-death-2/REPORT.md` (+ `work/` berisi `fn_*.txt`, `readers_ctx.txt`, ekstraksi APK `apk1722/` — sumber `boringcar_model.json`), `~/workspace/rea-hcr-speed/REPORT.md`, `~/workspace/goals/hozin-hcr-mod-aplikasi-root-mod-menu-hill-climb-racing/GOAL.md`
- Catatan: file-file di `~/workspace/rea-hcr-death-3/work/` hanya berisi hasil scan/disassembly (tidak ada binary game yang disalin).
