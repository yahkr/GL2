extends Gun


const ammo_notification = preload("res://weapons/ammo_notification.tscn")


func _process(_delta):
	shoot_gun()
	reload_gun()


func _on_area_3d_body_entered(body):
	if body.is_in_group("PistolAmmo"):
		if reserve_ammo < reserve_size:
			body.queue_free()
			reserve_ammo = min(reserve_ammo + 18, reserve_size)
			%SoundCollectAmmo.play()
			var notification_instance = ammo_notification.instantiate()
			%ItemNotifications.add_child(notification_instance)
