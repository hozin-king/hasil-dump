# REA — Gboard (com.google.android.inputmethod.latin) — Full Dump & Analysis

**Tanggal:** 7 November 2026
**Tujuan:** Memahami isi APK Gboard resmi terbaru sampai bisa dijawab "nanti bisa diapain aja" (fitur apa yang bisa di-hook/mod), khususnya dalam konteks modul LSPosed GboardHook (fork `hozin-king/GboardHook`, libxposed API).

---

## 1. Info APK

| Item | Nilai |
|---|---|
| Sumber unduhan | `[tautan unduhan dihapus — minta ke Alyaa]` → redirect ke `[tautan unduhan dihapus — minta ke Alyaa]` |
| File lokal | `~/workspace/rea-gboard/gboard.apk` |
| Ukuran | 79.288.776 byte (±75,6 MB) |
| SHA-256 | `2b1c28cf650894ead8a95224ac15fce246e61cd54d11e2149c2a13fc24b30d84` |
| Package | `com.google.android.inputmethod.latin` |
| versionName | `18.6.3.1002251336-release-arm64-v8a` |
| versionCode | `176071766` |
| minSdk / targetSdk / compileSdk | 26 / 37 / 37 |
| Arsitektur | arm64-v8a saja |
| File di dalam ZIP | 9.462 file, total tak terkompresi ±112 MB |

> **Catatan versi:** halaman APKPure saat di-scrape mencantumkan `18.5.11.993608717-release-arm64-v8a`, tetapi file yang benar-benar terunduh lewat `?versionCode=176071766` adalah **18.6.3.1002251336**. Semua temuan di laporan ini berlaku untuk **18.6.3** (versionCode 176071766).

### Komponen hasil dump

| Komponen | Isi |
|---|---|
| `classes.dex` | 7.845.128 byte |
| `classes2.dex` | 8.796.432 byte |
| `classes3.dex` | 3.198.204 byte |
| `classes4.dex` | 580.844 byte |
| `resources.arsc` | 20.860.896 byte |
| `lib/arm64-v8a/libintegrated_shared_object.so` | 33.995.120 byte (inti native: engine keyboard, model ML) |
| Native lain (12 file) | `libgraphics-core.so` (243 KB), `libfilterframework_jni.so`, `libgrammar-checker_jni.so`, `libimage_processing_util_jni.so`, `libogg_opus_encoder.so`, `libscam_partition*.so`, `libexpressive_concepts_model_less_predictor_jni_native.so`, `libandroidx.graphics.path.so`, `libnative_crash_handler_jni.so`, `libjni_signalinitializer.so`, `libsurface_util_jni.so` |
| Manifest (apktool) | `LatinIME` service (`com.android.inputmethod.latin.LatinIME`, `BIND_INPUT_METHOD`), `ClipboardContentProvider` (authority `com.google.android.inputmethod.latin.clipboard_content`, `exported=false`), `SettingsActivity`, `ThemeBuilderActivity` + `ThemeEditorActivity`, `AndroidSpellCheckerService`, `InAppTrainingService` (federated learning, proses `:train`), Superpacks services, `PhenotypeMetadataHolderService` (disabled) |
| Permission menarik | `RECORD_AUDIO`, `CAMERA`, `READ_MEDIA_IMAGES`, `INJECT_KEY_EVENTS`, `BIND_SERVICE` ke `com.google.android.apps.aicore.service`, `PERSONAL_CONTEXT_*` (3 permission konteks on-device), `RECEIVE_BOOT_COMPLETED`, `FOREGROUND_SERVICE` |

### Cara dump (repro)

- `aapt2 dump badging/permissions` — identitas + permission.
- `apktool 2.10.0` (`java -jar apktool_2.10.0.jar d`) → `gboard-decoded/` (manifest, res, smali). Exit 0.
- `jadx 1.5.1` atas keempat dex → `jadx-out/` (13.624 kelas; 26 kelas error decompile, sisanya OK).
- `dexdump` + `strings` untuk verifikasi keberadaan string kunci di tiap dex.

**Batasan:** nama kelas/metode internal Gboard di-obfuscate (contoh: `fnb`, `fof`, `fpo`, `odo`, `fps`, `fob`) — hanya kelas publik API (`com.google.android.apps.inputmethod.libs.clipboard.*`) yang memakai nama asli. Tidak ada analisis native mendalam (Ghidra/IDA tidak tersedia di VM ini) — klaim soal `.so` hanya berbasis `strings`. Tidak ada pengujian runtime (tidak diinstal/dijalankan).

