extends Gun


const ammo_notification = preload("res://weapons/ammo_notification.tscn")


func _process(_delta):
	shoot_gun()
	reload_gun()


func _on_area_3d_body_entered(body):
	if body.is_in_group("PistolItem"):
		body.queue_free()
		process_mode = Node.PROCESS_MODE_INHERIT
		%SoundCollectAmmo.play()
		get_parent().select_weapon(get_index(), false)
		get_tree().get_nodes_in_group("WeaponSelectItem")[get_index()].modulate = Color.WHITE
	elif body.is_in_group("PistolAmmo"):
		if reserve_ammo < reserve_size:
			body.queue_free()
			reserve_ammo = min(reserve_ammo + 18, reserve_size)
			%SoundCollectAmmo.play()
			var notification_instance = ammo_notification.instantiate()
			%ItemNotifications.add_child(notification_instance)
