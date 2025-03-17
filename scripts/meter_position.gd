extends Control


var v_tween
var h_tween

var up = 300
var down = 440

@onready var off_x = get_viewport().get_visible_rect().size.x * 0.8

var right = true

func _ready():
	Events.meter_angry.connect(shake)
	Events.pop.connect(bounce)
	Events.touch_side.connect(update_side)
	pass

func update_side(is_right):
	if is_right == right:
		return
	right = is_right
	if right:
		off_x = get_viewport().get_visible_rect().size.x * 0.85 - get_rect().size.x / 2.0
	else:
		off_x = get_viewport().get_visible_rect().size.x * 0.15 - get_rect().size.x / 2.0
	if is_instance_valid(h_tween):
		h_tween.kill()
	h_tween = get_tree().create_tween()
	h_tween.set_trans(Tween.TRANS_QUAD)
	h_tween.set_ease(Tween.EASE_OUT)
	h_tween.tween_method(func(v): position.x = v, position.x, off_x, 0.5)
	
func bounce():
	var was = position.y
	if is_instance_valid(v_tween):
		v_tween.kill()
	v_tween = get_tree().create_tween()
	v_tween.set_trans(Tween.TRANS_QUAD)
	v_tween.set_ease(Tween.EASE_OUT)
	v_tween.tween_method(func(v): position.y = v, was, was - 20.0, 0.1)
	v_tween.set_ease(Tween.EASE_IN)
	v_tween.tween_method(func(v): position.y = v, was - 20.0, up if Events.multimeter_up else down, 0.1)

func shake():
	if is_instance_valid(h_tween):
		h_tween.kill()
	h_tween = get_tree().create_tween()
	# h_tween.set_ease(Tween.EASE_OUT)
	h_tween.set_trans(Tween.TRANS_QUAD)
	off_x = position.x
	h_tween.set_ease(Tween.EASE_OUT)
	h_tween.tween_method(func(v): position.x = v, position.x, off_x -16.0, 0.08)
	h_tween.set_ease(Tween.EASE_IN)
	h_tween.tween_method(func(v): position.x = v, off_x -16.0, off_x +16.0, 0.16)
	h_tween.set_ease(Tween.EASE_OUT)
	h_tween.tween_method(func(v): position.x = v, off_x +16.0, off_x, 0.08)
	
var was_up = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Events.multimeter_up != was_up:
		if was_up:
			Events.meter_calm.emit()
		was_up = Events.multimeter_up
		if is_instance_valid(v_tween):
			v_tween.kill()
		v_tween = get_tree().create_tween()
		v_tween.set_ease(Tween.EASE_OUT)
		v_tween.set_trans(Tween.TRANS_CUBIC)
		v_tween.tween_method(func(v): position.y = v, position.y, up if was_up else down, 0.4 if was_up else 0.6)
	pass
