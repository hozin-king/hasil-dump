# REA Booster — Hill Climb Racing 1 (batas beli 10 + cooldown pemakaian)

- **Tanggal:** 17 Nov 2026
- **Target:** HCR 1 `com.fingersoft.hillclimb`, `libgame.so` arm64
  - 1.72.2: `~/workspace/hcrx-1.72.2/arm64/lib/arm64-v8a/libgame.so` (SHA-256 `307f6b87dfae712a…`, cocok dengan XAPK resmi — terverifikasi REA-2)
  - 1.71.1: `~/workspace/hcrx/lib/arm64-v8a/libgame.so` (SHA-256 `e27734f12fa574d2…`)
- **Sifat:** riset saja (REAd-only). TIDAK ada implementasi, TIDAK menyentuh `~/workspace/hozin-hcr-mod/`.
- **Konvensi:** alamat = offset file = VA (PIE, base 0). Semua alamat di bawah diverifikasi ulang di sesi ini dari disassembly, kecuali yang ditandai "laporan lama".

## Ringkasan eksekutif

1. **Batas beli 10 ditegakkan di TIGA tempat** (semua di `PowerUpDialog.cpp`): handler tombol plus (clamp jumlah), fungsi refresh dialog (reset + pesan MAX), dan fungsi konfirmasi beli (gerbang sebenarnya, `owned > 9` → batal diam-diam). **Ketiganya harus di-patch** — menambal gerbang beli saja TIDAK cukup, karena dialog akan me-reset jumlah ke 0 dan menonaktifkan tombol beli begitu owned ≥ 10.
2. **Inventaris booster = SATU kunci bersama** `'hcr1-nitro'` untuk kelima tipe (NITRO/JUMP/BIGTIRES/GRIP/GLIDER). Tidak ada kunci per-tipe.
3. **Cooldown ada dan nyata:** state machine per objek booster (0=ready, 1=aktif, 2=cooldown). Durasi cooldown per tipe: NITRO 2,0 dtk, JUMP 0,5 dtk, BIGTIRES 10,0 dtk, GRIP 18,0 dtk, GLIDER 10,0 dtk. `canUse` menolak pemakaian saat state 1 (aktif) maupun 2 (cooldown).
4. **Tiap aktivasi mengonsumsi tepat 1 booster** dari stok bersama (kecuali bila flag gratis / sisa pakai gratis / charge tersisa). Jadi "pakai terus-menerus" tetap menghabiskan stok — itulah kenapa penghapusan batas beli dan penghapusan cooldown adalah dua pekerjaan yang saling melengkapi. Alternatif: patch konsumsi (aktivasi gratis, stok tidak berkurang).
5. **Lokal, tanpa server:** inventaris + koin/gems disimpan di `UserDefault.xml` (cocos2d-x, file lokal di perangkat). Seluruh jalur beli/pakai tidak memanggil satu pun fungsi jaringan (0 panggilan `socket`/`connect`/`send`/`recv` di graf panggil jalur tersebut; 6 situs panggil jaringan di seluruh binary berada di subsistem socket terpisah 0x784xxx–0x78dxxx dan tidak dirujuk dari kode booster).
6. **Pola byte 16-byte di semua situs kunci IDENTIK antara 1.72.2 dan 1.71.1** — pattern-scan yang sama jalan di kedua versi (hanya alamatnya bergeser).

---

## 1. Batas beli 10

### 1.1 String

| | 1.72.2 | 1.71.1 |
|---|---|---|
| `"MAXIMUM ALLOWED AMOUNT OF BOOSTER IS %d"` | rodata `0x1cefb6` | rodata `0x1cc28b` |
| xref (pemakaian di refresh) | `0x5adfe4` | `0x5a39d4` |

### 1.2 Di mana jumlah booster disimpan

**Satu kunci bersama untuk kelima tipe: `'hcr1-nitro'`** (string 1.72.2 `0x1f5a15` / 1.71.1 `0x1f1d4a`). Tidak ada kunci `hcr1-glider`, `hcr1-jump`, dsb. — pencarian string di rodata memastikan ketiadaannya. Kelima tipe memakai stok yang sama; dialog "BUY BOOSTER?" hanya memilih *tipe yang akan dipakai*, bukan stok yang berbeda.

Fungsi akses inventaris (1.72.2 / 1.71.1):

| Fungsi | 1.72.2 | 1.71.1 | Keterangan |
|---|---|---|---|
| `getNitroCount()` | `0x5a6874` | `0x59c264` | `getInt('hcr1-nitro')` via singleton profil `0x6ae768` + vtable slot `0x18` |
| `setNitro(n)` | `0x5a843c` | `0x59de2c` | `setInt` slot `0x50` + `save` slot `0x78` |
| `addNitro(n)` | `0x5a8480` | `0x59de70` | `setNitro(get()+n)` |
| `subtractNitro(n)` | `0x5a6ba4` | `0x59c594` | `setNitro(get()-n)` |
| `getPrice(owned, amount)` | `0x5a8630` | `0x59e020` | lihat §1.4 |

Singleton profil: `0x6ae768` (1.72.2). Objeknya bervtable `0x866bc0`: slot `0x18` = `getInt` (`0x6ade84`), slot `0x50` = `setInt` (`0x6ae480`), slot `0x78` = `save` (`0x6aea00`). (Lihat §3 untuk bukti penyimpanan lokal.)

Pemberi booster gratis lain (jalur yang juga memanggil `addNitro`, jumlah di `w0`): `0x3155c0` (fungsi `0x31523c`), `0x3713b0` (`0x371294`), `0x371b3c` (`0x37143c`), `0x424700` (`0x4245b4`), `0x498538` (`0x4974f4`). Tiga di antaranya (`0x3155c0`, `0x424700`, `0x498538`) memainkan bunyi yang sama dengan jalur beli (`mov w0,#1; bl 0x5948b4`) — ciri jalur hadiah (daily/video/level-up). Identitas persis tiap pemberi belum dipetakan (tidak memengaruhi patch batas beli).

