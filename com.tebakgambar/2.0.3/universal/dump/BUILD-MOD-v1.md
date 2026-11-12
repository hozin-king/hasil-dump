# BUILD-MOD-v1 — Tebak Gambar Mod v1 (gabung APK)

Dibangun 22 Okt 2026. APK: `~/workspace/your_files/TebakGambar-Mod-v1.apk`
(37.219.015 byte). Repo privat: `hozin-king/hozin-tebakgambar-mod`
(sumber patch + skrip build + workflow; Release `v1` berisi APK hasil CI).
Basis: `Tebak Gambar_2.0.3.apks` SHA-256
`7666317a321ff49072936348b3397c57a29252752e5b4d70524e8df1ae463916`,
package `com.tebakgambar`, versionCode 15029 / versionName 2.0.3,
Flutter (Dart AOT snapshot `ace654289f5abc240509fc941453ebc5`).

Pemetaan alamat: blutter == offset file di libapp.so (segmen .text
memetakan vaddr 0x200000 ke offset 0x200000). Semua byte di bawah dibaca
dari biner asli dan dicocokkan dengan decode capstone SEBELUM ditimpa;
skrip `patch_libapp.py` gagal keras bila ada yang tidak cocok.

## Fitur 1 — Bantuan rewarded langsung cair (TERPASANG, 3 titik)

Jalur terbukti: popup bantuan memanggil method show manajer iklan kUa
(singleton, field statis offset 0x1328) yang mengembalikan `Future<bool>`.
Bila true → popup memanggil `addProgress` (kunci jawaban, murni
SharedPreferences `free_answer_quantity`/`free_answer_progress`) atau
penambah hint — keduanya nol jaringan. Bila false → toast "Gagal memuat
iklan, coba lagi nanti" dan hadiah hangus. Method show melengkapi sebuah
`Completer<bool>` (field 0x1b objek state kUa) dari callback
FullScreenContentCallback; hadiah hanya cair lewat bool ini.

| Titik | Alamat | Byte sebelum | Byte sesudah | Alasan |
|---|---|---|---|---|
| P1a | 0x470b08 | `02 f0 41 b8` (`ldur w2, [x0, #0x1f]`) | `c2 82 00 11` (`add w2, w22, #0x20` = true) | Handler `onAdDismissedFullScreenContent` (0x470a5c): flag earned (field 0x1f) yang diteruskan ke penyelesaian completer (panggilan 0x470b18) dipaksa selalu true — iklan ditutup sedini apa pun, hadiah tetap cair. Representasi true sama persis dengan yang ditulis callback earned asli di 0x47096c–0x470970. |
| P1b | 0x470a34 | `d0 c2 00 91` (`add x16, x22, #0x30` = false) | `d0 82 00 91` (`add x16, x22, #0x20` = true) | Handler `onAdFailedToShowFullScreenContent` (0x47098c): nilai penyelesaian false → true (1 byte: 0xC2→0x82). Gagal tampil pun berakhir sukses. |
| P1c | 0x794008 | `c0 c2 00 91` (`add x0, x22, #0x30` = false) | `c0 82 00 91` (`add x0, x22, #0x20` = true) | Method show kUa (0x793f98): bila objek iklan (field 0xb) kosong sesudah upaya muat (0x765a64) — kasus OFFLINE / no-fill / gagal muat — method mengembalikan false. Diubah jadi true → pemanggil langsung memberi hadiah tanpa AdMob sama sekali. |

Interstitial antar-soal (manajer fUa, singleton offset 0x131c):

| Titik | Alamat | Byte sebelum | Byte sesudah | Alasan |
|---|---|---|---|---|
| P2 | 0x795004 | `b5 52 f3 97` (`bl #0x469ad8`) | `1f 20 03 d5` (`nop`) | Method show interstitial (0x794f90): satu-satunya pemanggilan tampil iklan di-NOP. Sesudahnya method menunggu hasil pemanggilan itu (Await menerima nilai non-Future sebagai nilai selesai — semantik Dart standar) lalu mengembalikan true seperti sesudah tampil normal (0x795014); pemanggil di penangan jawaban (0x790e80) hanya memasang penangan error pada future-nya dan membuang hasilnya. Tiga pemanggil lain 0x469ad8 (0x78d454, 0x794378) tidak disentuh. Iklan interstitial tidak pernah tampil; alur soal tidak berubah. |

## Fitur 2 — Nyawa naik saat salah + kebal game over (TIDAK DIPASANG — mekaniknya tidak ada di klien)

Bukan ditolak dan bukan dilewati: titik patch-nya tidak ada. Bukti dari
bedah libapp.so sesi ini:

1. GameData (`_eWa`, class id 2960) field 0x7 = life, bertipe **String**,
   nilai bawaan "5" (penginisialisasi bawaan 0x765118 dan jalur
   fallback parse token 0x774184 mengisi string "5" dari pool
   [pp+0x11248]).
2. Xref menyeluruh ke stub alokasi GameData (0x764ffc) menemukan 12
   situs konstruksi: fromJson (0x3cadfc, 0x3cb43c), bawaan (0x765170),
   parse token (0x774184/0x7742a8/0x7745e0/0x774728), empat updater
   notifier vWa (0x7947ac, 0x794b28, 0x79a6f8, 0x79aeec), dan merge
   login (0x79f5e4). **Semuanya** menyalin life apa adanya atau mengisi
   bawaan — tidak satu pun mengurangi atau menambah.
