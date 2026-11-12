# REA — Onet Klasik / "Onet Online" (onet.picachu) v2.15

Analisis statis penuh atas bundle `Onet_Klasik_2.15_1_s4mo.apks` (base.apk + 4 split).
Metode: androguard (inventaris kelas/field), jadx 1.5.1 (dekompilasi classes.dex, classes4.dex,
classes5.dex), readelf/strings atas lib native. Semua klaim di bawah punya bukti di dex/so.

---

## 1. Verifikasi bundle & base

| Item | Nilai |
|---|---|
| Package | `onet.picachu` |
| Nama aplikasi (manifest) | **Onet Classic** (di Play Store/Uptodown: "Onet Online") |
| versionName / versionCode | 2.15 / 20088 |
| Application | `com.mygdx.game.AdjustApplication` (kelas game sendiri) |
| Main activity | `com.mygdx.game.AndroidLauncher` (libGDX) |
| minSdk / targetSdk | 23 / 36 |
| Sertifikat | CN=**onet2003**, SHA-256 `3D9141E25A78D5B1B38CF84DF40EBBC705C5F46272088DF191C1ACED5CE419DD` |
| Isi bundle | base.apk 64.326.160 B; split_config.arm64_v8a (3.880.274 B); split_config.in (41.369 B); split_config.ms (33.177 B); split_config.xxhdpi (461.223 B) |

- **Base cocok dengan split ABI yang dikirim user sebelumnya**: kelima APK dalam bundle memakai
  sertifikat yang sama persis (SHA-256 di atas) dan `stamp-cert-sha256` identik
  (`3257d599a49d…6d`); ukuran split_config.arm64_v8a sama dengan file kiriman sebelumnya
  (3.880.274 B) → build yang sama.
- Dex di base: 8 file (`classes.dex` … `classes8.dex`, total 62.062 kelas) + `assets/audience_network.dex`
  (Facebook Audience Network). **±99% isi dex adalah SDK iklan/mediasi** (AdMob, AppLovin MAX,
  Mintegral, InMobi, IronSource/Unity Ads, Bigo, BidMachine, Yandex, Pangle, Fyber + Firebase).
  Kode game sendiri hanya ±190 kelas.
- Izin penting: INTERNET, BILLING, AD_ID, POST_NOTIFICATIONS, WAKE_LOCK, VIBRATE, FOREGROUND_SERVICE.
- Aset game: `assets/data/graphics/` (atlas/UI libGDX), `assets/data/sounds/` (musik + efek).
  **Tidak ada file definisi level** — level dibangkitkan prosedural (lihat §3).

## 2. Vonis PairIP: **TIDAK ADA PairIP di game ini** (koreksi bukti)

Identifikasi awal "libpglarmor + libsigner = PairIP" **terbukti keliru** dari simbol JNI:

| Lib | Pemilik sebenarnya | Bukti (simbol JNI ter-ekspor) |
|---|---|---|
| `libpglarmor.so` | **ByteDance Pangle** (iklan) | `Java_com_bytedance_sdk_component_pglcrypt_PglCryptUtils_bc` |
| `libsigner.so` | **Adjust SDK** (tanda tangan anti-fraud iklan) | `Java_com_adjust_sdk_sig_NativeLibHelper_nSign`, `…_nOnResume` |
| `libnms.so` | SDK iklan (JNI generik) | hanya `JNI_OnLoad`, tanpa atribusi PairIP |

Bukti standar PairIP di base — **semuanya negatif**:

- Kelas `com.pairip.*` di seluruh 8 dex: **0** (62.062 kelas dipindai; string "pairip" tidak muncul
  di dex mana pun maupun di dalam kedua .so).
- Application di manifest = `com.mygdx.game.AdjustApplication` — kelas milik game sendiri;
  isinya (jadx) hanya `Adjust.initSdk(new AdjustConfig(this, "nqigm21gaz28", ENVIRONMENT_PRODUCTION))`.
  Bukan stub PairIP.
- `libpairipcore.so`: **tidak ada** di split mana pun.
- Perlindungan VM atas kode game: **tidak ada**. Sensus metode `com.gdxgame.onet.*`:
  691 metode, **0 native, 0 tanpa badan kode** — seluruh logika game terbaca sebagai Java biasa
  dan terdekompilasi jadx dengan bersih.
