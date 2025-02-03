extends Node


signal meter_angry
signal meter_calm

signal transition
signal teleport

enum Tooltip {
	NONE,
	UP,
	POP,
	TOO_HARD,
	RIGHT
}

var multimeter_up = false

var tooltip: Tooltip = Tooltip.UP

signal pop
signal hide_tooltip
signal show_tooltip(tooltip: Tooltip)

signal cutscene
signal city_song
signal space_song

signal sparks(vec)

func _ready():
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	show_tooltip.connect(_on_show)
	hide_tooltip.connect(_on_hide)
	
func _on_show(t: Tooltip):
	tooltip = t
	
func _on_hide():
	tooltip = Tooltip.NONE
	
var city = false
var planet_destroyed = false
var score: int = 99999 if OS.is_debug_build() else 0
signal score_changed

var charge = 0.0
var player_path_hacky_do_not_use = null
var iso_cam_hacky_do_not_use
var hacky_endcam_do_not_use

func add_score(diff: int):
	score += diff
	score_changed.emit()
