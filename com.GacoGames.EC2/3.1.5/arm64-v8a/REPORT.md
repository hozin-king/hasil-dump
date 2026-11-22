> Catatan arsip: APK yang dianalisis adalah repack/mod (bukan resmi Gaco Games) — sertifikat Android Debug, ApkSignatureKillerEx. APK tidak pernah di-install/dijalankan.

# REA — Epic Conquest 2 v3.1.5 MOD APK (liteapks.dev repack)

**Analysis date:** 2026-11-20 · **Analyst:** REA subagent · **Mode:** static analysis ONLY — the APK was never installed, never run, and no mod/injector was built from it.

## 0. Header facts

| Field | Value |
|---|---|
| File | `Epic-Conquest-2-v3.1.5-mod.apk` (in `~/workspace/rea-epic-conquest-2/`) |
| Size | 220,928,308 B (210.7 MiB) |
| SHA-256 | `b36ad4a93aa941edae515f77136d9e13ac2b444c9187270b51ad698a7202e530` |
| ZIP entries | 1,090 files, 373,044,266 B uncompressed |
| Source | `[tautan unduhan dihapus — minta ke Alyaa]` (needed a `Referer` header; direct curl got Cloudflare 403) |
| Package | `com.GacoGames.EC2` |
| Version | versionName `3.1.5`, versionCode `509` |
| SDK | minSdk 25, targetSdk 37, compileSdk 37 (platformBuildVersionName `17`) |
| Engine | Unity **6000.3.8f1**, IL2CPP (no Mono DLLs; `assets/bin/Data/Managed/` holds only `Metadata/` + `Resources/`) |
| Build GUID | `7f1ad9d6579248bcacb0035839a276da` (from `boot.config`) |
| Signer | **Android Debug certificate** — `CN=Android Debug, OU=Android, O=US, L=US, ST=US, C=US`; SHA-256 `1e08a903aef9c3a721510b64ec764d01d3d094eb954161b62544ea8f187b5953`; SHA-1 `5d08264b44e0e53fbccc70b4f016474cc6c5ab5c`; RSA 2048; verified with v2 + v3 schemes (v1 false) |
| Manifest date | 2026-10-10 (signing/packaging date; most original files carry the Unity epoch `1981-01-01`) |

**First-pass verdict on the signer alone:** the official Gaco Games release is signed with the developer's Play key. A repack signed with the generic **Android Debug** key is, by definition, not the official build. Everything below is consistent with a third-party repack.

## 1. Dump inventory

Work products: `dump/apktool/` (apktool decode: manifest, res, smali, smali_classes2, smali_classes3), `dump/dex/` (raw DEX files), `dump/so/lib/arm64-v8a/` (raw .so files), `dump/jadx-classes3/` (jadx output for the injected DEX), `dump/assets/` (extracted `global-metadata.dat`).

### 1.1 DEX files

| DEX | Size | Classes | Strings | Contents |
|---|---|---|---|---|
| `classes.dex` | 8,073,812 B | 8,590 | 53,131 | Google Play services, AndroidX, Discord SDK, `com.gacogames.ec2bridge`, billing (`com.android.billingclient`) |
| `classes2.dex` | 9,548,560 B | 8,624 | 61,272 | IronSource ads, Unity3D player/ads, Kotlin + kotlinx.coroutines, OkHttp, `gatewayprotocol.v1` |
| `classes3.dex` | **14,856 B** | **14** | 267 | **Injected by the modder — see §2** |

