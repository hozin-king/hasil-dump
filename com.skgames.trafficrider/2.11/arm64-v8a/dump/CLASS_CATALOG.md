# Traffic Rider — Class Catalog (Il2CppDumper)

**Sumber:** `~/workspace/rea-trafficrider/dump/dump.cs` — Il2CppDumper untuk
`com.skgames.trafficrider` v2.11, Unity 6 + IL2CPP, `libil2cpp.so` hash
`a1e1dc90…` (file yang sama dengan sumber REA mod v1.2–v1.4).
**Tanggal katalog:** 3 Nov 2026. **Sifat dokumen:** riset saja — tidak ada
kode yang diubah, tidak ada build.

## Cara membaca

- **Offset** (`// 0x…`) = offset field di dalam instance object (IL2CPP).
  Berlaku untuk field instance, BUKAN field `static` — field static tinggal
  di static storage yang alamatnya harus di-resolve saat runtime, jadi
  offset static di bawah ini dicantumkan apa adanya dari dump dan TIDAK
  bisa langsung dipakai sebagai `obj + offset`.
- **RVA** = alamat method relatif terhadap image base `libil2cpp.so`.
  File offset di `.so` = RVA − 0x4000 (segmen RX). Pola prologue 32-byte
  yang dipakai mod v1.2+ tetap wajib dipakai untuk resolve runtime
  (prologue 16-byte terbukti tidak unik); jangan pakai `base + RVA` mentah.
- **Tidak ada yang dikarang.** Semua field/offset/RVA di bawah ini berasal
  dari dump. Yang belum bisa dipastikan dari dump saja ditandai
  "unverified in dump" atau masuk bagian "Belum bisa ditentukan".
- **Aturan cakupan:** hanya fitur LOKAL, SOLO, VISUAL-ONLY, atau OFFLINE.
  Sistem server/online ada di bagian OFF-LIMITS di akhir, tanpa usulan
  pemakaian. Score multiplier TIDAK diusulkan (perintah user), dan
  `Time.timeScale` TIDAK diusulkan (game membawa `SpeedHackDetector`
  yang mengawasinya).

---

## 1. Motor pemain (player bike)

### MotorMover — penggerak & fisika motor pemain (146 field, 50 method)
Inti gameplay: kecepatan, gigi, RPM, lajur, tabrakan, wheelie, scrape.
Field kunci:
- `curSpeed` 0xFC (float), `maxSpeed` 0x104 (float — PERINGATAN: tidak
  pernah dibaca game, menaikkannya tidak berpengaruh; sudah dibuktikan
  v1.2), `maxAcceleration` 0x108, `handling` 0x10C, `braking` 0x110
- `laneId` 0x114, `isOnOppositeLane` 0x118, `curGear` 0x124,
  `curRpm` 0x128, `curStrafe` 0xF8
- `halfWidth` 0x160, `frontLength` 0x164 (dipakai box ESP v1.4)
- `trans` (Transform) 0x1A8, `mainCam` (Camera) 0x2B0,
  `handleWheelTrans` 0x1B8, `wheeliePos` 0x58
- `isCrashed` 0x1E1, `isScrapingLeft` 0x220, `isScrapingRight` 0x221,
  `wheelieState` 0x1FC, `curWheelieValue` 0x204, `curWheelieCharge` 0x208
- `isHorning` 0x1E0, `hasHitVehicle` 0x1E3, `vehicleHitLocation` 0x1E4
- Mesin: `GearRatio` 0x2C0, `MaxEngineRPM` 0x2C8, `MinEngineRPM` 0x2CC,
  `MaxEngineTorque` 0x2D4, `FinalGearRatio` 0x2E4
Method kunci:
- `Update()` RVA 0x188E530 — berisi cabang scrape (snap/cap/clamp X ke
  lebar jalan) dan cabang Crash keluar jalan; sumber masalah noclip v1.3
- `FixedUpdate()` 0x188FF8C, `HandleSpeed()` 0x188F96C,
  `Crash()` 0x188F714 (satu-satunya gerbang kematian; dipakai god mode),
  `OnTriggerEnter()` 0x1890A50 (satu-satunya handler tabrakan; dipakai
  noclip), `HitTrafficSlowly()` 0x1890C8C
- `GetGear()` 0x1890900, `GetMaxSpeed()` 0x189090C,
  `GetSpeedMs()` 0x1890914, `GetSpeedKmh()` 0x189091C,
  `GetRpm()` 0x1890988, `GetPosition()` 0x1890990,
  `GetPosX()` 0x18909A8, `GetPosZ()` 0x18909C0,
  `GetHalfWidth()` 0x18909E4, `GetFrontLength()` 0x18909EC
- `StartWheelie()` 0x188E364, `EndWheelie()` 0x188E41C,
  `HornPressed()` 0x188E448, `GearUp()` 0x18910A4, `GearDown()` 0x1891098,
  `ResetMotor(bool)` 0x188FDB0, `BlinkMotor()` 0x187ED74
- `ChangeMaterials()` 0x188D90C, `ChangeMaterialsOnlyAtNight()` 0x188DDB4,
  `ChangeMaterialsToOriginal()` 0x188E08C (ganti material siang/malam)
- `ActivateRevLimiter()` 0x18912C8, `DeactivateRevLimiter()` 0x1891080
**Dipakai untuk (lokal):** overlay telemetri lengkap (RPM, gigi, kecepatan
  km/h via `GetSpeedKmh`, strafe, status wheelie + charge, indikator
  scraping kiri/kanan, status crash) — semua read-only, tanpa mengubah
  gameplay. `GetSpeedKmh` adalah jawaban resmi atas asumsi unit `curSpeed`
  di ESP v1.4 (apakah m/s atau bukan) — unverified in dump: isi fungsi
  belum dibaca, tapi namanya menunjukkan konversi resmi.

### MotorManager — katalog motor yang bisa dimiliki (15 field, 13 method)
- `motorProperties` (List<MotorProperties>) 0x20
- Index statis tiap motor: `indexHarleyDavidson` 0x0, `indexZX10R` 0x4,
  `indexDucati1098R` 0x8, `indexNinja300` 0xC, `indexZZR1400` 0x10,
  `indexHayabusa` 0x14, `indexYamahaR1` 0x18, `indexDucatiStreetfighter`
  0x1C, `indexMultistrada` 0x20, `indexS1000RR` 0x24, `indexH2R` 0x28
- `GetMotorCount()` 0x188C4DC, `GetOwnedMotorCount()` 0x188C540,
  `GetMotorIdBySelectionIndex()` 0x188C698,
  `GetSelectionIndexByMotorId()` 0x188C214,
  `GetLastOwnedMotorIndex()` 0x188C84C,
  `GetQuestRewardMultiplierWrtLastOwnedMotorForCash()` 0x188C924,
  `GetQuestRewardMultiplierWrtLastOwnedMotorForGold()` 0x188C95C,
  `CanAffordNewBikeForCareer()` 0x188C9A8,
  `UpdateMotorOwningStates()` 0x188C2EC
