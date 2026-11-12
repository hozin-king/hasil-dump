# REA — World Football League (com.touchtao.soccerkinggoogle) v1.9.9.7

Analisis statis saja — tidak ada build, tidak ada perubahan kode. Perkakas: jadx (dex → Java), apktool (manifest/res), nm/readelf/strings pada `libHQRenderLib.so`. Batas VM: tidak ada Ghidra/IDA, jadi analisis native berbasis peta simbol dinamis + string, bukan pseudocode.

## 0. Vonis ringkas

- Ini game lama TouchTao (penerbit Mobirix) yang **seluruh logika gamenya C++ native** di `libHQRenderLib.so` (engine internal "M3D/HQ"). Java/Kotlin di dex **hanya cangkang**: jembatan JNI, Billing, Play Games, iklan, Firebase Analytics. Tidak ada logika game yang bisa di-hook di Java.
- Game ini **punya mode online sungguhan melawan manusia**: server sendiri `wslogin.touchtao.com`, protokol socket khusus — registrasi nickname, ruang (create/join/kick), pertandingan, leaderboard server, pesan, dan berbagi rekaman pertandingan (playback) yang disimpan di server.
- Ekonomi = **unlock berbayar sekali beli**, bukan mata uang: 4 SKU Play Billing. Verifikasi pembelian **lokal** (RSA klasik), hak akses disimpan lokal oleh kode native. Tidak ada validasi server. Tidak ada sistem energi/stamina. "Coin & Diamond" hanya nama tekstur menu warisan versi lama.
- **PairIP: TIDAK ADA** (vonis standar koreksi — bukti di §7).
- Karier/liga/piala (mode CL) 100% lokal di perangkat. Yang server: mode MP, leaderboard MP, penyimpanan playback. Play Games: 2 leaderboard publik + 9 achievement, nilainya dihitung lokal lalu diserahkan ke Google.

## 1. Identitas & bundle

| Item | Nilai (bukti) |
|---|---|
| Package | `com.touchtao.soccerkinggoogle` (manifest) |
| Label | **World Football League** (`res/values/strings.xml`: `app_name`) |
| versionName / versionCode | **1.9.9.7 / 62** (manifest). Angka "1.9.9.9.9.7" di nama berkas kiriman user adalah penamaan toko/situs unduhan, bukan versi aplikasi. |
| minSdk / targetSdk | 23 / 35 |
| Application | `androidx.multidex.MultiDexApplication` — tidak ada Application kustom |
| Activity utama | `com.touchtao.soccerkinggoogle.WinnerSoccer2014` (MAIN/LAUNCHER, landscape, fullscreen) |
| Pengembang / penerbit | TouchTao (kode, string hak cipta "(C)TouchTao") / Mobirix (akun Play `developer?id=mobirix`, AdMob `ca-app-pub-6743569825907537`, dukungan `help.mobirix.com/...game_idx=161`) |
| Isi bundle | base.apk 47.013.932 B (281 entri) + split arm64 (hanya `libHQRenderLib.so` 4.996.936 B) + split `in` + xxhdpi |
| Beban base | `assets/res_all.pak` 23,7 MB (semua aset+data game, format arsip LZMA), `assets/s.mp3` 7,4 MB, dex 7,37+8,22 MB + `classes3.dex` 596 B (shim D8) |
| Sertifikat base | CN=sj, self-signed 2010–2110, SHA-256 `1FD0C148…6FC5` |

**Catatan asal-usul bundle:** `stamp-cert-sha256` di split = `3257d599…733bbd6d`, **tidak sama** dengan penanda tangan base (CN=sj). Pola yang sama persis dengan bundle Catur Jetstart kemarin (hash stamp identik) — kesimpulan hati-hati: kedua bundle ini melewati jalur repack/distribusi pihak ketiga yang sama, bukan unduhan Play murni. Konsekuensi praktis dibahas di §8.

Izin (manifest, lengkap yang relevan): INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, BILLING, WAKE_LOCK, VIBRATE, READ/WRITE_EXTERNAL_STORAGE (warisan), AD_ID + izin AdServices (tumpukan iklan), izin signature milik sendiri. **Tidak ada** izin lokasi/telepon-state/kamera.

