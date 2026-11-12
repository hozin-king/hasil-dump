# Analisis Lanjutan — Jalur Iklan & Fisika Tembakan

**Game:** World Football League — `com.touchtao.soccerkinggoogle` v1.9.9.7 (versionCode 62)
**Objek:** `libHQRenderLib.so` (arm64-v8a, 4.996.936 B, BuildID `1d5d05250365ac0b7484c02db750ed89fe8d19be`)
**Metode:** analisis statis saja — jadx (Java) + disassembly `llvm-objdump` (NDK 26.1) per fungsi atas dynsym. Semua alamat di bawah adalah **VA dynsym** berkas ini (= offset berkas untuk segmen terkait); alamat berubah bila versi game berubah. Melengkapi `REPORT.md` (§2, §3.4, §5) — tidak ada build, tidak ada berkas lain yang diubah.
**Konvensi bukti:** "terbukti" = terlihat langsung di instruksi/kode Java; "tafsiran" = kesimpulan dari pola instruksi, diberi label.

---

# TUGAS A — JALUR IKLAN

## A.1 Vonis arsitektur (jawaban inti)

Keputusan **"tampilkan iklan sekarang" diambil native (C++)**, bukan Java. Java hanya **penampil pasif**: ia tidak punya timer, tidak punya logika frekuensi, dan tidak pernah memulai iklan sendiri (satu-satunya pengecualian: preload & pembuatan objek banner saat start, §A.5). Ada **dua jalur yang independen di bawah satu kelas native `CInGameAdv`**:

1. **Banner** — AdMob `AdView` yang ditempel sebagai overlay Android di atas `GLSurfaceView`.
2. **Interstitial fullscreen** — AdMob `InterstitialAd.show()`.

Keduanya **tidak berbagi satu fungsi pemicu**: banner digerakkan `CInGameAdv::DisplayAdv()` / `CInGameAdv::EnableAdv(bool,int)`, interstitial digerakkan `CInGameAdv::PopupFullScreenAdv()`. Yang menyatukan keduanya hanyalah (a) objek global yang sama `g_pInGameAdv` (`0x4CF388`), dan (b) gugus jembatan JNI `nativeAd*` di `0x267168–0x26747C`. Konsekuensi untuk vonis hook ada di §A.6.

Seluruh pemanggilan Java dari native berjalan lewat method-ID yang di-cache di struktur env global `g_mEnv` (`0x4CB650`, diakses via GOT `0x4BD7E8`): `CallStaticVoidMethod` / `CallStaticBooleanMethod` ke metode **statis** `com.touchtao.soccerkinggoogle.WinnerSoccer2014`. Nama-nama string JNI di .rodata membenarkan ini: `adDisplayAdv`, `adPopupFullScreen`, `adEnableAdv`, `adCloseAdv`, `adGetWidth`, `adGetHeight`, `adIsReady`, `adv_Preload` (so_strings baris 9874–11616).

## A.2 Jalur banner — rantai persis

```
[native] CGame::EnterState(GAMESTATE) 0x33B844  /  CGame::MainLoop() 0x33C68C   (transisi state)
   └─ CInGameAdv::DisplayAdv()                                   0x413334
        ├─ nativeAdDisplayAdv()  [jembatan JNI]                  0x267168
        │    └─ JNIEnv::CallStaticVoidMethod → WinnerSoccer2014.adDisplayAdv()V   (Java statis)
        │         └─ HQAdView.DisplayAdv() → EnableAdv(true, 0)
        │              └─ AdView.setVisibility(VISIBLE)  ← AdMob banner, unit di bawah
        └─ callback virtual OnDisplay(x, y, w, h) pada g_pInGameAdv (menyimpan geometri +0x38..+0x47, state +0x48 := 2)
[native] CInGameAdv::EnableAdv(bool, int mode)                   0x41350C
   └─ nativeAdEnableAdv(bool, int)                               0x2671F0
        └─ WinnerSoccer2014.adEnableAdv(boolean, int)V → HQAdView.EnableAdv(z, i)
             └─ AdView.setVisibility(VISIBLE/GONE) + gravity (mode 0 → bawah/81, mode≠0 → atas/49; mode 1 selalu GONE, mode 2 mengikuti z)
[native per frame] CHQGameWndSession::MainRenderLoop() 0x349638 / LoadingLoop()
   ├─ CInGameAdv::UpdateAdv(session) 0x4135A4  → nativeAdIsReady() 0x267378 → WinnerSoccer2014.adIsReady()Z → HQAdView.IsReady() (bIsReady dari AdListener.onAdLoaded)
   └─ CInGameAdv::RenderAdv()        0x4135D4  → bila field +0x28==1: DrawBannerBG() 0x412FDC (latar banner digambar native di balik AdView)
```

Fakta pendukung dari disassembly:

- `CInGameAdv` (konstruktor `0x41322C`) mendaftarkan dirinya ke `g_pInGameAdv`, membuat tekstur latar banner, dan mengeset field: `+0x18` = flag tunggu-popup, `+0x19` = isReady, `+0x1C/+0x20` = lebar/tinggi banner terskala, `+0x24` = mode, `+0x28` = banner aktif (dibaca `CGame::IsAdvDisplaying()` `0x33DE58` dan `RenderAdv`), `+0x30` = `time_t` display terakhir, `+0x48` = state display (0 = belum, 1 = display diminta, 2 = OnDisplay diterima).
- `DisplayAdv()` `0x413334`: bila `+0x48 != 0` langsung `ret` (anti dobel); selain itu `+0x48 := 1`, catat `time()` ke `+0x30`, panggil `nativeAdDisplayAdv()`, lalu dispatch virtual `OnDisplay` pada `g_pInGameAdv`. Subkelas game `CGame::CMyInGameAdv` (konstruktor di sekitar `0x33EEB0`) meng-override callback-callback iklan sebagai stub `ret` 4-byte (termasuk callback selesai-popup di `0x33EEC4`) — logika iklan game sepenuhnya berjalan di kelas dasar `CInGameAdv`.
- `EnableAdv(bool,int)` `0x41350C` menyimpan `+0x28 := bool`, `+0x24 := mode`, mengukur ulang ukuran banner dari `nativeAdGetWidth()` `0x267254` / `nativeAdGetHeight()` `0x267334` (→ `WinnerSoccer2014.adGetWidth()I` / `adGetHeight()I` → `HQAdView.GetWidth/GetHeight`, bawaan 480×75), lalu tail-call `nativeAdEnableAdv(bool, mode)`.
- `CloseAdv()` `0x413478`: `+0x28 := 0`, `+0x24 := 0`, `nativeAdEnableAdv(false,0)` + `nativeAdCloseAdv()` `0x2671AC` (→ `WinnerSoccer2014.adCloseAdv()V` → `HQAdView.CloseAdv()`), `+0x48 := 0`.

