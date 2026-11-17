# REA — "Speed Instan Tanpa Jengat" + Pengali Torsi (SeekBar) — Hill Climb Racing 1

**Target:** HCR 1 v1.72.2, `libgame.so` arm64 stripped (`~/workspace/hcrx-1.72.2/`, 8.883.448 B);
cadangan 1.71.1 (`~/workspace/hcrx/`, 8.812.296 B).
**Status:** riset statis SAJA — TIDAK ada implementasi, TIDAK menyentuh `~/workspace/hozin-hcr-mod/`.
**Konteks rilis:** god mode v4 sudah RILIS sebagai v1.7 (code 10) 17 Nov 17:29 — fitur ini target **v1.8**.
**Tanggal:** 17 Nov 2026.

Ringkasan eksekutif: kecepatan kendaraan hidup di **linear velocity body chassis
`[body+0x50]`/`[body+0x54]`**, putaran chassis di **angular velocity `[body+0x58]`**,
dan torsi mesin di **maxMotorTorque joint roda (`[joint+0xb8]`)** yang di-set tiap frame
dari stat mesin `[car+0x760]` (Jeep: **23,0 × 1,046^(level−1)**). Motor roda BUKAN
torsi mentah ke body — melainkan **joint motor Box2D** (`SetMotorSpeed` + `SetMaxMotorTorque`).
Jengat = reaksi torsi motor yang memutar chassis ke belakang. Karena itu jawaban yang
benar BUKAN "torsi lebih besar", melainkan **set linear velocity langsung ke target +
tahan angular velocity ≈ 0**, dan pengali torsi dipasang sebagai **hook di
`SetMaxMotorTorque` (0x6ced10)** yang WAJIB jalan bareng penahan putaran.

---

## 1. Layout struct body (chassis / roda) — TERKONFIRMASI

Objek body = class `PhysicsSprite` (vtable `0x832cd8`, 121+ slot; dibuat via `0x6d1ea4`).
Chassis = `[car+0x2d8]`; kandidat kepala = `[car+0x2d0]`; body roda = `[car+0x788]`/`[car+0x790]`.
Rantai jangkar (dari PROBE.md): `run+0x3a8` → vehicle → `+0x258` → car → `+0x2d8` → chassis body.

| Offset | Isi | Bukti |
|---|---|---|
| `+0x0c` / `+0x10` | posisi (x, y) | getter slot `0x70` (`0x4f4b30`): `ldp s0,s1,[body+0xc]`; dipakai flip `0x3ae7a8`, stuck check, `0x505394` |
| `+0x2c` / `+0x30` | **local center** (pusat massa lokal), BUKAN velocity | `0x4f9880` membangun `b2MassData` {massa, center, I}: `I = [0xa0]·(s1²+s2²) + [0xa8]` (teorema sumbu sejajar) lalu `bl 0x6cf5b0` (= `SetMassData`) |
| `+0x48` | **sudut (radian) — kandidat kuat, BUTUH probe runtime** | fungsi copy/init `0x6cef80`: `[dst+0x48] ← [def+0x0c]` (sudut dari def) dan `[dst+0x4c] = 0`; getter berdekatan `0x67d9c0`/`0x67d9c8`; dipakai helper transform titik `0x67d9d0`/`0x67da50`/`0x67dadc` |
| `+0x4c` | komponen rotasi pendamping (kemungkinan cos, atau 0 saat init) | lihat baris di atas |
| `+0x50` / `+0x54` | **linear velocity (vx, vy)** — PASTI | (a) stuck check `0x5053b8`: `ldp s0,s1,[chassis+0x50]` → `sqrt(s0²+s1²) < 1,0` → timer mati; (b) cluster accessor: slot `0x80` = `0x67d88c` (`ldr s0,[x0,#0x50]`), setter `0x67d894`/`0x67d8ac` menulis `[body+0x50]`/`[body+0x54]` + menandai `[body+0x150] \|= 0x101` (flag dirty/awake); (c) solver `0x6d9f40`: velocity di-update `v += impuls × [body+0xa4]` (= invMass) lalu `str d6,[x10,#0x50]`; (d) fungsi debu roda `0x4f0c88` menghitung signed speed dari pasangan ini |
| `+0x58` | **angular velocity ω (rad/s)** — PASTI | solver `0x6d9f64–0x6d9f7c`: `s3 = [body+0x58] + [body+0xac]·(cross)` lalu `str s3,[x10,#0x58]` — persis `ω += invI × impuls`; fungsi debu: rim speed = `[wheelbody+0x58] × [car+0x774]` (radius); copy/init: `[dst+0x58] ← [def+0x18]` (angularVelocity dari def) |
| `+0xa0` | massa | KE calc `0x4f9878`: `s0 = [body+0xa0]` dipakai `massa·|v|²` |
| `+0xa4` | invMass (1/massa) | solver: `v += impuls × [body+0xa4]` |
| `+0xa8` | momen inersia I | KE calc: suku tambahan `+ [body+0xa8]` (= I·ω²) |
| `+0xac` | invI (1/I) | solver: `ω += [body+0xac] × (cross)` |
| `+0x150` | flag dirty/awake (bit) | setter velocity menulis `strh 0x101` ke sini |
| `+0x04` | flags (bit 1 = awake) | setter motor: `[body+4] \|= 2` + `[body+0xd8] = 0` (bangunkan body) |
| `+0xd8` | sleep timer | di-nol-kan saat body dibangunkan |

