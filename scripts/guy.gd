extends Sprite3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	RenderingServer.global_shader_parameter_set("spherePos", global_position)
