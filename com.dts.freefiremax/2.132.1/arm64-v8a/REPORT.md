# REA — Free Fire MAX 2.132.1 (com.dts.freefiremax)

File: bundle `.apkm` 488.528.702 byte (SHA tidak dicatat di sini; verifikasi ZIP valid),
berisi `base.apk` (14.938.181 byte) + `split_config.arm64_v8a.apk` (85.989.990 byte)
+ `split_asset_pack_install_time.apk` (399.093.881 byte) + `info.json`.
File unduhan asli tidak diubah; analisis dari ekstrak salinan (scratch dibersihkan setelah analisis).

## 1. Identitas & keaslian — RESMI, bukan repack

- Package: `com.dts.freefiremax`, label "Free Fire MAX"
- versionName `2.132.1`, versionCode `2019118524`, minSdk 21, targetSdk 36, compileSdk 36
- Varian APKMirror: arm64-v8a, nodpi, Android 5.0+, diposting 2026-09-16
  ("Free Fire MAX x NARUTO 2.132.1" — kolaborasi NARUTO pada judul rilis)
- Main activity: `com.dts.freefireth.FFMainActivity` (codebase bersama Free Fire TH)
- Signer (apksigner, status Verifies): `O=111dots studio`,
  cert SHA-256 `ca49d7c4a007cf614ebb3d31b5e33989ff8af482be73b1f04996b61d054649ec`
  — 111dots studio adalah studio Garena pembuat Free Fire.
  APK juga membawa Play Source Stamp (Google) → **APK resmi**, bukan mod/repack.
- Permissions kunci: INTERNET, `com.android.vending.BILLING`, lokasi kasar+halus,
  kamera, mikrofon, `DETECT_SCREEN_CAPTURE`, foreground service, kalender, dsb.

## 2. Stack teknologi

- Engine: **Unity + IL2CPP**.
  - `libunity.so` 21 MB; penanda string versi hanya keluarga **2018.4.x**
    (terbanyak `2018.4.12f1`) — mesin lama yang dipertahankan Garena.
  - `libil2cpp.so` 185 MB (arm64) — seluruh logika game di native IL2CPP.
  - Metadata IL2CPP `assets/bin/Data/Managed/Metadata/global-metadata.dat`
    57,4 MB, sanity `0xfab11baf` valid, **metadata version 31**
    (berada di install-time asset pack, 46.135 entri, bukan di base.apk).
- Java tipis: 3 dex (±17 MB) — launcher + **Garena MSDK**
  (auth, token cache, OpenId, share, `garena.pay` extras) + Firebase +
  Play Services + AndroidX. Tidak ada logika ekonomi/match di lapisan Java.
- Native lain di split arm64: `libGGP.so` 9,4 MB (anti-cheat Garena Game Protector,
  ELF stripped, tanpa dynamic symbol — tidak bisa dikarakterisasi dari string),
  `libanogs.so` 5,5 MB + `libanort.so` 1,7 MB (tujuan tidak teridentifikasi
  dari string — TIDAK diklaim sebagai anti-cheat), `libFFWebRequest.so`,
  `libff_voice_engine.so`, WebRTC (`libjingle_peerconnection_so.so`, voice chat),
  `libAkSoundEngine.so`, Firebase C++.
- **Tidak ada `libBifrost.so` di bundle ini** (base, split arm64, maupun asset pack).
  Ini BUKAN bukti Bifrost tidak ada di game — bisa dikirim saat runtime / di dalam GGP.
- Tidak ditemukan endpoint produksi dalam plaintext (libFFWebRequest tanpa string
  domain Garena/Free Fire) — endpoint kemungkinan lewat remote config / terenkripsi.
  Ini batas analisis statis, bukan bukti tidak ada server.

## 3. Ekonomi & mode — klasifikasi server-vs-local dahulu

- **Arsitektur: client render/input, server yang memutuskan.** Bukti dari biner:
  (a) tidak ada logika mata uang di Java (0 hit "diamond" di classes.dex);
  (b) auth + token via Garena MSDK (login wajib, token cache);
  (c) pembelian lewat Garena Pay + izin Play Billing;
  (d) anti-cheat GGP ikut dikirim (stripped).
  Tidak ada packet capture live dalam analisis ini — otoritas server atas match
  disimpulkan dari arsitektur + model produk, dan dinyatakan sebagai inferensi.
- **Ekonomi (SERVER):** diamond, gold, bundle/skin, elite pass, dan item berbayar
  lain — saldo & inventaris dari server, pembelian diverifikasi server.
