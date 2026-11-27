# Pocong Outbreak — full dump + static REA

- Package: `com.owngames.pocongoutbreak`
- Version: **1.6.3.6 / versionCode 43** (verified from the APK manifest itself;
  matches the APKPure listing)
- Source: APKPure XAPK, SHA-256
  `a3db72ed9e4833b0c03c90fee6a899555702ef55e7ed5a3e877f43b2f8da12a9`
  (32,668,040 bytes; base APK 20,655,442 bytes + config splits, no OBB)
- minSdk 21, targetSdk 34
- Main activity: `com.owngames.pocongoutbreak.MainActivity`
- Analysis: static only — the APK was never installed or run.
- Date: 2026-11-27

## Permissions (13)
INTERNET, ACCESS_NETWORK_STATE, VIBRATE, WAKE_LOCK, FOREGROUND_SERVICE,
SCHEDULE_EXACT_ALARM, WRITE_EXTERNAL_STORAGE, BILLING, AD_ID,
ACCESS_ADSERVICES_TOPICS, ACCESS_ADSERVICES_AD_ID,
ACCESS_ADSERVICES_ATTRIBUTION, BIND_GET_INSTALL_REFERRER_SERVICE.

## Engine — OwnGames native engine (NOT Unity, NOT Godot)
- `libnative-lib.so` 4.45 MB — the game code (arm64-v8a only).
- `libownengine.so` 2.27 MB — OwnGames engine (render, IO, save, JNI bridge).
- `libownbox2d.so` — Box2D physics. `libownlibxml.so` — XML parsing.
- All `.so` files are stripped of `.symtab`, but `.dynsym` carries full
  mangled C++ names (3,890 FUNC entries in libnative-lib, 3,400 with
  size) — the whole game is effectively symbolized.
- Java side is thin: 14,607 dex classes, only 263 `com.owngames.*`
  (OwnConnect SDK + OwnEngine IO/JNI glue). Game logic is native C++.
- No OpenSSL/DES in native libs — crypto is Java-side (see Save).
- Assets: 2,225 files, 28 MB, all in obfuscated dirs with obfuscated
  names (`.oga` 1,181 / `.ogt` 947 / `.ogm` 93 / `.ogf` 3). Content is
  NOT plain Ogg (magic bytes scrambled) — assets are obfuscated/
  encrypted at rest. One asset is `audience_network.dex` (Facebook
  ads SDK, 4.86 MB, standard dex 035) — not game code.

## Game mode — single-player OFFLINE vs AI waves. NO live multiplayer.
Evidence:
- Gameplay is wave-based vs AI pocong: `GamePlayScene::addPocong`,
  `Wave::getJumlahPocong`, `GamePlayScene::getNearestPocong(OwnView*)`.
  Pocong types are local classes (Tall, Badut, Kembar3Lepasan, Payung,
  Kangguru, TearGas, FlashBang, Merchant, Boss).
- Only game host in the whole dex: `https://ownconnect.tahoogle.com/Forum/OCSDK2/`
  (OwnConnect account/forum SDK: login, register, contact, report,
  password, gift). No gameplay state goes there.
- No websocket / socket.io / realtime host anywhere in dex or native.
- Google Play Games multiplayer API strings exist in dex but are DEAD
  legacy code (Google deprecated realtime multiplayer in 2020;
  `STATUS_MULTIPLAYER_DISABLED` present). Play Games is used only for
  achievements / leaderboard (score submission) / cloud save.
- network_security_config.xml allows cleartext to 103.195.90.138,
  127.0.0.1, 13.250.187.133 (OwnConnect server IPs) — nothing else.
- Play Store tags: Single player, Offline.
- **Conclusion: all four cheats below are local-only; there is no
  real-player opponent to affect. Scope for any future build is
  solo/bot/local.**

## Protections — effectively none in the game's own code
- No root detection (no magisk/su checks in native code; the
  `isRooted=`/`isEmulator=` strings in dex belong to an ads/analytics
  SDK log format, not game logic).
- No emulator detection, no Frida/Xposed detection, no tamper check.
- No Play Integrity / SafetyNet in game code (attestation strings in
  dex are all Google Mobile Ads `gads:`).
- No certificate pinning: no `<pin-set>` in network_security_config.xml
  (the "CertificatePinner" strings are OkHttp library code, unused
  by the game); cleartext is even permitted for the game-server IPs.
