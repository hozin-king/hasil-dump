extends Node









const SCRIPT_PELANGGAN: = preload("res://scripts/pelanggan.gd")
const SCRIPT_TIMER: = preload("res://scripts/timer_lingkaran.gd")

const JARAK_TIMER: = 16.0
const FILE_PELANGGAN: = "res://data/pelanggan.json"
const FOLDER_SUARA: = "res://assets/suara/"


const KECEPATAN_JALAN: = 200.0
const TINGGI_DEWASA_LATAR_LAMA: = 285.0
const JARAK_ANTRE: = 105.0
const JEDA_PERTAMA: = Vector2(1.5, 3.5)




const MAHAL_MULAI: = 1.0
const MAHAL_PENUH: = 1.3
const PELUANG_KELUH_MAKS: = 0.9
const PELUANG_TETAP_BELI: = 0.25

const JALUR_TROTOAR: = [Vector2(-90, 345), Vector2(300, 470), Vector2(600, 597), Vector2(900, 730), Vector2(1200, 872), Vector2(1640, 1040)]
const JEDA_PEJALAN: = Vector2(5.0, 12.0)
var pejalan: Array[Sprite2D] = []
var detik_pejalan: = 2.0





const LAJUR_PULANG: = 25.0
const LAJUR_KE_KANAN: = 55.0
const LAJUR_KE_KIRI: = 85.0

var _pejalan_ke_kanan: Sprite2D = null
var _pejalan_ke_kiri: Sprite2D = null

var _kantong_tipe: Array = []

var daftar_pelanggan: Array = []
var pakai_3d: = false


var antrean: Array = []
var detik_datang_berikutnya: = -1.0

const LANGKAH_JUALAN_TUTORIAL: = ["layani", "marah", "habis"]
const DETIK_SABAR_MARAH: = 4.0
const PERLAMBAT_SABAR_RAMAI: = 0.25
var _jeda_tutorial: = 1.0
var _tut_pertama_datang: = false
var keranjang: = {}
var tombol_barang: = {}



var tahan_depan: = false


var pelanggan: Sprite2D:
	get:
		var d: = _depan()
		return d["sprite"] if not d.is_empty() else null
var status: String:
	get:
		var d: = _depan()
		if d.is_empty():
			return "kosong"
		match d["status"]:
			"depan": return "menunggu"
			"jalan", "antre": return "datang"
		return d["status"]

@onready var warung: Node2D = get_parent()
@onready var wadah: Node2D = %WadahPelanggan
@onready var titik_jalur: Array[Marker2D] = [ %JalurJalan, %JalurTangga, %JalurAtas]
@onready var titik_mulai: Marker2D = %JalurMulai
@onready var titik_berdiri: Marker2D = %TitikPelanggan
@onready var titik_pulang: Marker2D = %JalurPulang
@onready var gelembung: PanelContainer = %Gelembung
@onready var teks_gelembung: Label = %TeksGelembung
@onready var bar_layani: PanelContainer = %BarLayani
@onready var suara: AudioStreamPlayer = %Suara


func _ready() -> void :
	randomize()
	var data_pelanggan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FILE_PELANGGAN))
	VarianBaju.gabung(data_pelanggan)
	daftar_pelanggan = data_pelanggan["pelanggan"]
	pakai_3d = data_pelanggan.get("pakai_3d", false)
	_bangun_tombol_barang()
	GameState.data_berubah.connect(_perbarui_tombol_barang)
	gelembung.hide()
	_gaya_subtitle()
	_atur_rak(false)


func _skala_latar() -> float:
	return warung.TINGGI_DEWASA_LATAR_LUAS / TINGGI_DEWASA_LATAR_LAMA if warung.LATAR_LUAS else 1.0


func _process(delta: float) -> void :
	_ikuti_pelanggan_dengan_gelembung()
	_perbarui_meja(delta)
	_proses_pejalan(delta)
	_jaga_jarak_lajur(delta)
	for p in antrean:
		_letakkan_timer(p)
	var berhenti: bool = GameState.status_hari != "buka" or warung.dialog_aktif or warung.sedang_sholat or warung.panel_terbuka()
	if berhenti:
		return



	var langkah_tut: = GameState.tutorial_langkah
	if langkah_tut == "asli_layani":


		if not _tut_pertama_datang and antrean.is_empty():
			_jeda_tutorial -= delta
			if _jeda_tutorial <= 0.0:
				_tut_pertama_datang = true
				_datangkan_pelanggan()
	elif GameState.mode_latihan and (langkah_tut in LANGKAH_JUALAN_TUTORIAL or langkah_tut == "tunggu_tutup"):
		if langkah_tut != "tunggu_tutup" and _depan().is_empty():
			_jeda_tutorial -= delta
			if _jeda_tutorial <= 0.0:
				_jeda_tutorial = 1.0
				_datangkan_pelanggan()
		else:
			_jeda_tutorial = 1.0

	else:
		if detik_datang_berikutnya < 0.0:
			detik_datang_berikutnya = randf_range(JEDA_PERTAMA.x, JEDA_PERTAMA.y)
		detik_datang_berikutnya -= delta
		if detik_datang_berikutnya <= 0.0:
			var jeda: Vector2 = GameState.aturan()["jeda_datang"] * pengali_jam(GameState.menit) * float(GameState.efek_reputasi()["datang"]) * GameState.pengali_keramaian() * GameState.pengali_ramai_upgrade(GameState.menit) * GameState.pengali_jeda_kejadian() * GameState.pengali_pengajian() * GameState.pengali_ramai_murah() * GameState.pengali_ramai_cerita() * GameState.pengali_ramai_promosi() * GameState.PENGALI_JEDA_PEMBELI
			detik_datang_berikutnya = randf_range(jeda.x, jeda.y)

			if antrean.size() < GameState.maks_antre() and GameState.menit < GameState.jam_wajib_tutup() and not GameState.sedang_banjir():
				_datangkan_pelanggan()





	var n_antre: = 0
	for p in antrean:
		if p["status"] == "antre":
			n_antre += 1
	var pengali_ramai: = 1.0 / (1.0 + PERLAMBAT_SABAR_RAMAI * maxi(n_antre - 1, 0))
	for p in antrean.duplicate():
		if p["status"] != "antre" and p["status"] != "depan":
			continue
		if GameState.tutorial_langkah in ["layani", "habis", "asli_layani"]:
			continue


		if tahan_depan and p["status"] == "antre":
			continue
		var laju: = pengali_ramai if p["status"] == "antre" else 1.0
		p["waktu"] += delta * (p["batas"] / DETIK_SABAR_MARAH if GameState.tutorial_langkah == "marah" else laju)
		p["timer"].sisa = 1.0 - p["waktu"] / p["batas"]
		if p["waktu"] >= p["batas"]:
			var kalimat: = "Lama banget, Pak... nggak jadi deh." if p["status"] == "depan" else "Antrenya lama banget... nggak jadi deh."
			_pelanggan_pulang(p, kalimat, "kesal", false)



func warung_tutup() -> void :


	for p in antrean:
		p["status"] = "pergi"
		if is_instance_valid(p["sprite"]):
			p["sprite"].queue_free()
		if is_instance_valid(p["timer"]):
			p["timer"].queue_free()
	antrean.clear()
	gelembung.hide()
	_atur_rak(false)
	keranjang.clear()
	_perbarui_tombol_barang()



func bubarkan_semua(kalimat: String) -> void :
	var depan: = _depan()
	if not depan.is_empty():
		depan["sprite"].aksi("bicara")
		await ucapkan(kalimat, "", 1.6, depan["sprite"])
	for p in antrean.duplicate():
		_pelanggan_pulang(p, "", "", true, false)
	gelembung.hide()




func kabur_semua() -> void :


	detik_datang_berikutnya = randf_range(40.0, 70.0)
	for p in antrean.duplicate():
		if p["status"] == "pergi":
			continue
		p["status"] = "pergi"
		p["timer"].queue_free()
		antrean.erase(p)
		_kabur(p["sprite"])
	for s in pejalan:
		if is_instance_valid(s):
			_kabur(s)
	pejalan.clear()
	_pejalan_ke_kanan = null
	_pejalan_ke_kiri = null
	gelembung.hide()
	_atur_rak(false)
	keranjang.clear()
	_perbarui_tombol_barang()


func _kabur(sprite: Sprite2D) -> void :
	if not is_instance_valid(sprite):
		return
	warung.emot(sprite, "!!", Color(0.95, 0.3, 0.25))
	if sprite.karakter != null:
		sprite.karakter.batalkan_aksi()
		sprite.karakter.ganti_anim_jalan("Running")
	sprite.pergi(jalur_keluar_kanan(sprite.position, LAJUR_PULANG), KECEPATAN_JALAN * _skala_latar() * 2.4)




func _depan() -> Dictionary:
	for p in antrean:
		if p["status"] != "pergi" and p["status"] != "datang":
			return p
	return {}




func _datangkan_pelanggan() -> void :
	var data: = pilih_tipe(true, true)

	var terlihat: = _wajah_terlihat()

	var bintang: = false
	if GameState.waktunya_minigame_tip():
		var warga_tip: = daftar_pelanggan.filter( func(d): return String(d["id"]) in GameState.WARGA_TIP and not terlihat.has(VarianBaju.wajah(String(d["id"]))) and ResourceLoader.exists("res://assets/potret/warga_%s.png" % String(d["id"])) and not GameState.di_rumah_saat_hujan(String(d["id"])) and not GameState.tipe_cerita_aktif().has(String(d["id"])))
		if not warga_tip.is_empty():
			data = warga_tip.pick_random()
			bintang = true
			GameState.tip_mg_hari = GameState.hari

	var mg_qris: = false
	if not bintang and GameState.waktunya_minigame_qris():
		var warga_q: = daftar_pelanggan.filter( func(d): return String(d["id"]) in GameState.WARGA_TIP and not terlihat.has(VarianBaju.wajah(String(d["id"]))) and ResourceLoader.exists("res://assets/potret/warga_%s.png" % String(d["id"])) and not GameState.di_rumah_saat_hujan(String(d["id"])) and not GameState.tipe_cerita_aktif().has(String(d["id"])))
		if not warga_q.is_empty():
			data = warga_q.pick_random()
			bintang = true
			mg_qris = true
			GameState.catat_minigame_qris()
	if data.is_empty() or terlihat.has(VarianBaju.wajah(String(data["id"]))):
		return
	catat_belanja(String(data["id"]))
	var sprite: = Sprite2D.new()
	sprite.set_script(SCRIPT_PELANGGAN)
	sprite.modulate = warung.cahaya_karakter
	sprite.set_meta("tipe", data["id"])
	wadah.add_child(sprite)
	sprite.position = titik_mulai.position



	var lewat: Array = []
	if warung.LATAR_LUAS:
		var dari_kiri: = randf() < 0.5

		var lega_kiri: = _lajur_lega(LAJUR_KE_KANAN, 1.0)
		var lega_kanan: = _lajur_lega(LAJUR_KE_KIRI, -1.0)
		if dari_kiri and not lega_kiri and lega_kanan:
			dari_kiri = false
		elif not dari_kiri and not lega_kanan and lega_kiri:
			dari_kiri = true
		_tandai_lajur(sprite, LAJUR_KE_KANAN if dari_kiri else LAJUR_KE_KIRI, 1.0 if dari_kiri else -1.0)
		var lajur: = jalur_lajur(LAJUR_KE_KANAN if dari_kiri else LAJUR_KE_KIRI)
		if not dari_kiri:
			lajur.reverse()
		var tujuan_antre: = _posisi_antre(_urutan_baru())
		var belok: = _titik_terdekat(lajur, tujuan_antre)
		sprite.position = lajur[0]
		for t in lajur.slice(1):
			var sebelum_belok: bool = t.x < belok.x if dari_kiri else t.x > belok.x
			if sebelum_belok:
				lewat.append(t)


		var mundur: = [belok]
		for i in range(lewat.size() - 1, -1, -1):
			mundur.append(lewat[i])
		mundur.append(sprite.position)
		var sisa: float = JARI_BELOK * _skala_latar()
		var awal: Vector2 = mundur[-1]
		var buang: = lewat.size()
		for i in mundur.size() - 1:
			var panjang: float = mundur[i].distance_to(mundur[i + 1])
			if panjang >= sisa:
				awal = mundur[i].lerp(mundur[i + 1], sisa / panjang)
				buang = i
				break
			sisa -= panjang
		lewat.resize(lewat.size() - buang)
		lewat.append_array(_belokan_halus(awal, belok, tujuan_antre))
	sprite.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LAMA * _skala_latar()
	if pakai_3d and data.has("model3d"):
		sprite.atur_3d(data["model3d"], titik_berdiri.position.y)
	else:
		sprite.atur(load("res://assets/karakter/" + data["gambar"]), float(data["tinggi"]) * _skala_latar(), titik_berdiri.position.y)
	var timer: = Node2D.new()
	timer.set_script(SCRIPT_TIMER)
	timer.visible = false

	wadah.get_parent().add_child(timer)
	var p: = {"sprite": sprite, "timer": timer, "pesanan": GameState.pesanan_acak(data.get("tidak_boleh_beli", []), data.get("suka", {})), 
		"status": "datang", "waktu": 0.0, "batas": GameState.sabar_antre_dasar() * GameState.pengali_sabar(true)}
	if bintang:
		p["tip"] = true
		p["pernah_tip"] = true
		p["mg_qris"] = mg_qris


		for i in 5:
			var lain: Array = GameState.pesanan_acak(data.get("tidak_boleh_beli", []), data.get("suka", {}))
			if _total_pesanan(lain) > _total_pesanan(p["pesanan"]):
				p["pesanan"] = lain
		var tanda: = Sprite2D.new()
		tanda.texture = preload("res://assets/ikon/bintang.svg")
		tanda.name = "TandaTip"
		sprite.add_child(tanda)
	antrean.append(p)
	if not lewat.is_empty():
		sprite.jalan(lewat, KECEPATAN_JALAN * _skala_latar() * randf_range(0.85, 1.05))
		await sprite.sampai
		if is_instance_valid(sprite):
			sprite.remove_meta("lajur")
		if p["status"] != "datang" or not is_instance_valid(sprite):
			return

		antrean.erase(p)
		antrean.append(p)

		_jalan_ke_tempat(p, false)
		return
	_jalan_ke_tempat(p, true)






