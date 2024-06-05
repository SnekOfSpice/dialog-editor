extends Screen


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_menu(0)
	find_child("QuitButton").visible = not OS.has_feature("web")

func _gui_input(event: InputEvent) -> void:
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


func _on_close_button_pressed() -> void:
	GameWorld.stage_root.set_screen("")
