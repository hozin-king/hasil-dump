# REA-4 — Kenapa God Mode v5 (P0) GAGAL di lapangan?

**Tanggal:** 17 Nov 2026, ~19:00 WIB
**Target:** Hill Climb Racing 1.72.2 (`libgame.so` SHA `307f6b87…`) + 1.71.1
**Fakta lapangan:** user sudah install v1.9.1, God Mode ON, tetap **DRIVER DOWN di 1008m** (+131.035 koin, 20x air time, 1x flip, **1x NECK FLIP**), Speed Instan ON (30), Torsi 10x. Tes v1.8 sebelumnya juga mati dengan God ON di 594m.
**Tugas:** riset saja, JANGAN implementasi, JANGAN ubah `~/workspace/hozin-hcr-mod/` (hanya baca).
**Hasil REA-2/REA-3 yang dipakai:** `~/workspace/rea-hcr-death-2/REPORT.md`, `~/workspace/rea-hcr-death-3/REPORT.md`.

---

## 0. Ringkasan eksekutif

**P0 tidak gagal karena bug implementasi — P0 gagal karena cakupan.** Implementasi `cbz_to_b`, pola scan, dan loop toggle semuanya benar (dibuktikan ulang di §1). Masalahnya:

1. **P0 hanya menambal 2 dari ~45 kendaraan.** P0A menambal blok DestroyBody di `PlayerCarFastBike` (0x524f10) dan P0B menambal blok detach joint di `PlayerCarOneWheeler` (0x560974). Screenshot user menunjukkan kendaraan **tipe motor** (bukan Jeep) — kemungkinan besar Motocross Bike (`PlayerCarBike`) atau Fast Bike; bila bukan FastBike/OneWheeler, **patch P0 berada di fungsi yang tidak pernah dipanggil selama run**.
2. **Ada setter flag ke-16 yang luput dari REA-2: `strh` (halfword write).** Delapan situs `strh w9, [x8]` menulis `0x0001` di `[car+0x32f]` — flag=1 SEKALIGUS clear latch `[car+0x330]`. v4 hanya me-NOP `strb`, jadi jalur ini **hidup penuh**. Latch-nya di-set oleh callback kontak Box2D (0x4f4b68) saat fixture kepala menyentuh sesuatu (tipe 5/2). Ini jalur kematian yang lengkap dan tidak tersentuh lapisan apa pun.
3. **12 setter `strb` lain** (stuck, jatuh, detach, akumulator, kill-zone, hazard, countdown, stage trigger, switch — REA-2) juga tidak di-NOP v4.
4. **Countdown `[run+0x630]`/`[run+0x634]` (baru):** bila `[run+0x630]!=0` dan countdown `[run+0x634]` habis → langsung `bl 0x3c2c0c` (end-run). Tidak membaca flag, tidak memakai death timer 0x62c — **tidak diblok v2/v3/v4/P0**.
5. **KOREKSI terhadap REA-2: death timer v2 BUKAN tersangka.** v2 me-NOP **5/5** situs timer (bukan 2 seperti ditulis REA-2). Terverifikasi statis (pola A 4 hit + pola B 1 hit di 1.72.2) DAN di runtime (log v1.7 17:32: `dtimer:5`, kelima alamat tercatat). Jadi jalur timer paralel sudah tertutup — dengan asumsi toggle God ON benar menerapkan NOP-nya.
6. **Bukti NECK FLIP:** achievement NECK FLIP hanya diberikan bila flag **CLEAR** (0x531a58: `ldrb flag; cbnz → skip`). User mendapat 1x NECK FLIP → saat flip itu terjadi, flag masih 0. Kematian datang **setelah** flip — konsisten dengan urutan: neck flip → kepala menyentuh tanah → callback kontak set latch → frame berikutnya `strh` set flag=1 → DRIVER DOWN.

**Penyebab paling mungkin (berurutan):** (1) kendaraan user bukan FastBike/OneWheeler sehingga P0 tidak pernah berjalan + flag di-set oleh `strh` setter (kontak kepala pasca neck-flip) atau salah satu dari 12 setter `strb` lain; (2) countdown `[run+0x630]`/`[run+0x634]`; (3) blok destroy `[car+0x519]`-gated di kendaraan user sendiri (kandidat, belum terbukti kapan pointer body-nya non-null).

**Yang PALING perlu dikonfirmasi dari runtime (belum ada):** log/status JSON v1.9.1 saat God ON (field `p0`, `dtimer`, `gsrc`), versi game di POCO (1.72.2 vs 1.73.3?), dan kendaraan yang dipakai user.

---

## 1. (a) Audit implementasi P0 — TIDAK DITEMUKAN BUG

### 1.1 `cbz_to_b` — benar (dihitung tangan dari disassembly)

