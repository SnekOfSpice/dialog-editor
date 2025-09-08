extends Control

#@export var skip := false


@onready var logo_tex : Sprite2D = $Parts/Logo
@onready var char_tex : Sprite2D = $Parts/Character
@onready var name_tex : RichTextLabel = $Parts/Name

var start_positions = {}

signal chapter_intro_finished()

func _ready() -> void:
	visible = false
	modulate.a = 0
	
	start_positions[logo_tex] = logo_tex.position
	start_positions[char_tex] = char_tex.position
	start_positions[name_tex] = name_tex.position
	

func set_chapter_cover(pov_name: String, bottom_text: String, new_background: String, zoom: float, bgm: String):
	if GameWorld.skip:
		if GameWorld.camera:
			GameWorld.camera.zoom_to(zoom, 0)
		Sound.play_bgm(bgm)
		GameWorld.game_stage.set_background(new_background)
		emit_signal("chapter_intro_finished")
		
		GameWorld.game_stage.set_background(new_background)
		GameWorld.camera.zoom_to(zoom, 0.0)
		GameWorld.camera.move_to(0,0,0)
		GameWorld.hide_all_characters()
		Sound.play_bgm(bgm)
		if GameWorld.game_stage:
			GameWorld.game_stage.set_static(0)
			GameWorld.game_stage.set_fade_out(0, 0)
			GameWorld.game_stage.hide_cg()
		
		if bgm != Sound.bgm_key:
			Sound.fade_out_bgm(0)
		return
	
	for part in $Parts.get_children():
		part.visible = true
	$AssembledTexture.texture = null
	
	var logo_tween = create_tween()
	var char_tween = create_tween()
	var name_tween = create_tween()
	
	for extra in char_tex.get_children():
		extra.queue_free()
	match pov_name:
		"anhedonia":
			char_tex.texture = load("res://game/characters/sprites/anhedonia-neutral.png")
		"one":
			char_tex.texture = load("res://game/characters/sprites/one-neutral.png")
			var eye_progress : int = GameWorld.game_stage.get_character("one").eye_progress
			if eye_progress > 0:
				var eyes = Sprite2D.new()
				char_tex.add_child(eyes)
				#eyes.centered = false
				eyes.texture = load(str("res://game/characters/sprites/neutral-stage", eye_progress, ".png"))
			var outfit = Sprite2D.new()
			outfit.texture = load("res://game/characters/sprites/oneOutfit.png")
			char_tex.add_child(outfit)
	
	logo_tween.set_parallel()
	char_tween.set_parallel()
	name_tween.set_parallel()
	
	if bottom_text == "EMPTY":
		name_tex.text = ""
	else:
		name_tex.text = str("[right]", bottom_text)
	
	name_tex.position = start_positions[name_tex]
	logo_tex.position = start_positions[logo_tex]
	char_tex.position = start_positions[char_tex]
	
	logo_tex.modulate.a = 0
	char_tex.modulate.a = 0
	name_tex.modulate.a = 0
	
	var black_delay := 0.0
	if Parser.page_index == 0:
		$Black.visible = true
		var black_tween = create_tween()
		black_tween.set_parallel()
		black_delay = 4.0 + 3
		black_tween.tween_property($Black, "modulate:a", 0.0, black_delay).set_delay(3.0)
	else:
		$Black.visible = false
	
	var logo_delay := 0.8 + black_delay
	var char_delay := 4.0 + black_delay
	var name_delay := 5.7 + black_delay
	
	var logo_duration = 5.0
	var char_duration = 2.0
	var name_duration = 4.0
	
	logo_tween.tween_property(logo_tex, "position", logo_tex.position + Vector2(0, -30), logo_duration).set_delay(logo_delay).set_ease(Tween.EASE_OUT)
	char_tween.tween_property(char_tex, "position", char_tex.position + Vector2(0, -30), char_duration).set_delay(char_delay).set_ease(Tween.EASE_OUT)
	name_tween.tween_property(name_tex, "position", name_tex.position + Vector2(0, -30), name_duration).set_delay(name_delay).set_ease(Tween.EASE_OUT)
	logo_tween.tween_property(logo_tex, "modulate:a", 1, 1.0).set_delay(logo_delay + 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	char_tween.tween_property(char_tex, "modulate:a", 1, 3.0).set_delay(char_delay + 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	name_tween.tween_property(name_tex, "modulate:a", 1, 3.0).set_delay(name_delay + 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	
	modulate.a = 0.0
	visible = true
	
	var mod_tween = create_tween()
	mod_tween.finished.connect(start_fade_timer)
	mod_tween.tween_property(self, "modulate:a", 1, 0.3)
	mod_tween.set_parallel()
	
	var full_fade_in_after : float = max(max((logo_delay + logo_duration), (char_delay + char_duration)), (name_delay + name_duration))
	
	mod_tween.tween_property(self, "modulate:a", 0, 2.4).set_delay(full_fade_in_after + 4)
	
	get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.game_stage.set_background.bind(new_background))
	get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.camera.zoom_to.bind(zoom, 0.0))
	get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.camera.move_to.bind(0,0,0))
	get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.hide_all_characters)
	get_tree().create_timer(full_fade_in_after).timeout.connect(Sound.play_bgm.bind(bgm))
	if GameWorld.game_stage:
		get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.game_stage.set_static.bind(0))
		get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.game_stage.set_fade_out.bind(0, 0))
		get_tree().create_timer(full_fade_in_after).timeout.connect(GameWorld.game_stage.hide_cg)
	
	if bgm != Sound.bgm_key:
		Sound.fade_out_bgm(full_fade_in_after)
	#get_tree().create_timer(full_fade_in_after).timeout.connect(replace_with_assembled_texture)
	#
#func replace_with_assembled_texture():
	#$AssembledTexture.texture = get_viewport().get_texture().get_image()

func start_fade_timer():
	get_tree().create_timer(2).timeout.connect(emit_signal.bind("chapter_intro_finished"))
