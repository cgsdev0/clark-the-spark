extends Path2D

func _ready():
	$Line2D.default_color = Color("#262b44")  
	$Line2D.width = 20
	for point in curve.get_baked_points():  
		$Line2D.add_point(point + position)
