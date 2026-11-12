# REA — BombSquad 1.8.4 (net.froemling.bombsquad)

File: bundle `.apks` 82.164.604 byte (SHA-256 `7daa3d11…54401`), berisi `base.apk` (131.710.865 byte) + `split_config.arm64_v8a.apk` (30.069.380 byte). File unduhan asli tidak diubah; analisis dari ekstrak salinan (sudah dibersihkan setelah analisis).

## 1. Identitas & keaslian — RESMI, bukan repack

- Package: `net.froemling.bombsquad`, label "BombSquad"
- versionName `1.8.4`, versionCode `23068`, minSdk 32, targetSdk 37
- Signer (apksigner): `CN=Eric Froemling, OU=Personal, O=Personal, L=San Francisco, ST=CA, C=US`
- SHA-256 cert: `3d9af7cbfa18d6847b8bdb852490071682e1e9e4e3dae100254fc8ba2b8b41fc`
- Eric Froemling adalah kreator BombSquad → **APK resmi**, bukan mod/repack pihak ketiga.
- Permissions kunci: INTERNET, `com.android.vending.BILLING`, AD_ID, VIBRATE, FOREGROUND_SERVICE.

## 2. Stack teknologi

- Engine: **Ballistica** (C++ sendiri) — `libmain.so` 28,7 MB di split arm64-v8a + Crashlytics.
- **Logika game = Python, dan source-nya ikut dikirim**: 513 file `.py` (+ `.pyc`) di `assets/ballistica_files/ba_data/python/`:
  `babase` (engine base), `baclassic` (game klasik), `baplus` (akun/cloud), `bauiv1` (UI),
  `bascenev1`/`bascenev1lib` (scene & gameplay), `bacommon`, `efro`.
- Data game: ±3.995 blob hash-named `.bablob` di `assets/ballistica_files/ba_data/assets/`.
- Java tipis: satu `classes.dex` 5,9 MB (launcher + Play Billing client + Play Games v2 + Firebase).
- Python tertanam di native (`libmain.so` menyebut Python 1.529x); tidak ditemukan string "cheat"/"tamper"
  di libmain (string "integrity" 9x — kemungkinan Play Integrity untuk pembelian).

## 3. Ekonomi & mode — klasifikasi server-vs-local DAHULU

**Server-side (data akun disinkron dari master server, menimpa nilai lokal):**
- `classic.tickets`, `classic.tokens`, `classic.purchases`, `gold_pass`, `remove_ads`,
  `league_type/num/rank` — semua diisi dari data akun server (`_appmode.py` ~L697/L758).
  Tanpa akun: tickets=0, purchases=kosong.
- Pembelian lewat **transaksi akun v1 server** (`add_v1_account_transaction` +
  `run_v1_account_transactions`, `baplus`) + Google Play Billing untuk pembayaran.
- Harga item dari server: `get_v1_account_misc_read_val('price.<item>')`; kode store
  berkomentar "need to keep this synced with the master server".
- `have_pro()` memeriksa pembelian **server-side**: `gold_pass`, `upgrades.pro`,
  `static.pro`, `static.pro_sale`.
- Karakter difilter oleh `classic.purchases` (`spazappearance.py`).
- Turnamen: entri + hadiah (tiket, trofi, chest) dari server; cache turnamen
  di-invalidasi tiap suspend. Liga/power-ranking dihitung server.
- Tiket didapat dari turnamen & achievement yang dilaporkan ke server
  (`report_achievement`, `handle_account_gained_tickets`).

**Local (simulasi di perangkat):**
- Gameplay arena itu sendiri (fisika, bot, arena) jalan di engine + Python lokal.
- Mode lokal: multiplayer satu perangkat & lawan bot; mode online: public party
  (daftar via master server, host-authoritative: host UI, kick, halaman host),
  turnamen & liga (server).

