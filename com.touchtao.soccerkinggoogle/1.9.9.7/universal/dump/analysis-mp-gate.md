# Analisis Native — Sinyal Status Multiplayer untuk Kill Switch Mod
## World Football League `com.touchtao.soccerkinggoogle` v1.9.9.7 — `libHQRenderLib.so` (BuildID `1d5d0525…`)

Analisis statis (disassembly `llvm-objdump`, NDK 26.1) saja, tanpa build. Semua alamat = VA dynsym = offset dari base modul. Melengkapi `REPORT.md` §3.2.

**Vonis singkat:** sinyal paling andal BUKAN mode game/menu, melainkan blok flag sesi di ekor `CNetworkManager`. Game ini **tidak punya** fungsi `IsConnected()/IsLogin()/GetState()` — tidak ada simbol seperti itu di dynsym; seluruh kode internal menguji byte flag mentah dengan pola `ldrb …; cmp w8,#1`. Payload cukup meniru pola yang sama.

---

## 1. Peta struktur

### 1.1 Di mana instans aktif disimpan (TIGA jalur, semuanya terbukti)

| Jalur | Bukti |
|---|---|
| **Global `g_pNetworkManager` @ `0x4cf378`** (BSS, nama persis di dynsym) | Relokasi `R_AARCH64_GLOB_DAT @0x4be4a8 → g_pNetworkManager`; `CNetworkManager::GetNetworkManager()` `0x3ca2e4` = `ldr x8,[GOT 0x4a8]; ldr x0,[x8]; ret` (deref ganda). Konstruktor `0x3ca2f4` menutup dengan `str x19,[x8]` (this → global), destruktor `0x3ca47c` menulis `xzr` ke sana. |
| Member `CGame` | `CGame::OnInitialize_Step2` `0x33b7e8`: `operator new(0x7c138)` → `CNetworkManager()` → `str x20,[x19,#0x18]`. Jadi `*(CGame+0x18)`, dengan `g_pGame @ 0x4cb640`. |
| — | NM dibuat **sekali saat inisialisasi game, selalu ada walau offline penuh**. Keberadaan pointer NM ≠ online. |

`sizeof(CNetworkManager) = 0x7c138` (dari `new` di atas). Isi: `+0x0000..0x7b927` hampir seluruhnya buffer data besar (entri leaderboard, info playback, pesan, dll. — tidak dipetakan per-field, tidak relevan untuk gerbang). Semua state sesi ada di ekor `≥0x7b928`.

### 1.2 `CNetworkManager` — field ekor (offset absolut dari `this`)

Basis bantu di banyak fungsi: `T = this+0x7c000`.

