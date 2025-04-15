@tool
extends Node
class_name DIISISGlobal

## Welcome to DIISIS!
## Tutorial on the entire plugin on GitHub:
## @tutorial(Wiki): https://github.com/SnekOfSpice/dialog-editor/wiki/

enum LineType {
	Text, Choice, Instruction, Folder
}


enum ChoiceBehaviorAfterSelection {
	Default,
	Show,
	Enabled,
	Disabled,
	Hidden
}

func str_to_typed(value:String, type_string:String):
	match type_string:
		"float":
			return float(value)
		"string":
			return String(value)
		"bool":
			var cast : bool = true if value == "true" else false
			return cast
