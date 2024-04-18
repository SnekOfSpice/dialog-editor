@tool
extends CenterContainer
class_name AddressSelectActionContainer

@export var address_depth := DiisisEditorUtil.AddressDepth.Line

func serialize() -> Dictionary:
	var result := {}
	
	result ["selected"] = is_selected()
	
	return result

func deserialize(data:Dictionary):
	find_child("SelectCheckBox").button_pressed = data.get("selected")

func is_selected() -> bool:
	return find_child("SelectCheckBox").button_pressed

func set_selected(value:bool):
	if find_child("SelectCheckBox").button_pressed != value:
		find_child("SelectCheckBox").button_pressed = value

func _on_select_check_box_toggled(toggled_on: bool) -> void:
	set_selected(toggled_on)


func _on_a_index_pressed(index: int) -> void:
	var address = DiisisEditorUtil.get_address(self, address_depth)
	match index:
		0: # copy this
			DiisisEditorActions.copy(address_depth, address)
		1: # copy selection
			DiisisEditorActions.copy(address_depth)
		2: # cut this
			DiisisEditorActions.cut(address_depth, address)
		3: # cut selection
			DiisisEditorActions.cut(address_depth)
		4: # insert above
			request_insert_items(true)
		5: # insert below
			request_insert_items(false)


func request_insert_items(above:bool):
	var selected_address = DiisisEditorUtil.get_address(self, address_depth)
	if not above:
		var parts = DiisisEditorUtil.get_split_address(selected_address)
		parts[address_depth] += 1
		var new_address := ""
		for p in parts:
			new_address += str(p)
			new_address += "."
		new_address = new_address.trim_suffix(".")
		selected_address = new_address
	DiisisEditorActions.insert_from_clipboard(selected_address)