## 2. Arsitektur — logika game di native, Java hanya cangkang

### 2.1 Sisi Java (dex) — 11 berkas game, sisanya SDK

Kelas game utuh (jadx, nama asli tanpa obfuskasi):

- `com.touchtao.soccerkinggoogle.WinnerSoccer2014` — Activity utama + semua callback JNI untuk native: Billing, Play Games, iklan, UDID, sensor/gamepad.
- `com.touchtao.soccerkinggoogle.ProductItemInfo` — katalog IAP (§4).
- `com.touchtao.soccerkinggoogle.ConstantParam` — ID iklan, ID Play Games, kunci publik lisensi.
- `com.touchtao.common.HQRenderLib` — deklarasi `native` murni (System.loadLibrary("HQRenderLib")); `HQGameView`/`HQGameRenderer` = GLSurfaceView + antrean callback ke native (mis. `SetNeedCallBack_PayOrderDirect_PurchaseFinished`).
- `com.touchtao.common.HQAppGooglePaySec` — verifikasi tanda tangan pembelian RSA lokal (§4).

Sisa ~7.300 kelas dex adalah SDK: AdMob + mediasi AppLovin MAX (Unity Ads, Meta Audience Network, Pangle/`com.bytedance.sdk`, Liftoff/Vungle, Fyber, InMobi, Mintegral, Chartboost), Firebase Analytics/Installations/Measurement saja, Play Billing 7.0.0, Play Games v2, androidx. **Tidak ada** kelas `firebase-auth`/`firestore`/`firebase-database` (tidak muncul di daftar `.properties` maupun jadx) → tidak ada akun Firebase, tidak ada cloud save. Room & WorkManager yang terdaftar di manifest adalah bawaan pustaka SDK — nol pemakaian di kelas game (satu-satunya "Room" di paket game adalah nama resource `R.java`).

### 2.2 Sisi native — `libHQRenderLib.so` (satu-satunya .so)

ELF64 aarch64, BuildID `1d5d05250365ac0b7484c02db750ed89fe8d19be`, clang 21. Tabel simbol dinamis **utuh terbaca: 9.255 simbol** — peta kelas/metode C++ lengkap. Komposisi kelas utama (jumlah simbol):

- Engine "M3D": `CM3DDevice3`, `CM3DTexture3`, `CM3DXMesh`, `CM3DAssetFileSystem` (baca `res_all.pak`), font/rich-text; audio `vox::` (Vox engine, 934 simbol, pihak ketiga); JsonCpp; LZMA/7-Zip (`NCompress`, `CLZMAFileManager`, CLSID/IID codec) untuk membuka .pak.
- Game: `CGame` (75), `CGamePlay` (53), `CPlayer` (102), `CTeam` (97), `CTeamManager` (43), `CFootBall` (43), `CCupAndLeague` (46), `CHQGameWndSession` (81), `CHQMainGameWnd` (61), ±55 kelas menu `CGameMenu_*` — **seluruh UI game digambar native** (bukan layout Android).
- Jaringan: `CNetworkManager` (60), `CConnection` (40), `CBlockingSocket`, `CM3DXPlayerSocket(Android)`, `CM3DXPlayerHttp`, `CPacketManager`, `CGameRoom`.
- Jembatan JNI hanya ±20 fungsi: siklus GLSurfaceView (`onDrawFrame`, `onSurfaceCreated/Changed`, `onPause/Resume`), input (`onPointerClick/Move`, `onKeyClick`, gamepad), `onTextEditFinished`, `onAdvHasPopup`, dan `onPayOrderDirectPurchaseFinished(int)` — gerbang hasil pembayaran dari Java ke native.

**Di mana tiap bagian tinggal:**

