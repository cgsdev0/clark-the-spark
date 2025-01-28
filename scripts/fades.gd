extends MeshInstance3D


@export var electric = false
@export var electrified = false
@export var fades = false
var dead = false
var mat: StandardMaterial3D

func kill():
	dead = true
	electrified = false
	
# Called when the node enters the scene tree for the first time.
func _ready():
	mat = mesh.surface_get_material(0)
	mat = mat.duplicate()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mesh.surface_set_material(0, mat)

func fade_out(delta):
	if fades:
		mat.albedo_color.a -= delta * 5.0

func _process(delta):
	if electrified && electric:
		mat.next_pass = preload("res://materials/electrified.tres")
	else:
		mat.next_pass = null
	if fades:
		mat.albedo_color.a += delta * 2.5
		mat.albedo_color.a = clampf(mat.albedo_color.a, 0.4, 1.0)
