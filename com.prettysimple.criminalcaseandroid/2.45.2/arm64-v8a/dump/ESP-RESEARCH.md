# Riset ESP — Criminal Case v2.45.2 (1830811)

**Tanggal:** 11 November 2026 (WIB)
**Target:** `com.prettysimple.criminalcaseandroid` v2.45.2 — ESP garis/kotak overlay ke objek misi di scene hidden-object
**Status:** FASE STATIK SELESAI — laporan riset, BUKAN aplikasi ESP. Tidak ada APK/lib game yang diubah, tidak ada hook/patch.
**Dasar:** `REPORT.md` (REA 11 Nov 2026) + analisis lanjutan dari `libcriminalcase.so` (20,2 MB, Cocos2d-x 2.2.6, namespace `montana`).

---

## 1. Vonis kelayakan

### MUNGKIN — layak lanjut ke fase runtime, dengan dua gerbang yang belum terjawab

Bukti statiknya kuat dan spesifik (bukan dugaan umum): kelas-kelas yang tepat untuk ESP **terbukti ada** di binary (`montana::HOItem`, `montana::HOScreen`, `montana::HOItemPanel`, `montana::QuadTree`, …), alamat vtable mereka **berhasil diturunkan dari graf relokasi**, dan layout memori engine-nya **diketahui persis dari sumber resmi Cocos2d-x 2.2.6**. Tidak ada satu pun dari fondasi itu yang ternyata kosong.

Tapi ESP **belum bisa dinyatakan pasti bisa**. Dua hal hanya bisa dipastikan saat game jalan di perangkat:

1. **Layout field kelas custom `montana::HOItem` / `HOItemPanel`** — nama kelasnya terbukti, tapi isi memorinya (di offset mana posisi, nama item, status "sudah ditemukan", dan bagaimana panel misi menunjuk ke objeknya) tidak ada di file statik. Harus dibaca dari memori hidup.
2. **Perilaku PairIP terhadap pembacaan memori read-only** — tidak ada bukti PairIP mendeteksi/memblokir pembacaan memori dari proses lain, tapi internals-nya opak, jadi tidak bisa dinyatakan aman 100% dari statik.

**Keputusan yang direkomendasikan:** lanjut ke fase capture runtime (rencana di §6). Bila kedua gerbang lolos, ESP bisa dibangun dengan pendekatan **read-only** (tanpa hook, tanpa patch). Bila salah satu gagal, opsinya tinggal hook fungsi engine (risiko PairIP naik jauh) atau batal.

**Yang TIDAK berubah dari REA:** posisi objek tidak bisa dibaca dari file — konten JSON terenkripsi, dan itu terkonfirmasi ulang (tidak ada satupun koordinat/posisi objek di string dump atau aset plaintext).

---

## 2. Temuan statik — TERBUKTI

### 2.1 Kelas-kelas kunci ESP ada di binary (RTTI typeinfo)

Binary di-strip dari symbol table statik (tidak ada `.symtab`), tapi **nama tipe RTTI selamat** — 551 kelas `montana::` dan 160 kelas `cocos2d::` berhasil diekstrak dari string typeinfo (`montana-rtti-classes.txt`, `montana-class-list.txt`, `cocos2d-class-list.txt` di folder ini). Yang paling relevan:

| Kelas | Peran yang disimpulkan | Bukti |
|---|---|---|
| `montana::HOItem` | Satu objek hidden-object di scene (HO = Hidden Object) | RTTI `N7montana6HOItemE`, string `hidden_object` di dump baris 30648 |
| `montana::HOScreen` | Layar utama permainan hidden-object (crime scene) | RTTI `N7montana8HOScreenE` |
| `montana::HOItemPanel` | Panel daftar misi (nama barang yang harus dicari) | RTTI `N7montana11HOItemPanelE` |
| `montana::HOItemPanelSlot` | Satu slot misi di panel | RTTI `N7montana15HOItemPanelSlotE` |
| `montana::StageScreen` | Layar "stage" (wadah scene + UI) | RTTI `N7montana11StageScreenE` |
| `montana::StageNode` | Node stage di scene graph | RTTI `N7montana9StageNodeE` |
| `montana::QuadTree` / `QuadTreeNode` / `QuadTreeItem` / `QuadTreeDelegate` | Indeks spasial untuk hit-test sentuhan (quadtree = struktur yang memetakan posisi objek) | RTTI keempat nama |
| `montana::LayerPanZoom` (+ Delegate) | Layer scene yang bisa di-pan/zoom — transform inilah yang menggeser posisi layar | RTTI `N7montana12LayerPanZoomE` |
| `montana::MGFind` / `MGFindClue` / `MGFindTrash` / `MGFindTheSame` | Minigame-minigame "cari" (bukan scene utama) | RTTI; teks UI `MGFindHeadLine: "Move the objects to find the clue!"` |
| `montana::MinigameScreen` / `MinigameTopBar` / `MinigameCounter` | Wadah minigame | RTTI |
| `montana::TimeAttackScreen` | Mode Time Attack ("Find as many hidden objects as possible") | RTTI + teks UI |
| `montana::DifferenceScreen` | Mode "spot the difference" | RTTI |
| `montana::HOFXScore` | Efek skor saat objek ditemukan | RTTI |
| `montana::MontanaGame` | Kelas utama game | RTTI |
| `montana::ClueNode` / `ClueBox` / `InvestigateNode` | Node barang bukti / investigasi | RTTI |
| `cocos2d::CCScene` / `CCNode` / `CCSprite` / `CCDirector` / `CCLayer` / `CCArray` | Engine (lihat §3) | RTTI |

**Catatan scope:** ESP tahap pertama harus menyasar **crime scene utama (`HOScreen`/`StageScreen`)**, bukan minigame. Minigame (`MGFind*`, `DifferenceScreen`, `TimeAttackScreen`) adalah layar terpisah dengan mekanisme berbeda — masing-masing butuh pemetaan sendiri nanti.

**Tidak ditemukan:** nama method/fungsi apa pun untuk kelas-kelas di atas (0 signature berhasil di-demangle). Symbol table statik memang di-strip; yang selamat hanya nama tipe. Alamat fungsi harus dicari lewat disassembly (lihat §2.3) atau di-runtime.

### 2.2 Jangkar vtable dari graf relokasi (alamat virtual, relatif terhadap base load `.so`)

Metode: string nama typeinfo (`N7montana…E`) di `.rodata` → relokasi `R_AARCH64_RELATIVE` yang menunjuk ke string itu = field nama dari objek typeinfo → objek typeinfo terkonfirmasi (field+8 cocok dengan string) → semua relokasi yang menunjuk ke objek typeinfo = kandidat `vtable[1]` → vtable dimulai 16 byte sebelumnya. Semua objek typeinfo di bawah **terkonfirmasi** (reloc field nama cocok).

