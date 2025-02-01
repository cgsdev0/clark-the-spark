extends ColorRect


func _ready():
	Events.transition.connect(cut)
	pass # Replace with function body.


func cut():
	var t = get_tree().create_tween()
	t.tween_method(change_size, 1.05, 0.0, 0.5)
	t.tween_callback(func(): Events.teleport.emit())
	t.tween_interval(0.4)
	t.tween_method(change_size, 0.0, 1.05, 0.5)

func change_size(s):
	var mat: ShaderMaterial = material
	mat.set_shader_parameter("circle_size", s)
	
func _process(delta):
	var mat: ShaderMaterial = material
	mat.set_shader_parameter("screen_width", get_viewport_rect().size.x)
	mat.set_shader_parameter("screen_height", get_viewport_rect().size.y)
