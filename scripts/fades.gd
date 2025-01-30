extends MeshInstance3D


enum Electric {
	GENERIC,
	CEILING_FAN
}

@export var type: Electric = Electric.GENERIC

@export var electric = false
@export var electrified = false
@export var fades = false
@export var solid_while_alive = false
var dead = false
var mat: StandardMaterial3D

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
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_BACK
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
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