func _urutan_baru() -> int:
	var n: = 0
	for q in antrean:
		if q["status"] != "pergi":
			n += 1
	return n



func _posisi_antre(i: int) -> Vector2:
	var titik: = [titik_berdiri.position, titik_jalur[2].position, titik_jalur[1].position, titik_jalur[0].position, titik_mulai.position]
	var sisa: float = i * JARAK_ANTRE * (1.0 if warung.LATAR_LUAS else TINGGI_DEWASA_LATAR_LAMA / warung.TINGGI_DEWASA_LATAR_LUAS)
	for k in titik.size() - 1:
		var panjang: float = titik[k].distance_to(titik[k + 1])
		if sisa <= panjang:
			return titik[k].lerp(titik[k + 1], sisa / panjang)
		sisa -= panjang
	return titik[-1]


func _urutan(p: Dictionary) -> int:
	var i: = 0
	for q in antrean:
		if q == p:
			return i
		if q["status"] != "pergi" and q["status"] != "datang":
			i += 1
	return i




func _jalan_ke_tempat(p: Dictionary, dari_jalan: bool) -> void :
	var tujuan: = _posisi_antre(_urutan(p))
	var jalur: Array = []
	if dari_jalan:

		var titik: = [titik_jalur[0].position, titik_jalur[1].position, titik_jalur[2].position, titik_berdiri.position]
		for t in titik:
			if t.distance_to(titik_berdiri.position) > tujuan.distance_to(titik_berdiri.position) + 1.0:
				jalur.append(t)
	jalur.append(tujuan)
	p["status"] = "jalan"
	p["timer"].visible = false
	var sprite: Sprite2D = p["sprite"]
	sprite.jalan(jalur, KECEPATAN_JALAN * _skala_latar())
	await sprite.sampai
	if p["status"] != "jalan":
		return
	_hadap_bapak(sprite)
	if _urutan(p) == 0:
		_sampai_di_depan(p)
	else:
		p["status"] = "antre"
		p["timer"].visible = true


func _hadap_bapak(sprite: Sprite2D) -> void :
	sprite.hadap(warung.bapak_3d.position - sprite.position if warung.bapak_3d != null else Vector2(0.35, -1.0))


func _maju_semua() -> void :
	for p in antrean:
		if p["status"] == "antre" or p["status"] == "jalan":
			var tujuan: = _posisi_antre(_urutan(p))
			if p["sprite"].position.distance_to(tujuan) > 2.0:

				_jalan_ke_tempat(p, false)


func _sampai_di_depan(p: Dictionary) -> void :


	if tahan_depan:
		p["status"] = "antre"
		p["timer"].visible = true
		while tahan_depan and p["status"] == "antre" and is_instance_valid(p["sprite"]):
			await get_tree().process_frame
		if p["status"] != "antre" or _urutan(p) != 0 or not is_instance_valid(p["sprite"]):
			return
	p["status"] = "menyapa"
	p["timer"].visible = false

	if p.get("tip", false):
		p["tip"] = false
		var tanda: Node = (p["sprite"] as Node).get_node_or_null("TandaTip")
		if tanda != null:
			tanda.queue_free()
		await warung.tawarkan_minigame_tip(String(p["sprite"].get_meta("tipe", "")), bool(p.get("mg_qris", false)), _total_pesanan(p["pesanan"]))
		if p["status"] != "menyapa" or not is_instance_valid(p["sprite"]):
			return


	var sapa: = GameState.sapaan_pelanggan(String(p["sprite"].get_meta("tipe", "")), p["pesanan"])
	p["sprite"].aksi("bicara")
	ucapkan(sapa + " " + GameState.kalimat_pesanan(p["pesanan"]), "minta_" + p["pesanan"][0][0], 0.0, p["sprite"])


	if _aturan_sebagian() and _target(p).is_empty():
		p["status"] = "dilayani"
		await GameState.get_tree().create_timer(1.4, false).timeout
		if not is_instance_valid(p["sprite"]) or p["status"] != "dilayani":
			return
		GameState.ulas("habis", String(p["sprite"].get_meta("tipe", "")))
		warung.tampilkan_pesan("Barang yang dicari habis semua, pembeli pulang. Belanja stok lewat HP (aplikasi Belanja).", 4.0)
		_pelanggan_pulang(p, "Yah, %s habis ya, Pak? Ya sudah deh." % _nama_habis(p, {}), "habis", false)
		return
	p["status"] = "depan"
	p["waktu"] = 0.0

	p["batas"] = GameState.batas_respon(p["pesanan"].size()) * GameState.pengali_sabar(false)
	GameState.bunyi("bel")
	p["timer"].sisa = 1.0
	p["timer"].visible = true
	keranjang.clear()
	_perbarui_tombol_barang()
	_atur_rak(true)



func _total_pesanan(pesanan: Array) -> int:
	var t: = 0
	for b in pesanan:
		t += GameState.harga_jual(String(b[0])) * int(b[1])
	return t




func _on_layani_ditekan() -> void :
	var p: = _depan()
	if p.is_empty() or p["status"] != "depan":
		return
	if keranjang.is_empty():
		return
	var diminta: = _target(p)
	var sebagian: = diminta != _diminta(p)
	if keranjang != diminta:
		p["sprite"].aksi("bicara")
		GameState.bunyi("salah")
		GameState.ulas("salah", String(p["sprite"].get_meta("tipe", "")))
		ucapkan("Bukan itu, Pak. " + GameState.kalimat_pesanan(p["pesanan"]), "salah")
		keranjang.clear()
		_perbarui_tombol_barang()
		return

	var rasio_tertinggi: = 0.0
	var id_termahal: = ""
	for id in diminta:
		if GameState.rasio_harga(id) > rasio_tertinggi:
			id_termahal = id
		rasio_tertinggi = maxf(rasio_tertinggi, GameState.rasio_harga(id))
	var mengeluh_mahal: = false
	if not GameState.tutorial_langkah in LANGKAH_JUALAN_TUTORIAL and GameState.tutorial_langkah != "asli_layani" and randf() < peluang_mengeluh(rasio_tertinggi):
		if randf() >= PELUANG_TETAP_BELI:
			GameState.ulas("mahal", String(p["sprite"].get_meta("tipe", "")))
			_pelanggan_pulang(p, "Wah, mahal amat, Pak. Nggak jadi deh.", "kesal", false)
			warung.kabari_keluhan_mahal(id_termahal)
			return
		mengeluh_mahal = true
		warung.kabari_keluhan_mahal(id_termahal)

	for id in diminta:
		var b: = GameState.data_barang(id)
		if b["jenis"] == "layanan":
			var diisi: = GameState.isi_otomatis_layanan(id, diminta[id])
			if diisi > 0:
				warung.tampilkan_pesan("Saldo layanan diisi otomatis %s dari laci." % GameState.format_rupiah(diisi))
		var kurang: bool = (b["jenis"] == "fisik" and GameState.stok[id] < diminta[id]) or (b["jenis"] == "layanan" and GameState.saldo_layanan < b["modal"] * diminta[id])
		if kurang:
			warung.tampilkan_pesan("Maaf, %s tidak cukup." % String(b["nama"]).to_lower())
			var kalimat: = "Yah, %s habis ya, Pak? Ya sudah deh." % String(b.get("sebutan", b["nama"])).to_lower()
			GameState.ulas("habis", String(p["sprite"].get_meta("tipe", "")))
			if GameState.tutorial_langkah in ["layani", "habis"]:
				GameState.tutorial_langkah = "tunggu_tutup"
				if GameState.mode_latihan:
					GameState.menit = maxi(GameState.menit, GameState.JAM_BOLEH_TUTUP)
					warung.tampilkan_pesan("Pembeli kecewa karena barangnya habis! Rajin cek stok dan belanja lewat HP. Latihan jualan selesai.", 3.0)
					warung.tut_tutup_mulai = Time.get_ticks_msec()
				else:
					warung.tampilkan_pesan("Stok habis, pembeli pulang. Belanja stok lagi lewat HP (aplikasi Belanja) supaya tidak terulang.", 6.0)
			_pelanggan_pulang(p, kalimat, "habis", false)
			return
	var total: = 0
	for id in diminta:
		total += GameState.harga_jual(id) * int(diminta[id])


	var tipe_utang: = String(p["sprite"].get_meta("tipe", ""))
	var dikasih_utang: = false
	if not p.get("pernah_tip", false) and GameState.tawar_hutang(tipe_utang, total):
		p["status"] = "dilayani"
		p["timer"].visible = false
		var minta: = String(GameState.MINTA_UTANG.pick_random())
		p["sprite"].aksi("bicara")
		ucapkan(minta, "sapa", 2.0, p["sprite"])
		dikasih_utang = await warung.tanya_hutang(tipe_utang, total, minta)
		if not is_instance_valid(p["sprite"]):
			return
		if not dikasih_utang:
			GameState.tolak_hutang(tipe_utang)
			keranjang.clear()
			_perbarui_tombol_barang()
			_atur_rak(false)
			_pelanggan_pulang(p, String(GameState.MARAH_DITOLAK_UTANG.pick_random()), "kesal", false)
			return
	for id in diminta:
		for i in diminta[id]:
			GameState.jual(id)
	p["status"] = "dilayani"
	_kresek_terbang(p)
	p["timer"].visible = false
	_atur_rak(false)
	keranjang.clear()
	_perbarui_tombol_barang()
	GameState.catat_pelanggan_dilayani(diminta.size())

	if GameState.tutorial_langkah == "layani":
		GameState.tutorial_langkah = "marah"
		warung.tampilkan_pesan("Pembeli puas karena barangnya sesuai! Pembeli berikutnya: perhatikan lingkaran kesabaran di atas kepalanya.", 6.0)
	elif GameState.tutorial_langkah == "marah":
		GameState.tutorial_langkah = "habis"
	elif GameState.tutorial_langkah == "asli_layani":

		warung.selesaikan_tutorial_pertama()
	GameState.tambah_akrab(String(p["sprite"].get_meta("tipe", "")), GameState.AKRAB_LAYANI)
	if sebagian:
		GameState.ulas("habis", String(p["sprite"].get_meta("tipe", "")))
	elif mengeluh_mahal:
		GameState.ulas("mahal_beli", String(p["sprite"].get_meta("tipe", "")))
	elif p["waktu"] < p["batas"] * 0.5:
		GameState.ulas("cepat", String(p["sprite"].get_meta("tipe", "")))
	elif p["pesanan"].size() > 1:
		GameState.ulas("banyak", String(p["sprite"].get_meta("tipe", "")))
	elif rasio_tertinggi < 1.0:
		GameState.ulas("murah", String(p["sprite"].get_meta("tipe", "")))
	else:
		GameState.ulas("layani", String(p["sprite"].get_meta("tipe", "")))
	if dikasih_utang:
		GameState.kasih_hutang(tipe_utang, total)
		warung.tampilkan_pesan("Utang %s dicatat di Buku Hutang." % GameState.format_rupiah(total), 3.0)
		await ucapkan("Hatur nuhun pisan, Pak! Insyaallah segera saya bayar.", "terima_kasih", 1.6, p["sprite"])
		_pelanggan_pulang(p, "", "", true)
		return
	warung.atur_pose_kasir("melayani")


	if not is_instance_valid(p["sprite"]):
		return



	var anak_kecil: = VarianBaju.sifat(String(p["sprite"].get_meta("tipe", ""))) == "anak"
	if GameState.pakai_qris() and not anak_kecil:
		GameState.terima_qris(total)
		GameState.bunyi("kurir")
		warung.uang_melayang("QRIS +" + GameState.format_rupiah(total))
		ucapkan("Bayar pakai QRIS ya, Pak. Sudah saya scan.", "qris", 1.0, p["sprite"])
	else:
		GameState.bunyi("koin")
		warung.uang_melayang("+" + GameState.format_rupiah(total))


	var tipe_p: = String(p["sprite"].get_meta("tipe", ""))
	var langganan: = GameState.data_warga_tipe(tipe_p) and GameState.tingkat_akrab(tipe_p) >= GameState.TINGKAT_LANGGANAN
	if langganan and not anak_kecil and int(GameState.ulasan_langganan_hari.get(tipe_p, -1)) != GameState.hari\
	and randf() < GameState.PELUANG_ULASAN_LANGGANAN:
		GameState.ulasan_langganan_hari[tipe_p] = GameState.hari
		GameState.ulasan_warga(5, GameState.ULASAN_LANGGANAN.pick_random(), GameState.daftar_warga()[tipe_p])

	var ucapan_akhir: Array = []
	var peluang_tip: = float(GameState.efek_reputasi()["tip"]) + GameState.efek_upgrade("tip") + (GameState.PELUANG_TIP_LANGGANAN if langganan else 0.0)
	if not anak_kecil and randf() < peluang_tip:
		var tip: = [500, 1000, 2000].pick_random() as int
		GameState.uang += tip
		GameState.data_berubah.emit()
		warung.uang_melayang("Tip +" + GameState.format_rupiah(tip))
		ucapan_akhir = ["Kembaliannya ambil saja, Pak!", "tip"]
	var ucapan_akhir_teks: Array = ucapan_akhir
	if mengeluh_mahal:
		p["sprite"].aksi("marah")
		ucapan_akhir_teks = [["Mahal juga ya, Pak... Ya sudah lah, terpaksa.", "Wah, naik ya harganya? Ya udah, butuh.", "Kok lebih mahal dari warung sebelah, Pak? Hmm, ya sudah."].pick_random(), "kesal"]
	elif sebagian:
		ucapan_akhir_teks = ["Yang %s habis ya, Pak? Ya sudah, ini saja." % _nama_habis(p, diminta), "terima_kasih"]
	elif ucapan_akhir_teks.is_empty():
		ucapan_akhir_teks = [GameState.ucapan_terima_kasih(String(p["sprite"].get_meta("tipe", "")), p["pesanan"]), "terima_kasih"]
	var sprite_pergi: Sprite2D = p["sprite"]
	_pelanggan_pulang(p, "", "", true)
	_ucap_sambil_pergi(String(ucapan_akhir_teks[0]), String(ucapan_akhir_teks[1]), sprite_pergi)