**Dipakai untuk (lokal):** overlay info garasi (motor dimiliki/belum, jumlah
  motor) dan penghitung reward quest per motor terakhir — display saja.
  `GetSelectionIndexBy_IAP_Id` (0x188C76C) TIDAK dipakai (jalur IAP).

### MotorProperties — data satu motor (37 field, 13 method)
- `nickName` 0x20, `uniqueId` 0x28, `prefabName` 0x30,
  `assetBundleName` 0x38, `thumbnailImage` 0x40, `garageIconImage` 0x48
- `requiredLevel` 0x50, `isIAP` 0x54, `iapId_Android` 0x58,
  `iapId_IOS` 0x60, `iapId_WP8` 0x68, `isGold` 0x70, `price` 0x74,
  `isOwned` 0x78, `lifeCount` 0x7C
- Upgrade: `powerBase` 0x84, `powerUpgradeMax` 0x88,
  `powerUpgradeCur` 0x8C, `handlingBase` 0x90, `handlingUpgradeMax` 0x94,
  `handlingUpgradeCur` 0x98, `brakingBase` 0x9C, `brakingUpgradeMax`
  0xA0, `brakingUpgradeCur` 0xA4, `baseUpgradePrice` 0x80,
  `maxUpgrade` (statis) 0x0, `perUpgradeIncrement` (statis) 0x4
- Kosmetik: `paintPrice` 0xC0, `decal1Index` 0xC4, `decal2Index` 0xC8,
  `decal3Index` 0xCC, `decal4Index` 0xD0, `decalPrice` 0xD4
- `GetPowerUpgradePrice()` 0x1892650, `GetHandlingUpgradePrice()`
  0x1892684, `GetBrakingUpgradePrice()` 0x18926A0
**Dipakai untuk (lokal):** overlay statistik motor + biaya upgrade
  berikutnya (display). Field `isIAP`/`iapId_*` hanya penanda — TIDAK
  dipakai untuk membuka motor berbayar.

### Enum & struct pendukung motor
- `MotorState`, `WheelieState`, `HitLocation`, `SpotLightState` — status
  motor/wheelie/lokasi tabrakan/lampu sorot; dipakai label status overlay.
- `MaterialChange` — pasangan material yang diganti siang/malam; dipakai
  memahami sistem material (lihat `ChangeMaterials` di atas).

---

## 2. Kendaraan lalu lintas (traffic)

### TrafficManager — pengatur spawn & daftar kendaraan (10 field, 12 method)
- `activeTrafficSegment` 0x30, `trafficVehicles`
  (List<TrafficVehicle>) 0x38 — sumber data ESP,
  `activeTrafficVehicleCount` 0x40, `targetTrafficVehicleCount` 0x44,
  `maxNumberOfTrafficVehicles` 0x48, `minNumberOfTrafficVehicles` 0x4C,
  `motorMover` 0x60
- `FixedUpdate()` RVA 0x189EEE8 — hook main-thread ESP v1.4;
  `Start()` 0x189E7D8, `WarmUpTraffic()` 0x189EE54,
  `SetTrafficSegment(string)` 0x189F5E0,
  `GetTrafficSegment()` 0x189F758,
  `IsLaneAvailableOnPoint()` 0x189F760,
  `GetFrontVehicleDistanceAndSpeed()` 0x189F968 (jarak + kecepatan
  kendaraan di depan, per lajur — data mentah untuk peringatan jarak),
  `GetRandomInactiveCar()` 0x189FBF8,
  `CalculateTargetTrafficVehicleCount()` 0x189F044,
  `CheckForRespawn()` 0x189F09C
**Dipakai untuk (lokal):** semua fitur ESP (sudah dipakai v1.3/v1.4);
  `GetFrontVehicleDistanceAndSpeed` bisa jadi overlay "kendaraan depan:
  jarak + kecepatan"; `targetTrafficVehicleCount`/`trafficDensityForRelaxMode`
  (di GameStateManager) adalah kandidat toggle densitas lalu lintas
  lokal — unverified in dump: belum diuji apakah mengubahnya saat balapan
  aman.

### TrafficMover — perilaku satu kendaraan (57 field, 12 method)
- `lightsForHighGfx` 0x20, `wheelRadiusForHighGfx` 0x28,
  `wheelsForHighGfx` (List<Transform>) 0x30 — rangka roda ESP v1.4
- `halfWidth` 0x48, `frontLength` 0x4C — box ESP v1.4
- `hornType` 0x44, `targetSpeed` 0x74, `curSpeed` 0x78,
  `trafficIndex` 0x7C, `isActive` 0x80, `isOnOppositeLane` 0x81,
  `hasBeenHit` 0x82, `canChangeLane` 0x83, `laneId` 0x84,
  `occupyingLaneId` 0x88, `occupyingLaneX` 0x8C
- Lampu: `stopLeftObj` 0x90, `stopRightObj` 0x98, `stopMiddleObj` 0xA0,
  `shortlightLeftObj` 0xA8, `shortlightRightObj` 0xB0,
  `backlightLeftObj` 0xB8, `backlightRightObj` 0xC0,
  `signalLeftObj` 0xC8, `signalRightObj` 0xD0, `lightGround` 0xD8
- `motorMover` 0x108, `trans` 0x110, `shadowTrans` 0x118,
  `trafficState` 0x130
- `Activate()` 0x189FCE8, `Deactivate()` 0x189EDB0,
  `SetMotor()` 0x189ED80, `GetPosX()` 0x18A1FF8, `GetPosZ()` 0x18A2010,
  `StartChangingLane()` 0x18A1FA4, `FixedUpdate()` 0x18A1090
**Dipakai untuk (lokal):** label ESP diperkaya (lajur, kecepatan, status
  lampu sein/rem — sein kiri/kanan bisa dibaca dari `isSignalingLeft`
  0xF9/`isSignalingRight` 0xFA — unverified in dump: nama field
  menunjukkan sein, belum diuji runtime); `hasBeenHit` untuk menandai
  kendaraan yang sudah tersenggol.

### TrafficVehicle — bungkus satu kendaraan (4 field, 1 method)
- `obj` (GameObject) 0x10, `trans` (Transform) 0x18,
  `collider` (Collider) 0x20, `trafficMover` (TrafficMover) 0x28
**Dipakai untuk (lokal):** sumber data ESP (sudah dipakai v1.3/v1.4);
  `obj` + `Object.get_name` = nama model kendaraan.

### TrafficSegment — definisi segmen jalan (5 field, 1 method)
- `segmentName` 0x10, `lanes` (List<float>) 0x18, `laneWidth` 0x20,
  `hasOppositeLanes` 0x24, `oppositeLanes` (List<float>) 0x28
