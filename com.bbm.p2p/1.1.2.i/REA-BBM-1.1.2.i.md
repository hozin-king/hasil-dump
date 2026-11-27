# REA — BBM (com.bbm.p2p) v1.1.2.i

- **Tanggal REA:** 27 November 2026 (WIB)
- **Metode:** statis saja (jadx 1.5.1 + apktool 2.10.0 + strings/capstone). APK **tidak** diinstal/dijalankan.
- **File:** `bbm-v1.1.2.i-release.apk` — 44.928.677 byte
- **SHA-256:** `1d3b3f8dff92ea0438771f739b22bdf564e76857e9e848cb2cfe75688956c6dc`
- **Hasil:** dump + REA selesai. APK sumber **TIDAK dihapus** (aturan 27 Nov 18:40).

---

## 1. Identitas

| Item | Nilai |
|---|---|
| Package | `com.bbm.p2p` |
| Version | `1.1.2.i` (versionCode 68) |
| App label | BBM |
| minSdk / targetSdk | 23 / 34 (compileSdk 34) |
| Bahasa/framework | Kotlin 1.8.10, Gradle 7.6.4 |
| Dex | satu `classes.dex` (±1,8 MB), 1154 file hasil jadx |
| Native lib | hanya `libjingle_peerconnection_so.so` (WebRTC, 11.377.336 byte, stripped) — 4 ABI |
| Activities / services / receiver / provider | 13 / 3 / 1 / 2 |
| Permissions | 16 |
| Aset penting | `assets/wordlist_en.txt` = daftar kata BIP39 (2048 kata) |

### 1.1 BUKAN BBM resmi BlackBerry

Package resmi BlackBerry Messenger adalah `com.bbm`. Aplikasi ini memakai
`com.bbm.p2p` dan sertifikat **self-signed** dengan identitas:

- CN=Huqsakamara, O=Huqsakamara, L=Lampung, ST=Bandar Lampung, C=35154
- Sertifikat dibuat 26 November 2026 (sehari sebelum APK ini beredar)

Jadi ini aplikasi **clone/komunitas buatan developer individu Indonesia**
(Huqsakamara, Lampung), bukan produk BlackBerry. Nama "BBM" di sini meniru
merek lama, bukan afiliasi resmi.

### 1.2 Aktivitas (13)

Tambah Kontak, Profil Saya, Pengaturan, "Masuk dengan Frasa Pemulihan"
(`RestoreActivity`), Undangan Baru, Broadcast, Pembaruan (feed/berita),
Story, Panggilan, Grup, Scan Barcode, Chat, Main.

### 1.3 Layanan (3)

- `KeepAliveService` — foreground service (notifikasi id 4711), "Menjaga
  koneksi chat P2P (WebRTC DataChannel + WebSocket signaling) tetap hidup".
- `MusikListenerService` — `NotificationListenerService`, "BBM Now Playing"
  (membaca lagu yang sedang diputar dan membagikannya ke kontak).
- Satu service panggilan WebRTC (via `e0`).

---

## 2. Arsitektur: hybrid WebRTC P2P + signaling server

```
  [App A] ---- WebSocket ws:// (signaling) ----> [Server 103.89.2.86:3002]
     |   <--- presence / invite / SDP / ICE ---      |
     +---- WebRTC DataChannel "bbm-chat" (DTLS) ----+  (via TURN bila perlu)
     +---- WebRTC audio/video call -----------------+
```

- **Pesan/chat/file/panggilan:** peer-to-peer lewat WebRTC DataChannel
  (label `"bbm-chat"`, `l0.java:328`) dan media WebRTC (`e0.java`,
  `org.webrtc.*`). Kirim: `l0.java:367`
  `dataChannel.send(new DataChannel.Buffer(ByteBuffer.wrap(bArr), false))`.
  Terima: `r0.java:49 onMessage` → dispatcher `a.Y(String pin, byte[])`
  (`a.java:2257`).
- **Signaling:** WebSocket ke server pusat. Client WebSocket **buatan tangan**
  (`s0.java`): raw `Socket`, handshake HTTP Upgrade manual, validasi
  `Sec-WebSocket-Accept` dengan SHA-1 (RFC 6455 standar).