| Patch | Instruksi asli | Decode | `b` hasil | Verifikasi |
|---|---|---|---|---|
| P0A 0x524f10 | `88 03 00 34` = `cbz w8, #0x524f80` | w=0x34000388, Rt=8, imm19=28, off=0x70 | `1c 00 00 14` (`b #0x524f80`) | imm19=28 → 0x1C ✓ |
| P0B 0x560974 | `68 04 00 34` = `cbz w8, #0x560a00` | w=0x34000468, Rt=8, imm19=35, off=0x8c | `23 00 00 14` (`b #0x560a00`) | imm19=35 → 0x23 ✓ |

Cek di `payload.cpp`: helper memverifikasi byte atas `0x34`/`0x35`, Rt==w8, sign-extended imm19, lompatan maju ≤0x1000 — semuanya lolos. **Target lompatan sama persis dengan target cbz asli** (bukan alamat salah).

### 1.2 Pola scan P0 — benar, unik, terverifikasi di kedua binary

`verify_scan.py` dijalankan ulang: **18/18 pola OK** di 1.71.1 dan 1.72.2. P0A tepat 1 hit tiap versi (1.71.1 `0x51a91c`, 1.72.2 `0x524f0c`); P0B tepat 1 hit tiap versi (1.71.1 `0x55637c`, 1.72.2 `0x560970`).

### 1.3 Loop toggle — benar

- Patch via `patch4` (mprotect seluruh range + memcpy + `__builtin___clear_cache`) + `verify4` read-back; rollback bila verifikasi gagal; restore saat OFF.
- Toggle loop di `init_thread` (poll 0,5 dtk atas `read_flags()`); scan P0 sekali saat init, `base` = segmen r-xp pertama libgame.so dari `/proc/self/maps`.
- Scan memverifikasi target memang `cbz w8` **sebelum** menyimpan — tidak ada patch buta.
- `git diff HEAD` di working copy menunjukkan P0 **tidak berubah** dari v1.9.1 (hanya tambahan v1.10: 413 baris, komentar + string status di sekitar P0). HEAD = `5c36abd` (v1.9.1).

### 1.4 Catatan (bukan bug, tapi batas desain)

- Scan P0 terjadi **sekali saat init**. Bila game di POCO ternyata **bukan 1.72.2/1.71.1** (mis. auto-update ke 1.73.3, code 10222 — diketahui ada per APKPure), pola tidak ketemu → patch tidak diterapkan → God mati total tanpa pesan yang terlihat user. **Hipotesis ini belum terkonfirmasi** — butuh log/status JSON v1.9.1 (lihat §5).
- Patch menempel di **kode** (bukan objek), jadi tetap berlaku walau objek `car` baru dibuat tiap run/stage. Respawn/ganti stage **bukan** penjelasan kegagalan.
- Tidak ada race dengan kode game yang relevan: patch ditulis sekali (saat toggle ON) dan bertahan; game tidak menulis ulang kode `.text`.

**Kesimpulan §1:** P0 diimplementasikan dengan benar. Kegagalan ada di **cakupan** (apa yang tidak ditambal), bukan di **cara menambal**.

---

## 2. (b) Peta lengkap jalur kematian yang TIDAK diblok P0

### 2.1 Peta kendaraan: P0 hanya menambal 2 dari ~45 subclass

Semua subclass `PlayerCar` memakai vtable 98 slot yang sama. Slot 16 (0x80) = update per-frame kendaraan; slot 25 (0xc8) = entry kedua ke logika yang sama (hasil disassembly tumpang tindih — keduanya mengarah ke blok destroy yang sama per kendaraan). Hasil pemindaian semua slot 16 & 25 (file `work/vehmap.py` → `work/vehmap.json`):