| Kelas | String nama (offset file `.rodata`) | Objek typeinfo (vaddr) | Kandidat vtable (vaddr) | Keyakinan |
|---|---|---|---|---|
| `montana::HOItem` | `0x3c1c58` | `0x11c3d48` | **`0x11c3d00`** | **Tinggi** (satu-satunya referensi) |
| `montana::HOItemPanel` | `0x3c1c6a` | `0x11c40a8` | **`0x11c3d58`** | **Tinggi** (satu-satunya referensi) |
| `montana::HOItemPanelSlot` | `0x3c1c82` | `0x11c4408` | **`0x11c40b8`** | **Tinggi** (satu-satunya referensi) |
| `montana::QuadTree` | `0x3c4cf3` | `0x1204980` | **`0x1204938`** | **Tinggi** (satu-satunya referensi) |
| `montana::QuadTreeNode` | `0x3c4cda` | `0x1204970` | **`0x1204918`** | **Tinggi** (satu-satunya referensi) |
| `montana::QuadTreeItem` | `0x3c0899` | `0x11aac10` | **`0x11aabf0`** | **Tinggi** (satu-satunya referensi) |
| `montana::HOFXScore` | `0x3c1c43` | `0x11c3cf0` | `0x11c3c68` | Sedang (2 kandidat; diambil yang terdekat sebelum typeinfo) |
| `cocos2d::CCDirector` | `0x3c671c` | `0x1208d30` | `0x1208d18` | Sedang (3 kandidat; diambil yang terdekat sebelum typeinfo) |
| `montana::LayerPanZoom` | `0x3bf415` | `0x1195170` | `0x1195148` | Sedang (4 kandidat) |
| `montana::MGFind` | `0x3c0ee4` | `0x11ad108` | `0x11ad0b0` | Sedang (6 kandidat) |
| `montana::HOScreen` | `0x3c1790` | `0x11bafe8` | `0x11bafb0` | Sedang (10 kandidat) |
| `montana::StageScreen` | `0x3c17e8` | `0x11bc128` | `0x11bc100` | Sedang (7 kandidat) |
| `montana::StageNode` | `0x3bf996` | `0x1199fb8` | `0x1199e50` | Sedang (3 kandidat) |
| `cocos2d::CCScene` | `0x3c6891` | `0x120bcb0` | `0x120bcc8` | Sedang (4 kandidat) |
| `cocos2d::CCSprite` | `0x3c6eaf` | `0x120fc98` | `0x120fc60` | Sedang (21 kandidat — banyak subclass) |
| `cocos2d::CCNode` | `0x3c6603` | `0x1208840` | `0x12080b8` | Sedang (∼100 kandidat — vtable CCNode besar, ∼100 fungsi virtual; kandidat yang diambil berjarak 0x788 sebelum typeinfo, konsisten dengan ukuran vtable sebesar itu) |
| `montana::MinigameScreen` | `0x3c115f` | `0x11b2540` | `0x11b3da8` | Sedang (14 kandidat) |
| `montana::TimeAttackScreen` | `0x3c1800` | `0x11bc800` | `0x11bc7c8` | Sedang (10 kandidat) |
| `montana::DifferenceScreen` | `0x3c1741` | `0x11ba8a0` | `0x11ba880` | Sedang (8 kandidat) |

**Cara verifikasi di runtime (wajib):** baca memori yang sudah direlokasi di `base + vtable`, cek `[0] == 0` (offset-to-top, single inheritance), `[1] == base + typeinfo`, `[2..]` semuanya menunjuk ke dalam rentang `.text` (`0x75ea80–0x11725d4`). Bila salah satu gagal, kandidat itu salah — coba kandidat lain dari daftar referensi.

**Jebakan yang sudah dihindari:** isi file `.data.rel.ro` di disk **tidak bisa** dipakai memverifikasi vtable — linker (LLD) mengisi slot pointer dengan 0 di file dan hanya mengisi addend di entri `.rela.dyn`; nilai pointer baru ada setelah loader menerapkan relokasi di memori. Referensi yang jatuh di `.got` (mis. `StageNode` `0x12a02f0`) adalah slot GOT untuk pemakaian `typeid`, bukan vtable — jangan dipakai.

**Jangkar tambahan (ekspor dinamis, alamat virtual pasti):** 69 ekspor JNI di `.dynsym`, di antaranya `Java_org_cocos2dx_lib_Cocos2dxRenderer_nativeRender @ 0xb0c364`, `nativeInit @ 0xad5c3c`, `nativeTouchesBegin @ 0xb0cce4`, `nativeTouchesEnd @ 0xb0cd54`, `JNI_OnLoad @ 0xad5c38`. Berguna sebagai titik masuk alternatif bila heap-scan buntu (mis. breakpoint/read di `nativeRender` untuk mengambil alamat scene saat frame digambar — tapi itu sudah masuk wilayah hook, lihat §5).

### 2.3 Kode `.text` TIDAK terenkripsi saat diam — disassembly statik dimungkinkan

- Entropi `.text` (10,5 MB) stabil **6,50–7,04 bit/byte** di semua segmen 1 MB, dengan ratusan prolog fungsi ARM64 (`stp x29, x30`) dan ribuan `ret` per segmen. Itu profil kode ARM64 asli, bukan ciphertext (ciphertext akan ~8,0 tanpa pola instruksi).
- Artinya PairIP **tidak mengenkripsi seluruh segmen kode di file** — yang di-VM-kan kemungkinan hanya fungsi-fungsi tertentu (atau proteksinya bekerja di level lain). Disassembly statik dengan `llvm-objdump` dari NDK (tersedia di VM: `~/android-sdk/ndk/26.1.10909125/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump`; `objdump` sistem TIDAK mendukung AArch64) bisa dipakai untuk mencari alamat fungsi engine (mis. `CCNode::getPosition`, `CCDirector::sharedDirector`) lewat xref string/vtable — pekerjaan lanjutan bila heap-scan butuh bantuan.
- Batasan: tanpa symbol table, pencarian fungsi tetap berbasis pola (xref ke string/vtable yang sudah diketahui) — makan waktu, tapi jalurnya ada.

