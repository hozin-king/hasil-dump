# Hasil Dump — Arsip Dump Full + REA

Arsip privat laporan reverse engineering (analisis statis) aplikasi/game Android.
Struktur: `<package>/<version>/<bit>/REPORT.md` + `<package>/<version>/<bit>/dump/`.

## Aturan baca

- `bit` = arsitektur artefak yang dianalisis (`arm64-v8a`, `armeabi-v7a`, `universal` bila bundle berisi beberapa ABI atau arsitektur tidak ditegaskan di laporan).
- `universal` juga dipakai untuk laporan non-APK (log, mini-app, modul Zygisk).
- Laporan disensor: tautan unduhan langsung (APKPure/MediaFire/CDN bertanda tangan) dihapus — minta ke Alyaa bila perlu.
- Semua temuan bersifat analisis statis; tanpa Ghidra/IDA di VM, tidak ada dekompilasi native penuh.

## Folder `dump/` — apa isinya

Setiap folder versi punya subfolder `dump/` berisi produk analisis/dump yang
dirujuk `REPORT.md`-nya: file analisis (`.md`/`.txt`/`.json`/`.csv`), dump
IL2CPP (types/methods/fields), daftar strings, header/offset (`.h`/`.hpp`),
skrip dump/analisis (`.py`/`.cs`), manifest, decompile `.zip` (parsial), dan
biner kecil yang jadi subjek analisis (`.so` payload, `.dll` game, modul
`.zip`, `global-metadata` hasil deobfuscate) — semuanya < 95 MB.

## Yang sengaja TIDAK di-upload (dan alasannya)

- **APK / `.apks` / `.xapk` mentah** — paket aplikasi berhak cipta, bukan hasil dump.
- **Pohon ekstrak massal** — tree apktool (`smali/`/`res/`/`assets/`), `jadx`/`jadx_out` lengkap, `extracted/`/`apks_out/`/`xapk/`, `work/` build: puluhan ribu file per paket, mayoritas kode pihak ketiga/SDK.
- **Biner hasil ekstrak yang generik/besar** — `libil2cpp.so` hasil ekstrak (>100 MB), `global-metadata.dat` mentah (yang sudah di-deobfuscate BOLEH dan ada di `dump/`), `.dex` mentah, asset `.bundle`, build cache (`.gch`, `CMakeFiles/`).
- **File tunggal >95 MB** — batas aman di bawah batas 100 MB/file GitHub.
  Praktiknya, API Git Data GitHub menolak blob >~25 MB: 4 file dump besar
  (dua `global-metadata*.dat` 50–57 MB, `script.json` 63 MB, `il2cpp.h`
  61 MB) di-upload sebagai `.gz` (13/14/4/1 MB) + `NOTE-GZIP.txt` di
  foldernya; pulihkan dengan `gunzip`.
- **Kredensial & tautan bertanda tangan** — `cookies.txt`, `download_url.txt`, respons API berisi parameter unduhan, token/API key: disensor atau tidak di-upload sama sekali.
- **Folder kerja mentah** — `downloads/`, `work/`, `apktool_out/`.

Total arsip saat ini: 615 MB file dump (843 file) + laporan. Ukuran ini
disengaja dibatasi: total semua folder `rea-*/` di VM > 20 GB (ratusan ribu
file, mayoritas ekstrak mentah) dan tidak realistis di-push ke satu repo.

## Paket

- `app.monitorworld`
- `app.superkickoff`
- `cc.clashofmagic.s1`
- `com.GacoGames.EC2`
- `com.WandaSoftware.TruckersofEurope3`
- `com.ansangha.drdriving`
- `com.appon.defendthebunker`
- `com.apps.MyXL`
- `com.bytedance.snail`
- `com.chess`
- `com.cod4.firstmission`
- `com.disney.app`
- `com.dts.freefiremax`
- `com.dts.freefireth`
- `com.ea.game.pvzfree_row`
- `com.fingersoft.hcr2`
- `com.fingersoft.hillclimb`
- `com.forthblue.pool`
- `com.fungames.sniper3d`
- `com.gameloft.android.GAND.GloftTCMF`
- `com.google.android.inputmethod.latin`
- `com.happylabs.happymall2`
- `com.happylabs.hotelstory2`
- `com.herocraft.game.farmfrenzy`
- `com.hozinking.gameTTT.TapTapTycoon`
- `com.jetstartgames.chess`
- `com.julian.wildhunter`
- `com.kipas.studio`
- `com.lahelu`
- `com.litapps.selfly`
- `com.live_streaming_tv.online_tv`
- `com.maleo.bussimulatorid`
- `com.mare.sal`
- `com.martinmagni.mekorama`
- `com.meluapp.tekatekisilangpintar`
- `com.miniclip.fraggerfree`
- `com.movieph.bj.playvibes`
- `com.neopawstudio.warunglife`
- `com.neptune.domino`
- `com.prettysimple.criminalcaseandroid`
- `com.prineside.tdi2`
- `com.proximabeta.mf.uamo`
- `com.rockstargames.gtasa`
- `com.rookery.courier`
- `com.skgames.trafficrider`
- `com.tebakgambar`
- `com.temka.dota2mobile`
- `com.thegwchr.fuzzy`
- `com.touchtao.soccerkinggoogle`
- `com.ubisoft.hungrysharkworld`
- `com.weatherradar.liveradar.weathermap`
- `com.youmusic.magictiles`
- `diamond.quest.dont.rush`
- `io.github.belmantegu.wonderrecomp`
- `net.froemling.bombsquad`
- `onet.picachu`
- `smellymoo.sand`
- `yio.tro.vodobanka`
- `zygisk-imgui`

Total: 61 paket, 66 folder versi.