| Offset | Tipe | Makna (bukti di §2) |
|---|---|---|
| `+0x7b928 / +0x7b92c / +0x7b930` | int×3 | Parameter request leaderboard (type, awal, jumlah ≤8) — `SetRequestLeaderBoardInfo` `0x3cd22c` |
| `+0x7b934` | 0x280 B | Array entri leaderboard (di-`memset` di konstruktor) |
| `+0x7c020` | ptr | `CCallBackHandler*` (di-`new(0x18)` di konstruktor) |
| `+0x7c028` | ptr | `CPacketManager*` singleton (`g_pPacketManager @ 0x4cf380`) — relai paket dalam pertandingan |
| **`+0x7c030`** | u8 | **CONNECTING** — di-set 1 oleh `Connect()`, di-nol-kan saat handshake sukses |
| **`+0x7c031`** | u8 | **ESTABLISHED** — sesi socket ke server hidup (flag utama, §2) |
| `+0x7c032` | u8 | Finish/disconnect-pending — di-set 1 oleh `Disconnect()` sebelum kirim paket penutup |
| **`+0x7c033`** | u8 | **LOGGED-IN** — di-set 1 hanya oleh sukses login/register |
| `+0x7c034` | u8 | Nickname valid (panjang 3–25) — di-set `LoadRegistration`/`Login`, **bukan** flag sesi |
| `+0x7c035` | u8 | **HOST / pemilik sesi** — di-set 1 hanya oleh sukses *create session* |
| `+0x7c038` | obj | `CGameRoom` tertanam (ukuran `0x88`, lihat §1.4) |
| **`+0x7c0c0`** | u8 | **IN-ROOM** — di-set 1 oleh sukses create **dan** join |
| `+0x7c0c1` | u8 | Match dimulai — terbukti di-set oleh *push* server `'s'` (sisi tamu); penulis sisi host tidak ditemukan di fungsi NM (lihat §5) |
| `+0x7c0c2` | char[32] | Nickname sendiri |
| `+0x7c0e4` | int | Di-set 1 saat sukses join (dugaan: slot/kode peran — label tidak terbukti) |
| `+0x7c0e8` | 12 B | `_UserUDID_Hash` target kick |
| `+0x7c0f8 / +0x7c100` | ptr×2 | Callback hasil jaringan + user-ptr (`RegisterCallback` `0x3ca518`) |
| `+0x7c10c / +0x7c110 / +0x7c114` | int×3 | Penghitung paket, cap waktu paket terakhir, durasi timeout (default `0x7530`=30000 di `RegisterDefaultCallback` `0x3ccf70`) |
| **`+0x7c118`** | ptr | **`CConnection*`** — dibuat `Connect()`, **tidak** di-null-kan saat disconnect (lihat §4) |
| `+0x7c120` | u8 | Huruf request tertunda (pending): `'i'` login, `'c'` create, `'j'` join, `'s'` start, `'f'` finish, `'k'` kick, `'q'` leave, `'r'` ranking, `'o'` playback-info, `'w'` get-playback, `'b'` put-playback, `'m'` playback-comment, `'z'` message-info, `'e'` get-message |
| `+0x7c124` | int | Penghitung retry request |
| `+0x7c128` | u8 | Di-set 1 oleh konstruktor/`Reset`/`DisconnectAndReset`; dibaca `OnPlayerDisconnect` (bit0=1 → tahan `ReturnToMpMenu`). Penulis-pengnolnya tidak terpetakan — **jangan dipakai** |
| `+0x7c12c / +0x7c130` | int×2 | Pasangan (tipe pesan error, `GAMEMENU_TYPE` tujuan) — `SetErrorMessage` `0x3ca524`; default tujuan MP_MainMenu = `0x31` |
| `+0x7c134` | int | Salinan jumlah pemain room saat push start diterima |

### 1.3 `CConnection` — field (ukuran `0x1910`, dari `new`/`operator delete` di `CNetworkManager::Connect`/`~CNetworkManager`)

| Offset | Makna |
|---|---|
| `+0x0000` | int penghitung retry establish (`SendEstablishConnectionPackage` `0x3c8ce4` menolkan, `…RetryPackage` menaikkan) |
| `+0x0008 / +0x0820` | Dua `DataPacket` tertanam (paket establish `'s','r'` dan `'s','w'`) |
| `+0x1038` | char host[] (wilayah `+0x1038..+0x1910` di-`memset 0x8d8` di konstruktor; host disalin `__strcpy_chk(…,0x80)`) |
| `+0x10b8 / +0x10bc` | int port server; int parameter koneksi ke-3 — dari `CNetworkManager::Connect` `0x3ca534`: arg2 = `atoi(port)`, arg3 = `(GetCurrentMS() & 0xff) + 0x7d0` |
| **`+0x10c0`** | u8 **ESTABLISHED (cermin)** — 0 di konstruktor/`Disconnect()`; di-set 1 oleh `ProcessConnectionPacket` saat balasan establish diterima; `CNetworkManager::Update` menguji byte ini ==0 sebagai koneksi putus |
| `+0x10c8 / +0x10d0` | Antrean keluar `DataPacket*` head/tail (`IsOutgoingQueueEmpty` `0x3c8188` menguji head==NULL) |
| `+0x10d8 / +0x10e0` | Antrean masuk head/tail |
| `+0x10e8 / +0x10ec` | int cap waktu aktivitas terakhir / request terakhir (`GetTimeOfLastReqest` `0x3c8360` mengembalikan `+0x10ec`) |
| `+0x10f0` | `DataPacket*` paket retry |
| `+0x10f8` | u8 socket aktif — di-set 1 oleh `Connect()` setelah socket dibuat, di-nolkan `Disconnect()` |
| `+0x1100 / +0x1104` | u8 notify-ditangguhkan + cap waktunya (`SuspendNotify`/`ResumeNotify`) |
| **`+0x1108`** | **int fd socket UDP** — transportnya UDP (`socket`+`bind`+`sendto`/`recvfrom`, tanpa `connect()` TCP). `Disconnect()` `0x3c7ffc`: `close([+0x1108]); [+0x1108] = -1` |
| `+0x110c` | int cap waktu kirim/terima terakhir |

