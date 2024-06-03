extends Control
class_name StageRoot

func _ready():
	change_stage(CONST.STAGE_GAME)
	set_screen("")
	GameWorld.stage_root = self

func set_screen(screen_path:String):
	if screen_path.is_empty():
		for c in $ScreenContainer.get_children():
			c.queue_free()
		$ScreenContainer.visible = false
		return
	var new_stage = load(screen_path).instantiate()
	$ScreenContainer.add_child(new_stage)
	$ScreenContainer.visible = true
	

func set_background(background:String, fade_time:=0.0):
	var new_background:Node
	var old_backgrounds:=$Background.get_children()
	if background.ends_with(".png"):
		new_background = Sprite2D.new()
		new_background.texture = load(background)
		new_background.centered = false
	elif background.ends_with(".tscn"):
		new_background = load(background).instantiate()
	new_background.modulate.a = 0.0
	$Background.add_child(new_background)
	
	var fade_tween := get_tree().create_tween()
	fade_tween.tween_property(new_background, "modulate:a", 1.0, fade_time)
	for old_node : Node in old_backgrounds:
		fade_tween.finished.connect(old_node.queue_free)

func change_stage(stage_path:String):
	var new_stage = load(stage_path).instantiate()
	$StageContainer.add_child(new_stage)
	for child in $StageContainer.get_children():
		if new_stage != child:
			child.queue_free()
