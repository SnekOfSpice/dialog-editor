extends Control
class_name StageRoot

var stage := ""
var screen := ""

func _ready():
	change_stage(CONST.STAGE_MAIN)
	set_screen("")
	GameWorld.stage_root = self

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and $ScreenContainer.get_child_count() == 0:
		set_screen(CONST.SCREEN_OPTIONS)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and $ScreenContainer.get_child_count() == 0:
		set_screen(CONST.SCREEN_OPTIONS)

func set_screen(screen_path:String):
	if Parser.line_reader:
		if Parser.line_reader.is_input_locked:
			return
	if screen_path.is_empty():
		for c in $ScreenContainer.get_children():
			c.queue_free()
		$ScreenContainer.visible = false
		return
	var new_stage = load(str(CONST.SCREEN_ROOT, screen_path)).instantiate()
	$ScreenContainer.add_child(new_stage)
	$ScreenContainer.visible = true
	screen = screen_path

func set_background(background:String, fade_time:=0.0):
	var new_background:Node
	var old_backgrounds:=$Background.get_children()
	if background.ends_with(".png"):
		new_background = Sprite2D.new()
		new_background.texture = load(str(CONST.BACKGROUND_ROOT, background))
		new_background.centered = false
	elif background.ends_with(".tscn"):
		new_background = load(str(CONST.BACKGROUND_ROOT, background)).instantiate()
	else:
		push_error(str("Background ", background, " does not end in .png or .tscn."))
		return
	new_background.modulate.a = 0.0
	$Background.add_child(new_background)
	
	var fade_tween := get_tree().create_tween()
	fade_tween.tween_property(new_background, "modulate:a", 1.0, fade_time)
	for old_node : Node in old_backgrounds:
		fade_tween.finished.connect(old_node.queue_free)
	
	GameWorld.background = background

func new_gamestate():
	game_start_callable = Parser.reset_and_start
	change_stage(CONST.STAGE_GAME)
	#Parser.reset_and_start()

func load_gamestate():
	game_start_callable = Options.load_gamestate
	change_stage(CONST.STAGE_GAME)
	#Options.load_gamestate()
	#Parser.paused = false

var game_start_callable:Callable
func change_stage(stage_path:String):
	var new_stage = load(str(CONST.STAGE_ROOT, stage_path)).instantiate()
	
	if stage_path == CONST.STAGE_GAME:
		new_stage.callable_upon_blocker_clear = game_start_callable
	
	for child in $StageContainer.get_children():
		if new_stage != child:
			child.queue_free()
	$StageContainer.add_child(new_stage)
	
	
	match stage_path:
		CONST.STAGE_MAIN:
			new_stage.start_game.connect(new_gamestate)
			new_stage.load_game.connect(load_gamestate)
		#CONST.STAGE_GAME:
			#new_stage.blockers_cleared.connect(game_start_callable)
	
	stage = stage_path
	set_screen("")
