# REA — Truckers of Europe 3 v0.9.52 (code 214)

**Tanggal:** 11 Nov 2026 · **Direktori kerja:** `~/workspace/rea-toe3-v0952/`
**Tujuan:** REA + dump penuh untuk rebuild mod v1.0.9 ke v0.9.52. **Bukan** build mod, **tanpa** analisis runtime, **tanpa** bypass apa pun.
**REA lama (pembanding):** `~/workspace/rea-truckers-of-europe-3/REPORT.md` (v0.7.64, code 193, 7 Nov 2026).

---

## 1. Identitas APK

| Item | Nilai |
|---|---|
| Sumber | MediaFire `.apks` — "Truckers_of_Europe_3_0.9.52.apks", upload 2026-10-31, quickkey `[disensor]` (URL unduh langsung `[disensor]`, token bertanda-tangan — **jangan disebar/dikutip**, kedaluwarsa) |
| Sumber DITOLAK | APKVision = MOD APK ("MOD: Unlimited Money", repack) — tidak dipakai. API publik APKPure hanya punya s/d 0.7.64 (193). APKCombo tidak terjangkau. APKMirror/Uptodown tidak mengindeks 0.9.52. |
| File `.apks` | **797.359.310 B** · SHA-256 `915244a3fecbbf336dd991a887207ec92e99437b699bf71872bc0eb4931aedda` · SHA-1 `6e575bbfc84ad7ae4b905f9de7a70da99f3c9f92` |
| Isi `.apks` | `base.apk` 50.384.386 B · `split_UnityDataAssetPack.apk` 702.642.808 B (4.894 entri, Addressables `aa/catalog.bin`) · `split_config.arm64_v8a.apk` 44.210.054 B |
| Package | `com.WandaSoftware.TruckersofEurope3` |
| Versi | **versionName 0.9.52, versionCode 214** (aapt2) |
| SDK | minSdk **29** (dulu 23), targetSdk **36** (dulu 35), compileSdk 36 |
| Launcher | **`com.wandasoftware.toe3.ToE3PlayerActivity`** (dulu `com.unity3d.player.UnityPlayerActivity`; kelas ada di `classes4.dex`) |
| Signer | apksigner **Verifies**; SHA-256 cert **`5c388af39778ed7a1aebfdf425719adc5f4e2accf82407cc0085f10a8addc23a` = SAMA PERSIS dengan v0.7.64 (Google Play App Signing)** — file **ASLI Play, bukan repack** (base.apk dan split config sama-sama cert ini; source stamp `3257d599…`) |
| Engine | **Unity 6000.3.22f1** (dulu 2022.3.62f3) · `libil2cpp.so` 109.316.760 B, ELF aarch64 stripped, BuildID `180ea8485bbffafe978935c985f9967cbc5d0dc3` (dulu 63.948.512 B, BuildID `e58a580a…`) · `libunity.so` 25.246.768 B · `global-metadata.dat` 15.027.256 B, **metadata version 39** (dulu 31) |

### ⚠️ MASALAH TERBUKA — hash `libil2cpp.so` TIDAK cocok dengan perangkat user

| Sumber | SHA-256 `libil2cpp.so` |
|---|---|
| File ini (dihitung 2 cara: `sha256sum` hasil extract + Python zipfile-streaming persis logika `GameInfo.java` mod — hasilnya sama) | `0053df95b1a6701e5f03d3aa9b802ea7920bd12c34ec36f99245528615f5cab9` |
| Screenshot perangkat user (awalan yang terlihat) | `c9acaca94bcb9e02…` |

**Status: BELUM TERJAWAB.** File MediaFire kedua ("Truckers.of.Europe.3.ver.0.9.52.build.214.apks", 591,16 MB, upload 2026-11-06, quickkey `[disensor]`) **tidak berhasil diunduh**: host `[disensor]` kini mengembalikan halaman Cloudflare "Just a moment…" (6.904 B HTML) lalu HTTP 000 — egress IP ini diblokir host tersebut (host file pertama `download2445` masih jalan). Upaya ulang dengan URL segar dari halaman file gagal dengan cara yang sama.

