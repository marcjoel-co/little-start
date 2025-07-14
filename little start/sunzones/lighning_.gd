extends Node2D

var decay_timer = 0.5

func _process(delta: float) -> void:
	decay_timer -= delta
	if not Global.inSunZone and decay_timer < 0:
		if $UI/ProgressBar.value > 0:
			$UI/ProgressBar.value -= 1
			decay_timer = 0.5
