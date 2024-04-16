@tool
extends VBoxContainer

var deserialized_range:int

func update(line_index:int, max_reach):
	find_child("FolderRangeSpinContainer").max_value = max_reach
	
	if deserialized_range != null:
		find_child("FolderRangeSpinContainer").set_value_no_signal( deserialized_range)
	
	find_child("Label").text = str(
		"spans: (", line_index, " - ", line_index + find_child("FolderRangeSpinContainer").value,")", "\n",
		"max span: ", max_reach + line_index
		)

func set_page_view(view:DiisisEditor.PageView):
	find_child("Label").visible = view == DiisisEditor.PageView.Full
	find_child("PanelContainer").visible = not view == DiisisEditor.PageView.Minimal

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

func get_folder_contents_visible() -> bool:
	return find_child("FolderVisibilityCheckBox").button_pressed

func _on_folder_range_spin_container_value_changed(value: float) -> void:
	deserialized_range = value
	Pages.editor.current_page.update()


func _on_folder_visibility_check_box_pressed() -> void:
	Pages.editor.current_page.update()
