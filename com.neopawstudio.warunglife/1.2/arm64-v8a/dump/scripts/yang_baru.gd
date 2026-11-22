extends ColorRect














signal ditutup

const GH: = preload("res://scripts/gaya_hud.gd")
const TENANG: = preload("res://scripts/tema_tenang.gd")


const LATAR: = Color(0.07, 0.05, 0.03, 0.96)
const KARTU: = Color(1, 1, 1, 0.07)
const KREM: = Color(1, 0.97, 0.9)
const KREM_REDUP: = Color(1, 0.93, 0.8, 0.8)

const CATATAN: = {

	"1.2": [
		["baru", "Kalender Hadiah: absen sekali sehari dapat Rp15.000, setiap 4 hari hadiah besar sampai Rp400.000, dan baju Kaos & sarung di hari ke-30. Lihat kapan saja lewat aplikasi Hadiah di HP."], 
		["lebih_baik", "Ikon aplikasi di HP tampil baru: lebih cerah, mengilap, dan berbayang."], 
		["baru", "Kode Warung: warungmu otomatis dicadangkan ke server tanpa perlu login. Kodenya ada di menu jeda (ketuk untuk menyalin). Ganti HP atau game terhapus? Tekan MULAI > Pulihkan warung lama, lalu ketik kodenya."], 
		["lebih_baik", "Warung tersimpan otomatis selama bermain, jadi jualan tidak hilang kalau game tiba-tiba tertutup atau HP mati. Simpanan cloud juga tidak lagi tertinggal diam-diam."], 
		["lebih_baik", "Warungmu ikut cadangan akun Google di HP. Kalau game dihapus lalu dipasang lagi di HP yang sama, game langsung menawarkan \"Warungmu ditemukan!\".", "android"], 
		["lebih_baik", "Main di dua HP lebih aman: game menanyakan dulu simpanan mana yang mau dipakai. Kode Pindah HP juga tidak hangus kalau gagal dipakai."], 
		["baru", "ADU LARIS: duel jualan 1 menit melawan warung lain di depan warung, sesudah warung tutup. Ada papan Adu Laris mingguan, dan mode Latihan yang bisa dimainkan kapan saja."], 
		["baru", "Foto profil: pilih foto tokoh untuk warungmu. Fotomu tampil di papan peringkat dan Adu Laris."], 
		["baru", "Papan Juara minggu ini untuk tiap kerja sampingan, tampil saat diajak kerja. Mini-game tidak lagi berhenti di 2x target, jadi skormu bisa setinggi-tingginya."], 
		["lebih_baik", "Ngojol lebih jelas: tarif di kartu order adalah uang yang kamu terima, dan order hari itu bisa diambil sampai habis. Hari Jumat order dua kali lebih banyak. Aplikasi OjekKampung kini berwarna biru."], 
		["lebih_baik", "Semua tombol yang mengeluarkan uang sekarang bertanya dulu (Batal / Ya, bayar), jadi uang tidak hilang karena tombol kepencet."], 
		["baru", "Lemari baju di kamar: dekati lemari, lalu ketuk Lemari baju. Tester yang ikut uji coba sudah bisa memakai Kaos & sarung untuk Pak Misran; baju lain menyusul."], 
		["baru", "Pak Misran nyangkut saat jalan-jalan? Buka menu jeda > Pengaturan > \"Pak Misran nyangkut? Pindahkan\"."], 
		["perbaikan", "Barang yang dipesan sesudah warung tutup, atau dari HP saat jalan-jalan, sekarang tetap diantar kurir."], 
		["perbaikan", "Tanpa Iklan lebih andal: bayar QRIS atau transfer saat game tertutup tetap aktif sendiri. Tautkan akun Google tidak macet lagi.", "android"], 
		["perbaikan", "Game tidak lagi keluar sendiri di beberapa HP (seperti Infinix Note 40 Pro 5G, Redmi Note 14 5G, POCO M7 Pro 5G) dan saat berpindah tempat.", "android"], 
		["perbaikan", "Game tidak lagi keluar sendiri saat berpindah tempat.", "ios"], 
		["perbaikan", "Panel Misi tidak lagi menutupi Belanja Online, warga tidak membeli dagangannya sendiri, tanda \"!\" tidak muncul di tempat kosong, dan perbaikan kecil lainnya."], 
	], 

	"1.1": [
		["lebih_baik", "Sewa kios sekarang tetap dan lebih ringan: Rp100.000 sampai Rp500.000. Sewa hanya naik di Level 3, 5, 7, dan 9, dan Pak Haji Rasyid memberi tahu alasannya. Kerja sampingan tidak lagi membuat sewa naik."], 
		["baru", "Misi di panel kiri bisa diketuk untuk melihat lokasi warga di gambar tempatnya, hari, jam, dan apakah orangnya bisa ditemui sekarang."], 
		["perbaikan", "Cerita Takjil Masjid dan Agus Pulang tetap bisa diselesaikan walau tanggalnya sudah lewat. Kalau uang belum cukup, selalu ada pilihan Nanti dulu."], 
		["lebih_baik", "Harga perlengkapan warung naik 25% (etalase kaca tetap), dan harga beli kios dari Pak Haji Rasyid menjadi Rp30 juta."], 
		["lebih_baik", "Tampilan Belanja Online lebih lega, barang yang terlihat sekaligus jadi lebih banyak."], 
		["lebih_baik", "Stok tiap barang sekarang paling banyak 100. Stok lama yang lebih dari 100 tetap aman dan bisa dijual."], 
		["perbaikan", "Panel Stok dengan daftar barang panjang tidak lagi terpotong di layar HP."], 
		["baru", "Banjir sesekali datang saat hujan seharian: tidak ada pembeli dan kendaraan, Pak Misran tidak bisa keluar warung, dan ada tombol Lewati sampai air surut pukul 17.00."], 
		["baru", "Bonus mini-game: capai skor 2x lipat dari target, permainan langsung selesai dan dapat uang tambahan."], 
		["perbaikan", "Motor cicilan tidak lagi langsung disita kalau matel belum sempat menagih karena hujan atau Pak Misran sakit."], 
		["perbaikan", "Ikan dan buah yang sudah didapat tetap masuk Tas walau game tertutup di tengah mini-game."], 
		["lebih_baik", "Tampilan jendela pop up, naik level, hasil misi, dan menu utama kini bergaya emas."], 
		["lebih_baik", "Warga tidak lagi ngutang receh: utang paling sedikit Rp10.000, dan baru bisa dicicil kalau Rp20.000 ke atas."], 
		["lebih_baik", "Ikan mahal kini jauh lebih langka. Harga jual yang terlalu mahal lebih sering ditolak pembeli."], 
		["baru", "Mini-game sekarang bisa dijeda dengan tombol Jeda."], 
		["baru", "Pengaturan suara kini terpisah: Musik, Efek Suara, dan Suara Sekitar."], 
		["lebih_baik", "Ada peringatan kalau simpanan cloud lebih lama dari warung di HP ini, jadi warung tidak tertimpa tanpa sengaja."], 
		["perbaikan", "Game tidak lagi tertutup sendiri saat menautkan akun Google di HP Android lama.", "android"], 
		["lebih_baik", "Mini-game Cek QRIS sekarang muncul sekali sehari, supaya jualan tidak sering terpotong."], 
		["baru", "Isi Tas sekarang bisa dibuang: pilih barangnya, tentukan jumlahnya, lalu ketuk Buang."], 
		["baru", "Belanja Online punya filter Stok di bawah 5 dan Diskon, bisa dipakai bersamaan."], 
		["lebih_baik", "Saldo QRIS sekarang terlihat di layar warung dan layar utama HP."], 
		["perbaikan", "Penumpang ojek sekarang duduk membonceng dengan benar, termasuk Mang Ujang dan Abah Karta."], 
		["perbaikan", "Sesudah kios dibeli, ojek bisa narik lagi mulai pukul 17.00 sampai 23.30."], 
		["lebih_baik", "Hari Jumat order ojek dua kali lebih banyak, dan bisa narik dari pagi sampai malam."], 
		["lebih_baik", "Harga kios Pak Haji Rasyid tidak lagi turun terlalu jauh: keringanannya pelan dan paling banyak 60%."], 
		["lebih_baik", "Potongan harga upgrade dari iklan sekarang paling banyak 60%."], 
		["perbaikan", "Bayar sewa kios sekarang otomatis memakai saldo QRIS kalau uang di laci kurang, jadi kios tidak diambil padahal uangnya cukup."], 
		["perbaikan", "Tip dari pembeli tidak lagi lebih besar dari belanjaannya (misalnya saat beli permen)."], 
		["perbaikan", "Ajakan bagi sembako Pak RT tidak lagi bilang warung libur kalau kios sudah milik sendiri."], 
		["perbaikan", "Perbaikan kecil teks dan tampilan lainnya."], 
	], 

	"1.0": [
		["baru", "Menu lebih jelas: MULAI hanya untuk pemain baru, sesudah itu cukup LANJUTKAN. Main baru di slot lain lewat Load Save (slot Kosong)."], 
		["baru", "Ngojol makin seru: penumpang dan barang terlihat di motor, roda berputar, kendaraan warna-warni di lajur kiri, sisa jarak tertulis, dan lebih menantang."], 
		["lebih_baik", "Warung libur hanya hari Jumat. Sesudah kios dibeli dari Pak Haji Rasyid, jam buka bebas sampai pukul 24.00."], 
		["lebih_baik", "Energi 20% lebih awet. Isi energi: ngopi +30% dan makan mi rebus +30%, masing-masing sekali sehari."], 
		["baru", "Aplikasi Kalkulator di HP, tarik saldo QRIS sebagian, dan Peringkat di HP langsung membuka papan lebar."], 
		["lebih_baik", "Mini-game Cek QRIS lebih mudah dibaca (HP pembeli diperbesar), cukup 4 QRIS. Padi di sawah tidak bisa hijau semua lagi."], 
		["lebih_baik", "Tautkan akun Google (Android) lebih sederhana, lengkap dengan pilihan simpanan terakhir beserta detail warungnya.", "android"], 
		["baru", "Tautkan akun di iPhone: Masuk dengan Apple atau Google (Pengaturan > Akun & simpanan cloud). Simpanan warung aman di cloud, dapat bonus Rp100.000 sekali per akun. Tidak wajib.", "ios"], 
		["baru", "Pernah main di HP lain? Pilih Masuk dengan Google memakai akun yang sama, lalu ambil simpanan warungmu dari cloud.", "ios"], 
		["perbaikan", "Sewa tidak tertagih dua kali, kurir tidak macet, catatan pesanan tidak bergetar, rating tidak dibulatkan ke atas, dan banyak perbaikan lain dari laporan pemain."], 
	], 

	"0.40": [
		["baru", "Tautkan akun Google (Pengaturan > Akun & simpanan cloud): simpanan warung aman di cloud dan dapat bonus Rp100.000 sekali per akun. Tidak wajib."], 
		["baru", "NGOJOL: sesudah warung tutup, ambil order warga di aplikasi OjekKampung lalu antar penumpang atau barang naik motor (mini-game nyetir). Dapat ongkos + tip."], 
		["baru", "Motor terbuka di Level 3 dan bisa dicicil: bayar uang muka Rp2 juta, motor langsung dibawa pulang, lalu Rp1 juta tiap bulan. Telat bayar, matel datang menarik motornya!"], 
		["baru", "Gelar ★ Warga Baik Hati dan nama emas di papan peringkat untuk semua yang membeli Tanpa Iklan atau Dukung Kami, dan ★ Warga Peduli dengan nama platinum untuk Dukungan besar. Terima kasih!"], 
		["lebih_baik", "Tas lebih lega: setiap kotak muat 10 barang sejenis. Memancing bisa sampai pukul 20.00 dengan suasana senja."], 
		["lebih_baik", "Simpanan jauh lebih aman dengan cadangan otomatis. Load Save > Pulihkan simpanan lama untuk mengembalikan warung dari cadangan di HP."], 
		["lebih_baik", "Pembayaran yang belum lunas diingatkan, roti & jamu titipan diantar lagi, papan diperbarui tiap 30 menit, dan jempol di atas 1.000 ditulis ringkas (1k)."], 
		["perbaikan", "Tertabrak saat uang menipis tidak lagi langsung membuat warung bangkrut. Pak Misran tidak lagi macet di pagar atau depan pintu rumah."], 
		["perbaikan", "Papan peringkat besar selalu bisa ditutup, barang di Bungkus Rapi bisa diseret, misi yang ditunda selalu muncul, dan daftar misi tidak menampilkan cerita yang tidak kamu pilih."], 
		["perbaikan", "Kotak kode Pindah HP, kode promo, dan ganti nama selalu bisa diketik (keyboard muncul). Warga Bank tidak lagi melebar keluar layar."], 
	], 
	"0.39": [
		["baru", "Buku Hutang tampil seperti buku catatan sungguhan, lengkap dengan tulisan tangan berwarna tinta."], 
		["baru", "Grosir Haji Maman: salah pencet bisa dibatalkan dengan tombol \"Batal 1\"."], 
		["lebih_baik", "Simpanan lebih aman: ada cadangan otomatis, dan simpanan yang rusak tidak lagi tampil Kosong."], 
		["lebih_baik", "Roti dan jamu titipan yang habis siang diantar lagi hari itu juga, dan kurir tidak macet lagi."], 
		["lebih_baik", "Ikan dan buah di Tas maksimal 5 per kotak. Jual ke Bu Ida perlu diketuk dua kali supaya tidak terjual tanpa sengaja."], 
		["lebih_baik", "Tanpa Iklan diperiksa ke toko dan ikut Pindah HP. Pembayaran yang belum lunas diingatkan. Papan peringkat diperbarui tiap 30 menit."], 
		["perbaikan", "Token listrik dan barang di bawah kertas pesanan bisa diklik. Jumatan bisa dihentikan dengan joystick dan tidak tertabrak."], 
		["perbaikan", "Titik merah aplikasi HP hilang setelah dibuka. Misi Susu Sekolah dan cerita warga selalu muncul. Daftar yang digeser tidak ikut memencet +5."], 
	], 
	"0.38": [
		["baru", "Papan Peringkat besar: klik lencana PERINGKAT untuk melihat semua warung lengkap dengan omzet, plus peringkat Mingguan dan Bulanan."], 
		["baru", "Jempol: beri semangat untuk warung pemain lain yang kamu kagumi, sampai 10 jempol sehari."], 
		["baru", "Pilih cara melayani di Pengaturan: Seret atau Klik barang di rak."], 
		["baru", "80 obrolan warga baru dan 37 ulasan pelanggan baru."], 
		["lebih_baik", "Waktu di game 20% lebih lambat, dan pembeli langsung bayar begitu belanjaannya lengkap."], 
		["lebih_baik", "Sewa kios dikunci seminggu dan bisa dicicil di Warga Bank. Pasar buka sampai pukul 21.00."], 
		["lebih_baik", "Tampilan baru untuk Pengaturan, Dukung Kami, rak, misi, dan notifikasi."], 
		["perbaikan", "Hari libur: tombol \"Libur · Keluar Warung\" langsung membawa Pak Misran keluar. Tidak lagi terjebak di pos ronda."], 
		["perbaikan", "Roti dan jamu titipan yang habis diantar lagi hari itu juga, jadi pembeli tidak komplain."], 
	], 
}

