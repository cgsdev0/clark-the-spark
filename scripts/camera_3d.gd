extends Camera3D

var target: Vector3 = Vector3.ZERO
var destination: Vector3 = Vector3.ZERO
var target_rotation = 0.0
var target_pitch = 0.0
var ceiling = true
var target_y = 0.0
var chase = null

# Called when the node enters the scene tree for the first time.
func _ready():
	target_y = global_position.y
	pass # Replace with function body.


func based_lerp(a, b, delta, rate):
	if abs(b - a) < 0.1:
		return a
	return lerp(a, b, 1-exp(-delta * rate))

func based_lerp_angle(a, b, delta, rate):
	return lerp_angle(a, b, 1-exp(-delta * rate))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# fade out solid objects
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.collision_mask = 16
	params.from = global_position
	params.to = %AnimatedSprite3D.global_position
	params.hit_from_inside = true
	var result = space.intersect_ray(params)
	if result.has("collider"):
		result.collider.get_parent().fade_out(delta)
	
	# toggle upstairs
	params = PhysicsPointQueryParameters3D.new()
	params.collision_mask = 32
	params.position = target
	result = space.intersect_point(params)
	var zone = "downstairs"
	if !result.is_empty():
		zone = result[0].collider.zone
	if zone == "upstairs":
		%house.show_upstairs(true)
		get_parent().get_node("WireMesh/Upstairs").visible = true
	
	if is_instance_valid(chase):
		var from = get_parent().dx()
		var to = chase.global_position
		global_position.x = based_lerp(global_position.x, from.x, delta, 2.0)
		global_position.z = based_lerp(global_position.z, from.z, delta, 2.0)
		global_position.y = based_lerp(global_position.y, from.y + 2.0, delta, 2.0)
		var a = Vector2(global_position.x, global_position.z) - Vector2(to.x, to.z)
		global_rotation.y = based_lerp_angle(global_rotation.y,  PI / 2.0 - a.angle(), delta, 8.0)
		global_rotation.x = based_lerp_angle(global_rotation.x, -PI / 10.0, delta, 3.0)
		return
	# move
	var diff = target - destination
	var xz = Vector2(diff.x, -diff.z)
	target_rotation = fposmod(xz.angle() - PI / 2.0, 2 * PI)
	if ceiling:
		target_rotation = PI / 2.0
		target_pitch = -PI / 2.0
	else:
		target_pitch = -PI / 9.0
	global_rotation.y = based_lerp_angle(global_rotation.y, target_rotation, delta, 3.0)
	global_rotation.x = based_lerp_angle(global_rotation.x, target_pitch, delta, 3.0)
	global_position.x = based_lerp(global_position.x, destination.x, delta, 3.0)
	global_position.z = based_lerp(global_position.z, destination.z, delta, 3.0)
	global_position.y = based_lerp(global_position.y, target_y + 
		(10.0 if ceiling else 0.0) +
		(8.0 if zone == "upstairs" else 0.0), delta, 3.0)