---

## 2. Temuan A — Sub-sistem Clipboard (fokus GboardHook)

### 2.1 Kelas-kelas kunci (semua masih ada di 18.6.3)

| Kelas | Peran | Bukti |
|---|---|---|
| `com.google.android.apps.inputmethod.libs.clipboard.ClipboardContentProvider` | ContentProvider SQLite tabel `clips` | `smali/.../ClipboardContentProvider.smali`, 1.257 baris; `query(Uri, String[], String, String[], String)` di baris 811; authority `com.google.android.inputmethod.latin.clipboard_content` di manifest |
| `fof` | `ClipboardContentProviderUtils` (source `ClipboardContentProviderUtils.java`) | `smali_classes2/fof.smali`; method `a(Context)J` = `getUnpinnedItemTimeLimitInMilliSeconds`, `d(Context,I,J)` = pembangun URI `content://...clipboard_content/clips`, `j(...)` = query helper, `k(Context,Z)` = jalur query baru |
| `fnb` | `Callable` pembangun query jalur lama (dipakai `fnc`) | `smali_classes2/fnb.smali`, method `call()` |
| `fob` | `ClipboardAdapter` (RecyclerView adapter clipboard) | `smali_classes2/fob.smali`; jadx `defpackage/fob.java` (`public final class fob extends ju`, field `fob.x = wpm.i("com/google/android/apps/inputmethod/libs/clipboard/ClipboardAdapter")`) |
| `fpo` | Registry flag clipboard (namespace `ro.com.google.ime.clipboard`) | `smali/fpo.smali` lengkap (lihat §2.3) |
| `fps` | Enum kunci flag Phenotype | `jadx-out/sources/defpackage/fps.java`, entri `USER_RETENTION("Clipboard.userRetentionTime")` |
| `odo` | Pembaca nilai flag (Phenotype) | `smali/odo.smali`, string `"Invalid flag: "` di baris 492 & 1004, method `g()` mengembalikan `Object` |

### 2.2 `ClipboardContentProvider.query()` — TIDAK BERUBAH

`query()` menerima `(Uri, projection, selection, selectionArgs, sortOrder)`, cek `UriMatcher` (harus match `2`), lalu meneruskan semuanya apa adanya ke `SQLiteDatabase.query("clips", ...)` dan mengembalikan Cursor. Tidak ada sanitasi/validasi tambahan. **Target hook GboardHook atas method ini masih valid di 18.6.3.**

### 2.3 Registry flag clipboard (`fpo`, namespace `ro.com.google.ime.clipboard`)

| Field | Nama flag | Tipe + default |
|---|---|---|
| `a` | `config_clipboard` (handle namespace) | `Lodl.p("config_clipboard", "ro.com.google.ime.clipboard")` |
| `b` | `text_clip_item_char_limit` | long, default `0x4e20` = **20.000 karakter** |
| `c` | `enable_clip_item_consumers` | boolean, default `false` |
| `d` | `enable_clipboard_query_refactoring` | boolean, default **`true`** |
| `e` | `enable_system_clipboard_direct_paste_for_quick_paste` | boolean, default `false` |
| `f` | `enable_extended_clipboard_history` | boolean, default `false` |

Hanya **3** flag `enable_*clipboard*` yang tersisa di seluruh APK (dari `strings` semua dex).

### 2.4 Dua jalur query — dan kenapa ini penting

**Jalur baru (default stock, flag `d` = true) — `fof.k(Context, boolean)`:**
- Selection: `((item_type & 1) = 0 AND (item_type & 2) = 0 AND timestamp >= ?) OR ((item_type & 1) != 0) OR ((item_type & 1) = 0 AND (item_type & 2) != 0)`, argumen waktu = `max(now - a(context), ...)`, sort `"timestamp DESC"` (tanpa limit SQL).
- Limit diterapkan di Java: total maks 100 item, dan pengelompokan per-timestamp berhenti setelah **5 timestamp berbeda** (`if (i3 >= 5) break;` di `fof.k`, jadx `fof.java`).
- `a(context)` = waktu retensi tetap dipakai di jalur ini untuk filter `timestamp >= ?`.

