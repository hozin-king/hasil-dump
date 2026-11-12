# REA — Higgs Domino Island 2.85 (com.neptune.domino)

File: bundle `.apkm` 216.126.237 byte (SHA tidak dihitung di sini; file unduhan asli tidak diubah), berisi `base.apk` (147.215.538 byte) + `split_config.arm64_v8a.apk` + `split_config.armeabi_v7a.apk` + `info.json` (APKMirror, diposting 2026-10-16, varian arm64-v8a + arm-v7a, Android 6.0+). Analisis dari salinan ekstrak (sudah dibersihkan setelah analisis).

## 1. Identitas & keaslian — kemungkinan besar RESMI, dengan satu catatan

- Package: `com.neptune.domino`, label "Higgs Games Island"
- versionName `2.85`, versionCode `2851`, minSdk 23, targetSdk 36, compileSdk 36
- Main activity: `com.pokercity.lobby.lobby` (codebase lobby bersama "PokerCity")
- Signer (apksigner, verified "Verifies"): `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US`, cert SHA-256 `676d2c044fd4c701e8117b8927b36ea0898a8cad464f40532673173018740d63` (v1 cert `META-INF/BNDLTOOL.RSA`, 4096-bit RSA, berlaku 2018–2048)
- **Catatan kejujuran:** DN sertifikat ini GENERIK (bukan atas nama Higgs Games), jadi identitas publisher tidak bisa dikonfirmasi dari sertifikat saja. Yang mendukung keaslian: signature valid + provenance APKMirror (APKMirror memeriksa kecocokan signature dengan versi Play Store sebelum publish) + konsistensi package/versi. Referensi internal menguatkan: string `com.higgs.dominops`, `com.higgs.dominos`, `Higgs Games`, `Higgsdomino` di libgame.so. Kesimpulan: **kemungkinan besar APK resmi, bukan repack/mod** — tapi bukan kepastian setingkat signer bernama publisher (seperti BombSquad/Eric Froemling kemarin).

## 2. Stack teknologi — hybrid Cocos C++ + Unity untuk slot

