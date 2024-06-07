extends Node


var stage_root: StageRoot
var game_stage: GameStage
var instruction_handler: InstructionHandler

var background := ""


func serialize():
	var result := {}
	result["background"] = background
	result["game_stage"] = game_stage.serialize()
	return result

func deserialize(data:Dictionary):
	if game_stage:
		stage_root.set_background(data.get("background", CONST.BACKGROUND_WORKSHOP))
		game_stage.deserialize(data.get("game_stage", {}))
	else:
		print("game stage not set for gameworld deserialization")