- String obfuscation: asset filenames + save JSON keys are gibberish
  (see Save), but code symbols are NOT obfuscated (full dynsym names).
- IAP exists (Google Play Billing + `GameData::addIAP`, `IAPData`) —
  real purchases; NOT in cheat scope.

## Cheat audit (audit only — nothing built)
All four are CLIENT-SIDE and feasible. Full function list + offsets
in `cheat-functions.txt`. Offsets are libnative-lib.so file offsets
(vaddr, PIE base 0); runtime address = base + offset.
- **Auto aim** — very feasible. `GamePlayScene::getNearestPocong(OwnView*)`
  @ 0x1749dc; `Shooter::isKenaTarget(OwnView*, bool)` @ 0x298500.
- **High damage** — feasible. `GameData::getDamage()` @ 0x30dab4;
  `Bullet::hit(OwnView*)` @ 0x29f61c; `Pocong::mati(int, string)` @ 0x26d98c;
  `Pocong::getHp()` @ 0x26fdd8.
- **Bullet track** — feasible (built-in homing exists).
  `Bullet::setMissile(OwnTarget*, OwnView*)` @ 0x29fedc;
  `Bullet::needResetTarget()` @ 0x2a00fc.
- **God mode** — very feasible. `GameData::damageHeart(int)` @ 0x31070c;
  `GameData::getCurHeart()` @ 0x31067c; `GameData::setCurHeart(int)` @ 0x311e58.
- No server-side validation of aim/damage/HP: all local GameData state.

## Save data (audit — for the Tahu Bulat Save Tool merge)
Full detail in `save-format.md`; decryptor in `pocong_save_decrypt.py`.
- Files (app internal files dir): `save_data_beta.owndata` and
  `save_data_rilis.owndata`.
- Crypto: **DES/ECB/PKCS5Padding**, key **`ufajdm2d3`** (effective DES
  key = first 8 bytes, `ufajdm2d`). Proven from Java
  `com.owngames.ownengine.io.OwnSaveData` + native
  `GameData::GameData` constructing
  `OwnSaveData("save_data_beta.own", "ufajdm2d3")` and
  `OwnSaveData("save_data_rilis.own", "ufajdm2d3")`.
  Same OwnSaveData scheme as Tahu Bulat / Food Truck, different pair.
- Plaintext: JSON with obfuscated field names (~35 observed keys,
  e.g. `hansufesoas`, `akufhaeyfa`, `uabfeyafh2..6`, plus readable
  `weapon`). Key→meaning mapping not yet established (needs a real
  decrypted save).
- Save triggers: nine `Pocong*::mati()` variants call
  `OwnSaveData::save()`; load happens in the GameData constructor.
- ~200 OwnSaveData ctor sites game-wide (per-feature saves) — only
  the main GameData pair is mapped here.

## Files in this dump
- `README.md` — this report
- `manifest.txt` — manifest (package, version, SDK, permissions, components)
- `dex-classes.txt` — 14,607 dex classes
- `dynsym-native-lib.txt`, `dynsym-ownengine.txt` — dynamic symbol maps
- `strings-dex.txt`, `strings-native-lib.txt`, `strings-ownengine.txt`
- `plt-native-lib.txt` — PLT stub -> imported symbol map
- `dis-gamedata-doload.txt`, `dis-gamedata-dosave.txt`, `dis-dosave-full.txt`
  — GameData::doLoad / doSave disassembly (ARM64, capstone)
- `dis-ownsavedata-ctor.txt`, `dis-ownsavedata-load.txt`,
  `dis-save-char.txt`, `dis-save-str.txt`, `dis-load.txt`
- `cheat-functions.txt` — cheat audit (functions + offsets)
- `save-format.md` — save format + crypto + keys
- `pocong_save_decrypt.py` — DES/ECB save decryptor/re-encryptor
  (round-trip verified; needs a real save file from a device)
- `hosts-endpoints.txt` — hosts + endpoints + multiplayer verdict
- `disasm.py`, `pltmap.py`, `scan_calls.py`, `parse_manifest.py`,
  `dump_java.py` — tooling used for this REA (capstone + pyelftools)

## Source deletion
Per the standing rule (22 Nov 2026): after this dump + REA was pushed
and verified, the source XAPK/APK and the full extraction were deleted
totally. Only this dump remains.
