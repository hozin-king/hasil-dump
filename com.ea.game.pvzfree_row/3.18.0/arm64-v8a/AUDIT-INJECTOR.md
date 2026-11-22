# AUDIT — Desain Root Injector "Hozin PvZ Injector" (PvZ2 3.18.0 / 3180)

**Status:** DESAIN SAJA — injector BELUM dibangun. Build menunggu kata user setelah audit ini.
**Dasar:** `REPORT.md` (REA statis 16 Nov 2026, libpvz.so 50.117.680 B, 87.313 simbol dinamis).
**Target:** `com.ea.game.pvzfree_row` 3.18.0 (3180), arm64-v8a, HP user POCO X6 Pro (root KernelSU).

---

## 1. Ringkasan eksekutif

PvZ2 3.18.0 adalah target injector yang **paling ramah** dari semua game yang pernah diaudit di sini — karena satu fakta: **libpvz.so mengekspor 87.313 simbol dinamis dengan nama C++ lengkap**. Hook bisa diikat lewat `dlsym()` berdasarkan nama mangled yang stabil, bukan pattern-scan buta. Ekonomi per-level (sun, lawn mower, damage) **terbukti lokal**; ekonomi pembelian (coins/gems via IAP, unlock tanaman via store) **server-gated dan DILARANG**. Anti-cheat bukan garis keras (tidak ada Bifrost/GGP) — perlindungan utamanya Play Integrity token + verifikasi receipt IAP + validasi lisensi Play, semuanya server-side dan semuanya **dihindari** dengan tidak mengubah APK dan tidak menyentuh IAP.

**Rekomendasi: BANGUN, dengan cakupan solo/offline saja** (fitur di §5). Risiko utama bukan deteksi hook, melainkan **server yang sewaktu-waktu memperketat** (integrity token, re-sync profil) — mitigasinya fail-closed + gate mode (§4, §7).

---

## 2. Arsitektur injector yang diusulkan

```
[RootInjector generik — pola yang sudah terbukti di UE Hook / HCR Mod / BUSSID / TR]
  ptrace attach ke proses game (root)
    → dlopen payload .so ke dalam proses game
      → payload menunggu libpvz.so termuat (dlopen/dlsym polling + dl_iterate_phdr)
        → verifikasi identitas target (§3 — GAGAL = keluar diam-diam, TANPA menu)
          → resolve alamat hook (§4 — dlsym dulu, pattern-scan fallback)
            → pasang hook (Dobby, §6)
              → tampilkan mod-menu ImGui native di dalam render game (§8)
                → hook HANYA aktif di mode solo/offline (§7 — gate)
```

### 2.1 Urutan inject yang benar untuk game ini
1. **Jangan inject saat download resource / validasi lisensi.** Game mengunduh expansion + cek lisensi Play di awal (Java). Injector menunggu `libpvz.so` termuat — itu terjadi saat engine native start, setelah (atau bersamaan dengan) fase download. Menu mod **baru boleh muncul setelah game sampai di main menu** (cek `LawnApp::IsAppLoaded()` / `LoadingCompleted()` — simbol tersedia).
2. Payload TIDAK menyentuh Java/Dex sama sekali — tidak ada hook ke `com.ea.nimble.*`, tidak ada bypass lisensi, tidak ada sentuhan ke BillingClient.
3. Satu proses game = satu sesi injector. Bila game di-restart, injector inject ulang dari awal (tidak ada state persisten di luar menu).

### 2.2 Target library
- **HANYA `libpvz.so`.** Jangan hook `libNimble.so` (itu jembatan integrity — menyentuhnya justru memicu kecurigaan), jangan hook libc/libEGL kecuali untuk render ImGui (dan itu pun lewat fungsi GLES yang sudah diimpor game, bukan patch sistem).

## 3. Identifikasi target & fail-closed (anti salah sasaran)

Sebelum hook apa pun dipasang, payload WAJIB lolos semua cek ini; **satu saja gagal → injector keluar tanpa menu, tanpa pesan palsu, tanpa hook setengah jalan**:

| Cek | Cara | Nilai yang diharapkan (3.18.0) |
|---|---|---|
| Package name | `getPackageName` / baca `/proc/<pid>/cmdline` | `com.ea.game.pvzfree_row` |
| versionCode | PackageManager / baca `versionCode` dari APK | `3180` |
| libpvz.so terload | `dl_iterate_phdr` / `/proc/<pid>/maps` | ada, ukuran ~50.117.680 B |
| BuildID libpvz.so | baca note `.note.gnu.build-id` dari file `.so` di memori/disk | `8e40bdc91b1c112b29b4b4b587a04159` |
| SHA-256 (opsional, mahal) | hash file `.so` di `/data/app/…/lib/arm64/libpvz.so` | `079a0c71a67ae61f…dff5` |
| Simbol kunci ada | `dlsym(handle, "_ZN5Board11AddSunMoneyEi") != NULL` | alamat valid di dalam range libpvz.so |

**Kenapa BuildID + versionCode, bukan cuma versionCode:** versionCode bisa sama untuk build berbeda (EA memakai penomoran internal `243911` di remote config); BuildID mengikat ke biner persis yang diaudit.

## 4. Resolusi alamat hook — dlsym dulu, pattern-scan sebagai cadangan

### 4.1 Jalur utama: dlsym berdasarkan nama mangled (STABIL)
Semua target di REPORT.md §5 diekspor di `.dynsym` dengan nama mangled lengkap. `dlsym(RTLD_DEFAULT, "_ZN5Board11AddSunMoneyEi")` mengembalikan alamat fungsi **tanpa peduli offset berubah** antar build — selama signature C++-nya tidak berubah, nama mangled-nya identik. Ini jauh lebih tahan update daripada hardcode offset.

**Nama mangled kunci (salin persis dari REA):**
- `_ZN5Board11AddSunMoneyEi` — sun
- `_ZN5Board12TakeSunMoneyEi` — sun (ambil)
- `_ZN6Zombie10TakeDamageEijb` — damage zombie
- `_ZN5Board8AddPlantEii8SeedTypeS0_` — tanam
- `_ZN5Board10CanPlantAtEii8SeedTypeb` — cek bisa tanam
- `_ZN5Board17SetSuperMowerModeEb` — super mower
- `_ZN10PlayerInfo8AddCoinsEibNSt6__ndk112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEN5eastl12basic_stringIcNS7_9allocatorEEESA_` — coins (**DITOLAK — jangan di-hook untuk menambah koin; dicatat hanya sebagai bukti jalur**)
- `_ZN7LawnApp13DoCheatDialogEv` — cheat dialog bawaan (**riset saja, bukan fitur**)

### 4.2 Jalur cadangan: pattern-scan multi-signature
Bila di update berikut EA men-strip `.dynsym` (risiko nyata — lihat §9), dlsym gagal dan injector beralih ke pattern-scan. Aturan pattern-scan:

- **Satu fungsi = minimal 2 signature independen** (mis. prolog fungsi + urutan instruksi khas di badan fungsi + referensi string di dekatnya). Hook hanya dipasang bila **kedua** signature cocok di alamat yang sama (cross-check).
- **Pola STABIL vs RAPUH:**
  - Stabil: prolog fungsi ARM64 (`STP X29, X30, [SP, #-n]!; MOV X29, SP`), pemanggilan fungsi libc yang sama (`__android_log_print` dengan tag yang sama), referensi ke string konstan (mis. nama file save / pesan log), akses ke field dengan offset yang sama dari `this`.
  - Rapuh: alamat absolut, offset mentah hasil kompilasi, urutan register alokasi, hasil inlining (fungsi kecil seperti `GetCoins` rawan di-inline di update berikut — jangan jadikan anchor).
  - **Anchor terbaik untuk game ini:** `Board::AddSunMoney` — fungsi kecil tapi punya string/log call di dekatnya dan dipanggil dari banyak tempat; `Zombie::TakeDamage` — badan besar, banyak cabang (HP check, armor, death) sehingga pola badannya khas.
- **Bila tidak ada signature yang cocok → FAIL-CLOSED.** Injector keluar diam-diam. Tidak ada "coba offset lama", tidak ada toggle yang pura-pura jalan.

### 4.3 Kenapa pola ini tahan update minor
- Update minor (3.18.0 → 3.18.1) biasanya mengubah **isi data** (level, tanaman, harga) dan **sedikit logika**, bukan signature fungsi inti yang sudah stabil bertahun-tahun (`Board::AddSunMoney` ada sejak PvZ2 awal). Nama mangled hanya berubah bila signature C++ berubah — itu jarang untuk fungsi inti.
- Update mayor (engine ganti, Sexy framework diganti) akan mematahkan SEMUA pola — dan itu **benar**: injector harus menolak jalan, bukan nekat. Fail-closed adalah fitur, bukan bug.

