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
	
	var characters := {}
	for character : Character in get_tree().get_nodes_in_group("character"):
		characters[character.character_name] = character.serialize()
	state["characters"] = characters
	state["background"] = GameWorld.game_stage.background
	state["bgm"] = Sound.bgm_key
	if is_instance_valid(GameWorld.game_stage):
		state["game_stage"] = GameWorld.game_stage.serialize()
	
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
	
	
	if is_instance_valid(GameWorld.game_stage):
		GameWorld.game_stage.deserialize(state.get("game_stage", {}))

	Sound.play_bgm(state.get("bgm", Sound.bgm_key))

func serialize() -> Dictionary:
	return {"states_by_page" : states_by_page}

func deserialize(data: Dictionary):
	states_by_page = data.get("states_by_page", {})

#
### default is at 0.0.0
#func store_into_subaddress(value, storage:Dictionary, subaddress:String) -> void:
	#storage[subaddress] = value
#
#func fetch_prev_from_subaddress(storage:Dictionary, start_page:int, start_line:int, start_dialine:int) -> Variant:
	#var state_subaddresses := storage.keys()
	#var start_subaddress := str(start_page, ".", start_line, ".", start_dialine)
	#state_subaddresses.append(start_subaddress)
	#state_subaddresses.sort_custom(sort_subaddrs)
	#var prev_state_index = state_subaddresses.find(start_subaddress) - 1
	#return storage.get(state_subaddresses[prev_state_index])
#
#func sort_subaddrs(a:String, b:String) -> bool:
	#var parts_a = a.split(".")
	#var parts_b = b.split(".")
	#while parts_a.size() < 3:
		#parts_a.append("0")
	#while parts_b.size() < 3:
		#parts_b.append("0")
	#if parts_a[0] == parts_b[0]:
		#if parts_a[1] == parts_b[1]:
			#return parts_a[2] < parts_b[2]
		#else:
			#return parts_a[1] < parts_b[1]
	#else:
		#return parts_a[0] < parts_b[0]