Total: 17,228 classes. `classes3.dex` is the only DEX that is not part of a normal Unity build of this game (Unity builds of this size normally ship 2 DEX files; the 14-class third DEX is the modder's loader + signature killer).

### 1.2 Native libraries (arm64-v8a only)

| Library | Size | Notes |
|---|---|---|
| `libil2cpp.so` | 94,217,584 B | Game code (IL2CPP). Exports the standard IL2CPP API (`il2cpp_domain_get_assemblies`, `il2cpp_class_from_name`, `il2cpp_class_get_method_from_name`, `il2cpp_runtime_invoke`) — the API surface the menu resolves at runtime to hook game methods. Timestamp `1981-01-01` (untouched-looking; cannot be proven without the official APK). |
| `libunity.so` | 24,516,624 B | Unity runtime, stock. |
| `libdiscord_partner_sdk.so` | 8,645,792 B | Discord SDK (voice/social). |
| `libkrisp_wrapper.so` | 1,509,264 B | Krisp noise suppression (Discord voice). |
| `libunitycoherencenative.so` | 493,112 B | Unity Coherence (multiplayer/netcode lib, stock). |
| `lib_burst_generated.so` | 128,432 B | Unity Burst, stock. |
| `libmain.so` | 6,696 B | Unity `libmain` (loads `libunity.so`/`libil2cpp.so`); stock strings, no menu references. |
| **`libmenu.so`** | **1,569,640 B** | **Injected mod menu — see §2.3.** BuildID `c9c6a72a321547679bf3873aaa3549daf3056f99`, **stripped**, and the ONLY `.so` dated `2026-10-10 13:55` (packaging time) while every other lib is dated `1981-01-01`. |

### 1.3 Assets (479 entries)

Standard Unity 6000 layout: `assets/aa/Android/` (Addressables bundles — `startup_units_hero_assets_all_…bundle` 24.6 MB, `startup_graphics_assets_all_…bundle` 16.0 MB, per-quest bundles), `assets/bin/Data/` (266 files: `global-metadata.dat` 14,982,460 B, `globalgamemanagers` + splits, `boot.config`, `ScriptingAssemblies.json`), `assets/iads/` (IronSource ad controller), `assets/ad-viewer/` (OMID viewability JS), `assets/thz/` (Krisp VAD models), `assets/dexopt/baseline.prof`. No extra files attributable to the modder were found in `assets/` (the mod lives entirely in `classes3.dex` + `libmenu.so`).

Game economy symbols recovered from `global-metadata.dat` (game's own strings, not mod evidence): `ruby`, `ruby_1`…`ruby_6`, `ruby_pack_double_1`…`ruby_pack_double_6`, `rubyPrice`, `MenuRubyPack`, `MenuPremiumPass`, `PremiumPassObjectState`, `valueGold`, `requiredGold`, `sell_gold`, `title_diamond`. So the premium currency is **ruby** (6 IAP packs + double-ruby variants) and the soft currency is **gold**, with a **Premium Pass** product.

### 1.4 Manifest: permissions and components

**Permissions (15):**
`INTERNET`, `ACCESS_NETWORK_STATE`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `com.google.android.gms.permission.AD_ID`, `com.android.vending.BILLING`, `com.android.vending.CHECK_LICENSE`, `ACCESS_ADSERVICES_TOPICS`, `ACCESS_ADSERVICES_ATTRIBUTION`, `WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE`, `com.GacoGames.EC2.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (signature-level, self-defined).

**Components (all from SDKs/Unity — no mod-added component):**
- Activities (14): `com.gacogames.ec2bridge.EpicConquestPlayerActivity` (main/launcher), Google Sign-In hub, billing `ProxyBillingActivity`/`ProxyBillingActivityV2`, Discord `AuthenticationActivity`, IronSource controller/interstitial/OpenUrl/TestSuite activities, Unity Ads webview, `InlineStoreActivity`, AndroidX credentials hidden activities.
- Services (8): WorkManager (`SystemForegroundService`, `SystemAlarmService`, `SystemJobService`), Google sign-in revocation, datatransport scheduler, Room invalidation, TransportBackendDiscovery.
- Receivers (10): WorkManager/constraint/profile-installer/datatransport — all stock.
- Providers (3): `androidx.startup.InitializationProvider`, IronSource lifecycle providers.
- `android:extractNativeLibs="true"`, `install-location="preferExternal"`.

**Application class:** `com.pairip.application.Application` (see §2.2).

## 2. REA — what the MOD changed

### 2.1 Injection chain (proven, end to end)

1. `UnityPlayerActivity.onCreate()` — the **first statement** is the injected call (`dump/apktool/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali:94`):
   ```smali
   invoke-static/range {p0 .. p0}, Lcom/ModPlayerprefs;->Modded(Landroid/content/Context;)V
   ```
   Everything else in `onCreate` is stock Unity.
2. `com.ModPlayerprefs.Modded(Context)` (`dump/jadx-classes3/sources/com/ModPlayerprefs.java`, decompiled in full):
   ```java
   public class ModPlayerprefs {
       private static final String Located_Playerprefs = "MainActivity";
       public static void Modded(Context context) {
           System.loadLibrary("menu");
       }
   }
   ```
   Despite the suggestive name ("Playerprefs"), this class does **nothing** except load `libmenu.so`. All cheat logic is native, inside `libmenu.so`.
3. `libmenu.so` `JNI_OnLoad` (file offset `0xd99e8`) stores the `JavaVM*` and calls the init routine (`0xd91f4`), which registers JNI natives and spawns the hook thread via `pthread_create` (the only `pthread_create` call site in the library, at `0xd3a30`).

### 2.2 Signature killer — `com.android.support.killsign` (ApkSignatureKillerEx)

`classes3.dex` contains `com.android.support.killsign` + 12 inner classes (`$a`–`$l`). The DEX strings name the tool outright:

```
https://github.com/L-JINBIN/ApkSignatureKillerEx
HiddenApiBypass
killPM
killOpen
getApkContentsSigners
sPackageInfoCache
mt.signature.killer.path1 / mt.signature.killer.path2
```

Behaviour (decompiled `dump/jadx-classes3/sources/com/android/support/killsign.java`, 374 lines):
- The class `extends android.app.Application` and its **static initializer** runs at load:
  ```java
  killPM("com.GacoGames.EC2", "<base64 Google Android cert>");
  killOpen("com.GacoGames.EC2", "", "", "");
  ```
- `killPM()` replaces the `CREATOR` field of `android.content.pm.PackageInfo` with a spoofing `Parcelable.Creator` (`killsign$l`) that overwrites `packageInfo.signatures[0]` and `signingInfo.getApkContentsSigners()[0]` with a **hardcoded certificate**, then clears `PackageManager.sPackageInfoCache` and the `Parcel` creator maps.
- `killOpen()` (349 Dalvik instructions; jadx could not fully decompile it) hooks file-open paths for `base.apk`/`pkg.apk` under `/data/app/…` and `/mnt/asec/…` (the `b(String,String)` path matcher) — i.e. it also spoofs signature reads done by opening the APK file directly.
- Implementation uses `sun.misc.Unsafe`, `java.lang.invoke.MethodHandles`/`MethodHandle`, and a `HiddenApiBypass` helper (`setHiddenApiExemptions`) to reach hidden Android APIs.
- The spoofed certificate (Base64-decoded and verified with openssl) is the well-known AOSP "Android" test certificate:
  - Subject/Issuer: `C=US, ST=California, L=Mountain View, O=Google Inc., OU=Android, CN=Android`
  - Serial: `38BDA18A2221D2C8E43616FACF43A9A58553066A`
  - Validity: 2020-12-02 → 2050-12-02
  - SHA-256: `B1:22:3C:DD:EF:F0:B9:C3:E5:57:E5:25:C3:1A:F7:B5:C7:E4:A3:DF:35:70:F6:FC:A2:2A:DB:78:BA:0C:ED:0A`
  - This is the certificate ApkSignatureKillerEx bundles as the "original" signature to present to any in-app signature check.

**Application class chain:** the manifest's `<application android:name="com.pairip.application.Application">` — `com.pairip.application.Application extends com.android.support.killsign` (`dump/apktool/smali/com/pairip/application/Application.smali`). So the modder kept the game's own **PairIP** protection Application class but re-parented it onto the signature killer, so PairIP's own checks see the spoofed signature.

### 2.3 PairIP — the game's own protection, kept but neutered

36 smali files under `com/pairip/` remain in the APK, including `com/pairip/licensecheck/LicenseClient`, `LicenseActivity`, `ILicenseV2ResultListener`. PairIP is a commercial anti-tamper / license-verification SDK (Play license check — hence the `CHECK_LICENSE` permission and the `com.android.vending.billing.InAppBillingService.BIND` intent filter). Its code is present, but with `killsign` as the Application parent and the signature spoofed to the AOSP test cert, its signature-based checks cannot distinguish this repack from a legitimately signed build. Whether the license check itself is also bypassed could not be determined statically (the `LicenseClient` smali is present and was not diffed against an official build).

### 2.4 `libmenu.so` — the mod menu (native, obfuscated)

- ELF64 AArch64, stripped, SONAME `libmenu.so`, `BIND_NOW`.
- `NEEDED`: `liblog.so`, `libandroid.so`, `libEGL.so`, `libGLESv2.so`, `libc.so`, `libm.so`, `libdl.so` — **EGL + GLESv2 linkage is the ImGui-style in-game overlay renderer** (draws the menu on top of the game via the game's own GL context; no `SYSTEM_ALERT_WINDOW` permission is needed or requested).
- 2,211 dynamic symbols; **all defined function/object symbol names are randomized** (e.g. `QKVcHWDYnBXmjeQKItM3BDc4`, `MXYMe8IzzZ9Q8mcBSr36EvwP`) — deliberate symbol obfuscation. 168 undefined imports, all plain libc/libdl (including `dlopen`, `dlsym`, `dl_iterate_phdr`, `mprotect`, `mmap`, `pthread_create`, `__android_log_print`, `syscall`, `prctl`) — i.e. it resolves everything else at runtime, including the IL2CPP API (no `il2cpp_*` import; resolution goes through `dlopen`/`dlsym`/`dl_iterate_phdr` against `libil2cpp.so`).
- `JNI_OnLoad` exported at `0xd99e8` (36 bytes: stores JavaVM, calls init, returns `JNI_VERSION_1_6`).
- Readable strings are almost entirely gone: of 3,570 strings, **~1,440 match a Base64-like pattern and are encrypted/obfuscated blobs**; the only plaintext strings of interest are:
  - `libmenu.so` (×2), `libil2cpp_hook_guard`, `substrate_hook_init`, `libriru_module.so`, `goldfish_battery`, `AQAB_RSA_PUBKEY_MODULUS_N`
  - `https://api.protection.internal/v3/verify` — a non-routable, internal-looking hostname (almost certainly a decoy/placeholder or a dead anti-tamper check endpoint; it cannot resolve on a real device)
- `substrate_hook_init` indicates the classic **Substrate (MSHookFunction)** inline-hook engine from the LGL/KittyMemory-style mod-menu template.
- Because the strings are encrypted and symbols randomized, the **exact hook targets and menu labels could not be recovered statically** (see §5). The template's runtime string decryption happens in `.init_array` constructors / at first use.

### 2.5 Advertised mod features vs binary evidence

Mod sites listing this exact build (v3.1.5, `com.GacoGames.EC2`) agree on the feature set:

| Advertised feature | Sources | Binary corroboration |
|---|---|---|
| Mod Menu (floating, top-left icon) | HappyMod, Modyolo, Platinmods (thread by Yaskashije, "still working for 3.1.5"), RealApkClub | **Strong** — `libmenu.so` is an ImGui overlay menu (EGL/GLES, `JNI_OnLoad`, hook thread) loaded at every launch |
| Damage Multiplier | HappyMod, Modyolo, Platinmods | Plausible (IL2CPP hook); **not individually proven** — labels are encrypted |
| God Mode | HappyMod, Modyolo, Platinmods, MODXDA | Plausible; **not individually proven** |
| Unlimited Skill Usage | Modyolo, Platinmods | Plausible; **not individually proven** |
| Unlimited Gold / Rubies ("never decrease") | Modyolo, HappyMod, RealApkClub | Plausible; **not individually proven**. Note: currency lives in IL2CPP game code (`ruby_1..6`, `ruby_pack_double_*` in metadata); the menu hooks the spend path rather than editing save data (the loader class named "ModPlayerprefs" performs no PlayerPrefs writes — its only action is loading `libmenu.so`) |
| Costume boxes (Claris & Chase) | Modyolo | Claim only |
| Game Speed | Modyolo | Claim only |
| Free shopping / unlocked premium | RealApkClub, MODXDA, ApkZolo | Claim only; `ProxyBillingActivity` (Play Billing) is still present, so purchases are not removed from the manifest — a "free shopping" claim would require a billing hook, which was not isolated |

**What is proven:** a runtime IL2CPP hooking menu is injected at every launch, and the APK's signature/license verification is defeated. **What is not proven statically:** the per-feature method hooks (damage, god mode, currency) — those live behind encrypted strings in `libmenu.so` and would need dynamic analysis or a decompiler (Ghidra/IDA, unavailable on this VM) to confirm one by one.

### 2.6 What was NOT changed (as far as static analysis can tell)

- No extra activities/services/receivers/providers were added to the manifest; all components belong to Unity/Google/Discord/IronSource.
- No extra permissions were added beyond what a stock Unity game + Play license check needs (no SMS, location, camera, microphone, contacts, call, accessibility, device-admin, or overlay permissions).
- `libil2cpp.so`, `libunity.so`, and the game assets carry their original `1981-01-01` timestamps and stock structure; the modification is additive (DEX 3 + `libmenu.so` + one smali line + Application re-parenting) rather than a rewrite of game code. This could not be proven byte-for-byte without the official APK (§5).

## 3. Security scan

### 3.1 Permissions — clean for a game
Nothing beyond a normal Unity game with ads + Play Billing + license check. No permission that would enable spying or premium fraud (no `SEND_SMS`, `READ_SMS`, `ACCESS_FINE_LOCATION`, `CAMERA`, `RECORD_AUDIO`, `READ_CONTACTS`, `BIND_ACCESSIBILITY_SERVICE`, `BIND_DEVICE_ADMIN`, `SYSTEM_ALERT_WINDOW`).

### 3.2 Components — clean
No added component; no exported mod activity/service/receiver. The only exported entry points are Unity's own.

### 3.3 Embedded URLs / domains / IPs
From all three DEX string tables + `libmenu.so` strings, the only hosts are legitimate SDK endpoints:
`accounts.google.com`, `discord.com`, `gateway.unityads.unity3d.com`, `i-sdk.mediation.unity3d.com`, `o-sdk.mediation.unity3d.com`, `o-crash.mediation.unity3d.com`, `o-ext.mediation.unity3d.com`, `pagead2.googlesyndication.com`, `www.googleapis.com`, `www.supersonicads.com` (IronSource), `support.google.com`, `youtrack.jetbrains.com`, `issuetracker.google.com`, plus the killsign repo URL `github.com/L-JINBIN/ApkSignatureKillerEx` and the non-routable `api.protection.internal` (see §2.4). **No C2 domain, no IP literals, no data-exfiltration endpoint found.** (Encrypted strings in `libmenu.so` could hide more URLs — see §5.)

### 3.4 Obfuscation / packers
- `libmenu.so`: symbol-name randomization + string encryption (deliberate anti-analysis, standard for mod menus — not by itself malware evidence).
- DEX: no packer; `classes.dex`/`classes2.dex` are plain (only `classes3.dex` is the small injected file).
- No `DexClassLoader`/`PathClassLoader`/`loadDex` dynamic code loading found in smali.
- No native packer signatures detected in `libmenu.so` (plain ELF, readable `.text`/`.rodata`).

### 3.5 Suspicious API usage
- `SmsManager` / `sendTextMessage`: **none**.
- Accessibility / device-admin APIs: **none** (only AndroidX compat *class names* matching the grep, no usage).
- `Runtime.exec`: 3 smali files only — IronSource ad-quality SDK (obfuscated `?` classes, typical `getprop`/`logcat` probes) and `com.yasirkula.unity.DebugConsoleLogcatLogger$LogcatWorker` (legitimate Unity logcat plugin). Not mod-related.
- `SYSTEM_ALERT_WINDOW` / `canDrawOverlays`: **none** (menu renders in-process via EGL).
- Crypto (`javax/crypto`, `MessageDigest`, `KeyStore`): 36 smali files, all in Google/Unity/Discord SDK code.
- `libriru_module.so` string in `libmenu.so`: references the Riru (root) module name — a leftover string from the menu template's root-detection/anti-detection code, not an actual Riru module in the APK (no such file is shipped).

### 3.6 VirusTotal lookup — NOT AVAILABLE
No `vt-cli`, no VirusTotal API key, and no VT connector exist on this VM. A web search for the file's SHA-256 (`b36ad4a9…`) returned no VirusTotal record — the hash is not publicly indexed. **The file was NOT uploaded anywhere.** If a VT verdict is wanted, submit the hash (not the file) at `virustotal.com/gui/file/b36ad4a93aa941edae515f77136d9e13ac2b444c9187270b51ad698a7202e530`.

### 3.7 Verdict: **SUSPICIOUS (not proven malicious)**

- **Confirmed malicious-adjacent behaviour:** signature/license verification is deliberately defeated (`killsign` + spoofed Google cert + Application re-parenting), and a runtime hooking menu with encrypted strings is injected into a commercial game. That is the entire purpose of the repack, and it is also why it cannot be trusted the way an official build can.
- **No overt malware found statically:** no C2/exfiltration endpoints, no SMS/premium-fraud code, no accessibility/device-admin abuse, no extra permissions or components, no dynamic code loading, no credential harvesting surface beyond what the game itself already has (Google/Discord login SDKs are stock).
- **Residual risk (cannot be excluded statically):** the encrypted strings in `libmenu.so` could hide additional URLs or behaviours; the menu runs with the game's full permissions and can read/write the game's memory and files. The account-ban risk is real (online features, cloud save, and Discord/Play Games login all see a tampered client). Recommendation: do not install on a primary device or a Google/Play Games account you care about; treat the APK as untrusted third-party code, which it is.

## 4. How to reproduce / verify

```bash
# Integrity
sha256sum Epic-Conquest-2-v3.1.5-mod.apk
# b36ad4a93aa941edae515f77136d9e13ac2b444c9187270b51ad698a7202e530

# Signer (needs JDK on PATH)
~/android-sdk/build-tools/34.0.0/apksigner verify --verbose --print-certs Epic-Conquest-2-v3.1.5-mod.apk

# Dump (tools fetched during this analysis: /tmp/apktool.jar, /tmp/jadx-1.5.1)
java -jar /tmp/apktool.jar d -f -o dump/apktool Epic-Conquest-2-v3.1.5-mod.apk
/tmp/jadx-1.5.1/bin/jadx -d dump/jadx-classes3 dump/dex/classes3.dex

# Key grep points
grep -rn ModPlayerprefs dump/apktool/smali_classes2/com/unity3d/player/UnityPlayerActivity.smali
grep -rn killsign dump/apktool/smali/com/pairip/application/Application.smali
strings -a dump/so/lib/arm64-v8a/libmenu.so | grep -i -E 'substrate|il2cpp_hook_guard|protection.internal'
```

## 5. Honest limits

1. **No official APK for diffing.** All "changed vs official" claims rest on structural evidence (added DEX, added `.so`, injected smali line, re-parented Application, debug signer). Byte-level diffs of `libil2cpp.so` / `classes.dex` / game assets against the Play build were impossible.
2. **Per-feature hooks not recovered.** `libmenu.so` encrypts its strings and randomizes symbols; without Ghidra/IDA (not available on this VM) the exact IL2CPP methods hooked for Damage/God Mode/Currency could not be named. Advertised features are corroborated only by the menu's existence + consistent claims across independent mod sites.
3. **No dynamic analysis.** The APK was never installed or run, so runtime behaviour (network traffic, file writes, anti-ban behaviour, actual menu contents) is unverified.
4. **No VirusTotal verdict** (§3.6).
5. `killOpen()` (349 Dalvik instructions) could not be fully decompiled by jadx; its exact file-open interception is described from its path matcher + the surrounding code, not from a complete decompilation.
6. The `.init_array` string-decryption routines and the ICF-folded thread entry in `libmenu.so` were not fully traced; the hook-thread identification rests on the single `pthread_create` call site and the `JNI_OnLoad` → init → `pthread_create` chain.
