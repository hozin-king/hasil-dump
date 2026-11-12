# Laporan Dump & REA — "Total Conquest" v1.0.2 (file kiriman user)

Tanggal analisis: 22 Oktober 2026 (WIB)
Metode: unzip penuh → apktool (manifest) → apksigner/jarsigner (sertifikat) → JADX headless (356 kelas, 597 file Java, 8 error decompile) → analisis strings DEX & paket aset → penelusuran jalur kode manual pada kelas-kelas kunci.
File: `_GJID_Total_Conquest_v1.0.2_Mod_15_a1e4.apk` — 9.181.791 byte, SHA-256 `eb7f69488422a41b5a214a7ea9f2d5ec19f4ba0a782e40ad6e928dad12a61af2`.

---

## 1. Identitas (terverifikasi dari file, bukan dari nama file)

| Item | Nilai |
|---|---|
| Nama game | Total Conquest |
| Package | `com.gameloft.android.GAND.GloftTCMF` (package resmi Gameloft untuk game ini) |
| Versi APK | versionName **1.0.2**, versionCode 10200 |
| minSdk / targetSdk | 9 / 18 (era Android 4.3) |
| Pengembang asli | Gameloft SA ("MIDlet-Vendor: Gameloft SA", GAME-PRODUCT-ID 1769, GAME-GGI 53933) |
| Asal build | Build **IGP/operator untuk Samsung GT-i9000 (Galaxy S generasi pertama)** — bukti `content.txt`: `MIDlet-Jar-URL: TotalConquest_Samsung_GT_i9000_L_IGP_GAND_ML_IAP_102.jar`, `GameVer: 1.1.1` |
| Activity utama | `.Start` (launcher) → `.S800x480.GloftTCMF` (game) |
| Sertifikat penanda tangan | **BUKAN Gameloft** — lihat §2 |

Isi paket sangat ramping (226 file, 18,5 MB ter-ekstrak): satu `classes.dex` (1,5 MB) + aset paket data resolusi 800x480. Tidak ada OBB/ekspansi.

## 2. Vonis: MODIFIKAN PIHAK KETIGA — dan isi mod-nya

**Bukti penanda tangan (paling keras):** APK ditandatangani sertifikat **AOSP test key publik** —
DN `EMAILADDRESS=android@android.com, CN=Android, OU=Android, O=Android`, SHA-256 `a40da80a59d170caa950cf15c18c454d47a39b26989d8b640ecd745ba71bf5dc`.
Itu kunci debug/test Android yang tersedia publik; Gameloft tidak pernah merilis dengan kunci ini. Kesimpulan: **APK sudah dibongkar, diubah, dan ditandatangani ulang oleh pihak ketiga.**

**Yang TIDAK ditemukan (sama pentingnya):**
- Tidak ada mod menu, tidak ada overlay/floating service, tidak ada activity/receiver/service asing di manifest — seluruh komponen adalah komponen pola rilis Gameloft era itu (Start, GCM, KeyProvider, IAP MyWebView, Facebook LoginActivity, LocalPushReceiver).
- Tidak ada paket kode asing. Semua paket ter-obfuscate teridentifikasi sebagai SDK sah era 2013–2014: Amazon IAP ("Kiwi"/PurchasingManager, `com/a/a/a`), Samsung IAP (`com.sec.android.iap`, `com/c/a/a`), Google Play IAB (`com/b/a/a`), Sina Weibo SSO (`com/d/a`), Facebook SDK (tidak ter-obfuscate), library IAP Gameloft sendiri (`com.gameloft.android2d.iap.*`).
- Tidak ada file save/RMS bawaan berisi progres curang; simpanan dibuat saat runtime.

