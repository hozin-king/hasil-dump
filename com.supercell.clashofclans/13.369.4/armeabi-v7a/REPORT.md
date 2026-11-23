# REA + Riset Jalur 13.x 64-bit — Private Server Clash of Clans Offline ala Nara

**Tanggal:** 23 Nov 2026
**Status:** RISET + REA STATIS SAJA — server TIDAK dibangun, APK TIDAK di-install/dijalankan, TIDAK di-push ke mana pun.
**Pembanding:** `~/workspace/rea-clash-of-clans/REA-CLASH-OF-CLANS-NARA.md` (CoC 5.2 "Nara Patch" v1.5 — REPACK + server `com.nara.server` tertanam, RC4 kunci publik UCS, `libg.so` ARM32, alamat server di-patch ke 127.0.0.1:9339)
**Detail REA lengkap:** [`analysis/REA-FINDINGS.md`](analysis/REA-FINDINGS.md) (431 baris)

---

## 0. Ringkasan eksekutif + verdict

**Verdict: BERAT — feasible secara prinsip, tapi BUKAN proyek cepat. Skala usaha 2–6 bulan untuk hasil setara Nara di 13.x, dengan risiko gagal nyata di tengah jalan.**

Alasan singkatnya: klien 13.369.4 resmi jauh lebih tertutup dari 5.2. String `libg.so` terenkripsi (hostname server dan materi kripto tidak bisa dibaca dari statis), kunci RC4 era UCS tidak ada lagi, CSV gameplay kini bertanda tangan (`Sig:` + 64 byte), ada cek signature APK (11 hash hardcoded) dan jalur verifikasi integritas perangkat. Jalur Nara (ganti IP + pakai kunci RC4 publik + server UCS) **tidak bisa dipakai ulang** untuk 13.x — protokolnya harus di-RE dari nol lewat analisis runtime.

Ada satu jalur pintas yang lebih ringan (jalur B di §5 — mode offline bawaan klien via patch flag, seperti yang dilakukan komunitas 8133 untuk versi lama), tapi itu pun belum terbukti untuk 13.x dan cakupannya lebih sempit dari server penuh.

**Satu koreksi penting:** file yang berhasil didapat dan dianalisis ternyata **varian armeabi-v7a (32-bit), BUKAN arm64** — lihat §1. `libg.so` arm64 belum didapat; itu prasyarat sebelum pekerjaan lanjutan apa pun.

---

## 1. Klien yang didapat

| Item | Nilai |
|---|---|
| Package | `com.supercell.clashofclans` — **resmi Supercell, bukan repack** |
| versionName / versionCode | `13.369.4` / `1242` (rilis 22 Jun 2020, TH13, update musim panas: Headhunter, Super Witch, Inferno Dragon) |
| minSdk / targetSdk | 16 / 29 (Android 4.1 / 10) |
| Ukuran | 154.243.348 B (±147,1 MiB); unzip 2.569 file, 172.833.040 B |
| MD5 | `92c62442b6876c2373c579ac73f87060` — **cocok persis dengan katalog mirror** |
| SHA-256 | `ee077e5131e041b3bff68b008976afe38246aa8e748fe04e876bb40d77f411f7` |
| Signer | `CN=Visa Forsten, OU=Supercell, O=Supercell, L=Helsinki, ST=Uusimaa, C=FI`, RSA 4096; SHA-256 signer `9ea146d9…0d4d9c`; skema v1+v2 terverifikasi |
| Activity utama | `com.supercell.titan.GameApp`; app class `TitanMultidexApplication` |
| File lokal | `~/workspace/rea-coc-13x/CoC-13.369.4-armeabi-v7a.apk` (nama diganti 23 Nov — semula `…-arm64.apk`, menyesatkan) |

### 1.1 Koreksi varian — BUKAN arm64

