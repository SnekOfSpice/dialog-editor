@tool
extends Node

var blank_override_line_addresses := []
var blank_override_choice_item_addresses := []

var cached_pages := {}
var cached_lines := {}
# these technically could also be in cached_lines, but that serialization is so deep and nested, this is way easier
var cached_choice_items := {}

var clipboard := {}
var current_selection_address_depth := -1 # should be DiisisEditorUtil.AddressDepth
var delete_from_selected_addresses_on_insert := false

func add_line(at_index:int, data:={}, force_new_line_object:=true, change_line_references:=false):
	add_lines([at_index], {at_index:data}, force_new_line_object, change_line_references)


func add_lines(indices:Array, data_by_index:={}, force_new_line_object:=true, change_line_references:=false):
	if not Pages.editor.current_page:
		Pages.editor.add_page(0)
	
	for i in indices:
		var cached_lines_on_page : Dictionary = cached_lines.get(Pages.editor.get_current_page_number(), {})
		var cached_lines_at_index : Array = cached_lines_on_page.get(i, [])
		if (not blank_override_line_addresses.has(str(Pages.editor.get_current_page_number(), ".", i))
		and not cached_lines_at_index.is_empty()
		and data_by_index.get(i, {}).is_empty()):
			var data = cached_lines_at_index.pop_back()
			cached_lines_on_page[i] = cached_lines_at_index
			cached_lines[Pages.editor.current_page.number] = cached_lines_on_page
			data_by_index[i] = data
		
	Pages.editor.current_page.add_lines(indices, data_by_index, force_new_line_object, change_line_references)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()



func delete_lines(indices:Array):
	var page_number := Pages.editor.get_current_page_number()
	for i in indices:
		var address := str(page_number, ".", i)
		while blank_override_line_addresses.has(address):
			blank_override_line_addresses.erase(address)
		# update cached line data
		if cached_lines.has(page_number):
			var cached_lines_on_page = cached_lines.get(page_number)
			var cached_lines_at_index = cached_lines_on_page.get(i, [])
			cached_lines_at_index.append(Pages.editor.current_page.get_line_data(i))
			cached_lines[page_number][i] = cached_lines_at_index
		else:
			cached_lines[page_number] = {i:[Pages.editor.current_page.get_line_data(i)]}
		
		Pages.change_line_references_directional(
		Pages.editor.get_current_page_number(),
		i,
		Pages.editor.current_page.get_line_count() - 1,
		 - 1
	)
	
	Pages.editor.current_page.delete_lines(indices)
	Pages.editor.refresh(false, true)
	
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_line(at):
	delete_lines([at])

func go_to(address:String, discard_without_saving:=false):
	var parts := DiisisEditorUtil.get_split_address(address)
	
	# prepare current page to change
	if Pages.editor.current_page:
		Pages.editor.current_page.set_page_key(Pages.editor.current_page.find_child("PageKeyLineEdit").text)
		Pages.editor.current_page.save()
		Pages.editor.current_page.enable_page_key_edit(false)
	
	if Pages.editor.get_current_page_number() != parts[0]:
		Pages.local_line_insert_offset = 0
	
	Pages.editor.load_page(parts[0], discard_without_saving)
	if not Pages.editor.current_page:
		return
	await get_tree().process_frame
	Pages.editor.current_page.update()
	
	if parts.size() >= 2:
		await get_tree().process_frame
		Pages.editor.current_page.ensure_control_at_address_is_visible(address)

func load_page(at:int):
	go_to(str(at))

func change_page_references_dir(changed_page: int, operation:int):
	Pages.change_page_references_dir(changed_page, operation)

