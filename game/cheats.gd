extends Control

var ff_goal_page := 0
var ff_goal_line := 0
var ff_active := false
var ff_prev_text_speed := 60.0

func _ready() -> void:
	await get_tree().process_frame
	ParserEvents.fact_changed.connect(build_fact_list)
	ParserEvents.read_new_page.connect(on_read_new_page)
	ParserEvents.read_new_line.connect(on_read_new_line)
	find_child("PageSpinBox").max_value = Parser.page_data.size() - 1
	find_child("PageKeyLabel").text = Parser.get_page_key(0)
	find_child("AutoContinueCheckButton").button_pressed = Parser.line_reader.auto_continue
	build_fact_list()

func on_read_new_page(number:int):
	find_child("CurrentPageLabel").text = str("Current Page: ", number, " - ", Parser.get_page_key(number))

func on_read_new_line(index:int):
	if not ff_active:
		return
	if Parser.page_index == ff_goal_page and index == ff_goal_line:
		Parser.line_reader.auto_continue = false
		ff_active = false
		Parser.line_reader.text_speed = ff_prev_text_speed
		GameWorld.skip = false

func build_fact_list():
	find_child("FactsList").clear()
	for fact in Parser.facts:
		var icon:Texture2D
		if Parser.get_fact(fact):
			icon = load("res://addons/diisis/editor/visuals/true.png")
		else:
			icon = load("res://addons/diisis/editor/visuals/false.png")
		find_child("FactsList").add_item(fact, icon)

func _on_reset_facts_pressed() -> void:
	Parser.reset_facts()
	build_fact_list()

func _on_change_fact_button_pressed() -> void:
	for idx in find_child("FactsList").get_selected_items():
		var fact = find_child("FactsList").get_item_text(idx)
		Parser.change_fact(fact, find_child("FactValueButton").button_pressed)
	build_fact_list()


func _on_load_page_button_pressed() -> void:
	#GameState.game.set_all_characters_visible(false)
	Parser.read_page(find_child("PageSpinBox").value, find_child("LineSpinBox").value)


func _on_auto_continue_check_button_pressed() -> void:
	Parser.line_reader.auto_continue_delay = 0.0
	Parser.line_reader.auto_continue = find_child("AutoContinueCheckButton").button_pressed


func _on_page_spin_box_value_changed(value: float) -> void:
	find_child("PageKeyLabel").text = Parser.get_page_key(int(value))
	find_child("LineSpinBox").value = 0
	var data = Parser.page_data
	var page = data.get(int(find_child("PageSpinBox").value))
	find_child("LineSpinBox").max_value = page.get("lines").size()


func _on_read_line_button_pressed() -> void:
	Parser.line_reader.emit_signal("line_finished", Parser.line_reader.line_index)

func _on_ff_button_pressed() -> void:
	Parser.read_page(0, 0)
	ff_goal_page = find_child("PageSpinBox").value
	ff_goal_line = find_child("LineSpinBox").value
	ff_active = true
	ff_prev_text_speed = Parser.line_reader.text_speed
	Parser.line_reader.auto_continue = true
	Parser.line_reader.text_speed = LineReader.MAX_TEXT_SPEED
	GameWorld.skip = true