### 1.3 Tiga situs penegakan batas 10 (semua di PowerUpDialog.cpp)

#### Situs 1 — Handler tombol plus (clamp jumlah terpilih)

Fungsi 1.72.2 `0x5adc2c` / 1.71.1 `0x5a361c`.

```
; 1.72.2, 1.71.1 identik
0x5adca8 / 0x5a3698:  cmp w8, #0xb        ; owned + amount  vs  11
0x5adcac / 0x5a369c:  b.lt  #...          ; < 11 -> lolos, jumlah dipakai apa adanya
0x5adcb0 / 0x5a36a0:  mov w8, #0xa        ; >= 11 -> clamp: amount = 10 - owned
0x5adcb4 / 0x5a36a4:  sub w8, w8, w0      ; (w0 = owned)
0x5adcb8 / 0x5a36a8:  str w8, [x19, #0x160] ; simpan amount terpilih
```

Pola 16 byte @ `0x5adca8` / `0x5a3698` (identik kedua versi):
`1f2d0071 8b000054 48018052 0801004b`

#### Situs 2 — Refresh dialog (reset + nonaktifkan + pesan MAX)

Fungsi 1.72.2 `0x5ade68` / 1.71.1 `0x5a3858`. Tiga perbandingan `#0xa`:

| Cabang | 1.72.2 | 1.71.1 | Efek bila owned ≥ 10 |
|---|---|---|---|
| Reset | `cmp w20, #0xa` @ `0x5adeb0` | @ `0x5a38a0` | amount di-reset ke 0, kontrol dinonaktifkan (slot `0x268`), bunyi 125 |
| Tampilan | `cmp w20, #0xa` @ `0x5adf44` | @ `0x5a3934` | tampilan jumlah/harga mode "penuh" |
| Pesan MAX | `cmp w20, #0xa` @ `0x5adfdc` | @ `0x5a39cc` | tampilkan `"MAXIMUM ALLOWED AMOUNT OF BOOSTER IS %d"` (argumen `%d` = 10, `mov w4, #0xa` @ 1.72.2 `0x5ae008` / 1.71.1 `0x5a39f8`) + nonaktifkan tombol beli |

Pola 16 byte (identik kedua versi):
- reset @ `0x5adeb0`/`0x5a38a0`: `9f2a0071 f503002a cb020054 60de40f9`
- tampilan @ `0x5adf44`/`0x5a3934`: `9f2a0071 a0833ead a0833dad eb000054`
- pesan MAX @ `0x5adfdc`/`0x5a39cc`: 1.72.2 `9f2a0071 cb020054 00e1ffb0 00d83e91`, 1.71.1 `9f2a0071 cb020054 40e1ffb0 002c0a91` (12 byte pertama identik)

**Ini situs yang membuat patch gerbang-beli saja tidak cukup:** begitu owned ≥ 10, refresh me-reset amount ke 0 dan menonaktifkan kontrol — tombol beli tidak pernah bisa ditekan, jadi gerbang beli tidak pernah tercapai.

#### Situs 3 — Konfirmasi beli (gerbang sebenarnya)

Fungsi 1.72.2 `0x5ae364` / 1.71.1 `0x5a3ad4` (fungsi dialog `0x5ae208`/`0x5a3ad4` di atasnya hanya setup + memanggil refresh `0x5ade68`). Alur terverifikasi dari disassembly 1.72.2:

```
0x5ae3c0: adrp x23, #0x877000
0x5ae3c4: ldr x23, [x23, #0x2d8]   ; x23 = pointer ke int koin ([0x8772d8] berisi POINTER)
0x5ae3c8: ldr w21, [x23]           ; w21 = koin
0x5ae3cc: bl #0x5a6874             ; getNitroCount() = owned
0x5ae3d0: ldr w1, [x19, #0x160]    ; amount terpilih
0x5ae3d4: bl #0x5a8630             ; price(owned, amount)
0x5ae3d8: mov w20, w0
0x5ae3dc: cmp w0, w21
0x5ae3e0: b.le #0x5ae3fc           ; harga <= koin -> lanjut
0x5ae3e4: ... bl #0x5ae0e4         ; koin tidak cukup -> toast, kembali
0x5ae3fc: bl #0x5a6874             ; getNitroCount() lagi
0x5ae400: cmp w0, #9
0x5ae404: b.gt #0x5ae66c           ; owned > 9 -> BATAL DIAM-DIAM, tanpa beli, tanpa pesan
0x5ae408: ldr w8, [x23]
0x5ae40c: sub w8, w8, w20
0x5ae410: str w8, [x23]           ; kurangi koin
0x5ae414: ldr w0, [x19, #0x160]
0x5ae418: bl #0x5a8480             ; addNitro(amount)
```

1.71.1 padanan: `cmp w0, #9` @ `0x5a3df0`, `b.gt #0x5a405c` @ `0x5a3df4`; kurangi koin @ `0x5a3df8–0x5a3e00`; `addNitro` @ `0x5a3e08` (`bl 0x59de70`).

Catatan penting:
- Ceknya **hanya `owned`, bukan `owned+amount`** — bila owned ≤ 9, pembelian sebesar apa pun lolos gerbang ini (yang membatasi di dialog adalah clamp situs 1 + reset situs 2).
- Bila gagal di gerbang ini, **tidak ada pesan** — batal diam-diam (return ke `0x5ae66c`/`0x5a405c`).

Pola 16 byte @ `0x5ae400` / `0x5a3df0` (identik kedua versi):
`1f240071 4c130054 e80240b9 0801144b`

### 1.4 Harga (kenapa "tak terbatas" tetap dibatasi koin)

`getPrice(owned, amount)` 1.72.2 `0x5a8630` / 1.71.1 `0x59e020` — terverifikasi di sesi ini (bentuk tertutup deret aritmetika: `umull` + `lsr #1` + `madd`):

```
price = unit_price × ( amount×owned + amount×(amount+1)/2 )
      = unit_price × Σ(owned+i) untuk i = 1..amount
unit_price = int32 di global [0x87eb40]   (1.72.2; padanan 1.71.1 belum dilacak)
amount <= 0 -> 0
```

