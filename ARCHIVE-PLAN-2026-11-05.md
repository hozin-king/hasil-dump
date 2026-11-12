# Rencana arsip 5 Nov 2026 (SUDAH DIGANTIKAN repo ini)

> Dokumen perencanaan 5 Nov 2026 — disimpan sebagai konteks arsip.
> Perintah arsip yang berlaku sekarang adalah yang dipakai repo
> `hasil-dump` ini (struktur `<pkg>/<version>/<bit>/`).

# Daftar Arsip REA + Dump ke GitHub — HASIL SAJA, TANPA APK

Disusun: 5 Nov 2026 ~14:50 WIB (diukur langsung dari `~/workspace`)
Perintah user: 5 Nov 2026 08:34 WIB — arsipkan hasil dump & REA ke GitHub agar AI lain
bisa lanjutkan project (contoh: TikTok LSP, Tahu Bulat, dll). **Hasilnya saja,
tanpa full APK.** APK original/mod dikecualikan.

## Temuan penting — baca dulu sebelum approve

Arsip "semua teks" **tidak bisa sekali push**: total file teks (.md/.txt/.json/.cs/
.java/.xml/.csv/.log/.py) di semua folder ≈ **1,9 GB, ~400 ribu file** — isinya
sebagian besar pohon decompile lengkap (smali/jadx), bukan laporan. Push via
Git Data API untuk volume segitu tidak realistis dalam satu repo (pembanding:
push 129 MB / 13.800 file saja butuh 13 commit chunked). Karena itu daftar ini
dibagi 2 tier.

## Tier 1 — LAPORAN SAJA (disarankan, langsung bisa di-push)

Satu repo privat baru, mis. `hozin-king/rea-archive`, satu folder per project,
isinya hanya file laporan + ringkasan analisis di tiap folder:

| Project | Laporan utama | Ukuran laporan* |
|---|---|---|
| BombSquad | REPORT.md | 6 KB |
| Bunker | REPORT.md + BUILD-MODMENU-v1..v6.md | kecil |
| Catur | REPORT.md | 13 MB teks total di folder |
| CinemaID (baru, 5 Nov) | REPORT.md | 24 MB teks total di folder |
| Clash of Magic | REPORT.md | — |
| COD4 | REA-COD4-v0.5.9.md | 3 MB teks |
| Defender | REPORT.md + ANALISIS-LANJUT.md | — |
| Diamond Quest | HOOK-TARGETS-v360.md + INJECTOR-PATTERNS.md | 39 KB |
| Dota 2 Mobile | REPORT.md | 36 KB |
| Drive (3 folder) | REPORT.md tiap folder | — |
| Farm Frenzy | REPORT.md | — |
| FF Old 2020 Chrono | REPORT.md | 10 KB |
| FFMax | REPORT.md | 7 KB |
| Fragger | REPORT.md | 8 MB teks |
| Higgs Domino | REPORT.md | 8 KB |
| Mario Wonder | REPORT.md | 945 KB teks |
| Mekorama | REPORT.md | 5 MB teks |
| Onet | REPORT.md | — |
| Pool Billiards | REPORT.md + AUDIT-ARCADE.md | 758 KB teks |
| Super Kick Off | REPORT.md | 12 MB teks |
| Total Conquest | REPORT.md | 16 MB teks |
| Traffic Rider | REPORT.md + CLASS_CATALOG.md + methods.json | 97 MB teks |
| Vodobanka | REPORT.md | 27 MB teks |
| World Football | REPORT.md + 3 analysis-*.md | 39 MB teks |
| FF 2019 | ANALISIS.md | 26 MB teks |
| FFMax dump | ANALISIS.md + FFMax-dump.cs + FFMax-Assembly-CSharp.cs | 32 MB teks |
| Vidio | README.md + native_libs.md + urls.txt | 199 KB |
| MPT3 | RE_FINDINGS.md | 4 KB teks |
| Lahelu | DEEPDIVE.md + RINGKASAN.md | 51 MB teks |
| Whee | ANALISIS.md | 3 MB teks |
| TikTok LSP | source modul `tiktok-patch-xposed/` (11 MB, tanpa APK) | 11 MB |
| Tahu Bulat | source `hozin-tahubulat-mod/` + `hozin-tahubulat-patcher/` + `hozin-tahubulat-v43/` (tanpa `original/tahubulat-original.apk` 52 MB di dalamnya) | ~54 MB tanpa APK |

