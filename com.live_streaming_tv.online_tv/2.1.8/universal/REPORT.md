# BitTV v2.1.8 — Full Dump + REA Report

- **Date:** 13 Nov 2026 (WIB)
- **Analysed builds:**
  - `BitTV-v2.1.8-alpha.apk` — 18,153,867 bytes (17.31 MiB)
    - SHA-256: `38398486ee79d08ee7371ac0d94e32345db20174e797a3f615d8aae80992e49a`
    - MD5: `8ed006961131508ade167e66dc22e383`
    - Source: [tautan unduhan dihapus — minta ke Alyaa] — uploaded by "Duktek TV"
  - `BitTV-v2.1.8-agate.apk` — 18,153,863 bytes (17.31 MiB)
    - SHA-256: `94039e71f60ac45dea6759338841d8539e18b880f47b3676c0991321a4951c0e`
    - Source: [tautan unduhan dihapus — minta ke Alyaa] — uploaded by "azaeL !", 12 Nov 2026, 7,292 downloads
- **Scope:** analysis only. No mod, injector, patch, or bypass was built; the APKs were not modified or uploaded anywhere.

## 1. Verdict (TL;DR)

- **Not a Play build.** Self-signed with a joke dev certificate (`C=ID, ST=Konohagure, L=Metro CIty, O=Manyu Holding Limited, OU=R&D, CN=Manyu` — "Konohagure" is the Naruto village). v2 signature scheme only, one signer, cert SHA-256 `231cc5ba9879f49f93d0c706bc05816f5b1392316fe4704b4374356ccb1cb656`. No Play App Signing. There is no Play reference APK to compare against, so "official vs repack" cannot be settled from this artifact alone — but the signer is the app's own dev key, not a Play key, and both sfile.co uploads share it.
- **What it is:** a single-activity Kotlin IPTV/live-TV player (ExoPlayer/media3 + FFmpeg), R8-obfuscated, whose entire channel list, stream URLs, DRM licences and "premium" gating come from **Firebase Remote Config at runtime**. Nothing about the channels is bundled in the APK.
- **Alpha vs agate — claim VERIFIED:** the forwarded note said the two versions are the same build, differing only by version clustering for extra Firebase quota. Confirmed by direct comparison: same signer, same versionCode (62), **2,193 of 2,199 zip entries byte-identical** (all dex/smali identical). The only differences are (a) `versionName` (`2.1.8-alpha` vs `2.1.8-agate`), (b) the **Firebase project config** — alpha points at project `bittvv218`, agate at project `new-216` (different sender IDs, app IDs and API keys), and (c) the 20-byte ELF build-id inside the four `libffmpeg.so` files (a rebuild artifact; strings identical). Same AdMob IDs in both. So: **same code, two Firebase projects = two quota pools**. Exactly as claimed.
- **Monetisation is real production ads** (AdMob + Unity Ads + ironSource/LevelPlay mediation, real `ca-app-pub-8969365987662613` IDs), not test ads. "Premium" is not a Play subscription — it is a local lock flag (`isLocked`) cleared by watching rewarded ads, an unlock code, or granted viewing time. There is **no Google Play Billing** in the app.
- **Playback depends on `duktek.id`**: stream requests are sent through OkHttp with a spoofed Firefox user-agent and a `Referer: https://duktek.id/?device=<android_id>&is_genuine=<flag>` header. The `is_genuine` flag implies a genuine-install check on the server side.
- **Protections: effectively none in the app's own code.** No root/Frida/Magisk/Xposed/Play Integrity checks, no SSL pinning, cleartext HTTP allowed app-wide. The only root/emulator strings come from ad SDKs (ad-fraud checks).

## 2. Identity

| Field | Value |
|---|---|
| Package | `com.live_streaming_tv.online_tv` |
| App name | BitTV |
| versionName / versionCode | `2.1.8-alpha` (and `2.1.8-agate`) / 62 |
| minSdk / targetSdk / compileSdk | 24 / 35 / 35 (Android 15) |
| Main activity | `com.live_streaming_tv.online_tv.BitTVActivity` |
| Application class | `com.live_streaming_tv.online_tv.App` (empty `onCreate`) |
| Debuggable | No |
| `allowBackup` / `largeHeap` / `extractNativeLibs` | true / true / false |
| `usesCleartextTraffic` | **true** |
| Dex files | 4 (`classes.dex` … `classes4.dex`), 2,199 zip entries |
| Signer | v2 only, 1 signer, self-signed RSA 2048, DN `C=ID, ST=Konohagure, L=Metro CIty, O=Manyu Holding Limited, OU=R&D, CN=Manyu`; SHA-256 `231cc5ba…b1cb656`, SHA-1 `ab9d40a6614087c51f7ec3081698afb23ce6f7a6` |