## 5. Daftar fitur — BOLEH / DITOLAK / BELUM PASTI

### 5.1 BOLEH (solo/offline, terbukti lokal — kandidat v1.0)
| Fitur | Hook / mekanisme | Bukti lokal |
|---|---|---|
| Sun tak terbatas (di level) | Hook `Board::AddSunMoney` (tambah sun tiap panggil) atau bypass `Board::CanTakeSunMoney` → selalu true | §6 REPORT — resource per-level, in-memory |
| 1-hit kill zombie | Hook `Zombie::TakeDamage(int,unsigned,bool)` — paksa damage besar / HP jadi 1 | Simulasi lokal penuh |
| Tanaman kebal (god mode tanaman) | Hook jalur damage tanaman (fungsi persisnya butuh probe — kandidat `Plant::SpikeRockTakeDamage` sejenis; cari `Plant::TakeDamage` saat probe) | Simulasi lokal penuh |
| Super lawn mower | Panggil/set `Board::SetSuperMowerMode(true)` saat level mulai | `SetSuperMowerMode(bool)` lokal |
| Tanam gratis (tanpa sun) | Bypass `Board::CanPlantAt` + `GetCurrentPlantCost` (biaya jadi 0) | Logika lokal; **hati-hati**: ini mengubah ekonomi level, tapi tetap lokal |
| Tanpa cooldown seed packet | Hook `SeedBank::RefreshAllPackets` / recharge timer (fungsi persis butuh probe) | Kemungkinan lokal |

**Catatan "tanam gratis":** secara teknis lokal, tapi paling "kelihatan" dari sisi desain game. Tetap masuk kandidat v1.0 karena solo/offline; bila probe menunjukkan server ikut campur, pindahkan ke DITOLAK.

### 5.2 DITOLAK (jangan pernah masuk desain — pembelian nyata / server)
| Fitur | Alasan |
|---|---|
| Tambah coins / gems via `PlayerInfo::AddCoins` atau sejenis | **IAP = pembelian nyata.** Coins/gems dibeli dengan uang asli lewat Nimble MTX + Google Play Billing; receipt diverifikasi server (`PurchaseTransactionVerifier`, `SynergyCatalog`). Memberi currency gratis = mewakili pembelian nyata. **DILARANG.** |
| Unlock tanaman via store / `FinishPlantSale` / `HandleInAppPurchase` | Jalur MTX berbayar. DILARANG. |
| No Ads pack / Speed-Up bundle / Hard Nudge | Produk berbayar (`NoAdsPackSKU [868917]` dsb.), expiry dicatat server. DILARANG. |
| Reward video / iklan gratis | Server-side (Draper/IronSource). Di luar cakupan. |
| Mode Arena / kompetitif / leaderboard | Tidak ditemukan di build ini, tapi **gate §7 berlaku untuk semua mode ranking**: mod nonaktif total bila game masuk mode kompetitif/ranking apa pun. |
| Bypass lisensi Play / bypass integrity token / bypass `isDeviceRooted` | **DILARANG.** Itu evasi anti-tamper, bukan fitur game. Injector tidak menyentuh Nimble sama sekali. |

### 5.3 BELUM PASTI (butuh runtime probe — JANGAN masuk v1.0 sebelum terbukti)
- **Plant Food tak terbatas** — tidak ada accessor di .dynsym; counter kemungkinan member Board/data-driven.
- **Cooldown seed packet** — fungsi recharge persis belum teridentifikasi.
- **Apakah server me-re-sync saldo/progres** saat profil Synergy sinkron — menentukan apakah nilai lokal (coins dari hadiah level, dsb.) aman disentuh.
- **Trigger `LawnApp::DoCheatDialog()`** — dialog cheat bawaan; cara memicunya tidak diketahui.
- **Apakah `isDeviceRooted()` Nimble dipanggil & ditindaklanjuti** — menentukan apakah root terdeteksi game (bukan berarti injector diblokir, tapi menentukan risiko akun).
- **Fungsi damage tanaman persis** (god mode tanaman).

## 6. Rekomendasi kerangka

