@tool
extends Node

enum AddressDepth {
	Page, Line, ChoiceItem
}

func get_address(object:Node, address_depth:AddressDepth) -> String:
	var address := ""
	
	if address_depth == AddressDepth.Page:
		var parent_page = object
		while not parent_page is Page:
			parent_page = parent_page.get_parent()
		address = str(parent_page.get("number"))
	elif address_depth == AddressDepth.Line:
		var parent_line = object
		while not parent_line is Line:
			parent_line = parent_line.get_parent()
		var parent_page = parent_line.get_parent()
		while not parent_page is Page:
			parent_page = parent_page.get_parent()
		address = str(parent_page.get("number"), ".", parent_line.get_index())
	elif address_depth == AddressDepth.ChoiceItem:
		var parent_choice = object
		while not parent_choice is ChoiceEdit:
			parent_choice = parent_choice.get_parent()
		var parent_line = parent_choice.get_parent()
		while not parent_line is Line:
			parent_line = parent_line.get_parent()
		var parent_page = parent_line.get_parent()
		while not parent_page is Page:
			parent_page = parent_page.get_parent()
		address = str(parent_page.get("number"), ".", parent_line.get_index(), ".", parent_choice.get_index())
	
	return address

func truncate_address(address:String, to_level:AddressDepth) -> String:
	var result := ""
	var parts = get_split_address(address)
	if parts.size() < to_level:
		push_warning("Address is already truncated below requested level")
		return address
	for i in to_level + 1:
		result += str(parts[i])
		result += "."
	result = result.trim_suffix(".")
	return result

func get_split_address(address:String) -> Array[int]:
	var result : Array[int] = []
	var address_parts = address.split(".")
	for part in address_parts:
		result.append(int(part))
	return result

func get_address_depth(address:String) -> int:
	return address.count(".")

func get_node_at_address(address:String):
	var level := get_address_depth(address)
	var address_parts := get_split_address(address)
	if Pages.editor.current_page.number != address_parts[0]:
		push_warning("Current page is not within scope of address")
		return
	
	if level == AddressDepth.Page:
		return Pages.editor.current_page
	elif level == AddressDepth.Line:
		return Pages.editor.current_page.get_line(address_parts[1])
	elif level == AddressDepth.ChoiceItem:
		return Pages.editor.current_page.get_line(address_parts[1]).get_choice_item(address_parts[2])
		