### 1a. KOREKSI terhadap riset sebelumnya
- **PROBE.md ("getter sudut" slot `0x70`) SALAH.** Slot `0x70` vtable PlayerCar
  (`0x4f4b30`) mengembalikan **POSISI** (`ldp s0,s1,[body+0xc]`), bukan sudut.
  Arg 0 → posisi chassis; arg 1 → posisi kandidat kepala (via vtable+`0x3b8`).
  Sumber sudut yang benar adalah `[body+0x48]` (lihat tabel) atau `atan2f` atas
  vektor arah (dipakai di `0x3d1c80`: `bl atan2f` lalu `× −57,29578` → derajat).
- **`[body+0x2c]` BUKAN velocity.** Itu local center; rumus di `0x4f9880` adalah
  `SetMassData`, bukan energi kinetik.
- **Laporan death (`[run+0x624]` = "resource ke-2 / udara") SALAH.** `[run+0x624]`
  di 1.72.2 adalah **FUEL**: dikuras di `0x3c9470–0x3c94b0` dengan
  `fuel -= dt × 2,5 × throttle × [car+0x718]` (throttle dari slot vtable `0x158`),
  peringatan low-fuel di 15,0, lalu countdown 4 detik → game over (`0x3b7c70`).
  (Di 1.71.1 fuel ada di `[run+0x60c]`; struct bergeser +0x18 di 1.72.2.)

---

## 2. Di mana throttle & motor diterapkan

### 2.1 Throttle
- Getter throttle = **slot vtable `0x158`** pada objek car, mengembalikan float 0..1.
  Dipakai di fuel drain (`0x3c9484`), suara mesin (`0x4de760`/`0x4de6f8`), dan
  perhitungan motor.
- Nilai throttle yang dihaluskan (lerp 3/detik atau 6/detik) disimpan di
  **`[car+0x318]`** (update Jeep `0x53bba4`, BadCar `0x50525c`).

### 2.2 Motor roda = joint motor Box2D (BUKAN torsi ke body)
Roda digerakkan oleh **joint motor** pada dua joint roda:
- Joint roda: **`[car+0x7b0]`** dan **`[car+0x7b8]`** (depan/belakang — urutan
  mana-depan vs mana-belakang BELUM terkonfirmasi, butuh probe).
- Layout struct joint: `bodyA +0x60`, `bodyB +0x68`, **`motorSpeed +0xb4`**,
  **`maxMotorTorque +0xb8`**, impuls motor `+0x98`/`+0xac`, flag enable `+0xc4`/`+0xc5`.

Dua setter (keduanya membangunkan kedua body: `[body+4] |= 2`, `[body+0xd8] = 0`):

| Fungsi | Alamat 1.72.2 | Alamat 1.71.1 | Perilaku |
|---|---|---|---|
| `SetMotorSpeed(joint, speed)` | **`0x6ced48`** | `0x6be3a4` | `str s0,[joint,#0xb4]` |
| `SetMaxMotorTorque(joint, torque)` | **`0x6ced10`** | `0x6be36c` | `str s0,[joint,#0xb8]` |

