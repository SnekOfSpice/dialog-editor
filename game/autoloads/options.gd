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

	music_volume = config.get_value("preferences", "music_volume", music_volume)
	master_volume = config.get_value("preferences", "master_volume", master_volume)
	sfx_volume = config.get_value("preferences", "sfx_volume", sfx_volume)
	text_speed = config.get_value("preferences", "text_speed", text_speed)
	auto_continue_delay = config.get_value("preferences", "auto_continue_delay", auto_continue_delay)
	auto_continue = config.get_value("preferences", "auto_continue", auto_continue)
	set_fullscreen(config.get_value("preferences", "fullscreen", fullscreen))
	save_slot = config.get_value("preferences", "save_slot", 0)
	apply_font_prefs(config.get_value("preferences", "font_prefs", {}))
	
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
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen = true

var font_prefs : Dictionary
func store_font_prefs(prefs:Dictionary):
	font_prefs = prefs

func apply_font_prefs(prefs:Dictionary):
	font_prefs = prefs
	Style.set_label_font(prefs.get("label_font", 0))
	Style.set_rich_text_label_font(prefs.get("rich_text_label_font", 0))
	Style.set_rich_text_label_font_size(prefs.get("rich_text_label_font_size", Style.DEFAULT_RTL_FONT_SIZE))
	Style.set_label_font_size(prefs.get("label_font_size", Style.DEFAULT_LABEL_FONT_SIZE))

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
	config.set_value("preferences", "font_prefs", font_prefs)
	
	config.set_value("state", "just_finished_game", just_finished_game)
	config.set_value("state", "unlocked_epilogue", unlocked_epilogue)

	# Save it to a file (overwrite if already exists).
	config.save(OPTIONS_PATH)


func get_save_thumbnail_path(slot := save_slot) -> String:
	return str("user://thumbnail", slot, ".png")

func get_save_thumbnail_size() -> Vector2:
	return Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width") * 0.15,
	ProjectSettings.get_setting("display/window/size/viewport_height") * 0.15)

func get_savedata_dir_name(slot := save_slot) -> String:
	return str("slot", slot)

func has_savedata(slot := save_slot) -> bool:
	var err = DirAccess.open(str("user://", get_savedata_dir_name(slot)))
	if not err:
		return false
	return true

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
	
	Parser.save_parser_state(get_savedata_dir_name(), data_to_save)

func load_gamestate():
	var game_data := Parser.load_parser_state(get_savedata_dir_name())
	Sound.deserialize(game_data.get("Sound", {}))
	GameWorld.deserialize(game_data.get("GameWorld", {}))
	GoBackHandler.deserialize(game_data.get("GoBackHandler", {}))
	#var character_visibilities : Dictionary= game_data.get("Game.character_visibilities", {})
	#for c in get_tree().get_nodes_in_group("Character"):
		#c.deserialize(character_visibilities.get(c.character_name, {}))
