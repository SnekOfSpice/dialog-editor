@tool
extends Node


func add_line(at, data:={}):
	if not Pages.editor.current_page:
		Pages.editor.insert_page(0)
	Pages.editor.current_page.add_line(at, data)
	await get_tree().process_frame
	Pages.editor.current_page.update()

func delete_line(at):
	Pages.editor.current_page.delete_line(at)
func delete_single_line(at):
	Pages.editor.current_page.delete_single_line(at)

func add_lines(at:int, line_data:Array):
	await get_tree().process_frame
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
