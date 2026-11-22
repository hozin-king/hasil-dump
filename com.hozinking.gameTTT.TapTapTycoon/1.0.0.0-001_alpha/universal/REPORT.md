> Catatan arsip: Aplikasi milik user sendiri (bukan game pihak ketiga).

# REA — Tap Tap Tycoon (com.hozinking.gameTTT.TapTapTycoon)

**APK:** `Tap_Tap_Tycoon_1.0.0.0_001_alpha_0_ulel.apk` — 423.092 B,
SHA-256 `45f8a560dab269f13e362d2dd55bc46a2b781b00d34f51feb079be911054a4fd`
**Package:** `com.hozinking.gameTTT.TapTapTycoon`, versionCode 1,
versionName `1.0.0.0 001_alpha`, minSdk 21, targetSdk 39
**Signer asli:** AOSP test key (`CN=Android, O=Android`, SHA-256 `a40da80a…`)
— kunci debug generik Sketchware, BUKAN keystore persisten. APK hasil port
(penanda baru) TIDAK bisa timpa install alpha: user harus uninstall dulu.
**Tanggal REA:** 16 Nov 2026. Bukti: `apk/` (hasil unzip), `/tmp/ttt-apktool/`.

## 1. Struktur APK

| Komponen | Isi |
|---|---|
| `AndroidManifest.xml` | `SketchApplication`, `MainActivity` (launcher, portrait), `DebugActivity`, `uses-library org.apache.http.legacy` |
| `classes.dex` (224 KB) | Runtime Sketchware + Apache HttpClient + framework Android |
| `classes2.dex` (32 KB) | `MainActivity`, `DebugActivity`, `FileUtil`, `SketchApplication`, `SketchLogger`, `SketchwareUtil` |
| `assets/` (100 KB) | **HANYA 3 file: `game.js` (60.750 B, 697 baris), `index.html` (22.543 B, 388 baris), `style.css` (16.212 B, 720 baris)** |
| `res/` | Ikon launcher mipmap (240×240 xxxhdpi), layout Sketchware |

**Shell (terbukti dari smali `MainActivity`):** satu `WebView` —
`setJavaScriptEnabled(true)`, `setDomStorageEnabled(true)`,
`setAllowFileAccess(true)`, `loadUrl("file:///android_asset/index.html")`.
Tidak ada `addJavascriptInterface`. Game 100% berjalan di WebView; kode
Java tidak mengandung logika game apa pun.

**Permission:** `INTERNET`, `ACCESS_NETWORK_STATE`,
`BIND_EXTERNAL_STORAGE_SERVICE`, `MANAGE_EXTERNAL_STORAGE`,
`READ/WRITE_EXTERNAL_STORAGE`, `WRITE_MEDIA_STORAGE`. Storage permission
tidak dipakai oleh game.js (tidak ada File API) — sisa template Sketchware.

## 2. Cara kerja game ("Cyber Tap Tycoon", neon clicker, 6 halaman)

- **Ringkasan:** tombol TAP besar; mata uang "Energi". Per Tap = `clickPower`
  (awal 1), CPS = `autoTappers` (awal 0). Daftar upgrade di bawahnya.
- **10 upgrade** (rumus beli: `cost = floor(cost × multiplier)`; bonus
  `+ (base + cost×0,01)` per level):
  | # | Nama | Bonus | Cost awal | × cost | Unlock |
  |---|---|---|---|---|---|
  | 1 | ⚡ Plasma Glove | +1/tap | 25 | 1,6 | — |
  | 2 | 🤖 Neon Drone | +1/dtk | 50 | 1,5 | Glove Lv 10 |
  | 3 | 🌌 Quantum Core | +10/dtk | 500 | 1,7 | Drone Lv 10 |
  | 4 | 🌋 Anti-Matter Gen | +75/dtk | 5.000 | 1,8 | Quantum Lv 10 |
  | 5 | 🛰️ Dyson Sphere Seg | +500/dtk | 75.000 | 1,9 | Anti-Matter Lv 10 |
  | 6 | Nova | +5.000/dtk | 500.000 | 2,0 | Dyson Lv 10 |
  | 7 | Singularity | +50.000/dtk | 5.000.000 | 2,1 | Nova Lv 10 |
  | 8 | Infinity | +500.000/dtk | 50.000.000 | 2,2 | Singularity Lv 10 |
  | 9 | Omega | +5.000.000/dtk | 500.000.000 | 2,3 | Infinity Lv 10 |
  | 10 | God | +50.000.000/dtk | 5.000.000.000 | 2,5 | Omega Lv 10 |