### 6.1 Hooking engine — **Dobby** (pemenang)
| Kandidat | Vonis | Alasan |
|---|---|---|
| **Dobby** | **DIPILIH** | Sudah **terbukti di tangan user** (HCR Mod, BUSSID v1.0.8, Traffic Rider v2.5 — semua jalan di POCO yang sama). ARM64 12-byte trampoline, kecil, stabil, tidak butuh framework tambahan. Patch 5 langkah untuk NDK modern sudah diketahui (lihat AGENTS.md 10 Okt 2026 — jangan pakai Dobby mentah). Cocok untuk lib 50 MB stripped-sebagian karena Dobby tidak peduli simbol — ia hook alamat yang kita beri (dari dlsym/pattern-scan). |
| Substrate / LSPosed | DITOLAK untuk shipping | Butuh framework Xposed/LSPosed terpasang + modul Zygisk — user punya root KernelSU tapi memasang rantai Xposed hanya untuk satu game menambah permukaan deteksi (dan LSPosed gampang dideteksi aplikasi). |
| Inline hook manual (raw) | CADANGAN | Bisa, tapi menulis ulang trampoline ARM64 sendiri = risiko bug (ingat pelajaran 12-byte vs 8-byte stub di BUSSID — patch 12 byte menimpa tetangga). Dobby sudah menyelesaikan masalah ini. Hanya dipakai bila Dobby gagal di fungsi tertentu. |
| Frida-gadget / Frida server | **DITOLAK untuk shipping** | Alat riset yang bagus (untuk probe runtime §5.3), tapi berat, mudah dideteksi (port, thread, string "frida"), dan tidak cocok sebagai injector yang dikirim ke user. **Boleh dipakai saat probe saja.** |

### 6.2 UI mod-menu — **ImGui native** (di dalam proses game)
- **ImGui (Dear ImGui) native**, di-render lewat konteks GLES game sendiri (game sudah mengimpor seluruh fungsi GLES — `gl*` ada di .dynsym libpvz.so). Satu toggle di menu: ON/OFF per fitur, tanpa toggle palsu (fitur yang hook-nya gagal resolve = toggle tidak muncul / tertulis "tidak tersedia di versi ini").
- Alternatif yang ditolak: **overlay Kotlin terpisah** (butuh izin overlay, tampil di atas game sebagai window lain — lebih gampang dideteksi user lain & lebih ribet sinkronisasi state dengan native). ImGui sudah pola yang dipakai UE Hook user — konsisten.
- Menu harus punya **tombol "Nonaktifkan semua & lepas hook"** (unhook bersih) + indikator status (versi game terdeteksi, jumlah hook aktif, mode gate aktif/tidak).

### 6.3 Bahasa & struktur payload
- **C++ (NDK, arm64-v8a saja)** — payload `.so` kecil: resolver (dlsym + pattern-scan) + hook (Dobby) + menu (ImGui) + gate (§7). Tanpa Java, tanpa resource tambahan.
- Struktur file yang diusulkan: `payload/` (resolver + hook + menu), `patterns/` (signature per versi game, dipisah dari kode — satu file JSON per versionCode, supaya update = tambah file pola, bukan ubah kode), `gate/` (deteksi mode — satu file, fail-closed).

## 7. Gate mode — pemisah solo vs kompetitif (WAJIB, fail-closed)

Aturan: **mod hanya hidup di mode solo/offline. Begitu game masuk mode apa pun yang melibatkan pemain lain / ranking / server, semua hook nonaktif (unhook / bypass ke fungsi asli) sampai kembali ke mode solo.**

- **Sinyal mode yang bisa dibaca (dari simbol yang ada):** `LawnApp::ShowLeaderboardScreen`, class `Leaderboard`, `GameSelector` (pemilih mode), `Challenge` (mode tantangan), `Board::SetPinataMode` (mode Piñata — event, kemungkinan ada leaderboard mingguan → **perlakukan sebagai kompetitif, gate ON**).
- **Arena tidak ditemukan di build ini** — tapi gate ditulis generik: daftar mode yang diizinkan = **Adventure + Mini-game solo + Zen Garden** (semua lokal). Mode lain = gate ON (nonaktif). Daftar mode diambil dari `GameMode`/`GameSelector` saat probe runtime — jangan hardcode dari tebakan.
- **Gate harus SATU fungsi terpusat** (`is_competitive_mode()`), fail-closed: bila mode tidak dikenali → **anggap kompetitif → nonaktifkan**. Sama seperti gate multiplayer BUSSID (satu cek terpusat, fail-closed).
- **Tidak ada pengecualian "sekadar lihat-lihat".** Bila user memaksa, jawabannya tetap tidak.