Pola byte (56 byte, **UNIK — tepat 1 kemunculan di tiap binary**):
- `SetMaxMotorTorque`: `083040f9090940798900083729011f32090900791fd900b9083440f9090940798900083729011f32090900791fd900b900b800bdc0035fd6`
- `SetMotorSpeed`: `083040f9090940798900083729011f32090900791fd900b9083440f9090940798900083729011f32090900791fd900b900b400bdc0035fd6`
- Keduanya hanya beda 1 byte (offset store `0xb8` vs `0xb4` di posisi byte ke-0x30).
  Prolog "bangunkan body" saja muncul 10× — pattern-scan HARUS memakai fungsi penuh
  56 byte, atau prolog + store spesifik. Ada pula combined setter
  (`stp s0,s1,[joint,#0xb4]` + clear impuls) di `0x6cb0c8`/`0x6cca64`
  dan getter `GetMotorSpeed` (`0x6cca54`) / `GetMaxMotorTorque` (`0x6cb0c0`).

### 2.3 Situs aplikasi per-frame (update Jeep `0x53bba4`, di `0x53c108–0x53c134`)
```asm
0x53c108: bl #0x6ced48        ; SetMotorSpeed(joint=[car+0x7b8], speed=hasil hitung)
0x53c10c: ldr s0, [x19, #0x760]
0x53c110: ldr x0, [x19, #0x7b8]
0x53c114: fneg s0, s0
0x53c118: bl #0x6ced10        ; SetMaxMotorTorque(joint=[car+0x7b8], torque=-[car+0x760])
0x53c11c: ldr x0, [x19, #0x7b0]
0x53c120: mov v0.16b, v8.16b
0x53c124: bl #0x6ced48        ; SetMotorSpeed(joint=[car+0x7b0], speed=v8)
0x53c128: ldr s0, [x19, #0x760]
0x53c12c: ldr x0, [x19, #0x7b0]
0x53c130: fneg s0, s0
0x53c134: bl #0x6ced10        ; SetMaxMotorTorque(joint=[car+0x7b0], torque=-[car+0x760])
```
Perhitungan motor speed (di `0x53c074–0x53c104`, disederhanakan):
`speed = (boost[0x410] + 0,5) × A[0x76c] × B[0x764] × clamp([car+0x760] − |ω_roda|, 0, 1) × (0,25 bila [car+0x3a0] > 0)`.
Perhatikan: **`[car+0x760]` dipakai DUA kali** — sebagai **batas kecepatan** roda
(`clamp(23 − |ω|, 0, 1)`: motor hanya mendorong bila roda di bawah ~23 rad/s)
DAN (dinegasi) sebagai **batas torsi**. Jadi satu stat mesin mengendalikan
top speed DAN akselerasi.

### 2.4 Stat mesin `[car+0x760]` (nilai torsi) — TERUKUR
Di-set sekali saat konstruksi kendaraan, dari level upgrade:
```
0x4f9484: ldr s1, [rodata+0xc5c]   ; s1 = 1,046  (pengali per level, float di 0x1fdc5c)
0x4f948c: fmov s0, #23.0           ; base Jeep
0x4f9494: subs w9, w9, #1
0x4f9498: fmul s0, s0, s1          ; loop: s0 = 23,0 × 1,046^(level−1)
0x4f94a8: str s0, [x19, #0x760]    ; [car+0x760] = torsi mesin
```
Nilai base (level 1) per kendaraan, dari `fmov s0,#X` sebelum masing-masing
`str s0,[x19,#0x760]`: **Jeep 23,0**; kendaraan lain **28,0 / 25,0 / 21,0 / 15,0 /
4,25** (sebagian kendaraan menghitungnya dari konstanta lain — tidak semua
berupa `fmov` di dekatnya). Rentang praktis:
- Level 1: **±4–28**
- Level ~20 (×1,046^19 ≈ ×2,37): **±10–66**

**Tanda:** nilai yang ditulis ke joint adalah **negatif** (`-[car+0x760]`).
Itu konvensi arah game (motor berputar ke arah negatif di koordinatnya), BUKAN
torsi negatif yang merusak — mobil tetap melaju maju. Pengali HARUS mengalikan
**magnitudo** (nilai absolut) dan mempertahankan tanda: `s0_baru = s0 × pengali`.

