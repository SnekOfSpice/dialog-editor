extends Control

var nodes := {}

var leftKeyDown := false
var rightKeyDown := false
var upKeyDown := false
var downKeyDown := false

func _ready() -> void:
	connect("visibility_changed", on_visibility_changed)

func _process(delta: float) -> void:
	var md := Vector2()
	if leftKeyDown:
		md.x -= 1
	if rightKeyDown:
		md.x += 1
	if upKeyDown:
		md.y -= 1
	if downKeyDown:
		md.y += 1
	
	var zoom_change := 0.0
	if Input.is_action_just_pressed("mouse_wheel_up"):
		zoom_change += 0.1
	if Input.is_action_just_pressed("mouse_wheel_down"):
		zoom_change -= 0.1
	$Camera.zoom.x += zoom_change
	$Camera.zoom.x = clamp($Camera.zoom.x, 0.2, 5)
	$Camera.zoom.y += zoom_change
	$Camera.zoom.y = clamp($Camera.zoom.y, 0.2, 5)
	
	$Camera.position += md.normalized() * delta * 350 * (1.0 / float($Camera.zoom.x))

func _input(event: InputEvent) -> void:
	if pressed(event, "ui_left"):
		leftKeyDown = true
	elif pressed(event, "ui_right"):
		rightKeyDown = true
	elif pressed(event, "ui_up"):
		upKeyDown = true
	elif pressed(event, "ui_down"):
		downKeyDown = true
	elif released(event, "ui_left"):
		leftKeyDown = false
	elif released(event, "ui_right"):
		rightKeyDown = false
	elif released(event, "ui_up"):
		upKeyDown = false
	elif released(event, "ui_down"):
		downKeyDown = false

func pressed(event, actionName:String) -> bool:
	return InputMap.event_is_action(event, actionName) and event.pressed

func released(event, actionName:String) -> bool:
	return InputMap.event_is_action(event, actionName) and not event.pressed

func on_visibility_changed():
	var cam : Camera2D = find_child("Camera")
	cam.enabled = visible
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
	var origin := Vector2.ZERO
	var radius = Pages.get_page_count() * 50
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
