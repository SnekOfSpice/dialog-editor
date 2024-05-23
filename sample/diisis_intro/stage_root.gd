extends Control

func _ready():
	change_stage(CONST.STAGE_GAME)
	

func change_stage(stage_path:String):
	
	var new_stage = load(stage_path).instantiate()
	$StageContainer.add_child(new_stage)
	for child in $StageContainer.get_children():
		if new_stage != child:
			child.queue_free()
