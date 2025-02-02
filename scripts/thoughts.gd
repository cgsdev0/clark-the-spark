extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match Events.tooltip:
		Events.Tooltip.UP:
			$BubbleButton/Up.show()
			$BubbleButton/Space.hide()
			$BubbleButton/TooHard.hide()
		Events.Tooltip.POP:
			$BubbleButton/Up.hide()
			$BubbleButton/Space.show()
			$BubbleButton/TooHard.hide()
		Events.Tooltip.TOO_HARD:
			$BubbleButton/Up.hide()
			$BubbleButton/Space.hide()
			$BubbleButton/TooHard.show()
