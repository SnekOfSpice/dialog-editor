extends Node2D

@export var character_name := ""

func _ready():
	ParserEvents.dialog_line_args_passed.connect(on_dialog_line_args_passed)

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

func set_emotion(emotion:String):
	visible = true
	$Sprite2D.texture = load(str("res://sample/diisis_intro/characters/sprites/", character_name, "-", emotion, ".png"))