**Dipakai untuk (lokal):** overlay info lajur aktif (posisi X tiap lajur,
  lebar lajur, ada/tidaknya lajur berlawanan) dan riset perilaku noclip
  (batas jalan berasal dari segmen ini + `GameStateManager` di bawah).

### MainTrafficManager — prefab & tipe segmen (2 field)
- `trafficPrefabsHighGfx` (List<GameObject>) 0x20,
  `trafficSegmentTypes` (List<TrafficSegment>) 0x28
**Dipakai untuk (lokal):** daftar model kendaraan yang bisa muncul
  (display / riset nama prefab); mencocokkan instance ke prefab =
  unverified in dump (perlu uji runtime).

### CrossroadDetector — detektor persimpangan (0 field, 3 method)
- `OnTriggerEnter()` 0x185706C, `OnTriggerExit()` 0x18570C8
**Dipakai untuk (lokal):** status "di persimpangan" untuk overlay
  (bersama `GameStateManager.isInCrossroad`).

### Enum traffic
- `TrafficState`, `HornType` (klakson mobil/bus/truk — dipakai
  `AudioManager.PlayHorn`).

---

## 3. Status game & skor (read-only untuk overlay)

### GameManager — skor & statistik satu balapan (33 field, 7 method)
- `score` (privat) 0x3C, `scoreBase` 0x40, `oldScore` 0x38,
  `distanceInMeters` 0x44, `combo` 0x48, `maxCombo` 0x4C,
  `overtakeCount` 0x50, `overtakeCountOver200` 0x54,
  `maxSpeedAchieved` 0x58, `speedOnCrash` 0x5C,
  `totalWheelieTimer` 0x64, `scoreBoostState` 0x68,
  `curHighSpeedTimer` 0x6C, `totalHighSpeedTimer` 0x70,
  `curOpposingLaneTimer` 0x74, `totalOpposingLaneTimer` 0x78,
  `timeLeft` 0x7C, `gamePlayTime` 0x80, `comboTimer` 0x88,
  `endlessNonThrottleTime` 0x8C, `motorMover` 0x90,
  `currentMission` 0x98, `checkPointZList` 0xA0,
  `checkPointPassedList` 0xA8
- `GetScore()` 0x1859438 — RANTAI KE LEADERBOARD (lihat OFF-LIMITS);
  TIDAK dipakai untuk pengali skor.
- `CloseCall(bool)` 0x1859F80, `FixedUpdate()` 0x1859470
**Dipakai untuk (lokal):** overlay statistik balapan real-time (jarak,
  kombo, overtake, waktu high-speed, waktu lawan arah, waktu tersisa,
  checkpoint) — read-only. Skor hanya ditampilkan, tidak diubah.

### GameStateManager — status global statis (24 field statis, 3 method)
- `gameMode` 0x0, `difficultyMode` 0x4, `location` 0x8,
  `timeOfDay` 0xC, `isLensFlareActive` 0x10, `isRaining` 0x11,
  `isSnowing` 0x12, `trafficWarmedUp` 0x13,
  `leftHandTrafficEnabled` 0x14, `trafficDensityForRelaxMode` 0x18
- `msToKmhFactor` 0x1C, `oneOverMsToKmhFactor` 0x20 — FAKTOR KONVERSI
  RESMI m/s→km/h (menjawab asumsi ESP v1.4; cara baca static storage =
  unverified in dump, harus di-resolve runtime)
- `minOvertakeSpeed` 0x24, `terrainLeftBorder` 0x28,
  `terrainRightBorder` 0x2C — BATAS KIRI/KANAN TERRAIN (kunci riset
  perilaku keluar jalan / teleport balik saat noclip nonaktif),
  `selectedMotorIndex` 0x30, `power` 0x34, `braking` 0x38,
  `handling` 0x3C, `gameState` 0x40, `motorState` 0x44,
  `lifeCount` 0x48, `usedLifeCount` 0x4C, `isInCrossroad` 0x50
- `Reset()` 0x1859248
**Dipakai untuk (lokal):** overlay mode/kesulitan/lokasi/waktu/cuaca;
  faktor konversi kecepatan resmi; riset batas terrain untuk noclip.

### Enum status
- `GameMode`, `DifficultyMode`, `Location` (highway/desert/city/winter),
  `TimeOfDay` (noon/evening/night), `GameState`, `ScoreBoostState`,
  `CloseCallLocation` — label overlay & logika tampilan.

---

## 4. Jalan, dunia & terrain

### TerrainManager — generator jalan & terrain (32 field, 8 method)
- `trainObject` 0x20, `trainTrans` 0x28, `isTrainActive` 0x30,
  `hasTrainActivatedThisRun` 0x31, `tunnelObject` 0x38,
  `tunnelDistanceToStartingRoad` 0x40, `tunnelHalfLength` 0x44,
  `tunnelShadowLength` 0x48, `tunnelPosX` 0x4C, `tunnelPosY` 0x50,
  `terrainOffsetY` 0x54, `roadLength` 0x58,
  `roadGroups` (List<RoadGroup>) 0x60,
  `backgroundMountains` 0x68, `activeTerrains` 0xA0,
  `curRoadGroupIndex` 0xAC, `curLoopCount` 0xB0,
  `curInnerRoadPartIndex` 0xB4, `curRoadPutState` 0xB8,
  `isMotorInTunnel` 0xBC, `isMotorInTunnelShadow` 0xBD,
  `tunnelPosZ` 0xC0, `tunnelTrans` 0xC8, `motorMover` 0xD0
- `IsInTunnel(float)` 0x189DA8C, `FixedUpdate()` 0x189DB5C,
  `CheckMountainPut()` 0x189D69C
**Dipakai untuk (lokal):** overlay status terowongan (di dalam/di
  bayangan terowongan, panjang terowongan), status kereta aktif,
  grup jalan aktif — display; riset kenapa motor "kembali" saat keluar
  batas (kemungkinan reset segmen — unverified in dump).

### RoadGroup — satu grup potongan jalan (13 field, 7 method)
- `groupName` 0x10, `loopCount` 0x18, `requiredGfxQuality` 0x1C,
  `startingRoadPart` 0x20, `endingRoadPart` 0x28,
  `innerRoadParts` 0x30, `hasTunnel` 0x38, `hasTrain` 0x39,
  `leftMountainAvailable` 0x3A, `rightMountainAvailable` 0x3B
**Dipakai untuk (lokal):** nama grup jalan aktif + apakah ada
  terowongan/kereta di depan (info overlay).

### Lainnya (dunia)
- `RoadPutState` — status penempatan potongan jalan (dipakai
  `TerrainManager.curRoadPutState`).
- `MirrorAdjuster` — nilai fresnel/emisi kaca spion siang/sore/malam/
  terowongan (display tweak kaca spion — unverified in dump: hanya
  nilai, belum ada method pemakai yang dibaca).