Bukti (terverifikasi langsung): `aapt dump badging` → `native-code: 'armeabi-v7a'`; direktori `lib/` hanya berisi 5 file `armeabi-v7a`, tidak ada `lib/arm64-v8a`; kelima `.so` terverifikasi ELF32 ARM. APK ini adalah **base APK dari Android App Bundle** (signer `BNDLTOOL`, ada `res/xml/splits0.xml` yang isinya hanya modul bahasa) — library arm64 semestinya ada di split APK terpisah (`config.arm64_v8a`) yang tidak ikut terunduh.

**Konsekuensi:** semua pernyataan tentang `libg.so` di laporan ini adalah tentang `libg.so` **ARM32** (13.607.752 B, SHA-256 `1be70496…b5b1bf1`). Temuan DEX, manifest, assets, dan CSV berlaku umum antar varian ABI; pola/offset native arm64 bisa berbeda dan **belum dianalisis**.

### 1.2 Sumber APK — link user + fallback

- **Link langsung APKMirror yang dikirim user** (tautan unduhan langsung disensor — minta ke Alyaa bila perlu; varian arm64) dicoba 2× dari VM: selalu **HTTP 403** dari Cloudflare APKMirror (dengan dan tanpa header Referer). Penyebab paling mungkin: key unduhan sudah kedaluwarsa (key APKMirror berumur pendek) dan/atau Cloudflare memblokir IP datacenter VM. APKPure (`d.apkpure.com`, `download.apkpure.com`) juga 403; direct link a2zapk JS-gated.
- **Fallback yang dipakai:** androidapks.com / androidapksfree CDN (22 Jun 2020), MD5 terverifikasi cocok dengan katalog mirror. Mayoritas mirror lain (Downzen dkk.) juga menyajikan varian armeabi-v7a sebagai "13.369.4" — varian arm64 terutama tersedia di APKMirror.
- **Catatan ukuran:** APKMirror mencantumkan varian arm64 nodpi ±147,82 MB; file yang didapat 147,10 MiB — selisih ini konsisten dengan perbedaan varian ABI, bukan file rusak.

---

## 2. Sepuluh temuan terpenting (REA klien)

Detail + bukti di [`analysis/REA-FINDINGS.md`](analysis/REA-FINDINGS.md) §3.

