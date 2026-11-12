# Hasil Dump — Arsip Dump Full + REA

Arsip privat laporan reverse engineering (analisis statis) aplikasi/game Android.
Struktur: `<package>/<version>/<bit>/REPORT.md`.

## Aturan baca

- `bit` = arsitektur artefak yang dianalisis (`arm64-v8a`, `armeabi-v7a`, `universal` bila bundle berisi beberapa ABI atau arsitektur tidak ditegaskan di laporan).
- `universal` juga dipakai untuk laporan non-APK (log, mini-app, modul Zygisk).
- Laporan disensor: tautan unduhan langsung (APKPure/MediaFire/CDN bertanda tangan) dihapus — minta ke Alyaa bila perlu. Tidak ada biner mentah (APK/.so) di repo ini.
- Semua temuan bersifat analisis statis; tanpa Ghidra/IDA di VM, tidak ada dekompilasi native penuh.

## Paket

- `app.monitorworld`
- `app.superkickoff`
- `cc.clashofmagic.s1`
- `com.WandaSoftware.TruckersofEurope3`
- `com.appon.defendthebunker`
- `com.apps.MyXL`
- `com.chess`
- `com.cod4.firstmission`
- `com.dts.freefiremax`
- `com.fingersoft.hcr2`
- `com.forthblue.pool`
- `com.gameloft.android.GAND.GloftTCMF`
- `com.google.android.inputmethod.latin`
- `com.happylabs.happymall2`
- `com.happylabs.hotelstory2`
- `com.herocraft.game.farmfrenzy`
- `com.jetstartgames.chess`
- `com.kipas.studio`
- `com.litapps.selfly`
- `com.mare.sal`
- `com.miniclip.fraggerfree`
- `com.movieph.bj.playvibes`
- `com.neptune.domino`
- `com.prettysimple.criminalcaseandroid`
- `com.prineside.tdi2`
- `com.rockstargames.gtasa`
- `com.rookery.courier`
- `com.skgames.trafficrider`
- `com.tebakgambar`
- `com.temka.dota2mobile`
- `com.touchtao.soccerkinggoogle`
- `com.weatherradar.liveradar.weathermap`
- `diamond.quest.dont.rush`
- `io.github.belmantegu.wonderrecomp`
- `net.froemling.bombsquad`
- `onet.picachu`
- `smellymoo.sand`
- `yio.tro.vodobanka`
- `zygisk-imgui`

Total: 39 paket, 42 folder versi.
