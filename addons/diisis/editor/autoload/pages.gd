@tool
extends Node


var head_defaults := []

var dropdowns := {"character": ["dii", "sis"]}
var dropdown_titles := ["character"]
var dropdown_dialog_arguments := []
var dropdown_title_for_dialog_syntax := "character"
var use_dialog_syntax := true
var text_lead_time_same_actor := 0.0
var text_lead_time_other_actor := 0.0

var empty_strings_for_l10n := false
var locales_to_export := ["af_ZA", "sq_AL", "ar_SA", "hy_AM", "az_AZ", "eu_ES", "be_BY", "bn_IN", "bs_BA", "bg_BG", "ca_ES", "zh_CN", "zh_TW", "hr_HR", "cs_CZ", "da_DK", "nl_NL", "en_US", "et_EE", "fo_FO", "fi_FI", "fr_FR", "gl_ES", "ka_GE", "de_DE", "el_GR", "gu_IN", "he_IL", "hi_IN", "hu_HU", "is_IS", "id_ID", "it_IT", "ja_JP", "kn_IN", "kk_KZ", "kok_IN", "ko_KR", "lv_LV", "lt_LT", "mk_MK", "ms_MY", "ml_IN", "mt_MT", "mr_IN", "mn_MN", "se_NO", "nb_NO", "nn_NO", "fa_IR", "pl_PL", "pt_BR", "pa_IN", "ro_RO", "ru_RU", "sr_BA", "sk_SK", "es_ES", "sw_KE", "sv_SE", "syr_SY", "ta_IN", "te_IN", "th_TH", "tn_ZA", "tr_TR", "uk_UA", "uz_UZ", "vi_VN", "cy_GB", "xh_ZA", "zu_ZA"]
const DOMINANT_LOCALES := ["af_ZA", "sq_AL", "ar_SA", "hy_AM", "az_AZ", "eu_ES", "be_BY", "bn_IN", "bs_BA", "bg_BG", "ca_ES", "zh_CN", "zh_TW", "hr_HR", "cs_CZ", "da_DK", "nl_NL", "en_US", "et_EE", "fo_FO", "fi_FI", "fr_FR", "gl_ES", "ka_GE", "de_DE", "el_GR", "gu_IN", "he_IL", "hi_IN", "hu_HU", "is_IS", "id_ID", "it_IT", "ja_JP", "kn_IN", "kk_KZ", "kok_IN", "ko_KR", "lv_LV", "lt_LT", "mk_MK", "ms_MY", "ml_IN", "mt_MT", "mr_IN", "mn_MN", "se_NO", "nb_NO", "nn_NO", "fa_IR", "pl_PL", "pt_BR", "pa_IN", "ro_RO", "ru_RU", "sr_BA", "sk_SK", "es_ES", "sw_KE", "sv_SE", "syr_SY", "ta_IN", "te_IN", "th_TH", "tn_ZA", "tr_TR", "uk_UA", "uz_UZ", "vi_VN", "cy_GB", "xh_ZA", "zu_ZA"]
const LOCALES := ["af_ZA",
"sq_AL",
"ar_DZ",
"ar_BH",
"ar_EG",
"ar_IQ",
"ar_JO",
"ar_KW",
"ar_LB",
"ar_LY",
"ar_MA",
"ar_OM",
"ar_QA",
"ar_SA",
"ar_SY",
"ar_TN",
"ar_AE",
"ar_YE",
"hy_AM",
"az_AZ",
"eu_ES",
"be_BY",
"bn_IN",
"bs_BA",
"bg_BG",
"ca_ES",
"zh_CN",
"zh_HK",
"zh_MO",
"zh_SG",
"zh_TW",
"hr_HR",
"cs_CZ",
"da_DK",
"nl_BE",
"nl_NL",
"en_AU",
"en_BZ",
"en_CA",
"en_IE",
"en_JM",
"en_NZ",
"en_PH",
"en_ZA",
"en_TT",
"en_VI",
"en_GB",
"en_US",
"en_ZW",
"et_EE",
"fo_FO",
"fi_FI",
"fr_BE",
"fr_CA",
"fr_FR",
"fr_LU",
"fr_MC",
"fr_CH",
"gl_ES",
"ka_GE",
"de_AT",
"de_DE",
"de_LI",
"de_LU",
"de_CH",
"el_GR",
"gu_IN",
"he_IL",
"hi_IN",
"hu_HU",
"is_IS",
"id_ID",
"it_IT",
"it_CH",
"ja_JP",
"kn_IN",
"kk_KZ",
"kok_IN",
"ko_KR",
"lv_LV",
"lt_LT",
"mk_MK",
"ms_BN",
"ms_MY",
"ml_IN",
"mt_MT",
"mr_IN",
"mn_MN",
"se_NO",
"nb_NO",
"nn_NO",
"fa_IR",
"pl_PL",
"pt_BR",
"pt_PT",
"pa_IN",
"ro_RO",
"ru_RU",
"sr_BA",
"sr_CS",
"sk_SK",
"sl_SI",
"es_AR",
"es_BO",
"es_CL",
"es_CO",
"es_CR",
"es_DO",
"es_EC",
"es_SV",
"es_GT",
"es_HN",
"es_MX",
"es_NI",
"es_PA",
"es_PY",
"es_PE",
"es_PR",
"es_ES",
"es_UY",
"es_VE",
"sw_KE",
"sv_FI",
"sv_SE",
"syr_SY",
"ta_IN",
"te_IN",
"th_TH",
"tn_ZA",
"tr_TR",
"uk_UA",
"uz_UZ",
"vi_VN",
"cy_GB",
"xh_ZA",
"zu_ZA",]