const JENIS: = {
	"baru": ["BARU", Color(1.0, 0.8, 0.42)], 
	"lebih_baik": ["LEBIH BAIK", Color(0.55, 0.82, 0.4)], 
	"perbaikan": ["PERBAIKAN", Color(0.96, 0.55, 0.3)], 
}


static func versi_sekarang() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))



static func versi_isi() -> String:
	var v: = versi_sekarang()
	if CATATAN.has(v):
		return v
	var terbaik: = ""
	for k: String in CATATAN:
		if terbaik == "" or k.naturalnocasecmp_to(terbaik) > 0:
			terbaik = k
	return terbaik





static func perlu_tampil() -> bool:
	var v: = versi_isi()
	return v != "" and GameState.yang_baru_dilihat != v and GameState.yang_baru_dilihat != versi_sekarang()


static func tandai_dilihat() -> void :
	if GameState.yang_baru_dilihat == versi_sekarang():
		return
	GameState.yang_baru_dilihat = versi_sekarang()
	GameState.simpan_pengaturan()


func _ready() -> void :
	theme = GH.tema_jendela_emas()
	color = Color(0.02, 0.03, 0.06, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 110
	var versi: = versi_isi()
	var layar: = get_viewport_rect().size
	var tengah: = CenterContainer.new()
	tengah.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(tengah)
	var kartu: = PanelContainer.new()
	kartu.add_theme_stylebox_override("panel", GH.bingkai_emas(Vector4(28, 20, 28, 20)))
	tengah.add_child(kartu)
	var kolom: = VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	kartu.add_child(kolom)


	var judul: = _teks(tr("Yang Baru di Versi %s") % versi, 34, GH.KUNING, true)
	judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(judul)
	var sub: = _teks("Terima kasih sudah update! Ini perubahan terbaru di warungmu:", 18, KREM_REDUP)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kolom.add_child(sub)
	var garis: = ColorRect.new()
	garis.color = Color(GH.KUNING, 0.6)
	garis.custom_minimum_size = Vector2(140, 2)
	garis.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	kolom.add_child(garis)


	var gulir: ScrollContainer = load("res://scripts/hp/gulir_sentuh.gd").new()
	gulir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lebar: = clampf(layar.x - 160.0, 560.0, 820.0)
	gulir.custom_minimum_size = Vector2(lebar, clampf(layar.y - 300.0, 220.0, 470.0))
	kolom.add_child(gulir)
	var daftar: = VBoxContainer.new()
	daftar.add_theme_constant_override("separation", 8)
	daftar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gulir.add_child(daftar)
	for poin: Array in CATATAN.get(versi, []):

		if poin.size() > 2 and String(poin[2]) != ("ios" if OS.get_name() == "iOS" else "android"):
			continue
		daftar.add_child(_baris(String(poin[0]), String(poin[1])))

	var oke: = Button.new()
	oke.text = "Oke, ayo main!"
	oke.theme_type_variation = &"TombolHijau"
	oke.focus_mode = Control.FOCUS_NONE
	oke.custom_minimum_size = Vector2(320, 62)
	oke.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	oke.add_theme_font_size_override("font_size", 24)
	oke.pressed.connect( func():
		GameState.klik()
		_tutup())
	kolom.add_child(oke)


	modulate.a = 0.0
	kartu.pivot_offset = kartu.get_combined_minimum_size() / 2.0
	kartu.scale = Vector2(0.94, 0.94)
	var tw: = create_tween().set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(kartu, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(e: InputEvent) -> void :
	if e.is_action_pressed("ui_cancel"):
		_tutup()
		get_viewport().set_input_as_handled()


func _tutup() -> void :
	tandai_dilihat()
	ditutup.emit()
	queue_free()


func _baris(jenis: String, isi: String) -> Control:
	var j: Array = JENIS.get(jenis, JENIS["baru"])
	var warna: Color = j[1]
	var p: = PanelContainer.new()
	p.add_theme_stylebox_override("panel", TENANG.kotak(KARTU, 14, Vector4(12, 10, 16, 10)))
	var h: = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)

	var lencana: = PanelContainer.new()
	lencana.custom_minimum_size = Vector2(128, 0)
	lencana.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lencana.add_theme_stylebox_override("panel", TENANG.kotak(warna, 10, Vector4(8, 3, 8, 4)))
	var lt: = _teks(String(j[0]), 15, Color(0.12, 0.07, 0.02), true)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lencana.add_child(lt)
	h.add_child(lencana)
	var t: = _teks(isi, 19, KREM)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.custom_minimum_size.x = 200
	h.add_child(t)
	return p


func _teks(teks: String, ukuran: int, warna: Color, cetak: = false) -> Label:
	var l: = Label.new()
	l.text = teks
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", GH.cetak() if cetak else GH.font("Nunito", 800))
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", warna)
	l.add_theme_constant_override("outline_size", 0)
	return l