\* "Ukuran teks total di folder" = semua file teks di folder itu, bukan hanya
laporan — laporan intinya sendiri jauh lebih kecil (KB–MB). Tier 1 yang
di-push hanya file laporan/ringkasan, jadi total Tier 1 diperkirakan
**puluhan MB, bukan GB**.

Catatan Tahu Bulat: **tidak ada folder dump full-class terpisah** — yang ada
hanya source mod, patcher, dan APK original. Jadi arsip Tahu Bulat = source +
laporan mod, bukan dump full class. (Sudah disampaikan ke user 5 Nov 08:35 WIB.)
Catatan TikTok LSP: tidak ada folder `rea-tiktok` terpisah — arsipnya dari
source modul + laporan yang ada.

## Tier 2 — DUMP TEKS LENGKAP (nanti, per project, bila diminta)

Pohon decompile lengkap per project, hanya bila AI lain benar-benar butuh.
Perkiraan ukuran teks per folder (diukur 5 Nov 2026):

- rea-bunker 676 MB teks (118.414 file) — paling besar
- rea-drive-dump 505 MB teks (91.027 file)
- rea-defender 176 MB teks (64.158 file)
- rea-trafficrider 97 MB teks · rea-onet 63 MB · rea-defender-github 52 MB
- rea-lahelu-dump 51 MB · rea-worldfootball 39 MB · rea-farmfrenzy 36 MB
- rea-gdrive-20261022 36 MB · ffmax-dump 32 MB · ff2019-dump 26 MB
- rea-cinemaid 24 MB · rea-drive-20261022a 23 MB · rea-totalconquest 16 MB
- rea-drive-20261022b 15 MB · rea-catur 13 MB · rea-newdrive 13 MB
- rea-clashofmagic 13 MB · rea-superkickoff 12 MB · rea-fragger 8 MB
- rea-mekorama 5 MB · mpt3-dump 4 KB teks (sisanya biner)
- Sisanya < 1 MB teks (bombsquad, diamondquest, dota2mobile, ffmax, higgs-domino, ff-old, vidio, whee 3 MB)

Tier 2 butuh repo terpisah per project + push chunked (bukan sekali jalan),
dan tiap project diputuskan sendiri — jangan di-push borongan.

## YANG DIKECUALIKAN (tidak ikut arsip, di tier mana pun)

- Semua `*.apk` / `*.xapk` — contoh: COD4 50 MB, Dota 2 Mobile 494 MB,
  FF Old 2020 Chrono 678 MB, Mario Wonder 4 GB (biner), Whee 816 MB biner.
  Total biner yang dibuang dari arsip: belasan GB.
- Semua `*.dex` / `*.so` / `.bin` / `.zip` dump (mis. `M.WONDER.zip`,
  `FFMax-Assembly-CSharp.zip` — isinya dump biner, bukan laporan).
- `cookies.txt` — ada di `ffmax-dump/`, `rea-mariowonder/`, `whee-dump/`
  (kredensial, jangan pernah naik ke GitHub).
- Folder kerja mentah `apktool_out/` di rea-cinemaid (DEX + res hasil
  apktool, 149 MB biner) — laporannya (REPORT.md) yang naik, bukan ini.

## Rencana push (setelah user setuju)

1. Buat repo privat `hozin-king/rea-archive` (butuh approval card per push —
   kredensial GitHub lama mati sejak 3 Nov, push tidak otomatis).
2. Push Tier 1 dulu (laporan + source TikTok LSP + source Tahu Bulat).
3. Tier 2 hanya bila user/AI lain minta project tertentu.

## Keputusan yang ditunggu dari user (satu jawaban)

- "Gas Tier 1" → buat repo + push laporan saja, atau
- "Gas Tier 1 + sebut project Tier 2" → tambah dump lengkap project itu, atau
- "Satu repo per project" → ubah rencana repo sebelum push.

Jangan push apa pun sebelum jawaban ini — sesuai aturan push hanya bila
disuruh, dan aturan arsip "hasil saja, tanpa full APK".