var facts := {}

var instruction_templates := {
		"show-character": {
			"args" : [
				"character_name",
				"clear_others"
			],
			"arg_types" : [
				"string",
				"bool"
			]
		},
		"rotate": {
			"args" : [
				"angle"
			],
			"arg_types":
				["float"]
		}
	}

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

var evaluator_paths := ["res://sample/inline_eval.gd"]

signal pages_modified

func serialize() -> Dictionary:
	return {
		"head_defaults" : head_defaults,
		"page_data" : page_data,
		"instruction_templates": instruction_templates,
		"facts": facts,
		"dropdowns": dropdowns,
		"dropdown_titles": dropdown_titles,
		"dropdown_dialog_arguments": dropdown_dialog_arguments,
		"dropdown_title_for_dialog_syntax": dropdown_title_for_dialog_syntax,
		"file_config": get_file_config(),
		"locales_to_export" : locales_to_export,
		"empty_strings_for_l10n": empty_strings_for_l10n,
		"use_dialog_syntax": use_dialog_syntax,
		"text_lead_time_other_actor": text_lead_time_other_actor,
		"text_lead_time_same_actor": text_lead_time_same_actor,
	}

func deserialize(data:Dictionary):
	# all keys are now strings instead of ints
	var int_data = {}
	var local_page_data = data.get("page_data")
	for i in local_page_data.size():
		var where = int(local_page_data.get(str(i)).get("number"))
		int_data[where] = local_page_data.get(str(i)).duplicate()
	
	page_data.clear()
	page_data = int_data.duplicate()
	head_defaults = data.get("head_defaults", [])
	instruction_templates = data.get("instruction_templates", {})
	if data.get("facts") is Array:
		var compat_facts := {}
		for f in data.get("facts"):
			compat_facts[f] = true
		facts = compat_facts
	else:
		facts = data.get("facts", {})
	dropdowns = data.get("dropdowns", {})
	dropdown_titles = data.get("dropdown_titles", [])
	dropdown_dialog_arguments = data.get("dropdown_dialog_arguments", [])
	dropdown_title_for_dialog_syntax = data.get("dropdown_title_for_dialog_syntax", "")
	locales_to_export = data.get("locales_to_export", DOMINANT_LOCALES)
	empty_strings_for_l10n = data.get("empty_strings_for_l10n", false)
	use_dialog_syntax = data.get("use_dialog_syntax", true)
	text_lead_time_other_actor = data.get("text_lead_time_other_actor", 0.0)
	text_lead_time_same_actor = data.get("text_lead_time_same_actor", 0.0)
	
	apply_file_config(data.get("file_config", {}))

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
	