- **Mode (SERVER):** battle royale, clash squad, dan mode rotasi lain — semuanya
  match online melawan pemain asli, dimediasi server. **Tidak ada mode
  offline/latihan vs bot** di game ini (tidak ada jalur match lokal yang ditemukan;
  game mewajibkan login + koneksi server).
- **Akun:** Garena/Facebook/Google/guest via MSDK; progres terikat akun server.

## 4. Tabel verdict — server-vs-local dahulu

| Fitur | Klasifikasi | Verdict | Bukti |
|---|---|---|---|
| Aimbot / aim-silent | SERVER/online | ❌ DITOLAK (lawan pemain asli) | Match server; butuh hook memori + bypass — keduanya ditolak |
| ESP / wallhack | SERVER/online | ❌ DITOLAK (lawan pemain asli) | Posisi musuh dari server; overlay ESP = keuntungan vs pemain asli |
| No recoil / no spread | SERVER/online | ❌ DITOLAK | Parameter tembak memengaruhi match online; server + GGP mengawasi |
| Speed / teleport / fly | SERVER-timed | ❌ DITOLAK | Gerakan & waktu match dipegang server; lokal = desync + flag |
| Unlimited diamond / gold | SERVER | ❌ DITOLAK (bypass ekonomi) | Saldo dari server; tidak ada logika lokal yang bisa diubah |
| Item berbayar / bundle gratis | SERVER | ❌ DITOLAK (bypass pembelian) | Inventaris + pembelian diverifikasi server (Garena Pay/Billing) |
| Bypass anti-cheat (GGP) | SERVER | ❌ DITOLAK | libGGP.so dikirim stripped; bypass = evasi deteksi |
| Lihat data lawan / akun lain | SERVER | ❌ DITOLAK | Data lawan tidak dikirim ke client di luar kebutuhan match |
| Mod visual murni lokal | LOCAL | ➖ TIDAK DIREKOMENDASIKAN | Tanpa nilai gameplay; tetap berisiko flag GGP/integrity |
| Mode offline / vs bot | — | ❌ TIDAK ADA | Game 100% online; tidak ada permukaan solo yang layak |

## 5. Risiko utama

- **Sanksi akun:** Garena menerapkan ban permanen + ban perangkat untuk cheat
  (konteks riset sebelumnya; kebijakan ini di luar biner, tapi konsisten dengan
  kehadiran GGP + MSDK token/akun). Diamond/item berbayar = uang asli — hangus
  bila akun kena sanksi.
- **GGP stripped:** ruang lingkup deteksinya TIDAK bisa dipastikan dari string
  statis (0 hit untuk magisk/xposed/frida/root/ptrace/hook/cheat/ban/integrity
  di libGGP.so — string terenkripsi/strip). Jangan berasumsi aman dari deteksi.
- **Update OB:** 2.132.1 adalah build September 2026; OB baru ±2 bulan sekali
  mengubah libil2cpp/metadata — hook apa pun (bahkan yang sah) rapuh per OB.
- **Tidak ada pembanding biner lama** di tangan — "apa yang berubah vs OB
  sebelumnya" TIDAK bisa dijawab dari biner ini saja (dinyatakan plain).

## 6. Rekomendasi langkah berikutnya

**JANGAN bangun mod Free Fire MAX apa pun.** Tidak ada permukaan mod solo/offline
yang layak: game 100% online, semua ekonomi server-side, semua cheat gameplay
yang umum ditanyakan = merugikan pemain asli atau bypass pembelian/deteksi.
Jalur yang sah: main apa adanya; diamond/item lewat pembelian resmi.
Perlu dicatat terpisah: permintaan meng-update modul cheat Rama Zygisk untuk
versi ini (aimbot/ESP + InitBypass) adalah pekerjaan yang sama dan juga ditolak
— laporan ini tidak berisi tabel offset/kandidat offset per-OB apa pun.

## 7. Batas analisis ini (dinyatakan plain)

- Analisis statis saja: manifest/aapt, daftar isi APK, string/symbol-level pada
  dex + .so terpilih, header metadata IL2CPP. Tidak ada JADX dekompilasi penuh,
  tidak ada Ghidra/IDA, TIDAK ada IL2CPP dump (sengaja tidak dilakukan, karena
  dump menghasilkan tabel offset), tidak ada analisis paket jaringan live.
- Versi Unity dilaporkan dari penanda string di libunity.so (2018.4.x), bukan
  dari konfirmasi runtime.
- Tidak ada APK mod yang di-build, tidak ada push, tidak ada instalasi,
  file unduhan asli tidak diubah.
