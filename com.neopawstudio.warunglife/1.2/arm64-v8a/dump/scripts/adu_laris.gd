extends RefCounted














const BERKAS: = "user://adu_laris.json"
const MAKS_MAIN: = 5
const JENDELA_DETIK: = 24 * 3600
const MENIT_GAME: = 60.0
const DURASI: = 60.0
const JAM_AKHIR: = 23.5
const ENERGI_MIN: = 15.0
const TROFI_MENANG: = 3
const TROFI_SERI: = 1
const JUMLAH_PEMBELI: = 40
const TIP_PER_DETIK: = 100.0


const OMZET_MAKS_WAJAR: = 1250000



const RAK_KIRI: = ["mi_goreng", "mi_rebus", "telur", "gula", "minyak_goreng", "beras", "sabun", "deterjen", "sachet", "kopi_bubuk"]
const RAK_KANAN: = ["air_mineral", "teh_botol", "susu_kotak", "kopi_susu", "soda", "ciki", "permen", "biskuit", "roti", "es_krim"]
const BARANG: = RAK_KIRI + RAK_KANAN

const NAMA_LAWAN: = ["Warung Barokah", "Toko Sumber Rejeki", "Warung Bu Tini", "Warung Berkah Jaya", "Kios Mang Dadang", 
	"Warung Cahaya", "Toko Mekar Sari", "Warung Pojok", "Warung Sederhana", "Kios Bu Romlah", "Warung Sinar Pagi", 
	"Toko Makmur", "Warung Rizki", "Warung Mbak Yuli", "Kios Abah Ujang", "Warung Bintang"]


static func _muat() -> Dictionary:
	if not FileAccess.file_exists(BERKAS):
		return {}
	var f: = FileAccess.open(BERKAS, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func _simpan(d: Dictionary) -> void :

	var sementara: = BERKAS + ".tmp"
	var f: = FileAccess.open(sementara, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(d))
	f.close()
	DirAccess.rename_absolute(sementara, BERKAS)


static func _sekarang() -> int:
	return int(Time.get_unix_time_from_system())



static func _main_terhitung(d: Dictionary) -> Array:
	var batas: = _sekarang() - JENDELA_DETIK
	return (d.get("main", []) as Array).filter( func(t): return int(t) > batas)


static func sisa_kesempatan() -> int:
	return maxi(MAKS_MAIN - _main_terhitung(_muat()).size(), 0)



static func teks_tunggu() -> String:
	var daftar: = _main_terhitung(_muat())
	if daftar.size() < MAKS_MAIN:
		return ""
	var paling_lama: = int(daftar.min())
	var detik: = maxi(paling_lama + JENDELA_DETIK - _sekarang(), 60)
	var jam: = detik / 3600
	var menit: = (detik % 3600) / 60
	return (TranslationServer.translate("%d jam %d menit") % [jam, menit]) if jam > 0 else (TranslationServer.translate("%d menit") % menit)


static func data_pemain() -> Dictionary:
	var d: = _muat()
	return {"trofi": int(d.get("trofi", 0)), "menang": int(d.get("menang", 0)), "kalah": int(d.get("kalah", 0)), "seri": int(d.get("seri", 0)), 
		"beruntun": int(d.get("beruntun", 0))}



static func alasan_tidak_bisa() -> String:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	if gs.mode_latihan or gs.tutorial_langkah != "":
		return "Adu Laris belum bisa dimainkan sekarang."
	var jam: float = gs.menit / 60.0
	if jam < gs.ngojol_jam_mulai():
		return "Duel resmi Adu Laris dibuka sesudah warung tutup."
	if jam >= JAM_AKHIR:
		return "Sudah terlalu malam untuk Adu Laris. Besok lagi ya."
	if gs.energi < ENERGI_MIN:
		return "Pak Misran terlalu lelah untuk Adu Laris. Ngopi atau tonton iklan energi dulu."
	if sisa_kesempatan() <= 0:
		return TranslationServer.translate("Kesempatan Adu Laris habis (5 kali sehari). Terbuka lagi dalam %s.") % teks_tunggu()
	return ""




static func boleh_latihan() -> bool:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	return not gs.mode_latihan and gs.tutorial_langkah == ""


static func boleh_tampil() -> bool:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	return not gs.mode_latihan and gs.tutorial_langkah == "" and gs.menit / 60.0 >= gs.ngojol_jam_mulai()



static func tanggal_wib() -> String:
	var t: = Time.get_datetime_dict_from_unix_time(_sekarang() + 7 * 3600)
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]



