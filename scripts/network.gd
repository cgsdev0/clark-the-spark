extends Node3D

var connections: Dictionary = {}
var nodes

@export var npc = false
@export var active = false

func add_connection(edges, a, b):
	if edges[a] not in connections:
		connections[edges[a]] = []
	connections[edges[a]].push_back(edges[b])

const wire_thickness = 0.04

func create_cube_mesh(pos: Vector3):
	var cube = CSGBox3D.new()
	cube.material = preload("res://materials/wires.tres")
	cube.size = Vector3(wire_thickness, wire_thickness, wire_thickness)
	if test_upstairs(to_global(pos)):
		$WireMesh/Upstairs.add_child(cube)
	else:
		$WireMesh.add_child(cube)
	cube.position = pos

func test_upstairs(point: Vector3):
	var space = get_world_3d().direct_space_state
	var params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 32
	params.position = point
	var result = space.intersect_point(params)
	if !result.is_empty():
		return result[0].collider.zone == "upstairs"
	return false
	
func create_edge_mesh(a: Vector3, b: Vector3):
	var cube = CSGBox3D.new()
	cube.material = preload("res://materials/wires.tres")
	var len = (b - a).length()
	# var dx = max(abs(diff.x) - wire_thickness, wire_thickness)
	# var dy = max(abs(diff.y) - wire_thickness, wire_thickness)
	# var dz = max(abs(diff.z) - wire_thickness, wire_thickness)
	var normal = (b-a).normalized()
	cube.size = Vector3(wire_thickness, wire_thickness, len)
	if test_upstairs(to_global(a)) && test_upstairs(to_global(b)):
		$WireMesh/Upstairs.add_child(cube)
	else:
		$WireMesh.add_child(cube)
	cube.position = (a + b) / 2.0
	cube.look_at(cube.global_position + normal, Vector3.FORWARD)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	var cube: MeshInstance3D = get_child(0)
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
	
	reinit()
	
func reinit(node = 0):
	if active:
		current = node
		$PlayerPath.curve.clear_points()
		$PlayerPath.curve.add_point(nodes[node])
		$PlayerPath/Player.position = nodes[node]

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

func is_point_in_ceiling(pos: Vector3) -> bool:
	var space = get_world_3d().direct_space_state
	var params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 4
	params.position = pos
	if !space.intersect_point(params).is_empty():
		return true
	return false
	
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
	space = get_world_3d().direct_space_state
	params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 64
	params.position = to_global(nodes[i])
	var result = space.intersect_point(params)
	if !result.is_empty():
		var obj = result[0].collider
		var node = obj.find_child("Forward")
		if is_instance_valid(node):
			return node.global_basis.z.normalized()
	if n == 1:
		var next: Vector3 = (nodes[i] - nodes[connections[i][0]]).normalized()
		if next != Vector3.UP && next != Vector3.DOWN:
			cached = next.normalized()
		return cached
	if n == 2:
		var a = nodes[i]
		var b = nodes[connections[i][0]]
		var c = nodes[connections[i][1]]
		var ab = (b - a).normalized()
		var ac = (c - a).normalized()
		var next = ab.cross(ac)
		if next != Vector3.UP && next != Vector3.DOWN && next != Vector3.ZERO:
			cached = maybe_flip(i, next.normalized())
		else:
			next = -(ab + ac).normalized()
			if next != Vector3.ZERO:
				cached = next
		return cached
	var a = nodes[connections[i][0]]
	var b = nodes[connections[i][1]]
	var c = nodes[connections[i][2]]
	var ab = (b - a).normalized()
	var ac = (c - a).normalized()
	var next = ab.cross(ac)
	if next != Vector3.UP && next != Vector3.DOWN:
		cached = maybe_flip(i, next.normalized())
	return cached

var can_buffer = true


var charging = false
var charge_time = 3.0

func pop():
	charging = false
	Events.add_score(electrified.get_reward())
	electrified.kill()
	electrified = null
	$PlayerPath/Player/ChargeSound.stop()
	tween = get_tree().create_tween()
	tween.tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ONE * 0.5, 0.2)
	tween.tween_callback(clear_tween)
	$PlayerPath/Player/PopSound.play()

var charge_timer = 0.0
var max_charge_time = 2.9
var is_possible = true
var require_release = false

var radius = 2.0

func find_nearest(pos: Vector3):
	var l = to_local(pos)
	var m = null
	var d = 1000000
	for i in nodes.size():
		var dist = (l - nodes[i]).length_squared()
		if dist < d:
			d = dist
			m = i
	return m

func dx():
	var d = max($PlayerPath/Player.progress - 0.05, 0.0)
	print($PlayerPath/Player.progress)
	return to_global($PlayerPath.curve.sample_baked(d))
	
func grid_hop():
	var grid = get_parent().get_child(get_index() + 1)
	$PlayerPath.reparent(grid)
	$Camera3D.reparent(grid)
	active = false
	await RenderingServer.frame_post_draw
	grid.active = true
	grid.reinit(grid.find_nearest(to_global(nodes[current])))

