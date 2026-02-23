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


const CONTROL_SEQUENCES := ["advance", "ap", "call", "clname", "comment", "fact", "fbrf", "func", "lc", "mp", "name", "ruby", "strpos", "ts_abs", "ts_rel", "ts_reset", "var", ]
const CONTROL_SEQUENCES_WITH_COLON := [
	"call",
	"clname",
	"comment",
	"fact",
	"fbrf",
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

const QUIT_DIALOG_TITLE_CLOSE := "Do you want to close DIISIS?"
const QUIT_DIALOG_TITLE_NEW := "Open a new, blank file?"
const QUIT_DIALOG_TITLE_RELOAD := "Reload DIISIS?"
const QUIT_DIALOG_TITLE_OPEN := "Open existing file at [code]%s[/code]?"
const UNSAVED_FILE_PATH := "DIISIS~unsaved~"

func type_to_str(type:int) -> String:
	match type:
		TYPE_FLOAT:
			return "float"
		TYPE_INT:
			return "int"
		TYPE_BOOL:
			return "bool"
	return "String"

func trim_bilateral_spaces(text:String) -> String:
	var trimmable_space := text.begins_with(" ")
	while trimmable_space:
		text = text.trim_prefix(" ")
		trimmable_space = text.begins_with(" ")
	trimmable_space = text.ends_with(" ")
	while trimmable_space:
		text = text.trim_suffix(" ")
		trimmable_space = text.ends_with(" ")
	return text
