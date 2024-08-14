extends Control


func _ready() -> void:
	ParserEvents.fact_changed.connect(build_fact_list)
	find_child("PageSpinBox").max_value = Parser.page_data.size() - 1
	find_child("PageKeyLabel").text = Parser.get_page_key(0)
	find_child("AutoContinueCheckButton").button_pressed = Parser.line_reader.auto_continue
	build_fact_list()

func build_fact_list(_a=null,_b=null,_c=null):
	find_child("FactsList").clear()
	for fact_name in Parser.facts:
		var icon:Texture2D
		var fact_value = Parser.get_fact(fact_name)
		if fact_value is bool:
			icon = load("res://addons/diisis/editor/visuals/true.png") if fact_value else load("res://addons/diisis/editor/visuals/false.png")
		elif fact_value is int:
			var label = Label.new()
			label.text = str(fact_value)
			var vp = SubViewport.new()
			vp.add_child(label)
			add_child(vp)
			vp.size = label.size
			await RenderingServer.frame_post_draw
			icon = vp.get_texture()
		find_child("FactsList").add_item(fact_name, icon)

func _on_reset_facts_pressed() -> void:
	Parser.reset_facts()
	build_fact_list()

func _on_change_fact_button_pressed() -> void:
	for idx in find_child("FactsList").get_selected_items():
		var fact = find_child("FactsList").get_item_text(idx)
		Parser.change_fact(fact, find_child("FactValueButton").button_pressed)
	build_fact_list()


func _on_load_page_button_pressed() -> void:
	if GameWorld.game_stage:
		GameWorld.game_stage.set_all_characters_visible(false)
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
