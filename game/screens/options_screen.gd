extends Screen

var pause_state_before_open:bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	pause_state_before_open = Parser.paused
	Parser.set_paused(true)
	
	find_child("QuitButton").visible = not OS.has_feature("web")
	#find_child("GameButton").visible = GameWorld.stage_root.stage != CONST.STAGE_MAIN
	#find_child("GameMenu").visible = GameWorld.stage_root.stage != CONST.STAGE_MAIN
	
	find_child("TextSpeedSlider").max_value = LineReader.MAX_TEXT_SPEED
	find_child("TextSpeedSlider").value = Options.text_speed
	find_child("AutoContinueCheckBox").button_pressed = Options.auto_continue
	find_child("AutoDelaySlider").value = Options.auto_continue_delay
	
	_on_auto_continue_check_box_pressed()
	_on_text_speed_slider_value_changed(Options.text_speed)
	_on_auto_delay_slider_value_changed(Options.auto_continue_delay)
	
	find_child("FullscreenCheckBox").button_pressed = Options.fullscreen
	
	find_child("MasterVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	find_child("MusicVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	find_child("SFXVolumeSlider").value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	set_menu(0)
	set_menu_available(0, GameWorld.stage_root.stage != CONST.STAGE_MAIN)


func close():
	Options.save_prefs()
	Parser.set_paused(pause_state_before_open)
	super.close()

func _input(event: InputEvent) -> void:
	super(event)

# hide menu 0 if coming from main menu stage
func set_menu_available(menu:int, available:bool):
	if available:
		find_child("OptionMenusButtonContainer").get_child(menu).visible = true
		return
	
	if find_child("OptionMenusContainer").get_child(menu).visible:
		if menu == find_child("OptionMenusContainer").get_child_count() - 1:
			set_menu(0)
		else:
			set_menu(menu + 1)
	find_child("OptionMenusButtonContainer").get_child(menu).visible = false

func set_menu(menu:int):
	find_child("OptionMenusButtonContainer").get_child(menu).grab_focus()
	for child in find_child("OptionMenusContainer").get_children():
		child.visible = child.get_index() == menu


func _on_master_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(find_child("MasterVolumeSlider").value)
	)



func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(find_child("MusicVolumeSlider").value)
	)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(find_child("SFXVolumeSlider").value)
	)


func _on_save_button_pressed() -> void:
	Options.save_gamestate()
	Options.save_prefs()


func _on_main_menu_button_pressed() -> void:
	if GameWorld.stage_root.stage == CONST.STAGE_GAME:
		Options.save_gamestate()
	GameWorld.stage_root.change_stage(CONST.STAGE_MAIN)


func _on_auto_continue_check_box_pressed() -> void:
	var check_box : CheckBox = find_child("AutoContinueCheckBox")
	find_child("AutoDelaySlider").visible = check_box.button_pressed
	find_child("AutoDelayLabel").visible = check_box.button_pressed
	
	Options.auto_continue = check_box.button_pressed
	if is_instance_valid(Parser.line_reader):
		Parser.line_reader.auto_continue = check_box.button_pressed


func _on_text_speed_slider_value_changed(value: float) -> void:
	var label : Label = find_child("TextSpeedValueLabel")
	if value == LineReader.MAX_TEXT_SPEED:
		label.text = "Instant"
	else:
		label.text = str(value)
	Options.text_speed = int(value)
	if is_instance_valid(Parser.line_reader):
		Parser.line_reader.text_speed = value


func _on_auto_delay_slider_value_changed(value: float) -> void:
	var label : Label = find_child("AutoDelayLabel")
	label.text = str(value, " s")
	Options.auto_continue_delay = value
	if is_instance_valid(Parser.line_reader):
		Parser.line_reader.auto_continue_delay = value


func _on_fullscreen_check_box_pressed() -> void:
	Options.set_fullscreen(find_child("FullscreenCheckBox").button_pressed)


func _on_quit_button_pressed() -> void:
	if GameWorld.stage_root.stage == CONST.STAGE_GAME:
		Options.save_gamestate()
	Options.save_prefs()
	get_tree().quit()
