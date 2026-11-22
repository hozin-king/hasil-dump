> Catatan arsip: Package meniru Disney — bukan aplikasi Disney. Ini mod tool Free Fire TH ('VortexHub'), bukan aplikasi proxy umum.

# REA + AUDIT — PROXY_ANDROID_5.2.apk

**Tanggal:** 17 Nov 2026 · **Analisis:** statis saja (tanpa Ghidra/Hopper/IDA; JADX 1.5.3 terpasang khusus untuk audit ini) · **APK tidak pernah dijalankan**

## 1. Identitas

| Item | Nilai |
|---|---|
| File | `PROXY_ANDROID_5.2.apk` (MediaFire `7lu8efrq4j8sxfi`, dkey sama) |
| Ukuran | 15.569.316 byte |
| SHA-256 | `939728915fbe4e4eaeea383aa52b0022aff18a88c4e1b726f53675ade2094e6e` |
| MD5 | `90bf47e6a5111826b25b81bd32ca1d83` |
| Package | `com.disney.app` (nama meniru Disney — bukan aplikasi Disney) |
| versionName / versionCode | `5.2` / `1` |
| minSdk / targetSdk / compileSdk | 21 / 34 / 34 (platform 14) |
| Label | `PROXY ANDROID ` |
| Penanda tangan | **Kunci uji publik AOSP** — `CN=Android, EMAILADDRESS=android@android.com`, SHA-256 cert `a40da80a59d170caa950cf15c18c454d47a39b26989d8b640ecd745ba71bf5dc` (kunci `testkey` yang dipakai semua orang; bukan identitas developer asli) |
| Dibangun dengan | Sketchware (`SketchApplication`; UI blok + library `AndroidSketchwareMaster`) |
| Bahasa dasar | Portugis (Brasil), dengan terjemahan EN/ES/PT via API MyMemory |
| Isi | 64 file `.dex`, **0 file `.so` native**, 861 file `res/`, `resources.arsc`, dump 29 MB |

## 2. Vonis utama

**Ini bukan aplikasi proxy umum. Ini adalah *mod tool* Free Fire TH (Thailand, `com.dts.freefireth`) bermerek "VortexHub" / "Vortex", dari channel "Vanz Settings", didistribusikan lewat blog "Maharna Mods".**

Cara kerjanya ada tiga lapis, dan semuanya terbukti dari kode + aset:

1. **Injeksi file via Shizuku** — menyalin patch game + config palsu ke direktori privat Free Fire, menembus scoped storage dengan hak shell level-sistem.
2. **Spoofing version-check** — `localConfig.json` palsu mengarahkan alamat pemeriksaan versi game ke server milik modder (`http://2.25.132.119:2223`, `fakeVersion: "1.0"`).
3. **VPN lokal "VortexVpn" + blokir iklan DNS** — VpnService yang hanya me-routing 14 IP hardcoded + memblokir domain iklan/tracking. **Namun VPN ini rusak (lihat §5).**

Aplikasi dikunci lisensi **KeyForge** (key + HWID perangkat) sebelum panel bisa dibuka.

## 3. Alur aplikasi

`IdiomaActivity` (pilih bahasa, launcher) → `MainActivity` (splash 0–100% + toast "By Vortex") → `Main2Activity` (gerbang lisensi KeyForge; minta izin overlay) → `Main3Activity` (panel utama). `DebugActivity` hanya layar crash Sketchware. `SecurityInitProvider` menjalankan cek anti-debug/emulator/root saat start (hasilnya dibuang — lihat §7).

## 4. Mekanisme 1 — Injeksi file via Shizuku (inti "proxy"-nya)

`Main3Activity` (tombol "Ativar") melakukan ini, semuanya lewat `Shizuku.newProcess(["sh","-c", ...])`:

