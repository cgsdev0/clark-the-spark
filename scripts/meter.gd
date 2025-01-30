extends Node2D

var internal_score = 0
var target_score = 0
var jump_timer = 0.0

func _ready():
	Events.meter_angry.connect(angry)
	Events.meter_calm.connect(calm)
	Events.score_changed.connect(score_changed)

func angry():
	$AnimationPlayer.play("error")

func calm():
	$AnimationPlayer.play("RESET")

func _process(delta):
	jump_timer += delta * 2.0
	var computed = int(lerp(internal_score, target_score, clampf(jump_timer, 0.0, 1.0)))
	$Label.text = str(computed)
	
func score_changed():
	jump_timer = 0.0
	internal_score = target_score
	target_score = Events.score
