@tool
extends Node

var cached_lines := {}
# these technically could also be in cached_lines, but that serialization is so deep and nested, this is way easier
var cached_choice_items := {}

func add_lines(indices:Array, data_by_index:={}):
	if not Pages.editor.current_page:
		Pages.editor.add_page(0)
	
	for i in indices:
		# use cached data if it's there
		if cached_lines.has(Pages.editor.current_page.number):
			var cached_lines_on_page : Dictionary = cached_lines.get(Pages.editor.current_page.number)
			if cached_lines_on_page.has(i):
				data_by_index[i] = cached_lines_on_page.get(i)
		
	Pages.editor.current_page.add_lines(indices, data_by_index)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()


func add_line(at_index:int, data:={}):
	add_lines([at_index], {at_index:data})

func delete_lines(indices:Array):
	for i in indices:
		# update cached line data
		if cached_lines.has(Pages.editor.current_page.number):
			var lines : Dictionary = cached_lines.get(Pages.editor.current_page.number)
			lines[i] = Pages.editor.current_page.get_line_data(i)
		else:
			cached_lines[Pages.editor.current_page.number] = {i:Pages.editor.current_page.get_line_data(i)}
	
	Pages.editor.current_page.delete_lines(indices)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_line(at):
	Pages.editor.current_page.delete_line(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func load_page(at:int):
	# prepare current page to change
	if Pages.editor.current_page:
		Pages.editor.current_page.set_page_key(Pages.editor.current_page.find_child("PageKeyLineEdit").text)
		Pages.editor.current_page.save()
		Pages.editor.current_page.enable_page_key_edit(false)
	
	## TODO: Adding this await fucks up the load???
	#await get_tree().process_frame
	Pages.editor.load_page(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func change_page_references_dir(changed_page: int, operation:int):
	Pages.change_page_references_dir(changed_page, operation)

func create_page(at, overwrite_existing:= false):
	Pages.create_page(at, overwrite_existing)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_page(at:int):
	prints("pages before deletion: ", Pages.page_data.keys())
	#if at == Pages.editor.current_page.number:
	cached_lines[at] = Pages.page_data.get(at)#Pages.editor.current_page.serialize()
	Pages.delete_page_data(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()
	prints("pages after deletion: ", Pages.page_data.keys())

func add_page(at:int):
	var data : Dictionary = cached_lines.get(at, {})
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

func add_choice_item(line_address:String):
	var default_data := {
		"choice_text": "choice label",
		"target_page": 0,}
	var target_line : Line = DiisisEditorUtil.get_node_at_address(line_address)
	var item_address := str(line_address, ".", target_line.get_choice_item_count())
	target_line.add_choice_item(cached_choice_items.get(item_address, default_data))

func delete_choice_item(item_address:String):
	var item = DiisisEditorUtil.get_node_at_address(item_address)
	var parts = DiisisEditorUtil.get_split_address(item_address)
	var data = item.serialize()
	cached_choice_items[item_address] = data
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