- Tidak ada meta-data/stub PairIP di manifest; launcher tidak melakukan cek tanda tangan sendiri.

**Kesimpulan §2:** game ini tidak dilindungi PairIP maupun protector sejenis.
Yang ada hanyalah tumpukan SDK iklan. Jalur mod gabung/repack **tidak terhalang PairIP**
(bukan karena dibypass — memang tidak ada yang menghadang); lihat catatan kejujuran di §7.

## 3. Arsitektur game (libGDX)

Framework: `com.gdxgame.*` = framework libGDX internal developer (BOUNCE — field `bounceLog`),
dikelola singleton `Lcom/gdxgame/b;` berisi manager: adsManager `Lb1/b;`, prefManager `Lk1/d;`,
remoteConfig `Lj1/c;`, encryptManager `Ll1/a;`, soundManager `Li1/c;`, guiManager `Ln1/b;`
(tumpukan layar), localizeManager `Lp1/a;`.

Kelas game (`classes4.dex`, paket `com.gdxgame.onet`):

| Kelas | Peran |
|---|---|
| `Lcom/gdxgame/onet/Onet;` (extends `Lcom/gdxgame/b;`) | Kelas game utama: sesi online, `getData()`, `save(...)`, `saveUserInfo(...)`, purchaseManager `Lcom/gdxgame/onet/c;`, socialManager `Lw1/C0249b;` |
| `Lcom/gdxgame/onet/layer/a;` | **Layar permainan OFFLINE** (Classic + Continue; field mode `L` = 0/1/2) |
| `Lcom/gdxgame/onet/layer/OnlineLayer;` | Lobi + permainan **ONLINE** (room, automatch, chat) |
| `Lcom/gdxgame/onet/layer/c;` | Layar permainan kedua (papan yang sama, varian ikon klasik) |
| `Lcom/gdxgame/onet/layer/d;` | Dialog/menu (pengaturan, toko remove-ads, privasi) |
| `Lcom/gdxgame/onet/layer/b;` | Aktor "hadiah jatuh" (gift) di layar permainan |
| `Ls1/C0237c;` (s1.c) | **Papan permainan** (widget + seluruh logika papan) |
| `Ls1/C0239e;` (s1.e) | **Ubin (tile)**: field `b`=tipe, `c`=x, `d`=y, `e/f/g`=salinan cadangan, `k`=sudah kosong |
| `Ls1/C0236b;` (s1.b) | Konfigurasi permainan (ditimpa remote config, §4) |
| `Lu1/C0245c;` (u1.c) | **GameData** (save utama, §4) |
| `Lcom/gdxgame/onet/message/CS* / SC*` | Protokol server (60 kelas, §5) |

### Papan & aturan main — `Ls1/C0237c;`

- Grid: field `f` = `C0239e[][]` berukuran **16 kolom × 9 baris = 144 ubin**; sisa ubin di field `m`
  (mulai 144, `t()` mengembalikannya). Ukuran ubin 76 × 80 px.
- Tipe ubin: `byte[] k` diisi `k[i] = i/4` → **36 tipe × 4 salinan**, diacak Fisher-Yates.
- Pembangkitan papan lokal: `x(Ls1/C0236b;)V` — 100% lokal; bila papan buntu, otomatis `H()`.
  Seed dapat diatur: `F(J)V` (setSeed pada `java.util.Random B`).
- Muat papan dari string: `y(Ljava/lang/String;Ls1/C0236b;)Z` — format 144 angka koma
  (0 = kosong, selain itu tipe+1); serialisasi balik: `K()Ljava/lang/String;`.
