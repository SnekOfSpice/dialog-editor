@tool
extends Window


func _on_close_requested() -> void:
	hide()

func set_id(id:String):
	$ChangeTextIDContainer.fill(id)