**Implikasi:** file ini Play-signed dan asli, tapi **bukan biner yang persis sama dengan yang terpasang di HP user** (kemungkinan: build 0.9.52 lain dengan version code sama — mis. revisi staged-rollout/hotfix, atau build dari track berbeda). Semua temuan metadata di laporan ini (nama class/method/field) hampir pasti sama di build user — nama-nama itu bagian dari kode game yang sama — tapi **offset/alamat/pola biner dan hash gate TIDAK BOLEH disalin mentah**. Rebuild WAJIB: (a) resolve semua target **by-name via API IL2CPP** (seperti payload v1.0.9 yang sudah begitu), dan (b) verifikasi ulang hash `libil2cpp.so` dari **biner perangkat user sendiri** (tarik via root) sebelum rilis; gate versi mod harus memakai hash build user, bukan `0053df95…`.

---

## 2. Ringkasan perubahan vs v0.7.64

| Aspek | v0.7.64 (code 193) | v0.9.52 (code 214) |
|---|---|---|
| Unity | 2022.3.62f3, metadata v31 | **6000.3.22f1, metadata v39** |
| Tipe / method / field / properti / event | 13.246 tipe, 141 image, 179 assembly (method/field tidak dicatat) | **17.758 tipe (+34%), 128.122 method, 89.038 field, 21.390 properti, 500 event, 178 image, 178 assembly** |
| Assembly-CSharp | 1.340 tipe | **2.463 tipe (+84%)** |
| minSdk / targetSdk | 23 / 35 | **29 / 36** |
| Launcher activity | `UnityPlayerActivity` | **`ToE3PlayerActivity`** |
| Multiplayer | **TIDAK ADA** (0 string "Multiplayer"; tanpa Photon/PlayFab; satu-satunya endpoint `gs.wandaservices.net`) | **ADA — open beta** (lihat §3) |
| Sistem traffic | `TrafficSpawner` (12 method) + `TrafficCar` (41 method, 132 field), Assembly-CSharp | **Keduanya HILANG** → **`Wanda.TrafficSystem.dll` (baru)**, `TrafficVehicleAI` 331 method / 623 field |
| Iklan/monetisasi | Pangle, Unity Ads | + **Google Mobile Ads mediation** (AppLovin, InMobi, IronSource, Liftoff, Mintegral, Pangle, UnityAds), Firebase Analytics/Crashlytics (lib + assembly baru) |
| Native lib baru | — | `libunitycoherencenative.so` (Unity Coherence, MP), `libapminsighta/b.so`, `libFirebaseCpp*`, `libbuffer_pgl.so`, `libfile_lock_pgl.so` |
| Izin baru | — | `READ_MEDIA_AUDIO`, `FOREGROUND_SERVICE_DATA_SYNC`, `com.amazon.privacypass.ATTEST`, `CHECK_LICENSE`; fitur mikrofon (voice chat); Vulkan wajib |
| `Prefs` | 235 method, 1 field | **368 method (+57%), 18 field, 154 properti** |
| `TruckController` | 33 method, 209 field | **71 method, 247 field** |
| `ZPlayerPrefs` (save terenkripsi) | 21 method, 5 field | 22 method, 7 field — bentuk sama |
| IAP | coins1–4, golds1–4, remove_ads, unlock_trailers | **SAMA, tidak berubah** |
| Endpoint game | `https://gs.wandaservices.net` | **SAMA, satu-satunya endpoint game** (tidak ada `wss://` literal; tidak ada Photon/PlayFab) |
| Anti-cheat / deteksi root | TIDAK ADA | **TETAP TIDAK ADA** (lihat §6) |

---

## 3. MULTIPLAYER — perubahan terbesar (klasifikasi v0.7.64 TIDAK lagi berlaku penuh)

### 3.1 Bukti (metadata strings, 152.215 string)

| Kata kunci | v0.7.64 | v0.9.52 |
|---|---|---|
| Multiplayer | 0 | **477** |
| OtherPlayer | — | **369** |
| Chat | 1 | **283** |
| Autopilot | 0 | **50** |
| Convoy | 0 | **37** |
| VoteKick | 0 | **19** |
| Spectate | 0 | 0 (fitur bernama "Guest"/"spectator" — lihat bawah) |
| Photon / PlayFab / FishNet / Netcode | 1 / 0 / 0 / 0 | 1 / 0 / 0 / 0 |

### 3.2 Stack multiplayer (statik)

