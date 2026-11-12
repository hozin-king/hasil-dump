# Riset Combo — Criminal Case v2.45.2 (1830811)

**Tanggal:** 11 November 2026 (WIB)
**Target:** state pengali combo (x2–x6) + mekanisme reset, untuk hook dari injector root
**Status:** FASE STATIK SELESAI — laporan riset, BUKAN aplikasi/mod. Tidak ada file game yang diubah, tidak ada patch/repack, PairIP tidak disentuh.
**Dasar:** `libcriminalcase.so` (20,2 MB, Cocos2d-x 2.2.6, namespace `montana`), `dumps/strings-libcriminalcase.txt`, `ESP-RESEARCH.md` (metode derivasi vtable dari graf relokasi).
**Tools:** `llvm-objdump` NDK 26.1.10909125, `llvm-readelf`, Python + pyelftools. Disassembly penuh `.text` disimpan sementara di `/tmp/dis_all.txt` (2.696.748 baris, bukan bagian repo kerja).

---

## 0. Ringkasan eksekutif

- **Field combo = int32 di `StageTopBarCombo + 0x120`, rentang 0..5.** Pengali tampil = combo+1 (x1..x6). Terbukti dari ctor (init 0), increment, clamp, decrement, reset, dan getter — semuanya membaca/menulis offset yang sama.
- **Reset = fungsi `Combo::reset` di `0xa7e1e0`**: matikan glow slot yang menyala, lalu `str wzr, [x0, #0x120]` (combo = 0). Satu-satunya pemanggilnya (via thunk `StageTopBar::resetCombo` `0xa79d8c`) adalah handler salah ketuk di `0x92e824`.
- **Naik = fungsi `Combo::increment` di `0xa7ddec`**: combo++ (cap 5), update glow slot, tampilkan sprite popup `ho/ho_bonus<N>` (N = min(combo,5)+1). Dipanggil tiap kali objek ditemukan (3 situs, via thunk `0xa79d78`).
- **Skor BUKAN `base * (combo+1)`** — melainkan **lookup tabel** `0xaa243c(item, combo, 0)` → `tabel[combo]` (int di +0x18 elemen). Jadi "x6" = baris tabel indeks 5; nilai rupiah/poin tiap baris tidak bisa dibaca dari statik (tabelnya di memori runtime).
- **Vtable Combo hanya berisi 2 method khusus** (destructor); semua logika combo ada di method NON-virtual — jadi hook harus ke alamat fungsi langsung, bukan via vtable.
- **KOREKSI PENTING terhadap metode ESP-RESEARCH §2.2:** alamat vtable yang diturunkan di sana adalah alamat *header* vtable (offset-to-top + typeinfo). **Nilai vptr yang hidup di memori = header + 16** (vptr menunjuk slot fungsi virtual pertama; offset-to-top ada di vptr−16, typeinfo di vptr−8). Terbukti dari ctor/dtor. Semua alamat ESP harus ditambah 16 saat dipakai untuk heap-scan vptr. (Detail di §1.3.)

---

## 1. Vtable `montana::StageTopBarCombo` — TERBUKTI

### 1.1 Derivasi (metode yang sama seperti ESP-RESEARCH §2.2)

| Langkah | Hasil |
|---|---|
| String nama typeinfo `N7montana16StageTopBarComboE` | file offset / vaddr `0x3c4964` |
| Relokasi `R_AARCH64_RELATIVE` → string | `0x1200ce8` (satu-satunya) → objek typeinfo `0x1200ce0` |
| Relokasi → objek typeinfo | `0x12009a0` (satu-satunya) → **vtable header `0x1200998`** |
| Verifikasi `llvm-readelf -r` | `0x1200ce0`: `R_AARCH64_ABS64 _ZTVN10__cxxabiv120__si_class_type_infoE + 0x10` (vptr typeinfo); `0x1200ce8` → nama; `0x1200cf0` → `0x1208840` = typeinfo `cocos2d::CCNode` → **Combo single-inheritance langsung dari `CCNode`** (`__si_class_type_info`) |

**Keyakinan: TINGGI** (satu-satunya kandidat di tiap langkah, dan struktur `__si_class_type_info` terkonfirmasi lengkap: vptr + nama + base=CCNode).

### 1.2 Isi vtable (dari graf relokasi; slot berurutan, addend di `.text` 0x75ea80–0x11725d4)

- Total **103 method virtual** (indeks [2]..[104] dari header; [0]=offset-to-top, [1]=typeinfo).
- Hanya **[2] dan [3] yang khusus Combo**:
  - `[2]` (vptr+0) = `0xa7d844` — complete destructor `~StageTopBarCombo`
  - `[3]` (vptr+8) = `0xa7d94c` — deleting destructor (memanggil [2], lalu `operator delete` dengan **size `0x188` = 392 → `sizeof(StageTopBarCombo) = 0x188`**)
- `[4]`..`[104]` = virtual `CCNode` yang diwarisi — alamatnya **identik** di vtable Combo, Slot, Item, SlotGlow, dan StageTopBar (mis. `0xaed8a4`, `0xaeda24`, `0xae94f0`, `0xae8028`, …). Jadi **tidak ada method virtual khusus combo** (tidak ada `setCombo`/`updateCombo` virtual). Logika combo hidup di method non-virtual (§3) — hook harus menarget alamat fungsi, bukan entri vtable.

