extends Node


var states_by_page := {}

func _ready() -> void:
	ParserEvents.go_back_accepted.connect(on_go_back_accepted)
	ParserEvents.read_new_line.connect(on_read_new_line)

func on_read_new_line(line:int):
	line -= 1
	# save the state
	var state := {}
	
	var characters := {}
	for character : Character in get_tree().get_nodes_in_group("character"):
		characters[character.character_name] = character.serialize()
	#state["characters"] = characters
	state["background"] = GameWorld.background
	state["bgm"] = Sound.bgm_key
	if is_instance_valid(GameWorld.game_stage):
		state["game_stage"] = GameWorld.game_stage.serialize()
	
	if states_by_page.has(Parser.page_index):
		states_by_page[Parser.page_index][line] = state
	else:
		states_by_page[Parser.page_index] = {line : state}

func on_go_back_accepted(page:int, line:int, _dialine:int):
	if not states_by_page.has(page):
		return
	if not states_by_page[page].has(line):
		return
	
	# handle payload
	var state : Dictionary = states_by_page[page][line]
	#var characters : Dictionary = state.get("characters", {})
	#for character : Character in get_tree().get_nodes_in_group("character"):
		#character.deserialize(characters.get(character.character_name, {}))
	
	if is_instance_valid(GameWorld.stage_root):
		GameWorld.stage_root.set_background(state.get("background", ""))
	
	if is_instance_valid(GameWorld.game_stage):
		GameWorld.game_stage.deserialize(state.get("game_stage", {}))

	Sound.play_bgm(state.get("bgm", Sound.bgm_key))

func serialize() -> Dictionary:
	return {"states_by_page" : states_by_page}

func deserialize(data: Dictionary):
	states_by_page = data.get("states_by_page", {})
