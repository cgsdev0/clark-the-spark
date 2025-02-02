extends Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotation.y += delta * rot_speed;

var dead = false

var rot_speed = 0.1;

func unlerp(from: float, to: float, value: float) -> float:
	return (value - from) / (to - from)
	
# more copy paste
func is_possible():
	return true

func get_max_charge_time():
	return 3.0

func get_reward():
	return 0
	
func get_charge_time():
	return 2.8
	
func kill():
	dead = true
	for mat in mats:
		mat.albedo_color = Color.WEB_GRAY
		mat.emission_enabled = false
		mat.next_pass = null
	electrified = false

# Called when the node enters the scene tree for the first time.
var mats = []
func _ready():
	var meshes = find_children("*", "MeshInstance3D")
	if is_instance_of(self, MeshInstance3D):
		meshes.push_back(self)
	for node in meshes:
		for i in node.mesh.get_surface_count():
			var mat = node.mesh.surface_get_material(i)
			if node.get_surface_override_material(i) != null:
				mat = node.get_surface_override_material(i)
			mats.push_back(mat)

func pop():
	charging = false
	Events.planet_destroyed = true
	self.kill()
	%PlayerPath/Player/ChargeSound.stop()
	%PlayerPath/Player/PopSound.play()
	var t = get_tree().create_tween()
	t.tween_property(self, "rot_speed", 0.0, 0.5)
	t.tween_interval(2.6)
	t.set_ease(Tween.EASE_IN)
	t.set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "scale", Vector3.ZERO, 0.18)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.parallel().tween_property(%BigGuy, "pixel_size", 0.2, 0.35).set_delay(0.19)

var charging = false
var electrified
var charge_timer = 0.0
var charge_time = 0.0
var max_charge_time = 2.9
var is_possible_question_mark = true
var require_release = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if !%EndCam.current:
		return
	
	if !Input.is_action_pressed("pop"):
		require_release = false
	# copy pasta time
	if charging:
		charge_timer += delta
		if Events.charge >= 100.0 && is_possible_question_mark:
			pop()
			return
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
