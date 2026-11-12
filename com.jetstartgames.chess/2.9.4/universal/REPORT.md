> Catatan arsip: Arsitektur tidak ditegaskan di laporan (bundle tanpa split arsitektur) — memakai `universal`.

# REA — Chess v2.9.4 (`com.jetstartgames.chess`, Jetstart Games)

Analisis statis (jadx 1.5.1 atas `classes.dex`, androguard hanya untuk manifes/sertifikat — tanpa xref androguard). Berkas sumber: `Catur_2.9.4_0_saw1.apks` (base.apk 3,4 MB + `split_config.in` + `split_config.xxhdpi`). Semua klaim di bawah merujuk kelas/method/field hasil dekompilasi persis apa adanya (nama ter-obfuscate R8 dipertahankan).

---

## 1. Verifikasi

| Item | Nilai |
|---|---|
| Package | `com.jetstartgames.chess` |
| Nama aplikasi | "Chess" (Jetstart Games) |
| versionName / versionCode | 2.9.4 / 89 |
| minSdk / targetSdk | 23 / 35 |
| Application class kustom | **Tidak ada** (tidak ada `android:name` pada `<application>`) |
| Activity milik game | `MainActivity` (layar permainan), `MenuActivity` (LAUNCHER), `SetActivity` (pengaturan/tema) |
| Activity SDK | `ProxyBillingActivity`/`ProxyBillingActivityV2` (Billing), `PlayCoreDialogWrapperActivity`, `GoogleApiActivity` |
| Service/Provider | Hanya Firebase (`FirebaseInitProvider`, measurement, datatransport) — tidak ada service milik game |
| Izin | `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `BILLING`, `AD_ID` (gms), `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `BIND_GET_INSTALL_REFERRER_SERVICE`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (milik sendiri) |
| Native libs | **Tidak ada** — engine 100% Java |
| Dex | Satu `classes.dex` (1.586.840 byte), 1.477 kelas |

**Inventaris kelas:** hanya 5 kelas bernama jelas milik game: `com.jetstartgames.chess.{MainActivity, MenuActivity, SetActivity, CustomTextView}`, `com.jetstartgames.logic.ChessBoardPlay`. Sisanya ter-obfuscate R8 ke paket 1–2 huruf (±918 kelas termasuk library yang ikut ter-obfuscate). SDK teridentifikasi dari nama paket: `com/google/*` 492 kelas (Firebase Analytics/Installations/datatransport + GMS), Billing ±141 kelas. Ada `com.alexdp.cplib.TextViewNoPadding` — sisa library GUI catur Java yang menjadi nenek moyang lapisan `o2.*` (lihat §2).

**Penandatanganan:** bundle `.apks` ditandatangani ulang oleh perantara (META-INF memuat `BNDLTOOL.RSA`): sertifikat self-signed beridentitas acak (`CN=hbclzkdyufg, O=oimnfckjasdf`), serial `0x8f2b5f0605259e76`, berlaku 2015-06-26 → 2042-11-10. Hash sertifikat orisinal Play Store tersimpan di berkas `stamp-cert-sha256` = `3257d599a49d2c961a471ca9843f59d341a405884583fc087df4237b733bbd6d`.

**Aset:** `assets/book.bin` (buku pembuka poliglot), `assets/kpk.bitbase`, `assets/krkp.winmasks` (bitbase endgame), `fonts/ChessCases.ttf`.

---

## 2. Arsitektur permainan

Game ini punya **dua inti catur Java** yang hidup berdampingan:

### 2.1 Lapisan permainan/GUI — paket `o2.*` (+ `k2.*`, `j2.*`, `t0.*`)
Turunan library GUI catur Java klasik (keluarga DroidFish/GUI chess library):

