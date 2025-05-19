extends Node2D
class_name Character

@export var character_name := ""

## dictionary for overlay-style sprites. should be laid out like so:
## [codeblock]
## var extras := {
##     # needs to be called "default"
##     "default" : {
##        "extra1" : Object,
##        "extra2" : Object
##        },
##     # override for emotion with this name, sorted by extra
##     "emotion1" : { 
##        # extra1 will change when emotion1 is displayed
##        "extra1" : Object
##        }
## }
## [/codeblock]
## All [Object]s should be pngs you drag in there
@export var extras : Dictionary[String, Dictionary] = {
	"default" : {}
}
var fade_in := 0.4
var fade_out := 0.4
var fade_tween

var emotion := ""

var target_x := 0.0
var target_visibility := visible

var emotions_by_page := {}

@onready var active_mat = $Sprite.get_material()

func _ready():
	for emotion_name in extras.keys():
		var group =  Node2D.new()
		group.name = emotion_name
		$Extras.add_child(group)
		
		var extras_in_emotion : Dictionary = extras.get(emotion_name)
		for extra_name in extras_in_emotion.keys():
			var tex = Sprite2D.new()
			tex.name = extra_name
			tex.texture = extras_in_emotion.get(extra_name)
			tex.visible = false
			group.add_child(tex)
			if tex.texture.get_size().x > $Sprite.texture.get_size().x:
				tex.position.x += 0.5 * (tex.texture.get_size().x - $Sprite.texture.get_size().x)
		
		group.visible = false
	
	set_emotion("neutral")
	ParserEvents.dialog_line_args_passed.connect(on_dialog_line_args_passed)
	add_to_group("character")
	target_x = position.x
	
	
	
	visibility_changed.connect(on_visibility_changed)

func set_x_position(idx:int, time := 0, advance_instruction_after_reposition:=false):
	var position0 = 195
	var position6 = 822
	@warning_ignore("integer_division")
	var fraction = (position6 - position0) / 7
	target_x = position0 + idx * fraction
	
	var t = create_tween()
	t.tween_property(self, "position:x", target_x, time)
	
	if advance_instruction_after_reposition and Parser.line_reader:
		t.finished.connect(Parser.inform_instruction_completed)

func serialize() -> Dictionary:
	var result := {}
	
	result["visible"] = target_visibility
	result["emotion"] = emotion
	result["target_x"] = target_x
	result["emotions_by_page"] = emotions_by_page
	result["progress"] = active_mat.get_shader_parameter("progress")
	
	var extra_data := {}
	for group : Node2D in $Extras.get_children():
		var group_data := {}
		for item : Sprite2D in group.get_children():
			group_data[item.name] = item.visible
		extra_data[group.name] = group_data
	result["extras"] = extra_data
	
	return result

func deserialize(data: Dictionary):
	set_emotion(data.get("emotion", "neutral"))
	position.x = data.get("target_x", position.x)
	target_x = data.get("target_x", position.x)
	visible = data.get("visible", false)
	target_visibility = data.get("visible", false)
	emotions_by_page = data.get("emotions_by_page", {})
	active_mat.set_shader_parameter("progress", data.get("progress", 0.0))
	
	var extra_data : Dictionary = data.get("extras", {})
	for group : Dictionary in extra_data.values():
		for item_name in group.keys():
			set_extra_visible(item_name, group.get(item_name))

func on_dialog_line_args_passed(actor_name: String, dialog_line_args: Dictionary):
	if actor_name == character_name:
		active_mat.set_shader_parameter("progress", 0.469)
	else:
		active_mat.set_shader_parameter("progress", 0.0)
	if emotion != "invisible" and actor_name == character_name:
		visible = true
	if dialog_line_args.has(str(character_name, "-emotion")):
		var new_emotion : String = dialog_line_args.get(str(character_name, "-emotion"))
		emotion = new_emotion.trim_suffix("-emotion")
		set_emotion(emotion)


func set_emotion(emotion_name:String):
	emotion = emotion_name
	if emotion_name == "invisible" or emotion_name.is_empty():
		target_visibility = false
		if fade_tween:
			fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.finished.connect(self.set.bind("visible", false))
		fade_tween.tween_property(self, "modulate:a", 0, fade_out * modulate.a)
		return
	visible = true
	find_child("Sprite").texture = load(str("res://game/characters/sprites/", character_name, "-", emotion, ".png"))
	
	var special_extra := false
	for group : Node2D in $Extras.get_children():
		if group.name == emotion:
			group.visible = true
			special_extra = true
		else:
			group.visible = false
	
	if not special_extra and $Extras.get_node("default"):
		$Extras.get_node("default").visible = true

func set_extra_visible(extra_name : String, visibility : bool, hide_others:=false):
	for group : Node2D in $Extras.get_children():
		for item : Sprite2D in group.get_children():
			if item.name == extra_name:
				item.visible = visibility
			elif hide_others:
				item.visible = false

func on_visibility_changed():
	target_visibility = visible
	if visible and fade_in == 0:
		return
	if not visible:
		return
	
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	
	if visible:
		modulate.a = 0
		fade_tween.tween_property(self, "modulate:a", 1, fade_in)
	
	fade_tween.finished.connect(fade_tween.kill)

## circumvents fade_out.
func set_invisible():
	visible = false