**Jalur lama (hanya bila flag `d` = false) — `fnb.call()`:**
- Cek flag `fpo.d` dulu; bila true, langsung pakai `fof.k(context, true)` dan return.
- Bila false, bangun selection `"((item_type | ?) - (item_type & ?)) & ? = 0 and timestamp >= ?"` (masih mengandung `"timestamp >= ?"`), argumen waktu = `now - fof.a(context)` (dengan floor `max(..., qpn...m(0x7f140903, 0))`), dan sortOrder = `String.format(Locale.US, "timestamp DESC limit %d", 100)`.

### 2.5 Verifikasi tiap hook GboardHook terhadap 18.6.3

| Hook di GboardHook | Status di 18.6.3 | Bukti |
|---|---|---|
| `ClipboardContentProvider#query` — tulis ulang argumen `"timestamp >= ?"` | **MASIH BERFUNGSI** | Provider + `query()` tidak berubah (§2.2); selection kedua jalur masih mengandung `"timestamp >= ?"` (`fnb` baris 68-70; `fof.k` baris 189) |
| `query` — tulis ulang sortOrder bila `arg4 == "timestamp DESC limit 5"` | **MATI (no-op diam-diam)** | Satu-satunya kemunculan string `"timestamp DESC limit"` di SEMUA dex adalah format string `"timestamp DESC limit %d"` di `fnb.smali:389`, yang diisi angka **100** (`const/16 v7, 0x64`, baris 162-168). Tidak ada literal `"timestamp DESC limit 5"` di mana pun. Kondisi `== "timestamp DESC limit 5"` tidak akan pernah cocok |
| ReadConfig — hardcode `enable_clipboard_query_refactoring` = false | **MASIH BERFUNGSI** | Nama flag masih ada (`fpo.smali:30-37`, default true); kelas pembaca `odo` masih punya `"Invalid flag: "` (baris 492, 1004) dan method `g()` ber-return `Object` — titik hook yang dicari DexKit (`usingStrings("Invalid flag: ")`, returnType `Object`) masih ada |
| ReadConfig — hardcode `enable_clipboard_entity_extraction` = false | **MATI (no-op)** | String `"enable_clipboard_entity_extraction"` (dan `"entity_extraction"` / `"clipboard_entity"`) **tidak ditemukan di dex mana pun** (0 kemunculan di classes.dex–classes4.dex). Flag ini sudah dihapus/diganti di 18.6.3; hook tidak akan pernah terpicu |
| Retention-time — `fof.a(Context)` diganti return `clipboardTextTime` | **MASIH BERFUNGSI** | Method ditemukan via DexKit string `"Failed to parse retention hours"` (`fof.smali:162`, jadx: `getUnpinnedItemTimeLimitInMilliSeconds`). Logika: bila flag `f` (`enable_extended_clipboard_history`) false → return konstanta `0x36ee80` = 3.600.000 ms (**1 jam**); bila true → parse setting jam (resource `0x7f1408fb`, default `"1"`) → `Duration.ofHours(hours).toMillis()`; gagal parse → fallback `fof.b` = `Duration.ofHours(1)` |
| Adapter — `findAdapterMethod` + `hookAdapter` | **TIDAK AKTIF (kode dimatikan di sumber)** | Di `PluginEntry.kt` pemanggilannya di-comment (`// hookAdapter(it, classLoader)`). Kelas target (`fob` = ClipboardAdapter) masih ada, tapi hook tidak terpasang. Finder DexKit (kelas memakai string `"com/google/android/apps/inputmethod/libs/clipboard/ClipboardAdapter"` + method memakai angka 5) secara prinsip masih bisa menemukan target |
| `HashSet.size()` — return 5 bila set berisi `j$.time.Instant` dan `map.size <= clipboardTextSize` | **TIDAK BISA DIVERIFIKASI efeknya** | `HashSet` adalah kelas JDK (selalu ada). Efeknya bergantung pada kode mana yang membuat `HashSet<Instant>` — di jalur `fof.k` yang dibaca tidak ada `HashSet` eksplisit; kemungkinan dipakai di adapter/dedup `fob`/`fnc`. Tanpa runtime trace, efek pastinya tidak bisa dipastikan |

