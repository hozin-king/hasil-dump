# Audit + Daftar Fitur Root Injector — Warung Life Simulator 1.2
## (Kerangka HCR — diadaptasi untuk Godot)

**Tanggal:** 22 November 2026
**Target:** `com.neopawstudio.warunglife` 1.2 (code 49), Godot 4.7.2
**Status tahap ini:** ANALISIS + AUDIT SAJA. Injector **belum dibangun** — build setelah user memilih fitur.
**Dokumen pendamping:** `REA-WARUNG-LIFE-SIMULATOR.md` (laporan REA lengkap), `dump-full/hook_targets_1.2.yaml` (target per lapis).

---

## 1. Kerangka HCR yang dipakai — dan apa yang harus berubah

Kerangka HCR Mod (`~/workspace/hozin-hcr-mod/`, GOAL.md dibaca) terdiri dari:

| Elemen kerangka HCR | Status untuk Warung Life | Keterangan |
|---|---|---|
| Aplikasi root + auto-launch game (`am start`, fallback `monkey`) | **PAKAI APA ADANYA** | Game belum jalan → app membukanya sendiri, lalu inject/edit. Sama seperti HCR. |
| Auto-inject (foreground service + polling `pidof` ~2 dtk, inject 1×/PID) | **PAKAI, diubah maknanya** | Untuk game ini "inject" utama = edit save/config via root (lihat §2). Polling tetap dipakai untuk mendeteksi game jalan/mati. |
| Overlay floating logo (draggable) → panel toggle | **PAKAI APA ADANYA** | Toggle default OFF, tidak bisa ON sebelum "payload" (di sini: mesin edit save) siap. Sama seperti HCR. |
| Payload `.so` + pattern-scan (tahan update) | **DIGANTI** | Tidak ada method bernama di Godot (`.so` stripped). Pattern-scan IL2CPP tidak berlaku. Pengganti: (A) edit file save/config — tidak butuh pola sama sekali; (B) riset hook engine `FileAccess`/`JSON`/`HTTPRequest` via string anchor — pola **belum di-resolve** (butuh Ghidra). |
| Status JSON + tab Diagnosis (tanpa logcat) | **PAKAI APA ADANYA** | Payload/mesin edit WAJIB menulis status per fitur (`ok/gagal/alasan`) + hasil read-back (baca ulang file sesudah edit) supaya diagnosis POCO bisa dibaca tanpa Termux. |
| Fail-closed per fitur | **PAKAI APA ADANYA** | Fitur yang targetnya tidak ketemu (file tidak ada / game versi lain) = NONAKTIF, bukan crash, bukan nilai asal-asalan. |
| Version gate | **PAKAI — 1.2/code 49 SAJA** | Cek `versionCode` + `cek_versi.gd KODE_BUILD_ANDROID=49`. Build lain = tolak. (Game juga punya cek versi jarak jauh `versi.json min_kode` yang bisa memaksa update.) |
| Pre-create file status chmod 666 (UID game tidak bisa buat file di `/data/local/tmp`) | **PAKAI APA ADANYA** | Berlaku bila ada komponen yang jalan di dalam proses game. Untuk edit save via root, yang menulis adalah app (root) — bukan game. |
| ptrace GETREGSET + `strerror(errno)` di tiap kegagalan | **PAKAI bila ada .so** | Hanya relevan bila jalur (B) hook engine dibangun. Jalur (A) tidak memakai ptrace sama sekali. |
| Dobby static + `-static-libstdc++`, stage dari nativeLibraryDir | **PAKAI bila ada .so** | Sama — hanya relevan untuk jalur (B). |
| Toggle OFF saat game mati; overlay tetap tampil (anti-gagal) | **PAKAI APA ADANYA** | Standar injector root: logo floating selalu tampil apa pun hasil inject. |

### 1.1 Dua jalur implementasi — rekomendasi

