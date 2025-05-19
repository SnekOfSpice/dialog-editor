extends Control
class_name GameStage

@onready var characters := {}

enum TextStyle {
	ToBottom,
	ToCharacter,
}

@export var text_style := TextStyle.ToBottom
@export var stylebox_regular : StyleBox
@export var stylebox_cg : StyleBox

@onready var line_reader : LineReader = find_child("LineReader")

var dialog_box_tween : Tween
var dialog_box_offset := Vector2.ZERO
var actor_name := ""
var cg := ""
var cg_position := ""
var base_cg_offset : Vector2
var is_name_container_visible := false
var hovering_meta := false

@onready var text_container_custom_minimum_size : Vector2 = find_child("TextContainer1").custom_minimum_size
@onready var rtl_custom_minimum_size : Vector2 = find_child("BodyLabel").custom_minimum_size

@onready var cg_roots := [find_child("CGBottomContainer"), find_child("CGTopContainer")]
@onready var text_start_position = find_child("TextContainer1").position

var ui_id := 1
@onready var ui_root : Control = find_child(str("TextContainer", ui_id))

var callable_upon_blocker_clear:Callable

@onready var camera = $Camera2D
@onready var overlay_static = find_child("Static").get_node("ColorRect")
@onready var overlay_fade_out = find_child("FadeOut").get_node("ColorRect")
@onready var overlay_orgasm = find_child("Orgasm").get_node("ColorRect")


@onready var orgasm_mat = overlay_orgasm.get_material()
@onready var fade_mat = overlay_fade_out.get_material()
@onready var static_mat = overlay_static.get_material()

var target_lod := 0.0
var target_mix := 0.0
var target_static := 0.0

func _ready():
	use_ui(1)
	find_child("StartCover").visible = true
	ParserEvents.actor_name_changed.connect(on_actor_name_changed)
	ParserEvents.body_label_text_changed.connect(on_body_label_text_changed)
	ParserEvents.page_terminated.connect(go_to_main_menu)
	ParserEvents.instruction_started.connect(on_instruction_started)
	ParserEvents.instruction_completed.connect(on_instruction_completed)
	ParserEvents.read_new_line.connect(on_read_new_line)
	
	GameWorld.game_stage = self
	
	line_reader.auto_continue = Options.auto_continue
	line_reader.text_speed = Options.text_speed
	line_reader.auto_continue_delay = Options.auto_continue_delay
	
	set_text_style(text_style)
	
	for character in find_child("Characters").get_children():
		character.visible = false
	
	grab_focus()
	
	tree_exiting.connect(on_tree_exit)
	
	hide_cg()
	
	await get_tree().process_frame
	if callable_upon_blocker_clear:
		callable_upon_blocker_clear.call()
	else:
		Parser.reset_and_start()
	
	await get_tree().process_frame
	find_child("StartCover").visible = false

func on_read_new_line(_line_index:int):
	Options.save_gamestate()

func on_tree_exit():
	GameWorld.game_stage = null

func on_instruction_started(
	instruction_text : String,
	_delay : float,
):
	if instruction_text.begins_with("black_fade"):
		find_child("ControlsContainer").visible = false

func on_instruction_completed(
	instruction_text : String,
	_delay : float,
):
	if instruction_text.begins_with("black_fade"):
		find_child("ControlsContainer").visible = true

func go_to_main_menu(_unused):
	GameWorld.stage_root.change_stage(CONST.STAGE_MAIN)


func _process(_delta: float) -> void:
	fade_mat.set_shader_parameter("lod", lerp(fade_mat.get_shader_parameter("lod"), target_lod, 0.02))
	fade_mat.set_shader_parameter("mix_percentage", lerp(fade_mat.get_shader_parameter("mix_percentage"), target_mix, 0.02))
	
	static_mat.set_shader_parameter("intensity", lerp(static_mat.get_shader_parameter("intensity"), target_static, 0.02))
	static_mat.set_shader_parameter("border_size", lerp(static_mat.get_shader_parameter("border_size"), 1 - target_static, 0.02))
	
	orgasm_mat.set_shader_parameter("lod", lerp(orgasm_mat.get_shader_parameter("lod"), 0.0, 0.000175))
	
	find_child("VFXLayer").position = -camera.offset * camera.zoom.x

func cum(_voice:String):
	orgasm_mat.set_shader_parameter("lod", 1.8)
	
	get_tree().create_timer(1.5).timeout.connect(orgasm_mat.set_shader_parameter.bind("lod", 1.4))