- `o2.k` — posisi untuk lapisan GUI: `int[64]` papan (`f2606h`), bitboard `long` (`f2603c`…), giliran `boolean b`, hak rokade, target en-passant, halfmove/fullmove. Ada copy-constructor `new k(o2.k)`.
- `o2.i` — langkah GUI: `f2610a` = petak asal, `b` = petak tujuan, `c` = bidak promosi.
- `o2.j` — pembangkit langkah legal: `g(o2.k): ArrayList<o2.i>` (dipakai validator & petunjuk UI).
- `o2.d` — objek Game: pohon langkah `o2.f` (node berisi langkah + skor engine per node), parser SAN `d(String)`, serialisasi `h(DataInputStream,int)` / `m(DataOutputStream)`, varian PGN `j(String)`/`g(String)`/`f(String,boolean)`.
- `o2.c` — controller pusat (lihat §7–§9 untuk API persisnya).
- `o2.o` — jam catur: `b(int baseMs, int incrementMs)` mengatur waktu dasar + increment.
- `o2.b` — penerima hasil berpikir engine (thinking-info sink) — §7.3.
- `k2.c` — view papan (`ChessBoardPlay` mewarisinya): menggambar panah hint (`setHintTo(-1)`), dan ikon mutu langkah — bitmap `ic_best/ic_good/ic_book/ic_bad/ic_mistake` dimuat di konstruktor `ChessBoardPlay`, dipilih per kode mutu 1–5 di `k2/c.java:176`. **Klasifikasi mutu langkah adalah fitur bawaan** (dipakai mode analisis).
- `j2.j` — utilitas global: tabel kesulitan, data puzzle (§10), ekonomi (§4), helper SharedPreferences.
- `j2.q` — `OnTouchListener` papan (jalur input manusia, §8).

### 2.2 Engine — paket `u.*`, nama internal "chessprince"
Engine catur Java murni, sangat mirip garis keturunan **CuckooChess** (arsitektur bitboard + UCI in-process; penilaian ini inferensi dari struktur, bukan klaim pasti):

- `u.n` — Position engine: `int[64]` + bitboard `long` per warna/jenis, `short[]` riwayat langkah (undo stack), hash Zobrist `f2827l`.
- `u.h` — Move engine (from/to/promo ter-packing).
- `u.a` — tabel serangan bitboard statis (`long[]`/`long[][]`).
- `u.j` — pembangkit langkah engine.
- `u.g` — evaluasi: banyak tabel PST `static int[]` + bitbase KPK (`P`) dan winmask KRKP (`Q`), dimuat dari aset di `n2/c.java:330-333`.
- `u.t` / `u.s` — TranspositionTable (probe/store `a(long,h,…)` / `b(long)`).
- `u.r` — Search: alpha-beta/PVS inti `d(int,int,int,int,int,boolean)` (`u/r.java:367`), varian `h(int,int,int,int,boolean)` (:583); mengeluarkan baris UCI `info depth %d score %s %d%s time %d nodes %d nps %d pv%s` (:470-an) dengan skor `cp`/`mate` dan flag `upperbound`/`lowerbound`; pengkodean skor mate ±1.000.000/2.000.000 (dikali 100) di :1222.
- `u.c` — parser FEN: `public static final n i(String str)` (`u/c.java:214`) membangun `u.n` dari teks FEN (melempar "Invalid castling flags" :296, "Invalid en passant square" :311); juga pembaca berkas baris `j(String)` :448 untuk berkas konfigurasi engine (nama dari preferensi `"engine"`, default `"stockfish"` — sisa warisan arsitektur engine-eksternal; engine yang benar-benar dipakai adalah `u.*` in-process).
- Buku pembuka poliglot dari `/assets/book.bin` (`l2/j.java:296`, `n2/b.java:149`) dengan opsi `l2.a` BookOptions (`bookMaxLength=1.000.000`, `preferMainLines`, `tournamentMode`, `bookRandom`).
- `n2.a` — adapter engine (memegang `u.j`, `u.n`, `Thread`; sink perintah tersinkronisasi `d(String)` — berbentuk adapter UCI). Daftar nama opsi UCI yang dikenal (`n2/a.java:47`): `uci_*`, `hash`, `ponder`, `multipv`, `gaviotatbpath`, `syzygypath`, `strength`.
- `n2.b` — thread engine in-process (`implements Runnable`, mengimpor `u.r`): menjalankan pencarian `u.*` dan memancarkan baris teks UCI yang kemudian di-parse balik oleh `m2.c` (pola warisan DroidFish: engine internal berbicara UCI di dalam proses yang sama).

### 2.3 Kesulitan & waktu berpikir
Nama kesulitan → nilai strength (`MainActivity.w()`, sekitar :3268; disimpan ke `o2.c.f2567k`; nama internal engine `o2.c.f2566j = "chessprince"`):

`begginer 20, easy 50, medium 90, hard 180, advanced 240, expert 300, candidate 400, master 550, grandmaster 800, champion 1000, training 1000`

