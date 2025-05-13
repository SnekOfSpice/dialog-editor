@tool
extends Control

func init():
	find_child("Evaluator Paths").init()
	find_child("Arguments").init()
	$TabContainer.current_tab = 0
	_on_tab_container_tab_changed(0)


func _on_tab_container_tab_changed(tab: int) -> void:
	match tab:
		0: # arguments
			find_child("Arguments").find_child("MethodSearch").grab_focus()
