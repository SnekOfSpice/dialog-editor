@tool
extends Control
class_name Page

var number := 0
var page_key := ""
var next := 1

func init(n:=number):
	var data = Pages.page_data.get(n)
	number = n
	$Info/Number.text = str(n)
	set_next(n+1)
	find_child("Facts").init()
	deserialize(data)

func set_page_key(key: String):
	page_key = key
	$Info/PageKey.text = page_key

func clear():
	for c in get_children():
		if not c is Line:
			continue
		c.queue_free()

func save():
	Pages.page_data[number] = serialize()

func serialize() -> Dictionary:
	var data := {}
	
	data["number"] = number
	data["page_key"] = page_key
	data["next"] = find_child("NextLineEdit").value
	data["meta.scroll_vertical"] = find_child("ScrollContainer").scroll_vertical
	data["terminate"] = find_child("TerminateCheck").button_pressed
	data["facts"] = find_child("Facts").serialize()
	
	var lines_data := []
	for c in find_child("Lines").get_children():
		if not c is Line:
			continue
		lines_data.append(c.serialize())
	data["lines"] = lines_data
	
	return data

func deserialize(data: Dictionary):
	set_page_key(data.get("page_key"))
	if not data.get("next"):
		data["next"] = number+1
	set_next(int(data.get("next")))
	find_child("TerminateCheck").button_pressed = data.get("terminate", false)
	deserialize_lines(data.get("lines"))
	find_child("Facts").deserialize(data.get("facts", {}))
	
	await get_tree().process_frame
	find_child("ScrollContainer").scroll_vertical = data.get("meta.scroll_vertical", 0)
	update()

func deserialize_lines(lines_data: Array):
	# instantiate lines
	for l in find_child("Lines").get_children():
		if not l is Line:
			continue
		l.queue_free()
	
	for data in lines_data:
		var line = preload("res://addons/diisis/editor/src/line.tscn").instantiate()
		find_child("Lines").add_child(line)
		line.init()
		line.deserialize(data)
		line.connect("move_line", move_line)
		line.connect("delete_line", delete_line)
		line.connect("insert_line", add_line)
		line.connect("move_to", move_line_to)
	
	enable_page_key_edit(false)

func set_next(next_page: int):
	next = next_page
	var next_exists = Pages.page_data.keys().has(next)
	find_child("NextKey").visible = next_exists
	
	if not next_exists:
		return
	
	var next_key = Pages.page_data.get(next).get("page_key")
	
	find_child("NextLineEdit").max_value = Pages.get_page_count()
	find_child("NextLineEdit").value = next
	find_child("NextKey").text = next_key

func _on_page_key_edit_pressed() -> void:
	pass # Replace with function body.

func enable_page_key_edit(value: bool):
	$Info/PageKey.visible = not value
	$Info/PageKeyLineEdit.visible = value
	$Info/PageKeyLineEdit.text = page_key
	
	$Info/Seperator.visible = page_key != ""

func _on_page_key_edit_button_toggled(button_pressed: bool) -> void:
	if not button_pressed:
		# add check for duplicates later
		set_page_key($Info/PageKeyLineEdit.text)
		save()
	
	enable_page_key_edit(button_pressed)


func _on_page_key_line_edit_text_changed(new_text: String) -> void:
	$Info/PageKeyEditButton.disabled = Pages.key_exists(new_text)


func _on_add_pressed() -> void:
	add_line()

func delete_line(at_index):
	var line_to_delete : Line = find_child("Lines").get_child(at_index)
	var lines_to_delete := [line_to_delete]
	
	for l in find_child("Lines").get_children():
		if l.line_type == DIISIS.LineType.Folder:
			var range : Vector2 = l.get_folder_range_v()
			if at_index >= range.x and at_index <= range.y:
				l.change_folder_range(-1)
	
	var folder_range : Vector2 = line_to_delete.get_folder_range_v()
	if Input.is_key_pressed(KEY_SHIFT) and line_to_delete.line_type == DIISIS.LineType.Folder:
		for i in range(at_index + 1, folder_range.y + 2): # I wish I knew why +2
			lines_to_delete.append(find_child("Lines").get_child(i))
	
	for l in lines_to_delete:
		l.queue_free()
	
	await get_tree().process_frame
	update()

func add_line(at_index:int=find_child("Lines").get_child_count()):
	for l in find_child("Lines").get_children():
		if l.line_type == DIISIS.LineType.Folder:
			var range : Vector2 = l.get_folder_range_v()
			if at_index >= range.x and at_index <= range.y:
				l.change_folder_range(1)
			# if at_index iss within range (index to index + max value), increase range by 1
	var line = preload("res://addons/diisis/editor/src/line.tscn").instantiate()
	find_child("Lines").add_child(line)
	line.init()
	line.connect("move_line", move_line)
	line.connect("insert_line", add_line)
	line.connect("delete_line", delete_line)
	line.connect("move_to", move_line_to)
	
	var idx = line.get_index()
	while idx > at_index:
		find_child("Lines").move_child(line, idx-1)
		idx = line.get_index()
	
	update()

func swap_lines(index0:int, index1:int):
	if index0 == index1:
		return
	if find_child("Lines").get_child_count() - 1 < max(index0, index1):
		return
	
	var line0 = find_child("Lines").get_child(index0)
	var line1 = find_child("Lines").get_child(index1)
	
	find_child("Lines").move_child(line0, index1)
	find_child("Lines").move_child(line1, index0)
	
	update()

