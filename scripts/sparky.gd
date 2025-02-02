extends Node2D

func _ready():
	$Timer.start()
	$Body.play("default")
	
func _on_timer_timeout():
	if randi_range(0, 6) == 0:
		$Eyes.play("double_blink")
	else:
		$Eyes.play("blink")
	$Timer.start(randf_range(3.0, 5.5))