**SDK akhir yang benar-benar dipanggil kode game: AdMob (Google Mobile Ads) langsung, bukan MAX/AppLovin API.** Bukti Java:

- Banner: `com.touchtao.common.HQAdView` — `new AdView(...)`, `AdSize.BANNER`, unit **`ca-app-pub-6743569825907537/3191004009`** (`ConstantParam.AdvParam.AD_UNIT_GOOGLE_BAR`), dibuat sekali di `WinnerSoccer2014.onAgreeToStart()`.
- Interstitial: `com.google.android.gms.ads.interstitial.InterstitialAd`, unit **`ca-app-pub-6743569825907537/4667737200`** (`AD_UNIT_GOOGLE_INTERSTITIAL`).
- SDK mediasi (AppLovin MAX, Unity, Meta, Pangle, dll.) memang ada di dex sebagai pustaka (lihat `REPORT.md` §2.1), tetapi **tidak ada satu pun panggilan API mediasi di kelas game** — jalur yang dieksekusi kode game murni AdMob. (Mediasi di sisi server AdMob, bila dikonfigurasi penerbit, berada di luar bukti kode ini.)

## A.3 Jalur interstitial — rantai persis + arah `onAdvHasPopup`

```
[native — pemicu, 9 situs panggil, semua di mesin state menu]
   CGamePlay::UpdateMenu()   0x340768 → situs 0x340B20, 0x340F28, 0x340FF4, 0x341054
   CGameSelect::UpdateMenu() 0x3452A8 → situs 0x345790, 0x345EC0, 0x345FB0, 0x34623C
   CGetPlaybackOperation::OnSuccess(...) 0x3A186C → situs 0x3A1894
   └─ CInGameAdv::PopupFullScreenAdv()                           0x413610
        gerbang: byte [CHQMainGameWnd +0x1A5] == 0 → ret (tidak tampil sama sekali)
        selain itu: this->+0x18 := 1  (flag "sedang menunggu popup selesai")
        └─ nativeAdPopupFullScreen(void(*)())  [jembatan JNI]    0x2673B0
             argumen = &CInGameAdv::Callback_OnPopupFinished (0x413658, terbukti dari relokasi GOT 0x4BE6B0)
             bila g_bInAdPopupFullScreen (0x4CB6C8) sudah 1 → langsung lompat ke callback (anti re-entransi)
             selain itu: simpan callback ke g_pOnAdPopupFullScreenFinished (0x4CB6C0), set g_bInAdPopupFullScreen := 1,
             └─ CallStaticVoidMethod → WinnerSoccer2014.adPopupFullScreen()V
                  ├─ mGoogleInterstitialAd != null → InterstitialAd.show() + FullScreenContentCallback;
                  │    onAdDismissed / onAdFailedToShow → OnFullScreenAdvClose()
                  └─ mGoogleInterstitialAd == null → SetNeedCallBack_Adv_HasPopup() + adv_Preload()  (tidak ada iklan, native tetap diberi tahu "selesai")

[Java → native — PEMBERITAHUAN SELESAI, bukan pemicu]
   WinnerSoccer2014.OnFullScreenAdvClose()
   └─ HQGameRenderer.SetNeedCallBack_Adv_HasPopup()  → flag statis mNeedCallBack_Adv_HasPopup = true
   └─ HQGameRenderer.onDrawFrame() (per frame, thread GL): bila flag → HQRenderLib.onAdvHasPopup()
        └─ JNI Java_com_touchtao_common_HQRenderLib_onAdvHasPopup   0x269920
             bila g_bInAdPopupFullScreen == 1: nol-kan flag itu, lalu br ke callback tersimpan (g_pOnAdPopupFullScreenFinished)
             └─ CInGameAdv::Callback_OnPopupFinished()              0x413658
                  g_pInGameAdv->+0x18 := 0; panggil virtual OnPopupFinished() (di CMyInGameAdv: stub ret 0x33EEC4)
```

**Jadi `onAdvHasPopup` berarah Java → native** (`HQRenderLib.onAdvHasPopup()` dideklarasikan `native` di Java, implementasi JNI di `0x269920`). Namanya menipu: artinya bukan "ada popup, tampilkan", melainkan **"popup fullscreen barusan selesai/ditutup"** — ia melepaskan status tunggu native. Polanya identik dengan antrean callback lain di `HQGameRenderer` (`SetNeedCallBack_PayOrderDirect_PurchaseFinished`, `SetNeedCallBack_TextEditFinished`): Java tidak boleh memanggil native dari sembarang thread, jadi hasil asinkron dititipkan sebagai flag statis dan dieksekusi di awal `onDrawFrame()` berikutnya, tepat sebelum `HQRenderLib.onDrawFrame()`.

**Koreksi nama yang menyesatkan:** fungsi bebas `OnAdv_HasPopUp()` di `0x33B25C` **bukan** bagian rantai hidup — isinya satu instruksi `ret` (stub kosong), tidak punya pemanggil, dan tidak dirujuk relokasi mana pun. Callback yang benar-benar dipakai adalah `CInGameAdv::Callback_OnPopupFinished` `0x413658` (bukti relokasi GOT di atas). Hal serupa: lapisan fungsi bebas `adDisplayAdv(cbDisplay, cbPress, cbError)` `0x412F88`, `adCloseAdv()` `0x412FD0`, `adRefreshAdv()` `0x412FD4` (= `ret`), `adEnableAdv(bool,int)` `0x412FD8` adalah lapisan abstraksi platform lama **tanpa pemanggil** di .so ini; jalur hidup langsung `CInGameAdv → nativeAd*`.

Catatan samping: `WinnerSoccer2014.mShowFinalFullScreenAdv` (Java) tidak pernah diset `true` di kode game Java maupun dirujuk dari .so — cabang "tampilkan iklan terakhir lalu `Exit_Internal()`" di `OnFullScreenAdvClose()` **mati di build ini**.

