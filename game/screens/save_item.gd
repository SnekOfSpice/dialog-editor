extends Button

var save_slot:int

func _ready() -> void:
	find_child("TextureRect").custom_minimum_size = Options.get_save_thumbnail_size()

func set_slot(slot:int):
	save_slot = slot
	var thumb_path : String = Options.get_save_thumbnail_path(save_slot)
	var image = Image.new()
	var error = image.load(thumb_path)
	if error:
		find_child("TextureRect").texture = load("res://game/systems/save_system/no_data.png")
	else:
		find_child("TextureRect").texture = ImageTexture.create_from_image(image)
	
	%Slot.text = str("Slot ", slot + 1)
	
	#var data_path : String = Options.get_savedata_dir_name(save_slot)
	if error:
		%Data.text = "No Data"
	else:
		var time = FileAccess.get_modified_time(thumb_path)
		var label = Time.get_datetime_string_from_unix_time(time, true)
		label = label.replace(" ", "\n")
		%Data.text = label
	#else:
	
	await get_tree().process_frame
	
	custom_minimum_size = $Container.size


func _on_mouse_entered() -> void:
	$Container.add_theme_constant_override("margin_top", 6)
	$Container.add_theme_constant_override("margin_bottom", 2)


func _on_mouse_exited() -> void:
	$Container.add_theme_constant_override("margin_top", 4)
	$Container.add_theme_constant_override("margin_bottom", 4)