- **Algoritme jalur pasangan (≤3 segmen / ≤2 belokan)** — persis aturan Onet klasik:
  - `i(IIII)Z` — cek garis lurus bersih (0 belokan); menulis titik jalur ke `int[] d`, jumlah titik di `e`.
  - `k(Ls1/C0239e;Ls1/C0239e;)Z` — bentuk L (1 belokan).
  - `j(Ls1/C0239e;Ls1/C0239e;)Z` — bentuk Z/U (2 belokan) **termasuk rute keluar papan**
    (titik jalur memakai koordinat −1 / di luar tepi).
  - `h(Ls1/C0239e;Ls1/C0239e;)Z` — gerbang utama: tipe sama (`b` sama) **dan** salah satu jalur di atas lolos.
  - `q(Ls1/C0239e;Ls1/C0239e;Z)Z` — eksekusi "eat": panggil `h`, terapkan gravitasi `o(...)`,
    `m -= 2`, callback `onEat/onEmpty/onStuck` (interface `Ls1/C0237c$InterfaceC0067c;`).
  - `p(IIIIII)Z` — eat berdasarkan koordinat+tipe (dipakai untuk menerapkan eat dari server/replay).
  - `s([Ls1/C0239e;)Z` — cari **pasangan pertama yang bisa disambung** (brute-force semua pasangan via `h`).
  - `w(Z)Z` — ada-gerakan?; bila argumen false, pasangan yang ketemu **disorot** (`f(true)` pada ubin)
    + callback `onHint` → **inilah implementasi tombol Hint**.
  - `u(IIII)V` — sorot pasangan tertentu (dipakai hint dari server di mode online).
  - `H()Z` — **Swap**: menata ulang posisi ubin sampai ada pasangan tersambung (dipakai tombol swap
    dan otomatis saat buntu).
  - Mode gravitasi per level: enum `Ls1/EnumC0235a;` (Classic, Up, Down, Left, Right, diagonal D1/D2,
    Vertical*, Horizontal*); dipilih dari nomor level oleh `B(I)V`
    (`level % (((21-1)*(21-1))*5 + 7)` kombinasi) → "level" bukan data, melainkan seed + mode geser.
- Timer & skor (di `layer/a`): batas waktu field `f` (float detik; default remote-config
  `timeClassic/timeContinue = 480`), berjalan field `j`; tiap eat `onEat(...)` → skor pool `n += 20`;
  skor tampil/akhir = `n / 20`; bonus selesai = sisa detik utuh ditambahkan ke `n` sebelum dibagi.
  Timeout → dialog revive (`W(Z)`, +60 detik via iklan rewarded).

## 4. Ekonomi, item, IAP, save

### Item (mode offline — Classic & Continue)

| Item | Stok awal (default remote config `Ls1/C0236b;`) | Cara nambah |
|---|---|---|
| Hint | Classic **7** (`hintClassic`), Continue **2** (`hintContinue`) | +1 tiap naik level; hadiah jatuh; rewarded ads (placement `button_hint`) |
| Swap | Classic **7** (`swapClassic`), Continue **2** (`swapContinue`) | +1 tiap naik level; hadiah jatuh; rewarded ads (placement `button_swap`) |
| Waktu | 480 detik (`timeClassic`/`timeContinue`) | hadiah jatuh +60–120 detik; revive timeout +60 detik via rewarded |

- Jumlah hint/swap berjalan disimpan di slot save per mode (`Lu1/C0243a;` field `b` = hint, `c` = swap,
  `d` = string papan/"next", `e` = seed, `i` = level, `g` = skor pool, `f/h` = float waktu).
- Hadiah jatuh (`layer/b`, tipe m/n/o): acak selama bermain — m → +hint, n → +swap, o → +waktu
  (rentang dari remote config `giftHintMin/Max=2`, `giftSwapMin/Max=2`, `giftTimeMin/Max=60..120`,
  `giftDuration=60`).
- Mekanik bawaan developer bernama persis **`cheatSwap`** (remote config, default aktif):
  setelah sesi ke-2, tiap 30 detik (`cheatSwapDuration`), bila skor ≥ ambang pada `cheatSwapData`
  `{288,0,2, 144,0,3}` (pasangan skor/sisa-ubin/tipe), game diam-diam melakukan
  `Ls1/C0237c;->I(II)Z` (swap penolong) — retensi bawaan, bukan celah.
- **Tidak ada koin/mata uang lunak.** Tidak ada toko item.

### IAP

- **Satu-satunya produk: `onet.picachu.removeads`** (non-consumable, via gdx-pay
  `PurchaseManagerGoogleBilling2`, dihubungkan di `AndroidLauncher`).