- **Server default (hardcoded):** `http://103.89.2.86:3002`, bisa diubah user
  lewat preference key `"server"` (`j.R()`/`j.v()`).
- **REST:** helper `j.H(path, JSONObject)` = POST JSON
  (`Content-Type: application/json`, timeout 10 detik, **tanpa header
  Authorization** — auth dibawa di body JSON berupa `pin`/`token`).
  `j.v(path)` = GET. Bukti smali: `decoded/smali/androidx/activity/j.smali`,
  method `H`.
- **Endpoint REST yang terlihat di kode:**

| Endpoint | Fungsi |
|---|---|
| `POST /bbm/daftar` | Registrasi: `{nama, status, seedHash?}` → server mengembalikan `{pin, token, nama}` |
| `POST /bbm/ikat-seed` | Ikat frasa pemulihan ke akun: `{pin, token, seedHash}` |
| `GET/POST /bbm/profil?pin=` | Profil/status kontak |
| `GET /bbm/turn?pin=&token=` | Kredensial TURN: `{urls, username, password, stun, ttl}` |
| `ws://<host>/bbm/ws` | Signaling WebSocket |

- **TURN/STUN:** default STUN `stun:stun.l.google.com:19302`, TTL default
  86400 detik. Kredensial TURN diambil dari server per sesi.
- **TIDAK ADA TLS pada signaling:** `s0.java` **melempar error
  "hanya ws:// didukung, bukan \<scheme\>" bila skema bukan `ws`** — `wss://`
  **tidak didukung**. REST juga HTTP biasa. Manifest
  `usesCleartextTraffic=true`. Artinya seluruh signaling (termasuk PIN,
  token, SDP, dan pengumuman identitas) berjalan **cleartext**.

---

## 3. Identitas, PIN, dan frasa pemulihan

- **PIN = 8 karakter, diterbitkan server** (bukan dibuat lokal).
  Registrasi (`o0/u0.java` case 1): `POST /bbm/daftar` → respons berisi
  `pin` + `token` → disimpan via `o0/l.o()` ke SharedPreferences.
- **Identity hash** = SHA-256 hex dari PIN (`androidx.activity.j.I()`).
  Dipakai sebagai alamat identitas di signaling (bukan PIN mentah).
  Pemetaan hash→PIN disimpan lokal di `a.f1039j` (`a.L()`).
- **Announce** (saat connect, `a.java` sekitar baris 630):
  `{"type":"announce","hash":<sha256(pin)>,"ts":<unix>,"sig":HMAC-SHA256(key=hex-decode(sesi_secret), msg="<hash>.<ts>")}`
  dan respons server `announceok`.
- **Presence:** server mendorong `{"type":"presence","online":[hash,...]}`;
  aplikasi menyimpan set hash online di `a.c` (`a.java:663`). Saat kontak
  keluar dari daftar online, status musiknya ikut dimatikan (`o0/l.p`).
- **Frasa pemulihan = BIP39 standar, 12 kata** (`o0/m2.java`):
  16 byte entropi acak (`SecureRandom`) + 4 bit checksum (byte pertama
  SHA-256 entropi) → 12 kata dari `wordlist_en.txt`.
  `m2.d()` memvalidasi 12 kata, merekonstruksi entropi, mengembalikan
  **SHA-256 hex entropi** (= `seedHash`).
- **Restore** (`RestoreActivity`): frasa → `seedHash` → dikirim ke server
  → server mengembalikan `pin`/`token`/`nama`/`status` lama. Jadi
  **pemetaan frasa→PIN hidup di server**, bukan derivasi lokal.
- **Session secret** (`sesi_secret`, `sesi_expires`): dibaca di `a.c0()`
  (`a.java:3417`/`4221`); bila secret masih ada dan masa berlaku > 60 detik
  dipakai ulang, kalau tidak minta baru via thread `androidx.activity.b`
  case 4. **Lokasi tulis pastinya tidak ketemu di hasil dekompilasi
  (UNPROVEN)** — kemungkinan besar diterbitkan server saat login/announce.

---

## 4. Protokol pesan (DataChannel, JSON plaintext)

