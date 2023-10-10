extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PageSelect.max_value = Pages.get_page_count() - 1


func deserialize(data:Dictionary):
	$LineEdit.text = data.get("choice_text")
	$PageSelect.value = data.get("target_page")
	
	update()

func serialize():
	return {
		"choice_text": $LineEdit.text,
		"target_page": $PageSelect.value
	}

func _on_page_select_value_changed(value: float) -> void:
	update()

func update():
	var default_target = int($PageSelect.value)
	default_target = min(default_target, Pages.get_page_count() - 1)
	
	$PageKeyLabel.text = Pages.page_data.get(default_target).get("page_key")
	$PageSelect.value = default_target


func _on_delete_pressed() -> void:
	queue_free()
