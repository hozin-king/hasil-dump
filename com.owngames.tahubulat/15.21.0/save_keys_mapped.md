# Pemetaan Arti Key JSON Save Tahu Bulat

Save: `walaidwjss2_0_cio0.decrypted.json` (Tahu Bulat 15.21.0 / build 313, file `walaidwjss2.own` + `data`).
APK: `base.apk` 15.21.0/313. Native lib: `libnative-lib.so` (arm64).

## Metode
- Semua key JSON dikumpulkan dari file ter-decrypt (109 top-level, 248 distinct key total termasuk nested, 1113 kemunculan).
- Setiap literal dicari di `.rodata` `libnative-lib.so`; xref ADRP+ADD dilacak ke fungsi pemakainya
  (`GameData::loadDataBaru` 0x2e6278, `GameData::saveAllGameData` 0x2fa604, `GameData::loadData` 0x2ee188,
  `GameData::saveDataCabang` 0x31da74, `GameData::convertDataLama` 0x2e3ee0, `GameData::loadCabangLintasGame` 0x324fbc,
  `GameData::loadCabangFestival` 0x3253f4, `GameData::getUangDiCabang` 0x323a00, `GameData::getAllTimeMoneyCabang` 0x2f2f14).
- 245 dari 248 key ada di `.rodata` dan punya xref. 3 key tidak ada di `.so`: `FTTB`, `id`, `iiafefked`
  (`FTTB` ada di `classes3.dex`, dipakai `MainActivity.onActivityResult`; `iiafefked` tidak ada di dex mana pun).
- Key yang hanya dibaca `convertDataLama` = key format save LAMA (migrasi), bukan format baru.
- Nilai key kripto/DES TIDAK dicantumkan di dokumen ini.

## Tingkat keyakinan
- **yakin** — ada nama getter/fungsi yang jelas (mis. `getUangDiCabang`, `KolakData::getJumlahStok`,
  `RempahManager::loadRempah`, `ChestManager::setChest`, `Cabang::getListTargetFestival`) atau key plaintext.
- **mungkin** — bukti kuat tapi tidak langsung (pola nilai, nama fungsi pemanggil, konteks objek).
- **tebakan** — satu petunjuk lemah saja.
- **tidak diketahui** — hanya tipe + offset/konteks, tanpa petunjuk arti.

## A. Top-level (109 key)

