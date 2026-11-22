# REA — Warung Life Simulator 1.2 (com.neopawstudio.warunglife)

**Tanggal:** 22 November 2026
**File game:** `~/workspace/rea-new-game/game.bin` (218.465.210 B, SHA-256 `550c9547ed4d34325c8d152c4ad9fb2187e66b63991b5d212ee99edd52257d44`)
**Workspace:** `~/workspace/rea-warung-life/`
**APK TIDAK pernah di-install / dijalankan. File game TIDAK di-upload ke mana pun.**

---

## 1. Ringkasan eksekutif

Warung Life Simulator adalah **game simulasi warung kelontong Indonesia** (berbahasa Indonesia, tokoh utama "Pak Misran") — jual-beli barang, layani pelanggan, naik level warung, kelola energi, utang-piutang warga, cicilan motor, ojek online, sampai cerita berseri. **Bukan game Unity — ini Godot 4.7.2.** Seluruh logika game ada di **132 file GDScript terkompilasi (.gdc)** yang berhasil di-decompile **penuh** (59.378 baris) — tidak ada satu pun bagian logika yang tersembunyi.

Temuan terpenting untuk injector:

1. **Ekonomi 100% lokal.** Satu mata uang (Rp), save berupa **JSON polos tanpa enkripsi dan tanpa checksum**. Semua yang bisa dimodifikasi (uang, energi, stok, level, upgrade, utang, cicilan) tinggal di-edit di file save — **tidak perlu inject .so sama sekali** untuk sebagian besar fitur.
2. **Satu-satunya yang server-side dan TIDAK bisa dipalsukan client-side: pembelian IAP** (verifikasi Google Play lewat Supabase Edge Function) dan **entitlement pendukung/no-ads yang terdaftar di server**. Leaderboard memang ditandatangani HMAC, tapi kuncinya ada di dalam client — jadi secara teknis bisa dipalsukan (tetap masuk kelompok DITOLAK).
3. **Tidak ada anti-cheat yang berarti.** Tanpa root detection, tanpa Play Integrity, tanpa LVL, tanpa obfuscation. Proteksi terkuatnya hanyalah: (a) cek versi jarak jauh yang bisa memaksa update, (b) verifikasi pembelian di server.
4. **Kerangka HCR tidak bisa dipakai mentah-mentah.** HCR dibangun untuk Unity IL2CPP (name resolver + pattern-scan terhadap method bernama). Di Godot, .so engine **stripped** (tanpa simbol) dan logika ada di bytecode GDScript — jadi "hook by name" tidak ada. Desain injector harus berubah (lihat §7 dan `AUDIT-DAN-FITUR-INJECTOR.md`).

---

## 2. Identitas & artefak

| Item | Nilai (terverifikasi) |
|---|---|
| Nama | Warung Life Simulator |
| Package | `com.neopawstudio.warunglife` |
| Version | 1.2 (versionCode **49**), targetSdk 36, minSdk 24 |
| File | `game.bin` 218.465.210 B, SHA-256 `550c9547…57d44` |
| Isi | Split APK: base.apk (14 MB), split_assetPackInstallTime.apk (208 MB), split_config.arm64_v8a.apk (73 MB), split_config.in.apk, split_config.xxhdpi.apk |
| Engine | **Godot 4.7.2.stable.official** (`libgodot_android.so` 71.114.944 B, stripped, BuildID sha1 `270121fe…e01d345c`) |
| Permissions | BILLING (IAP), INTERNET, ACCESS_NETWORK_STATE, AD_ID, WAKE_LOCK, RECEIVE_BOOT_COMPLETED, FOREGROUND_SERVICE, CHECK_LICENSE, DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION |
| DEX | classes.dex 8.326.756 B + classes2.dex 5.261.768 B; 12.202 class, ~96.682 method (mayoritas library) |
| Plugin Java | `com.neopawstudio.googlelogin.GodotGoogleLogin`, `com.neopawstudio.unityads.GodotUnityAds`, `org.godotengine.plugin.googleplaybilling.GodotGooglePlayBilling` (plugin resmi Godot, Kotlin) |