### 1.4 `CGameRoom` (tertanam di NM `+0x7c038`, ukuran `0x88`)

Dari konstruktor/`Clear` `0x3ca0d4`/`0x3ca0f8`, `SetPlayerName`/`SetPlayerUDID`/`OnPlayerConnect` (langkah slot `0x30`, hanya slot 0–1):

- Slot pemain di `+0x00` dan `+0x30`: `_UserUDID_Hash` 12 B @`+0x00`, nama char[32] @`+0x0c`, flag terhubung @`+0x2c` (ditulis `strh 1`).
- Nama room char[32] @`+0x62` (`SetName` `0x3ca120`).
- **`+0x84` int = jumlah pemain terhubung (0–2)** — absolut di NM: **`+0x7c0bc`**.

> Tidak ada instans `CGameRoom` global terpisah dan tidak ada member room di `CGame`/`CHQGameWndSession` yang dipakai untuk status MP — room hidup di dalam NM. `CHQGameWndSession` hanya sesi jendela/render (menu aktif dipegang `CGameSelect` di `CGame+0xe0`, menu di `[CGameSelect+0x8]`); tidak ditemukan enum "mode game = MP" global di `CGame`/`CGamePlay` — mesin pertandingan sendiri buta-MP, relai ditangani `CPacketManager` lewat NM.

---

## 2. Sinyal status MP paling andal — rantai flag sesi

Urutan hidup sesi, semua dari disassembly:

1. **Mulai menghubungi:** `CNetworkManager::Connect()` `0x3ca534` menulis `strb #1,[this+0x7c030]` (CONNECTING=1), membuat `CConnection` baru (`new(0x1910)`, membuang yang lama) ke `+0x7c118`, lalu `CConnection::Connect()` `0x3c8aa0` (membuat socket UDP, fd → `conn+0x1108`, `conn+0x10f8=1`, kirim paket establish).
2. **Handshake diterima:** `ProcessConnectionPacket` `0x3cb16c`, kasus sub-tipe `'s'`:
   ```asm
   mov  w8, #0x100
   strh w8, [x22, #0x30]        ; NM+0x7c030: byte30=0, byte31=1
   mov  w8, #0x10c0
   strb w10(=#1), [x9, x8]      ; conn+0x10c0 = 1   (x9 = conn)
   ```
   Satu-satunya penulis pola ini → **ESTABLISHED (`+0x7c031`) = 1** berarti server menjawab dan sesi socket sah.
3. **Login:** `Login()` `0x3ccf90` menolak jalan kecuali `+0x7c031==1`, lalu mengirim `SendLoginPackage` (pending `'i'`). Sukses dijawab di `ProcessRequestSuccessPacket` `0x3cb8e8` kasus `'i'` (target tabel lompat `0x3cbbd8`): `strb #1,[…+0x7c033]`; jalur alternatifnya `strh #0x0101,[…+0x7c033]` (menulis `+0x7c033=1` sekaligus `+0x7c034=1`). → **LOGGED-IN (`+0x7c033`) = 1**.
4. **Masuk room:** kasus `'c'` (create, `0x3cc0dc`): `strb #1,[+0x7c035]` (HOST) **dan** `strb #1,[+0x7c0c0]` (IN-ROOM), room dibersihkan lalu slot 0 = diri sendiri. Kasus `'j'` (join, `0x3cbe88`): `strb #1,[+0x7c0c0]`, kedua slot room diisi, `room+0x84 = 2`, `+0x7c0e4 = 1`, event callback 16 — tanpa menyentuh `+0x7c035`. Konsisten dengan gerbang internal: `RequestStartGame` `0x3cdc1c` menuntut `+0x7c031==1 && +0x7c033==1 && +0x7c035==1 && +0x7c0c0==1` (hanya host boleh memulai); `RequestFinishGame` `0x3cdca8` menuntut `+0x7c031==1 && +0x7c0c0==1`.
5. **Pertandingan berjalan:** push server `'s'` di `ProcessPushPacket` `0x3cb590`: `strb #1,[+0x7c0c1]`, menyalin `room+0x84` ke `+0x7c134`, callback event 13. Selama room penuh, `Update()` `0x3cacd0` menjalankan relai: syarat `+0x7c0c0==1 && [+0x7c0bc] >= 2` → `CPacketManager::SendDummy` (keep-alive) dan `CPacketManager::Update`.
6. **Keluar room:** `RequestLeaveSession` `0x3cabfc` / `ReturnToMpMenu` `0x3cab2c` (keduanya identik intinya): kirim paket leave (pending `'q'`), `strh wzr,[+0x7c0c0]` (IN-ROOM & match-started = 0), `strb wzr,[+0x7c035]` (HOST=0) — **login dan established TIDAK disentuh** (user kembali ke lobby MP, masih online).
7. **Putus total:** `Disconnect()` `0x3ca754`: bila `+0x7c032` bit0 sudah 1 → langsung kembali; bila `+0x7c031==1` → set `+0x7c032=1` dan kirim `SendFinishConnectionPackage`, eksekusi fisik ditunda `Update()` sampai antrean keluar kosong → `DisconnectAndReset()`. Bila `+0x7c031!=1` → langsung `DisconnectAndReset()`.
   **Pembersih total:** `Reset()` `0x3ca40c` dan `DisconnectAndReset()` `0x3ca7c4` menulis 0 ke kata `+0x7c030` (connecting/established/finish-pending/logged-in), halfword `+0x7c034` (nickname-valid/host), dan halfword `+0x7c0c0` (in-room/match-started); `DisconnectAndReset` juga memanggil `CConnection::Disconnect()` (fd → −1, `conn+0x10c0/+0x10f8` → 0) lalu `Die()`; keduanya menulis `+0x7c128=1`.

