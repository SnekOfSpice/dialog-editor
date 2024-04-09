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


func change_page(to):
	# prepare current page to change
	if Pages.editor.current_page:
		Pages.editor.current_page.set_page_key(Pages.editor.current_page.find_child("PageKeyLineEdit").text)
		Pages.editor.current_page.save()
		Pages.editor.current_page.enable_page_key_edit(false)
	
	Pages.editor.load_page(to)

func change_page_references_dir(changed_page: int, operation:int):
	Pages.change_page_references_dir(changed_page, operation)

func create_page(at, overwrite_existing:= false):
	Pages.create_page(at, overwrite_existing)

func delete_page(at):
	Pages.delete_page_data(at)

func add_page(at:int):
	Pages.add_page_data(at)
	Pages.change_page_references_dir(at, 1)
	Pages.editor.load_page(at)


func move_line(line:Line, dir:int):
	Pages.editor.current_page.move_line(line, dir)
