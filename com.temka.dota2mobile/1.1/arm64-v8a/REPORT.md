# REA — Dota 2 Mobile v1.1 (APKVISION)

Tanggal analisis: 25 Oktober 2026 (WIB).
Metode: analisis statis saja. Tidak ada uji runtime di HP, tidak ada koneksi yang dicoba ke server mana pun, tidak ada IL2CPP dump, dan tidak ada tabel offset. Tidak ada mod yang dibangun dalam tugas ini.

## 1. Identitas file

- Sumber: [tautan unduhan dihapus — minta ke Alyaa]
- Nama file lokal: `Dota-2-Mobile-v1.1-APKVISION.apk`
- Ukuran: 517.741.536 byte (494 MB; sesuai `Content-Length` dari HEAD request)
- SHA-256 file: `16df8b634cb7a3e19fed8660b0cb05c263879bc2a8c921385be51b323d2a0be1`
- `file`: Android package (APK), with gradle app-metadata.properties
- Uji ZIP: `testzip` bersih (tidak ada entri rusak), total 22.490 entri, total ukuran tak terkompresi 1.059.271.511 byte
- Catatan unduhan: unduhan single-stream sangat lambat (sekitar 118 KB/s), sehingga file dirakit dari unduhan paralel multi-range; ukuran akhir terverifikasi persis 517.741.536 byte dan SHA-256 di atas dihitung dari file rakitan tersebut.

## 2. Identitas aplikasi (dari manifest / aapt2)

- Package: `com.temka.dota2mobile`
- Label: `Dota 2 Mobile`
- versionName: `1.1`, versionCode: `2`
- minSdk: 28 (Android 9), targetSdk: 36 (Android 16), compileSdk: 36
- install-location: `preferExternal`
- ABI native: hanya `arm64-v8a`
- Application class: `org.apkvision.dota2mobile.Entry`
- Activity utama (MAIN/LAUNCHER): `org.apkvision.dota2mobile.LauncherActivity`
- Activity game (Unity, `android.app.lib_name` = `game`): `org.apkvision.dota2mobile.GameActivity`
- Provider: hanya `androidx.startup.InitializationProvider` (tidak diekspor). Tidak ada service/receiver yang diekspor di manifest.
- Permission (hanya ini):
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_WIFI_STATE`
  - `android.permission.WAKE_LOCK`
  - `com.temka.dota2mobile.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (permission internal aplikasi sendiri)
- Fitur: GLES 0x30000, Vulkan tidak wajib, layar landscape, touchscreen/multitouch tidak wajib.

## 3. Signer — bukti utama bukan resmi Valve

- Hasil `apksigner verify --print-certs` (lolos verifikasi tanda tangan, tetapi penandatangannya sendiri yang bermasalah dari sisi asal-usul):
  - Signer #1 DN: `CN=APKVISION.ORG, OU=APKVISION.ORG, O=APKVISION.ORG, L=APKVISION.ORG, ST=APKVISION.ORG, C=APKVISION.ORG`
  - SHA-256 sertifikat: `a54b28d5675941c1d39d6937b4f8e4c69966dede417aca2785bd8dc840c8d1d8`
  - SHA-1 sertifikat: `496900e8e6f947ad542a5f5f0434cb7aa01029ac`
  - Masa berlaku sertifikat: 16 Juli 2024 s.d. 17 November 3023 (masa berlaku ~1000 tahun, pola sertifikat self-signed pihak ketiga, bukan sertifikat rilis publisher besar)
- Package bukan milik Valve (`com.temka.dota2mobile`, bukan namespace Valve), class aplikasi/launcher memakai namespace `org.apkvision.dota2mobile`, dan satu-satunya domain HTTPS di DEX adalah `https://apkvision.org`.
- Di DEX tidak ditemukan string `steam`, `Valve`, `valve`, `BillingClient`, `purchase`, `billing`, `playfab`, `googleapis`, atau `play.google`.
- Kesimpulan: **BUKAN game resmi Valve.** Ini adalah build komunitas/pihak ketiga yang memakai nama, hero, item, lore, dan peta Dota 2, didistribusikan ulang dan ditandatangani ulang oleh APKVISION. Klaim apa pun bahwa ini "Dota 2 Mobile resmi dari Valve" tidak didukung bukti di dalam APK ini.
- Konteks publik yang sejalan (bukan bukti dari APK): pencarian web menemukan artikel yang menyebut proyek komunitas "DroidDeck" sebagai bukan rilis resmi Valve, hanya bisa main lawan bot saat ini, dan mengarahkan unduhan ke APKVision.org untuk "Dota 2". Artikel itu bukan sumber resmi Valve, jadi di sini hanya dicatat sebagai konteks, bukan sebagai penentu vonis — penentu vonis tetap package/signer di atas.

