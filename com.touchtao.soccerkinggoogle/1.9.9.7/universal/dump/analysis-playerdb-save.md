# Analisis Native — Basis Data Pemain, Fungsi Kesulitan, Format Simpanan Karier

**Target:** World Football League `com.touchtao.soccerkinggoogle` v1.9.9.7, `libHQRenderLib.so` (BuildID `1d5d0525…`, VA = offset berkas di `.text`/`.rodata`).
**Metode:** disassembly `llvm-objdump` (NDK 26.1) atas fungsi dynsym + ekstraksi & parsing nyata `res_all.pak`. Analisis saja, tanpa build. Melengkapi `REPORT.md` §5–§6.
**Tanggal:** 23 Okt 2026.

---

## 1. `CTeam::ApplyGameDifficultyToPlayerDataBase(_PlayerDataBase*)` — VA `0x4289d8`

### 1.1 Tanda tangan & konteks register (terbukti dari disassembly)

```
x0 = CTeam* (this)          x1 = _PlayerDataBase* (SATU record pemain, 80 byte)
```

Fungsi ini **bukan** pemroses seluruh basis data: ia mengolah **satu record** setiap panggilan.

### 1.2 Gerbang (gate) — penentu tim mana yang terkena

```asm
4289d8  x8  = this + 0xe000
4289dc  x9  = [this + 0xe0f8]              ; pointer "gate base"
4289e0  x10 = (s32)[this + 0xe10c]         ; slot tim (0 / 1)
4289e4  x9  = x9 + x10*4
4289e8  w9  = [x9 + 0x58]                   ; flag kontrol slot ini
4289ec  if (w9 != 0) return;               ; ← flag ≠ 0 → TIDAK diskala
```

Identitas field (dari `CTeam::SetupStatusAndInfo(_TeamShareStatus*, int)` @ `0x421818` dan `CTeamManager::SetupStatusAndInfo()` @ `0x42be2c`):

| Field | Isi |
|---|---|
| `CTeam+0xe0f0` | `_TeamShareStatus*` (status bersama di `CTeamManager+0x58`) |
| `CTeam+0xe0f8` | `*(status[+0x10])` = `[CTeamManager+0x10]` — pointer struktur kontrol pertandingan |
| `CTeam+0xe10c` | **slot tim** (argumen int `SetupStatusAndInfo`: `0` = tim di `CTeamManager+0x250`, `1` = tim di `CTeamManager+0xe930`) |
| `CTeam+0xe108` | byte `(slot == 0)` |
| `CTeam+0xe110` | **team ID** tim ini (ditulis `LoadTeamAndPlayerStatisticInfo`, lihat §1.4) |

Gerbang membaca `u32` di `gateBase + slot*4 + 0x58`: **0 = tim CPU → diskala; ≠ 0 = tim yang dikendalikan manusia → dilewati utuh.** Inilah mekanisme bawaan game untuk hanya melemahkan tim komputer.

### 1.3 Nilai kesulitan & yang diskala

```asm
4289f4  x8 = [this + 0xe0f0]   ; status
4289f8  x8 = [x8]              ; status[0] = CTeamManager*
4289fc  x8 = [x8 + 0x8]        ; [CTeamManager+0x8]  (pointer objek sesi/device)
428a00  w8 = [x8 + 0x88]       ; ★ NILAI KESULITAN (u32)
```

Perilaku menurut nilai kesulitan `D` (semua operasi pada byte record `x1`):

| `D` | Pengurangan | Berlaku pada offset record |
|---|---|---|
| `0, 1, 2` | **−20** | `+0x32, +0x33, +0x35, +0x37, +0x3a` |
| `3` | **−10** | `+0x32, +0x33, +0x35, +0x37, +0x3a` |
| `≥ 4` | **0 (tanpa pengurangan)** | — |

Setelah pengurangan (dan juga bila `D ≥ 4`), **selalu dijalankan penjepit (clamp)** pada **enam** byte: hasil `< 1 → 1`, `≥ 100 → 99`, selain itu dibiarkan:

```
offset yang dijepit: +0x32, +0x33, +0x35, +0x37, +0x38, +0x3a
```

Catatan presisi:
- Offset `+0x38` **hanya dijepit, tidak pernah dikurangi**; offset `+0x34, +0x36, +0x39` **tidak disentuh sama sekali** oleh fungsi ini.
- Pengurangan adalah aritmetika byte 32-bit dari `ldrb` lalu `strb`: bila nilai awal `<` pengurang, byte membungkus (wrap) lalu tertangkap clamp `≥100 → 99`. Di data asli semua atribut ≥ 8 dan mayoritas ≥ 20, jadi jalur wrap praktis tidak terjadi — tapi hook pengganti harus meniru/memperbaiki ini secara sadar.
- Tidak ada skala persentase: murni pengurangan konstan per tingkat.

### 1.4 Rantai pemanggil (xref PLT, terbukti)

