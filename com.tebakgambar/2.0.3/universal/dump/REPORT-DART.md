# RE Lanjutan (Dart AOT) — Tebak Gambar v2.0.3

Tanggal: 22 Oktober 2026
Target: melacak tiga titik logika di `libapp.so` (arm64, 8.258.448 byte, SHA-256 `d60898c1f417…`) untuk spek mod dari user: (1) bantuan iklan langsung cair tanpa menonton iklan, (2) timer level akhir, (3) salah jawab kebal / tambah nyawa.
Kelanjutan dari: `REPORT.md` (dump + REA dasar).

## Metode — blutter BERHASIL

- **blutter** (clone github.com/worawit/blutter) dijalankan penuh di VM: Dart VM 3.12.2 dibangun dari sumber (snapshot hash `ace654289f5abc240509fc941453ebc5`, cocok dengan laporan dasar), lalu snapshot aplikasi dibedah. Keluaran nyata: `work/dart/out/` berisi `pp.txt` (object pool, 41.008 baris), `objs.txt` (35.785 baris), `asm/` (1.403 berkas library, 2.759 fungsi beralamat), `blutter_frida.js`.
- Hambatan teknis yang diselesaikan: `libcapstone-dev` tidak tersedia di apt → dipakai binding pip capstone 5.0.7 (header + `libcapstone.so` dari paket pip) dengan `capstone.pc` buatan lokal.
- Karena flag snapshot `dedup_instructions` + obfuskasi nama, banyak fungsi di keluaran blutter berukuran `-0x1` (tidak didisassembly blutter). Untuk fungsi-fungsi itu dipakai **disassembler capstone beranotasi buatan sendiri** (`work/dart/disas.py`): melacak pola `add/ldr` relatif ke register PP (x27) dan menyelesaikan setiap referensi ke entri `pp.txt`, plus `work/dart/scan_pp.py` yang memindai seluruh `.text` (1.540.324 instruksi) untuk menemukan semua situs yang mereferensikan string/objek pool tertentu. **Semua alamat di bawah berasal dari keluaran alat ini, bukan tebakan.**
- Konvensi register yang terverifikasi dari kode: x27 = PP (object pool), x26 = THR, x28 = basis heap pointer terkompresi, x22 = objek `null`; objek `true` = null+0x20, `false` = null+0x30 (terlihat dari pola simpan/bandingkan yang konsisten di beberapa fungsi).
- Nama kelas/fungsi asli **terobfuskasi** (mis. `kUa`, `_rXa`); identifikasi peran fungsi di bawah didasarkan pada string debug yang direferensikannya — dan game ini ternyata **penuh string debug `<CHECK>`/emoji** yang sangat membantu.

---

## Fitur 1 — Bantuan iklan langsung cair (bantuan huruf + kunci jawaban)

### Alur rewarded yang sebenarnya (manajer iklan: library `Uvj`, kelas `kUa`)

Tiga closure callback AdMob berhasil dibedah penuh:

| Callback | Alamat | Isi (bukti) |
|---|---|---|
| `onUserEarnedReward` | `0x4708e0` | Hanya dua hal: print `✅ User earned … reward: …` (ref string di `0x470918`, `0x470934`) dan **menulis nilai `true` (null+0x20) ke field offset 0x1f** objek state iklan yang di-capture (`0x47096c`). Tidak ada pemberian bantuan di sini, tidak ada jaringan. |
| `onAdDismissedFullScreenContent` | `0x470a5c` | Print `… ad dismissed, earned reward: <flag>` (ref `0x470ab0`), lalu **meneruskan flag field 0x1f yang sama** ke callback penyelesaian milik pemanggil (panggilan `0x68f8e4` di `0x470b18` dengan flag sebagai argumen). Setelah itu ada penanganan lanjutan per-tujuan iklan — terlihat perbandingan string `"hint"` (ref `0x470b58`, `[pp+0x112e8]`). |
| `onAdFailedToShowFullScreenContent` | `0x47098c` | Print `❌ … ad failed to show: …` (ref `0x4709c4`, `0x4709e0`) dan memanggil callback penyelesaian dengan nilai `false` (null+0x30, di `0x470a34`). |

