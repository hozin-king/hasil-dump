# FINDINGS-save.md — Mekanisme Save Data Cinta di Citampi 1.87.5

## Ringkasan
Save offline Citampi Stories adalah **JSON UTF-8 yang dienkripsi AES-256-CBC (PKCS7)**,
dengan **kunci + IV acak per file** yang disimpan di dalam header file itu sendiri
(dipermutasi). **Tidak ada kunci hardcoded di APK.**

Format file `.sav`:

| Offset | Isi |
|---|---|
| `[0]` | `dictSeed` — selalu `0xff` (255) pada save yang ditulis game |
| `[1..48]` | 48 byte header = IV (16 B) + Key (32 B), dipermutasi |
| `[49..]` | Ciphertext AES-256-CBC, PKCS7 — plaintext = JSON UTF-8 |

Ukuran terverifikasi: `save00` 81.441 B → plaintext 81.382 B (81.392 = 16×5087);
`save09` 81.505 B → plaintext 81.440 B (81.456 = 16×5091).

## Kelas-kelas kunci (dari Il2CppDumper, `dump.cs`)
- `Ikaan.Utility.IkaanDataFormat` (TypeDefIndex 1285, static):
  - `Encode(byte[] input, byte dictSeed, byte[] iv, byte[] key)` — RVA `0x24816E4`
  - `Decode(byte[] input)` — RVA `0x2481FF0`
  - `Decode(byte[] input, out Nullable<byte> seed)` — RVA `0x2482008`
  - `_getIndiciesMap(int dictSeed)` — RVA `0x2481E40` (private)
- `saveObject` (TypeDefIndex 376): `{ string key; string value; }` — satu entri save.
- `saveHelper` (TypeDefIndex 579, static):
  - `loadSavegameFromFile` — RVA `0x2316D5C`
  - `checkTampering(string deviceIDFromSavegame)` — RVA `0x2317A48`
  - `GetOfflineSlotFilePath` — RVA `0x2322798`
  - `TryReadOfflineSlotFileStandalone` — RVA `0x2322E60`
  - `TryWriteOfflineSlotFile` — RVA `0x23234AC`
  - `fileCorrupted` — RVA `0x231ADE8`
  - `AutosaveSlotIndex = 9` (autosave hanya menulis `save09.sav`); literal
    `save09.sav` (0x55138F0), `.sav` (0x54E6CC0).

Jalur baca: `GetOfflineSlotFilePath(slot)` → `File.Exists` →
`File.ReadAllBytes` → `IkaanDataFormat.Decode` → `Encoding.Default.GetString` →
`JsonConvert.DeserializeObject<object>` → `List<saveObject>`.

Jalur tulis: `JsonConvert.SerializeObject` → `Encoding.UTF8.GetBytes` →
`Encode(utf8bytes, 0xff, null, null)` → `File.WriteAllBytes`. `iv`/`key` null →
`AesManaged.GenerateIV()` / `GenerateKey()` acak per save.

## Permutasi header (`_getIndiciesMap`)
`System.Random(dictSeed)` → 16 integer DISTINCT dalam 1..47 (0 dikecualikan,
duplikat di-retry: `v = (int)(rand.NextDouble() * 48.0)`), lalu di-Sort ascending.
Posisi (1-based, dalam 48 byte header) yang ada di map → byte IV; sisanya → byte
Key. Decode dan Encode simetris (Encode: `header[0] = seed`; loop posisi 1..48,
cocok → IV, tidak → Key; lalu header + ciphertext digabung).

Untuk `dictSeed = 0xff`, map (sorted) = posisi IV di header. Nilai map dapat
dihitung ulang dari seed saja — tidak ada rahasia di sini.

## Replikasi `System.Random` (.NET) — jebakan
Implementasi `System.Random` di game ini (IL2CPP, RVA ctor `0x4442358`,
`InternalSample` RVA `0x4442514`) **bukan** varian .NET Framework klasik:

- `SeedArray[55] = 161803398 - |seed|` (BUKAN `SeedArray[0]`)
- loop shuffle berjalan **54 iterasi** (`i = 1..54`), sehingga `SeedArray[0]` tetap 0
- fase kedua klasik (`SeedArray[k] -= SeedArray[1 + (k+30)%55]`, 4 pass, `k = 1..55`)
- `inext = 0`, `inextp = 21`; `InternalSample` klasik (wrap ke 1 saat ≥ 56)

