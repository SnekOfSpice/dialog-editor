@tool
extends VBoxContainer


func serialize() -> Dictionary:
	return {
		"name" : $Label.text,
		"value" : $LineEdit.text
	}

func deserialize(data: Dictionary):
	$Label.text = data.get("name")
	$LineEdit.text = data.get("value")
