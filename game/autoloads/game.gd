extends Node

var start_data : GameStartData
var screen := ""
var pause_state_before_open:bool
var camera : GameCamera

@export_group("Screen Fade", "screen_fade_")
@export_exp_easing("positive_only") var screen_fade_in := 1.0
@export_exp_easing("positive_only") var screen_fade_out := 0.5

var screenshot_to_save:Image
var game_stage : GameStage

@export var creating_slideshow := false
@export var performance_test := false

var fov_before_screen : float
var just_ended := false


var release:bool:
	get():
		return OS.has_feature("release") or OS.has_feature("mobile")


func _ready():
	if release:
		creating_slideshow = false
		screen_fade_in = 1
		screen_fade_out = 0.5
	set_screen("")
	
	Game.hook_up_button_sfx(self)
	ParserEvents.page_terminated.connect(func(number : int):
		if number == Parser.get_page_count() -1:
			just_ended = true
		)
	
	# mobile back button
	get_tree().get_root().connect("go_back_requested", func():
		if screen.is_empty():
			set_screen(CONST.SCREEN_OPTIONS)
		else:
			set_screen("")
			)
	
	%PreviewLabel.visible = performance_test
	
	EventBus.settings_changed.connect(on_settings_changed)
	on_settings_changed()
	#if performance_test:
		#Parser.page_finished.connect(func(index:int):
			#if index == 3:
				#%PreviewLabel.text = "[font_size=200]OK THATS IT BYE[/font_size]"
				#var t = get_tree().create_timer(5)
				#t.timeout.connect(get_tree().quit)
			#)


func on_settings_changed():
	%FPSLabel.visible = Options.fps_counter_visible

func set_screen(screen_path:String, payload := {}) -> Screen:
	var old_screen := screen
	if is_instance_valid(Parser.line_reader):
		if Parser.line_reader.is_executing:
			return null
	
	#if Overlay.playing:
		#return null
	
	if screen.is_empty():
		pause_state_before_open = Parser.paused
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	
	if screen_path.is_empty():
		Parser.set_paused(pause_state_before_open)
		if screen_fade_out == 0 or %ScreenContainer.get_child_count() == 0:
			for c in %ScreenContainer.get_children():
				c.queue_free()
			%ScreenContainer.visible = false
			if is_instance_valid(game_stage):
				game_stage.screen_close_blocker = false
		else:
			var tween
			for c in %ScreenContainer.get_children():
				var t = create_tween()
				t.tween_property(c, "modulate:a", 0, screen_fade_out)
				t.set_ease(Tween.EASE_OUT_IN)
				t.finished.connect(c.queue_free)
				if is_instance_valid(game_stage):
					t.finished.connect(game_stage.set.bind("screen_close_blocker", false))
				tween = t
			tween.finished.connect(%ScreenContainer.set_visible.bind(false))
		screen = screen_path
		EventBus.screen_changed.emit(old_screen, screen)
		return null
	else:
		if camera:
			fov_before_screen = camera.fov
		for c : Screen in %ScreenContainer.get_children():
			c.queue_free()
	
	if SceneLoader.current_scene == GameStage.PATH and screen.is_empty():
		grab_thumbnail_screenshot()
	
	var new_screen = load(str(CONST.SCREEN_ROOT, screen_path)).instantiate()
	
	match screen_path:
		CONST.SCREEN_SAVE:
			if payload.get("save", false):
				new_screen.button_mode = SaveScreen.ButtonMode.Save
		CONST.SCREEN_NOTICE:
			new_screen.handle_payload(payload)
	
	if screen_fade_in > 0:
		new_screen.modulate.a = 0
	%ScreenContainer.add_child(new_screen)
	if screen_fade_in > 0:
		var t = create_tween()
		t.tween_property(new_screen, "modulate:a", 1, screen_fade_in)
		t.set_ease(Tween.EASE_OUT_IN)
	%ScreenContainer.visible = true
	screen = screen_path
	Game.hook_up_button_sfx(new_screen)
	
	EventBus.screen_changed.emit(old_screen, screen)
	if camera:
		get_tree().process_frame.connect(camera.set.bind("fov", fov_before_screen), CONNECT_ONE_SHOT)
	return new_screen


func hook_up_button_sfx(start_node:Node):
	if start_node is Button and start_node.name != "AndroidHackButton":
		start_node.mouse_entered.connect(Sound.play_sfx.bind("ui_hover", true, "UI"))
		start_node.focus_entered.connect(Sound.play_sfx.bind("ui_hover", true, "UI"))
		start_node.pressed.connect(Sound.play_sfx.bind("ui_click", true, "UI"))
	for child in start_node.get_children():
		hook_up_button_sfx(child)


func grab_thumbnail_screenshot():
	screenshot_to_save = get_viewport().get_texture().get_image()
	var s = Options.get_save_thumbnail_size()
	screenshot_to_save.resize(s.x, s.y)



func _process(_delta: float) -> void:
	%FPSLabel.text = str(Engine.get_frames_per_second())


func str_to_vec2(s) -> Vector2:
	if s is Vector2:
		return s
	if not s is String:
		return Vector2.ZERO
	s = s.replace("(", "")
	s = s.replace(")", "")
	
	var segments = s.split(",")
	
	return Vector2(float(segments[0]), float(segments[1]))