## A.4 Yang BUKAN jalur iklan ini (agar tidak tertukar)

- **`CMobirixMoreGame`** (`0x34E03C`, `LoadAdvInfo` `0x34E090`, `SaveAdvInfo` `0x34EE3C`, `ParseAdvJson` `0x34E8A0`) + berkas `adv.sav`/`mobiadv.sav` + `CMoreGame` (`0x34F988` dst.) + menu `CGameMenu_MobirixMoreGame`/`CGameMenu_MoreGame::RenderAdv` `0x3818D4`: ini **cross-promo "More Games" Mobirix** (daftar game lain dari `http://cross.mobirix.net/...`, diunduh & digambar native sebagai menu). Bukan AdMob, tidak lewat `WinnerSoccer2014.ad*`, dan tidak disentuh vonis §A.6.
- **`CPlayGround::BuildAdv()` `0x40B98C` / `RenderAdv_Type0–3` `0x40C73C–0x40CDC0`** + string `Res\Adv\%s`: papan iklan **di dalam stadion 3D** (tekstur dari `res_all.pak`). `CFootBall::ImpactDetect_Adv()` `0x3F987C` adalah tabrakan bola dengan papan itu. Bukan iklan jaringan.
- **`CGame::OnPressAdv()` `0x33DE50`**: satu instruksi `ret` — penekanan banner oleh pemain tidak melakukan apa-apa di build ini (tidak ada klik-through dari native).

## A.5 Frekuensi & kondisi pemicu (dari kode, bukan tebakan)

**Banner** — digerakkan **transisi state/menu**, bukan timer:

| Kondisi | Bukti |
|---|---|
| Masuk state 1 (`CGameSelect`, menu pilih) | `CGame::EnterState` `0x33B8DC`: `DisplayAdv()` lalu `EnableAdv(false, 0)`, diakhiri tail-call `nativeAdv_Preload()` |
| Masuk state 2 (`CGamePlay`, pertandingan) | `EnterState` `0x33B900`: `DisplayAdv()` lalu `EnableAdv(true, 2)` |
| Perpindahan state yang sama dari `MainLoop` | `CGame::MainLoop` `0x33C95C`, `0x33CA64`, `0x33CADC`, `0x33CB70` — pola identik (logika transisi terduplikasi di dua tempat) |
| Di dalam pertandingan, per jenis menu in-game | `CGamePlay::EnterGameMenu` (±`0x3401C0–0x34024C`): menu 3 → `EnableAdv(true, 2)`; menu 0x0B/0x13/0x26 → `EnableAdv(false, 0)`; menu lain → `EnableAdv(true, 0)` |
| Banner atas saat bermain | `CGamePlay::ShowTopGameAdv()` `0x3402D4`: `EnableAdv(true, mode)` dengan mode = 2 bila `[CGame+0xC0]==3`, selain itu 1 — dipanggil dari alur menu pertandingan |
| Objek banner dibuat & `loadAd()` pertama | Java saja: konstruktor `HQAdView` di `onAgreeToStart()` — **di luar kendali native** (tampil awal disembunyikan via `EnableAdv(false,0)`) |

**Interstitial** — digerakkan **event akhir pertandingan / keluar menu**, bukan interval waktu dan bukan "tiap X menit":

- **Akhir pertandingan** (`CGamePlay::UpdateMenu`): dua blok identik (±`0x340ED8` dan ±`0x340F50`) menjalankan: `CTeamManager::CanEndMatch()` → naikkan byte counter `[objek bersama +0x1A5]` sebesar 1 → `CGame::SaveSetting()` (counter **persisten**) → bila counter sesudah dinaikkan **== 1, lompat ke `EnterGameMenu(0x3D)` tanpa popup**; bila != 1 → `PopupFullScreenAdv()` lalu `StopGameWndSession(10)`. Blok ketiga (`0x340FE4`, jalur `CanEndMatch()` gagal) memanggil `PopupFullScreenAdv()` di `0x340FF4` tanpa menaikkan counter. Situs `0x340B20` berada di cabang event menu `0x3D` (61) dengan syarat gabungan dua flag bukan-nol.
- **Menu pilih** (`CGameSelect::UpdateMenu`): 4 situs di cabang-cabang transisi antar-menu (keluar dari sub-menu/mode tertentu menuju menu lain) — tidak ada penghitung tambahan di sisinya; satu-satunya gerbang adalah gerbang global di bawah.
- **Playback jaringan** (`CGetPlaybackOperation::OnSuccess` `0x3A1894`): popup dipanggil setelah operasi playback MP sukses, sebelum `StopGameWndSession(3)`. Ini konteks mode online; dicatat demi kelengkapan peta, bukan bagian jalur offline.
- **Gerbang global di `PopupFullScreenAdv()` `0x413610`:** byte di `[CHQMainGameWnd +0x1A5]` (pointer didapat via `CGame::GetGame()->[+0x120]`) — **bila 0, fungsi langsung `ret`**. Byte yang sama: (a) dinaikkan +1 pada akhir pertandingan di atas, (b) dibaca sebagai `signed char` dengan ambang **>= 5** oleh `CGameMenu_SelectMode::Initialize()` `0x387A30` dan `CGameMenu_StartGame::Initialize()` `0x38EC64` untuk mengunci tombol mode bila unlock-all (SKU item 0) belum dibeli. Tafsiran yang konsisten dengan ketiga pemakaian: byte ini adalah **penghitung pemakaian/ppertandingan selesai pada salinan gratis** — interstitial praktis **tidak tampil sebelum pertandingan pertama selesai, dan tampil pada transisi akhir-pertandingan/keluar-menu sesudahnya**. Tidak ditemukan konstanta interval lain (tidak ada pembagi/modulo frekuensi di `PopupFullScreenAdv` maupun di situs-situs panggilnya).
- **Preload:** interstitial dimuat (a) sekali di Java saat start (`InterstitialAd.load` di `onAgreeToStart`), (b) dari native lewat `nativeAdv_Preload()` `0x267438` → `WinnerSoccer2014.adv_Preload()V` pada transisi masuk menu pilih & sesudah tiap popup ditutup. Bila belum termuat saat popup diminta, Java langsung memicu callback selesai (iklan dilewati, bukan ditunggu).

## A.6 Vonis keterwujudan — titik hook untuk injector native (Dobby)

