extends AudioStreamPlayer

# Fungsi buat ganti lagu
func ganti_musik(lagu_baru: AudioStream):
	# 1. Cek dulu, kalau lagunya sama dan lagi main, jangan diganggu
	if stream == lagu_baru and playing:
		return
	
	stream = lagu_baru
	play()