### 2.1 Struktur asset pack (split_assetPackInstallTime.apk, 1.272 entri)

Layout loose-file Godot 4: `assets/.godot/exported/133200997/` (8 scene), `assets/.godot/imported/`, `assets/scripts/` (**132 .gdc**), `assets/data/` (15 JSON), `assets/assets.sparsepck` (114.100 B — manifest PCK v4, 1.265 file, berisi index + `project.binary` + ikon; bukan konten tambahan).

Scene yang di-export (binary .scn): `main_menu`, `warung` (scene utama, script `warung.gd` 4.976 baris), `intro`, `pilih_penjaga`, `jelajah`, `pengaturan`, `placeholder`, + `tema.res`.

Per extension: 474 `.import`, 387 `.ctex` (tekstur), 140 `.remap`, **132 `.gdc`**, 54 `.scn`, 19 `.json`, 15 `.oggvorbisstr`, 13 `.sample`, 10 `.gdshader`, 8 `.mp3str`, 4 `.fontdata`, 2 `.png`, 2 `.ogv`, 1 `.xml`, 1 `.res`, 1 `.cfg`, 1 `.bin`, 1 `.sparsepck`, 1 `.gd` (stub kosong 0 byte — lihat §3.2).

---

## 3. Full dump — metode & hasil

### 3.1 Metode

Game ini **bukan Unity**: tidak ada `libil2cpp.so`, tidak ada Mono, tidak ada Unity player. Il2CppDumper **tidak berlaku**. Jalur dump yang benar:

1. Ekstrak split APK → temukan `libgodot_android.so` + `assets/` berisi `.gdc`.
2. **GDRE Tools v2.8.0-beta.2** (GDRETools/gdsdecomp, diunduh dari GitHub releases, 35 MB) — `gdre_tools.x86_64 --headless --bytecode=4.5.0 --decompile=<file>.gdc`.
3. Header `.gdc` diawali `GDSC` + bytecode version **101** (0x65) — sama dengan Godot 4.5.0-stable, jadi `--bytecode=4.5.0` berhasil men-decompile file Godot 4.7.2 ini tanpa error.
4. 3 file `export_plugin.gdc` (satu per addon) bertabrakan nama di output datar — di-decompile terpisah ke `addons/<nama>/`.

### 3.2 Hasil dump

| Metrik | Jumlah |
|---|---|
| File GDScript ter-decompile | **132** (unik; 133 file .gd karena export_plugin ×3) |
| Total baris | **59.378** |
| Fungsi (`func`) | **2.473** |
| Variabel | 1.550 |
| Konstanta | 1.457 |
| Signal | 65 |
| `class_name` global | 3 (`BillingClient`, `WarnaProyeksi`, `VarianBaju`) |
| Ukuran dump | 2,07 MB |

Lokasi: `~/workspace/rea-warung-life/dump-full/` (struktur direktori dipertahankan: `scripts/`, `scripts/hp/` 22 file, `scripts/minigame/` 14 file, `addons/`, `rekam/`), + `index.json` (per-file: baris/fungsi/SHA-256) + `stats.json`. **Tidak ada file .md di dalam dump-full** (sesuai aturan).

File terbesar: `scripts/game_state.gd` — **10.970 baris, 709 fungsi** — seluruh state + logika pusat game ada di satu file ini. Berikutnya: `scripts/warung.gd` (4.976 baris), `scripts/layanan.gd`, `scripts/pelanggan.gd`.

Catatan: `assets/gaya_hud.gd` yang ikut ter-export berukuran **0 byte** (stub kosong); script aslinya adalah `scripts/gaya_hud.gdc` yang berhasil di-decompile.

### 3.3 Yang TIDAK bisa di-dump dari statik

- **Logika server Supabase** (isi fungsi RPC `kirim_skor5`, `cek_hak_bebas_iklan`, `cadangan_simpan`, dsb. + Edge Function `verifikasi-pembelian`): hanya nama fungsi + parameter yang terlihat dari client; validasi di dalam server **tidak terlihat**.
- **Pola byte fungsi engine** di `libgodot_android.so` (stripped, tanpa simbol): butuh disassembly (Ghidra/IDA — tidak tersedia di VM ini). Hanya string anchor yang dicatat (lihat `hook_targets_1.2.yaml` lapis C).
- **Isi Addressables/remote**: tidak ada — semua data game ada di dalam APK (data JSON lokal).