- **Assembly baru `Wanda.MultiPlayer.dll` — 645 tipe**, namespace `Wanda.MP`. God-class **`Wanda.MP.MultiPlayer`: 1.359 method, 1.242 field, 82 properti, 2 event.**
- **Assembly baru `UnityEngine.MultiplayerModule.dll`** + native **`libunitycoherencenative.so`** (Unity Coherence — `CoherenceBridge_*` JNI).
- **Transport custom Wanda (bukan Photon/PlayFab):** `MultiPlayerTcpLink`, `MultiPlayerNativeTlsStream` (26 method — TLS native), `TcpConnectProbe`, `ClientTlsMemory`, `ClientDirectPlan`/`ClientDirectMemory`, `ClientRoomHttps` (room discovery via HTTPS), `TransportReconnectRoutine`, `NetDropHoldProtocol`. Endpoint server **di-resolve saat runtime via `gs.wandaservices.net`** (tidak ada URL server MP hardcode di biner/literal).
- **Room/session:** `MultiPlayerRoom*` (Connect, Welcome, RuleOptions, RoomPin, RoomBonus, RoomAudio…), `MultiPlayerSessionInfoText`, `SessionFindGoneClock`, `NewRoom` ("oda kodla bulundu → katılma ekranı" = room ditemukan via kode).
- **Pemain lain:** `OtherPlayer*` (Slot, Data, ComponentAction, GameObjectAction), `OtherTruckFlow`/`OtherTrailerFlow`/`OtherVehicleFlow`, `TruckController.get_IsRemoteVehicle` (M[15598], BARU), `MultiPlayerSelfIdentity` (`IsSelfAliasOfOther`, `ShouldApplyServerId`).
- **Traffic di MP:** `MultiPlayerTrafficAuthority`, `MultiPlayerTrafficBudget`/`Governor`, `MultiPlayerTrafficCrashAuthority` + `Policy`, `MultiPlayerTrafficHitReport`, `MultiPlayerTrafficVehicle` (14 method), `MultiPlayerServerTraffic` — **tabrakan dengan traffic di MP di-arbitrase server**.
- **Chat + GIF:** in-game chat (preset + GIF, sesuai pengumuman update), `MultiPlayerVoiceChatTab`, preferensi `MpVoice*`/`MpChat*` di `Prefs`.
- **Autopilot (fitur game baru):** `AutopilotDriver` (60 method, 111 field), `AutopilotConvoy*`, `AutopilotVehicle*`, `AutopilotLead*`.
- **Spectate + Join as Guest:** literal "{0} did not accept the passenger request. You continue as a spectator.", `AllowGuest`, `CameraSnapGuest*`, `GuestCopy`; `Prefs.MpAllowWatch`/`MpAllowGuest`/`MpAllowInterior`.
- **Vote-kick:** `OpenVoteKick`, "Only players who have interacted with you in the game appear in this list", "Only you are in the room".
- **Cloud prefs:** `MultiPlayerCloudPrefs` (Export/Import JSON, `MAX_JSON`, `TABLE`) — sinkronisasi **pengaturan** (suara, tema, volume voice), bukan ekonomi.
- **Keamanan/privasi MP (BARU, jangan disentuh):** `MultiPlayerScreenSecure` (deteksi screen-capture: `get_IsOn`, `get_Captured`, `Set`/`Reapply`/`Tick`/`Send`, `VERIFY_SEC`/`RETRY_SEC`/`RETRY_MAX`); `PurchaseReportQueue` (laporan pembelian IAP ke server MP: `STORE_GOOGLE`/`STORE_APPLE`, product/tx/token, `AckHash`/`ApplyAck`); `MPSModInfo`/`MPSModCacheInfo` (loader konten/mod sesi MP dengan gate hash + rentang versi + expiry: `Name`/`Hash`/`Title`/`Room`/`Running`/`Paused`/`Loader`/`Rev`/`Valid`/`VerMin`/`VerMax`/`ExpiresAt`); `OwnedDiffFingerprint` (fingerprint FNV-style atas diff konten yang dimiliki, untuk validasi sinkronisasi).
- **Ekonomi MP:** `Prefs.MpEconomyDirty` (M[2332], BARU), `ProfileData.MpPrefs` (F[2100], BARU), `Prefs.mpWashTickets` (F[5257], BARU), `JobComplete.RoomBonusHighlight` (M[12770], BARU).

### 3.3 Konsekuensi klasifikasi

Vonis "single-player offline" v0.7.64 **tidak lagi berlaku penuh**. Game kini punya mode multiplayer open-beta (room-based, pemain lain nyata, traffic + tabrakan di-arbitrase server, pembelian dilaporkan ke server MP). **Rebuild WAJIB dibatasi ke solo/offline:** semua hook mod harus **nonaktif saat sesi multiplayer berjalan** (deteksi via state `Wanda.MP.MultiPlayer` / `TruckController.get_IsRemoteVehicle` / keberadaan room). Fitur apa pun yang menyentuh pemain lain — ESP pemain lain, teleport/noclip di dalam room, no-damage terhadap tabrakan MP, manipulasi ekonomi saat di room — masuk **kelas yang ditolak** (sama seperti ESP/aimbot online pada umumnya).