Hanya ada **satu** pemanggil di seluruh `.so` (PLT `0x4a8320`, dipanggil di `0x428f4c`):

```
CDevice::NewMatch(AI_TYPE, bool)                       0x3f4d08
  └─ (per tim) CTeam::LoadTeamAndPlayerStatisticInfo(teamId)   0x428ec8
       ├─ LoadTeamInfo(teamId, this+0xb0)
       ├─ [this+0xe110] = teamId
       ├─ LoadPlayerDataBaseOneTeam(teamId, bufferStack)       0x4288e4
       └─ loop i = 0..20:
       │     memcpy(&this+0x34d + i*0x50, bufferStack + i*0x50, 0x50)
       │     ApplyGameDifficultyToPlayerDataBase(&this+0x34d + i*0x50)   ← 21× per tim
       ├─ (inline) BackupPlayerAbility → salin 9 byte ability ke this+0x290 + i*9
       └─ UpdatePlayerStatisticBySubstitutions()
```

Kedua tim (slot 0 dan slot 1) melewati jalur yang sama persis di `NewMatch` (team ID dari `[CDevice+0x98]`/`[CDevice+0x9a]`, u16). Yang membedakan hasil akhir **hanya gerbang §1.2**. Fungsi ini dipanggil **saat pemuatan tim menjelang pertandingan**, bukan saat DB dibaca dari `.pak` mentah-mentah dan bukan per frame.

Fungsi pemuat DB terkait (untuk peta lengkap):

| Fungsi | VA | Perilaku |
|---|---|---|
| `CTeam::LoadPlayerDataBase(int idx, _PlayerDataBase* out)` | `0x4287f4` | Baca **1 record**: `Seek(idx*80)`, `Read(out, 0x50)`; idx dijepit `≤ 0xa55 (2645)`; lalu `UpdatePlayerAge(out, 1)` |
| `CTeam::LoadPlayerDataBaseOneTeam(int teamIdx, _PlayerDataBase* out)` | `0x4288e4` | Baca **1 tim = 21 record**: `Seek(teamIdx*0x690)`, `Read(out, 0x690)`; teamIdx dijepit `≤ 0x7d (125)`; lalu `UpdatePlayerAge(out, 21)` |
| `CTeam::LoadTeamInfo(int idx, _TeamDataBase* out)` | `0x4286ec` | TeamDB: baca u32 header (jumlah tim), `Seek(4 + idx*58)`, `Read(out, 0x3a=58)` |
| `CGame::GetPlayerDBName()` | `0x33dd48` | Bahasa == 1 → `Res\Data\PlayerDB2022_Zh.dat`, selain itu `Res\Data\PlayerDB2022_En.dat` |
| `CGame::UpdatePlayerAge(_PlayerDataBase*, int count)` | `0x33dd90` | Per record: `[rec+0x40] = -26 - [rec+0x41]` (lihat §2.3) |

### 1.5 Vonis untuk fitur "pelemah AI" (hook di fungsi ini)

**Mungkin, dan titik ini justru titik terbaik.** Alasan:

1. **Diskriminasi user vs lawan tersedia penuh di titik hook**, dari `x0` (`CTeam*`):
   - slot tim: `[CTeam+0xe10c]` (0/1);
   - team ID: `[CTeam+0xe110]`;
   - **flag kontrol bawaan game**: `[[CTeam+0xe0f8] + slot*4 + 0x58]` — `0` = CPU, `≠0` = manusia. Payload cukup meniru gerbang asli: terapkan skala slider **hanya bila flag == 0**.
   - Indeks pemain pun dapat diturunkan: `playerIdx = (x1 − (CTeam+0x34d)) / 0x50` (0..20).
2. Hook di sini berjalan **sebelum** `BackupPlayerAbility` menyalin ability ke array kerja (`CTeam+0x290`), jadi satu titik mengubah semua turunan (statistik `CPlayer`, kecepatan, tembakan).
3. Alternatif yang lebih kasar — hook `LoadTeamAndPlayerStatisticInfo` (`0x428ec8`) seusai kembali — **tidak dianjurkan**: saat itu ability sudah tersalin ke `CTeam+0x290 + i*9` dan statistik turunan sudah dihitung; payload harus menulis dua tempat (array DB `+0x34d` **dan** array ability `+0x290`) dan tetap kalah urutan dari `UpdatePlayerStatisticBySubstitutions`.
4. **Kill-switch MP wajib**: `NewMatch` juga dipakai mode jaringan. Aturan aman: skala kustom hanya bila flag gerbang == 0 (persis kondisi CPU pada fungsi asli); bila kedua slot berflag manusia (indikasi vs manusia), hook harus no-op total. Jangan pernah mengskala record tim berflag manusia.

Rumus hook yang aman (per record, hanya saat flag gerbang == 0):