Di layar ditampilkan sebagai persen (strength × 0,1%) bila < 1000 (`o2/c.java:914-915`). Pasangan parameter waktu per kesulitan (`MainActivity.y()` :3336; field `f1592u`/`f1593v`, default keduanya 100000; `f1594w = 60`):

begginer 40000/100000 · easy 50000/100000 · medium 60000/100000 · hard 70000/100000 · advanced 80000/100000 · expert 90000/110000 · candidate 100000/120000 · master 110000/130000 · grandmaster 120000/150000 · champion 130000/170000 · training 40000/100000. Pasangan ini diteruskan ke jam `o2.o.b(f1592u, f1594w)` saat game dibuat (`MainActivity` :1968, :2900) dan `f1593v` dipakai sebagai kedua argumen waktu pada tugas hint. Opsi engine (`k2.d`): `hashMB` default 16 (dari preferensi), `tbHints`, `tbHintsEdit`, `tbRootProbe`, `tbEngineProbe`.

### 2.4 Mode permainan
Semua mode **offline**:

- **Vs komputer** — 10 tingkat kesulitan di atas.
- **Kampanye 20 level** — kode mode `C0 = "0".."19"`; `j2.j.J(int)` memetakan level→nama kesulitan (0–9 dan 10–19 sama-sama berjalan begginer→champion; 100→"training"). Level 11–20 adalah "lap 2": posisi berpasukan kustom dari `j2.j.f2064o[10]` (§10). MenuActivity merender `button_l1..l20`, `star1..star20`, `lock2..lock20`.
- **Dua pemain lokal (pass-and-play)** — kode `C0 = "50"` (string `menu_level_plan_50` = "TWO PLAYERS").
- **Puzzle/taktik** — kode `C0 = "100"`, 100 posisi mate-in-N (§10).
- **Analisis** — sub-mode (field `f1553k0` di MainActivity; string `confirm_analysis`), dengan klasifikasi mutu langkah bawaan (§2.1). Gratis dibatasi per hari oleh `j2.j.i()`: preferensi `last_analysis_date` + `analysis_count < 2`.

Fitur bawaan lain: **undo** (navigasi pohon `o2.d`/`o2.f`), **hint** (§7.2), jam catur dengan increment (`o2.o`), check-in harian (preferensi `checkin_current_streak`, drawable `bonus.png`/`bonus_wait.png`), tema papan unduhan (§4).

---

## 3. Permukaan online — TIDAK ADA mode online vs manusia

Bukti (pemindaian seluruh dex: 9.330 string, inventaris 1.477 kelas):

- Pola string `socket`/`websocket`: **0 temuan**.
- Kelas `firebase/database`, `firestore`, `firebase/auth`, `gms/games`, `remoteconfig`, `okhttp`: **0** — tidak ada Realtime Database, Firestore, Auth, Play Games, maupun klien HTTP umum.
- Satu-satunya kelas GMS adalah `AdvertisingIdClient` (4 kelas) — **tidak ada SDK penyaji iklan** (tidak ada AdMob dsb. di dex).
- Seluruh lalu lintas jaringan terpetakan habis ke: (1) Firebase Analytics + Installations + datatransport CCT (User-Agent `datatransport/3.1.8` di `f0/g.java`); (2) POST laporan pembelian ke AWS (§4); (3) unduhan tema S3 (§4); (4) tautan Play Store (aplikasi sendiri + promosi silang `com.dimcoms.checkers` milik penerbit yang sama).

**Kesimpulan:** `INTERNET` hanya untuk analitik, atribusi iklan, billing, dan unduh tema. Tidak ada pertandingan melawan manusia jarak jauh dalam bentuk apa pun; lawan "online" tidak ada — yang ada hanya engine lokal, 2-pemain satu perangkat, dan puzzle.

---

## 4. Ekonomi