---

## 4. Metadata v39 — cara parser dipecahkan

Parser v31 (`il2cpp_meta.py`) **gagal total** di v39: header tumbuh 264 → **380 byte**, layout berubah, field sampah → OOM. Yang dilakukan:

1. Header v39 = `sanity (0xFAB11BAF)` + `version (39)` + **31 × `Il2CppSectionMetadata{offset u32, size u32, count u32}`** = 380 byte. Urutan section sama dengan v31, **kecuali** 2 section lama hilang (`metadataUsageLists`/`metadataUsagePairs` tidak ada di v38+) dan 3 section baru (`attributeData`, `attributeDataRanges`, `exportedTypeDefinitions` di akhir; `windowsRuntimeTypeNames`/`windowsRuntimeStrings` kosong).
2. Validasi: ke-31 section **kontigu, menaik, berakhir tepat di EOF** (15.027.256). Contoh: stringLiteral 34.002 literal (tabel 136.008 B) → stringLiteralData 858.292 B → string 2.679.570 B / 152.269 string → … → exportedTypeDefinitions 3.168 entri.
3. Lebar indeks variabel (dikonfirmasi dari `c01ns/Il2CppDumper`, fork yang mendukung v35/v38/v39): `typeDefinitionIndexSize=2` (17.758 tipe), `genericContainerIndexSize=2` (2.501), **`typeIndexSize=2`** (diturunkan dari record `interfaceOffsets` 6 byte = indeks 2 B + offset 4 B), `parameterIndexSize=4` (146.903 — v39+), sisanya (event/interfaces/nested/property/method/field/genericParameter) **4 byte** di v39.
4. Ukuran record hasil hitung **cocok persis** dengan `size/count` tiap section: `ImageDefinition` 36 B, `TypeDefinition` 76 B, `MethodDefinition` 30 B, `FieldDefinition` 10 B, `ParameterDefinition` 10 B, `PropertyDefinition` 20 B, `EventDefinition` 22 B, `GenericContainer` 16 B, `GenericParameter` 14 B. Layout tiap record diverifikasi terhadap tipe yang diketahui (`<Module>`, `NullableAttribute`, `GPGSIds`: nama, namespace, token `0x0200000N`, bitfield, `fieldStart`/`methodStart`/`methodCount`/`fieldCount`/`vtableStart` semua konsisten).
5. **Catatan:** `TypeDefinition.byvalTypeIndex`/`declaringTypeIndex`/`parentIndex` adalah indeks ke **runtime `Il2CppType` array** (bukan ke `typeDefinitions`) — nilainya bisa > 17.758. Parser ini **tidak me-resolve tipe field** ke nama (hanya `typeIdx` angka); nama field + tipe pemiliknya terkonfirmasi, tipe field diinferensi dari REA v0.7.64 bila identik.
6. String literal diekstrak dengan benar (v35+: panjang = `dataIndex` literal berikut − `dataIndex` saat ini; 34.000 literal). Literal UI game berbahasa **Turki** (Wanda Software, Turki).

**Alat:** `~/workspace/rea-toe3-v0952/il2cpp_dump.py` (parser v39) + hasil `types.txt` (17.758 tipe), `methods.txt` (128.122), `fields.txt` (89.038), `properties.txt` (21.390), `events.txt` (500), `images.txt` (178), `targets.txt` (dump member target), `literals.txt` (34.000 literal), `metadata_strings.txt` (152.215 string), `dump.json`. Repo `rea` CLI lokal (`~/workspace/rea`) sudah di-build (`npm ci && npm run build:cached`, BUILD_EXIT=0) tapi **tidak punya** perintah `inspect-il2cpp-metadata` di v6.4.0 — parser Python di atas yang dipakai.

---

## 5. Tabel target mod v1.0.9 → padanan v0.9.52

Semua target di-resolve **by-name** (payload v1.0.9 memakai `il2cpp_class_get_method_from_name`/`get_field_from_name`, bukan offset hardcode) — jadi yang penting adalah **nama masih ada**, bukan alamat. Indeks method/field di bawah adalah indeks **metadata global** (berubah total vs v0.7.64 — mis. `Prefs.set_Balance` dulu M[13633], kini M[2328]).

