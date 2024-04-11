@tool
extends Node

var cached_lines := {}

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
	var level = address.count(".")
	address = address.trim_suffix("c" if conditional else "f")
	var address_parts = address.split(".")
	var int_parts := []
	for part in address_parts:
		int_parts.append(int(part))
	var func_name := str(action, "_", "conditional" if conditional else "fact")
	
	if Pages.editor.current_page.number != int_parts[0]:
		push_warning("Current page is not the page of the address")
		return
	if level == DiisisEditorUtil.AddressDepth.Page:
		if conditional:
			push_warning("Cannot add conditional to page")
			return
		if action == "add":
			Pages.editor.current_page.call(func_name, fact_name, fact_value)
		elif action == "delete":
			Pages.editor.current_page.call(func_name, fact_name)
	elif level == DiisisEditorUtil.AddressDepth.Line:
		if action == "add":
			Pages.editor.current_page.get_line(int_parts[1]).call(func_name, fact_name, fact_value)
		elif action == "delete":
			Pages.editor.current_page.get_line(int_parts[1]).call(func_name, fact_name)
	elif level == DiisisEditorUtil.AddressDepth.ChoiceItem:
		if action == "add":
			Pages.editor.current_page.get_line(int_parts[1]).get_choice_item(int_parts[2]).call(func_name, fact_name, fact_value)
		elif action == "delete":
			Pages.editor.current_page.get_line(int_parts[1]).get_choice_item(int_parts[2]).call(func_name, fact_name)


func add_fact(address:String, target:int, fact_name:String, fact_value:bool):
	operate_local_fact(address, target, "add", fact_name, fact_value)
	return
	var conditional = address.ends_with("c")
	var level = address.count(".")
	address = address.trim_suffix("c" if conditional else "f")
	var address_parts = address.split(".")
	var int_parts := []
	for part in address_parts:
		int_parts.append(int(part))
	
	if Pages.editor.current_page.number != int_parts[0]:
		push_warning("Current page is not the page of the address")
		return
	if level == DiisisEditorUtil.AddressDepth.Page:
		if conditional:
			push_warning("Cannot add conditional to page")
			return
		Pages.editor.current_page.add_fact(fact_name, fact_value)
	elif level == DiisisEditorUtil.AddressDepth.Line:
		if conditional:
			Pages.editor.current_page.get_line(int_parts[1]).add_conditional(fact_name, fact_value)
		else:
			Pages.editor.current_page.get_line(int_parts[1]).add_fact(fact_name, fact_value)
	elif level == DiisisEditorUtil.AddressDepth.ChoiceItem:
		if conditional:
			Pages.editor.current_page.get_line(int_parts[1]).get_choice_item(int_parts[2]).add_conditional(fact_name, fact_value)
		else:
			Pages.editor.current_page.get_line(int_parts[1]).get_choice_item(int_parts[2]).add_fact(fact_name, fact_value)

func delete_fact_local(address:String, target:int, fact_name:String):
	operate_local_fact(address, target, "delete", fact_name)