**Tidak ada titik native tunggal yang menekan kedua format sekaligus.** Banner dan interstitial berpisah sejak `CInGameAdv`; menyatukannya hanya di Java (`WinnerSoccer2014`/`HQAdView`) yang berada di luar payload .so. Kombinasi minimal yang **terverifikasi bersih** adalah **3 hook, semuanya di kelas `CInGameAdv`**:

| # | Target | VA | Perlakuan | Kenapa bersih |
|---|---|---|---|---|
| 1 | `CInGameAdv::PopupFullScreenAdv()` | `0x413610` | `ret` langsung (no-op di pintu masuk) | Satu-satunya pemanggil `nativeAdPopupFullScreen` (bukti xref: hanya fungsi ini). No-op **di sini** berarti flag tunggu `+0x18` tidak pernah diset dan `g_bInAdPopupFullScreen` tidak pernah naik — tidak ada callback yang ditunggu siapa pun. Situs panggil di menu melanjutkan transisinya pada instruksi berikutnya (terbukti: sesudah `bl PopupFullScreenAdv` kode langsung `EnterGameMenu`/`StopGameWndSession`), jadi game tidak menggantung. |
| 2 | `CInGameAdv::DisplayAdv()` | `0x413334` | `ret` langsung | Satu-satunya pemanggil hidup `nativeAdDisplayAdv` selain lapisan mati `adDisplayAdv`. No-op membuat `+0x48` tetap 0 dan Java tidak pernah menerima perintah tampil banner. |
| 3 | `CInGameAdv::EnableAdv(bool, int)` | `0x41350C` | hook yang **memaksa argumen `bool := false`** lalu memanggil fungsi asli (trampoline) | `EnableAdv(true, …)` adalah jalur independen yang dapat membuat `AdView` visible tanpa `DisplayAdv` (state pertandingan & menu in-game, §A.5). Memaksa `false` — bukan no-op — membuat fungsi asli tetap menulis `+0x28 := 0` & `+0x24`, sehingga `RenderAdv()` tidak menggambar kotak latar banner native dan `IsAdvDisplaying()` konsisten; Java hanya menerima `setVisibility(GONE)`. |

Peringatan jebakan (bukti dari urutan instruksi):

- **Jangan** menekan interstitial di `nativeAdPopupFullScreen` `0x2673B0` sebagai satu-satunya titik: pemanggilnya sudah menyet `+0x18 := 1` **sebelum** memanggil jembatan; bila jembatan di-no-op, flag itu tidak pernah dibersihkan (`Callback_OnPopupFinished` tidak akan pernah jalan) dan `IsNeedWaitForPopupFullScreenFinish()` `0x41367C` (membaca `+0x18`) akan bernilai benar selamanya. Fungsi terakhir ini tidak ditemukan pemanggilnya via PLT di .so ini, jadi risikonya "tidak terbukti menggantung, tapi statusnya kotor" — titik di `0x413610` menghindari seluruh persoalan.
- Alternatif banner di jembatan `nativeAdDisplayAdv` `0x267168` + `nativeAdEnableAdv` `0x2671F0` (keduanya `ret`) memang memblokir Java, tetapi menyisakan state native `+0x28 == 1` dari `CInGameAdv::EnableAdv` sehingga `RenderAdv()` tetap menggambar **kotak latar banner kosong** tiap frame. Karena itu kombinasi 3 hook di atas lebih bersih daripada hook jembatan.
- Hook tambahan opsional: `nativeAdv_Preload()` `0x267438` → `ret`, untuk menghentikan pemuatan interstitial dari sisi native. Ini **tidak** menghentikan (a) `InterstitialAd.load` awal di Java, (b) `MobileAds.initialize`, (c) `loadAd()` banner di konstruktor `HQAdView`. **Batas jujur:** payload .so murni menekan **tampilan** iklan secara tuntas, tetapi SDK AdMob tetap terinisialisasi dan tetap melakukan sebagian lalu-lintas muat di Java. Bila syarat fitur adalah "tanpa lalu-lintas iklan sama sekali", itu tidak dapat dipenuhi dari native saja.

**Keputusan yang diserahkan ke parent:** fitur "hapus iklan" **layak dibangun** sebagai injector native 3-titik di atas (konteks offline penuh; tidak menyentuh jalur MP — situs playback di §A.5 ikut mati karena memakai fungsi yang sama, dan itu memang perilaku yang diinginkan untuk mode apa pun). Tidak ada alasan menahan fitur ini atas dasar "jalur murni Java": keputusan tampil terbukti native.

---

# TUGAS B — FISIKA TEMBAKAN

## B.1 Temuan model yang menentukan segalanya: lintasan bola bersifat PARAMETRIK (tabel frame), bukan integrasi kecepatan

Tidak ada simulasi "velocity + gravitasi per frame" untuk bola yang sedang meluncur. Buktinya rangkap tiga:

1. **Pembangun tabel:** setiap tendangan memanggil keluarga `CFootBall::SetBallOutTo_*` yang **menghitung seluruh lintasan di muka** dan menulisnya sebagai tabel posisi per frame di `CFootBall +0x9C`: entri 12 byte `{x, y, z}` (int), indeks frame di `+0x11B8`, jumlah frame di `+0x11BC` (maksimum **300 frame** — penutup tabel di `SetBallOutTo_Shoot` `0x3F8758`: `[+0x11B8] := 0`, `[+0x11BC] := 300` saat offset tabel mencapai `0xE04` = 299×12).
2. **Pemutar tabel:** `CFootBall::UpdateBallInfo()` `0x3F61DC` per frame hanya **menyalin** entri tabel ke posisi bola: `pos.x := [this + frameIdx*12 + 0x9C]`, `pos.y := [… + 0xA0]`, `pos.z := [… + 0xA4]`; delta per frame disimpan ke `+0x16A8/+0x16AC/+0x16B0`; frameIdx++; bila frameIdx >= `[+0x11BC]`, state bola (`+0x16B8`) dinolkan. Tidak ada penambahan percepatan/gravitasi di sini.
3. **Tidak ada field kecepatan persisten:** di `CFootBall` tidak ditemukan pasangan field velocity/angular-velocity yang dibaca-ditulis antar-frame. Yang ada: posisi saat ini `+0x1684 (x) / +0x1688 (y) / +0x168C (z)`, posisi frame sebelumnya `+0x1690/+0x1694/+0x1698`, delta `+0x16A8…`, dan 10 objek `CBezier3D` (`0x3F5AB0`, `ComputeBezierPoints` `0x3F5B90`) yang menempel di `+0xEE8…+0x11B8` — dipakai keluarga operan/pantulan untuk membentuk tabelnya. Konstruktor `CFootBall::CFootBall()` `0x3F5F1C` me-`memset` wilayah `+0x9C` sepanjang `0x15E8` byte (tabel + area Bezier) hingga tepat `+0x1684`.

