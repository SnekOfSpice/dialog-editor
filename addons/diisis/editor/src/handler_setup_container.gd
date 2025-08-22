@tool
extends Control

func init():
	for child in $TabContainer.get_children():
		child.init()
	set_tab(0)

func set_tab(tab:int) -> void:
	$TabContainer.current_tab = tab
	_on_tab_container_tab_changed(tab)

func select_function(method:String):
	set_tab(0)
	find_child("Arguments").select_function(method)

func _on_tab_container_tab_changed(tab: int) -> void:
	find_child("TabContainer").get_child(tab).init()
	match tab:
		0: # arguments
			find_child("Arguments").find_child("MethodSearch").grab_focus()

func get_unsaved_change_tabs() -> Array:
	var unsaved_args : bool = "*" in find_child("Arguments").find_child("SaveButton").text
	var unsaved_handlers : bool = "*" in find_child("Paths").find_child("SaveEvaluatorChangesButton").text
	
	var result := []
	if unsaved_args:
		result.append("Arguments")
	if unsaved_handlers:
		result.append("Paths")
	
	return result