| Bagian | Tempat | Bukti |
|---|---|---|
| Simulasi pertandingan | Native | `CGamePlay`, `CPlayer`+status `CPlayerState_*`, perintah `CPlayerCmd_*`, `CDribblePool` (pengambil keputusan CPU: `GetShootScore`, `GetLongShootScore`, `GetLongPassScore`, `DoDecision`) |
| Karier/liga/piala | Native | `CCupAndLeague` + menu `CGameMenu_CL_*` (jadwal, klasemen, versus, rekor) |
| Ekonomi/toko | Native (UI+logika) + Java (transaksi) | `CGameMenu_Shop`, `CGame::EnterLayOut(..., GAME_SHOP_ITEM_TYPE, ...)`; Java hanya menjalankan Billing & verifikasi |
| Multiplayer | Native penuh | `CConnection`/`CNetworkManager` (§3) |
| Render | Native (OpenGL ES, M3D) | sesuai nama lib & `HQGameRenderer` |

**Obfuskasi: praktis tidak ada.** Nama kelas/metode Java game asli (plus string berbahasa Mandarin warisan pengembang di `ProductItemInfo`), dan dynsym native membuka seluruh peta C++ termasuk nama parameter enum. Yang "tertutup" hanya isi fungsi native (butuh disassembly; tidak ada Ghidra di VM ini).

## 3. Mode permainan & permukaan online

### 3.1 Mode lokal

Dari sensus menu native: **Cup & League (CL)** — grup otomatis/manual, varian World Cup, jadwal, klasemen liga, tabel versus, rekor, pengaturan pertandingan; **latihan** (`SelectTraining`), pilih tim (+World Cup), adu penalti (ada achievement-nya), putar ulang & simpan rekaman (`Replay`, `SaveLoadReplay`), toko, opsi. Pertandingan persahabatan/cepat lewat `SelectMode`/`StartGame`.

### 3.2 Mode MP — online sungguhan, server sendiri (BUKTI KUAT)

Ini bukan sisa menu mati; tumpukan protokolnya lengkap di `CConnection` (alamat VA di lib):

- Koneksi & login: `CConnection(char const* host, int, int)` `0x3c7e5c`; `Connect()` `0x3caa0`; `SendLoginPackage(char const*)` `0x3c8fbc`; `SendEstablishConnectionPackage()` `0x3c8ce4`; host server berupa string di native: **`wslogin.touchtao.com`**.
- Registrasi identitas: `CNetworkManager::LoadRegistration()` `0x3cd098` / `SaveRegistration()` `0x3ccd4c` / `IsNicknameValid(char const*)` `0x3cd11c`; identitas pemain = `_UserUDID_Hash` (hash dari UDID perangkat/UUID yang dibuat Java dan disimpan di SharedPreferences `UUID_SAVE`, atau ANDROID_ID).
- Ruang pertandingan: `SendCreateSessionPackage(SGameSessionInfo*)` `0x3c9730`, `SendJoinSessionPackage(_UserUDID_Hash*)` `0x3c97c4`, `SendLeaveSessionPackage()` `0x3c9864`, `SendKickOutPlayerPackage(...)` `0x3c99cc`; model ruang `CGameRoom` (nama, pemain per slot, UDID); menu `CGameMenu_MP_SelectServer` → ada **pilihan server**.
- Pertandingan: `SendStartGamePackage()` `0x3c98d4`, `CNetworkManager::ProcessGamePacket(DataPacket*)` (paket selama pertandingan berjalan), `SendFinishGamePackage(int)` `0x3c9944` — **skor akhir dilaporkan klien ke server** dengan satu int.
- Leaderboard server: `SendGetRankingPackage(GAME_LEADERBOARD_TYPE, int, int)` `0x3c9394` / `RequestLeaderBoard(...)` `0x3cd24c`; menu `CGameMenu_MP_LeaderBoard(+Detail)`.
- Pesan antar-pemain: `SendGetMessagePackage`, `SendGetMessagesInfoPackage`, menu `MP_ViewMessage`.
- **Playback (rekaman) di server:** `SendPutPlaybackPackage(bool,int,int,char*)` `0x3c94e4` (unggah), `SendGetPlaybackPackage(...)` `0x3c95a8`, `SendGetPlaybackInfoPackage`, `SendPutPlaybackCommentPackage(...)`, menu `MP_PlaybackPutPrompt`/`MP_PlaybackComment`. Ini fitur "TV channel" berbayar di §4: rekaman gol disimpan di server dan dibagikan.
- Keandalan: antrean retry paket (`SaveRetryData`/`SendRetryData`, `CPacketManager::SaveCriticalPacket`), keep-alive (`KeepConnectionAlive`).