3. Alur jawaban (0x790b54–0x791670) tidak menyentuh GameData sama
   sekali; jawaban salah hanya memutar `sounds/sound_salah.wav` dan
   menampilkan popup `salah.png`. Tidak ditemukan gerbang game over
   berbasis life di klien.
4. Satu-satunya penghitung lokal yang berkurang dengan gerbang >0
   adalah **hint** pada struktur level `_kWa` field 0x13 (kunci JSON
   "hint", bawaan 3): dikurangi method notifier (closure 0x79ae08,
   entry 0x79ad6c) saat bantuan huruf dipakai, ditambah jalur hadiah
   hint (0x79a57c, "💡 Incrementing hint"). Itu bukan nyawa.

Kesimpulan: di build 2.0.3, nyawa tidak dikurangi jawaban salah di sisi
aplikasi — bila angka nyawa berubah, itu datang dari token server
(`game_token`), dan jalur merge lokal justru mengambil life dari
salinan lokal (0x79f4b8 → 0x79f5ec). Tidak ada instruksi yang bisa
diubah menjadi "+1 saat salah" tanpa menulis kode baru ke dalam alur
jawaban (code cave di biner AOT — risiko merusak game, tidak dilakukan).
"Kebal game over karena nyawa habis" secara lokal sudah menjadi
keadaan bawaan versi ini. Risiko sisa yang tidak bisa dibuktikan dari
biner: perilaku server saat menerima token hasil sinkronisasi.

## Fitur 3 — Timer level akhir (TIDAK DIPASANG — tidak terbukti ada)

Penelusuran terarah terakhir sesi ini + pencarian menyeluruh sebelumnya:
tanpa string hitung mundur/timeout di pool (satu-satunya padanan,
"chronometerCountDown", adalah string framework Flutter), tanpa
`Timer.periodic`/`Stopwatch` pada logika soal, tanpa kolom durasi di
skema data level, alur soal level 10/"Raja Gambar" (kunci "raja"
[pp+0x119c0], dirujuk 0x75138c/0x7513ac) tidak memuat penghitung waktu.
Yang terbukti ada hanyalah penghitung soal untuk jadwal interstitial.
Sesuai aturan: tidak ada toggle/patch palsu.

## Menu mod (Java, `com.hozin.tgmod.ModMenu`)

- Tombol "MOD" sebagai jendela WindowManager `TYPE_APPLICATION_PANEL`
  menempel token activity (Flutter memakai FlutterSurfaceView — view
  biasa tertutup, pola yang sama dengan pelajaran Bunker), bisa
  digeser, ketuk membuka panel.
- Disuntik lewat `onCreate` baru di MainActivity (smali_classes4;
  kelas asli tidak punya onCreate) → dex menu menjadi classes5.dex.
- Panel berisi STATUS fitur 1–2 + kredit; popup kredit "Mod by Hozin
  King" sekali per proses + Toast "MOD AKTIF" sekali. **Tanpa saklar**
  — patch biner statis tidak bisa di-toggle runtime, saklar akan
  menjadi saklar palsu.

## Penggabungan APK

- base.apk dari .apks + lib/arm64-v8a dari split_config.arm64_v8a.apk
  (libapp.so terpatch, libflutter.so, libdatastore_shared_counter.so).
  Split density (xxhdpi) dan bahasa (in/ms) tidak digabung — sumber
  daya Android-nya minimal untuk Flutter (UI dirender Dart); fallback
  ke sumber daya base.
- Manifest dibersihkan: atribut `android:requiredSplitTypes` &
  `android:splitTypes` dibuang, meta-data `com.android.vending.splits
  .required` & `com.android.vending.splits` dibuang (kalau tidak,
  pemasangan ditolak INSTALL_FAILED_MISSING_SPLIT),
  `android:extractNativeLibs` false → true.
- versionCode/versionName TIDAK diubah (15029 / 2.0.3).

## Tanda tangan

Keystore mod sendiri (`mod.keystore`, alias `modkey`), sertifikat
SHA-256:
`2E:D1:3A:47:F4:87:3B:1D:F8:14:50:8B:23:F1:32:F7:02:94:64:5C:59:E6:25:1F:0E:C3:92:E5:53:34:BB:03`.
Berbeda dari sertifikat asli (CN=tebakgambar.com) → **user wajib
uninstall Tebak Gambar asli dulu**; progres lokal tidak ikut terbawa.

## Verifikasi terprogram (atas APK final, verify.py)

- 4/4 byte patch hadir di libapp.so dalam APK final (P1a/P1b/P1c/P2).
- classes5.dex ada & memuat `Lcom/hozin/tgmod/ModMenu;`; classes4.dex
  memuat referensi ModMenu (kait onCreate).
- Aset Flutter utuh: 451 entri `assets/flutter_assets/` (sama dengan
  base asli), termasuk 400 zip level.
- Lib arm64 lengkap: 3 berkas.
- `apksigner verify` lulus (sertifikat di atas); `zipalign -c` lulus;
  manifest final: extractNativeLibs=true, tanpa penanda split wajib.
- APK resmi rilis dibangun ulang oleh GitHub Actions dari sumber repo
  dan menjalankan verify.py yang sama sebelum Release dibuat.
