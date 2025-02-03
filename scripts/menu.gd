extends Control

@onready var SFX_Bus_ID = AudioServer.get_bus_index("SFX")
@onready var Music_Bus_ID = AudioServer.get_bus_index("Music")

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	%Sprite2D.texture = %AnimatedSprite3D.texture
	get_tree().paused = true
	%MusicSlider.value_changed.connect(_on_music_slider_value_changed)
	%SFXSlider.value_changed.connect(_on_sfx_slider_value_changed)
	%SFXSlider.drag_ended.connect(_on_drag_end)
	%MusicSlider.value = db_to_linear(AudioServer.get_bus_volume_db(Music_Bus_ID))
	%SFXSlider.value = db_to_linear(AudioServer.get_bus_volume_db(SFX_Bus_ID))

func _process(delta):
	$Path2D/PathFollow2D.progress += delta * 1000.0
	
func _on_drag_end(changed):
	if !changed:
		return
	%PlayerPath/Player/PopSound.play()
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Music_Bus_ID, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_Bus_ID, linear_to_db(value))


func _on_quit_pressed():
	get_tree().quit()

func _on_fullscreen_pressed():
	if get_viewport().mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
		get_viewport().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		get_viewport().mode = Window.MODE_WINDOWED

var first = false
func _input(event):
	if !first:
		return
	if event.is_action_pressed("pause"):
		visible = !visible
		get_tree().paused = !get_tree().paused
		
func _on_start_pressed():
	Events.transition.emit()
	await Events.teleport
	hide()
	$Path2D.hide()
	%Start.hide()
	if !OS.has_feature("web"):
		%Quit.show()
	first = true
	material.set_shader_parameter("alpha", 0.0)
	$Modesty.show()
	get_tree().paused = false