---

## 4. Gambaran game

Pemain adalah **Pak Misran** (atau Ibu, bisa dipilih di `pilih_penjaga`), pemilik warung kelontong. Satu hari game: bangun 07:00 → persiapan → buka 09:00 → layani pelanggan → tutup (boleh tutup 16:00) → tidur (boleh tidur 21:00). Jumat libur (warung tutup, bisa ngojol/janji warga).

Sistem-sistem utama (semua di `game_state.gd` kecuali disebut lain):

- **Jual-beli**: 37 barang (`data/barang.json`) — 32 fisik + 5 layanan (top-up e-wallet, paket data 2/5/10 GB, token listrik). Tiap barang: `modal` (harga beli), `jual` (harga jual), `peluang` (probabilitas diminta), `stok_awal`. Marjin tipis (mis. mi goreng 2.500→3.500; minyak goreng 17.000→19.500). Harga jual bisa diubah pemain (`ubah_harga_jual`, ada `batas_harga_jual` + `rasio_harga` — harga terlalu mahal bikin pelanggan batal).
- **Level warung**: 10 level + Level 11 "Coming Soon" (`data/tugas.json`). Tiap level: target pelanggan/barang/omzet + tugas khusus (`beruntun` = layani N pelanggan tanpa batal, `multi`, `laba_hari`, `minuman`, `hari_sempurna`) + hadiah uang. Naik level membuka barang + upgrade baru. Reputasi (bintang) **bukan** syarat level (dihapus 29 Okt — hanya menambah keramaian).
- **Upgrade**: 12 upgrade (`data/upgrade.json`), Rp425.000–Rp3.190.000, level-gated: etalase (Lv1, 425K — wajib hari pertama), kipas (Lv2, 520K), lampu LED (Lv2, 620K), spanduk (Lv3, 830K), bangku (Lv3, 940K), kurir cepat (Lv4, 1.040K), radio (Lv5, 1.245K), QRIS (Lv6, 1.455K), CCTV (Lv7, 2.490K), genset (Lv8, 2.075K), TV warung (Lv9, 3.190K), WiFi (Lv10, 1.105K). Efek: ramai (+%), sabar (+%), maks antre, respon (detik melayani), tip, supplier (diskon harga beli), dsb. Batas total bonus ramai 50%, sabar 85%.
- **Energi**: 100 → drain 0,039/menit siang, 0,099/menit malam, lari 0,42/detik. Ngopi +30 dan makan mi rebus +30 (masing-masing **1×/hari**, pakai stok sendiri). Iklan rewarded → energi penuh 100% (**1×/hari**). Di bawah 20% tidak bisa buka warung. Ada aturan puasa Ramadhan (tidak ngopi/makan siang hari, buka puasa sekali setelah Maghrib 18:00).
- **Uang & biaya**: modal awal Rp630.000. Biaya harian casual Rp10.000 / hard Rp20.000. Bangkrut bila minus 3 hari (casual) / 1 hari (hard). Sewa kios: ada tunggakan, bisa dicicil, bisa beli kios (`kios_milik` = bebas sewa).
- **Wishlist** (impian besar): HP mewah Rp6.000.000 (Lv1), **motor Rp12.000.000 (Lv3 — DP Rp2.000.000 + cicilan 10×, ada debt collector "matel" datang jam 11:00 bila telat, motor bisa DISITA)**, rumah Rp18.000.000 (Lv6, renovasi → energi drain ×0,85; motor → waktu kirim ×0,6).
- **Buku hutang**: pinjamkan uang ke warga, tagih kemudian (tegas/baik-baik, lewat chat), ada yang telat bayar, ada yang ikhlas. Mempengaruhi reputasi + keakraban.
- **Ngojol** (ojek online, saat libur/malam): order 5 maks/hari, ongkos Rp5.000–30.000 (maks Rp35.000/order, maks malam Rp100.000), tip maks Rp5.000, bonus hujan ×1,25, pengali Jumat ×2. Butuh motor.
- **Layanan digital**: QRIS (peluang bayar QRIS 35% bila upgrade QRIS dibeli) → `saldo_digital`; top-up/data/token pakai `saldo_layanan` (isi otomatis Rp50.000, awal Rp50.000).
- **Minigame** (14, di `scripts/minigame/`): mg_dasar, mg_adu_laris, mg_bersih, mg_bungkus, mg_cocok, mg_kembalian, mg_langganan, mg_mancing, mg_ojol, mg_panen, mg_petik, mg_qris, mg_tata, mg_tumpuk — memberi upah + tip. Kerja sampingan ada yang minta tonton iklan untuk upah 2×.
- **HP dalam game** (17 aplikasi, `scripts/hp/`): belanja, bukukas (buku kas), harga, kalender, kalkulator, kontak, mbanking, misi, ojol, panduan, papan (leaderboard), peta, tas, ulasan, upgrade, wasap (chat warga — janji, tagih utang, cerita), wishlist.
- **Cerita**: berseri per bab (`data/cerita.json`), ada Agus (kurir/teman), misi, janji ketemu warga, ronda malam, pengajian, jumatan, takbiran, banjir/hujan, ketabrak kendaraan (biaya dokter / utang dokter), kucing "Neo" (bisa dikasih makan), dll.
- **Login harian**: Rp15.000/hari; milestone hari ke-4: 100K, 8: 150K, 12: 200K, 16: 250K, 20: 300K, 24: 350K, **26: bebas_iklan (GRATIS)**, 28: 400K, 30: baju.

