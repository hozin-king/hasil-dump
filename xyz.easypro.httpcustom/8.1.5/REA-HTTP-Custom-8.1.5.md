# REA — HTTP Custom - AIO Tunnel VPN 8.1.5 (xyz.easypro.httpcustom)

**Tanggal REA:** 27 November 2026
**Sumber APK:** APKMirror, diunggah 23 Nov 2026 (`.apkm`, 35.043.841 B)
**Metode:** REA statis saja — APK **tidak** di-install / tidak dijalankan.
**Status APK sumber:** dihapus total setelah push ini terverifikasi (aturan 22 Nov 2026).

## 1. Identitas

| Field | Nilai |
|---|---|
| Package | `xyz.easypro.httpcustom` |
| Version | 8.1.5 (versionCode 942) |
| Developer | ePro Dev Team |
| minSdk / targetSdk | 29 (Android 10) / 36 |
| compileSdk | 37 (platformBuildVersionName 17) |
| Arsitektur | arm64-v8a saja (native libs di split `split_config.arm64_v8a.apk`) |
| Application class | `com.pairip.application.Application` (framework lisensi PairIP) |
| appComponentFactory | `dev.epro.httpcustom.MainFactory` |
| Zygote preload | `dev.epro.r0.O12993300278451645084` (runtime DexGuard di-preload di zygote) |

SHA-256 (lengkap di `dump/hashes.txt`):

- `.apkm`: `2a2304565ccb867a5e7e12e3a8cba5e85dc17fce20f5d70385972a620f221b90`
- `base.apk` (13.512.655 B): `f925a85917023188ed0c30eb42a29cb663d1e0eaba6e1f6ea1eea3731406b0cb`
- `split_config.arm64_v8a.apk` (29.074.396 B): `c72a821b6450b9b394dba44c3eb2a31296f301dca8e18eef290ccc5d6fcf9fff`

Isi `.apkm`: `base.apk` (539 entri, 5 dex) + `split_config.arm64_v8a.apk` (13 entri: 11 native lib + manifest + `stamp-cert-sha256`) + 3 density split (`xhdpi`, `xxhdpi`, `xxxhdpi`).

## 2. Arsitektur — aplikasi "native-first"

Ini **bukan** aplikasi Java biasa. Seluruh logika aplikasi hidup di native code yang
dilindungi DexGuard; lapisan Java/Kotlin hanya kerangka tipis:

- **Kode aplikasi sendiri hanya 70 file smali** (`smali/dev/epro/httpcustom/`, lihat
  `dump/smali-app/`): `MainActivity`, `HTTPCustomApp`, `SyncProvider`,
  `CustomVpnService`, `ProfileDatabase`/`ProfileDatabase_Impl`, `HcrNativeCodec`, dsb.
- **Semua method penting di kelas-kelas itu adalah `native`** (tidak ada bytecode).
  Contoh `MainActivity.smali`: `<clinit>` hanya memanggil
  `Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(0x48c)` lalu semua lifecycle
  (`onCreate`, `onNewIntent`, dst.) dideklarasikan `native`.
- **Total 5 dex, 12.440 class**: `classes.dex` 4.231.676 B, `classes2.dex` 3.426.072 B,
  `classes3.dex` 3.384.540 B, `classes4.dex` 542.808 B, `classes5.dex` 108.960 B.
  Mayoritas isi dex adalah library hasil shading (`dev.epro.r0` = Jetpack/AndroidX/Tink
  yang di-shade + di-obfuscate, `net.zetetic` = SQLCipher, `org.chromium`, dsb.).
- **DexGuard** (Guardsquare): string terenkripsi, nama class/method hasil obfuscation
  (`Lh/prnup/fnruxh/szepgyrk;`, `Ldev/epro/r0/V1302567207208145847;`, dst.),
  tabel JNI dibangun saat runtime, `JNI_OnLoad` ter-obfuscate dengan control-flow
  trampoline (`adr x17; eor x17, x17, xzr; br x17`) + stack canary + loop dekripsi
  byte-per-byte (campuran `add`/`eor`/`ror`/`mul` dengan konstanta `movk`, contoh di
  `libf2c.so` `JNI_OnLoad` @ `0xe57a68`).