1. **Varian sebenarnya armeabi-v7a, bukan arm64** (§1.1). `libg.so` arm64 belum didapat — prasyarat riset lanjutan.
2. **String `libg.so` terenkripsi.** `.rodata` hanya 125 KB berisi nama JNI; `.data` ±4 MB ber-entropi **7,983** (nyaris acak); brute-force XOR 1-byte atas 13,6 MB untuk `gamea`, `clashofclans`, `127.0.0.1`, `Connecting`, `fhsd6f86`, `nonce` → **nol hit**. Hostname, pesan login, dan kripto sesi baru bisa dibaca setelah dekripsi runtime.
3. **Hostname `gamea.clashofclans.com`: 0 kemunculan** di `libg.so`, `classes.dex`, `assets/`, `resources.arsc`. `127.0.0.1` / `9339` / `10101` / `20104` / `LoginOk`: juga 0. Satu-satunya host Supercell plaintext adalah link bantuan Helpshift.
4. **Kunci RC4 UCS tidak ada.** String `"fhsd6f86f67rt8fw78fw789we78r9789wer6re"` + `"nonce"`: 0 kemunculan di libg/dex/libcrypt. RC4 **tidak terkonfirmasi** masih dipakai — server Nara tidak bisa diarahkan ke klien ini hanya dengan ganti IP.
5. **Tidak ada jejak libsodium/Blake2/nacl.** `blake2` / `sodium` / `Pepper` / `ChaCha` / `X25519` / `Ed25519` / `HKDF` / `AES`: 0 kemunculan plaintext. Algoritma kripto 13.x **tidak teridentifikasi dari statis** — implementasinya hidup di `libg.so` yang ter-obfuscasi.
6. **Format CSV baru `Sig:`** — 44 file `assets/logic/*.csv` + `client_globals.csv` diawali `Sig:` + **tanda tangan 64 byte**, baru payload kompresi `5d…` di offset 68. Inferensi: signature 64 byte ≈ Ed25519; CSV modifikasi tanpa signature valid kemungkinan ditolak klien. (16 CSV lama di `assets/csv/` masih format `0x5D` seperti 5.2; `fingerprint.json` SHA-1 mencakup prefix `Sig:` — terverifikasi untuk `buildings.csv`.)
7. **`checkSignature()` (GameApp.java:568–585)** — SHA-1 signature APK → Base64 vs **11 hash hardcoded** (`RWEg0wzahyAlW2DQMkx9FUMH9SU=`, `LhjT+HJrHeYxMicWUY+yrsLr654=`, …). Repack dengan signer lain gagal cek ini kecuali ceknya di-patch.
8. **Jalur integritas perangkat** — `testDeviceIntegrity(byte[])` stub no-op di Java + native `setDeviceVerificationResult(boolean, boolean, String)` tanpa pemanggil Java (hasil atestasi diteruskan ke native). Server resmi kemungkinan menolak klien yang gagal atestasi; server privat harus memutuskan mengimplementasikan atau mengabaikan pesan ini (formatnya belum diketahui).
9. **`libcrypt-lib.so` BUKAN kripto game** — itu Adjust Signature V2 (2 export JNI `nSign`/`nOnResume`, kunci HMAC di AndroidKeyStore alias `"key2"`) untuk anti-spoofing atribusi install. Jangan tertipu namanya.
10. **Jejak anti-Frida di `libg.so`** — template pesan D-Bus `"/re/frida/HostSession"`, `"EnumerateProcesses"`, `"org.freedesktop.DBus.Properties"` berulang ≥5× di `.rodata`. Inferensi (belum terbukti): deteksi Frida — relevan karena analisis runtime kemungkinan memakai Frida. Plus: `assets/level/` (61 JSON TH1–10/NPC di 5.2) **hilang**; `globals.json` + `globals_definition.json` JSON plaintext baru (tuning server-driven, `KillSwitches`, `TownHallMaxLevel: 9` Builder Base); Supercell ID sudah **native** (`UseNative: true`, Game `"magic"`, base URL tidak ada di DEX); `READ_PHONE_STATE` **hilang**; `CAMERA` baru (QR Supercell ID); `libsentry` ada tapi DSN kosong.

**Yang tetap sama dari 5.2:** format kompresi CSV `0x5D`, `fingerprint.json` SHA-1, `sc/` tekstur (168 file, 113 MB), `BILLING` + IAP, arsitektur Java-tipis + `libg.so` sebagai otak game + protokol biner via TCP. **Tidak ada server privat tertanam** (tidak seperti Nara).

### Inventaris singkat

DEX tunggal `classes.dex` 8.276.280 B, 9.635 class / 58.490 method (vs 939 class di 5.2); native 5 lib armeabi-v7a stripped (`libg.so` 13.607.752 B; `libfmod.so` 952.092 B — ganti `libfmodex`; `libcrypt-lib.so` 169.692 B; `libsentry.so` 542.420 B; `libsentry-android.so` 13.912 B); assets 837 file (`csv/` 17, `logic/` 44, `sc/` 168, `sc3d/` 57 baru, `sfx/` 488 ogg, `fingerprint.json` 1.114 entri dengan `"version":"13.369.5"` ≠ versionName 13.369.4). JADX 1.5.1: 6.190 file Java ter-decompile, 9 error.

---

## 3. Delta vs 5.2 (ringkas)