---

## 5. Ekonomi — lokal vs server

### 5.1 Mata uang: SATU, lokal, tanpa premium currency

- **Hanya ada `uang` (Rp, int).** Tidak ada diamond/gem/koin premium. Semua harga dalam Rupiah dan semua transaksi dihitung client-side (`game_state.gd`: `jual` ~2356, `beli_stok` ~2393, `terima_qris` ~2423, `catat_transaksi` ~5881).
- **Tidak ada mata uang kedua.** `saldo_layanan` dan `saldo_digital` adalah sub-saldo Rupiah, bukan currency terpisah.
- **Tidak ada gacha / loot box / energi berbayar.** Energi hanya pulih lewat istirahat/ngopi/makan/iklan.

### 5.2 IAP — nyata, Google Play, server-validated

Produk (harga dari `dukungan.gd` + `game_state.gd`):

| Product ID | Harga Android | Isi |
|---|---|---|
| `tanpa_iklan` | **Rp29.000** | Bebas iklan (permanen) |
| `dukung_esteh` | Rp15.000 | Donasi: segelas kopi untuk tim |
| `dukung_nasipadang` | Rp35.000 | Donasi: makan siang tim |
| `dukung_game_45` | Rp60.000 | Donasi + **bebas iklan** |
| `dukung_game_100` | Rp99.000 | Donasi + **bebas iklan** |

(Harga iOS lebih mahal: 19K/49K/79K/129K.)

Alur pembelian (`game_state.gd` ~8955–9420):
1. `BillingClient.gd` = wrapper plugin resmi Godot (`org.godotengine.plugin.googleplaybilling`) → `queryProductDetails` → harga dari Play → `purchase(id)` → `on_purchase_updated`.
2. Pembelian lunas → `_catat_beli_lunas` + `_daftarkan_pendukung` → **verifikasi ke server** via Edge Function `POST https://vfeihrxdwynivqcksxwl.supabase.co/functions/v1/verifikasi-pembelian` (`papan_online.gd` ~418) dengan `{id_papan, token, produk, platform: android}`. Server memverifikasi token ke Google Play.
3. Hasil verifikasi → RPC `buat_kode_pendukung` → pemain dapat **kode pendukung** + gelar ★ Warga Baik Hati / ★ Warga Peduli di leaderboard + ucapan terima kasih di genteng warung.
4. Flag lokal `tanpa_iklan` disimpan di `pengaturan.cfg` (section `toko`).