**Konsekuensi:** menyuntik "kecepatan/spin" **sesudah** tendangan dieksekusi tidak ada gunanya — yang dapat disuntik hanyalah **parameter pembangun tabel**, pada saat tabel dibangun. Kabar baiknya: pembangunnya tunggal dan sempit (§B.3).

## B.2 Peta fungsi tembakan

| Fungsi | VA | Peran (bukti) |
|---|---|---|
| `CPlayer::DoInputAction_Shoot(_PowerGuage*, bool*)` | `0x405AE4` | Jalur manusia: ambil arah dari `CInput::GetDirectionCache`, nilai power = `(short)[_PowerGuage+0x2]`, panggil `SelectShootPoint` (`0x405B30`) lalu `Shoot` (`0x405B94`) |
| `CPlayer::SelectShootPoint(int, int*, M3DXVector3i*)` | `0x406A08` | Memilih **titik bidik di garis gawang**: menghitung derajat ke 3 kandidat — pusat gawang (x = ±`0x21000`, z = 0) dan dua titik dalam dekat tiang (z = ∓`0x1A00` = 6.656) — lalu memilih berdasar posisi kiper, skill, dan `CRandom` (rentang acak diturunkan dari atribut pemain, ±`0x406CEC`) |
| `CPlayer::CovertShootDirToDest(M3DXVector3i*)` | `0x404880` | Mengubah arah hadap menjadi titik tujuan: normalisasi arah, x tujuan := garis gawang (konstanta `+0x21000` / `−0x1F000`-an sesuai byte arah serang di `_TeamShareStatus +0xE108`, penunjuk tim di `CPlayer+0x1270`), z tujuan := perpotongan garis arah dengan garis gawang itu (`CVectorHelper::CalculateIntersectYByLine`) |
| `CPlayer::Shoot(_PlayerGetBallParam*, int, M3DXVector3i*)` | `0x4050C0` | **Corong semua tembakan terarah.** Membangun struct parameter di stack (`sp+0x10…sp+0x44`), termasuk: dest (dari argumen `M3DXVector3i*`), argumen int ke-2 → parameter tinggi/power, dan **parameter curve yang dihitung di sini** (lihat §B.5), lalu mengaktifkan state pemain lewat vtable state di `CPlayer+0xBF8` |
| `CPlayer::TestActionAvailable(...)` | `0x404938` | Pemanggil kedua `Shoot` (`0x404AD0`) — dispatcher aksi generik (jalur CPU/perintah) |
| `CPlayerCmd_Shoot::OnCommand / UpdateCommand / DoActionOrDoRun` | `0x3DA57C / 0x3DA5CC / 0x3DA6E8` | Lapisan perintah CPU di atas state; bukan eksekutor bola |
| `CPlayerState_Shoot::Start(void*)` | `0x3E5F24` | Menyalin struct parameter `Shoot` ke field state (peta offset di §B.3) |
| `CPlayerState_Shoot::_Update_Shoot()` | `0x3E6130` | **Eksekutor pada keyframe animasi:** cek `CheckCanCollideBall` + pemilik tangkapan bola, hitung `AngleAdd`/`SpeedAdd`, terapkan cabang acak per tipe behavior, lalu panggil `CFootBall::SetBallOutTo(FOOTBALLSTATE=6, …)` di `0x3E651C` (dan varian state 7 untuk subset behavior, `0x3E6330–0x3E635C`) |
| `CPlayerState_Shoot::GetShootAngleAdd()` | `0x3E6A18` | Koreksi sudut kecil (orde satuan, maks ±3 + basis −1/0/+1) dari selisih arah hadap vs arah tujuan & perbandingan skill byte pemain vs lawan |
| `CPlayerState_Shoot::GetShootSpeedAdd()` | `0x3E6B20` | Koreksi kecepatan: konstanta persen dari nilai mentah `(skillByte*12 − 1110) * 0x147B >> 17` dst. — string debug yang tertinggal di .rodata membenarkan pasangan ini: `"Shoot Angle Add:%d,Speed Add:%d"` dan `"0,TheorySpeed:%d"` |
| `CPlayerState_Shoot::SendBallToDest(M3DXVector3i, int)` | `0x3E6BF0` | Pembantu ramping: `SetBallOutTo(state=4, dest.x, dest.z, 0, param, 0, 0)` — jalur pantulan, bukan tembakan utama |
| `CFootBall::SetBallOutTo(FOOTBALLSTATE, int×6)` | `0x3F68BC` | **Dispatcher tunggal.** Menyimpan argumen ke `_OutToParam` di `+0x5C…`, state ke `+0x16B8`, posisi awal ke `+0x1670…`, lalu switch: 1→Dribble, 2/8/11→Pass, 3/9/12→LongPass, 4→Reflect, 5→Reflect_OverHead, **6→Shoot**, 7→LobShoot |
| `CFootBall::SetBallOutTo_Shoot(int,int,int,int,int,int,bool)` | `0x3F82E0` | **Pembangun tabel lintasan tembakan** (dibedah di §B.4). Satu-satunya pemanggilnya adalah dispatcher di atas (`0x3F6BAC`) |
| `CFootBall::SetBallOutTo_LobShoot(int,int,int,int,int)` | `0x3F87A4` | Pembangun tabel lob (state 7) — keluarga terpisah, argumen digeser (dest dibaca dari argumen w3/w4 pemanggil) |
| `CDribblePool::GetShootScore(CPlayer*)` | `0x415FD8` | Skor keputusan CPU (jarak/sudut/skill); memanggil `CheckShootAngle` |
| `CDribblePool::CheckShootAngle(CPlayer*, int*, int*)` | `0x415BC0` | Mengeluarkan pasangan (angleAdd, speedAdd) versi penilai CPU. Pemanggil: `CDribblePool::CheckShoot` `0x414374`, `GetShootScore`, `CGoForBallPool::CheckShoot/DoDirect`, `CPlacementCornerKick/Freekick::DoDecision` — **murni penilai keputusan, bukan eksekutor**; meng-hook-nya tidak mengubah tembakan pemain manusia |
| `CDribblePool::GetLongShootScore(CPlayer*, int, int)` | `0x4166F8` | Skor tembakan jarak jauh untuk keputusan CPU |
| `CFootBall::ImpactDetect_GoalGate(int)` | `0x3F9370` | Deteksi tiang/mistar/jaring dari konstanta geometri (§B.4) — berjalan saat bola meluncur, di luar pembangun tabel |
| `CFootBall::Goal()` | `0x3F9A70` | Penetapan gol sesudah gate terlewati |
| `CFootBall::GetTargetPointFrame()` | `0x3F8D20` | `return [this+0x167C]` — indeks frame saat bola mencapai titik target, ditulis pembangun tabel |
| `CFootBall::GetBallTargetPosition / GetBallStartPosition` | `0x3F8E54 / 0x3F8EA0` | Membaca salinan target (`+0x1670…`) / posisi awal |

