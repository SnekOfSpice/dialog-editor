@tool
extends Node

func clear():
	deserialize({})

var head_defaults := []
var auto_complete_context := ""

var dropdowns := {"character": ["narrator", "amber"], "amber-emotion" : ["neutral", "happy"]}
var dropdown_titles := ["character", "amber-emotion"]
var dropdown_dialog_arguments := ["amber-emotion"]
var dropdown_title_for_dialog_syntax := "character"
var use_dialog_syntax := true
var text_lead_time_same_actor := 0.0
var text_lead_time_other_actor := 0.0
const NEGATIVE_INF := -int(INF)
var id_counter := NEGATIVE_INF

const ALLOWED_INSTRUCTION_NAME_CHARACTERS := [
	"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
	"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
	"_",
	"1","2","3","4","5","6","7","8","9","0",
	"."]
const LETTERS := ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",]

var empty_strings_for_l10n := false
var locales_to_export := ["af_ZA", "sq_AL", "ar_SA", "hy_AM", "az_AZ", "eu_ES", "be_BY", "bn_IN", "bs_BA", "bg_BG", "ca_ES", "zh_CN", "zh_TW", "hr_HR", "cs_CZ", "da_DK", "nl_NL", "en_US", "et_EE", "fo_FO", "fi_FI", "fr_FR", "gl_ES", "ka_GE", "de_DE", "el_GR", "gu_IN", "he_IL", "hi_IN", "hu_HU", "is_IS", "id_ID", "it_IT", "ja_JP", "kn_IN", "kk_KZ", "kok_IN", "ko_KR", "lv_LV", "lt_LT", "mk_MK", "ms_MY", "ml_IN", "mt_MT", "mr_IN", "mn_MN", "se_NO", "nb_NO", "nn_NO", "fa_IR", "pl_PL", "pt_BR", "pa_IN", "ro_RO", "ru_RU", "sr_BA", "sk_SK", "es_ES", "sw_KE", "sv_SE", "syr_SY", "ta_IN", "te_IN", "th_TH", "tn_ZA", "tr_TR", "uk_UA", "uz_UZ", "vi_VN", "cy_GB", "xh_ZA", "zu_ZA"]
const DOMINANT_LOCALES := ["af_ZA", "sq_AL", "ar_SA", "hy_AM", "az_AZ", "eu_ES", "be_BY", "bn_IN", "bs_BA", "bg_BG", "ca_ES", "zh_CN", "zh_TW", "hr_HR", "cs_CZ", "da_DK", "nl_NL", "en_US", "et_EE", "fo_FO", "fi_FI", "fr_FR", "gl_ES", "ka_GE", "de_DE", "el_GR", "gu_IN", "he_IL", "hi_IN", "hu_HU", "is_IS", "id_ID", "it_IT", "ja_JP", "kn_IN", "kk_KZ", "kok_IN", "ko_KR", "lv_LV", "lt_LT", "mk_MK", "ms_MY", "ml_IN", "mt_MT", "mr_IN", "mn_MN", "se_NO", "nb_NO", "nn_NO", "fa_IR", "pl_PL", "pt_BR", "pa_IN", "ro_RO", "ru_RU", "sr_BA", "sk_SK", "es_ES", "sw_KE", "sv_SE", "syr_SY", "ta_IN", "te_IN", "th_TH", "tn_ZA", "tr_TR", "uk_UA", "uz_UZ", "vi_VN", "cy_GB", "xh_ZA", "zu_ZA"]
const LOCALES := ["af_ZA","sq_AL","ar_DZ","ar_BH","ar_EG","ar_IQ","ar_JO","ar_KW","ar_LB","ar_LY","ar_MA","ar_OM","ar_QA","ar_SA","ar_SY","ar_TN","ar_AE","ar_YE","hy_AM","az_AZ","eu_ES","be_BY","bn_IN","bs_BA","bg_BG","ca_ES","zh_CN","zh_HK","zh_MO","zh_SG","zh_TW","hr_HR","cs_CZ","da_DK","nl_BE","nl_NL","en_AU","en_BZ","en_CA","en_IE","en_JM","en_NZ","en_PH","en_ZA","en_TT","en_VI","en_GB","en_US","en_ZW","et_EE","fo_FO","fi_FI","fr_BE","fr_CA","fr_FR","fr_LU","fr_MC","fr_CH","gl_ES","ka_GE","de_AT","de_DE","de_LI","de_LU","de_CH","el_GR","gu_IN","he_IL","hi_IN","hu_HU","is_IS","id_ID","it_IT","it_CH","ja_JP","kn_IN","kk_KZ","kok_IN","ko_KR","lv_LV","lt_LT","mk_MK","ms_BN","ms_MY","ml_IN","mt_MT","mr_IN","mn_MN","se_NO","nb_NO","nn_NO","fa_IR","pl_PL","pt_BR","pt_PT","pa_IN","ro_RO","ru_RU","sr_BA","sr_CS","sk_SK","sl_SI","es_AR","es_BO","es_CL","es_CO","es_CR","es_DO","es_EC","es_SV","es_GT","es_HN","es_MX","es_NI","es_PA","es_PY","es_PE","es_PR","es_ES","es_UY","es_VE","sw_KE","sv_FI","sv_SE","syr_SY","ta_IN","te_IN","th_TH","tn_ZA","tr_TR","uk_UA","uz_UZ","vi_VN","cy_GB","xh_ZA","zu_ZA",]
var default_locale := "en_US"

var facts := {}
var local_line_insert_offset:int

var custom_method_defaults := {}
var custom_method_dropdown_limiters := {}
var callable_autoloads := []
var ingestion_actor_declaration := ""
var evaluator_modified_times := {}

enum DataTypes {_String, _DropDown, _Boolean}
const DATA_TYPE_STRINGS := {
	DataTypes._String : "String",
	#DataTypes._Integer : "Integer",
	#DataTypes._Float : "Float",
	#DataTypes._Array : "Array",
	#DataTypes._Dictionary : "Dictionary",
	DataTypes._DropDown : "Drop Down",
	DataTypes._Boolean : "Boolean",
}

var head_data_types := {
	"speaker": DataTypes._DropDown,
	"emotion": DataTypes._String,
}

var editor:DiisisEditor

var page_data := {}
var text_data := {}

var evaluator_paths := []
var default_address_mode_pages : AddressModeButton.Mode = AddressModeButton.Mode.Objectt

const TOOLTIP_CAPITALIZE := "Capitalizes words around sentence beginnings and punctuation."
const TOOLTIP_NEATEN_WHITESPACE := "Cleans up spaces around punctuation marks, tags, brackets. Successive spaces get collapsed into one."
const TOOLTIP_FIX_PUNCTUATION := "Add periods. (maybe do other stuff in the future)"

#region toggle settings
const TOGGLE_SETTINGS := {
	"save_on_play" : "Saves the DIISIS script when you start playing in Godot (with F5 or otherwise)",
	"warn_on_fact_deletion" : "Prompts you to confirm the deletion of a page, line, or choice item if that object or any of its children contains facts. (not conditionals)",
	"show_facts_buttons" : "Shows toggle buttons to open and close facts & conditionals. (Hide if you write kinetic novels or whatever)",
	"collapse_conditional_controls_by_default" : "Determines if Conditionals have their combine mode and resulting behavior hidden by default.",
	"silly" : "Adds a bit of visual fluff to the editor :3",
	"first_index_as_page_reference_only" : "Pages will only treat being referenced by choices when they target index 0 if on, or any line on the page if off.",
	"validate_function_calls_on_focus" : "Checks if all functions match the source scripts when refocusing the editor window. Might cause a few frames of stutters.",
}
var save_on_play := true
var warn_on_fact_deletion := true
var silly := true
var show_facts_buttons := true
var collapse_conditional_controls_by_default := true
var first_index_as_page_reference_only := true
var validate_function_calls_on_focus := true

var loopback_references_by_page := {}
var jump_page_references_by_page := {}
#endregion

const STRING_SETTINGS := {
	"shader" : "Applies a shader to the editor. Restart to apply. Accepts res:// and uid:// paths :3"
}
var shader := ""

var append_periods := true
var replacement_rules := []
const DEFAULT_REPLACEMENT_RULES := [
	{
		"enabled" : false,
		"name" : "ellipsis",
		"symbol" : "...",
		"replacement" : "…"
	},
	{
		"enabled" : false,
		"name" : "leading quote",
		"symbol" : " \"",
		"replacement" : " «"
	},
	{
		"enabled" : false,
		"name" : "trailing quote",
		"symbol" : "\" ",
		"replacement" : "» "
	},
	{
		"enabled" : false,
		"name" : "n dash",
		"symbol" : "--",
		"replacement" : "–"
	},
	{
		"enabled" : false,
		"name" : "m dash",
		"symbol" : "---",
		"replacement" : "—"
	},
	{
		"enabled" : false,
		"name" : "double space",
		"symbol" : " ",
		"replacement" : "  "
	},
]

signal pages_modified

func sync_line_references():
	loopback_references_by_page.clear()
	jump_page_references_by_page.clear()
	for page_index in page_data.keys():
		var page := get_page_data(page_index)
		var line_index := 0
		for line in page.get("lines", []):
			if line.get("line_type") != DIISISGlobal.LineType.Choice:
				line_index += 1
				continue
			
			for choice in line.get("content").get("choices"):
				var loopback_page : int = choice.get("loopback_target_page")
				var loopback_line : int = choice.get("loopback_target_line")
				var jump_page : int = choice.get("target_page")
				var jump_line : int = choice.get("target_line")
				
				var address : String = choice.get("address")
				
				if choice.get("loopback"):
					if loopback_references_by_page.has(loopback_page):
						if loopback_references_by_page.get(loopback_page).has(loopback_line):
							loopback_references_by_page.get(loopback_page).get(loopback_line).append(address)
						else:
							loopback_references_by_page[loopback_page][loopback_line] = [address]
					else:
						loopback_references_by_page[loopback_page] = {loopback_line : [address]}

				if choice.get("do_jump_page"):
					if jump_page_references_by_page.has(jump_page):
						if jump_page_references_by_page.get(jump_page).has(jump_line):
							jump_page_references_by_page.get(jump_page).get(jump_line).append(address)
						else:
							jump_page_references_by_page[jump_page][jump_line] = [address]
					else:
						jump_page_references_by_page[jump_page] = {jump_line : [address]}
		
			line_index += 1