func _pelanggan_pulang(p: Dictionary, kalimat: String, kunci_suara: String, berhasil: bool, maju: = true) -> void :
	if p["status"] == "pergi" or not is_instance_valid(p["timer"]) or not is_instance_valid(p["sprite"]):
		return
	var tadi_di_depan: = _urutan(p) == 0

	if not berhasil and kunci_suara == "kesal" and GameState.tutorial_langkah == "marah":
		GameState.tutorial_langkah = "habis"
		warung.tampilkan_pesan("Pembeli marah karena terlalu lama menunggu! Bintang warung bisa turun. Layani pembeli secepatnya.", 6.0)
	if not berhasil:
		GameState.catat_pelanggan_batal()

		if kalimat.begins_with("Lama") or kalimat.begins_with("Antre"):
			GameState.ulas("kesal", String(p["sprite"].get_meta("tipe", "")))
			GameState.tambah_akrab(String(p["sprite"].get_meta("tipe", "")), GameState.AKRAB_KESAL)
		if kunci_suara == "kesal":
			GameState.bunyi("kesal")
	p["status"] = "pergi"
	p["timer"].visible = false
	var sprite: Sprite2D = p["sprite"]

	if not berhasil and kunci_suara == "kesal":
		warung.emot(sprite, "!!", Color(0.95, 0.3, 0.25))
	elif berhasil and randf() < 0.5:
		warung.emot(sprite, warung.EMOT_SENYUM)
	if tadi_di_depan:
		_atur_rak(false)
		keranjang.clear()
		_perbarui_tombol_barang()
	if kalimat != "":
		var gerak: = "marah" if kunci_suara == "kesal" else "bicara"
		sprite.aksi(gerak)
		if tadi_di_depan:
			await ucapkan(kalimat, kunci_suara, 1.3, sprite)
		else:
			await GameState.get_tree().create_timer(0.6, false).timeout



		var batas_marah: = 1.0
		while batas_marah > 0.0 and is_instance_valid(sprite) and gerak == "marah" and sprite.karakter != null and sprite.karakter._sedang_aksi:
			await GameState.get_tree().create_timer(0.1, false).timeout
			batas_marah -= 0.1
	if tadi_di_depan:
		gelembung.hide()
	antrean.erase(p)
	if is_instance_valid(p["timer"]):
		p["timer"].queue_free()
	if is_instance_valid(sprite):

		sprite.pergi(jalur_keluar_kanan(sprite.position, LAJUR_PULANG), KECEPATAN_JALAN * _skala_latar())
	if maju:
		_maju_semua()




func _ucap_sambil_pergi(teks: String, kunci: String, orang: Sprite2D) -> void :
	await ucapkan(teks, kunci, clampf(0.6 + teks.length() * 0.03, 1.0, 2.0), orang)
	if _pembicara == orang:
		gelembung.hide()







var _pembicara: Sprite2D = null

func ucapkan(teks: String, kunci_suara: String, lama: = 0.0, orang: Sprite2D = null) -> void :
	_pembicara = orang if orang != null else pelanggan


	teks_gelembung.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if teks.length() > 22 else TextServer.AUTOWRAP_OFF
	teks_gelembung.custom_minimum_size.x = 340.0 if teks.length() > 22 else 0.0
	teks_gelembung.text = teks
	_nama_subtitle.text = _nama_pembicara(_pembicara) + ":"
	gelembung.show()
	gelembung.reset_size()

	( func(): gelembung.size = Vector2.ZERO).call_deferred()
	for ekstensi in ["ogg", "wav", "mp3"]:
		var file: String = FOLDER_SUARA + kunci_suara + "." + ekstensi
		if kunci_suara != "" and ResourceLoader.exists(file):
			suara.stream = load(file)
			suara.play()
			break
	if lama > 0.0:
		await GameState.get_tree().create_timer(lama, false).timeout




var _nama_subtitle: Label

func _gaya_subtitle() -> void :
	gelembung.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var baris: = VBoxContainer.new()
	baris.add_theme_constant_override("separation", -4)
	baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gelembung.add_child(baris)
	_nama_subtitle = GH.label("", 22, GH.BIRU_NAMA, false, 6)
	_nama_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baris.add_child(_nama_subtitle)
	teks_gelembung.reparent(baris)
	GH.gaya_label(teks_gelembung, 22, Color.WHITE, false, 6)
	teks_gelembung.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _nama_pembicara(sprite: Sprite2D) -> String:
	if sprite == null or not is_instance_valid(sprite):
		return ""
	if sprite == warung.bapak_3d:
		return "Pak Misran"
	var tipe: = String(sprite.get_meta("tipe", ""))
	return String(GameState.daftar_warga().get(tipe, VarianBaju.nama_catatan(tipe) if VarianBaju.ada(tipe) else "Pembeli"))


func _ikuti_pelanggan_dengan_gelembung() -> void :
	if not gelembung.visible:
		return
	var sprite: = _pembicara
	if sprite == null or not is_instance_valid(sprite):
		gelembung.hide()
		return

	var layar: = gelembung.get_viewport_rect().size
	var y: = layar.y * 0.55
	if kresek != null and is_instance_valid(kresek):
		y = kresek.get_global_rect().position.y - gelembung.size.y + 28.0
	gelembung.position = Vector2((layar.x - gelembung.size.x) / 2.0, y)


func _letakkan_timer(p: Dictionary) -> void :
	if not is_instance_valid(p["sprite"]) or not is_instance_valid(p["timer"]):
		return
	var sprite: Sprite2D = p["sprite"]
	p["timer"].position = sprite.position - Vector2(0, sprite.tinggi_badan() + JARAK_TIMER)

	var tanda: = sprite.get_node_or_null("TandaTip") as Sprite2D
	if tanda != null and sprite.scale.x > 0.0:
		var s: = 1.0 / sprite.scale.x
		tanda.scale = Vector2.ONE * s * 0.8
		tanda.position = Vector2(0, - (sprite.tinggi_badan() + JARAK_TIMER + 46.0 + sin(Time.get_ticks_msec() / 220.0) * 6.0)) * s
	if p["timer"].visible:
		p["timer"].queue_redraw()













const SCRIPT_KRESEK: = preload("res://scripts/kresek.gd")

const UKURAN_KRESEK: = 240.0
const SCRIPT_RAK_KAYU: = preload("res://scripts/rak_kayu.gd")


const FILE_TATA_RAK: = "res://data/tata_rak.json"

var KOLOM_RAK: = 4
var KOLOM_RAK_KANAN: = 4
var UKURAN_SEL: = Vector2(114, 70)
var POP_BARANG: = 1.36
var SKALA_KIRI: = 0.0
var SKALA_KANAN: = 0.0
var KEPEKATAN_PAPAN_NAMA: = 0.82

var PULSA_X: = -1.0
var PULSA_Y: = -1.0
var SKALA_PULSA: = 0.0
var KOLOM_PULSA: = 5


func _ukuran_sel(_kunci: String) -> Vector2:
	return UKURAN_SEL
var kolom_kanan: VBoxContainer = null
const RAK_DAPUR: = ["mi_goreng", "mi_rebus", "minyak_goreng", "beras", "telur", "sayur", "gula", "kopi_bubuk", "lpg", "galon", "sachet", "obat", "sabun", "deterjen", "buku_tulis", "makanan_kucing"]
const RAK_JAJAN: = ["air_mineral", "teh_botol", "kopi_susu", "soda", "minuman_energi", "susu_kotak", "es_krim", "ciki", "permen", "biskuit", "kerupuk", "rengginang", "kurma", "sirup", "roti", "jamu"]
var Y_RAK: = 178.0
var Y_RAK_KANAN: = 178.0
const GH: = preload("res://scripts/gaya_hud.gd")
var TINGKAT_RAK: = 4
const WARNA_RAK: = Color(0.25, 0.15, 0.08, 0.94)
const WARNA_PAPAN: = Color(0.58, 0.37, 0.19)
const WARNA_KREM: = Color(1, 0.95, 0.85)

var lapisan_rak: Control = null
var kresek: Control = null
var _rak: = {}
var _stok_label: = {}
var _harga_label: = {}
var _nota: VBoxContainer
var _nota_baris: GridContainer
var _judul_nota: Label
var _skala_kresek: = 1.0
var _kertas: PanelContainer
var _zona_jatuh: Control = null
var _isi_nota_lalu: = -1


var _nota_kunci: = Vector2(-1, -1)
var _nota_ukuran_kunci: = Vector2.ZERO
const MIRING_NOTA: = -3.0
const ATAS_PAPAN: = 184.0


func _gaya(warna: Color, radius: int, tepi: = Color.TRANSPARENT, lebar_tepi: = 0) -> StyleBoxFlat:
	var g: = StyleBoxFlat.new()
	g.bg_color = warna
	g.set_corner_radius_all(radius)
	if lebar_tepi > 0:
		g.border_color = tepi
		g.set_border_width_all(lebar_tepi)
	g.content_margin_left = 8
	g.content_margin_right = 8
	g.content_margin_top = 6
	g.content_margin_bottom = 8
	return g






var JARAK_TEPI_RAK: = 96.0
var JARAK_TEPI_KANAN: = 96.0

