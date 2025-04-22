extends Node


var stage_root: StageRoot
var game_stage: GameStage
var instruction_handler: InstructionHandler

var camera : GameCamera

var background := ""

var skip := false
var just_started := true

func str_to_vec2(s) -> Vector2:
	if s is Vector2:
		return s
	if not s is String:
		return Vector2.ZERO
	s = s.replace("(", "")
	s = s.replace(")", "")
	
	var segments = s.split(",")
	
	return Vector2(float(segments[0]), float(segments[1]))

func serialize():
	var result := {}
	result["background"] = background
	result["game_stage"] = game_stage.serialize()
	return result

func deserialize(data:Dictionary):
	if game_stage:
		stage_root.set_background(data.get("background", ""))
		game_stage.deserialize(data.get("game_stage", {}))
	else:
		print("game stage not set for gameworld deserialization")

func hide_all_characters():
	for character : Character in get_tree().get_nodes_in_group("character"):
		character.set_invisible()
