# Mekanisme Driver Tembus (Filter) — Hill Climb Racing 1

**Konteks:** toggle "Driver Tembus" (💨) di Hozin HCR Mod v1.10/v1.10.1. Dicatat
17 Nov 2026 20:17 WIB atas pertanyaan user ("yang diubah itu offset atau class-nya?"),
dari kode payload `~/workspace/hozin-hcr-mod/app/src/main/cpp/payload/`
(`patterns.h`, `head_match.h`, `payload.cpp`) + hasil tes POCO v1.10.1.

## Jawaban singkat

**BUKAN patch kode di offset tetap** seperti God Mode (yang me-NOP instruksi di
alamat tetap, mis. v4: `0x3b0ddc`/`0x3ad494`/`0x4eff98`). Yang diubah adalah
**DATA hidup**: field filter (`categoryBits` / `maskBits` / `groupIndex`) di
dalam objek fixture Box2D driver (`b2Fixture`), lewat fungsi `SetFilterData`
**milik game sendiri**. Jadi: objeknya ditemukan lewat **offset struct**, tapi
yang diubah adalah **nilai field di dalam objek itu** — bukan kodenya.

## Yang diubah, persisnya

- **Fungsi yang dipakai:** `b2Fixture::SetFilterData(fixture, filter)` milik game.
  Dicari via pattern-scan 20 byte (UNIK, 1 hit, byte ke-20 IDENTIK di kedua versi):
  - 1.72.2: `0x6d0f64`
  - 1.71.1: `0x6c05c0`
  - Fungsi ini punya 82 caller dan tail-call `Refilter` — kontak LAMA yang
    melibatkan fixture ikut dihitung ulang.
- **Nilai baru:** filter `{categoryBits=32, maskBits=0, groupIndex=0}`.
  `maskBits = 0` artinya fixture itu **tidak bertabrakan dengan apa pun** —
  kepala dan badan driver menembus tanah, bukan menyentuhnya.
- **Nilai asli disimpan untuk restore** saat toggle dimatikan:
  `{32, 63430, 0}` (kepala Jeep: `cat=32`, `mask=63430`).

## Bagaimana fixture driver ditemukan

- **Offset struct mobil** (`PlayerCar`): `[car+0x2d0]` = body kepala,
  `[car+0x2d8]` = body chassis (badan utama). Dari body-body ini, semua fixture
  driver di-walk.
- **Pencocokan kepala** (`head_match.h`): fixture kepala dikenali dari
  radius **0,3014** + `cat=32` + `mask=63430` (skor 15, tertinggi). Sensor
  (chassisBack dkk: `cat=0 mask=0`) diberi skor negatif dan dilewati; filter
  sampah (`cat`/`mask` > 0xFFFF) ditolak.
- **Pengaman (v1.10.1):** pointer divalidasi via `/proc/self/maps` (cache 2 dtk)
  + span + alignment + kewarasan nilai SEBELUM deref/`SetFilterData`/tulis
  radius; toggle hanya diterapkan bila car ter-resolve + ≥1 fixture live
  (bila tidak: status "pending" + panel "tunggu run dimulai").

## Yang TIDAK disentuh Filter

- **Flag kematian `[PlayerCar+0x32f]` dan death timer `[run+0x62c]` tidak
  disentuh** — itu urusan God Mode (patch kode). Karena itu Filter saja TIDAK
  mencegah semua kematian: dengan God OFF, jalur mati lain (countdown
  `[run+0x630]`/`[run+0x634]`, setter flag lain) tetap bisa mematikan driver.

## Bukti lapangan (tes POCO v1.10.1, 17 Nov 2026 20:14 WIB)

- Filter ON + God sengaja OFF → run **15065m**, **165x BACK FLIP**, **0x NECK
  FLIP**, +6.093.240 koin, +23 gems, lalu DRIVER DOWN (diharapkan, God OFF).
  **Tidak crash** — ini tujuan utama v1.10.1 (v1.10 crash saat toggle ditekan).
- Kesimpulan: Filter bekerja — kepala menembus tanah tanpa pernah memicu
  neck flip, dalam run penuh backflip sejauh 15 km.

## Perbandingan dengan toggle driver lain (REA-3)

| Toggle | Mekanisme | Sifat |
|---|---|---|
| Driver Tembus (Filter) | Ubah filter fixture via `SetFilterData` game | Data hidup, reversibel (restore filter asli) |
| Hapus Driver | Null `[car+0x2d0]` | Data hidup; dikunci keras di v1.10.1 (tolak bila God OFF, pointer dikembalikan bila God dimatikan) |
| Driver Sembunyi (Pindah) | Teleport kepala tiap frame | Data hidup; validasi body kepala tiap frame |
| Driver Mungil (Shrink) | Tulis radius fixture 0,3014 → 0,001 | Data hidup |

Keempatnya adalah perubahan **data runtime**, bukan patch kode — berbeda dari
God Mode v4/v5/v6 yang menambal instruksi di offset tetap.