func _buat_rak(kunci: String, judul: String, tingkat: int, kolom: int, kanan: bool, atas: float) -> PanelContainer:
	var panel: PanelContainer = SCRIPT_RAK_KAYU.new()
	var isi: = VBoxContainer.new()

	isi.add_theme_constant_override("separation", int(SCRIPT_RAK_KAYU.TEBAL_PAPAN) + 5)
	panel.add_child(isi)

	var papan_nama: = GH.label(judul, 22, GH.KUNING, true)
	papan_nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	papan_nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	isi.add_child(papan_nama)
	papan_nama.z_index = tingkat * 2 + 2

	var kotak_judul: = Panel.new()
	kotak_judul.show_behind_parent = true
	kotak_judul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gaya_judul: = StyleBoxFlat.new()
	gaya_judul.bg_color = Color(0.1, 0.06, 0.02, 0.85)
	gaya_judul.border_color = Color(GH.KUNING, 0.75)
	gaya_judul.set_border_width_all(2)
	gaya_judul.set_corner_radius_all(12)
	kotak_judul.add_theme_stylebox_override("panel", gaya_judul)
	papan_nama.add_child(kotak_judul)
	var atur_kotak_judul: = func():

		var lebar_teks: float = papan_nama.get_theme_font("font").get_string_size(TranslationServer.translate(papan_nama.text), HORIZONTAL_ALIGNMENT_LEFT, -1, papan_nama.get_theme_font_size("font_size")).x
		var tinggi: float = papan_nama.size.y
		kotak_judul.size = Vector2(lebar_teks + 30.0, tinggi + 2.0)
		kotak_judul.position = Vector2((papan_nama.size.x - kotak_judul.size.x) / 2.0, -2.0)
	papan_nama.resized.connect(atur_kotak_judul)


	var tombol_kunci: = Button.new()
	tombol_kunci.flat = true
	tombol_kunci.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		tombol_kunci.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	tombol_kunci.add_theme_font_override("font", GH.font("Nunito", 800))
	tombol_kunci.add_theme_font_size_override("font_size", 18)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		tombol_kunci.add_theme_color_override(k, Color(1, 1, 1, 0.85))
	tombol_kunci.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	tombol_kunci.add_theme_constant_override("outline_size", 3)
	tombol_kunci.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tombol_kunci.anchor_left = 1.0
	tombol_kunci.anchor_right = 1.0
	tombol_kunci.anchor_bottom = 1.0
	tombol_kunci.offset_left = -160.0
	tombol_kunci.offset_right = 0.0
	tombol_kunci.pressed.connect( func(): _lipat_rak(kunci, not _rak[kunci]["terbuka"]))
	papan_nama.add_child(tombol_kunci)
	var sel: = _ukuran_sel(kunci)

	papan_nama.custom_minimum_size.x = sel.x * kolom + 4 * (kolom - 1)
	var daftar_tingkat: Array[HBoxContainer] = []
	var semua_tingkat: Array = []
	for t in tingkat:
		var baris: = _baris_rak(sel, kolom)
		isi.add_child(baris)


		baris.z_index = tingkat * 2 - t
		daftar_tingkat.append(baris)
		semua_tingkat.append(baris)

	var lipat: = Button.new()
	lipat.flat = true
	lipat.focus_mode = Control.FOCUS_NONE
	for k in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		lipat.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	lipat.add_theme_font_override("font", GH.font("Nunito", 800))
	lipat.add_theme_font_size_override("font_size", 15)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		lipat.add_theme_color_override(k, Color(1, 1, 1, 0.8))
	lipat.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	lipat.add_theme_constant_override("outline_size", 3)
	lipat.custom_minimum_size = Vector2(0, 26)
	lipat.pressed.connect( func(): _lipat_rak(kunci, not _rak[kunci]["terbuka"]))
	isi.add_child(lipat)
	var tingkat_kunci: Array[HBoxContainer] = []
	for t in tingkat:
		var baris: = _baris_rak(sel, kolom)
		isi.add_child(baris)
		baris.z_index = tingkat - t
		baris.hide()
		tingkat_kunci.append(baris)
		semua_tingkat.append(baris)
	panel.tingkat = semua_tingkat

	panel.z_index = -20
	lapisan_rak.add_child(panel)
	panel.offset_top = atas
	if kanan:
		panel.anchor_left = 1.0
		panel.anchor_right = 1.0
		panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		panel.offset_left = - JARAK_TEPI_KANAN
		panel.offset_right = - JARAK_TEPI_KANAN
	else:
		panel.offset_left = JARAK_TEPI_RAK
	_rak[kunci] = {"tingkat": daftar_tingkat, "kolom": kolom, "panel": panel, "kunci": tingkat_kunci, 
		"lipat": lipat, "terbuka": false, "atas": atas, "tombol_kunci": tombol_kunci}
	return panel





const BATAS_BAWAH_DAPUR: = 590.0
const BATAS_BAWAH_KANAN: = 596.0
const BATAS_BAWAH_TERBUKA: = 590.0
const SKALA_RAK_MIN: = 0.68
const SKALA_RAK_MAKS: = 1.15
const KRESEK_KIRI: = 130.0
var JARAK_RAK_KANAN: = 16.0
const RUANG_NOTA: = 300.0
const JARAK_NOTA_RAK: = 8.0
const SKALA_NOTA_MIN: = 0.72
const CELAH_NOTA_2_KOLOM: = 330.0



func _celah_nota() -> float:
	if not _rak.has("dapur") or kolom_kanan == null:
		return 9999.0
	var kiri: float = (_rak["dapur"]["panel"] as Control).get_global_rect().end.x + JARAK_NOTA_RAK
	var kanan: float = kolom_kanan.get_global_rect().position.x - JARAK_NOTA_RAK
	return maxf(kanan - kiri, 1.0)
const JARAK_BARIS_RAK: = SCRIPT_RAK_KAYU.TEBAL_PAPAN + 5.0


func _tinggi_rak(kunci: String) -> float:
	var rak: Dictionary = _rak[kunci]
	var n: = 0
	for b in rak["tingkat"] + (rak["kunci"] if rak["terbuka"] else []):
		if (b as Control).visible:
			n += 1
	var lipat: float = (JARAK_BARIS_RAK + 26.0) if (rak["lipat"] as Control).visible else 0.0

	return 6.0 + 27.0 + n * (UKURAN_SEL.y + JARAK_BARIS_RAK) + lipat + JARAK_BARIS_RAK



func _geser_rak_tablet() -> float:
	return maxf(0.0, (warung.get_viewport().get_visible_rect().size.y - 720.0) * 0.5)


func _atur_skala_rak() -> void :

	if not _rak.has("pulsa") or kolom_kanan == null or not warung.is_inside_tree():
		return
	var dapur: Dictionary = _rak["dapur"]
	var batas: = BATAS_BAWAH_DAPUR
	var panel_dapur: Control = dapur["panel"]


	var geser: = _geser_rak_tablet()
	panel_dapur.offset_top = Y_RAK + geser
	kolom_kanan.offset_top = Y_RAK_KANAN + geser
	var s: = clampf((batas - Y_RAK) / _tinggi_rak("dapur"), SKALA_RAK_MIN, SKALA_RAK_MAKS)
	if panel_dapur.size.x > 0.0:
		var lebar_kiri: float = warung.get_viewport().get_visible_rect().size.x / 2.0 - KRESEK_KIRI - panel_dapur.offset_left
		s = minf(s, lebar_kiri / panel_dapur.size.x)
	var s_kiri: = s
	var pulsa_ikut: = PULSA_Y < 0.0
	var tinggi_kanan: = _tinggi_rak("jajan") + ((JARAK_RAK_KANAN + _tinggi_rak("pulsa")) if pulsa_ikut else 0.0)
	s = clampf((BATAS_BAWAH_KANAN - Y_RAK_KANAN) / tinggi_kanan, SKALA_RAK_MIN, SKALA_RAK_MAKS)

	if kolom_kanan.size.x > 0.0 and panel_dapur.size.x > 0.0:
		var lebar_layar: float = warung.get_viewport().get_visible_rect().size.x
		var s_lebar: float = (lebar_layar - JARAK_TEPI_RAK - JARAK_TEPI_KANAN - RUANG_NOTA) / (panel_dapur.size.x + kolom_kanan.size.x)
		s = minf(s, s_lebar)
		s_kiri = minf(s_kiri, s_lebar)


	var sama: = minf(s_kiri, s)
	var ada_terbuka: = false
	if SKALA_KIRI > 0.0 or SKALA_KANAN > 0.0:

		var batas_lebar: = 99.0
		if kolom_kanan.size.x > 0.0 and panel_dapur.size.x > 0.0:
			var lebar_layar2: float = warung.get_viewport().get_visible_rect().size.x
			var kk: = SKALA_KIRI if SKALA_KIRI > 0.0 else sama
			var kn: = SKALA_KANAN if SKALA_KANAN > 0.0 else sama
			var perlu: = panel_dapur.size.x * kk + kolom_kanan.size.x * kn + JARAK_TEPI_RAK + JARAK_TEPI_KANAN + RUANG_NOTA
			batas_lebar = minf(1.0, lebar_layar2 / perlu)
		panel_dapur.scale = Vector2.ONE * (SKALA_KIRI if SKALA_KIRI > 0.0 else sama) * batas_lebar
		var sk: = (SKALA_KANAN if SKALA_KANAN > 0.0 else sama) * batas_lebar
		kolom_kanan.scale = Vector2(sk, sk)
		kolom_kanan.pivot_offset = Vector2(kolom_kanan.size.x, 0)
		_atur_pulsa(sk, batas_lebar)
		return
	panel_dapur.scale = Vector2.ONE * (s_kiri if ada_terbuka else sama)
	s = s if ada_terbuka else sama
	kolom_kanan.scale = Vector2(s, s)
	kolom_kanan.pivot_offset = Vector2(kolom_kanan.size.x, 0)
	_atur_pulsa(s, 1.0)





const PULSA_KIRI_BAWAH: = true
const NAIK_PULSA: = 30.0

func _atur_pulsa_kiri(p: Control) -> void :
	var ukuran: = p.get_combined_minimum_size()
	var hp: Control = warung.tombol_hp
	var kiri: float = (hp.offset_left + hp.custom_minimum_size.x + warung.JARAK_DOCK) if hp != null else 120.0
	var ruang: float = warung.lebar_sisi_bawah() - (kiri - (hp.offset_left if hp != null else 10.0))
	var sp: = clampf(ruang / maxf(ukuran.x, 1.0), 0.5, 1.2)
	p.anchor_left = 0.0
	p.anchor_right = 0.0
	p.anchor_top = 1.0
	p.anchor_bottom = 1.0
	p.grow_horizontal = Control.GROW_DIRECTION_END
	p.set_deferred("offset_left", kiri)
	p.set_deferred("offset_right", kiri + ukuran.x)


	var tinggi_hp: float = hp.custom_minimum_size.y if hp != null else ukuran.y * sp
	var bawah: = -6.0 - NAIK_PULSA - maxf(0.0, (tinggi_hp - ukuran.y * sp) / 2.0)
	p.set_deferred("offset_top", bawah - ukuran.y)
	p.set_deferred("offset_bottom", bawah)
	p.pivot_offset = Vector2(0, ukuran.y)
	p.scale = Vector2(sp, sp)




func _atur_pulsa(skala_kanan: float, batas_lebar: float) -> void :
	var p: Control = _rak["pulsa"]["panel"]
	if PULSA_KIRI_BAWAH:
		_atur_pulsa_kiri(p)
		return
	var sp: = (SKALA_PULSA * batas_lebar) if SKALA_PULSA > 0.0 else skala_kanan

	var ukuran: = p.get_combined_minimum_size()
	var x: = PULSA_X if PULSA_X >= 0.0 else JARAK_TEPI_KANAN
	var atas: = (PULSA_Y + _geser_rak_tablet()) if PULSA_Y >= 0.0\
	else kolom_kanan.offset_top + (kolom_kanan.size.y + JARAK_RAK_KANAN) * skala_kanan
	p.set_deferred("offset_left", - x - ukuran.x)
	p.set_deferred("offset_right", - x)
	p.set_deferred("offset_top", atas)
	p.set_deferred("offset_bottom", atas + ukuran.y)
	p.scale = Vector2(sp, sp)
	p.pivot_offset = Vector2(ukuran.x, 0)


func _baris_rak(sel: Vector2, kolom: int) -> HBoxContainer:
	var baris: = HBoxContainer.new()
	baris.alignment = BoxContainer.ALIGNMENT_CENTER
	baris.add_theme_constant_override("separation", 4)
	baris.custom_minimum_size = Vector2(sel.x * kolom + 4 * (kolom - 1), sel.y)
	return baris




