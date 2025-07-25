@tool
extends Control
class_name Page

var number := 0
var next := 1
var lines:Node

@onready var page_key_line_edit : LineEdit = find_child("PageKeyLineEdit")

signal request_delete()

func init(n:=number):
	%GoToHighlight.self_modulate.a = 0
	var data = Pages.page_data.get(n)
	number = n
	lines = find_child("Lines")
	find_child("Number").text = str(n)
	find_child("DeleteButton").disabled = n == 0
	find_child("DeleteButton").tooltip_text = "Page 0 cannot be deleted." if n == 0 else "Delete page."
	set_next(n+1)
	find_child("Facts").init()
	deserialize(data)
	page_key_line_edit.placeholder_text = "Page " + str(n)

func get_next():
	if find_child("TerminateCheck").button_pressed:
		push_warning("Getting next from a page that terminates.")
	return next

func get_page_key() -> String:
	return str(find_child("PageKeyLineEdit").text)

func set_page_key(value:String):
	find_child("PageKeyLineEdit").text = value

func add_fact(fact_name: String, fact_value):
	var facts = find_child("Facts")
	facts.add_fact(fact_name, fact_value)

func delete_fact(fact_name:String):
	var facts = find_child("Facts")
	facts.delete_fact(fact_name)

var block_next_duplicate_key_warning := false
func save():
	block_next_duplicate_key_warning = true
	Pages.page_data[number] = serialize()

func serialize() -> Dictionary:
	if not lines:
		init(number)
	var data := {}
	
	data["number"] = int(number)
	data["page_key"] = get_page_key()
	data["next"] = find_child("NextLineEdit").value
	data["meta.scroll_vertical"] = int(find_child("ScrollContainer").scroll_vertical)
	data["terminate"] = find_child("TerminateCheck").button_pressed
	data["facts"] = find_child("Facts").serialize()
	data["meta.selected"] = find_child("LineSelector").button_pressed
	data["meta.address_mode_next"] = int(find_child("AddressModeButton").get_mode())
	data["skip"] = find_child("SkipCheckBox").button_pressed
	
	var lines_data := []
	for c in lines.get_children():
		if not c is Line:
			continue
		lines_data.append(c.serialize())
	data["lines"] = lines_data
	
	return data

func deserialize(data: Dictionary):
	block_next_duplicate_key_warning = false
	if not lines:
		init(int(data.get("next", number+1)))
	set_page_key(data.get("page_key", "")) 
	set_next(int(data.get("next", number+1)))
	find_child("TerminateCheck").button_pressed = data.get("terminate", false)
	deserialize_lines(data.get("lines", []))
	find_child("Facts").deserialize(data.get("facts", {}))
	find_child("LineSelector").button_pressed = data.get("meta.selected", false)
	find_child("AddressModeButton").set_mode(data.get("meta.address_mode_next", Pages.default_address_mode_pages))
	set_skip(data.get("skip", false))
	
	update_incoming_references_to_page()
	
	await get_tree().process_frame
	find_child("ScrollContainer").scroll_vertical = data.get("meta.scroll_vertical", 0)
	update()

func set_skip(value:bool):
	modulate.a = 0.6 if value else 1
	find_child("SkipCheckBox").button_pressed = value

func deserialize_lines(lines_data: Array):
	# instantiate lines
	var lines_to_delete := []
	for l in lines.get_children():
		if not l is Line:
			continue
		if l.get_index() >= lines_data.size():
			lines_to_delete.append(l)
	
	for l in lines_to_delete:
		l.queue_free()
	
	var data_by_index := {}
	var i := 0
	while i < lines_data.size():
		data_by_index[i] = lines_data[i]
		i += 1
	
	add_lines(data_by_index.keys(), data_by_index)
	enable_page_key_edit(false)

func set_next(next_page: int):
	next = next_page
	var next_exists = Pages.page_data.keys().has(next)
	find_child("NextKey").modulate.a = 1.0 if next_exists else 0.0
	
	var next_key = Pages.page_data.get(next, {}).get("page_key", "")
	
	find_child("NextLineEdit").max_value = Pages.get_page_count() - 1
	find_child("NextLineEdit").value = next
	find_child("NextKey").text = str(
		"[url=goto-%s]" % next_page,
		next_key,
		"[/url]"
		)