func _physics_process(delta):
	if !active:
		return
	if Input.is_action_just_pressed("debug_hop") && OS.is_debug_build():
		grid_hop()
		return
	if charging:
		charge_timer += delta
		if Events.charge >= 100.0 && is_possible:
			pop()
	if charge_timer > min(max_charge_time, 2.9) && charging && !is_possible:
		charging = false
		Events.meter_angry.emit()
		$PlayerPath/Player/ChargeSound.stop()
		$PlayerPath/Player/FailSound.play()
		require_release = true
	if Input.is_action_just_released("pop"):
		require_release = false
	if Input.is_action_pressed("pop") && !charging && Events.charge == 0.0:
		if electrified && !is_instance_valid(tween) && !require_release:
			Events.meter_calm.emit()
			charging = true
			charge_timer = 0.0
			charge_time = electrified.get_charge_time()
			max_charge_time = electrified.get_max_charge_time()
			is_possible = electrified.is_possible()
			print("TIME: ", charge_time)
			if charge_time == 0.0:
				pop()
			else:
				$PlayerPath/Player/ChargeSound.play()
	if !Input.is_action_pressed("pop") && charging:
		# $PlayerPath/Player/FailSound.play()
		charging = false
		$PlayerPath/Player/ChargeSound.stop()
	if charging:
		Events.charge += delta * 100.0 / charge_time
	else:
		Events.charge -= delta * 200.0
	Events.charge = clampf(Events.charge, 0.0, 100.0)
	#if electrified && Input.is_action_just_pressed("pop") && !is_instance_valid(tween):
		#electrified.kill()
		#Events.add_score(50)
		#electrified = null
		#$PlayerPath/Player/ChargeSound.play()
		#tween = get_tree().create_tween()
		#tween.tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ONE * 0.5, 0.2)
		#tween.tween_callback(clear_tween)
		
	# DebugDraw3D.draw_arrow(to_global(nodes[current]), to_global(nodes[current] + get_normal(current) * 1.0), Color.RED, 0.05)
	var normal = get_normal(current)
	if normal == Vector3.UP:
		$Camera3D.ceiling = true
		
	else:
		$Camera3D.ceiling = false
	
	# ceiling stuff
	# toggle upstairs
	if name == "house_wires":
		var space = get_world_3d().direct_space_state
		var params = PhysicsPointQueryParameters3D.new()
		params.collision_mask = 32
		params.position = $PlayerPath/Player/AnimatedSprite3D.global_position
		var result = space.intersect_point(params)
		var zone = "downstairs"
		if !result.is_empty():
			zone = result[0].collider.zone
		if zone != "upstairs":
			%house.show_upstairs(false)
			$WireMesh/Upstairs.visible = false
	
	if is_point_in_ceiling($PlayerPath/Player/AnimatedSprite3D.global_position):
		radius -= delta * 6.0
	else:
		radius += delta * 6.0
	radius = clampf(radius, 0.0, 2.0)
	RenderingServer.global_shader_parameter_set("sphereRadius", radius)
	$Camera3D.destination = to_global(nodes[current] + normal * 1.5)
	$Camera3D.target = to_global(nodes[current])
	if npc:
		$Camera3D.chase = $PlayerPath/Player
	else:
		$Camera3D.chase = null
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
		if buffered.size() < 1 && can_buffer:
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
				rotated = -diff.x + diff.z # ???
			elif $Camera3D.target_rotation >= 5 * PI / 6.0 && $Camera3D.target_rotation < 7 * PI / 6.0:
				rotated = diff.x
			elif $Camera3D.target_rotation >= 2 * PI / 3.0 && $Camera3D.target_rotation < 5 * PI / 6.0:
				print("B")
				rotated = diff.x + diff.z
			elif $Camera3D.target_rotation >= 4 * PI / 3.0 && $Camera3D.target_rotation < 5 * PI / 3.0:
				rotated = -diff.z
			elif $Camera3D.target_rotation >= 7 * PI / 6.0 && $Camera3D.target_rotation < 4 * PI / 3.0:
				print("C")
				rotated = diff.x - diff.z # ???
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
			if adjusted.distance_squared_to(input) < 0.001 || connections[current].size() == 1:
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
					var offset =  get_normal(current) * 0.05
					if npc:
						offset = Vector3.UP * 0.05
					curve.add_point(p + offset)
				$PlayerPath/Player.progress = 0.0
				can_buffer = false
				tween = get_tree().create_tween()
				tween.parallel().tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ONE * 0.5, 0.2)
				tween.set_ease(Tween.EASE_IN_OUT)
				if !npc:
					tween.set_trans(Tween.TRANS_QUAD)
				var dur = max(0.33 * path_length, 0.33)
				tween.parallel().tween_property($PlayerPath/Player, "progress_ratio", 1.0, dur)
				tween.parallel().tween_callback(func(): can_buffer = true).set_delay(dur - 0.2)
				var operable = find_operable(curve.get_point_position(curve.point_count - 1))
				if operable && !operable.dead:
					tween.tween_property($PlayerPath/Player/AnimatedSprite3D, "scale", Vector3.ZERO, 0.2)
					electrified = operable
					tween.parallel().tween_callback(func(): operable.electrified = true)
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
	if candidate.dead && !candidate.mandatory:
		return null
	return candidate