Varian klasik (SeedArray[0], 55 iterasi) menghasilkan nilai yang SALAH mulai
dari sample ke-3. Varian di atas diverifikasi **10/10 nilai sama** dengan program
referensi `new Random(255)` di .NET 8, dan cocok dengan disassembly ctor
`System.Random` di `libil2cpp.so`. Detail disassembly: `dump/dis_Random_ctor.txt`,
`dump/dis_Random_InternalSample.txt`.

## Hasil decrypt (terverifikasi)
Decryptor: `citampi_decrypt.py` (di folder ini — reimplementasi .NET Random +
de-permutasi + AES-256-CBC + PKCS7 unpad; **tanpa kunci hardcoded**).

- `save00_0_sgx4.sav` (81.441 B) → JSON valid, top-level `List<saveObject>`,
  **376 entri** `{key, value}`, plaintext 81.382 B.
- `save09_1_74mu.sav` (81.505 B) → JSON valid, **377 entri**, plaintext 81.440 B.
- Struktur key (nama saja, tanpa nilai): `MONEY`, `BANK_MONEY_SAVING`,
  `FURNITURE_LEVEL`, `COOKING_LEVEL`, `MANAGEMENT_SKILL`, `MANAGEMENT_SKILL_XP`,
  `WIFE_PREGNANTLEVEL`, `CHILD_GROWTHLEVEL`, `WIFEROOM_LEVEL`,
  `PLAYER_SUSPCIOUS_LEVEL`, `BABY_ROOMREQLEVEL`, `ADSIAP`, `WIAP_20..22`,
  `GOJIAP`, `GOArea01IAP..GOArea06IAP`, `GOIndomarketIAP`, `GOOmegamartIAP`,
  `GOTokoMebelIAP`, `GOJoysteakIAP`, `GOWarungGanormalIAP`, `GOCinemakIAP`,
  `GOKlinikIAP`, `GOGymIAP`, `GODistroIAP`, `GOWarnetIAP`, `GOTokoSepedaIAP`,
  `GORecycleManIAP`, `GOKeefsiIAP`, `GOMekdiIAP`, … (376/377 entri; kedua file
  punya set key yang sama, save09 punya 1 duplikat key).
- Nilai `value` bertipe string atau null. **Isi nilai save user tidak disertakan
  di laporan/repo ini.**

## Anti-tamper / validasi server
- Lokal: `saveHelper.checkTampering(deviceIDFromSavegame)`; string literal:
  `" was tampered! We won't merge CGdata and IAP values with this save slot"`,
  `"Invalid magic number in saved data"`, `"Invalid data file (cannot read zip)..."`.
- Server (lihat FINDINGS-native.md / REPORT.md untuk endpoint): `saveHelper`
  menyimpan `dictSuspiciousState`, `bannedOnlineSaveIds`, konstanta
  `BannedServerMessage = "Player is banned"`, dan memanggil endpoint
  `/saveGame/upload`, `/saveGame/downloadSuspiciousState`, `/comparingValues/`,
  `/validate_buildhash`, `/validate_newlootboy`. Artinya nilai save online
  dibandingkan dengan server dan pemain yang ketahuan curang bisa di-ban.
  **Save offline bisa di-decrypt/di-edit secara lokal, tetapi sinkronisasi
  online + validasi server dapat menolak/menandai save yang diubah.**
- Online save: `saveHelper._downloadUri` / `_uploadUri` / `_deleteSaveUri` →
  `https://api.ikaanstudio.com/saveGame/...`; ada dukungan slot UniPin
  (`onUniPinSlotCompleteEvent`, `UniPinUnClaimStatus`).

## Catatan
- Disassembly fungsi save: `dump/dis_TryReadOfflineSlotFile.txt`,
  `dump/dis_TryWriteOfflineSlotFile.txt`, `dump/dis_Decode.txt`,
  `dump/dis_Decode2.txt`, `dump/dis_Encode.txt`, `dump/dis_getIndiciesMap.txt`.
- Token/il2cpp terkait save & kripto: `dump/tokens-save.txt`,
  `dump/tokens-crypto.txt`.