**Yang kemungkinan besar diubah (inferensi kuat, bukan diff per-baris — tidak ada APK stok pembanding di VM):**
1. Re-sign dengan testkey (terbukti, di atas).
2. Pelolosan **validasi langganan/lisensi build operator**: build ini adalah build berlangganan operator (paket teks memuat "VALIDATING SUBSCRIPTION / LICENCE INVALID / WE ARE CURRENTLY UNABLE TO VALIDATE THE SUBSCRIPTION FOR THIS GAME"). Build stok semacam itu tidak bisa berjalan standalone; file mod yang beredar wajib menonaktifkan/mem-bypass gerbang ini. Jalur permintaannya terlihat di `b/a/d/a.java:513` (framework mengirim `?key=` + isi `res/raw/serialkey.txt` = `988dmjh3420` ke server validasi).
3. serialkey tersebut bisa jadi kunci stok build ini atau kunci bersama yang ditanam modder — **tidak terkonfirmasi** mana yang benar.

Jadi "Mod" pada file ini secara realistis = **bypass lisensi/langganan + re-sign**, bukan cheat ekonomi. Penilaian atas klaim fitur mod ada di §8.

## 3. Dump penuh — inventaris & peran

### Native (.so) — hanya 2 lib kecil, BUKAN mesin game
| Lib | ABI | Ukuran | Peran (dari simbol JNI) |
|---|---|---|---|
| `libgenerator.so` | armeabi, armeabi-v7a, x86 | ±448 KB (x86: 579 KB) | **HDIDFV** Gameloft — `Java_com_gameloft_android_hdidfv_HDIDFV_getNHDIDFV*`: pembangkit ID perangkat untuk verifikasi/lisensi (memakai boost). |
| `libnativeU.so` | sama | ±13 KB (x86: 5 KB) | **NativeUtils** — `getClock/getClockMillis/getClockNano` (jam monotonik `clock_gettime`) + `CheckRoot`/`IsDeviceRooted` (deteksi root native). |

Tidak ada lib mesin grafis/gameplay native — **seluruh logika game ada di Java (classes.dex)**.

### Kode Java (paket utama)
- `com.gameloft.android.GAND.GloftTCMF` (31 kelas) + `.S800x480` (86 kelas, ter-obfuscate nama 1–2 huruf): kelas game inti `br.java` (±22.700 baris — logika MIDlet game), `bo.java` (±6.100 baris), `GLLib.java` (kerangka GL), `bg.java` (sesi/analitik GLOT + auth mata uang virtual), `ay.java` (konfigurasi server EVE), `l.java` (GDID).
- `com.gameloft.android2d.*` — framework Gameloft: IAP/freemium, social network.
- `com.gameloft.android.wrapper` — wrapper perangkat (lisensi, serial key, cek root & tanda tangan).
- `com.gameloft.android.hdidfv` — HDIDFV.
- SDK pihak ketiga: Facebook, Weibo, Amazon IAP, Samsung IAP, Google IAB, GCM.

### Aset (`assets/800x480/`, ±17 MB)
- File bernomor `0`–`60` + pecahan (`3.1`, `5.1`–`5.4`, `6.1`–`6.8`): **paket data/sprite format proprietary Gameloft** (header tabel offset terstruktur, bukan enkripsi penuh) — berisi data game & grafis resolusi 800x480.
- File bahasa per negara (`EN`, `DE`, `FR`, …): **teks polos terbaca penuh** — sumber utama peta sistem game di laporan ini.
- `IAP_profiles` (teks polos, format `;`): profil penagihan SMS operator per negara — untuk Indonesia: Indosat/Telkomsel/H3G Rp2.000–Rp15.000 per transaksi token.
- `events.json`: skema analitik (parameter `cash_balance`, `cash_earned`, `ch_level`, `xp_earned`, dll).
- `InitialFeed.bin` (720 byte): byte awal entropi tinggi → ter-obfuscate/terenkripsi ringan; isi persisnya tidak dibedah.
- `dataIGP`/`dataIGPSprites*`: data promosi in-game (katalog game Gameloft lain).
- `res/raw/serialkey.txt`: `988dmjh3420` (kunci build untuk validasi, lihat §2).
- `res/raw/content.txt`: metadata build MIDlet (identitas di §1, `EnableOnline: http://eve.gameloft.com:20001`).

