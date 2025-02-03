extends AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	Events.space_song.connect(on_space)
	Events.city_song.connect(on_city)
	Events.cutscene.connect(on_cutscene)
	pass # Replace with function body.

func on_space():
	self["parameters/switch_to_clip"] = &"Space"
	
func on_city():
	self["parameters/switch_to_clip"] = &"CityIntro"
	await get_tree().create_timer(4.0).timeout
	self["parameters/switch_to_clip"] = &"CityLoop"
	
func on_cutscene():
	self["parameters/switch_to_clip"] = &"Cutscene"
	await get_tree().create_timer(4.0).timeout
	self["parameters/switch_to_clip"] = &"Office"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