- Penangan: `Lcom/gdxgame/onet/c;->handlePurchase(...)` — menyimpan tanda terima ke GameData
  (`f0(requestId, orderId, transactionData, signature)`) **dan mengirimkannya ke validator server
  game** `Lv1/C0247b;->b(I…)` (mode 2 = validasi, 0 = catat beli, 1 = restore). Status bebas-iklan
  (`Lu1/C0245c;->G()Z`, field `M`/`L`) menentukan `adsManager.G(Z)`. → status VIP/remove-ads
  **divalidasi server**; ini satu-satunya nilai berbayar.
- VIP di akun server: `UserInfo.vip`, `vipExpired`, `CSGetVip`/`SCShowMessage` — terkait akun online.

### Save (lokal)

- Manajer: `Lk1/d;` (prefManager). Satu blob di SharedPreferences libGDX, kunci **`gameData`**:
  JSON kelas data framework `Lk1/c;` yang **dibalik stringnya lalu di-Base64** (obfuskasi ringan,
  bukan enkripsi). Auto-save tiap 10 detik bila kotor + flush eksplisit `prefManager.j()`.
- Isi (`Lu1/C0245c;` = GameData): 3 slot permainan berjalan (classic/continue/dll), `continueLevel`,
  tabel skor lokal top-10 (`highScores`, entri `Lu1/C0244b;`), cache papan peringkat server
  (`classicScores`, `continueScores`, …), `sessionCount`, pengaturan (background, classicIcon,
  changeVisible), `clientId`, dan field tanda terima remove-ads (H/I/J/K + kedaluwarsa L).

## 5. Permukaan online

Game ini **punya server sendiri** (warisan "Onet Kawaii"/Pikachu):

- Transport: **socket.io** (engine.io) ke `http://pikachu.onebi.net:9093/` — manajer sesi
  `Lx1/C0256g;`, pesan JSON bernama (`@a(name=...)`, Jackson). Jalur REST cadangan:
  `Lc1/a;` → `http://pikachu.onebi.net:4386`, versi protokol 56 (`Onet.VERSION`).
  (HTTP polos, bukan HTTPS.) Endpoint warisan lain: `onebi.net/Pikachu/index.php`, `version.php`.
- Akun: `CSCreateAccount`, `CSLogin{userInfo, deviceInfo}`, `CSValidateToken`, login Facebook
  (`UserInfo.TYPE_FACEBOOK`), token akses di `UserInfo.accessToken`.
- Mode ONLINE (PvP ruangan): `CSCreateRoom/CSJoinRoom/CSAutoMatch/CSReady`, papan ditentukan
  **seed dari server** (`SCStartGame{GameInfo{gameId, level, seed}, players, hintCost=-40}` —
  klien membangkitkan papan lokal dari seed yang sama), eat dilaporkan klien
  (`CSEat{gameId,x1,y1,id1,x2,y2,id2}`) dan **skor dipegang server** (`SCEat{scores[], seed}` —
  server menyiarkan ulang + re-seed), hint **dari server** (`CSHint{gameId}` → `SCHint{x1,y1,x2,y2,scores}`,
  biaya −40 skor), sesi dapat dipulihkan dari status server (`SCGameSession{gameState, scores, states}`
  → papan dimuat via `y(gameState)`), ada chat/emo/replay (`CSChat`, `CSEmo`, `CSReplay`).
  Lawan bisa manusia atau **bot** (`UserInfo.TYPE_BOT = 2`).
- Papan peringkat: server game (`CSLeaderBoard*` → `SCLeaderBoard*`, `SCUpdateRank*`) untuk
  total/harian/mingguan/classic/continue; hasil classic & continue terbaik **dilaporkan klien**
  (`CSUpdateClassic{bestClassic}`, `CSUpdateContinue`) dan exp/level **dihitung server**
  (`SCUpdateLevel{exp, level, levelExp, currentExp}`).
- Google Play Games: sign-in + **achievement** (`Games.getAchievementsClient().unlock(...)` di
  `AndroidLauncher`; submit skor/level juga lewat `socialManager` `Lw1/C0249b;` ke server game).
- Firebase: Analytics/Measurement + properti firebase-* (bukan backend permainan).
  Remote config framework (`Lj1/c;` + `Ls1/C0236b;`) menimpa angka-angka §4 dari server
  (kunci terbaca jelas: `hintClassic`, `timeClassic`, `cheatSwap`, dll.).
