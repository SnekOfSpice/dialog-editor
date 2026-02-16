extends Node

const OPTIONS_PATH := "user://preferences.cfg"

@export_group("DIISIS Defaults")
@export_range(1, LineReader.MAX_TEXT_SPEED, 1) var text_speed := 34:
	set(value):
		text_speed = value
		EventBus.settings_changed.emit()
@export_range(0.1, 60.0, 0.1) var auto_continue_delay := 1.0:
	set(value):
		auto_continue_delay = value
		EventBus.settings_changed.emit()
@export var auto_continue := false:
	set(value):
		auto_continue = value
		EventBus.settings_changed.emit()

var save_slot := 0
const MAX_SAVE_SLOTS := 6

#enum ShadowQuality {
	#Good,
	#Bad,
	#None
#}
enum WindowMode {
	Windowed,
	Borderless,
	Fullscreen
}
#var shadow_quality_index : ShadowQuality = ShadowQuality.Good:
	#set(value):
		#shadow_quality_index = value
		#EventBus.settings_changed.emit()
var window_mode_index : WindowMode = WindowMode.Fullscreen:
	set(value):
		window_mode_index = value
		EventBus.settings_changed.emit()
#var showdown_background_enabled := false:
	#set(value):
		#showdown_background_enabled = value
		#EventBus.settings_changed.emit()
#var render_scale_index := 1:
	#set(value):
		#render_scale_index = value
		#EventBus.settings_changed.emit()
#var slideshow_enabled := true:
	#set(value):
		#slideshow_enabled = value
		#EventBus.settings_changed.emit()

var finished_setup := false:
	set(value):
		finished_setup = value

#var sfx_description := false:
	#set(value):
		#sfx_description = value
		#EventBus.settings_changed.emit()
#var music_description := false:
	#set(value):
		#music_description = value
		#EventBus.settings_changed.emit()
#var dither_enabled := true:
	#set(value):
		#dither_enabled = value
		#EventBus.settings_changed.emit()
#var blur_enabled := true:
	#set(value):
		#blur_enabled = value
		#EventBus.settings_changed.emit()
#var blood_enabled := true:
	#set(value):
		#blood_enabled = value
		#EventBus.settings_changed.emit()
#var crt_enabled := true:
	#set(value):
		#crt_enabled = value
		#EventBus.settings_changed.emit()
var fps_counter_visible := false:
	set(value):
		fps_counter_visible = value
		EventBus.settings_changed.emit()
#var glow_enabled := true:
	#set(value):
		#glow_enabled = value
		#EventBus.settings_changed.emit()

var photomode_unlocked:=false:
	set(value):
		photomode_unlocked = value

func _ready() -> void:
	var config = ConfigFile.new()

	var err = config.load(OPTIONS_PATH)

	if err != OK:
		print("No options file found.")
		return

	set_screen(config.get_value("preferences", "current_screen", 0))
	text_speed = config.get_value("preferences", "text_speed", text_speed)
	auto_continue_delay = config.get_value("preferences", "auto_continue_delay", auto_continue_delay)
	auto_continue = config.get_value("preferences", "auto_continue", auto_continue)
	set_window_mode(config.get_value("preferences", "window_mode_index", WindowMode.Windowed))
	save_slot = config.get_value("preferences", "save_slot", 0)
	#apply_font_prefs(config.get_value("preferences", "font_prefs", {}))
	
	
	#sfx_description = config.get_value("accessibility", "sfx_description", false)
	#music_description = config.get_value("accessibility", "music_description", false)
	#
	#dither_enabled = config.get_value("graphics", "dither_enabled", false)
	#blur_enabled = config.get_value("graphics", "blur_enabled", false)
	#blood_enabled = config.get_value("graphics", "blood_enabled", false)
	#crt_enabled = config.get_value("graphics", "crt_enabled", false)
	fps_counter_visible = config.get_value("graphics", "fps_counter_visible", false)
	#glow_enabled = config.get_value("graphics", "glow_enabled", false)
	
	photomode_unlocked = config.get_value("progress", "photomode_unlocked", false)
	finished_setup = config.get_value("progress", "finished_setup", false)
	
	
	#set_render_scale_by_index(config.get_value("graphics", "render_scale_index", render_scale_index))
	#set_shadow_quality_by_index(config.get_value("graphics", "shadow_quality_index", shadow_quality_index))
	#showdown_background_enabled = config.get_value("graphics", "showdown_background_enabled", showdown_background_enabled)
	#slideshow_enabled = config.get_value("graphics", "slideshow_enabled", false)
	
	# 0.8 for better ux
	set_volume("Master", config.get_value("preferences", "master_volume", 0.8), false)
	set_volume("Music", config.get_value("preferences", "music_volume", 0.8), false)
	set_volume("SFX", config.get_value("preferences", "sfx_volume", 0.8), false)
	set_volume("UI", config.get_value("preferences", "ui_volume", 0.8), false)