- **Mata uang lokal:** saldo koin disimpan di SharedPreferences kunci `"ui_layout_cache"` di-XOR `51321`. Akses premium (`j2.j.h()`): bila saldo ≥ 5000 → potong 5000, tulis balik ter-XOR, catat event analitik `premium_access_points`, dan set `"internal_sync_id"` = (sekarang + 2.592.000.000 ms = **30 hari**) di-XOR `6718836467351654535`.
- **Buka level per level:** boolean `chess_fullUnlocked_<n>` + penghitung `chess_fullUnlocked_count_<n>` di preferensi; berkas preferensi bernama (helper `j2.j.q/d/e`): `LevelUnlocked.xml`, `LevelUnlocked_pack2.xml`, `LevelPurchased.xml`, `LevelPurchased_pack2.xml`, `Training.xml` (nomor puzzle aktif), `Level.xml`, `Move.xml`.
- **Flag premium:** preferensi `chess_premium` diisi dari kunci warisan `checkers_removed_ads` (warisan aplikasi Checkers penerbit yang sama). String `TEST_PREMIUM` ada di dex. Ada helper verifikasi tanda tangan RSA `j2.j.W(String, String)`.
- **Pelaporan pembelian (server):** `f0/k.java` (sintetik R8) mengirim POST JSON `{packageName, transaction_id, purchaseToken, productId, appInstanceId (Firebase), amount, currency, source, purchased_at_ms}` ke `https://ywb04q5rq0.execute-api.us-east-1.amazonaws.com/purchase`. **Fire-and-forget:** kode respons hanya ditulis ke log (`Log.d "AWS_VERIFY"`); tidak ada gerbang apa pun yang menunggu hasil server.
- **Tema:** `SetActivity` (±:605-625) mengunduh zip tema dari `https://s3.amazonaws.com/publicfilesbox-chess/themes/{dark,gold,white,neo,ace,gray,green}_<density>.zip` via AsyncTask. Layout terkait: `dialog_premium`, `dialog_pack2`, `icon_lock_pack`, `icon_pack`.
- **Analisis** digerbang lokal per hari (`j2.j.i()`, §2.4); dialog buka hint: layout `dialog_reward`, tombol `btn_hint2`/`btn_hint_rew`/`btn_hint_wait`, string `warning_hint`.
- Tabel angka di `j2.j`: `f2060k = {100,120,150,190,240,320,420,560,750,1000}`, `f2061l = {10,20,30,50,100,200,500,1000,20,40,60,100,200,400,1000,2000}` — berbentuk tabel harga/hadiah; semantik persisnya belum terkonfirmasi.

**Vonis ekonomi (bukti):** seluruh keputusan buka/premium diambil **lokal** dari SharedPreferences di atas; server hanya menerima laporan pembelian pasca-fakta. Konsekuensi vonisnya ada di §6 (gerbang pembayaran tetap gerbang pembayaran).

---

## 5. Penyimpanan & progres

- State permainan per mode disimpan di SharedPreferences sebagai blob Base64, berkunci awalan per mode + indeks level (field kunci `f1575c0/f1576e0/f1578g0/f1579h0`, kunci hitungan `f1577f0 = "gameStateCountHint"`, kunci int `d0` dengan nilai 100 = tidak ada simpanan).
- Statistik menang/kalah/seri **per tingkat kesulitan** (`easy_win/loss/draw`, `medium_*`, `hard_*`, `expert_*` — `MainActivity.E(String)`) dan per warna (`MainActivity.F(String)`); preferensi `playas` (putih/hitam).
- Progres puzzle: nomor puzzle aktif di `Training.xml`; progres kampanye: bintang/kunci per level (§4).
- **Tidak ada sinkronisasi awan** (tidak ada kelas DB/Auth/Games — §3). **Tidak ada ELO/rating server**; yang ada hanya penghitung W/L/D lokal dan nilai strength engine.

---

## 6. Vonis per fitur (server vs lokal dulu)

| Fitur | Sifat | Vonis |
|---|---|---|
| Asistensi vs manusia jarak jauh (online) | Mode **terbukti tidak ada** (§3) | Tidak ada yang ditolak — tidak ada mode-nya. Kill switch anti-online tetap dispesifikasi (§9) sebagai pagar |
| Advisor prediksi / langkah terbaik (vs komputer, puzzle, analisis) | 100% lokal, memakai engine game sendiri | **DITERIMA** — wilayah analisis/latihan. Target persis §7 |
| Auto play (vs komputer, puzzle) | 100% lokal, lewat jalur langkah resmi game | **DITERIMA**. Target persis §8. Wajib mati di mode 2-pemain lokal (§9) |
| Log pemikiran bercabang (branching) | Lokal; skor + multi-PV tersedia dari engine sendiri | **DITERIMA** — tidak perlu engine tambahan. Bukti §7.4 |
| Manipulasi rating/ELO | Tidak ada ELO; hanya penghitung W/L/D lokal di preferensi | Kosmetik lokal semata — tidak ada rating server yang bisa dimanipulasi |
| Buka premium / koin | Bukti: gerbangnya lokal (preferensi ter-XOR, server hanya log pembelian) — **tetapi** yang digerbang adalah konten berbayar Play Billing (akses premium 5000 koin / IAP) | **DITOLAK** — melewati gerbang pembayaran nyata, walau penegakannya lokal. Tanpa desain/rincian implementasi |
| Hapus iklan | Tidak ada SDK penyaji iklan di dex (hanya `AdvertisingIdClient`) | Moot — tidak ada iklan yang disajikan untuk dihapus |
| Tambah puzzle orisinal (banyak level buatan sendiri) | Data di dex, format sederhana (§10) | **DITERIMA** — bentuk data persis + metode ekstensi §10 |

