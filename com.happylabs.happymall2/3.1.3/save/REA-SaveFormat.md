# REA — Happy Mall Story: Sim Game — format save + decryptor

`com.happylabs.happymall2` v3.1.3 (versionCode 23). Lanjutan dari REA 7 Nov 2026
(`arm64-v8a/REPORT.md` — engine custom C++, offline penuh, save lokal).
Pekerjaan 27 Nov 2026: membedah `ProcessSaveFile`, membuktikan format save
sampai round-trip byte-identik, memetakan `CPlayerData`, dan mendecrypt satu
save asli pengguna (`save_0.dat`, 964 byte).

Sumber yang dianalisis 27 Nov: XAPK APKPure `HappyMall_3.1.3` (27.073.412 byte,
SHA-256 `d09d000d…2a41280`), varian **armeabi-v7a** (32-bit ARM; tidak ada
varian arm64 di APKPure). `base.apk` di dalamnya identik dengan build yang
di-REA 7 Nov (23.609.272 byte, `classes.dex` 6.662.760 byte), dan simbol kunci
terverifikasi juga ada di `libhappymall.so` armeabi-v7a
(`ProcessSaveFile` @ `0x201641`, `CPlayerData::GetCoins` @ `0x200c2d`,
`GetDiamonds` @ `0x200c11`, `LoadGame` @ `0x2012f9`, `SaveGame` @ `0x20133d`,
`CAccountData::SaveGame` @ `0x1fd111` / `LoadGame` @ `0x1fd2b9`).
Analisis statis saja — APK tidak diinstal/dijalankan.

> **Privasi:** nilai konkret dari save pengguna TIDAK dimuat di laporan ini.
> Yang dipublikasikan hanya format, offset field, dan cara membuktikan label.
> File save asli + hasil decrypt JSON-nya hanya ada lokal di mesin analisis.

## 1. Format file save (versi 3) — TERBUKTI

`ProcessSaveFile(unsigned char**, unsigned int*, unsigned char const*,
unsigned int)` @ `0x30edc4` (arm64) / `0x201641` (armv7).
File = header + payload terkompresi, keduanya di-XOR per-word 32-bit.

| Offset | Isi |
|---|---|
| `[0x00]` int32 | versi file: `2` atau `3` (`w8 & ~1 == 2`). File pengguna = `3`. |
| `[0x04]` uint32 | **kunci XOR 32-bit, tersimpan PLAINTEXT di file** (bukan secret hardcoded — dibaca dari file saat load; tiap save bisa beda). |
| `[0x08..0x98)` | field header, di-XOR per-word dengan kunci di atas. |
| `[0x98..]` | payload: data terkompresi **zlib level 1**, di-XOR per-word dengan kunci yang sama (alignment dimulai dari awal payload). |

Header v3 (152 byte = `0x98`, setelah di-XOR):

| Offset | Isi |
|---|---|
| `[0x08]` int32 | belum terpetakan (nilai pada save contoh: 491). |
| `[0x0C..0x17]` | nol (reserved?). |
| `[0x18..0x37]` | **SHA-256 dari data hasil dekompresi** (32 byte, ikut di-XOR). Bukan HMAC — hash biasa, bisa dihitung ulang. |
| `[0x38..0x77]` | 8× int64: **ujung kumulatif section** dalam koordinat (header+payload); entri terakhir = ukuran data hasil dekompresi. Pada save contoh: `[152, 376, 916, 988, 3424, 3616, 3692, 3556]`. |
| `[0x78..0x97]` | 32 byte nol (reserved?). |
| `[0x70]` int32 | ukuran data hasil dekompresi (= entri terakhir tabel di atas; dibaca `ProcessSaveFile` sebagai ukuran target uncompress). |

Varian **versi 2** (masih didukung load; dimigrasi ke v3 saat load, `0x30f03c`):
header 120 byte (`0x78`), ukuran di `[0x54]`, SHA-256 di `[0x14..0x33]`,
payload di `[0x78]`.