func swap_page_references(from: int, to: int):
	for page in page_data.values():
		var next = page.get("next")
		if next == from:
			page["next"] = to
		elif next == to:
			page["next"] = from
		
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				for choice in content.get("choices"):
					if choice.get("target_page") == from:
						choice["target_page"] = to
					elif choice.get("target_page") == to:
						choice["target_page"] = from
	await get_tree().process_frame
	editor.refresh(false)
	

func get_lines(page_number: int):
	return page_data.get(page_number).get("lines")

func change_page_references_dir(changed_page: int, operation:int):
	for page in page_data.values():
		var next = page.get("next")
		if next >= changed_page:
			page["next"] = next + operation
		
		
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var content = line.get("content")
				var choices = content.get("choices")
				for choice in choices:
					if choice.get("target_page") >= changed_page:
						choice["target_page"] = choice.get("target_page") + operation
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

func get_line_type(page_index:int, line_index:int) -> int:
	var page = page_data.get(page_index, {})
	var lines = page.get("lines")
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

func get_choice_text_shortened(page_index:int, line_index:int, choice_index:int):
	var page = page_data.get(page_index, {})
	var lines = page.get("lines")
	var line = lines[line_index]
	var choice = line.get("content").get("choices")[choice_index]
	var choice_text:String
	if choice.get("choice_text.enabled_as_default", true):
		choice_text = choice.get("choice_text.enabled")
	else:
		choice_text = choice.get("choice_text.disabled")
	return choice_text.left(25)

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
		var data = page_data.get(i)
		var new_number = data.get("number") - 1
		data["number"] = new_number
		page_data[new_number] = data
	
	# the last page is now a duplicate
	page_data.erase(get_page_count() - 1)
	
	change_page_references_dir(at, -1)
	
	emit_signal("pages_modified")


func get_data_from_address(address:String):
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

func get_defaults(property_key:String):
	for p in head_defaults:
		if p.get("property_name") == property_key:
			return p
	
	return {
		"name": "empty-instruction",
		"value":"defaultvalue",
		"data_type":DataTypes._String
	}

func get_all_instruction_names() -> Array:
	return instruction_templates.keys()

func get_instruction_arg_names(instruction_name: String) -> Array:
	return instruction_templates.get(instruction_name, {}).get("args", [])

func get_instruction_arg_types(instruction_name: String) -> Array:
	return instruction_templates.get(instruction_name, {}).get("arg_types", [])

func get_all_invalid_instructions() -> String:
	var warning := ""
	var page_index  := 0
	var malformed_instructions := []
	for page in page_data.values():
		var lines : Array = page.get("lines", [])
		var line_index := 0
		for line in lines:
			if line.get("line_type") != DIISIS.LineType.Instruction:
				continue
			var text = line.get("content").get("meta.text")
			var compliance := get_entered_instruction_compliance(text)
			if compliance != "OK":
				malformed_instructions.append(str("[url=goto-",str(page_index, ".", line_index),"]", page_index, ".", line_index, "[/url]"))
			line_index += 1
		page_index += 1
	
	if not malformed_instructions.is_empty():
		warning += str("Warning: invalid instructions at: ", ", ".join(malformed_instructions))
	return warning


# new schema with keys and values
func apply_new_header_schema(new_schema: Array):
	for i in page_data:
		var lines = page_data.get(i).get("lines")
		
		for line in lines:
			prints("PRETRANSFORM-", line["header"], " SCHEMA-> ", new_schema)
			line["header"] = transform_header(line.get("header"), new_schema, head_defaults)
			prints("POSTTRANSFORM-", line["header"])
	
	
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


func character_count_on_page_approx(page_number: int) -> int:
	var count := 0
	for line in page_data.get(page_number, {}).get("lines", []):
		var line_type = line.get("line_type")
		var content = line.get("content")
		if line_type ==	DIISIS.LineType.Choice:
			for choice in content.get("choices"):
				count += str(choice.get("choice_text.enabled")).length()
				count += str(choice.get("choice_text.disabled")).length()
		elif line_type ==	DIISIS.LineType.Text:
			count += str(content.get("content")).length()
	return count

