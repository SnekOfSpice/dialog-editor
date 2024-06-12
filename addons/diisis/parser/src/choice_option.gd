extends Button
class_name ChoiceButton

var facts := {}
var do_jump_page := false
var target_page := 0
var target_line := 0

var loopback:=false
var loopback_target_page:=0
var loopback_target_line:=0

signal choice_pressed(
	do_jump_page:bool,
	target_page:int,
	target_line:int,
	loopback:bool,
	loopback_target_page:int,
	loopback_target_line:int,
	)

func _ready() -> void:
	connect("pressed", on_pressed)

func on_pressed() -> void:
	# apply facts
	for f in facts.values():
		Parser.change_fact(f)
	
	if loopback:
		Parser.loopback_target_page = Parser.page_index
		Parser.loopback_target_line = Parser.line_index
		Parser.loopback_trigger_page = loopback_target_page
		Parser.loopback_trigger_line = loopback_target_line
		
	emit_signal("choice_pressed", do_jump_page, target_page, target_line)
	ParserEvents.choice_pressed.emit(
		do_jump_page,
		target_page,
		target_line,
		loopback,
		loopback_target_page,
		loopback_target_line,
		text,
	)
	visible = false