Karakter modelnya: pertandingan berjalan di klien (mesin yang sama), server mengatur sesi/relai paket dan **mempercayai laporan hasil dari klien**. Apakah servernya masih hidup hari ini tidak bisa dibuktikan dari analisis statis — kode jalurnya utuh; status operasional `wslogin.touchtao.com` di luar cakupan bedah berkas ini.

### 3.3 Play Games (Google)

Didorong dari native lewat callback Java statis di `WinnerSoccer2014`:

- Masuk Google Play Games (`InitializeGooglePlus`, `getGoogleLoginStatus`, `CheckAndResignin`).
- **2 leaderboard publik** diserahkan nilainya oleh Java: `LEADERBOARD_GOAL_SCORE` (`CgkI77jJnuUJEAIQAQ`) ← `mTotalGoalScore`, `LEADERBOARD_MATCH_SCORE` (`CgkI77jJnuUJEAIQCw`) ← `mTotalMatchScore`; kedua int itu diisi native lewat `setLeaderBoardData(int,int)` lalu `submitScore` saat user membuka papan (di `googleButtonClick`).
- **9 achievement** dibuka native lewat `unlockAchievementData(int)`: kemenangan pertama CL, juara pertama CL, penalti pertama, pakai TV channel pertama, unlock CL pertama, total gol 100/1.000/10.000/100.000.
- `onUploadServerAuthCode(String,String)` ada tapi **stub `return false`** — pengaitan akun server via kode auth Play Games TIDAK diimplementasikan di build ini.

### 3.4 Lain-lain

Firebase = Analytics + Installations saja (event `gameAnalysisLogEvent` bahkan no-op di Java). Sisa template lama yang mati: registrasi GCM ke `touchtao.com/gcm/gcmClientReg.asp`, `checkbrowser.asp`, GA `UA-47867358-55`, Chartboost. Mobirix: cross-promo `cross.mobirix.net`, halaman GDPR `gdprinfo.mobirix.net:33364`, kelas native `CMobirixMoreGame` + berkas `adv.sav`.

## 4. Ekonomi & IAP

### 4.1 Katalog (Java, `ProductItemInfo.GetProductInfo` — bukti langsung)

Hanya **4 SKU** Play Billing, semuanya unlock sekali beli:

| ID produk native | Isi | SKU |
|---|---|---|
| 1–6 | "赛制 baru" — format kompetisi baru: ikut berbagai liga & piala | `foot499` |
| 7–132 | "Tim baru" — unlock tim | `foot199` |
| 133–140 | "Saluran olahraga baru" — simpan rekaman pertandingan **di server**, bagikan gol ke teman sedunia (= fitur playback server §3.2) | `foot099` |
| lainnya (default) | "Buka semua level & mode game" | `com.touchtao.ws2014google.unlockgame` |

Di native, semua pembelian mengalir lewat satu tipe `GAME_SHOP_ITEM_TYPE` dan satu gerbang: `CGameMenu_Shop::PurchaseItem(item)` `0x38e468`, `GetPurchaseInfo(item, int*×5)` `0x38e218`, `IsItemRealMoneyPurchase(item)` `0x38e35c`, `OnPurchaseFinished(int)` `0x38e364`, `OnRestoreItem(int)`/`OnRestoreFinished(int,int)` (pemulihan pembelian), `ReceivePresentItem(item,int)` (hadiah). Ikon gembok + harga digambar generik: `CGameMenu::DrawLockIcon(...)`, `DrawItemPrice(...)`, `GetItemMoneyTexture(item, bool)`. `CHQMainGameWnd::Achievement_UnlockCupLeague(GAME_SHOP_ITEM_TYPE)` `0x34e004` mengaitkan unlock CL ke achievement Play Games.

### 4.2 Alur & validasi pembelian — LOKAL, tanpa server

`WinnerSoccer2014.HandlePurchase(Purchase)` (classes2.dex):