**Jalur A (DIREKOMENDASIKAN, bangun dulu): Companion root app — edit save/config.**
- App (root) membaca `simpanan_N.json` + `pengaturan.cfg` di `/data/data/com.neopawstudio.warunglife/files/`, mengubah nilai sesuai toggle, menulis kembali **dengan pola atomik yang sama seperti game** (tulis `.tmp` → cek ukuran → rename lama ke `.bak` → rename `.tmp` ke final), lalu memberi tahu game (atau restart scene) agar nilai baru terbaca.
- Keuntungan: tanpa pola engine, tanpa risiko crash dlopen, bekerja 100% dari yang terbukti di dump, tahan update selama format save tidak berubah (format save stabil antar minor — dicek ulang tiap update via version gate).
- Kelemahan: perubahan baru terlihat saat game load ulang slot / baca ulang nilai (sebagian nilai dibaca tiap frame dari `GameState` di memori — edit file saat game jalan TIDAK langsung mengubah memori; perlu restart game atau trigger `muat()`). Ini harus dijelaskan jujur di UI ("tutup game dulu" / "restart untuk menerapkan").
- **Jalur A saja sudah mencakup SEMUA fitur kelompok (a).**

**Jalur B (RISET, jangan dijanjikan dulu): Payload .so hook engine Godot.**
- Hook `FileAccess::get_file_as_string` / `store_string` (intersep baca/tulis save), `JSON::parse_string` (rewrite hasil parse di memori → efek langsung tanpa restart), `HTTPRequest::_request` (blokir/awasi RPC).
- Status: **pola belum ditemukan**. Yang ada hanya string anchor di `.so` (lihat `hook_targets_1.2.yaml` lapis C). Butuh disassembly Ghidra/IDA + uji POCO. Perkiraan usaha: besar, hasil tidak pasti.
- Jalur B HANYA dibutuhkan bila user minta efek **langsung tanpa restart** (mis. uang berubah saat game jalan) atau fitur yang tidak bisa dicapai lewat file (mis. freeze waktu di memori).

**Keputusan arsitektur diserahkan ke user:** Jalur A saja (cepat, andal), atau A + riset B.

---

## 2. Audit keamanan (ringkas — detail di REA §6)

- **Tidak ada root detection, Play Integrity, SafetyNet, LVL, atau obfuscation script.** Save JSON polos tanpa enkripsi/hash. Siapa pun dengan root bisa mengedit save.
- **Pembelian IAP diverifikasi server** (Edge Function → Google Play) — tidak bisa dipalsukan dari client.
- **Leaderboard ditandatangani HMAC-SHA256 dengan kunci yang ada di client** — proteksi semu; tetap DITOLAK untuk dimanipulasi (lihat §5).
- **Cek versi jarak jauh bisa memaksa update** — version gate 49 wajib.
- **Cloud backup mengirim save apa adanya** (base64+gzip, tanpa enkripsi); validasi isi oleh server **belum terbukti** — jangan andalkan cloud untuk "mengesahkan" save editan.

---

## 3. Kelompok (a) — BOLEH (solo/offline, terbukti dari dump)

Semua fitur ini bekerja **via Jalur A (edit save/config)**. Target file + kunci ada di `hook_targets_1.2.yaml` lapis A. Semua default **OFF**, fail-closed, version gate 49.

