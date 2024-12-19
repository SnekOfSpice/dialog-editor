extends Sprite2D

var time := 10.0
var remaining_time := 10.0

func _ready() -> void:
	time = randf_range(3.0, 6.0)
	remaining_time = time
	
	texture = load(str("res://game/visuals/vfx/splatter/blood", randi_range(1, 4),".png"))
	position = Vector2(randi_range(200, 760) * 1.5 - (960 * 0.5), randi_range(150, 490) * 1.5 - (540 * 0.5))
	var s := randf_range(0.5, 1.0)
	scale = Vector2(s, s)

func _process(delta: float) -> void:
	remaining_time -= delta
	if remaining_time <= time * 0.5:
		var fade_time := time * 0.5
		var ratio = remaining_time / fade_time
		modulate.a = snappedf(ratio, 0.2)
	if remaining_time <= 0:
		queue_free()
	