| Kendaraan | Update (slot 16) | Blok destroy di update | Gate | Ditambal P0? |
|---|---|---|---|---|
| **FastBike** | 0x524d7c | `[0x840]/[0x848]/[0x858]` @0x524f28–50 | flag **DAN** `[car+0x519]==0` | **YA (P0A)** |
| **OneWheeler** | 0x5606c4 | `[0x310]/[0x308]/[0x828]/[0x838]/[0x840]/[0x848]` @0x5608f0–50 | `[car+0x519]==0` saja | **TIDAK (hanya joint-nya)** |
| **OneWheeler** (joint) | 0x5606c4 | detach joint `[0x788]` + kepala `[0x2d0]` + `[0x780]` @0x560978–fc | flag | **YA (P0B)** |
| **Automobile** | 0x503248 | `[0x310]/[0x308]/[0x830]/[0x838]/[0x840]` @0x503488–d8 | `[car+0x519]==0` saja | TIDAK |
| **Bike** (Motocross) | 0x50a4e0 | `[0x310]/[0x308]/[0x818]/[0x820]/[0x828]` @0x50a6b8–708 | `[car+0x519]==0` saja | TIDAK |
| **ChopperBike** | 0x516068 | `[0x310]/[0x308]/[0x950]/[0x958]` @0x5163fc–450 (+ blok ke-2 @0x516104) | `[car+0x519]==0` saja | TIDAK |
| **MiniBike** | 0x557a58 | `[0x310]/[0x308]/[0x850]/[0x858]/[0x860]` @0x557cd8–d28 | `[car+0x519]==0` saja | TIDAK |
| **QuadBike** | 0x56642c | `[0x310]/[0x308]/[0x810]/[0x818]/[0x820]` @0x566604–654 | `[car+0x519]==0` saja | TIDAK |
| **Jeep** | 0x53bba4 | **tidak ada** destroy / flag-read / gate-519 di update | — | — (tidak ada yang ditambal) |
| Ambulance, FireTruck, Hotrod, Luxury, PoliceCar, Train, Tractor, Touristbus, Ufo, SuperHillclimber | — | ada blok destroy, **tanpa** flag-read dan tanpa gate-519 (gate lain, belum dipetakan) | ? | TIDAK |
| AirPlane, BubbleCar, CarCar, Lowrider, Shapeshifter | — | ada flag-read, **tanpa** destroy di update | — | TIDAK |
| BadCar, BigMonster, BoringCar, Custom, DieselTruck, Dragster, DuneBuggy, ElectricCar, Hachiroku, HippieVan, HoverCraft, MonsterTruck, MoonLander, RaceCar, RallyCar, ScrewFinger, Sleigh, SnowMobile, Spider, SuperOffroad, Tank, TrophyTruck, Truck | — | **tidak ada** destroy di update | — | — |

**Identifikasi kelas** (baru, via `.rela.dyn` + `vtables.json` REA-2): slot vtable yang menunjuk ke tiap fungsi update dicocokkan ke typeinfo — mis. 0x524d7c → `17PlayerCarFastBike`, 0x5606c4 → `19PlayerCarOneWheeler`, 0x5031e8 → `19PlayerCarAutomobile`, 0x50a480 → `13PlayerCarBike`, 0x53bba4 → `13PlayerCarJeep`.

**Kendaraan user:** kedua screenshot kematian (594m & 1008m) menunjukkan kendaraan **tipe motor** (roda besar ber-jari-jari, pengendara, profil rendah) — bukan Jeep. Antara Motocross Bike (`PlayerCarBike`) vs FastBike tidak bisa dibedakan pasti dari screenshot (crop di `/tmp/crop_594m.png`, `/tmp/crop_1008m.png`). **Bila kendaraan = Motocross Bike / Chopper / Mini / Quad / Automobile / Jeep → P0 tidak pernah berjalan.** Bila kendaraan = FastBike, P0A berjalan tapi kematian tetap bisa datang lewat §2.2–2.4.

### 2.2 Setter flag ke-16: `strh` — BARU, luput dari REA-2 (paling penting)

REA-2 hanya memindai `strb`. Ternyata ada **8 situs `strh`** yang menulis halfword `0x0001` di `[car+0x32f]`:

```
ldrb w8, [car, #0x330]     ; latch "pending death"
cbz  w8, #skip
add  x8, car, #0x32f
mov  w9, #1
strh w9, [x8]              ; [car+0x32f]=1 (flag) DAN [car+0x330]=0 (clear latch, little-endian)
```

| # | 1.72.2 | Lokasi | 1.71.1 |
|---|---|---|---|
| 1 | **0x4f659c** | helper bersama 0x4f6580 (dipanggil via vtable slot 0x58 dari banyak update; FastBike memanggil langsung @0x524f08) | **0x4ebfac** |
| 2 | **0x503430** | Automobile update | **0x4f8e40** |
| 3 | **0x50a660** | Bike update | **0x500070** |
| 4 | **0x5163ac** | ChopperBike update | **0x50bdbc** |
| 5 | **0x557c80** | MiniBike update | **0x54d68c** |
| 6 | **0x560898** | OneWheeler update | **0x5562a4** |
| 7 | **0x5665ac** | QuadBike update | **0x55bfb8** |
| 8 | **0x577ad0** | SnowMobile update (register x0) | **0x56d4dc** |

Pola byte untuk scan: `add x8, x?, #0x32f` (`91 0c be 68` untuk x19 / `91 0c bc 08` untuk x0) + `mov w9, #1` (`29 00 80 52`) + `strh w9, [x8]` (`09 01 00 79`); target strh di +8 dari `add`. Ditemukan dengan pencarian byte langsung (8+8 situs, 1 false positive di 0x433640/0x42a1dc dengan imm 0x281 — bukan setter).

**Latch `[car+0x330]` di-set oleh callback kontak Box2D 0x4f4b68** (fungsi yang menerima fixture yang bersentuhan):

