# REA + Dump — Traffic Rider (SK Games)

**Status: ANALISIS SAJA. Tidak ada mod/menu/injector yang dibangun, dan file game tidak diunggah/disebarkan ke mana pun.**
Tanggal analisis: 2 November 2026 (WIB). Target: mode solo/offline saja.

## 1. Identitas file

| Item | Nilai |
|---|---|
| Sumber | `[tautan unduhan dihapus — minta ke Alyaa]` (URL persis dari user) |
| File unduhan | `trafficrider.xapk` — 179.017.096 byte |
| SHA-256 XAPK | `6daa9edb2cd2d99a1993e60440214401be8ac8c7380e591d20af5e5b4fc009c9` |
| Tipe | Zip archive (XAPK v2, tanpa OBB) |
| Isi XAPK | `com.skgames.trafficrider.apk` (base, 150.259.930 byte), `config.arm64_v8a.apk` (split, 28.673.317 byte), `icon.png`, `manifest.json` |
| Package | `com.skgames.trafficrider` |
| versionName / versionCode | `2.11` / `902` (terverifikasi aapt2 badging + manifest.json) |
| ABI | `arm64-v8a` saja (native lib hanya ada di split `config.arm64_v8a`) |
| minSdk / targetSdk | 24 / 36 |
| Activity utama | `com.unity3d.player.UnityPlayerActivity` |
| SHA-256 base APK | `430d2181cc43e355a3566396b5e1900e67317a773cb3bab4725a4d1a71ab8dfb` |
| SHA-256 split APK | `f5a2377f991bd08b8978d377a80468581689d12fc8d4f96ead6a63a1ae8cf1b2` |

Izin penting di manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, `BILLING` (IAP), `AD_ID`, `VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `CHECK_LICENSE`.

## 2. Engine & struktur

- **Unity 6 (metadata version 31)** + **IL2CPP penuh**. Bukti:
  - `lib/arm64-v8a/libunity.so` (21.090.056 byte, SHA-256 `981fbee9dd8b245909b2c75d0e14f5a84371e0c9e7c24ecbe8830631a8737469`)
  - `lib/arm64-v8a/libil2cpp.so` (60.940.296 byte, SHA-256 `a1e1dc90c65646a4f76d49e209945a50185cb2bad9a9a2077e96522ab17ff80e`)
  - `lib/arm64-v8a/libmain.so`, FMOD (`libfmod.so`, `libfmodstudio.so`), Resonance Audio
  - `assets/bin/Data/Managed/Metadata/global-metadata.dat` (9.904.308 byte, SHA-256 `fa6c97e797440c97a1d46201c00163e1fcbb718c30b8846771fee29f040e6e6e`, signature `0xFAB11BAF`, version 31)
  - Folder `Managed/` hanya berisi `Metadata/` + `Resources/` — **tidak ada DLL Mono** (murni IL2CPP).
  - Assembly game: `Assembly-CSharp.dll` (dump: Image 5). Assembly lain yang relevan: `Google.Play.Games.dll`, `Firebase.*.dll`, `GoogleMobileAds*.dll` (AdMob + mediasi AppLovin/UnityAds/Liftoff).
- **Dump IL2CPP berhasil penuh** (Il2CppDumper lokal + .NET 8 dengan `DOTNET_ROLL_FORWARD=LatestMajor`; error akhir hanya "Press any key" karena stdin diarahkan — file dump lengkap):
  - `dump/dump.cs` (23.581.644 byte, 4.734 class, 69.820 method ter-parse)
  - `dump/script.json` (65.612.470 byte), `dump/il2cpp.h`, `dump/stringliteral.json` (15.381 string), `dump/DummyDll/`
  - File kerja: `methods.json` (daftar class/method + RVA/file offset), `xrefs.txt` (call graph hasil scan BL se-lib), `handlespeed.txt`, `speeduse.txt`, `strings_metadata.txt`.
- Konvensi alamat di laporan ini: **RVA** = alamat virtual di dump; **file offset** = RVA − 0x4000 (terverifikasi lewat prolog fungsi yang ter-decode benar dengan Capstone). Hook root-injector (pola Dobby/HCR) memakai alamat runtime = base `libil2cpp.so` + RVA.

## 3. Temuan per fitur (semua solo/offline)

### (a) God mode / tidak mati saat tabrakan — TERBUKTI BISA (lokal)

- **Satu-satunya pintu crash:** `MotorMover.OnTriggerEnter(Collider)` — RVA `0x1890A50`, file offset `0x188CA50`.
  - Disassembly membuktikan alurnya: resolve komponen dari collider lawan → cek byte flag di offset `0x81` komponen itu → bila set, **tail-jump ke `Crash()`** (`b #0x188f714` di `0x1890B60`); bila clear, masuk jalur lambat (`HitTrafficSlowly`, lihat bawah).
  - `MotorMover` **tidak punya** `OnCollisionEnter` sama sekali — tabrakan game ini 100% trigger-based, bukan physics collision.