1. `VerifyValidSignature(originalJson, signature)` → `HQAppGooglePaySec.verifyPurchase(kunciPublikPlay, …)` — verifikasi **RSA SHA1withRSA lokal di perangkat** dengan kunci publik dari `ConstantParam.IABParam` (pola IAB klasik).
2. Lolos & status purchased → `consumeAsync(...)` (semua produk dikonsumsi; pemulihan via query + `OnRestoreItem`), lalu hasil 1/0 diteruskan ke native: `HQGameRenderer.SetNeedCallBack_PayOrderDirect_PurchaseFinished(1)` → JNI `HQRenderLib.onPayOrderDirectPurchaseFinished(int)` → **native memberi unlock dan menyimpannya di data lokalnya sendiri**.

Tidak ada panggilan backend apa pun di jalur pembelian. Status kepemilikan unlock = **data lokal native**.

### 4.3 Yang TIDAK ada

- **Energi/stamina sebagai sistem: tidak ada** — 0 kemunculan "energy"/"stamina" di seluruh string native; tidak ada timer/hati di Java. (Atribut pemain di basis data memang urusan stat pemain, bukan gerbang bermain.)
- **Mata uang lunak yang bisa dibelanjakan: tidak terbukti ada di build Google ini.** Satu-satunya jejak "Coin/Diamond" adalah nama tekstur `Res\Menu\CoinAndDiamond.bmp` dan `FormatMoneyString(int, char*, bool)` (pemformat harga) — warisan antarmuka versi pasar Tiongkok/Korea (ada juga `MoneyS_Kr.bmp`, cek appstore LG U+ di `ConstantParam`). Seluruh pembelian nyata terpetakan ke 4 SKU di atas.

## 5. Data & simpanan

- **Data game utama: di memori/disk oleh native**, direktori privat aplikasi — string jalur `/data/data/com.touchtao.soccerkinggoogle` tertanam di lib. Serialisasi karier: `CCupAndLeague::Save(_ConfigData*)` `0x3d3b80` / `Load(_ConfigData*)` `0x3d3a7c` dan `SaveCupLeague(void*)` `0x3d03c4` / `LoadCupLeague(void*)` `0x3cfc0c` (stream biner `_ConfigData`). Nama berkas persisnya dibangun saat runtime dan tidak muncul sebagai string utuh — batas jujur bedah statis ini.
- **Registrasi MP** (nickname + UDID hash): `CNetworkManager::SaveRegistration/LoadRegistration` — berkas lokal native juga.
- **Rekaman pertandingan lokal:** `CGamePlay::SaveReplayData(int, bool)` `0x341104`; menu `SaveLoadReplay::SaveBlock()`. Rekaman bersifat data input/perintah (makanya kecil dan bisa diunggah sebagai playback).
- **Java/SharedPreferences:** `UUID_SAVE` (UUID acak identitas perangkat) + prefs GCM warisan. Tidak ada Room/SQLite dari game.
- `adv.sav` = status iklan/cross-promo Mobirix (`CMobirixMoreGame::SaveAdvInfo/LoadAdvInfo`).
- Basis data konten (di dalam `res_all.pak`): `Res\Data\PlayerDB2022_En.dat`, `TeamDB2022_En.dat` (roster 2022; varian Zh juga ada), `KeyFrameInfo.dat`, `form.bin`.

## 6. Internal pertandingan

