extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.hacky_endcam_do_not_use = self
	pass # Replace with function body.

func animate():
	var t = get_tree().create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "fov", 75, 2.5)

var was_current = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current && !was_current:
		was_current = true
		animate()
	pass
