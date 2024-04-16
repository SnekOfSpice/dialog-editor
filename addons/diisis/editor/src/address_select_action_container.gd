@tool
extends CenterContainer
class_name AddressSelectActionContainer

@export var address_depth := DiisisEditorUtil.AddressDepth.Line

func set_interactable(value:bool):
	find_child("SelectCheckBox").disabled = not value
	find_child("MenuBar").visible = value


func set_selected(value:bool):
	if find_child("SelectCheckBox").button_pressed != value:
		find_child("SelectCheckBox").button_pressed = value
	var selected_address = DiisisEditorUtil.get_address(self, address_depth)
	if value:
		DiisisEditorActions.add_to_selected_addresses(selected_address)
	else:
		DiisisEditorActions.remove_from_selected_addresses(selected_address)

func _on_select_check_box_toggled(toggled_on: bool) -> void:
	set_selected(toggled_on)


func _on_a_index_pressed(index: int) -> void:
	match index:
		0: # copy this
			DiisisEditorActions.clear_selected_addresses()
			set_selected(true)
			DiisisEditorActions.delete_from_selected_addresses_on_insert = false
			DiisisEditorActions.add_data_from_selected_addresses_to_clipboard()
			set_selected(false)
		1: # copy selection
			DiisisEditorActions.delete_from_selected_addresses_on_insert = false
			DiisisEditorActions.add_data_from_selected_addresses_to_clipboard()
		2: # cut this
			DiisisEditorActions.clear_selected_addresses()
			set_selected(true)
			DiisisEditorActions.delete_from_selected_addresses_on_insert = true
			DiisisEditorActions.add_data_from_selected_addresses_to_clipboard()
			set_selected(false)
			
		3: # cut selection
			DiisisEditorActions.delete_from_selected_addresses_on_insert = true
			DiisisEditorActions.add_data_from_selected_addresses_to_clipboard()
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
		new_address.trim_suffix(".")
		selected_address = new_address
	DiisisEditorActions.insert_from_clipboard(selected_address)
