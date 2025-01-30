extends Node


signal meter_angry
signal meter_calm

var score: int = 0
signal score_changed

func add_score(diff: int):
	score += diff
	score_changed.emit()
