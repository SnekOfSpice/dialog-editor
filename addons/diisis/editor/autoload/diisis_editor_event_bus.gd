@tool
extends Node


var quit := Quit.new()

signal active_path_set(path : String)

class Quit:
	signal window_reload()
	signal new_file()