Artinya harga **naik per booster yang dimiliki**: membeli 10 sekaligus saat owned=0 jauh lebih murah daripada saat owned=1000. Dengan ~1,9 miliar koin user, batas praktis bukan angka 10 melainkan koin — tapi batch besar tetap mahal secara kuadratik (Σ). Contoh: bila `unit_price` = 100, beli 10 saat owned=0 = 100×55 = 5.500; beli 10 saat owned=1000 = 100×10.055 ≈ 1.005.500. (Angka unit_price di atas ilustrasi — nilai pastinya ada di `[0x87eb40]`, belum dibaca runtime.)

Pola 16 byte @ `0x5a8630` / `0x59e020` (identik):
`3f040071 6b020054 2900000b 0a040011`

### 1.5 Kandidat patch batas beli

Semua patch di bawah = 1 instruksi (4 byte), reversibel (kembalikan byte asli). **Set lengkap yang dibutuhkan untuk alur dialog normal = P-BUY-A.**

| ID | Situs | Patch (contoh batas baru N=99) | Efek |
|---|---|---|---|
| **P-BUY-A1** | Plus clamp `0x5adca8`/`0x5a3698` | `cmp w8, #0xb` → `cmp w8, #0x64` (100); `mov w8, #0xa` @ `0x5adcb0`/`0x5a36a0` → `mov w8, #0x63` (99) | Jumlah terpilih boleh s.d. owned+amount ≤ 100 |
| **P-BUY-A2** | Refresh 3× `cmp #0xa` (`0x5adeb0`/`0x5adf44`/`0x5adfdc`; 1.71.1 `0x5a38a0`/`0x5a3934`/`0x5a39cc`) | `cmp w20, #0xa` → `cmp w20, #0x63` (99); `mov w4, #0xa` (argumen pesan) → `mov w4, #0x63` | Reset/pesan MAX baru terpicu di owned ≥ 99 |
| **P-BUY-A3** | Gerbang beli `0x5ae400`/`0x5a3df0` | `cmp w0, #9` → `cmp w0, #0x62` (98) | Beli lolos bila owned ≤ 98 |
| P-BUY-B | Gerbang beli saja | `b.gt #0x5ae66c` @ `0x5ae404`/`0x5a3df4` → `nop` (`d503201f`) | **TIDAK CUKUP SENDIRIAN** — dialog tetap me-reset amount ke 0 + menonaktifkan tombol beli saat owned ≥ 10 (situs 2). Hanya berguna bila digabung P-BUY-A2. |
| P-BUY-C | "Tak terbatas" praktis | Sama seperti P-BUY-A dengan N=4095 (maksimum immediate `cmp`, 12-bit) | Batas menjadi 4095; harga kuadratik akan menghabiskan koin jauh sebelum itu |

**Risiko / catatan:**
- Harga naik per owned (§1.4) — membeli ratusan sekaligus dalam satu transaksi jauh lebih mahal daripada membeli bertahap saat owned masih kecil. Bukan bug patch, ini desain harga game.
- Harga dihitung int32 (`mul w0, w8, w9`). Batch sangat besar (owned + amount besar) bisa overflow int32 → harga jadi negatif/kecil → beli "gratis" (atau crash tampilan). **Perlu probe runtime** sebelum membeli batch raksasa; mulai dari batch kecil.
- Tampilan jumlah di dialog belum dipastikan punya batas sendiri (lebar field) — probe: beli 50 sekaligus, lihat apakah angka tampil benar.
- Tidak ada efek ke save/server: `setNitro` → `save` lokal biasa (§3). Jumlah besar tersimpan sebagai int32 biasa di `UserDefault.xml`.
- Alternatif tanpa patch dialog: panggil `addNitro(n)` langsung (mis. via hook di tempat lain) — melewati ketiga situs sekaligus. Tapi itu mengubah cara kerja, bukan patch batas; tetap dicatat sebagai opsi implementasi.

---

## 2. Pemakaian + cooldown

### 2.1 Objek booster & state machine

Setiap tipe booster adalah satu objek (vtable dasar `0x83f8d0` 1.72.2 / `0x82e808` 1.71.1; factory `0x5a8688` 1.72.2 membuat objek per tipe: type 0 → ctor NITRO `0x5b6f18`, lalu `0x5aa508`, `0x5b2d08`, `0x5b0160`, `0x5b3cb8`). Layout field (offset dari objek, terverifikasi dari disassembly update/use/canUse):

| Offset | Isi |
|---|---|
| `+0x50` | state: **0 = ready, 1 = aktif, 2 = cooldown** |
| `+0x54` | enabled (byte) |
| `+0x58` | cached count (int) |
| `+0x5c` | durasi aktif (float) |
| `+0x60` | durasi cooldown (float) |
| `+0x64` | elapsed aktif (float) |
| `+0x68` | elapsed cooldown (float) |
| `+0x6c` | total pemakaian (int) |
| `+0x70` | flag gratis (byte) |
| `+0x74` | sisa pakai gratis (int) |
| `+0x78` | durasi cooldown varian B (float, awal 0) |
| `+0x7c` | charges per booster = 1 |
| `+0x80` | charges tersisa (int) |
| `+0xc0` | (NITRO) flag aktif (byte) |
| `+0xc1` | (NITRO) flag "timer cooldown berjalan" (byte) |
| `+0xcc` | (NITRO) kekuatan boost saat ini (float) |
| `+0xd0` | (NITRO) handle suara (-1 = tidak ada) |

Durasi per tipe — dari `fmov` di konstruktor (s0 = cooldown → `[0x60]`, s1 = aktif → `[0x5c]`):