func _lipat_rak(kunci: String, buka: bool) -> void :
	if buka:
		for k in _rak:
			if k != kunci and _rak[k]["terbuka"]:
				_lipat_rak(k, false)
	_rak[kunci]["terbuka"] = buka
	_perbarui_tombol_barang()



const GESER_NAMA_RAK: = 21.0


func _buat_barang(id: String) -> Button:
	var b: = GameState.data_barang(id)
	var sel: = _ukuran_sel(_rak_untuk(id))
	var tombol: = Button.new()
	tombol.flat = true
	tombol.focus_mode = Control.FOCUS_NONE
	tombol.custom_minimum_size = sel
	tombol.set_meta("tanpa_pantul", true)
	var tex: Texture2D = load("res://assets/barang/%s.png" % id)
	tombol.set_meta("gambar", tex)
	tombol.tooltip_text = b["nama"]



	var gambar: = TextureRect.new()
	gambar.texture = tex
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var besar: = Vector2(sel.x + 6, sel.y) * POP_BARANG

	besar.x = minf(besar.x, sel.x - 2.0)
	gambar.size = besar
	gambar.position = Vector2(-3 - (besar.x - sel.x - 6) / 2.0, -2 - (besar.y - sel.y))
	tombol.add_child(gambar)
	var nama: = Label.new()
	nama.text = _nama_rak(id)
	nama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nama.vertical_alignment = VERTICAL_ALIGNMENT_CENTER



	GH.gaya_label(nama, 12 if nama.text.length() > 12 else 13, Color.WHITE)
	nama.name = "Nama"
	nama.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nama.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nama.position = Vector2(-4, sel.y - 2.0 - GESER_NAMA_RAK)
	nama.size = Vector2(sel.x + 8, SCRIPT_RAK_KAYU.TEBAL_PAPAN + 2.0)


	nama.add_theme_constant_override("outline_size", 4)

	var latar_nama: = StyleBoxFlat.new()
	latar_nama.bg_color = Color(0.08, 0.05, 0.02, 0.72)
	latar_nama.set_corner_radius_all(7)
	nama.add_theme_stylebox_override("normal", latar_nama)

	var teks_tampil: = TranslationServer.translate(nama.text)
	var huruf: int = nama.get_theme_font_size("font_size")
	var lebar_tulisan: float = nama.get_theme_font("font").get_string_size(teks_tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, huruf).x
	while lebar_tulisan + 14.0 > sel.x + 8.0 and huruf > 9:
		huruf -= 1
		lebar_tulisan = nama.get_theme_font("font").get_string_size(teks_tampil, HORIZONTAL_ALIGNMENT_LEFT, -1, huruf).x
	nama.add_theme_font_size_override("font_size", huruf)
	var lebar_nama: = minf(sel.x + 8.0, lebar_tulisan + 14.0)
	nama.position.x = (sel.x - lebar_nama) / 2.0
	nama.size.x = lebar_nama
	tombol.add_child(nama)
	tombol.set_drag_forwarding( func(_pos: Vector2) -> Variant: return _mulai_seret(id, tombol), Callable(), Callable())
	tombol.pressed.connect( func():
		if not GameState.terbuka(id):
			GameState.bunyi("salah")
			warung.tampilkan_pesan("%s masih terkunci. Cara membuka: %s." % [b["nama"], GameState.cara_buka_barang(id)], 4.0)
		elif GameState.layani_dengan_klik():

			var depan: = _depan()
			if depan.is_empty() or depan["status"] != "depan":
				warung.tampilkan_pesan("Belum ada pembeli di depan meja.", 2.0)
				return
			GameState.klik()
			_ketuk_ke_kresek(id, tombol)
		else:
			warung.tampilkan_pesan("Tahan %s, lalu seret ke kresek hitam (atau pilih cara Klik di Pengaturan)." % String(b.get("sebutan", b["nama"])).to_lower()))

	var stok: = GH.label("", 20, Color.WHITE, true, 0)
	stok.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stok.anchor_left = 1.0
	stok.anchor_right = 1.0
	stok.offset_left = -32.0
	stok.offset_right = 0.0
	stok.offset_top = -2.0
	stok.offset_bottom = 30.0
	stok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tombol.add_child(stok)


	var harga: = Label.new()
	harga.add_theme_font_size_override("font_size", 12)
	harga.add_theme_constant_override("outline_size", 3)
	harga.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.02))
	harga.position = Vector2(-4, sel.y - 21.0 - GESER_NAMA_RAK)
	harga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tombol.add_child(harga)
	_harga_label[id] = harga
	if b["jenis"] == "fisik":
		_stok_label[id] = stok
	else:
		stok.hide()
	return tombol



var _tebal: FontVariation = null

func _font_tebal() -> Font:
	if _tebal == null:
		_tebal = FontVariation.new()
		_tebal.base_font = bar_layani.get_theme_font("font", &"Label")
		_tebal.variation_embolden = 0.9
	return _tebal


func _nama_rak(id: String) -> String:
	var b: = GameState.data_barang(id)
	var nama: String = String(b["nama"]).replace("Top-up Saldo ", "").replace("Paket data ", "").replace(" isi ulang", "").replace(" Rp10.000", "")
	if b.has("sebutan") and String(b["sebutan"]).length() < nama.length():
		nama = String(b["sebutan"]).left(1).to_upper() + String(b["sebutan"]).substr(1)
	return nama


func _rak_untuk(id: String) -> String:
	if id in RAK_DAPUR:
		return "dapur"
	if id in RAK_JAJAN:
		return "jajan"
	return "pulsa" if GameState.data_barang(id)["jenis"] == "layanan" else "jajan"



func _muat_tata_rak() -> void :
	var t: Variant = null
	if FileAccess.file_exists(FILE_TATA_RAK):
		t = JSON.parse_string(FileAccess.get_file_as_string(FILE_TATA_RAK))
	if typeof(t) == TYPE_DICTIONARY:
		var d: Dictionary = t
		JARAK_TEPI_RAK = clampf(float(d.get("kiri_x", JARAK_TEPI_RAK)), 0.0, 600.0)
		Y_RAK = clampf(float(d.get("kiri_y", Y_RAK)), 0.0, 600.0)
		JARAK_TEPI_KANAN = clampf(float(d.get("kanan_x", JARAK_TEPI_KANAN)), 0.0, 600.0)
		Y_RAK_KANAN = clampf(float(d.get("kanan_y", Y_RAK_KANAN)), 0.0, 600.0)
		SKALA_KIRI = clampf(float(d.get("skala_kiri", SKALA_KIRI)), 0.0, 2.0)
		SKALA_KANAN = clampf(float(d.get("skala_kanan", SKALA_KANAN)), 0.0, 2.0)
		KOLOM_RAK = clampi(int(d.get("kolom_kiri", KOLOM_RAK)), 2, 8)
		KOLOM_RAK_KANAN = clampi(int(d.get("kolom_kanan", KOLOM_RAK_KANAN)), 2, 8)
		UKURAN_SEL = Vector2(clampf(float(d.get("kotak_lebar", UKURAN_SEL.x)), 50.0, 200.0), clampf(float(d.get("kotak_tinggi", UKURAN_SEL.y)), 40.0, 160.0))
		POP_BARANG = clampf(float(d.get("ukuran_ikon", POP_BARANG)), 0.8, 2.0)
		JARAK_RAK_KANAN = clampf(float(d.get("jarak_pulsa", JARAK_RAK_KANAN)), 0.0, 200.0)
		KEPEKATAN_PAPAN_NAMA = clampf(float(d.get("kepekatan_papan_nama", KEPEKATAN_PAPAN_NAMA)), 0.0, 1.0)
		PULSA_X = clampf(float(d.get("pulsa_x", PULSA_X)), -1.0, 900.0)
		PULSA_Y = clampf(float(d.get("pulsa_y", PULSA_Y)), -1.0, 700.0)
		SKALA_PULSA = clampf(float(d.get("skala_pulsa", SKALA_PULSA)), 0.0, 2.0)
		KOLOM_PULSA = clampi(int(d.get("kolom_pulsa", KOLOM_PULSA)), 0, 8)
		SCRIPT_RAK_KAYU.kepekatan_dinding = clampf(float(d.get("kepekatan_rak", SCRIPT_RAK_KAYU.kepekatan_dinding)), 0.0, 1.0)


	var aman: = GH.tepi_kiri_kanan(warung.get_viewport())
	var tepi_aman: = maxf(aman.x, aman.y) + 8.0
	JARAK_TEPI_RAK = maxf(JARAK_TEPI_RAK, tepi_aman)
	JARAK_TEPI_KANAN = maxf(JARAK_TEPI_KANAN, tepi_aman)
	var n_dapur: = 0
	for id in GameState.urutan_barang:
		if _rak_untuk(id) == "dapur":
			n_dapur += 1
	TINGKAT_RAK = maxi(1, ceili(n_dapur / float(KOLOM_RAK)))


func _bangun_tombol_barang() -> void :
	_muat_tata_rak()
	lapisan_rak = Control.new()
	lapisan_rak.name = "LapisanRak"
	lapisan_rak.set_anchors_preset(Control.PRESET_FULL_RECT)
	lapisan_rak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_layani.get_parent().add_child(lapisan_rak)

	var akar: = bar_layani.get_parent()
	akar.move_child(lapisan_rak, mini(akar.get_node("PanelStok").get_index(), akar.get_node("PanelTugas").get_index()))


	_buat_rak("dapur", "DAPUR & RUMAH TANGGA", TINGKAT_RAK, KOLOM_RAK, false, Y_RAK)


	var n_jajan: = 0
	for id in GameState.urutan_barang:
		if _rak_untuk(id) == "jajan":
			n_jajan += 1
	var jajan: = _buat_rak("jajan", "MINUMAN & CAMILAN", maxi(1, ceili(n_jajan / float(KOLOM_RAK_KANAN))), KOLOM_RAK_KANAN, true, Y_RAK_KANAN)
	var n_pulsa: = 0
	for id in GameState.urutan_barang:
		if _rak_untuk(id) == "pulsa":
			n_pulsa += 1
	var kolom_pulsa: = KOLOM_PULSA if KOLOM_PULSA > 0 else KOLOM_RAK_KANAN
	var pulsa: = _buat_rak("pulsa", "KONTER PULSA", maxi(1, ceili(n_pulsa / float(kolom_pulsa))), kolom_pulsa, true, 0.0)
	kolom_kanan = VBoxContainer.new()
	kolom_kanan.add_theme_constant_override("separation", JARAK_RAK_KANAN)

	kolom_kanan.resized.connect(_atur_skala_rak)
	(_rak["dapur"]["panel"] as Control).resized.connect(_atur_skala_rak)
	kolom_kanan.anchor_left = 1.0
	kolom_kanan.anchor_right = 1.0
	kolom_kanan.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	kolom_kanan.offset_left = - JARAK_TEPI_KANAN
	kolom_kanan.offset_right = - JARAK_TEPI_KANAN
	kolom_kanan.offset_top = Y_RAK_KANAN
	kolom_kanan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lapisan_rak.add_child(kolom_kanan)
	for r in [jajan]:
		lapisan_rak.remove_child(r)
		r.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		kolom_kanan.add_child(r)
	for id in GameState.urutan_barang:
		tombol_barang[id] = _buat_barang(id)
	_bangun_meja_kasir()
	lapisan_rak.hide()
	_perbarui_tombol_barang()