**Catatan penting:**
- Pesan dalam game: *"Pembelian lewat Google Play bisa dilakukan setelah Warung Life rilis di Play Store"* — game ini **belum rilis di Play Store** saat build 1.2 dibuat (ada URL closed testing `play.google.com/apps/testing/com.neopawstudio.warunglife`; `MASA_UJI=false` di `cek_versi.gd` tapi logika tester masih ada). Billing kemungkinan belum aktif di build ini.
- **Bebas iklan bisa didapat GRATIS** lewat login harian hari ke-26 dan lewat kode promo (`hadiah == "bebas_iklan"`) — jadi IAP ini bukan satu-satunya jalan.
- **Tester** (yang main saat masa uji) **mempertahankan progres saat rilis**, pemain lain mulai dari nol — ini janji dev di layar dukungan.

### 5.3 Server (Supabase) — apa yang online, apa yang tidak

Backend: **Supabase** project `vfeihrxdwynivqcksxwl.supabase.co` + GitHub Pages `neopawstudio.github.io`.

| Layanan | Endpoint / RPC | Sifat |
|---|---|---|
| Leaderboard | `POST /rest/v1/rpc/kirim_skor5`, `ambil_papan2` | Kirim skor (total pembeli, omzet, bintang, level, hari) + ambil papan (tab semua/minggu/bulan). Skor = data lokal yang dikirim + HMAC (lihat §6). |
| Like / lapor | `beri_jempol`, `laporkan_nama`, `laporkan_nama2`, `hapus_skor` | Sosial leaderboard. Ada filter kata terlarang untuk nama warung (client-side, `papan_online.gd` ~120). |
| Pendukung | `buat_kode_pendukung`, `cek_kode_pendukung(2)`, `cek_bebas_iklan`, `cek_hak_bebas_iklan`, `ambil_warga_baik_hati`, `tandai_warga_baik_hati` | Entitlement no-ads + gelar pendukung, keyed by `id_papan`. |
| Promo | `pakai_kode_promo` | Kode promo server-validated (habis/kedaluwarsa/tidak_ada). Hadiah: bebas_iklan / baju / (uang — alur else di client tidak eksplisit). |
| Akun online | Supabase Auth (`/auth/v1/token`, id_token Google/Apple) + RPC `akun_status`, `akun_bonus`, `akun_hapus`; Edge Function `cabut-apple` | Login Google/Apple, tautan akun, hapus akun. |
| Cloud backup | `cadangan_simpan`, `cadangan_ambil`, `cadangan_cari` | Simpan/ambil paket save (lihat §5.4). |
| Pindah HP | `buat_kode_pindah`, `ambil_kode_pindah` | Transfer save antar HP lewat kode (server sebagai perantara). |
| Analitik | `catat_analitik`, `hapus_analitik` | Event gameplay (antre lokal maks 400, kirim tiap 180 dtk, maks 60/kirim). Bisa dimatikan. |
| Crash grafis | `lapor_crash_grafis` | Laporan crash + jejak grafis (`jejak_grafis.txt`). |
| Cek versi | `https://neopawstudio.github.io/versi.json` | `min_kode` / `kode_terbaru` / `url_update` + saklar remote `jeda_server`. |
| Foto profil | `atur_foto_profil`, `ambil_foto_papan` | Foto profil leaderboard (pilihan preset, bukan upload bebas). |
| Adu laris | `kirim_adu_laris` (+ antre lokal `adu_laris_tertunda.json`) | Skor minigame adu laris mingguan. |

**Yang TIDAK online:** seluruh gameplay (jual-beli, pelanggan, energi, level, cerita, utang, ngojol, minigame) — semua client-side, bisa dimainkan offline penuh. **Tidak ada multiplayer real-time.** `libunitycoherencenative.so` (coherence) adalah runtime WASM milik **Unity Ads**, bukan multiplayer — tidak ada gameplay multiplayer di game ini.

### 5.4 Save — lokal, polos, dan cloud-nya juga polos

