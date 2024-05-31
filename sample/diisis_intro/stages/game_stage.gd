extends Control

@onready var characters := {
	CONST.CHARACTER_AMBER : $Characters/Amber,
	CONST.CHARACTER_ETERNA : $Characters/Eterna,
}

var dialog_box_tween : Tween
var dialog_box_offset := Vector2.ZERO
var actor_name := ""
var is_name_container_visible := false

var blockers := 3

func _ready():
	#find_child("TextContainer").position = Vector2(size.x * 0.5, size.y - find_child("TextContainer").size.y * 0.5)
	ParserEvents.actor_name_changed.connect(on_actor_name_changed)
	ParserEvents.text_content_text_changed.connect(on_text_content_text_changed)
	
	GameWorld.instruction_handler = $Handler
	
	remove_blocker()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		$LineReader.request_advance()


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



#
#func _process(delta):
	#$Icon.global_position = find_child("TextContentLabel").global_position

func remove_blocker():
	blockers -= 1
	if blockers <= 0:
		Parser.reset_and_start(0)
		print("start")