---

## 7. [BUILD] API engine milik game — untuk advisor prediksi & log bercabang

### 7.1 Membuat & mengirim tugas pencarian (jalur resmi game)
Objek tugas: `m2.b` (DTO). Pabrik statisnya (`m2/b.java:70`):

```java
public static m2.b a(int posId, long startMillis, o2.k position, java.util.ArrayList history,
                     o2.k startPos, boolean drawOffer, int timeA, int timeB,
                     int clockA, int clockB, int n60, String engineName, int strength, boolean analysisFlag)
```
(Pemetaan nama parameter disimpulkan dari dua situs pemanggil di bawah — urutan/tipe persis dari dex.)

Pengiriman: `m2.c.k(m2.b)` (:590) pada runner `m2.c` yang dipegang controller sebagai `o2.c.f2559a`. Pengikatan engine: `m2.c.j(n2.a, String)` (:532); opsi engine: `m2.c.f(String)` / `m2.c.h(String[])`; nilai **MultiPV dikirim ke engine di `m2/c.java:312`** (`b("MultiPV", …)`).

Dua situs pemanggil kanonis:
- **Jurus komputer:** `o2/c.java:1028` — strength = `f2567k` (sesuai kesulitan), flag terakhir `false`.
- **Hint bawaan game:** `MainActivity.hintPressed(View)` (:1849) — strength **1000 (penuh)**, flag terakhir `true`, waktu dari `f1593v`, jam dari state `o2.o`. Inilah bukti bahwa pencarian terdalam atas posisi saat ini memang jalur yang didukung game sendiri.

Signature inti engine mentah (bila diperlukan): `u.r.d(int,int,int,int,int,boolean)` (alpha-beta/PVS, `u/r.java:367`) dan `u.r.h(int,int,int,int,boolean)` (:583) — stateful dan ter-obfuscate berat; **jalur yang disarankan tetap `m2.b`/`m2.c`** di atas.

### 7.2 Memuat posisi arbitrer (pertanyaan c) — BISA, dua tingkat
- Tingkat game: `o2.c.n(String fen)` (`o2/c.java:880`, synchronized) — membangun `o2.d` baru dari teks FEN: `dVar.b.h(new o2.k(t0.a.m(str)))` lalu memasangnya via `p(dVar)`. Menerima FEN parsial gaya puzzle (`"<papan> w - -"`, §10). Dipakai stok untuk puzzle & kampanye lap 2.
- Tingkat engine: `public static final u.n u.c.i(String str)` (`u/c.java:214`) — FEN → posisi engine `u.n`, tanpa objek game apa pun.
- Tugas `m2.b` membawa posisinya sendiri (`o2.k` + `ArrayList` riwayat + `o2.k` posisi awal) — terpisah dari game yang sedang berjalan; jalur hint membuktikan pola snapshot non-destruktif (posisi disalin, hasil hanya jadi panah petunjuk). `o2.k` punya copy-constructor.

### 7.3 Skor evaluasi (pertanyaan a) — TERPAPAR PENUH
Engine memancarkan baris UCI `info depth %d score %s %d%s time %d nodes %d nps %d pv%s` (`u.r`, ±:470). Runner `m2.c` me-parse-nya token per token (`depth` :443, `multipv` :471, nilai skor `Integer.parseInt` :494, flag `upperbound`/`lowerbound` ±:495-505) dan membungkusnya menjadi objek baris:

