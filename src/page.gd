extends VBoxContainer


var number := 0
var page_key := ""


func init(n:=number):
	page_key = Pages.page_data.get(n).get("page_key")
	load_data(Pages.page_data.get(n).get("data"))

func load_data(page_data: Dictionary):
	# instantiate lines
	pass

func clear():
	for c in get_children():
		c.queue_free()
	