- `SunOrientation` — orientasi matahari (display/lighting info).
- `WindMillRotator` — kincir angin (objek dunia, display saja).
- `TextureTilingController` — pengulangan tekstur jalan (display tweak).
- `SceneObjectHolder` — penampung objek scene (riset, bukan fitur).
- `CheckEditorOnly` — hanya editor, abaikan.

---

## 5. Kamera & render

### CameraMover — kamera pengikut (21 field, 9 method)
- `currentFollowDistance` 0x24, `motorMover` 0x28,
  `forwardDistance` 0x38, `cameraTrans` 0x40, `parentTrans` 0x48,
  `headObj` 0x50, `headTrans` 0x58, `headRigid` 0x60,
  `wheelieHeightCoeff` 0x68, `wheelieStrafeCoeff` 0x6C,
  `maxLookAngle` 0x74, `currentLookAngle` 0x78,
  `targetLookAngle` 0x7C, `mainCam` 0x88,
  `nearClipPlaneLow` 0x90, `nearClipPlaneHigh` 0x94
- `LateUpdate()` 0x1855A20, `Push()` 0x18560AC, `Reset()` 0x18562F0,
  `LookRight()` 0x18563E4, `LookLeft()` 0x18563F0,
  `LookForward()` 0x1856400
**Dipakai untuk (lokal):** toggle jarak kamera (follow distance),
  near-clip, dan tombol lihat kiri/kanan/depan — tweak tampilan lokal.

### CameraShaker — guncangan kamera (18 field, 9 method)
- `skyCamera` 0x20, `targetShakeAmount` 0x30,
  `targetRotationAmount` 0x34, `curShakeAmount` 0x3C,
  `curRotationAmount` 0x40, `damping` 0x48, `cam` 0x50,
  `camTrans` 0x58, `seed` 0x70
- `ShakeWithSpeed(float)` 0x1856918, `CrashWithSpeed(float)` 0x1856944,
  `FallShake(float)` 0x1856970
**Dipakai untuk (lokal):** toggle/peredam guncangan kamera (kenyamanan
  visual) — menonaktifkan guncangan tidak mengubah gameplay.

### Lainnya (kamera/render)
- `CameraExtensions` — helper kamera (method utilitas; detail belum
  dibaca — unverified in dump).
- `CameraTweener` — animasi kamera (tween; dipakai transisi menu).
- `GraphicsQuality` (enum) — kualitas grafis; dipakai `Globals` +
  `RoadGroup.requiredGfxQuality`.

---

## 6. UI & menu (mayoritas display-only)

### InGameHUDManager — HUD balapan (301 field, 121 method — survei parsial)
- Grup UI: `transSpeedGroup` 0x40, `transDistanceGroup` 0x48,
  `transTimeGroup` 0x50, `scoreGroupMover` 0x58, `timeLeftMover` 0x60,
  `highSpeedMover` 0x70, `comboMover` 0x78, `linearWheelieMover` 0x80,
  `speedGroupMover` 0x88, `distanceGroupMover` 0x90,
  `btnWheelieLeftMover` 0xB0, `btnWheelieRightMover` 0xB8,
  `btnGearUpLeftMover` 0xC0, `btnGearDownLeftMover` 0xC8,
  `btnGearUpRightMover` 0xD0, `btnGearDownRightMover` 0xD8
- `lblSpeedUnit` 0x158, `lblDistanceUnit` 0x160,
  `moneyEarnedPerSpeed` (privat) 0x28
**Dipakai untuk (lokal):** sumber posisi/visibilitas elemen HUD (untuk
  overlay yang tidak menutupi HUD); satuan kecepatan/jarak yang tampil.
  Detail 121 method belum dibaca satu per satu — survei parsial.

### MenuManager — menu utama (230 field, 111 method — survei parsial)
Pusat navigasi menu; dipakai memahami alur menu saja (bukan fitur).
Detail per-method belum dibaca — survei parsial.

### MenuGarageManager — garasi (102 field, 51 method — survei parsial)
- Tombol upgrade: `btnUpgradePower` 0x70, `btnUpgradeHandling` 0x78,
  `btnUpgradeBraking` 0x80; panel beli upgrade 0x88/0x90/0x98
- `colorPickerMover` 0x58, jam garasi (`clockAkrep` 0x20,
  `clockYelkovan` 0x28, `clockSaniye` 0x30)
**Dipakai untuk (lokal):** info garasi (tombol/panel upgrade, color
  picker) untuk overlay; pembelian upgrade = transaksi lokal biasa,
  bukan fitur mod (harga dari `MotorProperties`).

### MenuCareerManager / MenuCareerProgressGroup — karier
- Progres dunia/misi karier (display). Method kunci dibaca parsial:
  dipakai overlay progres karier (misi selesai/belum per dunia).

### MenuSettingsManager — pengaturan (67 field, 64 method — survei parsial)
- Pengaturan game (suara, grafik, kontrol, satuan) — dipakai daftar
  toggle resmi yang bisa ditampilkan/diubah dari overlay (tweak
  tampilan yang memang disediakan game).

### MenuQuestManager / MenuRightInfoPanelManager / MenuBankManager
- `MenuQuestManager` — panel quest harian (display progres quest).
- `MenuRightInfoPanelManager` — panel info kanan (display).
- `MenuBankManager` — bank (level bank, progres inspect, reward
  cash/gold, kapasitas): `lblBankLevel` 0x40, `sldBankProgress` 0x48,
  `lblCashReward` 0x60, `lblGoldReward` 0x68, `lblCashCapacity` 0x70,
  `lblGoldCapacity` 0x78, `btnBankUnlock` 0x80 — display saja;
  membuka bank berbayar = transaksi, bukan fitur mod.

### MenuMotorPainter / MenuColorPicker — cat & decal
- Pilihan warna/decal motor di garasi. **Dipakai untuk (lokal):**
  preview/info warna & decal yang dimiliki; membuka cat/decal berbayar
  = transaksi, bukan fitur mod.

### MenuThumbnailManager / MenuThumbnail — thumbnail garasi
- Gambar kecil motor di garasi (display).

### MenuMessageManager / MenuKeyboardManager / MenuKeyboardTutorialManager / MenuTutorialManager / MenuTutorialArrowMover
- Pesan popup, keyboard, tutorial & panah tutorial (display; tutorial
  bisa ditandai sudah dilihat — lihat `PlayerStats` flags tutorial).

### MenuDynamicButtonManager / MenuItemMover / MenuItemTweener / MenuItemScaler / MenuItemFader / MenuCanvasTweener / MenuItemAlphaState / MenuItemMoveState / AlphaTweenType / PanelLoopRotator / PanelPingPongAlpha / PanelPingPongScaler / PanelShaker / PanelShakeRotator / PanelTypeForAlpha
- Animasi & tween elemen menu (display saja; dipakai memahami
  pergerakan panel HUD/menu).

