> Catatan arsip: File sumber bernama `ANALISIS.md`, disalin sebagai `REPORT.md`. Arsitektur tidak ditegaskan di analisis — memakai `universal`.

# Analisis Awal APK Whee (lokal, tidak dipublikasikan)

## Identitas
- Package: `com.bytedance.snail` (terverifikasi via APKMirror)
- Version: 45.9.1 (versionCode 2024509010), rilis 12 Agu 2026
- Nama: "Whee - TikTok Chat" — catatan: versi 45.x sudah rebrand jadi aplikasi CHAT ("TikTok's social chat app"); Whee photo-app orisinal adalah v1.x (2024)
- Application: `com.ss.android.ugc.aweme.app.host.AwemeHostApplication`
- Main activity: `com.ss.android.ugc.aweme.splash.SplashActivity`
- minSdk 23, targetSdk 36

## Arsitektur penting
- Base APK = kerangka kode TikTok (package `com.ss.android.ugc.aweme.*`), 23.525 class di 1 dex.
- Hanya 3 class bernama Whee di base dex (`com.tiktok.whee.im.common.impl.WheeIMApiHook` + 2 config popup).
- 420 activity terdaftar di manifest, TAPI sebagian besar (termasuk PhotoDetailActivity, TakoImageActivity, MainActivity) TIDAK ADA di base dex → kode fitur diunduh saat runtime via sistem plugin TikTok.
- Konsekuensi untuk hook: class target harus di-hook by-name; LSPosed `findAndHookMethod` akan memicu class-load saat plugin termuat. Nama class/metode final HARUS dikonfirmasi saat runtime (dump class di HP root).

## API
- Domain: `*.tiktokv.com`, `*.tiktokcdn.com`, `www.tiktok.com`, `mon.tiktokv.com`
- Path foto: `/tiktok/v1/story/highlight/collection/batch_aweme_detail`, `/tiktok/v1/post/settings/`, dsb.

## Proteksi (level base dex)
- Tidak ada string FLAG_SECURE, XposedBridge, frida-server, SafetyNet, PlayIntegrity di base dex (cek riil kemungkinan di native lib + plugin).
- `allowBackup=false`, tidak debuggable.
- `networkSecurityConfig` ada (indikasi cert pinning), `usesCleartextTraffic=true`.
- Screenshot: tidak ada anti-screenshot global terdeteksi di base dex (hanya ScreenShotFeedbackTask untuk laporan feedback & flag live course).

## Kandidat hook point — fitur "download/simpan foto dari timeline"
1. `com.ss.android.ugc.aweme.comment.photocomment.PhotoDetailActivity` / `PhotoDetailActivityV2` (photo viewer; manifest-declared, plugin-loaded) — injeksi tombol/menu download di `onCreate` atau long-press.
2. `com.ss.android.ugc.aweme.tako.otherpage.image.detail.TakoImageActivity` — image detail alternatif.
3. Intersepsi URL gambar di pipeline image loading (Fresco/TTImage, plugin-loaded) — tangkap URL lalu unduh via DownloadManager/MediaStore.
4. Jalur termudah bila UI hook sulit: hook network layer (TTNet) untuk mengoleksi URL gambar timeline.

## Langkah berikut (menunggu spesifikasi user)
- Tentukan perilaku fitur yang diinginkan (tombol download di viewer? auto-save semua foto timeline?).
- Dump class saat runtime di HP root untuk dapat nama metode final, baru tulis modul LSPosed.

File: `whee.apk` (bundle APKM 240MB) → `whee-base.apk` (97MB). Sumber: APKMirror, unduh 15 Okt 2026.