func _bangun_meja_kasir() -> void :
	var meja: = Control.new()
	meja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meja.anchor_left = 0.5
	meja.anchor_right = 0.5
	meja.anchor_top = 1.0
	meja.anchor_bottom = 1.0
	meja.offset_left = -235.0
	meja.offset_right = 235.0
	meja.offset_top = -232.0
	meja.offset_bottom = -8.0
	lapisan_rak.add_child(meja)


	var zona: = Control.new()


	zona.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zona_jatuh = zona
	meja.add_child(zona)
	kresek = SCRIPT_KRESEK.new()
	meja.add_child(kresek)
	kresek.custom_minimum_size = Vector2.ONE * UKURAN_KRESEK

	kresek.position = Vector2((470.0 - UKURAN_KRESEK) / 2.0, 224.0 - UKURAN_KRESEK * 0.9)
	kresek.size = kresek.custom_minimum_size
	kresek.pivot_offset = kresek.size * Vector2(0.5, 0.85)
	zona.position = kresek.position - Vector2(40, 60)
	zona.size = kresek.size + Vector2(80, 70)
	zona.set_drag_forwarding(Callable(), 
		func(posisi: Vector2, data: Variant) -> bool: return kresek._can_drop_data(posisi, data), 
		func(posisi: Vector2, data: Variant) -> void : kresek._drop_data(posisi, data))
	kresek.dijatuhi.connect(_taruh_di_kresek)
	kresek.diketuk.connect( func():
		if keranjang.is_empty():
			warung.tampilkan_pesan("Klik barang di rak, langsung masuk kresek ini." if GameState.layani_dengan_klik() else "Tahan barang di rak, lalu seret ke kresek ini.")
			return
		GameState.klik()
		keranjang.clear()
		warung.tampilkan_pesan("Kresek dikosongkan.")
		_perbarui_tombol_barang())


	var kertas: = PanelContainer.new()
	var gk: = _gaya(Color(1.0, 0.93, 0.52), 3)
	gk.shadow_color = Color(0, 0, 0, 0.35)
	gk.shadow_size = 6
	gk.shadow_offset = Vector2(3, 5)
	gk.content_margin_left = 14
	gk.content_margin_right = 14
	gk.content_margin_top = 20
	gk.content_margin_bottom = 12
	kertas.add_theme_stylebox_override("panel", gk)
	kertas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kertas.position = Vector2(222, 40)
	_kertas = kertas
	kertas.rotation_degrees = MIRING_NOTA
	kertas.custom_minimum_size = Vector2(220, 0)
	kertas.draw.connect( func():

		var w: = kertas.size.x
		var y: = 44.0
		var langkah: = 30.0

		if _nota_baris != null and _nota_baris.columns == 2 and _nota_baris.get_child_count() > 0:
			langkah = (_nota_baris.get_child(0) as Control).size.y + float(_nota_baris.get_theme_constant("v_separation"))
			y = _nota.position.y + _nota_baris.position.y - 2.0
		while y < kertas.size.y - 8.0:
			kertas.draw_line(Vector2(10, y), Vector2(w - 10, y), Color(0.85, 0.72, 0.3, 0.6), 1.0)
			y += langkah
		var paku: = Vector2(w / 2.0, 9)
		kertas.draw_circle(paku + Vector2(2, 3), 8.0, Color(0, 0, 0, 0.3))
		kertas.draw_circle(paku, 8.0, Color(0.85, 0.15, 0.12))
		kertas.draw_circle(paku + Vector2(-2.5, -2.5), 3.0, Color(1, 0.6, 0.55)))
	meja.add_child(kertas)
	_nota = VBoxContainer.new()



	_nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nota.add_theme_constant_override("separation", 4)
	kertas.add_child(_nota)
	_judul_nota = Label.new()
	_judul_nota.add_theme_font_size_override("font_size", 17)
	_judul_nota.add_theme_color_override("font_color", Color(0.4, 0.2, 0.05))
	_judul_nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nota.add_child(_judul_nota)
	_nota_baris = GridContainer.new()
	_nota_baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nota_baris.add_theme_constant_override("v_separation", 2)
	_nota_baris.add_theme_constant_override("h_separation", 8)
	_nota.add_child(_nota_baris)
	_perbarui_nota()


func _atur_rak(_tampil: bool) -> void :

	_perbarui_nota()



func _perbarui_meja(delta: float) -> void :
	if lapisan_rak == null:
		return
	lapisan_rak.visible = GameState.status_hari == "buka" and not warung.sedang_sholat
	if not lapisan_rak.visible:
		return
	var d: = _depan()
	var menunggu: bool = not d.is_empty() and d["status"] == "depan"
	var seret: = get_viewport().gui_is_dragging() and get_viewport().gui_get_drag_data() is Dictionary
	kresek.siap = seret and menunggu
	if _zona_jatuh != null:
		var mf: = Control.MOUSE_FILTER_PASS if seret else Control.MOUSE_FILTER_IGNORE
		if _zona_jatuh.mouse_filter != mf:
			_zona_jatuh.mouse_filter = mf
	var tujuan: = 1.0
	if kresek.siap:
		tujuan = 1.12
	elif menunggu:
		tujuan = 1.0 + 0.025 * sin(Time.get_ticks_msec() / 300.0)
	_skala_kresek = lerpf(_skala_kresek, tujuan, minf(delta * 12.0, 1.0))
	kresek.scale = Vector2(_skala_kresek, _skala_kresek)
	kresek.modulate.a = lerpf(kresek.modulate.a, 1.0 if menunggu else 0.55, minf(delta * 8.0, 1.0))

	var bapak: Sprite2D = warung.bapak_3d
	if bapak != null:
		var kepala: Vector2 = bapak.get_parent().get_global_transform_with_canvas() * (bapak.position - Vector2(0, bapak.tinggi_badan()))



		var batas_kiri: float = (_rak["dapur"]["panel"] as Control).get_global_rect().end.x + JARAK_NOTA_RAK
		var batas_kanan: float = kolom_kanan.get_global_rect().position.x - JARAK_NOTA_RAK
		var celah: float = _celah_nota()
		var s: float = clampf(celah / maxf(_kertas.size.x, 1.0), SKALA_NOTA_MIN, 1.0)
		_kertas.scale = Vector2(s, s)
		var lebar: float = _kertas.size.x * s

		var tengah: float = clampf(kepala.x, batas_kiri + lebar / 2.0, maxf(batas_kiri + lebar / 2.0, batas_kanan - lebar / 2.0))

		var atas: float = 66.0
		if warung._kolom_kiri != null:
			atas = maxf(atas, warung._kolom_kiri.get_global_rect().end.y + 4.0)
		var tujuan_nota: = Vector2(tengah - _kertas.size.x / 2.0, maxf(kepala.y - _kertas.size.y * s - 16.0, atas))

		if _nota_kunci.x < -0.5 or not _kertas.size.is_equal_approx(_nota_ukuran_kunci) or _nota_kunci.distance_to(tujuan_nota) > 160.0:
			_nota_kunci = tujuan_nota
			_nota_ukuran_kunci = _kertas.size
		_kertas.global_position = _nota_kunci

		var kotak_kertas: = Rect2(_kertas.global_position + Vector2(_kertas.size.x * (1.0 - s) / 2.0, 0.0), _kertas.size * s)
		var menimpa: = kotak_kertas.intersects((_rak["dapur"]["panel"] as Control).get_global_rect()) or kotak_kertas.intersects(kolom_kanan.get_global_rect())
		_kertas.modulate.a = lerpf(_kertas.modulate.a, 0.62 if menimpa else 1.0, minf(delta * 10.0, 1.0))
	else:
		_kertas.position.y = ATAS_PAPAN - _kertas.size.y + 8.0
	_kertas.pivot_offset = Vector2(_kertas.size.x / 2.0, 9.0)






const HURUF_NOTA_2_KOLOM: = [18, 17, 16]
const IKON_NOTA_2_KOLOM: = 30.0
const JARAK_KOLOM_NOTA: = 10
var _huruf_nota_2: = 17

func _lebar_nota_2_kolom(pesanan: Array, ukuran: = 16) -> float:
	var huruf: Font = _judul_nota.get_theme_font("font")
	var nama_terlebar: = huruf.get_string_size("✓ 3/3 (stok)", HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran - 1).x
	for b in pesanan:
		nama_terlebar = maxf(nama_terlebar, huruf.get_string_size(_nama_rak(String(b[0])), HORIZONTAL_ALIGNMENT_LEFT, -1, ukuran).x)
	return (IKON_NOTA_2_KOLOM + 5.0 + nama_terlebar + 2.0) * 2.0 + JARAK_KOLOM_NOTA + 28.0 + 4.0



func _perbarui_nota() -> void :
	if _nota_baris == null:
		return
	for c in _nota_baris.get_children():
		c.free()
	var d: = _depan()
	if d.is_empty() or not d["status"] in ["depan", "dilayani"]:
		_judul_nota.text = "Menunggu pembeli..."
		_isi_nota_lalu = -1
		if _kertas != null:
			_kertas.reset_size()
		return
	_judul_nota.text = "PESANAN"
	var jumlah: = 0
	for k in keranjang:
		jumlah += int(keranjang[k])

	if _kertas != null:
		_kertas.rotation_degrees = MIRING_NOTA
	_isi_nota_lalu = jumlah



	_nota_baris.columns = 1
	if d["pesanan"].size() >= 5 and _celah_nota() >= CELAH_NOTA_2_KOLOM:
		for ukuran in HURUF_NOTA_2_KOLOM:
			if _celah_nota() >= _lebar_nota_2_kolom(d["pesanan"], ukuran):
				_huruf_nota_2 = ukuran
				_nota_baris.columns = 2
				break
	_nota_baris.add_theme_constant_override("h_separation", JARAK_KOLOM_NOTA if _nota_baris.columns == 2 else 8)
	_nota_baris.add_theme_constant_override("v_separation", 4 if _nota_baris.columns == 2 else 2)
	for b in d["pesanan"]:
		var id: String = b[0]
		var minta: = int(b[1])
		var ada: = _tersedia(id, minta) if _aturan_sebagian() and d["status"] == "depan" else minta
		var sudah: = minta if d["status"] == "dilayani" else mini(int(keranjang.get(id, 0)), minta)
		if _nota_baris.columns == 2:
			_nota_baris.add_child(_sel_nota_2_kolom(id, minta, ada, sudah))
			continue
		var baris: = HBoxContainer.new()
		baris.mouse_filter = Control.MOUSE_FILTER_IGNORE
		baris.add_theme_constant_override("separation", 6)
		baris.custom_minimum_size.x = 160
		var ikon: = TextureRect.new()
		ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ikon.texture = load("res://assets/barang/%s.png" % id)
		ikon.custom_minimum_size = Vector2(30, 30)
		ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		baris.add_child(ikon)
		var nama: = Label.new()
		nama.text = _nama_rak(id)
		nama.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nama.add_theme_font_size_override("font_size", 15)
		nama.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
		baris.add_child(nama)
		var angka: = Label.new()
		var lengkap: = ada > 0 and sudah >= ada
		angka.text = ("✓ %d/%d" if lengkap else "%d/%d") % [sudah, ada]
		var warna_angka: = Color(0.15, 0.6, 0.25) if lengkap else Color(0.75, 0.35, 0.1)

		if ada <= 0:
			angka.text = "HABIS"
			warna_angka = Color(0.8, 0.15, 0.1)
			nama.add_theme_color_override("font_color", Color(0.55, 0.45, 0.38))
		elif ada < minta:
			angka.text += " (stok)"
		angka.add_theme_font_size_override("font_size", 16)
		angka.add_theme_color_override("font_color", warna_angka)

		angka.custom_minimum_size.x = 92 if ada < minta and ada > 0 else 64
		angka.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		baris.add_child(angka)
		_nota_baris.add_child(baris)

	if _kertas != null:
		_kertas.reset_size()



func _sel_nota_2_kolom(id: String, minta: int, ada: int, sudah: int) -> Control:
	var sel: = HBoxContainer.new()
	sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sel.add_theme_constant_override("separation", 5)
	sel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ikon: = TextureRect.new()
	ikon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ikon.texture = load("res://assets/barang/%s.png" % id)
	ikon.custom_minimum_size = Vector2(IKON_NOTA_2_KOLOM, IKON_NOTA_2_KOLOM)
	ikon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ikon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ikon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sel.add_child(ikon)
	var v: = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", -4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sel.add_child(v)
	var nama: = Label.new()
	nama.text = _nama_rak(id)
	nama.add_theme_font_size_override("font_size", _huruf_nota_2)
	nama.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	v.add_child(nama)
	var angka: = Label.new()
	var lengkap: = ada > 0 and sudah >= ada
	angka.text = ("✓ %d/%d" if lengkap else "%d/%d") % [sudah, ada]
	var warna_angka: = Color(0.15, 0.6, 0.25) if lengkap else Color(0.75, 0.35, 0.1)
	if ada <= 0:
		angka.text = "HABIS"
		warna_angka = Color(0.8, 0.15, 0.1)
		nama.add_theme_color_override("font_color", Color(0.55, 0.45, 0.38))
	elif ada < minta:
		angka.text += " (stok)"
	angka.add_theme_font_size_override("font_size", _huruf_nota_2 - 1)
	angka.add_theme_color_override("font_color", warna_angka)
	v.add_child(angka)
	return sel



var _urutan_rak_cache: Array = []

func _urutan_rak() -> Array:
	if _urutan_rak_cache.is_empty():
		var semua: Array = GameState.urutan_barang.duplicate()
		var nilai: = {}
		for i in semua.size():
			nilai[semua[i]] = GameState.level_buka_barang(semua[i]) * 1000 + i
		semua.sort_custom( func(a, b): return nilai[a] < nilai[b])
		_urutan_rak_cache = semua
	return _urutan_rak_cache


