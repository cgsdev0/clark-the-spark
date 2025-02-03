extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match Events.tooltip:
		Events.Tooltip.UP:
			for child in $BubbleButton.get_children():
				child.hide()
			$BubbleButton/Up.show()
		Events.Tooltip.POP:
			for child in $BubbleButton.get_children():
				child.hide()
			$BubbleButton/Space.show()
		Events.Tooltip.TOO_HARD:
			for child in $BubbleButton.get_children():
				child.hide()
			$BubbleButton/TooHard.show()
		Events.Tooltip.RIGHT:
			for child in $BubbleButton.get_children():
				child.hide()
			$BubbleButton/Right.show()