### 2.4 Mekanisme misi: daftar target itu dinamis per permainan

String `items_repartition` (dump baris 30650) dan `elite_items_repartition` (baris 27535) di klaster nama item scene (`napkin`, `tornfabric`, `hidden_object`, `reveal_arrow`, …) menunjukkan item-item **didistribusikan ulang (repartition) tiap permainan** — daftar misi kemungkinan dipilih acak dari pool item scene di tiap putaran, bukan daftar tetap per scene. Konsekuensinya untuk ESP:

- Posisi tiap item (kemungkinan) tetap per scene, tapi **subset yang jadi misi berubah tiap main**.
- ESP tidak cukup hanya memetakan semua `HOItem` — ia harus tahu **subset mana yang sedang jadi misi**, dan itu hanya ada di state runtime (`HOItemPanel` + slot-slotnya, atau `StageScreen`/`HOScreen`).
- Bagaimana slot panel menunjuk ke objeknya (pointer langsung ke `HOItem`? ID item? indeks?) **tidak diketahui dari statik** — ini pertanyaan runtime nomor satu (§6 langkah 6).

### 2.5 PairIP — yang terbukti dan yang tidak

Terbukti:
- `libpairipcore.so` (608.896 B) adalah NEEDED pertama `libcriminalcase.so`; `KeyImportApplication` di manifest.
- String-nya 2.905 baris; kata kunci anti-tamper yang dicari (`ptrace`, `frida`, `xposed`, `magisk`, `substrate`, `hook`, `integrity`, `tamper`, `root`) **0 hit** — yang ada hanya impor generik `dlopen`/`dlsym` (konsisten dengan loader/VM).
- Tidak ada deteksi root/Magisk/Xposed/Frida di smali maupun string native (sesuai REA).

Tidak terbukti / tidak bisa dinilai dari statik:
- Apakah PairIP memindai memori/proses lain, memeriksa `/proc/self/maps`, atau mendeteksi pembacaan memori eksternal. Internals-nya opak.
- Apakah ada pemeriksaan integritas berkala terhadap `.text` di memori (ini relevan hanya bila ada yang men-patch; pembacaan read-only tidak mengubah apa pun, jadi pemeriksaan integritas kode tidak akan terpicu oleh baca saja — secara teori).

**Penilaian:** pendekatan read-only (baca `/proc/<pid>/mem`, tanpa menulis, tanpa hook, tanpa patch) **tidak menyentuh satu pun mekanisme yang terbukti ada** (tanda tangan, verifikasi receipt server, konten terenkripsi). Risiko sisa adalah perilaku PairIP yang tidak terlihat — hanya bisa diuji empiris di fase runtime (§6 langkah 8: amati apakah game crash/aneh selama probing read-only).

---

## 3. Peta struktur Cocos2d-x 2.2.6 (sumber resmi, tag `cocos2d-x-2.2.6`)

Header diverifikasi langsung dari repo `cocos2d/cocos2d-x` tag `cocos2d-x-2.2.6` (disimpan di folder ini: `CCNode.h`, `CCSprite.h`, `CCScene.h`, `CCLayer.h`, `CCDirector.h`, `CCObject.h`, `ccTypeInfo.h`). Semua offset di bawah adalah **arm64 LP64, layout stok engine** — wajib diverifikasi di runtime karena Pretty Simple bisa saja mem-patch engine-nya.

### 3.1 `CCNode` — objek dasar semua yang tampil di layar

`CCObject` (base): vptr +0 (8 B), `m_uReference` +8 (uint), `m_uAutoReleaseCount` +12 (uint) → ukuran base 16 B.

