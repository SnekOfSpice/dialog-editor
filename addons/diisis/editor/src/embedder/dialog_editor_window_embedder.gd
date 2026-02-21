@tool
extends Control
class_name DialogEditorWindowEmbedder


var window : Window


func _ready() -> void:
	item_rect_changed.connect(on_item_rect_changed)
	on_item_rect_changed()


func add_window(editor_window : DiisisEditorWindow):
	window = editor_window
	%SubViewport.add_child(editor_window)
	
	window.call_deferred("popup")
	#window.transient = false
	window.borderless = true
	on_item_rect_changed()


func on_item_rect_changed():
	if not window:
		return
	window.size = size
	%SubViewport.size = size
	window.position = EditorInterface.get_editor_main_screen().global_position
	print(window.position)

func _on_visibility_changed() -> void:
	if not window:
		return
	window.visible = visible