- **Modul:** baterai `autoUpgradeTimer` (awal 18.000 dtk = 5 jam).
  Auto-Clicker (1 tap / 5 dtk, makin cepat +0,1 dtk/level, min 0,5 dtk)
  dan Auto-Upgrade (1 target) HANYA jalan saat baterai > 0 dan
  menguras 1 dtk/dtk. Isi daya: `max(10, floor(kosong/3600)×10)`.
  Upgrade kapasitas +1 jam, cost ×2,5. **Quirk:** CPS (`autoTappers`)
  tetap mengalir walau baterai 0 — "Mogok" hanya mematikan sistem
  otomatis, bukan income pasif.
- **Offline progress:** saat load, `detikOffline × autoTappers`
  ditambahkan ke skor — **tanpa batas jam dan tanpa cek baterai**.
- **Loop:** tick 1 dtk (CPS + kuras baterai + auto-upgrade), tick
  auto-clicker 1 dtk, auto-save + sync cloud tiap 5 dtk.
- **Audio:** 100% sintesis WebAudio — SFX tap (sine 850→150 Hz,
  80 ms), bass loop sawtooth (8 nada, tiap 250 ms). Tanpa file audio.
- **Profil:** nama pemain (default `Hozinking`, maks 14 karakter),
  ID akun numerik 8 digit acak, teman, like, statistik
  (total selamanya / total klik / energi dihabiskan).
- **Repositori/Log:** "Sistem Enkripsi Kernel" — KOSMETIK. Log hanya
  catatan lokal (maks 25 baris), tidak ada deteksi nyata.
- **Setelan:** hanya Reset Progress (hapus save + reload).
- **Tanpa iklan, tanpa IAP.**

## 3. Save lokal — lemah (ini alasan user minta proteksi)

- `localStorage['cyberTap_saveData_secured']` = `base64( XOR(JSON, key) )`,
  kunci hardcode di game.js: `"HozinkingThunderSakti99"`.
- Siapa pun yang membuka APK bisa baca kunci + dekripsi + edit save
  (skor, level, dsb.) dalam hitungan detik. XOR + base64 bukan enkripsi.
- Token Supabase + email tersimpan di state yang sama (ikut ter-save).

## 4. Backend — Supabase (ini "sistem" yang dipindah ke hozinking.my.id)

Satu-satunya domain di seluruh JS: `https://hfdmjqorcctsajyrpdcd.supabase.co`.
**Anon key JWT tertanam polos di game.js** (baris 4-5).

| Fitur | Endpoint Supabase | Catatan |
|---|---|---|
| Auth daftar | `POST /auth/v1/signup` | email+password → OTP email |
| Auth verifikasi OTP | `POST /auth/v1/verify` | type signup, 6 digit |
| Auth login | `POST /auth/v1/token?grant_type=password` | |
| Leaderboard | `GET /rest/v1/cybertap_leaderboard?order=total_energy_all_time.desc&limit=20` | top 20 |
| Cloud save | `POST /rest/v1/cybertap_leaderboard?on_conflict=account_id` (upsert) | kirim: account_id, player_name, score, total_energy_all_time, click_level, auto_level, friends, likes, updated_at |
| Cloud load | `GET ...?account_id=eq.<id>` | **hanya pulihkan 5 field** (nama, skor, total, clickLevel, autoLevel) |
| Chat global | `GET/POST /rest/v1/cybertap_chats` (30 terakhir) | |
| Like | `PATCH ...?account_id=eq.<id>` `{likes: n+1}` | |
| Profil orang lain | `GET ...?account_id=eq.<id>` | + cari pemain, tambah teman |
| Report | — | **PALSU: hanya `alert()`, tidak ada request server** |

