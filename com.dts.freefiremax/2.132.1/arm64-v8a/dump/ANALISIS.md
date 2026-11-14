# Analisis metadata FF Max (OB baru, 17 Okt 2026)

- global-metadata.dat terenkripsi XOR single-byte 0xE8 -> decrypt -> metadata v31
- libil2cpp.so ter-strip/protected -> Il2CppDumper auto-mode gagal; parse manual via Python
- Layout v31 (dari source Il2CppDumper): TypeDefinition=88B, MethodDefinition=40B (paramCount@38),
  FieldDefinition=12B, ParameterDefinition=12B

## Hasil verifikasi hook (8/8 OK)
- COW.GamePlay.FollowCamera.get_OffsetForNormal OK
- COW.GameConfig.get_ResetGuest OK
- COW.GamePlay.Player.GetCurrentDashSpeed OK
- COW.GamePlay.Player.get_MaxJumpHeight OK
- COW.GamePlay.Player.get_CustomGravity OK
- COW.GamePlay.Player.get_RisingGravity OK
- COW.GamePlay.Player.get_FallingGravity OK
- COW.GamePlay.Player.get_HeadCollider OK
- Aim-silent: COW.GamePlay.HBIBDMMOOOK.LHNJLFOINDO (params=1) MASIH ADA
- Struct CGKJLKPMGDJ: 9/9 field HitInfo OB55 masih ada (total fields sekarang 18)

## Kesimpulan
Semua nama (termasuk nama obfuscated) IDENTIK dengan OB55. Modul terbaru
(RamaModz-OB55-autoupdate.zip, commit 1a76aad) langsung kompatibel tanpa perubahan.
Field offset di-resolve by-name saat runtime, jadi penambahan field tidak masalah.
Konfirmasi akhir tetap via tab UPDATE di HP user.
