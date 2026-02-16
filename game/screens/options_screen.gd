extends Screen


func _ready() -> void:
	super()
	
	Parser.set_paused(true)
	
	find_child("QuitButton").visible = not OS.has_feature("web")
	find_child("TextSpeedSlider").value = Options.text_speed
	find_child("AutoContinueCheckBox").button_pressed = Options.auto_continue
	find_child("AutoDelaySlider").value = Options.auto_continue_delay
	
	%AutoContinueCheckBox.button_pressed = Options.auto_continue
	_on_auto_continue_check_box_toggled(Options.auto_continue)
	_on_text_speed_slider_drag_ended(false)
	_on_text_speed_slider_value_changed(Options.text_speed)
	%TextSpeedSlider.set_value_no_signal(Options.text_speed)
	_on_auto_delay_slider_value_changed(Options.auto_continue_delay)
	_on_auto_delay_slider_drag_ended(false)
	%AutoDelaySlider.set_value_no_signal(Options.auto_continue_delay)
	
	
	%VolumeSliderMaster.value = Options.get_volume("Master")
	%VolumeSliderMusic.value = Options.get_volume("Music")
	%VolumeSliderSFX.value = Options.get_volume("SFX")
	%VolumeSliderUI.value = Options.get_volume("UI")
	
	update_volume_labels()
	
	%CurrentSlotLabel.text = "Using Slot %s" % (Options.save_slot + 1)
	
	if OS.has_feature("mobile"):
		%SaveHintLabel.modulate.a = 1
	else:
		%SaveHintLabel.modulate.a = 0
	
	
	#%SFXDescriptionCheckBox.button_pressed = Options.sfx_description
	#%MusicDescriptionCheckBox.button_pressed = Options.music_description
	#%DitherCheckBox.button_pressed = Options.dither_enabled
	#%BlurCheckBox.button_pressed = Options.blur_enabled
	#%BloodCheckBox.button_pressed = Options.blood_enabled
	#%CRTCheckBox.button_pressed = Options.crt_enabled
	#%GlowCheckBox.button_pressed = Options.glow_enabled
	%FPSCounterCheckBox.button_pressed = Options.fps_counter_visible
	
	#%ShadowOptionButton.select(Options.shadow_quality_index)
	#%RenderingScaleOptionButton.select(Options.render_scale_index)
	#%ShowdownBackgroundCheckBox.button_pressed = Options.showdown_background_enabled
	#%SlideshowCheckBox.button_pressed = Options.slideshow_enabled
	
	%DesktopControls.visible = OS.has_feature("pc")
	%MobileControls.visible = OS.has_feature("mobile")
	%ScreenshotsContainer.visible = OS.has_feature("pc")
	
	set_menu(0)
	find_child("SaveContainer").visible = SceneLoader.in_game
	#%SlideshowInfoLabel.visible = not SceneLoader.in_game
	#%SlideshowPossibilityLabel.visible = SceneLoader.in_game
	#%SlideshowCheckBox.disabled = SceneLoader.in_game
	
	%WindowModeOptionButton.select(Options.window_mode_index)
	for idx in DisplayServer.get_screen_count():
		%ScreenOptionButton.add_item("Screen %s" % (idx + 1))
	%ScreenOptionButton.select(DisplayServer.window_get_current_screen())
	
	#EventBus.settings_changed.connect(on_settings_changed)
	#on_settings_changed()


func close():
	Options.save_prefs()
	super.close()


func _input(event: InputEvent) -> void:
	super(event)


@onready var screen_count := DisplayServer.get_screen_count()

var restart_preview_timer := 0.0
func _process(delta: float) -> void:
	if screen_count > 1 and DisplayServer.window_get_mode() != DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
		if not %ScreenOptionButton.has_focus():
			%ScreenOptionButton.select(DisplayServer.window_get_current_screen())
	if not find_child("TextMenu").visible:
		return
	var slider_value : float = find_child("TextSpeedSlider").value
	if %BodyPreviewLabel.visible_ratio == 1:
		if slider_value == LineReader.MAX_TEXT_SPEED:
			return
		restart_preview_timer -= delta
		if restart_preview_timer <= 0:
			restart_preview_timer = get_restart_preview_timer_duration()
			%BodyPreviewLabel.visible_ratio = 0
	else:
		%BodyPreviewLabel.visible_ratio += LineReader.get_body_label_progress_step(float(slider_value), %BodyPreviewLabel.get_parsed_text(), delta)



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
	Options.set_volume("Master", value, false)




func _on_save_button_pressed() -> void:
	Options.save_gamestate()
	Options.save_prefs()


func _on_main_menu_button_pressed() -> void:
	if SceneLoader.in_game:
		Options.save_gamestate()
	Game.set_screen("")
	SceneLoader.request_background_loading(MainMenu.PATH, true)



func _on_auto_continue_check_box_toggled(toggled_on: bool) -> void:
	find_child("AutoDelaySlider").visible = toggled_on
	find_child("AutoDelayLabel").visible = toggled_on
	
	Options.auto_continue = toggled_on