Semua pesan adalah **JSON plaintext** lewat DataChannel. **Tidak ada
enkripsi end-to-end di lapisan aplikasi** — kerahasiaan hanya mengandalkan
transport DTLS WebRTC (dan signaling justru cleartext ws/HTTP).

Tipe pesan (`"t"`) yang ditangani dispatcher `a.Y()` / `a.c()`:

| Tipe | Arti |
|---|---|
| `msg` | Pesan teks: `{id, teks, ts, ping, kutip, lokasi}` |
| `read` | Tanda dibaca: `{id}` — masuk → status pesan jadi `"R"` (`o0/l.D`, `a.java:2672`); keluar dikirim saat chat dibuka (`a.java:1546`) |
| `typing` | Indikator mengetik |
| `invite` / `inviteok` | Undangan tambah kontak (berisi PIN) |
| `story` | Story |
| `berkas` | File: `{id, nama, mime, ukuran, berkasPath}` |
| `signal` | SDP/ICE lewat WebSocket (via `a.K`) |
| `announce` / `announceok` / `presence` | Registrasi kehadiran + daftar online |
| `hello` | Sapaan awal berisi PIN + nama |
| `statusProfil` / `lokalBerubah` | Perubahan profil/status |
| `ruangPesan`, `ruangKirimMulai`, `ruangKirimData`, `ruangKirimEnd` | Pesan + file grup (file dikirim per-chunk Base64) |
| `ruangHadir`, `ruangOk`, `ruangInfo`, `ruangError`, `ruangDikeluarkan`, `ruangPelan` | Manajemen grup (gabung/keluar/dikeluarkan/dll) |
| `ruangMasuk` | Masuk grup via PIN |
| `ping` | Keepalive |
| `sesi` | Terkait sesi |

- **Status pesan lokal:** `"antre"` (queued) dan `"R"` (read). Tidak ada
  status "terkirim/delivered" terpisah yang terlihat.
- **Grup:** disimpan di preference `"grup"` (`o0/t0.java`); tautan undangan
  `bbm://grup?g=<12 hex>&n=<nama>`.
- **Tidak ada fitur hapus/revoke pesan.** String "hapus" di aplikasi hanya
  muncul sebagai "Hapus foto". Tidak ada pesan anti-revoke yang bisa
  dimatikan karena fiturnya memang tidak ada.
- **File:** metadata JSON + transfer chunk Base64 lewat DataChannel;
  file tersimpan dengan `berkasPath` di JSON pesan.
- **Story:** file mentah di `filesDir/story`; pratinjau tautan (`j0.java`)
  mengambil meta OG dan mengunduh gambar (cap 700 KB) ke cache.
- **Lokasi:** dibagikan sebagai tautan `https://maps.google.com/?q=`
  + tile `https://tile.openstreetmap.org/16/`.
- **Musik (Now Playing):** `MusikListenerService` membaca notifikasi
  pemutar musik; status lagu per kontak disimpan di `musikKontak`,
  lagu sendiri di `musikSaya`.

---

## 5. Penyimpanan lokal — semuanya plaintext

**Seluruh data aplikasi ada di SATU file SharedPreferences biasa
`"bbm_p2p"` (MODE_PRIVATE, tanpa enkripsi)** — `o0/l.java` adalah satu-satunya
lapisan storage. Tidak ada SQLite/Room/SQLCipher, tidak ada
`EncryptedSharedPreferences`, tidak ada Android Keystore.

| Key | Isi |
|---|---|
| `pin` | PIN 8 karakter sendiri (plaintext) |
| `token` | Token server (plaintext) |
| `nama`, `status`, `statusTs` | Nama + status profil |
| `seed` | Frasa pemulihan 12 kata (plaintext!) |
| `seedTerikat` | Flag frasa sudah diikat ke server |
| `sesi_secret`, `sesi_expires` | Secret HMAC sesi + masa berlaku |
| `server` | Alamat server (default `http://103.89.2.86:3002`) |
| `kontak` | JSON array `{pin, nama, minta}` |
| `pesan` | JSON object `pin → [pesan...]`, dibatasi 200 pesan/kontak |
| `undangan` | Undangan masuk `{pin, nama, ts}` |
| `grup` | Data grup (via `o0/t0.java`) |
| `pembaruan` / `feed` | Feed/berita dari server |
| `musikKontak`, `musikSaya` | Status lagu |
| `fotoTs` | Timestamp foto profil |
| `keepAlive` | Preferensi keep-alive |

