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


var control_sequences := ["lc", "ap", "mp", "var", "func", "name", "clname", "fact", "strpos", "call", "advance", "ts_rel", "ts_abs", "ts_reset", "comment", "ruby"]
var control_sequences_with_colon := [
	"call",
	"clname",
	"comment",
	"fact",
	"func",
	"name",
	"ruby",
	"ts_rel",
	"ts_abs",
	"var",
]
var control_sequences_with_closing_tag := ["ruby"]

func type_to_str(type:int) -> String:
	match type:
		TYPE_FLOAT:
			return "float"
		TYPE_INT:
			return "int"
		TYPE_BOOL:
			return "bool"
	return "String"