func is_header_schema_empty():
	return head_defaults.is_empty()

func serialize() -> Dictionary:
	var data := {
		"head_defaults" : head_defaults,
		"id_counter" : id_counter,
		"page_data" : page_data,
		"text_data" : text_data,
		"default_locale" : default_locale,
		"custom_method_defaults": custom_method_defaults,
		"full_custom_method_defaults": _get_custom_method_full_defaults(),
		"custom_method_dropdown_limiters": custom_method_dropdown_limiters,
		"callable_autoloads": callable_autoloads,
		"ingestion_actor_declaration": ingestion_actor_declaration,
		"facts": facts,
		"dropdowns": dropdowns,
		"dropdown_titles": dropdown_titles,
		"dropdown_dialog_arguments": dropdown_dialog_arguments,
		"dropdown_title_for_dialog_syntax": dropdown_title_for_dialog_syntax,
		"file_config": get_file_config(),
		"locales_to_export" : locales_to_export,
		"empty_strings_for_l10n": empty_strings_for_l10n,
		"replacement_rules": replacement_rules,
		"append_periods": append_periods,
		"use_dialog_syntax": use_dialog_syntax,
		"text_lead_time_other_actor": text_lead_time_other_actor,
		"text_lead_time_same_actor": text_lead_time_same_actor,
		"default_address_mode_pages": default_address_mode_pages,
		"evaluator_modified_times": evaluator_modified_times,
	}
	for setting in TOGGLE_SETTINGS.keys():
		data[setting] = get(setting)
	for setting in STRING_SETTINGS.keys():
		data[setting] = get(setting)
	return data

func deserialize(data:Dictionary):
	# all keys are now strings instead of ints
	var int_data = {}
	var local_page_data = data.get("page_data", {})
	for i in local_page_data.size():
		var where = int(local_page_data.get(str(i)).get("number"))
		int_data[where] = local_page_data.get(str(i)).duplicate()
	
	page_data.clear()
	page_data = int_data.duplicate()
	head_defaults = data.get("head_defaults", [])
	custom_method_defaults = data.get("custom_method_defaults", {})
	custom_method_dropdown_limiters = data.get("custom_method_dropdown_limiters", {})
	callable_autoloads = data.get("callable_autoloads", [])
	ingestion_actor_declaration = data.get("ingestion_actor_declaration", "")
	evaluator_modified_times = data.get("evaluator_modified_times", {})
	for key in evaluator_modified_times.keys():
		evaluator_modified_times[key] = int(evaluator_modified_times.get(key))
	var fact_fix := {}
	var fact_data : Dictionary = data.get("facts", {})
	for fact_name in fact_data:
		if fact_data.get(fact_name) is bool:
			fact_fix[fact_name] = fact_data.get(fact_name)
		else:
			fact_fix[fact_name] = int(fact_data.get(fact_name))
	facts = fact_fix
	dropdowns = data.get("dropdowns", {})
	dropdown_titles = data.get("dropdown_titles", [])
	dropdown_dialog_arguments = data.get("dropdown_dialog_arguments", [])
	dropdown_title_for_dialog_syntax = data.get("dropdown_title_for_dialog_syntax", "")
	locales_to_export = data.get("locales_to_export", DOMINANT_LOCALES)
	default_locale = data.get("default_locale", "en_US")
	empty_strings_for_l10n = data.get("empty_strings_for_l10n", false)
	use_dialog_syntax = data.get("use_dialog_syntax", true)
	text_data = data.get("text_data", {})
	text_lead_time_other_actor = data.get("text_lead_time_other_actor", 0.0)
	text_lead_time_same_actor = data.get("text_lead_time_same_actor", 0.0)
	default_address_mode_pages = data.get("default_address_mode_pages", AddressModeButton.Mode.Objectt)
	
	for setting in TOGGLE_SETTINGS.keys():
		set(setting, data.get(setting, get(setting)))
	for setting in STRING_SETTINGS.keys():
		set(setting, data.get(setting, get(setting)))
		
	id_counter = data.get("id_counter", NEGATIVE_INF)
	replacement_rules = data.get("replacement_rules", [])
	append_periods = data.get("append_periods", true)
	
	apply_file_config(data.get("file_config", {}))
	
	# init limiters
	await get_tree().process_frame
	for method in get_all_instruction_names():
		if custom_method_dropdown_limiters.has(method):
			continue
		var arg_data := {}
		for arg in get_custom_method_arg_names(method):
			var type : int = get_custom_method_arg_type(method, arg)
			if type == TYPE_STRING:# or type == TYPE_NIL:
				arg_data.set(arg, [])
		if not arg_data.is_empty():
			custom_method_dropdown_limiters.set(method, arg_data)

func get_page_count() -> int:
	return page_data.size()

func get_line_count(page:int) -> int:
	return page_data.get(page).get("lines", []).size()

func create_page_data(number:int, overwrite_existing := false, overwrite_data:={}):
	if page_data.keys().has(number) and not overwrite_existing:
		push_warning(str("page_data already has page with number ", number))
		return
	page_data[number] = {
		"number": number,
		"page_key": "",
		"lines": [],
		"next": number + 1
	}
	if overwrite_existing:
		page_data[number] = {
		"number": overwrite_data.get("number", number),
		"page_key": overwrite_data.get("page_key", ""),
		"lines": overwrite_data.get("lines", []),
		"next": overwrite_data.get("next", number + 1)
	}
	
	emit_signal("pages_modified")

func swap_pages(page_a: int, page_b: int):
	if not (page_data.keys().has(page_a) and page_data.keys().has(page_b)):
		return
	
	swap_page_references(page_a, page_b)
	
	var data_a = page_data.get(page_a)
	var data_b = page_data.get(page_b)
	data_b["number"] = page_a
	data_a["number"] = page_b
	page_data[page_a] = data_b
	page_data[page_b] = data_a
	