- **Lokal:** `user://simpanan_N.json`, **N = 1..6** (`JUMLAH_SLOT = 6`, `game_state.gd` ~3255). Isi = `JSON.stringify(dict, "\t")` — seluruh state game (uang, energi, stok, tingkat, progres, hutang, motor, ngojol, chat, dll. — daftar lengkap di `hook_targets_1.2.yaml` lapis A). **Tanpa enkripsi, tanpa hash, tanpa tanda tangan.** Load (`_baca_slot` ~3503) hanya `JSON.parse_string` + cek hasilnya dict tidak kosong; bila rusak, pakai `.bak`.
- **Tulis atomik:** `<file>.tmp` → verifikasi ukuran byte → rename lama ke `.bak` → rename `.tmp` ke final (`_tulis_slot_aman` ~3461). Auto-save tiap 45 detik (`SELANG_SIMPAN_OTOMATIS`).
- **Cloud backup** (`cadangan_warung.gd` ~90 + `game_state.gd` `_paket_pindah` ~10034): paket = `"1:" + base64(gzip(JSON))` berisi **seluruh slot save mentah + flag toko (tanpa_iklan, pendukung, kode_pendukung) + lemari + promo** — **tanpa enkripsi**, hanya gzip+base64. Dikirim ke RPC `cadangan_simpan` dengan tanda HMAC (`_tanda(dev|rahasia|sha256(data))`). Kunci backup = `_rahasia` acak 16-byte hex per perangkat. Sidik (`_sidik`) = SHA-256 dari MD5 tiap file slot + flag toko — dipakai hanya untuk deteksi perubahan (skip upload bila sama), **bukan validasi**.
- **Pindah HP** memakai paket yang sama via `buat_kode_pindah`/`ambil_kode_pindah`.
- **Implikasi:** server menerima paket save apa adanya; **apakah server memvalidasi isi save saat restore — TIDAK BISA DIBUKTIKAN dari statik** (logika server tidak terlihat). Ini item "perlu verifikasi" di audit.

### 5.5 Iklan

- **Unity Ads**: Game ID Android `800425443` (`iklan_unity.gd`), placement `BP_Rewarded_Android` (rewarded) + `BP_Interstitial_Android` (selingan). Test mode OFF (kecuali `hp_pengembang`).
- Rewarded dipakai untuk: energi penuh 1×/hari, upah kerja 2×, tip minigame. Bila `tanpa_iklan` aktif, hadiah diberikan langsung tanpa menonton iklan (`layar_kerja.gd` ~183, `bar_energi.gd` ~195).
- SDK: `com.unity3d.ads.*` di DEX + `libunitycoherencenative.so` (514.424 B, stripped, BuildID sha1 `a1e5b073…`).

---

## 6. Anti-cheat / anti-tamper — hasil audit

