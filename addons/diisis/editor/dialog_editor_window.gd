@tool
extends Window

# TODO
# init the editor
# refactor all classes to @tool and a manual call of init() instead of _ready

signal editor_closed()

func _on_about_to_popup() -> void:
	find_child("Editor").init()
	pass
	find_child("Editor").position = -size*0.5
	print($Icon.position)
	print(find_child("Editor").position)
	get_viewport().canvas_transform = get_viewport().canvas_transform.translated(size*0.5)
	get_viewport().get_camera_2d().offset = (size*0.5)
	#find_child("SubViewport").size = size

func _process(delta: float) -> void:
	#$Node.position = Vector2.ZERO - Vector2.ONE * 122
	#$SubViewportContainer/SubViewport.size = size * 0.5
	#$Editor.position.x += 1
	pass
	#find_child("Editor").position = -size
	#find_child("Editor")
	#print($Camera2D.position)
	#$Camera2D.position.x -= 23 * delta
	#$Camera2D.enabled = true

func _on_close_requested() -> void:
	emit_signal("editor_closed")
	hide()
	queue_free()


func _on_size_changed() -> void:
	if not get_viewport().get_camera_2d():
		return
	get_viewport().get_camera_2d().offset = (size*0.5)
	#find_child("Editor").position = size
	#find_child("SubViewport").size = size