func _unhandled_input(event: InputEvent) -> void:
	if not GameWorld.stage_root.screen.is_empty():
		return
	if event is InputEventKey:
		if event.pressed:
			if InputMap.action_has_event("ui_cancel", event):
				GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)
			if InputMap.action_has_event("screenshot", event):
				var screenshot := get_viewport().get_texture().get_image()
				var path := str("user://screenshot_", ProjectSettings.get_setting("application/config/name"), "_", Time.get_datetime_string_from_system().replace(":", "-"), ".png")
				screenshot.save_png(path)
				
				var notification_popup = preload("res://game/systems/notification.tscn").instantiate()
				var global_path := ProjectSettings.globalize_path(path)
				var global_dir := global_path.substr(0, global_path.rfind("/"))
				find_child("VNUIRoot").add_child(notification_popup)
				notification_popup.init(str("Saved to [url=", global_dir, "]", global_path, "[/url]"))
			if InputMap.action_has_event("toggle_auto_continue", event):
				line_reader.auto_continue = not line_reader.auto_continue
				Options.auto_continue = line_reader.auto_continue
			if InputMap.action_has_event("toggle_ui", event):
				if find_child("VNUI").visible:
					hide_ui()
				else:
					show_ui()
			if InputMap.action_has_event("cheats", event) and OS.has_feature("editor"):
				find_child("Cheats").visible = not find_child("Cheats").visible
				
	if event is InputEventMouse:
		if event.is_pressed() and InputMap.action_has_event("ui_cancel", event):
			GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)

	if event.is_action_pressed("advance"):
		for root in cg_roots:
			if root.visible and emit_insutrction_complete_on_cg_hide:
				hide_cg()
				return
		if not find_child("VNUI").visible:
			return
		if hovering_meta:
			return
		line_reader.request_advance()
	elif event.is_action_pressed("go_back"):
		line_reader.request_go_back()

func show_ui():
	if is_instance_valid(find_child("VNUI")):
		find_child("VNUI").visible = true

func hide_ui():
	find_child("VNUI").visible = false

func set_cg(cg_name:String, fade_in_duration:float, cg_root:Control):
	if stylebox_cg:
		var ui1panel : PanelContainer = find_child("TextContainer1").find_child("Panel")
		ui1panel.add_theme_stylebox_override("panel", stylebox_cg)
	
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
		cg_node = TextureRect.new()
		cg_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		cg_node.texture = load(cg_path)
	
	cg_root.add_child(cg_node)
	
	var t = create_tween()
	
	if cg_root.modulate.a == 1.0:
		cg_node.modulate.a = 0.0
		t.tween_property(cg_node, "modulate:a", 1.0, fade_in_duration)
	else:
		t.tween_property(cg_root, "modulate:a", 1.0, fade_in_duration)
	
	
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

func set_text_style(style:TextStyle):
	text_style = style
	if text_style == TextStyle.ToBottom:
		find_child("TextContainer1").custom_minimum_size = text_container_custom_minimum_size
		find_child("TextContainer1").position = text_start_position
		find_child("BodyLabel").custom_minimum_size = rtl_custom_minimum_size
	elif text_style == TextStyle.ToCharacter:
		find_child("TextContainer1").custom_minimum_size.x = 230
		find_child("BodyLabel").custom_minimum_size.x = 230

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
	
	if stylebox_regular:
		var ui1panel : PanelContainer = find_child("TextContainer1").find_child("Panel")
		ui1panel.add_theme_stylebox_override("panel", stylebox_regular)
	

func on_actor_name_changed(
	actor: String,
	name_container_visible: bool
	):
		actor_name = actor
		is_name_container_visible = name_container_visible
		return
		
