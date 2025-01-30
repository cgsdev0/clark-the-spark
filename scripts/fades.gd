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
}

var values = {
	# points gained, min needed, pop threshold, max time
	Electric.GENERIC: [5, 0, 5000, 1.0],
	Electric.ALARM_CLOCK: [5, 0, 5000, 1.0],
	Electric.CEILING_LIGHT: [5, 0, 5000, 1.0],
	Electric.TALL_LAMP: [5, 0, 5000, 1.0],
	Electric.SHORT_LAMP: [5, 0, 5000, 1.0],
	Electric.SPEAKER: [50, 20, 10000, 1.5],
	Electric.CEILING_FAN: [50, 20, 5000, 1.0],
	Electric.TV: [60, 40, 12000, 2.0],
	Electric.CONSOLE: [100, 100, 8000, 1.0],
	Electric.RADIATOR: [300, 300, 11000, 2.0],
	Electric.COMPUTER: [325, 300, 10000, 1.8],
	Electric.TREADMILL: [300, 600, 20000, 2.0],
	Electric.FRIDGE: [400, 1000, 20000, 2.8],
	Electric.MICROWAVE: [500, 800, 20000, 2.0],
	Electric.WASHER: [500, 2000, 20000, 1.5],
	Electric.DRYER: [1000, 2000, 20000, 2.5],
	Electric.OVEN: [1500, 1000, 50000, 2.8],
}

@export var type: Electric = Electric.GENERIC

@export var electric = false
@export var electrified = false
@export var fades = false
@export var solid_while_alive = false
@export var mandatory = false
var dead = false
var mat: StandardMaterial3D

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
	dead = true
	mat.emission_enabled = false
	electrified = false
	
# Called when the node enters the scene tree for the first time.
func _ready():
	mat = mesh.surface_get_material(0)
	if get_surface_override_material(0) != null:
		mat = get_surface_override_material(0)
	else:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	mat = mat.duplicate()
	if get_surface_override_material(0) != null:
		set_surface_override_material(0, mat)
	else:
		mesh.surface_set_material(0, mat)

func fade_out(delta):
	if fades:
		mat.albedo_color.a -= delta * 5.0

var speed = 5.0

var dead_timer = 0.0
func _process(delta):
	if dead:
		dead_timer += delta
	match type:
		Electric.CEILING_FAN:
			rotate_y(delta * speed)
			if dead:
				speed = move_toward(speed, 0.1, delta * 2.0)
			
	if electrified && electric:
		mat.next_pass = preload("res://materials/electrified.tres")
	else:
		mat.next_pass = null
	if fades:
		mat.albedo_color.a += delta * 2.5
		if electrified:
			mat.albedo_color.a += delta * 6.0
		if solid_while_alive && (!dead || dead_timer < 2.0):
			mat.albedo_color.a = 1.0
		mat.albedo_color.a = clampf(mat.albedo_color.a, 0.4, 1.0)