func word_count_on_page_approx(page_number: int) -> int:
	var count := 0
	for line in page_data.get(page_number, {}).get("lines", []):
		var line_type = line.get("line_type", null)
		var content = line.get("content")
		if line_type ==	DIISIS.LineType.Choice:
			for choice in content.get("choices"):
				count += str(choice.get("choice_text.enabled")).count(" ") + 1
				count += str(choice.get("choice_text.disabled")).count(" ") + 1
		elif line_type == DIISIS.LineType.Text:
			count += str(content.get("content")).count(" ") + 1
			count -= str(content.get("content")).count("[]>")
				
	return count

func character_count_total_approx() -> int:
	var sum := 0
	for i in page_data.keys():
		sum += character_count_on_page_approx(i)
	
	return sum
func word_count_total_approx() -> int:
	var sum := 0
	for i in page_data.keys():
		sum += word_count_on_page_approx(i)
	
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
			if line["content"]["active_actors_title"] == from:
				line["content"]["active_actors_title"] = to
			line["content"]["content"] = line["content"]["content"].replace(str("{", from, "|"), str("{", to, "|"))
			line["content"]["content"] = line["content"]["content"].replace(str("[]>", from), str("[]>", to))

func set_dropdown_options(dropdown_title:String, options:Array):
	var old_options : Array = dropdowns.get(dropdown_title, [])
	
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
				line["content"]["content"] = line["content"]["content"].replace(old_arg, new_arg)
				
				i += 1
	
	dropdowns[dropdown_title] = options

func alter_fact(from:String, to=null):
	for page in page_data.values():
		
		var page_facts:Dictionary
		page_facts = page.get("facts", {}).get("fact_data_by_name", {})
		for fact in page_facts.keys():
			if fact == from:
				if to is String:
					page_facts[to] = page_facts[from]
				page_facts.erase(from)
		
		for i in page.get("lines", []).size():
			var line = page.get("lines")[i]
			var line_facts:Dictionary
			line_facts = line.get("facts", {}).get("fact_data_by_name", {})
			for fact in line_facts.keys():
				if fact == from:
					if to is String:
						line_facts[to] = line_facts[from]
					line_facts.erase(from)
			
			var line_conditionals:Dictionary
			line_conditionals = line.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
			for fact in line_conditionals:
				if fact == from:
					if to is String:
						line_conditionals[to] = line_conditionals[from]
					line_conditionals.erase(from)
			
			if line.get("line_type") == DIISIS.LineType.Choice:
				var options = line.get("content")
				var choice_index := 0
				for option in options.get("choices", {}):
					var option_conditionals:Dictionary
					option_conditionals = option.get("conditionals", {}).get("facts", {}).get("fact_data_by_name", {})
					for fact in option_conditionals:
						if fact == from:
							if to is String:
								option_conditionals[to] = option_conditionals[from]
							option_conditionals.erase(from)
					
					var option_facts:Dictionary
					option_facts = option.get("facts", {}).get("fact_data_by_name", {})
					for fact in option_facts:
						if fact == from:
							if to is String:
								option_facts[to] = option_facts[from]
							option_facts.erase(from)
					choice_index += 1
	
	if to is String:
		facts[to] = facts.get(from)
	facts.erase(from)
	
	editor.refresh(false)

func does_address_exist(address:String) -> bool:
	if address.ends_with("."):
		return false
	var parts :Array[int]= DiisisEditorUtil.get_split_address(address)
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

func get_evaluator_methods() -> Array:
	var methods := []
	for evaluator : String in evaluator_paths:
		var script_methods:Array
		if evaluator.ends_with(".tscn"):
			var n = load(evaluator)
			if not n:
				push_warning(str("Couldn't load", evaluator))
				continue
			var s = n.get_script()
			if not s:
				push_warning(str("Couldn't get script on", evaluator))
				continue
			script_methods = s.get_script_method_list()
			n.queue_free()
		elif evaluator.ends_with(".gd"):
			var n = load(evaluator)
			if not n:
				push_warning(str("Couldn't load", evaluator))
				continue
			script_methods = n.get_script_method_list()
		else:
			push_warning(str("Couldn't resolve", evaluator, "because it doesn't end with .tscn or .gd"))
			continue
		
		for method in script_methods:
			if not methods.has(method.get("name")):
				methods.append(method.get("name"))
	
	var base = Node.new()
	var base_methods = base.get_method_list()
	for method in base_methods:
		methods.erase(method.get("name"))
	base.queue_free()
	
	methods.erase("execute")
	methods.erase("_wrapper_execute")
	return methods

