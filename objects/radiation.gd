extends Area3D


@export_range(0, 1) var strength := 1.0


func _on_radiation_body_entered(body):
	var player := body as Player
	if player:
		player.geiger = strength


func _on_radiation_body_exited(body):
	var player := body as Player
	if player and player.geiger == strength:
		player.geiger = 0
