extends Area2D

@onready var UI := get_tree().get_root().get_node("Node2D/UI")
var growth_timer = 1

func _process(delta: float) -> void:
	growth_timer -= delta
	while Global.inSunZone and growth_timer < 0:
		UI.progress_growth(15)
		growth_timer = 1
		
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if UI:
			Global.inSunZone = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		Global.inSunZone = false