**Vonis keamanan backend (fakta, bukan tebakan):** anon key + nama tabel
terbuka di file JS. Siapa pun yang punya key bisa GET/PATCH/POST
leaderboard & chat dengan `account_id` sembarangan — menimpa skor orang
lain, menambah like, dan mengirim chat atas nama siapa pun. Tidak ada
bukti RLS yang membatasi di sisi klien; keamanan sepenuhnya bergantung
pada konfigurasi Supabase yang tidak terlihat dari APK. Token akses
disimpan XOR (lihat §3).

## 5. Bug / ketidaksesuaian yang ditemukan (dari membandingkan JS vs HTML)

1. **5 upgrade baru (Nova–God) TIDAK PUNYA kartu UI.** `index.html`
   hanya punya 5 kartu (Glove–Dyson); JS sudah punya state, harga,
   listener, dan target auto-upgrade untuk Nova–God, tapi
   `getElementById('upg-nova-cost')` dkk. = `null` (di-guard, tidak
   crash). Akibat: upgrade 6–10 **tidak bisa dibeli** di build ini.
   Halaman Modul juga hanya punya 5 target auto-upgrade.
2. **`visitorHistory` tidak pernah diisi.** Array selalu kosong;
   "Riwayat Pengunjung Profil" selalu menampilkan teks kosong.
   Fitur mati.
3. **Offline progress tanpa batas** (lihat §2).
4. **Cloud load tidak lengkap** — upgrade Quantum ke atas, baterai,
   auto-clicker, teman, dan like tidak dipulihkan (lihat §4).
5. `loadGame`: cabang `if/else` accountId melakukan hal yang sama
   kecuali regenerasi ID — tidak berbahaya, hanya redundan.

## 6. Vonis

- Game **offline-first**: semua ekonomi jalan lokal; online hanya
  leaderboard, chat, dan cloud save (Supabase). Tidak ada yang
  server-gated untuk progres inti.
- **Kelayakan port: SANGAT LAYAK.** `game.js` hanya 697 baris,
  logika murni aritmetika + state + timer. UI HTML/CSS 1.108 baris
  adalah daftar + tombol + tema neon — mudah direplikasi native.
- **Pendekatan port yang dipilih:** rewrite native penuh —
  logika game di C++ (`libtaptap.so` via JNI: state, ekonomi,
  baterai, offline progress, format angka/waktu), UI 6 halaman di
  Kotlin native (tanpa WebView sama sekali), save dienkripsi
  AES-256-GCM (AndroidKeyStore) di Kotlin, audio sintesis via
  AudioTrack. HTML/CSS/JS **tidak ikut** di APK hasil port.
  Alasan: game kecil dan deterministik; enkripsi aset saja tidak
  memenuhi perintah "pindah ke C++ / full jadi lib".
- **Perubahan perilaku yang disengaja (dicatat jujur):**
  - Ke-10 upgrade tampil di UI (build lama hanya 5 yang bisa dibeli).
  - `visitorHistory` dihapus (fitur mati; tidak ada sumber datanya).
  - Tombol Report benar-benar mengirim laporan ke server hozinking
    (dulu palsu) — atau dihapus bila endpoint belum ada. Diputuskan:
    dihapus dari UI v1, dicatat di sini.
  - Auth email+OTP Supabase TIDAK dimigrasi di v1 (butuh endpoint
    auth CMS + deploy Worker — perlu persetujuan user); identitas =
    accountId lokal + nama. Leaderboard/chat/cloud-save pindah ke
    `https://hozinking.my.id/api/taptap/*` (spesifikasi di
    `server/taptap-api.md`; Worker TIDAK di-deploy tanpa izin).
  - Save lama (localStorage WebView) TIDAK dimigrasi — mulai baru.
