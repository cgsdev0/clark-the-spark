extends Node3D

@export var which = "spherePos1"

var buffer = []

func _physics_process(delta):
	buffer.push_back(get_parent().global_position)
	if buffer.size() > 2:
		global_position = buffer.pop_front()
	RenderingServer.global_shader_parameter_set(which, global_position)