| key | arti yang disimpulkan | keyakinan | bukti singkat |
|---|---|---|---|
| `vaevakmfa` | versi game/save ("15.21.0") | yakin | `loadDataBaru`: strdup → GameData+0x3c0; dipakai `getVersi` |
| `sfiaefg` | volume SFX (int, nilai 5) | yakin | `loadDataBaru`: int → GameData+0x3dc, lalu `OwnMusicPlayer::setSFXVolume` |
| `afjaisfalif` | nama pemain/profil ("HOZIN WATE") | yakin | `loadDataBaru`: asCString → strdup → GameData+0x1b8 |
| `fisjefkasda` | ID/token unik pemain (string 20 karakter alfanumerik) | tebakan | `loadDataBaru`: strdup → GameData+0x1a8; bentuknya mirip token instalasi/ID Own Connect; tidak ada getter bernama yang memakainya |
| `fwaldafg` | kode bahasa ("id") | mungkin | string "id" → GameData (loadDataBaru); nilai = kode bahasa Indonesia |
| `lfawogkaeg` | string kode/ID ("2024128") | tidak diketahui | string → GameData+0x510; tanpa petunjuk lain |
| `anwlfaliejf` | string ("0") | tidak diketahui | asString → GameData+0x198 |
| `8aksfklas` | string ("0") | tidak diketahui | asString → GameData+0x150 |
| `lopintesna` | string (kosong "") | tidak diketahui | asString di akhir `loadDataBaru`; tanpa petunjuk lain |
| `lfpeorveeill` | string ("0"), dipakai membangun objek 0x50 byte di GameData+0x820 | tidak diketahui | `loadDataBaru` 0x2eb48c: string dipakai sebagai argumen konstruktor objek di GameData+0x820; konteks sekitar = data event/promo |
| `kaangenkg` | int (-1) | tidak diketahui | int → GameData+0x508; juga dipakai saat load `gisgaemk`; default -1 (tidak ada) |
| `alwfaifaksl` | int (24) | tidak diketahui | int → GameData+0x18, default 0 |
| `iafjauelsds` | int (0) | tidak diketahui | int, default 0 |
| `waafeaggs` | int (0) | tidak diketahui | int → GameData+0x3c8 |
| `jafwkmfa` | int64 (8230), via SecureLong | tidak diketahui | SecureLong → GameData+0x3d0 |
| `asfalsjfla` | bool (true) | tidak diketahui | bool → GameData+0xc9; default TRUE bila absen |
| `bgaefmlw` | int (7) | tidak diketahui | int → GameData+0x3d8 |
| `faoekfwa` | bool (false) | tidak diketahui | bool → GameData+0x3e0 |
| `igsjgklsfa` | bool (false) | tidak diketahui | bool → GameData+0x3e1 |
| `afoafkafksd` | bool (true) | tidak diketahui | bool → GameData+0x9d, bila ada |
| `bfakfafwf` | bool (false) | tidak diketahui | bool → GameData+0x3f8 |
| `fkmfagrgh` | int64 (0), via SecureLong | tidak diketahui | SecureLong → GameData+0x3f0 |
| `akfofakgas` | int (13) | tidak diketahui | int → GameData+0x408 |
| `oaofkamfas` | int (10) | tidak diketahui | int → GameData+0x50c |
| `fpaeoflas` | bool (false) | tidak diketahui | bool → GameData+0x200, default false |
| `ppamleasa` | string ("12") | tidak diketahui | asString di `loadDataBaru` |
| `kafnkafa` | bool (true) | tidak diketahui | bool → GameData+0x690 |
| `ianfkawls` | int (0) | tidak diketahui | int → GameData+0x694 |
| `iajisjasdss` | int (2); bila absen dihitung dari uang total Bandung vs 10 miliar | mungkin | int → GameData+0x880; fallback: `getAllTimeMoneyCabang("Bandung")` vs 10000000000; kemungkinan indeks/level progres terkait ambang 10 miliar |
| `isfuisjkda` | bool (false) | tidak diketahui | bool → GameData+0x9c |
| `afjiafasdds` | bool (true) | tidak diketahui | bool → GameData+0x94 |
| `jfheudsads` | float (0.0) | tidak diketahui | float → GameData+0x98 (ucvtf 0.0/1.0) |
| `aijdafeae` | int (1) | tidak diketahui | int → GameData+0x90 |
| `baansndre` | bool (true) — flag "bundle aktif" | yakin | bool + `GameUtil::setValueBundleAktif(true)` |
| `auhfalsdesss` | bool (true) | tidak diketahui | bool → GameData+0x8d |
| `akfakwkdsdd` | float (0.0) — parameter auto-tap | yakin | `loadDataBaru`: `AutoTapScheduler::activateAutoTapEff(iafoassdeed, akfakwkdsdd)` |
| `iafoassdeed` | float (1000.0) — parameter auto-tap | yakin | sama seperti `akfakwkdsdd`; pasangan parameter `activateAutoTapEff` |
| `aushfajfe` | objek 6 flag bool (lihat §C) | tidak diketahui | 6 bool → GameData+0x7e0–0x7e5; tanpa petunjuk tujuan |
| `bfakflaekg` | array 14 int (elemen pertama 9) | tidak diketahui | array int; juga dibaca `convertDataLama`; tanpa petunjuk tujuan |
| `bekafwsfed` | array 14 int (elemen pertama 9) | tidak diketahui | sama seperti `bfakflaekg` |
| `iiafefked2` | string tanggal/waktu ("2024-12-11 22:42:12") | mungkin | string tanggal di `loadDataBaru` + `convertDataLama`; kemungkinan waktu kejadian terakhir (6 menit setelah `iiafefked`) |
| `iiafefked` | string tanggal/waktu ("2024-12-11 22:36:52") — key lama | tidak diketahui | TIDAK ada di `.rodata` native maupun dex mana pun: tidak dibaca kode saat ini; hanya tersisa di file save (kemungkinan nama lama dari `iiafefked2`) |
| `KEY_COOLDOWN_MEME` | cooldown meme (int64, 0) | yakin | key plaintext; int64 → GameData+0x568, default 0 |
| `KEY_POST_LAST_TIME` | waktu wall-clock (ms) terakhir "post" | yakin | key plaintext; int64 → GameData+0x558; nilainya sama dengan `slsaslvtea` |
| `KEY_POST_LAST_REALTIME` | elapsedRealtime terakhir "post" | yakin | key plaintext; int64 → GameData+0x560; nilainya sama dengan `slclltocaks` |
| `FIX_KALENDAR` | flag perbaikan kalender (false) | yakin | key plaintext; bool → GameData+0xc8, default false |
| `KEY_START_SEASON` | tanggal mulai musim ("06-03-2026") | yakin | key plaintext; string tanggal, default "04-07-2019" |
| `KEY_END_SEASON` | tanggal akhir musim ("10-04-2027") | yakin | key plaintext; string tanggal, default "04-08-2019" |
| `KEY_LAST_ID_CALENDAR` | id kalender terakhir (48) | yakin | key plaintext; int → GameData+0xc4, default 1 |
| `KEY_STATE_CALENDAR` | state kalender hadiah (array 28 entri [idItem, jumlah, namaItem, diambil]) | yakin | key plaintext; array; isinya loker/koin/penghasilan |
| `KEY_STATE_LABEL_REWARD` | state label reward (array 3 × {state}) | yakin | key plaintext; array objek {state} |
| `slclltocaks` | elapsedRealtime saat terakhir resume | mungkin | int64 → GameData+0x570, default 0; juga dibaca `loadResume` + `loadCloud`; nilainya sama dengan `KEY_POST_LAST_REALTIME` |
| `slsaslvtea` | waktu wall-clock (ms) saat terakhir resume | mungkin | int64 → GameData+0x578, default 0; juga dibaca `loadResume` + `loadCloud`; nilainya sama dengan `KEY_POST_LAST_TIME` |
| `gisgaemk` | daftar penjual/seller (array 20, lihat §C) | yakin | `loadDataBaru`: tiap penjual dicocokkan ke XML node `penjual` by id (field XML: images/item, moveX, moveY, rarity, scale, idKet, id, nama, deskripsi, alasan) |
| `gegaefa` | daftar loker (array 4, lihat §C) | yakin | `loadDataBaru`: tiap loker dari XML node `loker` (nama, textLabel, deskripsi, image, harga) |
| `jafekfsd` | daftar entri {nama, stok} (null di save ini) | mungkin | array objek {`q2kdaslflf` (nama), `jfauefna` (stok)}; struktur sama dengan daftar item |
| `amlfudwahfnfe` | objek data VIP (berisi entri `VIP_DATA_n`; null di save ini) | mungkin | `loadDataBaru`: loop format "%d" → `VIP_DATA_0`, `VIP_DATA_1`, … |
| `anfawfkalsdl` | objek JSON (null di save ini) | tidak diketahui | objek Json (copy) di `loadDataBaru`; tanpa petunjuk lain |
| `auwfkassd` | objek 2 int {`iaufasdsds`, `awufakfla`} | tebakan | objek; dipakai bersama `TimeUtil` — kemungkinan rentang waktu event |
| `dcoarhtoaamt` | data chat Own Connect (lihat §C) | yakin | objek per kontak ("Own Connect Admin", "Bapak Investor", "Satpam Elit", "Accel"); field dari setter `ChatRoom` |
| `clgasgnbat` | data cabang lintas-game (lihat §C) | mungkin | `loadCabangLintasGame`: iterasi nama member (`getMemberNames`); anggota: `FTTB`, `KTB`; tiap anggota punya `curIdxTarget` (+ `lastJsonResponse` di kode) |
| `fiawookasss` | array 21 nilai terkait cabang festival | mungkin | `loadCabangFestival`: array 21 (kebanyakan flag 0/1; 2 entri berupa timestamp ms); kemungkinan status/flag per cabang festival |
| `remakdsyds` | data rempah (array 25, lihat §C) | yakin | `loadDataBaru` 0x2ec6d4: per elemen panggil `RempahManager::loadRempah(int, int, string, string, int)`; bila kosong panggil `RempahManager::lepasRempah` |
| `afjiejsde` | data peti/chest (array 3, lihat §C) | yakin | `loadDataBaru` 0x2ec8f4: per elemen panggil `ChestManager::setChest(idx, id, timer, flag)` setelah `TimeUtil::getDifferenceTimeUsed` |
| `isfoakdse` | timer rempah (float, detik) | yakin | float → `ChestManager::setTimerRempah(float)` |
| `oefkasdokae` | timer peti/chest (float, detik) | yakin | float → `ChestManager::setTimerChest(float)` |
| `afuhfuefs` | int (2) | tidak diketahui | int → GameUtil+0x1f0 |
| `aufhaksdle` | int (1) | tidak diketahui | int → GameUtil+0x1f4 |
| `tsawliroaun` | bool (true) | tidak diketahui | bool → GameData+0xafb |
| `whtsraieck` | daftar paket konten + versi (lihat §C) | yakin | array {`identifier`, `versi`}; isinya "akangtahu" v21, "ramadhan" v1 |
| `wpophtaasu` | bool (true) | tidak diketahui | bool → GameData+0xc00, default false |
| `swrhmdnaa` | int (-1) | tidak diketahui | int → GameData+0x50, default -1 |
| `suwltwaha` | int (-1) | tidak diketahui | int → GameData+0x54, default -1 |
| `swrhmdnaa26` | int (-1) | tidak diketahui | int → GameData+0x58, default -1 |
| `noaitsfki` | bool (true) | tidak diketahui | bool → GameData+0xc01, default true |
| `mabruskias` | bool (false) | tidak diketahui | bool → GameData+0xaac, default false |
| `jmiasntieane` | int (1) — angka besar (OwnDisplayInteger) terkait promo game | mungkin | int → OwnDisplayInteger di GameData+0xba0; konteks sekitar = blok promo game (lihat `pg*`) |
| `oalunwitgnoo` | bool (false) | tidak diketahui | bool → GameData+0x849/0x84a |
| `cjloackm` | int (0) | tidak diketahui | int → GameData+0x84c, default 0 |
| `ahdeivtneah` | data event (lihat §C) | yakin | objek event; isinya `devaetnat` (data event: target + hadiah normal/VIP, tanggal, id, kode, banner, leaderboard, IAP) + 5 field state |
| `ifjwuajnsk` | bool (false) | tidak diketahui | bool → GameData+0x7e |
| `pepfalfeis` | bool (false) | tidak diketahui | bool → GameData+0x8c |
| `ieflfjeds` | int (-1) | tidak diketahui | int → GameData+0x80 |
| `ooawkfkes` | int (0) | tidak diketahui | int → GameData+0x84 |
| `eufhlaosfe` | int (0) | tidak diketahui | int → GameData+0x88 |
| `bpgackgdnro` | indeks background promo game (int, 0) | yakin | int → `GameData::changeBGPromoGame(int)` (default -1) |
| `pgereyng` | int (5) — state promo game | mungkin | int → GameData+0xbb0; blok `pg*` = Promo Game (lihat `bpgackgdnro`, `popup_promo`, `popup_vip`) |
| `ptriopmeo` | int (-1) — state promo game | mungkin | int → GameData+0xcb0, default -1 |
| `pgporimnae` | string ("0") — state promo game | mungkin | string (asCString); blok `pg*` |
| `pgidxrnedwr` | int (0) — state promo game | mungkin | int → GameData+0xbb4 |
| `pgteinmegry` | float (1060.0) — state promo game | mungkin | float → GameData+0xbac |
| `pgthdeari` | float (-0.164…) — state promo game | mungkin | float → GameData+0xba8 |
| `pglseaotcrs` | int (-1) — state promo game | mungkin | int → GameData+0x6c, default -1 |
| `pgipaslyng` | bool (false) — state promo game | mungkin | bool → GameData+0x71 |
| `fgkefeassdf` | int (2024) — key format save LAMA | tidak diketahui | HANYA dibaca `convertDataLama` (migrasi format lama → baru); nilai diisi dari `atoi` atas string lama; tanpa petunjuk arti |
| `friemfsa` | string ("0") — key format save LAMA | tidak diketahui | HANYA di `convertDataLama`; tanpa petunjuk arti |
| `klafawall` | string ("no kode") — key format save LAMA | tidak diketahui | HANYA di `convertDataLama`; nilai "no kode" mengisyaratkan field kode (kemungkinan kode promo/referral lama) |
| `oakwfeaef` | int (49) — key format save LAMA | tidak diketahui | HANYA di `convertDataLama`; nilai dari `atoi` atas string lama |
| `palfajgej` | int (0) — key format save LAMA | tidak diketahui | `convertDataLama` + `saveAllGameData`; tanpa petunjuk arti |