## 4. Engine

**Framework Java "android2d" milik Gameloft — turunan langsung kerangka MIDlet/J2ME mereka.** Bukti: metadata `MIDlet-*` lengkap di `content.txt`, kelas game bernama `GloftTCMF` (pola penamaan MIDlet Gameloft), sistem simpanan meniru RecordStore (RMS) J2ME (`bj.e(...)` membuka "store" bernama), teks UI memuat warisan J2ME ("PRESS 5", "PRESS OK"). **Bukan** Unity/Unreal/Cocos; tidak ada mesin native. Render & logika murni Java di atas wrapper Android Gameloft.

## 5. Arsitektur: ONLINE PENUH, terikat akun server (inti vonis)

Total Conquest di file ini adalah game **selalu-online berbasis akun server**, dibuktikan berlapis dari kode dan data file sendiri:

1. **Platform akun EVE** — `S800x480/ay.java:167`: klien mengambil **konfigurasi server** dari `http://eve.gameloft.com:20001/config/...` (kelas ini bernama log "SaveServerConfig"). EVE adalah platform online Gameloft (akun, sesi, layanan game).
2. **Identitas akun global (GDID)** — `gdid.gameloft.com/assign_global_id/` & `update_device_id/`; RMS lokal menyimpan `glot_gdid` (`l.java`). Save terikat akun: paket teks memuat dialog **"The save does not match / The account does not match / Change to this / Keep this"**.
3. **Save ada di server** — dialog konflik resmi game: *"If you switch to this data, it will overwrite the save that is currently associated with your device"* vs *"If you keep this data, it will overwrite the save that is currently on the server."* Progres = state akun di server; klien menyimpan cache/sinkronisasi lokal (RMS: `File_marker` berisi `sessionId`, `glot_save_time`, `GLOT_synchronizerCounter`).
4. **Server mata uang virtual (VGOLD)** — `S800x480/bg.java:739`: selama bermain, klien melakukan **auth berkala tiap 180 detik** ke `http://vgold.gameloft.com:20000/locate/auth`.
5. **PvP asinkron melawan pemain asli** — kota pemain lain diserang untuk menjarah sumber daya ("Steal %s Gold from players", "Free Food! Steal %s Food from other players", "Caesar of Slaughter: Win %s multiplayer battles", "Available Loot", "Fight another player to gain Glory!"). Sasaran bisa sedang online/perisai ("This player is online. You can't attack them right now", "This player has a shield"). **Kotamu diserang saat kamu offline**: notifikasi `offline_lord_attack_notice`, teks "You will be attacked by lords", "Thank the gods you're back! … we were attacked while you were away … they've managed to steal a portion of our resources", log pertempuran + **replay** server ("Battle Logs", "View Replay", "You were defeated by %s", "Resources looted", "Get Revenge", "Bribe"). Ada **Raid Shield** berbatas waktu (24 jam/3 hari/1 minggu) — mekanisme khas dunia persisten server.
6. **Sosial server** — Legion (guild: buat/gabung, donasi sumber daya, minta unit, undangan — semua lewat server), **global chat** ("Welcome to the global chat"), leaderboards, profil pemain dimuat dari server ("Loading user profile. Please wait…"), inbox/pesan antar pemain.
7. **Gerbang koneksi keras** — teks resmi: "No Internet connection available. Please connect to the Internet.", "Connecting to server. Please wait…", "Connection failed!", "Server is busy", "A new version is now available. Please update your version to play online."
8. **Kampanye memang ada** (misi vs AI: Spurius, Donatianus, Sulpicius, Trebellius; bintang 1–3; "Super Star: Acquire %s stars in the campaign") — tetapi kampanye berjalan **di dalam akun online yang sama** (progres, bintang, dan hadiahnya bagian dari state server), bukan mode offline terpisah.

## 6. Ekonomi & sistem (dari bukti file)