| Aspek | 5.2 (2013, Nara) | 13.369.4 (2020, resmi) |
|---|---|---|
| Signer | self-signed "Nara Archieve" 2026 | Supercell resmi, RSA 4096 |
| `libg.so` | 3.098.452 B, string plaintext | 13.607.752 B, **string terenkripsi** |
| Hostname server | `127.0.0.1` (patch Nara) | Tidak ditemukan plaintext |
| Kunci RC4 UCS | Ada (di server Nara) | **0 kemunculan** |
| CSV game | 31 file `csv/`, format `0x5D` | 44 file `logic/` + 17 `csv/`; logic ber-prefix **`Sig:` + 64 B** |
| Level JSON | 61 file `level/*.json` | **Hilang** |
| Server tertanam | Ada (`com.nara.server`) | **Tidak ada** |
| Cek signature APK | Tidak ada | **Ada, 11 hash** |
| Device integrity | Tidak ada | **Ada** (stub + native) |
| Supercell ID | Tidak ada | **Ada, native** |
| `libcrypt-lib.so` | Tidak ada | Ada — Adjust (bukan kripto game) |
| Anti-Frida | Tidak dilaporkan | String D-Bus Frida di `libg.so` |

---

## 4. Survei server privat CoC open-source

Tidak ada server open-source yang menarget 13.x. Yang paling baru mentok di 9.256.x.

| Proyek | Versi CoC | Bahasa | Status terakhir | Catatan |
|---|---|---|---|---|
| **UCS** (ultrapowa, asli) | ~7.x | C# | Mati (±2015) | RC4 era lama; basis semua fork |
| **ogclash** (fork UCS) | 8.709.x | C# | Mati | Fork UCS yang paling dikenal |
| **Clash SL** (skyprolk) | **8.709.16** | .NET | Masih ada, v0.7.3.5 | Server + client patcher + file decryptor; **versi tertinggi di jalur UCS** (terverifikasi ulang 23 Nov) |
| **CoCSharp** (FICTURE7) | 7.x/8.x | C# | Diarsipkan | Termasuk kripto libsodium era 8.x + proxy packet logger; README: "encryption update in 8.x.x" butuh `libg.so` di-patch |
| **Supercell.Magic** (Mimi8298) | **9.256.x** | C# | Ditinggalkan penulis (8 commit, "some logic bugs") | **Server open-source paling baru**: Game/Home/Battle/Chat/Search/Stream + Titan + PatchGenerator; dipakai atrasis.net; 114★/41 fork |
| **PySupercell Core** | — (framework) | Python | Aktif 2025 | Core/framework saja, bukan server jadi |
| **SC-CORE** (FMZNkdv) | — (framework) | Zig | Aktif 2025 | Core/framework saja, bukan server jadi |
| **cocdp** (clanner) | era RC4 | — | Lama (2015) | Dokumen protokol + tools (CSV decompressor dkk.), 235★ |
| **8133 / russhty — `coc-offline`** | 1.70–7.1.1 | Frida (JS) | Aktif (repo dibuat 24 Okt 2026 ada `coc-v18-offline`) | **Bukan server** — skrip Frida yang menyalakan flag offline bawaan klien (`LogicDefines::OFFLINE_MODE`) + patch cek IAP; ada juga `coc-v9-offline` (9.256.8) dan `coc-v18-offline` (18.0.5, "based on clash of magic (that is based on atrasis)", AI-assisted, "0 knowledge about newer coc protections", diuji hanya di emulator Android 11 via translasi ARM 32-bit). Plus tool patch IP `libg.so` (`gamea.clashofclans.com` → 127.0.0.1). |

**Closed-source (fakta, bukan solusi):** **Null's Clash** (nulls.gg, engine proprietary, kini 19.32.4 — pernah mendukung 13.369.4; membuktikan klien 13.369.4 *bisa* dilayani server privat); **Atrasis** (memakai Supercell.Magic, kini 19.32.4, TH19); **Clash of Magic** (komersial sejak 2015, S1–S4, tanpa source publik). Ketiganya membuktikan jalur 13.x mungkin — tapi tidak ada satu baris pun kodenya yang bisa dipakai ulang.

**Kesimpulan survei:** lompatan dari server open-source terbaru (9.256.x) ke 13.369.4 mencakup 4 tahun perubahan protokol — enkripsi sesi baru (bukan RC4), format pesan baru, CSV bertanda tangan, Supercell ID native, cek integritas. Tidak ada fondasi siap pakai; semuanya harus di-RE.