```
0x4f4bb8: ldrb w8, [car, #0x32f]     ; bila flag sudah 1, lewati satu cabang
0x4f4bd4: ldr w8, [fixture, #0x14]
0x4f4bd8: cmp w8, #5
0x4f4bdc: b.eq #0x4f4c28
0x4f4c20: cmp w8, #2
0x4f4c24: b.ne #0x4f4c30
0x4f4c28: mov w8, #1
0x4f4c2c: strb w8, [car, #0x330]     ; SET latch
```

Jadi pipanya lengkap dan **tidak tersentuh lapisan god mode mana pun**:

> kepala menyentuh tanah/obstacle (fixture tipe 5/2) → callback 0x4f4b68 set `[car+0x330]=1` → frame update berikutnya `strh` set **flag=1** → game-over lewat pembaca flag langsung / blok destroy kendaraan.

v4 hanya me-NOP `strb` — `strh` ini tidak kena. v3 (predikat) tidak menolong karena 31/32 pembaca flag membaca byte langsung (§2.5). P0 tidak menolong kecuali kendaraannya FastBike/OneWheeler.

### 2.3 12 setter `strb` lain — tetap hidup (REA-2, tidak di-NOP v4)

Stuck 0x5053f4 + 0x50bfbc, jatuh 0x4efae4, detach 0x50e570, akumulator 0x3d488c, kill-zone 0x4c9dfc, hazard 0x4ec2a8 / 0x5d09fc, countdown 0x52d610, stage trigger 0x4cb98c, switch 0x3ab7b0. Ditambah setter A v4 ternyata **bukan** kepala-di-tanah melainkan detektor GOAL stage ballsports (koreksi REA-2) — jadi NOP-nya tidak relevan untuk kematian kepala.

### 2.4 Countdown `[run+0x630]`/`[run+0x634]` — BARU, jalur game-over tanpa flag

Di fungsi update besar 0x3c585c:

```
0x3c767c: ldrb w8, [run, #0x630]
0x3c7680: cbz  w8, #0x3c76c4          ; bila [run+0x630]==0, lewati
0x3c7684: ldr  s0, [run, #0x634]      ; countdown (float)
0x3c7690: fsub d0, d0, d13             ; -= dt
0x3c7694: fmaxnm d0, d0, d1            ; clamp 0
0x3c76a0: str  s0, [run, #0x634]
0x3c76a4: b.hi #0x3c76c4               ; bila masih > 0, lewati
0x3c76a8: mov  x0, x19
0x3c76ac: bl   #0x3c2c0c               ; countdown habis -> END RUN / GAME OVER
```

**Tidak membaca flag, tidak memakai death timer 0x62c** — jadi tidak diblok v2 (yang me-NOP store 0x62c), v3 (predikat), v4 (setter flag), maupun P0 (bukan blok DestroyBody). Pemicu `[run+0x630]` belum dipetakan penuh: penulisnya antara lain 0x3c2dec (di dalam fungsi end-run 0x3c29e8 sendiri — `strb w9, [x0,#0x630]` + `str s0, [x0,#0x634]`, mengeset countdown saat run berakhir), 0x3d5a84, dan reset/clear di 0x3bbb9c / 0x449a74. **Status: kandidat, perlu riset lanjut siapa yang mengeset [run+0x630]=1 di tengah run.**

### 2.5 Pembaca flag langsung — predikat v3 dilewati

32 pembaca `ldrb [x,#0x32f]` di seluruh binary (terkonfirmasi ulang lewat disassembly Capstone penuh `.text`, 1.044.631 instruksi). 31 di antaranya membaca byte langsung; hanya 1 yang lewat predikat 0x3b2f94. Jadi **sekali flag=1 (lewat strh §2.2 atau 12 setter §2.3), game-over bisa fire tanpa lewat predikat yang di-patch v3**.

### 2.6 Yang SUDAH diperiksa dan DICORET sebagai penyebab