## B. Key nama cabang (objek cabang = 1 key per cabang)

Pemetaan dari `GameData::getUangDiCabang` (0x323a00): fungsi ini strcmp nama cabang lalu memuat key JSON-nya.
Semua yakin.

| key JSON | cabang |
|---|---|
| `laeiga2fsa` | Jakarta / jkt (JKT) |
| `83jdawdkmd` | Bandung / bdg (BDG) |
| `8q2rjolfqf` | Bali / bali (BALI) — tidak ada di save ini |
| `9qi2qfmkas` | Medan / mdn (MDN) |
| `q92rkmcslc` | Surabaya / sby (SBY) |
| `174inksadf` | Palembang / plmbg (PLB) — tidak ada di save ini |
| `7has23qsds` | Korea / kor (KOR) — tidak ada di save ini |
| `cmq932feas` | Jepang / jpn (JPN) — tidak ada di save ini |
| `57qwdasgsd` | Belanda / bld (BDL) — tidak ada di save ini |
| `q2rkqdasff` | Dubai / dubai (DBI) — tidak ada di save ini |
| `18fildafgs` | Purba / purba (PRB) — tidak ada di save ini |
| `q83ruqmdas` | Majapahit / maja (MAJ) — tidak ada di save ini |
| `5awduhkasd` | Tahu Con / tahucon (THC) |
| `a8wfjaliss` | Yogyakarta / yogyakarta (YOG) — tidak ada di save ini |
| `31rnkamsaj` | Festival / festival (FES) — stub di save ini |
| `13jmsrnaka` | 2.0.1.6 / 2016 (2016) — tidak ada di save ini |
| `41murbsm1a` | Mars / mars (MRS) — stub di save ini |
| `47ln1547` | Atlantis / atlantis (ATL) — stub di save ini |
| `f73r5y50` | Festival Story / festival_story (FESSTORY) |
| `4tlryatns1` | Atlantis Story / atlantis_story (ATLSTORY) — stub di save ini |
| `4ln1ts47` | (default, bila nama tidak cocok) — tidak ada di save ini |

