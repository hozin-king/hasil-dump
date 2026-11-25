# FINDINGS — Format Save Game (Food Truck City 1.2.15 / code 35)

## 1. Mekanisme (sama seperti Tahu Bulat)

- Save memakai **OwnSaveData** (framework Own Engine, `libownengine.so`).
- Cipher: **DES/ECB/PKCS5Padding**, key 8 byte (diambil dari string key
  tiap file). Mekanisme identik Tahu Bulat 15.21.0.
- File di disk = **nama file + `"data"`** — karena Java `OwnSaveData.save()`
  menulis ke `fileName + "data"`. Contoh: file `Data` → `Datadata`;
  `Config` → `Configdata`.
- Sufiks export (`_1_hjdc`) + ekstensi `.bin` pada file kiriman user
  **bukan** dari kode game (kemungkinan jalur export/backup, sama seperti
  sufiks `_0_cio0` + `.owndata` di Tahu Bulat).

## 2. Empat file save

| File (di disk) | Dibangun di | Key |
|---|---|---|
| `Configdata` | `libnative-lib.so` BL 0xdc7f8 | key DES sendiri |
| `Datadata` | `libnative-lib.so` BL 0xdd7c4 | key DES sendiri |
| `Achievementdata` | `libnative-lib.so` BL 0xe9334 | key DES sendiri (sama dengan Config) |
| `AnalyticDatadata` | `libnative-lib.so` BL 0xf019c | key DES sendiri |

Detail konstruksi (alamat + literal .rodata): lihat `FINDINGS-native.md` §3.
**Nilai key TIDAK dicantumkan di dump publik ini** (disimpan lokal saja).

## 3. Verifikasi decrypt — file save user `Datadata_1_hjdc.bin`

- File: **1.936 byte = tepat 242 blok × 8 byte**, entropi 7,324 bit/byte,
  tanpa magic bytes.
- Blok 8-byte berulang 47× berturut-turut di ekor (blok 194–240), blok
  terakhir berbeda — konsisten zero-fill + padding PKCS5 → **DES/ECB
  terkonfirmasi**.
- **Ke-17 key Tahu Bulat dicoba satu per satu — SEMUA GAGAL** (padding
  tidak valid, output tetap biner). Key game ini berbeda.
- Dengan key file `Data` yang ditemukan di `libnative-lib.so`:
  **decrypt BERHASIL → JSON valid, 39 top-level key.**
  Key lain (Config/Achievement/AnalyticData) terhadap file ini: gagal
  (sebagaimana mestinya — tiap file key-nya sendiri).

## 4. Isi save `Datadata` (hanya nama field — tanpa nilai)

39 top-level key (JSON valid, plaintext setelah decrypt):

`balonRevenueEnd`, `bonusTile`, `boosterRewardTakenDay0`,
`boosterRewardTakenDay1`, `boosterRewardTakenDay2`, `boxAdsCooldown`,
`buildingInventory` (list), `carPriceN` (list), `diamond`,
`doubleRewardEnd`, `exchangeBoostCarStored`, `exchangeBoostLevel`,
`exp`, `extraBox`, `freeAdsCarCooldown`, `gold`, `highestMobilLevel`,
`incomeBoostCarStored`, `incomeBoostLevel`, `lastRealTime`,
`lastSaveTime`, `level`, `lifetimeRevenue`, `maxMobilParkir`,
`maxMovingCar`, `mobil` (list 15), `offlineRevUpgradeLevel`,
`placedBuilding` (list), `playerName`, `playerProfPic`,
`priceBoostCarStored`, `priceDiscountLevel`, `speedUpgradeLevel`,
`spinnerCost`, `spinnerLeft`, `token`, `tutorial`, `tutorialKota`,
`unlockedProfPic` (list 192).

Mayoritas integer (mata uang, level, timer, upgrade); `mobil` =
daftar mobil; `buildingInventory`/`placedBuilding` = bangunan;
`unlockedProfPic` = 192 entri. Nilai save user TIDAK dicantumkan di sini.

## 5. Cloud save

`OwnGPGSManager::doSaveCloud/doLoadCloud` (libownengine.so) — game juga
punya jalur cloud save via Google Play Games. Tidak dianalisis lebih jauh
(butuh akun + runtime).

## 6. Catatan untuk Save Tool v1.2.0

- Aturan auto-deteksi yang diusulkan: nama file mengandung `Datadata`
  (case-insensitive, abaikan sufiks export + ekstensi) → Food Truck,
  key file `Data`; `walaidwjss2` → Tahu Bulat; nama tak dikenal →
  tolak fail-closed.
- File save hasil decrypt + key disimpan lokal di peneliti
  (`~/workspace/rea-foodtruck-decrypt/`), bukan di repo publik ini.