| Tipe | Ctor 1.72.2 | Ctor 1.71.1 | Cooldown `[0x60]` | Aktif `[0x5c]` |
|---|---|---|---|---|
| NITRO | `0x5b6f18` (fmov @ `0x5b6f4c`) | `0x5ac858` (fmov @ `0x5ac93c`) | **2,0 dtk** | 3,0 dtk |
| JUMP | `0x5b3cb8` (fmov @ `0x5b3cf0`) | `0x5a95f8` (fmov @ `0x5a96e0`) | **0,5 dtk** | 10,0 dtk |
| BIGTIRES / GLIDER (10/10) | `0x5aa508` (fmov @ `0x5aa540`) | `0x59fdc8` (fmov @ `0x59ff30`) | **10,0 dtk** | 10,0 dtk |
| GRIP | `0x5b2d08` (fmov @ `0x5b2d40`) | `0x5a85dc` (fmov @ `0x5a8730`) | **18,0 dtk** | 10,0 dtk |
| GLIDER / BIGTIRES (10/10) | `0x5b0160` (fmov @ `0x5b0198`) | `0x5a5648` (fmov @ `0x5a5b88`) | **10,0 dtk** | 10,0 dtk |

Catatan: dua ctor 10,0/10,0 (BIGTIRES vs GLIDER) belum dibedakan urutannya — tidak memengaruhi patch (keduanya 10,0 dtk, bentuk patch sama). Cara membedakan: vtable yang dipasang sesudah pemanggilan ctor dasar (1.71.1: ctor `0x5a5648` memasang vtable `0x82f380`).

Vtable per tipe (slot: `0x18` update, `0x30` canUse, `0x38` use, `0x80` getter durasi cooldown, `0xe0` setState) — 1.72.2:

| Tipe | Vtable | update | canUse | use |
|---|---|---|---|---|
| dasar | `0x83f8d0` | `0x5a6918` | `0x5a69bc` | `0x5a6a74` |
| NITRO | `0x840808` | `0x5b7198` | `0x5a69bc` | `0x5b7014` |
| JUMP | `0x8406e8` | `0x5b5bf0` | `0x5a69bc` | `0x5b3e04` |
| GRIP | `0x8405a0` | `0x5b3584` | `0x5a69bc` | `0x5b2e44` |
| GLIDER | `0x840448` | `0x5b1c6c` | `0x5a69bc` | `0x5b0288` |
| BIGTIRES | (belum di-resolve) | — | `0x5a69bc` | — |

1.71.1: dasar `0x82e808` (update `0x59c308`, canUse `0x59c3ac`, use `0x59c464`, cooldown-getter `0x59e5c8`, setState `0x59c95c`); NITRO vtable `0x82f740` (update `0x5acb88`, canUse `0x59c3ac`, use `0x5aca04`).

### 2.2 canUse — gerbang pemakaian (dipakai semua tipe)

`0x5a69bc` (1.72.2) / `0x59c3ac` (1.71.1), slot vtable `0x30`. Terverifikasi penuh:

```
enabled?                                   ; [0x54]==0 -> false
state == 1 (aktif)?                        ; -> false
free flag [0x70] && free-uses [0x74] > 0   ; -> lanjut (tanpa cek stok)
charges [0x80] >= 1                        ; -> lanjut
charges [0x80] <= 0 -> cek inventaris: getInt('hcr1-nitro') > 0 ?
                                           ; 0 -> false
cek kendaraan (slot 0xa0 objek [car+0x40]) ; bit0 set -> false
return (state != 2)                        ; false bila state==2 (cooldown)
```

**Kesimpulan: booster hanya bisa dipakai saat state == 0.** Cooldown (state 2) maupun aktif (state 1) sama-sama memblokir pemakaian ulang.

Pola 16 byte @ `0x5a69bc` / `0x59c3ac` (identik kedua versi):
`fd7bbea9 f30b00f9 fd030091 08504139`

### 2.3 Use — konsumsi 1 booster per aktivasi

**Use dasar** `0x5a6a74` (1.72.2) / `0x59c464` (1.71.1), slot `0x38` (dipakai JUMP/BIGTIRES/GRIP/GLIDER — masing-masing punya override sendiri, tapi polanya sama; yang terverifikasi penuh adalah use dasar + use NITRO):

```
canUse? -> bila tidak, return
bila [0x80] (charges tersisa) > 0 : pakai ulang TANPA konsumsi
bila flag gratis [0x70]          : [0x74]-- (pakai jatah gratis)
bila tidak                       : setNitro(count-1) @ 0x5a6af8  ; KONSUMSI 1
[0x80] = [0x7c] = 1 ; [0x80]--    ; charge langsung habis (jadi 0)
setState(1)                       ; aktif
```

Pola 16 byte @ `0x5a6a74` / `0x59c464` (identik):
`ff0301d1 fd7b01a9 f51300f9 f44f03a9`

**Use NITRO** `0x5b7014` (1.72.2) / `0x5aca04` (1.71.1), slot `0x38` override:

```
canUse? (slot 0x30) -> bila tidak, return
bila flag gratis [0x70] : [0x74]-- (dengan clamp >= 0)
bila tidak               : mov w0, #1; bl subtractNitro  ; KONSUMSI 1
[0x6c]++                                  ; total pemakaian
[0xcc] = 0 ; [0x64] = [0x68] = 0          ; reset timer + kekuatan
setState(1) ; [0xc0] = 1                  ; aktif
```

Titik konsumsi NITRO: `bl #0x5a6ba4` @ `0x5b7058` (1.72.2) / `bl #0x59c594` @ `0x5aca48` (1.71.1).
Pola 16 byte @ `0x5b7054` / `0x5aca44` (identik kedua versi):
`20008052 d3beff97 686e40b9 7fce00b9`

**Model konsumsi: tiap aktivasi = 1 booster dari stok bersama** (kecuali bila ada jatah gratis `[0x70]`/`[0x74]` — kemungkinan dari hadiah video — atau charge tersisa `[0x80]` > 0, yang dalam praktik langsung habis setelah satu kali pakai). Tidak ada "pakai gratis selamanya" bawaan game.

### 2.4 Update — transisi state & cooldown

**Update dasar** `0x5a6918` (1.72.2) / `0x59c308` (1.71.1), slot `0x18`. Terverifikasi penuh:

