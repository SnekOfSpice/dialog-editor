extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	find_child("PageSelect").max_value = Pages.get_page_count() - 1


func deserialize(data:Dictionary):
	$LineEdit.text = data.get("choice_text")
	find_child("PageSelect").value = data.get("target_page")
	
	update()

func serialize():
	return {
		"choice_text": $LineEdit.text,
		"target_page": find_child("PageSelect").value
	}

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var default_target = int(find_child("PageSelect").value)
	default_target = min(default_target, Pages.get_page_count() - 1)
	
	find_child("PageKeyLabel").text = Pages.page_data.get(default_target).get("page_key")
	find_child("PageSelect").value = default_target


func _on_delete_pressed() -> void:
	queue_free()