- Menyalin isi `assets/S1/` (dan `assets/S3/` untuk opsi Bypass) dari APK ke folder temporer, lalu `cp -R` ke **`/storage/emulated/0/Android/data/com.dts.freefireth/files/`** — direktori privat Free Fire yang normalnya tidak bisa ditulis aplikasi lain di Android 11+. Shizuku (hak `system`) yang menembusnya. Syarat: Shizuku harus aktif + izin diberikan, kalau tidak muncul "Shizuku nao esta conectado".
- **30 detik setelah penyalinan, `localconfig.json` di folder game dihapus** (`rm -rf .../files/localconfig.json`) — pola bersih-bersih/penghindar deteksi.
- Opsi ketiga (f84c) **menulis `localConfig.json` palsu** ke folder game, isinya persis:
  ```json
  {
  "verAddr":"http://2.25.132.119:2223/aalto/false/false/false/false/false/false/false/false/",
  "fakeVersion":"1.0"
  }
  ```
  `verAddr` adalah alamat yang dipakai game untuk cek versi/maintenance. Dengan ini game diarahkan ke server modder, dan versi dipalsukan jadi "1.0" — gerbang versi/login game diloloskan dari server yang dikendalikan modder.
- Setelah semua selesai, game diluncurkan paksa via Shizuku: `monkey -p com.dts.freefireth -c android.intent.category.LAUNCHER 1`, toast "Injeção enviada!". Bila Free Fire belum terpasang, tombol lain membuka halaman Play Store-nya.

## 5. Mekanisme 2 — Patch IFix "KMADB" ESP + headshot (aset S1)

`assets/S1/Assembly-CSharp-patch.bytes` (40.178 byte) adalah **hot-patch IFix** (framework `IFix.Core.PatchManager`) untuk `Assembly-CSharp, Version=0.86.0.518`, namespace **`COW.*`** — game targetnya Free Fire TH (patch ini yang disalin ke folder game pada §4). String yang terbukti di dalam patch:

- `KM ADB Teste 3 ESP`, `KM ESP`, `KMADB_SERVER_ERROR`, `__KMADB3_AppliedHead`, `__KMADB_Head`, `__KMADB_Server`, `get_HeadCollider`, `GetHeadTF` → **ESP + manipulasi head-collider (headshot/aimbot)**.
- `WorldToScreenPoint`, `GetMainCamera`, `CurrentLocalPlayer`, `CurrentGame`, `IsLocalPlayer`, `IsLocalTeammate`, `get_CurHP`, `get_IsReallyDead`, `IsVisible`, `FindObjectsOfType`, `Distance` → ekstraksi data pemain (posisi, HP, hidup/mati, terlihat) untuk overlay ESP.
- `Socket`, `Listen`, `BeginAccept`, `Receive`, `Loopback` → patch membuka **socket server di loopback** yang dibaca aplikasi overlay eksternal ("KM ADB" — ESP berbasis ADB).
- `ReadUrlFromLocalConfig`, `ReadAllText`, `get_persistentDataPath` → patch membaca `verAddr` dari `localConfig.json` yang dipalsukan di §4.
- `assets/S3/localConfig.json` berisi `{"resetGuest":true}` → **reset akun guest** (klasik untuk lepas dari ban akun guest). `assets/S1/localConfig.json` berisi `{"testCodePatch":true}`.

## 6. Mekanisme 3 — VPN "VortexVpn" (rusak + kosmetik)

Implementasi asli ada di `Main3Activity$a extends VpnService implements Runnable`:

- `onStartCommand` merespons aksi `ATIVAR` / `DESATIVAR` (Portugis). Thread `VortexVpnThread` membangun antarmuka: session `VortexHub`, alamat `10.255.255.1/24`, dan **14 route /32 hardcoded**: `202.81.97.157`, `202.81.96.8`, `202.81.97.159`, `202.81.87.163`, `143.92.125.134`, `154.223.134.27`, `148.222.71.22`, `8.218.96.148`, `34.104.35.84`, `34.126.239.123`, `35.187.246.126`, `108.158.194.35`, `172.217.29.131`, `3.174.29.69` (campuran IP Garena `202.81.x.x`, Google Cloud `34.x`, CloudFront `108.158.x`, Google `172.217.x`). Hanya IP-IP itu yang masuk tunnel.
- Blokir DNS/iklan: paket port 53 diurai nama domainnya (parser DNS manual); domain `doubleclick.net`, `googlesyndication.com`, `pubmatic.com`, `adservice.google.com`, `analytics.google.com` dibuang, plus regex untuk iklan YouTube/Spotify (`(youtube|spotify).*[-_](ads?|adserver|adtrigger)`), tracking (`ptracking|ad_status|doubleclick|pagead/adview`), dan `^ads?[-.]`. Paket lain (port 80/443, atau <40 byte) hanya ditulis balik ke tun fd (pass-through, **bukan forwarding sungguhan** — tidak ada socket keluar, tidak ada proxy upstream).
- **CACAT FATAL — manifest vs kode tidak cocok.** Manifest mendeklarasikan service `.MainActivity$VortexVpn` (dengan `BIND_VPN_SERVICE`), tapi **kelas itu tidak ada di dex mana pun** (hanya muncul 1× sebagai string). Implementasi aslinya `Main3Activity$a` **tidak dideklarasikan di manifest**. Kode memanggil `startService(new Intent(ctx, Main3Activity$a.class))` dengan aksi `ATIVAR` — di Android, service yang tidak dideklarasikan tidak bisa di-start. Jadi **VPN ini hampir pasti gagal start / crash saat dipakai**; yang benar-benar bekerja adalah injeksi file Shizuku (§4). Ada juga fitur "fake_lag" (JSON `fake_lag`: `ativo`, `duracao_ms`, `intensidade_pacotes`) — callback-nya didefinisikan tapi **tidak pernah dipanggil** (dead code).

## 7. Temuan keamanan / privasi

1. **TLS dimatikan total.** `defpackage/b.java` (OkHttp): `X509TrustManager` trust-all (check kosong, issuer kosong) + `HostnameVerifier` selalu `true`. **Semua HTTPS aplikasi bisa di-MITM** — termasuk panggilan API terjemahan dan validasi lisensi.
2. **Shizuku = hak shell level-sistem.** Aplikasi ini meminta dan memakai Shizuku untuk menulis ke direktori privat aplikasi lain. Memberi izin Shizuku ke APK ini berarti memberinya kemampuan menulis/menghapus file di folder data Free Fire (dan secara teknis perintah shell apa pun yang dieksekusi via `sh -c`).
3. **Server modder di tengah jalur game.** `verAddr` palsu (`2.25.132.119:2223`) berarti pemeriksaan versi/login game melewati server yang dikendalikan pihak ketiga — server itu bisa dimatikan kapan saja (fitur mati) atau dipakai untuk mencatat/memanipulasi. IP ini HTTP (bukan HTTPS).
4. **Lisensi KeyForge mengikat perangkat.** `Main2Activity`: key dimasukkan pengguna, HWID dibangun dari `android_id` (`KEYFORGE|ANDROID|<android_id>`, fallback UUID `install_id` bila emulator). Status: `KEY_NOT_FOUND`, `KEY_REVOKED`, `KEY_EXPIRED`, `HWID_MISMATCH`, `INVALID_INPUT`, `manutenção`. Key yang valid disimpan sebagai `pass` di SharedPreferences. **URL server lisensi tidak ditemukan dalam bentuk plaintext — disembunyikan di balik enkripsi string NPStringFog** (lihat §9).
5. **Popup pemaksa saluran (social engineering).** `Hub/…` (classes64.dex, nama kelas karakter Odia `ରାଧେକୃଷ୍ଣ`): dialog **tidak bisa di-cancel** berisi "MASUK SALURAN VANZ SETTINGS BIAR PANEL NYA WORK 100%" — tombol membuka channel WhatsApp `0029VbCeE8n65yDEcAG8mW2w`; tombol lain menyebar teks spam "…(App Name) Mod Apk … Free Premium … Download using this link 👉 https://maharnamods.blogspot.com". Muncul sampai 10× (counter `Krushna` di SharedPreferences).
6. **Anti-analisis dangkal.** `defpackage/c.java`: cek debugger (`Debug.isDebuggerConnected`), emulator (fingerprint/model/product), root/Magisk (`/system/xbin/su`, `/sbin/su`, `/data/adb/magisk`, `/data/adb/modules`, `test-keys`). Dijalankan saat start via `SecurityInitProvider`, **tetapi hasilnya dibuang** (tidak dipakai untuk menghentikan aplikasi) — kemungkinan vestigial atau pemicu di build lain.
7. **Identitas palsu + kunci publik.** Package `com.disney.app` meniru Disney; signer kunci uji AOSP (siapa pun bisa menandatangani APK seperti ini); `versionCode` 1 untuk "v5.2" (penomoran tidak konsisten — ciri repack).
8. **Opsi rusak.** `assets/S2/` tidak ada di APK, jadi opsi mode kedua selalu error ("pasta assets/S2 vazia ou inexistente"). `fake_lag` dead code (§6).
9. **Tidak ada native code** (0 `.so`) — semua logika di Java/Kotlin + patch .NET IFix.
10. **Risiko ban game.** Injeksi patch ke folder game + spoofing version-check + reset guest adalah tepat pola yang dideteksi anti-cheat Free Fire (Bifrost/GGP). Tidak ada bukti bypass anti-cheat di APK ini — patch IFix bekerja di level game, bukan menyembunyikan diri dari deteksi.