## B.3 Rantai eksekusi tembakan & peta struct

```
input manusia ── DoInputAction_Shoot ─┐
CPU/perintah ── TestActionAvailable ──┴→ CPlayer::Shoot(param, powerInt, dest*)
   struct parameter (stack) ──► CPlayerState_Shoot::Start menyalin ke field state:
        state +0x7C  behavior (PLAYER_BEHAVIOR; keluarga tembakan 0x5B–0x65, lob 0x7C/0x7D)
        state +0xA0  dest.x        +0xA4 dest.y        +0xA8 dest.z      (M3DXVector3i, satuan int internal)
        state +0xAC  paramTinggi/power  (dari argumen int ke-2 Shoot = nilai _PowerGuage+0x2 pada jalur manusia)
        state +0xB0  paramCurve         (dihitung di dalam CPlayer::Shoot — §B.5)
        state +0x08  CFootBall*         +0x10 CPlayer* pemilik        +0x30 info aksi pemain (arah di +0x3C, dst.)
   … animasi berjalan; pada keyframe ([state+0x4C] == (short)[state+0x68]) …
CPlayerState_Shoot::_Update_Shoot()
   ├─ GetShootAngleAdd() + 10  ─┐
   ├─ GetShootSpeedAdd()        ├→ CFootBall::SetBallOutTo(6, dest.x, dest.z, [+0xAC], angleAdd, speedAdd, [+0xB0])   @0x3E651C
   └─ cabang acak behavior (§B.5) ┘        dispatcher menggeser argumen 1 posisi:
                                            SetBallOutTo_Shoot(destX, destZ, paramTinggi, angleAdd, speedAdd, paramCurve, false)  @0x3F6BAC
                                                 └→ bangun tabel frame di CFootBall+0x9C (maks 300)
   per frame: UpdateBallInfo menyalin tabel → posisi bola; ImpactDetect_GoalGate/JudgeEnvironmentReflect berjalan di atasnya
```

Offset `CFootBall` yang terverifikasi dari disassembly di atas: tabel frame `+0x9C`; indeks frame `+0x11B8`; jumlah frame `+0x11BC`; `_OutToParam` mentah `+0x5C {destX, destZ, …}`; derajat arah tembakan `+0x88` (ditulis `SetBallOutTo_Shoot` dari `DegreeFromCoordinate` delta tujuan); salinan posisi awal/target `+0x1670…+0x1678`; frame-target `+0x167C`; state bola `+0x16B8`; penghitung pemakaian `+0x16BC`; posisi kini `+0x1684/+0x1688/+0x168C`; pemilik tangkapan `+0x16C8`.

## B.4 Pembangun tabel tembakan — `SetBallOutTo_Shoot` `0x3F82E0` dibedah

Urutan logika (register masuk: `w1=destX, w2=destZ, w3=paramTinggi, w4=angleAdd, w5=speedAdd, w6=paramCurve, w7=bool`):

1. **Titik target efektif di garis gawang:** konstanta sisi `±0x21000` dipilih dari tanda `destX`; bila posisi-x bola saat ini melewati `0x21000`, target-x dihitung cermin dari posisi bola (`w10 = ±0x2F000`-an + `2*posX`). 
2. **Sudut & kecepatan awal:** dari `paramTinggi`+`angleAdd` dihitung besaran awal (akar kuadrat atas kombinasi `paramTinggi*7000 + 420000 + …` via `CVectorHelper::Sqrt`), diuraikan dengan `M3DXCosIdx/M3DXSinIdx` (tabel cos/sin integer, sudut diindeks `DegreeFromCoordinate` atas delta (dest − posisi bola)); `speedAdd` menskala kecepatan sebagai persen (`(speedAdd + 100)` dikalikan dengan konstanta `0x51EB851F >> 37` ≈ /100). Derajat arah disimpan ke `CFootBall+0x88`.
3. **Komponen lengkung (curve) — parameter `w6`:** disimpan apa adanya (`[sp+0x34]`), lalu per fase dihitung kecepatan drift tegak-lurus arah tembak:
   `drift = (0xB54 − speedHorizontal) * |paramCurve| * 0x10624DD3 >> 38`, **hanya bila** `paramCurve != 0` **dan** `speedHorizontal <= 0xB53` (2.899); selain itu drift = 0. Tanda `paramCurve` memilih sisi drift (komponen arah dinormalisasi dinegasikan bersyarat via `cneg` pada `0x3F8538–0x3F853C`, lalu `Vec3FromCoordinateAndLen` ditambahkan ke langkah per frame).
4. **Integrasi tabel per frame:** posisi += langkah arah utama (`Vec3FromCoordinateAndLen` dengan speed horizontal) + langkah drift; ketinggian dikurangi penurun yang membesar (pola gravitasi diskret, penurun awal diturunkan dari komponen vertikal & konstanta `0x44C` = 1.100 pada fase pantulan); saat ketinggian menembus tanah terjadi **fase pantulan**: kecepatan horizontal diskalakan `*25/32` (±`0x3F86F8`), fase `[sp+0x24]` naik 0→1→2, frame saat pertama mencapai target dicatat ke `[CFootBall+0x167C]` beserta salinan posisi target. Bersamaan ditulis **array short sejajar per frame** (kemungkinan rotasi visual bola — tafsiran dari pola nilainya): komponen yang bertambah `+0x44C` per frame dan komponen bertanda `±10.000` (`0x2710`) mengikuti tanda curve, atau `−32.768` (`0x8000` dinegasikan) bila curve = 0.
5. Tabel ditutup pada 300 frame atau saat kondisi target/tanah selesai; `GetFutureFramePos`/`CalculateReachOutToParamFrameIndex` `0x3F8BEC` membaca hasilnya untuk prediksi AI/kiper.

