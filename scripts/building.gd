extends Node3D


@export var selected = false
enum Electric {
	GENERIC,
	HOUSE,
	OFFICE,
	TOWN_HOUSE,
	POWER_PLANT,
	SKYSCRAPER,
	TALL_BUILDING,
	STORE
}

var textures = {
	Electric.HOUSE: [
		preload("res://textures/house_textures.png"),
		preload("res://textures/house_textures_green.png"),
		preload("res://textures/house_textures_pink.png"),
		preload("res://textures/house_textures_yellow.png")
	],
	Electric.TOWN_HOUSE: [
		preload("res://textures/townhouse.png"),
		preload("res://textures/blue_townhouse.png"),
		preload("res://textures/yellow_townhouse.png"),
	],
	Electric.TALL_BUILDING: [
		preload("res://textures/tall_building.png"),
		preload("res://textures/green_tall_building.png"),
		preload("res://textures/yellow_tall_building.png")
	],
	Electric.STORE: [
		preload("res://textures/store.png"),
		preload("res://textures/store_yellow.png")
	]
}

var values = {
	# points gained, min needed, pop threshold, max time
	Electric.GENERIC: [5, 0, 2000, 1.0],
	Electric.HOUSE: [1000, 10000, 40000, 1.0],
	Electric.OFFICE: [2000, 15000, 60000, 1.0],
	Electric.TOWN_HOUSE: [1000, 10000, 40000, 1.0],
	Electric.POWER_PLANT: [100000, 99999, 10000000, 2.8],
	Electric.SKYSCRAPER: [30000, 60000, 10000000, 2.0],
	Electric.TALL_BUILDING: [5000, 40000, 10000000, 1.5],
	Electric.STORE: [2000, 15000, 60000, 1.0],
}

@export var type: Electric = Electric.GENERIC
@export var force_hop = false

var dead = false

func unlerp(from: float, to: float, value: float) -> float:
	return (value - from) / (to - from)
	
# more copy paste
func is_possible():
	var d = values[type]
	return Events.score >= d[1]

func get_max_charge_time():
	var d = values[type]
	return d[3]

func get_reward():
	var d = values[type]
	return d[0]
	
func get_charge_time():
	var d = values[type]
	if Events.score >= d[2]:
		return 0.0
	if Events.score < d[1]:
		var t = unlerp(0.0, d[1], max(Events.score, 1.0))
		return d[3] / clampf(t, 0.15, 0.9)
	var t = unlerp(d[1], d[2], Events.score)
	print("T: ", t)
	return lerp(d[3], 0.25, t)
	
func kill():
	dead = true
	for mat in mats:
		mat.albedo_color = Color.WEB_GRAY
		mat.emission_enabled = false
	electrified = false
	
func calculate_spatial_bounds(parent : Node3D, exclude_top_level_transform: bool) -> AABB:
	var bounds : AABB = AABB()
	if parent is VisualInstance3D:
		bounds = parent.get_aabb();

	for i in range(parent.get_child_count()):
		var child : Node3D = parent.get_child(i)
		if child:
			var child_bounds : AABB = calculate_spatial_bounds(child, false)
			if bounds.size == Vector3.ZERO && parent:
				bounds = child_bounds
			else:
				bounds = bounds.merge(child_bounds)
	if bounds.size == Vector3.ZERO && !parent:
		bounds = AABB(Vector3(-0.2, -0.2, -0.2), Vector3(0.4, 0.4, 0.4))
	if !exclude_top_level_transform:
		bounds = parent.transform * bounds
	return bounds

var aabb: AABB

# Called when the node enters the scene tree for the first time.
var mats = []
func _ready():
	add_to_group("buildings")
	aabb = calculate_spatial_bounds(self, false)
	var meshes = find_children("*", "MeshInstance3D")
	if is_instance_of(self, MeshInstance3D):
		meshes.push_back(self)
	for node in meshes:
		for i in node.mesh.get_surface_count():
			var mat = node.mesh.surface_get_material(i)
			if node.get_surface_override_material(i) != null:
				mat = node.get_surface_override_material(i)
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mat.cull_mode = BaseMaterial3D.CULL_BACK
			mat = mat.duplicate(true)
			node.set_surface_override_material(i, mat)
			mats.push_back(mat)
	if textures.has(type):
		var opts = textures[type]
		for mat: StandardMaterial3D in mats:
			mat.albedo_texture = opts.pick_random()
			
