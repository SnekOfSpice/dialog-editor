extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Parser.reset_and_start(0)
	#DialogLogger.start_new_log()