**Geometri gawang (konstanta keras, dari `ImpactDetect_GoalGate`):** garis gawang pada `|x| >= 0x21000` (135.168); tiang pada pusat z ± `0x295A` (10.586); mistar pada ketinggian y ≈ `0x1A5E` (6.750); kedalaman area gawang diperiksa hingga `x` ≈ `0x22F00/0x24500` tergantung sisi. Titik bidik sah `SelectShootPoint` (z ∈ {−6.656, 0, +6.656} pada x = ±135.168) berada **di dalam** mulut itu — konsisten.

## B.5 Sumber keacakan yang harus diketahui sebelum menilai "auto-gol"

1. **`CPlayer::Shoot` `0x4050C0` — asal `paramCurve`:** nilai di `sp+0x44` (→ state `+0xB0`) adalah **0** pada kebanyakan jalur. Ia hanya terisi bila `[CPlayer+0x1340 (tim) +0x11C] == 8` dan objek tertaut `CPlayer+0x1218 != null`; isinya gabungan byte skill pemain (`[obj+0x3]`, diskalakan `(b*4 − 200) * 0x6667 >> 17`), bonus 10 kondisional, koreksi berdasar short di info aksi (`==4 → +10`, `==12 → −(nilai+10)`, pola di `0x4051B8–0x405204`), dan **`CRandom::Random(50000)`** diskalakan `0x68DB8BAD >> 44` (≈ acak 0–5). Hasil tipikal: **orde ±belasan, sering 0**. Untuk tipe tim `== 9` dengan sub-behavior tertentu, argumen power justru **diganti** nilai acak rentang besar (`Random(10000, 20000)` / `(40000, 80000)` / `(10000, 100000)` di `0x405268–0x4052A4`).
2. **`_Update_Shoot` `0x3E6130` — cabang acak per behavior:** untuk behavior dalam himpunan bitmask `(behavior − 0x5D) ∈ [0,40]` kelompok pertama, dilempar `CRandom::Random(1000)`: hasil `> 500` → tembakan dilemahkan/dibelokkan (`angleAdd := −20`, parameter lain dinolkan, tetap state 6 di `0x3E641C–0x3E6470`); hasil `<= 500` → titik tujuan **digeser acak** tegak-lurus (vektor dari posisi bola, panjang `35840 + Random(10)*3584`, di `0x3E63A0–0x3E6418`), `paramTinggi` dijepit <= 40, lalu state 6 dengan parameter penuh **hanya bila** lemparan `>= 501` versi kedua — selain itu parameter dinolkan (tembakan lemah). Kelompok behavior lain menyesuaikan `paramTinggi` dengan pembagian (/2 dijepit ambang 29→15/20/28; /3 untuk `0x5B/0x5C` di `0x3E6474–0x3E64E4`). Subset behavior lain lagi memakai **state 7 (lob)** dengan dest yang sama (`0x3E632C`).
3. **`SelectShootPoint`** sendiri memilih titik bidik dengan komponen acak berbasis skill (§B.2) — titik tujuan yang masuk `Shoot` sejak awal bukan titik deterministik.

Artinya: **ketidakpastian tembakan disuntikkan di tiga lapis SEBELUM `SetBallOutTo_Shoot`.** Titik suntik yang berada di/di bawah lapis terakhir adalah satu-satunya yang kebal terhadap ketiganya.

## B.6 Vonis (a) AUTO-GOL — TERBUKTI ada titik suntik tunggal, dengan batas yang jelas

**Titiknya: pintu masuk `CFootBall::SetBallOutTo_Shoot` di `0x3F82E0`.**

Bukti kecukupan:

- Ia adalah **satu-satunya** pembangun tabel untuk tembakan state 6, dan satu-satunya pemanggilnya adalah dispatcher `SetBallOutTo` (xref penuh: hanya `0x3F6BAC`). Semua tembakan terarah — manusia (`DoInputAction_Shoot → Shoot`), CPU (`TestActionAvailable → Shoot`), perintah (`CPlayerCmd_Shoot`) — bermuara ke `CPlayerState_Shoot::_Update_Shoot` → `SetBallOutTo(6, …)` → fungsi ini. Mengganti argumen **di sini** tidak dapat dibatalkan oleh lapis mana pun di bawahnya, karena sesudah ini hanya ada penyalinan tabel per frame.
- Pada pintu masuk, seluruh penentu lintasan masih berupa **argumen register**: `w1 = destX`, `w2 = destZ`. Menulis ulang keduanya ke titik di dalam mulut gawang lawan — x = `±0x21000` mengikuti tanda `w1` asli (sisi serang sudah benar dari sananya), z = nilai di dalam rentang tiang (aman: rentang bidik bawaan game sendiri, z ∈ [−0x1A00, +0x1A00] relatif pusat; konstanta tiang ±0x295A dan mistar 0x1A5E dari `ImpactDetect_GoalGate`) — membuat tabel yang dibangun **persis lintasan menuju titik itu**, dengan sudut/kecepatan/tinggi dihitung oleh kode asli dari posisi bola saat itu. Arah serang tidak perlu dicari dari field lain: tanda `destX` yang datang sudah menyandikannya (konsisten dengan byte arah di `_TeamShareStatus +0xE108` yang dipakai `CovertShootDirToDest`).
- Alternatif titik yang lebih dini (`CPlayer::Shoot` `0x4050C0` pada argumen dest-nya, atau field state `+0xA0…` di `_Update_Shoot` sebelum `0x3E651C`) **ditolak sebagai titik utama** karena cabang acak §B.5 lapis 2 berjalan sesudahnya dan dapat menggeser/melemahkan tujuan lagi. Titik `0x3F82E0` berada sesudah semua cabang itu.

Batas jujur (kenapa vonisnya "lintasan pasti ke mulut gawang", **bukan** "gol pasti 100%"):