```
state = [0x50]
bila state == 1 (aktif):
    [0x64] += dt
    bila [0x64] >= [0x5c] (durasi aktif) -> setState(2)   ; masuk cooldown
bila state == 2 (cooldown):
    [0x68] += dt
    dur = getter slot 0x80  ; = [0x60], atau [0x78] bila [0x80]>0  (lihat 0x5a8bd8)
    bila [0x68] >= dur -> setState(0)                    ; ready lagi
```

Getter durasi cooldown (slot `0x80`) `0x5a8bd8`: mengembalikan `[0x78]` bila `[0x80]` (charges?) > 0, bila tidak `[0x60]`. `[0x78]` adalah "durasi cooldown varian B" (awal 0, di-set via setter slot `0xc0` = `0x5a8c4c`; caller setter itu belum dipetakan — kemungkinan jalur hadiah/promo).

**Keempat tipe non-NITRO memanggil update dasar dari update-nya sendiri** (blxref `0x5a6918`: `0x5b1c88` (GLIDER), `0x5b359c` (GRIP), `0x5b5c1c` (JUMP), `0x5aaf80` (BIGTIRES)). Jadi patch di update dasar menjangkau keempat tipe sekaligus.

**Update NITRO** `0x5b7198` (1.72.2) / `0x5acb88` (1.71.1) **tidak** memanggil update dasar — ia punya helper sendiri `0x5b751c` / `0x5acf0c`:

```
helper(dt):
  bila [0xc1] (timer cooldown berjalan):
      [0x68] += dt
      bila [0x68] > [0x60] (2,0 dtk) -> 0x5b7628 / 0x5ad018:
          [0xc1] = 0
          bila enabled && getNitroCount() >= 1 -> setState(0)
      bila belum -> return (masih cooldown)
  bila [0xc1] == 0:
      bila state == 2 -> setState(0)
      bila [0xc0] (aktif):
          [0x64] += dt
          bila [0x64] > [0x5c] (3,0 dtk) -> boost-end 0x5b7678:
              hentikan suara ([0xd0] -> -1)
              [0xc0] = 0 ; [0xc1] = 1 ; [0xcc] = 0
              setState(2)     ; masuk cooldown
```

Siklus NITRO lengkap: `use` → state 1 (aktif 3,0 dtk, `[0xc0]=1`) → `boost-end` → state 2 + `[0xc1]=1` (cooldown 2,0 dtk) → `cooldown-end` → state 0 (ready, **hanya bila stok ≥ 1**).

Pola 16 byte helper NITRO (identik kedua versi):
- `[0xc1]` check @ `0x5b752c` / `0x5acf1c`: `08044339 f30300aa 081ca04e 88010034`
- `fadd`/`fcmp` cooldown @ `0x5b753c` / `0x5acf2c`: `606a40bd 616240bd 0028281e 0020211e`

### 2.5 Kandidat patch "pakai terus-menerus tanpa cooldown"

| ID | Sasaran | Patch (4 byte, reversibel) | Cakupan |
|---|---|---|---|
| **P-CD-A** (rekomendasi) | Ctor tiap tipe, `fmov s0, #X` (durasi cooldown) | `fmov s0, #X` → `fmov s0, #0.0` (`0000201e`) | Per tipe. NITRO @ `0x5b6f4c`/`0x5ac93c`; JUMP @ `0x5b3cf0`/`0x5a96e0`; BIGTIRES @ `0x5aa540`/`0x59ff30` atau `0x5a5b88`; GRIP @ `0x5b2d40`/`0x5a8730`; GLIDER @ `0x5b0198`/sisanya. Cooldown jadi ~1 frame. |
| P-CD-B | Helper NITRO, `b.le` cooldown @ `0x5b7550`/`0x5acf40` | `b.le` → `b` (lompat selalu ke akhir-cooldown) | NITRO saja. Setara P-CD-A untuk NITRO. |
| P-CD-C | Update dasar `0x5a6918`/`0x59c308` | Ubah transisi aktif→cooldown: `b.ge #0x5a699c` @ `0x5a6988` (1.72.2) agar menuju jalur `setState(0)`, bukan `setState(2)` — atau NOP akumulasi `[0x68]` | Keempat tipe non-NITRO sekaligus (mereka semua memanggil update dasar). Perlu kehati-hatian: satu situs bersama, jangan sampai merusak transisi state 1. |
| P-CD-D | canUse — **TIDAK disarankan** | Hapus cek state==2 (`cmp w8,#2` + `cset`) | Rapuh: `[0xc1]` tetap 1 selama cooldown → helper tidak menjalankan bagian "aktif" (`[0xc0]`), jadi boost tidak bekerja walau state dipaksa 1; state machine desinkron. Jangan dipakai. |
| **P-CD-E** (komplemen, bukan cooldown) | Titik konsumsi | NITRO: `bl subtractNitro` @ `0x5b7058`/`0x5aca48` → `nop`. Dasar: pemanggilan `setNitro(count-1)` @ `0x5a6af8` → `nop` | Aktivasi tidak mengurangi stok. Cooldown tetap berlaku (2 dtk NITRO) — tapi stok tidak pernah habis, jadi "terus-menerus" dalam arti tidak kehabisan. Kombinasi P-CD-A + P-CD-E = pakai tanpa jeda DAN tanpa habis. |

Pola 16 byte ctor NITRO @ `0x5b6f4c` / `0x5ac93c` (identik):
`0010201e 0110211e f30300aa e80700f9`
(`fmov s0, #2.0` = `0010201e`; `fmov s1, #3.0` = `0110211e`. Untuk tipe lain, ganti byte pertama pola: JUMP `00102c1e` (0,5), BIGTIRES/GLIDER `0090241e` (10,0), GRIP `0050261e` (18,0).)