Kode singkat cabang (dari fungsi 0x3207e0): JKT, BDG, BALI, MDN, SBY, PLB, KOR, JPN, BDL, DBI, PRB, MAJ, THC, YOG,
FES, 2016, MRS, ATL, FESSTORY, ATLSTORY, ATLPERM ("Atlantis_Permanent" → "ATLPERM").
Di save ini ada 5 cabang lengkap (Jakarta, Bandung, Medan, Surabaya, Tahu Con), 4 stub (Festival, Mars, Atlantis,
Atlantis Story — hanya berisi `ijadsfafs`), dan Festival Story (berisi `dfetaats` + `ijadsfafs`).

## C. Field di dalam objek cabang (dari `GameData::saveDataCabang` 0x31da74 + `GameData::loadData` 0x2ee188)

| key | arti yang disimpulkan | keyakinan | bukti singkat |
|---|---|---|---|
| `dqjliddsa` | uang di cabang (string angka) | yakin | `getUangDiCabang` → `Json::operator[]` + `asString` + `OwnDisplayInteger::valueOf` |
| `ijadsfafs` | uang total sepanjang waktu (all-time money) di cabang | yakin | dipakai `saveDataCabang`, `loadCabangDataLama`, `getAllTimeMoneyCabang` (0x2f2f14) |
| `akefaloda` | timestamp ms terakhir (`TimeUtil::getMillis()`) | yakin | `saveDataCabang`: long dari `TimeUtil::getMillis()` |
| `ofwmlfaad` | elapsed realtime saat save (`TimeUtil::getElapsedRealtime()`) | yakin | `saveDataCabang`: long dari `TimeUtil::getElapsedRealtime()` |
| `knajshfafkajs` | tanggal cabang (string "DD-MM-YYYY H:M:S") | mungkin | string tanggal dari Cabang+0x130; kemungkinan tanggal cabang dibuka/dibuat |
| `kafefma2s` | SecureLong (nilai 0 di semua cabang) | tidak diketahui | SecureLong di Cabang+0x650; tanpa petunjuk lain |
| `ukhifas2atsuds` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0x74 |
| `uhfa2asds` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0x658 |
| `a9iawifmkaw` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0x138 |
| `aksfkfi2a` | array 7 SecureLong | mungkin | 7 SecureLong di Cabang+0x5d0–0x600; nilainya besar (ratusan juta s.d. puluhan kuadriliun) — kemungkinan 7 ambang/target (mis. target uang) |
| `ajfaw22sa` | array 12 SecureLong | mungkin | 12 SecureLong di Cabang+0x608; Bandung semua 50, Medan/Jkt bervariasi — kemungkinan 12 penghitung per item |
| `fawkkawss` | array data pembeli/penjual di cabang (lihat §D) | mungkin | array 9–10 item; `legaegm` = SecureLong, `aiefasfs` = float dari `BuyerManager::getCurTime()` |
| `adwkdsafs` | profil cabang (lihat §D) | mungkin | objek {`legaegm`, `ifafiawsada`, `q2kdaslflf`, `tiwamadf`, `aoueghn`, `aiwijfak`} |
| `kamsdasfg` | objek {`legaegm`, `ifafiawsada`} | tidak diketahui | `legaegm` = SecureLong di Cabang+0x580; `ifafiawsada` = angka tampilan dari OwnDisplayInteger di Cabang+0x5b8 |
| `aufhasas` | objek {`sifmefad` (bool), `tiwamadf` (timestamp)} | tidak diketahui | flag + timestamp dari Cabang+0x678 / +0x680 |
| `nalsjfafee` | objek {`sifmefad` (bool), `tiwamadf` (timestamp)} | tidak diketahui | flag + timestamp dari Cabang+0x268 / +0x260 (pasangan berbeda dari `aufhasas`) |
| `pbemsehoiwl` | array bool item yang sedang ditampilkan | yakin | array bool dari `ItemData::getIsShowingItem()` atas vector di Cabang+0x340–0x348 |
| `khfaksads2` | angka besar cabang (string angka, ~1,5–2,0 triliun) | mungkin | string dari `OwnDisplayInteger::getTextPolos()` di Cabang+0x638; kemungkinan total penghasilan cabang |
| `kdoaltaka` | data kolak (lihat §D) | yakin | semua field dari getter `KolakData` (`getStartTime`, `getJumlahStok`, `getHargaJual`, `getNJualKolak`, `getDataRekor`, `getListTotalPenjualan`, `getResepTerbaik`, `getListResep`) |
| `ksepathrui` | data KsatriaTahu / pet (lihat §D) | yakin | semua key plaintext + getter jelas |
| `skseatuamia` | array int 0/1 dari bitset | mungkin | array dari bitset di Cabang+0xa28 (jumlah bit di +0xa30); 10 entri di save ini — kemungkinan flag per sesuatu |
| `rkaessteipa` | array int dari vector | tidak diketahui | array dari vector<int> di Cabang+0xa88; 3 entri di Jakarta, kosong di cabang lain |
| `gsekanterasi` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0xaa0 |
| `ttuikmrepar` | long (0 di semua cabang) | tidak diketahui | long di Cabang+0xab8 |
| `ctpuentredro` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0xab0 |
| `usntlockgo` | bool (false di semua cabang) | tidak diketahui | bool di Cabang+0xaf9 |
| `hasortgin` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0xae0 |
| `hosmnetg` | int (0 di semua cabang) | tidak diketahui | int di Cabang+0xae4 |
| `henisghsls` | SecureLong (0 di semua cabang) | tidak diketahui | SecureLong di Cabang (offset tidak tercatat) |
| `lmisvaten` | array {`level`, `main`} | mungkin | array dari vector di Cabang+0xb78; hanya Bandung 1 entri — kemungkinan daftar misi/tantangan (level + status "main") |
| `tsunlriaoga` | array {`level`, `sudahTutorial`} | mungkin | array dari vector di Cabang+0xb00; 1 entri tiap cabang — kemungkinan daftar tutorial (level + sudah tutorial) |
| `sboitngai` | array {`level`, `bintang`} | mungkin | array dari vector di Cabang+0xb40; hanya Bandung 1 entri — kemungkinan daftar dengan rating bintang |
| `hleiglehve` | array {`level`, `score`} | mungkin | array dari vector di Cabang+0xb60; hanya Bandung 1 entri — kemungkinan daftar dengan skor |
| `dfetaats` | data festival (hanya bila cabang bertipe festival; lihat §D) | yakin | objek dari getter `Cabang` (`getDataMobilFestival`, `getDataResepFestival`, `getDataPromoFestival`, `getStartDateFestival`, `getEndDateFestival`, `getDataPopUpRewardsFestival`, `getListHadiahFestival`, `getIdFestival`, `getVersiFestivalServer`, `getLastIdxRewardFestival`, `getListTargetFestival`) |

