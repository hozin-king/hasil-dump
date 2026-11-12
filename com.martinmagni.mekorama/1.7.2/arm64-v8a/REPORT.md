# REA — Mekorama 1.7.2 (APK user)

File dianalisis: `Mekorama_1.7.2_0_w2ke.apk` (13.099.584 byte)
Workdir: `~/workspace/rea-mekorama/` (bukti mentah: `unzip_list.txt`, `dex_strings.txt`, `libmekorama_strings.txt`, `db_default.json`, `decoded/`)

## 1. Identitas

| Item | Nilai | Bukti |
|---|---|---|
| Package | `com.martinmagni.mekorama` | aapt badging |
| Versi | versionName `1.7.2`, versionCode `44` | aapt badging |
| SDK | min 21, target 33, compile 33 | aapt badging |
| Penandatangan | **CN=Mekorama, O=Martin Magni AB**, RSA 2048, SHA-256 cert `bd7dda942dd0264a20b6ddd30fcca0bcbb7ec62c723588917804ed9461088bce`; skema v1+v2 **Verifies** | apksigner |
| Kesimpulan asal | **APK resmi developer**, bukan repack pihak ketiga: sertifikat perusahaan developer asli, signature valid, tidak ada bekas patch/mod di DEX maupun native lib. (Batasan: hash tidak dibandingkan langsung dengan Play Store.) | |
| Engine | **BUKAN Unity.** Engine kustom native C++: `lib/arm64-v8a/libmekorama.so` (2,3 MB) + armeabi-v7a; fisika Bullet (simbol `btVector3`, `btEpsRoot`), QR encoder bawaan (`CQR_Encode`). Java/Kotlin hanya lapisan tipis (1 activity `com.martinmagni.mekorama.Mekorama`, kelas tidak diobfuscate) untuk jembatan AdMob/Billing/kamera. | unzip list, readelf dyn-syms |
| Permission | INTERNET, ACCESS_NETWORK_STATE, READ/WRITE_EXTERNAL_STORAGE, BILLING, AD_ID + AdServices, WAKE_LOCK, FOREGROUND_SERVICE | AndroidManifest.xml |

### Komponen jaringan (semua terbukti dari manifest + string DEX/native)
- **Iklan: AdMob** — meta-data `com.google.android.gms.ads.APPLICATION_ID = ca-app-pub-3677834091624020~1061046092`; 634 referensi `com/google/android/gms/ads` di DEX; unit iklan di native strings: `.../2475973617` dan `.../8774200374`; JNI callback `ad_interstitial_*` dan `ad_rewarded_*` → ada **interstitial + rewarded ads**.
- **IAP: Google Play Billing 5.1.0** — 171 referensi `com/android/billingclient`; JNI `iap_price/iap_purchased/iap_finished`.
- **Firebase Crashlytics + Analytics** — `libcrashlytics*.so`, 354 referensi crashlytics; TAPI manifest: `firebase_analytics_collection_enabled=false` dan `firebase_crashlytics_collection_enabled=false` (mati secara default, menyala setelah consent — JNI `consent_*` ada).
- **TIDAK ADA Play Games** (0 referensi `gms/games`, tidak ada meta-data APP_ID) → **tidak ada leaderboard, achievement, maupun cloud save**.
- URL satu-satunya di native lib: `mekoramaforum.com` dan `mekorama.com/privacy` (tautan keluar saja). **Tidak ada endpoint API server game.**

## 2. Struktur konten & save

### Level
- Total **144 file level `.bin`** di assets: 90 `x_*`, 48 `f_*`, 6 `w_*`.
- `assets/level_infos.json` mendaftarkan **80 level Story** (`x_*`) + **40 level Featured** (`f_*`, level komunitas terpilih yang dibundel offline). Sisanya (10 x_ versi lama/alternatif, 8 f_ tak terdaftar, 6 w_ contoh workshop/scan) tidak terdaftar di katalog.
- **Format level terbukti bisa dibaca/diedit**: 4 byte header + stream zlib (`78 01`). Hasil dekompresi contoh: `\x0c"Crash Course"\x0c"Martin Magni"` lalu grid voxel (~4 KB). Struktur: panjang+judul, panjang+nama author, lalu data blok. Ini format yang sama dengan **level card/QR** khas Mekorama — game punya encoder/decoder QR sendiri (`CQR_Encode`, `libBarcodeScannerLib.so`, string "Mekorama QR code.", "Too big for QR code!").
- **Editor level bawaan ada**: model blok editor `assets/3_*.bin` (cube, motor, zapper, slider, dll), field `dan` (default author name) di profil, JNI `asset_share_finished` + FileProvider untuk berbagi kartu level.