Isi toko (dari `baclassic/_store.py`): Pro, Gold Pass, 16 karakter
(Kronk, Zoe, Jack Morgan, Mel, Snake Shadow, Bones, Bernard, Pixel/Pixie, Grumbledorf,
Frosty, Pascal, B-9000, Agent Johnson, Taobao Mascot, Santa Claus, Easter Bunny),
map Lake Frigid, mini-game Race / Ninja Fight / Meteor Shower / Target Practice /
Easter Egg Hunt, upgrade infinite runaround/onslaught, ±40 ikon bendera & aksesori, merch.

## 4. Tabel verdict

| Fitur | Klasifikasi | Verdict | Bukti |
|---|---|---|---|
| Unlock semua karakter/map/mini-game | SERVER | ❌ DITOLAK (bypass pembelian) | `classic.purchases` dari server; filter karakter pakai purchases; tanpa akun = kosong |
| Unlimited ticket / token | SERVER | ❌ DITOLAK | `val.tickets/val.tokens` dari data akun server; tiket dari turnamen/achievement server |
| Pro / Gold Pass gratis | SERVER | ❌ DITOLAK (IAP bypass) | `have_pro()` cek pembelian server-side; pembayaran via Play Billing + transaksi akun |
| Hilangkan iklan (remove_ads) | SERVER | ❌ DITOLAK (paid benefit) | `classic.remove_ads` dari data akun server — sama polanya dengan benefit berbayar lain |
| God mode / infinite health / speed | LOCAL | ✅ FEASIBLE, solo lokal saja | Simulasi lokal (libmain.so + Python bascenev1lib); jalur: root injector runtime (pola HCR, tanpa resign) atau patch `.py` di APK (perlu resign) |
| ESP / aimbot | — | ➖ TIDAK RELEVAN | Arena 3rd-person terbuka, lempar bom fisika; tidak ada permukaan aim hitscan/tembus-tembok yang bermakna |
| Cheat di public party | SERVER/host | ❌ DITOLAK (rugikan pemain asli) | Party host-authoritative + daftar master server; mod client = risiko kick/ban |
| Cheat turnamen / liga | SERVER | ❌ DITOLAK | Entri, hadiah, ranking dihitung server |
| Edit config lokal (profil, kontrol, setting) | LOCAL | ✅ Bisa, nilai rendah | Config lokal bukan ekonomi; tidak menyentuh tiket/pembelian |

## 5. Risiko & catatan

- **Jalur mod lokal yang benar:** root injector runtime (tanpa ubah signature) lebih aman
  daripada patch APK — resigning memutus signature resmi dan bisa mengganggu fitur
  akun online (Play Games / akun v1).
- **Patch `.py` itu pedang bermata dua:** source Python yang ikut dikirim membuat
  mod lokal sangat mudah dibaca/diubah, tapi juga berarti mod APK gampang dibuat
  pihak lain — jangan pernah memakai APK hasil patch pihak ketiga tanpa verifikasi
  signature (kasus Fragger dulu: APK "MOD" terbukti repack).
- **Tidak ada anti-cheat engine khusus yang ditemukan** — penegakan praktisnya adalah
  ekonomi server + otoritas host di party. Jangan menguji mod di party publik.
- **Anti-tamper data:** arsip server memakai signature ed25519 (`bacommon/securedata.py`:
  `Archive` + `_verify_ed25519`, master keys) — data akun tidak bisa dipalsukan lokal.
- Versi 1.8.4 bergerak; update game bisa mengubah struktur Python/native — mod
  lokal harus dites ulang tiap update.

## 6. Rekomendasi langkah berikutnya

1. Bila user mau mod: bangun **root injector (pola HCR) untuk mode solo lokal saja**
   (vs bot / satu perangkat): god mode + speed. Target runtime di `libmain.so` /
   fungsi Python gameplay (`bascenev1lib/game/*`) — butuh riset offset runtime di HP
   root karena tidak ada simbol debug.
2. Jangan bangun apa pun yang menyentuh tiket, token, Pro, Gold Pass, remove_ads,
   turnamen, liga, atau party publik.
3. Uji di perangkat: instal resmi → main solo lokal → verifikasi mod hanya aktif
   di sesi lokal, tidak terbawa ke party publik.
