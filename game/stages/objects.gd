extends Node2D

var tween_by_object := {}

func _ready() -> void:
	for o : Node2D in get_children():
		o.modulate.a = 0.0

func serialize() -> Dictionary:
	var result := {}
	
	for o : Node2D in get_children():
		result[o.name] = o.visible
	
	return result

func deserialize(data:Dictionary):
	for o : Node2D in get_children():
		set_object_visible(o.name, data.get(o.name, false))

func hide_all():
	for o : Node2D in get_children():
		set_object_visible(o.name, false)

func set_object_visible(object_name:String, visibility:bool):
	var o : Node2D = get_node(object_name)
	if not o:
		push_warning(str("Object ", object_name, " doesn't exist!"))
		return
	
	var old_tween = tween_by_object.get(object_name)
	if old_tween:
		old_tween.kill()
	
	
	if visibility:
		o.modulate.a = 0.0
		o.visible = true
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(o, "modulate:a", 1.0, 3.0)
		tween_by_object[object_name] = tween
	else:
		o.visible = false
