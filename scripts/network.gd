extends Node3D

var connections: Dictionary = {}
var nodes

func add_connection(edges, a, b):
	if edges[a] not in connections:
		connections[edges[a]] = []
	connections[edges[a]].push_back(edges[b])

const wire_thickness = 0.04

func create_cube_mesh(pos: Vector3):
	var cube = CSGBox3D.new()
	cube.size = Vector3(wire_thickness, wire_thickness, wire_thickness)
	$WireMesh.add_child(cube)
	cube.position = pos
	
func create_edge_mesh(a: Vector3, b: Vector3):
	var cube = CSGBox3D.new()
	var diff = (b - a)
	var dx = max(abs(diff.x) - wire_thickness, wire_thickness)
	var dy = max(abs(diff.y) - wire_thickness, wire_thickness)
	var dz = max(abs(diff.z) - wire_thickness, wire_thickness)
	cube.size = Vector3(dx, dy, dz)
	$WireMesh.add_child(cube)
	cube.position = (a + b) / 2.0
# Called when the node enters the scene tree for the first time.
func _ready():
	var cube: MeshInstance3D = find_child("Grid")
	var mesh: ArrayMesh = cube.mesh
	var data = mesh.surface_get_arrays(0)
	nodes = data[0]
	var edges = data[12]
	cube.hide()
	# print(nodes)
	
	for node in nodes:
		create_cube_mesh(node)
	
	for i in range(0, edges.size(), 2):
		create_edge_mesh(nodes[edges[i]], nodes[edges[i+1]])
		add_connection(edges, i, i+1)
		add_connection(edges, i+1, i)
	# print(connections)
	
	$PlayerPath.curve.clear_points()
	$PlayerPath.curve.add_point(nodes[1])
	$PlayerPath/Player.position = nodes[1]

var current = 1
var tween

var buffered = []

func clear_tween():
	tween = null

var cached = -Vector3.FORWARD

func maybe_flip(i, normal):
	var space = get_world_3d().direct_space_state
	var params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 8
	params.position = to_global(nodes[i] + normal)
	if !space.intersect_point(params).is_empty():
		return normal
	return -normal
	