### ControllerGUIManager — GUI kontrol (19 field, 2 method)
- `AdjustControllerGUI()` 0x18B1A04 — penyesuaian tampilan kontrol
  (display tweak resmi).

### UIHandlebar — setang UI
- Setang di layar (kontrol sentuh; display/input).

### LogoManager — logo
- Logo menu (display).

### LanguageHelper / CKLocalization / CKLocalizeUI — bahasa
- Lokalisasi & teks UI (display; dipakai daftar bahasa).

### LinkOpener — pembuka link
- Membuka URL eksternal dari menu (display; bukan fitur mod).

---

## 7. Audio, efek & cuaca

### AudioManager — audio FMOD (40 field, 57 method)
- Event: `eventMenuMusic` 0x28, `eventCarCrash` 0x30,
  `eventCarImpact` 0x38, `eventTrafficPass` 0x40, `eventCarHorn` 0x48,
  `eventBusHorn` 0x50, `eventTruckHorn` 0x58,
  `eventMetalScrapeLoop` 0x60, `eventCashCount` 0x68,
  `eventExplosion` 0x70, `eventHit` 0x78, `eventLevelUp` 0x80,
  `eventFeatureUnlock` 0x88, `eventMissionReward` 0x90, `eventBuy1` 0x98,
  `eventBuy2` 0xA0, `eventClockTickLoop` 0xA8, `eventButtonClick` 0xB0,
  `eventMotorHornLoop` 0xB8, `eventWheelieEnd` 0xC0, `eventRainLoop` 0xC8,
  `eventThunder` 0xD0, `eventCoinWoosh` 0xD8
- Grup: `sfxGroup` 0xE0, `musicGroup` 0xE8; volume/mute:
  `sfxVolume` 0xF4, `sfxMute` 0xF8, `musicVolume` 0xFC, `musicMute` 0x100
- `PlayMenuMusic()` 0x1853E60, `PlayInGameMusic()` 0x1853E6C,
  `PlayCarCrash()` 0x1853E74, `PlayTrafficPass()` 0x1853E8C,
  `PlayHorn(HornType)` 0x1853EBC, `PlayMetalScrapeLoop()` 0x1853EF0,
  `StopMetalScrapeLoop()` 0x1853F38, `SetClockTickVolume()` 0x1853FF0
**Dipakai untuk (lokal):** toggle/mute SFX & musik dari overlay,
  volume per grup (tweak audio lokal yang memang disediakan game).

### EffectManager — efek partikel (34 field, 11 method)
- `rainPrefab` 0x20, `cameraRainLensPrefab` 0x28, `snowPrefab` 0x30,
  `lightCastPrefab` 0x88, `scrapeEffect` 0x98, `speedEffect` 0xB8,
  `rainTrans` 0x50, `snowTrans` 0x68, `scrapeEffectTrans` 0xA0,
  `speedEffectTrans` 0xC0, `isNight` 0x100, `isMotorInTunnel` 0x101,
  `thunderTimer` 0x104, `thunderInterval` 0x108
- `FixedUpdate()` 0x1857B78, `Update()` 0x1858494
**Dipakai untuk (lokal):** toggle efek visual (hujan/salju/efek
  kecepatan/efek gesek) untuk performa atau kejernihan tampilan.

### Weather / WeatherManager — cuaca (12 field, 4 method)
- `weatherList` 0x20, `eveningWeatherList` 0x28,
  `nightWeatherList` 0x30, material terdampak per lokasi 0x38–0x68,
  `activeWeather` (privat) 0x70
- `SetRandomWeather()` 0x18A363C, `GetActiveWeather()` 0x18A41FC
**Dipakai untuk (lokal):** overlay cuaca aktif; `SetRandomWeather`
  adalah kandidat toggle cuaca lokal — unverified in dump: belum diuji
  apakah aman dipanggil saat balapan berjalan.

---

## 8. Input & kontrol

### InputController — input balapan (15 field, 15 method)
- `tilt` 0x20, `brakePressed` 0x24, `gasPressed` 0x25,
  `leftBrakePressed` 0x27, `rightBrakePressed` 0x28,
  `leftThrottlePressed` 0x29, `rightThrottlePressed` 0x2A,
  `leftButtonPressed` 0x2B, `rightButtonPressed` 0x2C,
  `isHandlebarPressed` 0x39, `handlebarTilt` 0x3C
- `FixedUpdate()` 0x18AAE18, `OnLeftBrakePressed()` 0x18AB9E8,
  `OnLeftBrakeReleased()` 0x18AB9F4
**Dipakai untuk (lokal):** overlay status input real-time (gas/rem/
  tilt/setang) — read-only; BUKAN auto-play (tidak diusulkan: bermain
  otomatis mengubah hasil balapan, di luar cakupan visual-only).

### General — input sentuh (3 field, 107 method — mayoritas delegate)
- `Update()` 0x18A4EB4, `ProcessDrag()` 0x18A5D64
**Dipakai untuk (lokal):** memahami gesture sentuh (display/riset).

### Gesture / InputEvent / ChargedInfo / DragInfo / SwipeInfo / InputUtil
- Struktur gesture & event sentuh (riset input; display saja).

### Enum kontrol
- `ControllerType`, `SteeringType`, `ThrottleType`, `GearType`,
  `ControllerStates`, `_InputType`, `_InputState` — mode kontrol
  (display; dipakai label mode kontrol aktif).

### RTSCam — kamera RTS (display; kamera alternatif — unverified in dump:
  belum dibaca apakah aktif dipakai di game ini atau sisa).

---

## 9. Progres offline, misi, quest & save

### PlayerStats — statistik & mata uang pemain (91 field statis, 2 method)
- `totalCash` (ObscuredInt) 0x0, `totalGold` (ObscuredInt) 0x10,
  `totalKeys` (ObscuredInt) 0x20, `totalSkipVideo` 0x30,
  `extraLifeCount` 0x40, `experience` 0x50, `level` 0x60
- Skor lokal: `localMaxScoreEndlessOneWay` 0x70,
  `localMaxScoreEndlessTwoWay` 0x80, `localMaxScoreTimeTrialOneWay` 0x90,
  `localMaxScoreTimeTrialTwoWay` 0xA0
- Seumur hidup: `lifetimeCash` 0xB0, `lifetimeGold` 0xC0,
  `lifetimePlayCount` 0xD0, `lifetimePlayTime` 0xE0,
  `lifetimeDistanceTraveled` (ObscuredFloat) 0x100,
  `lifetimeOpposingLaneTimer` 0x118, `lifetimeWheelieTimer` 0x130,
  `lifetimeMaxSpeed` 0x148, `lifetimeCrashes` 0x160,
  `lifetimeOvertakes` 0x170
