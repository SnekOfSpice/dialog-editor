@tool
extends VBoxContainer

var deserialized_range:int

func update(line_index:int, max_reach):
	#var page_size : int = Pages.page_data.get(Pages.editor.current_page.number).get("lines", []).size()
	#var max_reach = Pages.editor.current_page.get_max_reach_after_indented_index(line_index)
	find_child("FolderRangeSpinContainer").max_value = max_reach# - line_index
	#find_child("FolderRangeSpinContainer").value = find_child("FolderRangeSpinContainer").max_value
	if deserialized_range != null:
		find_child("FolderRangeSpinContainer").set_value_no_signal( deserialized_range)
	#prints("page size ", Pages.editor.current_page.number, " is ", page_size)
	#prints("folder at ", line_index, " reaches ", find_child("FolderRangeSpinContainer").max_value)
	find_child("Label").text = str(
		"spans: (", line_index, " - ", line_index + find_child("FolderRangeSpinContainer").value,")", "\n",
		"max span: ", max_reach + line_index
		)
	$PanelContainer/HBoxContainer/DebugLabel.text = str("updated ", deserialized_range, " ", deserialized_range == null, "\n", Time.get_unix_time_from_system(), "\n", "max reach", max_reach)

func change_folder_range(by:int):
	find_child("FolderRangeSpinContainer").value += by
	find_child("FolderRangeSpinContainer").max_value += by

func get_included_count() -> int:
	if deserialized_range != null:
		return deserialized_range
	return find_child("FolderRangeSpinContainer").value

func serialize() -> Dictionary:
	var result := {}
	
	result["range"] = find_child("FolderRangeSpinContainer").value
	result["meta.contents_visible"] = find_child("FolderVisibilityCheckBox").button_pressed
	
	return result

func deserialize(data:Dictionary):
	var range_spinner : SpinBox = find_child("FolderRangeSpinContainer")
	range_spinner.set_value_no_signal(data.get("range", 0))
	deserialized_range = data.get("range", 0)
	var visibility_checkbox : CheckBox = find_child("FolderVisibilityCheckBox")
	visibility_checkbox.set_pressed_no_signal(data.get("meta.contents_visible", true))
	
	$PanelContainer/HBoxContainer/DebugLabel2.text = str(data, "\n", deserialized_range, "\n", Time.get_unix_time_from_system())
	
	#Pages.editor.current_page.update()

func get_folder_contents_visible() -> bool:
	return find_child("FolderVisibilityCheckBox").button_pressed

func _on_folder_range_spin_container_value_changed(value: float) -> void:
	deserialized_range = value
	Pages.editor.current_page.update()


func _on_folder_visibility_check_box_pressed() -> void:
	Pages.editor.current_page.update()