- **PairIP**: `Application` = `com.pairip.application.Application`, ada
  `com.pairip.licensecheck.LicenseActivity` di dex — lisensi/cek aplikasi via PairIP.
- **Penyimpanan**: Room + **SQLCipher** (`libsqlcipher.so` 2.275.368 B) — database
  profil terenkripsi di rest. `ProfileDatabase_Impl.smali` (72 baris) tidak memuat
  string `CREATE TABLE` — skema dibangun dari native / class obfuscated.
- **Backup dimatikan total**: `allowBackup="false"` + `data_extraction_rules.xml` /
  `backup_rules.xml` meng-exclude semua domain (root, file, database, sharedpref).
- **Network security**: `cleartextTrafficPermitted="false"`, trust anchor system saja,
  **tanpa certificate pinning** (tidak ada `pin-set`); `debug-overrides` percaya user
  CA (hanya berlaku di build debuggable).

## 3. Stack protokol / engine (native Go + C++)

Semua engine tunnel ada di **`libaio.so` (42.854.056 B, Go 1.26.8)** — Go binary
lengkap dengan `pclntab` (847 simbol `dev.epro/*` terdump di `dump/go_epro_funcs.txt`
+ `dump/go_aio_mobile.txt`):

- **Xray-core** (`github.com/xtls/xray-core`, gVisor netstack `gvisor.dev/gvisor`):
  `dev.epro/aio/mobile/xray.loadConfig`, `ValidateConfig`,
  `Java_dev_epro_mobile_Xray_validateConfig`. Protokol: VLESS, VMess, Trojan,
  Shadowsocks, WireGuard (`WireGuard v1 zx2c4 Jason@zx2c4.com`), Hysteria, HTTP/3,
  gRPC, XHTTP, REALITY, ECH, ML-KEM-768, uTLS.
- **relaycore** (`dev.epro/relaycore`, 689 simbol): `parseConfig`, `validateConfig`,
  `deriveInproxyKey`, `sealInproxyPayload`, `openInproxyPayload`,
  `deriveOSSHKey`, `newOSSHCipher`, `newObfuscatedSSHClientConn`,
  `obfuscatedSSHConn` (SSH ter-obfuscate), Meek (`decodeMeekPublicKey`),
  Conjure (`configureConjureLogger`), SlowDNS
  (`dev.epro/slowdns/Slowdns_startConfiguredWithSocketProtector`).
- **udp-custom** (`dev.epro/udp-custom/app/cmd/core`): `ParseClientConfig`,
  `ClientConfig.Check/Fill/Speed/String`, QUIC client.
- **Lib C/C++ lain**: `liblitevpn.so` (6.775.184 B), `libhev-socks5-tunnel.so`,
  `libtun2socks.so` (tun2socks), `libsqlcipher.so`.
- **DB operator MCC/MNC**: `assets/mcodes.json` (282 KB, daftar operator dunia) —
  dipakai untuk kunci operator / provider-block.

JNI bridge Java↔Go: `Java_dev_epro_mobile_ClientSession_startConfig`,
`Java_dev_epro_mobile_Mobile_runConfig`, `Java_dev_epro_mobile_Mobile_startConfig`,
`Java_dev_epro_relay_ClientSession_startConfig`, dsb.

## 4. Proteksi (terbukti dari `res/values/strings.xml`, 1.960 string)

File lengkap: `dump/strings.xml`. Yang relevan dengan config:

| Proteksi | Bukti string (nama resource → isi) |
|---|---|
| Config terenkripsi | `cloud_config_disclosure` → "HTTP Custom sends **the encrypted config** you save or upload to My Cloud…" |
| Format file | `cloud_config_invalid` → "Choose a valid **.hc or .oc** file." |
| Password config | `open_config_password_title` → "Config password"; `open_config_wrong_password` → "Wrong password"; `open_config_password_hint` → "Password" |
| Locked content | `locked_config_message` → "This config's content is locked and can't be viewed or edited. It is used only when connecting."; `one_cloud_create_lock_note` → "Config is fully locked (Lock all): customers can only connect, not view or edit it." |
| Legacy locked fields | `legacy_config_unlocked_fields_desc` → "Only the fields shown below can be changed." (host/port/username/password bisa diisi user: `config_notice_credentials_required`, `config_notice_server_required`) |
| Access ID (device binding) | `config_access_lock_desc` → "Only devices with the listed Access IDs can open this config. An internet connection is required to save a config with Access IDs."; `config_access_denied` → "This config does not allow this device's Access ID. Ask the creator to include your ID."; `config_access_recipients_invalid` → "Enter 1–100 valid Access IDs, one per line, without duplicates." |
| Hardware ID | `drawer_hardware_id` → "Hardware ID"; `open_config_hwid_blocked` → "This device isn't authorized for this config"; `hardware_id_dialog_message` → "Use this Hardware ID to authorise the device." |
| Extra protection | `config_extra_protection_desc` → "Requires online activation and a trusted device."; `config_extra_protection_denied` → "This device is not eligible to activate the protected config." |
| Root gate | `connect_block_extra_protection_root` → "Grant root access to use this protected config."; `open_config_root_blocked` → "This config can't be opened on a rooted device" |
| Mobile-data only | `connect_block_mobile_data` → "Turn off Wi-Fi, hotspot, and tethering. This config only works on mobile data." |
| SIM operator lock | `open_config_provider_blocked` → "This config is locked to a different SIM operator" |
| App blocklist | `open_config_application_blocked` → "This config can't be opened because an installed app is blocked by the config creator." |
| Runtime re-check | `open_config_runtime_blocked` → "Config reset — device no longer meets config protection" |

Cloud ("My Cloud", `cloud_config_*`):

