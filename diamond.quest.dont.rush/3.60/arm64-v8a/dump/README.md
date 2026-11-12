# rea-defender-dump — Arsip REA Diamond Quest: Don't Rush!

Arsip riset pribadi (repo PRIVAT) hasil dump + reverse engineering game
**Diamond Quest: Don't Rush!** v3.60 (`diamond.quest.dont.rush`, libGDX).
Laporan analisis lengkap ada di `REPORT.md`.

## Isi
- `REPORT.md` — laporan dump & REA (identitas, lib native, arsitektur server, anti-cheat, peta cheat, kelayakan upscale).
- `analysis/` — inventaris & string hasil analisis (9,2 MB).
- `decompiled/dex4/` — sumber hasil decompile classes4.dex (inti game + protokol jaringan `com.gdx.diamond.remote.*`) — terverifikasi dirujuk laporan.
- `decompiled/dex6/` — sumber hasil decompile classes6.dex (launcher).
- `decompiled/jadx-full-partial.zip`, `jadx2-full-partial.zip` — dua keluaran JADX penuh yang berhenti di tengah (batas RAM VM); cakupan kelas iklan/SDK tidak 100%.

## Yang TIDAK diikutkan (tetap lokal di VM)
- File `.apks` unduhan + split APK (base.apk 107 MB — melewati batas 100 MB/file GitHub).
- Aset game & lib native `.so` (biner bawaannya).
- Folder ekstraksi mentah & apktool.

Sumber lokal lengkap: `~/workspace/rea-defender/` (±771 MB).