## D. Nested key (di dalam objek di atas)

### `fawkkawss[]` (per item pembeli)
| key | arti | keyakinan | bukti |
|---|---|---|---|
| `legaegm` | level/tingkat (SecureLong) | mungkin | SecureLong; nilai 9 / 999999; nama yang sama dipakai sebagai level di banyak struct |
| `aiefasfs` | waktu (float) | mungkin | float dari `BuyerManager::getCurTime()` (bila i+2 < jumlah buyer); nilai contoh 1.135, 0.039, 378899136.0 |
| `a2jricadl` | bool | tidak diketahui | bool dari array byte di Cabang+0x660 |
| `aiwaksdaf` | long | tidak diketahui | long dari array di Cabang+0x668 (cabang else, bila buyer tidak ada) |

### `adwkdsafs` (profil cabang)
| key | arti | keyakinan | bukti |
|---|---|---|---|
| `legaegm` | level cabang (SecureLong; 39 / -1) | mungkin | SecureLong; -1 = belum ada |
| `ifafiawsada` | angka tampilan (string, "0"/"51350"/"1123200") | yakin | string dari `OwnDisplayInteger::getTextPolos()` |
| `q2kdaslflf` | nama tampilan ("Hacker"/"HOZIN KING"/"Toko Tahu"/"") | yakin | string nama profil cabang |
| `tiwamadf` | timestamp (long) | yakin | long timestamp |
| `aoueghn` | long (contoh 303909576 / 1438721) | tidak diketahui | long; tanpa petunjuk lain |
| `aiwijfak` | timestamp (long) | mungkin | long; dipakai sebagai timestamp di konteks profil |