**Nilai ringkas (kata 32-bit di `NM+0x7c030`, little-endian):** offline/reset = `0x00000000`; connecting = `0x00000001`; established belum login = `0x00000100`; established + logged-in = `0x01000100`. Byte per byte tetap cara baca yang disarankan (hindari menebak kombinasi `+0x7c032/+0x7c034`).

**Mengapa bukan sinyal lain:**
- `g_pNetworkManager != NULL` — selalu benar sejak init game (dibuat di `OnInitialize_Step2`), tidak membedakan apa pun.
- `NM+0x7c118 (CConnection*) != NULL` — dibuat `Connect()`, tetapi `DisconnectAndReset` **tidak** men-null-kannya (hanya destruktor NM yang menghapus). Setelah putus, pointer tetap menunjuk objek mati-sesi.
- fd socket `conn+0x1108 != -1` — benar selama sesi, tetapi fd dibuat *sebelum* handshake (jendela connecting) dan baru ditutup setelah antrean penutup terkuras (jendela pending). Bagus sebagai pemeriksa silang, bukan sinyal utama.
- Tipe menu aktif (`GAMEMENU_TYPE`) — objek menu dibebaskan/diganti tiap transisi dan mode pertandingan MP memakai menu in-game yang sama dengan offline; rapuh.

---

## 3. Titik masuk MP & titik keluar (pembersih)

`GAMEMENU_TYPE` didekode dari tabel lompat `CGameSelect::EnterGameMenu(GAMEMENU_TYPE,int)` `0x3448e8` (nilai = indeks tabel + 4):

| Nilai | Menu / isi |
|---|---|
| 42 (`0x2a`) | `CGameMenu_MP_SelectServer` — daftar server diambil via HTTP (`SendHttpCommand`, `CM3DXPlayerHttp`), **belum ada socket/sesi**; pilihan server disalin ke konfigurasi global `CGame` (host @ cfg`+0xf9aa0`, port) oleh `SelectServerList` `0x39e580`, dan `CNetworkManager::Connect` membaca host/port dari sana |
| 53 (`0x35`) | `CGameMenu_MP_NetworkOperation` + **`CConnectionOperation`** — pintu koneksi: `CConnectionOperation::SendNetworkRequest` `0x3970d4` = `RegisterDefaultCallback()` + `CNetworkManager::Connect()`; `OnSuccess` `0x39709c` memasang operasi berikutnya `CLoginOperation`, yang `SendNetworkRequest`-nya = `CNetworkManager::Login()` `0x3ccf90` |
| 55 (`0x37`) | NetworkOperation + `CRegisterOperation` (jalur daftar nickname; `SendNetworkRequest`-nya juga `Login()`) — didahului menu 50 `MP_RegisterPrompt` / 51 `MP_RegisterNameInput` |
| 49 (`0x31`) | `CGameMenu_MP_MainMenu` — lobby MP (tujuan akhir login & tujuan `ReturnToMpMenu`) |
| 47 (`0x2f`) | `CGameMenu_MP_ShowError`; 43/44 = `MP_LeaderBoard`/`MP_LeaderBoardDetail`; 52 = `MP_ViewMessage`; 54/56/57/58/59/60 = NetworkOperation + operasi GetMessageInfo / GetLeaderBoard / GetPlaybackInfo / GetPlayback / PutPlayback / PutPlaybackComment |

