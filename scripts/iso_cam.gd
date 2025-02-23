extends Camera3D

var target

func based_lerp(a, b, delta, rate):
	return lerp(a, b, 1-exp(-delta * rate))
	
func _ready():
	Events.iso_cam_hacky_do_not_use = self
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.selected:
			target = building
			break

func _process(delta):
	Events.city = current
	if target:
		var aabb: AABB = target.aabb
		var dest = aabb.get_center() * 25.0 + global_basis.z * 1000.0
		global_position = based_lerp(global_position, dest, delta, 5.0)
