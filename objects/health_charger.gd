extends Interactable


func interact(player):
	await get_tree().create_timer(1.0)
	print("HEALTH: " + str(player.health))