- **Proteksi yang dijanjikan vs nyata:** logika ekonomi + state di
  `.so` native (tidak bisa dibaca sebagai teks polos); save
  terenkripsi AES-GCM dengan kunci Keystore (tidak bisa dibuka
  tanpa device); R8 minify pada Kotlin. Ini BUKAN anti-cheat
  absolut — skor tetap bisa diubah di runtime oleh root — tapi
  jauh di atas XOR + HTML polos. Tidak ada klaim lebih dari itu.

## 7. AFK / idle + cloud save terikat akun (tambahan user 16 Nov 15:06)

Perintah: progres idle tetap jalan meskipun APK tidak dibuka, bahkan
meskipun APK dihapus; tidak lag; kuat menangani banyak pemain.

### Desain: offline progress berbasis TIMESTAMP (lazy evaluation)

- **Tidak ada loop/tick per pemain di server.** Server hanya menyimpan
  `last_seen_at` (jam server) + state. Saat pemain membuka game /
  klaim, server menghitung `earned = min(now_server - last_seen_at,
  8 jam) × CPS`. Selama APK tertutup (atau dihapus), server tidak
  mengerjakan apa-apa — "timer" hanyalah selisih dua timestamp yang
  dihitung saat klaim. Aplikasi: klaim otomatis saat buka game,
  dialog "Selamat Datang Kembali" menampilkan jam AFK + jumlah Energi.
- **Cap 8 jam (28.800 detik)** — berlaku di client DAN server.
  Alasan: (1) anti-cheat — jam server otoritatif, jam HP bisa diubah
  user, jadi klaim tanpa cap + jam HP = celah; cap membatasi
  keuntungan satu klaim; (2) ekonomi — klaim tunggal tidak boleh tak
  terbatas (mencegah "tinggalkan akun 1 tahun, kembali kaya");
  (3) 8 jam menutup tidur semalam (~7–8 jam), jendela idle yang
  wajar. Ini PERUBAHAN dari game asli (offline progress tanpa batas,
  §5.3) — disengaja, demi anti-cheat.
- **CPS dihitung server dari `levels`** (replay deterministik tabel
  upgrade, cermin engine C++ — teruji identik: drone Lv 2 = 3.25,
  glove 10/drone 10/quantum 1 = 81.39). Server TIDAK PERNAH percaya
  CPS kiriman client.
- **Baterai tidak menghalangi pendapatan idle** — setia pada quirk
  asli (§2: CPS tetap mengalir saat baterai 0; "Mogok" hanya
  menghentikan sistem otomatis).
- **Fallback lokal:** bila server belum live / offline, aplikasi
  menghitung dari `lastSavedMs` lokal (jam HP, cap yang sama 8 jam).
  Jalur ini lebih lemah (jam HP bisa diubah) — itu batas jalur lokal,
  bukan klaim server.

### Bila APK dihapus — jujur

- **DENGAN akun** (ID 8 digit dicatat + pernah sync ke server):
  install ulang → "Pulihkan Akun" → masukkan ID → profil dimuat
  dari server (skor/total/10 level) → klaim menghitung dari
  `last_seen_at`, jadi progres selama APK tidak ada tetap masuk
  (maks 8 jam). Timer "tetap berjalan" karena tidak ada proses yang
  perlu jalan — hanya timestamp yang dibandingkan saat klaim.
- **TANPA akun / tidak pernah sync:** progres hanya ada di save
  lokal terenkripsi di HP — ikut terhapus bersama data aplikasi —
  dan **TIDAK bisa kembali**. Tanpa akun/server, progres yang hanya
  di HP PASTI hilang bila APK dihapus. Mitigasi v1: ID tampil di
  halaman Profil + tombol salin; user harus mencatat ID-nya.