**Kesimpulan gerbang:** satu-satunya penentu cair/tidak adalah **bool murni di klien** — di-set oleh callback AdMob `onUserEarnedReward`, diteruskan saat iklan ditutup, dan `false` bila iklan gagal tampil (jadi dalam game asli: **offline = iklan gagal muat = tidak ada bantuan**, cocok dengan string `Gagal memuat iklan, coba lagi nanti`).

### Pemberian kunci jawaban (FreeAnswerProvider) — 100% lokal

Fungsi-fungsi provider berhasil dipetakan dari referensi string debug-nya:

- **Muat dari lokal**: fungsi di sekitar `0x793d64–0x793ee4` membaca kunci SharedPreferences `free_answer_quantity` dan `free_answer_progress`, print `   Read from SP: quantity=…` dan `✅ FreeAnswer loaded from local: quantity=…`. Sumber kebenaran saat runtime = **SharedPreferences**, bukan server.
- **`addProgress()`** — badan async di `0x799200` (dipanggil lewat stub entri `0x495558` pada singleton provider, field `<mUa._DMc@1554511533>`, dari alur penyelesaian popup di `0x799178`):
  1. Bila model belum dimuat (null) → muat dulu dari lokal (panggilan `0x793cdc` di `0x79925c`).
  2. `progress + 1` dihitung dari field model (`0x799284–0x799294`: field 0xf = progress, field 0x7 = quantity), print `   Current: progress=…, quantity=…` (ref `0x7992ac`).
  3. Print `   After watch: progress=…` (ref `0x799344`); bila progress mencapai syarat tonton (konfigurasi bawaan `{"reward":"1","numOfWatch":"3"}` / `{"reward":"1","numOfWatch":"1"}` dari laporan dasar) → `quantity + 1`, print `   ✨ Earned free answer! New quantity: …` (ref `0x7993b0`).
  4. **Simpan ke SharedPreferences**: `setInt("free_answer_quantity", …)` dan `setInt("free_answer_progress", …)` (ref kunci di `0x799414` dan `0x799438`), print `   Saved to SP: quantity=… (success=…), progress=…` (ref `0x799468`).
  5. **Verifikasi = baca ulang SharedPreferences** (ref kunci lagi di `0x799584`/`0x799598`, print `   Verified SP: quantity=…` di `0x7995b8`). "Verified" di sini verifikasi tulis-baca lokal, **bukan verifikasi server**.
  6. Jalur error: `❌ FreeAnswerProvider: Error adding progress: …` (ref `0x799654`).
  
  Di seluruh rentang fungsi ini **tidak ada satu pun referensi endpoint, Dio/HTTP, atau `game_token`** — hanya SharedPreferences, print debug, dan aritmetika field.
- **Klaim/pakai**: fungsi di sekitar `0x793ac0–0x793c08` — pola sama (tulis SP → verifikasi → `✅ FreeAnswerProvider: Free answer claimed! Total: …`, ref `0x793bc8`). Pemakaian kunci (`use`) di sekitar `0x799898–0x799a30` (`   Quantity: `, error `❌ FreeAnswerProvider: Error using free answer: ` ref `0x799a30`) juga lokal.
- **Popup pemanggil**: fungsi besar `0x7986a8–0x7991f8` memuat teks `Dapatkan bantuan kunci jawaban dengan nonton iklan … kali` (ref `0x798e10`), jalur error `❌ Error showing free answer ad: ` (ref `0x798efc`), dan toast sukses `Kamu mendapatkan 1 kunci jawaban!` (ref `0x79919c`, ditampilkan lewat helper `0x79376c`).

### Bantuan huruf — jalur yang sama

- Manajer iklan yang sama menangani tujuan `"hint"` (perbandingan string di handler dismiss, `0x470b58`).
- Status buka hint disimpan sebagai kunci SharedPreferences berprefiks **`hint_unlocked_`** (`[pp+0x210f0]`); situs referensinya: `0x4963c8` (fungsi UI game), `0x766c70` (lapisan data/provider), `0x795368` dan `0x79acdc` (widget). 
- Hint-nya sendiri **dibuat lokal dari jawaban** (string `Generated hint: "…"`, `Hint length: …` — laporan dasar §5). Tidak ada komponen server pada pemberian maupun pemakaian hint.