**Risiko / catatan pemakaian:**
- **Tidak ada stacking tipe yang sama:** `canUse` menolak aktivasi saat state==1, jadi NITRO tidak bisa ditumpuk dengan dirinya sendiri. Setelah cooldown di-nol-kan, rangkaiannya: aktif 3 dtk → jeda ~1 frame → aktivasi lagi (konsumsi 1 booster lagi). "Terus-menerus" = rantai aktivasi, bukan satu aktivasi abadi.
- **Stacking antar tipe berbeda BELUM terbukti** — tiap tipe objeknya sendiri-sendiri dengan state masing-masing; kemungkinan NITRO + GLIDER aktif bersamaan masih perlu probe runtime (tombol pakai per tipe di GameLayer memanggil slot `0x38` objeknya masing-masing).
- **Cooldown-end mensyaratkan stok ≥ 1** (NITRO helper `0x5b7628`: `getNitroCount() >= 1 → setState(0)`). Bila stok habis di tengah rantai, booster berhenti bisa dipakai (perilaku benar, bukan crash) — kecuali bila P-CD-E dipakai (stok tak berkurang).
- Efek samping yang teramati di kode: boost-end menghentikan satu suara (`[0xd0]`); tidak ada efek lain (tidak ada pengali skor/koin yang terikat ke booster di jalur ini).
- Durasi aktif `[0x5c]` TIDAK diubah patch di atas — NITRO tetap 3,0 dtk per aktivasi. Memperpanjang durasi aktif adalah patch terpisah (`fmov s1` di ctor).

---

## 3. Konfirmasi lokal (inventaris + koin/gems tanpa server)

### 3.1 Profil = cocos2d-x UserDefault, file lokal

- Singleton profil `0x6ae768` (1.72.2) membuat objek bervtable `0x866bc0` (slot `0x18` getInt `0x6ade84`, slot `0x50` setInt `0x6ae480`, slot `0x78` save `0x6aea00`).
- Fungsi `0x6ae818` (dipanggil dari getter singleton) membangun path file: `FileUtils::getWritablePath()` (`bl 0x6a1d10`) + string **`"UserDefault.xml"`** (rodata `0x1f3327`, dipakai di `0x6ae84c–0x6ae858`) → `<writable_path>/UserDefault.xml`. Path disimpan di global `0x8e6b60`.
- Fungsi save `0x6aea00` menserialisasi map kunci-nilai ke XML dengan elemen root **`"userDefaultRoot"`** (string rodata `0x1f8ca1`, dipakai di `0x6aeaf0–0x6aeaf8`). Ini format standar cocos2d-x `UserDefault`.
- Kunci yang dipakai: `'hcr1-nitro'` (inventaris), `'coins'` (rodata `0x1cb001`), `'gems'` (rodata `0x1ca88c`) — kunci polos UserDefault, tanpa awalan `hcr1-` untuk mata uang.
- Koin di memori: global `[0x8772d8]` berisi **pointer** ke int koin (bukan int-nya langsung) — dibaca di `0x5ae3c8`, dikurangi di `0x5ae408–0x5ae410`. Cermin in-memory dari nilai UserDefault.

### 3.2 Tidak ada panggilan jaringan di jalur beli/pakai

Metode: petakan alamat PLT (`socket` `0x803e50`, `connect` `0x803e70`, `send` `0x803ea0`, `recv` `0x803e20`, `fopen` `0x801980`, `fwrite` `0x801f50`) lewat `.rela.plt`, lalu pindai semua instruksi `bl` di fungsi-fungsi jalur booster.

- **0 panggilan jaringan / file-IO langsung** di: beli (`0x5ae208`, `0x5ae364`), plus (`0x5adc2c`), refresh (`0x5ade68`), `getNitroCount` (`0x5a6874`), `setNitro` (`0x5a843c`), `addNitro` (`0x5a8480`), `subtractNitro` (`0x5a6ba4`), harga (`0x5a8630`), getter profil (`0x6ae768`), `getInt` (`0x6ade84`), `setInt` (`0x6ae480`), `save` (`0x6aea00`), `canUse` (`0x5a69bc`), use dasar (`0x5a6a74`), use NITRO (`0x5b7014`), update dasar (`0x5a6918`), update NITRO (`0x5b7198`), helper NITRO (`0x5b751c`), boost-end (`0x5b7678`), cooldown-end (`0x5b7628`).
- **Seluruh binary hanya punya 6 situs panggil jaringan:** `socket` @ `0x78bb4c`, `0x78d9b4`; `connect` @ `0x78bc44`, `0x78bc64`; `send` @ `0x78be84`; `recv` @ `0x784ea8` — semuanya di wilayah `0x784xxx–0x78dxxx` (satu subsistem socket, kemungkinan HttpClient/WebSocket cocos2d-x), **tidak dirujuk dari kode booster mana pun**.
- Penulisan file akhirnya lewat `std::ofstream` (fopen internal libstdc++, bukan panggilan PLT langsung dari `libgame.so`) — konsisten dengan tidak ditemukannya `bl fopen`/`fwrite` di jalur save tingkat atas. `fopen` hanya dipanggil dari 5 tempat lain di binary (`0x37d108`, `0x5937fc`, `0x5f08f4`, `0x5f0d18`, `0x5fe3fc`), tak satu pun di jalur booster.
- Batasan bukti: ini bukti statis (tidak ada panggilan di graf panggil). Bukti definitif = probe runtime mode pesawat (§5).

### 3.3 Dampak praktis

Beli/pakai booster = baca/tulis `UserDefault.xml` lokal + cermin memori. Tidak ada validasi server atas jumlah booster, koin, atau cooldown. Patch client-side pada situs-situs di §1–§2 bekerja tanpa melawan server.

---

## 4. Tabel patch lengkap (implementasi — bukan bagian riset ini)

Semua patch 4 byte (1 instruksi), reversibel dengan mengembalikan byte asli. Pola 16 byte di bawah **identik antara 1.72.2 dan 1.71.1** (kecuali refresh pesan-MAX, 12 byte pertama identik).

### 4.1 Batas beli (paket lengkap P-BUY-A, batas baru contoh N=99)