- File .hc/.oc di-upload **dalam keadaan terenkripsi** ke server ePro Dev Team,
  tersedia **24 jam**, lalu link nonaktif (`cloud_config_summary` → "Files stay in
  the cloud for 24 hours.").
- Share link via domain **`eprdv.link`** — intent-filter `https://eprdv.link/.........`
  (9 karakter path, `autoVerify`) di `MainActivity`; "Anyone with your share link can
  import the file through HC; its protections still apply."
- Akses cloud dijaga **Play Integrity attestation**: `cloud_config_attestation_failed`
  → "Device security verification was unsuccessful. Cloud access cannot be granted yet.";
  `cloud_config_integrity_denied` → "This device does not meet cloud access requirements."
  (string `PrepareIntegrityTokenRequest{cloudProjectNumber=` + `cloud.prj` ada di dex).
- Menghapus file dari My Cloud menonaktifkan link-nya, tapi **tidak** menghapus
  salinan yang sudah di-download.

Import file (manifest `MainActivity`):

- `ACTION_VIEW` `content`/`file`, path `.*\.hc`, `.*\.yaml`, `.*\.yml`, `.*\.json`
  (sampai 4 level sub-ekstensi), MIME `application/x-hc-config`, `application/hc`,
  `application/x-httpcustom-config`, `application/httpcustom-config`,
  `application/httpcustom`, `application/octet-stream`, `application/json`,
  `application/yaml`, `text/yaml`, dst. + `ACTION_SEND` dengan MIME yang sama.
- Jadi selain `.hc`/`.oc`, app juga menerima config polos `.yaml`/`.yml`/`.json`
  (format Xray/V2Ray).

Layanan: `CustomVpnService` (foreground, `specialUse`, tidak di-export),
`VpnWatchdogJobService`, `ConnectionTileService` (Quick Settings tile, di-export),
`AssistDroid`/`AssistDroidSessionService` (IP finder, Digital Assistant / root),
`SyncProvider` (authority `xyz.easypro.httpcustom.core`, `exported=false`,
`initOrder=100` — semua method-nya `native`).

Permission penting: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`,
`FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE`, `QUERY_ALL_PACKAGES`
(dipakai proteksi app-blocklist), `READ_BASIC_PHONE_STATE`, `POST_NOTIFICATIONS`,
`HIDE_OVERLAY_WINDOWS`, `WAKE_LOCK`, `WRITE_EXTERNAL_STORAGE`.

## 5. FOKUS — MEKANISME DECRYPT CONFIG (.hc / .oc)

### 5.1 Yang terbukti dari kode

**a. Titik masuk dekripsi adalah native, bukan Java.**

- Tidak ada **satu pun** pemanggilan `javax.crypto.*` / `java.security.*` di kode
  aplikasi (`dev.epro.httpcustom`, 70 class). Xref seluruh dex: 0 pemakaian
  `Cipher`, `SecretKeyFactory`, `MessageDigest`, `KeyGenerator` di kode app.
- Tink di-shade sebagai `dev.epro.r0` (package Tink lengkap, termasuk
  `KeysetHandle`, `Aead`, `HybridEncrypt`, `StreamingAead`, dsb.) — tetapi xref
  menunjukkan **tidak ada** pemanggilan Tink dari kode aplikasi; Tink hanya
  dipakai library internal (kemungkinan DataStore/WorkManager), bukan untuk
  config. Lihat `dump/xref_tink.txt`, `dump/xref_cryptoutil.txt`.
- Seluruh alur import config (`MainActivity.onNewIntent` → parse → simpan profil →
  connect) diimplementasikan sebagai method `native`; `SyncProvider` (jalur
  berbagi profil antar komponen) juga 100% `native`.

**b. Entry point kripto native yang teridentifikasi: `HcrNativeCodec.transform`.**

Class `dev.epro.httpcustom.protocol.ssh.HcrNativeCodec`
(`dump/smali-app/protocol/ssh/HcrNativeCodec.smali`):

```smali
.method public static final native transform([B[BIJZI)Z
```

Signature: `transform(byte[] data, byte[] key, int a, long b, boolean c, int d) -> boolean`
— transform **in-place** pada `byte[]` (return boolean sukses/gagal), dengan
parameter: data, key (byte[]), satu `int`, satu `long`, satu `boolean`
(kemungkinan arah encrypt/decrypt), satu `int` (kemungkinan mode/algoritma).
Class ini singleton (`INSTANCE`, konstruktor privat memanggil native
`bikgltrptyrn()`), dan `<clinit>`-nya memanggil native
`cqbcgozgkzmi([Ljava/lang/Object;)I`. **Tidak ada pemanggil Java** untuk
`transform` di seluruh dex (lihat `dump/xref_transform.txt`) — ia dipanggil dari
native code (atau reflektif), konsisten dengan pemakaian internal oleh lapisan
DexGuard/SSH (nama class-nya `protocol/ssh` — dipakai di jalur SSH / obfuscated
SSH `deriveOSSHKey` / `newOSSHCipher` di `relaycore`).

**c. Lapisan string/kunci: DexGuard `szepgyrk`.**

Class `Lh/prnup/fnruxh/szepgyrk;` adalah pintu masuk runtime DexGuard:

- `longktebfdic0(I)V` — dipanggil dari `<clinit>` **setiap** class aplikasi dengan
  satu konstanta integer (mis. `MainActivity` → `0x48c`, `SyncProvider` → `0x469`).
  Ini pemicu dekripsi/registrasi per-class.
- `sd27913e872c5(I)Ljava/lang/String;` — dekripsi string berdasarkan indeks
  integer. Semua string sensitif (nama class, URL, kunci) **tidak ada** di dex
  sebagai plaintext — mereka didekripsi saat runtime.
- Class ini memuat `libf2c.so` (`System.loadLibrary("f2c")` di `<clinit>`-nya).

**d. Penyimpanan string/kunci terenkripsi di `libf2c.so`.**

- `.rodata` 8,7 MB (`0x8fbd0`, size `0x85560c`) — dimulai dengan tabel panjang
  (`u64`: 12, 8, 15, 61, 298, 363, …), diikuti tabel pasangan `(offset, length)`
  u32, diikuti blob entropi tinggi (entropi ~6,7 bit/byte pada offset `0x2643` —
  terenkripsi, bukan plaintext).
- `.data.rel.ro` memuat tabel raksasa: **22.193 pointer ke `.text`** dalam cluster
  berstruktur `[u64 meta][u64 fn_ptr]` berulang, dengan `meta` berpola dua u32
  (contoh `0x4b2000002643`, `0x521c00002344`, `0x407000002c78`, dan entri kecil
  `0x4e00000030`, `0x550000002f`) — tabel (offset,length,implementasi) untuk
  string/method yang didekripsi saat runtime. Tidak ditemukan **satu pun**
  `JNINativeMethod` statis (name, signature, fnPtr) dalam bentuk plaintext di
  `.data.rel.ro`/`.data` (scan relokasi `R_AARCH64_RELATIVE`/`ABS64`, lihat
  `dump/jni_tables.txt`) — tabel JNI dibangun dinamis oleh `JNI_OnLoad`.
- `JNI_OnLoad` `libf2c.so` @ `0xe57a58` (size `0xaa40`) dan `libcodec.so` @ `0x406c`
  (size `0x14748`, 20.946 instruksi) keduanya diawali trampoline obfuscate
  (`adr` + `eor` no-op + `br`) + stack canary + loop dekripsi byte-per-byte
  (pola `ldrb` → `add`/`eor` → `ror #0x1b/#0x1a/#0x19` → `mul` konstanta
  `0x85ebca6b` → `lsl #6` + `lsr #2`). Lihat `dump/disasm/libf2c_JNI_OnLoad_head.txt`
  dan `dump/disasm/libcodec_JNI_OnLoad_head.txt`, serta `dump/ptr_clusters.txt`.
- **Tidak ada** S-box AES maupun konstanta ChaCha `"expand 32-byte k"` di
  `libf2c.so` / `libcodec.so` / `libpolicy.so` — konstanta itu hanya ada di
  `libaio.so` (crypto standar Go untuk Xray) dan `libruntime.so` (ChaCha saja).
  Artinya cipher yang dipakai lapisan DexGuard/config **bukan AES/ChaCha
  standar yang dikenali dari tabel konstanta**, atau tabelnya ikut terenkripsi.

**e. Model kunci yang terbukti dari perilaku (strings.xml + manifest).**

- **Password config**: file `.hc`/`.oc` bisa diproteksi password yang dimasukkan
  user saat import (`open_config_password_title`, `open_config_wrong_password`).
  Password ini adalah input derivasi kunci file — tetapi fungsi derivasi (KDF)
  dan cipher-nya berada di native DexGuard, tidak terlihat statis.
- **Device binding**: kunci/akses terikat perangkat lewat **Access ID / Hardware ID**
  (1–100 ID penerima per config; butuh internet saat menyimpan config dengan
  Access ID — verifikasi server-side) dan **Extra protection** (aktivasi online +
  trusted device; butuh root saat connect).
- **Server-side enforcement**: proteksi tidak hanya lokal — aktivasi online,
  Play Integrity untuk cloud, dan re-check runtime
  (`open_config_runtime_blocked`).
- **Tidak ada sample config di APK**: `assets/` hanya berisi
  `PublicSuffixDatabase.list`, `dexopt`, `mcodes.json`, `oss_notices.md` —
  tidak ada `.hc`/`.oc` contoh, sehingga **round-trip decrypt→encrypt tidak
  dapat dibuktikan** dari artefak ini (tidak ada ciphertext + plaintext pasangan).

### 5.2 Yang TIDAK dapat dibuktikan dari REA statis ini (batasan jujur)

- **Algoritma cipher persis + KDF + letak byte kunci**: terkunci di dalam
  `libf2c.so` / `libcodec.so` / `libruntime.so` yang string, tabel JNI, dan
  (kemungkinan) body method-nya terenkripsi dan baru didekripsi saat runtime
  oleh `JNI_OnLoad` DexGuard. Menentukan cipher/KDF persis butuh eksekusi
  dinamis (menjalankan APK) — **di luar batas REA statis ini** (APK tidak
  di-install/dijalankan, sesuai aturan).
- **Tidak ada nilai kunci mentah yang ditulis di laporan ini** — sesuai pola REA
  save game sebelumnya (metode boleh, nilai kunci mentah tetap lokal). Dalam
  hal ini bahkan tidak ada kunci mentah yang berhasil diekstrak secara statis.
- Yang **bukan** mekanisme decrypt config (jangan dicampur): `deriveInproxyKey` /
  `sealInproxyPayload` / `openInproxyPayload` dan `deriveOSSHKey` /
  `newOSSHCipher` di `relaycore` (Go) adalah kriptografi **transport**
  (Inproxy & obfuscated-SSH saat koneksi berjalan), bukan dekripsi file `.hc`.
  Crypto transport Xray (TLS/VLESS/VMess/Trojan/Shadowsocks/WireGuard) juga
  terpisah dari enkripsi file config.

### 5.3 Ringkasan mekanisme (yang dapat dipertanggungjawabkan)

1. File `.hc`/`.oc` = **blob terenkripsi** (bukan JSON/YAML polos; JSON/YAML polos
   diterima sebagai jalur import terpisah).
2. Saat import, `MainActivity` (native) membaca file → meminta **password**
   bila file diproteksi → dekripsi dilakukan di **lapisan native DexGuard**
   (`libf2c.so`/`libcodec.so`, via `HcrNativeCodec.transform`-family dan
   string runtime `szepgyrk.sd27913e872c5`) → profil hasil dekripsi disimpan
   ke **Room + SQLCipher** (DB terenkripsi) → dipakai `CustomVpnService` saat
   connect (diteruskan sebagai config ke Go `relaycore.parseConfig` /
   `xray.loadConfig`).
3. Proteksi berlapis di atas enkripsi file: password → Access ID/Hardware ID
   (device binding, cek online) → Extra protection (aktivasi online + trusted
   device + root saat connect) → kunci operator/SIM, blocklist aplikasi,
   mobile-data-only, dan re-check runtime. Cloud (`eprdv.link`, 24 jam) hanya
   mendistribusikan blob yang **sudah terenkripsi**, dijaga Play Integrity.

## 6. Alur data config (ringkas)

```
.hc/.oc (file / share-link eprdv.link / My Cloud 24j)
  → MainActivity.onNewIntent (native, intent VIEW/SEND)
  → password? (open_config_password_title) → decrypt native (DexGuard libf2c/libcodec)
  → cek proteksi: Access ID / HWID / Extra protection (online) / operator / root / app-blocklist
  → simpan profil → Room + SQLCipher (ProfileDatabase)
  → connect: CustomVpnService → Go relaycore.parseConfig / xray.loadConfig
  → tunnel: Xray (VLESS/VMess/Trojan/SS/WG/Hysteria) / SSH obfuscated / SlowDNS / UDP-Custom
```

## 7. Isi dump ini

```
xyz.easypro.httpcustom/8.1.5/
├── REA-HTTP-Custom-8.1.5.md        (laporan ini)
└── dump/
    ├── AndroidManifest.xml         (decoded apktool 2.10.0)
    ├── strings.xml                 (res/values/strings.xml, 1.960 string)
    ├── hashes.txt                  (SHA-256 .apkm / base.apk / split arm64)
    ├── smali-app/                  (70 file smali kode aplikasi dev.epro.httpcustom)
    ├── go_epro_funcs.txt           (689 simbol Go dev.epro/* dari libaio.so)
    ├── go_aio_mobile.txt           (158 simbol JNI Go dev.epro/aio/mobile)
    ├── elf_info.txt                (section header semua .so arm64)
    ├── jni_tables.txt              (hasil scan tabel JNI statis — kosong, bukti runtime-build)
    ├── ptr_clusters.txt            (cluster pointer .data.rel.ro libf2c/libcodec/libruntime)
    ├── xref_transform.txt          (xref HcrNativeCodec.transform — tanpa pemanggil Java)
    ├── xref_tink.txt / xref_cryptoutil.txt (bukti tidak ada pemakaian Tink/Cipher di kode app)
    └── disasm/
        ├── libf2c_JNI_OnLoad_head.txt
        └── libcodec_JNI_OnLoad_head.txt
```

## 8. Batasan & catatan

- REA **statis** saja: tidak install, tidak run, tidak ada traffic yang diamati.
- **Tidak** berburu bug host operator / kredensial SSH hidup dari config hasil
  decrypt — yang dilaporkan hanya mekanismenya.
- Tidak ada sample `.hc` di APK → tidak ada bukti round-trip.
- Cipher/KDF persis file `.hc` **belum teridentifikasi** — butuh analisis dinamis
  (di luar ruang lingkup tugas ini); semua klaim di atas adalah yang terbukti
  dari jejak kode, bukan tebakan.
