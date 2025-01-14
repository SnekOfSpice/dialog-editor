extends Node2D

var page := 0


func _ready() -> void:
	$Clean.text = $Handwriting.text


func _on_font_button_pressed() -> void:
	$Handwriting.visible = not $Handwriting.visible
	$Clean.visible = not $Clean.visible

func show_poem():
	page = 1

func _on_read_button_pressed() -> void:
	#if page == 0:
		#show_poem()
		#return
	if GameWorld.game_stage:
		GameWorld.game_stage.show_ui()
	if Parser.line_reader:
		Parser.line_reader.instruction_handler.instruction_completed.emit()
	queue_free()
