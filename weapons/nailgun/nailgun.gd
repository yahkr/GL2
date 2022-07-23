extends Gun


@onready var area := $Area3D as Area3D


func _physics_process(delta):
	area.position = weapon_raycast.get_collision_point()
	if shoot_gun():
		for nail in area.get_overlapping_bodies():
			var path = Path3D.new()
			get_tree().get_root().add_child(path)
			path.curve = Curve3D.new()
			path.curve.add_point(weapon_raycast.get_collision_point())
			path.curve.add_point(nail.global_position)
	reload_gun()


func _on_area_3d_body_entered(body):
	if body.is_in_group("NailGunItem"):
		body.queue_free()
		process_mode = Node.PROCESS_MODE_INHERIT
		%SoundCollectAmmo.play()
		get_parent().select_weapon(get_index(), false)
		get_tree().get_nodes_in_group("WeaponSelectItem")[get_index()].modulate = Color.WHITE
		var notification_instance = item_notification.instantiate()
		%ItemNotifications.add_child(notification_instance)
		notification_instance.text = "d"
	elif body.is_in_group("NailGunAmmo"):
		if reserve_ammo < reserve_size:
			body.queue_free()
			reserve_ammo = min(reserve_ammo + 18, reserve_size)
			%SoundCollectAmmo.play()
			var notification_instance = ammo_notification.instantiate()
			%ItemNotifications.add_child(notification_instance)