- Flag: `hasPermanentDoubleCash` 0x1A0, `hasPermanentRemoveAds` 0x1AC,
  `isVip` 0x1B8 (flag pembelian — HANYA dibaca, TIDAK diubah),
  `everFollowedInstagram` 0x1C4, `everSubscribedYoutube` 0x1C5,
  `everRatedMe` 0x1C6
- Quest harian: `activeQuestIndex1` 0x248, `activeQuestIndex2` 0x24C,
  `activeQuestIndex3` 0x250, `hasClaimedTodaysQuest1/2/3` 0x254–0x256,
  `quest1Count` 0x258, `quest2Count` 0x25C, `quest3Count` 0x260,
  `quest1CountMeters` 0x264, `quest2CountMeters` 0x268,
  `quest3CountMeters` 0x26C
- Bank: `bankLevel` 0x270, `bankCash` 0x274, `bankGold` 0x278
- `lastClaimedFreeMissionIndex` 0x280, `lastClaimedPaidMissionIndex` 0x284
**Dipakai untuk (lokal):** overlay statistik lengkap (cash/gold/level/
  XP/jarak seumur hidup/quest harian/bank) — READ-ONLY.
  PERINGATAN: nilai mata uang memakai `ObscuredInt`/`ObscuredFloat`
  (CodeStage AntiCheat — nilai terenkripsi di memori), jadi TIDAK bisa
  diubah dengan tulis memori biasa; pemberian mata uang/flag VIP/item
  berbayar TIDAK diusulkan (lihat OFF-LIMITS).

### SaveManager — simpan/muat lokal (3 field, 60 method)
Pasangan Load/Save untuk: `SaveAllGameData()` 0x1896620,
  `ResetGameData()` 0x1896618, bahasa (0x18966D0/0x1896A38), pilihan
  (0x1896AC8/0x1896BC8), misi (0x1896CAC/0x1897074), keyboard
  (0x1897430/0x1897670), kontroler (0x1897848/0x18979B0), audio
  (0x1897AE8), pengaturan (0x1897C30/0x1897DD4), statistik iklan
  (0x1897FA8/0x18981DC), PlayerStats (0x189834C/0x18989FC), bank
  (0x1899A0C/0x1899AE8), quest (0x1899BB0/0x1899F7C + SaveQuest1/2/3Count
  0x189A110/0x189A1BC/0x189A268), tutorial (0x189A314/0x189A560),
  statistik motor (0x189A740/0x189AB64/0x189AECC/0x189AF24),
  motor terpilih (0x189AFAC/0x189B04C), sarung tangan
  (0x189B16C/0x189B2EC), LockInfo (0x189B454/0x189B730), waktu kit
  (starter/cash/gold/bike prom).
**Dipakai untuk (lokal):** memahami struktur save lokal (untuk fitur
  backup/restore save SENDIRI — file save milik pemain sendiri, offline).
  Pengeditan isi save untuk memberi mata uang/item berbayar TIDAK
  diusulkan. `ResetGameData` berbahaya (menghapus semua) — hanya
  dicatat, tidak dipakai.

### SaveHelper — tulis/baca key-value (7 field, 18 method)
- `DeleteAllKeys()` 0x1895D00, `WriteToDisc()` 0x1895D08,
  `HasKey()` 0x1895F60, `SaveString()` 0x1895F60, `SaveInt()` 0x1895FBC,
  `SaveFloat()` 0x189602C, `SaveBool()` 0x189609C, `SaveColor()`
  0x1896128, `SaveVec3()` 0x18961F8, `LoadString()` 0x18962C8,
  `LoadInt()` 0x189630C, `LoadFloat()` 0x1896364, `LoadBool()`
  0x18963BC, `LoadColor()` 0x189643C, `LoadVec3()` 0x1896528
**Dipakai untuk (lokal):** kunci-kunci pengaturan & progres (display /
  backup); format penyimpanan = PlayerPrefs-like, dengan kemungkinan
  enkripsi string (lihat StringEncryptor).

### SaveConstants — konstanta key save
- Nama-nama key save (display/riset; detail belum dibaca satu per satu
  — survei parsial).

### StringEncryptor / XOREncryptionDecryption — enkripsi string save
- `EncryptStr()` 0x1895DA0, `DecryptStr()` 0x1895E80,
  `EncryptStrControl()` 0x1895E10, `DecryptStrControl()` 0x1895EF0
**Dipakai untuk (lokal):** memahami bahwa sebagian string save
  terenkripsi (relevan untuk fitur backup/restore save yang benar, bukan
  untuk mengubah isinya).

### Mission / MissionManager — misi karier (16 field / 5 field, 19 method)
- Mission: `missionType` 0x10, `missionState` 0x14,
  `highestScore` 0x18, `totalDistanceInMeters` 0x1C,
  `totalDistanceInKm` 0x20, `cpCount` 0x24, `cpTimeIncrement` 0x28,
  `duration` 0x2C, `targetCount` 0x30, `goldReward` 0x34,
  `cashReward` 0x38, `timeForGold` 0x3C, `location` 0x40,
  `difficultyMode` 0x44, `timeOfDay` 0x48, `missionDifficulty` 0x4C;
  `IsCompleted()` 0x187FB00, `IsLocked()` 0x1886728, `IsReady()`
  0x18867BC, `IsEasy/Normal/Hard()` 0x1886850/0x18868E4/0x1886978,
  `GetCashReward()` 0x1886A0C, `GetGoldReward()` 0x1886AF4
- MissionManager: `missionList` 0x20, `activeWorldIndex` 0x28,
  `selectedWorldIndex` 0x2C, `activeMissionIndex` 0x30,
  `selectedMissionIndex` 0x34; `GetLastAvailableMissionForWorld()`
  0x188B444, `GetCompletedMissionCount()` 0x188B590,
  `CalculateActiveIndex()` 0x188B6A4, `CalculateDifficulties()`
  0x188B868, `IsDifficultyImpossible/Easy()` 0x188BC3C/0x188BCB4,
  `GetNeededPowerFromDifficulty()` 0x188BBD0,
  `GetRecommendedPowerFromDifficulty()` 0x188BBB4,
  `GetMissionDescription()` 0x188BCDC, `GetSelectedMission()` 0x188BDA4,
  `GetNextMission()` 0x188BE1C, `AreAllMissionsCompleted()` 0x188BF38
**Dipakai untuk (lokal):** overlay tracker misi (misi aktif, target,
  reward, kesulitan vs kekuatan motor, misi berikutnya) — read-only.
  Membuka misi terkunci = progres berbayar/waktu, TIDAK diusulkan.

### Quest / QuestManager — quest harian (3 field / 2 field)
- Quest: `questType` 0x10, `targetCount` 0x14, `useMetersCount` 0x18;
  `GetProgressPercentage()` 0x1892D7C, `IsCompleted()` 0x1892DAC,
  `GetDescription()` 0x1892DDC, `GetProgressText()` 0x1892DEC