- Iklan: mediasi raksasa (AdMob, AppLovin MAX, Pangle + APMInsight, Mintegral, InMobi, IronSource,
  Unity Ads, Bigo, BidMachine, Yandex, Fyber, Facebook AN) + **Adjust** (atribusi; token aplikasi
  `nqigm21gaz28`, lib `libsigner.so` miliknya).

### Lokal vs server — per nilai

| Nilai | Sifat | Bukti |
|---|---|---|
| Papan, jalur, eat, timer, skor **saat bermain offline** | **LOKAL penuh** | `Ls1/C0237c;` x/q/w/H; timer & skor di `layer/a` |
| Stok hint/swap & progres level offline | **LOKAL** (save `gameData`) | `Lu1/C0243a;`, `Lk1/d;` |
| bestClassic / bestContinue yang tampil di leaderboard server | Dilaporkan klien, **disimpan server** | `CSUpdateClassic{bestClassic}` (satu field, tanpa bukti permainan) |
| Exp, level akun, rank (semua papan peringkat) | **SERVER** | `SCUpdateLevel`, `SCUpdateRank*`, `UserInfo` |
| Skor & hint **di mode online** | **SERVER** (klien hanya melapor eat) | `SCEat.scores`, `SCHint`, `SCStartGame.hintCost` |
| Status remove-ads/VIP | **SERVER-validasi** | `Lv1/C0247b;->b(2, …)` validasi tanda terima |
| Konfigurasi angka permainan | Server (remote config) menimpa default lokal | `Ls1/C0236b;->a(Lj1/c;)` |

## 6. Vonis cheat per fitur (klasifikasi server-vs-lokal dulu)

**Mode OFFLINE (Classic & Continue) — semua lokal, layak secara teknis:**

| Fitur | Vonis | Alamat persis |
|---|---|---|
| Hint & swap **tanpa batas** | BISA — stok hanya int di slot save & field layar | slot `Lu1/C0243a;->b` (hint) / `->c` (swap); pemakaian di `Lcom/gdxgame/onet/layer/a;` (tombol hint `s`, swap `t`; penambah `n0(I)`/`p0(I)`). Cukup cegah pengurangannya atau set 999 saat level mulai |
| Bekukan timer | BISA — timer float lokal | `layer/a` field `f` (batas) & `j` (berjalan); atau tahan penambahan `j` di loop act layer |
| **ESP pasangan** (sorot semua pasangan tersambung) | BISA — mesinnya sudah ada di game | panggil berulang `Ls1/C0237c;->s([Ls1/C0239e;)Z` atau `w(Z)Z` dengan sorot, atau iterasi `h(Ls1/C0239e;Ls1/C0239e;)Z` atas grid `f` |
| Auto-solve (makan pasangan otomatis) | BISA — lebih berat | loop `s(...)` → `q(Ls1/C0239e;Ls1/C0239e;Z)Z` per pasangan; gravitasi & callback sudah ditangani `q/o` |
| Skor classic lokal (top-10 HP) | BISA — murni lokal | pool `layer/a` field `n` (+20/eat di `onEat`), tabel `highScores` di `Lu1/C0245c;` |
| Naik level / buka mode geser | BISA — lokal | seed & level di slot `Lu1/C0243a;->e/i`; mode dari `Ls1/C0237c;->B(I)V` |

**Mode ONLINE — SERVER, di luar cakupan (tidak dibuatkan):**

| Fitur | Vonis |
|---|---|
| Skor/rank/exp/leaderboard online | Server memegang skor (`SCEat.scores`), exp & rank dihitung server (`SCUpdateLevel`, `SCUpdateRank*`) — nilai lokal ditimpa server |
| Hint online | Diberikan server dan memotong skor (`SCHint`, `hintCost=-40`) |
| bestClassic leaderboard | Dilaporkan klien lewat satu field (`CSUpdateClassic`) — memang longgar secara teknis, tetapi nilainya adalah papan peringkat publik antar-pemain → **tidak disentuh** (kategori yang sama dengan skor server) |
| Remove-ads/VIP gratis | Tanda terima divalidasi server (`Lv1/C0247b;`) — bypass pembayaran nyata, **ditolak** |

## 7. Penilaian jalur mod