- **Akun v1 = ID 8 digit sebagai kunci pemulihan** (tanpa password/
  OTP — keputusan auth penuh menunggu user). Siapa pun yang tahu ID
  bisa memulihkan akun itu — model yang sama dengan upsert Supabase
  lama berdasar `account_id`. Bukan login aman.

### Database: D1 `stopwatch-db` (sama dengan Cerpen — tambahan 16 Nov 15:11)

- **JANGAN bikin database D1 baru.** Tabel TTT dibuat di
  `stopwatch-db` (UUID `9f103eb3-2be0-4a23-8967-ce69f0cae987`, 119
  tabel Cerpen) dengan prefix wajib `ttt_`:
  - `ttt_players` — akun + save + `last_seen_at` (SATU baris per
    pemain; lihat keputusan penamaan di bawah)
  - `ttt_chats` — pesan chat
- **Keputusan penamaan:** user menyarankan `ttt_accounts` /
  `ttt_saves` / `ttt_leaderboard`, tapi desain ini memakai SATU tabel
  `ttt_players` — klaim AFK butuh skor + level + `last_seen_at`
  sekaligus, jadi satu baris = 1 SELECT + 1 UPDATE tanpa JOIN;
  memisah akun/save jadi 2 tulis per klaim + 1 JOIN per baca.
  Leaderboard BUKAN tabel terpisah — query `ORDER BY
  total_energy_all_time DESC` di `ttt_players` dengan indeks,
  supaya tidak ada dual-write yang bisa drift.
- **Add-only, idempotent:** DDL `CREATE TABLE/INDEX IF NOT EXISTS`
  (`server/taptap_ddl.sql`) — hanya menambah tabel, TIDAK menyentuh
  tabel Cerpen. Diuji lokal di SQLite (D1 = SQLite) SEBELUM menyentuh
  D1 produksi: DDL 2x OK, tabel Cerpen simulasi utuh, upsert +
  klaim + leaderboard + chat + like semua lolos
  (`server/DDL-TEST.md`).
- **Binding Worker: `BACKUP_DB` SAJA** (sudah mengarah ke
  stopwatch-db). `DB` (cms-db) JANGAN dipakai untuk data TTT;
  bila `BACKUP_DB` tidak ada, endpoint mengembalikan 503 (tidak ada
  fallback diam-diam).

### Endpoint (spesifikasi di `server/taptap-api.md`, referensi di `server/worker-routes.js`)

- `POST /api/taptap/claim` `{account_id}` → `{earned,
  elapsed_seconds, capped, score, total_energy_all_time}` —
  1 SELECT (PK) + 1 UPDATE. **Belum di-deploy** (butuh persetujuan
  user, aturan 10 Nov).
- `POST /api/taptap/profile` — upsert save (levels 10 angka +
  `last_seen_at` = jam server). Cloud save menyimpan SEMUA 10 level
  (memperbaiki bug restore parsial asli yang hanya 2 level — Quantum
  ke atas hilang saat restore).
- `GET /api/taptap/profile/:id` — mengembalikan `levels` +
  `last_seen_at` (dipakai sinkronisasi antar-perangkat + restore).
- Aplikasi: sync cloud tiap 60 detik saat aktif (bukan tiap 5 detik),
  klaim hanya saat buka game, save lokal tiap 5 detik.

### Kenapa tidak lag walau banyak pemain

Semua operasi O(1) per pemain: klaim = 1 SELECT by PRIMARY KEY +
1 UPDATE; save = 1 UPSERT. Tidak ada cron, tidak ada loop per pemain,
tidak ada polling dari client saat idle (APK tertutup = 0 request).
10.000 pemain idle = 0 kerja server; 1.000 klaim/detik = 1.000 lookup
terindeks, masing-masing ~ms di D1. Bandingkan desain ticking:
N pemain × 1 tick/detik = N tulis/detik yang runtuh saat N besar.
Rate limit 60 req / 10 menit / IP mencegah spam klaim.
