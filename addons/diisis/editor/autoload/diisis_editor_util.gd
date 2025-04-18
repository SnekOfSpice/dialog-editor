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

func get_node_at_address(address:String, suppress_off_page_warning := false):
	var level := get_address_depth(address)
	var address_parts := get_split_address(address)
	if Pages.editor.get_current_page().number != address_parts[0]:
		if not suppress_off_page_warning:
			push_warning("Current page is not within scope of address")
		return null
	
	if level == AddressDepth.Page:
		return Pages.editor.get_current_page()
	elif level == AddressDepth.Line:
		return Pages.editor.get_current_page().get_line(address_parts[1])
	elif level == AddressDepth.ChoiceItem:
		return Pages.editor.get_current_page().get_line(address_parts[1]).get_choice_item(address_parts[2])
		

func sort_addresses(addresses:Array) -> Array:
	addresses.sort_custom(_sort_addresses)
	return addresses

func _sort_addresses(a1:String, a2: String) -> bool:
	var depth1 = get_address_depth(a1)
	var depth2 = get_address_depth(a2)
	
	if depth1 < depth2:
		return true
	elif depth1 > depth2:
		return false
	
	var last1 = get_split_address(a1).back()
	var last2 = get_split_address(a2).back()
	return last1 < last2

# TODO: [page name or number if no name] / line type / choice text (concat)
func humanize_address(address:String) -> String:
	if not Pages.does_address_exist(address):
		return "N/A"
	var address_string := ""
	var parts := get_split_address(address)
	address_string = str(Pages.get_page_key(parts[0]))
	if address_string.is_empty():
		address_string = str(parts[0])
	if parts.size() > 1:
		address_string += str(" / ", Pages.get_line_type_str(parts[0], parts[1]))
	if parts.size() > 2:
		address_string += str(" / ", Pages.get_choice_text_shortened(parts[0], parts[1], parts[2]))
	return address_string

func get_project_source_file_path() -> String:
	return String(ProjectSettings.get_setting("diisis/project/file/path"))

func set_project_file_path(active_dir:String, active_file_name:String):
	ProjectSettings.set_setting("diisis/project/file/path", str(active_dir, active_file_name))
	ProjectSettings.save()

## max height is a multiple of the editor size
func limit_scroll_container_height(
	scroll_container : ScrollContainer,
	max_height : float,
	scroll_hint_top : TextureRect=null,
	scroll_hint_bottom : TextureRect=null,
):
	if scroll_container.get_child_count() != 1:
		push_warning("Scroll container has not exactly 1 child")
		return
	var child_control = scroll_container.get_child(0)
	if not is_instance_valid(Pages.editor):
		return
	max_height *= Pages.editor.size.y
	var child_height : float = child_control.size.y
	if child_height <= max_height:
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.custom_minimum_size = child_control.custom_minimum_size
		if scroll_hint_top:
			scroll_hint_top.visible = false
		if scroll_hint_bottom:
			scroll_hint_bottom.visible = false
	else:
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll_container.custom_minimum_size.y = max_height
		if scroll_hint_top:
			scroll_hint_top.visible = scroll_container.scroll_vertical == 0
		if scroll_hint_bottom:
			scroll_hint_bottom.visible = scroll_container.scroll_vertical >= scroll_container.get_v_scroll_bar().max_value - (scroll_container.size.y + 1)
