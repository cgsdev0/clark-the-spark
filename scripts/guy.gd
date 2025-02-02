extends Sprite3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	RenderingServer.global_shader_parameter_set("spherePos", global_position)

func _physics_process(delta):
	var nearest_tv = null
	var dist = 100000
	for node in get_tree().get_nodes_in_group("tv_screen"):
		if !is_instance_valid(node):
			continue
		if !node.visible:
			continue
		var len = global_position.distance_to(node.global_position)
		if len < dist:
			nearest_tv = node
			dist = len
	
	var bus = AudioServer.get_bus_index("TV")
	if is_instance_valid(nearest_tv):
		var volume_db = AudioServer.get_bus_volume_db(bus)
		var vol = clampf(remap(dist, 0, 10, -15.0, -51.0), -51.0, -15.0)
		AudioServer.set_bus_volume_db(bus, vol)
		if vol <= -50.0:
			AudioServer.set_bus_mute(bus, true)
		else:
			AudioServer.set_bus_mute(bus, false)
	else:
		AudioServer.set_bus_mute(bus, true)
