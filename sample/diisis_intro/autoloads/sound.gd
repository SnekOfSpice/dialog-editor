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

func set_audio_player_volume(player:AudioStreamPlayer, volume:float):
	player.volume_db = linear_to_db(volume)


func play_bgm(bgm:String, fade_in:=0.0, from:=0.0):
	if bgm_key == bgm:
		return
	
	bgm_key = bgm
	
	var music_player = AudioStreamPlayer.new()
	music_player.connect("tree_exiting", audio_players.erase.bind(music_player))
	main_audio_player = music_player
	music_player.stream = load(str("res://sample/diisis_intro/sounds/music/", bgm_key))
	music_player.volume_db = -80
	music_player.set_bus("Music")
	
	if fade_in > 0.0:
		var t = create_tween()
		t.tween_method(
			set_audio_player_volume,
			set_audio_player_volume.bind(music_player, 0.0),
			set_audio_player_volume.bind(music_player, 1.0),
			fade_in
			)
		for player in audio_players:
			t.set_parallel()
			t.tween_method(
			set_audio_player_volume,
			set_audio_player_volume.bind(player, db_to_linear(player.volume_db)),
			set_audio_player_volume.bind(player, 0.0),
			fade_in
			)
			t.tween_callback(player.queue_free)
	else:
		while not audio_players.is_empty():
			var player : AudioStreamPlayer = audio_players.front()
			player.queue_free()
		music_player.volume_db = linear_to_db(Options.music_volume)
	
	audio_players.append(music_player)
	add_child(music_player)
	music_player.play(from)
	
	