func enable_page_key_edit(value: bool):
	find_child("PageKeyLineEdit").editable = value
	
	find_child("Seperator").visible = get_page_key() != ""
	find_child("Number").visible = get_page_key() != ""
	
	if value:
		page_key_line_edit.grab_focus()
		page_key_line_edit.caret_column = page_key_line_edit.text.length()
	else:
		find_child("PageKeyEditButton").grab_focus()

func save_page_key_from_line_edit():
	save()
	enable_page_key_edit(false)
	find_child("PageKeyEditButton").button_pressed = false


func _on_page_key_edit_button_toggled(button_pressed: bool) -> void:
	set_editing_page_key(button_pressed)

var page_key_before_edit := ""
func set_editing_page_key(value:bool):
	if value:
		if not page_key_line_edit.editable:
			page_key_before_edit = get_page_key()
	else:
		save_page_key_from_line_edit()
	enable_page_key_edit(value)


func _on_page_key_line_edit_text_changed(new_text: String) -> void:
	find_child("PageKeyEditButton").disabled = Pages.key_exists(new_text) and page_key_before_edit != new_text

func get_lines_to_delete(at_index) -> Array[Line]:
	var line_to_delete : Line = lines.get_child(at_index)
	var lines_to_delete : Array[Line] = [line_to_delete]
	
	
	if Input.is_key_pressed(KEY_SHIFT) and line_to_delete.line_type == DIISIS.LineType.Folder:
		var folder_range : Vector2 = line_to_delete.get_folder_range_v()
		for i in range(at_index + 1, folder_range.y + 2): # I wish I knew why +2
			lines_to_delete.append(lines.get_child(i))
	
	return lines_to_delete

func get_line(at_index:int) -> Line:
	if at_index < 0 or at_index >= lines.get_child_count():
		return null
	return lines.get_child(at_index)

func get_line_data(at_index:int) -> Dictionary:
	return lines.get_child(at_index).serialize()

func request_delete_line(at_index:int):
	var indices_to_delete := get_indices_to_delete(at_index, Input.is_key_pressed(KEY_SHIFT))
	var line_data_to_delete := {}
	var lines = lines
	for i in indices_to_delete:
		line_data_to_delete[i] = (lines.get_child(i).serialize())
	
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Delete Line")
	# delete in reverse
	indices_to_delete.reverse()
	undo_redo.add_do_method(DiisisEditorActions.delete_lines.bind(indices_to_delete))
	
	# restore in ascending index order
	indices_to_delete.reverse()
	undo_redo.add_undo_method(DiisisEditorActions.add_lines.bind(indices_to_delete, line_data_to_delete, true, true))
	undo_redo.commit_action()

func delete_line(at_index):
	delete_lines([at_index])

func delete_lines(indices:Array):
	# sort in descending order
	indices.sort()
	indices.reverse()
	
	# delete bottom up
	for i in indices:
		# handle folder shrinking
		for l in lines.get_children():
			if l.line_type == DIISIS.LineType.Folder:
				var range : Vector2 = l.get_folder_range_v()
				if i >= range.x and i <= range.y:
					l.change_folder_range(-1)
		
		lines.get_child(i).queue_free()

func get_indices_to_delete(start_index:int, consider_folder:=false) -> Array:
	if not consider_folder:
		return [start_index]
	
	var result := []
	var line_to_delete : Line = lines.get_child(start_index)
	
	if line_to_delete.line_type == DIISIS.LineType.Folder:
		var folder_range : Vector2 = line_to_delete.get_folder_range_v()
		for i in range(start_index, folder_range.y + 1): # I wish I knew why +2
			result.append(i)
	
	return result

func ensure_control_at_address_is_visible(address:String):
	find_child("ScrollContainer").scroll_vertical = 0
	await get_tree().process_frame
	var target = DiisisEditorUtil.get_node_at_address(address)
	find_child("ScrollContainer").ensure_control_visible(target)

func get_line_count():
	return lines.get_child_count()

func request_add_line(at_index:int):
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Add Line")
	DiisisEditorActions.blank_override_line_addresses.append(str(number, ".", at_index))
	undo_redo.add_do_method(DiisisEditorActions.add_line.bind(at_index, {}, true, true))
	undo_redo.add_undo_method(DiisisEditorActions.delete_line.bind(at_index))
	undo_redo.commit_action()