| # | Fitur | Cara kerja (Jalur A) | Target (file/kunci) | Catatan |
|---|---|---|---|---|
| A1 | **Uang banyak** (atur jumlah Rp) | Tulis `uang` di `simpanan_N.json` | `simpanan_N.json: uang` (int) | Satu-satunya mata uang; semua transaksi client-side. Nilai wajar: saran maks Rp99.999.999 supaya tidak merusak pacing cerita (bukan batas teknis). |
| A2 | **Energi penuh / tidak berkurang** | Tulis `energi: 100.0` di save; atau (Jalur B) hook `_kurangi_energi` | `simpanan_N.json: energi` (float 0..100) | Drain: 0,039/mnt siang, 0,099/mnt malam, lari 0,42/dtk (`game_state.gd` ~917–948). Edit file = energi penuh saat load; "tidak berkurang" butuh Jalur B / edit berkala. |
| A3 | **Stok penuh semua barang** | Tulis `stok: {id: 100}` untuk 37 barang | `simpanan_N.json: stok` (maks 100/barang) | Daftar 37 id di `data/barang.json`. |
| A4 | **Buka semua barang** | Tulis semua 37 id ke `barang_terbuka` | `simpanan_N.json: barang_terbuka` | Barang normalnya terbuka bertahap per level. |
| A5 | **Buka semua upgrade** | Tulis 12 id ke `upgrade_dimiliki` | `simpanan_N.json: upgrade_dimiliki` | 12 upgrade, Rp425K–3,19jt (`data/upgrade.json`). Efek langsung berlaku (ramai/sabar/kurir/dll. dihitung dari daftar ini). |
| A6 | **Naik level / progres tugas penuh** | Tulis `tingkat` + `progres: {pelanggan, barang, omzet, khusus}` penuh | `simpanan_N.json: tingkat, progres` | Level 0-based (tampil = +1), maks 10 (L11 "Coming Soon"). Target tiap level di `data/tugas.json`. Hadiah level ikut diberikan saat `_cek_tugas` jalan — hadiah berupa uang/barang/upgrade. |
| A7 | **Reputasi / bintang maks** | Tulis `reputasi` tinggi | `simpanan_N.json: reputasi` (float) | Bintang dihitung dari reputasi (`_bintang_dari`). Reputasi hanya menambah keramaian, bukan syarat level. |
| A8 | **Waktu beku / atur jam & hari** | Tulis `menit` (jam) dan `hari` | `simpanan_N.json: menit, hari` | Jam: 420=07:00, 540=09:00 (buka), 960=16:00, 1260=21:00. "Beku" penuh butuh Jalur B (hentikan `majukan_waktu`/`_process`). |
| A9 | **Saldo layanan + saldo digital penuh** | Tulis `saldo_layanan`, `saldo_digital` | `simpanan_N.json: saldo_layanan (awal 50K), saldo_digital` | Dipakai untuk top-up/data/token + bayar QRIS. |
| A10 | **Bebas sewa / kios milik sendiri** | Tulis `kios_milik: true`, `tunggakan_sewa: 0` | `simpanan_N.json: kios_milik, tunggakan_sewa, sewa_cicil, denda_sewa_hari` | Menghapus biaya sewa + denda. |
| A11 | **Motor lunas / anti-sita** | Tulis `motor_cicil` lunas + `motor_disita: false` | `simpanan_N.json: motor_cicil, motor_disita, motor_baru` | Motor wishlist Rp12jt, DP 2jt + 10 cicilan; matel datang jam 11:00 bila telat. |
| A12 | **Rumah + HP wishlist** | Tulis `rumah_renovasi: true`, `hape_mewah: true` | `simpanan_N.json: rumah_renovasi, hape_mewah` | Rumah → drain energi ×0,85; motor → waktu kirim ×0,6 (efek dihitung dari flag ini). |
| A13 | **Utang warga lunas / hapus utang** | Edit/bersihkan `hutang` | `simpanan_N.json: hutang` | Buku hutang: daftar utang warga + status tagih. |
| A14 | **Ngojol: reset order harian / uang ngojol** | Edit `ngojol` | `simpanan_N.json: ngojol` | Order maks 5/hari; reset = bisa ngojol lagi hari yang sama. |
| A15 | **Istirahat/ngopi/makan tanpa batas harian** | Reset `istirahat_hari` | `simpanan_N.json: istirahat_hari` | Batas normal 1×/hari tiap jenis (kopi +30, makan +30). |
| A16 | **Buka semua misi/cerita (bab)** | Tulis `bab`, `misi_status` | `simpanan_N.json: bab, misi_status, cerita_tamat` | Hati-hati: lompat bab bisa melewatkan trigger cerita / soft-lock — beri peringatan di UI, default OFF. |
| A17 | **Keakraban warga maks** | Tulis `keakraban` | `simpanan_N.json: keakraban` | Mempengaruhi dialog + peluang. |
| A18 | **Harga jual custom (untung besar)** | Tulis `harga_jual_khusus` | `simpanan_N.json: harga_jual_khusus` | Ada batas atas (`batas_harga_jual`, `rasio_harga`) — harga di atas batas bikin pelanggan batal. Saran: naikkan moderat, bukan mentok. |
| A19 | **Iklan: energi/upah tanpa nonton** (lokal) | — | — | Perilaku ini **sudah ada di game**: bila `tanpa_iklan` aktif, hadiah iklan diberikan langsung. Lihat A20 — ini jalurnya, bukan bypass iklan. |
| A20 | **Bebas iklan (lokal)** | Tulis `toko.tanpa_iklan: true` di `pengaturan.cfg` | `pengaturan.cfg [toko] tanpa_iklan` | **Dengan catatan besar (lihat §3.1):** flag ini client-side; game juga bisa mendapatkannya gratis lewat login harian hari ke-26 / kode promo. Entitlement server TIDAK ikut terdaftar — efeknya lokal saja (tidak ada gelar pendukung, tidak ada kode pendukung). Bukan pembelian — tidak menyentuh Play Billing sama sekali. |