- **Hasil pertandingan dihitung penuh di klien** — untuk semua mode. Mode MP memakai mesin yang sama; server hanya sesi/relai + pencatat hasil (§3.2). Tidak ada tanda tangan/validasi hasil dari server di kode klien.
- AI lawan = kumpulan penilai keputusan per pemain: `CDribblePool::DoDecision` dengan skor kandidat (`GetShootScore(CPlayer*)`, `GetLongShootScore`, `GetLongPassScore`, `GetBallOwnerScore`, `CheckShootAngle`, `IsPlayerOffside`, blokir, dsb.) + status pemain `CPlayerState_*`/`CPlayerCmd_*` (pola perintah — juga yang membuat rekaman pertandingan bisa berupa aliran perintah dan diputar ulang persis, termasuk untuk playback).
- Kesulitan bekerja dengan **mengskala basis data pemain**: `CTeam::ApplyGameDifficultyToPlayerDataBase(_PlayerDataBase*)` `0x4289d8` — database atribut pemain (`_PlayerDataBase`, dimuat dari `PlayerDB2022_*.dat`) diubah menurut tingkat kesulitan sebelum/di awal pertandingan. String debug tertinggal: "Shoot score : %d", "Shoot Angle Add:%d, Speed Add:%d", "TheorySpeed:%d" — sisa log pengembangan di build rilis.
- Kamera/arahan sentuh, gamepad, dan sensor gravitasi (kemiringan) semua ditangani native (`CGamePlay::CheckTouchControl_Attack/Defence`, JNI gamepad di §2.2).

## 7. Proteksi

### PairIP — TIDAK ADA (standar bukti base-APK, sesuai koreksi Onet/Super Kick Off)

- Kelas `com.pairip.*` di dex: **0** (string "pairip" di ketiga dex: 0 kemunculan dari ±15,6 MB dex).
- Application di manifest: `androidx.multidex.MultiDexApplication` — bukan Application PairIP maupun kustom.
- `libpairipcore.so`: tidak ada — satu-satunya .so di seluruh bundle adalah `libHQRenderLib.so`.
- Metadata/stub VM PairIP: tidak ada; kode game Java utuh terbaca (11 berkas, nama asli).
- `libpglarmor.so` memang muncul sebagai komponen SDK iklan Pangle di dex mediasi — sesuai pelajaran sebelumnya, itu **bukan** bukti PairIP dan tidak dipakai sebagai bukti apa pun di sini.

### Proteksi lain (kode game saja, dipisah dari derau SDK)

- **Cek tanda tangan di native:** fungsi ekspor `_Z18GetSigningHashCodeP7_JNIEnvP8_jobject` (`GetSigningHashCode`, VA `0x2685e8`) — native bisa membaca hash tanda tangan APK dari Java dan membandingkannya secara internal. Seberapa ketat gerbangnya (peringatan vs penolakan fitur) tidak bisa dipastikan tanpa disassembly — dicatat sebagai *ada mekanisme*, bukan *terbukti memblokir*.
- **Anti-debug:** `IsDebuggerConnected(JNIEnv, jobject)` VA `0x2689cc` + string JNI `isDebuggerConnected`.
- **Root/Frida/Xposed/Magisk/emulator di kode game: tidak ditemukan** — 0 string relevan di native; di dex, satu-satunya "hit" adalah regex daftar sufiks publik Mozilla (kata "exposed" di dalamnya) alias derau SDK, bukan kode deteksi.
- UDID anti-tamper tidak ada; identitas MP hanya hash UDID + nickname (§3.2).

## 8. Vonis cheat per fitur (server vs lokal dulu)

