@tool
extends LineReader
class_name GameStage

@onready var characters := {}

const PATH := "res://game/stages/game_stage.tscn"

var background : String = ""

@export_group("Devmode", "devmode_")
@export var devmode_enabled := false
@export var devmode_start_page := 0
@export var devmode_start_line := 0
@export var stylebox_regular : StyleBox
@export var stylebox_cg : StyleBox

#@onready var line_reader : LineReader = find_child("LineReader")

var dialog_box_tween : Tween
var dialog_box_offset := Vector2.ZERO
var actor_name := ""
var cg := ""
var cg_position := ""
var base_cg_offset : Vector2
var is_name_container_visible := false

@onready var cg_roots := [find_child("CGBottomContainer"), find_child("CGTopContainer")]

var callable_upon_blocker_clear:Callable
var meta_blocker := false
var screen_close_blocker := false
@onready var camera = %Camera2D

var target_lod := 0.0
var target_mix := 0.0


func get_default_targets() -> Dictionary:
	var result := {}
	for actor in actor_config.keys():
		result[actor] = 0
	return result

func _ready():
	super()
	if Engine.is_editor_hint():
		return
	if devmode_enabled:
		set_background("void")
	find_child("DevModeLabel").visible = devmode_enabled
	#GoBackHandler.store_into_subaddress(get_default_targets(), targets_by_subaddress, "0.0.0")
	find_child("StartCover").visible = true
	ParserEvents.actor_name_changed.connect(on_actor_name_changed)
	ParserEvents.page_terminated.connect(go_to_main_menu)
	ParserEvents.instruction_started.connect(on_instruction_started)
	
	Game.game_stage = self
	
	auto_continue = Options.auto_continue
	text_speed = Options.text_speed
	auto_continue_delay = Options.auto_continue_delay
	
	for character in find_child("Characters").get_children():
		character.visible = false
	
	
	
	tree_exiting.connect(on_tree_exit)
	
	hide_cg()
	
	await get_tree().process_frame
	if Game.start_data:
		Game.start_data.game_start_callable.call()
	else:
		push_error("No start data defined!")
	
	await get_tree().process_frame
	find_child("StartCover").visible = false


func on_tree_exit():
	Game.game_stage = null

func on_instruction_started(
	_instruction_text : String,
	_delay : float,
):
	find_child("StartCover").visible = false

func show_start_cover():
	find_child("StartCover").visible = true

func go_to_main_menu(_unused):
	SceneLoader.request_background_loading(MainMenu.PATH, true)


func _physics_process(delta: float) -> void:#(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	super(delta)
	find_child("VFXLayer").position = -camera.offset * camera.zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if not Game.screen.is_empty():
		return
	if event is InputEventScreenTouch:
		attempt_advance(event)
	if event is InputEventKey:
		if event.is_pressed():
			if InputMap.action_has_event("ui_cancel", event):
				Game.set_screen(CONST.SCREEN_OPTIONS)
			if InputMap.action_has_event("screenshot", event):
				var screenshot := get_viewport().get_texture().get_image()
				var path := str("user://screenshot_", ProjectSettings.get_setting("application/config/name").replace("://", " "), "_", Time.get_datetime_string_from_system().replace(":", "-"), ".png")
				screenshot.save_png(path)
				
				var notification_popup = preload("res://game/systems/notification.tscn").instantiate()
				var global_path := ProjectSettings.globalize_path(path)
				var global_dir := global_path.substr(0, global_path.rfind("/"))
				find_child("VNUIRoot").add_child(notification_popup)
				notification_popup.init(str("Saved to [url=", global_dir, "]", global_path, "[/url]"))
			if InputMap.action_has_event("toggle_auto_continue", event):
				auto_continue = not auto_continue
				Options.auto_continue = auto_continue
				Options.save_prefs()
			if InputMap.action_has_event("toggle_ui", event):
				if find_child("VNUI").visible:
					hide_ui()
				else:
					show_ui()
			if InputMap.action_has_event("cheats", event) and OS.has_feature("editor"):
				find_child("Cheats").visible = not find_child("Cheats").visible
				
	if event is InputEventMouse:
		if event.is_released() and InputMap.action_has_event("ui_cancel", event):
			Game.set_screen(CONST.SCREEN_OPTIONS)

	if (event.is_action_pressed("advance")):
		attempt_advance(event)
	if event.is_action_pressed("history"):
		if Game.screen == CONST.SCREEN_HISTORY:
			Game.set_screen("")
		else:
			Game.set_screen(CONST.SCREEN_HISTORY)
		
	elif event.is_action_pressed("go_back"):
		request_go_back()