### 2.5 Yang BUKAN motor (koreksi hipotesis awal)
- Fungsi `0x4f0c88` **BUKAN fungsi drive** — itu pengendali **partikel debu/asap
  roda**: menghitung signed speed dari velocity body roda, lalu memanggil
  slot `0x498` (= `str s0,[x0,#0x2c0]`, emission rate) pada objek
  `[car+0x748]`/`[car+0x750]` dengan nilai **20/25/60/0** (partikel/detik,
  tergantung stage). Objek `[car+0x748]`/`[car+0x750]` adalah
  **`CCParticleSystemQuad`** (vtable `0x8656c0`, dibuat factory `0x69afd8`),
  bukan roda/motor. Nilai 20/25/60 JANGAN dipakai sebagai acuan torsi.
- Fungsi `0x4f6848` juga bukan motor — itu update **suspensi/damper**
  (`[obj+0x80] = f(kecepatan chassis)`), dipanggil dengan joint `[car+0x7b0]`/`[car+0x7b8]`.
- `[car+0x774]` = **radius roda** (dipakai `rim speed = ω_roda × radius` di
  fungsi debu); `[car+0x718]` = laju konsumsi fuel; `[car+0x76c]`/`[car+0x764]`
  = faktor perhitungan motor speed.

---

## 3. Mekanisme jengat (wheelie)

1. Tiap frame, game memanggil `SetMotorSpeed` + `SetMaxMotorTorque` pada kedua
   joint roda. Solver Box2D menghitung impuls motor =
   `motorMass × (motorSpeed − Δω)`, **dibatasi ±(maxMotorTorque × dt)**,
   lalu menerapkannya ke roda (dan — lewat joint — reaksi yang sama besar
   berlawanan arah ke chassis).
2. Torsi motor yang besar → impuls besar → roda berputar cepat, TETAPI reaksi
   pada chassis = momen yang memutar chassis **ke belakang** (depan naik).
   Inilah jengat: **bukan bug, melainkan fisika joint motor yang bekerja benar**.
   Secara matematis, laju pitch chassis ∝ `torsi_motor / I_chassis`
   (`I` = `[chassis+0xa8]`, `invI` = `[chassis+0xac]`).
3. Begitu `[chassis+0x58]` (angular velocity) positif besar, chassis berotasi
   ke belakang; tanpa traksi roda depan di udara, kendaraan jungkir balik.
4. Karena itu **menaikkan torsi saja (pengali mentah) PASTI memperparah jengat**
   dengan faktor yang sama — lihat §5.

---

## 4. Kandidat implementasi "Speed Instan tanpa jengat"

Semua kandidat memakai rantai yang sudah ada di mod: hook update `0x3bd1dc`
(`hook_update`, sudah ter-hook Dobby untuk slow-mo) sebagai titik injeksi per-frame,
dan rantai `run+0x3a8 → vehicle → +0x258 → car → +0x2d8 → chassis body`.

### Kandidat A — Set linear velocity langsung + tahan angular velocity ≈ 0 (DIREKOMENDASIKAN)
- **Cara:** tiap frame (di hook update, SESUDAH physics step agar tidak
  ditimpa solver — atau sebelum step agar solver yang mengintegrasikannya;
  pilih satu, uji di HP): tulis `[chassis+0x50] = vx_target`,
  `[chassis+0x54] = vy_target` (arah gerak dipertahankan dari velocity saat ini
  atau dari hadap kendaraan), dan `[chassis+0x58] = 0` (atau diklem ke
  ±kecil, mis. ±0,5 rad/s, supaya masih bisa sedikit miring di tanjakan).
  Target speed dari SeekBar/config (lihat §6).
- **Alamat:** body chassis via rantai di atas; offset `+0x50`/`+0x54`/`+0x58`.
- **Plus:** kecepatan benar-benar instan (tidak menunggu akselerasi); jengat
  hilang karena sumber putaran (`ω`) ditahan tiap frame; tidak bergantung pada
  joint motor (jalan di semua kendaraan); stuck-check (`speed < 1,0`) otomatis
  lolos selama fitur aktif.