func add_lines(indices:Array, data_by_index:={}, force_new_line_object:=false, change_line_references:=false):
	indices.sort()
	var added_new_line := false
	for at_index in indices:
		if at_index >= lines.get_child_count():
			added_new_line = true
		var line:Line
		var line_data = data_by_index.get(at_index, {})
		if at_index >= lines.get_child_count() or force_new_line_object:
			line = preload("res://addons/diisis/editor/src/line.tscn").instantiate()
			lines.add_child(line)
			lines.move_child(line, at_index)
			line.init()
			line.connect("move_line", request_move_line)
			line.connect("insert_line", request_add_line)
			line.connect("delete_line", request_delete_line)
			line.connect("move_to", move_line_to)
		else:
			line = lines.get_child(at_index)
			line.deserialize({})
		
		if line_data != {}:
			line.deserialize(line_data)
		
		if line.line_type == DIISIS.LineType.Choice and line.get_choice_item_count() == 0:
			line.add_choice_item(0)
			line.add_choice_item(1)
		
		for l : Line in lines.get_children():
			if l.line_type == DIISIS.LineType.Folder:
				var range : Vector2 = l.get_folder_range_v()
				if at_index > range.x and at_index <= range.y:
					l.change_folder_range(1)
		
		if change_line_references:
			var to = Pages.editor.get_current_page().get_line_count() - 1 if Pages.editor.get_current_page() else indices.max()
			save()
			Pages.change_line_references_directional(
			Pages.editor.get_current_page_number(),
			at_index,
			to,
			 + 1
			)
	
	if added_new_line:
		await get_tree().process_frame
		find_child("ScrollContainer").scroll_vertical = find_child("ScrollContainer").get_v_scroll_bar().max_value

func add_line(at_index:int, data := {}):
	add_lines([at_index], {at_index: data})
	

func swap_lines(index0:int, index1:int):
	if index0 == index1:
		return
	if lines.get_child_count() - 1 < max(index0, index1):
		return
	
	var line0 = lines.get_child(index0)
	var line1 = lines.get_child(index1)
	
	lines.move_child(line0, index1)
	lines.move_child(line1, index0)
	
	update()

func request_move_line(line: Line, dir:int):
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Move Line")
	undo_redo.add_do_method(DiisisEditorActions.move_line.bind(line, dir))
	undo_redo.add_undo_method(DiisisEditorActions.move_line.bind(line, -dir))
	undo_redo.commit_action()

func move_line(line: Line, dir:int):
	var idx := line.get_index()
	var lines = lines
	if idx <= 0 and dir == -1:
		return
	
	if idx == lines.get_child_count() - 1 and dir == 1 and not Input.is_key_pressed(KEY_SHIFT):
		return
	
	if Input.is_key_pressed(KEY_SHIFT):
		var jumped_line := get_line(idx + dir)
		if jumped_line == null and dir == 1:
			var i = idx
			var prev_indent_level = get_line(idx - 1).indent_level
			while i > 0 and prev_indent_level > 0:
				var prev_line := get_line(i - 1)
				if prev_line.line_type == DIISIS.LineType.Folder:
					prev_line.change_folder_range(-1)
				i -= 1
				prev_indent_level = get_line(idx-1).indent_level
		elif jumped_line.line_type == DIISIS.LineType.Folder:
			jumped_line.change_folder_range(dir)
			#update()
			lines.move_child(line, idx+dir)
			Pages.swap_line_references(number, idx, idx+dir)
		elif jumped_line.indent_level != line.indent_level:
			var folder_operation:int
			if line.indent_level < jumped_line.indent_level: # add to folders
				folder_operation = 1
			elif line.indent_level > jumped_line.indent_level: # remove from folders
				folder_operation = -1
			
			var i = idx
			var prev_indent_level = get_line(idx - 1).indent_level
			while i > 0 and prev_indent_level > 0:
				var prev_line := get_line(i - 1)
				if prev_line.line_type == DIISIS.LineType.Folder:
					prev_line.change_folder_range(folder_operation)
				i -= 1
				prev_indent_level = get_line(idx-1).indent_level
				
		else:
			lines.move_child(line, idx+dir)
			Pages.swap_line_references(number, idx, idx+dir)
		update()
		return
	
	if line.line_type == DIISIS.LineType.Folder:
		if dir == -1:
			move_folder_up(line)
		elif dir == 1:
			move_folder_down(line)
		return
	
	var bump:int
	if dir == -1:
		var previous_line:Line = lines.get_child(idx - 1)
		
		if previous_line.line_type == DIISIS.LineType.Folder and previous_line.indent_level == line.indent_level and line.indent_level > 0:
			update()
			Pages.editor.notify("Use Shift to move outside of folder boundaries.")
			return
		bump = idx+dir
		if previous_line.indent_level > line.indent_level:
			# the line before this is in a folder, jump to before the folder
			var previous_range = range(idx)
			previous_range.reverse()
			
			for i in previous_range:
				var l:Line = lines.get_child(i)
				
				if l.indent_level <= line.indent_level:
					break
				bump = i
	elif dir == 1:
		var next_line:Line = lines.get_child(idx + 1)
		
		if next_line.indent_level < line.indent_level:
			update()
			Pages.editor.notify("Use Shift to move outside of folder boundaries.")
			return
		
		if next_line.line_type == DIISIS.LineType.Folder:
			bump = next_line.get_next_index() - 1
		else:
			bump = line.get_next_index()
		
	
	
	lines.move_child(line, bump)
	Pages.swap_line_references(number, idx, bump)
	update()

