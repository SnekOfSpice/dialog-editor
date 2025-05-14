extends Control

const LINES := [
	"This was a demo",
	"Thank you for reading <3"
]

func _ready() -> void:
	$White.modulate.a = 0.0
	$Black.modulate.a = 0.0
	$Label.modulate.a = 0.0
	$White.visible = true
	$Black.visible = true
	$Label.visible = true

func start():
	await get_tree().create_timer(1.0).timeout
	Parser.line_reader.instruction_handler.set_sun("steps", 3.7)
	await get_tree().create_timer(1.5).timeout
	Parser.line_reader.instruction_handler.set_sun("fill_amount", 6.5)
	await get_tree().create_timer(1.5).timeout
	Parser.line_reader.instruction_handler.set_sun("steps", 1.8)
	await get_tree().create_timer(0.5).timeout
	
	
	var white_tween = create_tween()
	white_tween.tween_property($White, "modulate:a", 1.0, 4.0)
	
	await white_tween.finished
	
	await get_tree().create_timer(1.0).timeout
	
	for line : String in LINES:
		
		$Label.text = line
		
		var fade = create_tween()
		fade.tween_property($Label, "modulate:a", 1.0, 2.0)
		await fade.finished
		
		await get_tree().create_timer(4.0).timeout
		
		fade = create_tween()
		fade.tween_property($Label, "modulate:a", 0.0, 2.0)
		await fade.finished
		
		await get_tree().create_timer(1.0).timeout
	
	var black_tween = create_tween()
	black_tween.tween_property($Black, "modulate:a", 1.0, 6.0)
	await black_tween.finished
	
	await get_tree().create_timer(2.0).timeout
	
	Parser.inform_instruction_completed()
