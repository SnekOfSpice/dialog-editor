extends Control
class_name StageRoot

var stage := ""
var screen := ""

var screenshot_to_save:Image

func _ready():
	change_stage(CONST.STAGE_MAIN)
	set_screen("")
	GameWorld.stage_root = self

func set_screen(screen_path:String, payload := {}):
	if is_instance_valid(Parser.line_reader):
		if Parser.line_reader.is_input_locked:
			return
	
	if stage == CONST.STAGE_GAME:
		screenshot_to_save = get_viewport().get_texture().get_image()
		var s = Options.get_save_thumbnail_size()
		screenshot_to_save.resize(s.x, s.y)
	
	var screen_container:Control
	if (null if not is_instance_valid(GameWorld.camera) else GameWorld.camera) is GameCamera:
		screen_container = GameWorld.camera.get_screen_container()
	else:
		screen_container = find_child("ScreenContainer")
	
	if screen_path.is_empty():
		for c in screen_container.get_children():
			c.queue_free()
		screen_container.visible = false
		#if $StageContainer.get_child_count() > 0:
			#$StageContainer.get_child(0).grab_focus()
		screen = screen_path
		return
	var new_stage = load(str(CONST.SCREEN_ROOT, screen_path)).instantiate()
	
	match screen_path:
		CONST.SCREEN_NOTICE:
			new_stage.handle_payload(payload)
	
	screen_container.add_child(new_stage)
	screen_container.visible = true
	screen = screen_path

func set_background(background:String, fade_time:=0.0):
	if background == "none" or background == "null" or background.is_empty():
		background = GameWorld.background
	var path = CONST.fetch("BACKGROUND", background)
	if not path:
		push_warning(str("COULDN'T FIND BACKGROUND ", background, "!"))
		return
	var new_background:Node2D
	var old_backgrounds:=$Background.get_children()
	if path.ends_with(".png") or path.ends_with(".jpg") or path.ends_with(".jpeg"):
		new_background = Sprite2D.new()
		new_background.texture = load(path)
		
		new_background.centered = false
	
	elif path.ends_with(".tscn"):
		new_background = load(path).instantiate()
	else:
		push_error(str("Background ", background, " does not end in .png, .jpg, .jpeg or .tscn."))
		return
	
	$Background.add_child(new_background)
	$Background.move_child(new_background, 0)
	
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
	
	GameWorld.background = background
	
	if is_instance_valid(GameWorld.game_stage):
		GameWorld.game_stage.get_node("Objects").hide_all()
		

func new_gamestate():
	game_start_callable = Parser.reset_and_start
	change_stage(CONST.STAGE_GAME)


func load_gamestate():
	game_start_callable = Options.load_gamestate
	change_stage(CONST.STAGE_GAME)

func start_epilogue():
	game_start_callable = Parser.read_page_by_key.bind("epilogue")
	change_stage(CONST.STAGE_GAME)

var game_start_callable:Callable
func change_stage(stage_path:String):
	await get_tree().process_frame
	
	set_screen("")
	for c in $Background.get_children():
		c.queue_free()
	var new_stage = load(str(CONST.STAGE_ROOT, stage_path)).instantiate()
	
	if stage_path == CONST.STAGE_GAME:
		new_stage.callable_upon_blocker_clear = game_start_callable
	
	for child in $StageContainer.get_children():
		if new_stage != child:
			child.queue_free()
	
	
	match stage_path:
		CONST.STAGE_MAIN:
			new_stage.start_game.connect(new_gamestate)
			new_stage.load_game.connect(load_gamestate)
			new_stage.start_epilogue.connect(start_epilogue)
		#CONST.STAGE_GAME:
			#new_stage.blockers_cleared.connect(game_start_callable)
	
	$StageContainer.add_child(new_stage)
	
	stage = stage_path

func get_stage_node() -> Node:
	return $StageContainer.get_child(0)
	