## 4. Arsitektur / engine

- Unity 6000.2.14f1, IL2CPP, Release, `StripEngineCode: 1` (dari `META-INF/com.android.games.engine.build_fingerprint`: `6000.2.14f1;IL2CPP;Release;StripEngineCode:1`).
- Gradle plugin: 8.10.0 (dari `META-INF/com/android/build/gradle/app-metadata.properties`).
- Native (hanya `lib/arm64-v8a/`):
  - `libil2cpp.so` — 88.653.648 byte
  - `libunity.so` — 21.490.128 byte
  - `libc++_shared.so` — 1.292.904 byte
  - `lib_burst_generated.so` — 379.192 byte
  - `libgame.so` — 144.104 byte
  - `libmain.so` — 6.696 byte
- DEX: `classes.dex` 6.443.384 byte, `classes2.dex` 47.592 byte, `classes3.dex` 19.388 byte. DEX ini praktis hanya launcher/wrapper AndroidX + Unity player; logika game ada di IL2CPP, bukan di DEX.
- Assembly game (dari `assets/bin/Data/ScriptingAssemblies.json`, bukan dari dump):
  - `Dota.App.dll`, `Dota.Client.dll`, `Dota.Data.dll`, `Dota.Gameplay.dll`
  - `LiteNetLib.dll` (jaringan UDP), `Unity.DedicatedServer.MultiplayerRoles.dll`, `UnityEngine.MultiplayerModule.dll`
  - URP (Universal Render Pipeline), Input System, TextMeshPro, DOTween, glTFast, Newtonsoft.Json
  - Tidak ada assembly Photon, Mirror (networking), PlayFab, atau Steamworks di daftar ini.
- Data game lokal (`assets/GameData/`, 27 file):
  - `heroes.json` (130 kunci termasuk `Version` dan hero dasar), `units.json` (340 kunci), `items.json` (545 kunci)
  - `bot_roles.json` (127 hero), `bot_builds.json` (39 hero), `bot_loadouts.json`
  - `creep_pull_timings.json`, `neutral_camp_boxes.json`, `neutral_items.json`, `building_attachments.json`
  - `map_dota.json` (kunci `map` + `entities`), `map_hero_demo_main.json`, `Maps/hero_demo_main/map_zones.json`
  - Lokalisasi hanya Inggris + Rusia: `dota_english.json`, `dota_russian.json`, `abilities_english.json`, `abilities_russian.json`, `items_english.json`, `items_russian.json`, `hero_lore_english.json`, `hero_lore_russian.json`, `hero_demo_english.json`, `hero_demo_russian.json`
  - Artinya: peta, hero, item, dan perilaku bot semuanya sudah dibundel di dalam APK, bukan diunduh dari server saat main.
- Scene Unity: `level0`, `level1` (besar, puluhan split 1 MB), `level2`, `globalgamemanagers` + `sharedassets0/1/2`. Ini konsisten dengan satu game MOBA lengkap di perangkat, bukan sekadar launcher/streaming.
- Jejak APKVISION (repack/patch, bukan sekadar mirror file mentah):
  - `assets/apkvision/language.json` (schema 1) berisi hash `metadata_sha256`, `overlay_sha256`, `unity_guid_sha256`, `source_metadata_sha256`, dan `changed_literal_indices` sebanyak 1.035 indeks — pola patch string literal (paling masuk akal: overlay terjemahan).
  - `assets/apkvision/en-assets.apk` (3.876.448 byte) isinya hanya satu file: `assets/bin/Data/Managed/Metadata/global-metadata.dat` (14.218.641 byte) — yaitu metadata pengganti, bukan aplikasi terpisah.
  - Konsekuensi jujur: dari statis saja tidak bisa dibuktikan bahwa patch APKVISION *hanya* mengubah terjemahan. File ini sudah dimodifikasi dari build aslinya (siapa pun "temka" sebagai author awal), dan tidak ada hash pembanding dari author asli yang bisa diverifikasi di sini.

## 5. Permukaan online vs lokal

### Yang terbukti lokal

