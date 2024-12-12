extends Character


var blink_intervals := []
var eyelids := []
var eye_progress := 0

var blink_range := Vector2(2, 4)

@onready var eye_overlay:Node2D = $Eyes.get_child(0)

func _ready() -> void:
	super._ready()
	blink_intervals.clear()
	eyelids.clear()
	for emotion : Node2D in $Eyes.get_children():
		for stage : Sprite2D in emotion.get_children():
			for eyelid in stage.get_children():
				blink_intervals.append(randf_range(blink_range.x, blink_range.y))
				eyelids.append(eyelid)
				eyelid.visible = false
			stage.visible = false
	set_eye_progress(0)
	set_emotion("neutral")

func _process(delta: float) -> void:
	var blink_index := 0
	while blink_index < blink_intervals.size():
		blink_intervals[blink_index] -= delta
		if blink_intervals[blink_index] <= 0:
			blink_intervals[blink_index] = randf_range(blink_range.x, blink_range.y)
			var eyelid : Sprite2D = eyelids[blink_index]
			eyelid.visible = true
			var t = get_tree().create_timer(randf_range(0.25, 0.35))
			t.timeout.connect(eyelid.set.bind("visible", false))
		blink_index += 1

func serialize() -> Dictionary:
	var character_data = super.serialize()
	
	character_data["eye_progress"] = eye_progress
	
	return character_data

func deserialize(data:Dictionary):
	set_eye_progress(data.get("eye_progress", 0)) 
	super.deserialize(data)

func set_eye_progress(progress:int):
	eye_progress = progress
	
	for stage in eye_overlay.get_children():
		stage.visible = stage.get_index() + 1 == progress
	
var no_eyes := ["tortured", "suspended"]

func set_emotion(emotion_name:String):
	super.set_emotion(emotion_name)
	
	var overlay:Node2D
	for child in $Eyes.get_children():
		if child.name.to_lower() == emotion_name:
			overlay = child
			break
	if not overlay:
		overlay = $Eyes.get_child(0)
	eye_overlay = overlay
	
	for child in $Eyes.get_children():
		child.visible = child == overlay
	
	for stage in overlay.get_children():
		stage.visible = stage.get_index() + 1 == eye_progress
	
	var blacklisted := false
	for substr : String in no_eyes:
		if emotion_name.contains(substr):
			blacklisted = true
			break
	if blacklisted:
		for stage in overlay.get_children():
			stage.visible = false
	
	if emotion.begins_with("torture") or emotion.begins_with("suspended"):
		$OneOutfit.visible = false
		$Eyes.visible = false
	else:
		$OneOutfit.visible = true
		$Eyes.visible = true
	
	if emotion.begins_with("suspended"):
		$Sprite.offset.y = -110
	else:
		$Sprite.offset.y = 0