---

## 5. Tiga jalur yang mungkin

### Jalur A — Server privat penuh ala Nara (repack klien + server localhost tertanam)
Sama seperti Nara: klien 13.369.4 di-patch (alamat server → 127.0.0.1, cek signature dimatikan), server C#/Java tertanam yang melayani login → home → battle NPC → klan/chat/ranking bot → gems awal + TH pre-upgrade.
- **Butuh:** RE protokol 13.x lengkap dari nol (handshake, enkripsi sesi, ratusan nomor pesan, format Home/Battle/Chat), kunci/algoritma kripto, kunci verifikasi `Sig:` CSV (atau patch verifikasi di klien), implementasi logika game server-side (ekonomi, upgrade, battle).
- **Skala:** **2–6 bulan** kerja fokus untuk setara Nara (Fase 1: libg arm64 + REA lanjut 1–3 hari; Fase 2: runtime RE host/handshake/kripto 1–3 minggu; Fase 3: server minimal login+home+NPC 1–2 bulan; Fase 4: klan/chat/ranking bot + konten TH13 +1–2 bulan). Ini estimasi kasar untuk reverser berpengalaman; untuk pemula bisa jauh lebih lama.
- **Risiko gagal terbesar:** enkripsi sesi memakai kunci yang diturunkan server-side / pinning native / gate SafetyNet — bila tidak bisa ditembus dari runtime, jalur ini mentok di Fase 2.

### Jalur B — Mode offline bawaan klien (patch flag, tanpa server) — JALUR RINGAN
Klien CoC punya flag offline internal (`LogicDefines::OFFLINE_MODE`) yang dipakai mode debug; komunitas 8133 menyalakannya via Frida untuk versi 1.70–7.1.1 (dan mengklaim sampai 18.0.5). Bila flag yang sama masih ada di `libg.so` 13.369.4, klien bisa jalan tanpa server sama sekali: desa lokal, bangun/upgrade, lawan NPC.
- **Butuh:** `libg.so` arm64 (atau arm32 untuk riset alamat), menemukan alamat flag offline di 13.369.4, dan mekanisme patch yang tahan di POCO (Frida Gadget / patch biner permanen — ingat ada string anti-Frida di `libg.so`, jadi Frida mungkin dideteksi).
- **Skala:** **hari–2 minggu** bila flag ketemu dan klien mau jalan offline; bila flag sudah dihapus/diubah di 13.x, jalur ini gugur dan kembali ke Jalur A.
- **Keterbatasan:** cakupan lebih sempit dari server penuh — klan/chat/ranking "bot" ala Nara kemungkinan tidak ada (itu logika server); yang didapat adalah permainan solo offline. Perlu verifikasi runtime apakah 13.x masih bisa main penuh tanpa server (data level tidak lagi dibundel di APK — §2 butir 10 — jadi sebagian konten mungkin tetap butuh server).

### Jalur C — Port Supercell.Magic (9.256.x) maju ke 13.x
Ambil server open-source paling baru (9.256.x) lalu perbarui protokolnya ke 13.369.4.
- **Butuh:** RE delta protokol 9.256 → 13.369 (enkripsi, nomor pesan, field baru, CSV `Sig:`, Supercell ID) — praktis sama beratnya dengan Jalur A, ditambah harus memahami dulu basis kode 9.256 yang ditinggalkan penulisnya ("some logic bugs").
- **Skala:** sebanding Jalur A (2–6 bulan), dengan keuntungan fondasi arsitektur server sudah ada.

**Rekomendasi riset (bukan build):** bila user memerintahkan lanjut, mulai dari **Jalur B dulu** — paling murah untuk membuktikan apakah 13.369.4 masih bisa hidup offline. Hasilnya menentukan apakah Jalur A/C layak diteruskan atau tidak.

---

## 6. Unknown terbesar + risiko