| Fitur | Kelas | Vonis & alamat |
|---|---|---|
| Unlock liga/piala (ID 1–6), tim (7–132), TV channel (133–140), unlock-all | **Lokal secara teknis** (verifikasi RSA lokal §4.2, hak disimpan native lokal) — **TAPI gerbang pembayaran IAP nyata** | **DITOLAK untuk dibuka.** Penegakan lokal tidak mengubah sifatnya: ini konten berbayar (konsisten dengan vonis premium Catur Jetstart). Alamat dicatat hanya sebagai bukti kelasnya: gerbang hasil bayar JNI `onPayOrderDirectPurchaseFinished` → `CGameMenu_Shop::OnPurchaseFinished(int)` `0x38e364`. |
| Progres karier/liga/piala, jadwal, klasemen, rekor (mode CL) | **Lokal penuh** (serialisasi native di perangkat) | Layak untuk build nanti: titik simpan/muat `CCupAndLeague::Save` `0x3d3b80` / `Load` `0x3d3a7c`, `SaveCupLeague` `0x3d03c4` / `LoadCupLeague` `0x3cfc0c`. Jalur paling bersih = edit berkas simpanan (root) atau hook titik Save/Load ini. Khusus mode offline/CL. |
| Tingkat kesulitan / kekuatan AI | **Lokal** | Layak (offline): `CTeam::ApplyGameDifficultyToPlayerDataBase(_PlayerDataBase*)` `0x4289d8` — satu-satunya pintu skala stat menurut kesulitan. |
| Atribut pemain (PlayerDB2022) | **Lokal** (berkas data di .pak) | Layak (offline): data `Res\Data\PlayerDB2022_En.dat` di `res_all.pak`; jalur injector = sela saat DB dimuat/di-skala (alamat di atas), bukan membongkar .pak. |
| Rekaman pertandingan lokal (simpan/putar ulang) | **Lokal** | Layak: `CGamePlay::SaveReplayData(int,bool)` `0x341104`. (Mengunggahnya ke server = fitur berbayar §4, tidak disentuh.) |
| Mode MP: ruang, pertandingan vs manusia, leaderboard MP, pesan, playback server | **Server** (`wslogin.touchtao.com`, §3.2) + lawan manusia asli | **DITOLAK TOTAL.** Termasuk melaporkan hasil palsu — `SendFinishGamePackage(int)` `0x3c9944` memang laporan klien, tapi itu papan & pertandingan publik antar-pemain. Fitur lokal apa pun wajib mati di mode MP (pola kill-switch yang biasa dipakai). |
| Leaderboard Play Games (total gol & total pertandingan) | Nilai **dihitung lokal**, papan **publik antar-pemain** di Google | **Tidak disentuh.** Paparan memang ada secara desain (native mengisi `setLeaderBoardData`, Java `submitScore` ke `LEADERBOARD_GOAL_SCORE`/`LEADERBOARD_MATCH_SCORE`) — menggelembungkan angka lokal akan mengalir ke papan publik; di luar batas. Achievement Play Games sama: dibuka dari progres lokal, tapi memalsukannya = memalsukan catatan publik Google. |
| Firebase/iklan | Bukan ekonomi game | Tidak relevan sebagai cheat; tidak disentuh. |

Catatan kesulitan umum: karena logika di C++, **tidak ada hook Java untuk fitur game** — semua target lokal berupa offset fungsi native di build ini (VA dynsym `libHQRenderLib.so` BuildID `1d5d0525…`; offset berubah bila versi game berubah).

## 9. Jalur mod yang direkomendasikan (bila user memesan nanti)

1. **Editor simpanan karier via root** — paling bersih untuk progres CL: baca/tulis data serialisasi `CCupAndLeague` di direktori privat aplikasi. Tanpa menyentuh APK, tanpa risiko tanda tangan. Perlu satu sesi pemetaan format `_ConfigData` dari berkas nyata di perangkat user.
2. **Root injector (pola Diamond/Catur, Pine)** bila butuh perilaku runtime (mis. skala kesulitan): hook offset native di atas pada proses game. Kerja C++ = lebih berat dari mod Java kemarin; alamat per-build.
3. **Repack: TIDAK dianjurkan.** Tanda tangan baru akan: (a) memutus masuk Play Games (App ID terikat sertifikat Play asli `3257d599…`), (b) membuat Billing tidak bermakna (lisensi terikat aplikasi Play Console; bundle ini sendiri sudah hasil re-sign pihak ketiga — §1), (c) berpotensi memicu cek `GetSigningHashCode` native. Ditambah .pak & kode native membuat patch smali tidak menolong apa-apa.

## 10. Batas analisis

- Tanpa Ghidra/IDA di VM: isi fungsi native tidak dibaca sebagai pseudocode; vonis bertumpu pada peta simbol dinamis yang lengkap (9.255 simbol), string, dan kode Java yang utuh. Nama berkas simpanan persis dan ketatnya gerbang `GetSigningHashCode` adalah dua hal yang hanya bisa dipastikan lewat disassembly mendalam atau uji runtime.
- Status hidup server MP (`wslogin.touchtao.com`) tidak diuji — bedah ini statis, sesuai perintah (analisis saja).
- jadx selesai dengan 37 error dari 7.370 kelas (semuanya di wilayah SDK); 11 berkas game terbaca utuh.