Urutan load (`ProcessSaveFile`): cek ukuran file ≥ header → cek versi →
XOR seluruh file dari offset 8 (NEON, 8 word per iterasi) → nol-kan field kunci
di buffer → alokasi `ukuran + header` → `uncompress` → cocokkan panjang hasil
dengan `[0x70]` → hitung SHA-256 hasil dekompresi → cocokkan dengan `[0x18]`.
Gagal di satu langkah mana pun → load gagal (return 0). Tidak ada cek server.

### Bukti round-trip (save asli pengguna, 964 byte)

- XOR payload dengan kunci dari `[0x04]` → `zlib.decompress` → **3556 byte**,
  cocok dengan `[0x70]`; `SHA-256` hasil dekompresi **cocok** dengan `[0x18]`.
- Kompresi ulang data hasil decrypt dengan `zlib.compress(data, 1)` →
  **byte-identik** dengan payload asli (level kompresi game = 1).
- Re-enkripsi penuh (header dibangun ulang + SHA-256 dihitung ulang) →
  **byte-identik dengan file asli** (SHA-256 file sama).
- Uji edit: ubah coins di blob → re-enkripsi → decrypt lagi → nilai baru
  terbaca, field lain tidak berubah, ukuran file tetap.

## 2. Struktur data hasil dekompresi — 7 section

Data 3556 byte terbagi 7 section (batas dari tabel header − 152):

| # | Blob | Ukuran | Awal |
|---|---|---|---|
| 0 | `[0, 224)` | 224 | `CPlayerData` — TERBUKTI (lihat §3). Awal: int32 versi `1`. |
| 1 | `[224, 764)` | 540 | versi `1`, lalu `87, 3, 1, 1, …` — kelas belum terpetakan. |
| 2 | `[764, 836)` | 72 | versi `1`, lalu `2`, … — kelas belum terpetakan. |
| 3 | `[836, 3272)` | 2436 | versi `1`, lalu nilai float (koordinat?) — diduga data map/shop, BELUM terbukti. |
| 4 | `[3272, 3464)` | 192 | versi `1`, sisanya nol. Ukurannya sama dengan `CTourData::GetSaveDataSize()` (`0xC0`) — petunjuk saja, BELUM terbukti. |
| 5 | `[3464, 3540)` | 76 | versi **`2`**, lalu `0, 1, 1, …`, ekor `3, 1, -1.0f` — kelas belum terpetakan. |
| 6 | `[3540, 3556)` | 16 | tag ASCII `TVNI1001` + 8 byte nol — arti belum terpetakan. |

Setiap section diawali int32 versi. Pemetaan section 1–6 ke kelas C++ belum
ditelusuri (pemanggil `LoadData` lewat vtable, tidak ada `BL` langsung).
Jangan menebak arti section dari ukuran nilainya saja.

File terpisah: `CAccountData` (296 byte, `0x128`) TIDAK ada di save ini —
disimpan di file sendiri `acct.bin` (`CAccountData::SaveGame` @ `0x308d10`,
`LoadGame` @ `0x308f10`, helper file `0x3af0e0`/`0x3af100`).

## 3. `CPlayerData` — peta field TERBUKTI (code trace)

Blok 224 byte (`GetSaveDataSize()` = `0xE0`), dimuat `LoadGame` @ `0x30e918`
(copy 224 byte ke struct global; word pertama harus `== 1`). Offset relatif
ke awal blok; bukti = nama getter/setter di `libhappymall.so` (arm64).