- **File media:** story di `filesDir/story` (mentah); cache pratinjau
  tautan di direktori cache (nama file = SHA-256 URL, TTL 6 jam).
- **Risiko langsung:** `allowBackup=true` di manifest — seluruh isi di atas
  (termasuk PIN, token, frasa pemulihan, dan SEMUA pesan) bisa diambil lewat
  `adb backup` / akses root tanpa hambatan apa pun.

---

## 6. Proteksi — praktis tidak ada

| Proteksi | Hasil |
|---|---|
| Obfuscation | R8/minify: nama class/method 1 huruf (`a`, `e0`, `j`, `l`, `m2`, `s0`, `l0`, `r0`, paket `o0`/`x0`). String TIDAK dienkripsi, struktur utuh — jadx mendekompilasi bersih |
| Certificate pinning | **Tidak ada** |
| Network security config | **Tidak ada file** |
| Root detection | **Tidak ada** (dex tidak mengandung string root/Magisk/SuperSU/busybox) |
| Frida/Xposed/LSPosed detection | **Tidak ada** (tidak ada string `xposed`, `lsposed`, `de.robv`, `frida`) |
| Play Integrity / SafetyNet | **Tidak ada** |
| Anti-tamper / signature check | **Tidak ada** |
| Cleartext | `usesCleartextTraffic=true`; signaling ws:// saja; REST HTTP saja |

Satu-satunya "perlindungan" adalah minifikasi nama dan fakta bahwa pesan
berjalan di atas DTLS WebRTC. Dari sisi modding, aplikasi ini praktis
terbuka.

---

## 7. Inventaris crypto

| Algoritma | Pemakaian | Lokasi |
|---|---|---|
| SHA-256 | Hash identitas PIN; `seedHash`; nama file cache | `j.I()`, `m2.d()`, `j0` |
| HMAC-SHA256 | Tanda tangan announce (`<hash>.<ts>`, key = hex-decode `sesi_secret`) | `a.java` (announce) |
| PBKDF2-HmacSHA256, 60.000 iterasi, 256-bit | Kunci enkripsi file cadangan | `j.C()` |
| AES-256-GCM | File cadangan `BBMBAK1` | `j.r()` (export) / `j.B()` (import) |
| BIP39 (12 kata, 128-bit entropi + 4-bit checksum) | Frasa pemulihan | `o0/m2.java`, `assets/wordlist_en.txt` |
| SHA-1 | Validasi `Sec-WebSocket-Accept` (RFC 6455) | `s0.java` |
| DTLS-SRTP (WebRTC) | Transport DataChannel/media | `libjingle_peerconnection_so.so` |
| SecureRandom | Entropi frasa | `m2.java:32` |

### Format cadangan `BBMBAK1` (terbukti dari `j.r()`/`j.B()`)

```
magic "BBMBAK1" (7 byte) || IV GCM 12 byte || AES-256-GCM(JSON)
JSON: {"v":1, "app":"bbm-p2p", "pin", "nama", "waktu", "kontak":[{pin,nama}]}
kunci = PBKDF2(password = frasa 12 kata ternormalisasi,
               salt = 16 karakter pertama seedHash hex,
               iterasi 60000, 256-bit)
```

---

## 8. Apa yang bisa dibikin ala WA Enhancer

Konteks: WA Enhancer adalah modul LSPosed untuk WhatsApp resmi. Di bawah ini
tiap fitur dinilai **terhadap arsitektur nyata BBM ini**, bukan ditempel dari
daftar WA. Catatan umum: karena **tidak ada deteksi Xposed/Frida/root dan
tidak ada integrity check**, hooking LSPosed secara teknis sangat mudah;
hambatan utamanya adalah nama method yang diobfuscate R8 (hook harus
berpatokan pada signature/pola smali, rapuh antar versi), dan fakta bahwa
sebagian perilaku (online, presence) dikendalikan server.

