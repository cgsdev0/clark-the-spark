extends Control

@onready var SFX_Bus_ID = AudioServer.get_bus_index("SFX")
@onready var Music_Bus_ID = AudioServer.get_bus_index("Music")

func _ready() -> void:
	%MusicSlider.value_changed.connect(_on_music_slider_value_changed)
	%SFXSlider.value_changed.connect(_on_sfx_slider_value_changed)
	%SFXSlider.drag_ended.connect(_on_drag_end)
	%MusicSlider.value = db_to_linear(AudioServer.get_bus_volume_db(Music_Bus_ID))
	%SFXSlider.value = db_to_linear(AudioServer.get_bus_volume_db(SFX_Bus_ID))

func _on_drag_end(changed):
	if !changed:
		return
	%PlayerPath/Player/PopSound.play()
func _on_music_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(Music_Bus_ID, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_Bus_ID, linear_to_db(value))
