extends Screen

@onready var rtl : RichTextLabel = find_child("RTLFontLabel")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	Parser.set_paused(true)
	
	find_child("QuitButton").visible = not OS.has_feature("web")
	#find_child("GameButton").visible = GameWorld.stage_root.stage != CONST.STAGE_MAIN
	#find_child("GameMenu").visible = GameWorld.stage_root.stage != CONST.STAGE_MAIN
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
	
	%CurrentSlotLabel.text = "Using Slot %s" % (Options.save_slot + 1)
	%SaveHintLabel.modulate.a = 0
	#for font in Style.LABEL_FONTS:
		#var loaded : Font = load(font)
		#find_child("LabelFontOptionButton").add_item(loaded.get_font_name())
	#find_child("LabelFontOptionButton").select(Options.font_prefs.get("label_font", 0))
	#for family : Dictionary in Style.RICH_TEXT_LABEL_FONTS:
		#var loaded : Font = load(family.get("normal_font"))
		#find_child("RTLFontOptionButton").add_item(loaded.get_font_name())
	#find_child("RTLFontOptionButton").select(Options.font_prefs.get("rich_text_label_font", 0))
	#find_child("LabelFontSizeSlider").value = theme.get_font_size("font_size", "Label")
	#find_child("LabelFontSizeLabel").text = str(int(find_child("LabelFontSizeSlider").value))
	#find_child("RTLFontSizeSlider").value = theme.get_font_size("normal_font_size", "RichTextLabel")
	#find_child("RTLFontSizeLabel").text = str(int(find_child("RTLFontSizeSlider").value))
	
	set_menu(0)
	find_child("SaveContainer").visible = GameWorld.stage_root.stage != CONST.STAGE_MAIN
	

func close():
	Options.save_prefs()
	super.close()

func _input(event: InputEvent) -> void:
	super(event)

var restart_preview_timer := 0.0
func _process(delta: float) -> void:
	if not find_child("TextMenu").visible:
		return
	var slider_value : float = find_child("TextSpeedSlider").value
	if rtl.visible_ratio == 1:
		if slider_value == LineReader.MAX_TEXT_SPEED:
			return
		restart_preview_timer -= delta
		if restart_preview_timer <= 0:
			restart_preview_timer = get_restart_preview_timer_duration()
			rtl.visible_ratio = 0
	else:
		# just taken directly from line reader
		rtl.visible_ratio += (float(slider_value) / rtl.get_parsed_text().length()) * delta

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
		find_child("RTLFontLabel").visible_ratio = 1
	else:
		label.text = str(int(value))
		find_child("RTLFontLabel").visible_ratio = 0
		restart_preview_timer = get_restart_preview_timer_duration()
	Options.text_speed = int(value)
	if is_instance_valid(Parser.line_reader):
		Parser.line_reader.text_speed = value

func get_restart_preview_timer_duration() -> float:
	if find_child("AutoContinueCheckBox").button_pressed:
		return find_child("AutoDelaySlider").value
	else:
		return 4

func _on_auto_delay_slider_value_changed(value: float) -> void:
	var label : Label = find_child("AutoDelayLabel")
	label.text = str(value, " s")
	Options.auto_continue_delay = value
	if is_instance_valid(Parser.line_reader):
		Parser.line_reader.auto_continue_delay = value
	if value == LineReader.MAX_TEXT_SPEED:
		find_child("RTLFontLabel").visible_ratio = 1
	else:
		find_child("RTLFontLabel").visible_ratio = 0
	restart_preview_timer = get_restart_preview_timer_duration()


func _on_fullscreen_check_box_pressed() -> void:
	Options.set_fullscreen(find_child("FullscreenCheckBox").button_pressed)


func _on_quit_button_pressed() -> void:
	if GameWorld.stage_root.stage == CONST.STAGE_GAME:
		Options.save_gamestate()
	Options.save_prefs()
	get_tree().quit()


func _on_label_font_size_slider_value_changed(value: float) -> void:
	find_child("LabelFontSizeLabel").text = str(int(value))


func _on_reset_label_font_size_button_pressed() -> void:
	pass
	#find_child("LabelFontSizeSlider").value = Style.DEFAULT_LABEL_FONT_SIZE
	#Style.set_label_font_size(Style.DEFAULT_LABEL_FONT_SIZE)


func _on_label_font_size_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		pass
	#Style.set_label_font_size(find_child("LabelFontSizeSlider").value)


func _on_rtl_font_size_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		pass
	#Style.set_rich_text_label_font_size(find_child("RTLFontSizeSlider").value)


func _on_rtl_font_size_slider_value_changed(value: float) -> void:
	find_child("RTLFontSizeLabel").text = str(int(value))

func _on_reset_rtl_font_size_button_pressed() -> void:
	pass
	#find_child("RTLFontSizeSlider").value = Style.DEFAULT_RTL_FONT_SIZE
	#Style.set_rich_text_label_font_size(Style.DEFAULT_RTL_FONT_SIZE)



func _on_save_to_slot_button_pressed() -> void:
	GameWorld.stage_root.set_screen(CONST.SCREEN_SAVE, {"save" : true})


func show_save_hint():
	%SaveHintLabel.modulate.a = 1

func hide_save_hint():
	%SaveHintLabel.modulate.a = 0