**Keluar / pembersih:**
- Keluar room saja: `RequestLeaveSession` / `ReturnToMpMenu` (§2 butir 6) — status kembali ke **lobby online** (logged-in tetap 1), bukan offline.
- Keluar MP sepenuhnya: `CGameSelect::UpdateMenu` `0x3452a8` memanggil `GetNetworkManager()->Disconnect()` (dua situs: `0x3454b0` dan tail-call `0x3456e4`, salah satunya didahului `SetErrorMessage(0, 0x35)`) saat user meninggalkan menu-menu MP. Ditambah jalur error/timeout internal: `RequestTimeout` `0x3caa54`, `ProcessConnectionPacket` kasus `'x'`/`'e'`, dan `Update()` (handshake hilang / antrean macet) → semuanya bermuara ke `Disconnect()` / `DisconnectAndReset()` → flag sesi nol (dengan jeda graceful §2 butir 7).
- Selesai pertandingan: `RequestFinishGame(int)` `0x3cdca8` (pending `'f'`; pemanggilnya di lapisan menu hasil pertandingan `CGameMenu_Result`, alamat persis pemanggil tidak dilokalisasi dalam bedah ini) — hanya melaporkan skor dan **tidak** memutus sesi; setelahnya user tetap in-room/logged-in sampai leave/disconnect eksplisit.

---

## 4. Penilaian risiko — jalur "terlihat offline, sebenarnya online"

Semua fungsi di bawah ini berjalan di atas **koneksi yang sama** dan hampir semuanya hanya menuntut `+0x7c031==1` (established) — beberapa bahkan **sebelum login** (`+0x7c033` tidak diuji oleh mereka):

| Fungsi (NM → CConnection) | Gerbang internal terbukti |
|---|---|
| `RequestLeaderBoard` `0x3cd24c` → `SendGetRankingPackage` (pending `'r'`) | hanya `+0x7c031==1` |
| `RequestPlaybackInfo` `0x3cd2e4` → `SendGetPlaybackInfoPackage` (`'o'`) | hanya `+0x7c031==1` |
| `RequestGetPlayback` `0x3cd7cc` → `SendGetPlaybackPackage` (`'w'`); `CheckAndDownloadPlaybackByUDID(Compressed)` | hanya `+0x7c031==1` |
| `RequestPutPlayback` `0x3cd628` → `SendPutPlaybackPackage` (`'b'`) | hanya `+0x7c031==1` |
| `RequestPutPlaybackComment` `0x3cd87c` (`'m'`); `GetMessageInfo` `0x3cd13c` (`'z'`); `GetMessage` `0x3cd1b4` (`'e'`) | hanya `+0x7c031==1` |
| Create/join room | `+0x7c031==1 && +0x7c033==1` |

Konsekuensi per pilihan sinyal:

