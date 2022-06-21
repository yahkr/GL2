extends Area3D


func _on_fire_body_entered(body):
	var player := body as Player
	if player:
		player.burn = true


func _on_fire_body_exited(body):
	var player := body as Player
	if player:
		player.burn = false
