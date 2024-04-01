@tool
extends Node


func add_line(at):
	if not Pages.editor.current_page:
		Pages.editor.add_empty_page()
	Pages.editor.current_page.add_line(at)

func delete_line(at):
	Pages.editor.current_page.delete_line(at)