- **Kiper & pemain lain tetap hidup sesudah tabel dibangun:** `UpdateBallInfo` menjalankan `JudgeEnvironmentReflect()` `0x3F6434` tiap frame dan keluarga `CPlayerState_GK_Save` / `CPlayer::CheckCanCollideBallInFuture` (`0x403DD0` dst.) dapat memotong/menangkap bola di tengah lintasan; hook di `0x3F82E0` tidak menonaktifkan itu. Tembakan dari jarak jauh dengan waktu terbang panjang tetap dapat digagalkan kiper secara sah oleh mesin game.
- **Tiang/mistar tetap berlaku:** titik suntik harus di dalam mulut (rentang aman di atas); menyuntik tepat ke tiang akan memantul sesuai `ImpactDetect_GoalGate`.
- **State 7 (lob) tidak tercakup:** subset behavior di `_Update_Shoot` (`0x3E632C`) dan jalur lob lain masuk `SetBallOutTo_LobShoot` `0x3F87A4`, bukan fungsi ini. Cakupan titik tunggal ini = tembakan state 6, yaitu tembakan standar manusia & CPU. Memperluas ke lob = titik kedua, belum dibedah sedalam ini.
- **Mode online (MP) di luar vonis** — sesuai batas `REPORT.md` §8, fitur apa pun wajib mati di mode MP; analisis ini untuk konteks offline.

## B.7 Vonis (b) CURVE EKSTREM — TERBUKTI parameternya ada, satu paket dengan titik yang sama

**Parameternya nyata dan terisolasi: `paramCurve` bertanda (signed int).** Rantai kepemilikannya utuh:

`CPlayer::Shoot` menghitungnya di `sp+0x44` (§B.5.1) → `CPlayerState_Shoot::Start` menyalinnya ke **state `+0xB0`** → `_Update_Shoot` meneruskannya sebagai argumen terakhir `SetBallOutTo(6, …, w7 = [+0xB0])` di `0x3E651C` → dispatcher menggesernya menjadi **argumen `w6`** di pintu `SetBallOutTo_Shoot` → di sana ia menggerakkan drift tegak-lurus per frame (§B.4.3) **dan** tanda komponen rotasi visual per frame (§B.4.4).

Bukti bahwa memperbesarnya memperbesar lengkung, bukan sekadar kosmetik: drift ditambahkan ke **posisi tabel** setiap frame (`Vec3FromCoordinateAndLen` kedua di `0x3F851C–0x3F8560`), dan posisi tabel itulah yang disalin menjadi posisi bola. Besarnya drift per frame sebanding dengan `|paramCurve|` lewat rumus di §B.4.3.

Syarat & batas dari kode (bukan tebakan angka):

- Drift **mati** bila kecepatan horizontal tembakan `> 0xB53` (2.899): curve ekstrem hanya bekerja pada tembakan yang tidak terlalu kencang — kombinasi "power maksimum + curve maksimum" secara internal saling meniadakan di rumus ini. Pada fase pantulan, drift dihitung ulang dengan rumus yang sama (fase `[sp+0x24] == 2`, `0x3F86C8`).
- **Tidak ditemukan penjepit (clamp) atas eksplisit terhadap `|paramCurve|`** di `SetBallOutTo_Shoot`: satu-satunya pembatas adalah gerbang kecepatan di atas dan aritmetika int32 rumus drift itu sendiri. Nilai bawaan game hanya orde ±belasan (§B.5.1) dan sering 0 — jadi "ekstrem" (mis. orde puluhan–ratusan) adalah wilayah **di luar yang pernah dipakai kode asli**: secara statis terbukti mekanismenya menerima & memperkuat, tetapi risiko luapan int32 pada `(0xB54 − speed) * |curve|` dan lintasan yang keluar lapangan/tiang tidak dapat dikesampingkan tanpa uji runtime. Angka aman tidak dijanjikan di sini.
- Titik suntik yang disarankan sama dengan §B.6: **tulis `w6` di pintu `0x3F82E0`** (atau, bila injector lebih suka satu titik data: field state `+0xB0` tepat sebelum panggilan `0x3E651C` — tetapi titik register di `0x3F82E0` mencakup juga jalur mana pun yang kelak memakai state 6).

**Bukti negatif yang diminta tugas:** tidak ada parameter lengkung lain. Pencarian menyeluruh atas dynsym & string tidak menemukan `spin`/`curve`/`angular` sebagai field atau fungsi bola (satu-satunya "Spin" di .so adalah kontrol UI `CUIControl_Spin`); fisika bola tidak mengenal kecepatan sudut persisten — lengkung **hanya** berasal dari `paramCurve` di atas, dan "rotasi" per frame hanyalah array short pendamping tabel. Jadi bila `paramCurve` tidak terbukti, curve ekstrem akan gugur — tetapi ia terbukti, dengan alamat dan rumus di atas.

## B.8 Ringkasan keputusan untuk parent

| Fitur | Vonis | Titik | Syarat/batas |
|---|---|---|---|
| Auto-gol (offline) | **Terbukti layak** — lintasan diarahkan paksa ke mulut gawang | Hook pintu `CFootBall::SetBallOutTo_Shoot` `0x3F82E0`, tulis ulang `w1/w2` (x = ±`0x21000` setanda asli, z dalam ±`0x1A00`) | Bukan jaminan gol: kiper/pantulan/tiang tetap berjalan; state 7 (lob) di luar cakupan; wajib mati di mode MP |
| Curve ekstrem (offline) | **Terbukti mekanismenya** — parameter tunggal bertanda, tanpa clamp atas eksplisit | Di titik yang sama, tulis `w6` (`paramCurve`; asal: state `CPlayerState_Shoot +0xB0`) | Mati bila speed horizontal > `0xB53`; nilai ekstrem berisiko luapan int32 — perlu uji runtime untuk angka; jangan digabung power maksimum |

Keduanya berbagi satu hook fisik yang sama di `0x3F82E0` — satu titik Dobby dapat menyuntik tujuan dan curve sekaligus, dan titik itu berada sesudah seluruh lapis keacakan tembakan (§B.5) serta sebelum satu-satunya penyalinan tabel per frame (§B.1).

---

*Akhir analisis. Semua alamat berlaku untuk `libHQRenderLib.so` BuildID `1d5d05250365ac0b7484c02db750ed89fe8d19be` (v1.9.9.7) dan harus diverifikasi ulang bila berkas berubah.*