```
untuk off di {0x32, 0x33, 0x35, 0x37, 0x3a}:           // set yang sama dengan asli
    rec[off] = clamp( rec[off] * sliderPersen / 100 , 1, 99 )
rec[0x38] = clamp( rec[0x38], 1, 99 )                  // opsional, meniru clamp asli
// JANGAN panggil fungsi asli setelah itu (akan mengurangi lagi −20/−10);
// atau panggil asli hanya untuk tim manusia (di mana ia memang no-op oleh gerbang).
```

---

## 2. Layout `_PlayerDataBase` & `_PlayerData` — dari data nyata

### 2.1 Ekstraksi `res_all.pak` (format terpecahkan dari disassembly)

`CLZMAFileManager::Open` @ `0x2b8740`, `FindRecord` @ `0x2b882c`, `ComputeHash` @ `0x2b8890`, `GetDecompressedSize` @ `0x2b88d4`, `CM3DFile::Open` @ `0x2c420c`:

```
res_all.pak:
  +0x00  u32  N = 673                        (jumlah record)
  +0x04  record[N], masing-masing 12 byte:
           +0x0 u32  hash nama  (h = 0; per char c: h = h*31 + (s8)c)
           +0x4 u32  offset blob dalam satuan DWORD (offset byte = nilai × 4)
           +0x8 u32  ukuran blob terkompresi
  blob: aliran LZMA-Alone (5 byte props + u32 ukuran hasil dekompresi + data)
```

Nama yang di-hash **bukan** nama mentah: `CM3DFile::Open` mengubah nama menjadi huruf kecil lalu memformat dengan templat `"res\\%s"` (`0x1134e6`). Contoh terbukti: `Res\Data\PlayerDB2022_En.dat` → hash dari `res\res\data\playerdb2022_en.dat` = `0x736550fa` → record #30, offset `1.847.388`, terkompresi `52.688` byte → hasil dekompresi **`211.680` byte**. TeamDB En: `7.312` byte. (Reproduksi: `lzma.decompress(blob, format=FORMAT_ALONE)` Python.)

Hasil kunci:

```
PlayerDB2022_En.dat = 211.680 byte = 2.646 record × 80 byte = 126 tim × 21 pemain
TeamDB2022_En.dat   =  7.312 byte = 4 (header jumlah=126) + 126 record × 58 byte
```

Ini membuktikan dari data nyata: **`sizeof(_PlayerDataBase) = 0x50 = 80`**, 21 pemain/tim, 126 tim — persis angka jepit di fungsi pemuat (§1.4). Tidak ada struktur `_PlayerData` terpisah di berkas: record berkas = `_PlayerDataBase`; representasi runtime per pemain adalah `CPlayer` (menunjuk record via `[CPlayer+0x8]`, diset `SetupPlayerDataBaseAndStatistic` @ `0x409e24` ke `CTeam+0x34d + idx*0x50`) plus array ability kerja 9 byte dan record statistik 20 byte di dalam `CTeam`.

### 2.2 Peta field `_PlayerDataBase` (offset dari awal record)

| Offset | Tipe | Isi | Bukti / rentang nyata (2.646 record) |
|---|---|---|---|
| `+0x00` | u8 | Indeks tim (0–125) | data |
| `+0x01` | u8 | Indeks pemain dalam tim (0–20) | data |
| `+0x02..0x21` | char[32] | Nama pemain, NUL-padded (cth. `Bachman`, `Harry Kane`) | data |
| `+0x22..0x31` | char[16] | Nama tim/kebangsaan (cth. `Austria`, `England`, `Brazil`) | data |
| **`+0x32..0x3a`** | **u8 × 9** | **Blok ability** (tabel §2.3) | data + kode |
| `+0x3b, +0x3c, +0x3d` | u8 × 3 | Enum kecil 0–4 (peran/kaki bintang? belum bernama pasti) | data |
| `+0x3e` | u8 | Kandidat tinggi badan (85–202; mayoritas 160–202) | data |
| `+0x3f` | u8 | Kandidat berat badan (54–102) | data |
| `+0x40` | u8 | Umur — **ditulis ulang saat muat**: runtime `= 230 − [+0x41]`; di berkas nilainya basi (`= 222 − [+0x41]`, sisa edisi 2014) | kode `UpdatePlayerAge` + data |
| `+0x41` | u8 | Tahun lahir terenkode: `tahun − 1792` (182–227 → umur runtime 3–48, bintang terverifikasi: Kane `201 → 29 th`, Neymar `200 → 30 th` pada 2022) | kode + data |
| `+0x42` | u8 | Konstan **7** di semua record | data |
| `+0x43` | u8 | Bulan lahir (1–12; Kane=7, Neymar=2 ✓) | data |
| `+0x44` | u8 | Tanggal lahir (1–31; Kane=28, Neymar=5 ✓) | data |
| `+0x45` | u8 | Bit-flag (nilai teramati 1/2/4/8 — kaki dominan dsb.) | data + `ApplyPlayerStatistics` |
| `+0x46` | u8 | ID penampilan (0–55, mayoritas 0) | data |
| `+0x47` | u8 | 0–15, jarang terisi | data |
| `+0x48..0x4e` | u8 × 7 | Flag 0/1 | data |
| `+0x4f` | u8 | Enum 0–4 | data |

