# Audit Injector — Dr. Driving 1.73 (com.ansangha.drdriving)

- **Tanggal:** 18 Nov 2026
- **Dasar:** `~/workspace/rea-drdriving/REPORT.md` (REA statis DEX via jadx + apktool + smali)
- **Prinsip:** BOLEH hanya yang **terbukti lokal/solo**. DITOLAK: IAP/unlock
  berbayar, currency server-verified, manipulasi leaderboard, cheat
  multiplayer/online, bypass lisensi/Play Integrity.
- **Sifat game:** ekonomi & progres **100% lokal** (SharedPreferences JSON,
  backup Firestore mentah tanpa validasi). **TAPI game ini punya multiplayer
  online nyata** (Firebase RTDB) + leaderboard/achievement Play Games —
  dan keduanya client-authoritative. Garis audit: semua yang menyentuh
  lawan manusia, rating, atau papan skor = DITOLAK.

## Ringkasan klasifikasi

| Fitur | Status | Alasan singkat |
|---|---|---|
| Tambah Coin lokal | ✅ BOLEH | Mata uang hasil main, 100% lokal (`o.iCoin`) |
| Beli mobil coin (1–6) / unlock | ✅ BOLEH | Harga coin, lokal (`d.buyCar`, `bHasCar`) |
| Upgrade mobil maks (6 ability) | ✅ BOLEH | Dibayar Coin, lokal (`iUpgrade`, `iGetUpgradeCost`) |
| Repair gratis / damage 0 (no-damage lokal) | ✅ BOLEH | `iCarDamage` lokal, repair dibayar Coin |
| Bensin tak habis (fuel per-misi) | ✅ BOLEH | `l.g_fGasLeft` lokal, per-misi saja |
| Level/EXP pengemudi | ✅ BOLEH | `iDriverLevel`/`iDriverExp` lokal |
| Hadiah misi / skor misi (solo) | ✅ BOLEH, bersyarat | Lokal — **wajib matikan submit leaderboard** saat aktif |
| Balon hadiah coin | ✅ BOLEH | Hadiah coin lokal (`adBalloon`, `bCashItem=false`) |
| Tambah Gold gratis | ❌ DITOLAK | Gold = produk IAP berbayar (`drdriving.gold200/600/1500`) |
| Beli/unlock mobil gold (7–27) gratis | ❌ DITOLAK | Unlock berbayar (harga gold 10–500) |
| Tukar gold→coin gratis / coin dari gold | ❌ DITOLAK | Turunan dari gold IAP |
| Balon hadiah gold | ❌ DITOLAK | Gold = currency IAP |
| Auto-win / rating / win-lose multiplayer | ❌ DITOLAK | Melawan pemain sungguhan via Firebase RTDB |
| Kirim pesan multiplayer palsu (`P`/`U`/`O`/`A`) | ❌ DITOLAK | Spoofing lawan, rating, posisi ghost |
| Submit skor leaderboard (semua 11) | ❌ DITOLAK | Papan skor publik Play Games |
| Unlock achievement Play Games | ❌ DITOLAK | Achievement publik (`ach_multiwin*` dll.) |
| Bypass cek versi / RemoteConfig gate | ❌ DITOLAK | Gate update `verCode` 69 / `iAppVersion` |
| Hilangkan iklan (AdMob) | ❌ DITOLAK | Monetisasi developer; bukan fitur gameplay lokal |
| Bypass lisensi / Play Integrity | ❌ N/A-DITOLAK | Tidak ada mekanisme itu di game; bila muncul, tetap ditolak |

## BOLEH — detail & bukti lokal

### 1. Tambah Coin (`o.iCoin` / `o.iCoinC`)
- Bukti: `o.java` — `iCoin`/`iCoinC` field JSON lokal; semua penambah
  (`d.onMissionFinished`, `d.onSuccessMission`, `d.buyCoin`) hanya
  `iCoinC += n; iCoin += n`. Tidak ada server.
- Catatan: nilai tersimpan di-offset `DrDrivingActivity.rs` (acak 1–1000
  per proses). Injector harus menambah **kedua** field (`iCoin` dan
  `iCoinC`) secara konsisten, atau hook di titik tambah (mis. return
  `onSuccessMission`), agar save/load konsisten. Jangan edit JSON mentah
  tanpa memperhitungkan `rs`.
- Batas: hanya untuk pemakaian solo. Coin yang dipakai lalu menang
  multiplayer tetap tercatat di `iWin`/rating — itu urusan mode
  multiplayer (DITOLAK), bukan coin-nya.

### 2. Beli / unlock mobil coin — mobil 1–6
- Bukti: `d.buyCar(int)` — `iPrice < 0` ⇒ harga coin `(-iPrice)`:
  AYH 2.000, SH 2.000, ESDAS 5.000, JUNO 5.000, SHC 9.000, SJ 9.000
  (`tool/e.java carinfo`). `bHasCar[i3] = true` lokal.
