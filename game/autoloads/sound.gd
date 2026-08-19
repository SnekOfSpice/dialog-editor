extends Node



var clip_names := []


var player : AudioStreamPlayer:
	get():
		return $AudioStreamPlayer
var playback : AudioStreamPlaybackInteractive:
	get():
		return $AudioStreamPlayer.get_stream_playback()
var stream : AudioStreamInteractive:
	get():
		return $AudioStreamPlayer.stream
var clip_index:int:
	get():
		return playback.get_current_clip_index()

func _ready() -> void:
	for i in stream.clip_count:
		clip_names.append(stream.get_clip_name(i))
	
	#EventBus.new_game_started.connect(func():
		#if Game.release:
			#set_music_volume_linear(0, 2)
		#)


func set_music_volume_linear(value : float, duration : float, delay := 0.0):
	var t = create_tween()
	t.set_parallel()
	t.tween_property($AudioStreamPlayer, "volume_linear", value, duration).set_delay(delay)
	

func get_current_clip_name() -> StringName:
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	return stream.get_clip_name(playback.get_current_clip_index())


func serialize() -> Dictionary:
	var data := {}
	
	data["current_clip"] = get_current_clip_name()
	
	return data


func deserialize(data:Dictionary):
	switch_to(data.get("current_clip", ""))


func play_sfx(sfx:String, random_pitch := true, bus := "SFX") -> AudioStreamPlayer:
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = load(CONST.fetch("SFX", sfx))
	sfx_player.set_bus(bus)
	add_child(sfx_player)
	sfx_player.play()
	if random_pitch:
		sfx_player.pitch_scale = randf_range(0.75, 1.0 / 0.75)
	sfx_player.finished.connect(sfx_player.queue_free)
	
	return sfx_player


func switch_to(clip_name : StringName):
	var current_clip_name : StringName = get_current_clip_name()
	
	if current_clip_name == clip_name:
		return
	
	playback.switch_to_clip_by_name(clip_name)