### 5.1 Ekonomi / profil (`Prefs`, `ProfileData`, `JobComplete`)

| Target v1.0.9 | v0.9.52 | Status |
|---|---|---|
| `Prefs.get_Balance` / `set_Balance` | **M[2327] / M[2328]** (`Prefs`, typeIdx 430) | ✅ Ada |
| `Prefs.get_Level` / `set_Level` | **M[2315] / M[2316]** | ✅ Ada |
| `Prefs.get_Xp` / `set_Xp` | **M[2317] / M[2318]** | ✅ Ada |
| `Prefs.get_JobFuel` / `set_JobFuel` | **M[2313] / M[2314]** | ✅ Ada |
| `Prefs.get_WashTickets` / `set_WashTickets` | **M[2475] / M[2476]** (field `WashTickets` F[2087] di `ProfileData`) | ✅ Ada |
| `Prefs.get_AdFree` / `set_AdFree` | **M[2335] / M[2336]** (+ `get_AdFreeEffective` M[2337], BARU) | ✅ Ada |
| `Prefs.get_CurrentJob` / `set_CurrentJob` | **M[2481] / M[2482]** | ✅ Ada |
| `Prefs.get_Gold` / `set_Gold` | M[2330] / M[2331] | ⚠️ Ada — **tetap DITOLAK (IAP)** |
| `Prefs.get_UnlockTrailers` / `set_UnlockTrailers` | M[2338] / M[2339] | ⚠️ Ada — **tetap DITOLAK (IAP)** |
| `Prefs.Spend` (params=3) | M[2329] | ✅ Ada |
| `ProfileData.Balance` (float) / `Gold` (int) / `Level` / `Xp` / `JobFuel` / `WashTickets` / `CurrentJob` | F[2064] / F[2065] / F[2059] / F[2060] / F[2058] / F[2087] / F[2094] (`ProfileData`, typeIdx 279, 52 field) | ✅ Ada |
| `JobComplete.SetXP` / `LevelUp` / `Completed` | M[12772] / M[12778] / M[12774] (`JobComplete`, typeIdx 1709) | ✅ Ada |
| BARU: `Prefs.MpEconomyDirty` | M[2332] | ℹ️ Flag ekonomi kotor (MP) — lihat §3.3 |
| BARU: `ProfileData.MpPrefs` | F[2100] | ℹ️ Slot prefs MP |

### 5.2 Truk / damage / noclip (`TruckController`, `TruckDamage`, Unity)

| Target v1.0.9 | v0.9.52 | Status |
|---|---|---|
| `TruckController.Update` | **M[15610]** (`TruckController`, typeIdx 2097, 71 method / 247 field) | ✅ Ada |
| `TruckController.OnCollisionEnter` | M[15606] | ✅ Ada |
| `TruckController.rigBody` / `fuel` / `fuelLeft` / `fuelTankCapacity` / `mainCamera` / `speed` / `speedInKph` | F[18635] / F[18654] / F[18657] / F[18580] / F[18670] / F[18690] / F[18691] | ✅ Ada semua |
| `TruckController.fuelRate` / `fuelMultiplier` | F[18688] / F[18713] | ✅ Ada |
| `TruckDamage.OnCollisionEnter` | **M[15706]** (`TruckDamage`, typeIdx 2100, 7 method / 8 field) | ✅ Ada |
| BARU: `TruckController.get_IsRemoteVehicle` | M[15598] | ℹ️ Penanda kendaraan pemain lain — **kunci deteksi MP** |
| `TruckController.ResetTruckPosition` / `RecoverTo` / `FloatingOriginPos` | M[15616] / M[15628] / M[15618] | ✅ Ada (relevan teleport) |
| `Transform.get_position` / `set_position` | **M[60166] / M[60167]** (`UnityEngine.Transform`, 184 method) | ✅ Ada |
| `Component.get_transform` | **M[59166]** | ✅ Ada |
| `Camera.WorldToScreenPoint` (1-arg) / `get_main` | **M[53689]** (overload lain M[53693]) / **M[53713]** (`UnityEngine.Camera`, 387 method) | ✅ Ada |
| `Screen.get_width` / `get_height` | **M[54464] / M[54465]** | ✅ Ada |
| `Object.get_name` | **M[59553]** | ✅ Ada |
| `Rigidbody.set_detectCollisions` / `set_velocity` / `set_angularVelocity` (+ `get_velocity`) | **M[113930] / M[114002] / M[113898]** (M[114001]) (`UnityEngine.Rigidbody`, PhysicsModule, 186 method) | ✅ Ada |