func _perbarui_tombol_barang() -> void :








	var isi: = {"dapur": [], "jajan": [], "pulsa": []}
	var n_kunci: = {"dapur": 0, "jajan": 0, "pulsa": 0}




	var n_tampak: = {"dapur": 0, "jajan": 0, "pulsa": 0}
	for id in _urutan_rak():
		var r: = _rak_untuk(id)
		isi[r].append(id)
		if not GameState.terbuka(id):
			n_kunci[r] += 1
		if GameState.terbuka(id) or bool(_rak[r]["terbuka"]):
			n_tampak[r] = isi[r].size()
	for r in isi:
		for i in (isi[r] as Array).size():
			var id: String = isi[r][i]
			var terkunci: = not GameState.terbuka(id)
			_tampilan_kunci(tombol_barang[id], terkunci)
			if _stok_label.has(id):
				_stok_label[id].visible = not terkunci
			var tampak: bool = i < int(n_tampak[r])
			tombol_barang[id].modulate.a = 1.0 if tampak else 0.0
			tombol_barang[id].mouse_filter = Control.MOUSE_FILTER_STOP if tampak else Control.MOUSE_FILTER_IGNORE
	for r in _rak:
		var rak: Dictionary = _rak[r]
		if n_kunci[r] == 0 and rak["terbuka"]:
			rak["terbuka"] = false
		_isi_tingkat(rak["tingkat"], isi[r], rak["kolom"], int(n_tampak[r]))
		(rak["lipat"] as Button).visible = false
		for baris: Control in rak["kunci"]:
			baris.hide()
		var tk: Button = rak["tombol_kunci"]
		tk.visible = n_kunci[r] > 0
		tk.text = ("%d terkunci ▲" if rak["terbuka"] else "%d terkunci ▼") % n_kunci[r]
		(rak["panel"] as Control).queue_redraw()
		(rak["panel"] as Control).call_deferred("reset_size")
	if kolom_kanan != null:
		kolom_kanan.call_deferred("reset_size")
	_atur_skala_rak()

	for id in _stok_label:
		var n: int = GameState.stok[id]
		var l: Label = _stok_label[id]
		l.text = str(n) if n > 0 else "HABIS"
		l.add_theme_color_override("font_color", Color.WHITE)
		var bulat: = StyleBoxFlat.new()
		bulat.bg_color = Color(0.1, 0.08, 0.06, 0.92) if n > 3 else (Color(0.82, 0.16, 0.14, 0.95) if n > 0 else Color(0.38, 0.38, 0.4, 0.95))
		bulat.border_color = Color.WHITE
		bulat.set_border_width_all(2)
		bulat.set_corner_radius_all(16)
		bulat.content_margin_left = 3
		bulat.content_margin_right = 3
		l.add_theme_stylebox_override("normal", bulat)
		l.add_theme_font_size_override("font_size", 20 if n > 0 else 15)
		l.offset_left = -56.0 if n <= 0 else (-38.0 if n >= 100 else -32.0)

	for id in _harga_label:
		var lh: Label = _harga_label[id]
		lh.visible = GameState.terbuka(id)
		var jual: = GameState.harga_jual(id)
		var pasar: = GameState.harga_pasar(id)
		var normal: = int(GameState.data_barang(id)["jual"])
		var panah: = "" if pasar == normal else ("↑" if pasar > normal else "↓")
		lh.text = GameState.format_rupiah(jual).replace("Rp", "") + panah
		var gl: = StyleBoxFlat.new()
		gl.bg_color = Color(0.85, 0.42, 0.08, 0.95) if jual > pasar else (Color(0.16, 0.55, 0.28, 0.95) if jual < pasar else Color(0.12, 0.08, 0.05, 0.75))
		gl.set_corner_radius_all(6)
		gl.content_margin_left = 4
		gl.content_margin_right = 4
		lh.add_theme_stylebox_override("normal", gl)
		lh.add_theme_color_override("font_color", Color.WHITE)
	if kresek != null:
		kresek.atur_isi(keranjang)
	_perbarui_nota()



func _isi_tingkat(tingkat: Array, ids: Array, kolom: int, n_tampak: = -1) -> void :
	for i in ids.size():
		var tombol: Button = tombol_barang[ids[i]]
		var baris: HBoxContainer = tingkat[mini(i / kolom, tingkat.size() - 1)]
		if tombol.get_parent() != baris:
			if tombol.get_parent() != null:
				tombol.reparent(baris)
			else:
				baris.add_child(tombol)
		baris.move_child(tombol, -1)
	var terpakai: = ceili((ids.size() if n_tampak < 0 else mini(n_tampak, ids.size())) / float(kolom))
	for t in tingkat.size():
		(tingkat[t] as Control).visible = t < terpakai



func _tampilan_kunci(tombol: Button, terkunci: bool) -> void :
	var gambar: = tombol.get_child(0) as TextureRect
	if gambar != null:
		gambar.modulate = Color(0.3, 0.28, 0.27, 0.95) if terkunci else Color.WHITE
	var gembok: = tombol.get_node_or_null("Gembok") as TextureRect
	if terkunci and gembok == null:
		gembok = TextureRect.new()
		gembok.name = "Gembok"
		gembok.texture = load("res://assets/ikon/gembok.svg")
		gembok.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gembok.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gembok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gembok.size = Vector2(30, 30)
		gembok.position = Vector2((tombol.custom_minimum_size.x - 30.0) / 2.0, tombol.custom_minimum_size.y * 0.32 - 15.0)
		tombol.add_child(gembok)
	if gembok != null:
		gembok.visible = terkunci
	var nama: = tombol.get_node_or_null("Nama") as Label
	if nama != null:
		nama.add_theme_color_override("font_color", Color(1, 1, 1, 0.5) if terkunci else Color.WHITE)