- **Minus / risiko:**
  - Menahan `ω = 0` terus-menerus membuat mobil **tidak bisa berputar di udara**
    (tidak bisa flip untuk bonus, mendarat selalu datar — bisa terasa aneh;
    mitigasi: tahan `ω` hanya bila kedua roda menapak / bila `|ω|` di bawah
    ambang, atau klem lunak bukan nol keras).
  - Velocity yang di-set tiap frame **berantem dengan solver**: suspensi/joint
    masih menghitung dari velocity lama; bisa timbul jitter visual pada roda
    atau respons tabrakan yang aneh (mobil "menerobos" rintangan ringan).
    Mitigasi: set velocity SEBELUM step (biar solver yang menyelesaikan
    kontak) dan hanya komponen X (maju) yang dipaksa, Y dibiarkan dari fisika.
  - Fuel tetap dikuras dari throttle (bukan dari kecepatan) — bila pemain tidak
    menahan gas, kecepatan instan jadi "gratis". Itu bisa dianggap fitur, tapi
    harus diputuskan (lihat §6).
  - Butuh arah: bila arah diambil dari velocity saat ini, mobil yang sedang
    mundur akan makin mundur; bila dari hadap kendaraan, perlu sudut
    `[body+0x48]` (masih kandidat — lihat §7).

### Kandidat B — Naikkan motor speed + batas torsi, dengan counter-torque pada chassis
- **Cara:** hook `SetMotorSpeed` (`0x6ced48`) → kalikan `s0` dengan faktor besar
  (top speed naik), hook `SetMaxMotorTorque` (`0x6ced10`) → kalikan `s0` dengan
  pengali (§5), DAN tiap frame terapkan counter-torque ke chassis
  (tulis `[chassis+0x58] -= k × [chassis+0x58]` atau set langsung 0 — sama
  seperti kandidat A untuk bagian penahan).
- **Plus:** tetap memakai jalur fisika resmi (roda benar-benar berputar, debu/
  suara mesin konsisten, suspensi berperilaku normal).
- **Minus / risiko:** pada dasarnya kandidat A + langkah ekstra; torsi besar
  tetap menimbulkan pitch SEBELUM penahan bekerja (satu frame jengat kecil
  masih mungkin); solver joint punya iterasi terbatas — torsi sangat besar
  (10× dari ~66 = ~660) bisa membuat joint solver overshoot/jitter; lebih
  banyak titik hook = lebih banyak yang bisa patah di update game berikutnya.

### Kandidat C — Bekukan sudut chassis (set `[body+0x48]` = sudut target tiap frame)
- **Cara:** tiap frame tulis `[chassis+0x48]` ke sudut "datar" (0 atau sudut
  tanah) + `[chassis+0x58] = 0`.
- **Plus:** paling harfiah "tidak jengat".
- **Minus / risiko:** **DITOLAK sebagai kandidat utama** — sudut `[body+0x48]`
  masih kandidat (belum terkonfirmasi runtime); menulis sudut langsung
  berantem keras dengan solver (posisi roda vs chassis jadi tidak konsisten,
  bisa teleport/clip); merusak tanjakan (mobil harus miring mengikuti tanah).
  Hanya layak sebagai eksperimen, bukan implementasi.

**Rekomendasi:** **Kandidat A** sebagai inti "Speed Instan", dengan **Kandidat B
(parsial: hook `SetMaxMotorTorque` saja)** sebagai pengali torsi pendamping
(lihat §5). Keduanya berbagi penahan angular velocity yang sama.

---

## 5. Pengali torsi (SeekBar) — tambahan

### 5.1 Di mana nilai torsi berada & di mana ia dikalikan
- **Nilai torsi (float):** `[car+0x760]` — stat mesin per kendaraan
  (Jeep 23,0 × 1,046^(level−1); kendaraan lain 4,25–28,0 level 1; maks ±66).
  Di-set sekali di konstruktor (Jeep: `0x4f94a8`).
- **Tempat ia diterapkan:** tiap frame di update kendaraan
  (Jeep `0x53c118`/`0x53c134`, kendaraan lain setara) → `SetMaxMotorTorque`
  (`0x6ced10`, 1.72.2 / `0x6be36c`, 1.71.1) dengan argumen `s0 = −[car+0x760]`
  → ditulis ke **`[joint+0xb8]`** (maxMotorTorque) pada kedua joint roda.