func move_folder_up(line:Line):
	var idx = line.get_index()
	var lines = lines
	var previous_line:Line = lines.get_child(idx - 1)
	if previous_line.line_type != DIISIS.LineType.Folder and previous_line.indent_level <= line.indent_level:
		lines.move_child(previous_line, idx + max(1, line.get_folder_range_i()))
		Pages.swap_line_references(number, idx, idx + max(1, line.get_folder_range_i()))
	else:
		#look before until you find start of page or something with less indentation
		var previous_indices = range(idx)
		previous_indices.reverse()
		var bump:=0
		for i in previous_indices:
			bump = i
			var l : Line = lines.get_child(i)
			if l.indent_level < line.indent_level:
				break
		#if start of page: move to 0
		var lines_in_folder := [line]
		for i in range(idx, line.get_folder_range_i() + 1):
			lines_in_folder.append(lines.get_child(i))
		lines_in_folder.reverse()
		if bump == 0:
			for l in lines_in_folder:
				lines.move_child(l, 0)
				Pages.swap_line_references(number, idx, 0)
		else:
			for l in lines_in_folder:
				lines.move_child(l, bump + 1)
				Pages.swap_line_references(number, idx, bump + 1)
		#else: move to found line idx + 1

func move_folder_down(line:Line):
	var idx = line.get_index()
	var lines = lines
	var lines_in_folder := []
	var index_after_folder = line.get_next_index()# TODO: should als oaccount for folders directly after
	
	var line_after_folder : Line = lines.get_child(index_after_folder)
	for i in range(idx, index_after_folder):
		lines_in_folder.append(lines.get_child(i))
	index_after_folder = line_after_folder.get_index()
	
	for l in lines_in_folder:
		lines.move_child(l, index_after_folder)

func move_line_to(line : Line, target_idx):
	lines.move_child(line, target_idx)
	update()

func get_max_reach_after_indented_index(index: int):
	var line = lines.get_child(index)
	var reach := 0
	var i = index + 1
	while i < lines.get_children().size():
		var l : Line = lines.get_child(i)
		i += 1
	#for l in lines.get_children():
		#if l.get_index() <= index:
			#continue
		# line is the folder itself, which has its own ident level of 1, so all lines that are one level lower are still valid
		if l.indent_level < line.indent_level - 1:
			break
		reach += 1
	
	return reach

func update_incoming_references_to_page():
	var refs := get_references_to_this_page()
	var ref_count := refs.size()
	var ref_label : RichTextLabel = find_child("IncomingReferences")
	ref_label.visible = ref_count != 0
	if ref_count == 1:
		var page : String = refs[0]
		ref_label.text = "[url=goto-%s]%s[/url] " % [page, page]
		ref_label.tooltip_text = "%s points here. Click to go there.\nPage Key: %s" % [page, Pages.get_page_key(int(page))]
	else:
		var bars := ""
		for i in min(ref_count, 8):
			bars += "|"
		ref_label.text = "[url=references]%s[/url] " % bars
		ref_label.tooltip_text = "View %s incoming references." % ref_count

func update_incoming_references():
	Pages.sync_line_references()
	update_incoming_references_to_page()
	for line : Line in lines.get_children():
		line.update_incoming_reference_label()

