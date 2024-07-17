extends Node2D
class_name Character

@export var character_name := ""
var emotion := ""

func _ready():
	ParserEvents.dialog_line_args_passed.connect(on_dialog_line_args_passed)
	add_to_group("character")

func serialize() -> Dictionary:
	var result := {}
	
	result["visible"] = visible
	result["emotion"] = emotion
	
	return result

func deserialize(data: Dictionary):
	visible = data.get("visible")
	set_emotion(data.get("emotion"))

func on_dialog_line_args_passed(actor_name: String, dialog_line_args: Dictionary):
	var new_modulate:float
	if actor_name == character_name:
		new_modulate = 1.0
	else:
		new_modulate = 0.8
	modulate.v = new_modulate
	if dialog_line_args.has(str(character_name, "-emotion")):
		var emotion : String = dialog_line_args.get(str(character_name, "-emotion"))
		emotion = emotion.trim_suffix("-emotion")
		set_emotion(emotion)

func set_emotion(emotion_name:String):
	emotion = emotion_name
	visible = true
	$Sprite2D.texture = load(str("res://game/characters/sprites/", character_name, "-", emotion, ".png"))
