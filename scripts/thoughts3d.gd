extends Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.player_path_hacky_do_not_use = %PlayerPath
	Events.show_tooltip.connect(on_show)
	Events.hide_tooltip.connect(on_hide)
	offset = Vector2(-150, -50)
	global_position = %PlayerPath/Player/AnimatedSprite3D.global_position

var tween
func on_show(tooltip: Events.Tooltip):
	offset = Vector2(400, 80)
	pixel_size = 0.0020
	global_position = %PlayerPath/Player/AnimatedSprite3D.global_position
	if is_instance_valid(tween):
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func on_hide():
	if is_instance_valid(tween):
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
