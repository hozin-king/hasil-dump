# REA — Pool Billiards Pro 5.3 (com.forthblue.pool)

- **File dibedah:** `~/workspace/user/files/Pool_Billiards_Pro_5.3_2_7sq3.apk`
- **Ukuran:** 13.948.850 byte (±13,3 MiB)
- **SHA-256:** `958b724b16caae49f2bd3f1418a822a6f78ac4666848f1e240f15bf83446f859`
- **Tanggal bedah:** 22 Okt 2026
- **Metode:** parse header DEX (Python), apktool (manifest), jarsigner/keytool (sertifikat), readelf/nm (native), JADX 1.5.1 `--single-class` per kelas kunci (PoolTable 1217 baris, GameScene 2884 baris, VsaiRuleBase, PoolRule, RuleImplBase, PVP8Ball, NetConnect, TcpClient, Main, PoolBall, BallSprite, AimLine).
- **Status:** bedah + vonis selesai. **Mod BELUM dibangun** (sesuai tugas).

---

## 1. Identitas pasti

| Item | Nilai | Bukti |
|---|---|---|
| Package | `com.forthblue.pool` | AndroidManifest |
| versionName / versionCode | **5.3 / 53** | apktool.yml |
| minSdk / targetSdk / compileSdk | 23 / 36 / 36 | apktool.yml + manifest |
| Activity utama | `com.forthblue.pool.Main` (landscape, singleTask) | manifest |
| App ID AdMob | `ca-app-pub-1158309768049631~5250610681` | manifest meta-data |
| Google Play Games APP_ID | `919458490344` | res/values/strings.xml |
| Doodle appid | `10026` | strings.xml |

**Sertifikat — ASLI, bukan modifan:**
- Penandatangan: `CN=FruitsMobile, OU=FruitsMobile, O=FruitsMobile, L=Beijing, ST=Beijing, C=CN` (FruitsMobile = nama lama studio yang sama; ForthBlue adalah brand lanjutannya).
- SHA-256 sertifikat: `2E:55:C8:8B:85:BD:10:DE:AF:C1:39:BE:A3:8D:09:AA:5A:50:77:8E:8B:23:7E:A2:35:4B:DA:90:64:BD:02:A5`
- SHA-1: `9D:BF:6C:E1:DE:F6:BC:A7:FF:78:01:36:0D:C8:C0:7B:48:1E:B6:91`
- Kunci RSA 1024-bit, SHA1withRSA, dibuat 23 Okt 2010, berlaku s/d 2092 — kunci developer orisinal yang dipakai konsisten sejak 2010 (itulah sebabnya masih bisa update di Play Store sampai sekarang).
- Skema tanda tangan: **v1 (JAR, `META-INF/FRUITSMO.RSA`) + v2 (APK Signature Scheme v2)** — terverifikasi dari APK Signing Block.
- Kesimpulan: APK ini bertanda tangan kunci privat developer asli. APK modifan pihak ketiga tidak mungkin memakai kunci ini (kasus Fragger kemarin berbeda: itu kunci debug AOSP).

---

## 2. Engine & arsitektur

**Bukan Unity, bukan Cocos2d-x.** Game ini memakai engine 2D/3D ringan buatan sendiri bernama **Basket** (`com.fruitsmobile.basket`) + kode game Java murni di `com.forthblue.pool`. Tidak ada JavaScript.

### Native (.so) — hanya jembatan JNI, TIDAK ada logika game/fisika

| Lib (arm64-v8a) | Ukuran | Isi |
|---|---|---|
| `libbasket.so` | 18.048 B | MathUtil native (sin/cos/tan/asin/acos/atan/atan2/sqrt), Matrix, partikel, util buffer — semua simbol **terekspor penuh** (`Java_com_fruitsmobile_basket_...`, C++ `basket::math::*`) |
| `libbasketgl1.so` | 17.040 B | Wrapper JNI OpenGL ES 1.x |
| `libbasketgl2.so` | 22.040 B | Wrapper JNI OpenGL ES 2.0 |

ABI tersedia: `arm64-v8a` + `armeabi-v7a`. Lib tidak di-strip (tabel simbol dinamis lengkap), tapi isinya tidak relevan untuk cheat — **seluruh logika permainan & fisika hidup di DEX (Java)**:

- `classes.dex` (8,6 MB) = kode game + Basket + SDK iklan; `classes4.dex` (7,2 MB) = Google Play services/Firebase/Guava; `classes3.dex` = desugar `j$`; `classes2.dex` = stub.
- Kelas game **tidak diobfuscate sama sekali** — nama asli semua terbaca:

