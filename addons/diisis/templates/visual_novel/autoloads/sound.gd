extends Node

var bgm_key := ""

var audio_players := []
var main_audio_player : AudioStreamPlayer

func serialize() -> Dictionary:
	var data := {}
	
	data["bgm_key"] = bgm_key
	data["playback_position"] = main_audio_player.get_playback_position()
	
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

func play_sfx(sfx:String):
	var player := AudioStreamPlayer.new()
	player.stream = load(str(CONST.SFX_ROOT, sfx))
	player.set_bus("SFX")
	add_child(player)
	player.play()

func play_bgm(bgm:String, fade_in:=0.0, from:=0.0):
	if bgm_key == bgm:
		return
	
	bgm_key = bgm 
	
	var music_player = AudioStreamPlayer.new()
	music_player.connect("tree_exiting", audio_players.erase.bind(music_player))
	main_audio_player = music_player
	music_player.stream = load(str(CONST.MUSIC_ROOT, bgm_key))
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
		#for player in audio_players:
			#t.set_parallel()
			#t.tween_method(
			#set_audio_player_volume,
			#db_to_linear(player.volume_db),
			#0.0,
			#fade_in
			#)
			#t.tween_callback(player.queue_free)
	else:
		while not audio_players.is_empty():
			var player : AudioStreamPlayer = audio_players.pop_front()
			player.queue_free()
		music_player.volume_db = linear_to_db(Options.music_volume)
	
	audio_players.append(music_player)
	add_child(music_player)
	music_player.play(from)
	
	