func get_evaluator_properties() -> Array:
	var methods := []
	for evaluator : String in evaluator_paths:
		var script_methods:Array
		if evaluator.ends_with(".tscn"):
			var n = load(evaluator)
			if not n:
				push_warning(str("Couldn't load", evaluator))
				continue
			var s = n.get_script()
			if not s:
				push_warning(str("Couldn't get script on", evaluator))
				continue
			script_methods = s.get_script_property_list()
			n.queue_free()
		elif evaluator.ends_with(".gd"):
			var n = load(evaluator)
			if not n:
				push_warning(str("Couldn't load", evaluator))
				continue
			script_methods = n.get_script_property_list()
		else:
			push_warning(str("Couldn't resolve", evaluator, "because it doesn't end with .tscn or .gd"))
			continue
		
		for method in script_methods:
			if not methods.has(method.get("name")):
				methods.append(method.get("name"))
	
	var base = Node.new()
	var base_methods = base.get_property_list()
	for method in base_methods:
		methods.erase(method.get("name"))
	base.queue_free()
	for method : String in methods:
		if method.ends_with(".gd") or method.ends_with(".tscn"):
			methods.erase(method)
	
	return methods

func search_string(substr:String):
	var found_facts := {}
	for fact : String in facts:
		if fact.contains(substr):
			found_facts[fact] = fact
	
	var found_choices := {}
	var found_text := {}
	var page_index := 0
	for page in page_data.values():
		var line_index := 0
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Choice:
				var choice_index := 0
				for choice in line.get("content", {}).get("choices", []):
					if choice.get("choice_text.enabled").contains(substr):
						found_choices[str(page_index, ".", line_index, ".", choice_index, " - enabled")] = choice.get("choice_text.enabled")
					if choice.get("choice_text.disabled").contains(substr):
						found_choices[str(page_index, ".", line_index, ".", choice_index, " - disabled")] = choice.get("choice_text.disabled")
					choice_index += 1
			elif line.get("line_type") == DIISIS.LineType.Text:
				var text : String = line.get("content", {}).get("content", "")
				if text.contains(substr):
					found_text[str(page_index, ".", line_index)] = text
			line_index += 1
		page_index += 1
	
	var result := {
		"facts":found_facts,
		"text":found_text,
		"choices":found_choices,
	}
	return result

func get_localizable_addresses() -> Array:
	return get_localizable_addresses_with_content().keys()

func get_localizable_addresses_with_content() -> Dictionary:
	var localizable_addresses := {}
	var page_index := 0
	for page in page_data.values():
		var line_index := 0
		for line in page.get("lines"):
			if line.get("line_type") == DIISIS.LineType.Text:
				localizable_addresses[(str(page_index, ".", line_index))] = line.get("content", {}).get("content", "")
			elif line.get("line_type") == DIISIS.LineType.Choice:
				var choice_index := 0
				for choice in line.get("content", {}).get("choices", []):
					if not choice.get("choice_text.enabled").is_empty():
						localizable_addresses[(str(page_index, ".", line_index, ".", choice_index, "enabled"))] = choice.get("choice_text.enabled")
					if not choice.get("choice_text.disabled").is_empty():
						localizable_addresses[(str(page_index, ".", line_index, ".", choice_index, "disabled"))] = choice.get("choice_text.disabled")
					choice_index += 1
			line_index += 1
		page_index += 1

	return localizable_addresses