| Kelas | Peran |
|---|---|
| `engine/PoolTable` | **Mesin fisika + state meja** (kelas inti, lihat §4) |
| `engine/PoolBall` | State per bola |
| `engine/PoolHole`, `engine/PoolBlocker` | Lubang & segmen cushion |
| `engine/BallSprite` | Render bola (shader bola 3D, quaternion rotasi) |
| `engine/PoolAI` | Interface AI: `think()`, `getAngle()`, `getStrength()`, `getTarX/Y()` |
| `rules/PoolRule`, `rules/RuleImplBase` | Kontrak + konstanta fisika & geometri meja |
| `rules/VsaiRuleBase` (+`Vsai8Ball`, `Vsai9Ball`) | Mode VS Computer + implementasi AI |
| `rules/Time8Ball1P`, `rules/Time9Ball1P`, `rules/TimeRuleBase` | Mode Time 1P |
| `rules/LevelRule`, `LevelManager` | Mode Arcade/stage (layout dari `assets/data/level_stage_*.txt`, teks polos) |
| `rules/TutorialRule` | Tutorial |
| `rules/PVP8Ball` | **Mode PvP online** (lihat §3) |
| `scene/GameScene` | Orkestrator: input sentuh, bidik, tembak, gambar garis bidik |
| `sprite/AimLine`, `sprite/PoolStick`, `sprite/StrengthBar` | Garis bidik, stik, bar kekuatan |
| `Main` (+`ConnectThread`), `NetWorkPortability` | Entry + koneksi PvP |

---

## 3. Online vs offline — ADA PvP MANUSIA ASLI (batas keras)

Game ini **bukan** offline murni. Mode-mode lokal (semua simulasi di perangkat, lawan AI/bot):

- **VS Computer** (8-ball & 9-ball, `Vsai8Ball`/`Vsai9Ball`) — AI geometris lokal.
- **Time Mode 1P** (8-ball & 9-ball) — sendirian lawan waktu.
- **Arcade/Stage** (`LevelRule`, layout teks polos di assets) — sendirian.
- **Tutorial**.

**Mode ONLINE — PvP manusia asli, terbukti dari kode:**

- Kelas `rules/PVP8Ball` (`isPVPMode() = true`, `PLAYER_TYPE_OPPO`), `scene/MatchingScene` (matchmaking), protobuf `com.junerking.proto.PoolProto$CCPVPRequest/CCPVPResponse/CCBall`.
- Transport: **socket TCP mentah** ke server khusus game: **`pool.galaxyaura.com` port 5678** (`com.junerking.net.TcpClient`, alamat+port hardcoded), lapisan request/response + login di `NetConnect`/`NetManager`, thread koneksi di `Main$ConnectThread`.
- Model sinkronisasi: bergantian giliran (`NetManager.exchangeTurn(...)`); tembakan lawan tiba sebagai parameter (strength/angle/spin terlihat dipakai ulang di `GameScene` dari `CCPVPResponse`) lalu **disimulasikan lokal**; posisi bola disinkronkan balik via `setBallPos(List<CCBall>)`.
- Di PvP, panjang garis petunjuk arah bola target (`outLine`) **digembok oleh stat stik** (`Var.stick_aim`) — bagian dari monetisasi stik/IAP.
- Jaringan lain: AdMob + Facebook Audience Network + Unity Ads (iklan), Google Play Games (APP_ID di atas; leaderboard/achievement), Firebase (analitik), Play Billing 7.1.1 (toko koin & stik — ada jalur verifikasi pembelian ke server: string `sendPurchaseInfoToServerToVerifyAndConsume`).

> **BATAS (wajib dibaca):** Semua fitur cheat di §5 hanya sah untuk mode **offline/lokal** (VS Computer, Time, Arcade, Tutorial). Memakai garis prediksi penuh / autoplay di **mode PvP online melawan manusia asli = curang terhadap pemain lain** dan di luar pola yang disetujui. Mod apa pun yang nanti dibangun harus **mati total saat `rule.isPVPMode()` true**. Risiko tambahan di PvP: karena state bola dipertukarkan dengan server/lawan, klien yang dimodifikasi berisiko desync dan terdeteksi dari ketidakcocokan state (mekanisme validasi server persisnya **belum terbukti** — tidak dibedah lebih jauh karena tidak diperlukan).

---

## 4. Fisika — deterministik, analitik, dan bisa diklon persis

Mesin fisika di `PoolTable` adalah **simulasi event-driven analitik berbahasa Java**, bukan integrasi langkah-kasar:

