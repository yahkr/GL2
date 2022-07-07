extends StaticBody3D


func _on_ladder_body_entered(body):
	var player := body as Player
	if player:
		player.ladder.append(self)


func _on_ladder_body_exited(body):
	var player := body as Player
	if player and player.ladder.has(self):
		player.ladder.erase(self)