| Offset | Tipe | Field (bukti) |
|---|---|---|
| `+0x00` | int32 | versi blok = `1` (dicek `LoadGame`) |
| `+0x04` | int32 | coins (ter-XOR) — `GetCoins`/`AdjCoin`: coins = `[+0x04] XOR [+0x70]` |
| `+0x08` | int32 | diamonds (ter-XOR) — `GetDiamonds`/`AdjDiamond`: diamonds = `[+0x08] XOR [+0x74]` |
| `+0x0C` | byte | BGM enabled (`IsBGMEnabled`/`SetBGMEnabled`) |
| `+0x0D` | byte | SE enabled (`IsSEEnabled`/`SetSEEnabled`) |
| `+0x0E` | byte | advertisements removed (`IsAdvertisementRemoved`/`RemoveAdvertisements`) |
| `+0x10` | int32 | language (`GetLanguage`/`SetLanguage`) |
| `+0x18` | int32 | max worker count (`GetMaxWorker`, `GetNewWorkerDiamondCost` = `(n-1)*250`) |
| `+0x1C` | char[64] | nama pemain (`GetName` return struct+`0x1C`; `SetName` copy ≤ 64 byte) |
| `+0x5C` | int32 | avatar ID (`GetAvatarID`/`SetAvatarID`) |
| `+0x60` | int32 | donated coins (`GetDonatedCoinNum`/`AdjDonatedCoinNum`) |
| `+0x64` | int32 | tutorial step (`GetTutorialStep`/`UpdateTutorialStep`/`HasTutorialEnded`) |
| `+0x68` | byte | **fraud flag** (`IsFraudulent`; setter menulis `1` bila validasi gagal; bila set, `GetCoins`/`GetDiamonds` return `0`) |
| `+0x69` | byte | notifications enabled (`IsNotificationsEnabled`) |
| `+0x6A` | byte | tourist clicking enabled (`IsTouristClickingEnabled`) |
| `+0x6C` | int32 | play time lapsed, detik (`GetPlayTimeLapsed`/`IncrementPlayTime`/`ClearPlayTime`) |
| `+0x70` | int32 | mask XOR coins (diacak ulang tiap `AdjCoin` via `0x3a8ca0`) |
| `+0x74` | int32 | mask XOR diamonds (diacak ulang tiap `AdjDiamond`) |
| `+0x78` | byte | large status bar (`IsLargeStatusBarEnable`) |
| `+0x79` | byte | multi-story visit disabled (`IsMultiStoryVisitDisabled`) |
| `+0x7A` | byte | subscription active (`IsSubscriptionActive`) |
| `+0x7C` | int32 | house ad fetch time (`GetHouseAdFetchTime`) |
| `+0xE0` | int32 | building display type (`GetBuildingDisplayType`) — **di luar blok save** (runtime-only; `LoadGame` me-nol-kan). |

### Obfuscation coins/diamonds (bukan enkripsi)

`AdjCoin(delta)`: `coins = [0x04] XOR [0x70]` → tambah delta (tolak bila
negatif) → tulis hasil polos ke `[0x04]` sementara → ambil angka acak baru →
simpan ke `[0x70]` → simpan `coins XOR acak` ke `[0x04]`. `AdjDiamond` sama
dengan `[0x08]`/`[0x74]`. Sebelum tulis, ada panggilan validasi `0x3ae8f0`
(gagal → fraud flag `[0x68] = 1`, tulis dibatalkan). Jadi mengedit coins
yang benar = tulis `nilai_baru XOR mask` ke `[0x04]` (atau ganti keduanya
konsisten) — jangan tulis nilai polos ke `[0x04]` tanpa menyesuaikan mask.

## 4. Decryptor

`happymall_decrypt.py` (Python 3, stdlib saja) di folder ini:

```
python3 happymall_decrypt.py save.dat [-o plain.bin] [--json player.json]
python3 happymall_decrypt.py save.dat --encrypt-back out.dat   # cek round-trip
```

Membaca kunci dari file itu sendiri (tidak ada kunci hardcoded), verifikasi
SHA-256, parse `CPlayerData` ke JSON. **Jangan masukkan save asli pengguna
ke repo publik** — tool ini untuk analisis lokal.

## 5. Catatan scope (dari REA 7 Nov, tetap berlaku)

- Game single-player offline; semua state gameplay lokal. Satu-satunya produk
  Play Billing = subscription bulanan `com.happylabs.happymall.monthly`.
- Gold = mata uang gameplay lokal. Diamond = mata uang premium (terikat
  pembelian/subscription) — edit Diamond/subscription = bypass IAP, di luar
  scope yang didukung (lihat verdict `arm64-v8a/REPORT.md` §8).
- Tidak ada deteksi root/emulator di jalur save; proteksi save hanya XOR +
  SHA-256 di atas (keduanya bisa dihitung ulang offline).
- Batasan: section 1–6 belum dipetakan ke kelas; field header `[0x08]` belum
  teridentifikasi; perilaku migrasi v2→v3 hanya dibaca dari disassembly
  (tidak diuji dengan file v2 asli); tanpa runtime, arti `TVNI1001` dan
  section 5 (versi 2) belum diketahui.
