@tool
extends Control

var number := 0

signal move_page (page_number, current_n, new_n)
signal go_to(page_number)
signal on_direct_swap (page_number)

func _ready() -> void:
	find_child("DirectStartedLabel").text = ""

func set_number(n: int):
	if not Pages.page_data.keys().has(n):
		return
	
	number = n
	
	find_child("NumberLabel").text = str(n)
	find_child("KeyLabel").text = Pages.page_data.get(n).get("page_key")
	
	find_child("DownButton").disabled = number <= 0
	find_child("UpButton").disabled = number >= Pages.get_page_count() - 1
	
	find_child("WordCountLabel").text = str(Pages.get_word_count_on_page_approx(number))


func _on_up_button_pressed() -> void:
	emit_signal("move_page", number, number + 1)


func _on_down_button_pressed() -> void:
	emit_signal("move_page", number, number - 1)


func _on_direct_swap_button_pressed() -> void:
	emit_signal("on_direct_swap", number)
	find_child("DirectStartedLabel").text = ">>"


func _on_go_to_button_pressed() -> void:
	emit_signal("go_to", number)
