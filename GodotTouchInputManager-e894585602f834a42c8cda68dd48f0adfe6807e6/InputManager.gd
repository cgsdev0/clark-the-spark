extends Node

var target = 80
var startPos: Vector2
var curPos: Vector2
var swiping = false

var clicked = false
var swipe_timer = 0.0
var cooldown = 0.0

func _process(delta):
	cooldown -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) && !swiping:
		swiping = true
		swipe_timer = 0.0
		startPos = get_window().get_mouse_position()
		
		
	if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		swiping = false
	
	if swiping:
		swipe_timer += delta
		if swipe_timer > 0.2 || cooldown > 0.0:
			swiping = false
			return
		curPos = get_window().get_mouse_position()
		if startPos.distance_to(curPos) >= target:
			swipe.emit(curPos - startPos)
			cooldown = 0.3
			swiping = false
			
signal swipe(dir)