func add_template_from_string(instruction:String):
	var entered_name := instruction.split("(")[0]
	var arg_string := instruction.trim_prefix(entered_name)
	arg_string = arg_string.trim_prefix("(")
	arg_string = arg_string.trim_suffix(")")
	
	var arg_names := []
	var arg_types := []
	var entered_args := arg_string.split(",")
	for arg in entered_args:
		if arg.is_empty():
			continue
		if arg.contains(":"): # typed
			var arg_name := arg.split(":")[0]
			var arg_type := arg.split(":")[1]
			while arg_name.begins_with(" "):
				arg_name = arg_name.trim_prefix(" ")
			while arg_name.ends_with(" "):
				arg_name = arg_name.trim_suffix(" ")
			while arg_type.begins_with(" "):
				arg_type = arg_type.trim_prefix(" ")
			while arg_type.ends_with(" "):
				arg_type = arg_type.trim_suffix(" ")
			arg_names.append(arg_name)
			arg_types.append(arg_type)
		else: # implicitly convert to string
			while arg.begins_with(" "):
				arg = arg.trim_prefix(" ")
			while arg.ends_with(" "):
				arg = arg.trim_suffix(" ")
			arg_names.append(arg)
			arg_types.append("string")
	
	instruction_templates[entered_name] = {
		"args" : arg_names,
		"arg_types": arg_types
	}

func update_instruction_from_template(old_name:String, new_full_instruction:String):
	var old_template : Dictionary = instruction_templates.get(old_name)
	instruction_templates.erase(old_name)
	add_template_from_string(new_full_instruction)
	var new_entered_name := new_full_instruction.split("(")[0]
	var new_template : Dictionary = instruction_templates.get(new_entered_name)
	
	for page in page_data.values():
		var lines : Array = page.get("lines", [])
		for line in lines:
			if line.get("line_type") != DIISIS.LineType.Instruction:
				continue
			if line.get("content", {}).get("name", "") != old_name:
				continue
			line["content"]["name"] = new_entered_name
			
			var old_text : String = line["content"]["meta.text"]
			
			var old_template_data = parse_instruction_to_handleable_dictionary(old_text, old_template)
			
			var old_arg_count : int = old_template.get("args").size()
			var old_arg_names : Array = old_template.get("args")
			var old_arg_types : Array = old_template.get("arg_types")
			var new_arg_count : int = new_template.get("args").size()
			var new_arg_names : Array = new_template.get("args")
			var new_arg_types : Array = new_template.get("arg_types")
			
			var transformed_string := new_entered_name
			transformed_string += "("
			
			var i := 0
			var goal_arg_count := min(old_arg_count, new_arg_count)
			while i < goal_arg_count:
				transformed_string += str(old_template_data.get("args").get(old_arg_names[i]))
				if i < goal_arg_count - 1:
					transformed_string += ", "
				i += 1
			
			
			transformed_string += ")"
			
			# instruction container handles it when it inits and finds an empty meta.text but existing args
			line["content"]["meta.text"] = transformed_string
			line["content"]["line_reader.args"] = parse_instruction_to_handleable_dictionary(transformed_string)
			
	

func parse_instruction_to_handleable_dictionary(instruction_text:String, template_override:={}) -> Dictionary:
	if get_entered_instruction_compliance(instruction_text) != "OK" and template_override.is_empty():
		return {}
	
	var result := {}
	var entered_name = instruction_text.split("(")[0]
	result["name"] = entered_name
	
	var args := {}
	var arg_names := template_override.get("args", Pages.get_instruction_arg_names(entered_name))
	var arg_types := template_override.get("arg_types", Pages.get_instruction_arg_types(entered_name))
	instruction_text = instruction_text.trim_prefix(str(entered_name, "("))
	instruction_text = instruction_text.trim_suffix(")")
	var entered_args := instruction_text.split(",")
	var i := 0
	
	while i < entered_args.size() and not entered_args.is_empty() and not arg_types.is_empty():
		var arg = entered_args[i]
		while arg.begins_with(" "):
			arg = arg.trim_prefix(" ")
		while arg.ends_with(" "):
			arg = arg.trim_suffix(" ")
		
		var arg_value
		var arg_type:String=arg_types[i]
		var value_string := arg.split(":")[0]
		if arg_type == "string":
			arg_value = value_string
		elif arg_type == "bool":
			if value_string == "true":
				arg_value = true
			if value_string == "false":
				arg_value = false
		elif arg_type == "float":
			if value_string.is_empty():
				arg_value = str("no value")
			else:
				arg_value = float(value_string)
	
		args[arg_names[i]] = arg_value
		i += 1
	
	result["args"] = args
	
	return result