- QuestManager: `questList` 0x20, `loopStartIndex` 0x28;
  `GetNextQuestIndex()` 0x18940E4
**Dipakai untuk (lokal):** overlay progres quest harian (deskripsi +
  persentase, dari `PlayerStats.quest*Count`) — read-only.

### LockInfo — syarat buka konten (56 field statis, 17 method)
- Syarat level & harga tiap mode/lokasi/waktu, mis.
  `hornLevelRequirement` 0x0, `wheelieLevelRequirement` 0x4,
  `lookLevelRequirement` 0x8, `endlessOneWayLevelOwned` 0xC +
  `endlessOneWayLevelRequirement` 0x10, `highwayEveningOwned` 0x3C +
  `highwayEveningPrice` 0x40 + `highwayEveningLevelRequirement` 0x44,
  dst. untuk desert/city/winter × noon/evening/night.
**Dipakai untuk (lokal):** overlay "apa yang belum kebuka + syaratnya"
  (display). Mengubah flag `*Owned` = membuka konten berbayar/level,
  TIDAK diusulkan.

### MenuCashAnimator — animasi uang
- Animasi pertambahan uang di UI (display).

---

## 10. Utilitas, display & misc lokal

- `Globals` — setting global statis: `speedUnit` 0x7C (km/h vs mph —
  dipakai overlay satuan), `driveOnLeft` 0x80 (lalu lintas kiri/kanan),
  `showWeatherEffects` 0x81, `graphicsQuality` 0x78,
  `forceHighQuality` 0xB8, `hasNotch` 0x70, `notchShiftValue` 0x74,
  `gloveCount` 0x84, `selectedGloveIndex` 0x88, `gloveOwningList`
  0x90, `glovePrices` 0x98, `gamesPlayed` 0xAC,
  `AdjustGraphicsQuality()` 0x185AA14, `AdjustNotch()` 0x185A688,
  `InitializeSettings()` 0x185A754 — tweak tampilan resmi.
- `Utility` — helper statis: `LoadScene()` 0x18A2834,
  `LoadMenuScene()` 0x18A28D8, `StartGame()` 0x18A2918,
  `PauseGame()` 0x18A2A98, `ResumeGame()` 0x18A2B54,
  `IsGamePaused()` 0x18A2C0C, `KmhToMph()` 0x18A2C30,
  `KmToMiles()` 0x18A2C40, `SecondsToStr()` 0x18A2CC4,
  `GetContinuePrice()` 0x18A3010, `CalculateLevelAwardCash/Gold()`
  0x18A31A0/0x18A3248, `CalculateExpToNextLevel()` 0x18A3268,
  `CalculateExpRewardForMission()` 0x18A3280 — konversi & hitung
  resmi untuk overlay (satuan, waktu, harga lanjut, reward level).
- `MainManager` — `get_SmartRealTime()` 0x187C2F0 (waktu real —
  dipakai overlay jam; bukan pengubah waktu).
- `SceneLoader` — loading scene (display/riset).
- `AssetBundleManager` — bundle aset (hanya `.ctor` di dump; dipakai
  memahami pemuatan aset, bukan fitur).
- `FPSCounter` — `FramesPerSec` 0x20, `frequency` 0x24, `fps` 0x28,
  `OnGUI()` 0x1858880 — overlay FPS bawaan game (tinggal ditampilkan
  / dibaca, bukan dibuat dari nol).
- `TakeScreenshot` — hanya `.ctor` di dump (0x189CBC0); kemungkinan
  stub/sisa — unverified in dump, jangan diandalkan.
- `DebugStreamer` — streaming debug (display/riset; detail belum
  dibaca).
- `ObjectCountPair` — pasangan objek+jumlah (struktur data umum).
- `ByteReader` — baca byte (utilitas; detail belum dibaca).

---

## 11. Engine & plugin pendukung (singkat — dipakai sebagai alat, bukan target)

- `UnityEngine.Object` — `get_name()` RVA 0x3325094 (nama GameObject,
  dipakai nama model ESP v1.4); `EnsureRunningOnMainThread()` RVA
  0x3324FAC (bukti API Unity wajib main thread — akar crash ESP v1.3);
  `m_CachedPtr` 0x10.
- `UnityEngine.Transform` — `get_position()` (dipakai ESP);
  `UnityEngine.Camera` — `WorldToScreenPoint()`, `get_main()`
  (dipakai ESP); `UnityEngine.Screen` — `get_width()`/`get_height()`.
- `UnityEngine.BoxCollider` — `get_center()` 0x337E06C,
  `get_size()` 0x337E21C (tinggi box ESP v1.4, dengan cek class dulu).
- `UnityEngine.Physics` / `Collider` — `get_attachedRigidbody()`
  0x337ED38 (fisika; bukan target fitur).
- `UnityEngine.Time` — HANYA dibaca (waktu); `timeScale` TIDAK
  disentuh (detektor).
- `UnityEngine.QualitySettings` / `Application` — kualitas & info
  aplikasi (display).
- `DG.Tweening` (+ Plugins/Core) — tween animasi UI (alat animasi
  overlay, bukan target).
- `FMOD` / `FMODUnity` / `FMOD.Studio` — mesin audio (dipakai
  `AudioManager`; bukan target).
- `UnityEngine.AddressableAssets` + `ResourceManagement` — pemuatan
  aset async (dipakai `SaveHelper` memuat font; bukan target).
- `IngameDebugConsole` — konsol debug dalam game (alat riset;
  unverified in dump: belum dibaca apakah aktif di build rilis).
- `CFX_*` / `WFX_*` / `ProFlare*` / `SparksExecutioner` /
  `ParticleScaler` — paket partikel/flare (efek visual; `WFX_BulletHoleDecal`
  kemungkinan sisa asset pack yang tidak dipakai game balap ini).
- `ch.sycoforge.Decal` (+ `RuntimeDecalCombiner`, `InfoBubble`) —
  sistem decal (bekas ban / stiker jalan — display).
- `Echo*` (EchoLogin, EchoEyeController, EchoPoolManager, dsb.) —
  framework login/efek pihak ketiga (bukan target; material
  `affectedMaterialsEchoLogin` di WeatherManager merujuk ke sini).
- `Newtonsoft.Json` — JSON (alat; dipakai pembacaan config).
- `TMPro` — TextMeshPro (UI teks; dipakai label overlay game).
- `UnityEngine.UI` / `UIElements` — UI bawaan (alat).
- `CodeStage.AntiCheat.ObscuredTypes` (`ObscuredInt/Float/Bool`) —
  nilai terenkripsi (lihat `PlayerStats`); `InjectionDetector`
  (TypeDefIndex 5697) & `SpeedHackDetector` (5699) — detektor yang
  WAJIB dihindari (jangan sentuh `Time.timeScale`, jangan inject
  assembly asing, jangan tulis nilai obscured mentah-mentah).