- `tick()` berjalan dengan **langkah tetap 16 ms** (`updateRunning(16L)`) tanpa peduli waktu frame sebenarnya → urutan simulasi selalu sama untuk input yang sama.
- Dalam satu langkah: `processRunning(dt)` berulang menghitung **waktu tabrakan berikutnya secara analitik** (`getNextHitTime` — penyelesaian kuadrat `workout(...)` untuk bola–bola, bola–cushion (segmen `PoolBlocker`), bola–lubang), memajukan semua bola lurus (`doRunning`: `x += vx·t`), lalu menyelesaikan tabrakan itu (`processHit`), sampai sisa waktu langkah habis.
- **Tabrakan bola–bola** (`doHit(PoolBall, PoolBall)`): tumbukan elastik sempurna massa sama — komponen kecepatan sepanjang garis pusat dipertukarkan. Tanpa angka acak.
- **Tabrakan cushion** (`doHit(PoolBall, PoolBlocker)`): pantulan dicerminkan, kecepatan × **0,8** (`BLOCK_HIT_LOST`), spin `w` dibagi 2, ada kopling spin↔geser dari `blocker.force`.
- **Friksi** (di `updateRunning`, per langkah 16 ms): friksi geser mengkopling kecepatan linear `v` dengan kecepatan putar permukaan `rv` memakai `ROLL_K = 1,5811388`; spin sumbu tegak `w` meluruh pada laju `0,15 × getForce()`; tahanan gulir `getRollForce()` memindahkan sisa `v` ke `rv` sampai bola berhenti murni menggelinding lalu diam.
- **Lubang**: bola yang masuk radius lubang tertarik gravitasi lubang `getHoleGravity()` (di `doRunning`), lalu `onPotBall`.

### Konstanta (dari `RuleImplBase`, berlaku umum)

| Parameter | Nilai |
|---|---|
| Jari-jari bola | **47,15** |
| Ukuran meja (unit internal) | **2810 × 1530** (area cushion ±1305 × ±665; posisi 6 lubang & segmen cushion berupa array float eksplisit `holePosition`/`blockersPosition`) |
| `getForce()` (skala friksi geser) | **1500** |
| `getRollForce()` | **100** |
| `getHoleGravity()` | **3600** |
| Restitusi cushion | **0,8** |
| Kekuatan tembak | min **200** – maks **4000** (stik PvP bisa menaikkan maks) |

### State bola — semua field publik, gampang dibaca runtime

`PoolTable.balls` adalah `public PoolBall[]` (indeks 0 = bola putih/cue). Tiap `PoolBall`:

- Posisi: `x`, `y` (warisan SpriteBase, unit meja, pusat meja = 0,0)
- Kecepatan linear: `vx`, `vy`
- Kecepatan putar permukaan (spin atas/bawah/samping hasil english): `rvx`, `rvy`
- Spin sumbu tegak: `w`
- Lainnya: `id`, `isAvailable`, `inHole`, `scale` (= jari-jari)

### Fungsi tembak — satu pintu masuk untuk manusia, AI, dan replay PvP

```java
// PoolTable.click(float strength, float spinX, float spinY, float angleDegrees)
poolBall.vx  = strength * cos(angle);
poolBall.vy  = strength * sin(angle);
poolBall.rvx = cos(angle) * spinY * strength;
poolBall.rvy = sin(angle) * spinY * strength;
poolBall.w   = (-strength * spinX) / ballRadius;
```

- Dipanggil `GameScene` untuk tembakan pemain: `table.click(aimStrength, aimPx, aimPy, aimAngle)` — `aimPx/aimPy` adalah titik pukul english dari UI, `aimAngle` dalam **derajat**.
- Dipanggil `PoolTable.tickAI` untuk tembakan AI: `click(aistrength, 0, 0, aiangle)` (AI tidak pernah pakai spin).
- Dipakai juga untuk mengeksekusi tembakan lawan di PvP dari data `CCPVPResponse`.

### Determinisme & replikasi

- **Tidak ada `Math.random`/acak di jalur fisika PoolTable.** Satu-satunya keacakan ada di AI (pemilihan tembakan cadangan + error sudut kesulitan) — tidak memengaruhi hasil simulasi dari parameter tembakan yang diberikan.
- Fungsi matematika (`sin/cos/sqrt/atan2`) lewat `MathUtil` → JNI `libbasket` yang sama; `doHit` bola–bola memakai `java.lang.Math.atan2/sin/cos`. Artinya: **klon simulasi yang berjalan di dalam proses game yang sama (mod gabung / hook in-process) memakai pustaka matematika yang identik → hasil prediksi bisa bit-exact**, bukan perkiraan.
- Karena gerak antar-tabrakan adalah garis lurus sempurna (event-driven), lintasan hasil klon berupa **polyline eksak** melalui titik-titik tabrakan, dan posisi berhenti tiap bola adalah keluaran langsung simulasi — bukan ekstrapolasi.

---

## 5. Vonis per fitur yang diminta

### a. LONG LINE (garis bidik diperpanjang sampai kena bola/cushion pertama) — **BISA PENUH**