func attempt_advance(event:InputEvent):
	if event.is_shift_pressed() and event is InputEventKey:
		return
	if screen_close_blocker:
		screen_close_blocker = false
		return
	if meta_blocker:
		meta_blocker = false
		return
	for root in cg_roots:
		if root.visible and emit_insutrction_complete_on_cg_hide:
			hide_cg()
			return
	if not find_child("VNUI").visible:
		return
	request_advance()

func show_ui():
	if is_instance_valid(find_child("VNUI")):
		find_child("VNUI").visible = true

func hide_ui():
	find_child("VNUI").visible = false

func set_cg(cg_name:String, fade_in_duration:float, cg_root:Control):
	#if stylebox_cg:
		#var ui1panel : PanelContainer = find_child("TextContainer1").find_child("Panel")
		#ui1panel.add_theme_stylebox_override("panel", stylebox_cg)
	
	cg_root.modulate.a = 0.0 if cg_root.get_child_count() == 0 else 1.0
	cg_root.visible = true
	
	var cg_path := CONST.fetch("CG", cg_name)
	var cg_node : Control
	
	if cg_path.is_empty():
		push_warning(str("Couldn't find CG \"", cg_name, "\"."))
		return
	if cg_path.ends_with(".tscn"):
		cg_node = load(cg_path).instantiate()
	else:
		cg_node = preload("res://game/cg/cg_texture.tscn").instantiate()
		cg_node.set_anchors_preset(Control.PRESET_CENTER)
		cg_node.texture = load(cg_path)
		cg_node.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		cg_node.custom_minimum_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)
	
	cg_root.add_child(cg_node)
	
	var t = create_tween()
	
	if cg_root.modulate.a == 1.0:
		cg_node.modulate.a = 0.0
		t.tween_property(cg_node, "modulate:a", 1.0, fade_in_duration)
	else:
		t.tween_property(cg_root, "modulate:a", 1.0, fade_in_duration)
	
	for child in cg_root.get_children():
		if child == cg_node:
			continue
		t.finished.connect(child.queue_free)
	
	var background_size : Vector2
	if cg_node is TextureRect:
		background_size = cg_node.texture.get_size()
	else:
		background_size = cg_node.size
	var overshoot = background_size - Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)
	var container = cg_node.get_parent() # might be top or bottom
	container.position = Vector2.ZERO
	if overshoot.x > 0:
		container.position.x = - overshoot.x * 0.5
	if overshoot.y > 0:
		container.position.y = - overshoot.y * 0.5
	base_cg_offset = container.position
	
	
	
	cg = cg_name

func set_cg_top(cg_name:String, fade_in_duration:float):
	cg_position = "top"
	set_cg(cg_name, fade_in_duration, find_child("CGTopContainer"))

func set_cg_bottom(cg_name:String, fade_in_duration:float):
	cg_position = "bottom"
	set_cg(cg_name, fade_in_duration, find_child("CGBottomContainer"))

func set_cg_offset(offset:Vector2):
	find_child("CGTopContainer").position = offset + base_cg_offset
	find_child("CGBottomContainer").position = offset + base_cg_offset


func hide_cg(fade_out := 0.0):
	cg = ""
	cg_position = ""
	if fade_out == 0.0:
		_clear_cg()
		return
	var t = create_tween()
	t.set_parallel()
	for cg_root : Control in cg_roots:
		t.tween_property(cg_root, "modulate:a", 0, fade_out)
	t.finished.connect(_clear_cg)
	
func _clear_cg():
	for cg_root : Control in cg_roots:
		cg_root.visible = false
		for c in cg_root.get_children():
			c.queue_free()
		#cg_root.modulate.a = 0.0
		if emit_insutrction_complete_on_cg_hide:
			Parser.function_acceded()
			emit_insutrction_complete_on_cg_hide = false
	
	#if stylebox_regular:
		#var ui1panel : PanelContainer = find_child("TextContainer1").find_child("Panel")
		#ui1panel.add_theme_stylebox_override("panel", stylebox_regular)
	





func set_callable_upon_blocker_clear(callable:Callable):
	callable_upon_blocker_clear = callable

