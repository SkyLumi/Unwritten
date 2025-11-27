# Konfigurasi Move

Semua angka tuning untuk `Move` ada di satu resource agar gampang diubah tanpa menggali tiap script.

## Resource baru
- `MoveTuning.gd` + `MoveTuning.tres` menampung nilai default (run, sprint, jump, midair).
- `Move.gd` mengekspor `tuning` dan otomatis memuat `MoveTuning.tres`, jadi semua state langsung dapat nilai.

## Cara pakai
1. Buka `src/Player/Moves/MoveTuning.tres` di Inspector.
2. Ubah nilai yang diinginkan (contoh: `run_speed`, `sprint_stamina_cost_per_second`, `jump_transition_timing`, dsb.).
3. Jika mau nilai khusus untuk satu move, duplikat `MoveTuning.tres`, drag & drop resource itu ke properti `tuning` milik node move terkait.

## Bidang konfigurasi cepat
- `run_speed`, `run_turn_speed`
- `walk_speed`, `walk_turn_speed`
- `sprint_speed`, `sprint_turn_speed`, `sprint_stamina_cost_per_second`
- `jump_transition_timing`, `jump_impulse_delay`, `jump_run_speed`, `jump_run_vertical_boost`, `jump_idle_vertical_boost`
- `jump_sprint_transition_timing`, `jump_sprint_impulse_delay`, `jump_sprint_speed`, `jump_sprint_vertical_boost`
- `midair_delta_vector_length`, `midair_jump_speed`, `midair_second_jump_multiplier`, `midair_landing_height`

Tambahkan bidang baru langsung di `MoveTuning.gd` jika ada angka lain yang ingin diatur terpusat. Pastikan script move membaca nilai tersebut dari `tuning`.