static func minggu_wib() -> String:
	var wib: = _sekarang() + 7 * 3600
	var t: = Time.get_datetime_dict_from_unix_time(wib)
	var ke: = (int(t["weekday"]) + 6) % 7
	var senin: = Time.get_datetime_dict_from_unix_time(wib - ke * 86400)
	return "%04d-%02d-%02d" % [senin["year"], senin["month"], senin["day"]]


static func harga(id: String) -> int:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	return int(gs.katalog[id]["jual"])












const POLA_BLOK: = ["kecil", "kecil", "sedang", "sedang", "besar"]
const JENIS_BARANG: = {"kecil": [1, 2], "sedang": [2, 3], "besar": [3, 5]}
const NILAI_PER_BARANG: = 6500.0
const TOLERANSI: = 0.05


static func benih_baru() -> int:
	return randi()


static func _acak_urut(daftar: Array, rng: RandomNumberGenerator) -> Array:
	var a: = daftar.duplicate()
	for k in range(a.size() - 1, 0, -1):
		var m: = rng.randi_range(0, k)
		var t = a[k]
		a[k] = a[m]
		a[m] = t
	return a



static func acak_rak(benih: int) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = benih + 7919
	return [_acak_urut(RAK_KIRI, rng), _acak_urut(RAK_KANAN, rng)]


static func _pesanan_seimbang(jenis_pesanan: String, qty: int, rng: RandomNumberGenerator) -> Dictionary:
	var r_jenis: Array = JENIS_BARANG[jenis_pesanan]
	var target: = qty * NILAI_PER_BARANG
	var terbaik: = {}
	var selisih_terbaik: = 1000000000000.0
	for coba in 400:
		var jenis: = mini(rng.randi_range(int(r_jenis[0]), int(r_jenis[1])), qty)
		var pilih: = _acak_urut(BARANG, rng).slice(0, jenis)
		var pesanan: = {}
		for id in pilih:
			pesanan[id] = 1
		for x in qty - jenis:
			var id: String = pilih[rng.randi_range(0, pilih.size() - 1)]
			pesanan[id] = int(pesanan[id]) + 1
		var selisih: = absf(nilai_pesanan(pesanan) - target)
		if selisih < selisih_terbaik:
			selisih_terbaik = selisih
			terbaik = pesanan
		if selisih <= target * TOLERANSI:
			break
	return terbaik



static func buat_pembeli(benih: int) -> Array:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	var rng: = RandomNumberGenerator.new()
	rng.seed = benih
	var warga: Array = (gs.WARGA_TIP as Array).filter( func(n): return ResourceLoader.exists("res://assets/potret/warga_%s.png" % n))
	var urutan: Array = []
	for blok in JUMLAH_PEMBELI / POLA_BLOK.size():



		var pola: = _acak_urut([["kecil", 1], ["kecil", 2], ["sedang", 3], ["sedang", 4]], rng)
		if blok == 0 and pola[0][1] != 1:
			var k: = pola.map( func(x): return int(x[1])).find(1)
			var t = pola[0]
			pola[0] = pola[k]
			pola[k] = t
		pola.append(["besar", 7])
		urutan.append_array(pola)
	var hasil: = []
	var npc_lalu: = ""
	for isi in urutan:
		var npc: = npc_lalu
		while npc == npc_lalu:
			npc = String(warga[rng.randi_range(0, warga.size() - 1)])
		npc_lalu = npc
		hasil.append({"npc": npc, "pesanan": _pesanan_seimbang(String(isi[0]), int(isi[1]), rng), "borong": isi[0] == "besar", 
			"jenis": isi[0]})
	return hasil


static func nilai_pesanan(pesanan: Dictionary) -> int:
	var total: = 0
	for id in pesanan:
		total += harga(String(id)) * int(pesanan[id])
	return total


static func jumlah_barang(pesanan: Dictionary) -> int:
	var n: = 0
	for id in pesanan:
		n += int(pesanan[id])
	return n



static func pengali_beruntun(beruntun: int) -> float:
	return 1.2 if beruntun >= 6 else (1.1 if beruntun >= 3 else 1.0)



static func tip_cepat(sisa_sabar: float) -> int:
	return int(round(maxf(sisa_sabar, 0.0) * TIP_PER_DETIK))