- Seluruh data pertandingan (hero, item, unit, peta, bot) ada di APK (lihat §4).
- Preferensi lokal di string metadata: `dota.last.hero`, `dota.last.items`, `dota.last.kd`, `dota.last.duration`, `dota.last.win`, `dota.last.difficulty`, `dota.last.team`, `dota.loadout.set.*`, `dota.account.name`, `dota.account.avatar`, `dota.play.difficulty`, `dota.play.team`, `dota.menu.mode`, plus pengaturan UI `dota.ui.zoom`, `dota.ui.camera`, `dota.ui.joystick`, `dota.ui.quality`, `dota.ui.resolution`, `dota.ui.fps`, `dota.ui.perf`.
- Mode bot didukung data: `bot_roles.json`, `bot_builds.json`, `bot_loadouts.json`, `creep_pull_timings.json`, dan peta demo hero (`hero_demo`).
- Tidak ada IAP: tidak ada string billing/purchase/BillingClient di DEX, tidak ada permission billing, tidak ada SDK toko di DEX. Jadi tidak ada "diamond/toko" server-side yang bisa di-bypass — jangan mengarang ekonomi premium untuk game ini.
- Tidak ada iklan SDK yang terdeteksi di DEX (tidak ada string admob/unityads).

### Yang terbukti ada jalur online (ke server privat, bukan Valve)

- Stack jaringan game: `LiteNetLib.dll` + `Unity.DedicatedServer.MultiplayerRoles.dll` + class `Dota.Gameplay.MatchServer` dan `Dota.Gameplay.ServerBootstrap` (metode `AutoStart`, plus mode `StartInManualMode`/`manualMode`).
- Konstanta jaringan di string metadata: `dota.net.host`, `dota.net.name`, `dota.net.code`, `dota.net.token`, `dota.net.diag`, `dota.net.loop`, dan `dota.online.url`, `dota.online.device`, `dota.online.secret`, `dota.online.session`.
- Satu-satunya host online konkret yang tertulis di metadata (di samping konstanta `dota.online.url`): `https://177-3-221-114.sslip.io` — yaitu nama DNS sslip.io untuk IP 177.3.221.114. Ini bukan domain Valve/Steam, melainkan server komunitas/pribadi.
- String terkait lain yang muncul di metadata: `dotaanticheat`, `dotaserver`, `dotaticketkey`, `dotasecuritylog`, `dotareporturl`, `dotastatus` — mengindikasikan ada mekanisme tiket/sesi dan semacam anti-cheat di sisi game/server, tetapi bentuk pastinya tidak bisa dipastikan dari statis saja.
- Yang TIDAK terbukti: apakah server sslip.io itu masih hidup saat ini, mode apa saja yang wajib online, dan apakah matchmaking publik benar-benar berjalan — semua itu butuh uji runtime, dan tidak ada koneksi percobaan yang dilakukan dalam REA ini. Jadi pernyataan yang aman adalah: **arsitektur hybrid — simulasi pertandingan bisa lokal (host lokal + bot), tetapi ada jalur online ke server privat untuk sesi/match; bukan game 100% offline, dan bukan pula game resmi Valve/Steam.**
- Catatan pembeda dari "Mirror" di DEX: hit `Mirror` di DEX hanya `autoMirrored`/`isAutoMirrored` (drawable Android), bukan library networking Mirror. Hit `UnityEngine.Networking` di `libil2cpp.so` adalah modul Unity lawas, bukan bukti matchmaking publik. `LiteNetLib` di `libil2cpp.so` hanya 1 hit mentah karena nama assembly utamanya tercatat di `ScriptingAssemblies.json`, bukan karena tidak dipakai.

## 6. Vonis per fitur (server vs lokal dulu)

Prinsip yang dipakai sama seperti REA sebelumnya: yang dilawan pemain asli / yang dipegang server = ditolak; yang murni solo/lokal vs bot = layak dipertimbangkan (dengan catatan risiko §7 tetap berlaku).

### LAYAK dipertimbangkan (solo / offline / vs bot, riset runtime dulu sebelum klaim jadi)