- **Death timer v2 — DICORET.** v2 me-NOP **5/5** situs store timer `[run+0x62c]`: 0x3c72e0, 0x3c7340, 0x3c76fc, 0x3c7748, 0x3c77d4 (pola A 16-byte: 4 hit; pola B 12-byte: 1 hit — terverifikasi di binary 1.72.2; pola 1.71.1 memberi 0 hit di 1.72.2 seperti diharapkan). **Bukti runtime:** log v1.7 17:32 (`hcr-log-2026-11-17_17-32-07.txt`): `"dtimer":"dtimer:5"` + kelima alamat tercatat (`deathtimer[0..4] str @ base+0x3c72e0/0x3c7340/0x3c76fc/0x3c77d4/0x3c7748`). Komentar `patterns.h` juga sudah benar ("Ditemukan 5 situs (riset v1 bilang 3 — SALAH)"). Klaim REA-2 "v2 hanya NOP 0x3c7748 + 0x3c77d4" **salah** — itu gambaran versi lama. Jalur timer paralel via `[vehicle+0x266]` (yang di-set handler kontak di 0x3b0de0, instruksi persis setelah `strb` setter A yang di-NOP v4) **tertutup oleh v2** — selama toggle God ON benar menerapkan NOP. Satu-satunya lubang: tidak ada log v1.9.1 untuk membuktikan `dtimer:5` di run yang gagal (lihat §5).
- **End-run helper 0x3b7c70 — bukan fungsi end-run.** Disassembly penuh menunjukkan ini fungsi lookup `std::map` (kunci map1: `daily_event`, `challenge`, `spacemission`, `retro_mission`, `doubleroad`; map2: `spider`, `screw­finger`, `train`, `hachiroku`, `carcar`, `sleigh`) yang mengembalikan boolean "mode/kendaraan spesial". Dipakai untuk mengeset `[car+0x519]` (lihat §2.7), bukan untuk mengakhiri run.
- **`[vehicle+0x266]` — tertutup via v2** (lihat di atas). Sekali di-set (=1) tidak pernah di-clear (4 penulis, semuanya menulis 1; tidak ada store 32-bit yang menutupinya), tapi timer yang dibacanya tidak bisa naik karena v2.
- **Fungsi 0x3c6300 — bukan jalur game-over.** Alamat itu berada di dalam fungsi besar 0x3c585c (update GameLayer/run); satu-satunya caller-nya 0x4f66e8 memanggilnya saat flag set — tapi 0x3c6300 sendiri adalah awal blok logika lain di fungsi yang sama, bukan pemicu game-over.

### 2.7 `[car+0x519]` — status: kandidat, bukan kepastian

- Hanya ada **2 penulis** di seluruh binary: 0x3b7b28 (`strb w9=1`, di konstruktor objek run 0x3b7748, bila helper 0x3b7c70 mengembalikan bit0=1) dan 0x3d1818 (`strb wzr=0`, di update besar 0x3d0420, bila helper mengembalikan bit0=0).
- Helper mengembalikan 1 hanya untuk mode spesial (`daily_event`/`challenge`/`spacemission`/`retro_mission`/`doubleroad`) atau kendaraan spesial (`spider`/`screw­finger`/`train`/`hachiroku`/`carcar`/`sleigh`). **Untuk run normal, `[car+0x519]` = 0.**
- Akibatnya blok destroy `[car+0x519]`-gated di Automobile/Bike/ChopperBike/MiniBike/QuadBike/OneWheeler (§2.1) **aktif selama run normal** — tapi tiap `DestroyBody` dijaga `cbz` null-check, jadi blok itu no-op selama pointer body null. **Kapan pointer `[0x310]/[0x308]/[0x830]/[0x838]/[0x840]` menjadi non-null, belum terbukti dari statics** (butuh data runtime — kemungkinan pointer itu adalah body driver yang dibuat saat spawn, atau body "driver terlepas" yang dibuat saat kematian). Bila pointer itu non-null selama run normal, game vanilla pun akan hancur di frame pertama — jadi kemungkinan besar pointer null sampai ada pemicu (mis. flag set → driver dilepas → body dibuat → blok destroy jalan). Artinya blok ini kemungkinan **akibat, bukan penyebab** kematian. Status: kandidat lapis kedua, bukan penyebab utama.

### 2.8 Caller end-run lain (non-timer) — untuk kelengkapan

`0x3c2c0c` (entry end-run) dipanggil dari 7 tempat: 0x3c72ec, 0x3c7518, 0x3c76ac (countdown §2.4), 0x3c7708, 0x3c7960 (ketiganya jalur timer — tertutup v2), 0x3c9774 (kondisi `[run+0x840]`/`[run+0x841]`/`[run+0x589]` + perbandingan counter + pemanggilan 0x3d0984), 0x3ca8e0 (stub jump-table). `0x3c29e8` (fungsi end-run penuh) dipanggil dari 0x3c7614, 0x3c7930, 0x3c918c, 0x3c9648. Predikat 0x3b2f94 dipanggil dari 12 tempat (bukan 2): 0x3c7724, 0x3c779c, 0x3c7f68, 0x3c8070, 0x3c9520, 0x3caba8, 0x3cb0dc, 0x3ce698, 0x3ce6f4, 0x3d4840, 0x5cda18, 0x60851c — v3 hanya menambal fungsi predikatnya sendiri (return false), jadi semua 12 caller ikut tertutup **untuk jalur predikat**, tapi tidak untuk 31 pembaca langsung.

---

## 3. (c) Rekonstruksi run 1008m (v1.9.1, God ON)

**Bukti NECK FLIP (0x531a58, di fungsi 0x531628):**

