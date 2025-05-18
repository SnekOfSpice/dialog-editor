@tool
extends Control

func init():
	for child in $TabContainer.get_children():
		child.init()
	$TabContainer.current_tab = 0
	_on_tab_container_tab_changed(0)

func select_function(method:String):
	$TabContainer.current_tab = 0
	_on_tab_container_tab_changed(0)
	find_child("Arguments").select_function(method)

func _on_tab_container_tab_changed(tab: int) -> void:
	find_child("TabContainer").get_child(tab).init()
	match tab:
		0: # arguments
			find_child("Arguments").find_child("MethodSearch").grab_focus()

func get_unsaved_change_tabs() -> Array:
	var unsaved_args : bool = "*" in find_child("Arguments").find_child("SaveButton").text
	var unsaved_handlers : bool = "*" in find_child("Handler Paths").find_child("SaveEvaluatorChangesButton").text
	
	var result := []
	if unsaved_args:
		result.append("Arguments")
	if unsaved_handlers:
		result.append("Handler Paths")
	
	return result