func update():
	lines = find_child("Lines")
	for l in lines.get_children():
		l.set_indent_level(0)
		l.visible = true
	
	
	var i = 0
	for l : Line in lines.get_children():
		if l.line_type == DIISIS.LineType.Folder:
			l.update_folder(get_max_reach_after_indented_index(i))
		i += 1
	
	#var folders_found := 0
	for l : Line in lines.get_children():
		l.update()
		var idx = l.get_index()
		if l.line_type == DIISIS.LineType.Folder:
			var is_folder_content_visible := l.get_folder_contents_visible() and l.visible
			# all after that in range of the folder line get indented l.indent_level + 1
			var folder_range_i : int = l.get_folder_range_i()
			if folder_range_i == 0:
				continue
			for j in range(idx, idx + folder_range_i + 1):
				lines.get_child(j).change_indent_level(1)
				if j > idx: # if beyond the folder itself
					lines.get_child(j).visible = is_folder_content_visible
			#folders_found += 1
	
	for node in get_tree().get_nodes_in_group("diisis_page_view_sensitive"):
		node.set_page_view(Pages.editor.get_selected_page_view())
	
	find_child("Facts").update()
	

func _on_next_line_edit_value_changed(value: float) -> void:
	set_next(int(value))

func _on_terminate_check_toggled(toggled_on: bool) -> void:
	find_child("NextContainer").visible = not toggled_on
	find_child("AddressModeButton").visible = not toggled_on

func _on_line_selector_toggled(toggled_on: bool) -> void:
	for line : Line in lines.get_children():
		line.set_selected(toggled_on)


func _on_delete_button_pressed() -> void:
	if Pages.editor.try_prompt_fact_deletion_confirmation(
		str(number),
		request_delete.emit
	):
		return
	if find_child("DeletePromptContainer").visible:
		find_child("DeletePromptContainer").visible = false
		emit_signal("request_delete")
	else:
		find_child("DeletePromptContainer").visible = true

func _on_cancel_deletion_button_pressed() -> void:
	find_child("DeletePromptContainer").visible = false


func _on_page_key_line_edit_text_submitted(new_text: String) -> void:
	try_save_page_key(new_text)

func try_save_page_key(new_key):
	if Pages.key_exists(new_key) and page_key_before_edit != new_key:
		page_key_line_edit.grab_focus()
		page_key_line_edit.caret_column = page_key_line_edit.text.length()
		if block_next_duplicate_key_warning:
			block_next_duplicate_key_warning = false
			return
		Pages.editor.notify(str("Page ", new_key, " already exists at ", Pages.get_page_number_by_key(new_key)))
		return
	save_page_key_from_line_edit()


func _on_page_key_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not page_key_line_edit.editable:
				set_editing_page_key(true)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			page_key_line_edit.text = page_key_before_edit
			set_editing_page_key(false)


func _on_page_key_line_edit_focus_exited() -> void:
	try_save_page_key(page_key_line_edit.text)


func _on_page_key_line_edit_mouse_entered() -> void:
	find_child("PageKeyEditContainer").custom_minimum_size.x = find_child("PageKeyEditContainer").size.x
	page_key_line_edit.add_theme_stylebox_override("normal", load("uid://wygkuwnsf32l"))
	page_key_line_edit.add_theme_stylebox_override("read_only", load("uid://wygkuwnsf32l"))


func _on_page_key_line_edit_mouse_exited() -> void:
	find_child("PageKeyEditContainer").custom_minimum_size.x = 0
	page_key_line_edit.remove_theme_stylebox_override("normal")
	page_key_line_edit.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())


func _on_next_key_meta_clicked(meta: Variant) -> void:
	Pages.editor.goto_with_meta(meta)


func get_references_to_this_page() -> Array:
	var results : Dictionary = Pages.get_references_to_page(number)
	var loopback_references : Array = results.get("loopback")
	var jump_references : Array = results.get("jump")
	var next_references : Array = results.get("next")
	
	var full := []
	full.append_array(loopback_references)
	full.append_array(jump_references)
	full.append_array(next_references)
	return full


func _on_incoming_references_meta_clicked(meta: Variant) -> void:
	if str(meta) == "references":
		Pages.editor.view_incoming_references(number)
	else:
		Pages.editor.goto_with_meta(meta)


func flash_highlight(address:String):
	if DiisisEditorUtil.block_next_flash_highlight:
		DiisisEditorUtil.block_next_flash_highlight = false
		return
	var parts = DiisisEditorUtil.get_split_address(address)
	match parts.size():
		1:
			DiisisEditorUtil.flash_highlight(%GoToHighlight)
		2:
			get_line(parts[1]).flash_highlight()
		3:
			get_line(parts[1]).get_choice_item(parts[2]).flash_highlight()
