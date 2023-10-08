extends Control


var _default
var property_name := ""

var value

signal property_changed(property_name, value)


func serialize() -> Dictionary:
	var d = {}
	
	d["property_name"] = property_name
	d["value"] = value
	
	return d

func deserlialize(data: Dictionary):
	_default = Pages.head_defaults.get(data.get("property_name"))
	property_name = data.get("property_name")
	value = data.get("value")
	
	update()

func update():
	$PropertyName.text = property_name
	find_child("LineEdit").text = str(value)
	find_child("LineEdit").placeholder_text = str(_default)

func _on_save_pressed() -> void:
	emit_signal("property_changed")
	update()
