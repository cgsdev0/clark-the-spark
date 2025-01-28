extends Camera3D

var target: Vector3 = Vector3.ZERO
var destination: Vector3 = Vector3.ZERO
var target_rotation = 0.0
var target_pitch = 0.0
var ceiling = true
var target_y = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	target_y = global_position.y
	pass # Replace with function body.


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
	
	
	# move
	var diff = target - destination
	var xz = Vector2(diff.x, -diff.z)
	target_rotation = fposmod(xz.angle() - PI / 2.0, 2 * PI)
	if ceiling:
		target_rotation = PI / 2.0
		target_pitch = -PI / 2.0
	else:
		target_pitch = -PI / 9.0
	global_rotation.y = lerp_angle(global_rotation.y, target_rotation, delta * 3.0)
	global_rotation.x = lerp_angle(global_rotation.x, target_pitch, delta * 3.0)
	global_position.x = lerp(global_position.x, destination.x, delta * 3.0)
	global_position.z = lerp(global_position.z, destination.z, delta * 3.0)
	global_position.y = lerp(global_position.y, target_y + (10.0 if ceiling else 0.0), delta * 3.0)