- Main lawan bot (mode bot + hero demo): data bot, peta, dan hero sudah lokal; ini permukaan mod yang paling masuk akal.
- Tuning bot lokal: build/loadout/role bot dari JSON lokal (kesulitan, komposisi tim) — selama hanya memengaruhi match bot sendiri.
- Pengaturan visual/kamera lokal: zoom kamera, kualitas, FPS, layout HUD (`dota.ui.*`) — tidak mengubah hasil lawan pemain asli bila dipakai di match bot.
- Latihan hero (hero demo) dan eksplorasi peta lokal: tidak ada lawan manusia yang dirugikan.
- Catatan: "layak dipertimbangkan" bukan berarti "sudah ada mod jadi". Semua ini masih butuh riset runtime di HP untuk menemukan cara kerjanya di IL2CPP; laporan ini sengaja tidak memuat offset apa pun.

### DITOLAK

- Cheat apa pun di match online melawan pemain asli lewat server privat (maphack/vision, auto-last-hit/deny otomatis, auto-cast/aim, speed, atau manipulasi paket LiteNetLib): melawan manusia asli, ditolak — status server "privat/komunitas" tidak mengubahnya.
- Bypass/utak-atik sesi online: memalsukan `dota.online.secret`/`dota.online.session`, `dota.net.token`, `dotaticketkey`, atau mekanisme `dotaanticheat` = bypass autentikasi/anti-cheat, ditolak.
- Mengaku, menjual, atau mendistribusikan ulang APK ini sebagai "Dota 2 Mobile resmi Valve", atau mengunggahnya ke Play Store: bukan resmi (lihat §3) dan memakai IP Valve, ditolak.
- Mengarang/mengklaim ada IAP, diamond, battle pass, atau toko premium yang bisa di-bypass: tidak ditemukan permukaannya di APK ini.
- Menginstal lalu langsung percaya penuh karena "lolos verifikasi tanda tangan": verifikasi apksigner hanya membuktikan file tidak rusak sejak ditandatangani APKVISION — bukan membuktikan file itu aman atau asli dari Valve.

## 7. Risiko instal APK pihak ketiga (jujur, tanpa dilebih-lebihkan)

- Bukan dari Play Store: tidak ada vetting Play Protect/store, tidak ada update resmi yang terjamin, dan tidak ada jalur pengaduan ke Valve.
- Sudah di-repack oleh APKVISION (bukti §4): patch string/metadata terbukti ada; isi patch di luar terjemahan tidak bisa dipastikan dari statis saja.
- Permission-nya sempit (hanya INTERNET, ACCESS_WIFI_STATE, WAKE_LOCK) — itu kabar baik relatif terhadap APK pihak ketiga lain — tetapi permission sempit tidak menghapus risiko kode native Unity/IL2CPP yang besar (88 MB `libil2cpp.so`) yang tidak bisa diaudit penuh dari statis.
- Game ini akan menghubungi (setidaknya berpotensi menghubungi) server privat `https://177-3-221-114.sslip.io` untuk sesi online, plus `https://apkvision.org` dari launcher — akun/sesi apa pun yang dipakai di dalamnya bukan akun Steam dan tidak dilindungi Valve.
- Saran praktis bila tetap mau mencoba: jangan pakai akun/password yang sama dengan akun penting lain, jangan login Steam/akun utama apa pun di dalamnya, dan anggap progres/akun di game ini bisa hilang sewaktu-waktu karena servernya privat.

## 8. Keterbatasan

- Analisis statis saja; tidak ada uji main di HP, tidak ada tangkapan lalu lintas jaringan, dan tidak ada verifikasi apakah server privat masih aktif.
- Tidak dilakukan IL2CPP dump dan tidak dibuat tabel offset, sesuai batas tugas.
- Nama author asli "temka" hanya terbaca dari package `com.temka.dota2mobile`; identitas/orang di baliknya tidak diverifikasi dan tidak diklaim di sini.
- Bila parent/user mau langkah lanjut, yang masuk akal berikutnya adalah uji runtime di HP (mode apa yang bisa dimainkan tanpa login, apakah bot bisa jalan offline penuh, dan apakah mode online benar-benar terhubung) — bukan langsung membangun mod.

## 9. Bukti pendukung di workdir

- `Dota-2-Mobile-v1.1-APKVISION.apk` (file yang dianalisis; tidak dikirim ke user, tidak diunggah ke mana pun)
- `badging.txt` (output aapt2 dump badging)
- `manifest.txt` (output aapt2 dump xmltree AndroidManifest.xml)
- `signer.txt` (output apksigner verify --print-certs)
- `ziplist.txt` (daftar DEX/lib/META-INF/assets pilihan)
- `meta_domains.txt` (domain dari string metadata, hasil grep)