func move_line(line: Line, dir:int):
	var idx := line.get_index()
	var lines = find_child("Lines")
	if idx <= 0 and dir == -1:
		return
	
	if idx == lines.get_child_count() - 1 and dir == 1:
		return
	
	if Input.is_key_pressed(KEY_SHIFT):
		lines.move_child(line, idx+dir)
		update()
		return
	if line.line_type == DIISIS.LineType.Folder:
		if dir == -1:
			move_folder_up(line)
		elif dir == 1:
			move_folder_down(line)
	else:
		
		if dir == -1:
			var previous_line:Line = lines.get_child(idx - 1)
			
			if previous_line.line_type == DIISIS.LineType.Folder:
				update()
				push_warning("Use Shift to move outside of folder boundaries.")
				return
			var bump := idx+dir
			if previous_line.indent_level > line.indent_level:
				# the line before this is in a folder, jump to before the folder
				var previous_range = range(idx)
				previous_range.reverse()
				
				for i in previous_range:
					var l:Line = lines.get_child(i)
					
					if l.indent_level <= line.indent_level:
						break
					bump = i
			lines.move_child(line, bump)
		elif dir == 1:
			var next_line:Line = lines.get_child(idx + 1)
			printt(next_line.get_index(), line.get_index(), next_line.indent_level, line.indent_level)
			if next_line.indent_level < line.indent_level:
				update()
				push_warning("Use Shift to move outside of folder boundaries.")
				return
			
			var bump := next_line.get_next_index() - 1
			lines.move_child(line, bump)
	update()

func move_folder_up(line:Line):
	var idx = line.get_index()
	var lines = find_child("Lines")
	var previous_line:Line = find_child("Lines").get_child(idx - 1)
	if previous_line.line_type != DIISIS.LineType.Folder and previous_line.indent_level <= line.indent_level:
		lines.move_child(previous_line, idx + max(1, line.get_folder_range_i()))
	else:
		#look before until you find start of page or something with less indentation
		var previous_indices = range(idx)
		previous_indices.reverse()
		var bump:=0
		for i in previous_indices:
			bump = i
			var l : Line = lines.get_child(i)
			if l.indent_level < line.indent_level:
				prints("bump at ", i)
				break
		#if start of page: move to 0
		var lines_in_folder := [line]
		for i in range(idx, line.get_folder_range_i() + 1):
			lines_in_folder.append(lines.get_child(i))
		lines_in_folder.reverse()
		if bump == 0:
			for l in lines_in_folder:
				prints("moving from ", l.get_index(), "to 0")
				lines.move_child(l, 0)
		else:
			for l in lines_in_folder:
				prints("moving from ", l.get_index(), "to", bump+1)
				lines.move_child(l, bump + 1)
		#else: move to found line idx + 1

func move_folder_down(line:Line):
	var idx = line.get_index()
	var lines = find_child("Lines")
	var lines_in_folder := []
	var index_after_folder = line.get_next_index()# TODO: should als oaccount for folders directly after
	
	var line_after_folder : Line = lines.get_child(index_after_folder)
	for i in range(idx, index_after_folder):
		lines_in_folder.append(lines.get_child(i))
	index_after_folder = line_after_folder.get_next_index()
	prints("moving to ", index_after_folder)
	
	#lines_in_folder.reverse()
	for l in lines_in_folder:
		prints("moving ", l.get_index(), " to ", index_after_folder)
		lines.move_child(l, index_after_folder)
	#var lines_after := []
	#for i in range(idx + line.get_folder_range_i(), lines.get_child_count()):
		#var l :Line= lines.get_child(i)
		#
		#if l.indent_level > line.indent_level:
			#break
		#lines_after.append(lines.get_child(i))
	#lines_after.reverse()
	#for l in lines_after:
		#lines.move_child(l, idx)

func move_line_to(line : Line, target_idx):
	find_child("Lines").move_child(line, target_idx)
	update()

func get_max_reach_after_indented_index(index: int):
	var line = find_child("Lines").get_child(index)
	var reach := 0
	for l in find_child("Lines").get_children():
		if l.get_index() <= index:
			continue
		if l.indent_level < line.indent_level:
			break
		reach += 1
	
	return reach

func update():
	for l in find_child("Lines").get_children():
		l.set_indent_level(0)
		l.visible = true
	
	
	var folders_found := 0
	for l in find_child("Lines").get_children():
		l.update()
	
		if l.line_type == DIISIS.LineType.Folder:
			# all after that in range of the folder line get indented l.indent_level + 1
			var folder_range : Vector2 = l.get_folder_range_v()
			if folder_range.x == folder_range.y:
				continue
			for i in range(folder_range.x, folder_range.y + 1):
				find_child("Lines").get_child(i).change_indent_level(1)
				if i > folder_range.x: # if beyond the folder itself
					find_child("Lines").get_child(i).visible = l.get_folder_contents_visible()
			folders_found += 1


func _on_next_line_edit_value_changed(value: float) -> void:
	set_next(int(value))


func _on_delete_page_button_pressed() -> void:
	pass # Replace with function body.


func _on_terminate_check_toggled(toggled_on: bool) -> void:
	find_child("NextContainer").visible = not toggled_on