- **`MotorMover.Crash()`** — RVA `0x188F714`, file offset `0x188B714` (48 instruksi s.d. early-return; badan lanjut memanggil `HandleGameOver` di `0x188F7F4`, terbukti lewat scan BL).
  - Mengeset flag crash (`isCrashed`, field `0x1E1` di `MotorMover`) dan memanggil rantai game over.
- **Rantai game over (terbukti lewat scan BL se-lib):**
  `OnTriggerEnter → Crash() → InGameHUDManager.HandleGameOver()` (RVA `0x186217C`; juga dipanggil `GameManager.FixedUpdate` di `0x1859E68`) `→ ShowGameOverScreen → PostScores → leaderboard` (lihat §3c).
- **Tidak ada sistem Damage/Health sama sekali** (grep metadata: `Damage` 0 hit, `Health` 2 hit tak relevan, `Invincible`/`GodMode` 0 hit). Crash bersifat biner: kena trigger = mati. Jadi tidak ada "nyawa" yang perlu di-nol-kan.
- **Jalur mod (root injector):** hook `MotorMover.Crash()` → return langsung (paling bersih), ATAU hook `MotorMover.OnTriggerEnter()` → return langsung (juga mematikan efek slow-hit, lihat §3b). Keduanya lokal murni, tidak menyentuh jaringan/server.

### (b) Tembus mobil & pembatas jalan / noclip — TERBUKTI BISA (lokal, satu pintu)

- Pintu yang sama dengan (a): `MotorMover.OnTriggerEnter()` adalah **satu-satunya** handler tabrakan pemain.
- **Tidak ditemukan class khusus pembatas/divider** (grep class: `Barrier`/`Divider`/`GuardRail`/`Obstacle` = nihil; yang ada hanya `TrafficVehicle`, `TrafficMover`, `RoadGroup`, `TrafficManager`).
- **Gerakan motor bersifat transform-driven, bukan Rigidbody:** field `MotorMover` tidak memuat `Rigidbody`; posisi digerakkan lewat `Transform` (`GetPosX`/`GetPosZ`, `curStrafe` 0xF8, `curSpeed` 0xFC). Collider pemain adalah trigger (tidak memblokir secara fisika). Artinya: mematikan `OnTriggerEnter`/`Crash()` sudah = tembus semua objek trigger — mobil maupun objek trigger lain di jalan.
- **Jalur lambat yang ikut mati bila OnTriggerEnter di-hook total:** bila flag `0x81` clear, `OnTriggerEnter` lanjut ke `HitTrafficSlowly(TrafficMover, speedDecrease)` (RVA `0x1890C8C`) dengan penurunan kecepatan **4.0 atau 13.0** (konstanta `fmov` di `0x1890C34`/`0x1890C68`), dan `TrafficMover.Deactivate()` (RVA `0x189EDB0`) saat kendaraan terlewati. Ini adalah mekanisme "serempetan pelan" + despawn kendaraan yang terlewati. Hook total `OnTriggerEnter` mematikan ketiganya sekaligus — sesuai permintaan "tembus", tapi perlu dicatat: efek close-call/overtake yang dihitung dari proximity (bukan trigger) tetap jalan karena `TrafficMover.hasGivenOvertakeScore` (field `0x38`) dan `GameManager.CloseCall()` (RVA `0x1859F80) terpisah.
- **Jalur mod (root injector):** sama dengan (a) — hook `OnTriggerEnter` return-awal = noclip penuh; hook `Crash()` saja = tidak mati tapi serempetan pelan masih memperlambat (pilih sesuai selera; rekomendasi awal: hook `Crash()` untuk god mode, dan `OnTriggerEnter` untuk noclip penuh).

### (c) Pengali score — TERBUKTI BISA secara lokal, TAPI BERISIKO LEADERBOARD (butuh keputusan parent)

- **Sumber score lokal:**
  - `GameManager.score` — field float offset `0x3C`; `scoreBase` int `0x40`; `combo` `0x48`; `overtakeCount` `0x50`; `distanceInMeters` `0x44`; `scoreBoostState` `0x68` (enum `ScoreBoostState`: `None=0, One=1, Two=2, Wheelie=3` — game sudah punya state boost skor bawaan).
  - `GameManager.GetScore()` — RVA `0x1859438`, file offset `0x1855438` (getter skor).
  - Akumulasi di `GameManager.FixedUpdate()` (RVA `0x1859470`; memanggil `GetSpeedKmh` di `0x18598A8` — skor dari jarak/kecepatan), `GameManager.CloseCall(bool)` (RVA `0x1859F80 — bonus near-miss/close call), `TrafficMover.hasGivenOvertakeScore` (skor overtake sekali per kendaraan), timer wheelie (`totalWheelieTimer`).