### Permissions (14)

`INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `VIBRATE`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION`, `ACCESS_ADSERVICES_TOPICS`, `AD_SERVICES_CONFIG`, `C2DM RECEIVE`, `BIND_GET_INSTALL_REFERRER_SERVICE`, `AD_ID`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. No storage, camera, microphone, or location permissions.

## 3. Engine / framework

- **Language:** Kotlin (R8-obfuscated, single-letter method names). The entire app logic lives in **one activity, `BitTVActivity` (41,434 smali lines)** plus 4 tiny classes: `App` (31 lines), `Ffmpeg` (34), `GestureConstraintLayout` (1,199), `MyFirebaseMessagingService` (1,014). Everything else is SDK code.
- **Player:** ExoPlayer via **androidx.media3** (`PlayerView` in `activity_bit_tv.xml` — no WebView in the main layout). Stream types `hls` / `dash`. A helper extracts the file extension from a URL to pick the player path.
- **Native libs (all 4 ABIs):** `libffmpeg.so` (ExoPlayer FFmpeg extension) and `libunitycoherencenative.so` (Unity Coherence — Unity Ads mediation component, KV store / user attributes; not a game library).
- **UI/SDKs:** Material, Room, WorkManager, Cast (see §7 note), Firebase (Analytics, Messaging, Crashlytics, Remote Config, Sessions, Installations), AdMob, Unity Ads, ironSource/LevelPlay, Histats tracking pixel (`sstatic1.histats.com/0.gif?4836516&101`).

## 4. Backend / Firebase config (found in the package)

### Firebase — alpha build
- Project: `bittvv218`; sender ID `1050680235589`; app ID `1:1050680235589:android:ca7d8c8567845c2a5cb52c`; storage bucket `bittvv218.firebasestorage.app`; `google_api_key` present (value withheld — it is a credential-like key).
- **FCM topic subscribed in `onCreate`: `bittvnew`** (same name as the Remote Config key below). `MyFirebaseMessagingService` builds custom notifications with `RemoteViews` from data messages.
- **Remote Config is the channel source.** `fetchAndActivate()` runs in `onCreate`; defaults (`res/xml/firebase_config.xml`) contain only two ad-timing keys: `durasi_jeda_iklan_pindah_channel` = 900 and `durasi_jeda_iklan_putar_video` = 1800 (seconds — ad interval on channel switch / on video play). The channel list itself is **not** in the defaults — it arrives from the server-side Remote Config values.

### Firebase — agate build (the only config difference)
- Project: `new-216`; sender ID `189973517597`; app ID `1:189973517597:android:e982bcb8635c5a684abdf4`; bucket `new-216.firebasestorage.app`; different API key. Same AdMob IDs, same code.

### Remote Config / channel JSON keys (seen in code)
`country_list`, `category_list`, `channelTv` / `saluranTv`, `menu_name`, `bittvnew`, `header_iptv`, `header_license`, `url_license`, `drm_rcti_plus`, `drm_vision_plus`, `rcti_plus`, `is_live`, `is_movie`, `jenis`, `source`, `image`, `name`, `url`, `premium`, `t_stamp`, `s_stamp`, `ppp`, `tun`, `none`, `kosong`. Per-channel object fields include `url`, `url_license`, `header_license`, `subtitle`, `jenis`, `premium`, `hls`, `image`, `s_stamp`, `t_stamp`, `is_movie`, `is_live`, `tagline`, plus a default headers object `{"Referer":"none", "Origin":"none", "User-Agent":"none"}` and `{"x-data":"none"}`.

### Stream hosts (network security config, cleartext permitted)
Bare IPs `103.30.123.46`, `210.210.155.35`, `210.210.155.37`; `live.cnbcindonesia.com`, `live.cnnindonesia.com`, `edge.metrotvnews.com`, `ott.tvri.co.id`, `op-group1-swiftservehd-1.dens.tv`, `op-krgroup2-swiftservesd-1.dens.tv`, `fhlsport19.1mv.xyz`. The base config permits cleartext generally (system trust anchors) — so HTTP is allowed app-wide, not just for those hosts.

### Referer spoofing (method `e0`, BitTVActivity.smali:20635)
Stream requests go through OkHttp with spoofed headers:
- User-Agent: `Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:<field>) Gecko/20100101 Firefox/119.0`
- `Referer: https://duktek.id/?device=<deviceID>&is_genuine=<isGenuine>`
- `Origin: https://duktek.id`

So playback identity is tied to `duktek.id` plus the device's Android ID.