### 1.3 KOREKSI: nilai vptr hidup = header + 16

Ctor `StageTopBarCombo::StageTopBarCombo` (`0xa7d670`):

```asm
a7d688: adrp  x8, 0x1200000
a7d68c: add   x8, x8, #0x9a8        ; x8 = 0x12009a8 = header 0x1200998 + 0x10
a7d698: str   x8, [x19]            ; this->vptr = 0x12009a8
```

Destructor `0xa7d844` dan semua dtor saudaranya melakukan hal yang sama (`str` header+16). Ini sesuai ABI Itanium: **vptr menunjuk slot fungsi virtual pertama; offset-to-top = [vptr−16], typeinfo = [vptr−8]**. Aturan verifikasi runtime ESP-RESEARCH §2.2 ("cek [0]==0, [1]==typeinfo di base+vtable") harus dibaca sebagai: **cek [vptr−16]==0 dan [vptr−8]==base+typeinfo**, dengan **vptr = alamat ESP + 16**. Konsekuensi praktis: heap-scan mencari objek Combo harus mencocokkan nilai **`base + 0x12009a8`**, bukan `base + 0x1200998`.

### 1.4 Vtable kelas-kelas tetangga (metode sama, semua kandidat tunggal → keyakinan TINGGI)

| Kelas | Typeinfo | Vtable header | vptr hidup (= header+16) | sizeof | Catatan |
|---|---|---|---|---|---|
| `StageTopBarCombo` | `0x1200ce0` | `0x1200998` | **`0x12009a8`** | `0x188` | 103 virtual; khusus hanya 2 dtor |
| `StageTopBarComboSlot` | `0x11fff60` | `0x11ffc18` | `0x11ffc28` | `0x178` | 103 virtual; khusus hanya 2 dtor (`0xa7b3d0`/`0xa7b480`, deleting dtor delete size `0x178`) |
| `StageTopBarComboItem` | `0x11ffc00` | `0x11ff8b0` | `0x11ff8c0` | — | 104 virtual; override di indeks 21 (`0xa7a900`, lihat §4) + 1 virtual tambahan di [105] (`0xa7a474`) |
| `StageTopBarComboSlotGlow` | `0x12002c0` | `0x11fff78` | `0x11fff88` | — | 103 virtual; khusus hanya 2 dtor |
| `StageTopBar` | `0x11ff898` | `0x11ff550` | `0x11ff560` | `0x158` | 103 virtual; khusus hanya 2 dtor (`0xa79ce0`/`0xa79ce4`); Combo* ada di **TopBar+0x148** |

Catatan koreksi kecil: derivasi ulang `StageScreen` memberi kandidat header `0x11bc108` (bukan `0x11bc100` seperti di ESP-RESEARCH — selisih 1 slot). Perlu cek ulang saat verifikasi runtime; tidak berdampak ke riset combo.

---

## 2. Field state combo — TERBUKTI

Objek `StageTopBarCombo` (base `CCNode` 280 byte = `0x118`, field turunan menempel setelahnya):

| Offset | Tipe | Isi / bukti |
|---|---|---|
| `+0x120` | **int32** | **COUNTER COMBO, 0..5.** Ctor `0xa7d708: str wzr, [x19, #0x120]` (init 0). Increment `0xa7de64: add w8, w8, #1 / str w8, [x21, #0x120]`. Clamp `0xa7dd84: mov w8, #5 / str w8, [x19, #0x120]`. Decrement `0xa7e144: sub w9, w9, #1 / str w9, [x0, #0x120]`. Reset `0xa7e250: str wzr, [x19, #0x120]`. Getter `0xa7e40c: ldr w0, [x0, #0x120]; ret`. |
| `+0x148` / `+0x14c` | int32 ×2 | Dua int (dipakai sebagai posisi/anchor sprite background; ctor memuat dari `.rodata 0x335508`; `+10` lalu `scvtf` saat membangun sprite di `0xa7d9c0`) — bukan state combo. |
| `+0x150` | byte | Flag booster/aktif. Diset 1 oleh `0xa7e2f0`/`0xa7e36c`, di-0-kan oleh `0xa7e330`. Di `refresh` dipakai sebagai `w2 = 1 & ~flag150` (menahan trigger ulang glow saat booster aktif). |
| `+0x158`, `+0x160`, `+0x168` | ptr | Sprite background (`top_combo_bg` → +0x158, `top_box_bevel` → +0x160, `top_bg_reflect` → +0x168), dibuat di `0xa7d9c0`. |
| `+0x170`, `+0x178` | ptr | Node turunan lain (dibuat di `0xa7dbe8` via `0xae86c8` = `CCNode::create`-ish, lalu `addChild` virtual [vptr+0x190]). |
| `+0x180` | `CCArray*` | **Array 5 slot combo.** Dibuat di `0xa7dbe8` (`0xaeec40` = `CCArray::create`), tiap slot ditambah via `0xaeeda0` (`addObject`). Diakses sebagai `ccArray` lewat `[array+0x18]` → `{num @+0, arr @+8}`. Dtor mengiterasi array ini. |
| `+0x124`..`+0x147` | packed | Tabel per-slot (5 entri × ~3 byte: warna/posisi) yang ditulis ctor (`0xb1f2`, `0x99fd`, `0x77f4`, `0x3bf7`, `0x56f6`, …) dan dibaca loop pembuat slot di `0xa7dbe8` (indeks `x25 = 0x144, 0x141, 0x13e, 0x13b, 0x138`). |