func serialize() -> Dictionary:
	var result := {}
	
	var character_data := {}
	for character : Character in find_child("Characters").get_children():
		character_data[character.character_name] = character.serialize()
	
	result["character_data"] = character_data
	result["cg"] = cg
	result["cg_position"] = cg_position
	result["base_cg_offset"] = base_cg_offset
	result["background"] = background
	
	result["start_cover_visible"] = find_child("StartCover").visible

	result["camera"] = %Camera2D.serialize()

	result["text_content_default"] = serialize_text_content(%DefaultTextContainer)
	
	return result

func serialize_text_content(root:Control) -> Dictionary:
	var result := {}
	result["root_visible"] = root.visible
	result["rotation_degrees"] = root.rotation_degrees
	result["body_text"] = root.find_child("BodyLabel").text
	result["visible_characters"] = root.find_child("BodyLabel").visible_characters
	return result
func deserialize_text_content(root:Control, data:Dictionary) -> void:
	root.visible = data.get("root_visible", false)
	root.rotation_degrees = data.get("rotation_degrees", 0)
	root.find_child("BodyLabel").text = data.get("body_text", "")
	root.find_child("BodyLabel").visible_characters = data.get("visible_characters", -1)

func deserialize(data:Dictionary):
	var character_data : Dictionary = data.get("character_data", {})
	for character : Character in find_child("Characters").get_children():
		character.deserialize(character_data.get(character.character_name, {}))
	
	%Camera2D.deserialize(data.get("camera", {}))
	
	var cg_name : String = data.get("cg", "")
	if cg_name.is_empty():
		hide_cg()
	else:
		if data.get("cg_position", "") == "top":
			set_cg_top(cg_name, 0.0)
		elif data.get("cg_position", "") == "bottom":
			set_cg_bottom(cg_name, 0.0)
		else:
			push_warning("cg_position isn't top or bottom")
			hide_cg()
	
	find_child("StartCover").visible = data.get("start_cover_visible", false)
	
	target_lod = data.get("fade_out_lod", 0.0)
	target_mix = data.get("fade_out_mix_percentage", 0.0)

	base_cg_offset = Game.str_to_vec2(data.get("base_cg_offset", Vector2.ZERO))

	
	#window_visibilities_by_subaddress = data.get("window_visibilities_by_subaddress", {})
	#targets_by_subaddress = data.get("targets_by_subaddress", get_ready_targets_by_subaddress())

	set_background(data.get("background"))


	deserialize_text_content(%DefaultTextContainer, data.get("text_content_default", {}))
	
	show_ui()

var emit_insutrction_complete_on_cg_hide :bool

func get_character(character_name:String) -> Character:
	for child : Character in %Characters.get_children():
		if child.character_name == character_name:
			return child
	return null

func _on_history_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_HISTORY)

func show_cg(cg_name: String, fade_in: float, continue_dialog_through_cg: bool) -> bool:
	if continue_dialog_through_cg:
		set_cg_bottom(cg_name, fade_in)
	else:
		emit_insutrction_complete_on_cg_hide = true
		set_cg_top(cg_name, fade_in)
		
	
	return not continue_dialog_through_cg

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_menu_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_OPTIONS)


func set_fade_out(lod:float, mix:float):
	target_lod = lod
	target_mix = mix



func set_background(new_bg_key:String, fade_time:=0.0):
	if new_bg_key == "none" or new_bg_key == "null" or new_bg_key.is_empty():
		new_bg_key = background
	var path = CONST.fetch("BACKGROUND", new_bg_key)
	if not path:
		push_warning(str("COULDN'T FIND BACKGROUND ", new_bg_key, "!"))
		return false
	var new_background:Node2D
	var old_backgrounds:=%Background.get_children()
	if path.ends_with(".png") or path.ends_with(".jpg") or path.ends_with(".jpeg"):
		new_background = Sprite2D.new()
		new_background.texture = load(path)
		
		new_background.centered = false
	
	elif path.ends_with(".tscn"):
		new_background = load(path).instantiate()
	else:
		push_error(str("Background ", new_bg_key, " does not end in .png, .jpg, .jpeg or .tscn."))
		return
	
	%Background.add_child(new_background)
	%Background.move_child(new_background, 0)
	
	var background_size := Vector2.ZERO
	if new_background is Sprite2D:
		background_size = new_background.texture.get_size()
	elif new_background.has_method("get_size"):
		background_size = new_background.get_size()
	
	var overshoot = background_size - Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
		)
	if overshoot.x > 0:
		new_background.position.x = - overshoot.x * 0.5
	if overshoot.y > 0:
		new_background.position.y = - overshoot.y * 0.5
	
	
	
	for old_node : Node in old_backgrounds:
		var fade_tween := get_tree().create_tween()
		fade_tween.tween_property(old_node, "modulate:a", 0.0, fade_time)
		fade_tween.finished.connect(old_node.queue_free)
	
	background = new_bg_key
	return false


