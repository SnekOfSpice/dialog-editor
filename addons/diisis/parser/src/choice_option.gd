extends Button
class_name ChoiceButton

var facts := {}
var do_jump_page := false
var target_page := 0
var target_line := 0

signal choice_pressed(do_jump_page, target_page, target_line)

func _ready() -> void:
	connect("pressed", on_pressed)

func on_pressed() -> void:
	# apply facts
	for f in facts.values():
		Parser.change_fact(f)
	
	emit_signal("choice_pressed", do_jump_page, target_page, target_line)
	ParserEvents.choice_pressed.emit(
		do_jump_page,
		target_page,
		target_line,
		text,
	)
	visible = false
