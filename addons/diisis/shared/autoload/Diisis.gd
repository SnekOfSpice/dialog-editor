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


const CONTROL_SEQUENCES := ["advance", "ap", "call", "clname", "comment", "fact", "func", "lc", "mp", "name", "ruby", "strpos", "ts_abs", "ts_rel", "ts_reset", "var", ]
const CONTROL_SEQUENCES_WITH_COLON := [
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
const CONTROL_SEQUENCES_WITH_CLOSING_TAG := ["ruby"]


const HTML_ENTITIES := {
	"&amp;" : "&",
	"&lt;" : "<",
	"&gt;" : ">",
	"&quot;" : "\"",
	"&apos;" : "\'",
	"&cent;" : "¢",
	"&pound;" : "£",
	"&yen;" : "¥",
	"&euro;" : "€",
	"&copy;" : "©",
	"&reg;" : "®",
	"&trade;" : "™",
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
