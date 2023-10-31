extends VBoxContainer


var is_editing_default := false
var property_name := ""
var _old_property_name := ""
var serialized_value := []
var _old_serialized_value := []

var data_type := Pages.DataTypes._String
var drop_down_title := ""

func _ready() -> void:
	update_drop_downs()

func update_drop_downs():
	find_child("DropDownButton").clear()
	for title in Pages.dropdown_titles:
		find_child("DropDownButton").add_item(title)
	
	if not Pages.dropdown_titles.front():
		return
	
	find_child("DropDownButton").select(0)
	
	for title in Pages.dropdowns.get(Pages.dropdown_titles[find_child("DropDownButton").get_selected_id()]):
		find_child("DropDownValueButton").add_item(title)

func set_editing_default(value: bool):
	is_editing_default = value
	find_child("PropertyNameEdit").visible = is_editing_default
	find_child("PropertyNameLabel").visible = not is_editing_default

func set_property_name():
	pass

func _on_drop_down_button_item_selected(index: int) -> void:
	find_child("DropDownValueButton").clear()
	for title in Pages.dropdowns.get(Pages.dropdown_titles[index]):
		find_child("DropDownValueButton").add_item(title)
