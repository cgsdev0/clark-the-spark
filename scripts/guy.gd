extends AnimatedSprite3D


# Called when the node enters the scene tree for the first time.
func _ready():
	play("default")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	RenderingServer.global_shader_parameter_set("spherePos", global_position)