func on_body_label_text_changed(
	_old_text: String,
	_new_text: String,
	lead_time: float,
):
	if text_style == TextStyle.ToBottom:
		return
	## move to neutral position if not visible
	## move to actor if visible
	var center = size * 0.5
	var actor_position:Vector2
	
	if is_name_container_visible:
		if not characters.get(actor_name):
			return
		actor_position = characters.get(actor_name).position
		var offset : int = sign(center.direction_to(actor_position).x) * 60
		actor_position.x -= offset
		if sign(offset) == 1:
			actor_position.x -= line_reader.text_container.size.x
		actor_position.y -= 100
	else: # name container isn't visible
		actor_position.x = center.x - line_reader.text_container.size.x * 0.5
		actor_position.y = size.y - line_reader.text_container.size.y - 60
	
	if dialog_box_tween:
		dialog_box_tween.kill()
	dialog_box_tween = create_tween()
	
	var text_container : CenterContainer = find_child("TextContainer1")
	text_container.position = actor_position
	text_container.position.y += 10
	dialog_box_tween.tween_property(text_container, "position", actor_position, lead_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

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
	result["text_container_position"] = find_child("TextContainer1").position
	result["text_style"] = text_style
	result["objects"] = $Objects.serialize()
	
	result["start_cover_visible"] = find_child("StartCover").visible
	result["static"] = overlay_static.get_material().get_shader_parameter("intensity")
	result["fade_out_lod"] = overlay_fade_out.get_material().get_shader_parameter("lod")
	result["fade_out_mix_percentage"] = overlay_fade_out.get_material().get_shader_parameter("mix_percentage")
	
	result["camera"] = $Camera2D.serialize()
	result["ui_id"] = ui_id
	result["ui_root_visible"] = ui_root.visible
	
	return result

func deserialize(data:Dictionary):
	var character_data : Dictionary = data.get("character_data", {})
	for character : Character in find_child("Characters").get_children():
		character.deserialize(character_data.get(character.character_name, {}))
	
	$Objects.deserialize(data.get("objects", {}))
	$Camera2D.deserialize(data.get("camera", {}))
	
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
	
	set_text_style(data.get("text_style", TextStyle.ToBottom))
	if text_style == TextStyle.ToCharacter:
		# gets deserialized as string for some reason??
		var fixed_position : Vector2
		var deserialized_position = data.get("text_container_position", find_child("TextContainer1").position)
		if deserialized_position is String:
			deserialized_position = deserialized_position.trim_prefix("(")
			deserialized_position = deserialized_position.trim_suffix(")")
			var parts = deserialized_position.split(",")
			fixed_position = Vector2(float(parts[0]), float(parts[1]))
		elif deserialized_position is Vector2:
			fixed_position = deserialized_position
		else:
			push_warning("Deserialized game_stage with something wild.")
			return
		find_child("TextContainer1").position = fixed_position
	
	target_lod = data.get("fade_out_lod", 0.0)
	target_mix = data.get("fade_out_mix_percentage", 0.0)
	overlay_fade_out.get_material().set_shader_parameter("lod", target_lod)
	overlay_fade_out.get_material().set_shader_parameter("mix_percentage", target_mix)
	
	target_static = data.get("static", 0.0)
	overlay_static.get_material().set_shader_parameter("intensity", target_static)
	overlay_static.get_material().set_shader_parameter("border_size", 1 - target_static)
	
	use_ui(data.get("ui_id", 1))
	base_cg_offset = GameWorld.str_to_vec2(data.get("base_cg_offset", Vector2.ZERO))
	ui_root.visible = data.get("ui_root_visible", true)

var emit_insutrction_complete_on_cg_hide :bool

func get_character(character_name:String) -> Character:
	for child : Character in $Characters.get_children():
		if child.character_name == character_name:
			return child
	return null

func _on_history_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_HISTORY)

func show_letter():
	hide_ui()
	var letter = preload("res://game/objects/letter.tscn").instantiate()
	add_child(letter)
	letter.position = Vector2(258, 8)

func _on_handler_start_show_cg(cg_name: String, fade_in: float, on_top: bool) -> void:
	if on_top:
		emit_insutrction_complete_on_cg_hide = true
		set_cg_top(cg_name, fade_in)
	else:
		var t = get_tree().create_timer(fade_in)
		t.timeout.connect(Parser.function_acceded)
		set_cg_bottom(cg_name, fade_in)

func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_menu_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_OPTIONS)

func _on_chapter_cover_chapter_intro_finished() -> void:
	Parser.function_acceded()
	find_child("ChapterCover").visible = false


func splatter(amount: int) -> void:
	for i in amount:
		var sprite := preload("res://game/visuals/vfx/splatter/blood_splatter.tscn").instantiate()
		find_child("VFXLayer").add_child(sprite)

func use_ui(id:int):
	var lr : LineReader = line_reader
	var root_existed : bool
	var body_label_text = lr.body_label.text
	var current_raw_name = lr.current_raw_name
	
	if ui_root:
		root_existed = true
	else:
		root_existed = false
	ui_id = id
	ui_root = find_child("TextContainer%s" % ui_id)
	for c in find_child("VNUI").get_children():
		if c.name.begins_with("TextContainer"):
			c.visible = c == ui_root
	
	lr.body_label = ui_root.find_child("BodyLabel")
	lr.text_container = ui_root
	lr.name_label = ui_root.find_child("NameLabel")
	lr.name_container = ui_root.find_child("NameContainer")
	lr.prompt_finished = ui_root.find_child("PageFinished")
	lr.prompt_unfinished = ui_root.find_child("PageUnfinished")
	
	if root_existed:
		lr.update_name_label(current_raw_name)
		lr.body_label.text = body_label_text

func set_static(level:float):
	target_static = level
	

func set_fade_out(lod:float, mix:float):
	target_lod = lod
	target_mix = mix

func _on_rich_text_label_meta_hover_ended(_meta: Variant) -> void:
	hovering_meta = false

func _on_rich_text_label_meta_hover_started(_meta: Variant) -> void:
	hovering_meta = true