```
0x531a58: ldrb w8, [x19, #0x32f]     ; flag
0x531a5c: cbnz w8, #0x531aec           ; bila flag=1, LEWATI pemberian NECK FLIP
0x531a60: ... strb w8, [x19, #0x9c8]  ; tandai NECK FLIP didapat + beri achievement
```

**User mendapat 1x NECK FLIP → pada momen itu flag masih 0.** (Di run v1.8 594m: 0x NECK FLIP — tidak ada informasi timing dari run itu.)

Urutan yang paling konsisten dengan semua bukti:

1. Run berjalan normal (Speed Instan 30, Torsi 10x, God ON). Flag=0 (setter A/B/C v4 di-NOP; timer di-NOP v2).
2. Kendaraan melakukan neck flip (kepala berputar melewati atas). Saat rotasi, NECK FLIP diberikan — **flag masih 0** saat itu.
3. Kepala menyentuh tanah / obstacle setelah flip → **callback kontak Box2D 0x4f4b68** (fixture tipe 5/2) mengeset latch `[car+0x330]=1`.
4. Frame update berikutnya, `strh` setter di update kendaraan user (mis. Bike 0x50a660, atau helper bersama 0x4f659c) melihat latch≠0 → **`strh` menulis flag=1** (v4 tidak menambalnya).
5. Flag=1 → salah satu dari 31 pembaca langsung / blok destroy kendaraan user (bila kendaraannya punya blok §2.1) → **DRIVER DOWN** di 1008m.
6. User mematikan God setelah mati supaya bisa ke lobby (efek samping v4 yang diketahui: layar game-over tertahan bila God ON — konsisten dengan laporan user).

**Alternatif yang tetap mungkin (bila (3)–(4) bukan pemicunya):** salah satu dari 12 setter `strb` (§2.3) fire setelah flip (mis. stuck 0x5053f4 bila kendaraan terjebak terbalik, atau detach 0x50e570 bila joint kepala lepas); atau countdown `[run+0x630]`/`[run+0x634]` (§2.4) yang pemicunya belum dipetakan. **Yang sudah dicoret:** setter A/B/C v4 (di-NOP, tidak bisa fire), death timer (di-NOP v2, 5/5 terverifikasi runtime).

**Yang tidak bisa ditentukan dari data yang ada:** kendaraan persis user (screenshot hanya menunjukkan tipe motor), dan apakah flag sempat jadi 1 sebelum NECK FLIP diberikan lalu di-clear lagi (tidak ada mekanisme clear flag yang ditemukan — tidak ada penulis flag=0; jadi flag yang sudah 1 akan tetap 1; karena NECK FLIP mensyaratkan flag=0, flag **belum pernah** jadi 1 sebelum momen itu).

---

## 4. (d) Hasil — penyebab paling mungkin, diurutkan

| # | Penyebab | Bukti | Keyakinan |
|---|---|---|---|
| 1 | **P0 tidak mencakup kendaraan user + flag di-set `strh` setter (kontak kepala pasca neck-flip)** | P0 hanya FastBike/OneWheeler (§2.1); 8 situs `strh` hidup, latch di-set callback kontak 0x4f4b68; NECK FLIP membuktikan flag=0 saat flip, lalu mati setelahnya (§3) | **Tinggi** |
| 2 | **Flag di-set salah satu dari 12 setter `strb` lain** (stuck/jatuh/detach/dll.) | REA-2 mendaftar 12 situs; v4 hanya NOP 3; tidak ada yang menutup 12 ini | Sedang–tinggi |
| 3 | **Countdown `[run+0x630]`/`[run+0x634]`** | Jalur end-run tanpa flag/timer, tidak diblok lapisan mana pun (§2.4); pemicunya belum dipetakan | Sedang (pemicu belum pasti) |
| 4 | **Blok destroy `[car+0x519]`-gated di kendaraan user** | Blok ada di 5 kendaraan + OneWheeler; `[car+0x519]=0` di run normal; tapi kapan pointer body non-null belum terbukti | Rendah–sedang (kemungkinan akibat, bukan penyebab) |
| 5 | **Game auto-update ke 1.73.3 → semua pola meleset** | 1.73.3 (code 10222) diketahui ada; pola 1.72.2 tidak akan ketemu di binary lain | Tidak bisa dicoret, tapi **tidak didukung** bukti: log v1.7 17:32 membuktikan game saat itu 1.72.2 (semua pola ketemu); tidak ada bukti update antara 17:32–18:40; overlay mod tetap jalan di v1.9.1 (tapi overlay tidak membuktikan scan berhasil) |
| — | Death timer (v2) | **DICORET** — 5/5 situs di-NOP, terverifikasi statis + runtime (`dtimer:5`) | — |
| — | Bug implementasi P0 (`cbz_to_b`, pola, toggle) | **DICORET** — dihitung tangan, 18/18 pola OK, `git diff` bersih | — |

---