| Proteksi | Status | Bukti |
|---|---|---|
| Root detection | **TIDAK ADA** | `isRooted` muncul 2× di DEX, tapi konteksnya string library AndroidX/Kotlin (`isRound/isRtlContext`, `isSameExceptionAs$FlowKt`), bukan cek game. Tidak ada RootBeer/Magisk/SuperSU. |
| Play Integrity / SafetyNet / App Attest | **TIDAK ADA** | Nol string di DEX maupun di `libgodot_android.so`. |
| License Verification (LVL) | **TIDAK ADA** | `com/android/vending/licensing` tidak ditemukan. Permission `CHECK_LICENSE` dideklarasi di manifest tapi tidak dipakai kode LVL; string `TRANSACTION_CHECK_LICENSE_V2` adalah internal Play Billing. |
| Obfuscation (script) | **TIDAK ADA** | `.gdc` hanya bytecode standar Godot — ter-decompile 100% dengan GDRE. Semua logika, harga, URL, dan kunci terlihat sebagai plaintext. |
| Obfuscation (native) | Parsial | `libgodot_android.so` stripped (tanpa simbol), tapi itu standar build release Godot, bukan obfuscation khusus. DEX memakai R8 (nama lambda `&$r8$lambda$…`). |
| Enkripsi save | **TIDAK ADA** | JSON polos (§5.4). |
| Checksum/integritas save | **TIDAK ADA** | Hanya cek "JSON valid + dict tidak kosong". |
| HMAC leaderboard | **ADA, tapi kunci di client** | Semua RPC papan ditandatangani HMAC-SHA256 dengan kunci `RAHASIA` yang **tertanam di client** (`papan_online.gd` ~12, 48 karakter hex). Siapa pun yang men-decompile game bisa menghitung tanda tangan valid untuk skor berapa pun. Server diasumsikan memverifikasi HMAC — tapi kunci yang bocor membuat verifikasi itu tidak berarti. Skor yang dikirim: `id|nama|total|bulan|jumlah_bulan|bintang|level|hari|omzet|omzet_bulan|minggu|pembeli_minggu|omzet_minggu`. |
| Verifikasi pembelian | **ADA, server-side** | Edge Function `verifikasi-pembelian` memverifikasi purchase token ke Google Play. Tidak bisa dipalsukan dari client (token harus asli dari Play). Entitlement pendukung tercatat di server per `id_papan`. |
| Cek versi + update wajib | **ADA** | `versi.json` remote: bila `kode build < min_kode` → layar "Wajib update", game tidak bisa lanjut. Ini kill-switch versi yang efektif. |
| Remote kill-switch server | **ADA** | Saklar `jeda_server` di `versi.json` → `papan.terapkan_saklar()` menonaktifkan kirim skor. |
| Filter nama | Client-side | Daftar kata terlarang di `papan_online.gd` ~120 (kata kasar/judi/URL) + leet-speak normalization. Server juga menolak nama (`alasan == "nama"`). |
| Dev backdoor | **ADA, tapi hash saja** | `KODE_PENGEMBANG_HASH` (SHA-256, `game_state.gd` ~9933): memasukkan kode promo yang hash-nya cocok → `hp_pengembang = true` (mode iklan contoh). **Kode aslinya tidak ada di client** dan tidak bisa dipulihkan dari hash. Jangan coba brute-force — di luar scope dan tidak feasible. |
| God-mode dev | **Nonaktif (dormant)** | `const GOD_MODE = false` + `god_aktif() = GOD_MODE and ResourceLoader.exists("res://scripts/god_mode.gd")` — file `god_mode.gd` **tidak ikut ter-export** (tidak ada di asset pack). `rek_promo_neopaw.gd` (autopilot perekam promo, dead code — tidak direferensikan scene mana pun) juga menyembunyikan node `god_mode.gd` saat rekam dan menyetel demo state (`tanpa_iklan=true`, uang 120.000, tingkat 3, reputasi 88, stok 40). Ini bukti dev punya god-mode internal — tapi tidak ada di build rilis. |
| Deteksi modifikasi asset | **TIDAK ADA** | Tidak ditemukan pengecekan hash/integritas terhadap `.gdc`/`.scn`/`.json` di asset pack. (Belum diuji runtime — apakah engine menolak .gdc yang dimodifikasi.) |

**Kesimpulan anti-tamper:** game ini **sangat terbuka untuk mod lokal** (save + config), dan **satu-satunya garis pertahanan yang nyata adalah server** (verifikasi pembelian + validasi skor yang tidak terlihat). Leaderboard HMAC dengan kunci di client adalah proteksi semu.

---

## 7. Implikasi untuk injector (kerangka HCR)

Kerangka HCR (native `.so` payload + pattern-scan + overlay + version gate + fail-closed + status JSON) dibangun untuk **Unity IL2CPP**, di mana method bisa di-resolve by name dan di-hook by RVA. Di game Godot ini, asumsi itu **tidak berlaku**:

1. **Tidak ada method bernama di native.** `libgodot_android.so` stripped — tidak ada simbol `godot::*` yang terekspos (hanya JNI `GodotLib_*` + FreeType). Name resolution ala IL2CPP mustahil.
2. **Logika ada di bytecode GDScript**, bukan native. "Hook" dalam arti IL2CPP tidak ada padanannya — yang ada adalah: (a) edit file save/config (root, tanpa inject), (b) ganti file `.gdc` di asset pack (belum diuji apakah engine menolaknya), (c) hook fungsi engine generik (`FileAccess`, `JSON`, `HTTPRequest`) via pattern-scan dari string anchor — polanya **belum di-resolve** (butuh Ghidra/IDA).
3. **Yang tetap bisa dipakai dari kerangka HCR:** struktur aplikasi (overlay menu toggle, auto-launch game, status JSON + Diagnosis, version gate 1.2/code 49, fail-closed per fitur, pre-create file status chmod 666, GETREGSET untuk ptrace, tulis langsung tanpa `.tmp` di dalam proses game). Yang harus diganti: lapisan resolver/hook-nya.
4. **Jalur mod paling andal untuk game ini bukan inject .so, melainkan companion app root** yang mengedit `simpanan_N.json` + `pengaturan.cfg` saat game mati (atau saat game jalan + paksa reload). Ini lebih sederhana, lebih stabil, dan tidak bergantung pada pola engine yang rapuh.

Daftar fitur per kelompok + targetnya ada di **`AUDIT-DAN-FITUR-INJECTOR.md`** (dokumen pendamping). Ringkasnya: BOLEH = uang, energi, stok, level/progres, upgrade, buka barang, waktu, reputasi, utang, cicilan motor, ngojol, hadiah login — semua via edit save. PERLU VERIFIKASI = apa pun yang menyentuh server (apakah restore cloud menolak save editan; apakah skor leaderboard tervalidasi). DITOLAK = IAP/dukungan (uang sungguhan), leaderboard (skor/jempol/lapor), kode promo server, bypass verifikasi pembelian, dan segala hal yang memakai kunci HMAC `RAHASIA` untuk memalsukan data server.

---

## 8. Batas jujur analisis statik

- **Validasi server tidak terlihat.** Apakah Supabase menolak skor yang tidak masuk akal, menolak paket cloud yang isinya diedit, atau memverifikasi ulang entitlement saat restore — tidak bisa dijawab dari client. Perlu uji runtime (akun kedua, offline/online) — itu di luar tahap analisis ini.
- **Pola native engine belum di-resolve.** Anchor string ada (§hook_targets lapis C), tapi alamat fungsi + pola byte unik belum ditemukan. Tanpa Ghidra/IDA di VM, klaim "hook X di alamat Y" tidak bisa dibuat.
- **Apakah .gdc yang dimodifikasi bisa di-load** (script-patch) belum diuji — tidak ada pengecekan integritas yang ditemukan di client, tapi perilaku runtime engine terhadap .gdc yang di-recompile bisa berbeda.
- **Harga IAP** adalah harga yang tertulis di client (Rp29.000 dkk.); harga final di Play Store bisa berbeda (tergantung `queryProductDetails`).
- **Decompile GDRE** sudah 100% file, tapi decompiler kadang menyederhanakan/mengubah urutan ekspresi — nomor baris di dump adalah nomor baris hasil decompile, bukan source asli. Nama variabel/fungsi dipertahankan (bytecode menyimpan nama asli).
- Game **belum rilis di Play Store** saat build ini dibuat — perilaku billing/versi di build rilis nanti bisa berubah.

---

## 9. File-file hasil kerja

| File | Isi |
|---|---|
| `dump-full/` | 132 file GDScript hasil decompile (59.378 baris) + `index.json` + `stats.json` |
| `dump-full/hook_targets_1.2.yaml` | Target hook 3 lapis (file / script / engine anchor) + catatan anti-tamper |
| `REA-WARUNG-LIFE-SIMULATOR.md` | Laporan ini |
| `AUDIT-DAN-FITUR-INJECTOR.md` | Audit + daftar fitur injector per kelompok (BOLEH / PERLU VERIFIKASI / DITOLAK) |
| `extracted/` | base.apk + arm64 + assetpack hasil ekstrak (bahan mentah) |
| `splits/` | 5 split APK asli |
| `game.bin` | File game asli (218 MB) |

### Perintah/tools yang dipakai
- `GDRE Tools v2.8.0-beta.2` (unduhan GitHub `GDRETools/gdsdecomp`): `--headless --bytecode=4.5.0 --decompile=*.gdc`
- `aapt`, `unzip`, `strings`, `nm`, `python3` (analisis DEX/JSON/PCK)
- Skill: `~/workspace/custom-skills/local-rea/SKILL.md`