### Other endpoints in strings
- YouTube InnerTube: `youtubei.googleapis.com`, `youtube.com/youtubei/v1/player|next|guide`, `/embed/`, `/watch` — a YouTube extractor path exists for some channels.
- `https://www.visionplus.id/`, `https://www.rctiplus.com/`.

## 5. DRM

- **Widevine DASH** (`dash-widevine` in code). Each channel carries its own licence URL (`url_license` + `header_license` in the channel JSON); the player builds a `licenseUri` from it.
- **Per-source DRM flows:** keys `drm_rcti_plus` and `drm_vision_plus` — separate licence handling for RCTI+ and Vision+ streams.
- UI strings: `drm_failed` = "Failed to load channel DRM license.", `drm_not_allowed` = "DRM features are not allowed on this device."
- The licence URLs themselves are server-side (Remote Config), so **which channels are DRM-protected cannot be enumerated statically**.

## 6. Premium / lock model (no Play Billing)

- **No `com.android.billingclient` anywhere.** The only purchase-related code is inside the Unity Ads SDK (its internal purchase-event tracking). There is no subscription and no in-app purchase.
- **Lock state is local, in SharedPreferences** (prefs file, keys read in `onCreate`):
  - `deviceID` → static `W2`; if empty, set from `Settings.Secure.ANDROID_ID` and saved.
  - `isGenuine` → static `U2` (string; used in the `duktek.id` referer).
  - `isLocked` → static `V2` (boolean).
  - `isPertama` → `X2` (first run, default true).
  - `lockCounter` (int), `ads_position_save` → `Y2`, `direct_link_position_save` → `Z2`.
- **Enforcement:** `f0(IZ)` (BitTVActivity.smali:20827–28956) reads `V2` (`isLocked`); when locked it calls `b0()` (line 18611), which stops and releases the ExoPlayer (playback halted).
- **Unlock paths (evidence):**
  - Rewarded ads: method `v(Context, String, boolean)` (40929) shows a LevelPlay rewarded ad (`com.unity3d.mediation.rewarded.LevelPlayRewardedAd`) if ready, otherwise opens a URL in the browser. Real rewarded unit IDs in code: `ca-app-pub-8969365987662613/7476576511` and `…/5936597274`.
  - Unlock code: string `code_to_unlock` = "Code to Unlock" — a code-entry dialog exists (exact verification flow not traced to a method; it is referenced by resource ID).
  - Viewing-time grants: string `durasi_nonton_anda_telah_kami_tambahkan_…` = "We have added your viewing duration, please continue enjoying Entertainment and Sports TV." — watching ads grants extra viewing time.
  - TV Box: string `bittv_pada_android_tv_box` = "BitTV on Android TV Box is free of charge, and ad-free. BitTV can also be used on Android Smartphone and Tablet devices. To download the application, please scan the QR code below using your Android phone. Thank you" — Android TV Box installs are advertised as free and ad-free.
- **Channel `premium` flag:** each channel JSON object has a `premium` field (read at lines 3676, 16563, 28812); premium channels are presumably the ones gated by the lock above. The exact premium-check branch was not fully de-obfuscated.
- **Ads (real production):** AdMob app ID `ca-app-pub-8969365987662613~2026999163` (`AD_MANAGER_APP=true`); both test IDs (`ca-app-pub-3940256099942544…`) and real IDs are present in strings, but the live code paths use the real publisher ID. Unity Ads + ironSource/LevelPlay mediation; ad waterfall logic (`last_ad_waterfall_time`); Remote Config ad delays 900 s (channel switch) / 1800 s (video play).

## 7. Protections (static only)