| Offset | Field | Tipe | Catatan ESP |
|---|---|---|---|
| +16 | `m_fRotationX` | float | |
| +20 | `m_fRotationY` | float | |
| +24 | `m_fScaleX` | float | |
| +28 | `m_fScaleY` | float | |
| +32 | `m_fVertexZ` | float | |
| **+36** | **`m_obPosition`** | **CCPoint (x f32, y f32)** | **POSISI node dalam koordinat parent — field terpenting ESP** |
| +44 | `m_fSkewX` | float | |
| +48 | `m_fSkewY` | float | |
| +52 | `m_obAnchorPointInPoints` | CCPoint | |
| +60 | `m_obAnchorPoint` | CCPoint | |
| +68 | `m_obContentSize` | CCSize (w f32, h f32) | ukuran sprite → untuk menggambar kotak |
| +76 | `m_sAdditionalTransform` | CCAffineTransform (6×f32) | dipakai `LayerPanZoom` untuk pan/zoom |
| +100 | `m_sTransform` | CCAffineTransform | |
| +124 | `m_sInverse` | CCAffineTransform | |
| +152 | `m_pCamera` | ptr | |
| +160 | `m_pGrid` | ptr | |
| +168 | `m_nZOrder` | int | |
| **+176** | **`m_pChildren`** | **`CCArray*`** | **jalan menelusuri scene tree** |
| **+184** | **`m_pParent`** | **`CCNode*`** | **jalan naik ke root (untuk komposisi transform)** |
| +192 | `m_nTag` | int | kemungkinan ID item |
| +200 | `m_pUserData` | ptr | |
| +208 | `m_pUserObject` | ptr | |
| +216 | `m_pShaderProgram` | ptr | |
| +224 | `m_eGLServerState` | int | |
| +228 | `m_uOrderOfArrival` | uint | |
| +232 | `m_pScheduler` | ptr | |
| +240 | `m_pActionManager` | ptr | |
| +248..254 | 7× bool (`m_bRunning`, `m_bTransformDirty`, `m_bInverseDirty`, `m_bAdditionalTransformDirty`, `m_bVisible`, `m_bIgnoreAnchorPointForPosition`, `m_bReorderChildDirty`) | bool | **`m_bVisible` di +252** |
| +256 | `m_nScriptHandler` | int | |
| +260 | `m_nUpdateScriptHandler` | int | |
| +264 | `m_eScriptType` | int | |
| +272 | `m_pComponentContainer` | ptr | |
| = 280 | ukuran `CCNode` | | |

Aturan waris yang relevan: bila `HOItem` mewarisi `CCSprite` (atau `CCNode`) secara tunggal dengan base pertama, maka **subobjek `CCNode` ada di offset +0** dan posisi tetap di **+36/+40** — field turunan `CCSprite` (`m_pobTextureAtlas`, `m_obRect`, …) menempel SETELAH +280. Bila `HOItem` mewarisi `CCNodeRGBA`, field RGBA menempel setelah +280 juga (base kedua `CCRGBAProtocol` adalah interface tanpa data). Ini asumsi yang masuk akal, tapi **harus dibuktikan di runtime** (korelasikan nilai +36/+40 dengan posisi layar yang terlihat).

### 3.2 Struktur penelusuran scene tree

- `CCArray` (di +176): `CCObject` base (16 B) + `ccArray* data` di **+16**. `ccArray` (definisi stok 2.2.6 — **belum berhasil diverifikasi ulang dari sumber di sesi ini**, file `ccCArray.h` tidak ketemu di path yang dicoba; verifikasi saat runtime): `num` +0 (uint), `max` +4 (uint), `arr` +8 (`CCObject**`).
- `CCScene : CCNode` — **tidak menambah field** (header 71 baris, hanya method). Jadi objek scene punya layout `CCNode` yang sama.
- `CCDirector : CCObject, TypeInfo` — **dua vptr** (`TypeInfo` di `ccTypeInfo.h` adalah base polimorfik: `virtual long getClassTypeInfo() = 0;`), jadi vptr kedua ada di +16 dan member sendiri mulai +24. Dengan urutan member terproteksi di header, **`m_pRunningScene` ada di +112** (bukan +96 — selisih ini berasal dari vptr kedua; contoh jebakan yang membuat verifikasi runtime wajib). `CCDirector` konkret di Android adalah subclass (`CCDisplayLinkDirector`) — field tambahannya menempel setelah member `CCDirector`, jadi offset +112 tidak berubah.
- `CCSprite` menambah field setelah +280 (`m_pobTextureAtlas`, `m_uAtlasIndex`, `m_pobBatchNode`, flag-flag dirty, `m_transformToBatch`, `m_sBlendFunc`, `m_pobTexture`, `m_obRect`, …) — tidak dibutuhkan untuk ESP kecuali korelasi ukuran.