### `kdoaltaka` (data kolak — semua yakin, getter `KolakData`)
| key | arti | bukti |
|---|---|---|
| `tiwamadf` | waktu mulai kolak | `KolakData::getStartTime()` |
| `jfauefna` | jumlah stok kolak | `KolakData::getJumlahStok()` |
| `jhauragla` | harga jual kolak (string) | `KolakData::getHargaJual(bool)` |
| `ifafiawsada` | daftar resep kolak (array int) | `KolakData::getListResep()` |
| `kjoulaakl` | jumlah kolak terjual | `KolakData::getNJualKolak()` |
| `rkoelkaokr` | rekor (array string angka) | `KolakData::getDataRekor()` via `getTextPolos()` |
| `jtudoaatltala` | total penjualan per item (array string angka) | `KolakData::getListTotalPenjualan()` via `getTextPolos()` |
| `krolesaekp` | resep terbaik (array int) | `KolakData::getResepTerbaik()` |

### `ksepathrui` (KsatriaTahu / pet — semua yakin, key plaintext)
`idResep` (id resep), `stage`, `namaPet`, `state`, `exp` (SecureLong), `level` (SecureLong),
`timerResep`, `timerMakan`, `timerJurus`, `timerEvolve` (float),
`delayResep`, `delayMakan`, `delayJurus`, `delayEvolve` (long),
`jlhPakaiJurus` (jumlah pakai jurus, `getJumlahPakaiJurus`), `ctMakanKsatriaTahu` (hitungan makan, int di Cabang+0xaa4),
`lastPakaiJurus` (string tanggal terakhir pakai jurus).

### `dfetaats` (data festival — semua yakin, getter `Cabang`)
| key | arti | bukti |
|---|---|---|
| `mitobemli` | data mobil festival (map string→string) | `Cabang::getDataMobilFestival()` |
| `irteesepm` | data resep festival (array {`idx`, `cabang`}) | `Cabang::getDataResepFestival()` |
| `pirteomom` | data promo festival (array {`idx`, `cabang`}) | `Cabang::getDataPromoFestival()` |
| `dsattaetr` | tanggal mulai festival | `Cabang::getStartDateFestival()` |
| `dafetneesd` | tanggal akhir festival | `Cabang::getEndDateFestival()` |
| `pwoaprude` | data popup reward festival | `Cabang::getDataPopUpRewardsFestival()` |
| `ltiaestrtg` | daftar target festival (array string angka) | `Cabang::getListTargetFestival()` via `OwnDisplayInteger::getTextPolos()` |
| `lhiasadtih` | daftar hadiah festival (array Json) | `Cabang::getListHadiahFestival()` |
| `bfeuiksatv` | bool | (field festival; getter tidak tercatat) |
| `ifeidatsvl` | id festival (int) | `Cabang::getIdFestival()` |
| `usltaonrgy` | bool | (field festival; getter tidak tercatat) |
| `vsererrvsie` | versi festival server (int) | `Cabang::getVersiFestivalServer()` |
| `liawdsxtr` | indeks reward festival terakhir (int) | `Cabang::getLastIdxRewardFestival()` |

Di save ini `f73r5y50.dfetaats` hanya berisi 3 key (`bfeuiksatv`, `ifeidatsvl`, `usltaonrgy`) — field lain kondisional /
festival tidak aktif.

### `gisgaemk[]` (penjual — yakin)
| key | arti | bukti |
|---|---|---|
| `legaegm` | level penjual (SecureLong; 0 / -1) | SecureLong per penjual; dicocokkan ke XML node `penjual` by id |
| `jfauefna` | stok (SecureLong) | SecureLong per penjual |
| `uwnfalef` | int (-1 di semua item) | int; kemungkinan ID/indeks penjual (default -1) |

### `gegaefa[]` (loker — yakin)
| key | arti | bukti |
|---|---|---|
| `jfauefna` | stok (SecureLong) | SecureLong per loker; dari XML node `loker` |
| `akfeaofeg` | bool | kemungkinan status buka/kunci loker |
| `tiwamadf` | timestamp (long) | long timestamp per loker |

### `aushfajfe` (6 flag bool — tidak diketahui)
`iajffawss` → GameData+0x7e0, `uawdnsafd` → +0x7e1, `fawfppfea` → +0x7e2, `ir93asass` → +0x7e3,
`iafpesksd` → +0x7e4, `f3owadssd` → +0x7e5. Enam flag boolean tanpa petunjuk tujuan.