## 8. Endpoint & string tertanam (terbukti)

| String | Sumber | Fungsi |
|---|---|---|
| `http://2.25.132.119:2223/aalto/false/...` | `Main3Activity.java:1082` + patch | Server verAddr palsu (versi/login game) |
| `https://api.mymemory.translated.net/get` | `MainActivity`/`Main2Activity`/`Main3Activity` | API terjemahan UI (PT↔EN/ES) |
| `https://maharnamods.blogspot.com` | `Hub/C0000.java` | Blog distributor mod |
| `https://whatsapp.com/channel/0029VbCeE8n65yDEcAG8mW2w` | `Hub/C0000.java`, `Main2Activity.java:327` | Channel "Vanz Settings" |
| `https://play.google.com/store/apps/details?id=com.dts.freefireth` | `Main3Activity.java:1320` | Play Store Free Fire TH |
| `com.dts.freefireth` | banyak | Target game |
| 14 IP route VPN | `Main3Activity$a.run()` | §6 |
| Server lisensi KeyForge | — | **Tidak ditemukan (string-fog)** |

Tidak ditemukan: kredensial/token hardcoded lain, kunci API, atau exfiltrasi data pengguna di luar HWID + key validasi.

## 9. Batasan analisis

- **Statis saja** — APK tidak dijalankan, tidak ada observasi runtime; perilaku VPN saat start (§6) disimpulkan dari manifest + kode, bukan dari percobaan.
- **String terenkripsi (NPStringFog).** `classes52.dex` berisi `nplus/n/p/NPStringFogPlus`; sebagian string (termasuk URL server lisensi KeyForge dan kemungkinan endpoint lain) di-deobfuscate saat runtime dan tidak terlihat di `strings`. Jadi daftar endpoint §8 kemungkinan **tidak lengkap**.
- **JADX 2 error** saat decompile (dari 8 file yang diproses): 1 metode `Main3Activity$a.a(byte[],int)` gagal di-decompile (ditampilkan sebagai bytecode; masih bisa dibaca — parser DNS) dan 1 error lain yang tidak memengaruhi kelas inti. Nama kelas `Hub` memakai karakter Unicode (jadx menamainya `C0000`).
- Identitas game dari patch (`COW.*`, Assembly-CSharp 0.86.0.518) disimpulkan sebagai Free Fire TH karena patch itu dipasang ke folder `com.dts.freefireth` oleh aplikasi itu sendiri — namespace internal game tidak diverifikasi ke sumber independen.

## 10. Inventaris dump

- `PROXY_ANDROID_5.2.apk` (asli, terverifikasi `unzip -t` bersih)
- `page.html` (halaman MediaFire sumber link unduhan)
- `badging.txt` (`aapt dump badging`), `manifest.txt` (`aapt dump xmltree AndroidManifest.xml`)
- `dump/` — isi APK ter-unzip (64 dex, `assets/S1/Assembly-CSharp-patch.bytes` + `localConfig.json`, `assets/S3/localConfig.json`, `assets/StorageInfo*.json`, font, `res/`, `resources.arsc`, `META-INF/`)
- `jadx-src/` — hasil decompile JADX atas `classes63/64/61/62.dex` (kode aplikasi + Hub + library; 37 file Java)
- `jadx.log` — log decompile