static func sabar(detik_berjalan: float, borong: bool, jumlah: = 0) -> float:
	var s: = lerpf(13.0, 8.0, clampf(detik_berjalan / DURASI, 0.0, 1.0))
	if borong:
		return s + 6.0
	return s + 0.8 * maxi(jumlah - 2, 0)




static func pilih_lawan() -> Dictionary:
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	var d: = _muat()
	var rng: = RandomNumberGenerator.new()
	rng.seed = hash("lawan:%s:%d:%d" % [minggu_wib(), (d.get("main", []) as Array).size(), _sekarang() / 60])
	var level: int = clampi(int(gs.level()) + rng.randi_range(-1, 1), 1, 20)
	var nama: String = NAMA_LAWAN[rng.randi_range(0, NAMA_LAWAN.size() - 1)]
	var pemain: = data_pemain()

	var jago: = clampf(0.35 + level * 0.025 + mini(int(pemain["beruntun"]), 5) * 0.04 + rng.randf_range(-0.1, 0.1), 0.25, 0.92)
	var foto: = rng.randi_range(1, 16)
	return {"nama": nama, "level": level, "foto": foto, "rekaman": _rekaman_bot(jago, rng.randi()), "bot": true}


static func _rekaman_bot(jago: float, benih: int) -> Array:
	var rng: = RandomNumberGenerator.new()
	rng.seed = benih
	var daftar: = buat_pembeli(rng.randi())
	var rekaman: = [0]
	var omzet: = 0
	var t: = 0.0
	var beruntun: = 0
	var i: = 0
	var detik: = 1
	while detik <= int(DURASI) and i < daftar.size():
		var p: Dictionary = daftar[i]


		var lama: float = (lerpf(2.0, 0.55, jago) + jumlah_barang(p["pesanan"]) * lerpf(1.3, 0.38, jago) + 0.29) * rng.randf_range(0.9, 1.12)
		var sabarnya: = sabar(t, bool(p["borong"]), jumlah_barang(p["pesanan"]))
		var salah: = rng.randf() < lerpf(0.22, 0.04, jago)
		if salah:
			lama += 2.0
		var selesai: = t + minf(lama, sabarnya)
		while detik <= int(DURASI) and float(detik) < selesai:
			rekaman.append(omzet)
			detik += 1
		if selesai > DURASI:
			break
		if lama <= sabarnya:
			beruntun = 0 if salah else beruntun + 1
			omzet += int(round(nilai_pesanan(p["pesanan"]) * pengali_beruntun(beruntun))) + tip_cepat(sabarnya - lama)
		else:
			beruntun = 0
		t = selesai + 0.6
		i += 1
	while rekaman.size() <= int(DURASI):
		rekaman.append(omzet)
	return rekaman



static func catat_mulai() -> void :
	var d: = _muat()
	var daftar: = _main_terhitung(d)
	daftar.append(_sekarang())
	d["main"] = daftar
	_simpan(d)



static func catat_hasil(hasil: String, omzet: int, rekaman: Array, lawan: String) -> int:
	var d: = _muat()
	var trofi: = TROFI_MENANG if hasil == "menang" else (TROFI_SERI if hasil == "seri" else 0)
	d["trofi"] = int(d.get("trofi", 0)) + trofi
	d[hasil] = int(d.get(hasil, 0)) + 1
	d["beruntun"] = int(d.get("beruntun", 0)) + 1 if hasil == "menang" else 0
	d["terbaik"] = maxi(int(d.get("terbaik", 0)), omzet)

	var simpanan: Array = d.get("rekaman", [])
	simpanan.append({"tanggal": tanggal_wib(), "minggu": minggu_wib(), "omzet": omzet, "rekaman": rekaman, "lawan": lawan, "hasil": hasil})
	while simpanan.size() > 5:
		simpanan.pop_front()
	d["rekaman"] = simpanan
	_simpan(d)
	return trofi



static func kirim_ke_server(omzet: int, pembeli: int, hasil: String, rekaman: Array) -> void :
	var gs = Engine.get_main_loop().root.get_node("/root/GameState")
	if gs.papan != null:
		gs.papan.kirim_adu_laris(omzet, pembeli, hasil, rekaman, minggu_wib())


static func rekaman_terakhir() -> Dictionary:
	var simpanan: Array = _muat().get("rekaman", [])
	return simpanan.back() if not simpanan.is_empty() else {}