### `auwfkassd` (tebakan)
`iaufasdsds` (int), `awufakfla` (int) — objek 2 int; dipakai bersama `TimeUtil`, kemungkinan rentang waktu event.

### `ahdeivtneah` (data event — yakin)
| key | arti | bukti |
|---|---|---|
| `tjapuemvlnath` | string | string → GameData+0x9e8 |
| `iesvveinpt` | bool | bool → GameData+0x9b8 |
| `leavjenatn` | int | int → GameData+0x938 |
| `fotrpens` | bool (default true) | bool → GameData+0xa08 |
| `lvaesipvt` | int (default -1) | int → GameData+0xa0c |
| `devaetnat` | data event (lihat bawah) | objek Json disalin ke GameData+0x9c0 |

`devaetnat` (yakin — key sebagian plaintext): `data` (array tier hadiah), `deskripsi`, `start_date`, `end_date`,
`icon_event`, `id_event` (int), `id_iap` (string), `id_iap_diskon` (string), `id_leaderboard` (string),
`img_banner`, `is_active`, `popup_vip`, `popup_vip_diskon`, `versi`.
Tiap elemen `data`: {`target` (int), `tipe` (int), `normal` (array hadiah), `vip` (array hadiah)}.
Tiap hadiah: {`idItem`, `jumlah`, `namaItem`, `tipe`} — contoh: Peridot ×5 (normal), Celengan [L] / Jam Kristal (vip, tipe `iap`).
`popup_vip` / `popup_vip_diskon`: objek berisi `img`.

### `dcoarhtoaamt` (data chat Own Connect — yakin)
Per kontak (room): "Own Connect Admin", "Bapak Investor", "Satpam Elit", "Accel".

| key | arti | bukti |
|---|---|---|
| `scthaorty` | story saat ini (int) | `ChatRoom::setCurStory` |
| `lstarsoty` | story terakhir (bool) | `ChatRoom::setIsLastStory` |
| `cldameyala` | lama delay story (float) | `ChatRoom::setLamaDelayStory` |
| `tdiymaeerl` | timer delay story (float) | `ChatRoom::setTimerDelayStory` |
| `hictaettinmg` | item chatting / struktur cerita | objek ItemChatting |
| `lchaatst` | pesan chat (array) | array pesan |
| `ccabahatng` | nama cabang (string) | dipakai di chat Bapak Investor |

`hictaettinmg` (ItemChatting — key sebagian plaintext): `isFromUser`, `id`, `tipe`, `nextTipe`, `nextId`,
`strText`, `isNextFromUser`, `idFoto`, `isUlangStory`, `isDelayStory`, `delayStory`.
`lchaatst[]`: {`sender`, `waktu` (int64 ms), `pesan`, `isUlangStory`} (field `notif`/`"Me"` di kode).

### `clgasgnbat` (data cabang lintas-game — mungkin)
Anggota: `FTTB` dan `KTB` (masing-masing {`curIdxTarget`: -1}).
`FTTB` dan `KTB` juga dipakai di Java `MainActivity.onActivityResult` (`classes3.dex`) — kemungkinan kode/ID game lain
dari Own Games untuk fitur lintas-game (judul game pastinya tidak diketahui).
`lastJsonResponse` juga dibaca di `loadCabangLintasGame` (bukan key di save ini).

### `remakdsyds[]` (data rempah — yakin)
Per elemen: `uahfeysss` (int — indeks/id rempah), `hadysdess` (float), `aeyfgaudies` (string), `uhfaefask` (string),
`iejfaisdsa` (int) — kelimanya diteruskan ke `RempahManager::loadRempah(int, int, string, string, int)`.
25 slot; `uahfeysss` berjalan 0–24.

### `afjiejsde[]` (data peti — yakin)
Per elemen: `uahfeysss` (int — id/tipe peti), `hadysdess` (float — timer, contoh 14400.0 = 4 jam),
`uhfaefask` (int — flag 0/1) — ketiganya diteruskan ke `ChestManager::setChest(idx, id, timer, flag)`.
3 slot; entri ke-2 dan ke-3 hanya berisi `uahfeysss: -1` (slot kosong).

### `whtsraieck[]` (daftar paket konten — yakin)
Per elemen: `identifier` (string — nama paket: "akangtahu", "ramadhan"), `versi` (int — 21 dan 1).

### `KEY_STATE_CALENDAR[]` (yakin)
Tiap elemen array posisi: [idItem, jumlah, namaItem, sudahDiambil] — contoh: ["loker_b", "1", "loker_b", 1],
["koin", "5", "penghasilan", 0].

### `KEY_STATE_LABEL_REWARD[]` (yakin)
Tiap elemen: {`state`: int}.

### `amlfudwahfnfe` (mungkin)
Objek berisi entri `VIP_DATA_0`, `VIP_DATA_1`, … (loop format "%d") — data VIP; null di save ini.

### `lmisvaten[]` / `tsunlriaoga[]` / `sboitngai[]` / `hleiglehve[]` (mungkin, lihat §C)
- `lmisvaten[]`: {`level`, `main`}
- `tsunlriaoga[]`: {`level`, `sudahTutorial`}
- `sboitngai[]`: {`level`, `bintang`}
- `hleiglehve[]`: {`level`, `score`}