### Progres & unlock
- `assets/level_infos.json` tiap level story punya field `su` yang naik monoton **0 → 150** sepanjang urutan story = ambang **total bintang kumulatif** untuk membuka level (inferensi kuat dari pola data; ±2 bintang/level termasuk mastery).
- `featured` semua `su=0` → Featured terbuka tanpa syarat bintang.

### Sistem save — kunci temuan
- `assets/db` (958 byte) adalah **template database profil default**: zlib → JSON:
  `{"v":1,"fl":-1,"om":1,"os":1,"ocs":1,"prt":0,"ad":0,"up":0,"dan":"Unknown Author","pwyw":[],"lvs":[{n,t,s,sb} × 91]}`
  - `lvs` = progres per level (`s` = bintang, `sb` = best steps/score)
  - `ad` = flag iklan, `up` = flag user-bayar, `pwyw` = daftar pembelian pay-what-you-want
  - String native: "Failed to save data! Out of storage space?"
- Save runtime adalah salinan JSON terkompresi-zlib yang sama di penyimpanan internal aplikasi (nama file runtime tidak tampil sebagai string polos di lib — batasan bukti; format & isinya identik dengan template). **Seluruh progres, bintang, dan flag premium bersifat lokal murni.**

## 3. Ekonomi / premium
- Model **pay-what-you-want** terbukti: 6 produk Billing di DEX: `com.martinmagni.mekorama.pwyw1` s/d `pwyw6` (tingkat donasi sukarela via Google Play).
- Tidak ada konten yang dikunci di balik pembayaran: semua 120 level katalog tersedia; yang berubah setelah membayar adalah **iklan mati** (flag `ad`/`up` di profil lokal).
- **Klasifikasi gate: LOKAL.** Validasi pembelian lewat Play Billing standar, tetapi status hasil pembelian disimpan dan dibaca dari profil lokal; tidak ada server validasi milik developer (tidak ada endpoint apa pun di binary).

## 4. Verdict per fitur mod potensial

| Fitur | Verdict | Alasan (bukti) |
|---|---|---|
| Unlock semua level story (lewati gerbang bintang `su`) | **LAYAK — lokal murni** | Gate dihitung dari total `s` di file save lokal; cukup edit save / patch cek `su`. Nol server. |
| Save editor (bintang, best steps, progres `lvs`) | **LAYAK — lokal murni** | Save = JSON zlib yang formatnya sudah terbongkar penuh dari `assets/db`. |
| Level pack / custom level injection | **LAYAK — lokal murni** | Format `.bin` = header + zlib (judul+author+grid voxel) sudah direkayasa dari sampel; menambah file + entri `level_infos.json` murni urusan lokal. Bahkan tanpa mod pun game resmi mendukung level kustom via editor + QR. |
| Buka konten premium/donasi (matikan iklan tanpa bayar, flag `up`/`ad`, `pwyw`) | **TOLAK** | Ini gerbang pembayaran nyata (donasi PWYW ke developer indie) — memalsukan status pembelian = mengambil manfaat berbayar tanpa membayar, walau flag-nya lokal. |
| Hilangkan iklan (jalur teknis memblokir AdMob) | **TOLAK sebagai fitur mod** | Di game ini bebas-iklan ADALAH manfaat berbayar PWYW itu sendiri; menghapus iklan = fitur yang sama dengan baris di atas. (Membedakan: tidak ada iklan pihak ketiga di luar skema ini.) |
| Leaderboard / cloud save mod | **Tidak ada objeknya** | Fitur tidak ada di binary (Play Games absen total) — jangan dikarang. |

## 5. Risiko teknis bila nanti diperintah build
- **Obfuscation rendah**: Java tidak diobfuscate; native lib **tidak di-strip** (4.917 entri dynsym, nama kelas C++ terbaca: `CQR_Encode`, Bullet, dll) → analisis lanjutan mudah.
- **Anti-tamper / signature check: tidak ditemukan** di lapisan aplikasi (tidak ada string verifikasi signature di native lib; 5 hit `getPackageInfo` di DEX berasal dari library Google generik). Batasan: tanpa dekompilasi native mendalam (Ghidra tidak tersedia di VM) tidak bisa 100% pasti, tapi tidak ada indikator cek integritas.
- Konsekuensi resign biasa berlaku: APK hasil mod tidak bisa update dari Play Store dan harus ditandatangani sertifikat sendiri (uninstall versi resmi dulu bila beda sertifikat).
- Titik mod paling bersih secara teknis: **save editor eksternal** (tanpa menyentuh APK sama sekali) atau patch kecil di cek `su`/penulisan save di native lib.

## Rekomendasi langkah berikutnya
1. Bila user mau jalur paling aman: buat **save editor** Mekorama (baca/tulis file db: bintang + unlock) — nol modifikasi APK, nol risiko signature.
2. Bila mau mod APK: target unlock-all-levels via patch gate `su`, dengan verdict premium/PWYW di atas tetap dikecualikan.
