extends Control

var nodes := {}

func _ready() -> void:
	connect("visibility_changed", on_visibility_changed)

func on_visibility_changed():
	if not visible:
		return
	
	for c in find_child("NodeContainer").get_children():
		c.queue_free()
	for c in find_child("EdgeContainer").get_children():
		c.queue_free()
	
	for i in Pages.page_data.keys():
		add_node(i)
	add_edges()

func add_edges():
	for graph_node in nodes.values():
		for c in graph_node.children:
			var ref = int(c)
			if nodes.has(ref):
				add_edge(graph_node, nodes.get(ref))
			else:
				prints(nodes.keys(), " doesnt have ", ref)

func add_node(page_index:int):
	var graph_node:GraphNodee
	if nodes.has(page_index) and is_instance_valid(nodes.get(page_index)):
		graph_node = nodes.get(page_index)
	else:
		graph_node = preload("res://src/graphview/graph_node.tscn").instantiate()
		nodes[page_index] = graph_node
		find_child("NodeContainer").add_child(graph_node)
		graph_node.children = Pages.get_page_references(page_index)
		graph_node.set_page_index(page_index)
	
	var pos:=Vector2.ZERO
	var origin := Vector2(1920, 1080) * 0.5
	var radius = 400
	pos.x = origin.x + radius * float(cos(2 * page_index * PI / Pages.get_page_count()))
	pos.y = origin.y + radius * float(sin(2 * page_index * PI / Pages.get_page_count()))
	graph_node.position = pos

func add_edge(from:GraphNodee, to:GraphNodee):
	prints("addionmg ", from.page_index , " - ", to.page_index)
	var edge = Line2D.new()
	var curve = Curve.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2.ONE * 0.7)
	edge.width_curve = curve
	edge.modulate.a = 0.4
	find_child("EdgeContainer").add_child(edge)
	edge.add_point(from.global_position + from.get_center())
	edge.add_point(to.global_position + to.get_center())