func delete_page(at:int):
	var cached_versions = cached_pages.get(at, [])
	cached_versions.append(Pages.page_data.get(at))
	cached_pages[at] = cached_versions
	await get_tree().process_frame # without this await, the last page cannot be deleted
	Pages.delete_page_data(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func add_page(at:int, page_reference_change:=1):
	var cached_versions : Array = cached_pages.get(at, [])
	var data : Dictionary
	if not cached_versions.is_empty():
		data = cached_versions.pop_back()
		cached_pages[at] = cached_versions
	else:
		data = {}
	Pages.add_page_data(at, data)
	await get_tree().process_frame
	Pages.change_page_references_dir(at, page_reference_change)
	Pages.editor.load_page(at)
	
	if not Pages.editor.current_page:
		return
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func move_line(line:Line, dir:int):
	Pages.editor.current_page.move_line(line, dir)

func swap_pages(page_a:int, page_b:int):
	Pages.swap_pages(page_a, page_b)

func rename_dropdown_title(from:String, to:String):
	Pages.rename_dropdown_title(from, to)
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

func set_dropdown_options(dropdown_title:String, options:Array, replace_in_text:bool, replace_speaker:bool):
	Pages.set_dropdown_options(dropdown_title, options, replace_in_text, replace_speaker)
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

func rename_fact(from:String, to:String):
	Pages.rename_fact(from, to)
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

## action should be either "add" or "delete"
func operate_local_fact(address:String, target:int, action:String, fact_name:String, fact_value:=true):
	var conditional = address.ends_with("c")
	var level := DiisisEditorUtil.get_address_depth(address)
	address = address.trim_suffix("c" if conditional else "f")
	var address_parts := DiisisEditorUtil.get_split_address(address)
	var func_name := str(action, "_", "conditional" if conditional else "fact")
	
	if Pages.editor.current_page.number != address_parts[0]:
		push_warning("Current page is not the page of the address")
		return
	
	if conditional and level == DiisisEditorUtil.AddressDepth.Page:
			push_warning("Pages do not have conditionals")
			return
	if action == "add":
		DiisisEditorUtil.get_node_at_address(address).call(func_name, fact_name, fact_value)
	elif action == "delete":
		DiisisEditorUtil.get_node_at_address(address).call(func_name, fact_name)

func add_fact(address:String, target:int, fact_name:String, fact_value):
	operate_local_fact(address, target, "add", fact_name, fact_value)

func delete_fact_local(address:String, target:int, fact_name:String):
	operate_local_fact(address, target, "delete", fact_name)

func add_choice_items(item_addresses:Array, choice_data_by_address:={}):
	item_addresses = DiisisEditorUtil.sort_addresses(item_addresses)
	for item_address in item_addresses:
		var target_line_address : String = DiisisEditorUtil.truncate_address(item_address, DiisisEditorUtil.AddressDepth.Line)
		var target_line : Line = DiisisEditorUtil.get_node_at_address(target_line_address)
		var parts := DiisisEditorUtil.get_split_address(item_address)
		var cache:Array=cached_choice_items.get(target_line_address, [])
		var data := choice_data_by_address.get(item_address, {})
		if not cache.is_empty() and data.is_empty() and not blank_override_choice_item_addresses.has(item_address):
			data = cache.pop_back()
			cached_choice_items[target_line_address] = cache
		target_line.add_choice_item(parts[2], data)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func add_choice_item(item_address:String, choice_data:={}):
	add_choice_items([item_address], {item_address:choice_data})

func delete_choice_items(item_addresses:Array):
	item_addresses = DiisisEditorUtil.sort_addresses(item_addresses)
	item_addresses.reverse()
	for item_address in item_addresses:
		blank_override_choice_item_addresses.erase(item_address)
		var line_address = DiisisEditorUtil.truncate_address(item_address, DiisisEditorUtil.AddressDepth.Line)
		var item = DiisisEditorUtil.get_node_at_address(item_address)
		var data = item.serialize()
		var cache :Array= cached_choice_items.get(line_address, [])
		cache.append(data)
		cached_choice_items[line_address] = cache
		item.queue_free()
	
	await get_tree().process_frame
	Pages.editor.current_page.update()
	
func delete_choice_item(item_address:String):
	delete_choice_items([item_address])

func move_choice_item(item_address:String, direction:int):
	var level := DiisisEditorUtil.get_address_depth(item_address)
	var address_parts := DiisisEditorUtil.get_split_address(item_address)
	
	if Pages.editor.current_page.number != address_parts[0]:
		push_warning("Current page is not the page of the address")
		return
	if level != DiisisEditorUtil.AddressDepth.ChoiceItem:
		push_warning("Trying to move choice item with incorrect address depth")
		push_warning(str(level))
		return
	
	var choice_line : Line = Pages.editor.current_page.get_line(address_parts[1])
	choice_line.move_choice_item_by_index(address_parts[2], direction)


## Returns addresses it copied from
func copy(depth:int, single_address_override := "") -> Array:
	var selected_addresses: Array
	if single_address_override.is_empty():
		selected_addresses = get_selected_addresses(depth)
	else:
		selected_addresses = [single_address_override]

	var data_at_depth := {}
	for address in selected_addresses:
		data_at_depth[address] = Pages.get_data_from_address(address).duplicate(true)
	clipboard[depth] = data_at_depth
	Pages.editor.notify(str("Added ", data_at_depth.size(), " items to clipboard!"))
	return selected_addresses

func cut(depth:int, single_address_override := ""):
	var copied = copy(depth, single_address_override)
	
	var objects_to_delete := []
	copied.reverse()
	for c in copied:
		objects_to_delete.append(DiisisEditorUtil.get_node_at_address(c))
	for object in objects_to_delete:
		object.request_delete()

func get_selected_addresses(depth:int) -> Array:
	var selected_on_page :=[]
	for selector : AddressSelectActionContainer in get_tree().get_nodes_in_group("address_selectors"):
		if selector.is_selected() and selector.address_depth == depth:
			selected_on_page.append(DiisisEditorUtil.get_address(selector, selector.address_depth))
	
	selected_on_page = DiisisEditorUtil.sort_addresses(selected_on_page)
	return selected_on_page

func insert_from_clipboard(start_address:String):
	var insert_depth = DiisisEditorUtil.get_address_depth(start_address)
	var data_at_depth = clipboard.get(insert_depth, {})
	var start_address_parts = DiisisEditorUtil.get_split_address(start_address)
	if insert_depth == DiisisEditorUtil.AddressDepth.Line:
		var indices := []
		var data_by_index := {}
		var i := 0
		for address in data_at_depth:
			indices.append(start_address_parts[1] + i)
			data_by_index[start_address_parts[1] + i] = data_at_depth.get(address)
			i += 1
	
		var undo_redo = Pages.editor.undo_redo
		undo_redo.create_action("Paste Lines")
		indices.sort()
		undo_redo.add_do_method(add_lines.bind(indices, data_by_index))
		indices.reverse()
		undo_redo.add_undo_method(delete_lines.bind(indices))
		undo_redo.commit_action()
		
		# deselect
		var addresses := []
		var page_number := Pages.editor.get_current_page_number()
		for j in indices:
			addresses.append(str(page_number, ".", j))
		for address in addresses:
			var object : Line = DiisisEditorUtil.get_node_at_address(address)
			object.set_selected(false)
		
	elif insert_depth == DiisisEditorUtil.AddressDepth.ChoiceItem:
		var i := 0
		var addresses := []
		var data_by_address := {}
		for address in data_at_depth:
			var new_address = str(
				start_address_parts[0], ".",
				start_address_parts[1], ".",
				start_address_parts[2] + i,
			)
			addresses.append(new_address)
			data_by_address[new_address] = data_at_depth.get(address)
			i += 1
		
		var undo_redo = Pages.editor.undo_redo
		undo_redo.create_action("Paste Choice Items")
		undo_redo.add_do_method(add_choice_items.bind(addresses, data_by_address))
		undo_redo.add_undo_method(delete_choice_items.bind(addresses))
		undo_redo.commit_action()
		
		for address in addresses:
			var object : ChoiceEdit = DiisisEditorUtil.get_node_at_address(address)
			object.set_selected(false)
	
	Pages.editor.notify(str("Adding ", data_at_depth.size(), " items from clipboard!"))

func replace_line_content_texts(line_addresses:Array, what:String, with:String, case_insensitive:=false):
	var pages_to_operate_on := {}
	for address in line_addresses:
		var parts = DiisisEditorUtil.get_split_address(address)
		if pages_to_operate_on.has(parts[0]):
			var lines : Array = pages_to_operate_on.get(parts[0])
			lines.append(parts[1])
		else:
			pages_to_operate_on[parts[0]] = [parts[1]]
	for n in pages_to_operate_on.keys():
		var page = Pages.page_data.get(n, {})
		var lines : Array = page.get("lines", [])
		var lines_to_operate_on : Array = pages_to_operate_on.get(n)
		var i := 0
		while i < lines.size():
			if not lines_to_operate_on.has(i):
				i += 1
				continue
			var line = lines[i]
			if line.get("line_type") == DIISIS.LineType.Text:
				var content : String = line.get("content").get("content")
				if case_insensitive:
					content = content.replacen(what, with)
				else:
					content = content.replace(what, with)
				line["content"]["content"] = content
			i += 1
	
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

func replace_choice_content_texts(choice_item_addresses:Array, what:String, with:String, case_insensitive:=false):
	var pages_to_operate_on := {}
	var enabled_addresses := []
	var disabled_addresses := []
	for address : String in choice_item_addresses:
		var parts = DiisisEditorUtil.get_split_address(address)
		if pages_to_operate_on.has(parts[0]):
			var lines : Dictionary = pages_to_operate_on.get(parts[0], {})
			var items : Array = lines.get(parts[1], [])
			items.append(parts[2])
		else:
			pages_to_operate_on[parts[0]] = {parts[1]:[parts[2]]}
		if address.ends_with("enabled"):
			enabled_addresses.append(".".join(parts))
		if address.ends_with("disabled"):
			disabled_addresses.append(".".join(parts))
	for n in pages_to_operate_on.keys():
		var page = Pages.page_data.get(n, {})
		var lines : Array = page.get("lines", [])
		for line_index in pages_to_operate_on.get(n).keys():
			var line = lines[line_index]
			if line.get("line_type") == DIISIS.LineType.Choice:
				var choices : Array = line.get("content").get("choices", [])
				var choice_indices_to_operate_on : Array = pages_to_operate_on.get(n).get(line_index)
				for index in choice_indices_to_operate_on:
					var choice = choices[index]
					var choice_address := str(n, ".", line_index, ".", index)
					if enabled_addresses.has(choice_address):
						if case_insensitive:
							choice["choice_text.enabled"] = choice["choice_text.enabled"].replacen(what, with)
						else:
							choice["choice_text.enabled"] = choice["choice_text.enabled"].replace(what, with)
					if disabled_addresses.has(choice_address):
						if case_insensitive:
							choice["choice_text.disabled"] = choice["choice_text.disabled"].replacen(what, with)
						else:
							choice["choice_text.disabled"] = choice["choice_text.disabled"].replace(what, with)
				
				line["content"]["choices"] = choices
			else:
				print("no choice")
	
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

func replace_line_content_text(line_address:String, what:String, with:String, case_insensitive:=false):
	replace_line_content_texts([line_address], what, with, case_insensitive)

func replace_choice_content_text(item_address:String, what:String, with:String, case_insensitive:=false):
	replace_choice_content_texts([item_address], what, with, case_insensitive)