Layout `CTeam` yang menampungnya (untuk payload): array record di **`CTeam+0x34d`** (21 × 80 byte, s/d `+0x9dd`); salinan ability kerja di **`CTeam+0x290 + i*9`**; pointer per pemain `_PlayerDataBase*` di `[CTeam+0xa78 + i*8]`, pointer ability di `[CTeam+0xa80 + i*8]`; buffer `_TeamDataBase` di `CTeam+0xb0` (58 byte).

`_TeamDataBase` (58 byte, terbukti): `+0x00` u8 indeks; `+0x01..0x20` char[32] nama tim; `+0x21..` kode 3 huruf (`AUT`, `ENG`, …); `+0x29..0x30` 8 byte parameter formasi; `+0x31` u8; **`+0x32..0x39` 8 byte rating tim** — byte `+0x32` adalah "kemampuan tim" yang dikembalikan `CCupAndLeague::GetTeamAbilityByID` @ `0x3d34e8` dan dipakai simulasi hasil AI-vs-AI (disalin ke `CCupAndLeague+0x770+i` oleh `InitializeExterndInfo` @ `0x3d0320`).

### 2.3 Blok ability `+0x32..+0x3a` — nama, rentang, tingkat keyakinan

Urutan array ability runtime (dari `CTeam::RestorePlayerAbility` @ `0x4290e0`, yang menyalin DB→array kerja): `[0]=+0x32, [1]=+0x35, [2]=+0x36, [3]=+0x37, [4]=+0x38, [5]=+0x3a, [6]=+0x33, [7]=+0x34, [8]=+0x39`.

| Offset | Rentang nyata | Kandidat nama | Keyakinan & bukti |
|---|---|---|---|
| `+0x32` | 22–94 | **Tembakan (shoot)** | Sedang — gradien posisi terkuat (rata-rata GK 34 → DEF 61 → MID 69 → FW 77); masuk set inti yang diskala kesulitan & di-clamp `IncPlayerAbility` |
| `+0x33` | 20–95 | **Bertahan (defense)** | **Tinggi (data)** — GK 75,5 / DEF 70,8 / MID 60,6 / FW 45,6; satu-satunya byte pertahanan yang diskala kesulitan |
| `+0x34` | 28–94 | Umpan (pass) | Sedang — rata di semua pemain lapangan (±76), rendah hanya di GK (63) |
| `+0x35` | 33–96 | Stamina | Sedang — hampir datar di semua posisi termasuk GK (±72–77); masuk set skala & clamp inti |
| `+0x36` | 35–95 | **Kecepatan (speed)** | **Terbukti kode** — `CPlayerState_TurnOnWithBall::ApplyPlayerSpeedStatistic` @ `0x3ebf5c` memakai ability[2] sebagai pengali kecepatan; `ApplyPlayerStatistics` menurunkan 4 parameter gerak/fisik dari byte ini |
| `+0x37` | 29–95 | Kandidat **kekuatan tembakan (shot power)** / dribel | Sedang — gradien serang kedua (GK 54 → FW 76), diskala kesulitan; pembeda power vs akurasi tidak terbaca statis (lihat catatan) |
| `+0x38` | 8–95 | Teknik/kontrol bola (agility) | Sedang — tinggi di GK (82, handling) dan pemain teknik (Neymar 91); **hanya di-clamp, tidak dikurangi** oleh fungsi kesulitan |
| `+0x39` | 30–94 | Kandidat sundulan / tendangan bebas / power | Rendah–sedang — datar antarposisi, menonjol di Kane (77–88); **tidak disentuh** fungsi kesulitan maupun `IncPlayerAbility` |
| `+0x3a` | 37–97 | **Kiper (goalkeeping)** | **Tinggi (data)** — GK utama 81,0 & GK cadangan 76,5; **semua pemain lapangan ≈ 50** (1.640 record tepat 50); diskala kesulitan (menurunkan kiper CPU) |

**Soal spin/curve/lengkung: tidak ada field-nya di `_PlayerDataBase`.** Kesembilan byte di atas terpetakan ke atribut konvensional; efek lengkung tembakan dihitung prosedural di `CPlayerState_Shoot::GetShootAngleAdd` @ `0x3e6a18` / `GetShootSpeedAdd` @ `0x3e6b20` dari arah, posisi bola, dan status — bukan dari atribut DB. Jadi "menaikkan spin pemain" lewat DB **tidak tersedia**; yang tersedia adalah menaikkan byte tembakan (`+0x32`, kandidat akurasi) dan `+0x37` (kandidat power).

**Rentang sah global ability: 1–99** (dijepit paksa oleh dua fungsi: min 1, maks 99 — `ApplyGameDifficulty…` dan `CTeam::IncPlayerAbility` @ `0x428fc8`). Nilai berkas asli berada di 8–97. Menulis 99 = maksimum yang diakui mesin; menulis > 99 akan dijepit turun pada jalur Inc/clamp berikutnya.