### Vonis Fitur 1: **BISA, murni lokal — termasuk offline**

- Pemberian bantuan huruf maupun kunci jawaban **tidak divalidasi dan tidak dicatat server pada jalur pemberian ini**; token `game_token`/endpoint game tidak disentuh sama sekali oleh kode pemberian. Server hanya berperan pada sinkronisasi `GameData` (nyawa/level/data — lihat Fitur 3), dan pada jalur provider yang dibaca, tidak ditemukan kode yang menimpa `free_answer_quantity` dari hasil sinkron.
- Titik intervensi paling realistis, urut dari paling bersih:
  1. **Lewati iklan, panggil jalur penyelesaian sukses secara langsung** — tiru panggilan yang dilakukan handler dismiss: sampaikan `earned=true` ke callback penyelesaian popup/provider (atau panggil stub provider `0x495558`/`addProgress` `0x799200` dari menu mod se-proses). Seluruh mesin progress→quantity→SP berjalan apa adanya, tanpa AdMob sama sekali → otomatis kebal offline.
  2. Patch handler dismiss `0x470a5c` agar selalu meneruskan `true` — lebih kotor (iklan tetap harus tampil dulu), tidak menyelesaikan syarat offline.
  3. Tulis langsung kunci SP `free_answer_quantity` — paling rapuh (mengabaikan logika progress), hanya cadangan.

---

## Fitur 2 — Timer level akhir (level 10 / soal "Raja Gambar")

### Yang dicari dan TIDAK ditemukan

- Tidak ada string UI terkait waktu habis / hitung mundur di seluruh `libapp.so`: tidak ada "waktu habis", "kehabisan waktu", "sisa waktu", "detik", "menit", "timeout" versi game (yang ada hanya string framework: `Timer`/`class _Timer` dart:async, `chronometerCountDown` milik framework, `TVTimer` milik pustaka lain).
- Tidak ada referensi `Timer.periodic` maupun `Stopwatch` di object pool (tidak ada entri Function untuk keduanya di `pp.txt`).
- Tidak ada konstanta `Duration` yang teridentifikasi sebagai durasi hitung mundur soal (pencarian Mint mikrodetik 10–180 detik di `pp.txt` nihil; durasi yang dibuat dari Smi detik saat runtime memang tidak meninggalkan jejak di pool — jadi ini bukti negatif yang tidak mutlak).
- Skema DB level (laporan dasar §7.1) tidak punya kolom waktu; satu-satunya string "raja" di pool adalah `"raja"` (`[pp+0x119c0]`, kemungkinan potongan kata soal) dan teks aturan `…SOAL DI SETIAP AKHIR LEVEL ADALAH RAJA GAMBAR…` (`[pp+0x28898]`) — tidak ada konstanta/konfigurasi timer yang menempel padanya.
- Satu-satunya mekanisme "berbasis hitungan" yang terbukti di kode permainan adalah penjadwalan iklan interstitial per jumlah soal terjawab (`interstitial_question_count`, default 5 — terlihat di fungsi progres jawaban benar, ref string di `0x790d88`, penghitung global di `0x790d44–0x790d7c`, print `📊 Questions answered: …`). Itu timer iklan, bukan timer soal.

### Vonis Fitur 2: **BELUM TERBUKTI — titik logika timer tidak ditemukan secara statis**

- Dengan bukti yang ada, **tidak terbukti ada logika hitung mundur khusus** untuk level 10 / soal Raja Gambar di kode Dart. Tiga kemungkinan yang tidak bisa dibedakan secara statis: (a) timer memang ada tapi digerakkan `AnimationController`/animasi UI (tidak menyisakan string/konstanta khas — beberapa controller animasi `Bs<double>` memang terlihat di kelas State UI), dan kegagalan saat waktu habis dipicu dari callback animasi; (b) yang diingat user sebagai "waktu" adalah mekanisme lain (mis. event berbatas waktu — ada `RegularEventModel`/`EventQuestionModel` dari server); (c) timer hanya visual tanpa logika gagal.
- **Rekomendasi sebelum mod dibangun**: verifikasi dinamis singkat (jalankan level terakhir di HP, rekam apa yang terjadi saat "waktu" habis; atau hook Frida pada `AnimationController`/callback soal) untuk memastikan timernya ada dan berakibat apa. Mematok patch pada alamat yang belum terbukti melanggar prinsip anti-fitur-palsu.
- Bila nanti terbukti ada dan pemeriksaannya lokal (sangat mungkin — seluruh logika soal terbukti lokal), penghapusannya realistis di titik callback "waktu habis" itu; tapi alamatnya **belum ada** dan tidak akan dikarang di laporan ini.

