extends HBoxContainer

var number := 0

signal move_page (page_number, current_n, new_n)

func set_number(n: int):
	if not Pages.page_data.keys().has(n):
		return
	
	number = n
	
	find_child("NumberLabel").text = str(n)
	find_child("KeyLabel").text = Pages.page_data.get(n).get("page_key")
	
	find_child("DownButton").disabled = number <= 0
	find_child("UpButton").disabled = number >= Pages.get_page_count() - 1


func _on_up_button_pressed() -> void:
	emit_signal("move_page", number, number + 1)


func _on_down_button_pressed() -> void:
	emit_signal("move_page", number, number - 1)
