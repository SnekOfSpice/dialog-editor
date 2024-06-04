extends Control
class_name GameStage

@onready var characters := {
	CONST.CHARACTER_AMBER : $Characters/Amber,
	CONST.CHARACTER_ETERNA : $Characters/Eterna,
}

var dialog_box_tween : Tween
var dialog_box_offset := Vector2.ZERO
var actor_name := ""
var is_name_container_visible := false

@onready var cg_roots := [find_child("CGBottomContainer"), find_child("CGTopContainer")]
var blockers := 3

func _ready():
	#find_child("TextContainer").position = Vector2(size.x * 0.5, size.y - find_child("TextContainer").size.y * 0.5)
	ParserEvents.actor_name_changed.connect(on_actor_name_changed)
	ParserEvents.text_content_text_changed.connect(on_text_content_text_changed)
	
	GameWorld.instruction_handler = $Handler
	GameWorld.game_stage = self
	
	remove_blocker()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		for root in cg_roots:
			if root.visible and emit_insutrction_complete_on_cg_hide:
				hide_cg()
				return
		$LineReader.request_advance()

func show_ui():
	find_child("VNUI").visible = true

func hide_ui():
	find_child("VNUI").visible = false

func set_cg(cg_name:String, fade_in_duration:float, cg_node:TextureRect):
	var cg_root : Control = cg_node.get_parent()
	cg_root.modulate.a = 0.0
	cg_root.visible = true
	
	cg_node.texture = load(str("res://sample/diisis_intro/cg/", cg_name, ".png"))
	var t = create_tween()
	t.tween_property(cg_root, "modulate:a", 1.0, fade_in_duration)

func set_cg_top(cg_name:String, fade_in_duration:float):
	set_cg(cg_name, fade_in_duration, find_child("CGTopContainer").get_node("CGTex"))

func set_cg_bottom(cg_name:String, fade_in_duration:float):
	set_cg(cg_name, fade_in_duration, find_child("CGBottomContainer").get_node("CGTex"))

func hide_cg():
	for cg_root : Control in cg_roots:
		cg_root.visible = false
		cg_root.modulate.a = 0.0
		if emit_insutrction_complete_on_cg_hide:
			GameWorld.instruction_handler.instruction_completed.emit()

func on_actor_name_changed(
	actor_name: String,
	is_name_container_visible: bool
	):
		self.actor_name = actor_name
		self.is_name_container_visible = is_name_container_visible
		return
		
func on_text_content_text_changed(
	old_text: String,
	new_text: String,
	lead_time: float,
):
	pass
	## move to neutral position if not visible
	## move to actor if visible
	#if is_name_container_visible:
		#if actor_name == CONST.CHARACTER_AMBER:
			#dialog_box_offset = Vector2(-20, -10)
		#elif actor_name == CONST.CHARACTER_ETERNA:
			#dialog_box_offset = Vector2(20, -10)
	#else:
		#dialog_box_offset = Vector2.ZERO
	#
	#if dialog_box_tween:
		#dialog_box_tween.kill()
	#dialog_box_tween = create_tween()
	#
	#var text_container : CenterContainer = find_child("TextContainer")
	#var target_position = Vector2(size.x * 0.5, size.y - text_container.size.y * 0.5)
	#target_position += dialog_box_offset
	#dialog_box_tween.tween_property(text_container, "position", target_position, lead_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func remove_blocker():
	blockers -= 1
	if blockers <= 0:
		Parser.reset_and_start(0)

var emit_insutrction_complete_on_cg_hide :bool
func _on_handler_show_cg(cg_name: String, fade_in: float, on_top: bool) -> void:
	if on_top:
		emit_insutrction_complete_on_cg_hide = true
		
		set_cg_top(cg_name, fade_in)
	else:
		var handler : InstructionHandler = GameWorld.instruction_handler
		var t = get_tree().create_timer(fade_in)
		t.timeout.connect(handler.instruction_completed.emit)
		
		set_cg_bottom(cg_name, fade_in)


func _on_history_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_HISTORY)
