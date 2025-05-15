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