var control_tween
func _on_line_reader_start_accepting_advance() -> void:
	if control_tween:
		control_tween.kill()
	var controls : Control = find_child("ControlsContainer")
	control_tween = create_tween()
	control_tween.tween_property(controls, "modulate:a", 1, 1)
	
	Options.save_gamestate()


func _on_line_reader_stop_accepting_advance() -> void:
	if control_tween:
		control_tween.kill()
	var controls : Control = find_child("ControlsContainer")
	control_tween = create_tween()
	control_tween.tween_property(controls, "modulate:a", 0, 1)

func get_screen_container() -> Control:
	return find_child("ScreenContainer")


func _on_android_hack_button_pressed() -> void:
	var e = InputEventKey.new()
	attempt_advance(e)


func on_actor_name_changed(
	actor: String,
	name_container_visible: bool
	):
		actor_name = actor
		is_name_container_visible = name_container_visible
		return

func _on_body_label_meta_hover_started(_meta: Variant) -> void:
	meta_blocker = true

func _on_body_label_meta_hover_ended(_meta: Variant) -> void:
	meta_blocker = false


func _on_body_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))


func play_sfx(_name:String):
	Sound.play_sfx(_name)
	return false

func set_bgm(_name:String, fade_in:float):
	Sound.play_bgm(_name, fade_in)
	return false


func chapter_break(
	new_background : String,
	new_bgm : String,
	transition_time := 0.0
):
	Sound.switch_to(new_bgm)
	set_background(new_background, transition_time)
	
	var callback_timer := get_tree().create_timer(transition_time)
	callback_timer.timeout.connect(Parser.function_acceded)
	return true

#func black_fade(fade_in:float, hold_time:float, fade_out:float, hide_characters:bool, new_background:="none", new_bgm:="none"):
	#var bg = new_background
	#if new_background == "none":
		#bg = background
	#
	#var bgm = new_bgm
	#if new_bgm == "none":
		#bgm = Sound.bgm_key
	#
	#%BlackFade.start(fade_in,
	#hold_time,
	#fade_out,
	#hide_characters,
	#bg,
	#bgm,
	#)
	#return true


func hide_all_characters() -> bool:
	for character: Character in get_tree().get_nodes_in_group("character"):
		character.visible = false
	return false


func zoom_to(value : float, duration : float) -> bool:
	camera.zoom_to(value, duration)
	return false

func splatter_blood(amount) -> bool:
	for i in int(amount):
		var sprite := preload("res://game/visuals/vfx/splatter/blood_splatter.tscn").instantiate()
		find_child("VFXLayer").add_child(sprite)
	return false

func set_emotion(character_name: String, emotion_name: String) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == character_name:
			character.set_emotion(emotion_name)
	return false

func show_character(character_name: String, clear_others: bool) -> bool:
	for character : Character in get_tree().get_nodes_in_group("character"):
		if character.character_name == character_name:
			character.visible = true
		elif clear_others:
			character.visible = false
	return false


func shake_camera(strength:float) -> bool:
	camera.apply_shake(strength)
	return false


func set_x_position(character_name: String, index:int, time:float, wait_for_reposition:bool) -> bool:
	if Game.game_stage:
		var character : Character = Game.game_stage.get_character(character_name)
		@warning_ignore("narrowing_conversion")
		character.set_x_position(int(index), time, wait_for_reposition)
	return wait_for_reposition


func sway_camera(intensity : float) -> bool:
	camera.set_sway_intensity(intensity)
	return false

func move_camera_to(x: float, y: float, duration: float) -> bool:
	camera.move_to(x, y, duration)
	return false


func control_camera(zoom : float, x : float, y : float, duration : float) -> bool:
	zoom_to(zoom, duration)
	move_camera_to(x, y, duration)
	return false

func roll_credits() -> bool:
	find_child("RollingCredits").start()
	return true

func set_character_name(character: String, new_name: String) -> bool:
	if Parser.line_reader:
		Parser.line_reader.set_actor_name(character, new_name)
	return false

func use_ui(id: float) -> bool:
	Game.game_stage.use_ui(int(id))
	return false