- **Tempat ia "dikalikan":** di dalam solver, impuls motor dibatasi
  `±(maxMotorTorque × dt)`. Jadi menaikkan `[joint+0xb8]` N kali =
  menaikkan gaya dorong maksimum N kali (selama `motorSpeed` belum tercapai).

### 5.2 Titik patch/hook yang disarankan (urut dari terbaik)
1. **Hook `SetMaxMotorTorque` (`0x6ced10`) — TERBAIK.** Kalikan `s0` dengan
   pengali slider sebelum diteruskan (`s0_baru = s0 × pengali`, tanda dipertahankan).
   Satu titik, kena kedua joint, tiap frame, tidak peduli kendaraan/level.
   Pola byte 56-byte unik ada di §2.2.
2. **Hook di situs pemanggil update kendaraan** (`0x53c118`/`0x53c134` Jeep):
   kalikan `[car+0x760]` yang dibaca. Lebih rapuh (tiap kendaraan punya alamat
   pemanggil berbeda — harus pattern-scan per kendaraan atau hook semua).
3. **Patch stat di konstruktor** (`0x4f94a8`: `fmov s0,#23,0` / hasil
   `str s0,[x19,#0x760]`): hanya berefek untuk kendaraan yang dibuat sesudah
   patch; nilai dasar berbeda per kendaraan (23/28/25/21/15/4,25) sehingga
   patch konstanta tidak seragam; DAN `[car+0x760]` juga dipakai sebagai batas
   kecepatan motor — mengubahnya ikut menaikkan top speed (efek samping).
   **Tidak disarankan** sebagai jalur utama.
4. **Patch langsung `[joint+0xb8]` tiap frame** (tulis `joint+0xb8 = −[car+0x760] × pengali`
   dari hook update): setara dengan opsi 1, tapi butuh pointer joint
   (`[car+0x7b0]`/`[car+0x7b8]`) tiap frame — lebih banyak kode, hasil sama.

### 5.3 Interaksi pengali torsi dengan anti-jengat (PENTING)
Pengali torsi **memperbesar penyebab jengat dengan faktor yang sama**:
torsi ×N → reaksi pitch ×N. Tanpa penahan putaran, slider 10× hampir pasti
membuat kendaraan jungkir balik seketika saat gas ditekan. Karena itu
pengali torsi TIDAK BOLEH berdiri sendiri. Tiga desain yang masuk akal:

**Opsi 1 — Pengali jalan BARENG penahan putaran (DIREKOMENDASIKAN).**
Slider pengali hanya aktif bila "Speed Instan" (penahan `ω`) aktif; keduanya
berbagi satu penahan angular velocity (kandidat A). Torsi besar mendorong roda,
penahan `ω ≈ 0` menyerap reaksi pitch di chassis.
- Plus: user mendapat akselerasi + top speed tanpa jengat; satu mekanisme
  penahan untuk semua sumber pitch; perilaku paling dapat diprediksi.
- Minus: penahan `ω` juga memblokir flip yang disengaja di udara (lihat
  mitigasi kandidat A: tahan hanya saat menapak, atau klem lunak).

**Opsi 2 — Batas atas slider yang aman bila anti-jengat mati.**
Bila penahan `ω` nonaktif, slider dibatasi maks **2×–3×** (masih terasa, pitch
masih bisa dikendalikan pemain dengan melepas gas); bila penahan aktif,
slider dibuka sampai **10×**.
- Plus: fleksibel; pemain yang mau "rasa liar" tetap bisa.
- Minus: dua batas = dua perilaku yang harus dijelaskan di UI; batas "aman"
  2–3× tetap bisa jengat di kendaraan ringan/torsi dasar besar (mis. base 28).

**Opsi 3 — Pengali diterapkan ke pendekatan set-velocity, bukan ke torsi mentah.**
Slider TIDAK menyentuh joint sama sekali — ia mengalikan **target speed**
kandidat A (`vx_target = base_speed × pengali`). Torsi joint dibiarkan normal.
- Plus: **nol risiko jengat dari pengali** (tidak ada torsi tambahan);
  implementasi paling sederhana (satu variabel); konsisten dengan "speed instan".
