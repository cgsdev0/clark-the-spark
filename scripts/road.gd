extends Path3D


var car = preload("res://scenes/car.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	var cars = floor(curve.get_baked_length())
	for i in cars:
		if randi_range(0, 10) <= 8:
			continue
		var c = car.instantiate()
		var keep = c.get_children().pick_random()
		for child in c.get_children():
			if child == keep:
				continue
			child.queue_free()
		add_child(c)
		c.progress = i

func _process(delta):
	for car in get_children():
		car.progress += delta