```java
o2.l(int depth, int scoreCp, int timeMs, long nodes, int ?, long ?,
     boolean upperbound, boolean lowerbound, boolean book, java.util.ArrayList<o2.i> pv)
```
dibangun di `m2/c.java:523` per peringkat PV. Hasil diterima controller lewat sink `o2.b`:

- `o2.b.c(int depth, o2.k pos, ArrayList<o2.l> lines)` — daftar baris berpikir terbaru; skor `o2.l.b` dalam **centipawn** (ditampilkan game sebagai `skor/100.0` pion, `o2/b.java` `e()`), skor mate mengikuti pengkodean UCI `score mate N`.
- `o2.b.b(int score, String bestmoveStr)` — langkah terbaik + skornya; disimpan ke node pohon permainan (`o2.f.f2594n` = skor, `f2593m` = langkah) — inilah fondasi klasifikasi mutu langkah bawaan.
- `o2.b.a(int)` — reset sesi pencarian; `o2.b.d(int, String, o2.i, boolean)` — penerus tampilan ke UI thread.

### 7.4 Multi-PV & penilaian langkah kandidat (pertanyaan b)
- **Multi-PV: salurannya mendukung peringkat banyak baris.** Runner mengirim opsi `MultiPV` ke engine (`m2/c.java:312`), parser info menangani token `multipv` (:471), slot baris diindeks per peringkat PV dengan pengisi placeholder (`m2/c.java:511-523`), dan adapter engine mengenal `multipv` sebagai nama opsi (`n2/a.java:47`). Nilai aktifnya berasal dari peta opsi engine — menaikkannya lewat jalur opsi yang sama memberi beberapa baris berperingkat (masing-masing: depth, skor cp, PV lengkap) dalam **satu** pencarian.
- **Menilai langkah kandidat arbitrer: tidak ada API "skor-kan langkah ini" langsung.** Pola yang tersedia (dan yang dipakai game sendiri untuk mutu langkah): tiru posisi (`new o2.k(pos)`), terapkan langkah kandidat, jalankan tugas strength-1000 pada posisi hasil, balik tanda skornya. Setiap cabang = satu pencarian asinkron lewat antrean runner yang sama (mesin tunggal → cabang dievaluasi bergantian; anggaran waktu per cabang dari parameter waktu `m2.b`).

**Kesimpulan log bercabang:** advisor dapat membangun log berpikir yang bisa diaudit penuh — per simpul: FEN/posisi, langkah kandidat, skor cp/mate, depth, PV — **seluruhnya dari engine game sendiri** (MultiPV untuk saudara selevel + pencarian per-cabang untuk kedalaman), tanpa engine tambahan.

---

## 8. [BUILD] Jalur eksekusi langkah manusia — untuk auto play

Jalur sentuh stok: `j2.q` (OnTouchListener papan) — `ACTION_DOWN` mencatat petak lewat `ChessBoardPlay.c(MotionEvent)`; `ACTION_UP` pada petak yang sama memanggil `ChessBoardPlay.k(square)` yang membangun `o2.i`, melewati gerbang `R0.e()`, lalu **`MainActivity.R0.h(k3)`**.

Titik masuk programatis yang harus dipakai auto play — method yang sama dengan yang dipakai sentuhan:

```java
o2.c.h(o2.i move)   // o2/c.java:600, synchronized — R0 adalah o2.c milik MainActivity
```
- Bila game dalam state masukan langkah (`o2.d.f2579a`), `h()` memvalidasi lewat pembangkit legal + pencocokan string; bila tidak, memanggil validator **`o2.c.b(o2.i)`** (`o2/c.java:241`): daftar legal dari `new o2.j().g(position)`, dicocokkan pada field `o2.i.f2610a` (asal), `b` (tujuan), `c` (promosi); tak cocok → toast "invalid_move" + `false`.
- Sukses → **`o2.c.m(o2.k, o2.i, boolean)`** (`o2/c.java:768`) menerapkan langkah, lalu `y()` menyegarkan UI dan `MainActivity.A()` memperbarui tampilan / memicu balasan komputer. Promosi bertahap lewat `o2.c.f2572p`.

Jadi auto play cukup: bangun `o2.i(from, to, promo)` dari langkah pilihan engine (§7), panggil `R0.h(move)` — validasi, penerapan, dan balasan komputer semuanya berjalan lewat jalur resmi game. Langkah ilegal ditolak game sendiri dengan aman.

