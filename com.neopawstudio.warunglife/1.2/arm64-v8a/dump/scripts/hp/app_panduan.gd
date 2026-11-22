extends VBoxContainer





const UI: = preload("res://scripts/hp/hp_ui.gd")
const WARNA: = Color(0.23, 0.48, 0.65)

var hp: Control
var _daftar: VBoxContainer

func _ready() -> void :
	add_theme_constant_override("separation", 0)
	add_child(UI.kepala("Panduan", WARNA))
	var g: Array = UI.gulir(6)
	var tepi: = MarginContainer.new()
	tepi.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for sisi in ["left", "right", "top", "bottom"]:
		tepi.add_theme_constant_override("margin_" + sisi, 8)
	tepi.add_child(g[0])
	add_child(tepi)
	_daftar = g[1]

func tampil() -> void :

	for anak in _daftar.get_children():
		anak.queue_free()
	_daftar.add_child(UI.label("Klik topik untuk membaca penjelasannya.", 14, UI.WARNA_REDUP, true))
	for topik in _isi_panduan():
		if topik[0] == "Sholat Jumat" and not GameState.ikut_ronda_jumatan():
			continue
		_daftar.add_child(_buat_topik(topik[0], topik[1]))

func _buat_topik(judul: String, baris: Array) -> Control:
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 0)
	var tombol: = UI.tombol("▸  " + judul, WARNA, 17, 44)
	tombol.alignment = HORIZONTAL_ALIGNMENT_LEFT
	kolom.add_child(tombol)
	var isi: = UI.panel(Color.WHITE, 8, 10)
	isi.hide()
	var teks: = VBoxContainer.new()
	teks.add_theme_constant_override("separation", 6)
	isi.add_child(teks)
	for b in baris:
		teks.add_child(UI.label("•  " + String(b), 15, UI.WARNA_TEKS, true))
	kolom.add_child(isi)
	tombol.pressed.connect( func():
		isi.visible = not isi.visible
		tombol.text = ("▾  " if isi.visible else "▸  ") + judul)
	return kolom