---

## 12. OFF-LIMITS (server/online) — dicatat saja, tanpa usulan pemakaian

- `GPGSIds` — ID leaderboard/achievement Play Games (server).
- `TPGameServicesManager` + handler `GPGSAuthenticate*` /
  `GPGSUserSignOut` / `GPGSAvatarInfoChanged` — login & layanan
  Play Games (akun pemain lain/server).
- `MenuCloudManager` — save cloud (server; sinkronisasi akun).
- `TPIAPManager` / `TPIAPListener` / `IAPRequestState` /
  `IAPPurchaseState` / `PurchaseComplete/Fail/RestoreHandler` /
  `PopupIAPManager` / `MenuStoreManager` — pembelian dalam aplikasi
  (barang berbayar; tidak disentuh).
- `MenuFreeCashManager` — cash gratis via iklan video / follow /
  rate (reward iklan; memberi reward tanpa menonton = bypass iklan).
- `AdManager` / `TPAdmobManager` / `AdmobVideo*Handler` /
  `InterstitialType` / `VideoAdLocation` / `PopupAdCacher` (di
  GameManager) — sistem iklan (server).
- Namespace `UnityEngine.Purchasing` (257 class) — IAP Unity (server).
- Namespace `GooglePlayGames` / `GooglePlayGames.BasicApi` — Play
  Games (server).
- Namespace `Firebase` / `Firebase.Platform` — backend Firebase (server).
- Namespace `GoogleMobileAds.*` — AdMob (server).
- Namespace `UnityEngine.SocialPlatforms` — platform sosial (server).
- `GameManager.GetScore()` → rantai `PostScores` → `PostToLeaderboard`
  (42 ID leaderboard di dump) — pengali skor DIKECUALIKAN perintah
  user, tidak diusulkan dalam bentuk apa pun.
- `PlayerStats.isVip` / `hasPermanentDoubleCash` /
  `hasPermanentRemoveAds` — flag pembelian (hanya dibaca, tidak diubah).
- `MotorProperties.isIAP` / `iapId_*` / `isGold` — penanda item
  berbayar (hanya dibaca, tidak dibuka).

---

## 13. Peluang fitur lokal paling menarik (ringkas)

1. **Faktor km/h resmi** — `GameStateManager.msToKmhFactor` (statis
   0x1C): ganti asumsi ×3,6 di label kecepatan ESP v1.4 dengan faktor
   resmi game (perlu resolve static storage saat runtime).
2. **Batas terrain & riset noclip** — `GameStateManager.terrainLeftBorder`
   0x28 / `terrainRightBorder` 0x2C + `TrafficSegment.lanes` /
   `laneWidth` / `oppositeLanes`: peta batas jalan untuk memahami
   kenapa motor "kembali" saat noclip dimatikan dan kenapa kecepatan
   tinggi mentok di pembatas (kaitkan dengan cabang scrape
   `MotorMover.Update` 0x188E530).
3. **Overlay telemetri penuh** — `MotorMover` GetGear/GetRpm/
   GetSpeedKmh/GetPosition + `curStrafe`/`wheelieState`/
   `curWheelieCharge`/`isScrapingLeft/Right`: HUD RPM-gigi-kecepatan-
   wheelie-scrape tanpa mengubah gameplay.
4. **ESP diperkaya** — `TrafficMover.laneId` 0x84, `trafficIndex` 0x7C,
   `hornType` 0x44, sein 0xF9/0xFA, `TrafficManager.
   GetFrontVehicleDistanceAndSpeed` 0x189F968: label lajur + klakson +
   peringatan kendaraan depan.
5. **Toggle densitas lalu lintas lokal** — `TrafficManager.
   targetTrafficVehicleCount` 0x44 + `GameStateManager.
   trafficDensityForRelaxMode` 0x18: kurangi/tambah kendaraan (visual
   + gameplay lokal; uji keamanan runtime dulu).
6. **Tweak kamera lokal** — `CameraMover.currentFollowDistance` 0x24,
   `LookLeft/Right/Forward`, `nearClipPlaneLow/High`; peredam
   `CameraShaker` (kenyamanan visual, tanpa efek gameplay).
7. **Overlay misi & quest** — `MissionManager` (misi aktif, target,
   reward, kesulitan vs kekuatan motor) + `QuestManager` +
   `PlayerStats.quest*Count`: tracker progres read-only.
8. **Overlay statistik pemain** — `PlayerStats` (cash/gold/level/XP/
   jarak seumur hidup/quest/bank) + `Utility` (konversi satuan, harga
   lanjut, reward level): panel statistik read-only.
9. **Toggle cuaca & efek** — `WeatherManager.GetActiveWeather` /
   `SetRandomWeather`, `EffectManager` (hujan/salju/efek kecepatan),
   `AudioManager` (mute/volume per grup): panel suasana lokal.
10. **Info garasi & syarat buka konten** — `MotorManager` +
    `MotorProperties` (statistik + harga upgrade) + `LockInfo`
    (syarat level/harga tiap mode/lokasi): overlay "apa yang belum
    kebuka + syaratnya", display saja.

## 14. Yang TIDAK bisa ditentukan dari dump saja (butuh uji runtime)

- Cara resolve alamat static storage IL2CPP (untuk semua field
  `GameStateManager`/`PlayerStats`/`Globals`/`LockInfo` statis) —
  dump hanya memberi offset logis, bukan alamat.
- Apakah `curSpeed` (TrafficMover & MotorMover) memang m/s — diduga
  kuat dari `msToKmhFactor`, tapi isi `GetSpeedKmh` belum dibaca.
- Nama prefab kendaraan persis dari `Object.get_name` (apakah
  "Sedan"/"Truck" atau generik) — hanya ketahuan di device.
- Apakah `TrafficVehicle.collider` selalu `BoxCollider` — v1.4 sudah
  memakai cek nama class runtime untuk ini.
- Apakah mengubah `targetTrafficVehicleCount` / memanggil
  `SetRandomWeather` / `CameraMover` mid-run aman (tidak crash /
  tidak merusak state balapan).
- Isi lengkap `InGameHUDManager` (121 method) & `MenuManager`
  (111 method) & `MenuSettingsManager` (64 method) — survei parsial
  saja di katalog ini.
- Apakah `IngameDebugConsole` aktif di build rilis, apakah `RTSCam`
  dipakai, dan apakah `TakeScreenshot` berfungsi (hanya `.ctor`).
- Perilaku pasti "teleport balik" saat noclip dimatikan & kenapa
  kecepatan tinggi mentok di pembatas — kandidat penyebab ada di
  `MotorMover.Update` + batas terrain, tapi urutan pastinya butuh
  uji device (ini ranah perbaikan v1.5, bukan katalog).
- Arti tiap `PlayerStats` flag tutorial & `SaveConstants` key —
  belum dibaca satu per satu.