- **Game utama: Cocos2d-x C++** — `libgame.so` 138,8 MB (arm64) dengan simbol C++ masih ada (namespace `ns_*_hw_game`: domino, qiuqiu, poker, texas, remi, kartu, chess, draughts, ludo, word, dll.). Logika game ada di C++, BUKAN di Lua.
- **Lua hanya framework** — 63 file `.luac` di `assets/luaSrc/luaCocos/` adalah framework quick-cocos2dx saja (Cocos2d, CocoStudio, AudioEngine, dsb.), bukan logika game.
- **Slot: Unity 2022.3.62f3 tertanam** — `assets/bin/Data/` (boot.config, data.unity3d, global-metadata.dat 10 MB = IL2CPP) + bundle `UnityFS` di `assets/SlotBootstrap/` + assembly game `Higgs.Slot.GameScripts.dll`, `Higgs.Fishing.GameScripts.dll`, `Higgs.Common.*.dll`, `HybridCLR.Runtime.dll` (hot-update C#).
- **Java tipis** — satu `classes.dex` 6 MB: lobby, Play Billing, Play Integrity, Facebook Login, Firebase, AppsFlyer, Crashlytics, PAG (`libpag.so`), `libffavc.so`.
- **Mode dari direktori aset:** domino, qiuqiu, poker, texas holdem, remi, kartu41, cangkulan, domino5zp, banyak slot, friend room, guild system, season.

## 3. Ekonomi & mode — model client→server, semua nilai dari server

- **Arsitektur jaringan: client kirim request, server yang memutuskan.** Ratusan simbol `Send*Req` lewat `IWebMsgInterface` (contoh: `SendAddBetReq`, `SendAchTakeAward`, `SendActivityPlayBallResult`).
- **Koin/chip:** diambil dari server — `LogicLayer::SendGetActCoinReq`, event `UpdateCoin`/`UpdateMoney`/`SyncCoinNumFromProvider`; tampilan koin di lobby (`FlyCoinLayer`) hanya animasi dari nilai server.
- **VIP:** server-side — `GetCurVip`, `SendGetVipDayShopInfo`, `SendVipLuckCardProgressReq`.
- **Pembelian:** Google Play Billing (567 kemunculan "billing" di dex, 182 "purchase") + verifikasi server; iklan reward memberi koin lewat server (`SendAddCoinByAdScoreReq`).
- **Login/auth:** Facebook (313), Google, guest, token-based (2.468 "token" di dex).
- **Endpoint:** satu-satunya host plaintext di libgame.so adalah domain TEST `https://itest.dominotest.net/data/handleMsg.do`. Host produksi tidak ada dalam bentuk plaintext — kemungkinan dikirim lewat respons login/remote config. Ini batas analisis statis, bukan bukti tidak ada server.
- **Anti-tamper yang ditemukan:** Play Integrity di dex (128 "integrity") + SDK `com.pokercity.sdk.PlayIntegrityApi` dengan field `isRooted` — token integrity + flag perangkat root ada di lapisan SDK. Tidak ditemukan string deteksi Xposed/Frida/Magisk bernama di libgame.so (0 hit) — tapi itu bukan bukti tidak ada deteksi (bisa di lapisan lain / server).
- **Mode offline/bot: TIDAK ADA.** Hit "offline" semuanya UI status lawan disconnect (`ShowPlayerOffLineState`, `SetPlayerOffline`); "practice" 0 hit; "singleplayer" 3 hit tak terkait. Semua mode = room online yang dijalankan server.

## 4. Temuan khusus: simbol cheat internal (bukan menu mod)

Di libgame.so ada simbol debug/test di layer meja: `StartCheating`, `HandleCheatStatus`, `onTouchCheat`, `m_iCheat`, plus flag `app_cheat_user`. Ini pola hook debug developer/test build, BUKAN menu cheat yang dikirim untuk pemain — dan adanya flag `app_cheat_user` mengindikasikan server menandai akun pengguna cheat. **Jangan dipicu/dicoba di akun utama**: memicu jalur ini = risiko penandaan akun. Kondisi pemicu pastinya tidak diketahui dari analisis statis (perlu runtime, tidak direkomendasikan).

## 5. Tabel verdict — server-vs-local dahulu

| Fitur | Klasifikasi | Verdict | Bukti |
|---|---|---|---|
| Unlimited koin/chip | SERVER | ❌ DITOLAK (bypass ekonomi) | Saldo diambil & disinkron dari server (`SendGetActCoinReq`, `SyncCoinNumFromProvider`); edit lokal tertimpa sinkronisasi |
| VIP gratis | SERVER | ❌ DITOLAK (bypass pembelian) | `GetCurVip` + `SendGetVipDayShopInfo` dari server |
| Kartu bagus / auto-win / atur hasil | SERVER | ❌ DITOLAK (rugikan pemain asli) | Pertandingan dimediasi server; `Deal*` di client hanya animasi dari kartu yang dibagikan server; client hanya kirim aksi (bet, buang kartu) |
| Lihat kartu lawan | SERVER | ❌ DITOLAK (rugikan pemain asli) | Kartu lawan tidak dikirim ke client (server hanya mengirim yang boleh dilihat tiap pemain) |
| Cheat di room teman (private room) | SERVER | ❌ DITOLAK | Room teman tetap dijalankan server; ekonomi & pembagian kartu sama-sama server-side |
| Speed gameplay | SERVER-timed | ➖ TIDAK BERGUNA | Timer giliran & hasil ronde dipegang server; yang bisa dipercepat hanya animasi lokal, risiko desync, tanpa manfaat gameplay |
| Hilangkan iklan | — | ➖ TIDAK BERGUNA | Iklan di sini sumber koin reward via server (`SendAddCoinByAdScoreReq`); tidak ditemukan gerbang bayar "bebas iklan" yang bermakna untuk di-bypass |
| Mod visual murni (tema/skin lokal) | LOCAL | ✅ secara prinsip, nilai rendah | Hanya tampilan, tanpa efek gameplay/ekonomi; tidak ada target spesifik yang ditemukan & direkomendasikan |
| Mode offline / vs bot | — | ❌ TIDAK ADA | Tidak ditemukan mode offline/latihan; praktis 100% online |

## 6. Risiko utama

- **Play Integrity + flag isRooted:** perangkat root / APK resign mudah ditandai; risiko sanksi akun (koin yang dibeli = uang asli, hangus bila akun kena sanksi).
- **Penandaan cheat-user server-side** (`app_cheat_user`) — game ini memang mengawasi perilaku cheat.
- **Resign memutus signature** dan integrity check; tidak ada jalur mod "tanpa resign" yang bermakna karena semua nilai kritis di server (berbeda dengan BombSquad yang simulasinya lokal).
- Update game rutin (2.85 Oktober 2026); hot-update Unity (HybridCLR) + konfigurasi server bisa mengubah perilaku tanpa update APK.

## 7. Rekomendasi langkah berikutnya

**JANGAN bangun mod Higgs Domino.** Tidak ada permukaan mod solo/offline yang layak: semua mode online, semua ekonomi server-side, dan semua cheat gameplay yang umum ditanyakan = merugikan pemain asli atau bypass pembelian. Satu-satunya yang "bisa" (mod visual murni) nilainya rendah dan tetap membawa risiko flag integrity — tidak direkomendasikan. Bila user tetap ingin sesuatu dari game ini, jalur yang sah: main apa adanya, VIP/koin lewat pembelian resmi.

## 8. Batas analisis ini (dinyatakan plain)

- Analisis statis saja: string/symbol-level pada dex + libgame.so + aset + manifest. Tidak ada JADX (dex tidak didekompilasi penuh), tidak ada Ghidra/IDA, tidak ada IL2CPP dumper untuk metadata Unity — logika slot C# tidak dibaca isinya.
- Host produksi tidak berhasil dipulihkan dari plaintext (kemungkinan remote config); model server-side disimpulkan dari pola request/response + sinkronisasi saldo, bukan dari membaca paket jaringan live.
- Tidak ada APK mod yang di-build, tidak ada push, tidak ada instalasi, file unduhan asli tidak diubah.