- Mobil 0 (KOS) sudah dimiliki sejak awal.

### 3. Upgrade mobil maks
- Bukti: `d.java:2693` — upgrade dibayar **Coin**
  (`iCoin - rs >= iGetUpgradeCost`), 6 ability (`iUpgrade[car][0..5]`),
  level maks 10. `iAbility` memengaruhi performa (termasuk `ability[5]`
  untuk ketahanan tabrakan). Semua lokal.

### 4. No-damage / repair gratis
- Bukti: `iCarDamage[32]` lokal; damage = `0,05×jarak + drift` per misi +
  kecelakaan `300 + speed×3000/(ability[5]+10+upgrade[5])`, maks 9.000.
  Repair cost = `iRepairCost × clamp(damage,1000…9000)/40000` dibayar Coin
  (`d.iGetRepairCost`, smali `d.smali:4184`).
- Menahan `iCarDamage` di 0 atau memotong biaya repair = modifikasi lokal
  murni. **Tidak memengaruhi lawan** (damage tidak dikirim ke multiplayer).

### 5. Bensin tak habis
- Bukti: `l.g_fGasLeft` (init 500/misi, 100 untuk misi FUEL) hanya dipakai
  di dalam satu misi; tidak ada tangki persisten. Menahan `g_fGasLeft`
  (atau `g_fFuelConsume = 0`) hanya memengaruhi misi solo yang sedang jalan.
- Perhatian: skor misi FUEL = `gasLeft×150/gasInitial` — fuel tak habis
  otomatis memaksimalkan skor FUEL. Bila skor itu ikut ter-submit ke
  leaderboard `leaderboard_fuel`, itu pelanggaran leaderboard → injector
  **wajib menonaktifkan `SubmitHighScore` / `uploadMultiLeaderboard`**
  selama fitur ini aktif (lihat syarat § "BOLEH bersyarat").

### 6. Level / EXP pengemudi
- Bukti: `iDriverLevel`/`iDriverExp` lokal; kurva basis 4.096 ×1,25/level
  (`d.iGetBaseExpForLevel`). Tidak ada validasi server.

### 7. Hadiah misi / skor misi — BOLEH hanya solo, tanpa submit skor
- Bukti: `d.onSuccessMission` — `rewardCoin = max(25, skor×0,3 +
  jarak×0,01 + 7)`, lokal. `SubmitHighScore(missionType, skor)` dipanggil
  setelahnya ke Play Games.
- **Syarat wajib:** bila injector mengubah skor/hadiah misi, hook juga
  harus **memblokir `SubmitHighScore` dan `uploadMultiLeaderboard`**
  selama sesi modded, agar skor hasil mod tidak naik ke leaderboard
  publik. Tanpa pemblokiran itu, fitur ini menjadi DITOLAK.

### 8. Balon hadiah coin
- Bukti: `d.processAdBalloon` — balon ketuk → `iCoin += iAmount`
  (`bCashItem=false`). Lokal. (Varian `bCashItem=true` memberi gold →
  DITOLAK, lihat bawah.)

## DITOLAK — detail & bukti

### 1. Tambah Gold gratis — IAP bypass
- Bukti: satu-satunya sumber gold berbayar adalah SKU
  `drdriving.gold200` ($1,99), `drdriving.gold600` ($4,99),
  `drdriving.gold1500` ($9,99); grant lokal di `onConsumeResponse`
  (`iGold += n; iBoughtGold += n`). Fakta bahwa grant-nya lokal **tidak**
  membuatnya boleh — gold adalah produk berbayar dan `iBoughtGold`
  dilacak sebagai total pembelian. Memberi gold gratis = melewati pembayaran.
- Termasuk: tukar gold→coin tanpa bayar gold, balon hadiah gold
  (`bCashItem=true`), dan "gold tak habis".

### 2. Unlock mobil gold (7–27) gratis
- Bukti: `d.buyCar` — `iPrice > 0` ⇒ harga gold: JIO/BKS 100, RHS/YMJ 200,
  KEJ/ISHS 300, KAIST/JBU 400, MANE 500, KYUBIN–CHESS 10–80.
  Mobil-mobil ini adalah konten berbayar (gold). Unlock gratis = bypass pembelian.

