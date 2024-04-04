@tool
extends Node

var cached_lines := {}

func add_line(at, data:={}):
	if not Pages.editor.current_page:
		Pages.editor.insert_page(0)
	# if cached line exists, use that as data
	if cached_lines.has(Pages.editor.current_page.number):
		var lines : Dictionary = cached_lines.get(Pages.editor.current_page.number)
		if lines.has(at):
			data = lines[at]
	Pages.editor.current_page.add_line(at, data)
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_line(at):
	Pages.editor.current_page.delete_line(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()


func delete_single_line(at):
	# cache data at that coord
	
	if cached_lines.has(Pages.editor.current_page.number):
		var lines : Dictionary = cached_lines.get(Pages.editor.current_page.number)
		lines[at] = Pages.editor.current_page.get_line_data(at)
	else:
		cached_lines[Pages.editor.current_page.number] = {at:Pages.editor.current_page.get_line_data(at)}
	
	Pages.editor.current_page.delete_single_line(at)
	
	await get_tree().process_frame
	Pages.editor.current_page.update()

func add_lines(at:int, line_data:Array):
	Pages.editor.current_page.add_lines(at, line_data)
	
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

func insert_page(at:int):
	Pages.insert_page_data(at)
	Pages.change_page_references_dir(at, 1)
	Pages.editor.load_page(at)