**Ringkasan clipboard:** dari 4 hook aktif GboardHook, **2 masih berfungsi** (rewrite `timestamp >= ?` + hardcode `query_refactoring` + retention-time = 3 dari 4 mekanisme; yang mati: rewrite `"limit 5"` dan hardcode `entity_extraction`). Efek praktis di 18.6.3: ukuran daftar clipboard **tidak lagi dikendalikan** oleh hook lama — daftar dibatasi 100 item / 5 grup timestamp oleh logika `fof.k` (bila flag true) atau `"timestamp DESC limit 100"` (bila flag false). Pengaturan "kapasitas" di UI modul saat ini kemungkinan besar **tidak berpengaruh** pada jumlah item yang tampil di versi ini.

---

## 3. Temuan B — Sistem Flag / Konfigurasi (Phenotype)

- Flag dibaca lewat factory `Lodl`: `a(String, boolean)` (boolean), `c(String, long)` (long), `p(String, String)` (namespace/config). Hasilnya objek `Lodi`; nilainya diambil lewat `g()` → `Object`.
- Kelas pembaca nilai: `odo` (method `a()`–`k()`; `"Invalid flag: "` di `a()` dan `g()`). Inilah titik yang di-hook GboardHook (`findReadConfigMethod` + `hookReadConfig`).
- Kunci flag didaftar sebagai enum `fps` (contoh: `USER_RETENTION("Clipboard.userRetentionTime")`, `fps.java:23`).
- Total flag `enable_*` unik di semua dex: **504**. Ini adalah permukaan serangan/mod terbesar: hampir semua fitur Gboard digerbangi flag boolean/long/string yang bisa dibalik dari satu titik hook yang sama dengan yang sudah dipakai GboardHook.
- Mekanisme update flag: server-side (Phenotype / Google Play Services sync) — nilai default di dex hanya fallback bila server belum mengirim nilai. Membalik flag secara lokal hanya bertahan sampai sync berikutnya menimpanya (kecuali hook diterapkan terus-menerus di tiap pembacaan, seperti yang dilakukan GboardHook).

---

## 4. Temuan C — Fitur lain yang kelihatan hook-able

### 4.1 Translate (server-side, tapi ada kontrol klien)

- Modul `TranslateAccessPointProviderModule`; log `"translate started %s -> %s in %s"`, `"Failed to parse translate response: %s"`, scope OAuth `https://www.googleapis.com/auth/translate`.
- Config klien: `translate_minimum_request_interval_millis`, `translate_minimum_waiting_for_next_call_millis` (rate-limit antar request).
- Vonis: mengubah interval klien mungkin; hasil akhir tetap dibatasi server Google Translate.

### 4.2 Voice typing / dictation (banyak flag, sebagian server-gated)

Flag `enable_*` yang ditemukan: `enable_ondevice_voice`, `enable_agentic_dictation`, `enable_agentic_dictation_debug_ui`, `enable_smart_dictation_speech_enhancement_setting`, `enable_dictation_feature_split_install`, `enable_s3_as_fallback_in_smart_dictation`, `enable_rambler_voice_correction_list_import_export`, `enable_action_key_on_voice_toolbar`, `enable_global_direct_to_voice_toolbar`, `enable_internal_speech_enhancement_indicator`, `enable_internal_speech_enhancement_pii_logging`, `enable_highlight_voice_composing_text_cursor_on_edge`.
- Log: `"MDictation is not enabled in incognito mode input session."` — dictation dimatikan paksa saat mode incognito.

### 4.3 Emoji Kitchen / GIF / stiker

Flag: `enable_emoji_kitchen_browse_entry_point_v2`, `enable_proactive_emoji_kitchen` (+ `enable_blocklist_for_proactive_emoji_kitchen`, `enable_debug_toast_for_proactive_emoji_kitchen`), `enable_animated_emoji_content_suggestions`, `enable_emoji_suggestion_from_top_candidate`, `enable_contextual_gif_search_query_suggestion`, `enable_custom_gif_categories`, `enable_custom_sticker_tab`, `enable_3d_couple_emojis`, `enable_inline_suggestion`, `enable_inline_suggestions_on_client_side`, `enable_close_proactive_suggestions_access_point`.
- Semua ini gerbang UI/konten berbasis flag — kandidat flip yang murah (satu titik hook yang sama).

### 4.4 Keyboard mengambang / satu tangan

