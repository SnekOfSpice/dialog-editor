extends VBoxContainer


var number := 0
var page_key := ""


func init(n:=number):
	var data = Pages.page_data.get(n)
	page_key = data.get("page_key")
	number = n
	$Info/Number.text = str(n)
	$Info/PageKey.text = str(page_key)
	deserialize(data.get("data"))

func deserialize(page_data: Dictionary):
	# instantiate lines
	print(page_data)

func clear():
	for c in get_children():
		c.queue_free()
	