**Rumus "atribut maks tim sendiri" yang aman:** jangan mengedit `.pak`/APK. Di runtime, untuk `CTeam` yang flag gerbangnya ≠ 0 (tim manusia) — atau sesudah `LoadTeamAndPlayerStatisticInfo` untuk tim itu — tulis pada **kedua** salinan:

```
untuk i in 0..20, untuk off di {0x32..0x3a}:
    *(u8*)(team + 0x34d + i*0x50 + off) = 99
    *(u8*)(team + 0x290 + i*9 + abilityIndex(off)) = 99
    // abilityIndex: 0x32→0, 0x35→1, 0x36→2, 0x37→3, 0x38→4, 0x3a→5, 0x33→6, 0x34→7, 0x39→8
```

Menulis hanya array DB tidak cukup bila backup ability sudah terbentuk (urutan di §1.4); menulis di titik hook §1.5 (di dalam loop, sebelum backup) adalah cara satu-tempat yang benar.

---

## 3. Format simpanan karier (mode Cup & League)

### 3.1 Nama berkas & direktori (terbukti)

`CGame::SaveSetting()` @ `0x33cf30` dan `CGame::GetSetting()` @ `0x33b9b4` membangun jalur dengan `strcat`:

```
jalur = "/data/data/com.touchtao.soccerkinggoogle"   ; string @ 0x10d737
      + "/"                                          ; string @ 0x10bea3
      + (flagDemo == 0 ? "ws14.sav"                   ; string @ 0x10a208
                       : "ws14demo.sav")               ; string @ 0x1130e8
```

**Berkas simpanan utama: `/data/data/com.touchtao.soccerkinggoogle/ws14.sav`** (mode demo: `ws14demo.sav`). Ditulis/dibaca lewat `CGenericFile` (bukan AAsset) — berkas privat aplikasi biasa, dapat ditarik dengan root.

### 3.2 Wadah berkas `_ConfigDataSave` — ukuran tetap `0x2058` (8.280 byte)

Dari `SaveSetting` (penulis) + `GetSetting`/`CompareAESKey` @ `0x33d5ec` (pembaca):

| Offset berkas | Ukuran | Isi |
|---|---|---|
| `+0x00` | 16 byte | **Kunci AES-128**, disimpan terang di berkas. Byte 0–3 = magic tetap `2A B0 D4 A8` (diverifikasi `CompareAESKey`); byte 4–15 = acak per penyimpanan (12 × `CRandom::Random(0x7e)` + konstanta, dibuat di `SaveSetting`) |
| `+0x10` | u32 | **Checksum** atas plaintext: `h = 0x1505; untuk setiap byte b (signed) pada payload offset 0x14..0x2047: h = h*33 + b` (gaya djb, dihitung **sebelum** enkripsi; 0x2034 byte) |
| `+0x14` | `0x2040` byte | **Payload terenkripsi AES-128-ECB** (kelas `CAES` @ `0x352dec`; `Cipher(void*,int)` @ `0x353b8c` mengenkripsi per blok 16 byte independen **tanpa IV/rantai** → ECB murni; implementasi AES tabel standar) |
| `+0x2054` | 4 byte | Ekor di dalam rentang cipher (nol/padding; di luar jangkauan checksum) |

Struktur plaintext payload (= citra `_ConfigData` yang diserialkan):

| Offset payload | Isi |
|---|---|
| `+0x14..0x93` (0x80 byte) | `_ConfigData + 0xfc .. 0x17b` |
| `+0x94` | u32 = `1` |
| `+0x98` | u32 volume suara (`CGameSound::GetVolume`) |
| `+0x9c..0x2047` (0x1fac byte) | `_ConfigData + 0x184 .. 0x212f` |

`_ConfigData` di memori dipegang `CGame` di `[CGame+0x120]`. Perhatian: fungsi-fungsi `CCupAndLeague::Save/Load(_ConfigData*)` menerima pointer **`_ConfigData + 0xfc`** (terbukti dari pemanggil `CGamePlay::EnterGameMenu` @ `0x340124`: `x1 = [obj+0x138] + 0xfc`; dan `CGameMenu_CL_SelectMode::Initialize` @ `0x36f2ac`: `x1 = config + 0xfc`). Semua offset §3.3 dinyatakan dalam tiga sistem: offset-CL (dari `config+0xfc`), offset-config absolut, dan offset payload/berkas (identik setelah dekripsi, karena payload menempelkan kedua potongan config secara berurutan dengan sisipan 8 byte di `+0x94`).

Pemetaan: `payload(o) = o + 0x14` untuk offset-CL `o < 0x80`; `payload(o) = o + 0x1c` untuk `o ≥ 0x88`. (8 byte config `0x17c..0x183` / offset-CL `0x80..0x87` tidak diserialkan.)

