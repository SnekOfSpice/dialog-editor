extends Node

var log_history := []
var date_string := ""

const LOG_DIR = "user://choice_logs/"

func _ready() -> void:
	ParserEvents.listen(self, "choice_pressed")
	ParserEvents.listen(self, "choices_presented")
	ParserEvents.listen(self, "fact_changed")

func serialize() -> Dictionary:
	var result := {}
	
	result["date_string"] = date_string
	result["log_history"] = log_history
	
	return result

func deserialize(data:Dictionary):
	date_string = data.get("date_string", get_new_date_string())
	load_log_history(date_string)

func handle_event(event_name: String, event_args: Dictionary):
	match event_name:
		"choice_pressed":
			var choice := "Choice: "
			choice += event_args.get("choice_text", "")
			if event_args.get("do_jump_page", false):
				choice += " -> "
				choice += str(event_args.get("target_page"))
			append_to_history(choice)
			
			save_log_history()
		"choices_presented":
			log_history.append("-----")
			var facts = Parser.get_facts_of_value(true)
			var fs := "True Facts: "
			for fact in facts:
				fs += str(fact, ", ")
			fs.trim_suffix(", ")
			append_to_history(fs)
			
			var choices = event_args.get("choices", [])
			var cs := "Presented: "
			for choice in choices:
				cs += str(choice.get("option_text"), ", ")
			cs.trim_suffix(", ")
			append_to_history(cs)
			
			save_log_history()
		"fact_changed":
			var fact = event_args.get("fact_name", "")
			var new_val = event_args.get("new_value")
			append_to_history(str("== Fact: ", fact, " -> ", new_val))
			
			save_log_history()

func append_to_history(log:String):
	log_history.append(str(log, " | ", Parser.get_line_position_string()))

func load_log_history(start_date_string):
	var file = FileAccess.open(str(LOG_DIR, "log-", start_date_string, ".txt"), FileAccess.READ)
	if not file:
		return
	var log = file.get_as_text()
	file.close()
	log_history = log.split("\n")

func save_log_history():
	var dir = DirAccess.open(LOG_DIR)
	if not dir:
		DirAccess.make_dir_absolute(LOG_DIR)
	var file = FileAccess.open(str(LOG_DIR, "log-", date_string, ".txt"), FileAccess.WRITE)
	file.store_string(get_log_string())
	file.close()

func get_log_string() -> String:
	var result := ""
	for l in log_history:
		result += l
		result += "\n"
	result.trim_suffix("\n")
	return result

func get_new_date_string():
	var ds := Time.get_datetime_string_from_system()
	ds = ds.replace(":", "-")
	date_string = ds

func start_new_log():
	if not log_history.is_empty():
		save_log_history()
	get_new_date_string()
	log_history.clear()