| # | Fitur | Bisa? | Bukti + kesulitan |
|---|---|---|---|
| 1 | Sembunyikan status online | **Sebagian / sulit** | Online ditentukan server dari `announce` + daftar `presence` (`a.java:663`, set `a.c`). Menghilangkan announce = server tidak bisa merutekan sinyal ke kita (pesan/panggilan masuk bisa gagal). Menyembunyikan *tampilan* online di UI sendiri mudah (hook pembacaan `a.c`), tapi menyembunyikan *dari server* sambil tetap menerima pesan butuh dukungan server / protokol. Sulit. |
| 2 | Sembunyikan centang dibaca (jangan kirim read receipt) | **Bisa — mudah** | Tanda dibaca keluar dari SATU tempat: `a.java:1546` membangun `{"t":"read","id":...}` lalu dikirim via `a.K()`. Blokir/hook titik itu saja. Penerimaan receipt orang lain tidak terpengaruh (masuk → status `"R"` lokal). |
| 3 | Baca pesan tanpa ketahuan (ghost read) | **Bisa — mudah** | Sama dengan #2: tahan pengiriman `read` sampai user membalas/membuka chat. |
| 4 | Anti-revoke / anti-hapus pesan | **Tidak relevan** | Aplikasi ini **tidak punya fitur hapus/revoke pesan** sama sekali. Tidak ada yang bisa diblokir. (Bila versi depan menambahkannya, delete akan datang sebagai tipe `"t"` baru di dispatcher `a.Y()` — titik hook-nya sudah jelas.) |
| 5 | Sembunyikan "mengetik…" | **Bisa — mudah** | Tipe `typing` ditangani dispatcher yang sama; pengirimannya lewat jalur `a.K()` seperti pesan lain. Blokir pengiriman `typing` keluar. (Lokasi kirim persisnya belum ditelusuri — lihat UNPROVEN.) |
| 6 | Simpan media/story otomatis | **Bisa — mudah** | Story sudah tersimpan mentah di `filesDir/story`; file chat punya `berkasPath` di JSON pesan. Hook pada case `"berkas"` di `a.Y()` (atau sekadar menyalin file dari disk — tidak perlu hook sama sekali karena plaintext). |
| 7 | Unduh story/status orang | **Bisa — mudah** | Sama dengan #6: file story mentah di disk; pratinjau tautan juga di-cache (nama file SHA-256 URL). |
| 8 | Anti-hapus story | **Tidak relevan** | Tidak ada protokol hapus story jarak jauh yang terlihat. |
| 9 | Sembunyikan terakhir dilihat / last seen | **Tidak relevan** | Tidak ada fitur last-seen; yang ada hanya `statusTs` (waktu ganti status profil). |
| 10 | Bypass PIN / masuk tanpa frasa | **Tidak bisa (client-side saja)** | PIN + token + `sesi_secret` diterbitkan server; pemetaan frasa→PIN hidup di server (`RestoreActivity` + `POST /bbm/daftar`). Menyuntik PIN/token palsu ke `l.o()` tidak menghasilkan sesi valid karena announce butuh HMAC dengan `sesi_secret` dari server. |
| 11 | Ganti server sendiri | **Sudah bisa — tanpa modul** | Alamat server adalah preference `"server"` yang bisa diubah user; default `http://103.89.2.86:3002`. |
| 12 | Multi-akun | **Bisa — sedang** | Identitas hanyalah isi preference (`pin`/`token`/`seed`); tidak ada struktur multi-profil. Modul bisa menyimpan beberapa set preference dan menukarnya + restart koneksi (`a.M()`/`a.n()`). Sedang: perlu menangani WebSocket + PeerConnection yang sedang jalan. |
| 13 | Blokir iklan | **Tidak relevan** | Tidak ada iklan di aplikasi. |
| 14 | Sembunyikan status "online" di grup | **Sama seperti #1** | Presence bersifat global per-hash identitas, bukan per-grup. |
| 15 | Kirim pesan terjadwal / auto-balas | **Bisa — sedang** | Jalur kirim terpusat (`a.K(pin, json)` + `l0` DataChannel send). Modul bisa mengantre JSON `msg` dan mengirimnya nanti. Perlu menjaga WebSocket/DataChannel tetap hidup (KeepAliveService sudah melakukannya). |
| 16 | Lihat pesan yang dihapus pengirim (arsip) | **Bisa — mudah (preventif)** | Karena semua pesan tersimpan plaintext di preference `"pesan"` (maks 200/kontak), modul cukup menyalinnya ke file sendiri saat tiba (`a.Y()` case `msg`). Bukan anti-revoke — ini arsip lokal. |

