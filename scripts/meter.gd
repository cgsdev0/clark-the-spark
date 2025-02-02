extends Node2D

var internal_score = 0
var target_score = 0
var jump_timer = 0.0

func _ready():
	Events.meter_angry.connect(angry)
	Events.meter_calm.connect(calm)
	Events.score_changed.connect(score_changed)

func angry():
	$Required.value = Events.charge
	$AnimationPlayer.play("error")

func calm():
	$Required.value = 0.0
	$AnimationPlayer.play("RESET")

func _process(delta):
	$Charge.value = Events.charge
	jump_timer += delta
	var computed = int(lerp(internal_score, target_score, clampf(jump_timer, 0.0, 1.0)))
	$Label.text = str(min(computed, 99999))
	if Events.planet_destroyed:
		$Label.text = "Err  "
		$Flash.play("RESET")

func score_changed():
	jump_timer = 0.0
	internal_score = target_score
	target_score = Events.score
	if target_score > 99999 && !Events.planet_destroyed:
		$Flash.play("flash")