func get_normal(i):
	var n = connections[i].size()
	var space = get_world_3d().direct_space_state
	var params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 4
	params.position = to_global(nodes[i])
	if !space.intersect_point(params).is_empty():
		cached = Vector3.UP
		return cached
	if n == 0:
		return cached
	if n == 1:
		var next: Vector3 = (nodes[i] - nodes[connections[i][0]]).normalized()
		next = next.rotated(Vector3.UP, PI / 2.0)
		if next != Vector3.UP && next != Vector3.DOWN:
			cached = next
		return cached
	if n == 2:
		var a = nodes[i]
		var b = nodes[connections[i][0]]
		var c = nodes[connections[i][1]]
		var ab = (b - a).normalized()
		var ac = (c - a).normalized()
		var next = ab.cross(ac)
		if next != Vector3.UP && next != Vector3.DOWN:
			cached = maybe_flip(i, next)
		else:
			cached = -(ab + ac).normalized()
		return cached
	var a = nodes[connections[i][0]]
	var b = nodes[connections[i][1]]
	var c = nodes[connections[i][2]]
	var ab = (b - a).normalized()
	var ac = (c - a).normalized()
	var next = ab.cross(ac)
	if next != Vector3.UP && next != Vector3.DOWN:
		cached = maybe_flip(i, next)
	return cached
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if electrified && Input.is_action_just_pressed("pop") && !is_instance_valid(tween):
		electrified.kill()
		electrified = null
		tween = get_tree().create_tween()
		tween.tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ONE * 0.5, 0.2)
		tween.tween_callback(clear_tween)
		
	# DebugDraw3D.draw_arrow(to_global(nodes[current]), to_global(nodes[current] + get_normal(current) * 1.0), Color.RED, 0.05)
	var normal = get_normal(current)
	if normal == Vector3.UP:
		$Camera3D.ceiling = true
	else:
		$Camera3D.ceiling = false
	$Camera3D.destination = to_global(nodes[current] + get_normal(current) * 1.5)
	$Camera3D.target = to_global(nodes[current])
	var input = Vector2.ZERO
	if Input.is_action_just_pressed("move_down"):
		input = Vector2.DOWN
	elif Input.is_action_just_pressed("move_up"):
		input = Vector2.UP
	elif Input.is_action_just_pressed("move_left"):
		input = Vector2.LEFT
	elif Input.is_action_just_pressed("move_right"):
		input = Vector2.RIGHT

	if input != Vector2.ZERO:
		if buffered.size() < 2:
			buffered.push_back(input)
		
	if !buffered.is_empty() && !is_instance_valid(tween):
		input = buffered.pop_front()
		var path = [nodes[current]]
		for n in connections[current]:
			var diff = nodes[current] - nodes[n]
			var rotated = -diff.x
			# print($Camera3D.target_rotation)
			if $Camera3D.target_rotation > PI / 3.0 && $Camera3D.target_rotation < 2 * PI / 3.0:
				rotated = diff.z
			elif $Camera3D.target_rotation >= PI / 6.0 && $Camera3D.target_rotation < PI / 3.0:
				print("A")
				rotated = diff.x - diff.z # ???
			elif $Camera3D.target_rotation >= 5 * PI / 6.0 && $Camera3D.target_rotation < 7 * PI / 6.0:
				rotated = diff.x
			elif $Camera3D.target_rotation >= 2 * PI / 3.0 && $Camera3D.target_rotation < 5 * PI / 6.0:
				print("B")
				rotated = diff.x + diff.z
			elif $Camera3D.target_rotation >= 4 * PI / 3.0 && $Camera3D.target_rotation < 5 * PI / 3.0:
				rotated = -diff.z
			elif $Camera3D.target_rotation >= 7 * PI / 6.0 && $Camera3D.target_rotation < 4 * PI / 3.0:
				print("C")
				rotated = -diff.x + diff.z # ???
			elif $Camera3D.target_rotation >= 5 * PI / 3.0 && $Camera3D.target_rotation < 11 * PI / 6.0:
				print("D")
				rotated = -diff.x - diff.z
			var adjusted = Vector2(rotated, diff.y).normalized()
			if $Camera3D.ceiling:
				print("we on ceilin")
				adjusted = Vector2(diff.z, -diff.x).normalized()
			# print("considering ", n)
			print(adjusted)
			print(input)
			if adjusted.distance_squared_to(input) < 0.001:
				print("cooking")
				if electrified:
					electrified.electrified = false
					electrified = null
				while connections[n].size() == 2:
					# make sure we stop at operators
					var operable = find_operable(nodes[n])
					# print(params.position)
					if operable:
						# print("BONK")
						break
					path.push_back(nodes[n])
					# print(connections[n])
					var a = connections[n][0]
					var b = connections[n][1]
					var prev = n
					n = a if current != a else b
					# print("MOVING FROM ", current, " TO ", n)
					current = prev
					get_normal(current)
				# print("MOVING FROM ", current, " TO ", n)
				current = n
				get_normal(current)
				path.push_back(nodes[n])
				var curve: Curve3D = $PlayerPath.curve
				curve.clear_points()
				var path_length = 0.0
				var start = path[0]
				for p in path:
					path_length += (p - start).length()
					start = p
					curve.add_point(p + get_normal(current) * 0.1)
				$PlayerPath/Player.progress = 0.0
				tween = get_tree().create_tween()
				tween.parallel().tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ONE * 0.5, 0.2)
				tween.set_ease(Tween.EASE_IN_OUT)
				tween.set_trans(Tween.TRANS_QUAD)
				tween.parallel().tween_property($PlayerPath/Player, "progress_ratio", 1.0, 0.25 * path_length)
				var operable = find_operable(curve.get_point_position(curve.point_count - 1))
				if operable:
					tween.tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ZERO, 0.2)
					electrified = operable
					tween.tween_callback(func(): operable.electrified = true)
				tween.tween_callback(clear_tween)
				break

var electrified = null
func find_operable(pos: Vector3):
	var space = get_world_3d().direct_space_state
	var params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 2
	params.collide_with_areas = true
	params.position = to_global(pos)
	var res = space.intersect_point(params)
	if res.is_empty():
		return null
	var candidate = res[0].collider.get_parent()
	if candidate.dead:
		return null
	return candidate
