extends Node


var _paths_that_switch_when_loaded := []
var _paths := []

@onready var current_scene := MainMenu.PATH
var in_game : bool:
	get():
		return current_scene == GameStage.PATH

## emitted when bg loaded scene is ready
signal scene_loaded(path : String)
## emitted when root of the tree is changed
signal scene_changed(path : String)

func _ready() -> void:
	%LoadRect.hide()
	scene_changed.emit(MainMenu.PATH)


func _process(_delta: float) -> void:
	for path in _paths:
		handle_auto_switch(path)

func request_background_loading(scene_path : String, switch_when_loaded := false) -> void:
	ResourceLoader.load_threaded_request(scene_path, "")
	_paths.append(scene_path)
	set_switch_when_loaded(scene_path, switch_when_loaded)


func set_switch_when_loaded(path:String, value:bool):
	if not _paths_that_switch_when_loaded.has(path) and value:
		_paths_that_switch_when_loaded.append(path)
	
	if _paths_that_switch_when_loaded.has(path) and not value:
		_paths_that_switch_when_loaded.erase(path)
	
	var status := ResourceLoader.load_threaded_get_status(path)
	if value:
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			handle_auto_switch(path)
		else:
			%LoadRect.visible = value
			await RenderingServer.frame_post_draw


func handle_auto_switch(path : String):
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		
		%LoadRect.hide()
		_paths.erase(path)
		
		if _paths_that_switch_when_loaded.has(path):
			var scene := ResourceLoader.load_threaded_get(path)
			get_tree().call_deferred("change_scene_to_packed", scene)
			_paths_that_switch_when_loaded.erase(path)
			current_scene = path
			get_tree().process_frame.connect(scene_changed.emit.bind(path), CONNECT_ONE_SHOT)
		
		scene_loaded.emit(path)
