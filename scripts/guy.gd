extends AnimatedSprite3D


# Called when the node enters the scene tree for the first time.
func _ready():
	play("default")
	pass # Replace with function body.

var walls = preload("res://materials/walls.tres")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	walls.set_shader_parameter("spherePos", global_position)