### 3.3 Lapisan karier: `CCupAndLeague::Save/Load` + `SaveCupLeague/LoadCupLeague`

Alamat: `Save(_ConfigData*)` `0x3d3b80`, `Load(_ConfigData*)` `0x3d3a7c`, `SaveCupLeague(void*)` `0x3d03c4`, `LoadCupLeague(void*)` `0x3cfc0c`, jembatan `UpdateSaveToInfo(CupAndLeagueSave*)` `0x3d358c` (cermin persis `SaveCupLeague`; `UpdateInfoToSave` @ `0x3d371c` adalah stub `ret` kosong).

Indeks aktif: `t = (s32)[CCupAndLeague+0x50c]` = **CL_TYPE** (ditulis `EnterCupLeague(CL_TYPE)` @ `0x3cf6b0`). Tabel jumlah tim per tipe (`GetTeamAmountByCLType` @ `0x3cf9e8`, tabel rodata `0x1f20d8`): tipe `0,1 → 32 tim`; `2,3,4 → 16 tim`; `5,6 → 14 tim`. Cabang format di Save/Load: `t < 2` memakai blok kecil; `t ≥ 2` memakai blok besar.

`Save/Load(_ConfigData*)` melakukan tepat tiga hal:

1. `SaveCupLeague(configCL + 0xb4 + t*0x255)` — serialkan objek ke **slot `CupAndLeagueSave` 597 byte (0x255)**. (Basis absolut config `+0x1b0`, dikonfirmasi `CGame::IsCLSaveExit(int)` @ `0x33dcf8`: byte pertama slot `config + t*0x255 + 0x1b0` ≠ `0xff` → simpanan ada.)
2. Bila `t ≥ 2`: `memcpy` **960 byte (0x3c0)** antara `CCupAndLeague+0x105` ↔ `configCL + 0x92a + t*0x3c0`.
3. Bila `t < 2`: salin **252 byte (0xfc)** antara `CCupAndLeague+0x9` ↔ `configCL + 0xeb2 + t*0xfc`.

Catatan kejujuran tata letak: ketiga wilayah itu **tumpang-tindih** di dalam wilayah CL `_ConfigData` (0x2034 byte) — memang desain union: hanya data tipe yang sedang aktif yang bermakna; tipe lain dapat berisi sisa. Editor wajib bekerja pada slot tipe karier yang sedang dimainkan user.

### 3.4 Struktur `CupAndLeagueSave` (597 byte) — peta field

Dari `SaveCupLeague` (objek `CCupAndLeague` → slot) dan cerminnya `UpdateSaveToInfo`:

| Offset slot | Ukuran | Sumber objek | Isi |
|---|---|---|---|
| `+0x00..0x21` | 34 byte | obj `+0x510` | **Daftar ID tim peserta CL** (≤32 ID + sisa; `0xff` = kosong). Byte `+0x00` = penanda simpanan ada |
| `+0x20` | 1 byte | obj `+0x7d8` (u32, byte rendah menimpa salinan dari obj+0x530) | Indeks tim manusia dalam daftar (dipakai `Load` untuk menurunkan flag obj `+0x8` dari perbandingan dengan 3) |
| `+0x21` | 1 byte | obj `+0x531`, juga → obj `+0x7dc` | Indeks/flag pendamping |
| `+0x22` | 1 byte | obj `+0x532` | Tahap kompetisi (dipakai `CanGoEliminationMatch`: `t<2 && byte==2`) |
| `+0x23, +0x24, +0x25` | 3 byte | obj `+0x533, +0x535, +0x534` | Flag/indeks kecil (urutan simpan 533,535,534 — keunikan kompilator, isi tetap 1:1) |
| `+0x26..0x45` | 32 byte | obj `+0x537` | Susunan tim per grup / daftar urutan awal (ID tim) |
| `+0x46..0x65` | 32 byte | obj `+0x557` | **Array urutan klasemen kerja** (disalin dari `+0x537` lalu diurutkan `SortCLTeam`) |
| **`+0x66..0x165`** | **256 byte** | obj `+0x578` | **Rekor klasemen per tim: 6 byte × s/d 42** (§3.5) |
| `+0x166..0x1a3` | 62 byte | (loop obj `+0x638/+0x662/+0x68c`) | Tiga array u16[21] pendamping (obj `+0x638`→slot `+0x126`, obj `+0x662`→slot `+0x150`, obj `+0x68c`→slot `+0x17a`) — statistik per tim non-klasemen (jadwal/hasil agregat) |
| `+0x1a4..0x1b8` | 21 byte | obj `+0x6b6` | Array u8[21] |
| `+0x1b9..0x1cd` | 21 byte | obj `+0x6cb` | Array u8[21] |
| `+0x1ce..0x1d7` | 10 byte | obj `+0x6e0` | Byte pendamping |
| `+0x1d8..0x227` | 80 byte | obj `+0x6ea` | u32[20] (tidak selaras 4 di objek, selaras di slot) |
| `+0x228..0x251` | 42 byte | obj `+0x73a` | Byte pendamping |
| `+0x252` | 1 byte | obj `+0x765` (dinormalkan 0/1 saat muat) | Flag boolean |
| `+0x254` | 1 byte | byte rendah u32 obj `+0x7dc` | Ditulis saat simpan; **tidak dibaca kembali** oleh `UpdateSaveToInfo` (sisa) |