---

## 9. [BUILD] Deteksi mode runtime — kill switch gaya Pool Billiards

Semua penanda adalah field pada `MainActivity` (instans aktif dapat dicapai dari controller lewat `o2.c.f2563g`):

| Field | Tipe | Arti |
|---|---|---|
| `S0` | `static int` | 1 = vs komputer, 2 = dua pemain lokal |
| `T0` | `static boolean` | mode puzzle aktif |
| `U0` | `static boolean` | kampanye lap 2 |
| `C0` | `static String` | kode mode: `"0".."19"` kampanye, `"50"` dua pemain, `"100"` puzzle |
| `f1585m` | `int` | cermin instans dari `C0` |
| `f1553k0` | `boolean` | sub-mode analisis |

**Aturan gerbang yang dispesifikasi untuk build:** prediksi + auto play **ON hanya bila** `S0 == 1` (vs komputer) **atau** `T0 == true` (puzzle) — termasuk sub-mode analisis dari kedua mode itu. **OFF total** bila `S0 == 2` / `C0 == "50"` (ada manusia kedua di perangkat yang sama) dan pada nilai tak dikenal apa pun (fail-closed). Mode online vs manusia tidak ada untuk digerbang (§3 terverifikasi), jadi gerbang ini murni pagar lokal — dibaca segar pada setiap titik masuk fitur, sama seperti pola `isPVPMode()` di Pool Billiards.

---

## 10. [BUILD] Sistem puzzle — data, format, dan cara memperluas

- **Lokasi:** di dalam kode dex, kelas `j2.j` — bukan aset/db.
- **Bentuk data (persis):** dua array paralel —
  - `public static final String[] j2.j.f2062m` — **100** FEN parsial, format `"<penempatan bidak> w - -"`: hanya penempatan + giliran (`w` pada semua entri stok) + rokade `-` + en-passant `-`, **tanpa** halfmove/fullmove. Contoh entri pertama: `2r4k/1R5p/p4b2/8/2q2P2/3Q4/6PP/5R1K w - -`.
  - `public static final int[] j2.j.f2063n` — mate-in-N sejajar indeks: indeks 0–9 → 1, 10–29 → 2, 30–59 → 3, 60–99 → 4.
  - (Tetangga, sistem berbeda: `j2.j.f2064o` `String[10]` = FEN pasukan kustom kampanye lap 2 — bukan puzzle.)
- **Satu entri level = satu string di `f2062m` + satu int di `f2063n` pada indeks yang sama.** Itulah seluruh bentuk data yang perlu dibuat untuk level baru: posisi mate-in-N, Putih jalan, format string persis di atas.
- **Pemuatan:** mode puzzle (`T0`) memanggil `R0.n(j.f2062m[P0])` — situs `MainActivity:2061` dan `:2913` — keduanya dengan cek batas **tertanam `P0 >= 0 && P0 < 100`**. Label mate dibaca dari `f2063n[P0]` (`MainActivity:2207`, `:3082`, `:3295`; `o2/c.java:1229`). Progresi di `j2/n.java` case 16: `P0+1`; pada `>= 100` mode puzzle keluar (`T0=false, C0="0"`). Nomor puzzle aktif tersimpan di `Training.xml`. Hasil win/lose/draw hanya dicatat sebagai event Firebase Analytics (`game_puzzle_win/lose/draw/played`, `puzzle_number`) — tanpa efek gerbang.
- **Ekstensi oleh hook:**
  - **Isi 100 slot yang ada dapat diganti elemen per elemen** tanpa menyentuh deklarasi field — cukup untuk menerbitkan set puzzle orisinal penuh (array adalah objek yang isinya bisa ditulis).
  - **Lebih dari 100** butuh dua hal tambahan: mengganti objek array pada field statis `final` (penulisan ulang field via reflection) **dan** melonggarkan konstanta `100` pada kedua situs pemuat + situs progresi di atas. Cantumkan sebagai pekerjaan patch tersendiri dengan target persis tersebut.
  - Validasi level buatan: jalankan tugas strength-1000 (§7.1) pada FEN-nya — engine game sendiri harus melaporkan `score mate N` sesuai `f2063n` sebelum level diterbitkan.

---

*Selesai. Analisis saja — tidak ada build mod yang dibuat dalam tugas ini. Semua target build di §7–§10 menunggu perintah bangun terpisah.*