### 3.1 Catatan khusus A20 (bebas iklan) — baca sebelum memilih
- Menyalakan flag lokal `tanpa_iklan` **bukan** membobol IAP: tidak ada transaksi Play yang dipalsukan, tidak ada token pembelian yang dibuat. Ini sama dengan yang game berikan gratis lewat login harian hari ke-26.
- Yang TIDAK didapat dari flag lokal: gelar ★ Warga Baik Hati/Peduli di leaderboard + kode pendukung + ucapan di genteng warung — semua itu dicatat server saat pembelian terverifikasi.
- `cek_hak_bebas_iklan()` di game hanya bisa MENGAKTIFKAN dari server, tidak pernah mencabut flag lokal — jadi flag lokal tidak akan "ketahuan dan dicabut" oleh game. Risiko yang tersisa adalah bila server suatu hari memvalidasi entitlement saat sinkronisasi — **belum terbukti** ada validasi semacam itu.
- Bila user ragu, A20 bisa dicoret dan diganti dengan "ingatkan login harian" (fitur pengingat, bukan mod).

---

## 4. Kelompok (b) — PERLU VERIFIKASI (belum bisa dipastikan dari statik)

Fitur-fitur ini **jangan dibangun** sebelum verifikasi runtime (akun kedua, amati perilaku server). Masing-masing butuh satu jawaban yang hanya bisa didapat dengan menguji:

| # | Fitur / pertanyaan | Yang belum diketahui | Cara verifikasi |
|---|---|---|---|
| B1 | **Apakah save editan lolos restore cloud?** | Apakah server memvalidasi isi paket `cadangan_simpan`/`cadangan_ambil` (mis. uang tidak wajar, progres tidak konsisten)? Logika server tidak terlihat. | Edit save → backup cloud → hapus lokal → restore → lihat apakah nilai editan kembali utuh atau ditolak/direset. |
| B2 | **Apakah skor leaderboard tervalidasi?** | Apakah server menolak `kirim_skor5` yang tidak masuk akal (mis. omzet raksasa di hari ke-1)? Rate-limit? Deteksi anomali? | (Hanya untuk diagnosis — JANGAN kirim skor palsu ke leaderboard publik. Uji di akun kedua bila perlu, dan tetap masuk kelompok DITOLAK untuk fitur.) |
| B3 | **Apakah .gdc yang dimodifikasi bisa di-load?** | Tidak ada pengecekan integritas di client, tapi perilaku engine terhadap bytecode yang di-recompile GDRE belum diuji. | Coba ganti satu `.gdc` kecil di asset pack (butuh repack split APK + install ulang) — berat; hanya bila Jalur B dipilih. |
| B4 | **Pola engine (Jalur B)** | Alamat fungsi `FileAccess`/`JSON`/`HTTPRequest` + pola byte unik di `libgodot_android.so` (stripped). | Disassembly Ghidra/IDA (tidak tersedia di VM) + uji POCO. |
| B5 | **Apakah edit save saat game jalan langsung terbaca?** | Sebagian nilai dibaca dari `GameState` di memori tiap frame; sebagian hanya saat load. Perilaku per kunci belum dipetakan. | Uji POCO: edit satu kunci saat game jalan → amati apakah HUD berubah tanpa restart. Hasilnya menentukan apakah Jalur A butuh "restart game" atau cukup "tutup-buka warung". |
| B6 | **Hadiah kode promo berupa uang** | Alur `pakai_kode_promo` di client hanya menangani `bebas_iklan` dan `baju:` secara eksplisit; hadiah lain (uang?) tidak terlihat. | Tidak relevan untuk mod (kode promo = server, DITOLAK) — dicatat saja supaya tidak salah klaim. |
| B7 | **Apakah billing aktif di build 1.2?** | Pesan game bilang pembelian baru bisa "setelah rilis di Play Store". Singleton `GodotGooglePlayBilling` mungkin tidak ada di build ini. | Cek di POCO (bila game sudah ter-install): buka layar dukungan → apakah harga muncul atau pesan "belum rilis". |

---

## 5. Kelompok (c) — DITOLAK