Objek runtime terkait yang **tidak** diserialkan (dihitung ulang saat muat/main): rekor pertandingan berpasangan obj `+0x798` (pasangan indeks tim, 4 byte/entri), array kemampuan tim obj `+0x770` (dari TeamDB `+0x32`), hitungan obj `+0x768`.

### 3.5 Poin liga & klasemen — lokasi persis yang dapat diedit

Dari `CCupAndLeague::SortCLTeam` @ `0x3d2994` (kunci urut: rekor[+0] desc unsigned → rekor[+4] desc signed → rekor[+5] desc unsigned — persis seri pemecah klasemen poin → selisih gol → gol memasukkan) dan `GetWinLose` @ `0x3d2260` (memakai `[+5] − [+4]` sebagai gol kemasukan):

**Rekor klasemen per tim = 6 byte di slot `+0x66 + 6*p`** (`p` = posisi tim dalam daftar ID slot `+0x00`, 0-based):

| Sub-offset | Tipe | Arti |
|---|---|---|
| `+0` | u8 | **POIN LIGA** ★ |
| `+1, +2, +3` | u8 × 3 | Belum bernama pasti (kandidat kuat: main/menang/seri atau menang/seri/kalah — tidak dibaca oleh `SortCLTeam`; editor poin murni tidak membutuhkannya, tetapi UI statistik rinci mungkin menampilkannya) |
| `+4` | s8 | **Selisih gol (GD)** |
| `+5` | u8 | **Gol memasukkan (GF)** (gol kemasukan diturunkan `GF − GD`) |

**Rumus offset poin di berkas (setelah dekripsi AES; offset payload = offset berkas):**

```
offsetPoin(t, p) = 0x136 + t*0x255 + 6*p
   ; 0xd0  = awal slot dalam payload  (0xb4 offset-CL + 0x1c)
   ; +0x66 = awal array rekor di dalam slot
   ; t = CL_TYPE karier aktif (0..6), p = posisi tim di daftar slot+0x00
offsetGD  = offsetPoin + 4        offsetGF = offsetPoin + 5
```

Contoh: karier tipe 5 (liga 14 tim), tim user di posisi daftar `p = 3` → poin di payload `0x136 + 5*0x255 + 18 = 0x136 + 0xC09 + 0x12 = 0xD51`.

Blok pendamping per tipe (bila editor perlu menyentuhnya): tipe `< 2`: blok 252 byte di payload `0xece + t*0xfc`; tipe `≥ 2`: blok 960 byte di payload `0x946 + t*0x3c0`.

### 3.6 Prosedur editor simpanan yang aman (dari format di atas)

1. Tarik `/data/data/com.touchtao.soccerkinggoogle/ws14.sav` (root). Ukuran harus `0x2058`.
2. Baca kunci 16 byte di `+0x00` (byte 0–3 wajib `2A B0 D4 A8`).
3. Dekripsi AES-128-**ECB** atas `+0x14 .. +0x2053` dengan kunci itu.
4. **Verifikasi**: hitung checksum djb (`h=0x1505; h=h*33+(s8)b` atas payload `0x14..0x2047`) — harus sama dengan u32 di `+0x10`. Langkah ini sekaligus membuktikan kesesuaian varian AES (bila implementasi `CAES` ternyata mentransposisi state, checksum gagal dan editor harus berhenti — jangan menulis).
5. Edit byte poin/GD/GF dengan rumus §3.5 (identifikasi `t` dari slot yang byte `+0x00`-nya ≠ `0xff` dan sesuai karier user; `p` dari posisi ID tim user di daftar slot).
6. Hitung ulang checksum → tulis ke `+0x10`; enkripsi ulang payload dengan kunci yang sama; tulis berkas kembali (pemilik/izin disamakan).

### 3.7 Yang masih harus dipetakan dari berkas nyata di perangkat

1. **Validasi AES + checksum** pada satu `ws14.sav` asli (langkah 3.6.4) — satu-satunya sisa risiko format berkas.
2. **CL_TYPE karier aktif user** dan posisi timnya (`p`) — baca dari slot hasil dekripsi pertama.
3. **Nama pasti sub-field rekor `+1..+3`** — bandingkan satu berkas sebelum/sesudah satu pertandingan liga yang hasilnya diketahui.
4. Isi blok pendamping 252/960 byte (jadwal & hasil per tim) bila editor kelak ingin mengedit jadwal, bukan hanya klasemen.

---

## 4. Kesimpulan — tabel alamat/offset final

### 4.1 Alamat fungsi (VA di `libHQRenderLib.so` build ini)

