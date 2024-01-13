extends Control
class_name GraphNodee

var page_index := 0
var children := []

signal page_button_pressed(page_index:int)

func _ready() -> void:
	connect("page_button_pressed", Pages.editor.load_page)
	

func set_page_index(value:int):
	page_index = value
	$Button.text = str(page_index)
	$Label.text = Pages.get_page_key(page_index)

func get_center():
	return size * 0.5


func _on_button_pressed() -> void:
	Pages.editor.set_graph_view_visible(false)
	emit_signal("page_button_pressed", page_index)