func _kresek_terbang(p: Dictionary) -> void :
	if kresek == null or kresek._vp == null:
		return
	var gambar: = TextureRect.new()
	gambar.texture = ImageTexture.create_from_image(kresek._vp.get_texture().get_image())
	gambar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gambar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gambar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gambar.size = kresek.size
	gambar.top_level = true
	gambar.z_index = 50
	gambar.pivot_offset = gambar.size / 2.0
	warung.akar_ui.add_child(gambar)
	gambar.global_position = kresek.global_position
	var sprite: Sprite2D = p["sprite"]
	var tujuan: Vector2 = sprite.get_parent().to_global(sprite.position - Vector2(0, sprite.tinggi_badan() * 0.45)) - gambar.size / 2.0
	var mulai: = gambar.global_position
	var puncak: = (mulai + tujuan) / 2.0 + Vector2(0, -120)
	var tw: = gambar.create_tween().set_parallel(true)
	tw.tween_method( func(t: float):
		gambar.global_position = mulai.lerp(puncak, t).lerp(puncak.lerp(tujuan, t), t), 0.0, 1.0, 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(gambar, "scale", Vector2(0.4, 0.4), 0.5)
	tw.chain().tween_property(gambar, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(gambar.queue_free)




func _mulai_seret(id: String, tombol: Button) -> Variant:

	if GameState.tutorial_langkah == "marah":
		warung.tampilkan_pesan("Tunggu dulu, jangan dilayani. Lihat apa yang terjadi kalau kesabarannya habis.", 3.0)
		return null
	if not GameState.terbuka(id):
		return null
	var b: = GameState.data_barang(id)
	var nama: = String(b.get("sebutan", b["nama"]))
	tombol.set_drag_preview(preload("res://scripts/pratinjau_seret.gd").buat(tombol.get_meta("gambar"), nama.left(1).to_upper() + nama.substr(1), kresek))
	GameState.klik()
	return {"barang": id}


func _diminta(p: Dictionary) -> Dictionary:
	var diminta: = {}
	for b in p["pesanan"]:
		diminta[b[0]] = b[1]
	return diminta





func _aturan_sebagian() -> bool:
	return not GameState.tutorial_langkah in LANGKAH_JUALAN_TUTORIAL



func _tersedia(id: String, minta: int) -> int:
	var b: = GameState.data_barang(id)
	if b["jenis"] == "fisik":
		return clampi(int(GameState.stok[id]), 0, minta)
	if b["jenis"] == "layanan":
		var modal: = maxi(int(b["modal"]), 1)
		var isi: = int(GameState.uang / GameState.JUMLAH_ISI_OTOMATIS) * GameState.JUMLAH_ISI_OTOMATIS
		return clampi(int((GameState.saldo_layanan + isi) / modal), 0, minta)
	return minta



func _target(p: Dictionary) -> Dictionary:
	var diminta: = _diminta(p)
	if not _aturan_sebagian():
		return diminta
	var t: = {}
	for id in diminta:
		var ada: = _tersedia(id, int(diminta[id]))
		if ada > 0:
			t[id] = ada
	return t



func _nama_habis(p: Dictionary, target: Dictionary) -> String:
	var nama: Array = []
	for b in p["pesanan"]:
		if int(target.get(b[0], 0)) < int(b[1]):
			var d: = GameState.data_barang(String(b[0]))
			nama.append(String(d.get("sebutan", d["nama"])).to_lower())
	if nama.size() <= 1:
		return "".join(nama)
	return ", ".join(nama.slice(0, nama.size() - 1)) + " dan " + String(nama[-1])






const LAMA_TERBANG_KLIK: = 0.4
var _antre_klik: Array = []
var _klik_berjalan: = false

func _ketuk_ke_kresek(id: String, tombol: Button) -> void :
	_antre_klik.append([id, tombol])
	if _klik_berjalan:
		return
	_klik_berjalan = true
	while not _antre_klik.is_empty():
		var isi: Array = _antre_klik.pop_front()
		var p: = _depan()
		if p.is_empty() or p["status"] != "depan":
			_antre_klik.clear()
			break
		await _terbangkan_ke_kresek(isi[1])
		if is_instance_valid(self):
			_taruh_di_kresek(isi[0])
	_klik_berjalan = false


func _terbangkan_ke_kresek(tombol: Button) -> void :
	var gambar_asal = tombol.get_meta("gambar") if is_instance_valid(tombol) and tombol.has_meta("gambar") else null
	if not (gambar_asal is Texture2D) or kresek == null:
		await GameState.get_tree().create_timer(LAMA_TERBANG_KLIK, false).timeout
		return
	var g: = TextureRect.new()
	g.texture = gambar_asal
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size = Vector2(64, 64)
	g.pivot_offset = g.size / 2.0
	g.top_level = true
	g.z_index = 50
	warung.akar_ui.add_child(g)
	var awal: = tombol.get_global_rect().get_center() - g.size / 2.0
	var tujuan: = kresek.get_global_rect().get_center() - g.size / 2.0
	var puncak: = (awal + tujuan) / 2.0 + Vector2(0, -90)
	g.global_position = awal
	var tw: = g.create_tween().set_parallel(true)
	tw.tween_method( func(t: float):
		if is_instance_valid(g):
			g.global_position = awal.lerp(puncak, t).lerp(puncak.lerp(tujuan, t), t), 0.0, 1.0, LAMA_TERBANG_KLIK)
	tw.tween_property(g, "scale", Vector2(0.6, 0.6), LAMA_TERBANG_KLIK).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "rotation_degrees", 25.0, LAMA_TERBANG_KLIK)
	await tw.finished
	g.queue_free()


func _taruh_di_kresek(id: String) -> void :
	var p: = _depan()
	if not GameState.terbuka(id):
		return


	if p.is_empty() or p["status"] != "depan":
		warung.tampilkan_pesan("Tunggu pembeli sampai di depan warung dulu, baru serahkan barangnya.", 2.0)
		return
	var diminta: = _diminta(p)

	if _aturan_sebagian() and diminta.has(id) and int(keranjang.get(id, 0)) >= _tersedia(id, int(diminta[id])):
		GameState.bunyi("salah", -6.0)

		if _tersedia(id, int(diminta[id])) >= int(diminta[id]):
			warung.tampilkan_pesan("%s cukup %d saja, sudah di kresek." % [_nama_rak(id), int(diminta[id])], 2.5)
		else:
			warung.tampilkan_pesan("Stok %s habis. Serahkan barang lain yang ada saja." % _nama_rak(id).to_lower(), 2.5)
		return
	keranjang[id] = keranjang.get(id, 0) + 1
	kresek.pantul()
	GameState.bunyi("kresek", -2.0)
	_perbarui_tombol_barang()
	var target: = _target(p)

	if not diminta.has(id) or keranjang[id] > int(diminta[id]):
		_on_layani_ditekan()
		return
	if keranjang == target:

		await GameState.get_tree().create_timer(0.12, false).timeout
		if p["status"] == "depan" and keranjang == _target(p):
			_on_layani_ditekan()



func uji_isi_kresek() -> void :
	var p: = _depan()
	if p.is_empty():
		return
	var target: = _target(p)
	for id in target:
		for i in int(target[id]):
			_taruh_di_kresek(String(id))




func _proses_pejalan(delta: float) -> void :

	if not warung.LATAR_LUAS or warung.dialog_aktif or GameState.preman_di_depan() or GameState.sedang_banjir():
		return
	pejalan = pejalan.filter(is_instance_valid)
	if _pejalan_ke_kanan != null and not is_instance_valid(_pejalan_ke_kanan):
		_pejalan_ke_kanan = null
	if _pejalan_ke_kiri != null and not is_instance_valid(_pejalan_ke_kiri):
		_pejalan_ke_kiri = null
	detik_pejalan -= delta
	if detik_pejalan > 0.0 or (_pejalan_ke_kanan != null and _pejalan_ke_kiri != null):
		return
	detik_pejalan = randf_range(JEDA_PEJALAN.x, JEDA_PEJALAN.y)


	var data: = pilih_tipe(false)
	if data.is_empty():
		return

	var ke_kanan: = _pejalan_ke_kanan == null and (_pejalan_ke_kiri != null or randf() < 0.5)
	var lajur_pakai: = LAJUR_KE_KANAN if ke_kanan else LAJUR_KE_KIRI
	var arah_pakai: = 1.0 if ke_kanan else -1.0

	if not _lajur_lega(lajur_pakai, arah_pakai):
		detik_pejalan = 1.5
		return
	var jalur: = jalur_lajur(lajur_pakai)
	if not ke_kanan:
		jalur.reverse()

	var kecepatan: = KECEPATAN_JALAN * _skala_latar() * randf_range(0.75, 1.1)
	var sprite: = _buat_pejalan(data, jalur, kecepatan, Vector2.ZERO)
	_tandai_lajur(sprite, lajur_pakai, arah_pakai)
	var terakhir: = sprite
	if ke_kanan:
		_pejalan_ke_kanan = sprite
	else:
		_pejalan_ke_kiri = sprite


	if data.has("berpasangan"):
		var pasangan: Dictionary = {}
		for d in daftar_pelanggan:
			if d["id"] == data["berpasangan"]:
				pasangan = d
		var terlihat: = false
		for anak in wadah.get_children():
			if anak.has_meta("tipe") and anak.get_meta("tipe") == data["berpasangan"]:
				terlihat = true
		if not pasangan.is_empty() and not terlihat:
			_kantong_tipe.erase(pasangan)
			await GameState.get_tree().create_timer(randf_range(0.7, 1.1), false).timeout
			terakhir = _buat_pejalan(pasangan, jalur, kecepatan, Vector2(0, -22))

	if ke_kanan:
		_pejalan_ke_kanan = terakhir
	else:
		_pejalan_ke_kiri = terakhir



func _buat_pejalan(data: Dictionary, jalur_asli: Array, kecepatan: float, geser: Vector2) -> Sprite2D:
	var jalur: Array = []
	for t in jalur_asli:
		jalur.append(t + geser)
	var sprite: = Sprite2D.new()
	sprite.set_script(SCRIPT_PELANGGAN)
	sprite.modulate = warung.cahaya_karakter
	sprite.set_meta("tipe", data["id"])
	wadah.add_child(sprite)
	sprite.position = jalur.pop_front()
	sprite.tinggi_dewasa_latar = TINGGI_DEWASA_LATAR_LAMA * _skala_latar()
	if pakai_3d and data.has("model3d"):
		sprite.atur_3d(data["model3d"], titik_berdiri.position.y)

		if sprite.karakter != null and sprite.karakter._animasi != null:
			sprite.karakter._animasi.speed_scale *= randf_range(0.9, 1.1)
			sprite.karakter._animasi.seek(randf_range(0.0, 0.6), true)
	else:
		sprite.atur(load("res://assets/karakter/" + data["gambar"]), float(data["tinggi"]) * _skala_latar(), titik_berdiri.position.y)
	pejalan.append(sprite)
	_hapus_di_ujung(sprite, jalur, kecepatan)
	return sprite


func _hapus_di_ujung(sprite: Sprite2D, jalur: Array, kecepatan: float) -> void :
	sprite.jalan(jalur, kecepatan)
	await sprite.sampai
	if is_instance_valid(sprite):
		sprite.queue_free()








const JARAK_AMAN_LAJUR: = 95.0

func _di_lajur() -> Array:
	var hasil: Array = []
	for s in pejalan:
		if is_instance_valid(s) and s.has_meta("lajur"):
			hasil.append(s)
	for p in antrean:
		var s = p["sprite"]
		if is_instance_valid(s) and s.has_meta("lajur"):
			hasil.append(s)
	return hasil


var jaga_jarak_aktif: = true

func _jaga_jarak_lajur(delta: float) -> void :
	if not jaga_jarak_aktif:
		return
	var orang: = _di_lajur()
	var aman: = JARAK_AMAN_LAJUR * _skala_latar()
	for a in orang:
		var tw: Tween = a.tween_jalan
		if tw == null or not tw.is_valid() or not a.sedang_jalan:
			continue
		var arah: float = a.get_meta("arah")
		var mau: = 1.0
		for b in orang:
			if b == a or b.get_meta("lajur") != a.get_meta("lajur") or b.get_meta("arah") != arah:
				continue
			var jarak: float = (b.position.x - a.position.x) * arah
			var b_di_depan: bool = jarak > 0.5 or (absf(jarak) <= 0.5 and a.lahir_ms > b.lahir_ms)
			if not b_di_depan or jarak > aman * 1.8:
				continue
			if jarak < aman:
				mau = 0.0
			else:
				var laju_b: float = b.laju_jalan * (b.skala_jalan if b.sedang_jalan else 0.0)
				mau = minf(mau, clampf(laju_b / maxf(a.laju_jalan, 1.0), 0.0, 1.0))
		var kini: float = a.skala_jalan
		var baru: float = move_toward(kini, mau, delta * 2.5)
		tw.set_speed_scale(baru)
		a.skala_jalan = baru
		a.tertahan = baru < 0.15



func _lajur_lega(lajur: float, arah: float) -> bool:
	var awal: Array = jalur_lajur(lajur)
	var titik: Vector2 = awal[0] if arah > 0.0 else awal[-1]
	for s in _di_lajur():
		if s.get_meta("lajur") == lajur and s.get_meta("arah") == arah and s.position.distance_to(titik) < JARAK_AMAN_LAJUR * _skala_latar() * 2.0:
			return false
	return true


func _tandai_lajur(s: Node, lajur: float, arah: float) -> void :
	s.set_meta("lajur", lajur)
	s.set_meta("arah", arah)






func jalur_lajur(jarak: float) -> Array:
	var arah: Vector2 = (JALUR_TROTOAR[-1] - JALUR_TROTOAR[0]).normalized()
	var ke_jalan: = Vector2( - arah.y, arah.x)
	var hasil: Array = []
	for t in JALUR_TROTOAR:
		hasil.append(warung._ke_lokal(t + ke_jalan * jarak))
	return hasil



func jalur_keluar_kanan(dari: Vector2, jarak: float) -> Array:
	var lajur: = jalur_lajur(jarak)
	var hasil: Array = [_titik_terdekat(lajur, dari)]
	for t in lajur:
		if t.x > hasil[0].x + 10.0:
			hasil.append(t)
	return hasil





const JARI_BELOK: = 150.0

func _belokan_halus(sebelum: Vector2, belok: Vector2, tujuan: Vector2) -> Array:


	if sebelum.distance_to(belok) < 4.0 or belok.distance_to(tujuan) < 4.0:
		return [belok]
	var a: = sebelum
	var hasil: = [a]
	var n: = 12
	for i in range(1, n):
		var t: = float(i) / n
		hasil.append(a.lerp(belok, t).lerp(belok.lerp(tujuan, t), t))
	return hasil


func _titik_terdekat(garis: Array, titik: Vector2) -> Vector2:
	var terbaik: Vector2 = garis[0]
	for i in garis.size() - 1:
		var t: = Geometry2D.get_closest_point_to_segment(titik, garis[i], garis[i + 1])
		if t.distance_to(titik) < terbaik.distance_to(titik):
			terbaik = t
	return terbaik











const JEDA_BELANJA_ULANG: = 180.0
static var _terakhir_belanja: = {}

func _menit_mutlak() -> float:
	return float(GameState.hari) * 1440.0 + float(GameState.menit)


func pilih_tipe(boleh_dobel: = true, untuk_beli: = false) -> Dictionary:
	var tokoh_cerita: = GameState.tipe_cerita_aktif()
	for longgar in ([false, true] if untuk_beli else [true]):
		for i in 8:
			var d: = _pilih_tipe_acak(boleh_dobel, not longgar)
			if d.is_empty() or not (GameState.di_rumah_saat_hujan(String(d["id"])) or tokoh_cerita.has(String(d["id"]))):
				if not d.is_empty() or longgar:
					return d
				break
	return {}


func catat_belanja(tipe: String) -> void :
	_terakhir_belanja[VarianBaju.wajah(tipe)] = _menit_mutlak()



func _wajah_terlihat() -> Dictionary:
	var ada: = {}
	for anak in wadah.get_children():
		if anak.has_meta("tipe") and not anak.is_queued_for_deletion():
			ada[VarianBaju.wajah(String(anak.get_meta("tipe")))] = true
	return ada


func _pilih_tipe_acak(boleh_dobel: bool, hindari_baru: = false) -> Dictionary:
	var ada: = _wajah_terlihat()
	if hindari_baru:
		var kini: = _menit_mutlak()
		for w in _terakhir_belanja:
			if kini - float(_terakhir_belanja[w]) < JEDA_BELANJA_ULANG:
				ada[w] = true
		boleh_dobel = false


	var ramai: = GameState.tipe_ramai()
	if not ramai.is_empty() and randf() < 0.75:
		var calon: = daftar_pelanggan.filter( func(d): return ramai.has(VarianBaju.sifat(String(d["id"]))) and (boleh_dobel or not ada.has(VarianBaju.wajah(String(d["id"])))))
		var total: = 0.0
		for d in calon:
			total += float(ramai[VarianBaju.sifat(String(d["id"]))]) * float(d.get("bobot", 1.0))
		var r: = randf() * total
		for d in calon:
			r -= float(ramai[VarianBaju.sifat(String(d["id"]))]) * float(d.get("bobot", 1.0))
			if r <= 0.0:
				return d
	if _kantong_tipe.is_empty():

		for d in daftar_pelanggan:
			var k: = GameState.pengali_tipe(String(d["id"])) * float(d.get("bobot", 1.0))
			for i in int(k) + (1 if randf() < k - int(k) else 0):
				_kantong_tipe.append(d)
		if _kantong_tipe.is_empty():
			_kantong_tipe = daftar_pelanggan.duplicate()
		_kantong_tipe.shuffle()
	for i in _kantong_tipe.size():
		if not ada.has(VarianBaju.wajah(String(_kantong_tipe[i]["id"]))):
			return _kantong_tipe.pop_at(i)

	var belum: = daftar_pelanggan.filter( func(d): return not ada.has(VarianBaju.wajah(String(d["id"]))))
	if not belum.is_empty():
		return belum.pick_random()

	return _kantong_tipe.pop_front() if boleh_dobel and not _kantong_tipe.is_empty() else {}






func peluang_mengeluh(rasio: float) -> float:
	return clampf((rasio - MAHAL_MULAI) / (MAHAL_PENUH - MAHAL_MULAI), 0.0, 1.0) * PELUANG_KELUH_MAKS


static func pengali_jam(menit: float) -> float:
	var jam: = menit / 60.0


	if GameState.ramadan():
		if jam < 10.0:
			return 0.6
		if jam < 11.0:
			return 1.2
		if jam < 15.0:
			return 2.0
		if jam < 16.5:
			return 0.85
		if jam < 18.0:
			return 0.6
		return 1.8
	if jam < 10.0:
		return 0.55
	if jam < 11.0:
		return 0.9
	if jam < 13.0:
		return 0.8
	if jam < 15.5:
		return 1.3
	if jam < 17.0:
		return 0.55

	if jam < 19.0:
		return 1.3
	if jam < 21.0:
		return 2.4
	return 3.5






func nota_dipakai() -> bool:
	if lapisan_rak == null or not lapisan_rak.visible:
		return false
	var d: = _depan()
	return not d.is_empty() and d["status"] == "depan"


func sedang_transaksi() -> bool:
	for p in antrean:
		if p["status"] in ["depan", "dilayani", "menyapa"]:
			return true
	return false