### 5.3 Traffic / ESP — TARGET LAMA HILANG, HARUS DITULIS ULANG

| Target v1.0.9 | v0.9.52 | Status |
|---|---|---|
| `TrafficSpawner` (12 method, 17 field) | **TIDAK ADA** — tipe tidak ditemukan di 17.758 tipe | ❌ Hilang |
| `TrafficSpawner.spawnedCars` | — | ❌ Hilang |
| `TrafficCar` (41 method, 132 field) + `TrafficCar.speed` / `playerDistance` | **TIDAK ADA** | ❌ Hilang |
| Pengganti: **`Wanda.TrafficVehicleAI`** (`Wanda.TrafficSystem.dll`, typeIdx 12693) | **331 method, 623 field, 26 properti** | ✅ **Target ESP baru** |
| `TrafficVehicleAI.Update` / `FixedUpdate` | M[99741] / M[99745] | ✅ Ada |
| `TrafficVehicleAI.get_CalculatedVelocity` | M[99744] (field `calculatedVelocity` F[70136]) | ✅ Ada (≈ `TrafficCar.speed`) |
| `TrafficVehicleAI.NearestPlayerDistance` | M[99797] | ✅ Ada (≈ `TrafficCar.playerDistance`) |
| `TrafficVehicleAI` field kecepatan | `configuredMaxSpeed` F[70051], `speedAtTickStart` F[70081], `registryAheadSpeedKmh` F[70201], `diagEffectiveMaxSpeedKmh` F[70231] | ✅ Ada |
| `TrafficVehicleAI` posisi | `driverPosition` F[70025], `previousPositionForVelocity` F[70135], `lookTargetAbsolutePosition` F[70176] | ✅ Ada (posisi via `Transform` seperti biasa) |
| MP: `TrafficVehicleAI.AdoptFromNetwork` / `RemoteOnlyTickDue` / `SeenOnlyByRemote` / `UnseenByAnyPlayer` | M[99747–99749] / M[99742] / M[99743] / M[99682] | ℹ️ Traffic bisa "diadopsi" dari network — ESP harus membedakan traffic lokal vs remote |
| MP: `MultiPlayerTrafficVehicle` | typeIdx 1457, 14 method / 24 field | ℹ️ Representasi traffic di MP |

**Cara ESP baru (usul):** enumerasi instance `TrafficVehicleAI` (via `Object.FindObjectsOfType` / registry traffic) → baca `Transform.position` + `calculatedVelocity` + `NearestPlayerDistance`. **Hanya solo/offline.** Di MP, traffic remote + kendaraan pemain lain (`OtherPlayer*`) **bukan** target ESP.

### 5.4 Teleport (`Job.DeliverPoint`)

| Target v1.0.9 | v0.9.52 | Status |
|---|---|---|
| `Job.DeliverPoint` | **F[2416]** (`Job`, typeIdx 335, 28 field; `int`, typeIdx 26639) | ✅ Ada |
| `Job` field terkait | `DeliverArea` F[2414], `StartArea` F[2415], `Income` F[2409], `CargoWeight` F[2405], `Km` F[2413], `To` F[2392] | ✅ Ada |
| `Prefs.get_CurrentJob` | M[2481] (lihat §5.1) | ✅ Ada |

Teleport **tetap di-gate** (aturan v1.0.9) — dan di MP teleport = terlihat pemain lain, jadi gate harus juga mencakup "bukan di room MP".

---

## 6. Klasifikasi server vs lokal per fitur (vonis)

Tanpa analisis runtime; vonis dari struktur kode + REA v0.7.64 (yang masih berlaku kecuali dinyatakan).

