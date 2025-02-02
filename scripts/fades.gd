extends MeshInstance3D


enum Electric {
	GENERIC,
	ALARM_CLOCK,
	CEILING_FAN,
	CEILING_LIGHT,
	TALL_LAMP,
	SHORT_LAMP,
	TV,
	COMPUTER,
	FRIDGE,
	MICROWAVE,
	OVEN,
	DRYER,
	WASHER,
	CONSOLE,
	RADIATOR,
	SPEAKER,
	TREADMILL,
	CAR,
	GENERATOR,
	RESISTOR,
	BIG_RESISTOR,
	CAPACITOR
}

var values = {
	# points gained, min needed, pop threshold, max time
	Electric.GENERIC: [5, 0, 2000, 1.0],
	Electric.ALARM_CLOCK: [5, 0, 2000, 1.0],
	Electric.CEILING_LIGHT: [5, 0, 2000, 1.0],
	Electric.TALL_LAMP: [5, 0, 2000, 1.0],
	Electric.SHORT_LAMP: [5, 0, 2000, 1.0],
	Electric.SPEAKER: [50, 20, 10000, 1.5],
	Electric.CEILING_FAN: [50, 15, 5000, 1.0],
	Electric.TV: [60, 40, 12000, 2.0],
	Electric.CONSOLE: [100, 90, 3000, 1.0],
	Electric.RADIATOR: [300, 200, 11000, 2.0],
	Electric.COMPUTER: [325, 300, 10000, 1.8],
	Electric.TREADMILL: [300, 600, 20000, 2.0],
	Electric.FRIDGE: [400, 1000, 20000, 2.8],
	Electric.MICROWAVE: [500, 800, 20000, 2.0],
	Electric.WASHER: [500, 2000, 20000, 1.5],
	Electric.DRYER: [1000, 2000, 20000, 2.5],
	Electric.OVEN: [1500, 1000, 20000, 2.8],
	Electric.CAR: [2500, 4000, 20000, 2.5],
	Electric.GENERATOR: [5000, 20000, 1000000, 2.8],
	Electric.RESISTOR: [2, 0, 50, 1.2],
	Electric.BIG_RESISTOR: [5, 5, 50, 1.2],
	Electric.CAPACITOR: [4, 1, 50, 2.3],
}

@export var type: Electric = Electric.GENERIC

@export var electric = false
@export var electrified = false
@export var fades = false
@export var solid_while_alive = false
@export var mandatory = false
@export var force_hop = false
@export var tooltip: Events.Tooltip = Events.Tooltip.NONE

var was_electrified = false
var dead = false
var mats: Array[StandardMaterial3D] = []

func unlerp(from: float, to: float, value: float) -> float:
	return (value - from) / (to - from)

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
	#var anim = find_child("AnimationPlayer")
	#if is_instance_valid(anim):
		#anim.pause()
	if tooltip != Events.Tooltip.NONE:
		Events.hide_tooltip.emit()
	if is_instance_valid(tv):
		tv.queue_free()
	dead = true
	for mat in mats:
		mat.albedo_color = Color.WEB_GRAY
		mat.emission_enabled = false
	electrified = false
	
var tv = null
# Called when the node enters the scene tree for the first time.
func _ready():
	if type == Electric.TV:
		var min = 100000
		for t in get_tree().get_nodes_in_group("tv_screen"):
			var len = (t.global_position - global_position).length_squared()
			if len < min:
				min = len
				tv = t
	for i in mesh.get_surface_count():
		var mat = mesh.surface_get_material(i)
		if get_surface_override_material(i) != null:
			mat = get_surface_override_material(i)
		else:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			mat.cull_mode = BaseMaterial3D.CULL_BACK
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
		mat = mat.duplicate()
		if get_surface_override_material(i) != null:
			set_surface_override_material(i, mat)
		else:
			mesh.surface_set_material(i, mat)
		mats.push_back(mat)
	
	# warm up cache idfk
	for mat in mats:
		mat.next_pass = preload("res://materials/electrified.tres")
	await RenderingServer.frame_post_draw
	for mat in mats:
		mat.next_pass = null
		
func fade_out(delta):
	if fades:
		for mat in mats:
			mat.albedo_color.a -= delta * 5.0

var speed = 5.0

func fade_tv(fade_in):
	var bus = AudioServer.get_bus_index("TV")
	var volume_db = AudioServer.get_bus_volume_db(bus)
	if fade_in:
		AudioServer.set_bus_mute(bus, false)
		var t = get_tree().create_tween()
		t.tween_method(func(vol): AudioServer.set_bus_volume_db(bus, vol), volume_db, -20.0, 0.4)
	else:
		var t = get_tree().create_tween()
		t.tween_method(func(vol): AudioServer.set_bus_volume_db(bus, vol), volume_db, -80.0, 0.4)
		t.tween_callback(func(): AudioServer.set_bus_mute(bus, true))
		
var dead_timer = 0.0

func fail_tooltip():
	if tooltip == Events.Tooltip.TOO_HARD:
		Events.show_tooltip.emit(tooltip)

func _process(delta):
	if electrified && !was_electrified:
		Events.multimeter_up = true
	if !electrified && was_electrified && !dead:
		Events.multimeter_up = false
	if tooltip == Events.Tooltip.POP && electrified && !was_electrified:
		Events.show_tooltip.emit(tooltip)
	if is_instance_valid(tv):
		tv.visible = self.is_visible_in_tree()
	if dead:
		dead_timer += delta
	match type:
		#Electric.TV:
			#if electrified && !was_electrified:
				#fade_tv(true)
			#if !electrified && was_electrified:
				#fade_tv(false)
		Electric.CEILING_FAN:
			rotate_y(delta * speed)
			if dead:
				speed = move_toward(speed, 0.1, delta * 2.0)
			
	if electrified && electric:
		for mat in mats:
			mat.next_pass = preload("res://materials/electrified.tres")
	else:
		for mat in mats:
			mat.next_pass = null
	if fades:
		for mat in mats:
			mat.albedo_color.a += delta * 2.5
			if electrified:
				mat.albedo_color.a += delta * 6.0
			if solid_while_alive && (!dead || dead_timer < 2.0):
				mat.albedo_color.a = 1.0
			mat.albedo_color.a = clampf(mat.albedo_color.a, 0.4, 1.0)
	was_electrified = electrified
