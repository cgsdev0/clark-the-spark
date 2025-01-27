extends Camera3D

var target: Vector3 = Vector3.ZERO
var destination: Vector3 = Vector3.ZERO
var target_rotation = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	var diff = target - destination
	var xz = Vector2(diff.x, -diff.z)
	target_rotation = fposmod(xz.angle() - PI / 2.0, 2 * PI)
	global_rotation.y = lerp_angle(global_rotation.y, target_rotation, delta * 3.0)
	global_position.x = lerp(global_position.x, destination.x, delta * 3.0)
	global_position.z = lerp(global_position.z, destination.z, delta * 3.0)
