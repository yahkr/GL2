extends Area3D


func _on_electricity_body_entered(body):
	var player := body as Player
	if player:
		player.electrocute = true


func _on_electricity_body_exited(body):
	var player := body as Player
	if player:
		player.electrocute = false
