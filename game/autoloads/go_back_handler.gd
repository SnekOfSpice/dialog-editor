extends Node


var states_by_page := {}

func _ready() -> void:
	ParserEvents.go_back_accepted.connect(on_go_back_accepted)
	ParserEvents.read_new_line.connect(on_read_new_line)

func on_read_new_line(line:int):
	await get_tree().process_frame
	#line -= 1
	# save the state
	var state := {}
	
	state["Sound"] = Sound.serialize()
	if is_instance_valid(Game.game_stage):
		state["game_stage"] = Game.game_stage.serialize()
	
	if states_by_page.has(Parser.page_index):
		states_by_page[Parser.page_index][line] = state
	else:
		states_by_page[Parser.page_index] = {line : state}

func on_go_back_accepted(page:int, line:int, _a):
	if not states_by_page.has(page):
		return
	if not states_by_page[page].has(line):
		return
	
	# handle payload
	var state : Dictionary = states_by_page[page][line]
	var characters : Dictionary = state.get("characters", {})
	for character : Character in get_tree().get_nodes_in_group("character"):
		character.deserialize(characters.get(character.character_name, {}))
	
	
	if is_instance_valid(Game.game_stage):
		Game.game_stage.deserialize(state.get("game_stage", {}))

	Sound.deserialize(state.get("Sound", {}))

func serialize() -> Dictionary:
	return {"states_by_page" : states_by_page}

func deserialize(data: Dictionary):
	states_by_page = data.get("states_by_page", {})