func does_instruction_name_exist(instruction_name:String):
	return instruction_templates.keys().has(instruction_name)

func get_compliance_with_template(instruction:String) -> String:
	var entered_name = instruction.split("(")[0]
	if not does_instruction_name_exist(entered_name):
		return str("Instruction ", entered_name, " does not exist")
	
	if instruction.count(",") + 1 != instruction_templates.get(entered_name).get("args").size():
		if instruction.count(",") > 0:
			return "Arg count mismatch"
	
	# for every arg, if it's float, it can't have non float chars, if bool, it has to be "true" or "false"
	var args_string = instruction.trim_prefix(entered_name)
	args_string = args_string.trim_prefix("(")
	args_string = args_string.trim_suffix(")")
	var args := args_string.split(",")
	var template_types : Array = instruction_templates[entered_name].get("arg_types", [])
	
	var i := 0
	while i < template_types.size() and not template_types.is_empty() and not args.is_empty():
		var arg_string : String = args[i]
		while arg_string.begins_with(" "):
			arg_string = arg_string.trim_prefix(" ")
		while arg_string.ends_with(" "):
			arg_string = arg_string.trim_suffix(" ")
		var arg_value : String = arg_string.split(":")[0]
		if arg_value.is_empty():
			return str("Argument ", i+1, " is empty")
		if template_types[i] == "bool":
			if arg_value != "true" and arg_value != "false":
				return str("Bool argument ", i + 1, " is neither \"true\" nor \"false\"")
		if template_types[i] == "float":
			for char in arg_value:
				if not char in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "."]:
					return str("Float argument ", i + 1, " contains non-float character. (0 - 9 and .)")
		i += 1
	
	return "OK"

func try_delete_instruction_template(instruction_name:String):
	instruction_templates.erase(instruction_name)

func get_entered_instruction_compliance(instruction:String, check_as_template:=false, error_on_duplicate := false) -> String:
	if instruction.count("(") != 1:
		return "Missing or excess ("
	if instruction.count(")") != 1:
		return "Missing or excess )"
	if instruction[instruction.length() - 1] != ")":
		return "Doesn't end with )"
	if instruction.find("(") > instruction.find(")"):
		return "( can't be behind )"
	if instruction.find("(") == 0:
		return "Can't start with ("
	
	var entered_name = instruction.split("(")[0]
	if check_as_template:
		if does_instruction_name_exist(entered_name) and error_on_duplicate:
			return "Instruction already exists"
		
		if entered_name.contains(" "):
			return "Entered name contains a space"
		
		if instruction.find("(") + 1 != instruction.find(")"):
			# for every arg, it must be ended with :bool, :string, :float (json doesn't support int / float distinction
			# and I can't be bothered to write support for dictionaries or arrays atm)
			var arg_string = instruction.trim_prefix(entered_name)
			arg_string = arg_string.trim_prefix("(")
			arg_string = arg_string.trim_suffix(")")
			var args := arg_string.split(",")
			var arg_names := []
			for arg in args:
				if arg.count(":") > 1:
					return "One or more args contain more than one :"
				if arg.contains(":") and not (arg.ends_with(":string") or arg.ends_with(":bool") or arg.ends_with(":float")):
					return "One or more typed arguments don't end in \":string\", \":bool\", or \":float\""
				var arg_name := arg.split(":")[0]
				while arg_name.begins_with(" "):
					arg_name = arg_name.trim_prefix(" ")
				while arg_name.ends_with(" "):
					arg_name = arg_name.trim_suffix(" ")
				if arg_name.is_empty():
					return "Empty argument name"
				if arg_names.has(arg_name):
					return "Duplicate argument names"
				else:
					arg_names.append(arg_name)
	else: # check as sth that follows the template
		var template_compliance := get_compliance_with_template(instruction)
		if template_compliance != "OK":
			return template_compliance
	
	
			
	
	return "OK"