func _isi_panduan() -> Array:
	var gs: = GameState
	var a: = gs.aturan()
	var sewa: Array = []
	var daftar_sewa: Array = gs.cerita["sewa"]["per_minggu"]
	for i in daftar_sewa.size():
		sewa.append("level %d: %s" % [i + 1, gs.format_rupiah(int(daftar_sewa[i]))])

	var menit_nyata: = (gs.JAM_BOLEH_TUTUP - gs.JAM_BUKA) / gs.kecepatan_waktu / 60.0
	return [
		["Hari & waktu", [
			"Pak Misran bangun pukul 07.00. Warung baru boleh dibuka pukul 09.00, jadi pagi bisa dipakai keliling kampung atau kerja sampingan pagi. Tombol Tutup Warung muncul pukul 16.00, dan pukul 17.00 warung wajib tutup (pesan Pak Haji Rasyid). Sore dan malam bebas keliling kampung. Jam buka berjalan sekitar %.0f menit nyata." % menit_nyata, 
			"Setiap hari Jumat warung libur (kecuali hari pertama). Pakai harinya untuk keliling kampung, mengobrol dengan warga, mencari cerita, atau kerja sampingan.", 
			"Sesudah kios dibeli dari Pak Haji Rasyid (cerita Kios Milik Sendiri), jam buka bebas: boleh buka kapan saja sampai pukul 24.00 (Kamis sampai 22.00 karena ronda), termasuk hari Jumat.", 
			"Janji ketemu: warga yang butuh bantuan di jam buka warung mengirim Wasap sehari sebelum libur (\"besok ada waktu?\"). Di hari libur, temui mereka di tempat dan jam yang disebut. Paling banyak 3 janji per hari libur; janji yang terlewat dijadwalkan lagi di libur berikutnya. Daftar janji hari ini ada di Kalender.", 
			"Setelah tutup, pulang ke rumah (sebelah kiri warung) dan tidur di kasur (mulai pukul 21.00): hari berganti dan permainan disimpan. Paling lambat pukul 02.00 Pak Misran pulang sendiri karena kelelahan.", 
			"Energi Pak Misran (bar Energi) turun seiring waktu sepanjang hari (ramai atau sepinya warung tidak berpengaruh), lebih cepat sesudah 21.00, serta saat berlari di mode jalan-jalan dan kerja sampingan. Di bawah 30% Pak Misran ngantuk: jalan lebih pelan dan waktu melayani lebih singkat. Di bawah 20% tidak kuat menjaga warung. Klik bar Energi untuk ngopi dari stok kopi warung (sachet, kopi susu, atau minuman energi) energi +30%, dan makan mi rebus dari stok warung energi +30%, masing-masing 1 kali sehari. Masih kurang, tonton 1 iklan untuk energi penuh (1 kali sehari). Kalau energi habis sampai 0%, Pak Misran pingsan: dibawa pulang warga, bayar mantri Rp20.000, dan besok bangun kesiangan pukul 10.00.", 
			"Kerja sampingan untuk uang tambahan: setiap hari ada satu kerja pagi (07.00–09.00) dan satu kerja malam (19.00–21.30), bergiliran, dikabarkan di grup Wasap setiap pagi. Pagi: bantu panen Abah Karta (terbuka setelah cerita Abah Karta selesai), bikin rengginang Nenek Sumi (terbuka setelah cerita Nenek Sumi selesai), angkut material Mang Ujang. Malam: antar pesanan Kang Asep, bersih-bersih masjid Kang Fadil, packing pesanan Mba Giska. Hari Jumat ada tambahan: siang (13.00–16.00) siapkan nasi kotak Jumat berkah bersama Haji Doni (upah 1,25x), lalu sore (mulai 16.00 sampai 17.00) bagi sembako bersama Pak RT (lebih lama, upah 1,5x).", 
			"Upah kerja sampingan Rp35.000 di Level 1-3, Rp40.000 di Level 4-6, dan Rp50.000 di Level 7-10. Dua kerja pertama setiap hari gratis; kerja ketiga di hari yang sama (hari Jumat) syaratnya menonton 1 iklan. Setelah selesai, menonton 1 iklan lagi membuat upahnya 2x (Level 1: Rp70.000). Cari warga bertanda Rp hijau. Makan waktu dan energi (-10).", 
			"Jam tidur menentukan jam bangun: tidur sebelum 22.00 bangun 07.00, sebelum 24.00 bangun 08.00, sebelum 01.00 bangun 09.00, lebih larut (atau sesudah ronda) bangun 10.00.", 
			"Mode jalan-jalan: tarik joystick sampai ujung untuk berlari (keyboard: tahan Shift).", 
			"Waktu dan semua orang berhenti selama HP atau jendela lain terbuka, baik di warung maupun saat jalan-jalan.", 
			"Jam ramai: 09.00-10.00 dan 15.30-17.00. Jam sepi: 13.00-15.30.", 
			"Warung baru masih sepi (sekitar 40% di hari pertama), lalu makin ramai setiap hari sampai penuh di hari ke-11.", 
			"Klik tanggal di kiri atas untuk membuka Kalender.", 
		]], 
		["Sholat Jumat", [
			"Setiap Jumat pukul 11.30 Haji Doni datang mengajak Pak Misran Sholat Jumat ke masjid. Ikut = warung tutup sampai 13.00 dan warga menulis ulasan bagus; menolak = warung tetap buka tetapi warga menulis ulasan buruk.", 
			"Malam Jumat (Kamis) mulai 23.30 warga berkumpul di pos ronda. Ikut ronda mulai pukul 24.00 menaikkan reputasi, tetapi besoknya Pak Misran bangun kesiangan pukul 10.00 karena begadang.", 
			"Selama itu warung tutup sebentar dan pelanggan pulang dulu (tidak dihitung batal).", 
		]], 
		["Melayani pelanggan", [
			"Pelanggan datang lalu mengantre. Lingkaran di atas kepala adalah sisa kesabarannya.", 
			"Sabar mengantre %d detik. Setelah sampai di depan Pak Misran: %d detik, ditambah %d detik untuk setiap jenis barang tambahan." % [int(a["sabar_antre"]), int(a["sabar_respon"]), int(a["respon_per_barang"])], 
			"Tahan barang yang disebut pelanggan di rak, lalu seret ke kresek hitam sesuai jumlahnya (dua kali = dua). Begitu isinya pas, pelanggan langsung dilayani. Klik kresek untuk mengosongkannya.", 
			"Cara lain: di Pengaturan > Cara melayani pilih Klik. Klik barang di rak dan barang itu terbang sendiri ke kresek (satu per satu, sekitar setengah detik per barang). Selama tutorial selalu memakai cara seret.", 
			"Begitu isi kresek pas, pembeli langsung membayar dan pergi, lalu pembeli berikutnya maju.", 
			"Pesanan campuran = pesanan berisi 2 jenis barang atau lebih.", 
			"Mulai Level 2, sesekali pelanggan datang membawa catatan belanjaan: 4 sampai 7 macam barang, masing-masing 1 atau 2. Daftarnya ada di nota kuning di meja, dan waktunya lebih lama sesuai banyaknya barang.", 
			"Setiap jenis pelanggan punya kebiasaan belanja sendiri (tidak selalu): tukang bangunan dan petani sering membeli kopi dan minuman, ibu-ibu beras, telur, minyak goreng, dan gas, nenek biskuit, anak-anak ciki dan permen. Siapkan stok sesuai pelanggan di kampungmu.", 
		]], 
		["Stok & belanja", [
			"Belanja stok lewat HP, aplikasi Belanja Online: pilih barang dengan +1 atau +5 (masuk keranjang), lalu tekan Beli. Barang diantar kurir: Reguler sekitar 30 detik (ongkir Rp10.000, gratis di Level 1-2), Cepat sekitar 20 detik (Rp20.000), atau Instan dengan menonton 1 iklan. Ongkir dibayar sekali untuk seharian. Reputasi tinggi dan perlengkapan kurir membuat antaran lebih cepat.", 
			"Sales roti datang menitipkan roti setiap beberapa hari. Kalau roti titipan habis, pembeli tidak memintanya dan sales datang lagi hari itu.", 
			"Warung baru bisa dibuka kalau setiap barang punya minimal %d stok (kecuali gas dan galon titipan pangkalan, yang baru boleh dijual setelah izin agennya keluar). Barang yang sedang diantar kurir belum dihitung. Di Belanja Online ada tombol Lengkapi stok untuk membeli semua kekurangannya sekaligus." % gs.MIN_STOK_BUKA, 
			"Stok yang menipis ditandai merah dan muncul angka di ikon HP.", 
			"Setiap pagi sales grosir mengabarkan promo lewat Wasap: 1-3 barang diskon 10-20%, khusus hari itu.", 
			"Mulai Level 2, Info Harga Pasaran mengabarkan harga pasaran tiap Senin lewat Wasap. Atur sendiri harga jualmu di aplikasi Harga Jual. Keluhan mahal dihitung dari harga pasaran: kalau pasaran naik, harga boleh ikut naik; kalau turun, ikut turunkan.", 
		]], 
		["Harga jual", [
			"Harga jual diatur di aplikasi Harga Jual di HP (tombol − dan +), paling tinggi 130% harga normal. Bisa juga lewat Belanja Online.", 
			"Begitu harga di atas harga yang disarankan, pelanggan mulai mengeluh mahal. Makin mahal, makin banyak yang mengeluh: sebagian tetap beli, sebagian batal, dan keduanya memberi bintang rendah.", 
			"Yang mengeluh: kebanyakan tidak jadi beli, sebagian kecil tetap beli. Keduanya bisa menulis ulasan buruk.", 
			"Sebaliknya, harga di bawah yang disarankan membuat warung lebih ramai (10% lebih murah = sekitar 15% lebih banyak pembeli, paling banyak 30%) dan pembeli lebih sabar menunggu, tapi untung per barang lebih kecil.", 
			"Harga di bawah normal bisa membuat pelanggan menulis ulasan bagus, tapi laba berkurang.", 
		]], 
		["Bulan Ramadan", [
			"Ramadan berlangsung 1-30 Maret, lalu Lebaran 31 Maret. Selama Ramadan warung boleh buka sampai 19.00, dan adzan Maghrib berkumandang pukul 18.00. Pasar tetap buka sampai 21.00.", 
			"Pola pembeli berubah: siang (11.00-15.00) sepi karena warga berpuasa, pagi ramai bahan masak (sayur, gula, minyak, telur, beras), sore ramai takjil (teh botol, air mineral, kerupuk, sirup, kurma) dan sering diborong 2-3 sekaligus. Siapkan stok takjil sebelum sore.", 
			"Sirup dan kurma terbuka saat Ramadan. Sesudah Lebaran tetap dijual, tapi peminatnya sedikit.", 
			"Pak Misran berpuasa: tidak bisa ngopi atau makan di siang hari. Sesudah Maghrib (18.00) klik bar energi untuk buka puasa, sekali sehari.", 
			"Malam hari (19.30-21.00) bisa ikut tarawih di masjid: jamaah makin akrab. Menjelang Lebaran ada zakat fitrah dan THR untuk Agus di aplikasi Warga Bank.", 
		]], 
		["Reputasi (bintang)", [
			"Warung baru belum punya ulasan (0 bintang), seperti tempat baru di peta online. Bintang muncul setelah pembeli mulai menulis ulasan.", 
			"Reputasi warung = rata-rata bintang dari 80 ulasan terakhir (aplikasi Ulasan), jadi naik-turunnya pelan. Warung baru masih dianggap biasa saja oleh warga yang belum kenal, jadi bintang tinggi butuh pelayanan baik yang konsisten berhari-hari.", 
			"Bintang di layar: rating 2,0 = 2 bintang, 3,0 = 3 bintang, 4,0 = 4 bintang, 4,6 = 5 bintang. Pembeli yang puas lebih sering memberi bintang 5 kalau fasilitas warung lengkap (kipas, bangku, lampu, radio, QRIS).", 
			"Pelanggan puas menulis ulasan bagus kalau dilayani cepat, barangnya lengkap, atau harganya murah.", 
			"Pelanggan kecewa (menunggu kelamaan, stok habis, salah barang, kemahalan) menulis ulasan buruk.", 
			"Fasilitas yang sudah bisa dibeli (levelnya sudah terbuka) tapi belum ada ikut dikeluhkan, misalnya \"nggak ada kipas angin, jadi agak gerah\" atau \"ngantre sambil berdiri\". Beli upgradenya supaya keluhan hilang dan bintang naik.", 
			"Warga juga menulis ulasan: ikut ronda, Jumatan, infak, dan menolong cerita warga = ulasan bagus; menolak Jumatan atau ada preman = ulasan buruk.", 
			"Selama warung masih kecil (Level 1-2), pembeli sering memberi catatan \"barang masih sedikit\", jadi bintang naik pelan-pelan.", 
			"Bintang hanya memengaruhi keramaian: mulai bintang 3 pembeli lebih sering datang (bintang 5 sekitar 18% lebih ramai). Bintang rendah tidak menghukum, dan bintang bukan syarat naik level. Klik bintang di kiri atas untuk melihat tabelnya.", 
		]], 
		["Keakraban warga", [
			"Setiap warga punya tingkat keakraban: Baru kenal, Kenal, Tetangga akrab, Langganan setia, Sudah seperti keluarga (lihat bar di aplikasi Kontak, lengkap dengan foto warga). Langganan setia kadang memberi tip dan ulasan bintang 5; yang sudah seperti keluarga sesekali datang ke warung membawakan makanan (+energi). Keakraban tiap warga naik paling banyak sekali sehari (panah hijau di atas kepalanya).", 
			"Naik kalau disapa di mode jalan-jalan (sekali sehari per warga), dibantu kerja sampingannya, ditolong ceritanya, dan dilayani dengan baik di warung.", 
			"Turun kalau ceritanya ditolak atau ia pulang kesal karena menunggu kelamaan.", 
			"Makin akrab, makin sering warga itu mampir belanja (sampai 60% lebih sering).", 
		]], 
		["Level Warung", [
			"Setiap Level Warung punya satu daftar tugas: layani pelanggan, jual barang, capai omzet, dan satu tugas khusus. Di level tertentu, kiriman uang untuk Agus juga termasuk tugasnya.", 
			"Semua tugas selesai = naik level: dapat hadiah uang, barang dagangan baru, dan perlengkapan (upgrade) baru.", 
			"Layani beruntun = melayani pelanggan berturut-turut tanpa ada satu pun yang batal (pulang kesal, stok habis, atau menolak harga).", 
			"Laba sehari = laba penjualan dalam satu hari (dihitung ulang setiap hari).", 
			"Mulai Level 4, naik level juga butuh reputasi minimal tertentu.", 
			"Detail tugas ada di aplikasi Misi, atau klik panel Level Warung di layar warung.", 
			"Cerita warga juga terbuka bertahap per Level Warung. Di mode jalan-jalan, klik panel MISI untuk melihat semua cerita: yang bergembok bertuliskan \"Terbuka di Level N\". Banyak cerita membuka barang dagangan baru (misalnya izin agen galon, pangkalan gas, soda dari Pak Rudi, es krim).", 
			"Tombol \"Tanpa Iklan\" di atas layar jalan-jalan: sekali beli, semua iklan hilang dan hadiah iklan langsung didapat.", 
		]], 
		["Kiriman untuk Agus", [
			"Misi utama: Agus butuh uang untuk kuliah, jadi dahulukan ini. Kirim uangnya lewat HP, aplikasi Warga Bank (m-banking), lalu Kirim uang.", 
			"Agus menghubungi beberapa hari setelah warung naik level (tidak di setiap level). Kiriman harus lunas sebelum warung bisa naik level.", 
			"Setiap kiriman punya batas tanggal. Kalau terlambat, batas diperpanjang %d hari dan target naik %d%% (paling banyak 2 kali)." % [int(gs.cerita["tambahan_hari"]), int(gs.cerita["denda_persen"])], 
		]], 
		["Utang pembeli & menyeberang jalan", [
			"Kadang pembeli minta ngutang saat membayar. Waktu berhenti sampai kamu memilih: kasih utang atau tolak. Utang yang dikasih tercatat di Buku Hutang (tombol BUKU HUTANG di kanan bawah, juga di meja kamar) dan dicoret begitu dibayar. Apa akibat pilihanmu? Cari tahu sendiri.", 
			"Di Buku Hutang ada tombol Tagih: tagih halus atau tegas, lalu orangnya datang ke warung. Ia bisa melunasi, mencicil, atau kamu ikhlaskan. Tagihan tegas lebih sering berhasil, tapi keakraban turun dan warga bisa tersinggung.", 
			"Di zebra cross Pak Misran langsung menyeberang begitu melangkah ke jalan (warung <-> sawah). Lihat dulu kiri-kanan: kalau ada mobil atau motor mendekat saat menyeberang, Pak Misran keserempet dan jatuh sampai kakinya terkilir, dan 2 hari terlewat untuk istirahat. Biaya dokter %s: pertama kali warga patungan membantu, sesudah itu dibayar sendiri (kalau uang kurang, sisanya jadi utang). Sesudah pernah keserempet, Pak Misran lebih waspada: tanda segitiga muncul di atas kepalanya saat kendaraan mendekat. Tunggu sampai tanda padam, baru menyeberang." % gs.format_rupiah(gs.BIAYA_TERTABRAK), 
		]], 
		["Sewa kios & biaya", [
			"Kios warung disewa dari %s. Sewa ditagih setiap Minggu pukul 18.00. Sewa boleh dicicil kapan saja sebelumnya lewat aplikasi Warga Bank, jadi hari Minggu tinggal bayar sisanya." % gs.nama_pemilik_kios(), 
			"Sewa per minggu mengikuti Level Warung: %s." % ", ".join(sewa), 
			"Sewa kios tetap setiap minggu. Sewa hanya naik saat warung mencapai Level 3, 5, 7, dan 9, dan Pak Haji Rasyid mengabari alasannya lewat Wasap. Sewa minggu ini: %s." % gs.format_rupiah(gs.sewa_per_minggu()), 
			"Besar sewa ditetapkan di awal minggu sewa dan tidak berubah sampai ditagih. Cicilan sewa melunasi tunggakan lebih dulu, sisanya untuk sewa minggu ini.", 
			"Belum ada uang? Pilih \"Bayar nanti\": sewa dicatat jadi tunggakan TANPA denda dan ditagih lagi Minggu depan. Tunggakan bisa dilunasi lebih awal di aplikasi Warga Bank.", 
			"Tagihan ketiga berturut-turut tidak bisa ditunda lagi: lunasi, atau pemilik mengambil kembali kiosnya (warung bangkrut).", 
			"Setiap warung ditutup juga dipotong biaya harian %s (listrik, iuran). Jangan kirim semua uang ke Agus: sisakan untuk biaya harian." % gs.format_rupiah(int(gs.BIAYA_HARIAN.get(gs.mode, 10000))), 
			"Kalau uang minus %d hari berturut-turut, warung bangkrut." % int(gs.BATAS_HARI_MINUS.get(gs.mode, 3)), 
			"Infak ke masjid (aplikasi Warga Bank, sekali sehari) menaikkan reputasi warung sedikit.", 
			"Harga perlengkapan bisa dipotong 10% dengan menonton iklan (paling banyak 6 kali per perlengkapan) di Upgrade Warung.", 
		]], 
		["Upgrade warung", [
			"Perlengkapan (etalase, kipas, lampu, dan lainnya) dibeli lewat tombol UPGRADE di kanan bawah layar warung (atau HP → Upgrade Warung) dan terbuka sesuai level.", 
			"Setiap perlengkapan punya efek, misalnya pelanggan lebih sabar atau lebih ramai, dan terlihat di warung.", 
		]], 
		["Kejadian tak terduga", [
			"Mulai hari ke-%d, kadang ada kejadian saat warung buka. Grup Warga RT 05 sering mengabari lebih dulu di pagi hari." % int(gs.data_kejadian.get("mulai_hari", 3)), 
			"Listrik padam: kulkas mati, minuman jarang dibeli. Genset membuat warung tetap terang dan kulkas tetap dingin.", 
			"Hujan deras: warung lebih sepi, tapi mie rebus dan kopi lebih dicari. Hujan turun 1 sampai 3 hari setiap minggu, kadang seharian. Cek ramalan cuaca di TV kamar.", 
			"TV di kamar Pak Misran menayangkan prakiraan cuaca hari ini dan besok (selalu tepat). Lihat sebelum tidur supaya bisa menyiapkan stok.", 
			"Rombongan kerja bakti: 4-5 jam warung lebih ramai oleh bapak-bapak. Pastikan stok air mineral, teh botol, dan kopi sachet cukup.", 
			"Pesanan borongan: warga memborong barang untuk acara. Terima = barang langsung terjual dan reputasi naik.", 
			"Preman minta uang keamanan: boleh dikasih atau ditolak. Kalau ditolak, ia nongkrong di depan warung 3-4 jam: pembeli kabur, trotoar sepi, dan warga menulis ulasan buruk.", 
			"Maling: sesekali ada barang hilang semalam, ketahuan saat warung dibuka. CCTV membuat preman dan maling jauh lebih jarang, dan maling yang datang pasti tertangkap.", 
		]], 
		["Pasar & hasil alam", [
			"Pasar ada di luar kampung. Naik angkot dari ujung jalan dekat pos ronda (Rumah Warga), ongkos Rp2.000 sekali jalan, sekitar 30 menit. Angkot ke pasar jalan pukul 05.00-21.00.", 
			"Pasar buka pukul 06.00-21.00 (juga saat Ramadan), libur Selasa dan Kamis. Saat pasar tutup, para penjual pulang.", 
			"Bu Ida membeli ikan hasil memancing dan buah dari kebun (kelapa, jambu, mangga, alpukat) yang ada di Tas HP.", 
			"Haji Maman menjual barang grosir. Harganya diacak tiap hari: ada yang lebih murah dari Belanja Online, ada yang lebih mahal, bandingkan sendiri. Barang masuk Tas dan langsung jadi stok begitu Pak Misran masuk warung.", 
			"Nini Onah menjual jajanan pasar yang menambah energi, tiap jajanan sekali sehari.", 
			"Memancing di kali dan memetik buah di kebun ada di peta jalan-jalan (penanda bergerak). Setiap lemparan pancing memakai sedikit energi; memetik buah tidak.", 
		]], 
		["Promosi & iklan berhadiah", [
			"Tombol PROMOSI di kanan bawah warung: tonton 1 iklan, warung lebih ramai selama 2 hari. Begitu habis, bisa dimulai lagi.", 
			"Iklan berhadiah lain: energi penuh (1 kali sehari), upah kerja sampingan 2x, kerja ketiga dalam sehari, kurir Instan, dan potongan harga perlengkapan lewat iklan (total paling banyak 60%).", 
			"Pembeli Tanpa Iklan dan pendukung tertentu langsung mendapat hadiahnya tanpa menonton.", 
		]], 
		["Peringkat, nama warung & pindah HP", [
			"Aplikasi Peringkat Warung di HP membandingkan jumlah pembeli yang dilayani dengan warung pemain lain (sepanjang masa dan bulan ini). Bagikan capaianmu untuk hadiah uang sekali.", 
			"Nama warung bisa diganti di Pengaturan atau di aplikasi Peringkat: pertama kali gratis, berikutnya dengan menonton 1 iklan.", 
			"Pindah HP (Pengaturan): buat kode di HP lama, ketik di HP baru dalam 7 hari. Data di HP lama TIDAK dihapus; simpanan di HP baru diganti salinannya, dan pembelian (Tanpa Iklan, pendukung) ikut terbawa. Sesudah itu kedua HP berjalan sendiri-sendiri.", 
		]], 
		["Menggeser pandangan", [
			"Tahan lalu geser di area warung untuk melihat sekitar: geser ke kiri untuk melihat masjid, ke kanan untuk rumah warga, juga ke atas dan ke bawah.", 
		]], 
	]