**Pengali tampil = combo + 1.** Bukti di ekor `0xa7ddec` (`0xa7df4c`): `w9 = min(combo, 5); w0 = w9 + 1; to_string(w0)` lalu `insert(0, "ho/ho_bonus", 11)` → sprite popup **`ho/ho_bonus<N>`** dengan N = 1..6 (skala 0.6, via `0x7d1f10`). Lima slot dibuat di `0xa7dbe8` (loop `w24 = 0x49..0x4d`, indeks slot `w21 = w24 − 0x48 = 1..5`) — slot ke-i menyala saat combo mencapai i. Jadi x1 = combo 0 (tanpa slot menyala), x6 = combo 5 (semua slot menyala).

**Skor memakai combo sebagai indeks tabel, bukan perkalian.** `0xaa243c(item, combo, 0)`:

```asm
aa2454: bl 0xaeee40                ; w0 = jumlah baris tabel item itu
aa2458: cmp w20, w0               ; w20 = combo
aa245c: b.hs 0xaa2478              ; combo >= jumlah baris -> return 0
aa2468: bl 0xaeee54                ; elemen tabel[combo]
aa2470: ldr w0, [x0, #0x18]       ; skor = elemen->field +0x18
```

Nilai tiap baris tabel hanya ada di memori runtime (tidak bisa dibaca dari statik). Konsekuensi: memaksa combo = 5 memberi skor baris tertinggi tiap kali objek ditemukan — tetapi angka pastinya harus diukur di runtime.

---

## 3. Method-method `StageTopBarCombo` (non-virtual) — TERBUKTI

Semua alamat virtual relatif terhadap base load `libcriminalcase.so`. `this` di `x0` (ARM64 AAPCS).