### 3.3 Jalur koordinat: node → layar

Posisi di +36 adalah **koordinat parent**, bukan piksel layar. Untuk menggambar garis/kotak overlay, ESP harus:

1. Baca `m_obPosition` (+36), `m_fScaleX/Y`, `m_fRotationX/Y`, `m_obAnchorPoint` (+60), `m_obContentSize` (+68) dari `HOItem` **dan semua ancestor-nya sampai root scene** (lewat `m_pParent` +184).
2. Komposisikan transform (termasuk `m_sAdditionalTransform` +76 milik `LayerPanZoom` — di sinilah pan/zoom scene diterapkan).
3. Konversi poin Cocos2d → piksel layar via faktor skala `CCEGLView` (design resolution vs resolusi fisik POCO).

Alternatif yang lebih sederhana (rencana B, tapi masuk wilayah hook): panggil fungsi engine `CCNode::convertToWorldSpace`/`nodeToWorldTransform` yang sudah jadi — butuh alamat fungsinya (cari lewat disassembly `llvm-objdump`, xref dari string/vtable) dan pemanggilan dari proses lain/Frida. Jalur ini **tidak** dipakai di fase read-only.

---

## 4. Pendekatan yang direkomendasikan: read-only dulu

| Pendekatan | Cara kerja | Risiko PairIP | Keterangan |
|---|---|---|---|
| **A. Read-only memory scan (DIREKOMENDASIKAN)** | Proses root terpisah membaca `/proc/<pid>/mem` + `/proc/<pid>/maps`; parse scene graph dari memori; gambar overlay dari aplikasi terpisah (window sistem). Tidak menulis apa pun ke game, tidak hook. | Paling rendah — tidak ada kode yang diubah, tidak ada fungsi yang dialihkan | Butuh semua offset diverifikasi (§6). Overlay digambar di luar game, jadi tidak tergantung render loop game. |
| B. Hook fungsi engine (mis. `nativeRender`, `CCNode::getPosition`) | Inject `.so` / Frida; panggil fungsi engine untuk posisi dunia | Lebih tinggi — injeksi + interposisi fungsi adalah hal yang paling mungkin dideteksi proteksi | Rencana B bila transform manual terlalu rapuh. Butuh alamat fungsi dari disassembly. |
| C. Patch lib / repack APK | Ubah `libcriminalcase.so` / tanda tangan | Tertinggi — tanda tangan rusak, PairIP hampir pasti bereaksi | **Jangan dilakukan.** |
| D. Baca dari file/statik | — | — | **Sudah terbukti mustahil** (konten terenkripsi). |

---

## 5. Yang masih TIDAK diketahui (jujur)

1. **Layout field `montana::HOItem`** — di offset mana nama/ID item, status ditemukan, bounding rect, dan pointer ke data itemnya. Tidak ada di statik.
2. **Kaitan panel misi ↔ objek** — bagaimana `HOItemPanelSlot` menunjuk ke `HOItem` (pointer? ID? indeks?). Tidak ada di statik.
3. **Apakah `HOItem` mewarisi `CCSprite`/`CCNode` langsung** — bila ada base custom di tengah, offset +36 bisa bergeser. Hanya runtime yang bisa memastikan.
4. **Apakah engine di-patch Pretty Simple** — offset stok 2.2.6 bisa saja bergeser bila mereka mengubah `CCNode`. Hanya runtime yang bisa memastikan.
5. **Perilaku PairIP terhadap pembacaan memori** — tidak ada bukti deteksi, tapi juga tidak ada bukti ketiadaan.
6. **Faktor skala poin→piksel dan design resolution aktif** — harus diukur di perangkat (bergantung `CCEGLView` + resolusi POCO).
7. **Apakah daftar misi berubah saat scene diulang / mode elite** — string `elite_items_repartition` mengisyaratkan distribusi berbeda di mode elite; perlu observasi runtime.
8. **Alamat fungsi engine** (`getPosition`, `convertToWorldSpace`, `sharedDirector`) — tidak ada di statik; perlu disassembly atau runtime (tidak wajib bila jalur A berhasil).