1. **Gerbang = established (`+0x7c031`)** → menangkap *seluruh* permukaan server di atas: lobby, leaderboard, playback server, pesan, room, dan pertandingan. Tidak ada jalur MP yang lolos, karena tidak ada satu pun request server yang bisa dikirim sebelum handshake menyalakan flag ini (`Login` sendiri menuntutnya). Ini pilihan yang menangkap risiko dengan benar.
2. **Gerbang = in-room / match saja (`+0x7c0c0`, `+0x7c0c1`, room count ≥2)** → **LOLOS**: user yang hanya membuka leaderboard/playback/pesan dari lobby MP akan tampak "offline" padahal sedang bertukar data dengan server dan terlihat pemain lain (leaderboard/playback bersifat publik). Juga lolos: fase lobby sesudah login sebelum create/join. **Jangan dipakai sebagai satu-satunya sinyal.**
3. **Jendela connecting** (`+0x7c030==1`, `+0x7c031==0`): socket UDP sudah dibuat dan paket establish sudah dikirim, tetapi belum ada sesi/login — belum ada interaksi antar-pemain. Risiko rendah; untuk keketatan penuh, sertakan flag ini dalam definisi "online" (rumus §5 sudah melakukannya).
4. **Di luar jangkauan sinyal ini (disebut agar tidak disalahartikan):** pengambilan daftar server MP via HTTP di menu SelectServer (terjadi sebelum `CConnection` ada), serta Play Games/iklan/Mobirix — semuanya HTTP terpisah, bukan sesi MP game ini, dan tidak ada pertandingan/lobby di sana. `CNetworkManager::Update` juga tidak dipanggil untuk mereka.
5. **Jeda putus (graceful):** setelah `Disconnect()` dipanggil, `+0x7c031` tetap 1 (dan `+0x7c032=1`) sampai antrean keluar kosong dan `DisconnectAndReset` berjalan di `Update()` — orde detik. Selama jeda itu gerbang membaca "online" → fitur tetap mati. Arah kesalahannya aman (false-positive online, bukan kebocoran).

---

## 5. Kesimpulan — RUMUS GERBANG

```cpp
// base = base modul libHQRenderLib.so saat runtime
uint8_t* nm = *(uint8_t**)(base + 0x4cf378);          // g_pNetworkManager
bool online = false, loggedIn = false, inRoom = false, inMatch = false;
if (nm) {
    online   = (nm[0x7c030] == 1) || (nm[0x7c031] == 1);  // connecting || established
    loggedIn = (nm[0x7c033] == 1);
    inRoom   = (nm[0x7c0c0] == 1);
    inMatch  = inRoom && (*(int*)(nm + 0x7c0bc) >= 2);    // room terisi 2 pemain
}
// GERBANG (yang dipakai):
fiturAktif = !online;
// pemeriksa silang opsional (harus konsisten, jangan menggantikan):
//   conn = *(uint8_t**)(nm + 0x7c118);
//   connOK = conn && conn[0x10c0] == 1 && *(int*)(conn + 0x1108) != -1;
```

- **Tingkat keyakinan: TINGGI** untuk offset, penulis/pembaca, dan nilai flag `+0x7c030/+0x7c031/+0x7c033/+0x7c0c0`, room count `+0x7c0bc`, global `0x4cf378`, dan fd `conn+0x1108` — masing-masing dikonfirmasi dari banyak situs tulis/baca yang konsisten (konstruktor, `Connect`, handshake, sukses login/create/join, push start, leave, disconnect, reset, dan gerbang internal semua `Request*`).
- **Keyakinan SEDANG** untuk label semantik `+0x7c035` = host/pemilik sesi (hanya dari pola set/clear + syarat `RequestStartGame`) dan `+0x7c0e4` (dibiarkan tanpa label pasti). Keduanya **tidak** dipakai rumus utama.
- **Yang TIDAK bisa dibuktikan statis:**
  1. Penulis `+0x7c0c1` untuk sisi host (hanya sisi tamu via push `'s'` yang terbukti) — karena itu `inMatch` di rumus diturunkan dari `inRoom && roomCount>=2`, bukan dari `+0x7c0c1`, dan rumus utama sengaja tidak bergantung padanya.
  2. Apakah server `wslogin.touchtao.com` masih beroperasi hari ini (di luar cakupan statis) — bila server mati, sesi tidak pernah melewati connecting, dan rumus tetap mematikan fitur selama percobaan koneksi berjalan.
  3. Perilaku balapan (race) bila payload membaca memori di luar utas main-loop game: flag ditulis utas utama; bacaan asinkron bisa menangkap transisi di tengah frame — mitigasinya baca ulang/dua sampel konsisten, bukan sesuatu yang bisa dibuktikan dari berkas.
  4. Nilai di luar yang teramati: flag-flag di atas hanya pernah ditulis 0/1 oleh kode yang dibedah; tidak ditemukan penulis lain untuk offset tersebut di fungsi-fungsi jaringan/menu MP yang diperiksa (pencarian tidak menjangkau 100% dari ±9.255 simbol, jadi klaimnya "tidak ditemukan", bukan "mustahil ada").
  5. Semua offset berlaku hanya untuk build ini (v1.9.9.7, BuildID di atas); versi lain wajib dipetakan ulang.
