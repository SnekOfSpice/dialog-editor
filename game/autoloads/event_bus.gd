extends Node

@warning_ignore("unused_signal")
signal save_slot_set(slot : int)
@warning_ignore("unused_signal")
signal new_game_started()
@warning_ignore("unused_signal")
signal settings_changed()
@warning_ignore("unused_signal")
signal before_screenshot()
@warning_ignore("unused_signal")
signal screenshot_taken()
@warning_ignore("unused_signal")
signal screen_changed(old_screen : String, new_screen : String)


## needed for diisis because inherited functions can get fucky with it sometimes
func emit_signal_custom(signal_name : String):
	emit_signal(signal_name)