- **Mata uang lunak: Gold & Food** — diproduksi Villa (Gold) & Farm (Food) per waktu, ditampung Gold/Food Storage berkapasitas terbatas; dipakai untuk bangun/upgrade/latih pasukan. Teks: "Soldiers need Food, and building requires Gold."
- **Mata uang premium: Tokens (disebut juga "cash" di analitik)** — "You don't have enough Tokens!", paket "Pouch/Bags/Bountiful Chest of Tokens". Didapat dari achievement, naik level, membersihkan reruntuhan, dan **dibeli**: (a) lewat Market dalam game dengan Gold/Food; (b) dengan uang asli lewat penagihan SMS operator (profil Indonesia di `IAP_profiles`) / kanal IAP lain — **divalidasi server** (`https://secure.gameloft.com/freemium/wapbilling/validate.php`, `https://iap.gameloft.com/freemium/getmanageditems/`, alur kode redeem SMS "INPUT CODE / The SMS has been sent").
- **Waktu bangun & latih** — "Building time: %s", antrean Barracks, opsi resmi "Finish now" (mempercepat pakai Tokens). Jam game dijaga anti-curang (lihat §7), dan state-nya tersinkron ke server — timer bukan murni hitungan lokal yang bebas.
- **Bangunan/sistem lain**: City Hall (penentu tier semua bangunan), Barracks, Muster Ground (kapasitas pasukan serang), Blacksmith (riset unit), Forum (Legion), Temple (buff berbatas waktu 2–48 jam), Architect (pekerja paralel tambahan — bisa disewa), tembok/gerbang/menara pertahanan/jebakan, potion pertempuran.
- **Penyimpanan lokal**: emulasi RMS J2ME (store: `File_marker`, `glot_save_time`, `glot_gdid`, `GLOT_synchronizerCounter`, `device`, satu store sesi GLOT bernama acak `SAGFdfajkshSF2345sMHL`) — isinya penanda sesi, waktu tersinkron, dan ID; **bukan** otoritas progres (otoritasnya server, §5.3).

## 7. Anti-cheat & integritas klien (bawaan Gameloft, dari kode)

1. **Cek hash tanda tangan** — `wrapper/l.java qA()/qB()`: hashCode sertifikat penanda tangan APK dibandingkan ke nilai harapan Gameloft yang tertanam; hasilnya disimpan sebagai properti `com.gameloft.Signature` dan **dibaca `bg.java`** untuk dimasukkan ke muatan data sesi/analitik yang dikirim ke server (telemetri — server bisa melihat klien hasil re-sign).
2. **Deteksi root native** — `libnativeU.so` `CheckRoot` → `GLLib.lA`; status root juga dikirim sebagai parameter analitik ("jb" pada skema sesi GLOT di `bg.java`).
3. **Jam anti-manipulasi** — `GLLib.bW()`: waktu game dihitung dari jam monotonik native (`clock_gettime` via libnativeU) yang dirujuk ke cap waktu awal, bukan dari jam dinding mentah — memajukan jam HP tidak mempercepat timer secara naif.
4. **Sidik perangkat HDIDFV** (`libgenerator.so`) — dipakai di URL iklan/IAP/validasi; mempersulit pemalsuan perangkat & pengulangan akun.
5. **Validasi transaksi server** untuk pembelian (§6) + item terkelola server (`getmanageditems`).

## 8. Peta cheat — vonis per fitur