- Minus: ini sebenarnya "pengali kecepatan", bukan "pengali torsi" — rasa
  (akselerasi dari diam, tanjakan) berbeda dari torsi asli; roda tidak berputar
  lebih cepat secara visual bila velocity di-set langsung.

**Rekomendasi:** **Opsi 1 sebagai default** (pengali torsi via hook
`SetMaxMotorTorque` + penahan `ω` selalu aktif bersamanya), dengan **Opsi 3
sebagai mode alternatif** bila user ternyata lebih suka "kecepatan" daripada
"rasa torsi". Opsi 2 hanya bila user minta slider tetap bisa dipakai tanpa
penahan — sampaikan batas amannya.

### 5.4 Rentang slider yang masuk akal
Berdasarkan nilai torsi normal yang terukur (§2.4: base **4,25–28,0** level 1,
s.d. **±66** di level maks):
- **Rentang: 1×–10×, langkah 0,5×, default 1×.**
- Alasan: 10× dari torsi maks (±66) ≈ **±660** — itu sudah sangat besar;
  di atas itu solver joint (iterasi tetap) mulai overshoot/jitter dan roda
  kehilangan traksi (spin di tempat, debu terus-menerus). 1× = perilaku normal
  (pengali mati, tanpa efek). Langkah 0,5× memberi 19 posisi — cukup halus
  untuk SeekBar tanpa membanjiri UI.
- Catatan: karena `[car+0x760]` juga membatasi kecepatan motor
  (`clamp(23 − |ω|, 0, 1)`), **pengali torsi saja TIDAK menaikkan top speed**
  — hanya akselerasi & tanjakan. Bila user mau top speed naik juga, perlu
  menaikkan batas kecepatan (kandidat A / hook `SetMotorSpeed`) — sampaikan
  ini jujur di UI (mis. label "Torsi (akselerasi)", bukan "Kecepatan").

---

## 6. Desain fitur yang diusulkan (jangan diputuskan sendiri — untuk dipilih user)

Satu seksi "Speed" di mod menu, di bawah God Mode v4:

| Opsi | Cara kerja | Plus | Minus |
|---|---|---|---|
| **A. Toggle "Speed Instan" + target kecepatan configurable** (ala Air Time) | Toggle ON → tiap frame set `[chassis+0x50]/[0x54]` ke target & tahan `[chassis+0x58] ≈ 0`. Target dari SeekBar/input angka (default **30 m/s**, rentang **10–60 m/s**, langkah 5). | Konsisten selama berkendara; mudah dipakai; anti-jengat built-in. | Berantem dengan solver (jitter potensial); blokir flip udara bila `ω` ditahan keras; butuh arah gerak yang benar. |
| **B. Tombol boost sekali** | Satu tap → set velocity ke target sekali (atau selama 1–2 detik), lalu fisika mengambil alih. | Gangguan minimal ke fisika; natural untuk lompatan; tidak perlu penahan permanen. | Kecepatan meluruh sesudah boost (gesekan/drag); sensasi kurang "instan" dibanding toggle; perlu cooldown supaya tidak di-spam. |
| **C. Slider pengali torsi 1×–10× (langkah 0,5×)** | Hook `SetMaxMotorTorque` (`0x6ced10`), kalikan `s0`. | Rasa akselerasi asli; roda/suara/debu konsisten; satu titik hook. | **Wajib** bareng penahan `ω` (Opsi 1 §5.3) — sendiri pasti jengat; tidak menaikkan top speed (batas `clamp(23−|ω|)`) |
| **D. Kombinasi (REKOMENDASI)** | Toggle Speed Instan (A) + slider torsi (C) di bawahnya; slider torsi hanya aktif bila toggle ON (penahan `ω` jalan). Target speed & pengali masing-masing configurable. | Satu mekanisme anti-jengat untuk semua; user dapat kecepatan instan + akselerasi buas sekaligus; perilaku paling terprediksi. | Paling banyak kode; dua kontrol yang harus dijelaskan; tetap ada risiko jitter solver di pengali 10×. |

Keputusan yang masih di tangan user: (1) toggle vs boost vs kombinasi;
(2) target speed default & rentang; (3) apakah pengali torsi boleh jalan tanpa
penahan `ω` (Opsi 2 §5.3) atau tidak.

---

