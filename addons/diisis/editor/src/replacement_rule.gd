@tool
extends HBoxContainer
class_name ReplacementRule

signal rule_updated()

func serialize() -> Dictionary:
	return {
		"enabled" : %CheckBox.button_pressed,
		"name" : %NameLabel.text,
		"symbol" : %SimpleSymbolLabel.text,
		"replacement" : %LineEdit.text,
	}

func deserialize(data:Dictionary):
	%CheckBox.button_pressed = data.get("enabled", false)
	%NameLabel.text = data.get("name", "")
	%SimpleSymbolLabel.text = data.get("symbol", "")
	%LineEdit.text = data.get("replacement", "")

func notify_rule_update(_a:=""):
	emit_signal("rule_updated")

func _on_delete_button_pressed() -> void:
	notify_rule_update()
	queue_free()