| Fitur kandidat | Vonis | Bukti / alasan |
|---|---|---|
| Tokens tak terbatas | **SERVER–TIDAK** | Premium currency terikat akun GDID/EVE; pembelian divalidasi server (wapbilling validate, getmanageditems); auth VGOLD berkala. Angka di klien hanya tampilan. |
| Gold/Food tak terbatas (untuk progres nyata) | **SERVER–TIDAK** | Kota & sumber daya adalah state akun server (dialog konflik save device↔server, save/account mismatch); hasil jarahan PvP diproses server. Mengubah angka lokal akan tertimpa sinkronisasi / tidak diakui server. |
| Bangun & latih instan | **SERVER–TIDAK** | Timer dijaga jam monotonik anti-clock-cheat + tersinkron server; jalur resmi mempercepat = "Finish now" pakai Tokens (transaksi server). |
| Menang PvP otomatis / jarahan besar / Glory | **SERVER–TIDAK** | Lawan, kota lawan, hasil, loot, glory, battle log & replay semuanya urusan server; menyerang pemain asli. |
| Unlock misi/level/bintang kampanye untuk akun | **SERVER–TIDAK** | Progres & bintang bagian dari state akun server (§5.8). |
| Duplikasi item/IAP gratis | **SERVER–TIDAK** | Item terkelola + validasi kwitansi/kode di server Gameloft. |
| Menu cheat debug bawaan ("Add 5,000 gold", "Add 5,000 food", "Add 10,000 tokens", "Win Battle", "Level UP", "Unlock all missions", "Unlock all achievements", "Upgrade all walls", "Empty cash", "Elapse time", dll) | **ADA sebagai string di paket teks ORIGINAL — aktivasi TIDAK TERBUKTI; efeknya pun server-bound** | Deretan string "Cheats/Unlocks" adalah sisa perangkat debug internal Gameloft yang ikut terbawa di paket bahasa build ritel (pola umum framework ini). Tidak ditemukan bukti jalur aktivasi di build ini; dan sekalipun terbuka, perubahan ekonominya bertabrakan dengan state server (§5–6). |
| Hal kosmetik klien murni (tampil FPS/heap, matikan iklan promo IGP lokal, ganti bahasa) | **LOKAL–BISA (kosmetik, tak menyentuh progres)** | Murni rendering klien; tidak ada nilai gameplay yang diakui server berubah. |
| Bypass lisensi/langganan build operator | **Sudah dilakukan modder file ini (bukan cheat gameplay)** | Lihat §2 — inilah isi "mod" yang realistis dari file ini. |

**Penilaian klaim mod bawaan file ini:** Nama file hanya mengklaim "Mod" generik. Dari arsitekturnya, klaim gaya situs mod untuk game ini (unlimited tokens/gold/food, serba instan) adalah **omong kosong secara teknis**: semua nilai itu milik akun di server, dan tidak ada mod menu/penambal nilai di dalam file ini yang bisa mengubah pengakuan server. Yang benar-benar diberikan file ini: game build operator lama yang **bisa dipasang & dibuka** (re-sign + lolos validasi langganan).

**Catatan konteks (di luar bukti file):** infrastruktur yang dirujuk file ini (EVE `eve.gameloft.com:20001`, VGOLD, GCM) adalah infrastruktur Gameloft era 2013–2014; Total Conquest sendiri sudah lama ditutup Gameloft. Uji DNS dari VM tidak konklusif (nama ter-resolve ke rentang IP proksi egress 198.18.x.x). Implikasi praktisnya: hari ini game ini kemungkinan besar bahkan tidak bisa login — sehingga seluruh diskusi cheat ekonomi bersifat teoretis untuk file ini.

## 9. Ukuran dump

`~/workspace/rea-totalconquest/` total **60.865.295 byte (±61 MB)**: downloads/ (APK 9.181.791 byte), extracted/ (226 file, ±19 MB), analysis/ (apktool_out + jadx_out 597 file Java + log & daftar isi).

## 10. Yang tidak terkonfirmasi

1. Diff per-baris terhadap APK stok Gameloft (tidak ada berkas stok pembanding) — rincian patch modder selain re-sign bersifat inferensi (§2).
2. Apakah menu cheat debug bisa dipicu di build ini, dan dengan input apa.
3. `serialkey.txt` (`988dmjh3420`): kunci stok build atau tanaman modder.
4. Isi `InitialFeed.bin` (ter-obfuscate) tidak dibedah sampai tuntas.
5. Status hidup/mati server Gameloft per Oktober 2026 tidak diuji langsung (DNS VM ter-proksi); konteks penutupan game berasal dari pengetahuan eksternal, bukan dari file.
