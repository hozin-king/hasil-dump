> Catatan arsip: File sumber bernama `RE_FINDINGS.md`, disalin sebagai `REPORT.md`.

# RE Magic Tiles 3 v13.096.004 (com.youmusic.magictiles)

## Engine
- Unity IL2CPP (libil2cpp.so 74MB arm64, global-metadata.dat v31, 15.9MB)
- Split APK: base.apk + split_UnityDataAssetPack.apk + split_config.arm64_v8a.apk

## Target hook (dari global-metadata.dat v31)

### Unlock semua lagu
- **Class:** `SSSceneManager` (tanpa namespace, TypeDef[391])
- **Method:** `IsSongUnlocked` (method[2880], 0 param, public, return bool)
- **Hook:** Dobby → selalu return `true` (1)
- **Cara resolve runtime:** `il2cpp_class_from_name(image, "", "SSSceneManager")`
  lalu `il2cpp_class_get_method_from_name(klass, "IsSongUnlocked", 0)`

### Alternatif / pendukung
- `GlobalService.ButtonUnlockAllSongsMain_OnClick` (method[12168], 4 param)
  → ada handler UI "unlock all songs" bawaan (mungkin tombol tersembunyi/VIP)
- Terkait: `CheckIfSongUnlocked`, `CheckSongUnlock`, `CheckUnlockSong`, `CanUnlockSong`,
  `OnUnlockSongWithVideo` (unlock via iklan), `WatchAdsToUnlockInit`

## Catatan
- Nama method tidak di-obfuscate (string jelas di metadata).
- Belum dicari: getter coin/diamond (ekonomi client-side, bisa via memscan).
- Auto-play flag bawaan belum ketemu di string — pakai bot pixel (pendekatan C).