func get_volume(bus : String) -> float:
	return AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus))


## volume is 0 to 1
func set_volume(bus : String, volume : float, save : bool):
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), volume)
	
	if save:
		save_prefs()

func set_window_mode(mode : WindowMode):
	window_mode_index = mode
	match mode:
		WindowMode.Fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.Borderless:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			await RenderingServer.frame_post_draw
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		WindowMode.Windowed:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			await RenderingServer.frame_post_draw
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	


#var font_prefs : Dictionary
#func store_font_prefs(prefs:Dictionary):
	#font_prefs = prefs
#
#func apply_font_prefs(prefs:Dictionary):
	#font_prefs = prefs
	##Style.set_label_font(prefs.get("label_font", 0))
	##Style.set_rich_text_label_font(prefs.get("rich_text_label_font", 0))
	##Style.set_rich_text_label_font_size(prefs.get("rich_text_label_font_size", Style.DEFAULT_RTL_FONT_SIZE))
	##Style.set_label_font_size(prefs.get("label_font_size", Style.DEFAULT_LABEL_FONT_SIZE))

func save_prefs():
	var config = ConfigFile.new()

	# Store some values.
	config.set_value("preferences", "master_volume", get_volume("Master"))
	config.set_value("preferences", "music_volume", get_volume("Music"))
	config.set_value("preferences", "sfx_volume", get_volume("SFX"))
	config.set_value("preferences", "ui_volume", get_volume("UI"))
	config.set_value("preferences", "text_speed", text_speed)
	config.set_value("preferences", "auto_continue", auto_continue)
	config.set_value("preferences", "auto_continue_delay", auto_continue_delay)
	config.set_value("preferences", "window_mode_index", window_mode_index)
	config.set_value("preferences", "current_screen", DisplayServer.window_get_current_screen())
	config.set_value("preferences", "save_slot", save_slot)
	
	#config.set_value("graphics", "shadow_quality_index", shadow_quality_index)
	#config.set_value("graphics", "render_scale_index", render_scale_index)
	#config.set_value("graphics", "slideshow_enabled", slideshow_enabled)
	
	
	#config.set_value("preferences", "font_prefs", font_prefs)
	#config.set_value("graphics", "dither_enabled", dither_enabled)
	#config.set_value("graphics", "blur_enabled", blur_enabled)
	#config.set_value("graphics", "blood_enabled", blood_enabled)
	#config.set_value("graphics", "crt_enabled", crt_enabled)
	#config.set_value("graphics", "fps_counter_visible", fps_counter_visible)
	#config.set_value("graphics", "showdown_background_enabled", showdown_background_enabled)
	#config.set_value("graphics", "glow_enabled", glow_enabled)
	#
	#config.set_value("accessibility", "sfx_description", sfx_description)
	#config.set_value("accessibility", "music_description", music_description)
	
	config.set_value("progress", "photomode_unlocked", photomode_unlocked)
	config.set_value("progress", "finished_setup", finished_setup)

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
	EventBus.save_slot_set.emit(slot)
#
func save_gamestate(grab_screenshot:=false):
	var data_to_save := {}
	data_to_save["Sound"] = Sound.serialize()
	if Game.game_stage:
		data_to_save["GameStage"] = Game.game_stage.serialize()
	
	if not Game.screenshot_to_save and grab_screenshot:
		Game.grab_thumbnail_screenshot()
	
	if Game.screenshot_to_save:
		var path_thumb := get_save_thumbnail_path()
		Game.screenshot_to_save.save_png(path_thumb)
		
		var path_time := get_save_time_path()
		var file = FileAccess.open(path_time, FileAccess.WRITE)
		file.store_string(Time.get_datetime_string_from_system(false, true))
		file.close()
	
	Parser.save_parser_state(get_savedata_dir_name(), data_to_save)


func load_gamestate():
	var game_data : Dictionary = Parser.load_parser_state(get_savedata_dir_name())
	Sound.deserialize(game_data.get("Sound", {}))
	if Game.game_stage:
		Game.game_stage.deserialize(game_data.get("GameStage", {}))
	#Overlay.play("chapter_out", true)


func get_save_time_path(slot := save_slot) -> String:
	return str("user://time", slot, ".txt")


#
#func set_shadow_quality_by_index(index:int):
	#shadow_quality_index = index
#
#
#func set_render_scale_by_index(index:int):
	#render_scale_index = index

func render_scale_index_to_scale(index : int) -> float:
	var render_scale : float
	if index == 0:
		render_scale = 1
	elif index == 1:
		render_scale = 0.5
	elif index == 2:
		render_scale = 0.25
	return render_scale

func set_screen(index:int):
	DisplayServer.window_set_current_screen(index)
