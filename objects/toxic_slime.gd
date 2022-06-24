extends Area3D


func _on_toxic_slime_body_entered(body):
	var player := body as Player
	if player:
		player.toxic_slime = true


func _on_toxic_slime_body_exited(body):
	var player := body as Player
	if player:
		player.toxic_slime = false