| Fungsi | VA |
|---|---|
| `CTeam::ApplyGameDifficultyToPlayerDataBase(_PlayerDataBase*)` | `0x4289d8` |
| `CTeam::LoadTeamAndPlayerStatisticInfo(int)` — pemanggil tunggalnya | `0x428ec8` (panggilan di `0x428f4c`) |
| `CTeam::LoadPlayerDataBase(int, _PlayerDataBase*)` | `0x4287f4` |
| `CTeam::LoadPlayerDataBaseOneTeam(int, _PlayerDataBase*)` | `0x4288e4` |
| `CTeam::LoadTeamInfo(int, _TeamDataBase*)` | `0x4286ec` |
| `CTeam::BackupPlayerAbility()` / `IncPlayerAbility(int,int)` / `RestorePlayerAbility(int)` | `0x428b60` / `0x428fc8` / `0x4290e0` |
| `CGame::GetPlayerDBName()` / `UpdatePlayerAge(_PlayerDataBase*, int)` | `0x33dd48` / `0x33dd90` |
| `CDevice::NewMatch(AI_TYPE, bool)` | `0x3f4d08` |
| `CCupAndLeague::Save(_ConfigData*)` / `Load(_ConfigData*)` | `0x3d3b80` / `0x3d3a7c` |
| `CCupAndLeague::SaveCupLeague(void*)` / `LoadCupLeague(void*)` | `0x3d03c4` / `0x3cfc0c` |
| `CCupAndLeague::UpdateSaveToInfo(CupAndLeagueSave*)` / `SortCLTeam()` / `GetWinLose(int)` | `0x3d358c` / `0x3d2994` / `0x3d2260` |
| `CGame::SaveSetting()` / `GetSetting()` / `CompareAESKey(_ConfigDataSave*)` / `IsCLSaveExit(int)` | `0x33cf30` / `0x33b9b4` / `0x33d5ec` / `0x33dcf8` |
| `CAES::Cipher(void*, int)` (ECB per blok) | `0x353b8c` |
| `CLZMAFileManager::Open/FindRecord/ComputeHash` | `0x2b8740` / `0x2b882c` / `0x2b8890` |

### 4.2 Rumus modifikasi aman

**(a) Hook pelemah AI** — hook `0x4289d8`; hanya bila `[[CTeam+0xe0f8] + [CTeam+0xe10c]*4 + 0x58] == 0` (tim CPU, persis gerbang asli): skala byte `{+0x32, +0x33, +0x35, +0x37, +0x3a}` record `x1` dengan slider user, jepit 1–99, **jangan** jalankan badan asli sesudahnya. Tim manusia & mode vs manusia: no-op total.

**(b) Atribut maks tim sendiri** — tim manusia: tulis 99 ke seluruh blok ability pada array DB (`CTeam+0x34d + i*0x50 + 0x32..0x3a`) **dan** array ability kerja (`CTeam+0x290 + i*9 + idx`, pemetaan idx di §2.3), untuk i = 0..20; atau lakukan di titik hook §(a) sebelum `BackupPlayerAbility` berjalan. Rentang sah mesin: 1–99. Tidak ada atribut spin/curve untuk dinaikkan.

**(c) Editor simpanan** — berkas `/data/data/com.touchtao.soccerkinggoogle/ws14.sav` (0x2058 byte): kunci AES-128 di `+0x00`, checksum djb-33 (seed `0x1505`) di `+0x10` atas payload terang `0x14..0x2047`, payload AES-128-ECB di `+0x14`. **Poin liga tim ke-`p` pada karier tipe `t`: offset payload `0x136 + t*0x255 + 6*p`** (GD di +4, GF di +5 dari awal rekor yang sama). Selalu verifikasi checksum hasil dekripsi sebelum menulis, dan tulis ulang checksum setelah mengedit.

---

### Lampiran — bukti ekstraksi data

- `res_all.pak`: N=673; `PlayerDB2022_En.dat` record indeks #30 (hash `0x736550fa` atas `res\res\data\playerdb2022_en.dat`), blob 52.688 → 211.680 byte; `TeamDB2022_En.dat` blob → 7.312 byte (header u32 = 126).
- Sampel record 0: tim 0, pemain 0 (kiper Austria), nama `Bachman` di `+0x02`, nama tim `Austria` di `+0x22`, ability `+0x32..+0x3a` = heks `1c 19 1d 48 25 24 43 47 43` = desimal `[28, 25, 29, 72, 37, 36, 67, 71, 67]` (pola kiper: `+0x3a` tinggi 67, `+0x32/+0x33` rendah), tinggi/berat `191/81`, byte umur berkas `+0x40/+0x41 = 20/202` (runtime: umur `230−202 = 28`).
- Statistik kolom ability dihitung atas seluruh 2.646 record (min/maks di §2.3); rata-rata per kelompok posisi dihitung dari indeks skuad `+0x01` (0 = kiper utama, 11 = kiper cadangan, 9–10 = penyerang).