---

## 6. Rencana capture runtime (langkah konkret di POCO user)

**Prasyarat:** Criminal Case v2.45.2 terinstal dan sudah dibuka sampai scene crime scene pertama (case apa pun, scene pertama cukup); HP root (KernelSU); game **jangan** login Facebook dulu selama probing (supaya tidak ada sync skor saat eksperimen; login bisa ditambahkan belakangan).

**Peralatan:** shell root di HP (`su` via Termux/ADB) + satu probe kecil (binary native atau aplikasi root) yang bisa: (a) baca `/proc/<pid>/maps` untuk base address `libcriminalcase.so`; (b) baca `/proc/<pid>/mem` di alamat yang diminta; (c) tulis hasilnya ke file. **Frida TIDAK diperlukan untuk fase ini** (read-only). Bila nanti butuh Frida (rencana B), itu keputusan terpisah.

**Langkah-langkah:**

1. **Dapatkan base address.** Buka game sampai scene crime scene tampil (misi terlihat di panel bawah). Dari root shell: `pid=$(pidof com.prettysimple.criminalcaseandroid)` lalu `grep libcriminalcase.so /proc/$pid/maps` — catat base (awal mapping `r--p` pertama).
2. **Verifikasi jangkar vtable.** Untuk tiap kandidat di §2.2: baca 32 byte di `base + vtable`, cek `[0]==0`, `[1]==base+typeinfo`, `[2],[3],[4]` masuk rentang `.text`. Catat mana yang lolos. Prioritas verifikasi: `HOItem` (0x11c3d00), `HOItemPanel` (0x11c3d58), `HOItemPanelSlot` (0x11c40b8), `QuadTree*` (0x1204938/0x1204918/0x11aabf0), `HOScreen` (0x11bafb0), `StageScreen` (0x11bc100), `CCScene` (0x120bcc8), `CCDirector` (0x1208d18), `CCNode` (0x12080b8).
3. **Temukan instance director.** Heap-scan (baca region heap anonim + mapping `.so`) cari pointer yang nilainya `== base + vtable_CCDirector` yang terverifikasi → itu alamat objek director. Baca `m_pRunningScene` di **+112** dari objek itu → alamat `CCScene` yang sedang jalan. Verifikasi: vptr scene `== base + vtable_CCScene`.
4. **Telusuri scene tree.** Dari scene: baca `m_pChildren` (+176) → `CCArray` → `data` (+16) → `ccArray {num, max, arr}` → tiap child pointer. Rekursif (batasi kedalaman, mis. 8 level) dan catat tiap node: alamat, vptr (cocokkan ke vtable yang dikenal → kenali kelasnya), posisi +36/+40, ukuran +68, `m_bVisible` +252, parent +184. Cari node yang vptr-nya `HOItem`/`HOScreen`/`StageScreen`/`StageNode`/`HOItemPanel`.
5. **Korelasikan posisi.** Pilih satu `HOItem` yang posisinya sudah dikenali secara visual (mis. objek besar di tengah scene). Bandingkan nilai +36/+40 (+ rantai parent) dengan posisi di screenshot. Bila tidak cocok: (a) coba offset alternatif ±, (b) curigai base custom / engine ter-patch — dump 280 byte pertama objek dan cari pola float yang cocok dengan koordinat layar.
6. **Pecahkan kaitan misi ↔ objek (langkah terpenting).** Dengan misi yang diketahui tampil di panel (catat nama-nama item yang diminta, mis. 8 nama): dump memori `HOItemPanel` + semua `HOItemPanelSlot` (alamat dari tree) sebanyak 512 byte tiap objek; cari di dalam dump: pointer yang sama dengan alamat `HOItem` yang ditemukan di langkah 4, atau string nama item, atau indeks kecil yang konsisten. Ulangi di scene berbeda / setelah "repartition" (main ulang scene) untuk melihat apa yang berubah. Tujuan: rumus pasti "slot X ↔ objek Y" + "flag sudah ditemukan di offset Z".
7. **Ukur konversi koordinat.** Untuk 2–3 objek yang sudah dipastikan: catat posisi node (rantai parent lengkap + scale/rotasi/anchor + `m_sAdditionalTransform` layer pan/zoom) dan posisi pikselnya di screenshot (resolusi layar POCO saat game jalan). Turunkan rumus poin→piksel + faktor skala EGLView. Uji rumus ke objek lain; bila meleset konsisten, berarti ada transform yang terlewat (biasanya pan/zoom layer).
8. **Uji toleransi PairIP (pengamatan pasif).** Selama langkah 2–7 (semua read-only), perhatikan: apakah game crash, freeze, force-close, atau muncul popup aneh? Mainkan satu scene sampai selesai setelah probing. Bila tidak ada gejala selama 2–3 sesi probing, anggap read-only ditoleransi (dengan catatan: ini bukti empiris, bukan jaminan).
9. **Serahkan hasil.** Yang harus dibawa pulang dari fase runtime: (a) daftar offset terverifikasi (posisi HOItem, kaitan panel, flag ditemukan), (b) rumus koordinat + faktor skala, (c) hasil uji PairIP, (d) satu dump memori contoh (scene + panel + beberapa HOItem, bila ukurannya wajar) sebagai bahan build ESP. Tanpa keempat ini, pembangunan ESP tidak boleh dimulai.

