@tool
extends Window


func _on_about_to_popup() -> void:
	$HandlerSetupContainer.init()

func select_function(method:String):
	$HandlerSetupContainer.select_function(method)

func _on_close_requested() -> void:
	hide()
