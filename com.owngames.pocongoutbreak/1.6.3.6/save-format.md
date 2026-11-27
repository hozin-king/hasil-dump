# Save format — Pocong Outbreak 1.6.3.6 (com.owngames.pocongoutbreak, code 43)

## Location & files
- App internal files dir: `/data/data/com.owngames.pocongoutbreak/files/`
- Two main save files (both constructed in `GameData::GameData`,
  libnative-lib.so @ 0x2f9800; construction sites ~0x2fd6c0-0x2fd74c):
  - `save_data_beta.owndata`  (OwnSaveData @ GameData+0x88)
  - `save_data_rilis.owndata` (OwnSaveData @ GameData+0x80)
- Java side appends "data": file = fileName + "data", i.e. the ctor
  arg is `save_data_beta.own` / `save_data_rilis.own` and the on-disk
  name gains the "data" suffix. Opened via Context.openFileInput /
  openFileOutput (CipherInputStream / CipherOutputStream).

## Crypto (proven from code, not assumed)
- Algorithm: **DES/ECB/PKCS5Padding** — from Java
  `com.owngames.ownengine.io.OwnSaveData` (classes.dex):
  `Cipher.getInstance("DES/ECB/PKCS5Padding")`, `DESKeySpec` built
  from the 2nd ctor arg as UTF-8 bytes.
- Key: **`ufajdm2d3`** (same for both files). DES uses the first 8
  bytes -> effective key **`ufajdm2d`** (hex `7566616a646d3264`).
- Same scheme as Tahu Bulat / Food Truck (OwnGames OwnSaveData),
  different filename/key pair.
- Old installs: `loadNotEncrypted()` migrates legacy plaintext saves
  (file may exist unencrypted on old devices — try plain JSON first).
- Native bridge: `OwnSaveData` C++ (libownengine.so, ctor @ 0xf4c74,
  save @ 0xf4dd0, load @ 0xf4f28) is a JNI bridge to Java
  `OwnUtilities.doSave/doLoad`. No OpenSSL/DES in native libs.

## Plaintext format
- JSON (UTF-8 string), built by `GameData::doSave()` (0x300b64) and
  read by `GameData::doLoad()` (0x2f4ed4). Log line seen in doLoad:
  `PRINT DAILYMISSION NEWSAVEDATA`.
- Field names are **obfuscated gibberish** (single JSON object, one
  key per field). Observed keys (doSave writes, doLoad reads):
  hansufesoas, ajlfilefd, yhuefadefe, ukesfhidas, akufhaeyfa,
  uafyfeas, auhgenyfas, akufnede, uabfeyafh2, uabfeyafh3,
  uabfeyafh4, uabfeyafh5, uabfeyafh6, whfaufefe, akfbnefes,
  sejfsejsd, luhfnseifo, aifnefnis, aufhneuas, iahfnyefgs,
  afnueafhis, auhfneusfs, sefsuhsse, aufhysefasce, aufhysefasce2,
  afhnesade, afnrusde, allfeufs, uafhafefasd, ayfgesufjfs,
  fufaiioefes, iefiodakasd, nbltaspiba — plus one readable key:
  `weapon`.
- Key->meaning mapping is NOT yet established (needs a decrypted
  real save + correlation with GameData getters). Known GameData
  getters that read these fields include money/diamond/energy/
  level/exp/heart/stage/skills/equips/fortress/battle-pass state.
- Values paired in doSave with asset names (e.g. `terialPet.png`,
  `diamond_4`, `skill_permanent.xml`, `mission.xml`, `atk_cat`,
  `list_fortress.xml`) — the JSON stores unlock/equip references.

## Persistence triggers (observed)
- `OwnSaveData::save(string)` PLT 0xd9530 is called from nine
  `Pocong*::mati()` variants (Tall, Badut, Kembar3Lepasan, Payung,
  Kangguru, KangguruChild, Merchant, TearGas, FlashBang) — killing a
  pocong persists progress.
- `OwnSaveData::load()` PLT 0xdd940 is called from
  `GameData::GameData` (ctor, 0x2fd80c) and
  `PopUpMerchant::initialize/onEnterScreen` (merchant state).
- ~200 OwnSaveData ctor call sites exist game-wide (per-feature
  saves: merchant, settings, etc.) — same DES/ECB scheme, different
  filename/key pairs; only the main GameData pair is mapped here.

## Decrypt / re-encrypt
- Script: `pocong_save_decrypt.py` (in this folder; DES/ECB via
  pycryptodome, openssl CLI fallback). Round-trip verified.
  `python3 pocong_save_decrypt.py save_data_rilis.owndata`
- Editing target for the future Save Tool merge: money, diamonds,
  energy, level, exp, heart, stage, skill/equip/fortress unlocks.
  (IAP currency bought with real money must NOT be faked — the
  save editor must only edit locally-earned values, same rule as
  the Tahu Bulat Save Tool.)