### 3. Cheat multiplayer (Firebase RTDB) — DITOLAK PENUH
- Bukti: mode online nyata — matchmaking `Waiting/` → room `Gaming/{room}`,
  pesan `ToCreator`/`ToJoiner`, ghost lawan via `U`, profil lawan via `P`.
  **Semua** manipulasi berikut dilarang:
  - Auto-win / paksa `onMultiFinished(0/4)` saat online; kirim `O N`
    (pura-pura lawan gagal) atau tahan `O Y`.
  - Kirim rating palsu di `P`/`A` (rating dikirim client sendiri, tapi
    memalsukannya merugikan matchmaking lawan).
  - Kirim posisi ghost palsu `U`, seed lintasan palsu `I`, rematch palsu `A`.
  - Mengubah `iWin`/`iLose`/`iRating` lalu main online — angka-angka itu
    adalah rekor kompetitif yang dikirim ke lawan (`P` message) dan ke
    leaderboard `multirating`/`multiwin`.
  - **Catatan teknis:** meski penentuan menang/kalah & rating 100%
    client-side (`d.onMultiFinished`, Elo `Q.d.a`), itu **bukan** alasan
    untuk membolehkan — lawannya manusia sungguhan. Satu-satunya pemakaian
    yang sah: mode solo (gameMode ≠ 2/3) atau friendly match yang disepakati
    kedua belah pihak secara eksplisit — dan itu pun di luar cakupan
    injector ini; defaultnya injector **tidak boleh aktif saat
    `g_bMultiPlayStart` / `mMultiPlayer` true**.
- **Gate wajib di injector:** nonaktifkan semua hook saat `mMultiPlayer`
  atau `g_iGameMode ∈ {2,3}` (mode online), atau minimal saat `room != null`.

### 4. Manipulasi leaderboard Play Games (11 leaderboard)
- Bukti: `SubmitHighScore(missionType, skor)` + `uploadMultiLeaderboard`
  → `LeaderboardsClient.submitScore` (app id `943954155630`).
  Leaderboard: brake, drift, fuel, highway, lane, multirating, multiwin,
  parking, speed, truck, vip. Skor dari misi yang dimodifikasi **dilarang**
  di-submit. Lihat syarat di § BOLEH no. 7.

### 5. Unlock achievement Play Games
- Bukti: 32 achievement lokal (`tool/a` lists) — tiap unlock memanggil
  `DrDrivingActivity.unlockAchievements(achievementID)` →
  `AchievementsClient.unlock`. Termasuk `ach_multiwin1/10/100`.
  Mengatur `bAchievement[i]=true` secara lokal saja tidak berguna tanpa
  unlock Play Games-nya, dan unlock-nya adalah klaim publik → DITOLAK.

### 6. Bypass cek versi / RemoteConfig gate
- Bukti: `verCode = 69`; `R <verCode>` antar pemain; bila
  `iFBAppVersion (RemoteConfig) > verCode` → paksa update Play Store.
  Memalsukan `verCode`/versi untuk masuk room dengan versi tak cocok =
  bypass gate developer → DITOLAK.

### 7. Hilangkan iklan (AdMob)
- Tidak ada SKU remove-ads; iklan (banner/interstitial/rewarded) adalah
  monetisasi developer. Menghilangkan iklan bukan fitur gameplay lokal →
  DITOLAK.

### 8. Bypass lisensi / Play Integrity
- Tidak ditemukan mekanisme lisensi/Play Integrity di kode game 1.73.
  Bila muncul di versi lain, tetap DITOLAK. Tidak ada yang perlu di-bypass
  di versi ini.

## Catatan implementasi untuk subagent injector

- **Tidak ada `.so` game** — jangan pakai pendekatan Dobby/PLT-hook native.
  Jalur: hook DEX (LSPosed/Frida) pada method/field di REPORT.md §7,
  atau patch smali. Perhatikan R8: nama class 1 huruf, field/method
  harus dicocokkan dengan dump 1.73 ini.
- **Perangkap `rs`:** semua nilai coin/gold/win/lose/rating yang tersimpan
  di-offset `rs` (acak 1–1000 per proses). Edit field mentah harus
  konsisten antara `iCoin`↔`iCoinC`, `iGold`↔`iGoldC`, atau lakukan
  perubahan lewat method tambah (mis. `onSuccessMission`) agar konsisten.
- **Gate online wajib:** matikan semua hook saat multiplayer aktif
  (`mMultiPlayer == true` / `room != null` / `g_iGameMode` 2 atau 3).
- **Gate leaderboard wajib:** bila skor/hadiah misi dimodifikasi, blokir
  `SubmitHighScore` + `uploadMultiLeaderboard` selama sesi itu.
- **Jangan sentuh:** kode billing (`onConsumeResponse`, SKU), pesan
  multiplayer (`onRealTimeMessageReceived`, `sendMessage`, `sendGameOver`),
  `saveToCloud` (Firestore `Users/{myID}`), dan segala yang mengirim
  rating/skor keluar perangkat.
- Save adalah JSON SharedPreferences key `"game"` — injector berbasis
  edit-save (bukan runtime hook) juga mungkin, dengan catatan offset `rs`.