| # | Yang ditolak | Alasan |
|---|---|---|
| C1 | **IAP / donasi gratis** (`tanpa_iklan` Rp29.000, `dukung_*` Rp15–99K) — memalsukan pembelian, membuat purchase token palsu, atau mengaku sudah bayar ke server | Uang sungguhan. Pembelian diverifikasi server via Google Play. Memalsukan = penipuan terhadap developer. (Flag lokal A20 bukan ini — A20 tidak menyentuh transaksi apa pun.) |
| C2 | **Leaderboard** — skor palsu, jempol palsu, lapor palsu, hapus skor orang, gelar pendukung palsu | Data milik bersama (papan peringkat publik). Memakai kunci HMAC `RAHASIA` dari client untuk memalsukan kiriman = menyerang server developer. Skor/jempol mempengaruhi pemain lain. |
| C3 | **Kode promo server** — menebak/brute-force kode promo, memakai `KODE_PENGEMBANG_HASH` untuk mencari kode pengembang | Kode promo adalah pemberian developer; kode pengembang adalah backdoor internal (hash SHA-256, tidak bisa dipulihkan — dan tidak boleh dicoba). |
| C4 | **Bypass verifikasi pembelian** — memalsukan respons Edge Function `verifikasi-pembelian`, memalsukan `cek_hak_bebas_iklan` / `buat_kode_pendukung` | Sama dengan C1: menyerang verifikasi server. |
| C5 | **Bypass cek versi / update wajib** (`versi.json min_kode`) | Mengakali gerbang versi developer; juga berbahaya (save versi lama bisa rusak). Version gate injector justru harus menghormatinya. |
| C6 | **Blokir/sabotase analitik orang lain atau crash report** | Analitik game ini per-pemain dan bisa dimatikan dari pengaturan (`atur_aktif`) — tidak ada yang perlu di-bypass. Memblokir RPC orang lain = di luar scope. |
| C7 | **Multiplayer / main bareng** | Game ini tidak punya multiplayer. Tidak ada yang bisa diaktifkan. |
| C8 | **God-mode dev (`god_mode.gd`)** | File tidak ada di build rilis. Tidak bisa "mengaktifkan" sesuatu yang tidak ikut ter-export. Jangan klaim bisa. |
| C9 | **Membuka file `rek_promo_neopaw.gd` sebagai fitur** | Itu autopilot perekam video dev (dead code). Bukan fitur gameplay. |

---

## 6. Rencana build yang disarankan (menunggu pilihan user)

**Fase 1 — Jalur A (companion root app, kerangka HCR):**
1. App `com.hozinking.warungmod`: auto-launch game → deteksi PID → baca `simpanan_N.json` (pilih slot aktif) + `pengaturan.cfg`.
2. Overlay floating logo → panel toggle untuk fitur A1–A18 + A20 (bila dipilih).
3. Tiap toggle: backup dulu (salin save ke `.bak` dengan stempel waktu) → tulis atomik (pola `.tmp` + `.bak` seperti game) → read-back verifikasi → tulis status JSON → tampilkan di Diagnosis.
4. Semua toggle default OFF. Perubahan diterapkan saat game load ulang (beri tahu user: "restart game" bila perlu — hasil B5 menentukan pesannya).
5. Version gate 1.2/code 49 + tolak bila `versi.json` remote `min_kode` > 49 (beri tahu user untuk update game dulu).
6. Build HANYA di GitHub Actions (aturan standar), rilis = link saja.

**Fase 2 — Riset Jalur B (hanya bila user minta efek tanpa restart):**
- Cari pola `FileAccess`/`JSON`/`HTTPRequest` di `libgodot_android.so` via disassembly (Ghidra) + uji POCO. Tanpa janji.

**Yang TIDAK dibangun:** semua kelompok (c); semua kelompok (b) sebelum verifikasinya selesai.

---

## 7. Yang perlu dipilih user

1. **Fitur mana dari kelompok (a) yang dibangun?** (Bisa semua, bisa sebagian — sebutkan nomornya, mis. "A1, A2, A3, A5".)
2. **A20 (bebas iklan lokal) ikut atau dicoret?** (Baca §3.1 dulu.)
3. **Jalur A saja, atau A + riset Jalur B?**
4. **Apakah game sudah ter-install di POCO?** (Untuk B5/B7 — menentukan pesan "restart" dan apakah billing aktif.)
