extends Node

var target_scene_path: String
var loading_status: int
var progress: Array = []

# --- BAGIAN INI SUDAH DISESUAIKAN SAMA PATH ABANG ---
@onready var loading_screen_scene = preload("res://src/UIScene/LoadingScreen.tscn") 
# ----------------------------------------------------

var current_loading_screen: Node

func load_scene(path: String):
	target_scene_path = path
	
	# Munculin Loading Screen
	var new_loading_screen = loading_screen_scene.instantiate()
	get_tree().root.add_child(new_loading_screen)
	current_loading_screen = new_loading_screen
	
	# Mulai loading background
	ResourceLoader.load_threaded_request(target_scene_path)
	
	set_process(true)

func _process(_delta):
	if target_scene_path == "":
		set_process(false)
		return

	loading_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	# --- PENTING: Pastikan nama node di scene LoadingScreen abang itu beneran "ProgressBar" ---
	if current_loading_screen.has_node("ProgressBar"):
		current_loading_screen.get_node("ProgressBar").value = progress[0] * 100
	# ------------------------------------------------------------------------------------------

	if loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene_resource = ResourceLoader.load_threaded_get(target_scene_path)
		
		# Pindah Scene
		get_tree().change_scene_to_packed(new_scene_resource)
		
		# Bersih-bersih
		current_loading_screen.queue_free()
		target_scene_path = ""