| Fitur | Vonis | Bukti v0.9.52 |
|---|---|---|
| Balance → 10.000.000 | **BOLEH (lokal, SOLO SAJA)** | `Prefs.set_Balance` M[2328]; save lokal via `ZPlayerPrefs` (AES, `Encrypt`/`Decrypt`, `useSecure` — bentuk sama seperti v0.7.64); Balance murni hasil gameplay, bukan mata uang beli. **BARU:** `MpEconomyDirty` + `PurchaseReportQueue` + cloud prefs → di dalam room MP, perubahan ekonomi bisa ter-flag/terlaporkan. **Mod wajib nonaktif di MP.** |
| Level / XP | **BOLEH (lokal, SOLO SAJA)** | `Prefs.Level`/`Xp`, `JobComplete.SetXP`/`LevelUp`; level hanya gerbang konten lokal. Di MP, level tampil ke pemain lain — tetap solo-only. |
| JobFuel 9999 / free fuel | **BOLEH (lokal, SOLO SAJA)** | `Prefs.JobFuel`, `TruckController.fuel`/`fuelLeft`/`fuelRate`; isi bensin gratis via iklan memang disediakan game. |
| WashTickets ≥ 99 | **BOLEH (lokal, SOLO SAJA)** | `Prefs.WashTickets`; ada `mpWashTickets` terpisah untuk MP — jangan sentuh yang MP. |
| AdFree paksa true | **BOLEH (lokal)** | `Prefs.AdFree`/`AdFreeEffective` — flag lokal (preseden HappyMall). |
| No-damage | **BOLEH (lokal, SOLO SAJA)** | `TruckDamage.OnCollisionEnter` M[15706]. **Tapi** tabrakan traffic di MP di-arbitrase server (`MultiPlayerTrafficCrashAuthority`, `MultiPlayerTrafficHitReport`) — no-damage di MP = desync/terlihat. Solo-only. |
| Noclip (Rigidbody) | **BOLEH (lokal, SOLO SAJA)** | `Rigidbody.set_detectCollisions`/`set_velocity`/`set_angularVelocity` — fisika lokal; di MP posisi disinkronisasi → noclip = teleport terlihat. Solo-only. |
| ESP traffic | **BOLEH (lokal, SOLO SAJA)** | Via `TrafficVehicleAI` (baru). **ESP kendaraan PEMAIN LAIN (`OtherPlayer*`) = DITOLAK.** |
| Teleport ke `Job.DeliverPoint` | **Tetap di-gate** (aturan v1.0.9) | `Job.DeliverPoint` F[2416] ada; `FloatingOriginPos`/`ResetTruckPosition` ada. Di MP = terlihat pemain lain. |
| **Gold** | **TETAP DITOLAK (IAP)** | `coins1–4`/`golds1–4` via Unity Purchasing (`iap.services.api.unity.com`); `PurchaseReportQueue` melaporkan pembelian ke server MP. |
| **Unlock Trailers** | **TETAP DITOLAK (IAP)** | Produk `unlock_trailers` masih ada; `OwnedDiffFingerprint` memvalidasi konten yang dimiliki di MP. |
| Autopilot (fitur game) | **Bukan target mod** | `AutopilotDriver` dkk. adalah fitur resmi baru — jangan di-hook/diubah. |
| Screen-capture protection MP | **Jangan disentuh** | `MultiPlayerScreenSecure` — game memverifikasi status tangkapan layar di MP. |

### Anti-cheat / deteksi root / integritas

- **TIDAK ADA deteksi root/anti-cheat di sisi game:** `magisk` 0, `frida` 0 (1 hit lama = kata "Friday"), `xposed` 0 di `libil2cpp.so` (10 hit di `libunity.so` = `VFXExposed*`, Unity Visual Effect Graph — false positive), `safetynet` 0, `playintegrity` 0, `isRooted` 0, `busybox` 0, `superuser` 0, `/su` 0 — di `libil2cpp.so` maupun `libunity.so`. DEX: `rootbeer` 0; hit `isRooted`/`magisk`/`play.integrity` semuanya dari SDK iklan (Unity Ads, AppLovin, InMobi, Chromium `WebViewMediaIntegrityApiStatus`) — bukan game.
- `libnms.so` + `libpglarmor.so` **masih ada** (komponen iklan Pangle, seperti v0.7.64 — bukan anti-cheat).
- **TAPI ada mekanisme integritas MP baru** (bukan anti-cheat klasik): `MultiPlayerScreenSecure`, `MPSModInfo` (hash-gated loader), `OwnedDiffFingerprint`, `PurchaseReportQueue`, arbitrase tabrakan server. Ini alasan tambahan untuk membatasi mod ke solo.
- **Save tetap terenkripsi:** `ZPlayerPrefs` (`Wanda.Core.dll`, typeIdx 14377): `Encrypt`/`Decrypt`, `GetIV`/`GetKey`, field `useSecure`/`keyLength`/`Iterations`/`strPassword`/`strSalt`/`_cachedIV`/`_cachedKey` — sama bentuknya dengan v0.7.64. Mod v1.0.9 tidak menyentuh file save langsung (pakai API `Prefs`), jadi ini tidak menghambat rebuild.
- **Izin baru yang relevan:** `com.amazon.privacypass.ATTEST` (Amazon Privacy Pass attestation — kemungkinan dipakai alur anti-abuse MP) dan `CHECK_LICENSE` (lisensi Play). Perilaku pastinya tidak terkonfirmasi statis.