Bukti: `PoolTable.calcAimTarget(float angle)` **sudah public** dan melakukan raycast analitik dari bola putih ke semua bola & blocker; mengembalikan jarak tabrakan pertama dan mengisi `getLastAimBallIndex()`. `GameScene.calcAimTarget()` memakainya untuk menggambar `aimLine` bawaan (dari bola putih ke titik ghost-ball) — jadi memperpanjang/mengubah garis ini hanya soal menggambar segmen yang lebih panjang dari data yang sudah dihitung game sendiri. Presisi = presisi game sendiri.

Catatan jujur: garis bidik bawaan sebenarnya sudah sampai ke bola pertama; yang belum ada di game bawaan adalah kelanjutan setelah kontak (itu masuk fitur b).

### b. PREDIKSI PENUH (lintasan bola putih + bola target, titik berhenti, rantai bercabang multi-warna, pantulan cushion presisi) — **BISA PENUH** (untuk mode offline)

Cara yang benar — dan satu-satunya yang presisi — adalah **menjalankan klon fisika game itu sendiri**, dan itu terbukti layak:

1. Salin state semua bola (8 float per bola: x, y, vx, vy, rvx, rvy, w + isAvailable) dari `table.balls` — semua field publik.
2. Terapkan parameter tembakan calon (strength/spin/sudut saat ini) lewat rumus `click()` di atas ke salinan bola putih.
3. Jalankan ulang inti `processRunning` + blok friksi `updateRunning` (tiga fungsi murni: `workout`, `getNextHitTime`, `doHit`×3 + `doRunning`) di atas salinan, **sambil merekam** posisi tiap bola di setiap event dan posisi berhenti akhirnya. Inti ini bebas efek samping kecuali bunyi klik di `doHit` — klon bersih cukup membuang panggilan `SoundManager`-nya; callback aturan (`onHitBall` dsb.) juga tidak perlu dijalankan untuk keperluan menggambar.
4. Gambar polyline tiap bola dengan warna bola itu sendiri (rantai A→B→C muncul alami karena simulasi memang menjalankan seluruh rantai), titik berhenti = posisi akhir terekam, pantulan cushion presisi karena memakai rumus pantulan game sendiri (restitusi 0,8 + kopling spin).

Infrastruktur gambar sudah ada: `AimLine extends LineSprite` + `Util.writeLine2D` (native) — garis tambahan bisa digambar sebagai LineSprite baru di scene yang sama, memakai transformasi koordinat yang sama seperti `GameScene` (`table.x + x*table.scalex`, dst).

Biaya hitung: satu simulasi tembakan = ratusan event paling banyak; dihitung ulang tiap sudut/power berubah saat membidik — ringan untuk CPU modern (perhitungan AI bawaan melakukan raycast serupa tiap frame).

Yang **tidak** disarankan: reimplementasi fisika dari nol di luar kode game (mis. di overlay terpisah dengan rumus sendiri) — risiko tidak presisi di friksi geser/spin (kopling `rv`↔`v` dan `w` itu khas mesin ini) dan tidak ada alasan menanggung risiko itu karena kode aslinya bisa diklon.

Batas ketelitian yang jujur: prediksi berlaku untuk parameter tembakan **saat garis digambar** (sudut + strength + titik english yang sedang dipilih). Jika pemain mengubah strength setelahnya, prediksi harus (dan bisa) dihitung ulang seketika.

### c. AUTO PLAY PINTAR (analisis meja → pilih tembakan optimal → eksekusi) — **BISA PENUH secara teknis untuk mode offline; tingkat kesulitan MENENGAH–TINGGI**

Semua balok bangunnya terbukti ada:

- **Eksekusi**: panggil `PoolTable.click(strength, spinX, spinY, angle)` — jalur yang sama persis dengan yang dipakai pemain, AI, dan replay PvP. Tidak perlu simulasi sentuhan sama sekali. Penempatan bola bebas (freeball) juga ada jalurnya (`putFreeball()` + set `balls[0].x/y`; pola sama seperti `tickAI` state 3).
- **Analisis & pencarian**: dengan klon simulasi dari (b), autoplay bisa *search*: sapu sudut (mis. resolusi 0,05°–0,1°) × beberapa tingkat strength (× spin bila perlu), simulasikan tiap kandidat, beri skor (bola target masuk? bola putih foul/ikut masuk? posisi akhir bola putih untuk tembakan berikutnya?), pilih yang terbaik. Ini **jauh lebih pintar dari AI bawaan** — AI bawaan (`VsaiRuleBase$1.think`) hanya geometris: cari pot lurus (`checkStraightPot`), pot via satu pantulan cushion (
...[truncated 14672 chars]