| Alamat | Nama kerja | Peran & bukti |
|---|---|---|
| `0xa7d670` | ctor | Set vptr `0x12009a8`; init `+0x120 = 0`, `+0x148/+0x150/+0x158` di-0-kan; panggil `0xa7d744` (init lanjutan). |
| `0xa7d744` | init lanjutan | Panggil `0xa7d9c0` (background) + `0xa7dbe8` (slot). |
| `0xa7d9c0` | build background | Buat sprite `top_box_bevel` (0x38f2b1), `top_combo_bg` (0x39fb06), `top_bg_reflect` (0x3b3b61) → `+0x160/+0x158/+0x168`; `addChild` via virtual [vptr+0x190]. |
| `0xa7dbe8` | build 5 slot | Buat array `+0x180`; loop 5×: `0xa7a3f8` (ctor `ComboItem`, arg w1 = indeks 1..5) → set posisi via virtual [vptr+0x98]/[vptr+0x238] → `addObject` ke array. |
| `0xa7d844` | `~StageTopBarCombo` (virtual #0) | Set vptr ke header+16, bebaskan array `+0x180` (iterasi + panggil `0xa7a384` per elemen), panggil dtor base `0xae7ee0`. |
| `0xa7d94c` | deleting dtor (virtual #1) | Panggil `0xa7d844`, lalu `operator delete(this, 0x188)`. |
| `0xa7d974` | `operator new` + ctor wrapper | `new(0x188)` → `0xa7d670` → `0xaed9f0` (autorelease). Satu-satunya pemanggil: `0xa79074` (di dalam init `StageTopBar`). |
| **`0xa7ddec`** | **increment / update combo** | **Lihat §3.1.** |
| **`0xa7dd60`** | **refresh + clamp** | **Lihat §3.2.** |
| **`0xa7e12c`** | **decrement** | `combo = combo − 1`, lalu update slot yang indeksnya == combo baru (cek `0xa7a558`/`0xa7a948` → `0xa7a560`). Hanya dipanggil dari cabang `combo == 6` di `0xa7ddec` — dalam alur normal tidak tercapai (combo di-cap 5), jadi praktis mati/defensif. **Jangan hook ini.** |
| **`0xa7e1e0`** | **RESET** | **Lihat §3.3 — target hook utama.** |
| `0xa7e264` | animasi skor | Loop `w22 = 0, 200, …, 1200` (step `0xc8`), panggil `0xae11c0/0xae2d34/0xae1d50/0xae930c` — animasi angka skor berjalan. Dipanggil via thunk TopBar `0xa79d94`. |
| `0xa7e2f0` | booster ON (?) | Set `[Combo+0x150] = 1`; cari slot aktif via `0xa7e0b0` → `0xa7a7ec(slot)`. |
| `0xa7e330` | booster OFF (?) | Set `[Combo+0x150] = 0`; cari slot aktif → `0xa7a844` lalu `0xa7a560`. |
| `0xa7e36c` | booster ON (varian) | Set `[Combo+0x150] = 1`, loop slot (detail belum dibaca penuh). |
| `0xa7e0b0` | cari slot aktif | Kembalikan slot pertama yang `0xa7a940(slot)` bit0-nya set; 0 bila tidak ada. |
| `0xa7e40c` | `getCombo()` | `ldr w0, [x0, #0x120]; ret` — dipakai screen saat menghitung skor find (`0x92907c` via thunk TopBar `0xa7a0ec`). |
| `0xa7e09c` | increment (varian) | Thunk kecil ke `0xa7ddec` dengan `(w1=1, w2=0, w3=(x2 != 0))` — pintu masuk increment kedua (pemanggilnya belum dilacak; tidak kritikal). |

### 3.1 `0xa7ddec` — increment (this=x0, w1, w2, w3)

```asm
a7de14: ldr  w8, [x0, #0x120]     ; combo
a7de18: cmp  w8, #5
a7de1c: b.ls 0xa7de4c              ; combo < 5 -> lanjut; >= 5 -> return langsung
a7de58: tbz  w2, #0, 0xa7de60      ; w2 bit0 == 0 -> jalur naik
a7de5c: cbnz w8, 0xa7df38          ; w2 != 0 dan combo != 0 -> lompat ke ekor popup
a7de60: ...                        ; JALUR NAIK:
a7de64: add  w8, w8, #1
a7de68: str  w8, [x21, #0x120]    ; combo++
        ; loop semua slot di +0x180: indeks slot via virtual [vptr+0x230];
        ;  bila indeks == combo      -> 0xa7a940, bila 0 -> 0xa7a5c8(slot, w1 = w20 ? 0xc8 : 0)
        ;  bila indeks == combo - 1  -> 0xa7a558, bila 0 -> 0xa7a6c4(slot, 1) (nyalakan glow)
        ;  bila combo == 6           -> bl 0xa7e12c (decrement; praktis tidak tercapai)
a7df38: ; EKOR POPUP:
a7df38: cmp  w8, #5
a7df3c: cset w9, hi
a7df40: and  w9, w20, w9           ; w20 = arg w1
a7df44: tbnz w9, #0, 0xa7de20      ; w1 && combo > 5 -> return
a7df48: tbz  w19, #0, 0xa7de20     ; w19 = arg w3; w3 == 0 -> return
a7df4c: cmp  w8, #5
a7df50: mov  w9, #5
a7df54: csel w9, w8, w9, lt       ; w9 = min(combo, 5)
a7df5c: add  w0, w9, #1
a7df60: bl   to_string(int)        ; "1".."6"
a7df64: adrp x2, 0x382000
a7df68: add  x2, x2, #0xbc1        ; "ho/ho_bonus" (11 char)
a7df78: bl   std::string::insert   ; -> "ho/ho_bonus<N>"
        ; ... buat sprite popup dari nama itu (skala 0.6, via 0x7d1f10) ...
```

### 3.2 `0xa7dd60` — refresh + clamp (this=x0, w1)

```asm
a7dd74: tbz  w1, #0, 0xa7dd8c      ; w1 bit0 == 0 -> lewati clamp
a7dd78: ldr  w8, [x19, #0x120]
a7dd7c: cmp  w8, #6
a7dd80: b.lo 0xa7dd8c              ; combo < 6 -> lewati
a7dd84: mov  w8, #5
a7dd88: str  w8, [x19, #0x120]    ; combo >= 6 -> paksa 5
a7dd8c: ; loop semua slot di +0x180:
a7ddc0: ldrb w8, [x19, #0x150]    ; flag booster
a7ddc4: ldr  w1, [x19, #0x120]    ; combo
a7ddc8: bic  w2, w22(#1), w8      ; w2 = 1 & ~flag150
a7ddcc: bl   0xa7a4e8              ; ComboItem::refresh(slot, combo, w2)
```

### 3.3 `0xa7e1e0` — RESET (this=x0) ★ target hook utama

```asm
a7e1f0: ldr  x8, [x0, #0x180]      ; array slot
a7e1f4: mov  x19, x0
        ; loop semua slot:
a7e22c: ldr  x8, [x8, #0x230]      ; virtual -> indeks slot
a7e230: blr  x8
a7e234: ldr  w8, [x19, #0x120]    ; combo
a7e238: cmp  w0, w8
a7e23c: b.hi 0xa7e248              ; indeks slot > combo -> lewati
a7e240: mov  x0, x20
a7e244: bl   0xa7a698              ; ComboItem::glowOff(slot) utk slot yg menyala
a7e250: str  wzr, [x19, #0x120]   ; ★ combo = 0
a7e254: ... ret
```

Urutan penting: glow dimatikan dulu berdasarkan combo lama, **baru** combo di-0-kan di akhir. Fungsi ini murni UI + reset counter — tidak menyentuh skor total dan tidak menampilkan hint sendiri.

---

## 4. `StageTopBarComboItem` / slot — method terkait glow

`ComboItem` = satu slot (indeks 1..5; indeks via virtual [vptr+0x230], yaitu virtual CCNode ke-70). Field slot: byte `+0x138` (glow aktif?), byte `+0x139`, byte `+0x13b` (sudah diproses?), int `+0x120`/`+0x124`/`+0x128`/`+0x134`, ptr `+0x140`/`+0x148` (sprite + glow).

| Alamat | Peran |
|---|---|
| `0xa7a4e8` | `refresh(slot, combo=w1, flag=w2)`: bila `[slot+0x13b]` sudah set → return; set `[slot+0x13b]=1`; bila indeks slot != combo → return; bila w2==0 → return; bila `[slot+0x138]==0` → return; bila lolos semua → `0xa7a560(slot)` (nyalakan glow). |
| `0xa7a560` | Glow ON + animasi: `[slot+0x139..0x13a] = 0x0101`, `[slot+0x13b] = 1`, panggil `0xa7c518`, jalankan action via `0xae9440`/`0xa7b5ec`. |
| `0xa7a6c4` | Glow ON berparameter: `[slot+0x138..0x139] = 0x0101`, skala glow 100.0f (`0x42c80000`), `0xa7bc78(slot, w1)`. |
| `0xa7a698` | Glow OFF: panggil `0xa7c550` lalu `0xa7b798` pada sprite `[slot+0x148]`. Dipakai reset (`0xa7e1e0`) dan refresh. |
| `0xa7a5c8` | Set `[slot+0x128] = w1` (dipakai increment saat indeks slot == combo, w1 = 0 atau 0xc8=200). |
| `0xa7a558` / `0xa7a940` / `0xa7a948` | Getter byte: `[slot+0x138]` / `[slot+0x139]` / `[slot+0x13b]`. |
| `0xa7a900` | Override virtual CCNode indeks 21 (di vtable Item): meneruskan virtual [vptr+0x98] ke dua child `[this+0x148]`/`[this+0x140]` — kemungkinan `setColor`/propagasi state visual. Bukan logika combo. |
| `0xa7a474` | Virtual tambahan Item [105]: membaca `[this+0x120]` (int), `[+0x12c]`/`[+0x12e]`, menulis hasil ke `[this+0x148]`/`[+0x140]` — kemungkinan `update`/sinkronisasi tampilan item. Bukan logika combo. |

---

## 5. `StageTopBar` — thunk penghubung (Combo\* di TopBar+0x148)

`StageTopBar` (sizeof `0x158`) memegang `StageTopBarCombo*` di **+0x148**. Method-method kecilnya hanya meneruskan ke Combo (tail-call `b`):

| Alamat | Terusan ke Combo | Dipakai untuk |
|---|---|---|
| `0xa79d60` | `0xa7e2f0` (flag150=1 + glow slot aktif) | booster ON |
| `0xa79d68` | `0xa7e36c` (flag150=1, loop slot) | booster ON (varian) |
| `0xa79d70` | `0xa7e330` (flag150=0) | booster OFF |
| `0xa79d78` | `0xa7ddec` dengan `(w1=0, w2=arg w1, w3=1)` | **increment combo** |
| `0xa79d8c` | `0xa7e1e0` | **reset combo** ★ |
| `0xa79d94` | `0xa7e264` (animasi skor) | animasi angka skor |
| `0xa79d9c` | `0xa7dd60` dengan `(w1=arg w1 & 1)`, tapi sebelumnya: bila byte `[TopBar+0x120]` sudah set → return; bila belum → set `[TopBar+0x120]=1` dulu | refresh + clamp (sekali per "episode"; byte `TopBar+0x120` adalah flag milik TopBar, **bukan** field combo) |
| `0xa79dc0` | — (getter byte `[TopBar+0x120]`) | cek flag TopBar |
| `0xa79dc8` | `setScoreText(string)` — tulis string skor ke `[TopBar+0x124]` dst. | update label skor |
| `0xa7a0ec` | `0xa7e40c` (`getCombo()`) | baca combo untuk hitung skor |

TopBar dibuat di `0x93db00` (dipanggil dari `0x93d850`): `ldr x0, [x0, #0x188]; bl TopBar::new (0xa79d0c); str x0, [x19, #0x1e0]` — objek screen menyimpan `StageTopBar*` di **+0x1e0**, skor total di **+0x1a8**.

---

## 6. Siapa yang memanggil increment / reset — jalur screen

`this` di semua situs di bawah adalah objek screen (keluarga `HOScreen`/`StageScreen` — penamaan kelas pastinya butuh cek vptr runtime, lihat §8; perilakunya sudah jelas dari kodenya). Screen memegang `StageTopBar*` di `+0x1e0`.

### 6.1 INCREMENT — saat objek ditemukan (3 situs, via thunk `0xa79d78`)

**Situs 1 — `0x929110`** (di handler "item ditemukan", sekitar `0x929078`):

```asm
929078: ldr x0, [x19, #0x1e0]     ; StageTopBar*
92907c: bl  0xa7a0ec                ; w24 = TopBar::getCombo()  (= combo saat ini)
929084: mov x0, x25                ; x25 = HOItem yg ditemukan
929088: mov w1, w24
92908c: mov w2, wzr
929090: bl  0xaa243c                ; w0 = skor = tabel[combo]   (§2)
929094: ldr w8, [x19, #0x1a8]      ; skor total
9290a0: add w8, w8, w0
9290a8: str w8, [x19, #0x1a8]      ; skor total += skor find
9290b8: mov w2, w25 / mov w3, w24 / mov w4, #1
9290c4: bl  0x9280ac                ; spawn HOFXScore (efek skor melayang)
9290c8: ldr w0, [x19, #0x1a8]
9290d4: bl  to_string(skor total)
9290e0: bl  0xa79dc8                ; TopBar::setScoreText(...)
9290fc: ldr w8, [x19, #0x260]      ; item ditemukan (counter)
929100: ldr w9, [x19, #0x258]      ; item total misi
929104: ldr x0, [x19, #0x1e0]
929108: cmp w8, w9
92910c: cset w1, eq                ; w1 = (semua item ketemu) ? 1 : 0
929110: bl  0xa79d78                ; TopBar::incrementCombo(w1) -> Combo::increment(0, w1, 1)
```

Urutan penting: **skor find dihitung dulu dengan combo LAMA, baru combo naik**. Jadi find pertama (combo 0) memakai baris tabel 0, find kedua baris 1, dst.

**Situs 2 — `0x92ecdc`** (jalur find kedua, sekitar `0x92ecb8`):

```asm
92ecb8: ldr w8, [x19, #0x264]      ; counter (?)
92ecbc: ldr w9, [x19, #0x3b8]
92ecc4: str wzr, [x19, #0x274]
92ecc8: add w8, w8, #1
92eccc: str wzr, [x19, #0x364]
92ecd0: cmp w8, w9
92ecd4: str w8, [x19, #0x264]
92ecd8: cset w1, eq
92ecdc: bl  0xa79d78                ; incrementCombo(w1 = counter == batas)
```

**Situs 3 — `0x938638`**: situs ketiga thunk yang sama (konteks tidak dibaca detail — pola yang sama, kemungkinan mode/minigame lain).

### 6.2 RESET — saat salah ketuk (1 situs, via thunk `0xa79d8c`) ★

**Situs tunggal — `0x92e824`** (di handler tap, sekitar `0x92e6e0`–`0x92e820`):

```asm
92e6ec: str xzr, [x19, #0x398]     ; bersih-bersih state tap
92e73c: ldr x0, [x19, #0x388]      ; objek tap sementara -> release, str xzr
92e748: ldr x0, [x19, #0x390]      ; -> release, str xzr
92e738: cbz x20, 0x92e820           ; x20 == 0 (tidak ada item yg kena tap) -> ke 0x92e820
...
92e820: ldr x0, [x19, #0x1e0]      ; StageTopBar*
92e824: bl  0xa79d8c                ; TopBar::resetCombo() -> Combo::reset() (combo = 0)
92e828: bl  0x8298a4
92e82c: bl  0x8309d8                ; return bool; dipakai utk percabangan berikut
        ; (0x8298a4/0x8309d8 belum diidentifikasi — kemungkinan cek penalti/hint;
        ;  bukan bagian dari reset combo itu sendiri)
```

Tidak ada pemanggil reset lain di seluruh `.text` (grep `bl 0xa79d8c` = 1 hasil). Tidak ada penulis `0` ke `Combo+0x120` selain ctor dan `0xa7e250` di dalam reset itu sendiri. **Jadi satu-satunya jalur reset combo adalah salah ketuk → `0x92e824` → `0xa79d8c` → `0xa7e1e0`.** Tidak ada reset berbasis timer (update per-frame di `0x928994` hanya memanggil *refresh* `0xa79d9c` bila akumulasi dt ≥ 1.3 dtk — konstanta double di `0x335b90` — dan tidak menyentuh `+0x120`).

### 6.3 REFRESH — 6 situs (via thunk `0xa79d9c`)

`0x9289ec` (update per-frame, lihat §6.2 akhir), `0x92965c`, `0x92b114`, `0x92ec38`, `0x93640c`, `0x9388c8`. Konteks masing-masing tidak dibaca detail; semuanya memanggil pola yang sama (clamp + sinkronisasi glow slot).

### 6.4 String hint `MsgHintCombo*` — BUKAN dari kode Combo

String `MsgHintCombo1/2/3` (`0x3c47e1/0x3c47f9/0x3c4811`) dan `MsgHintHiCombo1/2/3` (`0x3c4829/0x3c4841/0x3c4859`) direferensikan dari kode screen di wilayah `0x7fxxxx`–`0x9xxxxx` (mis. `0x7fb85c`, `0x7fbf88`, `0x802698`, `0x803750`, `0x8b36d8`, `0x8cbf0c`, `0x9447f8`), **bukan** dari fungsi-fungsi Combo di `0xa7dxxx`–`0xa7e4xx`. Artinya hint combo ditampilkan oleh kode screen, bukan oleh fungsi reset/increment. Hook reset tidak akan menghilangkan hint (hanya kosmetik).

---

## 7. RENCANA HOOK KONKRET (untuk injector root)

Semua alamat virtual (tambah base load `libcriminalcase.so` di runtime).

### Opsi A (disarankan) — 2 hook fungsi, pengali terkunci x6

| # | Hook | Alamat | Signature (tebakan dari disassembly) | Yang dilakukan hook |
|---|---|---|---|---|
| A1 | `Combo::reset` | **`0xa7e1e0`** | `void (StageTopBarCombo* this)` — `this` di `x0` | **Return langsung tanpa memanggil original** (no-op). Efek: salah ketuk tidak pernah me-reset combo. Keyakinan mekanisme: **TINGGI** (satu-satunya penulis 0 ke field; satu-satunya caller adalah handler miss). |
| A2 | `Combo::increment` | **`0xa7ddec`** | `void (StageTopBarCombo* this, int w1, int w2, int w3)` — `this` x0, arg w1–w3 | **Di awal hook: bila `[x0 + 0x120] < 4`, tulis `4` ke `[x0 + 0x120]`, lalu panggil original.** Original kemudian `combo++` → 5, update glow semua slot, dan tampilkan popup `ho/ho_bonus6`. Efek: **setiap** objek ditemukan → combo langsung 5 (x6), tidak peduli riwayat sebelumnya. Keyakinan: **TINGGI** (cap 5 + `combo++` + popup `min(combo,5)+1` semuanya terbaca langsung). Alternatif yang setara: hook A2 saja tanpa A1 sudah cukup untuk skor (tiap find me-reset combo ke 5), tapi tanpa A1, miss di antara dua find tetap me-0-kan combo — tampilan slot akan padam sesaat. Pakai keduanya untuk perilaku yang bersih. |

Catatan implementasi:
- Hook A2 harus **memanggil original** (bukan no-op), karena original-lah yang menyalakan glow slot + menampilkan popup. Menulis `5` langsung ke field tanpa memanggil original akan membuat skor x6 tapi UI slot tidak menyala (sinkronisasi visual tertinggal) — kecuali hook juga memanggil `refresh 0xa7dd60(this, 1)` setelah menulis.
- Jangan hook `0xa7e12c` (decrement) — jalurnya praktis mati.
- Jangan hook via vtable Combo — tidak ada entri virtual untuk increment/reset (hanya dtor). Pakai inline hook di alamat fungsi.
- Instance Combo berganti tiap scene (dibuat baru saat stage dimuat); hook level-fungsi berlaku untuk semua instance — tidak perlu mencari instance untuk A1/A2.

### Opsi B — 1 hook getter (skor maksimal tanpa mengubah UI combo)

- Hook **`Combo::getCombo` `0xa7e40c`** (`int (StageTopBarCombo* this)`, `this` x0) → **return 5 selalu, tanpa memanggil original**. Efek: tiap find dihitung dengan baris tabel 5 (skor maksimal), walau combo tersimpan tetap naik normal 0→5 dan bisa di-reset miss. Cocok bila tujuannya hanya skor, bukan tampilan x6 permanen. Keyakinan: **SEDANG–TINGGI** (getter dipakai di jalur skor `0x92907c`; belum dipetakan semua pemanggil getter — bila ada pemanggil lain yang mengandalkannya, perilaku ikut berubah; perlu cek runtime).
- Opsi B bisa dikombinasikan dengan A1 bila mau skor maksimal + combo tidak pernah reset.

### Opsi C — tulis memori berkala (tanpa hook kode; fallback)

- Cari instance Combo di heap: scan memori untuk pointer == `base + 0x12009a8` (**vptr hidup**, bukan header `0x1200998` — lihat §1.3). Atau telusuri scene graph dari director (`CCDirector::m_pRunningScene` +112, ESP-RESEARCH §3.2) → children (`CCNode +176`) → node yang vptr-nya `base + 0x12009a8` (atau TopBar `base + 0x11ff560`, lalu Combo = `[TopBar + 0x148]`).
- Tulis `5` (int32) ke `[Combo + 0x120]` tiap interval / tiap frame render. Keyakinan: **SEDANG** (field terbukti; kelemahannya instance berganti tiap scene dan penulisan berkala rawan balapan dengan reset — kalah cepat dari reset miss bila interval longgar; dan tetap menulis memori game, jadi dari sisi PairIP tidak lebih aman dari hook).
- Opsi C TIDAK disarankan sebagai utama — A1+A2 lebih deterministik.

### Yang TIDAK perlu dilakukan

- Tidak perlu mem-patch instruksi di `.text` (tidak ada satu instruksi tunggal yang "menentukan" combo — state-nya field, dan reset/increment adalah fungsi utuh).
- Tidak perlu menyentuh `MsgHintCombo*` / hint (kosmetik, ditampilkan screen).
- Tidak perlu menyentuh tabel skor `0xaa243c` (cukup pakai baris 5 lewat combo=5).

---

## 8. Verifikasi runtime yang masih diperlukan (POCO, root)

1. **Base + vptr Combo.** Buka game sampai crime scene tampil; `base = grep libcriminalcase.so /proc/<pid>/maps`. Heap-scan / telusur scene graph → objek dengan vptr `base + 0x12009a8`; cek `[vptr−16] == 0`, `[vptr−8] == base + 0x1200ce0`. Ini sekaligus memvalidasi koreksi §1.3 dan alamat header ESP (bila vptr yang ditemukan `base + 0x12009a8`, koreksi benar).
2. **Field +0x120.** Baca int32 di `[Combo + 0x120]`: harus 0 saat scene baru dimuat; naik +1 tiap objek benar ditemukan (maks 5); kembali 0 saat salah ketuk. Bila tidak cocok, field salah — laporkan nilai yang terlihat.
3. **Slot array.** Baca `[Combo + 0x180]` → `ccArray` → 5 pointer slot; tiap slot vptr-nya harus `base + 0x11ff8c0` (Item, vptr hidup) — konfirmasi rantai Combo→slot.
4. **Hook A1.** Pasang no-op di `base + 0xa7e1e0`; salah ketuk → `[Combo+0x120]` harus tetap (tidak 0), glow slot tetap menyala.
5. **Hook A2.** Pasang "tulis 4 lalu original" di `base + 0xa7ddec`; tiap find → combo langsung 5, popup `ho/ho_bonus6` muncul, skor find memakai baris tabel 5 (bandingkan skor per find sebelum/sesudah).
6. **Tabel skor.** Saat combo=5, baca skor per find dan bandingkan dengan combo=0 (baris 0) — ukur faktor/angka tiap baris; dan cek apakah skor total `[screen + 0x1a8]` bertambah sesuai (screen = objek yang memegang TopBar di +0x1e0).
7. **Penamaan screen.** Cek vptr objek screen pemanggil (yang memegang TopBar di +0x1e0) terhadap kandidat vtable `HOScreen` (`0x11bafb0` header / `0x11bafc0` vptr hidup — ESP) dan `StageScreen` (`0x11bc108` header per derivasi ulang ini / `0x11bc118` vptr hidup — ESP menulis `0x11bc100`, selisih 1 slot, perlu dipastikan) — untuk memberi nama pasti pada handler find/miss di §6.
8. **Toleransi PairIP.** Amati selama probing/hook: crash / freeze / popup aneh / skor tidak tersimpan. Seperti ESP-RESEARCH §2.5: tidak ada bukti PairIP mendeteksi hook, tapi internals opak — uji empiris, mainkan 1 scene penuh setelah hook aktif, dan jangan login Facebook selama pengujian (hindari sync skor).

---

## 9. Tingkat keyakinan per klaim

| Klaim | Keyakinan | Bukti |
|---|---|---|
| Vtable header Combo `0x1200998`, typeinfo `0x1200ce0`, base CCNode | Tinggi | Kandidat tunggal tiap langkah + struktur `__si_class_type_info` lengkap via readelf |
| vptr hidup = header+16 (`0x12009a8`) | Tinggi | Ctor `0xa7d670` + semua dtor menyimpan nilai itu ke `[this]` |
| sizeof Combo `0x188` | Tinggi | Deleting dtor `0xa7d94c` (`operator delete`, size `0x188`) |
| Field combo = int32 di `+0x120`, 0..5 | Tinggi | 6 fungsi independen membaca/menulis offset yang sama dengan semantik konsisten (init 0, +1 cap 5, clamp 5, −1, reset 0, getter) |
| Pengali tampil = combo+1 (x1..x6), 5 slot | Tinggi | Popup `ho/ho_bonus<min(combo,5)+1>` + loop pembuat 5 slot indeks 1..5 |
| Reset = `0xa7e1e0`, satu-satunya jalur reset, dipicu salah ketuk (`0x92e824`) | Tinggi | Satu-satunya `bl` ke thunk reset di seluruh `.text`; satu-satunya penulis 0 ke field selain ctor |
| Increment = `0xa7ddec`, dipanggil tiap find | Tinggi | 3 situs `bl` ke thunk increment; situs 1 terdokumentasi lengkap (skor → FX → label → increment) |
| Skor = lookup tabel `tabel[combo]`, bukan perkalian | Tinggi | `0xaa243c`: bounds-check + `ldr w0, [elem, #0x18]`; tidak ada instruksi `mul` pada combo di jalur itu |
| Tidak ada reset berbasis timer | Sedang | Update per-frame hanya memanggil refresh, bukan reset; tetapi tidak semua situs refresh dibaca detail — kemungkinan kecil ada jalur reset lain yang belum terlihat |
| Handler find/miss adalah method `HOScreen`/`StageScreen` | Sedang | Perilaku + layout field konsisten (TopBar +0x1e0, skor +0x1a8); nama kelas pastinya belum dibuktikan (butuh cek vptr runtime, §8.7) |
| Decrement `0xa7e12c` praktis tidak pernah jalan | Sedang | Hanya dipanggil dari cabang `combo == 6` yang tidak tercapai karena cap 5; tetapi ada kemungkinan jalur lain menulis 6 ke field (tidak ditemukan penulis 6) |
| Flag `+0x150` = mode booster | Rendah–Sedang | Diset/di-clear oleh 3 fungsi yang dipanggil via thunk TopBar dari banyak situs; nama "booster" dari string `booster_combo` di dekatnya, belum dibuktikan kaitan langsungnya |

## 10. Yang dicoba tapi TIDAK membuahkan hasil / masih buntu (jujur)

- **Tidak ada string literal "multiplier"** di dump (sesuai dugaan awal) — nilai combo memang int mentah, bukan string/nama field.
- **Vtable tidak membantu untuk logika combo** — hanya 2 dtor yang khusus Combo; semua logika ada di method non-virtual yang harus ditemukan lewat xref ctor/thunk/call-site, bukan lewat vtable.
- **Nilai tiap baris tabel skor tidak ditemukan statik** — tabelnya dibangun di runtime dari data item (JSON terenkripsi); hanya rumus aksesnya (`tabel[combo]`) yang terbukti.
- **Fungsi `0x8298a4` / `0x8309d8`** (dipanggil tepat setelah reset di `0x92e824`) belum diidentifikasi — kemungkinan logika penalti/hint pasca-miss; tidak memengaruhi rencana hook reset.
- **Situs increment ke-3 (`0x938638`) dan 5 dari 6 situs refresh** tidak dibaca detail — pola thunk-nya sama, tetapi konteks mode-nya (minigame/time-attack?) belum dipetakan.
- **Kaitan `booster_combo` ↔ flag `+0x150`** belum dibuktikan (string-nya direferensikan dari `0x966038` dan wilayah `0xedbxxx`, belum ditelusuri).