## 5. Kandidat patch untuk jalur yang tersisa (kedua versi)

> Semua alamat 1.72.2 terverifikasi dari disassembly. Alamat 1.71.1 untuk `strh` terverifikasi via pencarian byte; sisanya (P2–P4) diberi pola pencariannya — builder wajib verifikasi dengan `verify_scan.py` sebelum patch.

### P1 — NOP 8 situs `strh` setter (prioritas tertinggi, menutup §2.2)

Target: instruksi `strh w9, [x8]` (byte `09 01 00 79`) → NOP `1f 20 03 d5`. Pola scan (12 byte, target di +8): `add x8, x?, #0x32f` + `mov w9, #1` + `strh w9, [x8]`.

| 1.72.2 | 1.71.1 | Keterangan |
|---|---|---|
| 0x4f659c | 0x4ebfac | helper bersama 0x4f6580 (slot vtable 0x58) |
| 0x503430 | 0x4f8e40 | Automobile |
| 0x50a660 | 0x500070 | Bike (Motocross) |
| 0x5163ac | 0x50bdbc | ChopperBike |
| 0x557c80 | 0x54d68c | MiniBike |
| 0x560898 | 0x5562a4 | OneWheeler |
| 0x5665ac | 0x55bfb8 | QuadBike |
| 0x577ad0 | 0x56d4dc | SnowMobile |

Catatan: NOP `strh` membuat latch `[car+0x330]` tetap 1 (tidak di-clear). Sejauh pemindaian, latch **hanya** dibaca sebagai gate `strh` itu sendiri (8 situs) dan di-clear oleh 0x50f6f8 (BubbleCar) — tidak ditemukan jalur lain yang membaca latch. Tetap verifikasi saat implementasi: bila latch ternyata menggerakkan sesuatu, alternatifnya adalah NOP `strb` latch-setter di 0x4f4c2c (callback kontak, 1 situs — tapi mematikan latch untuk semua kendaraan sekaligus).

### P2 — NOP 12 setter `strb` lain (menutup §2.3)

Alamat 1.72.2 dari REA-2: stuck 0x5053f4 + 0x50bfbc, jatuh 0x4efae4, detach 0x50e570, akumulator 0x3d488c, kill-zone 0x4c9dfc, hazard 0x4ec2a8 / 0x5d09fc, countdown 0x52d610, stage trigger 0x4cb98c, switch 0x3ab7b0. Masing-masing `strb w?, [x?, #0x32f]` → NOP (`1f 20 03 d5`). Alamat 1.71.1 dicari dengan pola konteks tiap situs (seperti GSRC v4). **P1+P2 bersama = flag tidak pernah bisa jadi 1 lewat jalur apa pun yang diketahui** — ini defense-in-depth yang lebih kuat daripada menambal tiap pembaca (31 situs, tidak praktis).

### P3 — Perluas P0 ke blok destroy `[car+0x519]`-gated (menutup §2.1/§2.7)

Untuk tiap kendaraan, ubah `cbnz w8, #skip` setelah `ldrb w8, [car, #0x519]` menjadi `b #skip` (selalu lewati destroy) — analog dengan cara kerja P0 (`cbz_to_b`). Target `cbnz`:

| Kendaraan | 1.72.2 (`cbnz` setelah `ldrb #0x519`) | 1.71.1 |
|---|---|---|
| Automobile | 0x503478 | cari via pola `ldrb #0x519` + `cbnz` di update Automobile |
| Bike | 0x50a6a8 | idem (update Bike) |
| ChopperBike | 0x5161a4 dan 0x5163e8 (2 blok) | idem |
| MiniBike | 0x557cc4 | idem |
| QuadBike | 0x5665f0 | idem |
| OneWheeler (body) | 0x5608e0 | idem |
| FastBike | sudah P0A (flag-gated, bukan 519-gated) | — |

Pola scan: `ldrb w8, [x19, #0x519]` diikuti `cbnz w8, #target` — verifikasi target `cbnz` melompati seluruh blok destroy (bukan hanya 1 instruksi).

### P4 — Tutup countdown `[run+0x630]`/`[run+0x634]` (menutup §2.4)

Opsi A (paling kecil): NOP `str s0, [x19, #0x634]` di **0x3c76a0** (1.72.2) — countdown tidak pernah turun. Opsi B: NOP `bl #0x3c2c0c` di **0x3c76ac**. Alamat 1.71.1 dicari via pola `fsub d0, d0, d13; fmaxnm; fcvt; fcmp s0, #0.0; str s0, [x19, #0x634]`. **Peringatan:** `[run+0x634]` kemungkinan juga dipakai untuk countdown sah (mis. fuel-out) — verifikasi dulu siapa yang mengeset `[run+0x630]=1` sebelum menerapkan P4; jangan jadikan P4 sebagai patch pertama.