func _on_text_speed_slider_value_changed(value: float) -> void:
	var label : Label = find_child("TextSpeedValueLabel")
	if value == LineReader.MAX_TEXT_SPEED:
		label.text = "Instant"
		%BodyPreviewLabel.visible_ratio = 1
	else:
		label.text = str(int(value))
		%BodyPreviewLabel.visible_ratio = 0
		restart_preview_timer = get_restart_preview_timer_duration()


func _on_text_speed_slider_drag_ended(value_changed: bool) -> void:
	var value : float = %TextSpeedSlider.value
	
	Options.text_speed = int(value)

func get_restart_preview_timer_duration() -> float:
	if find_child("AutoContinueCheckBox").button_pressed:
		return find_child("AutoDelaySlider").value
	else:
		return 4

func _on_auto_delay_slider_value_changed(value: float) -> void:
	var label : Label = find_child("AutoDelayLabel")
	label.text = str(value, " s")
	
	if value == LineReader.MAX_TEXT_SPEED:
		%BodyPreviewLabel.visible_ratio = 1
	else:
		%BodyPreviewLabel.visible_ratio = 0
	restart_preview_timer = get_restart_preview_timer_duration()



func _on_auto_delay_slider_drag_ended(value_changed: bool) -> void:
	Options.auto_continue_delay = %AutoDelaySlider.value



func _on_quit_button_pressed() -> void:
	if SceneLoader.in_game:
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




func _on_save_to_slot_button_pressed() -> void:
	Game.set_screen(CONST.SCREEN_SAVE, {"save" : true})


func show_save_hint():
	%SaveHintLabel.modulate.a = 1

func hide_save_hint():
	%SaveHintLabel.modulate.a = 0


func _on_window_mode_option_button_item_selected(index: int) -> void:
	Options.set_window_mode(index)


func _on_screen_option_button_item_selected(index: int) -> void:
	Options.set_screen(index)


func _on_volume_slider_master_value_changed(value: float) -> void:
	Options.set_volume("Master", value, false)
	update_volume_labels()


func _on_volume_slider_master_drag_ended(value_changed: bool) -> void:
	Options.set_volume("Master", %VolumeSliderMaster.value, true)


func _on_volume_slider_music_value_changed(value: float) -> void:
	Options.set_volume("Music", value, false)
	update_volume_labels()


func _on_volume_slider_music_drag_ended(value_changed: bool) -> void:
	Options.set_volume("Music", %VolumeSliderMusic.value, true)


func _on_volume_slider_sfx_value_changed(value: float) -> void:
	Options.set_volume("SFX", value, false)
	update_volume_labels()


func _on_volume_slider_sfx_drag_ended(value_changed: bool) -> void:
	Options.set_volume("SFX", %VolumeSliderSFX.value, true)


func _on_volume_slider_ui_drag_ended(value_changed: bool) -> void:
	Options.set_volume("UI", %VolumeSliderUI.value, true)


func _on_volume_slider_ui_value_changed(value: float) -> void:
	Options.set_volume("UI", value, false)
	update_volume_labels()


func update_volume_labels():
	%VolumeLabelMaster.text = str(int(Options.get_volume("Master") * 100))
	%VolumeLabelMusic.text = str(int(Options.get_volume("Music") * 100))
	%VolumeLabelSFX.text = str(int(Options.get_volume("SFX") * 100))
	%VolumeLabelUI.text = str(int(Options.get_volume("UI") * 100))



#func on_settings_changed():
	#%ShadowOptionButton.disabled = Options.slideshow_enabled
	#%RenderingScaleOptionButton.disabled = Options.slideshow_enabled
	#%ShowdownBackgroundCheckBox.disabled = Options.slideshow_enabled
	#%SlideshowDeactivateLabel.visible = Options.slideshow_enabled


func _on_dither_check_box_toggled(toggled_on: bool) -> void:
	Options.dither_enabled = toggled_on


func _on_blur_check_box_toggled(toggled_on: bool) -> void:
	Options.blur_enabled = toggled_on


func _on_blood_check_box_toggled(toggled_on: bool) -> void:
	Options.blood_enabled = toggled_on


func _on_crt_check_box_toggled(toggled_on: bool) -> void:
	Options.crt_enabled = toggled_on


func _on_fps_counter_check_box_toggled(toggled_on: bool) -> void:
	Options.fps_counter_visible = toggled_on


func _on_glow_check_box_toggled(toggled_on: bool) -> void:
	Options.glow_enabled = toggled_on
	


func _on_change_save_slot_button_pressed() -> void:
	var payload := {"save" : false}
	var screen : Screen = Game.set_screen(CONST.SCREEN_SAVE, payload)
	screen.screen_on_close = CONST.SCREEN_OPTIONS


func _on_text_menu_visibility_changed() -> void:
	%BodyPreviewLabel.visible_ratio = 0


func _on_open_screenshots_folder_button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://"))