- **Rantai leaderboard TERBUKTI (scan BL se-lib, bukan asumsi):**
  - `InGameHUDManager.ShowGameOverScreen` memanggil `TPGameServicesManager.PostScores()` (satu-satunya caller, di `0x1864C04`).
  - `PostScores()` (RVA `0x1908D0C`) memanggil `GameManager.GetScore()` (di `0x1908DD0`) lalu `PostToLeaderboard()` 2× (di `0x1908F08`, `0x1908F2C`).
  - `GetScore()` juga dipakai HUD (`FixedUpdate` skor live, `ShowGameOverScreen` berkali-kali, `OnSkipMissionClicked`, `PostInGameAchievements`).
  - Bukti integrasi Play Games: `Google.Play.Games.dll` di dump + **42 string ID leaderboard `CgkI_…`** di `stringliteral.json` + class `TPGameServicesManager` lengkap (`PostToLeaderboard`, `PostScores`, `UnlockAchievement`, `ShowLeaderboards`).
- **Verdict:** pengali score **sangat bisa** lewat hook `GetScore()` → return `orig × N` (konsisten untuk tampilan, game over, dan achievement). **TAPI skor yang dikali itu juga yang dikirim ke leaderboard Play Games** setiap game over selesai — selama akun Play Games login. Jadi: aman hanya bila dimainkan **offline / tidak login Play Games**; bila login, skor hasil mod akan ter-posting ke leaderboard publik. **Fitur ini butuh keputusan parent sebelum dibangun** (sesuai instruksi tugas).
- **Bukan server-side murni:** tidak ada server skor SK Games sendiri yang ditemukan (tidak ada endpoint skor di string; network yang ada = Firebase/Ads/Play Games). Risiko spesifiknya adalah leaderboard Google Play, bukan server game.

### (d) Pengali kecepatan kendaraan — TERBUKTI BISA (lokal)

- **Field kecepatan hidup:** `MotorMover.curSpeed` float offset `0xFC` (satuan m/s — `GetSpeedMs` mengembalikannya, `GetSpeedKmh` = ×3.6). `baseSpeed` offset `0x100` (lantai kecepatan saat deselerasi), `braking` `0x110`, `maxAcceleration` `0x108`.
- **`MotorMover.HandleSpeed()`** — RVA `0x188F96C`, file offset `0x188B96C` (84 instruksi; dipanggil `MotorMover.Update` di `0x188ECE8`): menulis `curSpeed` di `0x188FA1C` (rem: `curSpeed − braking × dt`, dijaga ≥ `baseSpeed`) dan `0x188FAA0` (gas: `curSpeed + torque × dt`, dijaga ≥ `baseSpeed`). Tidak ada clamp atas sederhana di sini — top speed muncul dari simulasi mesin (`HandleEngineSimulation` RVA `0x188FCC0`, `CalculateEngineTorque` RVA `0x18910B0`, gear/RPM).
- **Jebakan yang sudah diperiksa:**
  - `MotorMover.maxSpeed` (field `0x104`) **TIDAK PERNAH dibaca** di `Update`/`FixedUpdate` (scan disassembly: 0 hit `#0x104`) — jadi menaikkan field `maxSpeed` saja kemungkinan besar TIDAK menaikkan kecepatan nyata.
  - `MotorMover.GetMaxSpeed()` (RVA `0x189090C`) **tidak punya caller BL sama sekali** — kemungkinan getter mati; hook ini saja lemah.
  - `GetSpeedKmh()` dipakai HUD/kamera/efek/skor (8 caller) — hook ini hanya mengubah tampilan & skor, bukan fisika.