| Situs | 1.72.2 | 1.71.1 | Instruksi asli | Patch (N=99) | Pola 16 byte |
|---|---|---|---|---|---|
| Plus clamp (cmp) | `0x5adca8` | `0x5a3698` | `cmp w8, #0xb` | `cmp w8, #0x64` | `1f2d00718b000054480180520801004b` |
| Plus clamp (mov) | `0x5adcb0` | `0x5a36a0` | `mov w8, #0xa` | `mov w8, #0x63` | `480180520801004b686201b9e00313aa` |
| Refresh reset | `0x5adeb0` | `0x5a38a0` | `cmp w20, #0xa` | `cmp w20, #0x63` | `9f2a0071f503002acb02005460de40f9` |
| Refresh tampilan | `0x5adf44` | `0x5a3934` | `cmp w20, #0xa` | `cmp w20, #0x63` | `9f2a0071a0833eada0833dadeb000054` |
| Refresh pesan MAX | `0x5adfdc` | `0x5a39cc` | `cmp w20, #0xa` | `cmp w20, #0x63` | 1722 `9f2a0071cb02005400e1ffb000d83e91` / 1711 `9f2a0071cb02005440e1ffb0002c0a91` |
| Refresh argumen %d | `0x5ae008` | `0x5a39f8` | `mov w4, #0xa` | `mov w4, #0x63` | (di dalam jendela pesan MAX) |
| Gerbang beli | `0x5ae400` | `0x5a3df0` | `cmp w0, #9` | `cmp w0, #0x62` | `1f2400714c130054e80240b90801144b` |

Alternatif gerbang saja: `b.gt` @ `0x5ae404`/`0x5a3df4` → `nop` (`d503201f`) — lihat peringatan P-BUY-B di §1.5.

### 4.2 Cooldown (paket P-CD-A, semua tipe) + konsumsi (P-CD-E)

| Situs | 1.72.2 | 1.71.1 | Instruksi asli | Patch | Pola 16 byte |
|---|---|---|---|---|---|
| Ctor NITRO (cd 2,0) | `0x5b6f4c` | `0x5ac93c` | `fmov s0, #2.0` | `fmov s0, #0.0` (`0000201e`) | `0010201e0110211ef30300aae80700f9` |
| Ctor JUMP (cd 0,5) | `0x5b3cf0` | `0x5a96e0` | `fmov s0, #0.5` | `fmov s0, #0.0` | (pola `00102c1e` + `fmov s1,#10.0` sesudahnya) |
| Ctor BIGTIRES (cd 10,0) | `0x5aa540` | `0x59ff30` / `0x5a5b88` | `fmov s0, #10.0` | `fmov s0, #0.0` | (pola `0090241e` + `fmov s1,#10.0`) |
| Ctor GRIP (cd 18,0) | `0x5b2d40` | `0x5a8730` | `fmov s0, #18.0` | `fmov s0, #0.0` | (pola `0050261e` + `fmov s1,#10.0`) |
| Ctor GLIDER (cd 10,0) | `0x5b0198` | sisanya dari dua 10/10 | `fmov s0, #10.0` | `fmov s0, #0.0` | (pola `0090241e` + `fmov s1,#10.0`) |
| Helper NITRO (alt.) | `0x5b7550` | `0x5acf40` | `b.le` | `b` (selalu) | dalam pola `606a40bd616240bd0028281e0020211e` |
| Konsumsi NITRO | `0x5b7058` | `0x5aca48` | `bl subtractNitro` | `nop` | `20008052d3beff97686e40b97fce00b9` |
| Update dasar (alt. non-NITRO) | `0x5a6918` (+`0x5a6988`) | `0x59c308` | `b.ge` aktif→cooldown | arahkan ke jalur `setState(0)` | (verifikasi pola 1.71.1 di `0x59c308` sebelum patch) |

Cara patch/hook (rekomendasi umum, mengikuti pola mod yang sudah ada):
- **Patch byte langsung** (seperti god mode v4/v5): pattern-scan 16 byte → verifikasi byte → tulis 4 byte → simpan byte asli untuk rollback. Paling cocok untuk semua situs di atas (semuanya 1 instruksi, tanpa parameter runtime).
- **Dobby-hook** hanya bila diperlukan (mis. bila ingin batas N yang bisa diubah dari panel mod menu saat runtime — hook fungsi `getNitroCount`/`getPrice` tidak memberi itu; hook tidak memberi keuntungan di sini karena semua situs adalah konstanta).
- Semua patch reversibel: tidak ada yang mengubah struktur data, tidak ada yang mengalokasikan memori, tidak ada yang menyentuh vtable.

---

## 5. Batas kejujuran — terbukti vs dugaan vs butuh probe

### Terbukti dari disassembly (sesi ini)
- Tiga situs penegakan batas 10 + logika masing-masing (plus clamp, refresh reset/pesan, gerbang beli `cmp #9`).
- Inventaris satu kunci `'hcr1-nitro'`; getter/setter/adder/subtracter + alamatnya di kedua versi.
- Rumus harga deret aritmetika + unit dari global `[0x87eb40]` (1.72.2).
- State machine booster (field + transisi), `canUse` (hanya state 0), konsumsi 1 per aktivasi (dasar + NITRO), siklus cooldown NITRO (aktif 3,0 → cooldown 2,0 → ready bila stok ≥ 1).
- Durasi cooldown/aktif tiap tipe dari ctor.
- Keempat tipe non-NITRO memanggil update dasar (blxref `0x5a6918`).
- Profil = UserDefault → `UserDefault.xml` lokal; kunci `'coins'`/`'gems'`/`'hcr1-nitro'`.
- 0 panggilan jaringan di seluruh graf panggil jalur beli/pakai; 6 situs jaringan di binary ada di subsistem socket terpisah.

