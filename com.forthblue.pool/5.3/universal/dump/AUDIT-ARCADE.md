# AUDIT — Mode Arcade & "Level Tambahan" Pool Billiards Pro 5.3
### Bisakah garis prediksi penuh, long line, dan Auto Play/perencana AI mod berlaku di Arcade?

- **Tanggal audit:** 22 Okt 2026 — audit murni (read-only), tidak ada kode mod yang diubah.
- **Sumber bukti:** `~/workspace/rea-poolbilliards/REPORT.md` (REA 22 Okt 2026); smali hasil apktool di `~/workspace/hozin-poolbilliards-mod/work/apk/smali/com/forthblue/pool/…`; aset `~/workspace/rea-poolbilliards/work/extracted/assets/data/level_stage_*.txt` (dihitung ulang dengan skrip); kode mod saat ini di `~/workspace/hozin-poolbilliards-mod/mod-src/com/hozin/poolmod/`.
- **Vonis ringkas:** Arcade memakai `PoolTable`, `GameScene`, dan pintu tembak `PoolTable.click()` yang **sama persis** dengan mode lain → prediksi penuh & long line berlaku apa adanya, dan Auto Play **bisa** berlaku. Tetapi fungsi objektif perencana saat ini (aturan 8-ball) **salah untuk Arcade**: Arcade tidak mengenal grup bola/foul 8-ball, melainkan permainan "habiskan semua bola sebelum meteran tembakan (`restTime`, mulai 6) habis", dengan lubang spesial (lubang hitam −2, lubang +cue +1, lubang −bola). Perencana perlu mode-objektif khusus Arcade (daftar persis di §4).

---

## 1. Inventaris mode & struktur level

### Mode game (dari kelas aturan, REPORT §2–§3)

| Mode | Kelas aturan | Sifat |
|---|---|---|
| VS Computer 8-ball / 9-ball | `rules/Vsai8Ball`, `rules/Vsai9Ball` (induk `VsaiRuleBase`) | Offline, AI lokal |
| Time 1P 8-ball / 9-ball | `rules/Time8Ball1P`, `rules/Time9Ball1P` (`TimeRuleBase`) | Offline |
| **Arcade / Stage** | **`rules/LevelRule` + `LevelManager`** | **Offline, sendirian** |
| Tutorial | `rules/TutorialRule` | Offline |
| PvP online | `rules/PVP8Ball` | Online (TCP `pool.galaxyaura.com:5678`) |

### Struktur level Arcade (bukti: `LevelManager.loadData`, `LevelRule.init`, hitung ulang aset)

- Data level = **7 berkas teks polos** `assets/data/level_stage_0.txt` … `level_stage_6.txt` (stage 0–6), masing-masing **30 baris = 30 level** → **total 210 level**. `LevelManager.loadData(activity, level, stage)` membuka `data/level_stage_<stage>.txt` dan mengembalikan baris ke-`level` (smali `LevelManager.smali:44`); `Main.startGameInArcadeMode(stage, level)` (Main.smali:4301) lalu memanggil `LevelRule.init(stage, level, baris)`.
- **Format satu baris** (didekode dari `LevelRule.init`, LevelRule.smali:551): semua bilangan dipisah spasi —
  `ballCount blackHoleCount blackHoleId[blackHoleCount] lalu per bola: textureId x y`.
  Bola pertama selalu texture 0 (bola putih); posisi dalam satuan meja yang sama (pusat 0,0).
- **"Level tambahan" — tidak ada paket DLC/unduhan terpisah.** Seluruh 210 level tertanam di APK sebagai aset di atas; tidak ditemukan mekanisme unduh level lain (satu-satunya pembaca data level adalah `LevelManager.loadData` dari assets). Jadi yang dimaksud "tambahan level" pada game ini = 7 stage × 30 level bawaan itu. UI pemilih: `LevelScene` menggambar 15 tombol per halaman (2 halaman per stage) dengan ikon bintang (`star_a`/`star_b`) dan gembok (`select_lock`).
- Statistik hasil hitung ulang atas ke-7 berkas (semua baris valid, 0 cacat format):

| Stage | Level | Bola per level (maks, termasuk cue) | Level berisi black hole dari data | Texture id terpakai |
|---|---|---|---|---|
| 0 | 30 | 16 | 5 | 0–15 |
| 1 | 30 | 17 | 10 | 0–15 |
| 2 | 30 | 20 | 15 | 0–15 |
| 3 | 30 | 21 | 24 | 0–15 |
| 4 | 30 | 23 | 20 | 0–14 (tanpa 13, 15) |
| 5 | 30 | 24 | 20 | 0–15 |
| 6 | 30 | 25 | 15 | subset (0,1,2,3,4,6,8,9,10,11) |

  Jumlah bola naik bertahap (level pertama stage 0 hanya 2 entri = cue + 1 bola; stage 6 sampai **25 entri = cue + 24 bola objek**). Texture id yang sama **boleh berulang** dalam satu level (mis. stage 1 berisi lima bola texture "1") — bola dibedakan hanya oleh indeks array, bukan nomor.
- Sudut bidik awal per level ditabelkan terpisah di kode: `LevelRule.start_angle[7][30]` (nilai 0–3) → `getDefaultAimAngle()` = nilai × 90°.

## 2. Objektif Arcade per level — SATU pola seragam untuk semua 210 level

Penilaian hidup seluruhnya di `LevelRule.onRoundOver` (LevelRule.smali:845) + `onPotBall` (:785) + `newMatch` (:698). Tidak ada variasi aturan per level; yang berubah hanya layout/jumlah bola/black hole.