- Flag: `enable_auto_float_keyboard_in_freeform`, `enable_auto_float_keyboard_in_landscape`, `enable_auto_float_keyboard_in_multi_window`.
- String UI: `close_accessory_floating_keyboard`, `exit_floating_keyboard_tooltip_hint`, `floating_keyboard_dock_hint_tooltip`, `one_handed_dialog_max_show_count`.

### 4.5 Tema

- `ThemeBuilderActivity` + `ThemeEditorActivity` terdaftar di manifest (non-exported) — bisa dipanggil/di-hook; flag `enable_materializer_manager`, `enable_extra_small_theme_without_height`, `enable_extra_small_width_portrait_theme`, `enable_expressive_concept_model`, `enable_expressive_concept_triggering_engine` (Material Expressive).
- Native: `libexpressive_concepts_model_less_predictor_jni_native.so` (model prediksi konsep ekspresif).

### 4.6 Mode incognito

- **Bukan flag.** Status incognito berasal dari `EditorInfo` aplikasi yang sedang diketik (`"EditorInfo = %s, IncognitoMode = %b"`, `HIDDEN_INCOGNITO_MODE`, `"%editorInfo;incognitoMode;keyboardType"`).
- Perilaku yang dikunci saat incognito: dictation dimatikan (`"MDictation is not enabled in incognito mode..."`), learning/personalization dimatikan (`"HonActivate(), incognitoMode=%s, shouldEnableLearning=%s"`).
- Mengubahnya butuh hook pada pembacaan status incognito / `onActivate`, bukan flip flag.

### 4.7 Lain-lain (dari manifest & permission)

- Spell checker: `AndroidSpellCheckerService` (`BIND_TEXT_SERVICE`) — koreksi ejaan sistem.
- Federated learning: `InAppTrainingService` (proses `:train`), flag `enable_dynamic_trainer`, `enable_hmm_user_history_backup`, `enable_backup_delight5_personalized_data` — personalisasi on-device.
- AI on-device: permission `BIND_SERVICE` ke `com.google.android.apps.aicore.service` (AICore), permission `PERSONAL_CONTEXT_*`; native `libgrammar-checker_jni.so` (grammar check), `libexpressive_concepts_model_less_predictor_jni_native.so`.
- Handwriting/stylus: `StylusSettingsActivity`, flag `enable_handwriting_promo`, `enable_voice_in_handwriting`, `enable_sync_stylus_toolbar`.
- Haptik/suara: **tidak ditemukan** flag `enable_*` untuk haptik; suara hanya `enable_beep_sound_at_recognition_end`, `enable_voice_sound_media_volume_scaling` — kemungkinan besar dikendalikan setting sistem, bukan flag.

---

## 5. Temuan D — Proteksi (integrity / root detection)

| Pemeriksaan | Hasil | Bukti |
|---|---|---|
| Play Integrity API | **TIDAK ADA** | 0 kemunculan `PlayIntegrity`/`playintegrity` di semua dex |
| SafetyNet | **TIDAK ADA** | 0 kemunculan `SafetyNet`/`safetynet` di semua dex |
| `ctsProfileMatch` / `basicIntegrity` | **TIDAK ADA** | 0 kemunculan |
| String `attestation` / `integrity` di dex | Hanya konteks tak terkait | `ATTESTATION_CLIENT_OVERRIDE_USED` (TrainerFeature), `FederatedLearning_DeviceIntegrityIntact`, `pay_get_integrity_token_for_pix_operation` (Google Pay), `setWebViewMediaIntegrityApiStatus` (WebView), teks prompt AI ("Lexical Integrity…", "Factual Integrity…") |
| String `integrity`/`attest` di native `libintegrated_shared_object.so` | Hanya teks prompt AI | `"Factual Integrity: Do not invent statistics…"`, `PRIVACY_AND_INTEGRITY`, `STRONG_PRIVACY_AND_INTEGRITY` — bukan cek tamper |
| Root detection | **ADA, satu titik** | `smali_classes2/qie.smali` (synthetic `Callable`, `packed-switch` case 5 = `:pswitch_e`): cek `Build.TAGS` mengandung `"test-keys"`, `new File("/system/app/Superuser.apk").exists()`, `new File("/system/xbin/su").exists()` → return `Boolean` |
| Pemakai root check | `roa.fP(Context, ...)` (baris 348: `const/4 v1, 0x5` → `new Lqie; ... Lqie;-><init>(Object, int)`) | Hasil dijalankan async via `Executor` (`Loin.m(Callable, Executor)`) lalu diteruskan ke callback `psi` (int 3). `roa` punya method `dump(Printer, boolean)` — ciri komponen diagnostik/telemetri, bukan gerbang fitur |
| SafetyNet/Play Integrity di native `.so` | **TIDAK ADA** | 0 kemunculan `safetynet`/`playintegrity` di `libintegrated_shared_object.so` (34 MB); 0 `magisk`, 0 `/system/xbin/su` |