**Kesimpulan feasibility:** fitur privasi berbasis *pengiriman* (read receipt,
typing) dan fitur berbasis *file lokal* (arsip/simpan media) mudah dibuat.
Fitur yang melawan server (sembunyikan online sungguhan, bypass PIN)
sulit/tidak bisa dari client saja. Anti-revoke tidak relevan karena fiturnya
tidak ada.

**Analisis saja — modul TIDAK dibangun dalam REA ini.**

---

## 9. Temuan keamanan ringkas (untuk pemilik/peneliti)

1. **Semua pesan plaintext di lapisan aplikasi** — siapa pun yang bisa
   melihat trafik DataChannel (atau server TURN) melihat isi chat.
2. **Signaling 100% cleartext** (ws:// + HTTP, `wss://` ditolak mentah-mentah)
   — PIN, token, `seedHash`, SDP/ICE bisa disadap di jaringan.
3. **Seluruh kredensial + frasa + pesan tersimpan plaintext** di
   SharedPreferences + `allowBackup=true`.
4. **Tidak ada satu pun proteksi client-side** (pinning, root/Frida/Xposed
   detection, integrity check) — aplikasi mudah dimodifikasi/direpack.
5. Identitas hanya sekuat PIN 8 karakter yang diterbitkan server +
   `sesi_secret`; keamanan akun bertumpu penuh pada server
   `103.89.2.86:3002` yang tidak diaudit di sini (statis saja).

---

## 10. UNPROVEN

- Versi persis WebRTC/`libjingle` (`.so` stripped, tidak ada string versi).
- Lokasi tulis `sesi_secret`/`sesi_expires` (sisi server saat login/announce
  adalah dugaan — situs tulisnya tidak ketemu di hasil dekompilasi).
- Endpoint sumber feed "Pembaruan" (JSON `feed` di preference; situs
  pengambilnya tidak teridentifikasi).
- Lokasi kirim persis indikator `typing` (tipe ditangani dispatcher; situs
  kirimnya belum ditelusuri).
- Apakah `FLAG_SECURE` dipakai di activity mana pun (tidak diperiksa).
- Apakah server `103.89.2.86:3002` masih hidup / perilakunya (tidak
  di-probe — statis saja).
- Detail penegakan admin grup di sisi server (tipe `ruangDikeluarkan` ada,
  tapi siapa yang berwenang tidak terbukti).
- Charset/pembuatan PIN 8 karakter di sisi server (yang terlihat hanya
  validasi panjang 8 di `o0/l.z()`).

---

## 11. Evidence

- `dump/manifest.txt` — `aapt2 dump xmltree` + badging.
- `dump/file-list.txt` — isi APK (per file + ukuran).
- `dump/dex-structure.txt` — struktur dex + daftar class aplikasi.
- `dump/endpoints.txt` — server, endpoint REST/WS, URL lain.
- `dump/crypto-summary.txt` — ringkasan crypto + format `BBMBAK1`.
- `dump/smali-evidence/` — kutipan smali/Java kunci (`j.H` POST helper,
  `m2` BIP39, announce HMAC, `s0` penolakan wss, kirim DataChannel).
- Laporan ini + folder `dump/` di-push ke `hozin-king/hasil-dump`,
  `com.bbm.p2p/1.1.2.i/`.

## 12. Catatan batas

- Tidak ada kredensial/server/pengguna orang lain yang dipanen dari APK.
- Tidak ada nilai key mentah di laporan ini; bila ada materi kunci di
  `LOCAL_ONLY_*`, file itu mode 600 dan tidak di-push.
- APK sumber tidak dihapus (aturan 27 Nov 18:40).