## 8. Risiko & mitigasi (jujur)

| Risiko | Kemungkinan | Dampak | Mitigasi |
|---|---|---|---|
| EA men-strip `.dynsym` di update berikut | Sedang | dlsym gagal → injector menolak jalan (bukan crash) | Pattern-scan fallback (§4.2) + fail-closed |
| Play Integrity token ditolak server karena root / injector terdeteksi | Sedang | Game tidak bisa login/sync, atau fitur online mati | Injector tidak menyentuh Nimble/integrity; root sudah ada sebelum injector (KernelSU); bila token ditolak, itu risiko root itu sendiri — sampaikan ke user, bukan disembunyikan |
| `isDeviceRooted()` Nimble dipakai & akun di-flag | Rendah–Sedang (belum terbukti dipakai) | Akun bisa dibatasi | Probe runtime dulu (§5.3); bila terbukti dipakai, tambahkan peringatan eksplisit di menu + opsi "jangan inject bila akun utama" |
| Server me-re-sync & mengoreksi progres/coins | Rendah (tidak ada bukti) | Nilai lokal kembali seperti semula | Jangan sentuh coins sama sekali (sudah DITOLAK); fitur v1.0 hanya per-level (sun/damage) yang tidak tersimpan ke profil |
| Update mayor ganti engine/framework | Rendah | Semua pola patah | Fail-closed + audit ulang per update (REA ulang tiap versionCode baru) |
| Ban akun | Tidak bisa dijamin nol | Akun PvZ2 bermasalah | Sampaikan jujur ke user: main di akun utama = risiko sendiri; fitur hanya solo/offline; tidak ada janji "aman 100%" |
| Lisensi Play gagal (APK diubah) | **Tidak berlaku** | — | Injector tidak mengubah APK — APK tetap asli + ter-sign EA |

## 9. Strategi kebal update (ringkas)

1. **dlsym nama mangled = garis pertahanan pertama** (stabil selama signature tak berubah).
2. **Pattern-scan multi-signature = cadangan** (2 signature independen per fungsi, cross-check, fail-closed).
3. **Pola per versi, dipisah dari kode** (`patterns/3180.json`, `patterns/3181.json`, …) — update game = tambah file pola + REA ulang, bukan rewrite injector.
4. **Gate versi keras** (package + versionCode + BuildID + simbol kunci) — versi tak dikenal = injector diam, bukan nekat.
5. **REA ulang tiap versionCode baru** sebelum klaim dukungan — jangan pernah "kemungkinan jalan" tanpa audit.

## 10. Langkah berikut (usul — menunggu kata user)

1. **(Opsional tapi disarankan) Runtime probe** di POCO user / perangkat tes: instal PvZ2 asli 3.18.0, jalankan, konfirmasi: (a) libpvz.so termuat + alamat `Board::AddSunMoney` via dlsym cocok; (b) `isDeviceRooted()` dipanggil/tidak; (c) plant food & seed cooldown (fungsi persis); (d) trigger CheatDialog; (e) apakah server mengoreksi progres. Probe memakai Frida (riset saja, bukan shipping).
2. **Build injector v1.0** (bila user setuju): payload C++ + Dobby + ImGui, fitur §5.1 saja, gate §7, fail-closed §3–§4.
3. **Tes di POCO**: inject → main menu → level Adventure → cek sun/1-hit/super mower → keluar level → cek save tidak rusak → cek mode leaderboard (gate nonaktif).
4. **REA ulang tiap update game** (versionCode baru) sebelum klaim dukungan.

---

## Lampiran — file kerja REA

- `REPORT.md` — laporan REA lengkap
- `dump/` — XAPK + APK + split arm64 terekstrak
- `analysis/dynsym.txt` / `dynsym_demangled.txt` / `strings_pvz.txt` / `strings_nimble.txt` / `dex_classes.txt`
- Logo: `~/workspace/your_files/Logo-HozinPvZ.png` (512×512) + `Logo-HozinPvZ-1024.png` (1024×1024)