---

## Fitur 3 — Salah jawab: kebal nyawa vs tambah nyawa

### Struktur data (terbukti)

- Kelas `GameData` hanya punya 3 field (dari `toString()`-nya di `0x54b0c8`, string `GameData(life: ` direferensikan di `0x54b0f0`):
  - **`life` — field offset 0x7** (dimuat pertama, `0x54b0fc`)
  - `lastLevelStructure` — offset 0xb
  - `data` — offset 0xf (peta data per level)
- Muat data **lokal-dulu**: fungsi provider di wilayah `0x764xxx` (`<CHECK> getLocalGameData: level=` ref `0x764fc8`; `<CHECK> _loadGameData() DONE, level=` ref `0x764ca8`; dump debug `   - Life: ` ref `0x764b28`, `0x764e7c`, `0x7651fc`).
- Penanganan jawaban (wilayah fungsi `0x790b54–0x791670`, termasuk progres jawaban benar dan logika buka soal berikut: `), unlocking next question` ref `0x7912c0`, ` - NOT unlocking next question` ref `0x7913a0`) — **seluruh panggilan di rentang ini adalah helper lokal**: pengambil konfigurasi, singleton iklan (`0x795060`, `0x794f90`), print debug. **Tidak ada referensi endpoint/jaringan di alur jawab-salah maupun jawab-benar** → pengurangan nyawa (yang menurut desain game terjadi saat jawaban salah) diterapkan oleh kode lokal atas state lokal, **bukan menunggu jawaban server**. Bunyi/popup salah juga lokal (`sounds/sound_salah.wav` ref `0x46b008`; `assets/images/popups/salah.png` ref `0x46ded4`).
- Sinkronisasi adalah peristiwa terpisah: `syncFromServerSafe` (string pengecualiannya direferensikan di `0x773da4`) dan **penggabungan (merge) saat login** (fungsi di wilayah `0x79f380–0x79f7a0`).

### Perilaku merge login — penentu nasib edit nyawa (terbukti dari disassembly)

Fungsi merge membaca token server (`sync_token` ref `0x79f418`; parse `game_token` — `🔴 Error parsing game_token: ` di wilayah yang sama), lalu menyusun `GameData` gabungan:

1. Print `🔵 Local GameData - Life: …` — nilai yang disimpan ke slot sementara di `0x79f4b8–0x79f4c0` adalah **field 0x7 (life) dari GameData LOKAL**.
2. GameData server dimuat dari token (panggilan `0x774054` di `0x79f4dc`); print `🟢 Server GameData - Level: …, Hint: …, SavedData count: …` (ref `0x79f500` dst.).
3. Peta `data` kedua sisi digabung oleh fungsi `0x79f9e0` (dipanggil `0x79f5b4`).
4. GameData hasil dibangun (objek dari panggilan provider `0x764ffc` di `0x79f5e4`) dan diisi di `0x79f5e8–0x79f600`:
   - **field 0x7 (life) ← nilai LOKAL** (slot dari langkah 1, `0x79f5ec`)
   - field 0xb (`lastLevelStructure`) ← milik **server** (`0x79f5f8`)
   - field 0xf (`data`) ← hasil gabungan peta (`0x79f5fc`)
   - lalu print `🟢 Merged GameData - Level: …, Life: …` (ref `0x79f63c`).

**Artinya: pada jalur merge login — satu-satunya jalur rekonsiliasi lokal↔server yang berhasil dibedah — nyawa justru diambil dari salinan LOKAL, bukan ditimpa server.**

### Vonis Fitur 3

