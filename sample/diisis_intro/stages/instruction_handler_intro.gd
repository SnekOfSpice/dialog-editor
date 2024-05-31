extends InstructionHandler


signal start_black_fade(
	fade_in:float,
	hold_time:float,
	fade_out:float,
	hide_characters:bool,
	new_background:String,
	new_bgm:String)

signal show_cg(
	cg_name:String,
	fade_in:float,
	on_top:bool)

func execute(instruction_name, args) -> bool:
	match instruction_name:
		"black_fade":
			print(args)
			var fade_in : float = args.get("fade_in")
			emit_signal("start_black_fade",
			fade_in,
			args.get("hold_time"),
			args.get("fade_out"),
			args.get("hide_characters"),
			args.get("new_background"),
			args.get("new_bgm"),
			)
			
			return true
		"show_cg":
			#var fade_in : float = 
			emit_signal("show_cg",
			args.get("name"),
			args.get("fade_in_time"),
			not args.get("continue_dialog_through_cg")
			)
			if not args.get("continue_dialog_through_cg"):
				return true
	return false