1. **Enkripsi sesi 13.x** — algoritma + kunci tidak diketahui; string terenkripsi. Hanya bisa dipecahkan lewat analisis runtime (dump memori setelah dekripsi) atau disassembly `libg.so` mendalam. Ini unknown #1.
2. **Nomor + format pesan 13.x** — login (dulu 10101→20104) dan seluruh set pesan belum diketahui; tidak ada di DEX/resources.
3. **Verifikasi `Sig:` CSV** — algoritma + lokasi public key belum diketahui; bila klien menolak CSV tanpa signature valid, konten game tidak bisa dimodifikasi/di-serve dari server privat tanpa patch klien.
4. **Cek signature APK + integritas perangkat** — repack harus mem-patch keduanya; seberapa dalam cek native-nya belum diketahui.
5. **Anti-Frida** — string deteksi Frida ada di `libg.so`; analisis runtime mungkin harus memakai teknik selain Frida (atau mem-patch deteksinya dulu).
6. **Ketergantungan server untuk konten** — `level/` hilang dari APK dan sebagian tuning pindah ke JSON server-driven; klien 13.x mungkin tidak bisa jalan penuh tanpa server meski flag offline dinyalakan.
7. **Varian arm64 belum didapat** — semua pekerjaan native lanjutan butuh `libg.so` arm64 yang benar (atau tetap memakai arm32 untuk riset pola, lalu porting).
8. **Legal/ToS** — private server melanggar ToS Supercell; hanya untuk pemakaian offline/localhost, jangan pakai akun asli, jangan sentuh server resmi.

---

## 7. Langkah konkret berikutnya (bila user memerintahkan build)

1. **Dapatkan varian arm64-v8a 13.369.4 yang benar** — link APKMirror baru yang masih segar dari user (key lama 403), atau unduh via APKMirror Installer di perangkat. Verifikasi `native-code: arm64-v8a` + hash sebelum dipakai.
2. **Riset Jalur B (murah, menentukan):** cari flag `OFFLINE_MODE` di `libg.so` 13.369.4 (string terenkripsi → butuh disassembly / pola dari versi lama), uji nyalakan offline di POCO (root) dan lihat sejauh mana game jalan tanpa server.
3. **Analisis runtime di POCO (root, klien resmi, tanpa repack dulu):** amati koneksi keluar (host/port aktual), dump string `libg.so` dari memori setelah dekripsi, tangkap handshake login. Ini satu-satunya jalan realistis menemukan host + kripto sesi 13.x.
4. **Baru setelah 2–3 terbukti:** putuskan Jalur A vs C, lalu bangun server minimal (login + home + simpan desa lokal) sebelum fitur klan/bot.
5. **Yang TIDAK dilakukan sebelum ada perintah:** build server, repack klien, install/jalankan APK apa pun, push hasil ke mana pun.

---

## 8. Artefak

Semua di `~/workspace/rea-coc-13x/` — APK **tidak** dihapus, tidak di-push (parent yang urus):

- `CoC-13.369.4-armeabi-v7a.apk` — 154.243.348 B, MD5 `92c62442…`, SHA-256 `ee077e51…` (nama diganti dari `…-arm64.apk` karena varian sebenarnya armeabi-v7a)
- `REA-COC-13X-64BIT.md` — laporan ini
- `analysis/REA-FINDINGS.md` — laporan REA lengkap (431 baris)
- `analysis/INVENTORY.txt` — inventaris 2.714 baris
- `analysis/libg_strings.txt` (120.612 baris), `dex_strings.txt` (92.723), `libcrypt_strings.txt`, `libfmod_strings.txt`, `libg_strings_utf16.txt`
- `analysis/aapt_badging.txt`, `apksigner_verify.txt`, `manifest_xmltree.txt`, `aapt_resources.txt`, `filelist.txt`
- `analysis/jadx-out/sources/` — 6.190 file Java (JADX 1.5.1, 9 error; log `analysis/jadx.log`)
- `dump-full/` — unzip lengkap APK (2.569 file)