**Perkiraan usaha:** langkah 1–3 sekitar 1 sesi (1–2 jam) bila tooling probe sudah siap; langkah 4–7 adalah pekerjaan RE yang sebenarnya (beberapa sesi, tergantung seberapa cepat pola ketemu). Langkah 6 adalah yang paling tidak pasti — bila kaitan panel↔objek tidak ketemu dari dump, fallback-nya adalah disassembly fungsi `StageScreen`/`HOItemPanel` (pakai `llvm-objdump` NDK) untuk melihat field mana yang dibaca saat tap — pekerjaan statik lanjutan, bukan runtime.

---

## 7. Pertanyaan terbuka (untuk diputuskan sebelum/saat fase runtime)

1. Apakah probing read-only dilakukan dengan akun Facebook **terputus** (disarankan) atau tetap login? (Risiko sync skor hanya relevan bila ESP dipakai main sungguhan; saat probing tidak ada skor yang diubah.)
2. Bila kaitan panel↔objek tidak ditemukan dari dump memori, apakah lanjut ke disassembly fungsi panel (lebih lama, tapi masih read-only terhadap game) atau langsung naik ke rencana B (Frida/hook)?
3. Apakah ESP nantinya harus bekerja juga di minigame (`MGFind*`, `DifferenceScreen`, `TimeAttackScreen`) atau cukup crime scene utama dulu? (Rekomendasi riset: crime scene dulu.)
4. Siapa yang menjalankan probe di HP — user menjalankan perintah yang disiapkan, atau probe dikemas jadi aplikasi kecil yang tinggal dibuka? (Rekomendasi riset: aplikasi probe kecil lebih andal daripada perintah shell manual yang rawan salah ketik alamat.)

---

## 8. File pendukung (di folder ini)

- `REPORT.md` — REA statik awal (keaslian, klasifikasi energi/koin/cash, server, PairIP).
- `montana-class-list.txt` — 551 kelas `montana::` (RTTI).
- `montana-rtti-classes.txt` — 570 nama tipe `montana::` hasil demangle.
- `cocos2d-class-list.txt` — 160 kelas `cocos2d::` (RTTI).
- `CCNode.h`, `CCSprite.h`, `CCScene.h`, `CCLayer.h`, `CCDirector.h`, `CCObject.h`, `ccTypeInfo.h` — header resmi Cocos2d-x 2.2.6 (tag GitHub `cocos2d-x-2.2.6`) sebagai acuan layout.
- `dumps/strings-libcriminalcase.txt` — 42.669 baris string `libcriminalcase.so` (sumber ekstraksi RTTI).
