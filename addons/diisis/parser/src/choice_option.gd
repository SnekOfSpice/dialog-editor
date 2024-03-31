extends Button
class_name ChoiceButton

var facts := {}
var do_jump_page := false
var target_page := 0

signal choice_pressed(do_jump_page, target_page)

func _ready() -> void:
	connect("pressed", on_pressed)

func on_pressed() -> void:
	# apply facts
	for f in facts.keys():
		Parser.change_fact(f, facts.get(f))
	
	emit_signal("choice_pressed", do_jump_page, target_page)
	ParserEvents.start("choice_pressed",{
		"do_jump_page":do_jump_page,
		"target_page":target_page,
		"choice_text": text,
	})
	visible = false
