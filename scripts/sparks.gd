extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.sparks.connect(on_sparks)
	pass # Replace with function body.

func on_sparks(vec):
	restart()
