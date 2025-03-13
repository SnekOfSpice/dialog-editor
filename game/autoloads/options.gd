extends Node

const OPTIONS_PATH := "user://preferences.cfg"

var master_volume := 1.0
var music_volume := 1.0
var sfx_volume := 1.0

@export_group("DIISIS Defaults")
@export var fullscreen := false
@export_range(1, LineReader.MAX_TEXT_SPEED, 1) var text_speed := 201
@export_range(0.1, 60.0, 0.1) var auto_continue_delay := 1.0
@export var auto_continue := false

var save_slot := 0
const MAX_SAVE_SLOTS := 4


var just_finished_game := false
var unlocked_epilogue := false

func _ready() -> void:
	var config = ConfigFile.new()

	var err = config.load(OPTIONS_PATH)

	if err != OK:
		print("No options file found.")
		return

	music_volume = config.get_value("preferences", "music_volume", 1.0)
	master_volume = config.get_value("preferences", "master_volume", 1.0)
	sfx_volume = config.get_value("preferences", "sfx_volume", 1.0)
	text_speed = config.get_value("preferences", "text_speed", 60)
	auto_continue_delay = config.get_value("preferences", "auto_continue_delay", 1.0)
	auto_continue = config.get_value("preferences", "auto_continue", false)
	set_fullscreen(config.get_value("preferences", "fullscreen", false))
	save_slot = config.get_value("preferences", "save_slot", 0)
	
	just_finished_game = config.get_value("state", "just_finished_game", false)
	unlocked_epilogue = config.get_value("state", "unlocked_epilogue", false)
	
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume)
	)
func set_fullscreen(value:bool):
	fullscreen = value
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	
func save_prefs():
	var config = ConfigFile.new()

	# Store some values.
	config.set_value("preferences", "master_volume", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))))
	config.set_value("preferences", "music_volume", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))))
	config.set_value("preferences", "sfx_volume", db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))))
	config.set_value("preferences", "text_speed", text_speed)
	config.set_value("preferences", "auto_continue", auto_continue)
	config.set_value("preferences", "auto_continue_delay", auto_continue_delay)
	config.set_value("preferences", "fullscreen", fullscreen)
	config.set_value("preferences", "save_slot", save_slot)
	
	config.set_value("state", "just_finished_game", just_finished_game)
	config.set_value("state", "unlocked_epilogue", unlocked_epilogue)

	# Save it to a file (overwrite if already exists).
	config.save(OPTIONS_PATH)

func does_savegame_exist():
	if not ResourceLoader.exists(get_savedata_path()):
		return false
	return true

func get_save_thumbnail_path(slot := save_slot) -> String:
	return str("user://thumbnail", slot, ".png")

func get_save_thumbnail_size() -> Vector2:
	return Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width") * 0.15,
	ProjectSettings.get_setting("display/window/size/viewport_height") * 0.15)

func get_savedata_path(slot := save_slot) -> String:
	return str("user://savegame", slot,".json")

func has_savedata(slot := save_slot) -> bool:
	return ResourceLoader.exists(get_savedata_path(slot))

func set_save_slot(slot : int):
	save_slot = slot
	if GameWorld.stage_root.stage == CONST.STAGE_MAIN:
		GameWorld.stage_root.get_stage_node().set_save_slot(slot)

func save_gamestate():
	var data_to_save := {}
	data_to_save["Sound"] = Sound.serialize()
	data_to_save["GameWorld"] = GameWorld.serialize()
	data_to_save["GoBackHandler"] = GoBackHandler.serialize()
	
	if GameWorld.stage_root.screenshot_to_save:
		var path := get_save_thumbnail_path()
		GameWorld.stage_root.screenshot_to_save.save_png(path)
	
	Parser.save_parser_state_to_file(get_savedata_path(), data_to_save)

func load_gamestate():
	var game_data := Parser.load_parser_state_from_file(get_savedata_path())
	Sound.deserialize(game_data.get("Sound", {}))
	GameWorld.deserialize(game_data.get("GameWorld", {}))
	GoBackHandler.deserialize(game_data.get("GoBackHandler", {}))
	#var character_visibilities : Dictionary= game_data.get("Game.character_visibilities", {})
	#for c in get_tree().get_nodes_in_group("Character"):
		#c.deserialize(character_visibilities.get(c.character_name, {}))