- **Jalur mod (root injector) yang benar:** hook `MotorMover.HandleSpeed()` (atau `Update`) dan, setelah fungsi asli, kalikan field `curSpeed` (`this + 0xFC`) dengan N (dengan batas atas waras di sisi mod, mis. setara ±400 km/jam, untuk menghindari efek kamera/fisika liar — angka batas ini rekomendasi, bukan konstanta game). Alternatif: hook `HandleEngineSimulation`/`CalculateEngineTorque` untuk menaikkan torsi — lebih "fisik" tapi lebih rumit dan memengaruhi akselerasi + RPM, bukan kecepatan puncak semata.

## 4. Anti-cheat & batasan lain (wajib dibaca sebelum membangun)

- **CodeStage Anti-Cheat Toolkit (ACTk) ADA di dalam game** (class di dump): `ObscuredFloat/Int/String/...`, `ObscuredPrefs`, `InjectionDetector`, `ObscuredCheatingDetector`, `SpeedHackDetector`, plus string dokumentasi "detect Cheat Engine's speed hack" dan "detect foreign managed assemblies".
  - `SpeedHackDetector` mengawasi manipulasi `Time.timeScale` — **jangan** memakai trik timeScale untuk kecepatan; jalur `curSpeed` di atas bukan timeScale sehingga tidak masuk pola deteksi itu (tetap perlu uji perangkat).
  - `InjectionDetector` mengawasi assembly managed asing — hook native (Dobby ke `libil2cpp.so`) bukan injeksi assembly managed, jadi di luar pola deteksi itu (tetap perlu uji perangkat).
  - `ObscuredPrefs` mengaburkan data simpanan (relevan untuk mata uang/simpanan, bukan untuk 4 fitur ini).
  - **Belum terbukti** apakah detector-detector ini aktif di scene game (instansiasi runtime) — hanya keberadaan kodenya yang terbukti. Perlu uji perangkat.
- **IAP memakai verifikasi server** (class `ServerSideVerificationOptions` dari Unity IAP) — pembelian dalam game terverifikasi server; bukan bagian dari 4 fitur yang diminta dan tidak dianalisis lebih jauh.
- **Tidak ada tool Ghidra/IDA di VM** — dekompilasi pseudocode tidak tersedia. Bukti di laporan ini berasal dari dump IL2CPP + disassembly Capstone ARM64 pada alamat yang tercantum, bukan dari decompiler. Perilaku runtime (mis. tipe komponen persis di balik flag `0x81` di `OnTriggerEnter`, aktif/tidaknya detector) baru bisa dipastikan lewat uji perangkat.
- **Tidak ada pola/byte-pattern yang dikarang** dalam laporan ini: semua offset di atas berasal dari dump IL2CPP / disassembly. Pola byte untuk patch (bila nanti dipilih jalur patch, bukan hook) harus diekstrak dari disassembly di alamat tersebut saat pembangunan — belum dibuat.

## 5. Ringkasan verdict

| Fitur | Verdict | Target utama (RVA / file offset) | Jalur mod |
|---|---|---|---|
| (a) God mode | ✅ Bisa, lokal | `MotorMover.Crash()` `0x188F714` / `0x188B714` | Hook Crash → return |
| (b) Noclip / tembus mobil & pembatas | ✅ Bisa, lokal | `MotorMover.OnTriggerEnter()` `0x1890A50` / `0x188CA50` | Hook OnTriggerEnter → return |
| (c) Pengali score | ⚠️ Bisa lokal, TAPI terkirim ke leaderboard Play Games saat login | `GameManager.GetScore()` `0x1859438` / `0x1855438` (field `score` `0x3C`) | Hook GetScore → ×N — **tunggu keputusan parent** |
| (d) Pengali kecepatan | ✅ Bisa, lokal | `MotorMover.HandleSpeed()` `0x188F96C` / `0x188B96C`, field `curSpeed` `0xFC` | Hook pasca-HandleSpeed: `curSpeed × N` |

**Rekomendasi pembangunan (bila parent menyetujui):** root injector pola HCR Mod (Dobby hook ke `libil2cpp.so`, bukan patch APK) dengan 3 toggle aman (god mode, noclip, speed multiplier) + 1 toggle score multiplier yang default MATI dan diberi peringatan leaderboard. Uji perangkat wajib: crash tidak terjadi, noclip tidak merusak close-call/overtake, kecepatan tidak merusak kamera, dan detector ACTk tidak bereaksi.