**Jalur gabung/repack:** Tidak ada PairIP/protector yang menghadang (§2) — secara mekanis repack
semudah game libGDX lain (Diamond/Tahu Bulat). Catatan kejujuran yang harus diketahui sebelum memilih jalur ini:
- APK hasil repack bertanda tangan beda → Google Play Games sign-in & achievement kemungkinan gagal,
  dan login server mengikat `accessToken`/device (CSLogin membawa `DeviceInfo`) — akun online bisa
  bermasalah; validasi remove-ads juga membaca tanda terima Play asli.
- Adjust `libsigner.so` menandatangani event atribusi, bukan gerbang permainan.

**Jalur root injector (pola Diamond/HCR — hook Java di proses asli):** Semua target §6 adalah
metode Java biasa yang terbaca penuh (691/691 tanpa native) — **terjangkau penuh** oleh hook
runtime (Pine) tanpa menyentuh APK: kandidat utama `Ls1/C0237c;->h/q/w/s/H`, slot save
`Lu1/C0243a;`, dan loop timer `layer/a`. Sinyal anti-injeksi/anti-root:
- Di kode game: **tidak ada** cek root, cek Frida/Xposed, maupun cek integritas yang ditemukan.
- Daftar path `su` memang ada di string dex — milik SDK iklan/atribusi (deteksi fraud iklan),
  bukan gerbang permainan; tidak ada bukti ia memblokir permainan.
- Risiko yang tersisa bersifat server: permainan **online** diawasi server lewat protokol
  (skor/hint dari server) — injector hanya masuk akal diarahkan ke mode offline.

**Rekomendasi jalur bila nanti diperintah membangun:** root injector khusus mode OFFLINE
(Classic/Continue) dengan target §6; mode online tidak disentuh sama sekali.
Tidak ada pembangunan yang dilakukan dalam tugas ini (analisis saja).

---

### Lampiran — alamat kunci (untuk pembangunan lanjutan tanpa bedah ulang)

- Papan: `Ls1/C0237c;` field `f` `[[Ls1/C0239e;`, `m` sisa ubin, `k` `byte[]` tipe, `B` `Ljava/util/Random;`, `d` `int[]` titik jalur, `e` jumlah titik.
- Ubin: `Ls1/C0239e;` field `b` tipe, `c` x, `d` y, `k` kosong.
- Jalur: `Ls1/C0237c;->i(IIII)Z`, `->k(Ls1/C0239e;Ls1/C0239e;)Z`, `->j(Ls1/C0239e;Ls1/C0239e;)Z`, `->h(Ls1/C0239e;Ls1/C0239e;)Z`.
- Aksi: `->q(Ls1/C0239e;Ls1/C0239e;Z)Z` (eat), `->p(IIIIII)Z` (eat by koordinat), `->w(Z)Z` / `->s([Ls1/C0239e;)Z` (cari pasangan/hint), `->u(IIII)V` (sorot), `->H()Z` / `->I(II)Z` (swap), `->x(Ls1/C0236b;)V` (papan baru), `->y(Ljava/lang/String;Ls1/C0236b;)Z` / `->K()Ljava/lang/String;` (muat/simpan string papan), `->F(J)V` (seed), `->B(I)V` (mode geser dari level), `->t()I` (sisa ubin).
- Layar offline: `Lcom/gdxgame/onet/layer/a;` field `f` batas waktu, `j` waktu berjalan, `n` pool skor, `l` hint, `m` swap, `q` level, `L` mode; `onEat(IIIIII)V` (+20), setter stok `n0(I)V`/`p0(I)V`.
- Save: `Lk1/d;` kunci SharedPreferences `gameData` (JSON dibalik + Base64); data `Lu1/C0245c;`, slot `Lu1/C0243a;` (`b` hint, `c` swap, `d` papan, `e` seed, `i` level, `g` skor).
- Config: `Ls1/C0236b;` (`hintClassic=7`, `swapClassic=7`, `hintContinue=2`, `swapContinue=2`, `timeClassic=480`, `timeContinue=480`, `cheatSwap*`).
- Server: socket.io `http://pikachu.onebi.net:9093/` via `Lx1/C0256g;`; REST `Lc1/a;` `http://pikachu.onebi.net:4386`; protokol `Lcom/gdxgame/onet/message/*`.
- IAP: produk tunggal `onet.picachu.removeads`; penangan `Lcom/gdxgame/onet/c;`; validator `Lv1/C0247b;`.