### Nama yang dipakai ulang di banyak struct
- `legaegm` — SecureLong "level/tingkat" (di `adwkdsafs`, `fawkkawss`, `kamsdasfg`, `gisgaemk`).
- `jfauefna` — "stok" (SecureLong di `gisgaemk`, `gegaefa`, `jafekfsd`; int di `kdoaltaka`).
- `tiwamadf` — timestamp (long) di banyak struct.
- `ifafiawsada` — angka tampilan (string dari `OwnDisplayInteger::getTextPolos()`) di `adwkdsafs`/`kamsdasfg`;
  array int daftar resep di `kdoaltaka`.
- `q2kdaslflf` — nama tampilan (di `adwkdsafs`, `jafekfsd`).
- `sifmefad` — bool flag (di `aufhasas`, `nalsjfafee`, `kamsdasfg` di kode lama — di save ini `kamsdasfg` hanya berisi
  `legaegm` + `ifafiawsada`).
- `uahfeysss` / `hadysdess` / `uhfaefask` — field bersama `remakdsyds` dan `afjiejsde` (indeks/id, timer/durasi, flag).

## E. Yang tetap tidak bisa ditentukan

1. **~40 field state kecil di `GameData`** (int/bool/float/string + offset 0x18–0xc01): hanya tipe + offset yang diketahui
   (`alwfaifaksl`, `iafjauelsds`, `waafeaggs`, `jafwkmfa`, `asfalsjfla`, `bgaefmlw`, `faoekfwa`, `igsjgklsfa`,
   `afoafkafksd`, `bfakfafwf`, `fkmfagrgh`, `lfawogkaeg`, `akfofakgas`, `anwlfaliejf`, `8aksfklas`, `isfuisjkda`,
   `afjiafasdds`, `jfheudsads`, `aijdafeae`, `auhfalsdesss`, `oaofkamfas`, `fpaeoflas`, `ppamleasa`, `kafnkafa`,
   `ianfkawls`, `lopintesna`, `lfpeorveeill`, `oalunwitgnoo`, `cjloackm`, `mabruskias`, `ifjwuajnsk`, `pepfalfeis`,
   `ieflfjeds`, `ooawkfkes`, `eufhlaosfe`, `afuhfuefs`, `aufhaksdle`, `tsawliroaun`, `wpophtaasu`, `swrhmdnaa`,
   `suwltwaha`, `swrhmdnaa26`, `noaitsfki`, `kaangenkg`). Alasan: tidak ada nama getter/fungsi yang memakainya;
   untuk menentukannya perlu melacak pemakaian tiap offset GameData di seluruh `.so` (xref balik per offset) —
   di luar jangkauan tugas ini.
2. **Field cabang yang semuanya 0/false** (`kafefma2s`, `ukhifas2atsuds`, `uhfa2asds`, `a9iawifmkaw`,
   `gsekanterasi`, `ttuikmrepar`, `ctpuentredro`, `usntlockgo`, `hasortgin`, `hosmnetg`, `henisghsls`,
   `rkaessteipa`, `aufhasas`, `nalsjfafee`, `kamsdasfg` sebagai objek): tidak ada pemakaian bernama yang memberi arti.
3. **`iiafefked`** — tidak dibaca kode mana pun (native maupun dex); hanya tersisa di file save.
4. **`FTTB` / `KTB`** — judul game pastinya tidak diketahui (hanya dipakai sebagai ID di `MainActivity.onActivityResult`
   dan sebagai member `clgasgnbat`).
5. **`fisjefkasda`** — hanya bentuk nilainya (string token 20 karakter) yang memberi petunjuk; tidak ada pemakaian bernama.
6. **Key format lama** (`fgkefeassdf`, `friemfsa`, `klafawall`, `oakwfeaef`, `palfajgej`) — hanya dibaca `convertDataLama`;
   arti aslinya tidak tercatat di kode baru.
7. **`aksfkfi2a` / `ajfaw22sa`** — hanya struktur (7 dan 12 SecureLong) + pola nilai yang diketahui; label pastinya
   (target/ambang/penghitung apa) tidak terbukti.
8. **`lmisvaten` / `tsunlriaoga` / `sboitngai` / `hleiglehve`** — hanya struktur {level, X} yang diketahui; nama fitur
   pastinya (misi/tutorial/rating/skor) tidak terbukti dari nama getter (loop body belum dibaca penuh).

## F. Catatan tambahan
- `popup_promo` BUKAN key save — itu config dari `GameUtil::getStringConfig("popup_promo")` (JSON config, bukan file save).
- `id`, `start_date`, `end_date`, `id_event`, `kode_event`, `img_banner`, `id_leaderboard`, `id_iap`, `id_iap_diskon`,
  `img`, `image`, `identifier`, `versi`, `target`, `tipe`, `normal`, `vip`, `idItem`, `jumlah`, `namaItem`,
  `deskripsi`, `icon_event`, `is_active`, `data` adalah key plaintext di dalam objek event/konten (bukan key acak).
- Sufiks `_0_cio0` / `_0_jecm` pada nama file save TIDAK dibangun kode APK (kemungkinan jalur export/backup di luar game).
- File kerja analisis: `build_xrefs.py`, `xref_map.json`, `disas_func.py`, `saveDataCabang.txt`, `loadData.txt`,
  `loadDataBaru.txt`, `saveAllGameData.txt`, `convertDataLama.txt`, `loadCabangLintasGame.txt`,
  `loadCabangFestival.txt`, `gap_*.txt`.
