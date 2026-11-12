> Catatan arsip: Arsitektur tidak ditegaskan di laporan (APK lama, minSdk 7) — memakai `universal`.

# REA — Fragger (APK kiriman user, nama berkas mengandung "MOD")

- **Berkas:** `Fragger-_MOD__1.1.4-Android-1.com_3_lshu.apk`
- **Ukuran:** 22.360.155 byte
- **SHA-256:** `e5f2933abaa6f26ff99dc1c67a7c4f6243d2fbc359d7f76aa59135ab1e87b02f` (cocok dengan yang diberikan)
- **Metode:** statis murni — unzip, apktool (manifest), jadx (classes.dex), strings/od pada lib native dan aset. Tidak ada uji runtime.

## 1. Identitas

| Item | Nilai |
|---|---|
| Package | `com.miniclip.fraggerfree` |
| Nama | Fragger Free (Miniclip) |
| versionName / versionCode | 1.1.4 / 15 |
| minSdk / targetSdk | 7 / 17 (era Android 4.2) |
| Dex | 1 buah `classes.dex` (3.876.340 byte) |
| Lib native | 1 buah: `lib/armeabi/libfragger.so` (6.501.368 byte, ARM 32-bit EABI5, stripped) — hanya ABI armeabi lama, **tidak ada arm64** |

### Sertifikat — BUKAN penerbit asli

APK ditandatangani dengan **kunci debug/test AOSP publik**:

- Subject/Issuer: `C=US, ST=California, L=Mountain View, O=Android, OU=Android, CN=Android / android@android.com`
- SHA-256 sidik jari: `A4:0D:A8:0A:59:D1:70:CA:A9:50:CF:15:C1:8C:45:4D:47:A3:9B:26:98:9D:8B:64:0E:CD:74:5B:A7:1B:F5:DC` (sidik jari kunci debug Android yang dikenal publik)
- Masa berlaku 29 Feb 2008 – 17 Jul 2035, SHA1withRSA

Ini **bukan** sertifikat Miniclip. Kesimpulan: APK sudah **di-re-sign oleh pihak ketiga** dengan kunci yang tersedia untuk siapa saja. Konsekuensi praktis: tidak bisa menimpa instalasi versi Play Store (tanda tangan beda), dan siapa pun bisa menandatangani APK "yang sama" — tidak ada jaminan integritas dari penerbit.

### Apakah ini APK hasil modifikasi orang lain? — YA, terbukti

Tiga bukti independen:

1. **Kode asing disuntikkan ke dex.** Ada paket `com.savegame` berisi satu kelas `SavesRestoring` yang bukan milik Miniclip maupun SDK iklan mana pun di APK ini. Kelas ini dipanggil sebagai **baris pertama** `FraggerActivity.onCreate()` (`SavesRestoring.DoSmth(this)`) — titik kait yang ditambahkan ke activity asli.
2. **Save orang lain ditanam di aset.** `assets/data.save` (2.355.917 byte, ZIP) berisi **cadangan utuh folder data privat sebuah perangkat**: `shared_prefs/`, `databases/` (termasuk GetJar, Google Analytics, auth cache), `app_webview/`, dan `files/Contents/Resources/` (config.dat, score.dat, seluruh sumber daya game). Perangkat sumber teridentifikasi dari isinya: Samsung Galaxy Note 3 (SM-N900), Android 4.4.2, Device Id `1457214228970-6hm7crgg8r`.
3. **Isi mod-nya adalah status premium dari save tersebut:**
   - `shared_prefs/INAPP_PURCHASED_OWNED.xml`: produk `removeadsunlockworlds` = 1 (paket IAP "hapus iklan + buka semua dunia" tercatat sebagai **sudah dimiliki**).
   - `shared_prefs/ADS_DISABLED.xml`: `disabled = true`.
   - `files/Contents/Resources/score.dat`: medali dunia 1 — mayoritas bernilai 3 (tertinggi) sampai ±level 26 (`last-selected-1 = 26`).
   - Catatan jujur: `config.dat` pada save ini mencatat `unlimitedGrenades = false` dan `levelSkips = 0` — jadi mod ini **bukan** granat tak terbatas/uang maksimal; isinya murni unlock premium + bebas iklan + progres sebagian dunia 1.

Mekanisme mod: saat peluncuran pertama (penanda SharedPreferences `savegame/notfirst`), `SavesRestoring` mengekstrak `data.save` langsung ke `/data/data/com.miniclip.fraggerfree/`, menimpa data awal game. Kelas yang sama juga mendukung `extobb.save`/`extdata.save` (tidak ada di APK ini). Ini templat "save restorer" yang beredar umum di situs APK mod — bukan karya khusus untuk game ini.

Inventaris paket dex selain itu bersih dan sesuai era: Miniclip (billing, nativeJNI, newsfeed), Chartboost, Flurry, GetJar, Millennial Media, MoP
...[truncated 6312 chars]