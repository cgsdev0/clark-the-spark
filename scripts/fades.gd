extends MeshInstance3D


enum Electric {
	GENERIC,
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
	Electric.GENERIC: [50, 0, 100, 2.8],
	Electric.CEILING_FAN: [50, 100, 1200, 1.0],
	Electric.CEILING_LIGHT: [50, 0, 1000, 1.0],
	Electric.TALL_LAMP: [50, 0, 100, 1.0],
	Electric.SHORT_LAMP: [50, 0, 100, 1.0],
	Electric.TV: [50, 0, 100, 2.8],
	Electric.COMPUTER: [50, 0, 100, 2.8],
	Electric.FRIDGE: [500, 500, 2000, 2.8],
	Electric.MICROWAVE: [50, 0, 100, 2.8],
	Electric.OVEN: [50, 0, 100, 2.8],
	Electric.DRYER: [50, 0, 100, 2.8],
	Electric.WASHER: [50, 0, 100, 2.8],
	Electric.CONSOLE: [50, 0, 100, 2.8],
	Electric.RADIATOR: [50, 0, 100, 2.8],
	Electric.SPEAKER: [50, 0, 100, 2.8],
	Electric.TREADMILL: [50, 0, 100, 2.8],
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
	
func get_charge_time():
	var d = values[type]
	if Events.score >= d[2]:
		return 0.0
	if Events.score < d[1]:
		var t = unlerp(0.0, d[1], max(Events.score, 10.0))
		return d[3] / t
	var t = unlerp(d[1], d[2], Events.score)
	print("T: ", t)
	return lerp(d[3], 0.2, t)
	
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
