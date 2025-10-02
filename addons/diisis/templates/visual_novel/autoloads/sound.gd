extends Node

var bgm_key := ""

var audio_players := []
var main_audio_player : AudioStreamPlayer

## Preserves the playback position when calling [method Sound.play_bgm] if the currently playing track and new track share the same prefix. E.g. "action_no_drums" and "action_full_instruments" would fade seamlessly between each other if this array contains "action".
@export var position_preserving_prefixes : Array[String]

func awa():
	print("awa")

func serialize() -> Dictionary:
	var data := {}
	
	data["bgm_key"] = bgm_key
	if main_audio_player:
		data["playback_position"] = main_audio_player.get_playback_position()
	else:
		data["playback_position"] = 0
	
	return data

func deserialize(data:Dictionary):
	play_bgm(data.get("bgm_key", ""), 0.0, data.get("playback_position", 0.0))

func set_audio_player_volume(volume:float):
	main_audio_player.volume_db = linear_to_db(volume)
	for player : AudioStreamPlayer in audio_players:
		if player == main_audio_player:
			continue
		player.volume_db = linear_to_db((1.0 - volume) / (audio_players.size() - 1))
		if db_to_linear(player.volume_db) <= 0.0:
			audio_players.erase(player)
			player.queue_free()

func play_sfx(sfx:String, random_pitch := true) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(CONST.fetch("SFX", sfx))
	player.set_bus("SFX")
	add_child(player)
	player.play()
	if random_pitch:
		player.pitch_scale = randf_range(0.75, 1.0 / 0.75)
	player.finished.connect(player.queue_free)
	return player

func play_bgm(bgm:String, fade_in:=0.0, from:=0.0):
	if bgm_key == bgm:
		return
	
	if bgm == "none" or bgm == "null":
		return
	
	var preserve_position := -1.0
	for prefix in position_preserving_prefixes:
		if bgm.begins_with(prefix) and bgm_key.begins_with(prefix):
			preserve_position = main_audio_player.get_playback_position()
	bgm_key = bgm 
	
	var music_player = AudioStreamPlayer.new()
	music_player.connect("tree_exiting", audio_players.erase.bind(music_player))
	main_audio_player = music_player
	
	var music_path := CONST.fetch("MUSIC", bgm_key)
	if not ResourceLoader.exists(music_path):
		push_error(str(music_path, " doesn't exist with key \"", bgm_key, "\""))
		return
	music_player.stream = load(music_path)
	music_player.volume_db = -80
	music_player.set_bus("Music")
	
	if fade_in > 0.0:
		var t = create_tween()
		t.tween_method(
			set_audio_player_volume,
			0.0,
			1.0,
			fade_in
			)
	else:
		while not audio_players.is_empty():
			var player : AudioStreamPlayer = audio_players.pop_front()
			player.queue_free()
		music_player.volume_db = linear_to_db(Options.music_volume)
	
	if preserve_position >= 0:
		from = preserve_position
	
	audio_players.append(music_player)
	add_child(music_player)
	music_player.play(from)
	

func fade_out_bgm(fade_out_time:float):
	if not main_audio_player:
		return
	play_bgm("silence", fade_out_time)