### P5 — Lapisan REA-3 (v1.10, sedang dibangun) tetap relevan

Filter "Driver Tembus", Hapus-B, Pindah, Shrink adalah lapisan pelengkap (mengurangi kontak kepala / konsekuensi fisik) — bukan pengganti P1–P3. Urutan bangun yang disarankan setelah v1.10: **P1 → P2 → P3 → (P4 bila pemicu 0x630 terkonfirmasi)**.

---

## 6. Data runtime yang akan mengonfirmasi (belum ada — diminta dari user/POCO)

1. **Log / status JSON v1.9.1 saat God ON** (tombol "Salin status" / file log di aplikasi — JANGAN suruh user jalankan Termux/logcat; ambil lewat UI aplikasi). Yang dicari:
   - `"p0":"a:ok b:ok"` dan `"p0_hook":"aktif (2/2)"` — membuktikan patch P0 diterapkan.
   - `"dtimer":"dtimer:5"` — membuktikan v2 menemukan 5 situs (bila `dtimer:0` → game bukan 1.72.2/1.71.1 → hipotesis #5 naik ke peringkat 1).
   - `"gsrc":"a:ok b:ok c:ok"`, `"dflag":"dflag:3"`.
   - Bila ada baris log `pola TIDAK ketemu` / `bukan strb yang diharapkan` → scan gagal → versi game beda.
2. **Versi game di POCO** (Pengaturan → aplikasi → Hill Climb Racing → versi; atau dari dalam game). Bila 1.73.x → semua pola 1.72.2/1.71.1 tidak berlaku; REA-5 harus memetakan ulang 1.73.x.
3. **Kendaraan yang dipakai saat run 1008m** (Jeep? Motocross Bike? Fast Bike? yang lain?). Ini menentukan apakah P0 pernah berjalan.
4. **Stage yang dipakai** (Countryside? stage lain? mode harian/challenge?) — menentukan `[car+0x519]` (hanya 1 untuk mode/kendaraan spesial).

---

## 7. Batas kejujuran — terbukti vs dugaan

**Terbukti dari disassembly/kode (1.72.2 & 1.71.1 di disk):**
- `cbz_to_b` benar; pola P0 unik 1 hit; toggle loop + rollback benar; P0 tidak berubah dari v1.9.1.
- Peta kendaraan (§2.1) + 8 situs `strh` (§2.2) + latch di-set callback kontak 0x4f4b68.
- 12 setter `strb` lain (REA-2, tidak di-NOP); 31/32 pembaca flag langsung.
- v2 me-NOP 5/5 situs timer (statis + log runtime v1.7 `dtimer:5`).
- Countdown `[run+0x630]`/`[run+0x634]` → end-run tanpa flag/timer.
- NECK FLIP mensyaratkan flag=0 (0x531a58).

**Masih dugaan (butuh data runtime §6):**
- Kendaraan persis user (screenshot hanya menunjukkan tipe motor).
- Apakah flag benar di-set oleh `strh` di run 1008m (vs 12 setter lain vs countdown) — urutan §3 adalah rekonstruksi paling konsisten, bukan observasi langsung.
- Kapan pointer body `[0x310]/[0x308]/[0x830]/[0x838]/[0x840]` non-null (menentukan apakah blok destroy §2.7 adalah penyebab atau akibat).
- Siapa yang mengeset `[run+0x630]=1` di tengah run (menentukan apakah P4 aman).
- Versi game di POCO saat run 1008m (1.72.2 diasumsikan dari log v1.7; belum ada bukti v1.9.1).

---

## 8. File kerja REA-4

- `~/workspace/rea-hcr-death-4/REPORT.md` (file ini)
- `~/workspace/rea-hcr-death-4/work/vehmap.py` + `vehmap.json` — peta blok destroy per kendaraan (45 subclass, slot 16 & 25)
- `~/workspace/rea-hcr-death-4/work/hcr4.py` — helper disassembler (capstone; catatan: jangan namai `dis.py`, menutupi stdlib `dis`)
- `~/workspace/rea-hcr-death-4/work/fullscan.py` + `fullscan.json` — scan penuh `.text` (32 pembaca flag, 11 pembaca `[car+0x519]`, 15 pembaca `[car+0x330]`, 128 situs `DestroyBody`, caller end-run/predikat)
- `~/workspace/rea-hcr-death-4/work/fn_*.txt` — dump fungsi: `fn_destroy_524f0c`, `fn_cleanup_5608c0`, `fn_timer_3c76d8`, `fn_4f65xx`, `fn_503xxx`, `fn_50axxx`, `fn_516xxx`, `fn_557xxx`, `fn_566xxx`, `fn_577xxx`, `fn_3b7b28_519set`, `fn_3d1818_519clr`, `fn_4f4c2c_330set`, `fn_3c6300`, `fn_4f66e0_408`