## 7. Yang masih butuh data runtime dari HP (probe dinamis)

1. **Sudut `[body+0x48]`**: baca nilainya saat mobil berputar/menanjak —
   konfirmasi ia menyapu 0→2π (atau −π→π) seiring rotasi, dan `[body+0x4c]`
   adalah pasangannya (cos) atau bukan. Bila bukan sudut, cari sumber sudut
   lain (kemungkinan `atan2` atas vektor hadap).
2. **Urutan joint**: `[car+0x7b0]` vs `[car+0x7b8]` — mana depan, mana belakang
   (log `s0` di `SetMotorSpeed`/`SetMaxMotorTorque` per joint saat jalan).
3. **Nilai motor saat jalan**: log `s0` di `0x6ced48` (motor speed) dan
   `0x6ced10` (max torque) saat gas penuh, menanjak, dan di udara — konfirmasi
   rentang nyata & tanda negatif torsi.
4. **Rantai pointer runtime**: verifikasi `run+0x3a8 → vehicle → +0x258 → car →
   +0x2d8 → chassis body` di perangkat (alamat hook update `0x3bd1dc` sudah
   terverifikasi oleh slow-mo v1.5–v1.6).
5. **Uji kandidat A di POCO**: set velocity + tahan `ω` — amati jitter,
   perilaku suspensi/tabrak, dan apakah flip di udara masih mungkin
   (bandingkan `ω = 0` keras vs klem lunak ±0,5 rad/s vs tahan-hanya-saat-menapak).
6. **Uji pengali torsi 10× + penahan `ω`**: amati stabilitas solver
   (jitter/overshoot) dan traksi roda (spin vs grip).
7. **Arah gerak**: tentukan apakah arah target diambil dari velocity saat ini
   atau dari hadap kendaraan (`[body+0x48]` bila terkonfirmasi) — uji mundur
   & putar balik.

---

## 8. Daftar alamat penting (1.72.2; 1.71.1 bila ada)

| Keterangan | 1.72.2 | 1.71.1 |
|---|---|---|
| `SetMotorSpeed` (joint+0xb4) | `0x6ced48` | `0x6be3a4` |
| `SetMaxMotorTorque` (joint+0xb8) | `0x6ced10` | `0x6be36c` |
| Update Jeep (slot 0x80) | `0x53bba4` | — |
| Situs motor Jeep (4 call) | `0x53c108/0x53c118/0x53c124/0x53c134` | — |
| Update BadCar (slot 0x80) | `0x50525c` | — |
| Stuck check (speed < 1,0) | `0x5053b8` | — |
| Fuel drain (`fuel -= dt·2,5·throttle·rate`) | `0x3c9470–0x3c94b0` | fuel di `[run+0x60c]` |
| Throttle getter (slot vtable 0x158) | via vtable car | sama |
| Getter posisi (slot vtable 0x70) | `0x4f4b30` | — |
| Predikat kematian | `0x3b2f94` | `0x3aa554` |
| Setter flag mati (god v4, sudah rilis) | `0x3b0ddc`, `0x3ad494`, `0x4eff98` | — |
| Ctor Jeep: `[car+0x760] = 23,0 × 1,046^(lvl−1)` | `0x4f9484–0x4f94a8` | — |
| Konstanta pengali upgrade 1,046 | rodata `0x1fdc5c` | — |
| Fungsi debu roda (BUKAN motor) | `0x4f0c88` | — |
| Pabrik particle roda | `0x69afd8` (vtable `0x8656c0` = `CCParticleSystemQuad`) | — |
| Update utama | `0x3c6840`; update besar `0x3c585c` | — |
| Hook update (slow-mo, sudah ada) | `0x3bd1dc` | — |

## 9. File kerja
- `~/workspace/rea-hcr-speed/hcrdis.py`, `scan.py`, `vtdump.py` (helper disassembly/scan/vtable)
- `~/workspace/rea-hcr-speed/big_update_1722.txt`, `jeep_update.txt`, `jeep_ctor2.txt`, `accessors.txt`
- Referensi: `~/workspace/hozin-hcr-mod/flip-probe/PROBE.md`,
  `~/workspace/hozin-hcr-mod/docs/fuel_analysis.md`, `~/workspace/rea-hcr-death/REPORT.md`
