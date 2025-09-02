extends Control


func _ready() -> void:
	visible = false



func start():
	visible = true
	
	var label : Label = find_child("Label")
	
	for text in ["DIISIS template demo", "created by Snek Remilia Ketter"]:
		label.text = text
		await get_tree().create_timer(2).timeout
	
	Parser.function_acceded()