- **None in the app's own code.** No root / Magisk / Frida / Xposed / RootBeer / Play Integrity detection; no certificate pinning (`CertificatePinner` absent; only an OkHttp `enablePublicKeyPinningBypassForLocalTrustAnchors` flag string). WebView SafeBrowsing is enabled in the manifest.
- The only root/emulator strings (`isEmulator=`, `isRooted=`) come from the Unity Ads SDK (ad-fraud checks), not from the app.
- `usesCleartextTraffic=true` + permissive network security config: traffic is interceptable in principle (no pinning to stop it).
- Dead reference: the manifest declares `com.live_streaming_tv.online_tv.CastOptionsProvider`, but **no such class exists in the APK** (only androidx's `DefaultCastOptionsProvider`) — Cast is likely non-functional.
- Native deep analysis (Ghidra/Hopper/IDA) was unavailable on this VM; native pseudocode could not be produced. `rea doctor` confirmed: node 24.22.1 OK, no Ghidra/Hopper/IDA, JADX not installed; androguard 4.1.4, aapt v1, apktool 2.10.0 used instead.

## 8. Per-feature verdict: LOCAL vs SERVER-GATED

| Feature | Verdict | Evidence |
|---|---|---|
| **Channel list / categories / EPG** | **SERVER-GATED** | List comes from Firebase Remote Config (`channelTv`/`saluranTv`, `country_list`, `category_list`); defaults XML has only ad-timing keys; no channel JSON bundled in assets (assets contain only `dexopt`, `ad-viewer`, `iads`). Cannot enumerate channels statically. |
| **Stream URLs** | **SERVER-GATED** | URLs are fields of the Remote Config channel JSON; player only routes by extension (`hls`/`dash`). |
| **Playback (player itself)** | LOCAL | ExoPlayer/media3 + FFmpeg extension bundled; `PlayerView` native layout. |
| **DRM licences (RCTI+/Vision+)** | **SERVER-GATED** | Licence URL per channel (`url_license`); Widevine DASH; `drm_rcti_plus` / `drm_vision_plus` flows. |
| **Premium / lock** | **LOCAL flag, SERVER-INFLUENCED** | `isLocked` is a local SharedPreferences boolean enforced in `f0()`; but `isGenuine` (referer flag) and the channel `premium` flags come from the server/Remote Config, and unlocks are earned via rewarded ads / unlock code / granted viewing time. No Play Billing. |
| **Auth / identity** | **SERVER-INFLUENCED, no login** | No login screen, no account. Identity = `ANDROID_ID` stored as `deviceID` + `isGenuine` flag, sent as `duktek.id` referer params on every stream request. |
| **Push / updates** | **SERVER-GATED** | FCM topic `bittvnew`; `MyFirebaseMessagingService` renders data messages as custom notifications. |
| **Ads** | **SERVER-GATED (units) / LOCAL (timing)** | Real AdMob/Unity/LevelPlay units; timing defaults (900 s / 1800 s) from Remote Config. |
| **YouTube channels** | **SERVER-GATED** | InnerTube endpoints present; which channels use them is in Remote Config. |

## 9. Download notes (sfile.co, for reproducibility)

sfile.co gates downloads behind a smartlink flow. Working sequence (one cookie jar, browser UA): file page → `/download/<short>?fid=<fid>` interstitial → smartlink `rNNNN.sfile.co/redirect/<short>/download` → wait ~9 s → same URL with `&auto=1` (sets `safe_link_counter` cookie) → the real file URL from the interstitial's adblock script (`[tautan unduhan dihapus — minta ke Alyaa]<id>/<n>/<hash>/<name>?is=<sig>&k=<key>`; the `k=` param is required). The `data-direct-download` attribute is a decoy that 302s back to the file page. A reusable downloader is saved at `~/workspace/rea-bittv-v218/sfile_download.py` (usage: `sfile_download.py <short-code> <output.apk>`). Note: the script URLs in the page are backslash-escaped (`\/`), and the `is=` signature rotates per interstitial fetch.

## 10. What could NOT be verified

- **"Official" vs repack:** no Play reference APK exists to compare; the signer is a self-signed dev key, which is consistent with a sideload-only app but does not prove provenance either way.
- **Channel list contents, stream URLs, and which channels are DRM/premium:** all server-side (Firebase Remote Config project `bittvv218` / `new-216`). Requires a live fetch with the app's Firebase config — not done here.
- **The exact unlock-code verification flow and the `isGenuine` computation:** referenced by resource ID / obfuscated methods; not traced to a definitive method.
- **Whether `isGenuine` is actually checked server-side by duktek.id:** the flag is sent in the referer, but the server's behaviour cannot be seen statically.
- **Native code behaviour:** no Ghidra/Hopper/IDA on this VM; `libffmpeg.so` and `libunitycoherencenative.so` were only string-checked.

## 11. Files

- `~/workspace/rea-bittv-v218/BitTV-v2.1.8-alpha.apk` (18,153,867 B, SHA-256 `38398486…92e49a`)
- `~/workspace/rea-bittv-v218/BitTV-v2.1.8-agate.apk` (18,153,863 B, SHA-256 `94039e71…951c0e`)
- `~/workspace/rea-bittv-v218/REPORT.md` (this file)
- `~/workspace/rea-bittv-v218/dump/` — extracted alpha APK; `agate_dump/` — extracted agate APK
- `~/workspace/rea-bittv-v218/apktool/` — apktool 2.10.0 decode (res + smali + smali_classes2/3/4)
- `~/workspace/rea-bittv-v218/all_strings.txt` (131,630 lines), `manifest_dump.txt`, `manifest_xmltree.txt`
- `~/workspace/rea-bittv-v218/sfile_download.py` — reusable sfile.co downloader