- **Kebal salah jawab (nyawa tidak berkurang): BISA secara lokal.** Pengurangan diterapkan kode lokal atas `GameData` lokal tanpa perjalanan ke server per jawaban; menahan pengurangan itu (patch pada titik pengurangan di provider/penangan jawaban, atau paksa tulis-ulang nilai life setelahnya) tidak membutuhkan kerja sama server. *Catatan kejujuran:* instruksi persis yang mengurangi life belum diisolasi sampai alamat tunggal — wilayahnya sudah sempit (provider GameData `0x763e00–0x780000` dan penangan jawaban `0x790b54–0x791670`), tetapi di laporan ini alamat itu **belum** diklaim karena belum terbukti dari keluaran alat.
- **Menambah nyawa (edit jumlah): nilai lokal menang di merge login.** Mengubah life di salinan lokal **tidak ditimpa** oleh merge login (bukti di atas: merged life ← local). Risiko yang masih terbuka dan dinyatakan apa adanya: (a) isi `syncFromServerSafe` (`0x773da4`) belum dibedah — namanya menyiratkan arah server→lokal untuk jalur selain login; (b) apakah server memvalidasi kewajaran life saat menerima push `game_token` berikutnya tidak bisa dibuktikan statis. Klasifikasi: **kemungkinan besar bertahan; belum 100% terverifikasi** — jauh lebih kuat daripada status "belum terverifikasi" di laporan dasar, tetapi belum boleh dijanjikan mutlak sebelum uji dinamis satu kali login ulang.

---

## Ringkasan vonis

| Fitur | Vonis | Bukti kunci (alamat di `libapp.so`) |
|---|---|---|
| 1. Bantuan iklan langsung cair (huruf + kunci jawaban), termasuk offline | **BISA — murni lokal** | Gerbang bool klien: earned set flag `0x4708e0`/`0x47096c`; dismiss teruskan flag `0x470a5c`/`0x470b18`; gagal → false `0x47098c`. Pemberian: `addProgress` `0x799200`, simpan SP `0x799414`/`0x799438`, verifikasi baca-ulang SP `0x7995b8`; muat dari SP `0x793d64–0x793ee4`; hint: kunci SP `hint_unlocked_` + cabang `"hint"` `0x470b58`. Nol referensi jaringan di jalur pemberian. |
| 2. Hapus timer level akhir | **BELUM TERBUKTI ada** | Pencarian string/pool menyeluruh nihil: tanpa string timeout, tanpa `Timer.periodic`/`Stopwatch`, tanpa konstanta durasi soal. Perlu verifikasi dinamis sebelum ada yang boleh di-patch. |
| 3a. Kebal salah jawab | **BISA — lokal** | Validasi + alur jawaban tanpa jaringan (`0x790b54–0x791670`); life = field 0x7 `GameData` (toString `0x54b0c8`); muat lokal-dulu (`0x764ca8`/`0x764fc8`). Titik instruksi pengurangan persis belum diisolasi (dinyatakan terbuka). |
| 3b. Tambah nyawa | **Kemungkinan besar bertahan** | Merge login menyusun life dari salinan lokal (`0x79f4b8` → disimpan `0x79f5ec`); struktur level dari server, peta data digabung (`0x79f5b4`). Sisa risiko: `syncFromServerSafe` belum dibedah + validasi server saat push belum terbukti. |

## Batasan

- Analisis statis murni (blutter + disassembly capstone beranotasi). Tidak ada eksekusi dinamis di perangkat; perilaku server yang sebenarnya (validasi push `game_token`) tidak teramati dari binary saja.
- Nama kelas/fungsi terobfuskasi; penamaan peran ("FreeAnswerProvider", "manajer iklan") berasal dari string debug bawaan aplikasi yang direferensikan fungsi-fungsi tersebut — string itu asli dari pengembang, bukan karangan analisis.
- Untuk Fitur 2 dan titik persis pengurangan nyawa di Fitur 3a, laporan ini sengaja berhenti di "belum terbukti/terisolasi" daripada mengarang alamat.
- Berkas kerja: `work/dart/out/` (keluaran blutter), `work/dart/scan_pp*.py`, `work/dart/disas.py`, `work/dart/span_*.txt`, `work/dart/*_closure.txt` — semua di bawah `~/workspace/rea-newdrive/work/dart/`.