func find_neighbor(direction: Vector2):
	var candidates = []
	for building in get_tree().get_nodes_in_group("buildings"):
		if building == self:
			continue
		var mine:AABB = aabb
		var other: AABB = building.aabb
		if direction.x == 0.0:
			mine.position.z = 0.0
			other.position.z = 0.0
		else:
			mine.position.x = 0.0
			other.position.x = 0.0
		if mine.intersects(other):
			candidates.push_back(building)
		
	var a = Vector2(global_position.x, global_position.z)
	var min = 10000000
	var who = null
	for candidate in candidates:
		var b = Vector2(candidate.global_position.x, candidate.global_position.z)
		var diff = a - b
		diff = Vector2(diff.x * direction.x, diff.y * direction.y)
		var l = diff.x + diff.y
		if l < min && l > 0.0 && l < 250.0:
			who = candidate
			min = l
	print(min)
	return who

func move_on():
	await get_tree().create_timer(2.0).timeout
	Events.transition.emit()
	await Events.teleport
	%EndCam.current = true
	
func pop():
	var should_hop = self.force_hop
	charging = false
	Events.add_score(self.get_reward())
	self.kill()
	%PlayerPath/Player/ChargeSound.stop()
	%PlayerPath/Player/PopSound.play()
	if should_hop:
		Events.charge = 0.0
		selected = false
		electrified = false
		for mat in mats:
			mat.next_pass = null
		var t = get_tree().create_tween()
		t.set_parallel(true)
		t.set_ease(Tween.EASE_IN)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(%IsoCam, "size", 800.0, 2.5)
		move_on()
		return true
	return false

var charging = false
var electrified
var charge_timer = 0.0
var charge_time = 0.0
var max_charge_time = 2.9
var is_possible_question_mark = true
var require_release = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !%IsoCam.current || !selected:
		return
		
		
	# copy pasta time
	if charging:
		charge_timer += delta
		if Events.charge >= 100.0 && is_possible_question_mark:
			if pop():
				return
	if charge_timer > min(max_charge_time, 2.9) && charging && !is_possible_question_mark:
		charging = false
		Events.meter_angry.emit()
		%PlayerPath/Player/ChargeSound.stop()
		%PlayerPath/Player/FailSound.play()
		require_release = true
	if Input.is_action_just_released("pop"):
		require_release = false
	if Input.is_action_pressed("pop") && !charging && Events.charge == 0.0:
		if !dead && !require_release:
			Events.meter_calm.emit()
			charging = true
			charge_timer = 0.0
			charge_time = get_charge_time()
			max_charge_time = get_max_charge_time()
			is_possible_question_mark = is_possible()
			if charge_time == 0.0:
				if pop():
					return
			else:
				%PlayerPath/Player/ChargeSound.play()
	if !Input.is_action_pressed("pop") && charging:
		# $PlayerPath/Player/FailSound.play()
		charging = false
		%PlayerPath/Player/ChargeSound.stop()
	if charging:
		Events.charge += delta * 100.0 / charge_time
	else:
		Events.charge -= delta * 200.0
	Events.charge = clampf(Events.charge, 0.0, 100.0)
		
		
		
		
		
		
		
		
		
	for mat in mats:
		mat.next_pass = preload("res://materials/electrified.tres")
	var target
	if Input.is_action_just_pressed("move_left"):
		target = find_neighbor(Vector2(-1, 0))
	elif Input.is_action_just_pressed("move_right"):
		target = find_neighbor(Vector2(1, 0))
	elif Input.is_action_just_pressed("move_up"):
		target = find_neighbor(Vector2(0, -1))
	elif Input.is_action_just_pressed("move_down"):
		target = find_neighbor(Vector2(0, 1))
	if target:
		charging = false
		require_release = false
		%PlayerPath/Player/ChargeSound.stop()
		for mat in mats:
			mat.next_pass = null
		selected = false
		await RenderingServer.frame_post_draw
		target.selected = true
		%IsoCam.target = target
		print(target)
