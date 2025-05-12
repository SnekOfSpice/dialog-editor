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

func type_to_str(type:int) -> String:
	match type:
		TYPE_FLOAT:
			return "float"
		TYPE_INT:
			return "int"
		TYPE_BOOL:
			return "bool"
	return "String"