### Masih dugaan (belum dibuktikan)
- Identitas persis kelima pemberi `addNitro` gratis (kemungkinan hadiah daily/video/level-up) — tidak memengaruhi patch.
- Siapa yang memanggil setter slot `0xc0` (durasi cooldown varian B `[0x78]`) — kemungkinan jalur hadiah/promo; tidak memengaruhi patch P-CD-A (yang menyentuh `[0x60]`).
- Urutan BIGTIRES vs GLIDER di antara dua ctor 10,0/10,0 — tidak memengaruhi patch.
- Nilai `unit_price` di `[0x87eb40]` (1.72.2) dan padanannya di 1.71.1 — belum dibaca dari memori.
- Apakah dialog jumlah punya batas tampilan sendiri di luar ketiga situs ini.

### Probe runtime yang dibutuhkan (sebelum/saat implementasi)
1. **Mode pesawat:** beli 1 booster + pakai 1 booster dengan data/Wi-Fi mati → bila berhasil, konfirmasi lokal definitif.
2. **Isi `UserDefault.xml`:** buka file save (di `/data/data/com.fingersoft.hillclimb/files/` atau `shared_prefs` setara — lokasi persisnya dari `getWritablePath`, belum dibaca runtime) sesudah beli → kunci `hcr1-nitro` harus bertambah; sesudah pakai → berkurang 1.
3. **Rantai NITRO pasca-patch:** aktifkan NITRO, tunggu 3 dtk (habis), tekan lagi segera → harus langsung aktif lagi (tanpa jeda 2 dtk). Ulang 5× → stok berkurang 5 (bila tanpa P-CD-E) / tetap (bila dengan P-CD-E).
4. **Stacking antar tipe:** aktifkan NITRO lalu GLIDER selagi NITRO aktif → apakah keduanya bekerja bersamaan? (Menentukan apakah "tanpa cooldown" bisa dikombinasikan antar tipe.)
5. **Beli batch besar:** beli 50 sekaligus pasca-patch → cek harga yang tampil vs rumus §1.4, dan cek tidak ada overflow int32 (harga negatif / beli gratis / crash).
6. **Tampilan dialog:** beli hingga owned = 15, 50, 99 → pastikan angka tampil benar dan tombol beli tetap aktif.
7. **Cooldown-end saat stok 0:** habiskan stok sampai 0 lalu pakai booster terakhir → pastikan tidak ada soft-lock (state 2 yang tidak pernah kembali ke 0 — kode mensyaratkan stok ≥ 1 untuk kembali ready; `canUse` sudah false saat stok 0, jadi ini aman secara logika, tapi perlu konfirmasi lapangan).

---

## Lampiran — peta fungsi (1.72.2 / 1.71.1)

```
PowerUpDialog (toko booster)
  plus handler      0x5adc2c / 0x5a361c     (clamp #11/#10)
  refresh           0x5ade68 / 0x5a3858     (3x cmp #10, pesan MAX)
  dialog setup      0x5ae208 / (—)         (memanggil refresh)
  buy-confirm       0x5ae364 / 0x5a3ad4     (gerbang cmp #9, kurangi koin, addNitro)
  insufficient      0x5ae0e4 / (—)         (toast koin tidak cukup)

Inventaris & harga
  getNitroCount     0x5a6874 / 0x59c264
  setNitro          0x5a843c / 0x59de2c
  addNitro          0x5a8480 / 0x59de70
  subtractNitro     0x5a6ba4 / 0x59c594
  getPrice          0x5a8630 / 0x59e020     (unit @ [0x87eb40] 1.72.2)
  factory booster   0x5a8688 / (—)
  profil singleton  0x6ae768 / (—)         (vtable 0x866bc0)
  getInt            0x6ade84 / (—)         (slot 0x18)
  setInt            0x6ae480 / (—)         (slot 0x50)
  save (UserDefault) 0x6aea00 / (—)        (slot 0x78; file UserDefault.xml)

Booster: state machine
  base update       0x5a6918 / 0x59c308     (slot 0x18 dasar)
  canUse            0x5a69bc / 0x59c3ac     (slot 0x30, semua tipe)
  base use          0x5a6a74 / 0x59c464     (slot 0x38 dasar)
  cooldown getter   0x5a8bd8 / 0x59e5c8     (slot 0x80)
  setState          0x5a6f6c / 0x59c95c     (slot 0xe0)
  NITRO update      0x5b7198 / 0x5acb88     (slot 0x18 NITRO)
  NITRO helper      0x5b751c / 0x5acf0c     (cooldown + aktif NITRO)
  NITRO use         0x5b7014 / 0x5aca04     (slot 0x38 NITRO)
  NITRO boost-end   0x5b7678 / (—)         (aktif -> cooldown)
  NITRO cd-end      0x5b7628 / 0x5ad018     (cooldown -> ready)
  NITRO ctor        0x5b6f18 / 0x5ac858     (cd 2,0 / aktif 3,0)
  JUMP ctor         0x5b3cb8 / 0x5a95f8     (cd 0,5 / aktif 10,0)
  BIGTIRES ctor     0x5aa508 / 0x59fdc8 atau 0x5a5648 (cd 10,0 / aktif 10,0)
  GRIP ctor         0x5b2d08 / 0x5a85dc     (cd 18,0 / aktif 10,0)
  GLIDER ctor       0x5b0160 / sisanya     (cd 10,0 / aktif 10,0)

File kerja sesi ini: ~/workspace/rea-hcr-booster/work/
  (xref.py, blxref.py, hcrdis.py, elfmap.py, vtable.py, vtable2.py, got2plt.pkl,
   fn_*.txt, x_*.txt)
```

## Koreksi terhadap ringkasan pra-sesi (ditemukan saat verifikasi ulang)

- Fungsi buy-confirm 1.72.2 **bermula di `0x5ae364`**, bukan `0x5ae208` — `0x5ae208` adalah fungsi setup dialog (memanggil refresh `0x5ade68`), dan buy-confirm adalah fungsi berikutnya setelah `ret`-nya.
- Koin global `[0x8772d8]` berisi **pointer** ke int koin, bukan int-nya langsung (`ldr x23, [x23, #0x2d8]` lalu `ldr w21, [x23]`).
- `func_start` (hcrdis) kadang salah untuk fungsi berdekatan — alamat fungsi di laporan ini diambil dari prolog yang terlihat langsung, bukan dari tabel itu.