func swap_line_references(on_page:int, from:int, to:int):
	var edited_current_page := false
	
	var current_page_number := editor.get_current_page_number()
	for page in page_data.values():
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				for choice in content.get("choices"):
					var page_number : int = page.get("number")
					if choice.get("target_page") == on_page:
					
						if choice.get("target_line") == from and choice.get("jump_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
							choice["target_line"] = to
							if page_number == current_page_number:
								edited_current_page = true
						elif choice.get("target_line") == to and choice.get("jump_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
							choice["target_line"] = from
							if page_number == current_page_number:
								edited_current_page = true
					
					if choice.get("loopback_target_page") == on_page:
						if choice.get("loopback_target_line") == from and choice.get("loop_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
							choice["loopback_target_line"] = to
							if page_number == current_page_number:
								edited_current_page = true
						elif choice.get("loopback_target_line") == to and choice.get("loop_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
							choice["loopback_target_line"] = from
							if page_number == current_page_number:
								edited_current_page = true
	
	if edited_current_page:
		await get_tree().process_frame
		editor.refresh(false, true)


func get_lines(page_number: int):
	return get_page_data(page_number).get("lines")

func swap_page_references(from: int, to: int):
	for page in page_data.values():
		if page.get("meta.address_mode_next", default_address_mode_pages) == AddressModeButton.Mode.Objectt:
			var next = page.get("next")
			if next == from:
				page["next"] = to
			elif next == to:
				page["next"] = from
		
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				for choice in content.get("choices"):
					if choice.get("jump_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
						if choice.get("target_page") == from:
							choice["target_page"] = to
						elif choice.get("target_page") == to:
							choice["target_page"] = from
					if choice.get("loop_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
						if choice.get("loopback_target_page") == from:
							choice["loopback_target_page"] = to
						elif choice.get("loopback_target_page") == to:
							choice["loopback_target_page"] = from
	await get_tree().process_frame
	editor.refresh(false)

func change_line_references_directional(on_page:int, starting_index_of_change:int, end_index_of_change:int, operation:int):
	var edited_current_page := false
	var current_page_number := editor.get_current_page_number()
	for page in page_data.values():
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				for choice : Dictionary in content.get("choices"):
					var page_number : int = page.get("number")
					if choice.get("target_page") == on_page and choice.get("jump_address_mode") == AddressModeButton.Mode.Objectt:
						var target_line : int = choice.get("target_line")
						if target_line >= starting_index_of_change and target_line <= end_index_of_change:
							choice["target_line"] = target_line + operation
							if page_number == current_page_number:
								edited_current_page = true
					
					if choice.get("loopback_target_page") == on_page and choice.get("loop_address_mode") == AddressModeButton.Mode.Objectt:
						var loopback_target_line : int = choice.get("loopback_target_line")
						if loopback_target_line >= starting_index_of_change and loopback_target_line <= end_index_of_change:
							choice["loopback_target_line"] = loopback_target_line + operation
							if page_number == current_page_number:
								edited_current_page = true
					
	local_line_insert_offset += operation
	if edited_current_page:
		await get_tree().process_frame
		editor.refresh(false, true)
	

func change_page_references_dir(changed_page: int, operation:int):
	for page in page_data.values():
		var next = page.get("next")
		if next >= changed_page:
			page["next"] = next + operation
		
		
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				var choices = content.get("choices")
				for choice : Dictionary in choices:
					if choice.get("target_page") >= changed_page and choice.get("jump_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
						choice["target_page"] = choice.get("target_page") + operation
					if choice.get("loopback_target_page") >= changed_page and choice.get("loop_address_mode", AddressModeButton.Mode.Objectt) == AddressModeButton.Mode.Objectt:
						choice["loopback_target_page"] = choice.get("loopback_target_page") + operation
	
	await get_tree().process_frame
	editor.refresh(false)

func key_exists(key: String) -> bool:
	if key == "":
		return false
	
	for i in page_data.size():
		if page_data.get(i).get("page_key") == key:
			return true
	
	return false

func get_page_key(page_index:int) -> String:
	return str(page_data.get(page_index, {}).get("page_key", ""))

func get_page_number_by_key(key:String) -> int:
	for page in page_data.values():
		if page.get("page_key") == key:
			return page.get("number")
	return -1

## when deserializing, UI elements such as choices may try to reference things that are further down the page
## then this ensures it'll fall back onto the saved data
func get_lines_safe(page_index:int, min_line_index:int) -> Array:
	var page = get_page_data(page_index)
	var lines : Array = page.get("lines")
	if lines.size() > min_line_index:
		return lines
	else:
		return page_data.get(page_index).get("lines")
	
func get_line_type(page_index:int, line_index:int) -> int:
	var lines = get_lines_safe(page_index, line_index)
	return int(lines[line_index].get("line_type"))

func apply_file_config(data:Dictionary):
	evaluator_paths = data.get("evaluator_paths", [])

func get_file_config() -> Dictionary:
	return {
		"evaluator_paths":evaluator_paths
	}

func get_line_type_str(page_index:int, line_index:int) -> String:
	var line_type = get_line_type(page_index, line_index)
	match line_type:
		DIISIS.LineType.Text:
			return "Text"
		DIISIS.LineType.Choice:
			return "Choice"
		DIISIS.LineType.Instruction:
			return "Instruction"
		DIISIS.LineType.Folder:
			return "Folder"
	return "undefined"

func get_choice_text_adr(address:String, length:=-1):
	var parts : Array[int] = DiisisEditorUtil.get_split_address(address)
	return get_choice_text(parts[0], parts[1], parts[2], length)

func get_choice_text(page_index:int, line_index:int, choice_index:int, length := -1):
	var page = page_data.get(page_index, {})
	var lines = page.get("lines")
	var line = lines[line_index]
	var choice = line.get("content").get("choices")[choice_index]
	var choice_text:String
	if choice.get("choice_text.enabled_as_default", true):
		choice_text = Pages.get_text(choice.get("text_id_enabled", ""))
	else:
		choice_text = Pages.get_text(choice.get("text_id_disabled", ""))
	if length == -1:
		return choice_text
	return choice_text.left(length)

func get_page_references(page_index:int) -> Array:
	if not page_data.has(page_index):
		push_warning(str("cannot get page reference on non-existent page ", page_index))
		return []
	var references := []
	var page : Dictionary = page_data.get(page_index)
	
	for line in page.get("lines"):
		var line_type = line.get("line_type")
		if not line_type == DIISIS.LineType.Choice:
			continue
		var content = line.get("content")
		
		for choice in content.get("choices"):
			var jump_page :bool=choice.get("do_jump_page", false)
			if jump_page:
				references.append(choice.get("target_page", 0))
	
	if not page.get("terminate", false):
		references.append(page.get("next", 0))
	
	return references

func add_page_data(at: int, new_data := {}):
	# reindex all after at
	for i in range(get_page_count() - 1, at - 1, -1):
		var data = page_data.get(i)
		var new_number = i + 1
		data["number"] = new_number
		page_data[new_number] = data
	
	# insert page
	create_page_data(at, true, new_data)

func delete_page_data(at: int):
	if not page_data.keys().has(at):
		push_warning(str("could not delete page ", at, " because it doesn't exist"))
		return
	if page_data.keys().size() <= 1:
		push_warning(str("cannot delete last page"))
		return
	
	# reindex all after at, this automatically overwrites the page at at
	for i in range(at + 1, get_page_count()):
		var data = page_data.get(i).duplicate(true)
		var new_number = data.get("number") - 1
		data["number"] = new_number
		page_data[new_number] = data
	
	# the last page is now a duplicate
	page_data.erase(get_page_count() - 1)
	
	change_page_references_dir(at, -1)

func get_data_from_address(address:String) -> Dictionary:
	var cpn = editor.get_current_page_number()
	var address_page = DiisisEditorUtil.get_split_address(address)[0]
	# if current page is address
	if cpn == address_page:
		var target = DiisisEditorUtil.get_node_at_address(address)
		return target.serialize()
	# get from internal data
	var depth = DiisisEditorUtil.get_address_depth(address)
	var parts = DiisisEditorUtil.get_split_address(address)
	
	if depth == DiisisEditorUtil.AddressDepth.Page:
		return page_data.get(address_page)
	elif depth == DiisisEditorUtil.AddressDepth.Line:
		var lines : Array = page_data.get(address_page).get("lines")
		return lines[parts[1]]
	elif depth == DiisisEditorUtil.AddressDepth.ChoiceItem:
		var lines : Array = page_data.get(address_page).get("lines")
		var line : Dictionary = lines[parts[1]]
		return line.get("content", {}).get("choices", [])[parts[2]]
	push_warning("This shouldn't happen.")
	return {}

func delete_data_from_address(address:String):
	var cpn = editor.get_current_page_number()
	var address_page = DiisisEditorUtil.get_split_address(address)[0]
	var depth = DiisisEditorUtil.get_address_depth(address)
	var parts = DiisisEditorUtil.get_split_address(address)
	# if current page is address
	if cpn == address_page:
		var target = DiisisEditorUtil.get_node_at_address(address)
		if depth == DiisisEditorUtil.AddressDepth.Line:
			target.request_delete()
			return
		elif depth == DiisisEditorUtil.AddressDepth.ChoiceItem:
			target.request_delete()
			return
	
	# get from internal data
	
	
	if depth == DiisisEditorUtil.AddressDepth.Page:
		delete_page_data(parts[0])
	elif depth == DiisisEditorUtil.AddressDepth.Line:
		var lines : Array = page_data.get(address_page).get("lines")
		lines.remove_at(parts[1])
		page_data[address_page]["lines"] = lines
	elif depth == DiisisEditorUtil.AddressDepth.ChoiceItem:
		var lines : Array = page_data.get(address_page).get("lines")
		var line : Dictionary = lines[parts[1]]
		var choices : Array = line.get("content", {}).get("choices", [])
		choices.remove_at(parts[2])
		page_data[address_page]["lines"]["content"]["choices"] = choices

func get_custom_autoload_methods(autoload:String) -> Array:
	var methods := []
	var autoload_script := get_autoload_script(autoload)
	var script_methods = autoload_script.get_script_method_list()
	for method in script_methods:
		var method_name : String = method.get("name")
		if method_name.ends_with(".gd"):
			continue
		methods.append(method_name)
	
	var base = ClassDB.instantiate(autoload_script.get_class())
	var base_methods = base.get_script_method_list()
	for method in base_methods:
		methods.erase(method.get("name"))
	methods.sort()
	return methods
func get_custom_autoload_properties(autoload:String) -> Array:
	var methods := []
	var autoload_script := get_autoload_script(autoload)
	var script_methods = autoload_script.get_script_property_list()
	for method in script_methods:
		var method_name : String = method.get("name")
		if method_name.ends_with(".gd"):
			continue
		methods.append(method_name)
	
	var base = ClassDB.instantiate(autoload_script.get_class())
	var base_methods = base.get_script_property_list()
	for method in base_methods:
		methods.erase(method.get("name"))
	methods.sort()
	return methods

func get_all_custom_properties() -> Array:
	var result := get_custom_properties()
	var autoload_method_names := []
	for autoload_name in callable_autoloads:
		var methods := get_custom_autoload_methods(autoload_name)
		for method in methods:
			autoload_method_names.append(str(autoload_name, ".", method))
		
	result.append_array(autoload_method_names)
	return result

func get_all_instruction_names() -> Array:
	var result := get_instruction_handler_methods()
	var autoload_method_names := []
	for autoload_name in callable_autoloads:
		var methods := []
		var autoload_script := get_autoload_script(autoload_name)
		var script_methods = autoload_script.get_script_method_list()
		for method in script_methods:
			methods.append(method.get("name"))
		
		var base = ClassDB.instantiate(autoload_script.get_class())
		var base_methods = base.get_method_list()
		for method in base_methods:
			methods.erase(method.get("name"))
		methods.sort()
		
		for method in methods:
			autoload_method_names.append(str(autoload_name, ".", method))
		
	
	result.append_array(autoload_method_names)
	return result

func get_autoload_script(autoload:String) -> Script:
	var path : String = ProjectSettings.get_setting(str("autoload/", autoload)).trim_prefix("*")
	var autoload_script : Script
	if path.ends_with(".gd"):
		autoload_script = load(path).instantiate()
		return autoload_script
	elif path.ends_with(".tscn"):
		var autoload_copy : Node = load(path).instantiate()
		autoload_script = autoload_copy.get_script()
		autoload_copy.queue_free()
		return autoload_script
	else:
		push_warning("Encountered fucky autoload")
		return null

func get_custom_method(instruction_name:String) -> Dictionary:
	if instruction_name.contains("."):
		var singleton_name := instruction_name.split(".")[0]
		var method_name := instruction_name.split(".")[1]
		for method in get_autoload_script(singleton_name).get_script_method_list():
			if method.get("name") == method_name:
				return method
	else:
		for script in get_list_of_evaluator_scripts():
			var script_methods = script.get_script_method_list()
			for method in script_methods:
				if method.get("name") == instruction_name:
					return method
	return {}

func get_custom_method_arg_type(method:String, arg:String) -> int:
	return get_custom_method_typesd(method).get(arg)

func get_instruction_arg_types(instruction_name: String) -> Array:
	var function : Dictionary = get_custom_method(instruction_name)
	var args := []
	for arg in function.get("args"):
		args.append(arg.get("type"))
	return args

func get_custom_method_args(instruction_name:String) -> Array:
	return get_custom_method(instruction_name).get("args", [])

func get_custom_method_arg_names(instruction_name) -> Array:
	var args := get_custom_method(instruction_name).get("args", {})
	var result := []
	for arg in args:
		result.append(arg.get("name"))
	return result

func get_custom_method_base_defaults(instruction_name: String) -> Array:
	return get_custom_method(instruction_name).get("default_args", [])

func get_custom_method_base_defaultsd(instruction_name: String) -> Dictionary:
	var defaults := get_custom_method_base_defaults(instruction_name)
	if defaults.is_empty():
		return {}
	var result := {}
	var args = get_custom_method_args(instruction_name)
	var i := (args.size() - defaults.size())
	while i < args.size():
		result[args[i].get("name")] = defaults[i - args.size()]
		i += 1
	return result

func _get_custom_method_full_defaults() -> Dictionary:
	var result := {}
	for method in get_all_instruction_names():
		result[method] = get_custom_method_defaults(method)
	return result

func set_custom_method_defaults(defaults:Dictionary):
	for method in defaults.keys():
		var args : Dictionary = defaults.get(method)
		custom_method_defaults.set(method, args.duplicate(true))

func get_custom_method_defaults(instruction_name: String) -> Dictionary:
	var base_defaults : Dictionary = get_custom_method_base_defaultsd(instruction_name)
	var defaults := {}
	var args : Array = get_custom_method_args(instruction_name)
	var i := 0
	for arg in base_defaults.keys():
		defaults[arg] = base_defaults.get(arg)
		i += 1
	var customs : Dictionary = custom_method_defaults.get(instruction_name, {})
	for arg in customs.keys():
		defaults[arg] = customs.get(arg)
	return defaults

func get_instruction_arg_count(instruction_name: String) -> int:
	return get_custom_method_arg_names(instruction_name).size()

func get_page_data(index:int) -> Dictionary:
	if editor.get_current_page_number() == index:
		return editor.get_current_page().serialize()
	return page_data.get(index)

func get_all_invalid_instructions() -> String:
	var warning := ""
	var page_index  := 0
	var malformed_instructions := []
	for page in page_data.values():
		var lines : Array = get_page_data(page.get("number")).get("lines", [])
		var line_index := 0
		for line in lines:
			if line.get("line_type") in [DIISIS.LineType.Instruction, DIISIS.LineType.Text]:
				var compliance = line.get("content").get("meta.validation_status")
				if compliance != "OK":
					malformed_instructions.append(str("[url=goto-",str(page_index, ".", line_index),"]", page_index, ".", line_index, "[/url]"))
			line_index += 1
		page_index += 1
	
	if not malformed_instructions.is_empty():
		warning += str("Error at: ", ", ".join(malformed_instructions))
	return warning


func get_all_invalid_address_pointers() -> String:
	var warning := ""
	var page_index  := 0
	var invalid_addresses := []
	for page in page_data.values():
		var next : String = str(int(page.get("next", -1)))
		if (not does_address_exist(next)) and (not page.get("terminate")):
			invalid_addresses.append(str("next ", next, " of page [url=goto-",str(page_index),"]", page_index, "[/url]"))
	
		var lines : Array = page.get("lines", [])
		if page.get("number") == editor.get_current_page_number():
			lines = editor.get_current_page().serialize().get("lines", [])
		var line_index := 0
		for line in lines:
			if line.get("line_type") != DIISIS.LineType.Choice:
				continue
			if not does_address_exist(str(page_index, ".", line_index)):
				continue
			var choices : Array = line.get("content").get("choices", [])
			var choice_index := 0
			for choice : Dictionary in choices:
				var choice_address := str(int(page_index), ".", int(line_index), ".", choice_index)
				if choice.get("do_jump_page", false):
					var address := str(int(choice.get("target_page")), ".", int(choice.get("target_line")))
					if not does_address_exist(address):
						invalid_addresses.append(str("jump ", address, " of choice [url=goto-",str(choice_address),"]", choice_address, "[/url]"))
				
				if choice.get("loopback", false):
					var address := str(int(choice.get("loopback_target_page")), ".", int(choice.get("loopback_target_line")))
					if not does_address_exist(address):
						invalid_addresses.append(str("loop ", address, " of choice [url=goto-",str(choice_address),"]", choice_address, "[/url]"))
				choice_index += 1
			line_index += 1
		page_index += 1
	
	if not invalid_addresses.is_empty():
		warning = str("Warning: invalid addresses at: ", ", ".join(invalid_addresses))
	return warning

# new schema with keys and values
func apply_new_header_schema(new_schema: Array):
	for i in page_data:
		var lines = page_data.get(i).get("lines")
		
		for line in lines:
			line["header"] = transform_header(line.get("header"), new_schema, head_defaults)
	
	editor.refresh(false)
	head_defaults = new_schema


func transform_header(header_to_transform: Array, new_schema: Array, old_schema):
	# TODO: use sort_custom and add an index to each head property to make this flexible when changing head defaults
	var transformed = []
	transformed.resize(new_schema.size())
	
	
	for i in min(old_schema.size(), new_schema.size()):
		var old_name = header_to_transform[i].get("property_name")
		var old_value = header_to_transform[i].get("values", [header_to_transform[i].get("value", null), null])
		var old_type = header_to_transform[i].get("data_type")
		var old_default = old_schema[i].get("values")
		
		var new_name = new_schema[i].get("property_name")
		var new_value = new_schema[i].get("values", [header_to_transform[i].get("value", null), null])
		var new_type = new_schema[i].get("data_type")
		
		# if the header was the default value here, just apply the new default schema
		if old_value[0] == old_default[0] and old_value[1] == old_default[1]:
			transformed[i] = new_schema[i]
		# the old value wasn't the default...
		else:
			
			var a = new_value
			if new_value[0] != old_value[0] or new_value[1] != old_value[1]:
				a = old_value
			
			var converted_value = {
				"property_name": new_name,
				"values": a,
				"data_type": new_type,
			}
			prints("converting ", header_to_transform[i], " to ", converted_value)
			transformed[i] = converted_value
			
			
	
	# idk this seems bad
	for j in transformed.size():
		if transformed[j] == null:
			transformed[j] = new_schema[j]
	
	return transformed

func lines_referencing_fact(fact_name: String):
	var ref_pages := []
	var ref_pages_page_bound := []
	var ref_lines_declare := []
	var ref_lines_condition := []
	var ref_lines_choice_declare := []
	var ref_lines_choice_condition := []
	for page in page_data.values():
		
		
		var page_facts:Dictionary
		if page.get("facts", {}).has("fact_data_by_name"):
			page_facts = page.get("facts", {}).get("fact_data_by_name", {})
		else:
			page_facts = page.get("facts", {})
		
		
		for fact in page_facts.keys():
			if fact == fact_name:
				ref_pages.append(page.get("number"))
				ref_pages_page_bound.append(page.get("number"))
		
		for i in page.get("lines", []).size():
			var line = page.get("lines")[i]
			var line_facts:Dictionary = line.get("facts", {}).get("fact_data_by_name", {})
			
			
			for fact in line_facts.keys():
				if fact == fact_name:
					if not ref_pages.has(page.get("number")):
						ref_pages.append(page.get("number"))
					ref_lines_declare.append(str(page.get("number"), ".", i))
			
			var line_conditionals:Dictionary
			if line.get("conditionals", {}).get("facts", {}).has("fact_data_by_name"):
				line_conditionals = line.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
			else:
				line_conditionals = line.get("conditionals", {}).get("facts", {})
			
			for fact in line_conditionals:
				if fact == fact_name:
					if not ref_pages.has(page.get("number")):
						ref_pages.append(page.get("number"))
					ref_lines_condition.append(str(page.get("number"), ".", i))
			
			if line.get("line_type") == DIISIS.LineType.Choice:
				var options = line.get("content")
				var choice_index := 0
				for option in options.get("choices", {}):
					var option_conditionals:Dictionary
					if option.get("conditionals", {}).get("facts", {}).has("fact_data_by_name"):
						option_conditionals = option.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
					else:
						option_conditionals = option.get("conditionals", {}).get("facts", {})
					for fact in option_conditionals:
						if fact == fact_name:
							if not ref_pages.has(page.get("number")):
								ref_pages.append(page.get("number"))
							ref_lines_choice_condition.append(str(page.get("number"), ".", i, ".", choice_index))
					
					var option_facts:Dictionary
					if option.get("facts", {}).has("fact_data_by_name"):
						option_facts = option.get("facts", {}).get("fact_data_by_name", {})
					else:
						option_facts = option.get("facts", {})
					for fact in option_facts:
						if fact == fact_name:
							if not ref_pages.has(page.get("number")):
								ref_pages.append(page.get("number"))
							ref_lines_choice_declare.append(str(page.get("number"), ".", i, ".", choice_index))
					choice_index += 1
	
	var all_refs := {
		"ref_pages_fact": ref_pages,
		"ref_pages_page_bound": ref_pages_page_bound,
		"ref_lines_fact": ref_lines_declare,
		"ref_lines_condition": ref_lines_condition,
		"ref_choices_fact": ref_lines_choice_declare,
		"ref_choices_condition": ref_lines_choice_condition
	}
	
	return all_refs

func get_text_on_all_pages() -> String:
	var result := ""
	for i in page_data.keys():
		result += get_text_on_page(i)
	return result

func get_text_on_page(page_number:int) -> String:
	var result := ""
	var data := get_page_data(page_number)
	for line in data.get("lines", []):
		var line_type = line.get("line_type")
		var content = line.get("content")
		if line_type == DIISIS.LineType.Choice:
			for choice in content.get("choices"):
				result +=  Pages.get_text(choice.get("text_id_enabled", ""))
				result +=  Pages.get_text(choice.get("text_id_disabled", ""))
		elif line_type == DIISIS.LineType.Text:
			var text : String = Pages.get_text(content.get("text_id", ""))
			if use_dialog_syntax:
				var actor_tag_index := text.find("[]>")
				while actor_tag_index != -1:
					var tag_end = text.find(":", actor_tag_index)
					if tag_end == -1:
						break
					text = text.erase(actor_tag_index, tag_end - actor_tag_index)
					actor_tag_index = text.find("[]>")
			result += text
	return result

## Returns word count in x and character count in y
func get_count_on_page(page_number:int, include_skipped:=false) -> Vector2i:
	var character_count := 0
	var word_count := 0
	var data := get_page_data(page_number)
	if data.get("skip", false) and not include_skipped:
		return Vector2i.ZERO
	for line in data.get("lines", []):
		if line.get("skip", false) and not include_skipped:
			continue
		var line_type = line.get("line_type")
		var content = line.get("content")
		if line_type == DIISIS.LineType.Choice:
			for choice in content.get("choices"):
				character_count +=  Pages.get_text(choice.get("text_id_enabled", "")).length()
				character_count +=  Pages.get_text(choice.get("text_id_disabled", "")).length()
				word_count += Pages.get_text(choice.get("text_id_enabled", "")).count(" ") + 1
				word_count += Pages.get_text(choice.get("text_id_disabled", "")).count(" ") + 1
		elif line_type == DIISIS.LineType.Text:
			var text : String = Pages.get_text(content.get("text_id", ""))
			if use_dialog_syntax:
				var actor_tag_index := text.find("[]>")
				while actor_tag_index != -1:
					var tag_end = text.find(":", actor_tag_index)
					if tag_end == -1:
						break
					text = text.erase(actor_tag_index, tag_end - actor_tag_index)
					actor_tag_index = text.find("[]>")
			text = remove_tags(text)
			character_count += text.length()
			word_count += text.count(" ") + 1
	return Vector2(word_count, character_count)

## Returns word count in x and character count in y
func get_count_total(include_skipped:=false) -> Vector2i:
	var sum := Vector2.ZERO
	for i in page_data.keys():
		var result = get_count_on_page(i, include_skipped)
		sum.x += result.x
		sum.y += result.y
	
	return sum

func rename_fact(from:String, to:String):
	alter_fact(from, to)

func rename_dropdown_title(from:String, to:String):
	var dd_values = dropdowns.get(from).duplicate(true)
	dropdowns[to] = dd_values
	if from != to:
		dropdowns.erase(from)
		dropdown_titles.insert(dropdown_titles.find(from), to)
		dropdown_titles.erase(from)
		if dropdown_dialog_arguments.has(from):
			var where = dropdown_dialog_arguments.find(from)
			dropdown_dialog_arguments.insert(where, to)
			dropdown_dialog_arguments.erase(from)
		if dropdown_title_for_dialog_syntax == from:
			dropdown_title_for_dialog_syntax = to
	
	# change in line data
	for page in page_data.values():
		var lines : Array = page.get("lines")
		for line : Dictionary in lines:
			if line.get("line_type") != DIISIS.LineType.Text:
				continue
			var text_id : String = line.get("content", {}).get("text_id")
			var content : String = Pages.get_text(text_id)
			content = content.replace(str("{", from, "|"), str("{", to, "|"))
			content = content.replace(str("[]>", from), str("[]>", to))
			Pages.save_text(text_id, content)

func set_dropdown_options(dropdown_title:String, options:Array, replace_in_text:=true, replace_speaker:=true):
	if replace_in_text:
		var old_options : Array = dropdowns.get(dropdown_title, [])
		var is_speaker := dropdown_title == dropdown_title_for_dialog_syntax
		
		for page in page_data.values():
			var lines : Array = page.get("lines")
			for line : Dictionary in lines:
				if line.get("line_type") != DIISIS.LineType.Text:
					continue
				
				var i := 0
				while i < min(old_options.size(), options.size()):
					var old_option:String=old_options[i]
					var new_option:String=options[i]
					if old_option == new_option:
						i += 1
						continue
					var old_arg := str(dropdown_title, "|", old_option)
					var new_arg := str(dropdown_title, "|", new_option)
					
					var text_id : String = line.get("content", {}).get("text_id")
					var content : String = Pages.get_text(text_id)
					content = content.replace(old_arg, new_arg)
					
					if is_speaker and replace_speaker:
						var old_speaker := str("[]>", old_option)
						var new_speaker := str("[]>", new_option)
						content = content.replace(old_speaker, new_speaker)
					
					Pages.save_text(text_id, content)
					
					i += 1
	
	dropdowns[dropdown_title] = options

func is_new_dropdown_title_invalid(title:String, previous_title := "") -> bool:
	return (title in dropdown_titles and previous_title != title) or title.to_lower() in ["string", "bool", "float"] or title.is_empty()

func delete_dropdown(title:String, erase_from_text:=true):
	if erase_from_text and dropdown_dialog_arguments.has(title):
		var options : Array = dropdowns.get(title, [])
		for page in page_data.values():
			var lines : Array = page.get("lines")
			for line : Dictionary in lines:
				if line.get("line_type") != DIISIS.LineType.Text:
					continue
				
				var text_id : String = line.get("content", {}).get("text_id")
				var content : String = Pages.get_text(text_id)
				var i := 0
				while i < options.size():
					var option:String=options[i]
					var option_str = str(title, "|", option)
					content = content.replace(option_str + ",", "")
					content = content.replace(option_str, "")
					i += 1
				content = content.replace("{}", "")
				Pages.save_text(text_id, content)
	
	dropdown_titles.erase(title)
	dropdown_dialog_arguments.erase(title)
	dropdowns.erase(title)
	
	await get_tree().process_frame
	
	Pages.editor.refresh(false)

func register_fact(fact_name : String, value):
	if has_fact(fact_name):
		push_warning(str("Fact ", fact_name, " already exists with default value ", facts.get(fact_name), " and won't be registered again."))
		return
	facts[fact_name] = value

func alter_fact(from:String, to=null):
	for page in page_data.values():
		var page_facts:Dictionary
		page_facts = page.get("facts", {}).get("fact_data_by_name", {})
		for fact in page_facts.keys():
			if fact == from:
				if to is String:
					var fact_data = page_facts.get(fact)
					fact_data["fact_name"] = to
					page_facts[to] = fact_data
				page_facts.erase(from)
		
		for i in page.get("lines", []).size():
			var line = page.get("lines")[i]
			var line_facts:Dictionary
			line_facts = line.get("facts", {}).get("fact_data_by_name", {})
			for fact in line_facts.keys():
				if fact == from:
					if to is String:
						var fact_data = line_facts.get(fact)
						fact_data["fact_name"] = to
						line_facts[to] = fact_data
					line_facts.erase(from)
			
			var line_conditionals:Dictionary
			line_conditionals = line.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
			for fact in line_conditionals:
				if fact == from:
					if to is String:
						var fact_data = line_conditionals.get(fact)
						fact_data["fact_name"] = to
						line_conditionals[to] = fact_data
					line_conditionals.erase(from)
			if line.get("line_type") == DIISIS.LineType.Text:
				var text_id =  line.get("content").get("text_id")
				var text := get_text(text_id)
				text = text.replace(
					str("<fact:", from, ">"),
					str("<fact:", to, ">")
				)
				save_text(text_id, text)
			if line.get("line_type") == DIISIS.LineType.Choice:
				var options = line.get("content")
				var choice_index := 0
				for option in options.get("choices", {}):
					var option_conditionals:Dictionary
					option_conditionals = option.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
					for fact in option_conditionals:
						if fact == from:
							if to is String:
								var fact_data = option_conditionals.get(fact)
								fact_data["fact_name"] = to
								option_conditionals[to] = fact_data
							option_conditionals.erase(from)
					
					var option_facts:Dictionary
					option_facts = option.get("facts", {}).get("fact_data_by_name", {})
					for fact in option_facts:
						if fact == from:
							if to is String:
								var fact_data = option_facts.get(fact)
								fact_data["fact_name"] = to
								option_facts[to] = fact_data
							option_facts.erase(from)
					choice_index += 1
	
	if to is String:
		facts[to] = facts.get(from)
	facts.erase(from)
	
	editor.refresh(false)
	
func is_fact_new_and_not_empty(fact_name: String) -> bool:
	return not (has_fact(fact_name) or fact_name.is_empty())

func has_fact(fact_name:String) -> bool:
	return facts.keys().has(fact_name)

func does_address_exist(address:String) -> bool:
	if address.ends_with(".") or address.is_empty():
		return false
	var parts : Array[int] = DiisisEditorUtil.get_split_address(address)
	if parts.size() <= 0 or parts.size() > 3:
		return false
	
	if parts.size() == 1: # page
		return page_data.has(parts[0])
	elif parts.size() == 2: # line
		return page_data.get(parts[0], {}).get("lines", []).size() > parts[1]
	elif parts.size() == 3: # choice item
		if page_data.get(parts[0], {}).get("lines", []).size() <= parts[1]:
			return false
		var line = page_data.get(parts[0], {}).get("lines", [])[parts[1]]
		if line.get("line_type") != DIISIS.LineType.Choice:
			return false
		return line.get("content", {}).get("choices", []).size() > parts[2]
	
	return false

func delete_fact(fact:String):
	alter_fact(fact)

func get_list_of_evaluator_scripts() -> Array[Script]:
	var result : Array[Script] = []
	for evaluator : String in evaluator_paths:
		if evaluator.ends_with(".gd"):
			var n = load(evaluator)
			if not n:
				push_warning(str("Couldn't load", evaluator))
				continue
			result.append(n)
		else:
			push_warning(str("Couldn't resolve", evaluator, "because it doesn't end with .tscn or .gd"))
			continue
	return result

func get_instruction_handler_methods() -> Array:
	var methods := []
	for script : Script in get_list_of_evaluator_scripts():
		var script_methods = script.get_script_method_list()
		for method in script_methods:
			methods.append(method.get("name"))
	
	methods = add_usable_line_reader_parts(false, methods)
	methods.sort()
	return methods

func get_custom_properties() -> Array:
	var methods := []
	for script : Script in get_list_of_evaluator_scripts():
		var script_methods = script.get_script_property_list()
		for method in script_methods:
			if not methods.has(method.get("name")):
				methods.append(method.get("name"))
	
	methods = add_usable_line_reader_parts(true, methods)
	for method : String in methods:
		if method.ends_with(".gd") or method.ends_with(".tscn"):
			methods.erase(method)
	
	return methods

## calls get_property_list if [member properties] else get_method_list
func add_usable_line_reader_parts(properties:bool, custom_array:Array) -> Array:
	var base := LineReader.new()
	var lr_things := base.get_property_list() if properties else base.get_method_list()
	var lr_methods := []
	for thing in lr_things:
		lr_methods.append(thing.get("name"))
	var base_node = Node.new()
	var node_methods := []
	var node_things := base_node.get_property_list() if properties else base_node.get_method_list()
	for thing in node_things:
		node_methods.append(thing.get("name"))
	
	var result := []
	var size := custom_array.size()
	var i := 0
	while i < size:
		var method = custom_array[i]
		if (
			method.begins_with("_") or
			method.begins_with("@") or
			method.contains(" ") or
			method != method.to_lower() or
			method.ends_with(".gd") or
			method.ends_with(".tscn") or
			method in node_methods
			):
			custom_array.remove_at(i)
			size -= 1
			continue
		result.append(method)
		i += 1
	
	base.queue_free()
	base_node.queue_free()
	return custom_array

func search_string(substr:String, case_insensitive:=false, include_tags:=false) -> Dictionary:
	var found_facts := {}
	for fact : String in facts:
		if (case_insensitive and fact.findn(substr) != -1) or (not case_insensitive and fact.find(substr) != -1):
			found_facts[fact] = fact
	var found_choices := {}
	var found_text := {}
	var found_instructions := {}
	var page_index := 0
	for page in page_data.values():
		var line_index := 0
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var choice_index := 0
				for choice in line.get("content", {}).get("choices", []):
					var text_enabled : String = Pages.get_text(choice.get("text_id_enabled"))
					var text_disabled : String = Pages.get_text(choice.get("text_id_disabled"))
					if (case_insensitive and text_enabled.findn(substr) != -1) or (not case_insensitive and text_enabled.find(substr) != -1):
						found_choices[str(page_index, ".", line_index, ".", choice_index, " - enabled")] = text_enabled
					if (case_insensitive and text_disabled.findn(substr) != -1) or (not case_insensitive and text_disabled.find(substr) != -1):
						found_choices[str(page_index, ".", line_index, ".", choice_index, " - disabled")] = text_disabled
					choice_index += 1
			elif line.get("line_type") == DIISIS.LineType.Text:
				var text : String = Pages.get_text(line.get("content", {}).get("text_id", ""))
				if not include_tags:
					text = remove_tags(text)
				
				if (case_insensitive and text.findn(substr) != -1) or (not case_insensitive and text.find(substr) != -1):
					found_text[str(page_index, ".", line_index)] = text
			elif line.get("line_type") == DIISIS.LineType.Instruction:
				var text : String = line.get("content", {}).get("meta.text", "")
				var reverse_text : String = line.get("content", {}).get("meta.reverse_text", "")
				if (case_insensitive and text.findn(substr) != -1) or (not case_insensitive and text.find(substr) != -1):
					found_instructions[str(page_index, ".", line_index, " - default")] = text
				if (case_insensitive and reverse_text.findn(substr) != -1) or (not case_insensitive and reverse_text.find(substr) != -1):
					found_instructions[str(page_index, ".", line_index, " - reverse")] = reverse_text
			line_index += 1
		page_index += 1
	
	var result := {
		"facts":found_facts,
		"text":found_text,
		"choices":found_choices,
		"instructions":found_instructions,
	}
	return result


func get_cascading_trail(start_page:int) -> Array:
	var trail := [start_page]
	
	var terminate : bool = get_page_data(start_page).get("terminate", false)
	var next : int = get_page_data(start_page).get("next")
	while not terminate:
		if trail.has(next):
			push_warning("Cyclic pages %s starting from %s" % [next, start_page])
			break
		trail.append(next)
		next = get_page_data(next).get("next")
		terminate = get_page_data(next).get("terminate", false)
	
	return trail

func stringify_page(index:int, modifiers := {}) -> String:
	var result := "PAGE %s" % index
	var data := get_page_data(index)
	var i := 0
	for line : Dictionary in data.get("lines", []):
		#print(line)
		result += "\nLINE %s\n" % i
		var line_type := get_line_type(index, i)
		match line_type:
			DIISIS.LineType.Text:
				result += get_text(line.get("content").get("text_id"))
				print(get_text(line.get("content").get("text_id")))
			DIISIS.LineType.Instruction:
				if not modifiers.get("include_instructions", false):
					i += 1
					continue
				result += line.get("content").get("meta.text")
			DIISIS.LineType.Choice:
				push_warning("Choice stringification not supported atm")
		i += 1
	result += "\n"
	return result

func remove_tags(t:String) -> String:
	var text := t
	var pairs = ["<>", "[]"]
	for pair in pairs:
		var scan_index := 0
		while scan_index < text.length():
			if text[scan_index] == pair[0]:
				if text.find(pair[1]) < scan_index:
					scan_index += 1
					continue
				var local_scan_index := scan_index
				var control_to_replace := ""
				while text[local_scan_index] != pair[1]:
					if text[local_scan_index] == "\n":
						break
					control_to_replace += text[local_scan_index]
					local_scan_index += 1
				control_to_replace += pair[1]
				
				if text.length() >= scan_index + 3:
					var tag_end := scan_index
					if (
						text[scan_index + 1] == "i" and
						text[scan_index + 2] == "m" and
						text[scan_index + 3] == "g"):
							tag_end = text.find("[/img]") + 5
							control_to_replace = text.substr(scan_index, tag_end - scan_index+1)
				text = text.erase(scan_index, control_to_replace.length())
			scan_index += 1
	return text

func update_all_compliances():
	# check modified because updating all compliances makes diisis stutter a bit
	var modified := false
	for path in evaluator_paths:
		var modified_time = FileAccess.get_modified_time(path)
		if not evaluator_modified_times.has(path):
			evaluator_modified_times[path] = modified_time
			modified = true
			break
		else:
			if evaluator_modified_times.get(path) != modified_time:
				evaluator_modified_times[path] = modified_time
				modified = true
				break
	if not modified:
		for autoload in callable_autoloads:
			var path : String = ProjectSettings.get_setting(str("autoload/", autoload)).trim_prefix("*")
			var modified_time = FileAccess.get_modified_time(path)
			if not evaluator_modified_times.has(path):
				evaluator_modified_times[path] = modified_time
				modified = true
				break
			else:
				if evaluator_modified_times.get(path) != modified_time:
					evaluator_modified_times[path] = modified_time
					modified = true
					break
	
	if not modified:
		return
	
	for method in get_all_instruction_names():
		update_compliances(method)
	if is_instance_valid(editor):
		editor.update_error_text_box()

func update_compliances(instruction_name:String):
	for page in page_data.values():
		var lines : Array = page.get("lines", [])
		for line in lines:
			var content : Dictionary = line.get("content", {})
			if line.get("line_type") == DIISIS.LineType.Instruction:
				if content.get("name", "") == instruction_name:
					var text : String = content.get("meta.text", "")
					var text_reverse : String = content.get("meta.reverse_text", "")
					var status = get_method_validity(text)
					if status != "OK":
						line["content"]["meta.validation_status"] = status
						continue
					status = get_method_validity(text_reverse)
					if status != "OK" and content.get("meta.has_reverse"):
						line["content"]["meta.validation_status"] = status
						continue
					line["content"]["meta.validation_status"] = "OK"
			elif line.get("line_type") == DIISIS.LineType.Text:
				var functions : Array = content.get("meta.function_calls", [])
				var compliance : String = "OK"
				for function in functions:
					var validity = get_method_validity(function)
					if validity != "OK":
						compliance = validity
						break
				line["content"]["meta.validation_status"] = compliance

func get_custom_method_types(instruction_name:String) -> Array:
	var result := []
	for arg in get_custom_method_args(instruction_name):
		result.append(arg.get("type"))
	return result
func get_custom_method_typesd(instruction_name:String) -> Dictionary:
	var result := {}
	for arg in get_custom_method_args(instruction_name):
		result[arg.get("name")] = arg.get("type")
	
	return result
func get_custom_method_base_default(instruction_name:String, arg_name:String):
	return get_custom_method_base_defaultsd(instruction_name).get(arg_name)
func get_default_arg_value(instruction_name:String, arg_name:String):
	return get_custom_method_defaults(instruction_name).get(arg_name)

func does_instruction_name_exist(instruction_name:String):
	return get_all_instruction_names().has(instruction_name)

func get_autoload_names() -> Array:
	var autoload_names := []
	for property in ProjectSettings.get_property_list():
		var prop_name :String = property.get("name")
		if prop_name.begins_with("autoload/"):
			autoload_names.append(prop_name.trim_prefix("autoload/"))
	autoload_names.sort()
	return autoload_names

func get_method_validity(instruction:String) -> String:
	if instruction.is_empty():
		return "Function is empty."
	if not instruction.ends_with(")"):
		return "Function should end with \")\""
	var entered_name = instruction.split("(")[0]
	if not does_instruction_name_exist(entered_name):
		var autoload_warning := ""
		if entered_name.contains("."):
			var autoload_name := entered_name.split(".")[0]
			if not Pages.callable_autoloads.has(autoload_name):
				if autoload_name in get_autoload_names():
					return str("Autoload ", autoload_name, " is not set for function calls")
				else:
					return str("Autoload ", autoload_name, " does not exist")
		return str("Function ", entered_name, " does not exist", autoload_warning)
	
	var method_args := get_custom_method_args(entered_name)
	var arg_count : int = method_args.size()
	if arg_count == 0:
		if not instruction.ends_with("()"):
			return "Function doesn't expect arguments"
	var entered_arg_count := instruction.count(",") + 1
	if instruction.ends_with("()"):
		entered_arg_count = 0
	if entered_arg_count > arg_count:
		return str(entered_name, " expects ", arg_count, " arguments but is called with ", entered_arg_count)
	elif entered_arg_count < arg_count:
		# check if all omitted args are covered by defaults
		var entered_arg_names := []
		for i in entered_arg_count:
			entered_arg_names.append(method_args[i].get("name"))
		var all_arg_names := get_custom_method_arg_names(entered_name)
		for arg_name in entered_arg_names:
			all_arg_names.erase(arg_name)
		var defaults = get_custom_method_defaults(entered_name)
		
		for arg_name in all_arg_names: #is now only not submitted args
			if not arg_name in defaults.keys():
				return str(entered_name, " expects ", arg_count, " arguments but is called with ", entered_arg_count)
		
	# for every arg, if it's float, it can't have non float chars, if bool, it has to be "true" or "false"
	var args_string = instruction.trim_prefix(entered_name)
	args_string = args_string.trim_prefix("(")
	args_string = args_string.trim_suffix(")")
	var args := args_string.split(",")
	var template_arg_names : Array = get_custom_method_arg_names(entered_name)
	var template_types : Array = get_custom_method_types(entered_name)
	
	var i := 0
	while i < template_types.size() and not template_types.is_empty() and i < args.size():
		var arg_string : String = args[i]
		while arg_string.begins_with(" "):
			arg_string = arg_string.trim_prefix(" ")
		while arg_string.ends_with(" "):
			arg_string = arg_string.trim_suffix(" ")
		var arg_value : String = arg_string.split(":")[0]
		if arg_value.is_empty() and get_custom_method_base_default(entered_name, template_arg_names[i]) == null:
			return str("Argument ", i+1, " is empty")
		if arg_value == "*" and get_default_arg_value(entered_name, template_arg_names[i]) == null:
			return str("Argument ", i+1, " is declared as default but argument ", template_arg_names[i], " has no default value.")
		
		var type_compliance : String = get_type_compliance(entered_name, template_arg_names[i], arg_value, template_types[i], i)
		if not type_compliance.is_empty():
			return type_compliance
		i += 1
	
	return "OK"

func get_type_compliance(method:String, arg:String, value:String, type:int, arg_index:int) -> String:
	if value.is_empty() and get_custom_method_base_defaultsd(method).get(arg) != null:
		return ""
	var default_notice := ""
	if value == "*":
		value = str(get_custom_method_defaults(method).get(arg))
		default_notice = "\n(Derived from default)"
	if type == TYPE_BOOL:
		if value != "true" and value != "false":
			return str("Bool argument ", arg_index + 1, " is neither \"true\" nor \"false\"")
	if type == TYPE_FLOAT:
		for char in value:
			if not char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "-"]:
				return str("Float argument ", arg_index + 1, " contains non-float character.\n(Valid characters are 0 - 9 and . and -)")
	if type == TYPE_INT:
		for char in value:
			if not char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]:
				return str("Int argument ", arg_index + 1, " contains non-int character.\n(Valid characters are 0 - 9)")
	
	var selected_limiters : Array = custom_method_dropdown_limiters.get(method, {}).get(arg, [])
	if selected_limiters.size() > 0:
		# build list of all options
		var valid_strings := []
		for dd_name in selected_limiters:
			valid_strings.append_array(dropdowns.get(dd_name))
		
		if not value in valid_strings:
			return str("Dropdown argument \"", value, "\" (", arg_index + 1, ") is not an option for ", ", ".join(selected_limiters), ".", default_notice, "\nValid strings are: ", ", ".join(valid_strings))
	return ""

func are_all_of_these_dropdown_titles(names:Array) -> bool:
	var result := true
	for dd_name in names:
		if not dd_name in dropdown_titles:
			result = false
			break
	return result

func capitalize_sentence_beginnings(text:String) -> String:
	

	var c12n_prefixes := [
		".", ":", ";", "?", "!", "~"
	]
	
	var letter_indices_after_elipses := {}
	var elipse_position := text.find("...")
	var elipse_length := 3
	while elipse_position != -1:
		if elipse_position < text.length() - elipse_length:
			if text[elipse_position + elipse_length + 1] in LETTERS:
				letter_indices_after_elipses[elipse_position + elipse_length + 1] = text[elipse_position + elipse_length + 1]
				elipse_position = text.find("...", elipse_position + elipse_length + 1)
				continue
			elif text[elipse_position + 1] == " " and elipse_position < text.length() - 1:
				if text[elipse_position + 2] in LETTERS:
					letter_indices_after_elipses[elipse_position + elipse_length + 2] = text[elipse_position + elipse_length + 2]
					elipse_position = text.find("...", elipse_position + elipse_length + 1)
					continue
		elipse_position = text.find("...", elipse_position + elipse_length + 1)

	var tags_in_text := []
	var scan_index := 0
	while scan_index < text.length():
		if text[scan_index] == "<":
			var tag_end = text.find(">", scan_index)
			if tag_end == -1:
				scan_index += 1
				continue
			var tag = text.substr(scan_index, tag_end - scan_index + 1)
			tags_in_text.append(tag)
		elif text[scan_index] == "{":
			var tag_end = text.find("}", scan_index)
			if tag_end == -1:
				scan_index += 1
				continue
			var tag = text.substr(scan_index, tag_end - scan_index + 1)
			tags_in_text.append(tag)
		elif text[scan_index] == "[":
			if text[scan_index-1] == "\\[":
				scan_index += 1
				continue
			var tag_end = text.find("]", scan_index)
			if tag_end == -1:
				scan_index += 1
				continue
			var tag = text.substr(scan_index, tag_end - scan_index + 1)
			tags_in_text.append(tag)
		scan_index += 1
	for letter : String in LETTERS:
		text = text.replace(str("<lc>", letter), str("<lc>", letter.capitalize()))
		text = text.replace(str("<lc> ", letter), str("<lc> ", letter.capitalize()))
		for prefix in c12n_prefixes:
			if prefix != "-":
				text = text.replace(str(prefix, letter), str(prefix, letter.capitalize()))
				text = text.replace(str(prefix, "<ap>", letter), str(prefix, "<ap>", letter.capitalize()))
				text = text.replace(str(prefix, "<mp>", letter), str(prefix, "<mp>", letter.capitalize()))
				text = text.replace(str(prefix, "<lc>", letter), str(prefix, "<lc>", letter.capitalize()))
			text = text.replace(str(prefix, " ", letter), str(prefix, " ", letter.capitalize()))
			text = text.replace(str(prefix, " <ap>", letter), str(prefix, " <ap>", letter.capitalize()))
			text = text.replace(str(prefix, " <mp>", letter), str(prefix, " <mp>", letter.capitalize()))
			text = text.replace(str(prefix, " <lc>", letter), str(prefix, " <lc>", letter.capitalize()))
	
	for tag in tags_in_text:
		text = text.replacen(tag, tag)
	
	for index in letter_indices_after_elipses.keys():
		var letter : String = letter_indices_after_elipses.get(index)
		text[index] = letter
	
	text = text.replace(" i ", " I ")
	
	return text

func neaten_whitespace(text:String) -> String:
	for letter : String in LETTERS:
		text = text.replace(str(":", letter), str(": ", letter))
		text = text.replace(str(":", letter.to_upper()), str(": ", letter.to_upper()))
	text = text.replace("<", " <")
	text = text.replace("[", " [")
	text = text.replace(" []>", "[]>")
	
	var contains_dead_whitespace := text.contains("  ")
	while contains_dead_whitespace:
		var doublespace_index = text.find("  ")
		text = text.erase(doublespace_index)
		contains_dead_whitespace = text.contains("  ")
	
	contains_dead_whitespace = text.contains("> ")
	while contains_dead_whitespace:
		var doublespace_index = text.find("> ")
		text = text.erase(doublespace_index + 1)
		contains_dead_whitespace = text.contains("> ")
	
	contains_dead_whitespace = text.contains("] ")
	while contains_dead_whitespace:
		var doublespace_index = text.find("] ")
		text = text.erase(doublespace_index + 1)
		contains_dead_whitespace = text.contains("] ")
	
	var closing_bb_lead_space_position := text.find(" [/")
	while closing_bb_lead_space_position != -1:
		var end_bracket_position = text.find("]", closing_bb_lead_space_position)
		if end_bracket_position == -1:
			break
		text = text.insert(end_bracket_position + 1, " ")
		text = text.erase(closing_bb_lead_space_position)
		closing_bb_lead_space_position = text.find(" [/")
	
	for sequence in DIISIS.control_sequences:
		var full_sequence := str("<", sequence, ": ")
		var sequence_pos := text.find(full_sequence)
		while sequence_pos != -1:
			text = text.erase(sequence_pos + full_sequence.length() - 1)
			sequence_pos = text.find(full_sequence, sequence_pos)
		
	text = text.replace("] .", "].")
	text = text.replace("> .", ">.")
	text = text.replace(": //", "://")
	text = text.replace(":...", ": ...")
	
	return text

func fix_punctuation(text:String) -> String:
	var lines = text.split("\n")
	var result := []
	for line : String in lines:
		if not append_periods:
			result.append(line)
			continue
		
		var ends_with_space := line.ends_with(" ")
		while ends_with_space:
			line = line.erase(line.length() - 1)
			ends_with_space = line.ends_with(" ")
		var has_punctuation := false
		var punctuation_marks := [
			".", "?", "~", "!", ":", ";", "]", ">", "*", "<", "\"", "-", "^"
		]
		for i in 10:
			punctuation_marks.append(str(i))
		
		if line.ends_with("]"):
			var opening_index = line.rfind("[")
			if opening_index > 0:
				if not line[opening_index - 1] in punctuation_marks:
					line = line.insert(opening_index, ".")
		
		for mark in punctuation_marks:
			if line.ends_with(mark):
				has_punctuation = true
		
		if has_punctuation:
			result.append(line)
		else:
			result.append(line + ".")
	
	for rule : Dictionary in replacement_rules:
		var enabled : bool = rule.get("enabled")
		if not enabled:
			continue
		var what = rule.get("symbol", "")
		var forwhat = rule.get("replacement", "")
		for i in result.size():
			var line : String = result[i]
			result[i] = line.replace(what, forwhat)
	
	return "\n".join(result)

func save_text(id:String, text:String) -> void:
	text_data[id] = text

func get_text(id:String, default:="") -> String:
	return text_data.get(id, default)

func does_text_id_exist(id:String) -> bool:
	return id in text_data.keys()

func get_text_id_address_and_type(id:String) -> Array:
	for page in page_data.values():
		var page_index = page.get("number")
		var line_index := 0
		for line in page.get("lines"):
			var content = line.get("content")
			if line.get("line_type") == DIISIS.LineType.Choice:
				if content.get("title_id") == id:
					var address := str(page_index, ".", line_index)
					return [address, "Choice Title"]
				var choice_index := 0
				for choice in content.get("choices"):
					var address := str(page_index, ".", line_index, ".", choice_index)
					if choice.get("text_id_enabled") == id:
						return [address, "Choice Enabled"]
					elif choice.get("text_id_disabled") == id:
						return [address, "Choice Disabled"]
					choice_index += 1
			elif line.get("line_type") == DIISIS.LineType.Text:
				if content.get("text_id") == id:
					var address := str(page_index, ".", line_index)
					return [address, "Text Line"]
			line_index += 1
	return ["0.0", "Not Found"]

func get_speakers() -> Array:
	return dropdowns.get(dropdown_title_for_dialog_syntax, []).duplicate()

## exact means only the passed speakers can be entered
func get_text_line_adrs_with_speakers(speakers:Array, exact:=false) -> Array:
	if speakers.is_empty():
		push_warning("Speakers is empty. Returning empty results.")
		return []
	var results := []
	for i in page_data.size():
		var pdata = get_page_data(i)
		for line : Dictionary in pdata.get("lines", []):
			if line.get("line_type") != DIISIS.LineType.Text:
				continue
			var text = get_text(line.get("content").get("text_id"))
			var contains_all := true
			for speaker : String in speakers:
				if not text.contains("[]>%s" % speaker):
					contains_all = false
					break
			if exact:
				for global_speaker in get_speakers():
					if global_speaker in speakers:
						continue
					if text.contains("[]>%s" % global_speaker):
						contains_all = false
						break
			if contains_all:
				results.append(line.get("address"))
	return results

func change_text_id(old_id:String, new_id:String) -> void:
	for page in page_data.values():
		var page_index = page.get("number")
		var broken:=false
		for line in page.get("lines"):
			var content = line.get("content")
			if line.get("line_type") == DIISIS.LineType.Choice:
				if content.get("title_id") == old_id:
					content["title_id"] = new_id
					broken = true
					break
				for choice in content.get("choices"):
					if choice.get("text_id_enabled") == old_id:
						choice["text_id_enabled"] = new_id
						broken = true
						break
					if choice.get("text_id_disabled") == old_id:
						choice["text_id_disabled"] = new_id
						broken = true
						break
			elif line.get("line_type") == DIISIS.LineType.Text:
				if content.get("text_id") == old_id:
					content["text_id"] = new_id
					broken = true
					break
		if broken:
			break
	
	if text_data.has(old_id):
		var old_value : String = text_data.get(old_id)
		text_data[new_id] = old_value
		text_data.erase(old_id)
	
func get_new_id() -> String:
	id_counter += 1
	return str(str("%0.3f" % Time.get_unix_time_from_system()), "-", id_counter)

## Returns a dict with keys "loopback", "jump" and "next"
func get_references_to_page(page_index:int) -> Dictionary:
	var line_count = get_page_data(page_index).get("lines", []).size()
	var loopback_references := []
	var jump_references := []
	if first_index_as_page_reference_only:
		loopback_references.append_array(get_loopback_references_to(page_index, 0))
		jump_references.append_array(get_jump_references_to(page_index, 0))
	else:
		for i in line_count:
			loopback_references.append_array(get_loopback_references_to(page_index, i))
			jump_references.append_array(get_jump_references_to(page_index, i))
	var next_references := []
	for page in page_data.values():
		if page.get("next", -1) == page_index and not page.get("terminate", false):
			next_references.append(str(int(page.get("number"))))
	return {
		"loopback" : loopback_references,
		"jump" : jump_references,
		"next" : next_references,
	}

func get_loopback_references_to(page_index:int, line_index:int) -> Array:
	return loopback_references_by_page.get(page_index, {}).get(line_index, [])
	
func get_jump_references_to(page_index:int, line_index:int) -> Array:
	return jump_page_references_by_page.get(page_index, {}).get(line_index, [])

func get_facts_data(address:String) -> Dictionary:
	var parts = DiisisEditorUtil.get_split_address(address)
	var cpn : int = editor.get_current_page_number()
	match DiisisEditorUtil.get_address_depth(address):
		DiisisEditorUtil.AddressDepth.Page:
			var data : Dictionary = editor.get_current_page().serialize()
			return data.get("facts", {}).get("fact_data_by_name", {})
		DiisisEditorUtil.AddressDepth.Line:
			var data := get_line_data(parts[0], parts[1])
			return data.get("facts", {}).get("fact_data_by_name", {})
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			var data : Dictionary = get_line_data(parts[0], parts[1]).get("content").get("choices")[parts[2]]
			return data.get("facts", {}).get("fact_data_by_name", {})
	
	return {}

func get_line_data_adr(address:String) -> Dictionary:
	var data := {}
	var parts = DiisisEditorUtil.get_split_address(address)
	return get_lines_safe(parts[0], parts[1])[parts[1]]

func get_line_data(page_index:int, line_index:int) -> Dictionary:
	return get_line_data_adr(str(page_index, ".", line_index))

func get_fact_data_payload_before_deletion(address:String) -> Dictionary:
	var facts_by_address := {}
	var parts = DiisisEditorUtil.get_split_address(address)
	match DiisisEditorUtil.get_address_depth(address):
		DiisisEditorUtil.AddressDepth.Page:
			var facts_data : Dictionary = get_facts_data(address)
			if not facts_data.is_empty():
				facts_by_address[address] = facts_data
			for i in editor.get_current_page().get_line_count():
				var line_address := str(address, ".", i)
				var line_payload = get_fact_data_payload_before_deletion(line_address)
				if not line_payload.is_empty():
					for key : String in line_payload.keys():
						facts_by_address[key] = line_payload.get(key)#.get(line_address)
		DiisisEditorUtil.AddressDepth.Line:
			var line_type := get_line_type(parts[0], parts[1])
			var line_data = get_line_data(parts[0], parts[1])
			var line_facts_data = get_facts_data(address)
			if not line_facts_data.is_empty():
				facts_by_address[address] = line_facts_data
			if line_type == DIISIS.LineType.Choice:
				var choices : Array = line_data.get("content", {}).get("choices", [])
				for i in choices.size():
					var choice_address := str(address, ".", i)
					var choice_payload = get_fact_data_payload_before_deletion(choice_address)
					if not choice_payload.is_empty():
						facts_by_address[choice_address] = choice_payload.get(choice_address)
		DiisisEditorUtil.AddressDepth.ChoiceItem:
			var facts_data = get_facts_data(address)
			if not facts_data.is_empty():
				facts_by_address[address] = facts_data
	
	return facts_by_address

func set_setting(value, setting:StringName):
	set(setting, value)

func make_puppy() -> String:
	var eyes := [
		[">", "<"],
		[",,>", "<,,"],
		["o", "o"],
		["O", "O"],
		["U", "U"],
		["u", "u"],
		["-", "-"],
		["^", "^"],
		["*^", "^*"],
		[".", "."],
		[";", ";"],
		["q", "q"],
		["e", "e"],
		["x", "x"],
		[",;,", ",;,"],
		]

	var whiskers := [
		[">", "<"],
		["-", "-"],
		["=", "="],
		["☆⌒", "⌒☆"],
	]

	var mouths := [
		"w",
		"w",
		"//w//",
		"w",
		"v",
		"m",
		"ω",
		"//ω//",
		"_",
		"∀",
		"▽",
		"﹏",
	]
	randomize()
	
	var has_whiskers = randf() < 0.7
	
	var emoticon = ""
	var w = whiskers.pick_random()
	if has_whiskers:
		emoticon += w[0]
	var e = eyes.pick_random()
	emoticon += e[0]
	emoticon += mouths.pick_random()
	emoticon += e[1]
	if has_whiskers:
		emoticon += w[1]
	return emoticon


func linearize_pages():
	for i in get_page_count():
		var data := get_page_data(i)
		data["next"] = i + 1
		data["terminate"] = i == get_page_count() - 1
		page_data[i] = data
	await get_tree().process_frame
	editor.refresh(false)
