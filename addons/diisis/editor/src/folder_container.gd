@tool
extends VBoxContainer

func update(line_index:int):
	var page_size : int = Pages.page_data.get(Pages.editor.current_page.number).get("lines", []).size()
	var max_reach = Pages.editor.current_page.get_max_reach_after_indented_index(line_index)
	find_child("FolderRangeSpinContainer").max_value = max_reach# - line_index
	#prints("page size ", Pages.editor.current_page.number, " is ", page_size)
	#prints("folder at ", line_index, " reaches ", find_child("FolderRangeSpinContainer").max_value)
	find_child("Label").text = str(
		"spans: (", line_index, " - ", line_index + find_child("FolderRangeSpinContainer").value,")", "\n",
		"max span: ", max_reach + line_index
		)

func change_folder_range(by:int):
	find_child("FolderRangeSpinContainer").max_value += by
	find_child("FolderRangeSpinContainer").value += by

func get_included_count() -> int:
	return find_child("FolderRangeSpinContainer").value

func serialize() -> Dictionary:
	var result := {}
	
	result["range"] = find_child("FolderRangeSpinContainer").value
	result["meta.contents_visible"] = find_child("FolderRangeSpinContainer").value
	
	return result

func deserialize(data:Dictionary):
	find_child("FolderRangeSpinContainer").value = data.get("range", 0)
	find_child("FolderVisibilityCheckBox").button_pressed = data.get("meta.contents_visible", true)
	
	#Pages.editor.current_page.update()

func get_folder_contents_visible() -> bool:
	return find_child("FolderVisibilityCheckBox").button_pressed

func _on_folder_range_spin_container_value_changed(value: float) -> void:
	Pages.editor.current_page.update()


func _on_folder_visibility_check_box_pressed() -> void:
	Pages.editor.current_page.update()