---

## 7. Rekomendasi rebuild (untuk keputusan user)

1. **Bisa dipakai ulang (by-name, tanpa ubah logika):** semua hook `Prefs.*` (Balance, Level, Xp, JobFuel, WashTickets, AdFree, CurrentJob), `TruckController.Update` + field (`rigBody`, `fuel`, `fuelLeft`, `fuelTankCapacity`, `mainCamera`, `speed`, `speedInKph`), `TruckDamage.OnCollisionEnter`, semua API Unity (`Transform`, `Camera`, `Screen`, `Object`, `Rigidbody`), `Job.DeliverPoint` (teleport, tetap di-gate). Indeks method berubah total — pastikan payload **tidak ada** indeks hardcode (payload v1.0.9 resolve by-name; verifikasi ulang saat rebuild).
2. **Harus ditulis ulang:** ESP traffic — `TrafficSpawner`/`TrafficCar` hilang; ganti ke **`TrafficVehicleAI`** (`calculatedVelocity`, `NearestPlayerDistance`, `Transform.position`).
3. **Wajib baru — gate sesi multiplayer:** mod harus mendeteksi room MP (mis. state `Wanda.MP.MultiPlayer` / `TruckController.get_IsRemoteVehicle`) dan **menonaktifkan semua hook** saat di MP. Ini syarat rebuild, bukan opsional.
4. **Gate versi:** update ke **0.9.52 / code 214**. Hash gate `libil2cpp.so` **jangan** diisi `0053df95…` dulu — verifikasi dari **biner perangkat user** (§1) karena biner user berbeda hash-nya.
5. **Tetap ditolak:** Gold, Unlock Trailers, ESP pemain lain, teleport/noclip/no-damage di dalam room MP, Autopilot, `MultiPlayerScreenSecure`, `MPSModInfo`.
6. **Tidak perlu:** bypass PairIP (tidak ada), bypass anti-cheat (tidak ada), bypass captcha (tidak ada).

## 8. Batasan & yang belum terjawab

- **Hash `libil2cpp.so` user vs file ini tidak cocok** (§1) — penyebab belum diketahui; file kedua MediaFire tidak berhasil diunduh (Cloudflare challenge di host `download2353`). Butuh biner dari perangkat user (tarik via root) atau sumber lain yang cocok.
- **Tanpa analisis runtime** (sesuai tugas): perilaku `MpEconomyDirty`, `MPSModInfo`, `MultiPlayerScreenSecure`, dan apakah Balance benar-benar tidak divalidasi server saat MP — **inferensi statis saja**, belum terverifikasi di perangkat.
- **Tipe field tidak di-resolve ke nama** (hanya `typeIdx` angka runtime); nama field + tipe pemilik terkonfirmasi penuh.
- **Tidak ada klaim "siap pakai"** — pola/alamat biner tidak disertakan; rebuild memakai resolusi by-name dan wajib uji runtime di perangkat (solo dulu).

## 9. File kerja (`~/workspace/rea-toe3-v0952/`)

- `REPORT.md` (file ini) · `il2cpp_dump.py` (parser metadata v39) · `dump.json` (indeks lengkap)
- `types.txt` (17.758 tipe) · `methods.txt` (128.122) · `fields.txt` (89.038) · `properties.txt` (21.390) · `events.txt` (500) · `images.txt` (178) · `targets.txt` (dump member target) · `literals.txt` (34.000 literal) · `metadata_strings.txt` (152.215 string)
- `Truckers_of_Europe_3_0.9.52.apks` (797.359.310 B, SHA-256 `915244a3…`) · `xapk/` (base + 2 split terekstrak) · `base-apk/` (base terekstrak) · `config-arm64/` (split config terekstrak) · `api_response.bin` (respons API APKPure — hanya s/d 0.7.64) · `il2cppdumper_Metadata.cs` / `il2cppdumper_MetadataClass.cs` / `il2cppdumper_Il2Cpp.cs` (referensi layout v39, c01ns/Il2CppDumper)
- File `ToE3-0.9.52-second.apks` **dihapus** (isinya hanya halaman error Cloudflare 6.904 B, bukan APK).
