@tool
extends Node

var cached_pages := {}
var cached_lines := {}
# these technically could also be in cached_lines, but that serialization is so deep and nested, this is way easier
var cached_choice_items := {}

func add_lines(indices:Array, data_by_index:={}):
	if not Pages.editor.current_page:
		Pages.editor.add_page(0)
	
	for i in indices:
		# what is this for again??
		if cached_lines.has(Pages.editor.current_page.number):
			var cached_lines_on_page : Dictionary = cached_lines.get(Pages.editor.current_page.number)
			var cached_lines_at_index : Array = cached_lines_on_page.get(i, [])
			if not cached_lines_at_index.is_empty():
				var data = cached_lines_at_index.pop_back()
				cached_lines_on_page[i] = cached_lines_at_index
				cached_lines[Pages.editor.current_page.number] = cached_lines_on_page
				data_by_index[i] = data
		
	Pages.editor.current_page.add_lines(indices, data_by_index)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()


func add_line(at_index:int, data:={}):
	add_lines([at_index], {at_index:data})

func delete_lines(indices:Array):
	for i in indices:
		# update cached line data
		if cached_lines.has(Pages.editor.current_page.number):
			var cached_lines_on_page = cached_lines.get(Pages.editor.current_page.number)
			var cached_lines_at_index = cached_lines_on_page.get(i, [])
			cached_lines_at_index.append(Pages.editor.current_page.get_line_data(i))
			cached_lines[Pages.editor.current_page.number][i] = cached_lines_at_index
		else:
			cached_lines[Pages.editor.current_page.number] = {i:[Pages.editor.current_page.get_line_data(i)]}
	
	Pages.editor.current_page.delete_lines(indices)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_line(at):
	delete_lines([at])

func load_page(at:int):
	# prepare current page to change
	if Pages.editor.current_page:
		Pages.editor.current_page.set_page_key(Pages.editor.current_page.find_child("PageKeyLineEdit").text)
		Pages.editor.current_page.save()
		Pages.editor.current_page.enable_page_key_edit(false)
	
	Pages.editor.load_page(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func change_page_references_dir(changed_page: int, operation:int):
	Pages.change_page_references_dir(changed_page, operation)

func delete_page(at:int):
	var cache = cached_pages.get(at, [])
	cache.append(Pages.page_data.get(at))
	cached_pages[at] = cache
	await get_tree().process_frame # without this await, the last page cannot be deleted
	Pages.delete_page_data(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func add_page(at:int):
	var cache : Array = cached_pages.get(at, [])
	var data : Dictionary
	if not cache.is_empty():
		data = cache.pop_back()
		cached_pages[at] = cache
	else:
		data = {}
	Pages.add_page_data(at, data)
	await get_tree().process_frame
	Pages.change_page_references_dir(at, 1)
	Pages.editor.load_page(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func move_line(line:Line, dir:int):
	Pages.editor.current_page.move_line(line, dir)

func swap_pages(page_a:int, page_b:int):
	Pages.swap_pages(page_a, page_b)


func rename_fact(from:String, to:String):
	Pages.rename_fact(from, to)

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

func add_fact(address:String, target:int, fact_name:String, fact_value:bool):
	operate_local_fact(address, target, "add", fact_name, fact_value)

func delete_fact_local(address:String, target:int, fact_name:String):
	operate_local_fact(address, target, "delete", fact_name)

func add_choice_item(item_address:String):
	var target_line_address : String = DiisisEditorUtil.truncate_address(item_address, DiisisEditorUtil.AddressDepth.Line)
	var target_line : Line = DiisisEditorUtil.get_node_at_address(target_line_address)
	var parts := DiisisEditorUtil.get_split_address(item_address)
	var cache:Array=cached_choice_items.get(target_line_address, [])
	var data := {}
	if not cache.is_empty():
		data = cache.pop_back()
		cached_choice_items[target_line_address] = cache
	target_line.add_choice_item(parts[2], data)

func delete_choice_item(item_address:String):
	var line_address = DiisisEditorUtil.truncate_address(item_address, DiisisEditorUtil.AddressDepth.Line)
	var item = DiisisEditorUtil.get_node_at_address(item_address)
	var data = item.serialize()
	var cache :Array= cached_choice_items.get(line_address, [])
	cache.append(data)
	cached_choice_items[line_address] = cache
	item.queue_free()

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