**Vonis proteksi:** Gboard 18.6.3 **tidak memiliki** Play Integrity / SafetyNet attestation dan tidak memblokir pemakaian di perangkat root. Satu-satunya cek root yang ditemukan adalah pemeriksaan klasik (test-keys / Superuser.apk / xbin/su) yang hasilnya masuk ke jalur diagnostik async (`roa` + `psi`), tanpa bukti di dump ini bahwa hasilnya memblokir fitur keyboard. Meng-hook Gboard tidak akan memicu integrity check di dalam APK ini — risiko utama justru dari **server** (flag Phenotype di-sync ulang dari server, dan fitur server-side seperti Translate/dictation bisa menolak request bila terdeteksi aneh).

---

## 6. Daftar "Bisa Diapain Aja" (dengan vonis)

Legenda: **MUNGKIN** = ada titik hook/flag yang terverifikasi di dump ini, tinggal implementasi. **SULIT** = butuh kerja tambahan besar / verifikasi runtime / kemungkinan dibatasi server. **TIDAK MUNGKIN** = tidak ada mekanisme yang mendukung di APK ini (berdasarkan bukti dump).

### Clipboard (inti GboardHook)

| # | Ide | Vonis | Alasan + bukti |
|---|---|---|---|
| 1 | Perpanjang waktu simpan clipboard (retensi) | **MUNGKIN** | Hook `fof.a(Context)` (via string `"Failed to parse retention hours"`) masih valid; return `clipboardTextTime` menggantikan 1 jam default / jam hasil parse |
| 2 | Paksa jalur query lama (`query_refactoring=false`) | **MUNGKIN** | Flag `fpo.d` masih ada, default true; titik hook ReadConfig (`odo`, `"Invalid flag: "`) masih ada |
| 3 | Ubah limit jumlah item via `"timestamp DESC limit 5"` | **TIDAK MUNGKIN** (di 18.6.3) | String itu tidak ada; satu-satunya bentuk adalah `"timestamp DESC limit %d"` yang diisi **100** (`fnb.smali:162-168,389`). Hook lama tidak akan pernah cocok |
| 4 | Batasi/ubah limit jadi N item (pengganti #3) | **MUNGKIN** | Ganti kondisi hook jadi prefix-match `"timestamp DESC limit"` dan tulis ulang angkanya; atau hook `fof.k()` (cap 100 item / 5 grup timestamp di Java, `fof.java:206-221`) |
| 5 | Hardcode `enable_clipboard_entity_extraction=false` | **TIDAK MUNGKIN** (no-op) | Flag tidak ada di dex mana pun (0 kemunculan) di 18.6.3 |
| 6 | Aktifkan `enable_extended_clipboard_history` (flag `fpo.f`) | **MUNGKIN** | Flag ada, default false; bila true, `fof.a()` memakai setting jam (resource `0x7f1408fb`) alih-alih konstanta 1 jam. Titik hook sama dengan #2 |
| 7 | Aktifkan `enable_system_clipboard_direct_paste_for_quick_paste` | **MUNGKIN** | Flag `fpo.e` ada, default false; titik hook sama |
| 8 | Naikkan `text_clip_item_char_limit` (20.000 karakter) | **MUNGKIN** | Flag long `fpo.b` ada (default 20000). Titik baca flag yang sama (`odo`, return `Object`) bisa mengembalikan `Long` lebih besar — butuh penyesuaian hook (saat ini hanya mengembalikan `false` boolean) |
| 9 | Aktifkan `enable_clip_item_consumers` | **SULIT** | Flag `fpo.c` ada, default false, tapi tidak ada bukti di dump tentang efeknya (tidak ditemukan pemakaian yang jelas) — butuh tracing runtime |
| 10 | Aktifkan kembali hook adapter (`fob` = ClipboardAdapter) | **SULIT** | Kelas target masih ada; tapi hook dimatikan di sumber (`// hookAdapter(...)`) dan finder DexKit (method memakai angka 5) belum diverifikasi ulang di 18.6.3 — butuh verifikasi + uji perangkat |

### Flag Phenotype lain (satu titik hook, 504 flag `enable_*`)

| # | Ide | Vonis | Alasan + bukti |
|---|---|---|---|
| 11 | Flip flag fitur UI (Emoji Kitchen v2, custom GIF categories, custom sticker tab, inline suggestions, dsb.) | **MUNGKIN** | Flag-flag ada di dex (`enable_emoji_kitchen_browse_entry_point_v2`, `enable_custom_gif_categories`, `enable_custom_sticker_tab`, `enable_inline_suggestion`, `enable_inline_suggestions_on_client_side`, dll.); semua dibaca lewat mekanisme `odo` yang sama |
| 12 | Aktifkan auto-float keyboard (freeform/landscape/multi-window) | **MUNGKIN** | Flag ada (`enable_auto_float_keyboard_in_freeform`, `..._in_landscape`, `..._in_multi_window`) |
| 13 | Aktifkan fitur voice/dictation (`enable_ondevice_voice`, `enable_agentic_dictation`) | **SULIT** | Flag ada, tapi fitur butuh model/server (AICore, S3 fallback, split install `enable_dictation_feature_split_install`) — flip flag saja belum tentu menghidupkan fitur |
| 14 | Aktifkan Material Expressive (`enable_expressive_concept_model`, `enable_materializer_manager`) | **MUNGKIN** | Flag ada; ada native pendukung (`libexpressive_concepts_model_less_predictor_jni_native.so`) |
| 15 | Percepat Translate (turunkan `translate_minimum_request_interval_millis`) | **SULIT** | Config klien ada (`translate_minimum_request_interval_millis`, `translate_minimum_waiting_for_next_call_millis`), tapi request ke Google Translate API — server bisa tetap membatasi |
| 16 | Paksa mode incognito mati/nyala | **SULIT** | Bukan flag — status berasal dari `EditorInfo` aplikasi (`IncognitoMode = %b`); butuh hook pembacaan status incognito / `onActivate`, belum dipetakan titik pastinya |
| 17 | Ubah haptik/getar keyboard | **TIDAK MUNGKIN** (via flag) | Tidak ada flag `enable_*` terkait haptik di dump; kemungkinan dikendalikan setting sistem |
| 18 | Buka Theme Builder/Editor langsung | **MUNGKIN** | `ThemeBuilderActivity` + `ThemeEditorActivity` terdaftar di manifest (non-exported — bisa dipanggil dari dalam proses Gboard / via hook) |

### Proteksi & risiko

| # | Ide | Vonis | Alasan + bukti |
|---|---|---|---|
| 19 | Bypass Play Integrity / SafetyNet di Gboard | **TIDAK MUNGKIN** (tidak perlu — tidak ada) | 0 bukti keberadaan API tersebut di dex maupun native lib |
| 20 | Sembunyikan root dari Gboard | **MUNGKIN** (tapi mungkin tidak perlu) | Satu-satunya cek root (`qie` case 5, dipanggil `roa.fP`) bisa di-hook return `false`; tapi tidak ada bukti cek ini memblokir fitur — hasilnya masuk jalur diagnostik async |

---

## 7. Catatan & batasan analisis

- Semua klaim di atas didasarkan pada string/kelas/metode yang benar-benar ditemukan di APK 18.6.3 (versionCode 176071766) — bukan dari dokumentasi atau asumsi. Nomor baris smali/jadx dicantumkan agar bisa dicek ulang.
- Nama kelas/metode internal ter-obfuscate; pemetaan ke nama asli (mis. `fof` = `ClipboardContentProviderUtils`) berasal dari string `.source` / log tag di dalam smali/jadx, bukan tebakan.
- `jadx` gagal decompile 26 dari 13.624 kelas (di antaranya `fnb` tidak ada di output jadx — analisis `fnb` memakai smali langsung).
- Tidak ada analisis native mendalam (Ghidra/IDA tidak tersedia) dan tidak ada pengujian runtime — vonis "MUNGKIN" berarti titik hook/flag terverifikasi ada, bukan berarti sudah teruji jalan di perangkat.
- APK tetap lokal di `~/workspace/rea-gboard/` dan tidak diunggah ke mana pun.