- **Sumber daya: `restTime`, mulai 6** (`newMatch`: `restTime = 6` = konstanta `INIT_STAR_COUNT`; ditampilkan di layar sebagai jumlah stik/`level_cue_count` lewat `GameScene.onRoundOver(II)`).
- **Menang:** semua bola objek habis dari meja selagi `restTime > 0` → `winner = 0`, status selesai; skor akhir ditambah bonus `restTime × 10.000` (GameScene.smali ±baris 1877).
- **Kalah:** `restTime ≤ 0` → `winner = −1`.
- **Perubahan `restTime` per tembakan** (dari `onRoundOver`):
  - Tidak ada bola masuk: **−1**.
  - Bola putih masuk (scratch): **−2** dan combo di-reset. (Sesudahnya game menaruh ulang bola putih di sekitar titik (−705, 0) lewat `putBall` dan masuk fase penempatan; area geser dibatasi `LevelRule.checkFreeballArea`: x ∈ [−1225, 1217], y ∈ [−605, 625] — hampir seluruh meja.)
  - Tembakan tidak menyentuh bola mana pun (`firsthit == −1`): **−2** dan combo di-reset.
  - Bola masuk ke **lubang hitam** (`effect_type 1`): **−2** per bola.
  - Bola masuk ke **lubang +cue** (`effect_type 5`): **+1**.
  - Bola masuk ke **lubang −bola** (`effect_type 4`): satu bola sisa lain ikut dihapus dari meja + skor bonus.
- **Skor:** tiap bola masuk: `skor += combo × 1000` (combo naik per bola dalam rangkaian tembakan beruntun, `onPotBall`). Lubang −bola memberi `(combo+1) × 1000` (atau ×1500 bila itu bola terakhir). Tipe tembakan dilaporkan ke UI sebagai Nice/Great/Excellent/Great-Cue (konstanta `TYPE_*`).
- **Tidak ada batas waktu dan tidak ada target skor/bintang di dalam aturan** — satu-satunya "mata uang" adalah `restTime`. Bintang per level ada sebagai ikon progres di `LevelScene` (`star_a`/`star_b`); ambang bintang persisnya berada di lapisan progres/UI (tidak dilacak sampai penyimpanan progres pada audit ini) — yang terbukti dari kode aturan hanyalah meter `restTime` (maks 6) dan bonus skor di atas.

## 3. Kompatibilitas mod

**(a) Fisika & titik tembak — SAMA PERSIS.** Arcade dijalankan oleh `GameScene` yang sama (ia mengimplementasikan `LevelRule$EventListener`; Main.smali:508 membuat `level_rule` dan `Main.startGameInArcadeMode` menyiapkannya) dengan `PoolTable` yang sama: `table.roundstate` cukup diganti `LevelRule$GameRoundState`. Tembakan tetap lewat `PoolTable.click(strength, spinX, spinY, angle)` dan snapshot state tetap `table.balls[]` (REPORT §4). Klon fisika mod (`Sim`) tidak tahu dan tidak perlu tahu soal aturan → **garis prediksi penuh + long line berlaku di Arcade tanpa perubahan apa pun.**

**(b) Oracle legalitas 8-ball TIDAK relevan di Arcade.** `LevelRule` **tidak menimpa** `PoolRule.isAvailableTarget` — ia mewarisi `RuleImplBase.isAvailableTarget` (RuleImplBase.smali:627) yang isinya: `return ballIndex != 0;` — **setiap bola non-cue adalah target sah**: tidak ada grup solids/stripes, tidak ada urutan, tidak ada bola 8 penentu. (Pembanding: `Vsai8Ball.isAvailableTarget`, Vsai8Ball.smali:178, adalah oracle grup yang dipakai perencana mod saat ini.) Karena perencana mod menanyakan oracle ke rule yang hidup (`Snap.captureLegal` memanggil `isAvailableTarget` lewat refleksi), di Arcade ia otomatis menerima "semua bola legal" dan `moneyBall = −1` (Snap.java: dari `ruleClass`) — fondasinya sudah benar; yang salah tinggal fungsi tujuannya (§4). Penentu sah & penilaian di Arcade = `LevelRule` sendiri: `onHitBall` (mencatat `firsthit`), `onPotBall` (skor/combo + mencatat `effect_type` lubang), `onRoundOver` (semua perubahan `restTime`, menang/kalah).

**(c) Gerbang PvP tidak relevan di Arcade.** `LevelRule` mewarisi `RuleImplBase.isPVPMode() = false` (RuleImplBase.smali:643) dan tidak ada kode jaringan apa pun di jalur Arcade (data dari assets lokal). Arcade murni offline; gerbang PvP mod tidak akan memblokir apa pun di sini, dan tidak ada risiko desync/deteksi server.

## 4. Kesenjangan perencana — yang HARUS diubah/ditambah untuk Auto Play di Arcade

Kondisi mod saat ini (`Auto.java`/`Snap.java` v1.2): saringan keras menolak kandidat bila (i) scratch, (ii) kontak pertama ilegal menurut oracle grup, (iii) **bola non-target masuk**, (iv) bola penentu (8) masuk dini; fallback-nya tembakan pengaman (safety) ala 8-ball; skor menilai pot legal + posisi lanjutan melawan lawan.

Untuk Arcade:

1. **Cabut konsep "bola non-target masuk = tolak".** Di Arcade semua bola boleh — bahkan harus — masuk; multi-pot dalam satu tembakan adalah keuntungan (combo & skor). Saringan (iii) dan (iv) harus nonaktif saat `ruleClass == LevelRule` (fondasi deteksinya sudah ada: `Snap.ruleClass`, `moneyBall = −1`).
2. **Ganti fungsi objektif: maksim
...[truncated 14649 chars]