@tool
extends Window

signal go_to(page_number:int)
var direct_swap_start := -1

func set_items_visible_name(search:String, override:=false):
	if search.is_empty():
		for i in %Items.get_children():
			i.visible = true
	else:
		for i : MovePageItem in %Items.get_children():
			if i.visible or override:
				i.visible = Pages.get_page_key(i.number).containsn(search)

func swap_pages(page_a: int, page_b: int):
	var undo_redo = Pages.editor.undo_redo
	undo_redo.create_action("Move Pages")
	undo_redo.add_do_method(DiisisEditorActions.swap_pages.bind(page_a, page_b))
	undo_redo.add_undo_method(DiisisEditorActions.swap_pages.bind(page_b, page_a))
	undo_redo.commit_action()
	
	fill()


func fill():
	direct_swap_start = -1
	for i in find_child("Items").get_children():
		i.queue_free()
	
	for i in Pages.page_data.keys():
		var item = preload("res://addons/diisis/editor/src/move_page_item.tscn").instantiate()
		find_child("Items").add_child(item)
		item.set_number(i)
		item.connect("move_page", swap_pages)
		item.connect("on_direct_swap", direct_swap)
		item.connect("go_to", on_item_go_to)
		item.init()
	
	%FilterLineEdit.text = ""
	%FilterLineEdit.grab_focus()
	%UnsubmittedFiltersWarning.hide()
	set_items_visible_name("")
	Pages.apply_font_size_overrides(self)

func direct_swap(page_clicked: int):
	if direct_swap_start == -1:
		direct_swap_start = page_clicked
		return
	
	swap_pages(direct_swap_start, page_clicked)
	direct_swap_start = -1

func on_item_go_to(number:int):
	emit_signal("go_to", number)
	hide()

func _on_about_to_popup() -> void:
	fill()


func _on_close_requested() -> void:
	hide()




func _on_reset_address_mode_popup_change_to_mode(mode: AddressModeButton.Mode) -> void:
	for item in find_child("Items").get_children():
		item.set_address_mode(mode)


func _on_v_id_pressed(id: int) -> void:
	match id:
		0:
			if Pages.confirm_linearize:
				var popup : RichTextConfirmationDialog = Pages.editor.popup_confirm_dialogue(
					"Linearizing pages assigns each page to point to its next-highest page, with the final page terminating the document, and all other page termination disabled. [b]This cannot be undone![/b]\n(This prompt can be disabled in [url=openwindow-FileConfigPopup]Editor > Preferences[/url])",
					"Confirm Linearize",
					(func():
						Pages.linearize_pages()
						fill())
					)
				popup.ok_button_text = "Linearize!"
			else:
				Pages.linearize_pages()
				fill()
		1:
			Pages.editor.popup_accept_dialogue(
				str("◌ Any filters that do not fall within the parameters below are treated like page key searches\n",
					"-----------\n",
					"◌ Order the entries with [code]order:asc[/code] and [code]order:desc[/code]",
					"\n",
					"◌ You can filter by word count by writing [code]wc:>200[/code] etc. Accepts
					[code]=[/code]
					[code]>=[/code]
					[code]>[/code]
					[code]<[/code]
					[code]<=[/code]",
					"\n\n◌ Separate all these commands with a space",
					"\n◌ You can enter multiple word counts to get pages with word count between those values",
					"[center]", "[color=pink]Submit filters with ENTER[/color]",
					"\n[font=res://addons/diisis/editor/visuals/theme/fonts/LinearAtype.ttf]shoutout alcoholic corpsefucking[/font]" if Pages.silly else "",
					"[/center]"
				),
				"Sort & Filter help"
			)
		2:
			$ResetAddressModePopup.popup()
			$ResetAddressModePopup.grab_focus()
			$ResetAddressModePopup.position = size - $ResetAddressModePopup.size
			# idk shit's fucked lol
			size.x += 1
			size.x -= 1



func set_items_movable(value : bool) -> void:
	for item : MovePageItem in %Items.get_children():
		item.set_movable(value)

func set_items_visible_wordcount(cutoff := -1, operand := WordCountOperand.Greater) -> void:
	for item : MovePageItem in %Items.get_children():
		match operand:
			WordCountOperand.Greater:
				if item.visible: item.visible = item.get_word_count() > cutoff
			WordCountOperand.Lesser:
				if item.visible: item.visible = item.get_word_count() < cutoff
			WordCountOperand.Equals:
				if item.visible: item.visible = item.get_word_count() == cutoff


enum WordCountOperand {
	Greater,
	Lesser,
	Equals
}
enum ItemSortKind {
	PageNumber,
	Ascending,
	Descending
}


func sort_items(sort_kind := ItemSortKind.PageNumber) -> void:
	var items : Array = %Items.get_children()
	items.sort_custom(func(item1 : MovePageItem, item2 : MovePageItem):
		if sort_kind == ItemSortKind.Ascending:
			return item1.get_word_count() < item2.get_word_count()
		if sort_kind == ItemSortKind.Descending:
			return item1.get_word_count() > item2.get_word_count()
		else:
			return item1.get_number() < item2.get_number()
		)
	for item in %Items.get_children():
		%Items.move_child(item, items.find(item))
	



func _on_filter_line_edit_text_submitted(new_text: String) -> void:
	%UnsubmittedFiltersWarning.hide()
	set_items_movable(new_text.is_empty())
	set_items_visible_name("")
	var filters := new_text.split(" ", false)
	for filter : String in filters:
		if filter.begins_with("order:"):
			if filter.trim_prefix("order:") == "asc":
				sort_items(ItemSortKind.Ascending)
			elif filter.trim_prefix("order:") == "desc":
				sort_items(ItemSortKind.Descending)
			else:
				sort_items(ItemSortKind.PageNumber)
		elif filter.begins_with("wc:"):
			var cutoff : int
			var operand : String
			var regex = RegEx.new()
			regex.compile("([0-9])+")
			for m : RegExMatch in regex.search_all(filter):
				var entity_match : String  = m.strings[0]
				cutoff = int(entity_match)
			regex.compile("([><=])+")
			for m : RegExMatch in regex.search_all(filter):
				operand = m.strings[0]
			
			
			if operand == ">=":
				cutoff -= 1
			elif operand == "<=":
				cutoff += 1
			
			var operand_type : WordCountOperand
			if operand.contains(">"):
				operand_type = WordCountOperand.Greater
			elif operand.contains("<"):
				operand_type = WordCountOperand.Lesser
			else:
				operand_type = WordCountOperand.Equals
			
			set_items_visible_wordcount(cutoff, operand_type)
		else:
			set_items_visible_name(filter)
	
	%FilterLineEdit.call_deferred("grab_focus")


func _on_filter_line_edit_text_changed(new_text: String) -> void:
	if %Items.get_child(0).movable and not new_text.is_empty():
	#if new_text.length() == 1:
		set_items_movable(false)
	if new_text.is_empty():
		_on_filter_line_edit_text_submitted(new_text)
		set_items_visible_wordcount()
	set_items_visible_name("", true)
	%UnsubmittedFiltersWarning.hide()
	for filter : String in new_text.split(" ", false):
		if filter.begins_with("wc:") or filter.begins_with("order:"):
			%UnsubmittedFiltersWarning.show()
			continue
		set_items_visible_name(filter)
